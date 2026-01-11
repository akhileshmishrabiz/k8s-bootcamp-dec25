

# cretae/import th public hosted zone for your domain in route53 and update nameservers in your domain registrar
data "aws_route53_zone" "main" {
  name         = "akhileshmishra.tech"
  private_zone = false
}

# Data source to get the ALB details from the Kubernetes Ingress
# The ingress controller creates the ALB, so we need to wait for it and fetch the hostname
data "kubernetes_ingress_v1" "app_ingress_status" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = var.app_name
  }

  depends_on = [
    kubernetes_ingress_v1.app_ingress
  ]
}


# cretae a route for subdomain -> ALB (aftr ingress is created in k8s)
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.app_name}.${data.aws_route53_zone.main.name}"
  type    = "A"

  alias {
    name                   = try(data.kubernetes_ingress_v1.app_ingress_status.status[0].load_balancer[0].ingress[0].hostname, "")
    zone_id                = "ZP97RAFLXTNZK"  # ap-south-1 ALB zone ID

    evaluate_target_health = true
  }

  depends_on = [
    data.kubernetes_ingress_v1.app_ingress_status
  ]
}


# need acm cert on subdomain
# need to validate the cert (create on record for acm cert )


resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.app_name}.${data.aws_route53_zone.main.name}"
  validation_method = "DNS"

  tags = {
    subName = "${var.app_name}.${data.aws_route53_zone.main.name}"
  }
}
# # Create a DNS validation record
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}


# # Validate the ACM certificate
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}