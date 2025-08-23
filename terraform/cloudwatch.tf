resource "aws_cloudwatch_event_rule" "minute" {
  name                = "minute-trigger"
  schedule_expression = "rate(1 minute)"   # or cron expression
}

# EventBridge -> Lambda target, with custom input payload
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.minute.name
  target_id = "sqs_sender"
  arn       = aws_lambda_function.sqs_sender.arn

  # Dummy payload passed into the Lambda as the event
  input     = "{\"commands\":[\"halt\"]}"
}

# Permission for EventBridge to invoke the Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs_sender.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.minute.arn
}
