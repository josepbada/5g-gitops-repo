# Monitoring module for 5G Telco Cloud
# Deploys Prometheus and Grafana for infrastructure monitoring

variable "namespace" {
  description = "Namespace for monitoring components"
  type        = string
}

# Prometheus deployment
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = var.namespace
    
    labels = {
      app       = "prometheus"
      component = "monitoring"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app       = "prometheus"
          component = "monitoring"
        }
      }

      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.48.0"

          port {
            container_port = 9090
            name           = "web"
          }

          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "prometheus-config"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Prometheus Service
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-service"
    namespace = var.namespace
    
    labels = {
      app = "prometheus"
    }
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      name        = "web"
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
    }

    type = "NodePort"
  }
}

# Prometheus ConfigMap
resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = var.namespace
  }

  data = {
    "prometheus.yml" = <<-EOT
      global:
        scrape_interval: 15s
        evaluation_interval: 15s

      scrape_configs:
        - job_name: 'kubernetes-pods'
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names:
                  - ${var.namespace}
          
          relabel_configs:
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
              action: keep
              regex: true
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
              action: replace
              target_label: __metrics_path__
              regex: (.+)
            - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
              action: replace
              regex: ([^:]+)(?::\d+)?;(\d+)
              replacement: $1:$2
              target_label: __address__
    EOT
  }
}

# Grafana deployment
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
    
    labels = {
      app       = "grafana"
      component = "monitoring"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app       = "grafana"
          component = "monitoring"
        }
      }

      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:10.2.0"

          port {
            container_port = 3000
            name           = "web"
          }

          env {
            name  = "GF_SECURITY_ADMIN_PASSWORD"
            value = "admin"
          }

          env {
            name  = "GF_USERS_ALLOW_SIGN_UP"
            value = "false"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "300m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# Grafana Service
resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana-service"
    namespace = var.namespace
    
    labels = {
      app = "grafana"
    }
  }

  spec {
    selector = {
      app = "grafana"
    }

    port {
      name        = "web"
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }

    type = "NodePort"
  }
}

# Outputs
output "prometheus_service" {
  description = "Prometheus service endpoint"
  value       = "${kubernetes_service.prometheus.metadata[0].name}:${kubernetes_service.prometheus.spec[0].port[0].port}"
}

output "grafana_service" {
  description = "Grafana service endpoint"
  value       = "${kubernetes_service.grafana.metadata[0].name}:${kubernetes_service.grafana.spec[0].port[0].port}"
}

output "grafana_password" {
  description = "Default Grafana admin password"
  value       = "admin"
  sensitive   = true
}