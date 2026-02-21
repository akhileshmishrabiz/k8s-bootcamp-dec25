output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "The port the RDS instance is listening on"
  value       = aws_db_instance.postgres.port
}

output "rds_db_name" {
  description = "The name of the default database"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "The master username for the database"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "rds_password" {
  description = "The master password for the database"
  value       = random_password.db_password.result
  sensitive   = true
}

output "rds_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.postgres.arn
}

output "rds_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.postgres.id
}

output "rds_resource_id" {
  description = "The RDS resource ID"
  value       = aws_db_instance.postgres.resource_id
}

output "rds_security_group_id" {
  description = "The ID of the security group attached to the RDS instance"
  value       = aws_security_group.rds_sg.id
}

output "rds_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.rds_subnet_group.name
}

output "rds_subnet_group_arn" {
  description = "The ARN of the DB subnet group"
  value       = aws_db_subnet_group.rds_subnet_group.arn
}

output "rds_multi_az" {
  description = "Whether the RDS instance is multi-AZ"
  value       = aws_db_instance.postgres.multi_az
}

output "rds_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = aws_db_instance.postgres.availability_zone
}

output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${aws_db_instance.postgres.username}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
  sensitive   = true
}
