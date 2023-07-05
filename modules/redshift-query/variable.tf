locals {
  endpoints = {
    "users" = ["GET"]
    "credit_cards" = ["GET"]
    "items" = ["GET"]
  }

  redshift_queries = {
    "users" = "SELECT * FROM USERS"
    "credit_cards" = "SELECT * FROM CREDIT_CARDS"
    "items" = "SELECT * FROM ITEMS"
  }

  flatten_endpoints = merge([
    for path, methods in local.endpoints : {
      for method in methods : "${method}.${path}" => {
        path   = path,
        method = method
      }
    }
  ]...)
}

variable "vpc_id" {
  type = string
}

variable "identity_provider_callback_urls" {
  type        = list(any)
  description = "List of allowed callback URLs for the identity providers"
  default     = ["https://oauth.pstmn.io/v1/callback"]
}

variable "cognito_user_pool_domain" {
  type        = string
  description = "Cognito domain"
  default     = "cencosudtestuser"
}
