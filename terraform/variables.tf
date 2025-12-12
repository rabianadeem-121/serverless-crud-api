variable "aws_region" {
  description = "AWS Region"
  default     = "ap-south-1"
}

variable "db_username" {
  description = "RDS username"
  type        = string
}

variable "db_password" {
  description = "RDS password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "docker_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}
