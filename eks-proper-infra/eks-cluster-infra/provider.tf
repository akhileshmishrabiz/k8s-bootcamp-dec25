provider "aws" {
  region = "ap-south-1"
  # assume_role {
  #   role_arn    = "arn:aws:iam::01234567890:role/role_in_account_b"
  # }
  default_tags {
    tags = {
      class = "eks-5-3rdjan"
    }
  }
}