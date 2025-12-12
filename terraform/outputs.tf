output "ec2_public_ip" {
  value = aws_instance.ci_cd.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "rds_port" {
  value       = aws_db_instance.postgres.port
  description = "The port of the RDS instance"
}

output "lambda_name" {
  value = aws_lambda_function.my_lambda.function_name
}

output "api_endpoint" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "api_id" {
  value = aws_api_gateway_rest_api.my_api.id
}
