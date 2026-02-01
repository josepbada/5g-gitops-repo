# Deployment of 5G Core Network Functions using reusable modules
# This configuration deploys AMF, SMF, and UPF components

# Deploy AMF (Access and Mobility Management Function)
module "amf" {
  source = "./modules/kubernetes"

  namespace      = kubernetes_namespace.telco5g.metadata[0].name
  component_name = "amf"
  image          = "nginx:alpine"  # Using nginx as placeholder for demo
  replicas       = 2
  port           = 8080

  environment_vars = {
    COMPONENT_TYPE = "AMF"
    LOG_LEVEL      = "INFO"
    NRF_ENDPOINT   = "nrf-service.telco5g.svc.cluster.local:8081"
  }

  depends_on = [kubernetes_namespace.telco5g]
}

# Deploy SMF (Session Management Function)
module "smf" {
  source = "./modules/kubernetes"

  namespace      = kubernetes_namespace.telco5g.metadata[0].name
  component_name = "smf"
  image          = "nginx:alpine"  # Using nginx as placeholder for demo
  replicas       = 2
  port           = 8082

  environment_vars = {
    COMPONENT_TYPE = "SMF"
    LOG_LEVEL      = "INFO"
    UPF_ENDPOINT   = module.upf.service_endpoint
    NRF_ENDPOINT   = "nrf-service.telco5g.svc.cluster.local:8081"
  }

  depends_on = [module.upf]
}

# Deploy UPF (User Plane Function)
module "upf" {
  source = "./modules/kubernetes"

  namespace      = kubernetes_namespace.telco5g.metadata[0].name
  component_name = "upf"
  image          = "nginx:alpine"  # Using nginx as placeholder for demo
  replicas       = 3
  port           = 8083

  environment_vars = {
    COMPONENT_TYPE = "UPF"
    LOG_LEVEL      = "INFO"
    DATA_NETWORK   = "internet"
  }

  depends_on = [kubernetes_namespace.telco5g]
}

# Deploy NRF (Network Repository Function)
module "nrf" {
  source = "./modules/kubernetes"

  namespace      = kubernetes_namespace.telco5g.metadata[0].name
  component_name = "nrf"
  image          = "nginx:alpine"  # Using nginx as placeholder for demo
  replicas       = 2
  port           = 8081

  environment_vars = {
    COMPONENT_TYPE = "NRF"
    LOG_LEVEL      = "INFO"
  }

  depends_on = [kubernetes_namespace.telco5g]
}

# Deploy Monitoring Stack
module "monitoring" {
  source = "./modules/monitoring"

  namespace = kubernetes_namespace.telco5g.metadata[0].name

  depends_on = [kubernetes_namespace.telco5g]
}

# Outputs for 5G components
output "amf_endpoint" {
  description = "AMF service endpoint"
  value       = module.amf.service_endpoint
}

output "smf_endpoint" {
  description = "SMF service endpoint"
  value       = module.smf.service_endpoint
}

output "upf_endpoint" {
  description = "UPF service endpoint"
  value       = module.upf.service_endpoint
}

output "nrf_endpoint" {
  description = "NRF service endpoint"
  value       = module.nrf.service_endpoint
}

output "monitoring_endpoints" {
  description = "Monitoring service endpoints"
  value = {
    prometheus = module.monitoring.prometheus_service
    grafana    = module.monitoring.grafana_service
  }
}

output "deployment_summary" {
  description = "Summary of all deployed components"
  value = <<-EOT
    ========================================
    5G Telco Cloud Deployment Summary
    ========================================
    Namespace: ${kubernetes_namespace.telco5g.metadata[0].name}
    
    Control Plane Components:
    - AMF: ${module.amf.service_endpoint} (${module.amf.deployment_name})
    - SMF: ${module.smf.service_endpoint} (${module.smf.deployment_name})
    - NRF: ${module.nrf.service_endpoint} (${module.nrf.deployment_name})
    
    User Plane Components:
    - UPF: ${module.upf.service_endpoint} (${module.upf.deployment_name})
    
    Monitoring:
    - Prometheus: ${module.monitoring.prometheus_service}
    - Grafana: ${module.monitoring.grafana_service}
    
    To access services:
    kubectl port-forward -n ${kubernetes_namespace.telco5g.metadata[0].name} svc/grafana-service 3000:3000
    kubectl port-forward -n ${kubernetes_namespace.telco5g.metadata[0].name} svc/prometheus-service 9090:9090
    ========================================
  EOT
}