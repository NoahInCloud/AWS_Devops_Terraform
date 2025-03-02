terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Adjust as needed
}

# Data source to fetch details for an existing Windows EC2 instance.
data "aws_instance" "example_vm" {
  instance_id = "i-0xxxxxxxxxxxxxxxx"  # Replace with your instance ID
}

# Output all available attributes as JSON (similar to Select-Object *)
output "vm_full_details" {
  description = "Full details of the VM as retrieved from AWS"
  value       = data.aws_instance.example_vm
}

# Output selected attributes (e.g., Name tag, instance ID, and state)
output "vm_selected_details" {
  description = "Selected details of the VM"
  value = {
    Name  = lookup(data.aws_instance.example_vm.tags, "Name", "unknown")
    VmId  = data.aws_instance.example_vm.id
    State = data.aws_instance.example_vm.state
  }
}
