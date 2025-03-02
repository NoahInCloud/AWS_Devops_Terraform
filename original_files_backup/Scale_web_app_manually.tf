terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"  # Similar to Azure's "westeurope"
}

###############################
# Generate Random Suffix (8 hex characters)
###############################
resource "random_id" "rand_suffix" {
  byte_length = 4
}

###############################
# Simulated Resource Group (for tagging)
###############################
locals {
  resource_group_name = "myResourceGroup${random_id.rand_suffix.hex}"
}

###############################
# Elastic Beanstalk Application (equivalent to App Service Plan / Web App)
###############################
resource "aws_elastic_beanstalk_application" "app" {
  name        = "AppServiceManualScale${random_id.rand_suffix.hex}"
  description = "Elastic Beanstalk application equivalent to Azure Web App"
  tags = {
    ResourceGroup = local.resource_group_name
  }
}

###############################
# Elastic Beanstalk Environment (deploys the web app)
###############################
resource "aws_elastic_beanstalk_environment" "env" {
  name                = "env-${random_id.rand_suffix.hex}"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.6 running Python 3.8"  # Adjust to your platform as needed

  # Example setting: use a LoadBalanced environment
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  tags = {
    ResourceGroup = local.resource_group_name
  }
}

###############################
# Outputs
###############################
output "resource_group_name" {
  description = "Simulated resource group name"
  value       = local.resource_group_name
}

output "app_service_plan_id" {
  description = "The ID of the Elastic Beanstalk application (analogous to an App Service Plan)"
  value       = aws_elastic_beanstalk_application.app.id
}

output "web_app_url" {
  description = "The default URL of the Elastic Beanstalk environment (web app endpoint)"
  value       = aws_elastic_beanstalk_environment.env.endpoint_url
}
