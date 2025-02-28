provider "aws" {
  region = "eu-west-1"  # Adjust as needed
}

###############################
# Variables
###############################
variable "user_name" {
  description = "The name of the IAM user to assign permissions to."
  default     = "Noah"  # This represents the user analogous to 'Noah@example.io'
}

###############################
# Data Sources: Lookup Existing User and Managed Policy
###############################
# Look up an existing IAM user (you might have already created this user in AWS)
data "aws_iam_user" "noah" {
  user_name = var.user_name
}

# Reference a managed policy (example: AmazonEC2FullAccess for managing EC2 instances)
data "aws_iam_policy" "ec2_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

###############################
# Role Assignment Equivalent: Attach the Policy to the User
###############################
resource "aws_iam_user_policy_attachment" "noah_ec2_policy_attachment" {
  user       = data.aws_iam_user.noah.user_name
  policy_arn = data.aws_iam_policy.ec2_full_access.arn
}

###############################
# Outputs (Simulating Azure’s Role Definition and Assignment outputs)
###############################
output "noah_user_details" {
  description = "IAM user details for the user (simulating the Azure AD user lookup)"
  value       = data.aws_iam_user.noah
}

output "attached_policy_details" {
  description = "Details for the attached managed policy (simulating a role definition)"
  value       = data.aws_iam_policy.ec2_full_access
}

output "policy_attachment_details" {
  description = "Details of the IAM policy attachment (simulating the role assignment)"
  value       = aws_iam_user_policy_attachment.noah_ec2_policy_attachment
}
