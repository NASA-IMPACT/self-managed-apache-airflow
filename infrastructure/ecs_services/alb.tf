
locals {
  subdomain = var.subdomain == "null" ? var.stage : var.subdomain
}

resource "aws_alb" "airflow_webserver" {
  name               = "${var.prefix}-webserver"
  internal           = false
  security_groups    = [aws_security_group.airflow_webserver_alb.id]
  subnets            = var.public_subnet_ids
    tags = {
      Contact = var.contact
      Project = var.project
  }
}

resource "aws_route53_record" "ecs-alb-record" {
  name    = "${lower(local.subdomain)}.${var.domain_name}"
  type    = "A"
  zone_id = data.aws_route53_zone.ecs_domain.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_alb.airflow_webserver.dns_name
    zone_id                = aws_alb.airflow_webserver.zone_id
  }
}

resource "aws_alb_target_group" "ecs-default-target-grp" {
  name     = "${var.prefix}-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags = {
      Contact = var.contact
      Project = var.project
  }
}

resource "aws_alb_listener" "ecs-alb-https" {
  load_balancer_arn = aws_alb.airflow_webserver.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.ecs-domain-certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs-default-target-grp.arn
  }

  depends_on = [aws_alb_target_group.ecs-default-target-grp]
}




resource "aws_alb_target_group" "ecs-app-target-group" {
  name = "${var.prefix}-app-tg"
  port = 8080 # docker port
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "ip"
  health_check {
    enabled = true
    path    = "/health"
    # Note: 'interval' must be greater than 'timeout'
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 5
  }

  tags = {
      Contact = var.contact
      Project = var.project
  }
}



resource "aws_alb_listener_rule" "ecs-alb-listener-role" {
  listener_arn = aws_alb_listener.ecs-alb-https.arn
  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.ecs-app-target-group.arn
  }
  condition {
    host_header {
      values = ["${lower(local.subdomain)}.${var.domain_name}"]
    }
  }
}



resource "aws_security_group" "airflow_webserver_alb" {
  name_prefix = "${var.prefix}-webserver-alb-"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
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






