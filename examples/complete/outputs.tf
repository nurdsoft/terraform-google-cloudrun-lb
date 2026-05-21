output "load_balancer_ip" {
  description = "The static IP address of the global load balancer."
  value       = module.cloudrun_lb.load_balancer_ip
}

output "load_balancer_domain" {
  description = "The custom domain configured for the load balancer."
  value       = module.cloudrun_lb.load_balancer_domain
}

output "internal_lb_ip" {
  description = "The automatically assigned Internal LB IP. Update Tailscale DNS with this value."
  value       = module.cloudrun_lb.internal_lb_ip
}
