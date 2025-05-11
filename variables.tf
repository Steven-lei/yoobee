variable "prefix" {
  description = "prefix for tags"
  default = "yoobee"
}

variable "region" {
  description = "region"
  type=string
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type = string
  default = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.10.10.0/24"
}
variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.10.100.0/24"
}
variable "public_az" {
  description = "Availability zone for the public subnet"
  default     = "us-east-1a"
}
variable "private_az" {
  description = "Availability zone for the private subnet"
  default     = "us-east-1b"
}

#default AMIs
variable "openvpn_ami_map" {
  description = "Map of OpenVPN AMIs per region"
  type = map(string)
  default = {
    "us-east-1"      = "ami-0f88e80871fd81e91"
    "ap-southeast-2" = "ami-0a1234567890abcd1"
    # Add more regions and corresponding AMI IDs as needed
  }
}


variable "custom_ami_id" {
  description = "AMI ID for OpenVPN"
  type        = string
  default = "ami-0f88e80871fd81e91"
}

# variable "key_name" {
#   description = "EC2 Key Pair"
#   type        = string
# }

