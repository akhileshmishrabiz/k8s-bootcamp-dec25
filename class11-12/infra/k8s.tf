resource "kubernetes_namespace" "craftista" {
  metadata {
    name = var.app_name

    labels = {
      name        = var.app_name
      managed-by  = "terraform"
      environment = var.environment
    }
  }
}

# Secret for Database Credentials (mounted as volume)
resource "kubernetes_secret" "catalogue_db_secrets" {
  metadata {
    name      = "catalogue-db-secrets"
    namespace = var.app_name

    labels = {
      app         = "catalogue-service"
      managed-by  = "terraform"
      environment = var.environment
    }
  }

  type = "Opaque"

  # Database credentials (will be mounted as files in /app/secrets/)
  data = {
    db_user     = aws_db_instance.postgres.username        # Creates file: /app/secrets/db_user
    db_password = random_password.dbs_random_string.result # Creates file: /app/secrets/db_password
  }

  depends_on = [kubernetes_namespace.craftista]
}

# ConfigMap for Application Configuration (mounted as volume)
resource "kubernetes_config_map" "catalogue_config" {
  metadata {
    name      = "catalogue-config"
    namespace = var.app_name

    labels = {
      app         = "catalogue-service"
      managed-by  = "terraform"
      environment = var.environment
    }
  }

  data = {
    # App version as top-level key for environment variable
    app_version = "1.0.0"

    # This will be mounted as /app/config.json
    "config.json" = jsonencode({
      app_version = "1.0.0"
      data_source = "db"
      db_host     = aws_db_instance.postgres.address
      db_name     = aws_db_instance.postgres.db_name
      db_user     = aws_db_instance.postgres.username
      db_password = "placeholder" # Will be overridden by secret volume
    })

    # This will be mounted as /app/db-config/db-config.properties
    "db-config.properties" = <<-EOT
      db_name=${aws_db_instance.postgres.db_name}
      db_host=${aws_db_instance.postgres.address}
    EOT
  }

  depends_on = [kubernetes_namespace.craftista]
}


