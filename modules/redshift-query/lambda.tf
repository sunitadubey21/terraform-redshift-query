data "archive_file" "zip_code_redshift_query" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-redshift-query"
  output_path = "${path.module}/redshift-query.zip"
}

data "archive_file" "welcome_check_in_message_archive_file" {
  type        = "zip"
  source_dir  = "${path.module}/api-gateway/welcome-check-in-message-code"
  output_path = "${path.module}/welcome-check-in-message-code.zip"
}

resource "aws_lambda_function" "welcome_check_in_message_lambda" {
  filename      = "${path.module}/welcome-check-in-message-code.zip"
  function_name = "welcomecencosudCheckInMessage"
  role          = aws_iam_role.role_api_gateway.arn
  handler       = "main.handler"
  runtime       = "nodejs14.x"

  #layers = var.util_layer_arn_array

  source_code_hash = filebase64sha256(data.archive_file.welcome_check_in_message_archive_file.output_path)
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.welcome_check_in_message_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = aws_apigatewayv2_api.gateway.arn
  # "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.rest_api.id}/*/${aws_api_gateway_method.check_in_api_method.http_method}${aws_api_gateway_resource.check_in_resource.path}"
}
