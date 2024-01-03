resource "aws_security_group" "airflow_webserver_alb" {
  name_prefix = "airflow-webserver-alb-"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "airflow_webserver" {
  name               = "${var.prefix}-webserver"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.airflow_webserver_alb.id]
  subnets            = var.public_subnet_ids
  ip_address_type    = "ipv4"
}

# The webserver service target group to route traffic from the ALB listener to the
# webserver ECS service.
# The flow of traffic is:
#   Internet -> ALB -> Listener -> Target Group -> ECS Service
# Note: ECS registers targets automatically, so we do not need to define them.
resource "aws_lb_target_group" "airflow_webserver" {
  name        = "${var.prefix}-webserver"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    enabled = true
    path    = "/health"
    # Note: 'interval' must be greater than 'timeout'
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "airflow_webserver" {
  load_balancer_arn = aws_lb.airflow_webserver.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow_webserver.arn
  }
}

resource "aws_cloudwatch_log_group" "airflow_webserver" {
  name_prefix       = "/${var.prefix}/airflow-webserver/"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "airflow_webserver" {
  family             = "${var.prefix}-webserver"
  cpu                = 1024
  memory             = 2048
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.airflow_task.arn
  network_mode       = "awsvpc"
  runtime_platform {
    operating_system_family = "LINUX"
    # ARM64 currently does not work because of upstream dependencies
    # https://github.com/apache/airflow/issues/15635
    cpu_architecture = "X86_64"
  }
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name   = "webserver"
      image  = join(":", [aws_ecr_repository.airflow.repository_url, "latest"])
      cpu    = 1024
      memory = 2048
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      healthcheck = {
        command = [
          "CMD",
          "curl",
          "--fail",
          "http://localhost:8080/health"
        ]
        interval = 35
        timeout  = 30
        retries  = 5
      }
      linuxParameters = {
        initProcessEnabled = true
      }
      essential   = true
      command     = ["webserver"]
      environment = var.airflow_task_common_environment
      user        = "50000:0"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_webserver.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "airflow-webserver"
        }
      }
    }
  ])
}

resource "aws_security_group" "airflow_webserver_service" {
  name_prefix = "${var.prefix}-service-"
  description = "Allow HTTP inbound traffic from load balancer"
  vpc_id      = var.vpc_id
  ingress {
    description     = "HTTP from load balancer"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.airflow_webserver_alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "airflow_webserver" {
  depends_on = [ null_resource.build_ecr_image ,  aws_ecr_repository.airflow ]
  name = "webserver"
  # Note: If a revision number is not specified, the latest ACTIVE revision is used.
  task_definition = aws_ecs_task_definition.airflow_webserver.family
  cluster         = aws_ecs_cluster.airflow.arn
  deployment_controller {
    type = "ECS"
  }
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_execute_command = true
  launch_type            = "FARGATE"
  network_configuration {
    subnets = var.public_subnet_ids
    # In order for a Fargate task to pull the container image, it must either
    #  1. use a public subnet and be assigned a public IP address
    #  2. use a private subnet that has a route to the internet or a NAT gateway
    assign_public_ip = true
    security_groups  = [aws_security_group.airflow_webserver_service.id]
  }
  platform_version    = "1.4.0"
  scheduling_strategy = "REPLICA"
  force_new_deployment = var.force_new_ecs_service_deployment
  load_balancer {
    target_group_arn = aws_lb_target_group.airflow_webserver.arn
    container_name   = "webserver"
    container_port   = 8080
  }
  # This can be used to update tasks to use a newer container image with same
  # image/tag combination (e.g., myimage:latest)
}
