variable "prefix" {}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the celery broker queue, in seconds. Must exceed the runtime of the longest Airflow task."
  type        = number
  default     = 1800
}
