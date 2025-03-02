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
# Data Source: Lookup an existing IAM user (simulating "Fred Prefect")
###############################
data "aws_iam_user" "fred_prefect" {
  user_name = "frPrefect"  # Replace with the actual IAM user name for Fred Prefect.
}

###############################
# Create the "Fred Group" with an Owner Tag
###############################
resource "aws_iam_group" "fred_group" {
  name = "FredGroup"

  tags = {
    Description = "Group for Fred to use"
    Owner       = data.aws_iam_user.fred_prefect.arn
  }
}

###############################
# Add Additional Members to "Fred Group"
###############################
variable "so_user_names" {
  description = "List of IAM user names to add as additional members (e.g., users where State equals 'SO')"
  type        = list(string)
  default     = []  # Supply IAM user names as needed.
}

resource "aws_iam_group_membership" "fred_group_members" {
  group = aws_iam_group.fred_group.name
  users = var.so_user_names
}

###############################
# Create a "Dynamic" Group: "Marketing Group"
###############################
# Note: AWS IAM does not support dynamic membership out-of-the-box.
# Here we create a group and tag it with a criteria string to indicate its intended purpose.
resource "aws_iam_group" "marketing_group" {
  name = "MarketingGroup"

  tags = {
    Description       = "Dynamic group for Marketing"
    DynamicMembership = "user.department contains 'Marketing'"
  }
}

###############################
# Outputs
###############################
output "fred_group_id" {
  description = "The ARN of the Fred Group"
  value       = aws_iam_group.fred_group.arn
}

output "marketing_group_id" {
  description = "The ARN of the Marketing Group"
  value       = aws_iam_group.marketing_group.arn
}
