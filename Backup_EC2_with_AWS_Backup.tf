provider "aws" {
  region = "eu-west-1"  # Similar to Azure's WestEurope
}

###############################
# Backup Vault
###############################
resource "aws_backup_vault" "vault" {
  name = "myBackupVault"
}

###############################
# IAM Role for AWS Backup
###############################
resource "aws_iam_role" "backup_role" {
  name = "AWSBackupServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "backup.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "backup_role_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

###############################
# Backup Plan for EC2 (using EBS snapshots)
###############################
resource "aws_backup_plan" "default_plan" {
  name = "DefaultBackupPlan"

  rule {
    rule_name         = "DailyBackup"
    target_vault_name = aws_backup_vault.vault.name
    # Cron expression for 23:00 UTC daily
    schedule          = "cron(0 23 * * ? *)"

    lifecycle {
      delete_after = 30  # Retain backups for 30 days
    }
  }
}

###############################
# Reference an Existing EC2 Instance
###############################
data "aws_instance" "vm" {
  # Replace with your existing EC2 instance ID.
  instance_id = "i-0123456789abcdef0"
}

###############################
# Backup Selection: Enable Backup Protection for the EC2 Instance
###############################
resource "aws_backup_selection" "vm_backup" {
  name         = "VMBackupSelection"
  plan_id      = aws_backup_plan.default_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn

  # AWS Backup uses ARNs to identify resources.
  resources = [
    data.aws_instance.vm.arn
  ]
}

###############################
# Outputs (Optional)
###############################
output "vault_id" {
  description = "The ID of the AWS Backup Vault"
  value       = aws_backup_vault.vault.id
}

output "protected_vm_id" {
  description = "The ID of the backup selection (representing the protected EC2 instance)"
  value       = aws_backup_selection.vm_backup.id
}
