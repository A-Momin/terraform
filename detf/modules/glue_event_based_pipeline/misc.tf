resource "null_resource" "prepare_lfn_deployment_package" {
  provisioner "local-exec" {
    command = <<EOT
        rm -fr ${path.module}/lambdas/lfn_deployment_package
        mkdir -p ${path.module}/lambdas/lfn_deployment_package
        cp ${path.module}/lambdas/lfn1/*.py ${path.module}/lambdas/lfn_deployment_package/
        cp ${path.module}/lambdas/lfn2/*.py ${path.module}/lambdas/lfn_deployment_package/
    EOT
  }

  #   triggers = {
  #     always = timestamp()
  #   }
}

data "archive_file" "zip_up_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/lfn_deployment_package"     # directory to compress
  output_path = "${path.module}/lambdas/lfn_deployment_package.zip" # final zip file path
  depends_on  = [null_resource.prepare_lfn_deployment_package]
}

resource "null_resource" "prepare_glue_external_py_lib" {

  count = var.run_prepare_glue_external_py_lib ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
        rm -fr ${path.module}/python_libraries
        mkdir -p ${path.module}/python_libraries
        cp /Users/am/mydocs/Software_Development/noteshub/utils/mylogger.py ${path.module}/python_libraries/
        pip install coloredlogs -t ${path.module}/python_libraries/
        pip install termcolor -t ${path.module}/python_libraries/
        cd ${path.module}/python_libraries/ && zip -r ../external_py_lib/package.zip .
        cd - && rm -fr ${path.module}/python_libraries
    EOT
  }
  #   triggers = {
  #     always = timestamp()
  #   }
}
