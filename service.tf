resource "aws_ecs_service" "service" {
  name                    = "${var.owner}-${var.app}-${var.environment}"
  cluster                 = local.cluster_arn
  task_definition         = aws_ecs_task_definition.task_definition.arn
  desired_count           = var.desired_count
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"
  enable_execute_command = true


  # force a new deployment without a change
  force_new_deployment = var.force_new_deployment

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = var.health_check_grace_period

  dynamic "service_registries" {
    for_each = var.cluster_cloudmap_namespace_name != null ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.service[0].arn
    }
  }

  dynamic "network_configuration" {
    for_each = var.service_type == "EC2" ? [] : [1]
    content {
      assign_public_ip = false
      subnets          = var.service_subnets
      security_groups  = concat([aws_security_group.internal.id], var.service_additional_security_groups)
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.service_type == "EC2" ? local.ordered_placement_strategys : {}
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  capacity_provider_strategy {
    # EC2 capacity provider is by default based on naming convention but may passed in as a var
    capacity_provider = var.service_type == "EC2" ? (
      var.ecs_instance_capacity_provider_name != null ?
      var.ecs_instance_capacity_provider_name : "${var.owner}-${var.environment}"
    ) : var.service_type
    weight = 100
    base   = var.desired_count
  }
  dynamic "load_balancer" {
    for_each = var.create_loadbalancer ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.target_group[0].arn
      container_name   = var.app
      container_port   = var.service_port
    }
  }

  lifecycle {
    ignore_changes = [desired_count] # task_definition
  }
}