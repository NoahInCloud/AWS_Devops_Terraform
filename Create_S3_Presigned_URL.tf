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
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
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
  default     = "twstorage75"
}

variable "container_name" {
  description = "Name of the folder (simulating a storage container)"
  default     = "bilder"
}

variable "blob_name" {
  description = "Name of the blob (object) to be uploaded"
  default     = "test.txt"
}

variable "presign_expiry" {
  description = "Expiry time in seconds for the pre-signed URL"
  default     = 3600
}

###############################
# Create a local file with current timestamp
###############################
resource "local_file" "test_file" {
  content  = timestamp()
  filename = "C:/Temp/test.txt"
}

###############################
# Create an S3 Bucket (simulating a Storage Account)
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
# Upload the local file as an S3 Object (simulating a blob)
###############################
resource "aws_s3_object" "blob" {
  bucket = aws_s3_bucket.bucket.bucket
  key    = "${var.container_name}/${var.blob_name}"
  source = local_file.test_file.filename
  etag   = filemd5(local_file.test_file.filename)
}

###############################
# Generate a Pre-Signed URL for the uploaded object
###############################
data "external" "presigned_url" {
  program = ["python3", "${path.module}/get_presigned_url.py"]
  query = {
    bucket = aws_s3_bucket.bucket.bucket
    key    = aws_s3_object.blob.key
    expiry = var.presign_expiry
  }
}

###############################
# Outputs
###############################
output "bucket_info" {
  description = "The name of the created S3 bucket (simulating the Storage Account)"
  value       = aws_s3_bucket.bucket.bucket
}

output "object_url" {
  description = "The public URL for the S3 object (non-presigned)"
  value       = "https://${aws_s3_bucket.bucket.bucket}.s3.amazonaws.com/${aws_s3_object.blob.key}"
}

output "presigned_url" {
  description = "The pre-signed URL for the uploaded object (simulating a SAS token)"
  value       = data.external.presigned_url.result.url
}
