# namespace -> devopsdozo (app_name)
resource "kubernetes_namespace" "app_ns" {
    metadata {
        name = var.app_name
    }
}

# database secrets
resource "kubernetes_secret" "db_secrets" {
    metadata {
        name      = "db-secrets"
        namespace = kubernetes_namespace.app_ns.metadata[0].name
    }

    data = {
        DATABASE_URL = "postgresql://${var.db_default_settings.db_admin_username}:${random_password.rds_password.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
        SECRET_KEY   = random_password.backend_secret_key.result
        DB_PASSWORD = random_password.rds_password.result
    }

    type = "Opaque"
}

# application configmap
resource "kubernetes_config_map" "app_config" {
    metadata {
        name      = "app-config"
        namespace = kubernetes_namespace.app_ns.metadata[0].name
    }

    data = {
        FLASK_DEBUG = "1"
        DB_NAME     = aws_db_instance.postgres.db_name
        DB_HOST     = aws_db_instance.postgres.address
        DB_PORT     = tostring(aws_db_instance.postgres.port)
        DB_USER     = var.db_default_settings.db_admin_username
    }
}

# external database service
resource "kubernetes_service" "external_db_service" {
    metadata {
        name      = "${var.app_name}-db-service"
        namespace = kubernetes_namespace.app_ns.metadata[0].name
    }

    spec {
        type          = "ExternalName"
        external_name = aws_db_instance.postgres.address
    }
}

# servicename: devopsdozo-db-service 
# namespace: devopsdozo
# dns name: ServiceName.Namespace.svc.cluster.local
# full dns: devopsdozo-db-service.devopsdozo.svc.cluster.local  


#### ingress ns setup

# HTTPS/SSL Ingress Configuration with TLS termination
# This creates an ALB with SSL certificate and HTTP to HTTPS redirect
resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.app_ns.metadata[0].name

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
    }
  }

  spec {
    # Use the ALB ingress class
    ingress_class_name = "alb"

    # TLS configuration for certificate management
    tls {
      hosts = ["devopsdozo.akhileshmishra.tech"]
    }

    # Single subdomain rule - all traffic for app.akhileshmishra.tech
    rule {
      host = "devopsdozo.akhileshmishra.tech"

      http {
        # Route API calls to backend service (must come first for priority)
        path {
          path      = "/api"
          path_type = "Prefix"

          backend {
            service {
              name = "backend"
              port {
                number = 8000
              }
            }
          }
        }

        # Route all other traffic to frontend
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "frontend"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.app_ns,
    aws_acm_certificate.cert
  ]
}
