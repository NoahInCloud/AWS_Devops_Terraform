terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Route53 is global; region is used for other resources.
}

###############################
# Variables
###############################
variable "dns_zone_name" {
  description = "DNS zone name (must be a valid domain, e.g. 'example.com')"
  default     = "example.com"
}

variable "dns_record_name" {
  description = "DNS record name (subdomain portion)"
  default     = "www"
}

variable "ipv4_address" {
  description = "IPv4 address for the A record"
  default     = "10.10.10.10"
}

variable "ttl" {
  description = "Time-to-live for the DNS record"
  default     = 3600
}

###############################
# Create a Hosted Zone (simulating an Azure DNS Zone)
###############################
resource "aws_route53_zone" "dns_zone" {
  name = var.dns_zone_name
}

###############################
# Create a DNS A Record in the Hosted Zone
###############################
resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = var.dns_record_name
  type    = "A"
  ttl     = var.ttl
  records = [var.ipv4_address]
}

###############################
# Outputs
###############################
output "dns_zone_name_servers" {
  description = "The name servers for the DNS zone."
  value       = aws_route53_zone.dns_zone.name_servers
}
