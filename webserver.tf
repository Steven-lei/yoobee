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
# IAM Role for EC2 
resource "aws_iam_role" "ec2_secrets_role" {
  name = "ec2-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy to allow Secrets Manager access
resource "aws_iam_policy" "secrets_manager_read_policy" {
  name = "SecretsManagerReadPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      Resource = data.aws_secretsmanager_secret.db_secret.arn
    },
    {
      Effect = "Allow",
      Action = [
        "secretsmanager:ListSecrets"
      ],
      Resource = "*"
    }]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secrets_manager_read_policy.arn
}

# Create an Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-secrets-instance-profile"
  role = aws_iam_role.ec2_secrets_role.name
}

################################# WEB SERVER TESTING ##############################
#    can be used to create a gold image for webserver template
#
resource "aws_security_group" "test_ssh_sg" {
  name        = "${var.prefix}-test-ssh"
  description = "allowing SSH access from specific IP for testing"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description = "SSH from My IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    
    cidr_blocks = [local.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-test-ssh"
  }
}

resource "aws_instance" "testwebserver" {
  ami                    = var.webserver_ami_id      # Use the gold image with wordpress and cloud agent
  instance_type          = "t2.micro" # Free tier eligible
  subnet_id              = values(aws_subnet.public_subnets)[0].id
  vpc_security_group_ids = [
                        aws_security_group.web_sg.id,
                        aws_security_group.test_ssh_sg.id
                        ]
  key_name               = aws_key_pair.yoobee.key_name   #var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
#!/bin/bash
apt update -y

mkdir -p /var/www/html
#create a status page with auto refresh
echo "<html><head><meta http-equiv=\"refresh\" content=\"5\"><title>Setup Progress</title></head><body><h2>Creating web page on: $(hostname -I)</h2>" > /var/www/html/index.html


echo "Step 1: Installing Apache...<br>" >> /var/www/html/index.html
#install php and wordpress
sudo apt install -y apache2 

#start web service so that we can know the server status by refreshing the page
systemctl start apache2
systemctl enable apache2

  
echo "Step 2: Installing PHP and php-mysql...<br>" >> /var/www/html/index.html
sudo apt install -y php php-mysql

echo "Step 3: Downloading WordPress...<br>" >> /var/www/html/index.html

#download wordpress
curl -O https://wordpress.org/latest.tar.gz 

echo "Step 4: Extracting WordPress...<br>" >> /var/www/html/index.html  
tar xzvf latest.tar.gz 

echo "Step 5: Moving WordPress to web root...<br>" >> /var/www/html/index.html
cp -a wordpress /var/www/html/ 
chown -R www-data:www-data /var/www/html/wordpress 


#create test page for php
echo "Step 6: Creating test php page...<br>" >> /var/www/html/index.html
echo "<?php echo \$_SERVER['SERVER_ADDR']; phpinfo(); ?>" > /var/www/html/phpinfo.php

echo "Step 7: Restarting Apache...<br>" >> /var/www/html/index.html
systemctl restart apache2 

echo "<h2>Setup Complete</h2></body></html>" >> /var/www/html/index.html
EOF

  tags = {
    Name = "${var.prefix}-testwebserver"
  }
}

output "testwebserver-publicip" {
  description = "Public IP of test webserver"
  value       = aws_instance.testwebserver.public_ip
}
output "testwebserver_ssh_connect" {
  description = "SSH command to connect to and confiugre the web Server"
  value = <<-EOT
    webserver has been launched.
    ssh -i ~/.ssh/yoobee-aws-key ubuntu@${aws_instance.testwebserver.public_ip}
    accessing webpage: http://${aws_instance.testwebserver.public_ip}
    accessing phpinfo: http://${aws_instance.testwebserver.public_ip}/phpinfo.php
    accessing wordpress admin page: http://${aws_instance.testwebserver.public_ip}/wordpress/wp-admin
    EOT
}


######################################## END OF WEB SERVER TESTING ########################