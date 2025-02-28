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
# Variables
###############################
variable "bucket_name" {
  description = "The name of the S3 bucket (must be globally unique and lowercase)"
  default     = "twstorageazure"
}

###############################
# Create S3 Bucket (simulating the Azure Storage Account)
###############################
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"

  tags = {
    ResourceGroup = "myResourceGroup"
    Location      = "westeurope"
  }
}

###############################
# Upload Files as S3 Objects (simulating Azure Storage Blobs)
###############################
resource "aws_s3_object" "mustang_blob" {
  bucket = aws_s3_bucket.bucket.bucket
  key    = "Mustang_1.JPG"
  source = "C:/azure_bilder/Mustang_1.JPG"
  etag   = filemd5("C:/azure_bilder/Mustang_1.JPG")
}

resource "aws_s3_object" "trackhawk_blob" {
  bucket = aws_s3_bucket.bucket.bucket
  key    = "Trackhawk_2.jpg"
  source = "C:/azure_bilder/Trackhawk_2.jpg"
  etag   = filemd5("C:/azure_bilder/Trackhawk_2.jpg")
}

###############################
# Outputs
###############################
output "mustang_blob_url" {
  description = "URL for the Mustang blob"
  value       = "https://${aws_s3_bucket.bucket.bucket}.s3.amazonaws.com/${aws_s3_object.mustang_blob.key}"
}

output "trackhawk_blob_url" {
  description = "URL for the Trackhawk blob"
  value       = "https://${aws_s3_bucket.bucket.bucket}.s3.amazonaws.com/${aws_s3_object.trackhawk_blob.key}"
}
