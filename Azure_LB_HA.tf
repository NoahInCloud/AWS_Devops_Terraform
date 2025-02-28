provider "aws" {
  region = "eu-west-1"  # Similar to Azure "westeurope"
}

###############################
# VPC and Networking
###############################

resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "tw-aws-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tw-aws-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tw-aws-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "tw-aws-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

###############################
# Security Group for Instances
###############################
resource "aws_security_group" "instance_sg" {
  name        = "tw-instance-sg"
  description = "Allow HTTP (80) and RDP (3389) access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    Name = "tw-instance-sg"
  }
}

###############################
# Network Load Balancer (NLB)
###############################
resource "aws_lb" "nlb" {
  name               = "tw-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id]

  tags = {
    Name = "tw-nlb"
  }
}

###############################
# Target Groups and Health Checks
###############################

# HTTP target group: For front-end load balancing on port 80 across all instances
resource "aws_lb_target_group" "http_tg" {
  name     = "tw-http-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    protocol            = "HTTP"
    path                = "/"
  }

  tags = {
    Name = "tw-http-tg"
  }
}

# RDP target groups: Each for a single instance, forwarding to port 3389
resource "aws_lb_target_group" "rdp_tg_vm1" {
  name     = "tw-rdp-tg-vm1"
  port     = 3389
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    protocol            = "TCP"
  }

  tags = {
    Name = "tw-rdp-tg-vm1"
  }
}

resource "aws_lb_target_group" "rdp_tg_vm2" {
  name     = "tw-rdp-tg-vm2"
  port     = 3389
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    protocol            = "TCP"
  }

  tags = {
    Name = "tw-rdp-tg-vm2"
  }
}

resource "aws_lb_target_group" "rdp_tg_vm3" {
  name     = "tw-rdp-tg-vm3"
  port     = 3389
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    protocol            = "TCP"
  }

  tags = {
    Name = "tw-rdp-tg-vm3"
  }
}

###############################
# NLB Listeners
###############################

# Listener for HTTP (port 80)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_tg.arn
  }
}

# Listeners simulating inbound NAT for RDP:
# Each listens on a unique front-end port and forwards to a specific target group.

resource "aws_lb_listener" "rdp_listener_vm1" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 4221
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rdp_tg_vm1.arn
  }
}

resource "aws_lb_listener" "rdp_listener_vm2" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 4222
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rdp_tg_vm2.arn
  }
}

resource "aws_lb_listener" "rdp_listener_vm3" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 4223
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rdp_tg_vm3.arn
  }
}

###############################
# EC2 Windows Instances
###############################

# Lookup the latest Windows Server 2016 AMI (modify filters as needed)
data "aws_ami" "windows_2016" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# Instance vm1: Using instance type m5.large (approx. Standard_D2s_v3)
resource "aws_instance" "vm1" {
  ami                         = data.aws_ami.windows_2016.id
  instance_type               = "m5.large"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = "my-key"  # Replace with your key pair

  security_groups             = [aws_security_group.instance_sg.id]

  tags = {
    Name = "myVM1"
  }
}

# Instance vm2: Also m5.large
resource "aws_instance" "vm2" {
  ami                         = data.aws_ami.windows_2016.id
  instance_type               = "m5.large"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = "my-key"

  security_groups             = [aws_security_group.instance_sg.id]

  tags = {
    Name = "myVM2"
  }
}

# Instance vm3: Using t3.medium (approx. Standard_DS1_v2)
resource "aws_instance" "vm3" {
  ami                         = data.aws_ami.windows_2016.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = "my-key"

  security_groups             = [aws_security_group.instance_sg.id]

  tags = {
    Name = "myVM3"
  }
}

###############################
# Register Instances with Target Groups
###############################

# HTTP attachments (assumes an HTTP service on port 80)
resource "aws_lb_target_group_attachment" "vm1_http" {
  target_group_arn = aws_lb_target_group.http_tg.arn
  target_id        = aws_instance.vm1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "vm2_http" {
  target_group_arn = aws_lb_target_group.http_tg.arn
  target_id        = aws_instance.vm2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "vm3_http" {
  target_group_arn = aws_lb_target_group.http_tg.arn
  target_id        = aws_instance.vm3.id
  port             = 80
}

# RDP attachments: Forwarding traffic from each NAT listener to port 3389 on the corresponding instance.
resource "aws_lb_target_group_attachment" "vm1_rdp" {
  target_group_arn = aws_lb_target_group.rdp_tg_vm1.arn
  target_id        = aws_instance.vm1.id
  port             = 3389
}

resource "aws_lb_target_group_attachment" "vm2_rdp" {
  target_group_arn = aws_lb_target_group.rdp_tg_vm2.arn
  target_id        = aws_instance.vm2.id
  port             = 3389
}

resource "aws_lb_target_group_attachment" "vm3_rdp" {
  target_group_arn = aws_lb_target_group.rdp_tg_vm3.arn
  target_id        = aws_instance.vm3.id
  port             = 3389
}
