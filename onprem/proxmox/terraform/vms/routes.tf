# ==========================================================
# 🌐 AIT Brainlab - Traefik Dynamic Ingress Routes Generator
# ==========================================================
# Declaratively generates dynamic Traefik file configuration
# and syncs routes to /opt/brainlab/traefik/dynamic/routes.yaml
# on brainlab-proxy (VM 100) with instant hot-reload.
# ==========================================================

locals {
  # 1. Declarative Traefik HTTP Routers, Middlewares & Services Structure
  traefik_dynamic_config = {
    http = {
      routers = merge(
        # Secure Routers (Port 443 with Let's Encrypt TLS for enable_tls = true)
        {
          for name, route in var.proxy_routes : "${name}-router" => {
            rule        = coalesce(route.rule_override, join(" || ", concat(["Host(`${route.domain}`)"], [for alias in route.aliases : "Host(`${alias}`)"])))
            entryPoints = ["websecure"]
            tls = {
              certResolver = "letsencrypt"
            }
            middlewares = coalesce(route.middlewares, ["security-headers", "rate-limit", "request-size-limit"])
            service     = "${name}-service"
          }
          if coalesce(route.enable_tls, true)
        },
        # HTTP-to-HTTPS Redirection Routers (Port 80 -> 443 for enable_tls = true)
        {
          for name, route in var.proxy_routes : "${name}-redirect-router" => {
            rule        = coalesce(route.rule_override, join(" || ", concat(["Host(`${route.domain}`)"], [for alias in route.aliases : "Host(`${alias}`)"])))
            entryPoints = ["web"]
            middlewares = ["redirect-to-https"]
            service     = "${name}-service"
          }
          if coalesce(route.enable_tls, true)
        },
        # HTTP-Only Routers (Port 80 without TLS for enable_tls = false)
        {
          for name, route in var.proxy_routes : "${name}-router" => {
            rule        = coalesce(route.rule_override, join(" || ", concat(["Host(`${route.domain}`)"], [for alias in route.aliases : "Host(`${alias}`)"])))
            entryPoints = ["web"]
            middlewares = coalesce(route.middlewares, ["rate-limit"])
            service     = "${name}-service"
          }
          if !coalesce(route.enable_tls, true)
        }
      )
      middlewares = {
        redirect-to-https = {
          redirectScheme = {
            scheme    = "https"
            permanent = true
          }
        }
        security-headers = {
          headers = {
            browserXssFilter     = true
            contentTypeNosniff   = true
            frameDeny            = true
            sslRedirect          = false
            stsSeconds           = 31536000
            stsIncludeSubdomains = true
            stsPreload           = true
            referrerPolicy       = "strict-origin-when-cross-origin"
          }
        }
        rate-limit = {
          rateLimit = {
            average = 100
            burst   = 50
          }
        }
        request-size-limit = {
          buffering = {
            maxRequestBodyBytes = 26214400 # 25 MB max upload limit
            memRequestBodyBytes = 2097152  # 2 MB memory buffer before spilling to disk
          }
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

# 3. Dynamic GitOps Route Sync to Brainlab-Proxy via NetBird Mesh
resource "terraform_data" "sync_traefik_routes" {
  triggers_replace = [
    local.traefik_dynamic_routes_yaml,
    var.proxy_ip
  ]

  provisioner "local-exec" {
    command = <<EOT
cat << 'EOF' | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${var.proxy_netbird_host} "sudo tee /opt/brainlab/traefik/dynamic/routes.yaml > /dev/null"
${local.traefik_dynamic_routes_yaml}
EOF
EOT
  }
}

