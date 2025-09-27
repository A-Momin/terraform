
########################################
# Destination bucket for replication (replica region)
########################################
resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = "${var.primary_bkt_name}-replica"
  acl      = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3.arn
      }
    }
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Replica     = "true"
  }

  lifecycle {
    prevent_destroy = true
  }
}

########################################
# Replication IAM role for cross-region replication
########################################
data "aws_iam_policy_document" "replication_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication_role" {
  name               = "${var.project}-s3-replication-role"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json
}

resource "aws_iam_policy" "replication_policy" {
  name   = "${var.project}-s3-replication-policy"
  policy = data.aws_iam_policy_document.replication_policy.json
}

data "aws_iam_policy_document" "replication_policy" {
  statement {
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectLegalHold",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      "${aws_s3_bucket.primary_bkt.arn}/*",
      "${aws_s3_bucket.primary_bkt.arn}"
    ]
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.replica.arn}/*",
      "${aws_s3_bucket.replica.arn}"
    ]
  }

  statement {
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.s3.arn]
  }
}

resource "aws_iam_role_policy_attachment" "replication_attach" {
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

########################################
# Replication configuration (CRR) - version 2 style (source side)
########################################
resource "aws_s3_bucket_replication_configuration" "primary_bkt_replication" {
  bucket = aws_s3_bucket.primary_bkt.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id       = "replicate-all"
    status   = "Enabled"
    priority = 1

    filter {
      prefix = ""
    }

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
      account       = data.aws_caller_identity.current.account_id
      access_control_translation {
        owner = "Destination"
      }
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }
  }
}
