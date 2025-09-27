resource "aws_redshift_subnet_group" "rsa_redshift_cluster" {
  name       = "${var.project}-subnet-group"
  subnet_ids = [for k, v in var.public_subnets : v.id if strcontains(k, "public")]
  tags       = { Name = "${var.project}-redshift-subnet-group" }
}

resource "aws_redshift_parameter_group" "rsa_redshift_cluster" {
  name   = "${var.project}-paramgrp"
  family = "redshift-1.0"

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }
  tags = { Name = "${var.project}-parameter-group" }
}

resource "aws_security_group" "redshift_sg" {
  name        = "${var.project}-redshift-sg"
  description = "Allow client ingress to Redshift cluster port"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow psql/SQL client from anywhere for demo (restrict in prod!)"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # This rule allows all outbound traffic (any port, any protocol) from your instances to anywhere on the internet.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-redshift-sg" }
}

resource "aws_redshift_cluster" "rsa_redshift_cluster" {
  cluster_identifier = var.redshift_cluster_identifier
  node_type          = var.redshift_node_type
  cluster_type       = var.node_count > 1 ? "multi-node" : "single-node"
  number_of_nodes    = var.node_count
  master_username    = var.redshift_master_username
  master_password    = var.redshift_master_password
  database_name      = var.redshift_db_name

  iam_roles = [aws_iam_role.redshift_role.arn]

  encrypted  = true
  kms_key_id = aws_kms_key.redshift.arn

  publicly_accessible                 = true
  cluster_subnet_group_name           = aws_redshift_subnet_group.rsa_redshift_cluster.id
  vpc_security_group_ids              = [aws_security_group.redshift_sg.id]
  automated_snapshot_retention_period = 7
  skip_final_snapshot                 = true

  tags = { Name = "${var.project}-redshift-cluster" }

  depends_on = [aws_iam_role_policy.redshift_policy_attach]
}
