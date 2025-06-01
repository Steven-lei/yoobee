variable "prefix" {
  description = "prefix for tags"
  default = "yoobee"
}

variable "region" {
  description = "region"
  type=string
  default = "ap-southeast-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type = string
  default = "10.10.0.0/16"
}

variable "vpn_azs" {
  description = "Availability zone for the vpn subnet"
  default     = ["ap-southeast-2a"]
}

variable "public_azs" {
  description = "Availability zone for the public subnet"
  default     = ["ap-southeast-2b","ap-southeast-2c"]
}
variable "private_azs" {
  description = "Availability zone for the private subnet"
  default     = ["ap-southeast-2b","ap-southeast-2c"]
}

# variable "key_name" {
#   description = "EC2 Key Pair"
#   type        = string
# }

variable "alb_certificate_arn" {
  description = "ARN of the SSL certificate in ACM"
  type        = string
  default = "arn:aws:acm:ap-southeast-2:615299744642:certificate/87dad769-42b8-448b-a212-be20145070dc"
}