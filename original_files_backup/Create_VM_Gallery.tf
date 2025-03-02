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
  region = "eu-west-1"  # Similar to Azure's WestEurope
}

###############################
# Variables
###############################
variable "resource_group" {
  description = "Simulated resource group name (used for tagging)"
  type        = string
  default     = "myVMfromImage"
}

variable "location" {
  description = "AWS region (should match provider region)"
  type        = string
  default     = "eu-west-1"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "myVMfromImage"
}

variable "custom_image_id" {
  description = "The custom Windows AMI ID to use for the instance (analogous to the shared image)"
  type        = string
  default     = "ami-xxxxxxxx"  # Replace with your custom Windows AMI ID
}

variable "key_name" {
  description = "The EC2 key pair name to allow Windows login"
  type        = string
  default     = "my-key"
}

###############################
# Random Suffix for Public DNS Name (for tagging purposes)
###############################
resource "random_string" "public_ip_suffix" {
  length  = 4
  special = false
  upper   = false
}

###############################
# VPC and Networking (Simulating Azure Virtual Network and Subnet)
###############################
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.resource_group
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mySubnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "myIGW"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "myRouteTable"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

###############################
# Elastic IP (Public IP with random DNS-like tagging)
###############################
resource "aws_eip" "public_ip" {
  vpc = true

  tags = {
    Name = "myPublicIP-${random_string.public_ip_suffix.result}"
  }
}

###############################
# Security Group (Allowing RDP on port 3389)
###############################
resource "aws_security_group" "sg" {
  name        = "mySG"
  description = "Allow RDP access"
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
    Name = "mySG"
  }
}

###############################
# Network Interface (ENI)
###############################
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.10"]  # Static private IP (adjust if necessary)
  security_groups = [aws_security_group.sg.id]

  tags = {
    Name = "myNic"
  }
}

###############################
# Windows EC2 Instance (from Custom AMI)
###############################
resource "aws_instance" "vm" {
  ami           = var.custom_image_id
  instance_type = "t3.small"  # Adjust instance type as needed
  key_name      = var.key_name

  # Instead of directly associating a public IP, we attach the network interface
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nic.id
  }

  associate_public_ip_address = false

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  tags = {
    Name      = var.vm_name,
    ResourceGroup = var.resource_group
  }
}

###############################
# Elastic IP Association
###############################
resource "aws_eip_association" "eip_assoc" {
  allocation_id = aws_eip.public_ip.allocation_id
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
  description = "The public IP address assigned to the instance"
  value       = aws_eip.public_ip.public_ip
}
