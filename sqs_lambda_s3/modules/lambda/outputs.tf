output "lambda_arn" {
    value = aws_lambda_function.sqs_s3_handler.arn
}