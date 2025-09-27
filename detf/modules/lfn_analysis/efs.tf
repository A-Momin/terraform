# EFS file system for Lambda
resource "aws_efs_file_system" "lfn_analysis_file_sys" {
  encrypted = true

  tags = {
    Name    = "lambda-efs"
    Project = "Lambda Analysis"
  }
}


# Mount target in each subnet
resource "aws_efs_mount_target" "lfn_analysis_efs_mnt_target" {
  #   for_each = toset(keys(aws_subnet.lfn_analysis_subnets))
  for_each = var.subnets

  file_system_id = aws_efs_file_system.lfn_analysis_file_sys.id
  #   subnet_id       = aws_subnet.lfn_analysis_subnets[each.key].id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]

  #   depends_on = [aws_subnet.lfn_analysis_subnets]
}

# Access point for Lambda
resource "aws_efs_access_point" "lfn_analysis_file_access_point" {
  file_system_id = aws_efs_file_system.lfn_analysis_file_sys.id

  root_directory {
    path = "/mnt/efs"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  depends_on = [aws_efs_mount_target.lfn_analysis_efs_mnt_target]

}




# #############################################
# # EFS
# #############################################
# resource "aws_efs_file_system" "efs" {
#   encrypted = true
#   tags      = { Name = "lambda2-efs" }
# }

# resource "aws_efs_mount_target" "efs_mt" {
#   for_each        = aws_subnet.lfn_analysis_subnets
#   file_system_id  = aws_efs_file_system.efs.id
#   subnet_id       = each.value.id
#   security_groups = [aws_security_group.efs_sg.id]
# }

# resource "aws_efs_access_point" "efs_ap" {
#   file_system_id = aws_efs_file_system.efs.id

#   root_directory {
#     path = "/mnt/efs"
#     creation_info {
#       owner_uid   = 1000
#       owner_gid   = 1000
#       permissions = "755"
#     }
#   }

#   posix_user {
#     uid = 1000
#     gid = 1000
#   }
# }
