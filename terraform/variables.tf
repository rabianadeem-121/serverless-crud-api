variable "aws_region" { default = "ap-south-1" }
variable "vpc_cidr" { default = "10.0.0.0/16" }

variable "db_username" { default = "appuser" }
variable "db_password" { default = "ChangeMe123!" }
variable "instance_type" { default = "t3.micro" }
variable "public_key" {
  type = string
}


variable "public_subnet_cidr_a" {
  description = "CIDR block for public subnet in AZ a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_b" {
  description = "CIDR block for public subnet in AZ b"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr_a" {
  description = "CIDR block for private subnet in AZ a"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR block for private subnet in AZ b"
  type        = string
  default     = "10.0.11.0/24"
}

variable "db_host" {
  description = "RDS database host endpoint"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}