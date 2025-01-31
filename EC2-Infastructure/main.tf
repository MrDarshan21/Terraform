terraform {
  required_version = "~> 1.1"
  required_providers {
    aws = {
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
  access_key = "         "
  secret_key = "         "
}

# Generate a TLS private key
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a key pair in AWS using the public key from the TLS resource
resource "aws_key_pair" "tf-key-pair" {
  key_name   = "tf-key-pair"
  public_key = tls_private_key.rsa.public_key_openssh
}

# Save the private key locally
resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tf-key-pair.pem"
}

# Security group
resource "aws_security_group" "mysg" {
  name = "my-sg1"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-sg1"
  }
}

# EC2 instances
resource "aws_instance" "myec2" {
  ami           = "ami-00bb6a80f01f03502"
  instance_type = "t2.micro"
  count         = 2

  vpc_security_group_ids = [aws_security_group.mysg.id]
  key_name               = aws_key_pair.tf-key-pair.key_name

  tags = {
    Name = "myinstance-${count.index + 1}"
  }
}
