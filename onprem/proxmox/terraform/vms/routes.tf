# ==========================================================
# 🌐 AIT Brainlab - Traefik Dynamic Ingress Routes Generator
# ==========================================================
# Declaratively generates dynamic Traefik file configuration
# and syncs routes to /opt/brainlab/traefik/dynamic/routes.yaml
# on brainlab-proxy (VM 100) with instant hot-reload.
# ==========================================================

locals {
  # 1. Declarative Traefik HTTP Routers & Services Structure
  traefik_dynamic_config = {
    http = {
      routers = {
        for name, route in var.proxy_routes : "${name}-router" => {
          rule        = join(" || ", concat(["Host(`${route.domain}`)"], [for alias in route.aliases : "Host(`${alias}`)"]))
          entryPoints = ["websecure"]
          tls = {
            certResolver = "letsencrypt"
          }
          service = "${name}-service"
        }
      }
      services = {
        for name, route in var.proxy_routes : "${name}-service" => {
          loadBalancer = {
            servers = [
              {
                url = route.target_url
              }
            ]
          }
        }
      }
    }
  }

  # 2. Rendered YAML string
  traefik_dynamic_routes_yaml = yamlencode(local.traefik_dynamic_config)
}
