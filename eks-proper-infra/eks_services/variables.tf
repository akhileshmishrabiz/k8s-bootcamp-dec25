variable "prefix" {
  type = string
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