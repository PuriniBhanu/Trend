terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# ********VPC*******
resource "aws_vpc" "trend_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "trend-vpc"
  }
}

# ******Subnet********

resource "aws_subnet" "trend_subnet" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "trend-subnet"
  }
}

# ******Internet Gateway******

resource "aws_internet_gateway" "trend_igw" {
  vpc_id = aws_vpc.trend_vpc.id
}

# ****** Route Table *********

resource "aws_route_table" "trend_rt" {
  vpc_id = aws_vpc.trend_vpc.id
}

resource "aws_route" "trend_route" {
  route_table_id         = aws_route_table.trend_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.trend_igw.id
}

resource "aws_route_table_association" "trend_assoc" {
  subnet_id      = aws_subnet.trend_subnet.id
  route_table_id = aws_route_table.trend_rt.id
}

#********** Security Group ************
resource "aws_security_group" "trend_sg" {
  vpc_id = aws_vpc.trend_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ******* IAM Role for EC2******

resource "aws_iam_role" "ec2_role" {
  name = "trend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "trend-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# *****EC2 Jenkins******
resource "aws_instance" "trend_ec2" {
  ami                    = "ami-0317b0f0a0144b137"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.trend_subnet.id
  vpc_security_group_ids = [aws_security_group.trend_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  key_name = "guvi_mumbai"  

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install java-17-amazon-corretto -y
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              yum install jenkins -y
              systemctl enable jenkins
              systemctl start jenkins
              EOF

  tags = {
    Name = "trend-jenkins-server"
  }
}

# *******Output******

output "public_ip" {
  value = aws_instance.trend_ec2.public_ip
}