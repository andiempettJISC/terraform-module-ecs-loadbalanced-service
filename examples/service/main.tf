# Add Terraform resources and modules here

locals {
  owner              = "example"
  app                = "nginx"
  env                = terraform.workspace
  public_subnet_ids  = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.owner}-${local.app}-${local.env}"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

}

module "ecs_cluster_fargate" {
  source          = "github.com/andiempettJISC/terraform-module-ecs-cluster?ref=v1.0.0"
  vpc_id          = local.vpc_id
  private_subnets = local.private_subnet_ids
  environment     = local.env
  owner           = local.owner
  enable_cloudmap   = true
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# Create ARM64 fargate service and tasks that are in private subnets only and can only be contacted within the VPC.
module "ecs_fargate_internal_cloudmap_arm_service" {
  source              = "../../."
  service_type        = "FARGATE"
  architecture        = "ARM"
  create_loadbalancer = false

  ingress_subnets = local.private_subnet_ids
  service_subnets = local.private_subnet_ids
  vpc_id          = local.vpc_id
  service_port    = 80
  cluster_arn     = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/example-dev"
  cpu             = 256
  memory          = 512
  desired_count   = 1
  log_retention   = 1

  task_execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  ingress_allow_security_groups   = [] # Set to allow external apps to communicate with tasks
  cluster_cloudmap_namespace_name = module.ecs_cluster_fargate.cloudmap_namespace_name

  taskdefinition_file_path = "taskdefinitions/${local.app}-${local.env}.json"

  environment = local.env
  owner       = local.owner
  app         = local.app

  depends_on = [ module.ecs_cluster_fargate ]

}

# Creare a service and task that are public fronted by an ALB
# module "ecs_fargate_loadbalanced_service" {
#   source              = "../../."
#   service_type        = "FARGATE"
#   create_loadbalancer = true
#   internal            = false
#   loadbalancer_type   = "application"

#   ingress_subnets = local.public_subnet_ids
#   service_subnets = local.private_subnet_ids
#   domain_name     = <SET DOMAIN NAME>
#   vpc_id          = local.vpc_id
#   service_port    = 80
#   cluster_arn     = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/example-dev"
#   cpu             = 256
#   memory          = 512
#   desired_count   = 1
#   log_retention   = 1

#   task_execution_role_arn = aws_iam_role.ecs_task_execution.arn

#   ingress_allow_ips               = ["${chomp(data.http.myip.response_body)}/32"]
#   ingress_allow_security_groups   = [] # Set to allow external apps to communicate with tasks
#   cluster_cloudmap_namespace_name = module.ecs_cluster_fargate.cloudmap_namespace_name

#   taskdefinition_file_path = "taskdefinitions/${local.app}-${local.env}.json"

#   environment = local.env
#   owner       = local.owner
#   app         = local.app

#   depends_on = [ module.ecs_cluster_fargate ]

# }