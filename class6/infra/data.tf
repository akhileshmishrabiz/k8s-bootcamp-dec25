data "aws_eks_cluster" "eks" {
  name = "eks-cluster-5-3rdjan"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "eks-cluster-5-3rdjan"
}

# data.aws_eks_cluster.eks.endpoint