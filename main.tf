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

#Elastic IP for NAT gateway
resource "aws_eip" "nat" {
  tags = {
    Name = "NAT-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public_subnets)[0].id  
}

# Create Private Route Table
resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.main-vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.prefix}-private-routetable"
  }
}

#Create Public Subnets
resource "aws_subnet" "vpn_subnets" {
  for_each = toset(var.vpn_azs)
  vpc_id = aws_vpc.main-vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, index(var.vpn_azs, each.key))
  availability_zone = each.key
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.prefix}-vpn-subnet-${each.key}"
    Type = "vpn"
  }
}

#Create Public Subnets
resource "aws_subnet" "public_subnets" {
  for_each = toset(var.public_azs)
  vpc_id = aws_vpc.main-vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 10+index(var.public_azs, each.key))
  availability_zone = each.key
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.prefix}-public-subnet-${each.key}"
    Type = "public"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = toset(var.private_azs)
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 100+index(var.private_azs, each.key))
  availability_zone = each.key

  tags = {
    Name = "${var.prefix}-private-subnet-${each.key}"
    Type = "private"
  }
}

#association for vpn subnets
resource "aws_route_table_association" "route-table-association-vpn" {
  for_each = { for az, subnet in aws_subnet.vpn_subnets : az => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public-route.id
}

#association for public subnets
resource "aws_route_table_association" "route-table-association-public" {
  for_each = { for az, subnet in aws_subnet.public_subnets : az => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public-route.id
}

#association for private subnets
resource "aws_route_table_association" "route-table-association-private" {
  for_each = { for az, subnet in aws_subnet.private_subnets : az => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private-route.id
}