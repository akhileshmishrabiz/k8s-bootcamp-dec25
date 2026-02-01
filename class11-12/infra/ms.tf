resource "kubernetes_service" "services" {
  for_each = local.services
  metadata {
    name = each.key
    namespace = var.app_name
  }
  spec {
    selector = {
      app = each.key
    }
    port {
      port        = each.value.port
      target_port = each.value.target_port
    }

    type = "ClusterIP"
  }
}

 resource "kubernetes_ingress_v1" "ms" {
  for_each = local.services
  metadata {
    name      = "${each.key}-ingress"
    namespace = var.app_name

    annotations = {
      # Create an internet-facing ALB (public access)
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"

      # Use IP mode for better compatibility with Fargate and pod networking
      "alb.ingress.kubernetes.io/target-type" = "ip"

      # Health check path - ALB will check this endpoint for service health
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"

      # SSL/TLS Configuration
      # Listen on both HTTP (80) and HTTPS (443) ports
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"

      # Automatically redirect HTTP traffic to HTTPS
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"

      # SSL Security Policy - ensures strong encryption
      "alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-2-2017-01"

      # AWS ACM Certificate ARN - replace with your certificate ARN
      # NOTE: Ensure this certificate covers your domain and is in the correct AWS region
      "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate.cert.arn

      # HTTP to HTTPS redirect action configuration
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": {\"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"

      # Group name - all ingresses with the same group share a single ALB
      "alb.ingress.kubernetes.io/group.name" = "shared-alb"
    }
  }

  spec {
    # Use the same NGINX ingress controller (shares NLB with application)
    ingress_class_name = "alb"

    # TLS configuration
    tls {
      hosts = [
        each.value.host
      ]
    }

    # Routing rule for ArgoCD UI
    rule {
      host = each.value.host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              # ArgoCD server service name (created by Helm chart)
              name = each.key
              port {
                number = each.value.port
              }
            }
          }
        }
      }
    }
  }
 }