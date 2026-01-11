data "aws_eks_cluster" "eks" {
  name = "eks-cluster-5-3rdjan"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "eks-cluster-5-3rdjan"
}



# output "vpcconfg" {
#   value = data.aws_eks_cluster.eks.vpc_config
# }

# output "subnet_ids" {
#   value = data.aws_eks_cluster.eks.vpc_config[0]["subnet_ids"]
# }

# vpc id, vpc cidr
# data.aws_eks_cluster.eks.vpc_config[0]["vpc_id"]
# data.aws_eks_cluster.eks.vpc_config[0]["security_group_ids"]
