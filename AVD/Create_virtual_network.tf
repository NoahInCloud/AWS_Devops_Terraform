terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.location  # e.g., "eu-west-1" for West Europe
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "Simulated resource group name (used for tagging)"
  type        = string
  default     = "tw-prod-rg"
}

variable "location" {
  description = "AWS region (simulate Azure region, e.g., eu-west-1 for westeurope)"
  type        = string
  default     = "eu-west-1"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "tw-prod-vnet"
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnets" {
  description = "List of subnets with name and address prefix"
  type = list(object({
    name           = string
    address_prefix = string
  }))
  default = [
    {
      name           = "AzureBastionSubnet"
      address_prefix = "10.10.0.0/26"
    },
    {
      name           = "AzureFirewallSubnet"
      address_prefix = "10.10.1.0/26"
    },
    {
      name           = "Production"
      address_prefix = "10.10.3.0/24"
    }
  ]
}

variable "dns_servers" {
  description = "DNS servers for the virtual network"
  type        = list(string)
  default     = ["10.10.3.4"]
}

###############################
# DHCP Options Set (to specify custom DNS servers)
###############################
resource "aws_dhcp_options" "dhcp" {
  domain_name_servers = var.dns_servers
}

###############################
# VPC (Simulating the Virtual Network)
###############################
resource "aws_vpc" "vpc" {
  cidr_block           = var.address_space[0]
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name          = var.vnet_name
    ResourceGroup = var.resource_group_name
  }
}

# Associate the DHCP options set with the VPC.
resource "aws_vpc_dhcp_options_association" "dhcp_assoc" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_dhcp_options.dhcp.id
}

###############################
# Subnets (Simulating the Azure Subnets)
###############################
resource "aws_subnet" "subnets" {
  for_each = { for s in var.subnets : s.name => s }
  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value.address_prefix
  availability_zone = "${var.location}a"  # e.g., eu-west-1a

  tags = {
    Name = each.value.name
  }
}

###############################
# Output
###############################
output "vnet_dns_servers" {
  description = "The DNS servers configured for the VPC (via DHCP options)"
  value       = aws_dhcp_options.dhcp.domain_name_servers
}
