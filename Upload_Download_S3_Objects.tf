terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"  # Similar to Azure's westeurope
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "Simulated resource group name (used for tagging)"
  type        = string
  default     = "myResourceGroup"
}

variable "location" {
  description = "AWS region (simulate Azure region)"
  type        = string
  default     = "eu-west-1"
}

variable "storage_account_name" {
  description = "Name of the S3 bucket (must be globally unique and lowercase)"
  type        = string
  default     = "tw75mystorageaccount"
}

variable "container_name" {
  description = "Name of the folder (simulating the storage container)"
  type        = string
  default     = "quickstartblobs"
}

###############################
# Create S3 Bucket (Simulating the Storage Account)
###############################
resource "aws_s3_bucket" "storage" {
  bucket = var.storage_account_name
  acl    = "private"

  versioning {
    enabled = false
  }

  tags = {
    ResourceGroup = var.resource_group_name
    Location      = var.location
  }
}

###############################
# Upload Blobs (Simulating Storage Blobs in a Container)
###############################
resource "aws_s3_object" "img1" {
  bucket = aws_s3_bucket.storage.bucket
  key    = "${var.container_name}/IMG_0498.jpg"
  source = "C:/Users/admin/Desktop/Bilder/IMG_0498.jpg"
  etag   = filemd5("C:/Users/admin/Desktop/Bilder/IMG_0498.jpg")
}

resource "aws_s3_object" "img2" {
  bucket = aws_s3_bucket.storage.bucket
  key    = "${var.container_name}/IMG_0406.jpg"
  source = "C:/Users/admin/Desktop/Bilder/IMG_0406.jpg"
  etag   = filemd5("C:/Users/admin/Desktop/Bilder/IMG_0406.jpg")
}

###############################
# Outputs
###############################
output "blob_names" {
  description = "Names of the blobs uploaded to the container (S3 object keys)"
  value       = [
    aws_s3_object.img1.key,
    aws_s3_object.img2.key
  ]
}
