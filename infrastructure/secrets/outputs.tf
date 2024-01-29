output "sql_alchemy_conn_name" {
  value = aws_secretsmanager_secret.sql_alchemy_conn.name
}


output "fernet_key_name" {
  value = aws_secretsmanager_secret.fernet_key.name
}


output "celery_result_backend_name" {
  value = aws_secretsmanager_secret.celery_result_backend.name
}

output "celery_result_backend_arn" {
  value = aws_secretsmanager_secret.celery_result_backend.arn
}


output "sql_alchemy_conn_arn" {
  value = aws_secretsmanager_secret.sql_alchemy_conn.arn
}


output "fernet_key_arn" {
  value = aws_secretsmanager_secret.fernet_key.arn
}
output "airflow_secrets" {
  value = aws_secretsmanager_secret.airflow_secrets.name
}

