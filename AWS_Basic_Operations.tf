provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

output "account_id" {
  description = "The AWS account ID for the current caller"
  value       = data.aws_caller_identity.current.account_id
}

output "user_arn" {
  description = "The ARN of the current caller"
  value       = data.aws_caller_identity.current.arn
}

output "user_id" {
  description = "The user ID of the current caller"
  value       = data.aws_caller_identity.current.user_id
}
