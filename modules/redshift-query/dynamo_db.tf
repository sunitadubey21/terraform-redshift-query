resource "aws_dynamodb_table" "rest_api_dynamo_db_table" {
  name         = "cencosud-api-dynamo-db-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "full_api_url"

  attribute {
    name = "full_api_url"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      write_capacity,
      read_capacity
    ]
  }
}

resource "aws_dynamodb_table_item" "users_query" {
  table_name = aws_dynamodb_table.rest_api_dynamo_db_table.name
  hash_key   = aws_dynamodb_table.rest_api_dynamo_db_table.hash_key

  item = <<-ITEM
    {
      "full_api_url": {"S": "ipg7egro14.execute-api.ap-south-1.amazonaws.com/users"},
      "redshift_query": {"S": "SELECT * FROM USERS"}
    }
  ITEM
}