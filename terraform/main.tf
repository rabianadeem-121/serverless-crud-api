# =========================================
# VARIABLES: Make sure they exist in variables.tf
# var.vpc_cidr
# var.public_subnet_cidr_a
# var.public_subnet_cidr_b
# var.private_subnet_cidr_a
# var.private_subnet_cidr_b
# var.db_username
# var.db_password
# var.aws_region
# =========================================

# --------------------------
# VPC
# --------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = { Name = "crud-vpc" }
}

# --------------------------
# Public Subnets (for NAT, optional)
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
# Private Subnets (for RDS and Lambda)
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
  tags   = { Name = "crud-gw" }
}

# --------------------------
# NAT Gateway for private subnets (Lambda needs outbound access)
# --------------------------
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
}

# --------------------------
# Route Tables
# --------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# --------------------------
# Security Group for Lambda → RDS
# --------------------------
resource "aws_security_group" "rds_sg" {
  name   = "rds_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Lambda outbound
resource "aws_security_group" "lambda_sg" {
  name   = "lambda_sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------
# RDS Subnet Group
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

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false
  skip_final_snapshot    = true
}

# --------------------------
# IAM Role for Lambda
# --------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --------------------------
# ECR Repository for Lambda Docker
# --------------------------
resource "aws_ecr_repository" "lambda_repo" {
  name = "crud-lambda-repo"
}

# --------------------------
# Lambda function (Docker)
# --------------------------
resource "aws_lambda_function" "crud_lambda" {
  function_name = "crud-lambda-docker"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = 10
  memory_size   = 512
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment {
    variables = {
      DB_HOST     = aws_db_instance.postgres.address
      DB_PORT     = aws_db_instance.postgres.port
      DB_NAME     = aws_db_instance.postgres.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
    }
  }
}

# --------------------------
# API Gateway
# --------------------------
resource "aws_apigateway_rest_api" "api" {
  name = "crud-api"
}

resource "aws_apigateway_resource" "users" {
  rest_api_id = aws_apigateway_rest_api.api.id
  parent_id   = aws_apigateway_rest_api.api.root_resource_id
  path_part   = "users"
}

resource "aws_apigateway_method" "users_any" {
  rest_api_id   = aws_apigateway_rest_api.api.id
  resource_id   = aws_apigateway_resource.users.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_apigateway_integration" "users_any" {
  rest_api_id             = aws_apigateway_rest_api.api.id
  resource_id             = aws_apigateway_resource.users.id
  http_method             = aws_apigateway_method.users_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.crud_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crud_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

