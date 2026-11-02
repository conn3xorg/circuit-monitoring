output "grafana_urls" {
  description = "Each host's Grafana URL, by host name."
  value       = { for name, h in var.hosts : name => "http://${var.grafana_listen == "0.0.0.0" ? try(h.address, h) : var.grafana_listen}:3000" }
}
