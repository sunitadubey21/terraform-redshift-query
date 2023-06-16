data "aws_subnets" "private-subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:connectivity"
    values = [
      "private"
    ]
  }
}

data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

data "http" "my-public-ip" {
  url = "https://ipv4.icanhazip.com"
}