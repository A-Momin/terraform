resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Environment = "Dev"
  }
}