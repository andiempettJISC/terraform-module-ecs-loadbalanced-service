variable "owner" {

}

variable "app" {

}

variable "environment" {

}

variable "domain_name" {
  default = null
  nullable = true
}

variable "domain_prefix" {
  default = null
}

variable "domain_use_root" {
  default = false
  type    = bool
}

variable "service_port" {

}

variable "health_check_port" {
  default = null
}

variable "health_check_interval" {
  description = "Determines the approximate amount of time, in seconds, between health checks of an individual container."
  default     = null
}

variable "health_check_healthy_threshold" {
  description = "Determines the number of consecutive health check successes required before considering an unhealthy container healthy."
  default     = null
}

variable "health_check_ok_status_codes" {
  default = "200"
}

variable "health_check_grace_period" {
  default     = null
  description = "The period of time, in seconds, that the Amazon ECS service scheduler should ignore unhealthy Elastic Load Balancing target health checks, container health checks, and Route 53 health checks after a task enters a RUNNING state."
}

variable "deregistration_delay" {
  description = "The time in seconds a draining task waits until its full deregisted and client connections are terminated."
  default     = "180"
  type        = string
}

variable "ingress_subnets" {

}

variable "service_subnets" {

}

variable "vpc_id" {

}

variable "service_type" {
  type        = string
  description = "Choose if this load balancer will be used by EC2 or Fargate service"
  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT", "EC2"], var.service_type)
    error_message = "Must be either FARGATE or EC2 service type."
  }
}

variable "service_additional_security_groups" {
  type        = list(string)
  default     = []
  description = "A list of existing additional security groups to add to the application service. They may grant access to resources like databases controlled outside this stack."
}

variable "ingress_additional_security_groups" {
  type        = list(string)
  default     = []
  description = "A list of existing additional security groups to add to the application load balancer (If one is created)."
}

variable "internal" {
  default = true
}

variable "ecs_instance_capacity_provider_name" {
  default = null
}

variable "desired_count" {

}

variable "cluster_arn" {

}

variable "cpu" {

}

variable "memory" {

}

variable "task_execution_role_arn" {

}

variable "task_role_arn" {
  default = null
}

variable "log_retention" {
  default = 1
}

variable "taskdefinition_file_path" {

}

variable "force_new_deployment" {
  default = false
}

variable "ingress_allow_ips" {
  default = []
}

variable "ingress_allow_ipv6" {
  default = null
}

variable "ingress_allow_security_groups" {
  default = []
}

variable "cluster_cloudmap_namespace_name" {
  default = null
}

variable "loadbalancer_type" {
  default     = "application"
  type        = string
  description = "Choose if this load balancer is and ALB or NLB"
  validation {
    condition     = contains(["application", "network"], var.loadbalancer_type)
    error_message = "Must be either application or network loadbalancer type."
  }
}

variable "architecture" {
  default     = "STANDARD"
  type        = string
  description = "Choose the task definition architecture."
  validation {
    condition     = contains(["STANDARD", "ARM"], var.architecture)
    error_message = "The container must use either AMD64 or ARM64 architecture."
  }
}

variable "create_loadbalancer" {
  default     = true
  type        = bool
  description = "Conditionally create a loadbalancer"
}

variable "autoscaling_min" {
  default = null
}

variable "autoscaling_max" {
  default = null
}

variable "autoscaling_cpu_threshold" {
  default = 70
}

variable "autoscaling_mem_threshold" {
  default = 90
}

variable "efs_volume_ids" {
  nullable = true
  default = {}
}