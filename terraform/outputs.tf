# Outputs for 5G Telco Cloud Infrastructure
# These values will be displayed after Terraform apply

output "cluster_info" {
  description = "Information about the deployed Kubernetes cluster"
  value = {
    name      = var.cluster_name
    namespace = kubernetes_namespace.telco5g.metadata[0].name
    labels    = kubernetes_namespace.telco5g.metadata[0].labels
  }
}

output "next_steps" {
  description = "Next steps after cluster creation"
  value = <<-EOT
    Cluster '${var.cluster_name}' has been created successfully!
    
    Next steps:
    1. Verify cluster status: kubectl cluster-info
    2. Check namespace: kubectl get namespace ${kubernetes_namespace.telco5g.metadata[0].name}
    3. Deploy 5G components to namespace: ${kubernetes_namespace.telco5g.metadata[0].name}
  EOT
}