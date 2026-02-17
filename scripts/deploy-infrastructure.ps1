# PowerShell script to deploy 5G Telco Cloud infrastructure
# This script automates the complete deployment process

param(
    [switch]$SkipPlan = $false,
    [switch]$AutoApprove = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "5G Telco Cloud Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
$terraformDir = "D:\wh15\terraform"
$ansibleDir = "D:\wh15\ansible"

# Check if Minikube is already running
Write-Host "Checking Minikube status..." -ForegroundColor Yellow
$minikubeStatus = minikube status 2>&1
if ($minikubeStatus -match "Running") {
    Write-Host "WARNING: Minikube is already running" -ForegroundColor Yellow
    $response = Read-Host "Do you want to delete and recreate? (y/n)"
    if ($response -eq 'y') {
        Write-Host "Deleting existing Minikube cluster..." -ForegroundColor Yellow
        minikube delete
    }
}
Write-Host ""

# Navigate to Terraform directory
Set-Location $terraformDir

# Initialize Terraform if not already done
if (-not (Test-Path ".terraform")) {
    Write-Host "Terraform not initialized. Running initialization..." -ForegroundColor Yellow
    terraform init
}

# Create or use existing plan
if (-not $SkipPlan) {
    Write-Host "Creating Terraform execution plan..." -ForegroundColor Yellow
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform plan failed" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

# Apply Terraform configuration
Write-Host "Applying Terraform configuration..." -ForegroundColor Yellow
if ($AutoApprove) {
    terraform apply -auto-approve tfplan
} else {
    terraform apply tfplan
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform apply failed" -ForegroundColor Red
    exit 1
}

Write-Host "Infrastructure deployment completed" -ForegroundColor Green
Write-Host ""

# Wait for cluster to be ready
Write-Host "Waiting for Kubernetes cluster to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Verify cluster is accessible
kubectl cluster-info
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Cannot access Kubernetes cluster" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Deploy 5G components using Ansible
Write-Host "Deploying 5G components using Ansible..." -ForegroundColor Yellow
Set-Location $ansibleDir

# Install required Ansible collections
Write-Host "Installing Ansible Kubernetes collection..." -ForegroundColor Yellow
ansible-galaxy collection install kubernetes.core

# Run Ansible playbook
ansible-playbook -i inventory.yml playbooks/deploy-5g-components.yml
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Ansible playbook execution failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Configure network policies
Write-Host "Applying network configuration..." -ForegroundColor Yellow
ansible-playbook -i inventory.yml playbooks/configure-5g-network.yml
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Network configuration failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Display deployment status
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nNamespaces:" -ForegroundColor Yellow
kubectl get namespaces

Write-Host "`nDeployments in telco5g namespace:" -ForegroundColor Yellow
kubectl get deployments -n telco5g

Write-Host "`nServices in telco5g namespace:" -ForegroundColor Yellow
kubectl get services -n telco5g

Write-Host "`nPods in telco5g namespace:" -ForegroundColor Yellow
kubectl get pods -n telco5g

Write-Host "`nNetworkPolicies in telco5g namespace:" -ForegroundColor Yellow
kubectl get networkpolicies -n telco5g

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To access services:" -ForegroundColor Yellow
Write-Host "  Grafana:    kubectl port-forward -n telco5g svc/grafana-service 3000:3000" -ForegroundColor White
Write-Host "  Prometheus: kubectl port-forward -n telco5g svc/prometheus-service 9090:9090" -ForegroundColor White
Write-Host ""
Write-Host "To view logs:" -ForegroundColor Yellow
Write-Host "  kubectl logs -n telco5g -l app=amf" -ForegroundColor White
Write-Host ""
Write-Host "To update Git repository:" -ForegroundColor Yellow
Write-Host "  cd D:\wh15" -ForegroundColor White
Write-Host "  git add ." -ForegroundColor White
Write-Host "  git commit -m 'Deployed 5G infrastructure'" -ForegroundColor White
Write-Host "  git push" -ForegroundColor White