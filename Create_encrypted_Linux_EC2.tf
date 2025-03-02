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
  region = "eu-west-1"  # Similar to Azure's "westeurope"
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "Name of the resource group (simulated by tagging)"
  default     = "myResourceGroup"
}

variable "location" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  default     = "MyVM"
}

variable "admin_username" {
  description = "Admin username for the VM (for tagging)"
  default     = "NoahinCloud"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  default     = "my-key"
}

###############################
# Random Suffix for Naming
###############################
resource "random_integer" "id" {
  min = 1000
  max = 9999
}

###############################
# VPC and Networking (Simulating Virtual Network and Subnet)
###############################
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.resource_group_name
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
# Security Group (Allow SSH)
###############################
resource "aws_security_group" "sg" {
  name        = "${var.vm_name}-sg"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vm_name}-sg"
  }
}

###############################
# KMS Key for EBS Encryption (Simulating Key Vault for Disk Encryption)
###############################
resource "aws_kms_key" "ebs_key" {
  description             = "KMS key for encrypting EBS volumes for ${var.vm_name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${var.vm_name}-kms-key-${random_integer.id.result}"
  }
}

###############################
# EC2 Instance (Ubuntu 18.04 LTS with Encrypted Root Volume)
###############################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical's owner ID
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "aws_instance" "vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "m5.large"  # Similar to Standard_D2S_V3
  subnet_id              = aws_subnet.subnet.id
  key_name               = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
    encrypted   = true
    kms_key_id  = aws_kms_key.ebs_key.arn
  }

  tags = {
    Name      = var.vm_name
    AdminUser = var.admin_username
    Suffix    = random_integer.id.result
  }
}

###############################
# Outputs
###############################
output "kms_key_arn" {
  description = "The ARN of the KMS key used for disk encryption"
  value       = aws_kms_key.ebs_key.arn
}

output "vm_id" {
  description = "The ID of the encrypted virtual machine"
  value       = aws_instance.vm.id
}
