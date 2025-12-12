# Variables (make sure these exist in variables.tf)
# var.vpc_cidr
# var.public_subnet_cidr_a
# var.public_subnet_cidr_b
# var.private_subnet_cidr_a
# var.private_subnet_cidr_b
# var.instance_type
# var.public_key
# var.db_username
# var.db_password

# --------------------------
# VPC
# --------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# --------------------------
# Public Subnets (2 AZs)
# --------------------------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_a
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_b
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1b"
}

# --------------------------
# Private Subnets (2 AZs for RDS)
# --------------------------
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = "ap-south-1b"
}

# --------------------------
# Internet Gateway
# --------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# --------------------------
# Security Group for EC2 / SSH
# --------------------------
resource "aws_security_group" "ec2_sg" {
  name   = "ec2_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------
# EC2 Key Pair
# --------------------------
resource "aws_key_pair" "key_pair" {
  key_name   = "github-actions-key-unique-2" # changed name to avoid duplicate
  public_key = var.public_key
}

# --------------------------
# EC2 for SSH tunnel / CI/CD testing
# --------------------------
resource "aws_instance" "ci_cd" {
  ami             = "ami-00ca570c1b6d79f36" # your preferred Linux AMI
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.public_a.id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name = aws_key_pair.key_pair.key_name
  
  tags = {
    Name = "ci-cd-instance"
  }
}

# --------------------------
# RDS Subnet Group (2 private subnets for AZ coverage)
# --------------------------
resource "aws_db_subnet_group" "main" {
  name       = "main_crud"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

# --------------------------
# RDS PostgreSQL
# --------------------------
resource "aws_db_instance" "postgres" {
  identifier        = "crud-rds"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = var.db_username
  password          = var.db_password
  db_name           = "cruddb"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "my_lambda" {
  function_name = "my-function"
  handler       = "index.handler"       # Make sure index.js exports `handler`
  runtime       = "nodejs24.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "../function.zip"     # Relative path to your zipped code
  source_code_hash = filebase64sha256("../function.zip")
  environment {
    variables = {
      DB_HOST     = var.db_host
      DB_USER     = var.db_user
      DB_PASSWORD = var.db_password
      DB_NAME     = var.db_name
      DB_PORT     = var.db_port
    }
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-api"
  description = "API for Lambda CRUD"
}

# Root Resource: /users
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "users"
}

# Resource: /users/{id} for PUT, DELETE
resource "aws_api_gateway_resource" "user_id" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{id}"
}

# --- Methods and Integrations ---

# GET /users
resource "aws_api_gateway_method" "get_users" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.users.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_get_users" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.users.id
  http_method             = aws_api_gateway_method.get_users.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda.invoke_arn
}

# POST /users
resource "aws_api_gateway_method" "post_users" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.users.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_post_users" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.users.id
  http_method             = aws_api_gateway_method.post_users.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda.invoke_arn
}

# PUT /users/{id}
resource "aws_api_gateway_method" "put_user" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.user_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_put_user" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.user_id.id
  http_method             = aws_api_gateway_method.put_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda.invoke_arn
}

# DELETE /users/{id}
resource "aws_api_gateway_method" "delete_user" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.user_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_delete_user" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.user_id.id
  http_method             = aws_api_gateway_method.delete_user.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda.invoke_arn
}

# Deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_get_users,
    aws_api_gateway_integration.lambda_post_users,
    aws_api_gateway_integration.lambda_put_user,
    aws_api_gateway_integration.lambda_delete_user
  ]
  rest_api_id = aws_api_gateway_rest_api.my_api.id
}

# Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  stage_name    = "prod"
}
