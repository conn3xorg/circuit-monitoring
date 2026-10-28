output "grafana_urls" {
  description = "Each host's Grafana URL, by host name."
  value       = { for name, h in var.hosts : name => "http://${try(h.address, h)}:3000" }
}
