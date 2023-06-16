data "aws_subnets" "public-subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:connectivity"
    values = [
      "public"
    ]
  }
}

data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

data "http" "my-public-ip" {
  url = "https://ipv4.icanhazip.com"
}