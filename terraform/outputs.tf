output "rds_endpoint" {
  value       = aws_db_instance.postgres.address
  description = "RDS PostgreSQL endpoint"
}

output "rds_port" {
  value       = aws_db_instance.postgres.port
  description = "RDS PostgreSQL port"
}

output "lambda_function_name" {
  value       = aws_lambda_function.crud_lambda.function_name
  description = "Lambda function name"
}

output "api_url" {
  value       = "${aws_apigateway_rest_api.api.execution_arn}/users"
  description = "API Gateway URL for /users endpoint"
}

output "ecr_repo_uri" {
  value       = aws_ecr_repository.lambda_repo.repository_url
  description = "ECR repository URI"
}

