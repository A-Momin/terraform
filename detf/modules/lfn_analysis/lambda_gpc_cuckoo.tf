#############################################
# Lambda Function
#############################################
resource "aws_lambda_function" "gpc_cuckoo" {
  function_name    = "gpc_cuckoo"
  runtime          = "python3.9"
  role             = aws_iam_role.lfn_analysis_role.arn
  handler          = "lambda_handler.cuckoo_handler"
  timeout          = 120 # Set the timeout here (in seconds); default is 3 seconds
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  # source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  ## The amount of RAM (MB) allocated to your Lambda function.
  memory_size = 128 # Default is 128 MB, can be set between 128 MB and 10,240 MB

  ## Reserved Concurrency (max limit)
  #   reserved_concurrent_executions = 9

  # Whether to publish creation/change as new Lambda Function Version. Defaults to false.
  publish = false

  vpc_config {
    # subnet_ids         = values(aws_subnet.lfn_analysis_subnets)[*].id
    subnet_ids         = values(var.subnets)
    security_group_ids = [aws_security_group.lambda_analysis_sg.id]
  }

  file_system_config {
    arn              = aws_efs_access_point.lfn_analysis_file_access_point.arn
    local_mount_path = "/mnt/efs" # Must starts with `/mnt/`.
  }

  #   # Increase /tmp storage to 5GB
  #   ephemeral_storage {
  #     size = 512 # Size in MB, default is 512 MB; max is 10,240 MB (10 GB)
  #   }

  environment {
    variables = {
      AWS_DEFAULT_RGION = "us-east-1"
    }
  }

  layers = [
    aws_lambda_layer_version.lfn_layer.arn
  ]

  tags = {
    Name    = "gpc_cuckoo"
    Project = "Lambda Analysis"
  }

  # Ensure EFS is ready before Lambda creation
  depends_on = [aws_efs_mount_target.lfn_analysis_efs_mnt_target]
}


# # Create an alias for production
# resource "aws_lambda_alias" "prod" {
#   name             = "prod"
#   function_name    = aws_lambda_function.gpc_cuckoo.arn
#   function_version = aws_lambda_function.gpc_cuckoo.version
# }

# # Provisioned Concurrency (pre-warmed instances)
# resource "aws_lambda_provisioned_concurrency_config" "pc" {
#   function_name                     = aws_lambda_function.gpc_cuckoo.function_name
#   qualifier                         = aws_lambda_alias.prod.name
#   provisioned_concurrent_executions = 3
# }


# ## ================================================================
# # Add permissions to CloudWatch Events rules to invoke Lambda function
# ## ================================================================
resource "aws_lambda_permission" "allow_cw_event_rules" {
  for_each      = aws_cloudwatch_event_rule.cw_event_rules
  function_name = aws_lambda_function.gpc_cuckoo.function_name
  source_arn    = each.value.arn
  statement_id  = each.key
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
}


#############################################
# Lambda Destinations (Success & Failure)
#############################################
resource "aws_lambda_function_event_invoke_config" "lambda_destinations" {
  function_name = aws_lambda_function.gpc_cuckoo.function_name

  # 👉 Together, they define the retry policy: Lambda retries until either retry attempts are exhausted OR event age expires, whichever comes first.
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0

  destination_config {
    on_failure {
      destination = aws_sqs_queue.failure_queue.arn
    }
    on_success {
      destination = aws_sns_topic.success_topic.arn
    }
  }
}
