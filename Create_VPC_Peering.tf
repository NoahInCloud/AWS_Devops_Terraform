terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"  # Similar to Azure's westeurope
}

###############################
# VPC 1 and Subnet (simulating myVirtualNetwork1)
###############################
resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "myVirtualNetwork1"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Subnet1-vpc1"
  }
}

###############################
# VPC 2 and Subnet (simulating myVirtualNetwork2)
###############################
resource "aws_vpc" "vpc2" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "myVirtualNetwork2"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = "10.1.0.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Subnet1-vpc2"
  }
}

###############################
# VPC Peering Connection
###############################
resource "aws_vpc_peering_connection" "peering" {
  vpc_id      = aws_vpc.vpc1.id
  peer_vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "myVirtualNetwork1-myVirtualNetwork2"
  }
}

###############################
# Route Table in VPC1 to route traffic to VPC2
###############################
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    destination_cidr_block      = aws_vpc.vpc2.cidr_block
    vpc_peering_connection_id   = aws_vpc_peering_connection.peering.id
  }

  tags = {
    Name = "rt-vpc1"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt1.id
}

###############################
# Route Table in VPC2 to route traffic to VPC1
###############################
resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.vpc2.id

  route {
    destination_cidr_block      = aws_vpc.vpc1.cidr_block
    vpc_peering_connection_id   = aws_vpc_peering_connection.peering.id
  }

  tags = {
    Name = "rt-vpc2"
  }
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt2.id
}

###############################
# Outputs
###############################
output "vnet1_peering" {
  description = "Peering from myVirtualNetwork1 to myVirtualNetwork2"
  value       = aws_vpc_peering_connection.peering.status.code
}

output "vnet2_peering" {
  description = "Peering from myVirtualNetwork2 to myVirtualNetwork1"
  value       = aws_vpc_peering_connection.peering.status.code
}
