data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lfn_analysis_role" {
  name               = "lfn-analysis-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "lfn_analysis_policies" {
  name = "lfn-analysis-policies"
  role = aws_iam_role.lfn_analysis_role.id

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
      {
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientWrite",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          # "ec2:DescribeSubnets",
          "ec2:DeleteNetworkInterface",
          # "ec2:AssignPrivateIpAddresses",
          # "ec2:UnassignPrivateIpAddresses"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:*", "sns:*"]
        Resource = "*"
      },

    ]
  })
}

# data "aws_iam_policy_document" "example_policy" {
#   version = "2012-10-17"

#   statement {
#     sid = "SQSFullAccess" # Optional: Adding SIDs for clarity
#     actions = [
#       "sqs:*",
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#   }

#   statement {
#     sid = "SESFullAccess"
#     actions = [
#       "ses:*",
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#   }

#   statement {
#     sid = "S3AndS3ObjectLambdaAccess"
#     actions = [
#       "s3:*",
#       "s3-object-lambda:*",
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#   }

#   statement {
#     sid = "CloudWatchLogsAccess"
#     actions = [
#       "logs:*",
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#   }

#   statement {
#     sid = "EFSClientAccess"
#     actions = [
#       "elasticfilesystem:ClientMount",
#       "elasticfilesystem:ClientWrite",
#       # Note: The original JSON had 'ClientWrite' listed twice; keeping both for fidelity, though redundant.
#       "elasticfilesystem:ClientWrite",
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#   }

#   statement {
#     sid = "EC2NetworkInterfaceManagement"
#     actions = [
#       "ec2:CreateNetworkInterface",
#       "ec2:DescribeNetworkInterfaces",
#       "ec2:DeleteNetworkInterface",
#       # The commented-out actions (DescribeSubnets, Assign/UnassignPrivateIpAddresses) are omitted as they were commented out in the source.
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#   }

#   statement {
#     sid = "SQSAndSNSCombinedAccess"
#     actions = [
#       "sqs:*",
#       "sns:*",
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#   }
# }

##################################################
# Security Group for EFS
##################################################

# Security Group for Lambda
resource "aws_security_group" "lambda_analysis_sg" {
  name        = "lambda-sg"
  description = "Allow Lambda to access EFS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS access from Lambda SG"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow Lambda -> EFS (outbound NFS)
resource "aws_security_group_rule" "lambda_to_efs" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.efs_sg.id
  security_group_id        = aws_security_group.lambda_analysis_sg.id
}

# Allow EFS <- Lambda (inbound NFS)
resource "aws_security_group_rule" "efs_from_lambda" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_analysis_sg.id
  security_group_id        = aws_security_group.efs_sg.id
}

# #############################################
# # Security Groups
# #############################################
# resource "aws_security_group" "lambda_analysis_sg" {
#   name   = "lambda_anlysis_sg"
#   vpc_id = aws_vpc.lfn_analysis_vpc.id
# }

# resource "aws_security_group" "efs_sg" {
#   name   = "lambda_anlysis_efs-sg"
#   vpc_id = aws_vpc.lfn_analysis_vpc.id

#   ingress {
#     from_port       = 2049
#     to_port         = 2049
#     protocol        = "tcp"
#     security_groups = [aws_security_group.lambda_anlysis_sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
