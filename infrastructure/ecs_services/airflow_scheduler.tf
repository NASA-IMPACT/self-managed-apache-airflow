resource "aws_cloudwatch_log_group" "airflow_scheduler" {
  name_prefix       = "/${var.prefix}-sm2a/airflow-scheduler/"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "airflow_scheduler_cloudwatch_agent" {
  name_prefix       = "/${var.prefix}-sm2a/airflow-scheduler-cloudwatch-agent/"
  retention_in_days = 1
}

# The CloudWatch agent configuration file for sending Airflow statsd metrics to CloudWatch.
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html
resource "aws_ssm_parameter" "airflow_ecs_cloudwatch_agent_config" {
  name        = "${var.prefix}-cloudwatch-agent-config"
  type        = "String"
  description = "CloudWatch agent configuration file for airflow ECS cluster"
  value = jsonencode(
    {
      agent = {
        region = var.aws_region,
        debug  = false
      }
      metrics = {
        namespace = "${var.prefix}SM2A"
        metrics_collected = {
          # These are the default values
          statsd = {
            service_address              = ":8125"
            metrics_collection_interval  = 10
            metrics_aggregation_interval = 60
          }
        }
      }
    }
  )
}



resource "aws_ecs_task_definition" "airflow_scheduler" {
  family             = "${var.prefix}-scheduler"
  depends_on         = [null_resource.build_ecr_image, aws_ecr_repository.airflow]
  cpu                = var.scheduler_cpu
  memory             = var.scheduler_memory
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.airflow_task.arn
  network_mode       = "awsvpc"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.task_cpu_architecture
  }
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name   = "scheduler"
      image  = join(":", [aws_ecr_repository.airflow.repository_url, "latest"])
      cpu    = var.scheduler_cpu
      memory = var.scheduler_memory

      healthcheck = {
        command = [
          "CMD-SHELL",
          "airflow jobs check --job-type SchedulerJob --hostname \"$${HOSTNAME}\""
        ]
        interval = 35
        timeout  = 30
        retries  = 5
      }
      essential = true
      command   = ["scheduler"]
      # Because we allow login via ECS exec, start the init process inside the container to remove any
      # zombie SSM agent child processes found.
      # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html#ecs-exec-task-definition
      linuxParameters = {
        initProcessEnabled = true
      }
      environment = concat(var.airflow_task_common_environment,
        [
          {
            name  = "SERVICES_HASH"
            value = join(",", local.services_hashes)
          }

      ])
      user = "50000:0"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_scheduler.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "airflow-scheduler"
        }
      }
    },
    {
      name      = "cloudwatch-agent"
      essential = true
      image     = "public.ecr.aws/cloudwatch-agent/cloudwatch-agent:latest"
      secrets = [
        {
          name      = "CW_CONFIG_CONTENT",
          valueFrom = aws_ssm_parameter.airflow_ecs_cloudwatch_agent_config.name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_scheduler_cloudwatch_agent.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "airflow-scheduler-cloudwatch-agent"
        }
      }
  }])
}

resource "aws_security_group" "airflow_scheduler_service" {
  name        = "${var.prefix}-scheduler"
  description = "Deny all incoming traffic"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_ecs_service" "airflow_scheduler" {
  name       = "${var.prefix}-scheduler"
  depends_on = [null_resource.build_ecr_image, aws_ecr_repository.airflow]
  # Note: If a revision is not specified, the latest ACTIVE revision is used.
  task_definition = aws_ecs_task_definition.airflow_scheduler.family
  cluster         = aws_ecs_cluster.airflow.arn
  deployment_controller {
    type = "ECS"
  }
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = var.number_of_schedulers
  enable_execute_command             = true
  launch_type                        = "FARGATE"
  network_configuration {
    subnets          = var.private_subnet_ids
    assign_public_ip = false
    security_groups  = [aws_security_group.airflow_scheduler_service.id]
  }
  platform_version    = "1.4.0"
  scheduling_strategy = "REPLICA"
  # Update from requirements
  force_new_deployment = var.force_new_ecs_service_deployment
}


