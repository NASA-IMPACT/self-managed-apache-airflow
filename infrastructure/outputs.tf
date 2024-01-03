output "private_subnets_id" {
  value = data.aws_subnets.private_subnets_id.ids
}

output "airflow_url" {
  value = module.ecs_services.airflow_url
}

output "database_endpoint" {
  value = module.database.database_endpoint
}