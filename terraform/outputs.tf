output "api_endpoint" {
  description = "URL base da API Gateway. A rota de autenticacao e POST {api_endpoint}/auth."
  value       = aws_apigatewayv2_api.auth.api_endpoint
}

output "lambda_function_name" {
  description = "Nome da funcao Lambda de autenticacao."
  value       = aws_lambda_function.auth.function_name
}

output "lambda_function_arn" {
  description = "ARN da funcao Lambda de autenticacao."
  value       = aws_lambda_function.auth.arn
}

output "lambda_security_group_id" {
  description = "ID do Security Group da Lambda (referenciado pela regra de ingress no RDS do Repositorio 1)."
  value       = aws_security_group.lambda.id
}
