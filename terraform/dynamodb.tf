# DynamoDB table to store message hashes
resource "aws_dynamodb_table" "message_hashes" {
  name         = "MessageHashes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}