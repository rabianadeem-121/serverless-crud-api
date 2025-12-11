resource "aws_apigateway_rest_api" "api" {
  name        = "serverless-crud-api"
  description = "API for CRUD operations"
}

resource "aws_apigateway_deployment" "deployment" {
  rest_api_id = aws_apigateway_rest_api.api.id
  stage_name  = "prod"
  depends_on  = [aws_lambda_function.app]
}
