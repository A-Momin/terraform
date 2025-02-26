resource "aws_lambda_function" "sqs_s3_handler" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = data.archive_file.lambda_zip.output_path
  function_name = var.function_name
  role          = aws_iam_role.role_for_lambda.arn
  handler       = "process_sqs.sqs_s3_handler"

#   source_code_hash = data.archive_file.lambda.output_base64sha256
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  runtime = var.runtime

  environment {
    variables = {
      foo = "bar"
    }
  }
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../python/process_sqs.py"
  output_path = "${path.module}/../../python/process_sqs.zip"
}
