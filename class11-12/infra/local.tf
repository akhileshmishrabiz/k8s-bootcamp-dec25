locals {
  services_list = [
    {
      name        = "frontend",
      port        = "80"
      target_port = "3000"
      host        = "frontend.${var.environment}.${var.app_name}.${var.domain}"
    },
    {
      name        = "catalogue"
      port        = "5000"
      target_port = "5000"
      host        = "catalogue.${var.environment}.${var.app_name}.${var.domain}"
    },
    {
      name        = "voting"
      port        = "8080"
      target_port = "8080"
      host        = "voting.${var.environment}.${var.app_name}.${var.domain}"
    },
    {
      name        = "recco"
      port        = "8080"
      target_port = "8080"
      host        = "recco.${var.environment}.${var.app_name}.${var.domain}"
    },
  ]

  # Map transformation for use with for_each
  services = { for svc in local.services_list : svc.name => svc }
}