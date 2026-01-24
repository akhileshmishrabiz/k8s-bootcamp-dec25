module "eks" {
  count =  var.if_eks_needed ? 1 : 0
  source  = "terraform-aws-modules/eks/aws"
  version = "21.5.0"

  name               = "${var.environment}-${var.prefix}-${var.eks_cluster_name}"
  kubernetes_version = "1.33"

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id = module.vpc.vpc_id
  # private subne for eks control and node 
  subnet_ids = module.vpc.private_subnets
  #   control_plane_subnet_ids = ["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }

  tags = {
    Terraform = "true"
    repo      = "k8s-bootcamp-dec25"
  }
}