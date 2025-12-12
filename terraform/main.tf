# --------------------------
# VPC
# --------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = { Name = "crud-vpc" }
}

# --------------------------
# Public Subnets (2 AZs)
# --------------------------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_a
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = { Name = "public-subnet-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_b
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1b"
  tags = { Name = "public-subnet-b" }
}

# --------------------------
# Private Subnets (2 AZs for RDS)
# --------------------------
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = "ap-south-1a"
  tags = { Name = "private-subnet-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = "ap-south-1b"
  tags = { Name = "private-subnet-b" }
}

# --------------------------
# Internet Gateway
# --------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "crud-igw" }
}

# --------------------------
# Security Groups
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

resource "aws_security_group" "rds_sg" {
  name   = "rds_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # allow EC2 and Lambda
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_sg" {
  name   = "lambda_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------
# EC2 Key Pair (optional)
# --------------------------
resource "aws_key_pair" "key_pair" {
  key_name   = "github-actions-key"
  public_key = var.public_key
}

# --------------------------
# EC2 Instance (optional)
# --------------------------
resource "aws_instance" "ci_cd" {
  ami             = "ami-00ca570c1b6d79f36" # change to preferred Linux AMI
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name = aws_key_pair.key_pair.key_name
  tags = { Name = "ci-cd-instance" }
}

# --------------------------
# RDS Subnet Group
# --------------------------
resource "aws_db_subnet_group" "main" {
  name       = "crud-subnet-group"
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
  db_name           = var.db_name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false
  skip_final_snapshot    = true
}

# --------------------------
# IAM Role for Lambda
# --------------------------
resource "aws_iam_role" "lambda_exec" {
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

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# --------------------------
# Lambda Function (Docker Image)
# --------------------------
resource "aws_lambda_function" "crud_lambda" {
  function_name = "crud-lambda"
  package_type  = "Image"
  image_uri     = var.lambda_image_uri
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 15

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# --------------------------
# API Gateway
# --------------------------
resource "aws_api_gateway_rest_api" "crud_api" {
  name        = "crud-api"
  description = "CRUD API Gateway"
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_apigateway_rest_api.crud_api.id
  parent_id   = aws_apigateway_rest_api.crud_api.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_method" "users_get" {
  rest_api_id   = aws_apigateway_rest_api.crud_api.id
  resource_id   = aws_apigateway_resource.users.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "users_get" {
  rest_api_id             = aws_apigateway_rest_api.crud_api.id
  resource_id             = aws_apigateway_resource.users.id
  http_method             = aws_apigateway_method.users_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.crud_lambda.invoke_arn
}

// ...existing code...
resource "aws_api_gateway_deployment" "prod" {
  depends_on = [aws_apigateway_integration.users_get]
  rest_api_id = aws_apigateway_rest_api.crud_api.id
  # stage_name removed — deployments don't manage stages
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.prod.id
  rest_api_id   = aws_apigateway_rest_api.crud_api.id
  stage_name    = "prod"
}
