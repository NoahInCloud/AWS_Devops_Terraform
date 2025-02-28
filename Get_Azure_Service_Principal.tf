terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust region as needed.
}

variable "role_name" {
  description = "The name of the IAM role representing the service principal"
  default     = "MyServiceRole"
}

data "aws_iam_role" "example" {
  name = var.role_name
}

output "example_service_principal" {
  description = "Details for the queried service principal (IAM role)"
  value = {
    name               = data.aws_iam_role.example.name
    arn                = data.aws_iam_role.example.arn
    assume_role_policy = data.aws_iam_role.example.assume_role_policy
    create_date        = data.aws_iam_role.example.create_date
  }
}
