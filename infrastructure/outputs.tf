output "lambda_function_name" {
  value = aws_lambda_function.app.function_name
}

output "api_endpoint" {
  value = aws_apigateway_rest_api.api.execution_arn
}
