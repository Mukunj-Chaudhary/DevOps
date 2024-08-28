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
  ami           = "ami-0e86e20dae9224db8"
  instance_type = "t2.micro"
  key_name        = aws_key_pair.TF_Key.key_name
  //security_groups = ["SG"]
  vpc_security_group_ids = [aws_security_group.SG.id]
  subnet_id = aws_subnet.EC2-vpc-subnet-01.id
  for_each = toset(["jenkins-master", "build-slave", "ansible"])
   tags = {
     Name = "${each.key}"
   }
}


resource "aws_security_group" "SG" {
  name        = "SG"
  description = "SSH Access"
  vpc_id = aws_vpc.EC2-vpc.id
  
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
  
resource "aws_vpc" "EC2-vpc" {
  cidr_block       = "10.1.0.0/16"
  tags = {
    Name = "Ec2-vpc"
  }
}

resource "aws_subnet" "EC2-vpc-subnet-01" {
  vpc_id = aws_vpc.EC2-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"
  tags = {
    Name = "EC2-vpc-subnet-01"
  }
}


resource "aws_subnet" "EC2-vpc-subnet-02" {
  vpc_id = aws_vpc.EC2-vpc.id
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1b"
  tags = {
    Name = "EC2-vpc-subnet-02"
  }
}


resource "aws_internet_gateway" "EC2-igw" {
  vpc_id = aws_vpc.EC2-vpc.id 
  tags = {
    Name = "EC2-igw"
  } 
}

resource "aws_route_table" "EC2-public-rt" {
  vpc_id = aws_vpc.EC2-vpc.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.EC2-igw.id 
  }
}

resource "aws_route_table_association" "EC2-rta-public-subnet-01" {
  subnet_id = aws_subnet.EC2-vpc-subnet-01.id
  route_table_id = aws_route_table.EC2-public-rt.id   
}


resource "aws_route_table_association" "EC2-rta-public-subnet-02" {
  subnet_id = aws_subnet.EC2-vpc-subnet-02.id
  route_table_id = aws_route_table.EC2-public-rt.id   
}


