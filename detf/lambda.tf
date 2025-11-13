resource "null_resource" "prepare_lfn_layer" {
  provisioner "local-exec" {
    command = <<-EOT
      rm -rf ${path.module}/lfn_layer/python
      mkdir -p ${path.module}/lfn_layer/python
      cp /Users/am/mydocs/Software_Development/noteshub/utils/mylogger.py ${path.module}/lfn_layer/python/
      pip install -r ${path.module}/lfn_layer_requirements.txt -t ${path.module}/lfn_layer/python
    EOT
  }

  #   triggers = {
  #     always = timestamp()
  #   }
}

data "archive_file" "lambda_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lfn_layer"        # directory to compress
  output_path = "${path.module}/lfn_layer.zip"    # final zip file path
  depends_on  = [null_resource.prepare_lfn_layer] # ensures zip runs after prep
}

resource "aws_lambda_layer_version" "lfn_layer" {
  layer_name               = "common_python_dependencies_layer"
  filename                 = "${path.module}/lfn_layer.zip"
  source_code_hash         = data.archive_file.lambda_layer_zip.output_base64sha256
  description              = "Common dependencies for Lambda functions"
  compatible_runtimes      = ["python3.11"]
  compatible_architectures = ["x86_64", "arm64"]
}
