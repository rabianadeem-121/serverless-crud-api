output "ec2_public_ip" {
  value = aws_instance.ci_cd.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "rds_port" {
  value       = aws_db_instance.postgres.port
  description = "The port of the RDS instance"
}
