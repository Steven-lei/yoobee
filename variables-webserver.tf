variable "webserver_ami_id" {
  type        = string
  description = "AMI ID to launch EC2 instances(A Gold Image for wordpress)"
  #default = "ami-0f5d1713c9af4fe30"  #AWS AMI
  default = "ami-0b8d56a4855e06134"
}


