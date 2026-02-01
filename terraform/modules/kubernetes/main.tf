# Kubernetes module for deploying 5G Core Network Functions
# This module creates deployments and services for 5G components

variable "namespace" {
  description = "Namespace where 5G components will be deployed"
  type        = string
}

variable "component_name" {
  description = "Name of the 5G component (e.g., amf, smf, upf)"
  type        = string
}

variable "image" {
  description = "Container image for the 5G component"
  type        = string
}

variable "replicas" {
  description = "Number of replicas for the deployment"
  type        = number
  default     = 1
}

variable "port" {
  description = "Port number for the service"
  type        = number
}

variable "environment_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

# Deployment for 5G component
resource "kubernetes_deployment" "component" {
  metadata {
    name      = var.component_name
    namespace = var.namespace
    
    labels = {
      app       = var.component_name
      component = "5g-core"
      tier      = "control-plane"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.component_name
      }
    }

    template {
      metadata {
        labels = {
          app       = var.component_name
          component = "5g-core"
          tier      = "control-plane"
        }
      }

      spec {
        container {
          name  = var.component_name
          image = var.image

          port {
            container_port = var.port
            name           = "service-port"
          }

          dynamic "env" {
            for_each = var.environment_vars
            content {
              name  = env.key
              value = env.value
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = var.port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = var.port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Service for 5G component
resource "kubernetes_service" "component" {
  metadata {
    name      = "${var.component_name}-service"
    namespace = var.namespace
    
    labels = {
      app       = var.component_name
      component = "5g-core"
    }
  }

  spec {
    selector = {
      app = var.component_name
    }

    port {
      name        = "service-port"
      port        = var.port
      target_port = var.port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# ConfigMap for component configuration
resource "kubernetes_config_map" "component_config" {
  metadata {
    name      = "${var.component_name}-config"
    namespace = var.namespace
  }

  data = {
    "component.conf" = <<-EOT
      # Configuration for ${var.component_name}
      component_name: ${var.component_name}
      service_port: ${var.port}
      log_level: INFO
    EOT
  }
}

# Outputs
output "deployment_name" {
  description = "Name of the created deployment"
  value       = kubernetes_deployment.component.metadata[0].name
}

output "service_name" {
  description = "Name of the created service"
  value       = kubernetes_service.component.metadata[0].name
}

output "service_endpoint" {
  description = "Internal endpoint for the service"
  value       = "${kubernetes_service.component.metadata[0].name}.${var.namespace}.svc.cluster.local:${var.port}"
}