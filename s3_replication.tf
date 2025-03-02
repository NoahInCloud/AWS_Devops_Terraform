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
  region = "eu-west-1"  # Adjust to match your desired region.
}

###############################
# Variables
###############################
variable "rg_name" {
  description = "Resource group name (used for tagging)"
  type        = string
  default     = "ctt-prod-sta-rg"
}

variable "src_account_name" {
  description = "Name of the source storage account (S3 bucket)"
  type        = string
  default     = "cttprodsta2025"
}

variable "dest_account_name" {
  description = "Name of the destination storage account (S3 bucket)"
  type        = string
  default     = "cttsta4625"
}

variable "src_container_name1" {
  description = "Name of the first source container (simulated as key prefix)"
  type        = string
  default     = "source-container1"
}

variable "dest_container_name1" {
  description = "Name of the first destination container (informational)"
  type        = string
  default     = "dest-container1"
}

variable "src_container_name2" {
  description = "Name of the second source container (simulated as key prefix)"
  type        = string
  default     = "source-container2"
}

variable "dest_container_name2" {
  description = "Name of the second destination container (informational)"
  type        = string
  default     = "dest-container2"
}

###############################
# Source S3 Bucket (simulate source storage account)
###############################
resource "aws_s3_bucket" "src" {
  bucket = var.src_account_name
  acl    = "private"
  
  versioning {
    enabled = true
  }
  
  tags = {
    ResourceGroup = var.rg_name
    AccountType   = "Source"
  }
}

###############################
# Destination S3 Bucket (simulate destination storage account)
###############################
resource "aws_s3_bucket" "dest" {
  bucket = var.dest_account_name
  acl    = "private"
  
  versioning {
    enabled = true
  }
  
  tags = {
    ResourceGroup = var.rg_name
    AccountType   = "Destination"
  }
}

###############################
# IAM Role for Replication
###############################
resource "aws_iam_role" "replication_role" {
  name = "S3ReplicationRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  name = "S3ReplicationPolicy"
  role = aws_iam_role.replication_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.src.arn,
          "${aws_s3_bucket.src.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        Resource = [
          aws_s3_bucket.dest.arn,
          "${aws_s3_bucket.dest.arn}/*"
        ]
      }
    ]
  })
}

###############################
# S3 Replication Configuration on Source Bucket
###############################
resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.src.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "rule1"
    status = "Enabled"

    filter {
      prefix = "${var.src_container_name1}/"
    }

    destination {
      bucket = aws_s3_bucket.dest.arn
    }
  }

  rule {
    id     = "rule2"
    status = "Enabled"

    filter {
      prefix = "${var.src_container_name2}/"
    }

    destination {
      bucket = aws_s3_bucket.dest.arn
    }
  }
}

###############################
# Outputs
###############################
output "replication_policy_id" {
  description = "The ID of the S3 replication configuration (source bucket replication configuration)"
  value       = aws_s3_bucket_replication_configuration.replication.id
}
