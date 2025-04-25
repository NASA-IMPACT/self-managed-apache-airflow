module "sqs_queue" {
  source = "./sqs"
  prefix = var.prefix
}



module "database" {
  source = "./database"

  account_id                  = local.account_id
  airflow_db                  = var.airflow_db
  allowed_security_groups_ids = concat(var.allowed_extra_security_groups_ids, module.ecs_services.allowed_security_groups_id)
  aws_region                  = local.aws_region
  prefix                      = var.prefix
  private_subnet_ids          = data.aws_subnets.private_subnets_id.ids
  public_subnet_ids           = data.aws_subnets.public_subnets_id.ids
  publicly_accessible         = var.rds_publicly_accessible
  rds_engine_version          = var.rds_engine_version
  rds_instance_class          = var.rds_instance_class
  snapshot_identifier         = var.rds_snapshot_identifier
  vpc_id                      = var.vpc_id
  allowed_cidr_blocks         = var.allowed_cidr_blocks
  db_allocated_storage        = var.rds_allocated_storage
  db_max_allocated_storage    = var.rds_max_allocated_storage
  backup_retention_period     = var.backup_retention_period
}




module "secrets" {
  source                   = "./secrets"
  db_endpoint              = module.database.database_endpoint
  db_name                  = var.airflow_db.db_name
  db_password              = module.database.database_password
  db_port                  = var.airflow_db.port
  db_username              = var.airflow_db.username
  fernet_key               = var.fernet_key
  prefix                   = var.prefix
  airflow_admin_username   = var.airflow_admin_username
  airflow_admin_password   = var.airflow_admin_password
  webserver_url            = module.ecs_services.airflow_url
  airflow_dag_secrets = merge({ db_secret_name = module.secrets.airflow_secrets }, var.airflow_dag_secrets, var.airflow_custom_variables)
}



resource "local_file" "airflow_configuration" {

  content = templatefile("${path.root}/configuration/airflow.cfg.tmpl",
    merge({
      prefix = var.prefix
      },
      var.extra_airflow_configuration
    )


  )
  filename = "../${path.root}/${var.infrastructure_foldername}/configuration/airflow.cfg"
}



module "ecs_services" {
  source                           = "./ecs_services"
  depends_on                       = [local_file.airflow_configuration]
  account_id                       = local.account_id
  airflow_task_common_environment  = local.airflow_task_common_environment
  aws_region                       = local.aws_region
  desired_max_workers_count        = var.desired_max_workers_count
  force_new_ecs_service_deployment = var.force_new_ecs_service_deployment
  prefix                           = var.prefix
  private_subnet_ids               = data.aws_subnets.private_subnets_id.ids
  service_worker_name              = "airflow-worker"
  vpc_id                           = var.vpc_id
  airflow_bucket_arn               = data.aws_s3_bucket.airflow_bucket.arn
  celery_result_backend_ssm_arn    = module.secrets.celery_result_backend_arn
  fernet_key_ssm_arn               = module.secrets.fernet_key_arn
  permission_boundaries_arn        = var.permission_boundaries_arn
  sql_alchemy_conn_ssm_arn         = module.secrets.sql_alchemy_conn_arn
  sqs_arns_list                    = concat(var.sqs_arns_list, [module.sqs_queue.celery_broker_arn])
  public_subnet_ids                = data.aws_subnets.public_subnets_id.ids
  worker_cpu                       = var.worker_cpu
  worker_memory                    = var.worker_memory

  custom_worker_policy_statement = var.custom_worker_policy_statement
  number_of_schedulers           = var.number_of_schedulers
  scheduler_memory               = var.scheduler_memory
  scheduler_cpu                  = var.scheduler_cpu
  contact                        = var.contact
  domain_name                    = var.domain_name
  project                        = var.project
  stage                          = var.stage
  worker_cmd                     = var.worker_cmd
  subdomain                      = var.subdomain
  workers_logs_retention_days    = var.workers_logs_retention_days
  task_cpu_architecture          = var.task_cpu_architecture
}

resource "null_resource" "airflow_create_airflow_user" {
  depends_on = [module.ecs_services, module.database]
  triggers = {
    admin_password = var.airflow_admin_password
    admin_username = var.airflow_admin_username
  }

  provisioner "local-exec" {
    command = <<EOF
        python ${path.root}/../scripts/run_task.py --wait-tasks-stopped --command "db init"
        python ${path.root}/../scripts/run_task.py --wait-tasks-stopped --command  "users create --username ${var.airflow_admin_username} --firstname ${var.airflow_admin_username} --lastname ${var.airflow_admin_username} --password ${var.airflow_admin_password} --email ${local.airflow_admin_email} --role Admin"
       EOF
  }
}


