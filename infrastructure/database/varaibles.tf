variable "airflow_db" {
  type = object({
    db_name  = string
    username = string
    password = string
    port     = number
  })
  sensitive = true
}
variable "publicly_accessible" {
  type = bool
}
variable "prefix" {

}

variable "rds_engine_version" {

}
variable "rds_instance_class" {

}
variable "aws_region" {

}
variable "account_id" {

}
variable "snapshot_identifier" {

}
variable "vpc_id" {

}
variable "allowed_security_groups_ids" {
  type = list(string)

}

variable "public_subnet_ids" {

}
variable "private_subnet_ids" {

}

variable "allowed_cidr_blocks" {
  type = list(string)
}

variable "db_allocated_storage" {
  type = number
}
variable "db_max_allocated_storage" {
  type = number
}