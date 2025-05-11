# Configure the AWS Provider
provider "aws" {
  region = var.region
}

#Fetch my public IP 
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

#convert my IP to CIDR format
locals {
  my_ip_cidr = "${data.http.my_ip.response_body}/32"
}

#use a keypair precreated
#it can be created by executing: ssh-keygen -t rsa -b 4096 -f ~/.ssh/yoobee-aws-key
resource "aws_key_pair" "yoobee" {
  key_name   = "yoobee-aws-key"
  public_key = file("~/.ssh/yoobee-aws-key.pub")
}

#Create VPC
resource "aws_vpc" "main-vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.prefix}_vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "internetgw" {
  vpc_id = aws_vpc.main-vpc.id
  tags = {
    Name = "${var.prefix}_internetgw"
  }
}

# Create Route Table
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.main-vpc.id

  # route for internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetgw.id
  }
  tags = {
    Name = "${var.prefix}-public-routetable"
  }
}

#Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main-vpc.id
  cidr_block = var.public_subnet_cidr
  availability_zone = var.public_az
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.prefix}-public-subnet"
    Type = "public"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_az

  tags = {
    Name = "${var.prefix}-private-subnet"
    Type = "private"
  }
}

#association for public subnet
resource "aws_route_table_association" "route-table-association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public-route.id
}