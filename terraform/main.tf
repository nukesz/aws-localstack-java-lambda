# -----------------------------------------------------------------------------
# 🟡 PROVIDER CONFIGURATION
# -----------------------------------------------------------------------------
# This configures the AWS provider to talk to LocalStack instead of real AWS.
# LocalStack exposes AWS-compatible APIs at localhost:4566.

provider "aws" {
  access_key                  = "test"  # Dummy credentials, required by AWS provider
  secret_key                  = "test"
  region                      = "us-east-1"  # Must match the region used in URIs

  # Skip real AWS validations (only needed for LocalStack)
  skip_credentials_validation = true
  skip_metadata_api_check     = true

  # Point AWS services to LocalStack endpoints
  endpoints {
    lambda     = "http://localhost:4566"
    apigateway = "http://localhost:4566"
    iam        = "http://localhost:4566"
    s3         = "http://localhost:4566"
    sqs        = "http://localhost:4566"
  }
}

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs#custom-service-endpoints

# -----------------------------------------------------------------------------
# 🟢 IAM ROLE FOR LAMBDA
# -----------------------------------------------------------------------------
# Lambda functions need a role (even in LocalStack). This one is fake but satisfies the requirement.

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

#resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
#  role       = aws_iam_role.lambda_exec_role.name
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AwsLambdaBasicExecutionRole"
#}

# -----------------------------------------------------------------------------
# 🧠 LAMBDA FUNCTION DEPLOYMENT
# -----------------------------------------------------------------------------
# This uploads the Java Lambda function and makes it runnable.

resource "aws_lambda_function" "my_lambda" {
  function_name = "my-java-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "com.example.LambdaHandler::handleRequest" # Java class with the handleRequest method
  runtime       = var.java_runtime_version

  filename           = "${path.module}/../${var.jar_file_location}"
  source_code_hash   = filebase64sha256("${path.module}/../${var.jar_file_location}")
}

# filename: Path to the JAR file.
# handler: Java package and class of your handler.
# source_code_hash: Forces update when JAR changes.

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function


# -----------------------------------------------------------------------------
# 🌐 API GATEWAY SETUP
# -----------------------------------------------------------------------------
# Creates the REST API named "MyLocalAPI"

resource "aws_api_gateway_rest_api" "api" {
  name = "MyLocalAPI"
}

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api


# -----------------------------------------------------------------------------
# 🔗 /hello RESOURCE UNDER THE ROOT "/"
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "hello"  # The URL path will be /hello
}

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource


# -----------------------------------------------------------------------------
# 🔃 Define HTTP Method for /hello — POST only (no auth)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "hello_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "POST"
  authorization = "NONE"
}

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method


# -----------------------------------------------------------------------------
# 🔌 Integrate API Gateway with Lambda (AWS_PROXY)
# -----------------------------------------------------------------------------
# This tells API Gateway to forward POST requests to the Lambda

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.hello_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${aws_lambda_function.my_lambda.arn}/invocations"
}

# type = "AWS_PROXY" tells API Gateway to pass the full request to Lambda

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration


# -----------------------------------------------------------------------------
# 🛡️ Grant API Gateway Permission to Invoke Lambda
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:us-east-1:000000000000:${aws_api_gateway_rest_api.api.id}/*/POST/hello"
}

# LocalStack ignores some permissions but this is required by Terraform

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission



# -----------------------------------------------------------------------------
# 🚀 Deploy API Gateway to a stage (e.g. /dev)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = timestamp()
  }
  # Ensure the integration is created first
  depends_on = [aws_api_gateway_integration.lambda_integration]
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id

  lifecycle {
    create_before_destroy = true
  }
}

# Learn more:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment
