#  1. Create openvpn sg allowing web admin UI
#  2. Create EC2 in public subnet installed with openvpn image


resource "aws_security_group" "openvpn_sg" {
  name        = "${var.prefix}-openvpn-sg"
  description = "Security group for  OpenVPN server"
  vpc_id      = aws_vpc.main-vpc.id

  # Allow TCP 943 (Admin Web UI)
  ingress {
    description = "Allow TCP 943 for OpenVPN Web UI"
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow TCP 1194 (OpenVPN traffic)
  ingress {
    description = "Allow TCP 1194 for OpenVPN tunnel"
    from_port   = 1194
    to_port     = 1194
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow TCP 443 (fallback HTTPS tunneling)
  ingress {
    description = "Allow TCP 443 for OpenVPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH from my IP
  ingress {
    description = "Allow SSH for OpenVPN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  # Egress - Allow all traffic (optional, or restrict as needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-openvpn-sg"
  }
}

#Elastic IP for VPN access server
resource "aws_eip" "vpnserver" {
  tags = {
    Name = "VPN-eip"
  }
}

resource "aws_instance" "openvpn" {
  ami                    = var.openvpn_ami_map[var.region]       # Use a valid OpenVPN AMI ID
  instance_type          = "t2.micro" # Free tier eligible
  subnet_id              = values(aws_subnet.vpn_subnets)[0].id
  vpc_security_group_ids = [aws_security_group.openvpn_sg.id]
  key_name               = aws_key_pair.yoobee.key_name   #var.key_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.prefix}-openvpn"
  }
}

resource "aws_eip_association" "vpnserver_assoc" {
  instance_id   = aws_instance.openvpn.id
  allocation_id = aws_eip.vpnserver.id
}

output "vpnserver_public_ip" {
  description = "the IP of VPN access server, use a VPN client to connect with after configuring"
  #value = aws_instance.openvpn.public_ip
  value = aws_eip.vpnserver.public_ip
}
output "vpnserver_private_ip" {

  value = aws_instance.openvpn.private_ip
}
output "vpnserver_ssh_connect" {
  description = "SSH command to connect to and confiugre the VPN Server"
  value = <<-EOT
VPN server has been launched. Be aware that the username could be root, ec2-user, or ubuntu depending on the AMI.
ssh -i ~/.ssh/yoobee-aws-key openvpnas@${aws_eip.vpnserver.public_ip}
EOT
}
