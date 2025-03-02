terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust as needed.
}

variable "domain" {
  description = "The domain for user principal names"
  default     = "example.com"  # Use a domain appropriate for your AWS setup.
}

variable "user_password" {
  description = "The password to assign to the IAM user (for console access)"
  type        = string
  sensitive   = true
  default     = "agxsFX72xwsSAi"
}

resource "aws_iam_user" "fred_prefect" {
  name = "frPrefect"   # AWS IAM user name

  tags = {
    DisplayName       = "Fred Prefect"
    GivenName         = "Fred"
    Surname           = "Prefect"
    JobTitle          = "Azure Administrator"
    Department        = "Information Technology"
    City              = "Oberbuchsiten"
    State             = "SO"
    Country           = "Switzerland"
    PostalCode        = "4625"
    StreetAddress     = "Hiltonstrasse"
    TelephoneNumber   = "455-233-22"
    UsageLocation     = "CH"
    # Include domain information in a tag if desired.
    Domain            = var.domain
  }
}

# Create a login profile to enable AWS Console access.
resource "aws_iam_user_login_profile" "fred_prefect_profile" {
  user                    = aws_iam_user.fred_prefect.name
  password                = var.user_password
  password_reset_required = false
}

output "fred_prefect_user_arn" {
  description = "The ARN of the newly created IAM user representing Fred Prefect"
  value       = aws_iam_user.fred_prefect.arn
}
