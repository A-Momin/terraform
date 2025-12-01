variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}

variable "lambda_get_orders_arn" {
  description = "Lambda function ARN for getting orders"
  type        = string
}

variable "lambda_get_orders_invoke_arn" {
  description = "Lambda invoke ARN for getting orders"
  type        = string
}

variable "lambda_get_orders_name" {
  description = "Lambda function name for getting orders"
  type        = string
}

variable "lambda_create_order_arn" {
  description = "Lambda function ARN for creating orders"
  type        = string
}

variable "lambda_create_order_invoke_arn" {
  description = "Lambda invoke ARN for creating orders"
  type        = string
}

variable "lambda_create_order_name" {
  description = "Lambda function name for creating orders"
  type        = string
}

variable "lambda_get_order_arn" {
  description = "Lambda function ARN for getting a single order"
  type        = string
}

variable "lambda_get_order_invoke_arn" {
  description = "Lambda invoke ARN for getting a single order"
  type        = string
}

variable "lambda_get_order_name" {
  description = "Lambda function name for getting a single order"
  type        = string
}

variable "lambda_update_order_arn" {
  description = "Lambda function ARN for updating orders"
  type        = string
}

variable "lambda_update_order_invoke_arn" {
  description = "Lambda invoke ARN for updating orders"
  type        = string
}

variable "lambda_update_order_name" {
  description = "Lambda function name for updating orders"
  type        = string
}

variable "lambda_delete_order_arn" {
  description = "Lambda function ARN for deleting orders"
  type        = string
}

variable "lambda_delete_order_invoke_arn" {
  description = "Lambda invoke ARN for deleting orders"
  type        = string
}

variable "lambda_delete_order_name" {
  description = "Lambda function name for deleting orders"
  type        = string
}

variable "lambda_admin_report_arn" {
  description = "Lambda function ARN for admin reports"
  type        = string
}

variable "lambda_admin_report_invoke_arn" {
  description = "Lambda invoke ARN for admin reports"
  type        = string
}

variable "lambda_admin_report_name" {
  description = "Lambda function name for admin reports"
  type        = string
}
