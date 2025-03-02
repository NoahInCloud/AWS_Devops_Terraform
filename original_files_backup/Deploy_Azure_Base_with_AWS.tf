terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.location
}

###############################
# Variables
###############################
variable "stack_name" {
  description = "The name of the CloudFormation stack"
  type        = string
  default     = "base-aws-deployment"
}

variable "location" {
  description = "AWS region (e.g. us-east-1, eu-west-1)"
  type        = string
  default     = "eu-west-1"
}

###############################
# Fetch the CloudFormation Template from GitHub
###############################
data "http" "cf_template" {
  # Replace the URL with the location of your CloudFormation template
  url = "https://raw.githubusercontent.com/your-repo/your-template.yaml"
}

###############################
# Deploy the CloudFormation Template
###############################
resource "aws_cloudformation_stack" "base_deployment" {
  name          = var.stack_name
  template_body = data.http.cf_template.body

  # Uncomment and adjust the following if your template requires parameters:
  # parameters = {
  #   ParameterKey1 = "Value1"
  #   ParameterKey2 = "Value2"
  # }

  # If your template creates IAM resources, you may need to acknowledge capabilities:
  capabilities = ["CAPABILITY_NAMED_IAM"]
}

###############################
# Outputs
###############################
output "stack_id" {
  description = "The ID of the deployed CloudFormation stack"
  value       = aws_cloudformation_stack.base_deployment.id
}
