#############################################
# Lambda Function
#############################################
resource "aws_lambda_function" "sqs_processor" {
  function_name    = "sqs-processor"
  description      = "Processes messages from SQS and performs analysis tasks"
  runtime          = "python3.9"
  role             = aws_iam_role.lfn_analysis_role.arn
  handler          = "lambda_handler.sqs_processor_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  memory_size = 512 # Default is 128 MB, can be set between 128 MB and 10,240 MB
  timeout     = 120 # Default is 3 seconds, can be set up to 900 seconds (15 minutes)

  architectures = ["x86_64"] # Default is "x86_64", other option is "arm64"

  ## Reserved Concurrency (max limit)
  #   reserved_concurrent_executions = 9

  # Whether to publish creation/change as new Lambda Function Version. Defaults to false.
  publish = false

  layers = [aws_lambda_layer_version.lfn_layer.arn]
  vpc_config {
    # subnet_ids         = [for s in aws_subnet.detf_subnets : s.id]
    subnet_ids         = values(var.subnets)
    security_group_ids = [aws_security_group.lambda_analysis_sg.id]
  }

  file_system_config {
    arn              = aws_efs_access_point.lfn_analysis_file_access_point.arn
    local_mount_path = "/mnt/efs"
  }

  # Increase `/tmp` storage to 5GB
  ephemeral_storage {
    size = 512 # Default is 512 MB, can be set up to 10,240 MB (10 GB)
  }

  # Enable SnapStart for faster cold starts
  snap_start {
    apply_on = "None" # Default is "None"; other option is "PublishedVersions"
  }

  environment {
    variables = {
      INPUT_QUEUE_URL   = aws_sqs_queue.input_queue.id
      FAILURE_QUEUE_URL = aws_sqs_queue.failure_queue.id
      SUCCESS_TOPIC_ARN = aws_sns_topic.success_topic.arn
      PROJECT           = "Lambda Analysis"
    }
  }

  tags = {
    Name    = "sqs-processor"
    Project = "${var.project}-sqs-processor"
  }

  depends_on = [aws_efs_mount_target.lfn_analysis_efs_mnt_target]
}

#############################################
# Event Source Mapping (SQS → Lambda)
#############################################
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  function_name    = aws_lambda_function.sqs_processor.arn
  event_source_arn = aws_sqs_queue.input_queue.arn
  batch_size       = 10
  enabled          = true
  # 👉 Together, they define the retry policy: Lambda retries until either retry attempts are exhausted OR record age expires, whichever comes first.
  # maximum_retry_attempts        = 0  # How many times to retry failed batches
  maximum_record_age_in_seconds = 60 # Maximum age of a record that Lambda sends to a function for processing; default is 60 seconds
}

