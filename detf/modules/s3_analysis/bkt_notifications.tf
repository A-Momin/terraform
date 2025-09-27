########################################
# SNS Topic and SQS Queue for notifications (targets for S3 event notifications)
########################################
resource "aws_sns_topic" "s3_notifications" {
  name = "${var.project}-${var.environment}-s3-topic"
}

resource "aws_sqs_queue" "s3_notifications_queue" {
  name                       = "${var.project}-${var.environment}-s3-queue"
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 30
  tags = {
    Project = var.project
  }
}

# Grant permissions for S3 to publish to SNS or SQS, and for Lambda to be triggered
resource "aws_sns_topic_policy" "s3_topic_policy" {
  arn    = aws_sns_topic.s3_notifications.arn
  policy = data.aws_iam_policy_document.sns_policy.json
}

data "aws_iam_policy_document" "sns_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.s3_notifications.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

########################################
# S3 Bucket Notification -> SNS / SQS / Lambda
########################################
resource "aws_s3_bucket_notification" "primary_bkt_notifications" {
  bucket = aws_s3_bucket.primary_bkt.id

  # Notify SNS on object created events
  topic {
    topic_arn     = aws_sns_topic.s3_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
    filter_suffix = ".csv"
  }

  # Notify SQS on object removed
  queue {
    queue_arn = aws_sqs_queue.s3_notifications_queue.arn
    events    = ["s3:ObjectRemoved:*"]
  }

  # Notify Lambda on PUT (be sure Lambda permissions are set)
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_consumer.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_prefix       = "processing/"
  }
}
