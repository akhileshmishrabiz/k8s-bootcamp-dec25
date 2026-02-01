data "aws_route53_zone" "public" {
  name         = var.domain
  private_zone = false
}

# need acm cert on subdomain
# need to validate the cert (create on record for acm cert )


resource "aws_acm_certificate" "cert" {
  domain_name       = "*.${var.environment}.${data.aws_route53_zone.public.name}"
  validation_method = "DNS"

  tags = {
    subName = "${var.environment}.${data.aws_route53_zone.public.name}"
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
  zone_id = data.aws_route53_zone.public.zone_id
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