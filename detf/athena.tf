# resource "aws_athena_database" "my_athena_db" {
#   name          = "athena_db"
#   bucket        = "${var.S3_DATALAKE_BKT_NAME}/athena-outputs/"
#   force_destroy = true
# }
