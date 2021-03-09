provider "aws" {
    region = "us-east-1"
    access_key = "provide the access key"
    secret_key = "provide the secret key"
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
resource "aws_security_group" "sg-xxxxxxxx" {
  name        = "sersg-mastersec"
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
      Name = "sg-mastersec"
  }
}
resource "aws_network_interface" "ni" {
  subnet_id       = aws_subnet.master-public-subnet.id
  private_ips     = ["10.0.1.24"]
  security_groups = ["aws_security_group.sg-xxxxxxxx.id"]
  attachment {
    instance     = aws_instance.foobar1.id
    device_index = 1
  }
}
resource "aws_eip" "elasticip"{
  vpc      = true
  network_interface ="aws_network_interface.id"
  associate_with_private_ip = "10.0.1.24"
  depends_on = [aws_internet_gateway.mastergw]
}
resource "aws_launch_template" "foobar" {
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  cpu_options {
    core_count       = 4
    threads_per_core = 2
  }

  credit_specification {
    cpu_credits = "standard"
  }

  disable_api_termination = true

  ebs_optimized = true

  elastic_gpu_specifications {
    type = "test"
  }

  elastic_inference_accelerator {
    type = "eia1.medium"
  }

  iam_instance_profile {
    name = "test"
  }

  image_id = "ami-042e8287309f5df03"

  instance_initiated_shutdown_behavior = "terminate"

  instance_market_options {
    market_type = "spot"
  }

  instance_type = "t2.micro"

  kernel_id = "test"

  key_name = "test"

  license_specification {
    license_configuration_arn = "arn:aws:license-manager:us-east-1:123456789012:license-configuration:lic-0123456789abcdef0123456789abcdef"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
  }

  placement {
    availability_zone = "us-east-1"
  }

  ram_disk_id = "test"

  vpc_security_group_ids = ["sg-xxxxxxxx"]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "test"
    }
  }

  user_data = <<-EOF
         #! /bin/bash
         sudo yum install httpd -y
         sudo systemctl start httpd
         sudo systemctl enable httpd
         echo "<h1> sample webserver </h1> >> var /var/www/html/index.html
  EOF      
}
resource "aws_autoscaling_group" "bar" {
  availability_zones = ["us-east-1"]
  desired_capacity   = 3
  max_size           = 5
  min_size           = 2
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
security_groups = ["aws_security_group.sg-xxxxxxxx.id"]
key_name = "don"
associate_public_ip_address = true
user_data = <<-EOF
         #! /bin/bash
         sudo yum install httpd -y
         sudo systemctl start httpd
         sudo systemctl enable httpd
         echo "<h1> sample webserver </h1> >> var /var/www/html/index.html
  EOF       

}
