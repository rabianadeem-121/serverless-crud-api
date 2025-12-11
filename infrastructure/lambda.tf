provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_lambda_function" "app" {
  function_name = var.lambda_name
  filename      = var.lambda_zip
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_role.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = {
      DB_HOST     = "<RDS_ENDPOINT>"
      DB_USER     = "<DB_USER>"
      DB_PASSWORD = "<DB_PASSWORD>"
      DB_NAME     = "<DB_NAME>"
      DB_PORT     = "5432"
    }
  }
}
