variable "webserver_ami_id" {
  type        = string
  description = "AMI ID to launch EC2 instances(A Gold Image for wordpress)"
  default = "ami-084568db4383264d4"
}

# variable "webserver_instance_type" {
#   type        = string
#   default     = "t2.micro"
# }

