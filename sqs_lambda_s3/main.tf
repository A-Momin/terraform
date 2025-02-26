module "sqs" {
    source = "./modules/sqs"
    queue_name = "httx-75243"
    delay_seconds = 10 # override default values
    lambda_function_name = module.lambda.lambda_arn # Access into a output variable in a different module.
}

module "lambda" {
    source = "./modules/lambda"
    function_name = "sqs_s3_handler"
}

module "s3" {
    source = "./modules/s3"
    bucket_name = "httx-75243-sqs-s3-bucket"
}