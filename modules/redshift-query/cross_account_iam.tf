resource "aws_iam_role" "cross_account_redshift_role" {
  name = "cencosud-cross-account-redshift-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          # Here we have used same account. The account id will change if cross account redshift access needed
          AWS = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/cencosud-api-lambda-role"
        }
      },
    ]
  })

  inline_policy {
    name   = "redshift-data-access"
    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = [
        {
          Action   = "redshift-data:*"
          Effect   = "Allow"
          # TODO: Will fix the access later. Need to use granular access policy
          Resource = "*"
        },
      ]
    })
  }
}