variable "prefix" {
  type    = string
  default = "dec"
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

# eks_cluster_name = "eksbootcamp"

variable "domain" {
  default = "akhileshmishra.tech"
}

variable "app_name" {
  default = "craftica"
}


variable "db_default_settings" {
  type = any
  default = {
    allocated_storage       = 30
    max_allocated_storage   = 50
    engine_version          = 14.15
    instance_class          = "db.t3.micro"
    backup_retention_period = 2
    db_name                 = "postgres"
    ca_cert_name            = "rds-ca-rsa2048-g1"
    db_admin_username       = "postgres"
  }
}