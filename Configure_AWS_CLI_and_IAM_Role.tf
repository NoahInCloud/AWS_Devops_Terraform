terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust region as needed
}

# Look up an existing IAM role that represents your application identity.
# (This role should exist in your AWS account with the name "twwebapp2021".)
data "aws_iam_role" "twwebapp" {
  name = "twwebapp2021"
}

output "twwebapp_info" {
  description = "Details for the IAM role representing the application"
  value = {
    RoleName    = data.aws_iam_role.twwebapp.name
    RoleId      = data.aws_iam_role.twwebapp.role_id
    Arn         = data.aws_iam_role.twwebapp.arn
    CreateDate  = data.aws_iam_role.twwebapp.create_date
    # AWS IAM roles do not have "SignInAudience" or "AppOwnerOrganizationId".
    # You might include the assume_role_policy if desired:
    AssumeRolePolicy = data.aws_iam_role.twwebapp.assume_role_policy
  }
}
