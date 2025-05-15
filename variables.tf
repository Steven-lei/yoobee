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

variable "vpn_azs" {
  description = "Availability zone for the vpn subnet"
  default     = ["us-east-1a"]
}

variable "public_azs" {
  description = "Availability zone for the public subnet"
  default     = ["us-east-1a","us-east-1b","us-east-1c"]
}
variable "private_azs" {
  description = "Availability zone for the private subnet"
  default     = ["us-east-1b","us-east-1c"]
}

# variable "key_name" {
#   description = "EC2 Key Pair"
#   type        = string
# }

variable "alb_certificate_arn" {
  description = "ARN of the SSL certificate in ACM"
  type        = string
  default = "arn:aws:acm:us-east-1:615299744642:certificate/adb88281-3883-4526-9e52-2ae10d07405a"
}