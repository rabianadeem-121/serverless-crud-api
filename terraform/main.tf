# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  map_public_ip_on_launch = true
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Security Group for EC2 / SSH
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  vpc_id      = aws_vpc.main.id

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

# EC2 for SSH tunnel / CI/CD testing
resource "aws_instance" "ci_cd" {
  ami           = "ami-0abcdef1234567890" # your preferred Linux AMI
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.ec2_sg.name]

  key_name      = aws_key_pair.key_pair.key_name
}

resource "aws_key_pair" "key_pair" {
  key_name   = "github-actions-key"
  public_key = var.public_key
}

# RDS
resource "aws_db_instance" "postgres" {
  identifier        = "crud-rds"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "cruddb"     # database name
  username          = var.db_username
  password          = var.db_password

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false
}


resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.private.id]
}
