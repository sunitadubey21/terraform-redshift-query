resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "cencosud-api"
  description = "cencosud API Gateway"
}

resource "aws_api_gateway_authorizer" "rest_api_authorizer" {
  name          = "cencosud-api-cognito-user-pool-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  provider_arns = [
    aws_cognito_user_pool.rest_api_user_pool.arn
  ]
}

# GET /users
resource "aws_api_gateway_resource" "get_users_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "users"
}
resource "aws_api_gateway_method" "get_users_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.get_users_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.rest_api_authorizer.id
  request_parameters = {
    "method.request.path.proxy" = true,
  }
}
resource "aws_api_gateway_integration" "get_users_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.get_users_resource.id
  http_method             = aws_api_gateway_method.get_users_api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.redshift_query_lambda.invoke_arn
}

# GET /credit_cards
resource "aws_api_gateway_resource" "get_credit_cards_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "credit_cards"
}
resource "aws_api_gateway_method" "get_credit_cards_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.get_credit_cards_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.rest_api_authorizer.id

  request_parameters = {
    "method.request.path.proxy" = true,
  }
}
resource "aws_api_gateway_integration" "get_credit_cards_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.get_credit_cards_resource.id
  http_method             = aws_api_gateway_method.get_credit_cards_api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.redshift_query_lambda.invoke_arn
}

# GET /items
resource "aws_api_gateway_resource" "get_items_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "items"
}

resource "aws_api_gateway_method" "get_items_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.get_items_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.rest_api_authorizer.id

  request_parameters = {
    "method.request.path.proxy" = true,
  }
}

resource "aws_api_gateway_integration" "get_items_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.get_items_resource.id
  http_method             = aws_api_gateway_method.get_items_api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.redshift_query_lambda.invoke_arn
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
    aws_api_gateway_integration.get_users_api_integration,
    aws_api_gateway_integration.get_credit_cards_api_integration,
    aws_api_gateway_integration.get_items_api_integration
  ]

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.rest_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}
