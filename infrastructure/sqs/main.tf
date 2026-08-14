# Using Amazon SQS as celery broker
# https://docs.celeryproject.org/en/stable/getting-started/backends-and-brokers/sqs.html
resource "aws_sqs_queue" "celery_broker" {
  name_prefix = "${var.prefix}-celery-broker-"

  # Must exceed the runtime of the longest Airflow task. When SQS makes a message
  # visible again while its task is still running, the message is redelivered and a
  # second worker attempts to start the same task instance. On Airflow 3 the Task
  # Execution API rejects that second start with `invalid_state`, the Celery executor
  # reports the task as failed, and the scheduler then kills the healthy original run.
  # The task fails despite never having errored.
  #
  # This must be set here rather than through celery's broker_transport_options: the
  # Airflow config uses `predefined_queues`, so kombu does not create the queue and
  # the queue's own attribute is what governs redelivery.
  visibility_timeout_seconds = var.visibility_timeout_seconds
}
