# PowerShell script to automate Kubernetes cluster upgrades
# This script handles upgrading Minikube and Kubernetes versions

param(
    [string]$TargetK8sVersion = "v1.29.0",
    [switch]$BackupFirst = $true
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kubernetes Cluster Upgrade Automation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "telco5g"
$backupDir = "D:\wh15\backups"

# Create backup directory if it doesn't exist
if (-not (Test-Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory | Out-Null
}

# Step 1: Pre-upgrade backup
if ($BackupFirst) {
    Write-Host "Step 1: Creating pre-upgrade backup..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$backupDir\pre-upgrade-$timestamp"
    New-Item -Path $backupPath -ItemType Directory | Out-Null
    
    # Backup all resources in the namespace
    Write-Host "  Backing up deployments..." -ForegroundColor White
    kubectl get deployments -n $namespace -o yaml > "$backupPath\deployments.yaml"
    
    Write-Host "  Backing up services..." -ForegroundColor White
    kubectl get services -n $namespace -o yaml > "$backupPath\services.yaml"
    
    Write-Host "  Backing up configmaps..." -ForegroundColor White
    kubectl get configmaps -n $namespace -o yaml > "$backupPath\configmaps.yaml"
    
    Write-Host "  Backing up networkpolicies..." -ForegroundColor White
    kubectl get networkpolicies -n $namespace -o yaml > "$backupPath\networkpolicies.yaml"
    
    Write-Host "  Backup completed: $backupPath" -ForegroundColor Green
    Write-Host ""
}

# Step 2: Check current version
Write-Host "Step 2: Checking current Kubernetes version..." -ForegroundColor Yellow
$currentVersion = kubectl version --short 2>&1 | Select-String "Server Version"
Write-Host "  Current version: $currentVersion" -ForegroundColor White
Write-Host "  Target version: $TargetK8sVersion" -ForegroundColor White
Write-Host ""

# Step 3: Verify cluster health before upgrade
Write-Host "Step 3: Verifying cluster health..." -ForegroundColor Yellow
$unhealthyPods = kubectl get pods -n $namespace --field-selector=status.phase!=Running -o json | ConvertFrom-Json
if ($unhealthyPods.items.Count -gt 0) {
    Write-Host "  WARNING: Found unhealthy pods before upgrade" -ForegroundColor Yellow
    Write-Host "  Unhealthy pods:" -ForegroundColor Yellow
    foreach ($pod in $unhealthyPods.items) {
        Write-Host "    - $($pod.metadata.name): $($pod.status.phase)" -ForegroundColor Yellow
    }
    
    $continue = Read-Host "  Continue with upgrade? (y/n)"
    if ($continue -ne 'y') {
        Write-Host "Upgrade cancelled" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  All pods are healthy" -ForegroundColor Green
}
Write-Host ""

# Step 4: Scale down deployments for upgrade
Write-Host "Step 4: Scaling down deployments..." -ForegroundColor Yellow
$deployments = kubectl get deployments -n $namespace -o jsonpath='{.items[*].metadata.name}'
foreach ($dep in $deployments -split ' ') {
    if ($dep) {
        Write-Host "  Scaling down $dep..." -ForegroundColor White
        kubectl scale deployment $dep -n $namespace --replicas=0
    }
}
Write-Host "  Deployments scaled down" -ForegroundColor Green
Write-Host ""

# Step 5: Perform cluster upgrade
Write-Host "Step 5: Upgrading Kubernetes cluster..." -ForegroundColor Yellow
Write-Host "  Stopping current Minikube cluster..." -ForegroundColor White
minikube stop

Write-Host "  Starting Minikube with new Kubernetes version..." -ForegroundColor White
minikube start --driver=docker --kubernetes-version=$TargetK8sVersion --cni=calico

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Cluster upgrade failed" -ForegroundColor Red
    Write-Host "  Attempting to restore previous version..." -ForegroundColor Yellow
    minikube delete
    minikube start --driver=docker --kubernetes-version=v1.28.0 --cni=calico
    exit 1
}
Write-Host "  Cluster upgraded successfully" -ForegroundColor Green
Write-Host ""

# Step 6: Wait for cluster to be ready
Write-Host "Step 6: Waiting for cluster to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
kubectl wait --for=condition=Ready nodes --all --timeout=300s
Write-Host "  Cluster is ready" -ForegroundColor Green
Write-Host ""

# Step 7: Restore resources
Write-Host "Step 7: Restoring resources..." -ForegroundColor Yellow
if ($BackupFirst -and (Test-Path "$backupPath\deployments.yaml")) {
    Write-Host "  Restoring deployments..." -ForegroundColor White
    kubectl apply -f "$backupPath\deployments.yaml"
    
    Write-Host "  Restoring services..." -ForegroundColor White
    kubectl apply -f "$backupPath\services.yaml"
    
    Write-Host "  Restoring configmaps..." -ForegroundColor White
    kubectl apply -f "$backupPath\configmaps.yaml"
    
    Write-Host "  Restoring networkpolicies..." -ForegroundColor White
    kubectl apply -f "$backupPath\networkpolicies.yaml"
}
Write-Host "  Resources restored" -ForegroundColor Green
Write-Host ""

# Step 8: Scale deployments back up
Write-Host "Step 8: Scaling deployments back up..." -ForegroundColor Yellow
$deploymentReplicas = @{
    "amf" = 2
    "smf" = 2
    "upf" = 3
    "nrf" = 2
    "prometheus" = 1
    "grafana" = 1
}

foreach ($dep in $deploymentReplicas.Keys) {
    Write-Host "  Scaling up $dep to $($deploymentReplicas[$dep]) replicas..." -ForegroundColor White
    kubectl scale deployment $dep -n $namespace --replicas=$deploymentReplicas[$dep]
}
Write-Host "  Deployments scaled up" -ForegroundColor Green
Write-Host ""

# Step 9: Wait for pods to be ready
Write-Host "Step 9: Waiting for all pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready pods --all -n $namespace --timeout=300s
Write-Host "  All pods are ready" -ForegroundColor Green
Write-Host ""

# Step 10: Verify upgrade
Write-Host "Step 10: Verifying upgrade..." -ForegroundColor Yellow
$newVersion = kubectl version --short 2>&1 | Select-String "Server Version"
Write-Host "  New Kubernetes version: $newVersion" -ForegroundColor White

# Run validation
Write-Host "`nRunning post-upgrade validation..." -ForegroundColor Yellow
& "D:\wh15\scripts\validate-deployment.ps1"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cluster Upgrade Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Upgrade Summary:" -ForegroundColor Yellow
Write-Host "  Previous version: $currentVersion" -ForegroundColor White
Write-Host "  Current version: $newVersion" -ForegroundColor White
Write-Host "  Backup location: $backupPath" -ForegroundColor White