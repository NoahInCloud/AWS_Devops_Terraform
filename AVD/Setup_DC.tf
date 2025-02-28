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
  region = var.location  # For example, "eu-west-1" to simulate Azure "westeurope"
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "Simulated resource group name (used for tagging)"
  type        = string
  default     = "ad-ds-rg"
}

variable "location" {
  description = "AWS region (e.g., eu-west-1)"
  type        = string
  default     = "eu-west-1"
}

variable "vnet_name" {
  description = "Name of the virtual network (for tagging)"
  type        = string
  default     = "ad-ds-vnet"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "ad-ds-subnet"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "ad-ds-vm"
}

variable "admin_username" {
  description = "Admin username for the VM (for tagging only)"
  type        = string
  default     = "Administrator"
}

variable "admin_password" {
  description = "Admin password for the VM (for tagging/demo purposes only)"
  type        = string
  sensitive   = true
  default     = "YourAdminPassword!"  # Do not hardcode passwords in production
}

variable "domain_name" {
  description = "The fully qualified domain name for the new forest"
  type        = string
  default     = "master.pri"
}

variable "netbios_name" {
  description = "The NetBIOS name for the new domain"
  type        = string
  default     = "MASTER"
}

variable "dsrm_password" {
  description = "Password for Directory Services Restore Mode"
  type        = string
  sensitive   = true
  default     = "yourpassword"  # Replace with a secure password
}

###############################
# Random Suffix for DNS-like Name
###############################
resource "random_integer" "dns_suffix" {
  min = 1000
  max = 9999
}

locals {
  dns_suffix = random_integer.dns_suffix.result
}

###############################
# VPC and Subnet (Simulating Virtual Network)
###############################
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name          = var.vnet_name
    ResourceGroup = var.resource_group_name
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.location}a"  # e.g., eu-west-1a
  map_public_ip_on_launch = false

  tags = {
    Name = var.subnet_name
  }
}

###############################
# Internet Gateway and Route Table
###############################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-${var.resource_group_name}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-${var.resource_group_name}"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

###############################
# Elastic IP (Simulating Public IP with DNS Name)
###############################
resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "mypublicdns${local.dns_suffix}"
  }
}

###############################
# Security Group (Allowing RDP for Management)
###############################
resource "aws_security_group" "sg" {
  name        = "ad-ds-sg"
  description = "Allow RDP access and other necessary ports"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # You may want to add additional rules for AD DS communications.
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ad-ds-sg"
  }
}

###############################
# Network Interface
###############################
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.4"]  # Optionally assign a static private IP (adjust as needed)
  security_groups = [aws_security_group.sg.id]

  tags = {
    Name = "ad-ds-nic"
  }
}

###############################
# Windows EC2 Instance (Using Windows Server 2016 Datacenter)
###############################
data "aws_ami" "win2016" {
  most_recent = true
  owners      = ["801119661308"]  # Microsoft Windows AMI owner ID; verify for your region
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
  instance_type          = "m5.large"  # Choose instance type comparable to Standard_DS2_v2
  key_name               = "my-key"    # Replace with your existing EC2 key pair name
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = false

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nic.id
  }

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  tags = {
    Name          = var.vm_name
    AdminUser     = var.admin_username
    ResourceGroup = var.resource_group_name
    # For demo purposes only; in production, never store passwords in tags.
    AdminPassword = var.admin_password
  }

  # Use user data to run a PowerShell script that installs AD DS.
  user_data = base64encode(<<EOF
<powershell>
# Download and execute the AD DS installation script from a public URL.
# Replace the URL with your actual script location.
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/YourUser/YourRepo/main/install-ad-ds.ps1" -OutFile "C:\\install-ad-ds.ps1"
# Execute the script with parameters.
powershell -ExecutionPolicy Unrestricted -File C:\\install-ad-ds.ps1 -domainName "${var.domain_name}" -netbiosName "${var.netbios_name}" -dsrmPassword "${var.dsrm_password}"
</powershell>
EOF
  )
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

output "private_ip" {
  description = "The private IP address assigned to the VM"
  value       = aws_network_interface.nic.private_ips[0]
}

output "public_ip" {
  description = "The public IP address of the Windows EC2 instance"
  value       = aws_eip.eip.public_ip
}
