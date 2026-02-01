# Output values from Kubernetes module

output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = kubernetes_deployment.component.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service"
  value       = kubernetes_service.component.metadata[0].name
}

output "service_endpoint" {
  description = "Full DNS endpoint for the service within the cluster"
  value       = "${kubernetes_service.component.metadata[0].name}.${var.namespace}.svc.cluster.local:${var.port}"
}

output "config_map_name" {
  description = "Name of the ConfigMap"
  value       = kubernetes_config_map.component_config.metadata[0].name
}