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

