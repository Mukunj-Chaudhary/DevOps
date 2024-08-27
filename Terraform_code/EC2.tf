terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.64.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


#Create Private Key Pair to connect to server
resource "aws_key_pair" "TF_Key" {
  key_name   = "TF-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

# RSA Public key for server of size 4096 bits
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "TF_Key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "TF_Key"
}


resource "aws_instance" "Demo" {
  ami           = "ami-066784287e358dad1"
  instance_type = "t2.micro"
  key_name        = aws_key_pair.TF_Key.key_name
  security_groups = ["SG"]
}


resource "aws_security_group" "SG" {
  name        = "SG"
  description = "SSH Access"
  
  ingress {
    description      = "Shh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-prot"

  }
}