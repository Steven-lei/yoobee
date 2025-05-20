# resource "aws_autoscaling_group" "web_asg" {
#   name                      = "${var.prefix}-web-asg"
#   desired_capacity          = 2
#   max_size                  = 3
#   min_size                  = 1
#   vpc_zone_identifier       = [for subnet in aws_subnet.public_subnets : subnet.id]
#   health_check_type         = "EC2"
#   health_check_grace_period = 300

#   target_group_arns = [aws_lb_target_group.web_tg.arn]  #target group

#   launch_template {
#     id      = aws_launch_template.webserver_template.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "Name"
#     value               = "${var.prefix}-webserver-asg"
#     propagate_at_launch = true
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }
# #scaleout while CPU usage > 70%
# resource "aws_autoscaling_policy" "scale_out" {
#   name                   = "${var.prefix}-scale-out"
#   scaling_adjustment     = 1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 300
#   autoscaling_group_name = aws_autoscaling_group.web_asg.name
# }

# resource "aws_cloudwatch_metric_alarm" "cpu_high" {
#   alarm_name          = "${var.prefix}-high-cpu"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = 120
#   statistic           = "Average"
#   threshold           = 70
#   alarm_description   = "Alarm when CPU exceeds 70% for 4 minutes"
#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.web_asg.name
#   }

#   alarm_actions = [aws_autoscaling_policy.scale_out.arn]
# }

# #scale in while CPU < 30%
# resource "aws_autoscaling_policy" "scale_in" {
#   name                   = "${var.prefix}-scale-in"
#   scaling_adjustment     = -1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 300
#   autoscaling_group_name = aws_autoscaling_group.web_asg.name
# }

# resource "aws_cloudwatch_metric_alarm" "cpu_low" {
#   alarm_name          = "${var.prefix}-low-cpu"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = 120
#   statistic           = "Average"
#   threshold           = 30
#   alarm_description   = "Alarm when CPU goes below 30% for 4 minutes"
#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.web_asg.name
#   }

#   alarm_actions = [aws_autoscaling_policy.scale_in.arn]
# }

# #Hooks for notification
# resource "aws_autoscaling_lifecycle_hook" "launching" {
#   name                   = "on-launch"
#   autoscaling_group_name = aws_autoscaling_group.web_asg.name
#   lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
#   notification_target_arn = aws_sns_topic.web_server_alerts.arn
#   role_arn                = aws_iam_role.asg_sns_role.arn
#   heartbeat_timeout       = 300
#   default_result          = "CONTINUE"
# }

# resource "aws_autoscaling_lifecycle_hook" "terminating" {
#   name                   = "on-terminate"
#   autoscaling_group_name = aws_autoscaling_group.web_asg.name
#   lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
#   notification_target_arn = aws_sns_topic.web_server_alerts.arn
#   role_arn                = aws_iam_role.asg_sns_role.arn
#   heartbeat_timeout       = 300
#   default_result          = "CONTINUE"
# }