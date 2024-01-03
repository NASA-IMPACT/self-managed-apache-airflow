variable "aws_profile" {
  default = null
}

variable "aws_region" {
  default = "us-west-2"
}

variable "logging_level" {
  validation {
    condition     = contains(["info", "debug", "error"], var.logging_level)
    error_message = "Valid value is one of the following: info|debug|error"
  }
  default = "info"
}

variable "vpc_id" {
  type = string
}

variable "private_subnets_tagname" {
  description = "subnets tagname (accepts wild card *)"


}

variable "public_subnets_tagname" {
  description = "subnets tagname (accepts wild card *)"


}


variable "state_backetname" {
  description = "Bucket name without prefixing it with 's3://'. This bucket will be used to hold dags,logs and terraform states"
}

variable "prefix" {
  description = "Deployment prefix"
  type        = string
}

variable "airflow_db" {
  type = object({
    db_name  = string
    username = string
    password = string
    port     = number
  })
  sensitive = true
}

variable "fernet_key" {
}

variable "permission_boundaries_arn" {
  default = "null"
}

variable "rds_engine_version" {
  default = "13.12"
}

variable "rds_instance_class" {
  default = "db.t4g.medium"
}

variable "desired_workers_count" {
  default = "1"
}