variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)."
  type        = string
}

variable "region" {
  description = "The GCP region for resources."
  type        = string
  default     = "us-central1"
}

variable "vpc_network" {
  description = "The name of the VPC network."
  type        = string
}

variable "root_domain" {
  description = "Base domain for the load balancer (e.g., example.com)."
  type        = string
}

variable "proxy_subnet_ip_cidr_range" {
  description = "CIDR range for the proxy-only subnet used by the Internal Application Load Balancer."
  type        = string
}

variable "google_restricted_vip_ips" {
  description = "Restricted Google VIPs for Private Google Access to serverless."
  type        = list(string)
  default     = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
}

variable "path_routing_rules" {
  description = "Map of URL paths to Cloud Run service names."
  type        = map(string)
}

# ------------------------------------------------------------------------------
# Optional Overrides — all have sensible defaults in the module
# ------------------------------------------------------------------------------

variable "lb_ip_name" {
  description = "The name for the reserved static IP."
  type        = string
  default     = "lb-static-ip"
}

variable "api_gateway_service_account_name" {
  description = "The name of the service account used by API Gateway (without the @project.iam.gserviceaccount.com suffix)."
  type        = string
  default     = "api-gateway-invoker-sa"
}

variable "application" {
  description = "The name of the application."
  type        = string
  default     = ""
}

variable "vendor" {
  description = "The name of the vendor."
  type        = string
  default     = ""
}
