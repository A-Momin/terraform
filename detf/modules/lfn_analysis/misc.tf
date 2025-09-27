
resource "null_resource" "prepare_lfn_zip_package" {
  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.module}/package_lfn_analysis
      mkdir -p ${path.module}/package_lfn_analysis
      cp ${path.module}/python/code/lambda_handler.py ${path.module}/package_lfn_analysis/
      pip install -r ${path.module}/python/requirements.txt -t ${path.module}/package_lfn_analysis
    EOT
  }

  #   triggers = {
  #     always = timestamp()
  #   }
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/package_lfn_analysis"            # directory to compress
  output_path = "${path.module}/python/package_lfn_analysis.zip" # final zip file path
  depends_on  = [null_resource.prepare_lfn_zip_package]          # ensures zip runs after prep
}


resource "null_resource" "prepare_lfn_layer" {
  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.module}/python/lfn_layer/python
      mkdir -p ${path.module}/python/lfn_layer/python
      cp /Users/am/mydocs/Software_Development/noteshub/utils/mylogger.py ${path.module}/python/lfn_layer/python/
      pip install -r ${path.module}/python/lfn_layer_requirements.txt -t ${path.module}/python/lfn_layer/python
    EOT
  }

  #   triggers = {
  #     always = timestamp()
  #   }
}

data "archive_file" "lambda_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/python/lfn_layer"     # directory to compress
  output_path = "${path.module}/python/lfn_layer.zip" # final zip file path
  depends_on  = [null_resource.prepare_lfn_layer]     # ensures zip runs after prep
}

# Common dependencies layer
resource "aws_lambda_layer_version" "lfn_layer" {
  layer_name               = "common_python_dependencies_layer"
  filename                 = "${path.module}/python/lfn_layer.zip"
  source_code_hash         = data.archive_file.lambda_layer_zip.output_base64sha256
  description              = "Common dependencies for Lambda functions"
  compatible_runtimes      = ["python3.9"]
  compatible_architectures = ["x86_64", "arm64"]
}


# resource "aws_lambda_layer_version" "lfn_layer" {
#   layer_name               = "common_python_dependencies_layer"
#   s3_bucket                = aws_s3_bucket.lambda_layers.id
#   s3_key                   = aws_s3_object.lfn_layer_zip.key
#   description              = "Common dependencies for Lambda functions"
#   compatible_runtimes      = ["python3.9"]
#   compatible_architectures = ["x86_64", "arm64"]
# }

