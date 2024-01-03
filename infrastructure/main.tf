module "sqs_queue" {
  source = "./sqs"
  prefix = var.prefix
}


module "database" {
  source = "./database"

  account_id                  = local.account_id
  airflow_db                  = var.airflow_db
  allowed_security_groups_ids = module.ecs_services.allowed_security_groups_id
  aws_region                  = local.aws_region
  prefix                      = var.prefix
  private_subnet_ids          = data.aws_subnets.private_subnets_id.ids
  public_subnet_ids           = data.aws_subnets.public_subnets_id.ids
  publicly_accessible         = true
  rds_engine_version          = var.rds_engine_version
  rds_instance_class          = var.rds_instance_class
  snapshot_identifier         = null
  vpc_id                      = var.vpc_id
}




module "secrets" {
  source      = "./secrets"
  db_endpoint = module.database.database_endpoint
  db_name     = var.airflow_db.db_name
  db_password = module.database.database_password
  db_port     = var.airflow_db.port
  db_username = var.airflow_db.username
  fernet_key  = var.fernet_key
  prefix      = var.prefix
}

module "ecs_services" {
  source                           = "./ecs_services"
  account_id                       = local.account_id
  airflow_task_common_environment  = local.airflow_task_common_environment
  aws_region                       = local.aws_region
  desired_workers_count            = var.desired_workers_count
  force_new_ecs_service_deployment = true
  prefix                           = var.prefix
  private_subnet_ids               = data.aws_subnets.private_subnets_id.ids
  service_worker_name              = "airflow-worker"
  vpc_id                           = var.vpc_id
  airflow_bucket_arn               = data.aws_s3_bucket.airflow_bucket.arn
  celery_result_backend_ssm_arn    = module.secrets.celery_result_backend_arn
  fernet_key_ssm_arn               = module.secrets.fernet_key_arn
  permission_boundaries_arn        = var.permission_boundaries_arn
  sql_alchemy_conn_ssm_arn         = module.secrets.sql_alchemy_conn_arn
  sqs_arns_list                    = [module.sqs_queue.celery_broker_arn]
  public_subnet_ids                = data.aws_subnets.public_subnets_id.ids
}


