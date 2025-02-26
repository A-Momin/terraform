data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "gpc_cuckoo_role" {
  name               = "gpc_cuckoo_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_iam_role_policy" "sqs_s3_logs_policies" {
  name = "sqs_s3_logs_policies"
  role = aws_iam_role.gpc_cuckoo_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ses:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:*",
          "s3-object-lambda:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}