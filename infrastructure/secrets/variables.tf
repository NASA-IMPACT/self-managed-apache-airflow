variable "db_username" {
}

variable "db_password" {
}

variable "db_endpoint" {
}

variable "db_port" {
}

variable "db_name" {
}

variable "prefix" {
}

variable "fernet_key" {
}
variable "airflow_admin_username" {

}
variable "airflow_admin_password" {

}

variable "webserver_url" {
}

variable "airflow_dag_secrets" {
  description = "Airflow DAG secrets"
  type        = map(any)
}