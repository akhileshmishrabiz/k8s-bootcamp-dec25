# Generate random password for RDS master user
resource "random_password" "db_password" {
  length  = 16
  special = true
  # Avoid characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# DB Subnet Group for RDS instance
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.db_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.db_identifier}-subnet-group"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

# Security Group for RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "${var.db_identifier}-sg"
  description = "Security group for ${var.db_identifier} RDS instance"
  vpc_id      = var.vpc_id

  # Ingress rule for PostgreSQL
  ingress {
    description = "PostgreSQL access from allowed CIDR blocks"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = length(var.allowed_cidr_blocks) > 0 ? var.allowed_cidr_blocks : []
  }

  # Egress rule - allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.db_identifier}-sg"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

# RDS PostgreSQL Instance
# checkov:skip=CKV2_AWS_30:too costly dont need it
resource "aws_db_instance" "postgres" {
  # Basic configuration
  identifier     = var.db_identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  # Using default AWS managed key for encryption
  # For custom KMS key, uncomment and provide kms_key_id
  # kms_key_id = var.kms_key_id

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  # High Availability
  multi_az = var.multi_az

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.db_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot     = true

  # Performance Insights
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  # Parameter group (using default for now, can be customized)
  # parameter_group_name = aws_db_parameter_group.postgres.name

  tags = {
    Name        = var.db_identifier
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Engine      = "PostgreSQL"
    MultiAZ     = var.multi_az
  }

  lifecycle {
    # Prevent accidental deletion of the database
    prevent_destroy = false
    # Ignore changes to password (to prevent recreation if password is changed externally)
    ignore_changes = [password]
  }
}
