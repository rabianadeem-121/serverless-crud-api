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
  security_groups = [aws_security_group.ec2_sg.name]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name = aws_key_pair.key_pair.key_name
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
