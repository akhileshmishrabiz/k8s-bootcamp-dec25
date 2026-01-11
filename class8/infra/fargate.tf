resource "kubernetes_namespace" "ns" {
  metadata {
    labels = {
      mylabel = "simple-nginx"
    }

    name = "simple-nginx"
  }
}

resource "aws_eks_fargate_profile" "fargate" {
  cluster_name           = data.aws_eks_cluster.eks.name
  fargate_profile_name   = kubernetes_namespace.ns.metadata[0].name # implict dependency
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn


#   subnet_ids             = ["subnet-0ffee1d8c65497cd5", "subnet-0c2476d7b7944b8bf", "subnet-0a9a27cd4d883b86c"] #module.vpc.private_subnets
    subnet_ids             = data.aws_eks_cluster.eks.vpc_config[0]["subnet_ids"]

  selector {
    namespace = kubernetes_namespace.ns.metadata[0].name
  }
}


resource "kubernetes_deployment" "nginx" {
    metadata {
        name      = "nginx"
        namespace = kubernetes_namespace.ns.metadata[0].name
    }

    spec {
        replicas = 2

        selector {
            match_labels = {
                app = "nginx"
            }
        }

        template {
            metadata {
                labels = {
                    app = "nginx"
                }
            }

            spec {
                container {
                    image = "nginx:latest"
                    name  = "nginx"

                    port {
                        container_port = 80
                    }
                }
            }
        }
    }

    depends_on = [aws_eks_fargate_profile.fargate]
}



resource "aws_iam_role" "eks_fargate_pod_execution_role" {
    name = "${data.aws_eks_cluster.eks.name}-fargate-pod-execution-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "eks-fargate-pods.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution_role_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
    role       = aws_iam_role.eks_fargate_pod_execution_role.name
}