terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust region as needed.
}

###############################
# Variables
###############################
variable "user_name" {
  description = "The username to create (without any domain part)"
  default     = "aadsyncuser"
}

variable "password" {
  description = "The password for the new IAM user"
  type        = string
  sensitive   = true
  default     = "Pa55w.rd1234"  # Use a secure method for managing secrets in production.
}

###############################
# Create the IAM User
###############################
resource "aws_iam_user" "new_user" {
  name = var.user_name

  tags = {
    CreatedBy = "Terraform"
  }
}

# Create a login profile to enable AWS Console access for the IAM user.
resource "aws_iam_user_login_profile" "new_user_profile" {
  user                  = aws_iam_user.new_user.name
  password              = var.password
  password_reset_required = false
}

###############################
# Attach AdministratorAccess Policy
###############################
resource "aws_iam_user_policy_attachment" "admin_attachment" {
  user       = aws_iam_user.new_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

###############################
# Outputs
###############################
output "new_user_arn" {
  description = "The ARN of the newly created IAM user."
  value       = aws_iam_user.new_user.arn
}

output "attached_policy" {
  description = "The attached AdministratorAccess policy ARN."
  value       = aws_iam_user_policy_attachment.admin_attachment.policy_arn
}
