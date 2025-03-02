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
  description = "Simulated resource group name (used for tagging)"
  type        = string
  default     = "myResourceGroup"
}

variable "location" {
  description = "AWS region (simulate Azure location)"
  type        = string
  default     = "eu-west-1"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "myVm"
}

variable "admin_username" {
  description = "Admin username for the VM (for tagging)"
  type        = string
  default     = "adminuser"
}

# Note: AWS Windows instances require a key pair rather than an admin password.
variable "key_name" {
  description = "EC2 key pair name for Windows login"
  type        = string
  default     = "my-key"
}

###############################
# Random Suffix for Public IP Tagging
###############################
resource "random_string" "dns_suffix" {
  length  = 4
  special = false
  upper   = false
}

###############################
# VPC and Subnet (Simulating Azure Virtual Network and Subnet)
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
# Elastic IP (Public IP with Random DNS-like Tag)
###############################
resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "myPublicIP-${random_string.dns_suffix.result}"
  }
}

###############################
# Security Group (Allow RDP)
###############################
resource "aws_security_group" "sg" {
  name        = "${var.vm_name}-sg"
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
    Name = "${var.vm_name}-sg"
  }
}

###############################
# Network Interface (Pre-created ENI)
###############################
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.10"]   # Choose a suitable static IP from your subnet's CIDR.
  security_groups = [aws_security_group.sg.id]

  tags = {
    Name = "myNic"
  }
}

###############################
# Windows EC2 Instance (using Windows Server 2016)
###############################
data "aws_ami" "win2016" {
  most_recent = true
  owners      = ["801119661308"]  # This owner ID is for Windows AMIs; verify for your region.
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
  ami           = data.aws_ami.win2016.id
  instance_type = "t3.medium"  # Adjust instance type as needed (similar to Standard_DS1_v2)
  key_name      = var.key_name

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
    Name      = var.vm_name
    AdminUser = var.admin_username
  }
}

###############################
# Associate the Elastic IP with the Network Interface
###############################
resource "aws_eip_association" "eip_assoc" {
  allocation_id       = aws_eip.eip.allocation_id
  network_interface_id = aws_network_interface.nic.id
}

###############################
# VPC Flow Logs (Simulating Azure Network Watcher)
###############################
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${aws_vpc.vpc.id}"
  retention_in_days = 14
}

resource "aws_iam_role" "flow_log_role" {
  name = "FlowLogRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "vpc-flow-logs.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name   = "FlowLogPolicy"
  role   = aws_iam_role.flow_log_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc_flow" {
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  traffic_type   = "ALL"
  vpc_id         = aws_vpc.vpc.id
  iam_role_arn   = aws_iam_role.flow_log_role.arn
}

###############################
# Outputs
###############################
output "vm_id" {
  description = "The ID of the Windows EC2 instance"
  value       = aws_instance.vm.id
}

output "network_watcher_id" {
  description = "The ID of the VPC Flow Log (simulating Network Watcher)"
  value       = aws_flow_log.vpc_flow.id
}
