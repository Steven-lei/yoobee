resource "aws_launch_template" "webserver_template" {
  name_prefix   = "${var.prefix}-webserver-template-"
  image_id      = var.webserver_ami_id  #golden AMI ID
  instance_type = "t2.micro" # Free tier eligible
  key_name      = aws_key_pair.yoobee.key_name   # 

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Private IP: $(hostname -I)" > /var/www/html/myip.html
            EOF
  )

  tag_specifications {
    resource_type="instance"
    tags = {
      Name = "${var.prefix}-webserver-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}