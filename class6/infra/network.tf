module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name = "${var.project}-${var.environment}-${var.vpc_name}"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = [var.subnet_cidr["private_subnets"][0], var.subnet_cidr["private_subnets"][1], var.subnet_cidr["private_subnets"][2]]
  public_subnets  = [var.subnet_cidr["public_subnets"][0], var.subnet_cidr["public_subnets"][1], var.subnet_cidr["public_subnets"][2]]


# Yes, EKS nodes generally need a NAT gateway (or a public IP and an Internet Gateway) to 
# join and operate within a private subnet
# we also need NAT to allow pods get imange(private or public) from internet
    enable_nat_gateway = true
    single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required tags for EKS cluster subnet discovery
  public_subnet_tags = {
    "kubernetes.io/cluster/eks-cluster-5-3rdjan" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/eks-cluster-5-3rdjan" = "shared"
    "kubernetes.io/role/internal-elb"            = "1"
  }
}