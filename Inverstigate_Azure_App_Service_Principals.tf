terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust the region as needed.
}

# Look up an existing IAM role that represents your application "twdemoapp".
data "aws_iam_role" "twdemoapp" {
  name = "twdemoapp"  # Ensure an IAM role with this name exists in your AWS account.
}

# (Optional) To manage role assignments in AWS, you typically attach policies or use the role with services.
# For example, you could attach an inline policy to the role:
#
# resource "aws_iam_role_policy" "example_policy" {
#   name = "ExamplePolicy"
#   role = data.aws_iam_role.twdemoapp.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = [ "s3:ListBucket" ],
#         Resource = "*" 
#       }
#     ]
#   })
# }
#
# In AWS, to "remove" assignments, you simply remove the policy attachments.

output "twdemoapp_info" {
  description = "Details for the queried IAM role representing the application"
  value = {
    RoleName         = data.aws_iam_role.twdemoapp.name
    RoleId           = data.aws_iam_role.twdemoapp.role_id
    Arn              = data.aws_iam_role.twdemoapp.arn
    CreateDate       = data.aws_iam_role.twdemoapp.create_date
    AssumeRolePolicy = data.aws_iam_role.twdemoapp.assume_role_policy
  }
}
