provider "aws" {
  region = "eu-north-1" # Change to your desired AWS region
}

# Create a new VPC
resource "aws_vpc" "gh_actions_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "gh-actions-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "gh_actions_subnet" {
  vpc_id                  = aws_vpc.gh_actions_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a" # Change as needed
  tags = {
    Name = "gh-actions-public-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gh_actions_igw" {
  vpc_id = aws_vpc.gh_actions_vpc.id
  tags = {
    Name = "gh-actions-igw"
  }
}

# Create a route table and associate it with the subnet
resource "aws_route_table" "gh_actions_route_table" {
  vpc_id = aws_vpc.gh_actions_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gh_actions_igw.id
  }
  tags = {
    Name = "gh-actions-route-table"
  }
}

resource "aws_route_table_association" "gh_actions_rta" {
  subnet_id      = aws_subnet.gh_actions_subnet.id
  route_table_id = aws_route_table.gh_actions_route_table.id
}


resource "aws_security_group" "gh_actions_sg" {
  name_prefix = "gh-actions-sg"
  vpc_id      = aws_vpc.gh_actions_vpc.id

  # Allow SSH
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort traffic (adjust the port if necessary)
  ingress {
    description = "Allow NodePort traffic"
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all egress traffic
  egress {
    description = "Allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gh-actions-security-group"
  }
}


# Launch an EC2 Instance
resource "aws_instance" "gh_actions_instance" {
  ami           = var.aws_ami
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.gh_actions_subnet.id
  key_name      = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.gh_actions_sg.id]

  tags = {
    Name = "gh-actions-instance"
  }
}
