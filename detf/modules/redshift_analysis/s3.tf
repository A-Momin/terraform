resource "aws_s3_bucket" "staging" {
  bucket        = "${var.project}-staging-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = { Name = "${var.project}-staging" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "staging" {
  bucket = aws_s3_bucket.staging.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.redshift.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
