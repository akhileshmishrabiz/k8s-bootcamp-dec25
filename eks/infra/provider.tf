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


data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}
# # aws provider alias for different regions
# provider "aws" {
#     alias  = "aws-west"
#     region = "us-west-2"
# }



provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Configure Helm Provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
