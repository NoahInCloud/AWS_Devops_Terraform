provider "aws" {
  region = "eu-west-1"  # Similar to Azure's "westeurope"
}

###############################
# VPC and Networking
###############################

# Create a VPC (simulating the Azure Virtual Network)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example-vnet"
  }
}

# Create a public subnet (similar to your Azure subnet)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "example-subnet"
  }
}

# Internet Gateway for outbound Internet connectivity
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "example-igw"
  }
}

# Route Table to direct Internet traffic from the subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the public subnet with the route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

###############################
# Security Group for the Windows Instance
###############################
resource "aws_security_group" "win_sg" {
  name        = "win-sg"
  description = "Allow RDP access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow RDP (TCP 3389)"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "win-sg"
  }
}

###############################
# Windows Server 2019 AMI Lookup
###############################
data "aws_ami" "win2019" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################
# Windows Virtual Machine (EC2 Instance)
###############################
resource "aws_instance" "winvm" {
  ami           = data.aws_ami.win2019.id
  instance_type = "m5.large"   # Approximate AWS equivalent for a Standard_D2s_v3 workload
  subnet_id     = aws_subnet.public.id
  key_name      = "my-key"     # Replace with your existing AWS key pair name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.win_sg.id]

  tags = {
    Name = var.vm_name  # Using the same variable as in your Azure config ("tw-win2019")
  }
}

###############################
# Outputs
###############################
output "vm_id" {
  description = "The ID of the Windows virtual machine."
  value       = aws_instance.winvm.id
}
