#############################################
# Lambda Function
#############################################
resource "aws_lambda_function" "gpc_cuckoo" {
  function_name    = "gpc_cuckoo"
  runtime          = "python3.9"
  role             = aws_iam_role.lfn_analysis_role.arn
  handler          = "lambda_handler.cuckoo_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256 # Used to trigger updates when source code changes.
  # source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  memory_size   = 512        # Default is 128 MB, can be set between 128 MB and 10,240 MB
  timeout       = 120        # Default is 3 seconds, can be set up to 900 seconds (15 minutes)
  architectures = ["x86_64"] # Default is "x86_64", other option is "arm64"
  #   reserved_concurrent_executions = 9   # Reserved Concurrency (max limit)

  publish = false # Whether to publish creation/change as new Lambda Function Version. Defaults to false.
  layers  = [aws_lambda_layer_version.lfn_layer.arn]
  vpc_config {
    # subnet_ids         = values(aws_subnet.lfn_analysis_subnets)[*].id
    subnet_ids         = values(var.subnets)
    security_group_ids = [aws_security_group.lambda_analysis_sg.id]
  }

  file_system_config {
    arn              = aws_efs_access_point.lfn_analysis_file_access_point.arn
    local_mount_path = "/mnt/efs" # Must starts with `/mnt/`.
  }

  # Increase /tmp storage to 5GB
  ephemeral_storage {
    size = 512 # Default is 512 MB, can be set up to 10,240 MB (10 GB)
  }

  # Enable SnapStart for faster cold starts
  snap_start {
    apply_on = "None" # Default is "None"; other option is "PublishedVersions"
  }

  environment {
    variables = {
      AWS_DEFAULT_RGION = "us-east-1"
    }
  }



  tags = {
    Name    = "gpc-cuckoo"
    Project = "${var.project}-gpc-cuckoo"
  }

  # Ensure EFS is ready before Lambda creation
  depends_on = [aws_efs_mount_target.lfn_analysis_efs_mnt_target]
}

# ## ================================================================
# # Add permissions to CloudWatch Events rules to invoke Lambda function
# ## ================================================================
resource "aws_lambda_permission" "allow_cw_event_rules" {
  for_each      = aws_cloudwatch_event_rule.cw_event_rules
  statement_id  = each.key
  function_name = aws_lambda_function.gpc_cuckoo.function_name
  source_arn    = each.value.arn
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
}


#############################################
# Lambda Destinations (Success & Failure)
#############################################
resource "aws_lambda_function_event_invoke_config" "lambda_destinations" {
  function_name = aws_lambda_function.gpc_cuckoo.function_name

  # 👉 Together, they define the retry policy: Lambda retries until either retry attempts are exhausted OR event age expires, whichever comes first.
  maximum_event_age_in_seconds = 21600 # Event age (in seconds) after which Lambda discards the event. Default is 6 hours (21600 seconds)
  maximum_retry_attempts       = 0     # Retry attempts (0 means no retry) on failure

  destination_config {
    on_failure { destination = aws_sqs_queue.failure_queue.arn }
    on_success { destination = aws_sns_topic.success_topic.arn }
  }
}

###############################################################################
###############################################################################

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

# Invoke the function once during resource creation
# resource "aws_lambda_invocation" "example" {
#   function_name = aws_lambda_function.example.function_name

#   input = jsonencode({
#     operation = "initialize"
#     config = {
#       environment = "production"
#       debug       = false
#     }
#   })
# }

# # Allow the function to invoke itself recursively
# resource "aws_lambda_function_recursion_config" "example" {
#   function_name  = aws_lambda_function.example.function_name
#   recursive_loop = "Allow"
# }

# resource "aws_lambda_function_url" "example" {
#   function_name      = aws_lambda_function.example.function_name
#   qualifier          = "my_alias"
#   authorization_type = "AWS_IAM"
#   invoke_mode        = "RESPONSE_STREAM"

#   cors {
#     allow_credentials = true
#     allow_origins     = ["https://example.com"]
#     allow_methods     = ["GET", "POST"]
#     allow_headers     = ["date", "keep-alive"]
#     expose_headers    = ["keep-alive", "date"]
#     max_age           = 86400
#   }
# }
