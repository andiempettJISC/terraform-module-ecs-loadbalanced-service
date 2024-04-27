output "target_group_arn" {
  value = var.create_loadbalancer ? aws_lb_target_group.target_group[0].arn : null
}

output "load_balancer_dns_name" {
  value = var.create_loadbalancer ? aws_lb.load_balancer[0].dns_name : null
}

output "application_url" {
  value = var.create_loadbalancer ? "https://${aws_route53_record.ec2_app_lb_record[0].fqdn}" : null
}

output "internal_application_url" {
  value = var.cluster_cloudmap_namespace_name != null ? "http://${var.app}.${var.cluster_cloudmap_namespace_name}" : null
}

output "full_internal_application_url" {
  value = var.cluster_cloudmap_namespace_name != null ? "http://${var.app}.${var.cluster_cloudmap_namespace_name}:${var.service_port}" : null
}

output "alb_security_group_id" {
  value = var.create_loadbalancer && var.loadbalancer_type == "application" ? aws_security_group.alb[0].id : null
}

output "service_security_group_id" {
  value = aws_security_group.internal.id
}