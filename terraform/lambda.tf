# -----------------------------------------------------------------------------
# 🧠 LAMBDA FUNCTION DEPLOYMENT
# -----------------------------------------------------------------------------
# This uploads the Java Lambda function and makes it runnable.

# === Lambda 1: Api Gateway handler  ===
resource "aws_lambda_function" "my_lambda" {
  function_name = "my-java-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "com.example.LambdaHandler::handleRequest" # Java class with the handleRequest method
  runtime       = var.java_runtime_version

  filename           = "${path.module}/../${var.jar_file_location}"
  source_code_hash   = filebase64sha256("${path.module}/../${var.jar_file_location}")
}

# === Lambda 2: SQS Sender ===
resource "aws_lambda_function" "sqs_sender" {
  function_name = "sqs-sender-lambda"
  runtime       = var.java_runtime_version
  handler       = "com.example.SqsSenderLambda::handleRequest"
  role          = aws_iam_role.lambda_exec_role.arn

  filename         = "${path.module}/../${var.jar_file_location}"
  source_code_hash = filebase64sha256("${path.module}/../${var.jar_file_location}")

  environment {
    variables = {
      QUEUE_URL    = aws_sqs_queue.demo_queue.id
      SQS_ENDPOINT = "http://localhost.localstack.cloud:4566"
    }
  }
}


# === Lambda 2: Processor Lambda ===
resource "aws_lambda_function" "sqs_processor" {
  function_name = "sqs-processor-lambda"
  runtime       = var.java_runtime_version
  handler       = "com.example.SqsProcessorLambda::handleRequest"
  role          = aws_iam_role.lambda_exec_role.arn

  filename         = "${path.module}/../${var.jar_file_location}"
  source_code_hash = filebase64sha256("${path.module}/../${var.jar_file_location}")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.message_hashes.name
      REGION     = "us-east-1"
      ENDPOINT   = "http://localhost.localstack.cloud:4566"
    }
  }
}


# filename: Path to the JAR file.
# handler: Java package and class of your handler.
# source_code_hash: Forces update when JAR changes.

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function