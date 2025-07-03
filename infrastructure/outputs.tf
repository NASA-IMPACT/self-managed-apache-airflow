output "private_subnets_id" {
  value = data.aws_subnets.private_subnets_id.ids
}

output "airflow_url" {
  value = module.ecs_services.airflow_url
}

output "database_endpoint" {
  value = module.database.database_endpoint
}

output "airflow_secret_name" {
  value = module.secrets.airflow_secrets
}

output "worker_security_group_id" {
  value = module.ecs_services.worker_security_group_id
}
