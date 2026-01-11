resource "kubernetes_secret_v1" "db" {
    metadata {
        name      = "db-secret"
        namespace = "student-portal"
    }

    type = "Opaque"

    data = {
       "db_link" = aws_secretsmanager_secret_version.dbs_secret_val.secret_string
    }
}

