resource "aws_secretsmanager_secret" "scram_user" {
  name = "msk/scram/user1"
}

resource "aws_secretsmanager_secret_version" "scram_creds" {
  secret_id     = aws_secretsmanager_secret.scram_user.id
  secret_string = jsonencode({ username = "alice", password = "SuperStrongPass123!" })
}

resource "aws_msk_single_scram_secret_association" "assoc" {
  cluster_arn = aws_msk_cluster.kafka.arn
  secret_arn  = aws_secretsmanager_secret.scram_user.arn
}
