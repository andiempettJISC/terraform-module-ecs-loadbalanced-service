# Add data imported from existing sources.
# Example would be data lookups or cloudformation exports

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}