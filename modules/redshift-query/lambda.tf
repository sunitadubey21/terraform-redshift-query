data "archive_file" "zip_code_redshift_query" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-redshift-query"
  output_path = "${path.module}/redshift-query.zip"
}

resource "aws_iam_role" "rest_api_lambda_role" {
  name = "cencosud-api-lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name   = "assume-role-cross-account"
    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Action   = "sts:AssumeRole"
          Effect   = "Allow"
          # Here we have used same account. The account id will change if cross account redshift access needed
          Resource = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/cencosud-cross-account-redshift-role"
        }
      ]
    })
  }

  inline_policy {
    name   = "dynamo-db-access"
    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Action   = "dynamodb:GetItem"
          Effect   = "Allow"
          Resource = aws_dynamodb_table.rest_api_dynamo_db_table.arn
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "aws_lambda_basic_execution_role_attachment" {
  role       = aws_iam_role.rest_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "rest_api_lambda_log_group" {
  name              = "/aws/lambda/cencosud-api-lambda"
  retention_in_days = 1
}

resource "aws_lambda_function" "redshift_query_lambda" {
  depends_on = [
    aws_cloudwatch_log_group.rest_api_lambda_log_group
  ]

  filename         = data.archive_file.zip_code_redshift_query.output_path
  source_code_hash = filebase64sha256(data.archive_file.zip_code_redshift_query.output_path)

  function_name = "cencosud-api-lambda"
  role          = aws_iam_role.rest_api_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  timeout       = 60

  environment {
    variables = {
      REDSHIFT_CLUSTER       = aws_redshift_cluster.redshift_cluster.cluster_identifier
      REDSHIFT_DATABASE      = aws_redshift_cluster.redshift_cluster.database_name
      REDSHIFT_DATABASE_USER = aws_redshift_cluster.redshift_cluster.master_username
      DYNAMODB_TABLE         = aws_dynamodb_table.rest_api_dynamo_db_table.name
      ASSUME_ROLE_ARN        = aws_iam_role.cross_account_redshift_role.arn
    }
  }
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "cencosud-api-gateway-execution"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redshift_query_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:${aws_api_gateway_rest_api.rest_api.id}/*"
}
