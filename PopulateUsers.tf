terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust as needed.
}

###############################
# Variables
###############################
variable "domain" {
  description = "The domain used for the user principal name (for tagging purposes)"
  default     = "example.com"
}

variable "user_password" {
  description = "The password to assign to all users"
  type        = string
  sensitive   = true
  default     = "agxsFX72xwsSAi"
}

###############################
# Read CSV Data
###############################
# Ensure that the CSV file "Fake_User_data.csv" is in the same directory as this configuration.
data "local_file" "fake_users" {
  filename = "Fake_User_data.csv"
}

###############################
# Decode CSV into a List of Maps
###############################
locals {
  users = csvdecode(data.local_file.fake_users.content)
}

###############################
# Create IAM Users and Their Login Profiles
###############################
resource "aws_iam_user" "users" {
  for_each = { for user in local.users : user.Username => user }
  
  name = each.value.Username
  path = "/"
  
  tags = {
    DisplayName     = "${each.value.GivenName} ${each.value.Surname}"
    GivenName       = each.value.GivenName
    Surname         = each.value.Surname
    JobTitle        = each.value.Occupation
    Department      = each.value.Department
    City            = each.value.City
    State           = each.value.State
    Country         = each.value.Country
    PostalCode      = each.value.ZipCode
    StreetAddress   = each.value.StreetAddress
    TelephoneNumber = each.value.TelephoneNumber
    Domain          = var.domain
  }
}

resource "aws_iam_user_login_profile" "users_profile" {
  for_each = aws_iam_user.users

  user                   = each.value.name
  password               = var.user_password
  password_reset_required = false
}

###############################
# Outputs
###############################
output "created_user_ids" {
  description = "Mapping of created IAM user names to their ARNs"
  value       = { for key, user in aws_iam_user.users : key => user.arn }
}
