## Only a Lake Formation admin (set in data_lake_settings.admins) can grant/revoke LF permissions.
## If your Terraform execution role (the one running `terraform apply`) is not an LF admin, you’ll get this error.

resource "aws_lakeformation_data_lake_settings" "lftn_setting" {
  admins = [var.lftn_admin_user.arn]

  #   create_database_default_permissions {
  #     permissions = ["ALL"]
  #     principal   = var.lftn_admin_user.arn
  #   }

  #   create_table_default_permissions {
  #     permissions = ["ALL"]
  #     principal   = var.lftn_admin_user.arn
  #   }

  trusted_resource_owners = []
}

resource "aws_lakeformation_resource" "datalake_registration" {
  arn = var.datalake_bkt.arn
}

###############################################################################
########################## Resource Based Access Control ######################
###############################################################################

resource "aws_lakeformation_permissions" "role_permissions_on_dbs" {
  for_each = toset(values(var.glue_catalog_databases)[*].name)

  principal                     = aws_iam_role.glue_role.arn
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  database {
    name = each.value
  }
}

# resource "aws_lakeformation_permissions" "user_permissions_on_dbs" {
#   for_each = toset(values(var.glue_catalog_databases)[*].name)

#   principal                     = var.lftn_admin_user.arn
#   permissions                   = ["ALL"]
#   permissions_with_grant_option = ["ALL"]

#   database {
#     name = each.value
#   }
# }

resource "aws_lakeformation_permissions" "role_permissions_on_datalake" {
  principal   = aws_iam_role.glue_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]
  #   permissions_with_grant_option = ["ALL"]

  data_location {
    arn = aws_lakeformation_resource.datalake_registration.arn
  }
}


# resource "aws_lakeformation_permissions" "role_permissions_on_tbl" {
#   principal   = aws_iam_role.glue_role.arn
#   permissions = ["ALL"]

#   table {
#     database_name = aws_glue_catalog_database.glue_catalog_db.name
#     name          = aws_glue_catalog_table.example_table.name
#   }
# }

# resource "aws_lakeformation_permissions" "role_permissions_on_tbl_cols" {
#   permissions = ["SELECT"]
#   principal   = "arn:aws:iam:us-east-1:123456789012:user/SanHolo"

#   table_with_columns {
#     database_name = aws_glue_catalog_table.example.database_name
#     name          = aws_glue_catalog_table.example.name
#     column_names  = ["event"]
#   }
# }

###############################################################################
########################### Tag Based Access Control ###########################
###############################################################################

# resource "aws_lakeformation_lf_tag" "lf_tag_def1" {
#   key    = "department"
#   values = ["Sales Team", "Customers Service Team"]
# }

# resource "aws_lakeformation_lf_tag" "lf_tag_def2" {
#   key    = "db_access"
#   values = true
# }

# resource "aws_lakeformation_lf_tag" "lf_tag_def3" {
#   key    = "environment"
#   values = ["Dev", "Production"]
# }

# resource "aws_lakeformation_permissions" "lftn_tag_based_permission" {
#   principal   = aws_iam_group.customerusers.arn
#   permissions = ["CREATE_TABLE", "ALTER", "DROP"]

#   lf_tag_policy {
#     resource_type = "DATABASE" # Possible values: DATABASE, TABLE

#     expression {
#       key    = "department"
#       values = ["Sales Team"]
#     }

#     expression {
#       key    = "Environment"
#       values = ["Dev"]
#     }
#   }
# }
