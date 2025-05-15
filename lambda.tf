# resource "aws_iam_role" "lambda_exec_role" {
#   name = "lambda_snapshot_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = "sts:AssumeRole",
#       Effect = "Allow",
#       Principal = {
#         Service = "lambda.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy" "lambda_snapshot_policy" {
#   name = "lambda_snapshot_policy"
#   role = aws_iam_role.lambda_exec_role.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "ec2:DescribeInstances",
#           "ec2:DescribeVolumes",
#           "ec2:CreateSnapshot",
#           "ec2:CreateTags",
#           "ec2:DescribeSnapshots",
#           "ec2:CopySnapshot"
#         ],
#         Resource = "*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "S3:PubObject",
#           "S3:GetObject",
#           "S3:ListBucket"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_file = "${path.module}/lambda/lambda.py"
#   output_path = "${path.module}/lambda/lambda.zip"
# }

# resource "aws_lambda_function" "snapshot_lambda" {
#   function_name = "ec2-daily-snapshot"
#   role          = aws_iam_role.lambda_exec_role.arn
#   handler       = "lambda.lambda_handler"
#   runtime       = "python3.9"
#   filename      = data.archive_file.lambda_zip.output_path
#   timeout       = 60
#   environment {
#     variables = {
#       BUCKET_NAME = aws_s3_bucket.snapshot_bucket.bucket
#     }
#   }
# }

# resource "aws_cloudwatch_event_rule" "daily_trigger" {
#   name                = "daily-snapshot-rule"
#   schedule_expression = "rate(1 day)"
# }

# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.daily_trigger.name
#   target_id = "lambda"
#   arn       = aws_lambda_function.snapshot_lambda.arn
# }

# resource "aws_lambda_permission" "allow_cloudwatch" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.snapshot_lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
# }