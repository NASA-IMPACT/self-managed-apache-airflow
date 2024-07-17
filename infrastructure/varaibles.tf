

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


variable "state_bucketname" {
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

variable "desired_max_workers_count" {
  default = "1"
}

variable "allowed_extra_security_groups_ids" {
  type    = list(string)
  default = []
}
variable "force_new_ecs_service_deployment" {
  type    = bool
  default = true
}
variable "extra_airflow_task_common_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "sqs_arns_list" {
  type    = list(string)
  default = []
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "rds_publicly_accessible" {
  type    = bool
  default = false
}

variable "rds_snapshot_identifier" {
  default = null
}


variable "airflow_admin_username" {

}
variable "airflow_admin_password" {

}
variable "airflow_admin_email" {
  default = null
}

variable "worker_cpu" {
  default = 4096
}
variable "worker_memory" {
  default = 4096 * 2
}

variable "custom_worker_policy_statement" {
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))
  default = []

}

variable "number_of_schedulers" {
  type    = number
  default = 1
}

variable "scheduler_cpu" {
  type    = number
  default = 1024
}
variable "scheduler_memory" {
  type    = number
  default = 2048
}

variable "contact" {
  default = "CSDA Admin"
}
variable "domain_name" {

}
variable "project" {
  default = "CSDA"
}
variable "stage" {

}

variable "worker_cmd" {
  type    = list(string)
  default = []
}

variable "subdomain" {
  default = "null"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}
variable "rds_max_allocated_storage" {
  type    = number
  default = 100
}

variable "extra_airflow_configuration" {
  type    = map(any)
  default = {}
}

variable "workers_logs_retention_days" {
  type = number
  default = 1
}



variable "airflow_custom_variables" {
  description = "Airflow custom variables"
  type        = map(string)
  default = {}
}

variable "infrastructure_foldername"{
  default = "infrastructure"
}