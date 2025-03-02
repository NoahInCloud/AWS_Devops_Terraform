provider "aws" {
  region = "eu-west-1"  # Choose a region; adjust as needed.
}

###############################
# Variables
###############################
variable "config_rule_name" {
  description = "The name for the AWS Config rule that audits EBS volume encryption."
  default     = "encrypted-volumes-rule"
}

###############################
# AWS Config Rule
###############################
resource "aws_config_config_rule" "encrypted_volumes" {
  name = var.config_rule_name

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  # Scope can be narrowed to EBS volumes (which are attached to EC2 instances)
  scope {
    compliance_resource_types = ["AWS::EC2::Volume"]
  }
}

###############################
# Outputs (optional)
###############################
output "config_rule_id" {
  description = "The ID of the AWS Config rule."
  value       = aws_config_config_rule.encrypted_volumes.id
}
