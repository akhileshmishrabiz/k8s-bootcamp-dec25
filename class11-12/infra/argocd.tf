resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.16"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Use ClusterIP since ALB will handle external traffic
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Run insecure mode since ALB terminates SSL
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  # Enable Ingress
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "alb"
  }

  set {
    name  = "server.ingress.hostname"
    #value = var.argocd_domain
    value = "argocd.${var.environment}.${var.domain}"
  }

  # AWS ALB Ingress annotations
  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
    value = "[{\"HTTPS\":443}]"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = aws_acm_certificate.cert.arn
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/ssl-redirect"
    value = "443"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/backend-protocol"
    value = "HTTP"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/group\\.name"
    value = "shared-alb"
  }

  depends_on = [kubernetes_namespace.argocd]
}
