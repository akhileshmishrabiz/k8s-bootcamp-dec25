terraform {
  required_version = "~> 1.8.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


terraform {
  backend "s3" {
    bucket  = "state-bucket-879381241087"
    key     = "k8s-bootcamp-dec25/github-oidc-aws/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "august-bootcamp"
      class   = "21december"
      repo    = "k8s-bootcamp-dec25/github-oidc-aws"
    }
  }
}