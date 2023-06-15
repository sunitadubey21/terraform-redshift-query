#module "cencosud_cognito" {
  #source = "./modules/redshift-query/cognito"
#}

#module "util_layer" {
#  source = "./util-layer"
#}

module "redshift_layer" {
  source = "./modules/redshift-query"
  #aws_region             = var.aws_region
  #account_id             = var.account_id
}

#module "cencosud_api" {
#  source                 = "../modules/redshift-query/api-gateway"
#  cognito_user_arn       = module.cencosud_cognito.cencosud_cognito_user_pool_arn
#  api_status_response    = ["200", "500"]
#  aws_region             = var.aws_region
#  account_id             = var.account_id
#  util_layer_arn_array   = module.util_layer.util_layer_arn_array
#}
