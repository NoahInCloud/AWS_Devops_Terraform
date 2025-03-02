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

###############################
# Create a "Dynamic" Group (simulate dynamic membership via tagging)
###############################
resource "aws_iam_group" "dynamic_group_01" {
  name = "DynamicGroup01"

  tags = {
    Description       = "Dynamic group created from PS"
    DynamicMembership = "user.department contains 'Marketing'"
  }
}

###############################
# Manage an Existing Group
###############################
# In AWS, to manage an existing IAM group you import it into Terraform.
# Here, we define a resource for an existing group. After creation, import it with:
#   terraform import aws_iam_group.existing_group ExistingGroup
resource "aws_iam_group" "existing_group" {
  name = "ExistingGroup"  # This should match the name of the group you want to manage.

  # AWS IAM groups don't have a SecurityEnabled property; we simulate it using tags.
  tags = {
    SecurityEnabled = "true"
  }
}

###############################
# Outputs
###############################
output "dynamic_group_info" {
  description = "Details of the dynamic group"
  value = {
    GroupName = aws_iam_group.dynamic_group_01.name
    ARN       = aws_iam_group.dynamic_group_01.arn
    Tags      = aws_iam_group.dynamic_group_01.tags
  }
}

output "existing_group_info" {
  description = "Details of the managed existing group"
  value = {
    GroupName = aws_iam_group.existing_group.name
    ARN       = aws_iam_group.existing_group.arn
    Tags      = aws_iam_group.existing_group.tags
  }
}
