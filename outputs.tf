output "load_balancer_ip" {
  description = "The static IP address of the global load balancer."
  value       = google_compute_global_address.lb_static_ip.address
}

output "load_balancer_domain" {
  description = "The custom domain configured for the load balancer."
  value       = local.lb_domain
}

output "internal_lb_ip" {
  description = "The automatically assigned Internal LB IP. Update Tailscale DNS with this value."
  value       = google_compute_address.internal_lb_ip.address
}
