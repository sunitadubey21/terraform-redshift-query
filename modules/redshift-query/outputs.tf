variable "default_callback_url" {
  default = "http://localhost:8080/auth/callback"
}
output "cognito_login_url" {
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.us-east-1.amazoncognito.com/login?response_type=code&client_id=${aws_cognito_user_pool_client.client.id}&redirect_uri=${var.default_callback_url}"
}
