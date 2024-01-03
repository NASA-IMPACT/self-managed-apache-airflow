output "celery_broker_url" {
  value = aws_sqs_queue.celery_broker.url
}

output "celery_broker_arn" {
  value = aws_sqs_queue.celery_broker.arn
}