output "api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_url" {
  description = "API Gateway base URL"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_stage_url" {
  description = "API Gateway stage URL"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_key_value" {
  description = "API Key value"
  value       = aws_api_gateway_api_key.premium_key.value
  sensitive   = true
}
