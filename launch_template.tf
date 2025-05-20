# resource "aws_launch_template" "webserver_template" {
#   name_prefix   = "${var.prefix}-webserver-template-"
#   image_id      = var.webserver_ami_id  #golden AMI ID
#   instance_type = "t2.micro" # Free tier eligible
#   key_name      = aws_key_pair.yoobee.key_name   # 
  
#   vpc_security_group_ids = [
#     aws_security_group.web_sg.id
#   ]

#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               apt update -y
#               apt install apache2 -y
#               echo "Private IP: $(hostname -I)" > /var/www/html/index.html
#               systemctl enable apache2
#               systemctl start apache2
#             EOF
#   )

#   tag_specifications {
#     resource_type="instance"
#     tags = {
#       Name = "${var.prefix}-webserver-instance"
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }