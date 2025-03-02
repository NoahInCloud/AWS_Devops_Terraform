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
  region = "eu-west-1"  # Equivalent to WestEurope
}

###############################
# Variables
###############################
variable "resource_group" {
  description = "Simulated resource group name (for tagging)"
  default     = "myResourceGroupScaleSet"
}

variable "location" {
  description = "AWS region (should match provider region)"
  default     = "eu-west-1"
}

variable "vnet_name" {
  description = "Name of the virtual network (for tagging)"
  default     = "myVnet"
}

variable "subnet_name" {
  description = "Name of the subnet"
  default     = "mySubnet"
}

variable "scale_set_name" {
  description = "Name of the scale set"
  default     = "myScaleSet"
}

variable "public_ip_name" {
  description = "Name for the public IP (for tagging)"
  default     = "myPublicIPAddress"
}

variable "load_balancer_name" {
  description = "Name of the load balancer"
  default     = "myLoadBalancer"
}

variable "admin_username" {
  description = "Admin username for the scale set (for tagging)"
  default     = "adminuser"
}

variable "key_name" {
  description = "EC2 key pair name for Windows login"
  default     = "my-key"
}

###############################
# Random Suffix for Naming
###############################
resource "random_string" "dns_suffix" {
  length  = 4
  special = false
  upper   = false
}

###############################
# Networking: VPC, Subnet, Internet Gateway, Route Table
###############################
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.vnet_name
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnet_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-${var.vnet_name}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-${var.vnet_name}"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

###############################
# Load Balancer (ALB)
###############################
resource "aws_lb" "alb" {
  name               = var.load_balancer_name
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet.id]

  tags = {
    Name = var.load_balancer_name
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.scale_set_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    path                = "/"
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.scale_set_name}-tg"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

###############################
# Security Group for Windows Instances (Allow RDP and HTTP)
###############################
resource "aws_security_group" "sg" {
  name        = "${var.scale_set_name}-sg"
  description = "Allow RDP and HTTP access"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "${var.scale_set_name}-sg"
  }
}

###############################
# Launch Template for Windows Instances
###############################
data "aws_ami" "win2016" {
  most_recent = true
  owners      = ["801119661308"]  # Microsoft Windows AMI owner ID; verify for your region.
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = var.scale_set_name
  image_id      = data.aws_ami.win2016.id
  instance_type = "m5.large"  # Similar performance to Standard_D2s_v3
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg.id]
  }

  user_data = base64encode(<<EOF
<powershell>
# Install IIS to simulate a custom script extension
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
</powershell>
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.scale_set_name
    }
  }
}

###############################
# Auto Scaling Group (ASG) for Windows Instances
###############################
resource "aws_autoscaling_group" "asg" {
  name                      = var.scale_set_name
  desired_capacity          = 3
  min_size                  = 2
  max_size                  = 10
  vpc_zone_identifier       = [aws_subnet.subnet.id]
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  target_group_arns         = [aws_lb_target_group.tg.arn]

  tag {
    key                 = "Name"
    value               = var.scale_set_name
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

###############################
# CloudWatch Alarms and Scaling Policies
###############################
# Scale-out alarm: CPU > 60%
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.scale_set_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "Scale out if CPU > 60% for 1 minute"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.scale_set_name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
}

# Scale-in alarm: CPU < 30%
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.scale_set_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Scale in if CPU < 30% for 1 minute"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.scale_set_name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
}
