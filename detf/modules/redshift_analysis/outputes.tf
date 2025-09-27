output "redshift_endpoint" {
  value       = aws_redshift_cluster.rsa_redshift_cluster.endpoint
  description = "Endpoint (address:port) for the cluster. Use psql or the Data API to connect."
}

output "redshift_jdbc_url" {
  value = "jdbc:redshift://${aws_redshift_cluster.rsa_redshift_cluster.endpoint}:${aws_redshift_cluster.rsa_redshift_cluster.port}/${aws_redshift_cluster.rsa_redshift_cluster.database_name}"
}

output "s3_staging_bucket" {
  value = aws_s3_bucket.staging.bucket
}

output "redshift_role_arn" {
  value = aws_iam_role.redshift_role.arn
}

output "kms_key_id" {
  value = aws_kms_key.redshift.key_id
}
