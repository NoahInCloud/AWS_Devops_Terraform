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
# Variables and Random Suffix
###############################
variable "resource_group_name" {
  description = "Simulated resource group name (used for tagging)"
  type        = string
  default     = "myResourceGroupSecureWeb"
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
  description = "Admin username for the VM (for tagging)"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM (to be stored in Secrets Manager – note: Windows EC2 uses a key pair for console access)"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!!"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "tw"
}

resource "random_integer" "id" {
  min = 1000
  max = 9999
}

locals {
  keyvault_name = "${var.prefix}key-vault-${random_integer.id.result}"
}

###############################
# VPC and Networking (Simulating Virtual Network, Subnet, Public IP)
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

resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "myPublicIpAddress"
  }
}

###############################
# Security Group (Allowing HTTPS on Port 443)
###############################
resource "aws_security_group" "sg" {
  name        = "myNetworkSecurityGroup"
  description = "Allow HTTPS inbound"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
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
    Name = "myNetworkSecurityGroup"
  }
}

###############################
# AWS Secrets Manager: Simulate Key Vault Certificate
###############################
resource "aws_secretsmanager_secret" "cert" {
  name        = "mycert"
  description = "Simulated certificate for IIS"
}

resource "aws_secretsmanager_secret_version" "cert_version" {
  secret_id     = aws_secretsmanager_secret.cert.id
  secret_string = "CERTIFICATE_DATA_PLACEHOLDER"
}

###############################
# Windows EC2 Instance with Certificate from Secrets Manager
###############################
data "aws_ami" "win2016" {
  most_recent = true
  owners      = ["801119661308"]  # Microsoft Windows AMIs owner; verify in your region.
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
  instance_type = "t3.medium"
  key_name      = "my-key"  # Replace with your existing EC2 key pair name.
  subnet_id     = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = false

  # Use user data to install IIS and configure it with the certificate.
  user_data = base64encode(<<EOF
<powershell>
# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Simulate retrieving the certificate from Secrets Manager.
# In a real scenario, you might use AWS SSM Agent or a custom script to pull the secret.
$certData = "CERTIFICATE_DATA_PLACEHOLDER"
Write-Output "Certificate retrieved: $certData"

# Configure IIS to use the certificate (placeholder logic)
Write-Output "Configuring IIS with the certificate..."
</powershell>
EOF
  )

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }

  tags = {
    Name          = var.vm_name
    ResourceGroup = var.resource_group_name
    AdminUser     = var.admin_username
  }
}

resource "aws_eip_association" "eip_assoc" {
  allocation_id = aws_eip.eip.allocation_id
  instance_id   = aws_instance.vm.id
}

###############################
# VPC Flow Logs (Simulating Network Watcher)
###############################
resource "aws_cloudwatch_log_group" "flow_log" {
  name              = "/aws/vpc/flow-log-${aws_vpc.vpc.id}"
  retention_in_days = 7
}

resource "aws_iam_role" "flow_log_role" {
  name = "FlowLogRole-${aws_vpc.vpc.id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name = "FlowLogPolicy-${aws_vpc.vpc.id}"
  role = aws_iam_role.flow_log_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "${aws_cloudwatch_log_group.flow_log.arn}:*"
    }]
  })
}

resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_cloudwatch_log_group.flow_log.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id
  iam_role_arn         = aws_iam_role.flow_log_role.arn
}

###############################
# Outputs
###############################
output "public_ip" {
  description = "The public IP address of the secure web app"
  value       = aws_eip.eip.public_ip
}
