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
  region = "us-east-1"  # Adjust as needed.
}

# Generate a random UUID for the custom policy name
resource "random_uuid" "vm_reader_policy_id" {}

# Create a custom IAM policy that grants read-only access (simulating "VM Reader")
resource "aws_iam_policy" "vm_reader" {
  name        = "VMReader-${random_uuid.vm_reader_policy_id.result}"
  description = "Custom policy to allow read-only access to EC2, VPC, and S3 resources."
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "EC2ReadOnly",
        "Effect": "Allow",
        "Action": "ec2:Describe*",
        "Resource": "*"
      },
      {
        "Sid": "VPCReadOnly",
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeSecurityGroups"
        ],
        "Resource": "*"
      },
      {
        "Sid": "S3ReadOnly",
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject"
        ],
        "Resource": "*"
      }
    ]
  })
}

# Look up the target IAM user (ensure this user exists in your account)
data "aws_iam_user" "target" {
  user_name = "Noah@example.io"  # Replace with the actual IAM user name.
}

# Attach the custom policy to the target user
resource "aws_iam_user_policy_attachment" "attach_vm_reader" {
  user       = data.aws_iam_user.target.user_name
  policy_arn = aws_iam_policy.vm_reader.arn
}

output "vm_reader_policy_id" {
  description = "The ID of the custom VM Reader policy."
  value       = aws_iam_policy.vm_reader.id
}

output "assigned_user" {
  description = "The IAM user assigned the VM Reader policy."
  value       = data.aws_iam_user.target.user_name
}
