resource "aws_lb" "load_balancer" {
  count = var.create_loadbalancer ? 1 : 0

  name               = "${var.owner}-${var.app}-${var.environment}"
  internal           = var.internal
  load_balancer_type = var.loadbalancer_type
  security_groups    = var.loadbalancer_type == "application" ? concat([aws_security_group.alb[0].id], var.ingress_additional_security_groups) : null
  subnets            = var.ingress_subnets

  enable_deletion_protection = var.environment == "prod" ? true : false

}

# lookup the NLB network interfaces. NLBs cant use security groups
data "aws_network_interface" "lb" {
  count = var.create_loadbalancer && var.loadbalancer_type == "network" ? length(var.ingress_subnets) : 0

  filter {
    name   = "description"
    values = ["ELB net/${aws_lb.load_balancer[0].name}/*"]
  }
  filter {
    name   = "subnet-id"
    values = [var.ingress_subnets[count.index]]
  }
}

resource "aws_lb_target_group" "target_group" {
  count = var.create_loadbalancer ? 1 : 0

  name                 = "${var.owner}-${var.app}-${var.environment}"
  port                 = var.service_port
  protocol             = var.loadbalancer_type == "application" ? "HTTP" : "TCP"
  target_type          = var.service_type == "EC2" ? "instance" : "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = var.deregistration_delay

  # https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#client-ip-preservation
  preserve_client_ip = var.loadbalancer_type == "network" ? (var.internal ? false : true) : null

  health_check {
    enabled  = true
    protocol = var.loadbalancer_type == "application" ? "HTTP" : "TCP"
    matcher  = var.loadbalancer_type == "application" ? var.health_check_ok_status_codes : null
    port = var.service_type == "EC2" ? null : (
      var.health_check_port == null ?
    var.service_port : var.health_check_port)
    healthy_threshold = var.health_check_healthy_threshold
    interval          = var.health_check_interval
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "listener" {
  count = var.create_loadbalancer ? 1 : 0

  load_balancer_arn = aws_lb.load_balancer[0].arn
  port              = var.loadbalancer_type == "application" ? "443" : var.service_port
  protocol          = var.loadbalancer_type == "application" ? "HTTPS" : "TCP"

  # Application: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies
  # Network: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-tls-listener.html#describe-ssl-policies
  ssl_policy      = var.loadbalancer_type == "application" ? "ELBSecurityPolicy-TLS13-1-2-2021-06" : null
  certificate_arn = var.loadbalancer_type == "application" ? aws_acm_certificate_validation.ec2_app_lb_cert_vaild[0].certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }

}

resource "aws_lb_listener" "redirect_listener" {
  count = var.create_loadbalancer && var.loadbalancer_type == "application" ? 1 : 0

  load_balancer_arn = aws_lb.load_balancer[0].arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

data "aws_route53_zone" "zone" {
  count = var.create_loadbalancer ? 1 : 0

  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "ec2_app_lb_cert" {
  count = var.create_loadbalancer && var.loadbalancer_type == "application" ? 1 : 0

  domain_name       = local.full_domain_name
  validation_method = "DNS"
}

resource "aws_route53_record" "ec2_app_cert_record" {
  for_each = var.create_loadbalancer && var.loadbalancer_type == "application" ? {
    for dvo in aws_acm_certificate.ec2_app_lb_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone[0].id
}

resource "aws_acm_certificate_validation" "ec2_app_lb_cert_vaild" {
  count = var.create_loadbalancer && var.loadbalancer_type == "application" ? 1 : 0

  certificate_arn         = aws_acm_certificate.ec2_app_lb_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.ec2_app_cert_record : record.fqdn]
}

resource "aws_route53_record" "ec2_app_lb_record" {
  count = var.create_loadbalancer ? 1 : 0

  zone_id = data.aws_route53_zone.zone[0].id
  name    = var.loadbalancer_type == "application" ? aws_acm_certificate.ec2_app_lb_cert[0].domain_name : local.full_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer[0].dns_name
    zone_id                = aws_lb.load_balancer[0].zone_id
    evaluate_target_health = false
  }
}
