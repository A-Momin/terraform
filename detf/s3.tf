resource "aws_s3_bucket" "s3_buckets" {
  for_each = toset(var.BUCKETS)
  bucket   = each.key

  force_destroy = true

  tags = {
    Name    = each.key
    Project = "${var.project}"
  }
}

resource "aws_s3_object" "datalake_bkt_folders" {
  count      = length(local.datalake_bucket_prefixes)
  bucket     = var.BUCKETS[0]
  key        = local.datalake_bucket_prefixes[count.index]
  depends_on = [aws_s3_bucket.s3_buckets[0]]
}

resource "aws_s3_object" "glue_assets_bkt_folders" {
  count      = length(local.glue_assets_bkt_prefixes)
  bucket     = var.BUCKETS[1]
  key        = local.glue_assets_bkt_prefixes[count.index]
  depends_on = [aws_s3_bucket.s3_buckets[1]]
}
