# Define ECS Service AutoScaling Target
resource "aws_appautoscaling_target" "airflow_worker" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.airflow.name}/${aws_ecs_service.airflow_worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = var.desired_max_workers_count
}

# CPU Utilization Scaling Policy
resource "aws_appautoscaling_policy" "cpu_scale_up" {
  name                   = "${var.prefix}-cpu-scale-up"
  policy_type            = "StepScaling"
  resource_id            = aws_appautoscaling_target.airflow_worker.resource_id
  scalable_dimension     = aws_appautoscaling_target.airflow_worker.scalable_dimension
  service_namespace      = aws_appautoscaling_target.airflow_worker.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    # Step Adjustments
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}
resource "aws_cloudwatch_metric_alarm" "cpu_high_alarm" {
  alarm_name          = "${var.prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2  # Total periods to evaluate
  datapoints_to_alarm = 2  # Trigger alarm only if all 3 exceed the threshold
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 30  # Each period is 60 seconds
  statistic           = "Average"
  threshold           = 80  # CPU usage must exceed 80%
  dimensions = {
    ClusterName  = aws_ecs_cluster.airflow.name
    ServiceName  = aws_ecs_service.airflow_worker.name
  }
  alarm_actions = [aws_appautoscaling_policy.cpu_scale_up.arn]
}


# Memory Utilization Scaling Policy
resource "aws_appautoscaling_policy" "memory_scale_up" {
  name                   = "${var.prefix}-memory-scale-up"
  policy_type            = "StepScaling"
  resource_id            = aws_appautoscaling_target.airflow_worker.resource_id
  scalable_dimension     = aws_appautoscaling_target.airflow_worker.scalable_dimension
  service_namespace      = aws_appautoscaling_target.airflow_worker.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    # Step Adjustments
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high_alarm" {
  alarm_name          = "${var.prefix}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2  # Total periods to evaluate
  datapoints_to_alarm = 2  # Trigger alarm only if all 3 exceed the threshold
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 30
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    ClusterName  = aws_ecs_cluster.airflow.name
    ServiceName  = aws_ecs_service.airflow_worker.name
  }
  alarm_actions = [aws_appautoscaling_policy.memory_scale_up.arn]
}
