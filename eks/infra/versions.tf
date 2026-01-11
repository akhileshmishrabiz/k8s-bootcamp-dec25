terraform {
  required_version = "1.8.1" # 1.12.1
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }

  }
}


terraform {
  backend "s3" {
    bucket  = "state-bucket-879381241087"
    key     = "eksbootcampdc25/eksinfra/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
    # assume_role = {
    #   role_arn    = "arn:aws:iam::01234567890:role/role_in_account_b"
    # }
  }
}

#/dev/k8s-bootcamp-dec25/eks/infra/versions.tf