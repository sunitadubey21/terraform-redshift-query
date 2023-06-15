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
}

resource "aws_iam_role_policy_attachment" "aws_lambda_basic_execution_role_attachment" {
  role       = aws_iam_role.rest_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "aws_lambda_vpc_access_execution_role_attachment" {
  role       = aws_iam_role.rest_api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "rest_api_lambda_sg" {
  name   = "cencosud-api-lambda-sg"
  vpc_id = var.vpc_id

  egress {
    description = "Allow all external traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

  environment {
    REDSHIFT_CLUSTER = aws_redshift_cluster.redshift_cluster.cluster_identifier
    REDSHIFT_DATABASE = aws_redshift_cluster.redshift_cluster.database_name
  }

  #layers = var.util_layer_arn_array
  vpc_config {
    security_group_ids = [aws_security_group.rest_api_lambda_sg.id]
    subnet_ids         = [data.aws_subnets.private-subnets.ids[0]]
  }
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "cencosud-api-gateway-execution"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redshift_query_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.rest_api.id}/*"
}
