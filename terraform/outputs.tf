# -----------------------------------------------------------------------------
# 📤 OUTPUT: Lambda Function Name
# -----------------------------------------------------------------------------

output "lambda_function_name" {
  description = "The name of the deployed Lambda function"
  value       = aws_lambda_function.my_lambda.function_name
}

# -----------------------------------------------------------------------------
# 📤 OUTPUT: API Gateway REST API ID
# -----------------------------------------------------------------------------

output "api_gateway_id" {
  description = "The ID of the created API Gateway REST API"
  value       = aws_api_gateway_rest_api.api.id
}

# -----------------------------------------------------------------------------
# 🌐 OUTPUT: Invoke URL for /hello endpoint
# -----------------------------------------------------------------------------

output "hello_endpoint_url" {
  description = "Invoke URL for the /hello endpoint"
  value       = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.api.id}/dev/_user_request_/hello"
}



resource "aws_iam_role_policy" "lambda_logging" {
  name   = "lambda_logging_policy"
  role   = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
