
# Example VPC resource required for Access Point VPC config
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "${var.project}-vpc" }
}

########################################
# Bucket Policy example (deny public access, allow principals)
########################################
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "DenyPublic"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.primary_bkt.arn,
      "${aws_s3_bucket.primary_bkt.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Example allow statement for a specific role or account (customize)
  statement {
    sid    = "AllowAccount"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.primary_bkt.arn,
      "${aws_s3_bucket.primary_bkt.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "primary_bkt_policy" {
  bucket = aws_s3_bucket.primary_bkt.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

########################################
# Metrics / CloudWatch configuration (S3 provides metrics; we show an example of bucket metric filter)
########################################
resource "aws_s3_bucket_metric" "primary_bkt_metric" {
  bucket = aws_s3_bucket.primary_bkt.id
  name   = "all-objects"

  filter {
    prefix = ""
  }
}

########################################
# KMS key for SSE-KMS
########################################
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket server-side encryption"
  deletion_window_in_days = 30

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_alias" "s3_alias" {
  name          = "alias/${var.project}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}



