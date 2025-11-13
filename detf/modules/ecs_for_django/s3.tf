# ------------------------
# S3 Buckets for Static and Media Files
# ------------------------
resource "aws_s3_bucket" "django_static" {
  bucket = "${var.project_name}-static-${random_id.bucket_suffix.hex}"

  tags = local.common_tags
}

resource "aws_s3_bucket" "django_media" {
  bucket = "${var.project_name}-media-${random_id.bucket_suffix.hex}"

  tags = local.common_tags
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "django_static" {
  bucket = aws_s3_bucket.django_static.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "django_media" {
  bucket = aws_s3_bucket.django_media.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "django_static" {
  bucket = aws_s3_bucket.django_static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "django_media" {
  bucket = aws_s3_bucket.django_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "django_static" {
  bucket = aws_s3_bucket.django_static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "django_media" {
  bucket = aws_s3_bucket.django_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
