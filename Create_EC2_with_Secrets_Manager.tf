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
  region = "eu-west-1"  # Equivalent to Azure's westeurope
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "Simulated resource group name (used for tagging)"
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
  description = "Admin username for the VM (for tagging purposes)"
  type        = string
  default     = "sysadmin"
}

variable "admin_password" {
  description = "Admin password for the VM (to be stored in Secrets Manager)"
  type        = string
  sensitive   = true
  default     = "hVFkk965BuUv"
}

variable "key_name" {
  description = "EC2 key pair name for Windows login"
  type        = string
  default     = "my-key"
}

###############################
# AWS Secrets Manager: Store Admin Password
###############################
resource "aws_secretsmanager_secret" "vm_admin_password" {
  name        = "${var.vm_name}-admin-password"
  description = "Admin password for the Windows VM"
  tags = {
    ResourceGroup = var.resource_group_name
  }
}

resource "aws_secretsmanager_secret_version" "vm_admin_password_version" {
  secret_id     = aws_secretsmanager_secret.vm_admin_password.id
  secret_string = var.admin_password
}

###############################
# Networking: VPC, Subnet, Internet Gateway, and Route Table
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
# Elastic IP (Public IP)
###############################
resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "${var.vm_name}-public-ip"
  }
}

###############################
# Security Group (Allow RDP)
###############################
resource "aws_security_group" "sg" {
  name        = "${var.vm_name}-sg"
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
# Windows EC2 Instance
###############################
data "aws_ami" "win2016" {
  most_recent = true
  owners      = ["801119661308"]  # Microsoft's Windows AMIs owner (verify for your region)
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
  instance_type          = "t3.medium"  # Adjust as needed
  key_name               = var.key_name
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = false  # We'll attach an Elastic IP

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  tags = {
    Name          = var.vm_name
    AdminUser     = var.admin_username
    ResourceGroup = var.resource_group_name
  }
}

###############################
# EIP Association
###############################
resource "aws_eip_association" "eip_assoc" {
  allocation_id = aws_eip.eip.allocation_id
  instance_id   = aws_instance.vm.id
}

###############################
# Outputs
###############################
output "secret_value" {
  description = "The admin password stored in Secrets Manager (sensitive)"
  value       = aws_secretsmanager_secret_version.vm_admin_password_version.secret_string
  sensitive   = true
}

output "vm_id" {
  description = "The ID of the Windows EC2 instance"
  value       = aws_instance.vm.id
}
