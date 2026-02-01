# Data source to get the ALB details from the Kubernetes Ingress
# The ingress controller creates the ALB, so we need to wait for it and fetch the hostname
data "kubernetes_ingress_v1" "app_ingress_status" {
  metadata {
    name      = "argocd-server-ingress"
    namespace = "argocd"
  }

  depends_on = [
    kubernetes_ingress_v1.argocd
  ]
}


# cretae a route for subdomain -> ALB (aftr ingress is created in k8s)
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "*.${var.environment}.${var.app_name}.${data.aws_route53_zone.public.name}"
  type    = "A"

  alias {
    name                   = try(data.kubernetes_ingress_v1.app_ingress_status.status[0].load_balancer[0].ingress[0].hostname, "")
    zone_id                = "ZP97RAFLXTNZK" # ap-south-1 ALB zone ID

    evaluate_target_health = true
  }

  depends_on = [
    data.kubernetes_ingress_v1.app_ingress_status
  ]
}

