#create a security group for web server, only allowing ssh from openvpn
resource "aws_security_group" "web_sg" {
  name        = "${var.prefix}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main-vpc.id

  # Inbound Rules
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from OpenVPN SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.openvpn_sg.id]
  }

  # Outbound Rule - Allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-web-sg"
  }
}
# resource "aws_instance" "testwebserver" {
#   ami                    = var.webserver_ami_id      # Use the gold image with wordpress and cloud agent
#   instance_type          = "t2.micro" # Free tier eligible
#   subnet_id              = values(aws_subnet.public_subnets)[0].id
#   vpc_security_group_ids = [aws_security_group.web_sg.id]
#   key_name               = aws_key_pair.yoobee.key_name   #var.key_name

#   user_data = <<-EOF
#               #!/bin/bash
#               apt update -y
#               apt install -y apache2
#               systemctl start apache2
#               systemctl enable apache2
#               echo "<html><body><h1>Private IP: $(hostname -I)</h1></body></html>" > /var/www/html/index.html
#               EOF

#   tags = {
#     Name = "${var.prefix}-testwebserver"
#   }
# }