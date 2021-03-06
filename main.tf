provider "aws" {
    region = "us-east-1"
    access_key = "xxxxxx"
    secret_key = "xxxxxx"
}

#create AWS key pair
#create vpc
#create Internet gateway
#create route table
#create a public and private subnets
#associate subnet with route table
#create security group to allow port 22,80,443
#create Ubuntu server and install apache2

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
  name ="apploadbalancer"
}
}
resource "aws_subnet" "masterc_private_subnet"{
vpc_id = aws_vpc.masterc-vpc.id
cidr_block = "10.0.1.0/24"
availablity_zone = "us-east-1a"
tags = {
  Environment = "testing"
  name ="compute"
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
resource "aws_lb" "testlb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public.masterc_public_subnet.id
}
resource "aws_instance" "web-server"{
ami = "ami-085925f297f89fce1"
instance_type = "t2.micro"
availablity_zone = "us-east-1a"
instance_count = 3
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
tags=
}


Testing 
Auto scaling
load load_balancer extra
