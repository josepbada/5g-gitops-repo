# Main Terraform configuration for 5G Telco Cloud Infrastructure
# This file orchestrates the deployment of Kubernetes cluster and 5G components

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

# Provider configuration for Docker
provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

# Variables that can be customized
variable "cluster_name" {
  description = "Name of the Kubernetes cluster for 5G Telco Cloud"
  type        = string
  default     = "5g-telco-cluster"
}

variable "namespace" {
  description = "Namespace for 5G components"
  type        = string
  default     = "telco5g"
}

variable "cpus" {
  description = "Number of CPUs for Minikube"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory allocation for Minikube in MB"
  type        = number
  default     = 4096
}


# resource "null_resource" "minikube_cluster" {
#   provisioner "local-exec" {
#     command = "minikube start --driver=docker --cpus=${var.cpus} --memory=${var.memory} --kubernetes-version=v1.28.0 --cni=calico; Start-Sleep -Seconds 20; kubectl cluster-info"
#    interpreter = ["PowerShell", "-Command"]
#   }


#   provisioner "local-exec" {
#     when        = destroy
#     command     = "minikube delete"
#     interpreter = ["PowerShell", "-Command"]
#   }
# }

# Configure Kubernetes provider to use Minikube
provider "kubernetes" {
  config_path    = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
  }
}

# Create namespace for 5G components
resource "kubernetes_namespace" "telco5g" {
  metadata {
    name = var.namespace

    labels = {
      name        = var.namespace
      environment = "development"
      purpose     = "5g-telco-cloud"
    }
  }


}

# Output values that can be used by other configurations
output "cluster_name" {
  description = "Name of the created Kubernetes cluster"
  value       = var.cluster_name
}

output "namespace" {
  description = "Namespace created for 5G components"
  value       = kubernetes_namespace.telco5g.metadata[0].name
}
