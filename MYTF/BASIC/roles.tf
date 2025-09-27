# data "aws_iam_policy_document" "lfn_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect  = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "lfn_role" {
#   name               = "lfn-role"
#   assume_role_policy = data.aws_iam_policy_document.lfn_assume_role_policy.json
#   #   assume_role_policy = jsonencode({
#   #     Version = "2012-10-17",
#   #     Statement = [
#   #       {
#   #         Action = "sts:AssumeRole",
#   #         Effect = "Allow",
#   #         Principal = {
#   #           Service = "lambda.amazonaws.com"
#   #         }
#   #       }
#   #     ]
#   #   })
# }

# resource "aws_iam_role_policy" "lfn_role_policy" {
#   name = "lfn-role-policy"
#   role = aws_iam_role.lfn_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = [
#         "s3:*",
#         "s3-object-lambda:*"
#       ]
#       Effect   = "Allow"
#       Resource = "*"
#       },
#       {
#         Action   = ["log:*"]
#         Effect   = "Allow"
#         Resource = "*"
#     }]
#   })
# }


# # -------------------------------
# # Create IAM Group
# # -------------------------------
# resource "aws_iam_group" "dev_group" {
#   name = "developers"
# }

# # Attach AWS managed policy to the group
# # resource "aws_iam_group_policy_attachment" "dev_group_attach" {
# #   group      = aws_iam_group.dev_group.name
# #   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# # }

# # -------------------------------
# # Create IAM User
# # -------------------------------
# resource "aws_iam_user" "dev_user" {
#   name          = "BushDev"
#   force_destroy = true # allows deletion even if keys exist
# }

# # Add user to group
# resource "aws_iam_user_group_membership" "dev_user_membership" {
#   user   = aws_iam_user.dev_user.name
#   groups = [aws_iam_group.dev_group.name]
# }

# # # -------------------------------
# # # Console Access (Password)
# # # -------------------------------
# # resource "aws_iam_user_login_profile" "dev_user_login" {
# #   user                    = aws_iam_user.dev_user.name
# #   password_length         = 16
# #   password_reset_required = true
# # }

# # # -------------------------------
# # # Programmatic Access (Access Key)
# # # -------------------------------
# # resource "aws_iam_access_key" "dev_user_key" {
# #   user = aws_iam_user.dev_user.name
# # }

# # # -------------------------------
# # # Outputs (Sensitive)
# # # -------------------------------
# # output "user_console_password" {
# #   value     = aws_iam_user_login_profile.dev_user_login.password
# #   sensitive = true
# # }

# # output "user_access_key_id" {
# #   value     = aws_iam_access_key.dev_user_key.id
# #   sensitive = true
# # }

# # output "user_secret_access_key" {
# #   value     = aws_iam_access_key.dev_user_key.secret
# #   sensitive = true
# # }

# # # Save sensitive values into local files
# # resource "local_file" "user_credentials" {
# #   filename = "${path.module}/user-credentials.txt"
# #   content  = <<EOT
# # User: ${aws_iam_user.dev_user.name}
# # Console Password: ${aws_iam_user_login_profile.dev_user_login.password}
# # AWS Access Key ID: ${aws_iam_access_key.dev_user_key.id}
# # AWS Secret Access Key: ${aws_iam_access_key.dev_user_key.secret}
# # EOT
# # }
