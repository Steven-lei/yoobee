#Varaibles for OpenVPN 


#default AMIs
variable "openvpn_ami_map" {
  description = "Map of OpenVPN AMIs per region"
  type = map(string)

  # these image need to be subscribed
  default = {
    "us-east-1"      = "ami-06e5a963b2dadea6f" 
    "ap-southeast-2" = "ami-056303ef214800fec"
    # Add more regions and corresponding AMI IDs as needed
  }
}

