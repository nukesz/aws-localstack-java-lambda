# 1. Create an SQS Queue
resource "aws_sqs_queue" "demo_queue" {
  name = "demo-queue"
}

# 2. IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Action    = "sts:AssumeRole",
      Principal = { 
        Service = "lambda.amazonaws.com" 
      }
    }]
  })
}

# 3. IAM Policy for sending messages to SQS
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "lambda_sqs_policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["sqs:SendMessage"],
        Resource = aws_sqs_queue.demo_queue.arn
      }
    ]
  })
}

# 4. Lambda Function
resource "aws_lambda_function" "sqs_sender" {
  function_name = "sqs-sender-lambda"
  runtime       = var.java_runtime_version
  handler       = "com.example.SqsSenderLambda::handleRequest"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../${var.jar_file_location}"
  source_code_hash = filebase64sha256("${path.module}/../${var.jar_file_location}")

  environment {
    variables = {
      QUEUE_URL    = aws_sqs_queue.demo_queue.id
      SQS_ENDPOINT = "http://localhost:4566"
    }
  }
}