project_id                 = "your-project-id"
environment                = "dev"
region                     = "us-central1"
vpc_network                = "vpc-network"
root_domain                = "example.com"
proxy_subnet_ip_cidr_range = "10.120.0.0/24"
google_restricted_vip_ips  = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]

path_routing_rules = {
  "/api"    = "my-api-service"
  "/health" = "my-api-service"
}

lb_ip_name                       = "lb-static-ip"
api_gateway_service_account_name = "api-gateway-invoker-sa"
application                      = "myapp"
vendor                           = "myvendor"
