# -----------------------------------------------------------------------------
# Example: Cloud Run LB
#
# This example shows the minimal setup to use the cloudrun-lb module.
# It provisions a dual-layer (external IAP-protected + internal) load balancer
# for Cloud Run services with private DNS zones for VPC-internal routing.
# -----------------------------------------------------------------------------
module "cloudrun_lb" {
  source = "../.."

  project_id                 = var.project_id
  environment                = var.environment
  region                     = var.region
  vpc_network                = var.vpc_network
  root_domain                = var.root_domain
  proxy_subnet_ip_cidr_range = var.proxy_subnet_ip_cidr_range
  google_restricted_vip_ips  = var.google_restricted_vip_ips
  path_routing_rules         = var.path_routing_rules

  lb_ip_name                       = var.lb_ip_name
  api_gateway_service_account_name = var.api_gateway_service_account_name
}
