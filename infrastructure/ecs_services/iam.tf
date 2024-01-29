# A role to control Amazon ECS container agent permissions.
# This role is for the ECS container agent, not containerized applications.
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html#create-task-execution-role


# A role to control permissions of airflow service containers.
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_role_arn
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
resource "aws_iam_role" "airflow_task" {
  name_prefix = "${var.prefix}-airflow-task-"
  permissions_boundary = var.permission_boundaries_arn == "null" ? null : var.permission_boundaries_arn
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# Containers need this policy for usage with the CloudWatch agent.
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy_servicelens_CloudWatch_agent_deploy_ECS.html
data "aws_iam_policy" "cloud_watch_agent_server_policy" {
  name = "CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloud_watch_agent_server_policy" {
  role       = aws_iam_role.airflow_task.name
  policy_arn = data.aws_iam_policy.cloud_watch_agent_server_policy.arn
}

# Grant airflow tasks permissions required to read/write messages from the celery broker.

resource "aws_iam_policy" "airflow_sqs_read_write" {
  name_prefix = "${var.prefix}-sqs-read-write-"
  path        = "/"
  description = "Grants read/write permissions on all SQS queues"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes",
        ]
        Resource = var.sqs_arns_list
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "airflow_sqs_read_write" {
  role       = aws_iam_role.airflow_task.name
  policy_arn = aws_iam_policy.airflow_sqs_read_write.arn
}

# The ECS Exec feature requires a task IAM role to grant containers the permissions
# needed for communication between the managed SSM agent (execute-command agent) and the SSM service.
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html#ecs-exec-enabling-and-using
resource "aws_iam_policy" "ecs_task_ecs_exec" {
  name_prefix = "${var.prefix}-task-ecs-exec-"
  path        = "/"
  description = "Grant containers the permissions needed for communication between the managed SSM agent (execute-command agent) and the SSM service."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "airflow_ecs_exec" {
  role       = aws_iam_role.airflow_task.name
  policy_arn = aws_iam_policy.ecs_task_ecs_exec.arn
}






resource "aws_iam_policy" "secret_manager_read_secret" {
  name        = "${var.prefix}-secretManagerReadSecret"
  description = "Grants read, list and describe permissions on SecretManager secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Effect = "Allow"
        Resource = [
          var.fernet_key_ssm_arn,
          var.sql_alchemy_conn_ssm_arn,
          var.celery_result_backend_ssm_arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "airflow_read_secret" {
  role       = aws_iam_role.airflow_task.name
  policy_arn = aws_iam_policy.secret_manager_read_secret.arn
}

# Allow airflow services to access S3
# In a proction environment, one may want to limit access to a specific key.

resource "aws_iam_policy" "airflow_task_storage" {
  name_prefix = "${var.prefix}-task-storage-"
  path        = "/"
  description = ""
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        Resource = [
          var.airflow_bucket_arn,
          "${var.airflow_bucket_arn}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "airflow_task_storage" {
  role       = aws_iam_role.airflow_task.name
  policy_arn = aws_iam_policy.airflow_task_storage.arn
}

# Allow the airflow metrics service to fetch ECS service information and send metrics
# to CloudWatch. These permissions are only required by the metrics service; but to
# simplify the configuration for demonstration purposes, all airflow services get
# the same permissions.
resource "aws_iam_policy" "airflow_metrics" {
  name_prefix = "airflow-metrics-"
  path        = "/"
  description = "Grant permissions needed for metrics service to get service information from ECS and send metric data to cloudwatch."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "airflow_metrics" {
  role       = aws_iam_role.airflow_task.name
  policy_arn = aws_iam_policy.airflow_metrics.arn
}


resource "aws_iam_policy" "airflow_worker_policies" {
  name_prefix = "airflow-worker-"
  path        = "/"
  description = "Grant permissions needed for the worker."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat ([
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration",
          "s3:*",
          "secretsmanager:GetSecretValue",
          "ecs:*"
        ]
        Resource = "*"
      }
    ], var.custom_worker_policy_statement)
  })
}

resource "aws_iam_role_policy_attachment" "airflow_workers" {
  role       = aws_iam_role.airflow_task.name
  policy_arn = aws_iam_policy.airflow_worker_policies.arn
}

// =========


resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix = "${var.prefix}ecsTaskExecution"
  permissions_boundary = var.permission_boundaries_arn == "null" ? null : var.permission_boundaries_arn
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy" "amazon_ecs_task_execution_role_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.amazon_ecs_task_execution_role_policy.arn
}

# The task execution role also requires read access to SSM to fetch the Cloud Watch
# agent configuration
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy_servicelens_CloudWatch_agent_deploy_ECS.html
data "aws_iam_policy" "amazon_ssm_read_only_access" {
  name = "AmazonSSMReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "amazon_ssm_read_only_access_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.amazon_ssm_read_only_access.arn
}



