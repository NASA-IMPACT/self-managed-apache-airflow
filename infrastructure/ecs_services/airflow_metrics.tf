

resource "aws_cloudwatch_log_group" "airflow_metrics" {
  name_prefix       = "/${var.prefix}-sm2a/airflow-metrics/"
  retention_in_days = 1
}


resource "aws_security_group" "airflow_metrics_service" {
  name        = "${var.prefix}-metrics"
  description = "Deny all incoming traffic"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_ecs_task_definition" "airflow_metrics" {
  family             = "${var.prefix}-metrics"
  cpu                = 256
  memory             = 512
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.airflow_task.arn
  network_mode       = "awsvpc"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name      = "metrics"
      image     = join(":", [aws_ecr_repository.airflow.repository_url, "latest"])
      cpu       = 256
      memory    = 512
      essential = true
      entryPoint = [
        "python"
      ]
      command = [
        "scripts/put_airflow_worker_autoscaling_metric_data.py",
        "--cluster-name",
        aws_ecs_cluster.airflow.name,
        "--worker-service-name",
        aws_ecs_service.airflow_worker.name,
        "--region-name",
        var.aws_region,
        "--desired-count",
        var.desired_max_workers_count,
        "--period",
        "30"
      ]
      environment = concat(var.airflow_task_common_environment,
        [
      {
            name  = "SERVICES_HASH"
            value = join(",", local.services_hashes)
      }

      ])
      user        = "50000:0"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_metrics.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "airflow-metrics"
        }
      }
    }
  ])
}
#
resource "aws_ecs_service" "airflow_metrics" {
  depends_on      = [null_resource.build_ecr_image, aws_ecr_repository.airflow]
  name            = "${var.prefix}-metrics"
  task_definition = aws_ecs_task_definition.airflow_metrics.family
  cluster         = aws_ecs_cluster.airflow.name
  deployment_controller {
    type = "ECS"
  }
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  launch_type                        = "FARGATE"
  enable_execute_command             = true
  network_configuration {
    subnets          = var.private_subnet_ids
    assign_public_ip = false
    security_groups  = [aws_security_group.airflow_metrics_service.id]
  }
  platform_version     = "1.4.0"
  scheduling_strategy  = "REPLICA"
  # Update from scripts folder
  force_new_deployment = var.force_new_ecs_service_deployment
}
