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
# Variables and Random ID
###############################
variable "prefix" {
  description = "Prefix for resource names"
  default     = "tw"
}

variable "location" {
  description = "AWS region"
  default     = "eu-west-1"
}

resource "random_integer" "id" {
  min = 1000
  max = 9999
}

locals {
  # In Azure, you create a resource group with a generated name.
  # AWS does not have resource groups in the same way, so we simulate it using tags.
  resource_group_name  = "${var.prefix}-rg-${random_integer.id.result}"
  # Storage account names in Azure must be lowercase and unique.
  # For AWS S3 buckets, the bucket name must also be globally unique and lowercase.
  storage_account_name = lower("${var.prefix}sa${random_integer.id.result}")
}

###############################
# Create an S3 Bucket (simulating an Azure Storage Account)
###############################
resource "aws_s3_bucket" "storage" {
  bucket = local.storage_account_name
  acl    = "private"

  tags = {
    ResourceGroup = local.resource_group_name
    Environment   = "Production"  # Customize as needed
  }

  # Note: AWS S3 automatically provides high durability and availability.
  # To simulate geo-redundancy similar to RAGRS, you might configure cross-region replication,
  # but that requires additional resources (like a replication configuration and IAM role).
}

###############################
# Outputs
###############################
output "resource_group_name" {
  description = "The simulated resource group name (from naming convention and tagging)"
  value       = local.resource_group_name
}

output "storage_account_name" {
  description = "The name of the created S3 bucket (simulating the Azure Storage Account)"
  value       = aws_s3_bucket.storage.bucket
}
