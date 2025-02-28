terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust as needed
}

# Create an IAM group named "Administrators"
resource "aws_iam_group" "administrators" {
  name = "Administrators"
}

# Explicitly assign IAM users to the group.
# Replace these with the actual IAM user names that should have admin privileges.
resource "aws_iam_group_membership" "admin_membership" {
  group = aws_iam_group.administrators.name
  users = [
    "alice",
    "bob",
    "charlie"
  ]
}

output "admin_group_members" {
  description = "List of members in the Administrators group"
  value       = aws_iam_group_membership.admin_membership.users
}
