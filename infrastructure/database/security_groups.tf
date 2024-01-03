# A subnet group for our RDS instance.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group


resource "aws_db_subnet_group" "airflow_db" {
  name_prefix = "${var.prefix}-airflow-db-"
  # We are making it public to show the full potential of distributed system
  # To make it private use provate subnets here
  subnet_ids  = var.publicly_accessible ? var.public_subnet_ids : var.private_subnet_ids
}

# A security group to attach to our RDS instance.
# It should allow incoming access on var.db.port from our airflow services.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "airflow_db" {
  name_prefix = "${var.prefix}-airflow-db-"
  description = "Allow inbound traffic to RDS from ECS"
  vpc_id      = var.vpc_id
  ingress {
    from_port = var.airflow_db.port
    to_port   = var.airflow_db.port
    protocol  = "tcp"
    security_groups = var.allowed_security_groups_ids
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}