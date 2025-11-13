resource "aws_s3_bucket_notification" "eventbridge_enable" {
  bucket = var.datalake_bkt.bucket

  eventbridge = true
}
