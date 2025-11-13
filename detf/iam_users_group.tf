resource "aws_iam_user" "lftn_user" {
  name = "AMShah"
}

# ----------------------------
# 2. Create IAM Users
# ----------------------------
resource "aws_iam_user" "users" {
  for_each = toset(var.iam_users)
  name     = each.key
}

resource "aws_iam_user_login_profile" "user_login_profiles" {
  for_each = aws_iam_user.users

  user = each.value.name

  password_reset_required = true
}

resource "local_file" "user_passwords" {
  for_each = aws_iam_user_login_profile.user_login_profiles

  filename = "${path.module}/${each.key}_password.txt"

  content = each.value.password
}

# ----------------------------
# 3. Create IAM Groups
# ----------------------------
resource "aws_iam_group" "groups" {
  for_each = toset(var.iam_groups)
  name     = each.key
}

# ----------------------------
# 4. Attach Users to Groups
# ----------------------------
locals {
  user_group_map = {
    AMShah  = ["admins"]
    Clinton = ["admins"]
    Joe     = ["developers"]
    Trump   = ["developers"]
  }
}

resource "aws_iam_user_group_membership" "membership" {
  for_each = local.user_group_map

  user   = each.key
  groups = each.value

  depends_on = [aws_iam_user.users, aws_iam_group.groups]
}

resource "aws_iam_group_policy_attachment" "admin_policies" {
  for_each = {
    "AdministratorAccess" = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  group      = aws_iam_group.groups["admins"].name
  policy_arn = each.value
}

resource "aws_iam_group_policy_attachment" "developer_policies" {
  for_each = {
    "PowerUserAccess"        = "arn:aws:iam::aws:policy/PowerUserAccess"
    "IAMUserChangePassword"  = "arn:aws:iam::aws:policy/IAMUserChangePassword"
    "AmazonS3ReadOnlyAccess" = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  group      = aws_iam_group.groups["developers"].name
  policy_arn = each.value
}


resource "aws_iam_access_key" "developer_keys" {
  for_each = aws_iam_user.users

  user = each.key
}

resource "local_file" "developer_credentials" {
  for_each = aws_iam_access_key.developer_keys

  #   filename = "${path.module}/credentials_${each.key}.txt"
  filename = pathexpand("~/.aws/credentials_${each.key}")
  content  = <<-EOT
        [${each.key}]
        aws_access_key_id     = ${each.value.id}
        aws_secret_access_key = ${each.value.secret}
        region                = us-east-1
    EOT
}

## -------------------------------------------------------------------------
########### Store Access Keys in SSM Parameter Store (Optional) ###########
## -------------------------------------------------------------------------


# # Generate access keys for each developer user
# resource "aws_iam_access_key" "developer_keys" {
#   for_each = aws_iam_user.users

#   user = each.key
# }

# # Store developer access keys in SSM Parameter Store
# resource "aws_ssm_parameter" "developer_access_key" {
#   for_each = aws_iam_access_key.developer_keys

#   name  = "/iam/users/${each.key}/access_key_id"
#   type  = "SecureString"
#   value = each.value.id
# }

# resource "aws_ssm_parameter" "developer_secret_key" {
#   for_each = aws_iam_access_key.developer_keys

#   name  = "/iam/users/${each.key}/secret_access_key"
#   type  = "SecureString"
#   value = each.value.secret
# }

# # Optional: Output Access Keys (for testing only)
# # ⚠️ Best practice: do not expose secrets in Terraform outputs in production.
# output "developer_access_keys" {
#   value     = { for k, v in aws_iam_access_key.developer_keys : k => v.id }
#   sensitive = true
# }
