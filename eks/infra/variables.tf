variable "environment" {
  description = "The environment for the infrastructure"
  type        = string
  default     = "dev"
}

variable "project" {
  type    = string
  default = "bootcampclass5"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "eks-vpc"
}
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "subnet_cidr" {
  type = map(list(string))
  default = {
    private_subnets = [
      "10.0.1.0/24",
      "10.0.2.0/24",
      "10.0.3.0/24"
    ]

    public_subnets = [
      "10.0.4.0/24",
      "10.0.5.0/24",
      "10.0.6.0/24"
    ]

  }
}

variable "app_name" {
  type    = string
  default = "student-portal"

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
