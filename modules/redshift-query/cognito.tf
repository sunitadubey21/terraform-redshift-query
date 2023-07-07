resource "aws_cognito_user_pool" "rest_api_user_pool" {
  name = "cencosud-api-user-pool"

  email_verification_subject = "Your Verification Code"
  email_verification_message = "Please use the following code: {####}"
  alias_attributes           = ["email"]
  auto_verified_attributes   = ["email"]

  password_policy {
    minimum_length    = 6
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  username_configuration {
    case_sensitive = false
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = true

    string_attribute_constraints {
      min_length = 3
      max_length = 256
    }
  }
}

// Create an App client
resource "aws_cognito_user_pool_client" "client" {
  name         = "cencosudtestuser_client"
  user_pool_id = aws_cognito_user_pool.rest_api_user_pool.id
  // We can configure additional providers like Facebook, Google, etc
  supported_identity_providers = [
    "COGNITO",
  ]
  callback_urls                        = var.identity_provider_callback_urls
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  allowed_oauth_scopes = [
    "email",
    "openid",
    "phone","profile","aws.cognito.signin.user.admin"
  ]
}

resource "aws_cognito_user_pool_domain" "main" {
  user_pool_id = aws_cognito_user_pool.rest_api_user_pool.id
  domain       = var.cognito_user_pool_domain
}

resource "aws_cognito_user" "example" {
  user_pool_id = aws_cognito_user_pool.rest_api_user_pool.id
  username     = "cognitotestuser2"
  password     = "Test123456*"
  attributes = {
    email          = "no-reply@hashicorp.com"
    email_verified = true
  }
}
