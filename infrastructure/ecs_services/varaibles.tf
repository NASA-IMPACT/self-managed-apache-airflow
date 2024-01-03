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
variable "desired_workers_count" {
  
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