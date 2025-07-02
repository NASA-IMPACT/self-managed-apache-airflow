output "airflow_url" {
  value = "${lower(local.subdomain)}.${var.domain_name}"
}

output "allowed_security_groups_id" {
  value = tolist([aws_security_group.airflow_webserver_service.id,
    aws_security_group.airflow_metrics_service.id,
    aws_security_group.airflow_standalone_task.id,
    aws_security_group.airflow_scheduler_service.id,
    aws_security_group.airflow_worker_service.id

  ])
}
output "worker_security_group_id" {
  value = aws_security_group.airflow_worker_service.id
}
