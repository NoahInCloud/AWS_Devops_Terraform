terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust as needed.
}

# Data source to fetch an existing IAM user by name.
data "aws_iam_user" "example" {
  user_name = "example-user"  # Replace with the actual user name.
}

# Manage the IAM user and "assign" a license via tags.
# If the user already exists outside Terraform, you can import it.
resource "aws_iam_user" "managed_user" {
  name = data.aws_iam_user.example.user_name

  # You may also set other properties as needed.
  path = "/"

  tags = {
    DisplayName       = data.aws_iam_user.example.user_name
    UsageLocation     = "CH"
    AssignedLicenses  = "06ebc4ee-1bb5-47dd-8120-11324bc54e06"  # Simulated license SKU
  }
}

output "assigned_licenses" {
  description = "The license assigned to the user (simulated via tags)"
  value       = aws_iam_user.managed_user.tags["AssignedLicenses"]
}
