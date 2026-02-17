# 5G Telco Cloud Infrastructure as Code

This repository contains Infrastructure as Code (IaC) configurations for deploying and managing a 5G Telco Cloud environment using Terraform and Ansible.

## Overview

This project automates the deployment of a complete 5G core network infrastructure including:
- AMF (Access and Mobility Management Function)
- SMF (Session Management Function)
- UPF (User Plane Function)
- NRF (Network Repository Function)
- Monitoring stack (Prometheus and Grafana)

## Architecture

The infrastructure is deployed on a Kubernetes cluster running on Minikube with Docker driver. All 5G components are containerized and orchestrated using Kubernetes.

### Components

- **Control Plane**: AMF, SMF, NRF
- **User Plane**: UPF
- **Monitoring**: Prometheus, Grafana
- **Namespace**: telco5g

## Prerequisites

Before using this repository, ensure you have the following installed:

1. **Docker Desktop** (running)
2. **Minikube** (v1.32.0 or later)
3. **Terraform** (v1.7.0 or later)
4. **Ansible** (v2.15.0 or later)
5. **kubectl** (v1.28.0 or later)
6. **Git** (for version control)

## Directory Structure
```
D:\wh15\
├── terraform/              # Terraform configurations
│   ├── modules/           # Reusable Terraform modules
│   │   ├── kubernetes/    # Kubernetes deployment module
│   │   └── monitoring/    # Monitoring stack module
│   ├── main.tf            # Main Terraform configuration
│   ├── outputs.tf         # Output definitions
│   ├── terraform.tfvars   # Variable values
│   └── 5g-components.tf   # 5G components deployment
├── ansible/               # Ansible configurations
│   ├── playbooks/        # Ansible playbooks
│   │   ├── deploy-5g-components.yml
│   │   └── configure-5g-network.yml
│   ├── roles/            # Ansible roles (future use)
│   ├── inventory.yml     # Ansible inventory
│   └── ansible.cfg       # Ansible configuration
├── k8s-manifests/        # Kubernetes YAML manifests
├── scripts/              # Automation scripts
│   ├── init-terraform.ps1
│   ├── deploy-infrastructure.ps1
│   ├── validate-deployment.ps1
│   └── upgrade-cluster.ps1
└── backups/              # Backup directory (git-ignored)
```

## Quick Start

### 1. Initialize Infrastructure
```powershell
# Initialize Terraform
.\scripts\init-terraform.ps1
```

This script will:
- Verify Terraform and Docker installations
- Initialize Terraform providers
- Validate configurations
- Create an execution plan

### 2. Deploy Infrastructure
```powershell
# Deploy complete infrastructure
.\scripts\deploy-infrastructure.ps1
```

This script will:
- Create Minikube cluster with Kubernetes
- Deploy 5G core network functions
- Apply network policies
- Deploy monitoring stack

### 3. Validate Deployment
```powershell
# Run validation tests
.\scripts\validate-deployment.ps1
```

This script performs automated checks on:
- Namespace existence
- Deployment readiness
- Service availability
- Network policy configuration
- Resource quotas and limits

### 4. Access Services

Once deployed, you can access services using port-forwarding:
```powershell
# Access Grafana
kubectl port-forward -n telco5g svc/grafana-service 3000:3000

# Access Prometheus
kubectl port-forward -n telco5g svc/prometheus-service 9090:9090
```

Then open your browser:
- Grafana: http://localhost:3000 (username: admin, password: admin)
- Prometheus: http://localhost:9090

## Usage

### Deploying Individual Components

You can deploy individual 5G components using Terraform modules:
```hcl
module "custom_component" {
  source = "./modules/kubernetes"
  
  namespace      = "telco5g"
  component_name = "my-component"
  image          = "my-image:tag"
  replicas       = 2
  port           = 8080
}
```

### Running Ansible Playbooks

Deploy components using Ansible:
```powershell
cd D:\wh15\ansible
ansible-playbook -i inventory.yml playbooks/deploy-5g-components.yml
```

Configure network policies:
```powershell
ansible-playbook -i inventory.yml playbooks/configure-5g-network.yml
```

### Upgrading the Cluster

To upgrade Kubernetes version:
```powershell
.\scripts\upgrade-cluster.ps1 -TargetK8sVersion "v1.29.0"
```

## Configuration

### Terraform Variables

Edit `terraform/terraform.tfvars` to customize:
```hcl
cluster_name = "5g-telco-cluster"
namespace    = "telco5g"
cpus         = 2
memory       = 4096
```

### Ansible Variables

Edit `ansible/inventory.yml` to customize:
```yaml
all:
  vars:
    kubernetes_namespace: telco5g
    cluster_name: 5g-telco-cluster
```

## Monitoring

### Prometheus

Prometheus collects metrics from all 5G components. Access the Prometheus UI at http://localhost:9090 after port-forwarding.

Useful queries:
- `up{namespace="telco5g"}` - Check which components are up
- `container_memory_usage_bytes{namespace="telco5g"}` - Memory usage by component

### Grafana

Grafana provides visualization dashboards. Default credentials:
- Username: admin
- Password: admin

## Troubleshooting

### Common Issues

**Issue**: Minikube fails to start
```powershell
# Solution: Delete and recreate cluster
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096 --kubernetes-version=v1.28.0 --cni=calico
```

**Issue**: Pods are not starting
```powershell
# Check pod status
kubectl get pods -n telco5g

# View pod logs
kubectl logs -n telco5g <pod-name>

# Describe pod for events
kubectl describe pod -n telco5g <pod-name>
```

**Issue**: NetworkPolicies not working
```powershell
# Verify Calico is installed
kubectl get pods -n kube-system | grep calico

# Check NetworkPolicy status
kubectl get networkpolicies -n telco5g
kubectl describe networkpolicy <policy-name> -n telco5g
```

### Viewing Logs
```powershell
# View logs for specific component
kubectl logs -n telco5g -l app=amf

# Follow logs in real-time
kubectl logs -n telco5g -l app=amf -f

# View logs from all containers in a pod
kubectl logs -n telco5g <pod-name> --all-containers
```

## Cleanup

To remove all deployed resources:
```powershell
# Using Terraform
cd D:\wh15\terraform
terraform destroy

# Manually delete Minikube cluster
minikube delete
```

## Contributing

1. Create a new branch for your changes
2. Make your modifications
3. Test thoroughly using validation script
4. Commit with descriptive messages
5. Push to GitHub

## License

This project is for educational purposes.

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [5G Architecture Overview](https://www.3gpp.org)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs)

## Version History

- v1.0.0 - Initial release with Terraform and Ansible automation
  - Automated cluster deployment
  - 5G core network functions (AMF, SMF, UPF, NRF)
  - Monitoring stack (Prometheus, Grafana)
  - Network policies and resource quotas
  - Automated validation and testing