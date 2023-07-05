module "redshift_layer" {
  source = "./modules/redshift-query"

  vpc_id     = var.vpc_id
}
