provider "aws" {
  region = "eu-west-1"   # Adjust as needed (for example, equivalent to Azure's "westeurope")
}

# ---------------------------
# Networking (VPC, Subnet, Security Group)
# ---------------------------

# Create a VPC (equivalent to Azure's Virtual Network)
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "myVPC"
  }
}

# Create a Subnet (equivalent to Azure's Subnet)
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "mySubnet"
  }
}

# Create a Security Group (similar to an Azure NSG)
resource "aws_security_group" "my_sg" {
  name        = "mySecurityGroup"
  description = "Allow RDP access"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mySecurityGroup"
  }
}

# ---------------------------
# First Windows Instance (myVM)
# ---------------------------

# Allocate an Elastic IP for the first VM
resource "aws_eip" "vm1_eip" {
  vpc = true

  tags = {
    Name = "myVM_EIP"
  }
}

# Create the first Windows EC2 instance
resource "aws_instance" "vm1" {
  # Replace with an appropriate Windows Server 2019 AMI for your region
  ami           = "ami-xxxxxxxx"  
  instance_type = "m5.xlarge"   # Adjust instance type as needed (similar to Azure's Standard_DS3_v2)
  subnet_id     = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  
  # Associate a public IP automatically
  associate_public_ip_address = true
  
  key_name = "my-key"  # Provide your existing AWS key pair name

  tags = {
    Name = "myVM"
  }
}

# Associate the Elastic IP with the first instance
resource "aws_eip_association" "vm1_assoc" {
  instance_id   = aws_instance.vm1.id
  allocation_id = aws_eip.vm1_eip.allocation_id
}

# ---------------------------
# Second Windows Instance (myVM2)
# ---------------------------

# Allocate an Elastic IP for the second VM
resource "aws_eip" "vm2_eip" {
  vpc = true

  tags = {
    Name = "myVM2_EIP"
  }
}

# Create the second Windows EC2 instance
resource "aws_instance" "vm2" {
  # Replace with an appropriate Windows Server 2016 with Containers AMI for your region
  ami           = "ami-yyyyyyyy"  
  instance_type = "m5.xlarge"
  subnet_id     = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  
  associate_public_ip_address = true

  key_name = "my-key"

  tags = {
    Name = "myVM2"
  }
}

# Associate the Elastic IP with the second instance
resource "aws_eip_association" "vm2_assoc" {
  instance_id   = aws_instance.vm2.id
  allocation_id = aws_eip.vm2_eip.allocation_id
}

# ---------------------------
# VM Resizing Note
# ---------------------------
# To resize an EC2 instance, change the "instance_type" attribute and run "terraform apply".
# For example, update aws_instance.vm1.instance_type from "m5.xlarge" to another instance type.
