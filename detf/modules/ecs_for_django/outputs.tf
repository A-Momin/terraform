# Outputs for Django ECS Deployment

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.django_app.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.django_cluster.name
}

output "blue_service_name" {
  description = "Name of the blue ECS service"
  value       = aws_ecs_service.django_app["blue"].name
}

output "green_service_name" {
  description = "Name of the green ECS service"
  value       = aws_ecs_service.django_app["green"].name
}

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = aws_lb_target_group.environments["blue"].arn
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = aws_lb_target_group.environments["green"].arn
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.django_db.endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis cache endpoint"
  value       = aws_elasticache_replication_group.django_cache.primary_endpoint_address
  sensitive   = true
}

output "static_bucket_name" {
  description = "Name of the S3 bucket for static files"
  value       = aws_s3_bucket.django_static.bucket
}

output "media_bucket_name" {
  description = "Name of the S3 bucket for media files"
  value       = aws_s3_bucket.django_media.bucket
}

output "cloudfront_static_domain" {
  description = "CloudFront domain for static files"
  value       = aws_cloudfront_distribution.static.domain_name
}

output "cloudfront_media_domain" {
  description = "CloudFront domain for media files"
  value       = aws_cloudfront_distribution.media.domain_name
}

output "application_url" {
  description = "Main application URL"
  value       = "https://${var.domain_name}"
}

output "www_url" {
  description = "WWW application URL"
  value       = "https://www.${var.domain_name}"
}

output "blue_test_url" {
  description = "Blue environment test URL"
  value       = "https://blue.${var.domain_name}"
}

output "green_test_url" {
  description = "Green environment test URL"
  value       = "https://green.${var.domain_name}"
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.django_app.dashboard_name}"
}

output "db_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
  sensitive   = true
}

output "django_secret_key_arn" {
  description = "ARN of the Django secret key"
  value       = aws_secretsmanager_secret.django_secret_key.arn
  sensitive   = true
}

output "listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = aws_lb_listener.https.arn
}
