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

# Create an IAM group that represents the directory role.
resource "aws_iam_group" "example_role" {
  name = "ExampleRole"
}

# Explicitly define the membership for the IAM group.
# Replace these user names with the actual IAM user names to be members.
resource "aws_iam_group_membership" "example_role_members" {
  group = aws_iam_group.example_role.name
  users = [
    "alice",
    "bob"
  ]
}

output "directory_role_info" {
  description = "Details of the IAM group representing the directory role and its members"
  value = {
    GroupName = aws_iam_group.example_role.name
    GroupArn  = aws_iam_group.example_role.arn
    Members   = aws_iam_group_membership.example_role_members.users
  }
}
