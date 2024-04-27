locals {
  cluster_arn       = var.cluster_arn
  cluster_name     = split("/", local.cluster_arn)[1]
  full_domain_name = var.create_loadbalancer ? (var.domain_use_root ? var.domain_name : (var.domain_prefix != null ? "${var.domain_prefix}.${var.domain_name}" : "${var.app}.${var.domain_name}")) : null

  app_allowed_sec_groups = var.loadbalancer_type == "application" ? (var.cluster_cloudmap_namespace_name != null ? concat([aws_security_group.alb[0].id], var.ingress_allow_security_groups) : [aws_security_group.alb[0].id]) : null

  app_internal_ingress_security_groups = var.loadbalancer_type == "application" ? local.app_allowed_sec_groups : var.ingress_allow_security_groups

  ordered_placement_strategys = {
    1 = {
      type  = "spread"
      field = "attribute:ecs.availability-zone"
    }
    2 = {
      type  = "binpack"
      field = "cpu"
    }
  }
}