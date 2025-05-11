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

locals {
  openvpn_ami_id = (
    contains(keys(var.openvpn_ami_map), var.region) ?
    var.openvpn_ami_map[var.region] :
    var.custom_ami_id
  )
}
resource "aws_instance" "openvpn" {
  ami                    = local.openvpn_ami_id       # Use a valid OpenVPN AMI ID
  instance_type          = "t2.micro" # Free tier eligible
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.openvpn_sg.id]
  key_name               = aws_key_pair.yoobee.key_name   #var.key_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.prefix}-openvpn"
  }
}