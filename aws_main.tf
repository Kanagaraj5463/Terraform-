provider "aws" {
    region = "us-east-1"
    access_key = "xxxxx.  provide key pair.  xxxxxxxxxx"
    secret_key = "xxxxx.  provide key pair.  xxxxxxxxxx"
}

resource "aws_vpc" "master-vpc"{
cidr_block= "10.0.0.0/16"
tags = {
  Environment = "testing"
}
}
resource "aws_internet_gateway" "mastergw"{
vpc_id = aws_vpc.master-vpc.id
}
resource "aws_route_table" "master-route-table"{
vpc_id = aws_vpc.master-vpc.id
route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.mastergw.id
}
}
resource "aws_subnet" "master-public-subnet"{
vpc_id = aws_vpc.master-vpc.id
cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1a"
}
resource "aws_subnet" "master-private-subnet"{
vpc_id = aws_vpc.master-vpc.id
cidr_block = "10.0.101.0/24"
availability_zone = "us-east-1a"
}
resource "aws_security_group" "ser" {
  name        = "ser"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.master-vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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
      Name = "ser"
  }
}
resource "aws_network_interface" "ni" {
  subnet_id       = aws_subnet.master-public-subnet.id
  private_ips     = ["10.0.2.24"]
  security_groups = [aws_security_group.ser.id]
  }
resource "aws_eip" "elasticip"{
  vpc      = true
  network_interface ="aws_network_interface.ni.id"
  associate_with_private_ip = "10.0.2.24"
  depends_on = [aws_internet_gateway.mastergw]
}
resource "aws_launch_template" "foobar" {
  name_prefix   = "foobar"
  image_id      = "ami-042e8287309f5df03"
  instance_type = "t2.micro"
}
resource "aws_autoscaling_group" "bar" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  launch_template {
    id      = aws_launch_template.foobar.id
    version = "$Latest"
  }
}
#create an EC2 instance and start the web server 
resource "aws_instance" "foobar1"{
ami = "ami-042e8287309f5df03"
instance_type = "t2.micro"
availability_zone = "us-east-1a"
security_groups = [ "${aws_security_group.ser.name}" ]
key_name = "don"
user_data = <<-EOF
         #! /bin/bash
         sudo yum install httpd -y
         sudo systemctl start httpd
         sudo systemctl enable httpd
         echo "<h1> sample webserver </h1> >> var /var/www/html/index.html
  EOF       

}
