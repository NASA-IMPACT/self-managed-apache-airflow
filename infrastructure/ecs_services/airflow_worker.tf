# Send worker logs to this Cloud Watch log group

resource "aws_cloudwatch_log_group" "airflow_worker" {
  name_prefix       = "/${var.prefix}/airflow-worker/"
  retention_in_days = var.workers_logs_retention_days
}



resource "aws_ecs_task_definition" "airflow_worker" {
  family             = "${var.prefix}-worker"
  depends_on         = [null_resource.build_worker_ecr_image, aws_ecr_repository.airflow]
  cpu                = var.worker_cpu    # 4096
  memory             = var.worker_memory # 4096 *2
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
      name      = "worker"
      image     = join(":", [aws_ecr_repository.worker_airflow.repository_url, "latest"])
      cpu       = var.worker_cpu
      memory    = var.worker_memory
      essential = true
      command   = var.worker_cmd != [] ? var.worker_cmd : ["celery", "worker"]
      linuxParameters = {
        initProcessEnabled = true
      }
      environment = concat(
        var.airflow_task_common_environment,
        # Note: DUMB_INIT_SETSID required to handle warm shutdown of the celery workers properly
        #  https://airflow.apache.org/docs/docker-stack/entrypoint.html#signal-propagation
        [
          {
            name  = "DUMB_INIT_SETSID"
            value = "0"
          },
          {
            name  = "WORKER_HASHES"
            value = join(",", local.workers_hashes)
          }
        ]
      )
      user = "50000:0"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_worker.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "airflow-worker"
        }
      }
    }
  ])
}

resource "aws_security_group" "airflow_worker_service" {
  name_prefix = "${var.prefix}-worker-"
  description = "Deny all incoming traffic"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "airflow_worker" {
  depends_on      = [null_resource.build_worker_ecr_image, aws_ecr_repository.airflow]
  name            = "${var.prefix}-worker"
  task_definition = aws_ecs_task_definition.airflow_worker.family
  cluster         = aws_ecs_cluster.airflow.arn
  deployment_controller {
    type = "ECS"
  }
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  # Workers are autoscaled depending on the active, unpaused task count, so there is no
  # need to specify a desired_count here (the default is 0)
  desired_count = 1
  lifecycle {
    ignore_changes = [desired_count]
  }
  enable_execute_command = true
  network_configuration {
    subnets          = var.private_subnet_ids
    assign_public_ip = false
    security_groups  = [aws_security_group.airflow_worker_service.id]
  }
  platform_version    = "1.4.0"
  scheduling_strategy = "REPLICA"
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
  # Update from workers folder
  # force_new_deployment = var.force_new_ecs_service_deployment

}


