terraform {
  required_version = "1.8.1" # 1.12.1
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      class = "eks-5-3rdjan"
    }
  }
}


# # aws provider alias for different regions
# provider "aws" {
#     alias  = "aws-west"
#     region = "us-west-2"
# }