variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_a" {
  description = "CIDR block for public subnet in AZ a"
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_b" {
  description = "CIDR block for public subnet in AZ b"
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr_a" {
  description = "CIDR block for private subnet in AZ a"
  default     = "10.0.10.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR block for private subnet in AZ b"
  default     = "10.0.11.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "public_key" {
  description = "EC2 public key for SSH"
  type        = string
}

variable "db_username" {
  description = "RDS database username"
  type        = string
  default = "appuser"
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
  default = "ChangeMe123!"
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default = "cruddb" 
}

variable "lambda_image_uri" {
  description = "Docker image URI for Lambda"
  type        = string
  default = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/crud-lambda:latest"
}

variable "lambda_function_name" { default = "crud-lambda" }