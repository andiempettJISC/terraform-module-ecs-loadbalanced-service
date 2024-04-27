terraform {
  required_version = ">= 1.0.0"
  # backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  access_key                  = terraform.workspace == "local" ? "fake" : null
  secret_key                  = terraform.workspace == "local" ? "fake" : null
  skip_credentials_validation = terraform.workspace == "local" ? true : false
  skip_metadata_api_check     = terraform.workspace == "local" ? true : false
  skip_requesting_account_id  = terraform.workspace == "local" ? true : false

  s3_use_path_style = terraform.workspace == "local" ? true : false

  default_tags {
    tags = {
      Environment = terraform.workspace
      Application = basename(abspath("${path.root}/"))
      Owner       = local.owner
      ManagedBy   = "terraform"
    }
  }

  endpoints {
    lambda           = terraform.workspace == "local" ? "http://localhost:4566" : null
    s3               = terraform.workspace == "local" ? "http://localhost:4566" : null
    iam              = terraform.workspace == "local" ? "http://localhost:4566" : null
    cloudwatch       = terraform.workspace == "local" ? "http://localhost:4566" : null
    cloudwatchlogs   = terraform.workspace == "local" ? "http://localhost:4566" : null
    sqs              = terraform.workspace == "local" ? "http://localhost:4566" : null
    apigateway       = terraform.workspace == "local" ? "http://localhost:4566" : null
    sts              = terraform.workspace == "local" ? "http://localhost:4566" : null
    cloudwatchevents = terraform.workspace == "local" ? "http://localhost:4566" : null
    elasticsearch    = terraform.workspace == "local" ? "http://localhost:4566" : null
    ec2              = terraform.workspace == "local" ? "http://localhost:4566" : null
    es               = terraform.workspace == "local" ? "http://localhost:4566" : null
    sns              = terraform.workspace == "local" ? "http://localhost:4566" : null
    kms              = terraform.workspace == "local" ? "http://localhost:4566" : null
    ssm              = terraform.workspace == "local" ? "http://localhost:4566" : null
  }
}