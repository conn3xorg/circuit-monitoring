variable "port" {
  type    = number
  default = 2222
}

# A throwaway password for a local container.
variable "grafana_admin_password" {
  type      = string
  ephemeral = true
  default   = "change-me-locally"
}

locals {
  box = { box = "127.0.0.1" }
  ssh = {
    ssh_port             = var.port
    ssh_private_key_file = "./id_ed25519"
    ssh_known_hosts_file = "./known_hosts"
  }
}

module "docker" {
  source = "github.com/conn3xorg/circuit-docker?ref=v0.1.0"

  hosts                = local.box
  ssh_port             = local.ssh.ssh_port
  ssh_private_key_file = local.ssh.ssh_private_key_file
  ssh_known_hosts_file = local.ssh.ssh_known_hosts_file
}

module "node_exporter" {
  source = "github.com/conn3xorg/circuit-node-exporter?ref=v0.1.0"

  hosts                = local.box
  ssh_port             = local.ssh.ssh_port
  ssh_private_key_file = local.ssh.ssh_private_key_file
  ssh_known_hosts_file = local.ssh.ssh_known_hosts_file
}

module "monitoring" {
  source = "../.."

  hosts                  = local.box
  grafana_admin_password = var.grafana_admin_password
  # Prometheus runs in a container, so it reaches the host's node_exporter
  # through the Docker bridge.
  targets              = { node = ["172.17.0.1:9100"] }
  ssh_port             = local.ssh.ssh_port
  ssh_private_key_file = local.ssh.ssh_private_key_file
  ssh_known_hosts_file = local.ssh.ssh_known_hosts_file

  depends_on = [module.docker]
}
