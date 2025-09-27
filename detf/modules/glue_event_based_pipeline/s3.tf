resource "aws_s3_bucket_notification" "notify_job_trigger_lfn" {
  bucket = var.datalake_bkt.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_customer_crawler_triggerer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${local.bronze}/customers/"
    # filter_suffix       = ".parquet"
  }
  depends_on = [aws_lambda_permission.allow_s3_to_invoke_lambda]
}

# Upload all files from local directory
resource "aws_s3_object" "upload_glue_job_script" {

  for_each = fileset("${path.module}/glue_scripts", "**")

  bucket = var.glue_assets_bkt.bucket
  key    = "/glue_scripts/${each.value}" # prefix in bucket
  source = "${path.module}/glue_scripts/${each.value}"
  #   etag   = filemd5("${path.module}/glue_scripts/${each.value}")
}

resource "aws_s3_object" "upload_glue_external_py_lib" {
  bucket = var.glue_assets_bkt.bucket
  key    = "/libraries/package.zip"
  source = "${path.module}/external_py_lib/package.zip"
  #   etag       = filemd5("${path.module}/external_py_lib/package.zip")
  depends_on = [null_resource.prepare_glue_external_py_lib]
}
