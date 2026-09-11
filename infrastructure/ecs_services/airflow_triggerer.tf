resource "aws_cloudwatch_log_group" "airflow_triggerer" {
  name_prefix       = "/${var.prefix}-sm2a/airflow-triggerer/"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "airflow_triggerer" {
  family             = "${var.prefix}-triggerer"
  depends_on         = [null_resource.build_ecr_image, aws_ecr_repository.airflow]
  cpu                = var.triggerer_cpu
  memory             = var.triggerer_memory
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
      name   = "triggerer"
      image  = join(":", [aws_ecr_repository.airflow.repository_url, "latest"])
      cpu    = var.triggerer_cpu
      memory = var.triggerer_memory
      healthcheck = {
        command = [
          "CMD-SHELL",
          "airflow jobs check --job-type TriggererJob --hostname \"$${HOSTNAME}\""
        ]
        interval = 35
        timeout  = 30
        retries  = 5
      }
      essential = true
      command   = ["triggerer"]
      linuxParameters = {
        initProcessEnabled = true
      }
      environment = concat(var.airflow_task_common_environment,
        [
          {
            name  = "SERVICES_HASH"
            value = join(",", local.services_hashes)
          }
        ]
      )
      user = "50000:0"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_triggerer.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "airflow-triggerer"
        }
      }
    }
  ])
}

resource "aws_security_group" "airflow_triggerer_service" {
  name        = "${var.prefix}-triggerer"
  description = "Deny all incoming traffic"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "airflow_triggerer" {
  name       = "${var.prefix}-triggerer"
  depends_on = [null_resource.build_ecr_image, aws_ecr_repository.airflow]
  task_definition = aws_ecs_task_definition.airflow_triggerer.family
  cluster         = aws_ecs_cluster.airflow.arn
  deployment_controller {
    type = "ECS"
  }
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_execute_command             = true
  launch_type                        = "FARGATE"
  network_configuration {
    subnets          = var.private_subnet_ids
    assign_public_ip = false
    security_groups  = [aws_security_group.airflow_triggerer_service.id]
  }
  platform_version     = "1.4.0"
  scheduling_strategy  = "REPLICA"
  force_new_deployment = var.force_new_ecs_service_deployment
}
