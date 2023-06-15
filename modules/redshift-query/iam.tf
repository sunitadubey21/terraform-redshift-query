resource "aws_iam_role" "role_api_gateway" {
  name = "role_cencosud_api_gateway_lambda"

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
  role       = aws_iam_role.role_api_gateway.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

