resource "aws_kms_key" "redshift" {
  description             = "KMS key for Redshift demo"
  deletion_window_in_days = 7

  tags = { Name = "${var.project}-kms" }
}

resource "aws_kms_alias" "redshift_alias" {
  name          = "alias/${var.project}-kms"
  target_key_id = aws_kms_key.redshift.key_id
}
