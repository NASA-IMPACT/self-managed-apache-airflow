output "airflow_url" {
  value = aws_alb_listener.ecs-alb-https.arn
}

output "allowed_security_groups_id" {
  value = tolist([aws_security_group.airflow_webserver_service.id,
    aws_security_group.airflow_metrics_service.id,
    aws_security_group.airflow_standalone_task.id,
    aws_security_group.airflow_scheduler_service.id,
    aws_security_group.airflow_worker_service.id

  ])
}
