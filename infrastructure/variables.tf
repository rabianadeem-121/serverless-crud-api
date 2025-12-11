variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "lambda_name" {
  type    = string
}

variable "lambda_zip" {
  type    = string
}

variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_ids" {
  type = list(string)
}
