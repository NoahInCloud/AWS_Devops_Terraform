terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_backup_vault" "vault" {
  name = "twrsv2022"

  tags = {
    Name = "twrsv2022"
  }
}

output "vault_id" {
  description = "The ID of the AWS Backup Vault"
  value       = aws_backup_vault.vault.id
}
