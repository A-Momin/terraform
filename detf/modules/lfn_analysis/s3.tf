resource "aws_s3_bucket" "cuckoo_bkt" {
  bucket        = "gpc-cuckoo-bucket-htech"
  force_destroy = true

  tags = {
    Name    = "gpc-cuckoo-bucket"
    Project = "Lambda Analysis"
  }
}


resource "aws_s3_object" "folders_in_bkt" {
  count  = length(var.cuckoo_s3_objects)
  bucket = aws_s3_bucket.cuckoo_bkt.bucket
  key    = "${var.cuckoo_s3_objects[count.index]}/" # The trailing slash makes it appear as a folder in the console
}

resource "null_resource" "templates_transfer" {

  provisioner "local-exec" {
    command = "aws s3 cp ${path.module}/templates s3://gpc-cuckoo-bucket-htech/email-templates --recursive"
  }
  depends_on = [aws_s3_bucket.cuckoo_bkt]
}

