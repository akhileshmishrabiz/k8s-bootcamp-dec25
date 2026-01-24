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
  }
}

