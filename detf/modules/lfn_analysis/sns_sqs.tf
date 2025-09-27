#############################################
# SQS Queues
#############################################
resource "aws_sqs_queue" "input_queue" {
  name = "lambda-input-queue"
}

resource "aws_sqs_queue" "failure_queue" {
  name = "lambda-failure-queue"
}

#############################################
# SNS Topic for Success
#############################################
resource "aws_sns_topic" "success_topic" {
  name = "lambda-success-topic"
}

# Example subscription (email)
resource "aws_sns_topic_subscription" "success_email" {
  topic_arn = aws_sns_topic.success_topic.arn
  protocol  = "email"
  endpoint  = "AMominNJ@gmail.com"
}
