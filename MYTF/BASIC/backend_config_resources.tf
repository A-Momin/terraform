# resource "aws_s3_bucket" "tf_state_bkt" {
#   bucket        = "tf-state-bkt-htech"
#   force_destroy = true
# }

# resource "aws_s3_bucket_versioning" "tf_state_bkt_versioning" {
#   bucket = aws_s3_bucket.tf_state_bkt.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_bkt_encryption" {

#   bucket = aws_s3_bucket.tf_state_bkt.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# resource "aws_dynamodb_table" "tf_state_locking_ddb_tbl" {
#   name         = "tf-state-locking-ddb-tbl"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#   attribute {
#     type = "S"
#     name = "LockID"
#   }
# }
