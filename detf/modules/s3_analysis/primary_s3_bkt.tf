########################################
# Source bucket (primary_bkt)
########################################
resource "aws_s3_bucket" "primary_bkt" {
  bucket = var.primary_bkt_name
  acl    = "private"

  # Block public ACLs / public policies by default
  force_destroy = false

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        # show SSE-KMS example; you can change to AES256 for SSE-S3
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3.arn
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "intelligent-tier-and-expire"
    enabled = true

    # Transition to INTELLIGENT_TIERING after 30 days, then to STANDARD_IA after 90 days, then to GLACIER DEEP after 365
    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE" # Glacier Deep Archive equivalent in lifecycle
    }

    expiration {
      days = 3650 # example: expire after 10 years (compliance scenario)
    }

    noncurrent_version_expiration {
      days = 90
    }

    abort_incomplete_multipart_upload_days = 7
  }

  website {
    # Only enable if explicitly requested (enable_website_hosting var)
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Optional: Transfer acceleration
  acceleration_status = var.enable_transfer_acceleration ? "Enabled" : "Suspended"

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      # Ignore a subset of fields that may be managed outside Terraform or updated frequently
      acl,
      lifecycle_rule,
    ]
  }
}

########################################
# Block public access at bucket level
########################################
resource "aws_s3_bucket_public_access_block" "primary_bkt_public_block" {
  bucket = aws_s3_bucket.primary_bkt.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################################
# Ownership controls (Bucket owner enforced)
########################################
resource "aws_s3_bucket_ownership_controls" "primary_bkt_owner" {
  # The bucket owner will be the AWS account that created the S3 bucket, regardless of who uploads the objects.
  # all Access Control Lists (ACLs) are disabled. Rely on modern IAM policies and Bucket Policies instead of complex ACLs.

  bucket = aws_s3_bucket.primary_bkt.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

########################################
# Object Lock (WORM) configuration - requires bucket to be created with object_lock_enabled = true
# Note: Terraform requires 'object_lock_enabled' at bucket creation time; below demonstrates pattern.
########################################
resource "aws_s3_bucket" "primary_bkt_with_object_lock" {
  # This is an illustrative alternate resource if you require object lock;
  # in practice, you create the bucket with object_lock_enabled = true on first creation.
  # Uncomment and use instead of aws_s3_bucket.primary_bkt if you need Object Lock.
  # bucket = "${var.primary_bkt_name}-object-lock"
  # acl    = "private"
  # object_lock_enabled = true
  #
  # versioning { enabled = true }
  #
  # lifecycle { prevent_destroy = true }
  #
  # tags = { Project = var.project }
  #
  # (We kept the previously defined primary_bkt bucket without object_lock to avoid creation conflicts.)
  lifecycle {}
}

########################################
# Object Lock retention example (this is an API call per-object; Terraform cannot set per-object retention for all objects automatically)
# You manage object-level retention using S3 Object Lock API or SDK (example here kept as comment)
########################################

########################################
# Server access logging (logs delivered to another bucket)
########################################
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.primary_bkt_name}-access-logs"
  acl    = "log-delivery-write"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "access-logs"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_logging" "primary_bkt_logging" {
  bucket = aws_s3_bucket.primary_bkt.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "s3-access-logs/${aws_s3_bucket.primary_bkt.bucket}/"
}

########################################
# Inventory configuration
########################################
resource "aws_s3_bucket_inventory" "primary_bkt_inventory" {
  bucket = aws_s3_bucket.primary_bkt.id
  name   = "daily-inventory"

  included_object_versions = "All"
  optional_fields          = ["Size", "LastModifiedDate", "StorageClass", "ETag"]

  schedule {
    frequency = "Daily" # or "Weekly"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.access_logs.arn
      prefix     = "inventory-reports"

      # Example encryption (uncomment in prod)
      # encryption {
      #   sse_s3 = true
      # }
    }
  }
}


########################################
# Analytics configuration example
########################################
resource "aws_s3_bucket_analytics_configuration" "primary_bkt_analytics" {
  bucket = aws_s3_bucket.primary_bkt.id
  name   = "analytics-by-prefix"

  filter {
    prefix = "logs/"
  }

  storage_class_analysis {
    data_export {
      output_schema_version = "V_1"
      destination {
        s3_bucket_destination {
          bucket_arn = aws_s3_bucket.access_logs.arn
          format     = "CSV"
          prefix     = "analytics-exports"
        }
      }
    }
  }
}

########################################
# S3 Access Point (useful to grant access to shared datasets, mount via EFS Access Point style)
########################################
resource "aws_s3_access_point" "primary_bkt_access_point" {
  bucket = aws_s3_bucket.primary_bkt.id
  name   = "${var.project}-${var.environment}-ap"

  vpc_configuration {
    vpc_id = aws_vpc.example.id
  }

}
