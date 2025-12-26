# Complete Command Reference - Week 9 Project

This document provides a categorized reference of all commands used during the Cloud-Native 5G Core weekend project.

---

## PowerShell Commands (Windows)

### Directory and File Management
```powershell
# Create project directory structure
cd D:\
New-Item -Path "week9-cnf-architecture" -ItemType Directory -Force
cd week9-cnf-architecture
New-Item -Path "documentation" -ItemType Directory -Force
New-Item -Path "diagrams" -ItemType Directory -Force
New-Item -Path "kubernetes-manifests" -ItemType Directory -Force
New-Item -Path "configs" -ItemType Directory -Force

# Create subdirectories for manifests
cd kubernetes-manifests
New-Item -Path "configmaps" -ItemType Directory -Force
New-Item -Path "deployments" -ItemType Directory -Force
New-Item -Path "statefulsets" -ItemType Directory -Force
New-Item -Path "services" -ItemType Directory -Force
New-Item -Path "storage" -ItemType Directory -Force
New-Item -Path "secrets" -ItemType Directory -Force

# List directory contents
Get-ChildItem -Directory

# Open files in Notepad++
notepad++ filename.yaml
```

### PowerShell Variables and Scripting
```powershell
# Store pod name in variable
$podName = (kubectl get pods -l app=amf -o jsonpath='{.items[0].metadata.name}')

# Display variable
Write-Host "Pod name: $podName" -ForegroundColor Yellow

# Measure time
$startTime = Get-Date
# ... do something ...
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds
Write-Host "Duration: $duration seconds" -ForegroundColor Green

# Create multi-line string (here-string)
$config = @'
Line 1
Line 2
'@

# Pipe string to kubectl
$config | kubectl apply -f -
```

---

## Git Commands

### Initial Setup
```powershell
# Initialize repository
git init

# Configure user
git config user.name "Josep Bada"
git config user.email "josepbada@example.com"

# Add remote repository
git remote add origin https://github.com/josepbada/5g-gitops-repo.git
```

### Daily Workflow
```powershell
# Check status
git status

# Add files
git add .
git add documentation\filename.md
git add kubernetes-manifests\deployments\amf-deployment.yaml

# Commit with message
git commit -m "Week 9: Description of changes"

# Push to remote
git push origin main
git push -u origin main  # First push, sets upstream

# Pull latest changes
git pull origin main

# View commit history
git log --oneline
```

### Create .gitignore
```powershell
# Create .gitignore file
@"
# Kubernetes secrets
*-secret.yaml
*.key
*.crt

# Temporary files
*.tmp
*.log
*.swp

# OS files
.DS_Store
Thumbs.db
"@ | Out-File -FilePath .gitignore -Encoding UTF8
```

---

## Docker Commands

### Docker Verification
```powershell
# Check Docker status
docker info

# List running containers
docker ps

# List all containers
docker ps -a

# List images
docker images

# Docker system information
docker system df

# Clean up (WARNING: removes everything)
docker system prune -a --volumes
```

---

## Kubernetes - Cluster Management

### Cluster Information
```powershell
# Get cluster info
kubectl cluster-info

# Get cluster nodes
kubectl get nodes
kubectl get nodes -o wide

# Describe node
kubectl describe node docker-desktop

# Get Kubernetes version
kubectl version --short
```

### Context and Namespace Management
```powershell
# View current context
kubectl config current-context

# View all contexts
kubectl config get-contexts

# Set default namespace
kubectl config set-context --current --namespace=open5gs-core

# View current namespace
kubectl config view --minify | Select-String "namespace"

# Reset to default namespace
kubectl config set-context --current --namespace=default
```

---

## Kubernetes - Namespace Operations

### Create and Manage Namespaces
```powershell
# Create namespace
kubectl create namespace open5gs-core

# List all namespaces
kubectl get namespaces
kubectl get ns

# Describe namespace
kubectl describe namespace open5gs-core

# Delete namespace (WARNING: deletes all resources inside)
kubectl delete namespace open5gs-core
```

---

## Kubernetes - Pod Operations

### Viewing Pods
```powershell
# Get all pods in namespace
kubectl get pods -n open5gs-core

# Get pods with more details
kubectl get pods -n open5gs-core -o wide

# Watch pods in real-time
kubectl get pods -n open5gs-core --watch

# Get pods with labels
kubectl get pods -l app=amf -n open5gs-core

# Get pod details in YAML
kubectl get pod <pod-name> -n open5gs-core -o yaml

# Get pod details in JSON
kubectl get pod <pod-name> -n open5gs-core -o json
```

### Describing and Logging
```powershell
# Describe pod (detailed info and events)
kubectl describe pod <pod-name> -n open5gs-core

# Get pod logs
kubectl logs <pod-name> -n open5gs-core

# Get last N lines of logs
kubectl logs <pod-name> -n open5gs-core --tail=20

# Follow logs (real-time)
kubectl logs <pod-name> -n open5gs-core -f

# Get logs for all pods with label
kubectl logs -l app=amf -n open5gs-core --tail=30

# Get previous container logs (if pod restarted)
kubectl logs <pod-name> -n open5gs-core --previous
```

### Executing Commands in Pods
```powershell
# Execute command in pod
kubectl exec <pod-name> -n open5gs-core -- <command>

# Interactive shell in pod
kubectl exec -it <pod-name> -n open5gs-core -- /bin/sh
kubectl exec -it <pod-name> -n open5gs-core -- /bin/bash

# Examples:
kubectl exec <pod-name> -n open5gs-core -- nslookup mongodb.open5gs-core.svc.cluster.local
kubectl exec <pod-name> -n open5gs-core -- nc -zv localhost 7777
kubectl exec <pod-name> -n open5gs-core -- ps aux
kubectl exec <pod-name> -n open5gs-core -- pkill -9 open5gs-nrfd
```

### Pod Lifecycle Management
```powershell
# Delete pod
kubectl delete pod <pod-name> -n open5gs-core

# Force delete pod
kubectl delete pod <pod-name> -n open5gs-core --force --grace-period=0

# Delete all pods with label
kubectl delete pods -l app=amf -n open5gs-core

# Delete all pods in namespace
kubectl delete pods --all -n open5gs-core
```

### Creating Temporary Test Pods
```powershell
# Create temporary busybox pod
kubectl run test-pod --image=busybox:1.35 --restart=Never --rm -it -n open5gs-core -- sh

# Run command and auto-delete
kubectl run test-client --image=busybox:1.35 --restart=Never --rm -it -n open5gs-core -- nslookup upf-0.upf-headless.open5gs-core.svc.cluster.local
```

---

## Kubernetes - Deployment Operations

### Viewing Deployments
```powershell
# Get all deployments
kubectl get deployments -n open5gs-core
kubectl get deploy -n open5gs-core

# Get deployment details
kubectl get deployment <deployment-name> -n open5gs-core -o yaml

# Describe deployment
kubectl describe deployment <deployment-name> -n open5gs-core
```

### Managing Deployments
```powershell
# Create deployment from YAML
kubectl apply -f deployments\nrf-deployment.yaml

# Delete deployment
kubectl delete deployment <deployment-name> -n open5gs-core

# Scale deployment
kubectl scale deployment <deployment-name> --replicas=3 -n open5gs-core

# Rollout restart (zero-downtime restart)
kubectl rollout restart deployment/<deployment-name> -n open5gs-core

# Check rollout status
kubectl rollout status deployment/<deployment-name> -n open5gs-core

# View rollout history
kubectl rollout history deployment/<deployment-name> -n open5gs-core

# Rollback to previous version
kubectl rollout undo deployment/<deployment-name> -n open5gs-core
```

---

## Kubernetes - StatefulSet Operations

### Viewing StatefulSets
```powershell
# Get all statefulsets
kubectl get statefulsets -n open5gs-core
kubectl get sts -n open5gs-core

# Get statefulset details
kubectl get statefulset <sts-name> -n open5gs-core -o yaml

# Describe statefulset
kubectl describe statefulset <sts-name> -n open5gs-core
```

### Managing StatefulSets
```powershell
# Create statefulset from YAML
kubectl apply -f statefulsets\mongodb-statefulset.yaml

# Delete statefulset
kubectl delete statefulset <sts-name> -n open5gs-core

# Scale statefulset
kubectl scale statefulset <sts-name> --replicas=3 -n open5gs-core

# Note: StatefulSet pods are created/deleted in order (0, 1, 2...)
```

---

## Kubernetes - Service Operations

### Viewing Services
```powershell
# Get all services
kubectl get services -n open5gs-core
kubectl get svc -n open5gs-core

# Get service details
kubectl get service <service-name> -n open5gs-core -o yaml

# Describe service
kubectl describe service <service-name> -n open5gs-core

# Get service endpoints
kubectl get endpoints <service-name> -n open5gs-core
kubectl get ep -n open5gs-core
```

### Managing Services
```powershell
# Create service from YAML
kubectl apply -f services\amf-service.yaml

# Delete service
kubectl delete service <service-name> -n open5gs-core

# Services are typically created inline with Deployments/StatefulSets
```

---

## Kubernetes - ConfigMap Operations

### Viewing ConfigMaps
```powershell
# Get all configmaps
kubectl get configmaps -n open5gs-core
kubectl get cm -n open5gs-core

# Get configmap contents
kubectl get configmap <cm-name> -n open5gs-core -o yaml

# Describe configmap
kubectl describe configmap <cm-name> -n open5gs-core

# View specific key in configmap
kubectl get configmap <cm-name> -n open5gs-core -o jsonpath='{.data.nrf\.yaml}'
```

### Managing ConfigMaps
```powershell
# Create configmap from YAML
kubectl apply -f configmaps\nrf-config.yaml

# Create configmap from file
kubectl create configmap <cm-name> --from-file=config.yaml -n open5gs-core

# Delete configmap
kubectl delete configmap <cm-name> -n open5gs-core

# Update configmap (edit in-place)
kubectl edit configmap <cm-name> -n open5gs-core

# After updating ConfigMap, restart pods to pick up changes
kubectl rollout restart deployment/<deployment-name> -n open5gs-core
```

---

## Kubernetes - PersistentVolume Operations

### Viewing Storage Resources
```powershell
# Get all PersistentVolumeClaims
kubectl get pvc -n open5gs-core

# Get PVC details
kubectl get pvc <pvc-name> -n open5gs-core -o yaml

# Describe PVC
kubectl describe pvc <pvc-name> -n open5gs-core

# Get all PersistentVolumes (cluster-wide)
kubectl get pv

# Describe PV
kubectl describe pv <pv-name>
```

### Managing PVCs
```powershell
# Delete PVC (WARNING: deletes data)
kubectl delete pvc <pvc-name> -n open5gs-core

# Delete all PVCs in namespace
kubectl delete pvc --all -n open5gs-core

# Note: PVCs created by StatefulSet volumeClaimTemplates
# are NOT automatically deleted when StatefulSet is deleted
```

---

## Kubernetes - Resource Analysis

### Resource Monitoring
```powershell
# Get resource usage (requires metrics-server)
kubectl top nodes
kubectl top pods -n open5gs-core

# Get resource requests and limits
kubectl get pods -n open5gs-core -o custom-columns=NAME:.metadata.name,MEMORY_REQUEST:.spec.containers[0].resources.requests.memory,MEMORY_LIMIT:.spec.containers[0].resources.limits.memory,CPU_REQUEST:.spec.containers[0].resources.requests.cpu,CPU_LIMIT:.spec.containers[0].resources.limits.cpu

# Get all resources in namespace
kubectl get all -n open5gs-core

# Get API resources
kubectl api-resources
```

### Event Monitoring
```powershell
# Get events in namespace
kubectl get events -n open5gs-core

# Get events sorted by time
kubectl get events -n open5gs-core --sort-by='.lastTimestamp'

# Get events for specific pod
kubectl get events --field-selector involvedObject.name=<pod-name> -n open5gs-core

# Watch events in real-time
kubectl get events -n open5gs-core --watch
```

---

## Kubernetes - Wait and Watch Operations

### Waiting for Resources
```powershell
# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=amf -n open5gs-core --timeout=120s

# Wait for deployment to be ready
kubectl wait --for=condition=available deployment/<deployment-name> -n open5gs-core --timeout=120s

# Wait for specific pod
kubectl wait --for=condition=ready pod/<pod-name> -n open5gs-core --timeout=60s
```

### Watching Resources
```powershell
# Watch pods
kubectl get pods -n open5gs-core --watch

# Watch all resources
kubectl get all -n open5gs-core --watch

# Press Ctrl+C to stop watching
```

---

## Kubernetes - Advanced Operations

### JSONPath Queries
```powershell
# Get pod name
kubectl get pods -l app=amf -o jsonpath='{.items[0].metadata.name}'

# Get pod IP
kubectl get pods -l app=amf -o jsonpath='{.items[0].status.podIP}'

# Get container image
kubectl get pods -l app=amf -o jsonpath='{.items[0].spec.containers[0].image}'

# Get restart count
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].restartCount}'

# Get all pod IPs
kubectl get pods -n open5gs-core -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'
```

### Labels and Selectors
```powershell
# Get pods with specific label
kubectl get pods -l app=amf -n open5gs-core

# Get pods with multiple labels
kubectl get pods -l app=amf,version=v1 -n open5gs-core

# Add label to pod
kubectl label pod <pod-name> environment=test -n open5gs-core

# Remove label from pod
kubectl label pod <pod-name> environment- -n open5gs-core

# Show labels
kubectl get pods --show-labels -n open5gs-core
```

### Patching Resources
```powershell
# Patch deployment (add/change fields)
kubectl patch deployment <deployment-name> -n open5gs-core -p '{"spec":{"replicas":3}}'

# Patch pod to remove finalizers (advanced troubleshooting)
kubectl patch pod <pod-name> -n open5gs-core -p '{"metadata":{"finalizers":null}}'

# Patch PVC to remove finalizers
kubectl patch pvc <pvc-name> -n open5gs-core -p '{"metadata":{"finalizers":null}}'
```

---

## Testing and Debugging Commands

### Network Testing from Pods
```powershell
# DNS lookup
kubectl exec <pod-name> -n open5gs-core -- nslookup mongodb.open5gs-core.svc.cluster.local

# Port connectivity test
kubectl exec <pod-name> -n open5gs-core -- nc -zv <service-name> <port>

# Ping test
kubectl exec <pod-name> -n open5gs-core -- ping -c 4 <service-name>
Curl test
kubectl exec <pod-name> -n open5gs-core -- curl http://<service-name>:<port>
### Health Check Testing
```powershell
# Test liveness probe manually
kubectl exec <pod-name> -n open5gs-core -- nc -zv localhost 7777

# Kill process to test liveness probe
kubectl exec <pod-name> -n open5gs-core -- pkill -9 open5gs-nrfd

# Watch pod restart after liveness failure
kubectl get pod <pod-name> -n open5gs-core --watch
```

### Resource Analysis Script
```powershell
# Run custom resource analysis
.\analyze-resources.ps1

# The script provides:
# - Per-component resource allocation
# - Total resource usage
# - Utilization percentages
# - Safety assessment
```

---

## Cleanup Commands

### Quick Cleanup (Delete Namespace)
```powershell
# Delete entire namespace (fastest method)
kubectl delete namespace open5gs-core

# Reset kubectl context
kubectl config set-context --current --namespace=default
```

### Selective Cleanup (Step-by-Step)
```powershell
# Delete Deployments
kubectl delete deployment nrf amf smf -n open5gs-core

# Delete StatefulSets
kubectl delete statefulset mongodb upf -n open5gs-core

# Delete Services
kubectl delete service mongodb nrf amf smf upf upf-headless -n open5gs-core

# Delete ConfigMaps
kubectl delete configmap nrf-config amf-config smf-config upf-config -n open5gs-core

# Delete PVCs
kubectl delete pvc mongodb-data-mongodb-0 upf-data-upf-0 -n open5gs-core

# Delete namespace
kubectl delete namespace open5gs-core
```

### Force Delete (Troubleshooting)
```powershell
# Force delete namespace
kubectl delete namespace open5gs-core --force --grace-period=0

# Force delete pod
kubectl delete pod <pod-name> -n open5gs-core --force --grace-period=0

# Force delete PVC
kubectl delete pvc <pvc-name> -n open5gs-core --force --grace-period=0
```

---

## Quick Reference by Task

### Deploy Complete 5G Core
```powershell
# Create namespace
kubectl create namespace open5gs-core
kubectl config set-context --current --namespace=open5gs-core

# Deploy in order
kubectl apply -f kubernetes-manifests/statefulsets/mongodb-statefulset.yaml
kubectl apply -f kubernetes-manifests/configmaps/nrf-config.yaml
kubectl apply -f kubernetes-manifests/deployments/nrf-deployment.yaml
kubectl apply -f kubernetes-manifests/configmaps/amf-config.yaml
kubectl apply -f kubernetes-manifests/deployments/amf-deployment.yaml
kubectl apply -f kubernetes-manifests/configmaps/smf-config.yaml
kubectl apply -f kubernetes-manifests/deployments/smf-deployment.yaml
kubectl apply -f kubernetes-manifests/configmaps/upf-config.yaml
kubectl apply -f kubernetes-manifests/statefulsets/upf-statefulset.yaml

# Verify deployment
kubectl get pods -n open5gs-core
kubectl get svc -n open5gs-core
kubectl get pvc -n open5gs-core
```

### Check System Health
```powershell
# Quick health check
kubectl get pods -n open5gs-core
kubectl get all -n open5gs-core

# Detailed health check
kubectl describe pods -n open5gs-core
kubectl get events -n open5gs-core --sort-by='.lastTimestamp'
kubectl logs -l app=nrf -n open5gs-core --tail=20

# Resource usage
.\analyze-resources.ps1
```

### Test High Availability
```powershell
# Delete one AMF pod to test recovery
$amfPod = (kubectl get pods -l app=amf -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $amfPod -n open5gs-core

# Watch recovery
kubectl get pods -l app=amf -n open5gs-core --watch

# Verify service continued
kubectl get endpoints amf -n open5gs-core
```

---

## Summary

This command reference covers:
- **PowerShell:** File management, scripting, variables
- **Git:** Version control and repository management  
- **Docker:** Container and image management
- **Kubernetes:** Complete cluster, pod, deployment, service, and storage operations
- **Testing:** Network connectivity, health checks, debugging
- **Cleanup:** Multiple methods for resource removal

All commands are organized by category and include practical examples from the Week 9 project.