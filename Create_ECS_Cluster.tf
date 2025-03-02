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
  region = "eu-west-1"  # Equivalent to Azure's "westeurope"
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "A name used for tagging resources (simulating an Azure resource group)"
  default     = "myResourceGroup"
}

variable "location" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  default     = "myVM"
}

variable "admin_username" {
  description = "Admin username for the VM (stored as a tag in AWS)"
  default     = "NoahinCloud"
}

variable "key_name" {
  description = "The name of the EC2 key pair to use for SSH access"
  default     = "my-key"
}

###############################
# Random DNS Suffix (for tagging the EIP)
###############################
resource "random_string" "dns_suffix" {
  length  = 4
  special = false
  upper   = false
}

###############################
# VPC and Subnet (simulate Azure Virtual Network and Subnet)
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
  map_public_ip_on_launch = false
  tags = {
    Name = "mySubnet"
  }
}

###############################
# Internet Gateway and Route Table
###############################
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
# Security Group (allow SSH and HTTP)
###############################
resource "aws_security_group" "sg" {
  name        = "mySG"
  description = "Allow SSH (22) and HTTP (80)"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "mySG"
  }
}

###############################
# Elastic IP (simulate Public IP with DNS suffix)
###############################
resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "mypublicdns${random_string.dns_suffix.result}"
  }
}

###############################
# Ubuntu 18.04 LTS AMI Lookup
###############################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

###############################
# Linux Virtual Machine (with Docker installed via user data)
###############################
resource "aws_instance" "vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "m5.large"  # Similar in performance to Standard_DS2_v2
  subnet_id              = aws_subnet.subnet.id
  key_name               = var.key_name
  associate_public_ip_address = false  # We will assign an Elastic IP separately
  security_groups        = [aws_security_group.sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose
    systemctl start docker
    # Run an Nginx container mapping port 80
    docker run -d -p 80:80 nginx
  EOF

  tags = {
    Name      = var.vm_name
    AdminUser = var.admin_username
  }
}

###############################
# Associate the Elastic IP with the Instance
###############################
resource "aws_eip_association" "eip_assoc" {
  allocation_id = aws_eip.eip.allocation_id
  instance_id   = aws_instance.vm.id
}

###############################
# Outputs
###############################
output "public_ip" {
  description = "The public IP address of the instance."
  value       = aws_eip.eip.public_ip
}
