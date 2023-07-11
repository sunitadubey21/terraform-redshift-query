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

resource "aws_api_gateway_resource" "endpoint_resource" {
  for_each = local.endpoints

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = each.key
}
resource "aws_api_gateway_method" "endpoint_api_method" {
  for_each = local.flatten_endpoints

  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.endpoint_resource[each.value.path].id
  http_method   = each.value.method
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.rest_api_authorizer.id
  request_parameters = {
    "method.request.path.proxy" = true,
  }
}
resource "aws_api_gateway_integration" "endpoint_api_integration" {
  for_each = local.flatten_endpoints

  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.endpoint_resource[each.value.path].id
  http_method             = each.value.method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.redshift_query_lambda.invoke_arn

  request_parameters = {
    for key, value in var.query_params :
    "integration.request.querystring.${key}" => "'${value}'"
  }

}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on  = [
    aws_api_gateway_integration.endpoint_api_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = "DEV"

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.rest_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}
