#SNS Topic
resource "aws_sns_topic" "web_server_alerts" {
  name = "web-server-state-notifications"
}

# IAM Role for ASG lifecycle hooks to publish to SNS
resource "aws_iam_role" "asg_sns_role" {
  name = "asg-lifecycle-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "autoscaling.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "asg_sns_policy" {
  role = aws_iam_role.asg_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sns:Publish",
        Resource = aws_sns_topic.web_server_alerts.arn
      }
    ]
  })
}

# SNS Subscriptions 
resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each  = toset(var.notification_emails)
  topic_arn = aws_sns_topic.web_server_alerts.arn
  protocol  = "email"
  endpoint  = each.key
}

resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "asg-instance-state-change"
  description = "Detect ASG EC2 instance running/stopping"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"],
    "detail": {
      "state": ["running", "stopping", "terminated"]
    }
  })
}

#Add SNS topic as target
resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "sns-target"
  arn       = aws_sns_topic.web_server_alerts.arn
}