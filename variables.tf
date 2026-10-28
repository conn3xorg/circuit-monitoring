variable "hosts" {
  type        = any
  description = "Hosts to configure: a map of names to addresses, or to host objects with an address and optional host_key, user, port, private_key_file or jump_hosts."
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "User to log in as."
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "SSH port."
}

variable "ssh_private_key_file" {
  type        = string
  default     = null
  description = "Path to a private key. When null, Conn3x uses the SSH agent."
}

variable "ssh_known_hosts_file" {
  type        = string
  default     = null
  description = "known_hosts file to check host keys against. When null, ~/.ssh/known_hosts."
}

variable "ssh_become" {
  type        = bool
  default     = false
  description = "Run commands as root through sudo."
}


variable "grafana_admin_password" {
  type        = string
  ephemeral   = true
  description = "Password for Grafana's admin user. Grafana reads it only on its first start."
}

variable "targets" {
  type        = map(list(string))
  default     = {}
  description = "Scrape targets by job name, as host:port, such as { node = [\"10.0.0.11:9100\", \"10.0.0.12:9100\"] }."

  validation {
    condition     = !contains(keys(var.targets), "prometheus") && !contains(keys(var.targets), "cadvisor")
    error_message = "The prometheus and cadvisor jobs are built in. Give your targets another job name."
  }
}

variable "scrape_interval" {
  type        = string
  default     = "30s"
  description = "How often Prometheus scrapes each target."
}

variable "retention" {
  type        = string
  default     = "15d"
  description = "How long Prometheus keeps samples, such as \"15d\" or \"6w\"."
}

variable "prometheus_listen" {
  type        = string
  default     = "127.0.0.1"
  description = "Address Prometheus's port 9090 is published on. It has no login, so the default keeps it on the host; reach it through Grafana or an SSH tunnel."
}

variable "grafana_listen" {
  type        = string
  default     = "0.0.0.0"
  description = "Address Grafana's port 3000 is published on."
}

variable "cadvisor" {
  type        = bool
  default     = true
  description = "Run cAdvisor too, so Prometheus has metrics for every container on the host."
}

variable "prometheus_version" {
  type        = string
  default     = "v3.15.0"
  description = "Tag of the prom/prometheus image."
}

variable "grafana_version" {
  type        = string
  default     = "13.2.4"
  description = "Tag of the grafana/grafana image."
}

variable "cadvisor_version" {
  type        = string
  default     = "v0.60.6"
  description = "Tag of the ghcr.io/google/cadvisor image."
}
