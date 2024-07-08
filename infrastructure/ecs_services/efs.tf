#####
# EFS
#####

locals {
  task_security_group_ids = [
    aws_security_group.airflow_worker_service.id,
    aws_security_group.airflow_scheduler_service.id,
    aws_security_group.airflow_standalone_task.id,
    aws_security_group.airflow_metrics_service.id,
    aws_security_group.airflow_webserver_service.id
  ]
}
resource "aws_efs_file_system" "efs" {
  creation_token = "${var.prefix}-efs"

  tags = {
    Name = "${var.prefix}-efs"
  }
}

resource "aws_efs_access_point" "access" {
  file_system_id = aws_efs_file_system.efs.id
    posix_user {
    uid = 50000
    gid = 0
  }
  root_directory {
    path = "/mnt/data"
    creation_info {
      owner_uid = 50000
      owner_gid = 0
      permissions = 777
    }
  }
}

resource "aws_security_group" "efs" {
  name   = "${var.prefix}-efs-sg"
  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 2999
    to_port         = 2999
    security_groups = local.task_security_group_ids
    cidr_blocks     = var.efs_allowed_cider_block
  }
  ingress {
    description = "NFS traffic from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = var.efs_allowed_cider_block
  }
}
resource "aws_efs_mount_target" "mount" {
  count = 2
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}