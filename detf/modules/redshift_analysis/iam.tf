data "aws_iam_policy_document" "redshift_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "redshift_role" {
  name               = "${var.project}-redshift-role"
  assume_role_policy = data.aws_iam_policy_document.redshift_assume.json
  tags               = { Name = "${var.project}-redshift-role" }
}

# Inline policy allowing S3 and Glue (and KMS decrypt for S3)
data "aws_iam_policy_document" "redshift_policy" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.staging.arn,
      "${aws_s3_bucket.staging.arn}/*"
    ]
  }

  statement {
    sid    = "GlueAndRedshiftActions"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "KMSDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.redshift.arn]
  }
}

resource "aws_iam_role_policy" "redshift_policy_attach" {
  name   = "${var.project}-redshift-policy"
  role   = aws_iam_role.redshift_role.id
  policy = data.aws_iam_policy_document.redshift_policy.json
}
