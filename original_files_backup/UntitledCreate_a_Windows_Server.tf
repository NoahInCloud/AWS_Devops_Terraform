terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"  # Similar to Azure's westeurope
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "Name of the resource group (used for tagging)"
  type        = string
  default     = "myResourceGroup"
}

variable "location" {
  description = "AWS region (simulate Azure region)"
  type        = string
  default     = "eu-west-1"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "myVM"
}

variable "admin_username" {
  description = "Admin username for the VM (for tagging only)"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM (for informational purposes only)"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"
}

###############################
# Random Suffix for DNS-Like Name
###############################
resource "random_integer" "dns_suffix" {
  min = 1000
  max = 9999
}

###############################
# VPC and Subnet (Simulating Virtual Network and Subnet)
###############################
resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = var.resource_group_name
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mySubnet"
  }
}

###############################
# Elastic IP with a DNS-like Name Tag
###############################
resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "myPublicIpAddress-${random_integer.dns_suffix.result}"
  }
}

###############################
# Security Group (Allowing RDP on Port 3389)
###############################
resource "aws_security_group" "sg" {
  name        = "myNetworkSecurityGroup"
  description = "Allow inbound RDP access"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "myNetworkSecurityGroup"
  }
}

###############################
# Windows EC2 Instance
###############################
data "aws_ami" "win2016" {
  most_recent = true
  owners      = ["801119661308"]  # Windows AMI owner ID (verify in your region)
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "vm" {
  ami                    = data.aws_ami.win2016.id
  instance_type          = "m5.large"  # Similar in performance to Standard_D2s_v3
  key_name               = "my-key"    # Replace with your existing EC2 key pair name
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = false  # We attach the Elastic IP separately

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  tags = {
    Name          = var.vm_name
    AdminUser     = var.admin_username
    ResourceGroup = var.resource_group_name
    # Storing the admin password in tags is not recommended; included here for demonstration.
    AdminPassword = var.admin_password
  }
}

###############################
# Elastic IP Association
###############################
resource "aws_eip_association" "eip_assoc" {
  allocation_id = aws_eip.eip.allocation_id
  instance_id   = aws_instance.vm.id
}

###############################
# Outputs
###############################
output "vm_id" {
  description = "The ID of the Windows EC2 instance"
  value       = aws_instance.vm.id
}

output "public_ip" {
  description = "The public IP address of the Windows EC2 instance"
  value       = aws_eip.eip.public_ip
}
