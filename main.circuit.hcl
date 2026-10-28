locals {
  dir = "/opt/stacks/monitoring"

  prometheus_config = yamlencode({
    global = { scrape_interval = var.scrape_interval }
    scrape_configs = concat(
      [{ job_name = "prometheus", static_configs = [{ targets = ["localhost:9090"] }] }],
      var.cadvisor ? [{ job_name = "cadvisor", static_configs = [{ targets = ["cadvisor:8080"] }] }] : [],
      [for job, targets in var.targets : { job_name = job, static_configs = [{ targets = targets }] }],
    )
  })

  grafana_datasource = yamlencode({
    apiVersion  = 1
    datasources = [{ name = "Prometheus", type = "prometheus", access = "proxy", url = "http://prometheus:9090", isDefault = true }]
  })

  compose = yamlencode({
    services = merge({
      prometheus = {
        image   = "docker.io/prom/prometheus:${var.prometheus_version}"
        command = ["--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus", "--storage.tsdb.retention.time=${var.retention}"]
        configs = [{ source = "prometheus", target = "/etc/prometheus/prometheus.yml" }]
        volumes = ["prometheus:/prometheus"]
        ports   = ["${var.prometheus_listen}:9090:9090"]
        restart = "unless-stopped"
      }
      grafana = {
        image = "docker.io/grafana/grafana:${var.grafana_version}"
        environment = {
          GF_SECURITY_ADMIN_PASSWORD__FILE = "/run/secrets/grafana_admin_password"
          GF_USERS_ALLOW_SIGN_UP           = "false"
        }
        secrets = ["grafana_admin_password"]
        configs = [{ source = "grafana_datasource", target = "/etc/grafana/provisioning/datasources/prometheus.yaml" }]
        volumes = ["grafana:/var/lib/grafana"]
        ports   = ["${var.grafana_listen}:3000:3000"]
        restart = "unless-stopped"
      }
      }, var.cadvisor ? {
      cadvisor = {
        image      = "ghcr.io/google/cadvisor:${var.cadvisor_version}"
        privileged = true
        devices    = ["/dev/kmsg"]
        volumes    = ["/:/rootfs:ro", "/var/run:/var/run:ro", "/sys:/sys:ro", "/var/lib/docker/:/var/lib/docker:ro", "/dev/disk/:/dev/disk:ro"]
        restart    = "unless-stopped"
      }
    } : {})
    configs = {
      prometheus         = { content = local.prometheus_config }
      grafana_datasource = { content = local.grafana_datasource }
    }
    secrets = {
      grafana_admin_password = { file = "./grafana_admin_password" }
    }
    volumes = { prometheus = {}, grafana = {} }
  })
}

circuit "monitoring" {
  hosts = var.hosts

  ssh {
    user             = var.ssh_user
    port             = var.ssh_port
    private_key_file = var.ssh_private_key_file
    known_hosts_file = var.ssh_known_hosts_file
    become           = var.ssh_become
  }

  step "dir" {
    directory {
      path = local.dir
    }
  }

  # Grafana runs as user 472 in group 0, so the group can read it.
  step "grafana_password" {
    file {
      path       = "${local.dir}/grafana_admin_password"
      content_wo = var.grafana_admin_password
      mode       = "0640"
      group      = "root"
    }
  }

  step "compose" {
    file {
      path    = "${local.dir}/compose.yaml"
      content = local.compose
    }
  }

  # Runs docker compose up when the file changed since the last run, or when
  # one of the services isn't running. A new password only takes effect on
  # Grafana's first start; change it in Grafana after that.
  step "up" {
    command {
      command = "cd ${local.dir} && docker compose up -d --remove-orphans --wait && sha256sum compose.yaml > .applied"
      unless  = "cd ${local.dir} && sha256sum -c --status .applied && [ \"$(docker compose config --services | sort)\" = \"$(docker compose ps --services --status running | sort)\" ]"
    }
  }
}
