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

resource "aws_dynamodb_table_item" "redshift_query" {
  for_each = local.redshift_queries

  table_name = aws_dynamodb_table.rest_api_dynamo_db_table.name
  hash_key   = aws_dynamodb_table.rest_api_dynamo_db_table.hash_key

  item = <<-ITEM
    {
      "full_api_url": {"S": "${aws_api_gateway_deployment.api_deployment.rest_api_id}.execute-api.${data.aws_region.this.name}.amazonaws.com/${each.key}"},
      "redshift_query": {"S": "${each.value}"},
      "redshift_user": {"S": "admin"},
      "redshift_instance": {"S": "cencosud-redshift-cluster"},
      "redshift_cross_acct_iam_role_arn": {"S": "arn:aws:iam::350711180666:role/cencosud-cross-account-redshift-role"}
    }
  ITEM
}