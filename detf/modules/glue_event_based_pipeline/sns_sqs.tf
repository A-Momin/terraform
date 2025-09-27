resource "aws_sns_topic" "glue_sns_topic" {
  name = var.TOPIC_NAME
}

resource "aws_sns_topic_subscription" "sns_sqs_subscription" {
  topic_arn = aws_sns_topic.glue_sns_topic.arn
  protocol  = "email"
  endpoint  = var.SNS_EMAIL_ENDPOINT
}
