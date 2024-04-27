resource "aws_security_group" "alb" {
  count       = var.loadbalancer_type == "application" ? 1 : 0
  name        = "${var.owner}-${var.app}-${var.environment}-alb"
  description = "Allow https access to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow HTTPS access"
    from_port        = var.loadbalancer_type == "application" ? 443 : var.service_port
    to_port          = var.loadbalancer_type == "application" ? 443 : var.service_port
    protocol         = "tcp"
    cidr_blocks      = var.ingress_allow_ips
    ipv6_cidr_blocks = var.ingress_allow_ipv6
    security_groups  = var.ingress_allow_security_groups
  }

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.owner}-${var.app}-${var.environment}-alb"
  }
}

resource "aws_security_group" "internal" {
  name        = "${var.owner}-${var.app}-${var.environment}-internal"
  description = "Allow internal HTTP access from the ALB"
  vpc_id      = var.vpc_id

  # Fargate maps target group ports to container ports. 
  # ECS will dynamically assign ports to tasks on an instance in the target group
  # https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PortMapping.html
  ingress {
    description     = "Allow internal access from the api ALB to the tasks"
    from_port       = var.service_port
    to_port         = var.service_port
    protocol        = "tcp"
    cidr_blocks     = var.loadbalancer_type == "network" && var.create_loadbalancer ? concat(var.ingress_allow_ips, formatlist("%s/32", data.aws_network_interface.lb.*.private_ip)) : null # formatlist("%s/32", data.aws_network_interface.lb.*.private_ip)
    security_groups = local.app_internal_ingress_security_groups
  }

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.owner}-${var.app}-${var.environment}-internal"
  }
}