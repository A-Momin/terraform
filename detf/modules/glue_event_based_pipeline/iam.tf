# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect  = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["glue.amazonaws.com"]
#     }
#   }
# }

resource "aws_iam_role" "glue_role" {
  name = var.GLUE_ROLE_NAME

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["glue.amazonaws.com"]
        }
      }
    ]
  })
}

# Additional IAM permissions for Glue Data Quality
resource "aws_iam_policy" "glue_data_quality_policy" {
  name        = "glue-data-quality-policy"
  description = "IAM policy for Glue Data Quality operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "glue:StartDataQualityEvaluationRun",
          "glue:GetDataQualityEvaluationRun",
          "glue:BatchGetDataQualityResult",
          "glue:GetDataQualityRuleset",
          "glue:ListDataQualityResults",
          "glue:GetDataQualityResult"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "${var.datalake_bkt.arn}/*",
          "${var.datalake_bkt.arn}",
          "${var.glue_assets_bkt.arn}/*",
          "${var.glue_assets_bkt.arn}"
        ]
      },
      {
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "AWS/Glue/DataQuality"
          }
        }
      }
    ]
  })
}

# Attach the policy to the Glue role
resource "aws_iam_role_policy_attachment" "glue_data_quality_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_data_quality_policy.arn
}

###############################################################################
###############################################################################

resource "aws_iam_role" "lfn_role" {
  name = var.LFN_ROLE_NAME
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lfn_role_policy" {
  role = aws_iam_role.lfn_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:*"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["log:*"]
        Effect   = "Allow"
        Resource = "*"
      },

    ]
  })
}

resource "aws_iam_role_policy" "glue_role_policy" {
  role = aws_iam_role.glue_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["events:PutEvents"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["log:*"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:StartDataQualityEvaluationRun",
          "glue:GetDataQualityEvaluationRun",
          "glue:BatchGetDataQualityResult",
          "glue:GetDataQualityRuleset",
          "glue:ListDataQualityResults",
          "glue:GetDataQualityResult"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${var.datalake_bkt.arn}/*",
          "${var.datalake_bkt.arn}",
          "${var.glue_assets_bkt.arn}/*",
          "${var.glue_assets_bkt.arn}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "AWS/Glue/DataQuality"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lfn_role_policy_attachment" {
  count      = length(var.LFN_ROLE_AWSM_POLICY)
  role       = aws_iam_role.lfn_role.name
  policy_arn = var.LFN_ROLE_AWSM_POLICY[count.index]
}

resource "aws_iam_role_policy_attachment" "glue_role_policy_attachment" {
  count      = length(var.LFN_ROLE_AWSM_POLICY)
  role       = aws_iam_role.glue_role.name
  policy_arn = var.LFN_ROLE_AWSM_POLICY[count.index]
}

# locals {
#   roles = [aws_iam_role.lfn_role.name, aws_iam_role.glue_role.name]
# }

# resource "aws_iam_role_policy_attachment" "lfn_role_policy_attachment" {
#   for_each = {
#     for pair in flatten([
#       for role in local.roles : [
#         for policy in var.LFN_ROLE_AWSM_POLICY : {
#           role   = role
#           policy = policy
#         }
#       ]
#     ]) : "${pair.role}-${basename(pair.policy)}" => pair
#   }

#   role       = each.value.role
#   policy_arn = each.value.policy
# }
