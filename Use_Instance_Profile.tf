terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"  # Adjust region as needed.
}

###############################
# Retrieve Existing Windows EC2 Instance Info
###############################
data "aws_instance" "target_vm" {
  # Replace with the actual instance ID of your Windows VM.
  instance_id = "i-0xxxxxxxxxxxxxxx"
}

output "managed_identity_principal_id" {
  description = "The IAM instance profile attached to the Windows EC2 instance (simulating a managed identity)"
  value       = data.aws_instance.target_vm.iam_instance_profile
}

###############################
# Download an S3 Object (simulate blob download)
###############################
resource "null_resource" "download_blob" {
  provisioner "local-exec" {
    # This command downloads the object from S3 to a local destination.
    # Adjust the bucket name, folder (container), object name, and destination as needed.
    command = "aws s3 cp s3://twstg00001/bilder/IMG_0498.jpg C:/Temp/IMG_0498.jpg"
  }
}
