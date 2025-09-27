resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.project}-alb-logs-bkt"
  force_destroy = true
}

# resource "aws_s3_bucket_acl" "alb_logs_acl" {
#   bucket = aws_s3_bucket.alb_logs.id
#   acl    = "private"
# }

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # The Principal must be the Elastic Load Balancing service account ID for your region (not your AWS account).
        Principal = {
          AWS = "arn:aws:iam::127311923021:root" # ELB Account ID for us-east-1;
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}


