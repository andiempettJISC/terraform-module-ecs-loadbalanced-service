resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.owner}-${var.app}-${var.environment}"
  retention_in_days = var.log_retention
}