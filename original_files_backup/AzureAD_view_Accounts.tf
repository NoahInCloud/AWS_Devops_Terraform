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

###############################
# Retrieve a Specific IAM User
###############################
data "aws_iam_user" "jane_ford" {
  # In AWS, IAM users are identified by their user name.
  # Ensure that an IAM user with this name exists.
  user_name = "jane.Noah@example.io"
}

###############################
# Outputs (simulate "Select *" or specific property selection)
###############################
output "jane_ford_all_properties" {
  description = "All available properties for jane.Noah@example.io"
  value       = data.aws_iam_user.jane_ford
}

output "jane_ford_selected_properties" {
  description = "Selected properties for jane.Noah@example.io"
  value = {
    user_name   = data.aws_iam_user.jane_ford.user_name
    arn         = data.aws_iam_user.jane_ford.arn
    path        = data.aws_iam_user.jane_ford.path
    create_date = data.aws_iam_user.jane_ford.create_date
  }
}
