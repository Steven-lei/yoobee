resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_snapshot_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_snapshot_policy" {
  name = "lambda_snapshot_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:DescribeSnapshots",
          "ec2:CopySnapshot"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.snapshot_bucket.arn,
          "${aws_s3_bucket.snapshot_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = "sns:Publish",
        Resource = aws_sns_topic.web_server_alerts.arn
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda.py"
  output_path = "${path.module}/lambda/lambda.zip"
}

resource "aws_lambda_function" "create_snapshot" {
  function_name = "ec2-daily-snapshot"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 60
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.snapshot_bucket.bucket
      ASG_NAME = aws_autoscaling_group.web_asg.name 
    }
  }

}

resource "aws_lambda_function_event_invoke_config" "invoke_config" {
  function_name = aws_lambda_function.create_snapshot.function_name
  # set notification using the same sns topic of webserver alerts
  destination_config {
    on_success {
      destination = aws_sns_topic.web_server_alerts.arn
    }
    on_failure {
      destination = aws_sns_topic.web_server_alerts.arn
    }
  }
}

#Lambda invoke role
resource "aws_iam_role" "eventbridge_invoke_lambda" {
  name = "eventbridge_invoke_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "scheduler.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "invoke_lambda_policy" {
  name = "invoke_lambda_policy"
  role = aws_iam_role.eventbridge_invoke_lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "lambda:InvokeFunction",
      Resource = aws_lambda_function.create_snapshot.arn
    }]
  })
}

resource "aws_scheduler_schedule" "lambda_schedule" {
  name       = "daily-snapshot-scheduler"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(17 17 * * ? *)"  # min hour dayofmonth month dayofweek year 
  schedule_expression_timezone = "Pacific/Auckland"
  target {
    arn      = aws_lambda_function.create_snapshot.arn
    role_arn = aws_iam_role.eventbridge_invoke_lambda.arn

    input = jsonencode({
      "message": "Triggered by EventBridge Scheduler"
    })
  }
}
################################

## RUN A Lambda manually
# aws lambda invoke \
#   --function-name ec2-daily-snapshot \
#   --payload "$(echo '{"message":"sync test"}' | base64)" \
#   response.json
# {
#     "StatusCode": 200,
#     "ExecutedVersion": "$LATEST"
# }
##################################

# resource "aws_cloudwatch_event_rule" "daily_trigger" {
#   name                = "daily-snapshot-rule"
#   schedule_expression = "cron(0 12 * * ? *)"  # 12:00 AM NZST (UTC+12)  min,hour,day of month,month,dayofweek, year
# }

# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.daily_trigger.name
#   target_id = "lambda"
#   arn       = aws_lambda_function.create_snapshot.arn
# }

# resource "aws_lambda_permission" "allow_cloudwatch" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.create_snapshot.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
# }