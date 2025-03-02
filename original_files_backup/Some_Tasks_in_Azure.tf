terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # AWS Route 53 is a global service; region can be any.
}

###############################
# Create a Hosted Zone (simulating a DNS Zone)
###############################
resource "aws_route53_zone" "zone" {
  name = "exampledomain.com"
}

###############################
# Create a DNS A Record
###############################
resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "www"
  type    = "A"
  ttl     = 3600
  records = ["10.10.10.10"]
}

###############################
# Outputs
###############################
output "dns_zone_name_servers" {
  description = "Name servers for the DNS zone"
  value       = aws_route53_zone.zone.name_servers
}
