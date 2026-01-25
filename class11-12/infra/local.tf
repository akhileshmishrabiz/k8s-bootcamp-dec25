locals {
  services_list = [
    { name = "frontend" },
    { name = "catalogue" },
    { name = "voting" },
    { name = "recco" },
  ]

  # Map transformation for use with for_each
  services = { for svc in local.services_list : svc.name => svc }
}