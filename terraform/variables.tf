variable "java_runtime_version" {
  description = "Runtime for all Java Lambdas"
  default     = "java17"
}

variable "jar_file_location" {
  description = "Location of the JAR file to be used by the Lambda function"
  type        = string
  default     = "build/libs/aws-localstack-java-lambda-1.0-SNAPSHOT-all.jar"
}