terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust as needed.
}

###############################
# Variables: List of Identities to Manage
###############################
variable "user_assigned_identities" {
  description = "List of user-assigned identities to manage, with their names and resource group names."
  type = list(object({
    name           = string
    resource_group = string
  }))
  default = [
    {
      name           = "identity1"
      resource_group = "rg-identity1"
    },
    {
      name           = "identity2"
      resource_group = "rg-identity2"
    }
  ]
}

###############################
# Create IAM Roles for Each Identity
###############################
resource "aws_iam_role" "uas" {
  for_each = { for u in var.user_assigned_identities : u.name => u }

  name = each.value.name

  # Trust policy: allowing EC2 instances to assume the role.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    ResourceGroup = each.value.resource_group
  }
}

###############################
# Attach a Managed Policy to Each Role
###############################
# Here we simulate the assignment of a Contributor-like role by attaching PowerUserAccess.
resource "aws_iam_role_policy_attachment" "assign_identity" {
  for_each = aws_iam_role.uas

  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

###############################
# Outputs: Identity and Role Assignment Details
###############################
output "user_assigned_identity_info" {
  description = "Mapping of user-assigned identities to their IAM role details"
  value = {
    for name, role in aws_iam_role.uas :
    name => {
      name           = role.name
      arn            = role.arn
      resource_group = role.tags["ResourceGroup"]
    }
  }
}

output "role_assignment_info" {
  description = "Details of the policy attachments for each identity"
  value = {
    for name, attachment in aws_iam_role_policy_attachment.assign_identity :
    name => {
      role_name  = attachment.role,
      policy_arn = attachment.policy_arn
    }
  }
}
