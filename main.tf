# ------------------------------------------------------------------------------
# Cloud Run LB
# ------------------------------------------------------------------------------

locals {
  lb_domain              = var.environment == "prod" ? "api.${var.root_domain}" : "api.${var.environment}.${var.root_domain}"
  cloud_run_services     = toset(values(var.path_routing_rules))
  internal_domain_suffix = "${var.environment}.internal"
}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_network" "vpc" {
  name    = var.vpc_network
  project = var.project_id
}

data "google_compute_subnetwork" "internal_subnet" {
  name    = "${var.environment}-default-subnet"
  region  = var.region
  project = var.project_id
}

# ------------------------------------------------------------------------------
# Serverless NEGs
# ------------------------------------------------------------------------------

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  for_each = local.cloud_run_services
  provider = google-beta

  name                  = "${each.key}-neg-${var.environment}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = each.key
  }
}

# ------------------------------------------------------------------------------
# External Application Load Balancer
# ------------------------------------------------------------------------------

resource "google_compute_global_address" "lb_static_ip" {
  name = "${var.lb_ip_name}-${var.environment}"
}

resource "google_compute_managed_ssl_certificate" "lb_ssl_cert" {
  name = "lb-ssl-cert-${var.environment}-v2"
  managed {
    domains = [local.lb_domain]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_backend_service" "backend_services" {
  for_each = local.cloud_run_services

  name                  = "${each.key}-backend-${var.environment}"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg[each.key].id
  }

  iap {
    oauth2_client_id     = google_iap_client.lb_iap_client.client_id
    oauth2_client_secret = google_iap_client.lb_iap_client.secret
  }
}

resource "google_compute_url_map" "lb_url_map" {
  name = "multi-service-lb-url-map-${var.environment}"

  default_service = values(google_compute_backend_service.backend_services)[0].id

  host_rule {
    hosts        = [local.lb_domain]
    path_matcher = "all-paths"
  }

  path_matcher {
    name            = "all-paths"
    default_service = values(google_compute_backend_service.backend_services)[0].id

    dynamic "path_rule" {
      for_each = var.path_routing_rules

      content {
        paths   = [path_rule.key]
        service = google_compute_backend_service.backend_services[path_rule.value].id
      }
    }
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "lb-https-proxy-${var.environment}"
  url_map          = google_compute_url_map.lb_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_ssl_cert.id]
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "lb-forwarding-rule-${var.environment}"
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = google_compute_global_address.lb_static_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# ------------------------------------------------------------------------------
# IAP Configuration
# ------------------------------------------------------------------------------

resource "google_iap_client" "lb_iap_client" {
  provider     = google-beta
  brand        = "projects/${data.google_project.project.number}/brands/${data.google_project.project.number}"
  display_name = "Terraform IAP Client for ${local.lb_domain}"
}

resource "google_iap_web_backend_service_iam_member" "api_gateway_access" {
  for_each = local.cloud_run_services
  provider = google-beta

  project             = var.project_id
  web_backend_service = google_compute_backend_service.backend_services[each.key].name
  role                = "roles/iap.httpsResourceAccessor"
  member              = "serviceAccount:${var.api_gateway_service_account_name}@${var.project_id}.iam.gserviceaccount.com"

  depends_on = [
    google_compute_backend_service.backend_services
  ]
}

resource "google_project_service_identity" "iap_sa" {
  provider = google-beta
  service  = "iap.googleapis.com"
  project  = var.project_id
}

resource "google_cloud_run_service_iam_member" "iap_invoker" {
  for_each = local.cloud_run_services

  location = var.region
  project  = var.project_id
  service  = each.key
  role     = "roles/run.invoker"

  member = "serviceAccount:${google_project_service_identity.iap_sa.email}"
}

# ------------------------------------------------------------------------------
# Private DNS Zone for run.app (VPC-internal Cloud Run routing)
# ------------------------------------------------------------------------------

resource "google_dns_managed_zone" "run_app_private" {
  provider    = google-beta
  name        = "cloud-run-app-private-${var.environment}"
  dns_name    = "run.app."
  description = "Private DNS zone for internal Cloud Run services"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.vpc.self_link
    }
  }
}

resource "google_dns_record_set" "run_app_cname" {
  provider     = google-beta
  name         = "*.run.app."
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.run_app_private.name
  rrdatas      = ["run.app."]
}

resource "google_dns_record_set" "run_app_a_record" {
  provider     = google-beta
  name         = "run.app."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.run_app_private.name
  rrdatas      = var.google_restricted_vip_ips
}

# ------------------------------------------------------------------------------
# Internal Application Load Balancer
# ------------------------------------------------------------------------------

resource "google_compute_address" "internal_lb_ip" {
  name         = "internal-lb-ip-${var.environment}"
  subnetwork   = data.google_compute_subnetwork.internal_subnet.id
  address_type = "INTERNAL"
  region       = var.region
}

resource "google_compute_backend_service" "internal_backends" {
  for_each              = local.cloud_run_services
  provider              = google-beta
  name                  = each.key
  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    group          = google_compute_region_network_endpoint_group.serverless_neg[each.key].id
    balancing_mode = "UTILIZATION"
  }
}

resource "google_compute_url_map" "internal_lb_url_map" {
  name            = "internal-lb-url-map-${var.environment}"
  default_service = values(google_compute_backend_service.internal_backends)[0].id

  dynamic "host_rule" {
    for_each = local.cloud_run_services
    content {
      hosts        = ["${host_rule.key}.${local.internal_domain_suffix}"]
      path_matcher = host_rule.key
    }
  }

  dynamic "path_matcher" {
    for_each = local.cloud_run_services
    content {
      name            = path_matcher.key
      default_service = google_compute_backend_service.internal_backends[path_matcher.key].id
    }
  }
}

resource "google_compute_target_http_proxy" "internal_http_proxy" {
  name    = "internal-lb-proxy-${var.environment}"
  url_map = google_compute_url_map.internal_lb_url_map.id
}

resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "proxy-only-subnet-${var.environment}"
  ip_cidr_range = var.proxy_subnet_ip_cidr_range
  network       = data.google_compute_network.vpc.id
  region        = var.region
  purpose       = "GLOBAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_global_forwarding_rule" "internal_forwarding_rule" {
  name                  = "internal-lb-forwarding-rule-${var.environment}"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.internal_http_proxy.id
  network               = data.google_compute_network.vpc.id
  subnetwork            = data.google_compute_subnetwork.internal_subnet.id
  ip_address            = google_compute_address.internal_lb_ip.address

  depends_on = [
    google_compute_subnetwork.proxy_subnet,
    google_compute_target_http_proxy.internal_http_proxy
  ]
}

# ------------------------------------------------------------------------------
# Private DNS Zone for {env}.internal (internal service discovery)
# ------------------------------------------------------------------------------

resource "google_dns_managed_zone" "internal_zone" {
  name        = "${var.environment}-internal-zone"
  dns_name    = "${local.internal_domain_suffix}."
  description = "Private zone for ${var.environment}.internal"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.vpc.id
    }
  }
}

resource "google_dns_record_set" "internal_wildcard" {
  name         = "*.${google_dns_managed_zone.internal_zone.dns_name}"
  managed_zone = google_dns_managed_zone.internal_zone.name
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_address.internal_lb_ip.address]
}
