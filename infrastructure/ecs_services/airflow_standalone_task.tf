

# Logs from the fluentbit container (not our application) go to CloudWatch
resource "aws_cloudwatch_log_group" "airflow_standalone_task" {
  name_prefix       = "/${var.prefix}-sm2a/airflow-standalone-task/"
  retention_in_days = 1
}

# A security group for our standalone tasks.
# We use this when making calls to the "run-task" API, not in our task definition.
resource "aws_security_group" "airflow_standalone_task" {
  name        = "${var.prefix}-standalone-task"
  description = "Deny all incoming traffic"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The standalone task template. Override container definition parameters like command,
# cpu and memory when making calls to the run-task API.
resource "aws_ecs_task_definition" "airflow_standalone_task" {
  family             = "${var.prefix}-standalone-task"
  cpu                = 256
  memory             = 512
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
      name        = "airflow"
      image       = join(":", [aws_ecr_repository.airflow.repository_url, "latest"])
      cpu         = 256
      memory      = 512
      essential   = true
      command     = ["version"]
      environment = var.airflow_task_common_environment
      user        = "50000:0"
      # Here is an example of how to forward logs to a sidecar fluentbit log router.
      # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/firelens-example-taskdefs.html#firelens-example-firehose
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_standalone_task.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "airflow-standalone-task"
        }
      }
    }
  ])
}
