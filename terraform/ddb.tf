resource "aws_dynamodb_table_item" "ddb_table_seeder" {
  table_name = aws_dynamodb_table.ddb_table.name
  hash_key   = aws_dynamodb_table.ddb_table.hash_key

  item = <<ITEM
{
  "id": {
    "N": "1"
  },
  "count": {
    "N": "0"
  }
}
ITEM
}

resource "aws_dynamodb_table" "ddb_table" {
  name         = "WebVisitorCounter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "N"
  }

}