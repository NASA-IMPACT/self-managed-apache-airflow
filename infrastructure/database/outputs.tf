output "database_password" {
  value = aws_db_instance.airflow_db.password
}


output "database_endpoint" {
  value = aws_db_instance.airflow_db.endpoint
}