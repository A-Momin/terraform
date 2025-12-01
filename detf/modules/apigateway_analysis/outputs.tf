output "api_gateway_url" {
  description = "API Gateway base URL"
  value       = module.api_gateway.api_url
}

output "api_gateway_stage_url" {
  description = "API Gateway stage URL"
  value       = module.api_gateway.api_stage_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito.user_pool_client_id
}

output "cognito_user_pool_domain" {
  description = "Cognito User Pool Domain"
  value       = module.cognito.user_pool_domain
}

output "api_key_value" {
  description = "API Key for usage plans"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}
