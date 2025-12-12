output "lambda_function_name" {
  value = aws_lambda_function.crud_api.function_name
}

output "api_id" {
  value = aws_apigatewayv2_api.http_api.id
}

output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "rds_host" {
  value = aws_db_instance.postgres.address
}
