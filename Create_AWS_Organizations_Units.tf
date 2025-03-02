terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # AWS Organizations is global; region is used for other resources.
}

###############################
# Data Source: Get the Organization and its Root
###############################
data "aws_organizations_organization" "org" {}

###############################
# Create Organizational Units (OUs)
###############################

# Create a top-level OU "Contoso" under the Organization root
resource "aws_organizations_organizational_unit" "contoso" {
  name      = "Contoso"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Create a top-level OU "NoahinCloud" under the Organization root
resource "aws_organizations_organizational_unit" "noahincloud" {
  name      = "NoahinCloud"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Create a child OU "NoahinCloudSubGroup" under "NoahinCloud"
resource "aws_organizations_organizational_unit" "noahincloud_subgroup" {
  name      = "NoahinCloudSubGroup"
  parent_id = aws_organizations_organizational_unit.noahincloud.id
}

###############################
# Data Source Examples
###############################

# Retrieve details for the "Contoso" OU
data "aws_organizations_organizational_unit" "contoso_data" {
  id = aws_organizations_organizational_unit.contoso.id
}

# Optionally, retrieve an OU by ID (replace with an actual OU ID)
data "aws_organizations_organizational_unit" "testgroupparent" {
  id = "ou-xxxx-xxxxxxxx"  # Replace with your known OU ID, if available.
}

###############################
# Outputs
###############################
output "contoso_ou_details" {
  description = "Details for the Contoso organizational unit"
  value       = data.aws_organizations_organizational_unit.contoso_data
}

output "testgroupparent_hierarchy" {
  description = "Details for the TestGroupParent organizational unit (if available)"
  value       = data.aws_organizations_organizational_unit.testgroupparent
}
