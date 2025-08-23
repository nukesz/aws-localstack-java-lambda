# Create an SQS Queue
resource "aws_sqs_queue" "demo_queue" {
  name = "demo-queue"
}

# Event source mapping (connects queue to processor lambda)
resource "aws_lambda_event_source_mapping" "sqs_to_processor" {
  event_source_arn = aws_sqs_queue.demo_queue.arn
  function_name    = aws_lambda_function.sqs_processor.arn
  batch_size       = 1
}