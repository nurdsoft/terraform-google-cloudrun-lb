# ------------------------------------------------------------------------------
# Internal Service Access
# ------------------------------------------------------------------------------

# --- Project ---

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

# --- Network ---

variable "vpc_network" {
  description = "The name of the VPC network."
  type        = string
}

variable "proxy_subnet_ip_cidr_range" {
  description = "The dedicated CIDR range for the proxy-only subnet. This MUST be a unique, non-overlapping range separate from the main VPC subnets. A distinct range is required because the Internal Load Balancer uses this reserved space to provision managed Envoy proxies that terminate and route traffic."
  type        = string
}

# --- DNS / Domain ---

variable "root_domain" {
  description = "Base domain for the load balancer (e.g., example.com)."
  type        = string
}

variable "google_restricted_vip_ips" {
  description = "Restricted Google VIPs for Private Google Access to serverless."
  type        = list(string)
}

# --- Load Balancer ---

variable "lb_ip_name" {
  description = "The name for the reserved static IP."
  type        = string
  default     = "lb-static-ip"
}

variable "path_routing_rules" {
  description = "Map of URL paths to Cloud Run service names."
  type        = map(string)
}

# --- IAP / Auth ---

variable "api_gateway_service_account_name" {
  description = "The name of the service account used by API Gateway (without the @project.iam.gserviceaccount.com suffix)."
  type        = string
  default     = "api-gateway-invoker-sa"
}

