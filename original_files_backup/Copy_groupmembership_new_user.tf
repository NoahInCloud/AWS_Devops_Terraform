provider "aws" {
  region = "us-east-1"
}

# Look up the source and target IAM users.
data "aws_iam_user" "source" {
  user_name = "AdeleV"
}

data "aws_iam_user" "target" {
  user_name = "LeeG"
}

# Provide a list of IAM group names that the source user is a member of.
variable "source_group_names" {
  description = "List of IAM group names that the source user is a member of"
  type        = list(string)
  default     = [
    "group-name-1",
    "group-name-2",
    "group-name-3"
  ]
}

# For each group, ensure the target user is a member.
resource "aws_iam_user_group_membership" "target_membership" {
  for_each = toset(var.source_group_names)
  user     = data.aws_iam_user.target.user_name
  groups   = [each.value]
}

output "target_membership_details" {
  value = aws_iam_user_group_membership.target_membership
}
