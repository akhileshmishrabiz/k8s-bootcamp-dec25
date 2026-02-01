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

