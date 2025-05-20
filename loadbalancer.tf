# #Security Group for Load Balancer
# #allowing HTTP / HTTPS

# resource "aws_security_group" "alb_sg" {
#   name        = "${var.prefix}-alb-sg"
#   description = "Allow HTTP from anywhere"
#   vpc_id      = aws_vpc.main-vpc.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.prefix}-alb-sg"
#   }
# }

# #Create Load Balancer

# resource "aws_lb" "web_alb" {
#   name               = "${var.prefix}-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]

#   tags = {
#     Name = "${var.prefix}-alb"
#   }
# }

# #Create Target Group
# resource "aws_lb_target_group" "web_tg" {
#   name     = "${var.prefix}-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main-vpc.id
#   target_type = "instance"

#   health_check {
#     path                = "/"
#     protocol            = "HTTP"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }

#   tags = {
#     Name = "${var.prefix}-tg"
#   }
# }

# # #create Listener
# # resource "aws_lb_listener" "http_listener" {
# #   load_balancer_arn = aws_lb.web_alb.arn
# #   port              = 80
# #   protocol          = "HTTP"

# #   default_action {
# #     type             = "forward"
# #     target_group_arn = aws_lb_target_group.web_tg.arn
# #   }
# #   # default_action {   #redirect to HTTPS
# #   #   type = "redirect"

# #   #   redirect {
# #   #     port        = "443"
# #   #     protocol    = "HTTPS"
# #   #     status_code = "HTTP_301"
# #   #   }
# #   # }
# # }

# #a more stricker policy: ELBSecurityPolicy-TLS-1-2-2021-06
# resource "aws_lb_listener" "https_listener" {
#   load_balancer_arn = aws_lb.web_alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"  #support TLS 1.0 1.1 1.2
#   certificate_arn   = var.alb_certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web_tg.arn
#   }
# }