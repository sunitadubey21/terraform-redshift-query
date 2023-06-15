resource "aws_apigatewayv2_api" "gateway" {
  name          = "example_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "auth" {
  api_id           = aws_apigatewayv2_api.gateway.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://${aws_cognito_user_pool.pool.endpoint}"
  }
}

resource "aws_apigatewayv2_integration" "int" {
  api_id             = aws_apigatewayv2_api.gateway.id
  integration_type   = "AWS_PROXY"
  connection_type    = "INTERNET"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.welcome_check_in_message_lambda.invoke_arn
}

# resource "aws_apigatewayv2_route" "route" {
#   api_id              = aws_apigatewayv2_api.gateway.id
#   route_key           = "GET /example"  # Corrige el formato de la ruta aquí
#   target              = "integrations/${aws_apigatewayv2_integration.int.id}"
#   authorization_type  = "JWT"
#   authorizer_id       = aws_apigatewayv2_authorizer.auth.id
# }

resource "aws_apigatewayv2_route" "getUsers" {
  api_id             = aws_apigatewayv2_api.gateway.id
  route_key          = "GET /get_users" # Correct the format of the route here
  target             = "integrations/${aws_apigatewayv2_integration.int.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_apigatewayv2_route" "getCreditCards" {
  api_id             = aws_apigatewayv2_api.gateway.id
  route_key          = "GET /get_credit_cards"
  target             = "integrations/${aws_apigatewayv2_integration.int.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_apigatewayv2_route" "getItems" {
  api_id             = aws_apigatewayv2_api.gateway.id
  route_key          = "GET /get_items"
  target             = "integrations/${aws_apigatewayv2_integration.int.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "cencosud-api"
  description = "cencosud API Gateway"
}

resource "aws_api_gateway_authorizer" "api_authorizer" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  provider_arns = [aws_cognito_user_pool.cognito_user_pool.arn]
}

resource "aws_api_gateway_resource" "check_in_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "check-in"
}

resource "aws_api_gateway_method" "check_in_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.check_in_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id

  request_parameters = {
    "method.request.path.proxy" = true,
  }
}

resource "aws_api_gateway_integration" "check_in_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.check_in_resource.id
  http_method             = aws_api_gateway_method.check_in_api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.welcome_check_in_message_lambda.invoke_arn
}

# resource "aws_api_gateway_method_response" "check_in_method_response" {
#   #for_each    = toset(var.api_status_response)
#   rest_api_id = aws_api_gateway_rest_api.rest_api.id
#   resource_id = aws_api_gateway_resource.check_in_resource.id
#   http_method = aws_api_gateway_method.check_in_api_method.http_method
#   status_code = each.value
# }

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = "DEV"
  depends_on  = [
    aws_api_gateway_method.check_in_api_method,
    aws_api_gateway_integration.check_in_api_integration
  ]
  lifecycle {
    create_before_destroy = true
  }
}
