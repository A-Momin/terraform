module "cognito" {
  source = "./modules/cognito"

  project_name = var.project_name
  environment  = var.environment
}

module "lambda" {
  source = "./modules/lambda"

  project_name = var.project_name
  environment  = var.environment
}

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name           = var.project_name
  environment            = var.environment
  cognito_user_pool_arn  = module.cognito.user_pool_arn
  cognito_user_pool_id   = module.cognito.user_pool_id

  lambda_get_orders_arn         = module.lambda.get_orders_function_arn
  lambda_get_orders_invoke_arn  = module.lambda.get_orders_invoke_arn
  lambda_get_orders_name        = module.lambda.get_orders_function_name

  lambda_create_order_arn         = module.lambda.create_order_function_arn
  lambda_create_order_invoke_arn  = module.lambda.create_order_invoke_arn
  lambda_create_order_name        = module.lambda.create_order_function_name

  lambda_get_order_arn         = module.lambda.get_order_function_arn
  lambda_get_order_invoke_arn  = module.lambda.get_order_invoke_arn
  lambda_get_order_name        = module.lambda.get_order_function_name

  lambda_update_order_arn         = module.lambda.update_order_function_arn
  lambda_update_order_invoke_arn  = module.lambda.update_order_invoke_arn
  lambda_update_order_name        = module.lambda.update_order_function_name

  lambda_delete_order_arn         = module.lambda.delete_order_function_arn
  lambda_delete_order_invoke_arn  = module.lambda.delete_order_invoke_arn
  lambda_delete_order_name        = module.lambda.delete_order_function_name

  lambda_admin_report_arn         = module.lambda.admin_report_function_arn
  lambda_admin_report_invoke_arn  = module.lambda.admin_report_invoke_arn
  lambda_admin_report_name        = module.lambda.admin_report_function_name
}
