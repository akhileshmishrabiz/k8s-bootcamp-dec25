
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



