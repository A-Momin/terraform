resource "aws_glue_catalog_database" "glue_catalog_databases" {
  for_each     = toset(var.GLUE_CATALOG_DB_NAMES)
  name         = each.value
  description  = "Glue Catalog Database for '${split("-", each.key)[length(split("-", each.key)) - 1]}' in DETF project"
  location_uri = "s3://${aws_s3_bucket.s3_buckets[var.BUCKETS[0]].arn}/"
}
