variable "prefix" {
}

variable "aws_region" {
}
variable "account_id" {
}
variable "permission_boundaries_arn" {

}
variable "private_subnet_ids" {
  type = list(string)

}

variable "sqs_arns_list" {
  type = list(string)
}

variable "vpc_id" {
}
variable "force_new_ecs_service_deployment" {

}

variable "service_worker_name" {

}
variable "desired_max_workers_count" {

}
variable "airflow_task_common_environment" {

}

# Allow ECS services to read secrets from AWS Secret Manager.
variable "fernet_key_ssm_arn" {

}
variable "sql_alchemy_conn_ssm_arn" {
}
variable "celery_result_backend_ssm_arn" {
}

variable "airflow_bucket_arn" {
}

variable "public_subnet_ids" {
}

variable "worker_cpu" {

}
variable "worker_memory" {

}

variable "custom_worker_policy_statement" {
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))

}

variable "number_of_schedulers" {
  type = number
}

variable "scheduler_cpu" {

  type = number
}
variable "scheduler_memory" {
  type = number

}

variable "domain_name" {
  type = string
}

variable "stage" {

}

variable "contact" {

}
variable "project" {

}

variable "worker_cmd" {
  type = list(string)
}

variable "subdomain" {
}

variable "workers_logs_retention_days" {
  type = number
}
variable "task_cpu_architecture" {

}