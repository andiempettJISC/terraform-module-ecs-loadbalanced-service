# Terraform Module ECS Load Balanced Service

A module to abstract the complexity of an ECS fargate or EC2 instance service

# Using The Terraform module

See [examples](./examples)

    module "cluster" {
        source = "github.com/example/terraform-module-ecs-loadbalanced-service?ref=v1.0.0"

        ...
        ...
    }


## Example Setup and deploy

[ECS cluster working example](./examples/service) is a working example.

then run the following:

    cd examples/service
    export AWS_REGION=eu-west-1
    export TF_WORKSPACE=dev
    terraform init

Then plan...

    terraform plan

...If the plan is successful apply.

    terraform apply

When you are finished destroy the resources

    terraform destroy

check the terraform state

    terraform state list
