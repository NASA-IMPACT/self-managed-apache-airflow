resource "aws_secretsmanager_secret" "fernet_key" {
  name_prefix = "${var.prefix}/airflow/config/fernet_key/"
}


resource "aws_secretsmanager_secret_version" "fernet_key" {
  secret_id     = aws_secretsmanager_secret.fernet_key.id
  secret_string = var.fernet_key
}

# Store core.sql_alchemy_conn setting for consumption by airflow SecretsManagerBackend.
# The config options must follow the config prefix naming convention defined within the secrets backend.
# This means that sql_alchemy_conn is not defined with a connection prefix, but with "config" prefix.
# https://airflow.apache.org/docs/apache-airflow/stable/howto/set-config.html

resource "aws_secretsmanager_secret" "sql_alchemy_conn" {
  name_prefix = "${var.prefix}/airflow/config/sql_alchemy_conn/"
}


resource "aws_secretsmanager_secret_version" "sql_alchemy_conn" {
  secret_id     = aws_secretsmanager_secret.sql_alchemy_conn.id
  secret_string = "postgresql+psycopg2://${var.db_username}:${var.db_password}@${var.db_endpoint}/${var.db_name}"
}

resource "aws_secretsmanager_secret" "celery_result_backend" {
  name_prefix = "${var.prefix}/airflow/config/celery_result_backend/"
}

resource "aws_secretsmanager_secret_version" "celery_result_backend" {
  secret_id     = aws_secretsmanager_secret.celery_result_backend.id
  secret_string = "db+postgresql://${var.db_username}:${var.db_password}@${var.db_endpoint}/${var.db_name}"
}

# This secret is for the Airflow DB and admin user.
resource "aws_secretsmanager_secret" "airflow_secrets" {
  name = "${var.prefix}-Airflow-master-secrets"
}

resource "aws_secretsmanager_secret_version" "airflow_secrets" {
  secret_id     = aws_secretsmanager_secret.airflow_secrets.id
  secret_string = <<EOF
   {
    "database_user": "${var.db_username}",
    "databse_password": "${var.db_password}",
    "databse_endpoint": "${var.db_endpoint}",
    "airflow_fernet_key": "${var.fernet_key}",
    "airflow_admin_username": "${var.airflow_admin_username}",
    "airflow_admin_password": "${var.airflow_admin_password}",
    "airflow_webserver_url": "${var.webserver_url}"
   }
EOF
}


# These secrets are values which are used by DAGs, but are sensitive and should not be passed through the container environment
resource "aws_secretsmanager_secret" "aws_dag_secrets" {
  name = "${var.prefix}/airflow/variables/aws_dags_variables"
}

resource "aws_secretsmanager_secret_version" "aws_dag_secrets" {
  secret_id     = aws_secretsmanager_secret.aws_dag_secrets.id
  secret_string = jsonencode(var.airflow_dag_secrets)
}