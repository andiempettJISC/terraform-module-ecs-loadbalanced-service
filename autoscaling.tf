resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.autoscaling_max != null ? 1 : 0
  max_capacity       = var.autoscaling_max != null ? var.autoscaling_max : var.desired_count
  min_capacity       = var.autoscaling_min != null ? var.autoscaling_min : var.desired_count
  resource_id        = "service/${local.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  count              = var.autoscaling_max != null ? 1 : 0
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = var.autoscaling_mem_threshold
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  count              = var.autoscaling_max != null ? 1 : 0
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = var.autoscaling_cpu_threshold
  }
}