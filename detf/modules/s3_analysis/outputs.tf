
########################################
# Outputs
########################################
output "s3_bucket_name" {
  value = aws_s3_bucket.primary_bkt.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.primary_bkt.arn
}

output "s3_replica_bucket" {
  value = aws_s3_bucket.replica.arn
}

output "kms_key_arn" {
  value = aws_kms_key.s3.arn
}
