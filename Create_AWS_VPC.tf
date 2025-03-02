provider "aws" {
  region = "eu-west-1"  # Similar to Azure's "westeurope"
}

###############################
# VPC and Networking
###############################

resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "myVirtualNetwork"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "default"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw-myVPC"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-public"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

###############################
# Security Group
###############################
resource "aws_security_group" "win_sg" {
  name        = "win-sg"
  description = "Allow RDP access"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow RDP (TCP 3389)"
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
    Name = "win-sg"
  }
}

###############################
# Network Interfaces (ENIs) for VM1 and VM2
###############################
resource "aws_network_interface" "eni_vm1" {
  subnet_id       = aws_subnet.public.id
  private_ips     = ["192.168.0.10"]  # Adjust as needed
  security_groups = [aws_security_group.win_sg.id]
  tags = {
    Name = "myVm1-eni"
  }
}

resource "aws_network_interface" "eni_vm2" {
  subnet_id       = aws_subnet.public.id
  private_ips     = ["192.168.0.20"]  # Adjust as needed
  security_groups = [aws_security_group.win_sg.id]
  tags = {
    Name = "myVm2-eni"
  }
}

###############################
# Elastic IPs and Associations
###############################
resource "aws_eip" "eip_vm1" {
  vpc = true
  tags = {
    Name = "myVm1-eip"
  }
}

resource "aws_eip" "eip_vm2" {
  vpc = true
  tags = {
    Name = "myVm2-eip"
  }
}

resource "aws_eip_association" "eip_assoc_vm1" {
  allocation_id       = aws_eip.eip_vm1.allocation_id
  network_interface_id = aws_network_interface.eni_vm1.id
}

resource "aws_eip_association" "eip_assoc_vm2" {
  allocation_id       = aws_eip.eip_vm2.allocation_id
  network_interface_id = aws_network_interface.eni_vm2.id
}

###############################
# Windows Server 2016 AMI Lookup
###############################
data "aws_ami" "win2016" {
  most_recent = true
  owners      = ["amazon"]

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
# Windows EC2 Instances
###############################
resource "aws_instance" "vm1" {
  ami           = data.aws_ami.win2016.id
  instance_type = "m5.large"  # Similar to Standard_D2s_v3 in Azure
  key_name      = "my-key"    # Replace with your key pair name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.eni_vm1.id
  }

  tags = {
    Name = "myVm1"
  }
}

resource "aws_instance" "vm2" {
  ami           = data.aws_ami.win2016.id
  instance_type = "m5.large"
  key_name      = "my-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.eni_vm2.id
  }

  tags = {
    Name = "myVm2"
  }
}

###############################
# Outputs
###############################
output "vm1_public_ip" {
  description = "Public IP address of myVm1"
  value       = aws_eip.eip_vm1.public_ip
}

output "vm2_public_ip" {
  description = "Public IP address of myVm2"
  value       = aws_eip.eip_vm2.public_ip
}
