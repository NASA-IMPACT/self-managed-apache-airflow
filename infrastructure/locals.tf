locals {
  aws_region          = data.aws_region.current.name
  account_id          = data.aws_caller_identity.current.account_id
  airflow_admin_email = var.airflow_admin_email != null ? var.airflow_admin_email : "${var.airflow_admin_username}@airflow.com"

  airflow_dag_variables = {
    # for each value in the map var.airflow_dag_variables, create a new key-value pair
    # where the key is "AIRFLOW_VAR_" + the value of the map and the value is the value of the map
    # to be loaded into the environment
    for k, v in var.airflow_dag_variables : "AIRFLOW_VAR_${k}" => v
  }

  airflow_task_common_environment = concat(var.extra_airflow_task_common_environment, [
    {
      name  = "AIRFLOW__WEBSERVER__INSTANCE_NAME"
      value = "${var.prefix}-${var.project}"
    },
    {
      name  = "AIRFLOW__LOGGING__LOGGING_LEVEL"
      value = upper(var.logging_level)
    },
    {
      name  = "AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER"
      value = "s3://${var.state_bucketname}/remote_base_log_folder/"
    },
    {
      name  = "X_AIRFLOW_SQS_CELERY_BROKER_PREDEFINED_QUEUE_URL"
      value = module.sqs_queue.celery_broker_url
    },
    # Use the Amazon SecretsManagerBackend to retrieve secret configuration values at
    # runtime from Secret Manager. Only the *name* of the secret is needed here, so an
    # environment variable is acceptable.
    # Another option would be to specify the secret values directly as environment
    # variables using the Task Definition "secrets" attribute. In that case, one would
    # instead set "valueFrom" to the secret ARN (eg. aws_secretsmanager_secret.sql_alchemy_conn.arn)
    {
      name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN_SECRET"
      # Remove the "config_prefix" using `substr`
      value = substr(module.secrets.sql_alchemy_conn_name, length(var.prefix) + 16, -1)

    },
    {
      name  = "AIRFLOW__CORE__FERNET_KEY_SECRET"
      value = substr(module.secrets.fernet_key_name, length(var.prefix) + 16, -1)
    },
    {
      name  = "AIRFLOW__CELERY__RESULT_BACKEND_SECRET"
      value = substr(module.secrets.celery_result_backend_name, length(var.prefix) + 16, -1)
    },
    {
      # Note: Even if one sets this to "True" in airflow.cfg a hidden environment
      # variable overrides it to False
      name  = "AIRFLOW__CORE__LOAD_EXAMPLES"
      value = "false"
    }

  ])

  airflow_cloud_watch_metrics_namespace = "${var.prefix}-SM2A"
}