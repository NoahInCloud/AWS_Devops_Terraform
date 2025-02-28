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
variable "vm_name" {
  description = "Name of the virtual machine"
  default     = "myVM"
}

variable "admin_username" {
  description = "Admin username for the VM (for tagging purposes)"
  default     = "adminuser"
}

variable "key_name" {
  description = "Name of the EC2 key pair to enable Windows login"
  default     = "my-key"
}

###############################
# Random Suffix for DNS Name
###############################
resource "random_string" "dns_suffix" {
  length  = 4
  special = false
  upper   = false
}

###############################
# VPC and Networking (simulating Azure virtual network/subnet)
###############################
resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "myVNet"
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
# Elastic IP (simulating a public IP with random DNS suffix)
###############################
resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "myPublicIP-${random_string.dns_suffix.result}"
  }
}

###############################
# Security Group (allowing RDP)
###############################
resource "aws_security_group" "sg" {
  name        = "mySG"
  description = "Allow RDP (TCP 3389)"
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
# Windows Server 2016 AMI Lookup
###############################
data "aws_ami" "win2016" {
  most_recent = true
  owners      = ["801119661308"]  # Microsoft Windows AMIs (check for your region)
  
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################
# Windows EC2 Instance
###############################
resource "aws_instance" "vm" {
  ami                    = data.aws_ami.win2016.id
  instance_type          = "t3.medium"  # Adjust instance type as needed; similar to Standard_DS1_v2 in performance
  subnet_id              = aws_subnet.subnet.id
  key_name               = var.key_name
  associate_public_ip_address = false  # We'll assign a static public IP via EIP
  vpc_security_group_ids = [aws_security_group.sg.id]

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

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
output "vm_id" {
  description = "The ID of the Windows EC2 instance"
  value       = aws_instance.vm.id
}

output "public_ip" {
  description = "The public IP address of the instance"
  value       = aws_eip.eip.public_ip
}
