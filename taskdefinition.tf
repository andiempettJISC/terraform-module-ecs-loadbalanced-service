resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.owner}-${var.app}-${var.environment}"
  requires_compatibilities = var.service_type == "EC2" ? [var.service_type] : ["FARGATE"]
  network_mode             = var.service_type == "EC2" ? "bridge" : "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory

  dynamic "runtime_platform" {
    for_each = var.architecture == "ARM" && var.service_type == "FARGATE" ? [1] : []
    content {
      cpu_architecture        = "ARM64"
      operating_system_family = "LINUX"
    }
  }

  # Read about the two iam roles for tasks here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
  # Summary: The task execution role is used to run (execute) the task.
  # Requirements like pulling from ECR, pulling secrets and running in a cluster
  # The Task role is the role assumed by the task container to access AWS resources the container app
  # needs. For example, Access to read from an s3 bucket, dynamodb etc.
  execution_role_arn = var.task_execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = templatefile("${path.root}/${var.taskdefinition_file_path}", {
    awslogs_group   = aws_cloudwatch_log_group.log_group.name,
    awslogs_region  = data.aws_region.current.name
    aws_account_id  = data.aws_caller_identity.current.account_id
    aws_region      = data.aws_region.current.name
    deployment_time = timestamp() # Mutates on each apply. allows for an always updating task definition.
  })

  dynamic "volume" {
    for_each = var.efs_volume_ids != null ? var.efs_volume_ids : {}
    content {
      name = "${var.owner}_${var.app}_${var.environment}_${volume.key}"
      efs_volume_configuration {
        file_system_id = volume.value
        transit_encryption = "ENABLED"
      }
    }
  }
}