locals {
  services_list = [
    {
      name        = "frontend",
      port        = "80"
      target_port = "3000"
    },
    {
      name        = "catalogue"
      port        = "5000"
      target_port = "5000"
    },
    {
      name        = "voting"
      port        = "8080"
      target_port = "8080"
    },
    {
      name        = "recco"
      port        = "8080"
      target_port = "8080"
    },
  ]

  # Map transformation for use with for_each
  services = { for svc in local.services_list : svc.name => svc }
}