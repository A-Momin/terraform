
# Upload all files from local directory
resource "aws_s3_object" "upload_glue_job_script" {

  for_each = fileset("${path.module}/glue_scripts", "**")

  bucket = var.glue_assets_bkt.bucket
  key    = "/glue_scripts/${each.value}" # prefix in bucket
  source = "${path.module}/glue_scripts/${each.value}"
  etag   = filemd5("${path.module}/glue_scripts/${each.value}")
}
