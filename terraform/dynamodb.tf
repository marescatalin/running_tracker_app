resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "DistanceRan"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Date"

  attribute {
    name = "Date"
    type = "S"
  }
}