# AWS Lambda + API Gateway Demo with LocalStack, Java, Gradle, and Terraform

This repository demonstrates how to use [LocalStack](https://github.com/localstack/localstack) to locally develop and test an AWS Lambda function written in Java, expose it via API Gateway as a REST API, and manage all infrastructure using [Terraform](https://www.terraform.io/). The project is built with Gradle.

---

## Features

- **Local AWS Cloud**: Uses LocalStack to emulate AWS Lambda, API Gateway, SQS and IAM locally.
- **Java Lambda**: Example Lambda handlers in Java ([`com.example`](src/main/java/com/example/)).
- **REST API**: Exposes the Lambda via API Gateway as a `/hello` endpoint.
- **Infrastructure as Code**: All resources (Lambda, API Gateway, IAM roles) are defined in [Terraform](terraform).
- **Gradle Build**: Build and package the Lambda function using Gradle.

---

## Prerequisites

- [Docker](https://www.docker.com/) (for running LocalStack)
- [LocalStack CLI](https://docs.localstack.cloud/getting-started/)
- [Terraform](https://www.terraform.io/downloads.html)
- [Java 17+](https://adoptium.net/)
- [Gradle](https://gradle.org/) (or use the provided `gradlew` wrapper)

---

## Quick Start

### Configure AWS CLI

```sh
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
```

### 1. Start LocalStack

```sh
localstack start
```

### 2. Build the Java Lambda

```sh
./gradlew clean build
```

This produces the Lambda JAR at `build/libs/aws-localstack-java-lambda-1.0-SNAPSHOT-all.jar`.

### 3. Deploy Infrastructure with Terraform

```sh
terraform init
terraform apply
```

Terraform will:

- Create an IAM role for Lambda
- Deploy the Lambda function
- Create an API Gateway REST API with a `/hello` resource
- Integrate API Gateway with Lambda (AWS_PROXY)
- Grant API Gateway permission to invoke the Lambda

### 4. Invoke the REST API

After deployment, Terraform will output the invoke URL, e.g.:

```
hello_endpoint_url = http://localhost:4566/restapis/xgmzt9qyjw/dev/_user_request_/hello
```

Test the endpoint:

```sh
curl -X POST "$hello_endpoint_url" -d 'World' -H "Content-Type: application/json"
```

---

### Invoke the Lambda directly:

```sh
aws --endpoint-url=http://localhost:4566 lambda invoke \
  --function-name sqs-sender-lambda \
  --cli-binary-format raw-in-base64-out \
  --payload '"Hello from LocalStack!"' \
  response.json
```

---

## Project Structure

- [`src/main/java/com/example/`](src/main/java/com/example/LambdaHandler.java): Java Lambda handlers.
- [`build.gradle`](build.gradle): Gradle build file.
- [`terraform`](terraform): Terraform configuration files.

---

## Cleaning Up

To remove all resources:

```sh
terraform destroy
```

---

## References

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda Java Programming Model](https://docs.aws.amazon.com/lambda/latest/dg/java-handler.html)

---

## License

See [aws/THIRD_PARTY_LICENSES](aws/THIRD_PARTY_LICENSES) for third-party licenses.