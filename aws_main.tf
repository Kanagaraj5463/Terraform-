provider "aws" {
    region = "us-east-1"
    version = "~> 0.12.6"
    access_key = "xxxxxx"
    secret_key = "xxxxxx"
}

#create AWS key pair to access AWS profile
#create VPC
#create Internet gateway
#create route table
#create a public and private subnets
#associate subnet with route table
#create security group to allow port 22,80,443 
#create autoscaling group and configuration
#create application load balancer 
#create Ubuntu server with latest AMI and install apache2

resource "aws_vpc" "masterc-vpc"{
cidr_block= "10.0.0.0/16"
tags = {
  Environment = "testing"
}
}
resource "aws_internet_gateway" "masterc_internet_gateway"{
vpc_id = aws_vpc.masterc-vpc.id
}
resource "aws_route_table" "masterc_route_table"{
vpc_id = aws_vpc.masterc-vpc.id

route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.masterc_internet_gateway.id
}
}
resource "aws_subnet" "masterc_public_subnet"{
vpc_id = aws_vpc.masterc-vpc.id
cidr_block = "10.0.101.0/24"
availablity_zone = "us-east-1a"
tags = {
  Environment = "testing"
  name ="public-subnet-for-apploadbalancer"
}
}
resource "aws_subnet" "masterc_private_subnet"{
vpc_id = aws_vpc.masterc-vpc.id
cidr_block = "10.0.1.0/24"
availablity_zone = "us-east-1a"
tags = {
  Environment = "testing"
  name ="private-subnet-for-compute-instances"
}
}
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.masterc-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.masterc-vpc."0.0.0.0/0"]
  }
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_web"
  }
}
resource "aws_network_interface" "webserver-nic" {
  subnet_id       = aws_subnet.masterc_public_subnet.id
  private_ips     = ["10.0.102.50"]
  security_groups = [aws_security_group.allow_web.id]
  }
}
resource "aws_eip" "elasticip" {
  vpc      = true
  network_interface ="aws_network_interface.webserver-nic.id"
  associate_with_private_ip = "10.0.102.50"
  depends_on = [aws_internet_gateway.masterc_internet_gateway]
}
resource "aws_placement_group" "test" {
  name     = "test"
  strategy = "cluster"
}
resource "aws_autoscaling_group" "masterc1" {
  name                      = "terraform-test"
  max_size                  = 10
  min_size                  = 5
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  placement_group           = aws_placement_group.test.id
  launch_configuration      = aws_launch_template.vmconfig.name
  vpc_zone_identifier       = [aws_subnet.masterc_public_subnet.id, aws_subnet.masterc_private_subnet.id]
  initial_lifecycle_hook {
    name                 = "masterc"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    notification_metadata = <<EOF
{
  "mas": "masterc1"
}
EOF
    notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
    role_arn                = "arn:aws:iam::123456789012:role/S3Access"
  }
  tag {
    key                 = "foo"
    value               = "masterc1"
    propagate_at_launch = true
  }
  timeouts {
    delete = "15m"
  }
  tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = false
  }
}
resource "aws_launch_template" "vmconfig" {
  name_prefix   = "masterc"
  image_id      = "ami-0d758c1134823146a"
  instance_type = "t2.micro"
}
resource "aws_autoscaling_group" "masterc1" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  launch_template {
    id      = aws_launch_template.vmconfig.id
  }
}
resource "aws_lb" "applb" {
  name               = "app"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = aws_subnet.public.masterc_public_subnet.id
  enable_deletion_protection = true
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-applb"
    enabled = true
    subnet_mapping {
    subnet_id     = aws_subnet.masterc_public_subnet.id
    allocation_id = aws_eip.elasticip.id
  }
  }
  tags = {
    Environment = "testing"
  }
}
resource "aws_instance" "web-server"{
ami = "ami-0d758c1134823146a"
instance_type = "t2.micro"
availablity_zone = "us-east-1a"
instance_count = 1
key_name = "main-key"
network_interface {
 device_index = 0
 network_interface_id = aws_network_interface.webserver-nic.id
}
user_data = <<-network_interface
             #!/bin/bash
             sudo apt update -y
             sudo apt install apache2 -y
             sudo systemctl start apache2
             sudo bash -c 'echo your very first web server > /var/www/html/index.html'
             EOF
}
