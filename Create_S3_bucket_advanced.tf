terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  # Set your AWS region (ensure this matches your desired region, e.g., "eu-west-1" for West Europe)
  region = var.location
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "The name of the resource group (simulated via tagging)"
  type        = string
}

variable "location" {
  description = "The AWS region (e.g., eu-west-1)"
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account to create. This will be used as the S3 bucket name and must be globally unique and lowercase."
  type        = string
}

###############################
# Create S3 Bucket (simulating the Azure Storage Account)
###############################
resource "aws_s3_bucket" "storage" {
  # Bucket names must be globally unique and lowercase.
  bucket = lower(var.storage_account_name)
  acl    = "private"

  tags = {
    ResourceGroup = var.resource_group_name
    Location      = var.location
  }
}

###############################
# Outputs
###############################
output "s3_bucket_url" {
  description = "The URL of the S3 bucket (use this along with your AWS credentials to access the bucket)"
  value       = "https://${aws_s3_bucket.storage.bucket}.s3.amazonaws.com"
}
