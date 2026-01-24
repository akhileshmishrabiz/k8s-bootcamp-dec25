
data "aws_eks_cluster" "eks" {
  name = "${var.environment}-${var.prefix}-${var.eks_cluster_name}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${var.environment}-${var.prefix}-${var.eks_cluster_name}"
}

# output "oidc_ulr" {
#   value = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
# }

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# output "oidc_arn" {
#   value = data.aws_iam_openid_connect_provider.eks.arn

# }

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Configure Helm Provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

