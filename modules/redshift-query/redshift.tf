# Random Password / Suffix
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!$%&*()-_=+[]{}<>:?"
}

resource "aws_security_group" "redshift_cluster_sg" {
  name   = "cencosud-redshift-cluster-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow TCP traffic from admin public IP to redshift" # For testing only
    protocol    = "tcp"
    from_port   = 5439
    to_port     = 5439
    cidr_blocks = ["${chomp(data.http.my-public-ip.response_body)}/32"]
  }

  ingress {
    description = "Allow all traffic within itself"
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
  }

  egress {
    description = "Allow all external traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_redshift_subnet_group" "redshift_cluster_subnet_group" {
  name       = "cencosud-redshift-cluster-subnet-group"
  subnet_ids = data.aws_subnets.private-subnets.ids
}

resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier        = "tf-redshift-cluster"
  database_name             = "mydb"
  master_username           = "admin"
  master_password           = random_password.password.result
  node_type                 = "dc2.large"
  cluster_type              = "single-node"
  apply_immediately         = true
  encrypted                 = true
  skip_final_snapshot       = true
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift_cluster_subnet_group.name
  vpc_security_group_ids    = [
    aws_security_group.redshift_cluster_sg.id
  ]
}

resource "aws_secretsmanager_secret" "redshift_connection" {
  description = "Redshift connect details"
  name        = "cencosud-redshift-cluster-secret"
}

resource "aws_secretsmanager_secret_version" "redshift_connection" {
  secret_id     = aws_secretsmanager_secret.redshift_connection.id
  secret_string = jsonencode({
    username            = aws_redshift_cluster.redshift_cluster.master_username
    password            = aws_redshift_cluster.redshift_cluster.master_password
    engine              = "redshift"
    host                = aws_redshift_cluster.redshift_cluster.endpoint
    port                = "5439"
    db                  = aws_redshift_cluster.redshift_cluster.database_name
    dbClusterIdentifier = aws_redshift_cluster.redshift_cluster.cluster_identifier
  })
}