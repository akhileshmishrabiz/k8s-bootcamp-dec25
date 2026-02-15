# Deploy Metric Server using Helm
resource "helm_release" "metric_server" {
    name             = "metrics-server"
    repository       = "https://kubernetes-sigs.github.io/metrics-server/"
    chart            = "metrics-server"
    namespace        = "kube-system"
    create_namespace = true

    set {
        name  = "args[0]"
        value = "--kubelet-insecure-tls"
    }

    set {
        name  = "args[1]"
        value = "--kubelet-preferred-address-types=InternalIP"
    }
}

output "metric_server_status" {
    description = "Metric Server deployment status"
    value       = helm_release.metric_server.status
}