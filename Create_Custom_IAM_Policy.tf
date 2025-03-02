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
  region = "us-east-1"  # Adjust the region as needed.
}

# Generate a random UUID to use for the role name.
resource "random_uuid" "custom_role_id" {}

# Create the IAM Role.
resource "aws_iam_role" "virtual_machine_starter" {
  name = random_uuid.custom_role_id.result

  # This trust policy allows EC2 instances to assume the role.
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# Attach an inline policy that grants permissions similar to your Azure custom role.
resource "aws_iam_role_policy" "virtual_machine_starter_policy" {
  name = "VirtualMachineStarterPolicy"
  role = aws_iam_role.virtual_machine_starter.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",          # Similar to Microsoft.Storage/*/read
          "s3:GetObject",           # Similar to Microsoft.Storage/*/read
          "ec2:Describe*",          # Similar to Microsoft.Compute/*/read and Microsoft.Network/*/read
          "ec2:StartInstances",     # Similar to Microsoft.Compute/virtualMachines/start/action
          "iam:Get*",               # Similar to Microsoft.Authorization/*/read
          "iam:List*",              # Similar to Microsoft.Authorization/*/read
          "resource-groups:ListGroups",  # Similar to Microsoft.Resources/subscriptions/resourceGroups/read
          "cloudwatch:DescribeAlarms"    # Similar to Microsoft.Insights/alertRules/*
        ],
        "Resource": "*"
      }
    ]
  })
}

output "role_arn" {
  description = "The ARN of the Virtual Machine Starter role"
  value       = aws_iam_role.virtual_machine_starter.arn
}
