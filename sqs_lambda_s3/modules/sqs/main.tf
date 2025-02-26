resource "aws_sqs_queue" "queue" {
  name                      = var.queue_name
  delay_seconds             = var.delay_seconds
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = {
    Environment = "production"
  }
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = var.lambda_function_name
}