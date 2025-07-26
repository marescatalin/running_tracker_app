resource "aws_scheduler_schedule" "invoke_lambda_schedule" {
  name = "InvokeLambdaSchedule"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "rate(1 day)"
  target {
    arn      = aws_lambda_function.lambda1.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ "input" : "This message was sent using EventBridge Scheduler!" })
  }
}