provider "aws" {
  region = "eu-west-1"   # Similar to Azure's "westeurope"
}

###############################
# Optional: AWS Resource Group
###############################
# AWS Resource Groups let you group resources by tag.
# This isn’t required for AWS to function but can help with organization.
resource "aws_resourcegroups_group" "rg" {
  name = "tw-rg01"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"],
      TagFilters = [
        { Key = "costcenter", Values = ["1987"] },
        { Key = "ManagedBy",  Values = ["Bob"] },
        { Key = "Status",     Values = ["Approved"] }
      ]
    })
  }

  tags = {
    costcenter = "1987"
    ManagedBy  = "Bob"
    Status     = "Approved"
  }
}

###############################
# Data Sources: Default VPC and Subnet
###############################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  default_for_az = true
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

###############################
# Data Source: Lookup Windows Server 2016 AMI
###############################
data "aws_ami" "windows_2016" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

###############################
# Sample Resource: Windows EC2 Instance with Tags
###############################
resource "aws_instance" "winsrv" {
  ami           = data.aws_ami.windows_2016.id
  instance_type = "m5.large"   # Approximate equivalent to Standard_D2s_v3
  subnet_id     = data.aws_subnet.default.id

  # Provide your key pair name here
  key_name = "my-key"

  # Automatically assign a public IP (if needed)
  associate_public_ip_address = true

  # Configure the root EBS volume (this simulates the OS disk)
  root_block_device {
    volume_type = "gp2"
  }

  tags = {
    Dept        = "IT"
    Environment = "Test"
    Status      = "Approved"
  }
}

###############################
# Outputs (Optional)
###############################
output "resource_group_tags" {
  description = "Tags applied to the AWS resource group (if using aws_resourcegroups_group)"
  value       = aws_resourcegroups_group.rg.tags
}

output "winsrv_tags" {
  description = "Tags applied to the Windows instance"
  value       = aws_instance.winsrv.tags
}
