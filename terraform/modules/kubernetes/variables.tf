# Input variables for Kubernetes module

variable "namespace" {
  description = "Kubernetes namespace for deployment"
  type        = string
}

variable "component_name" {
  description = "Name of the 5G component"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.component_name))
    error_message = "Component name must consist of lowercase alphanumeric characters or '-', and must start and end with an alphanumeric character."
  }
}

variable "image" {
  description = "Container image for the component"
  type        = string
}

variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 1
  
  validation {
    condition     = var.replicas >= 1 && var.replicas <= 10
    error_message = "Replicas must be between 1 and 10."
  }
}

variable "port" {
  description = "Service port number"
  type        = number
  
  validation {
    condition     = var.port > 0 && var.port < 65536
    error_message = "Port must be between 1 and 65535."
  }
}

variable "environment_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}