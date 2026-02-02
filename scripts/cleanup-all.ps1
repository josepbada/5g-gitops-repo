# Complete cleanup script for 5G Telco Cloud infrastructure
# This script removes all deployed resources and resets the environment

param(
    [switch]$KeepBackups = $false,
    [switch]$Force = $false
)

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║     5G Telco Cloud - Complete Cleanup                    ║" -ForegroundColor Red
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

if (-not $Force) {
    Write-Host "WARNING: This will remove ALL deployed resources!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The following will be deleted:" -ForegroundColor Yellow
    Write-Host "  • Minikube Kubernetes cluster" -ForegroundColor White
    Write-Host "  • All 5G components (AMF, SMF, UPF, NRF)" -ForegroundColor White
    Write-Host "  • Monitoring stack (Prometheus, Grafana)" -ForegroundColor White
    Write-Host "  • Terraform state files" -ForegroundColor White
    if (-not $KeepBackups) {
        Write-Host "  • Backup files" -ForegroundColor White
    }
    Write-Host ""
    
    $confirm = Read-Host "Type 'DELETE ALL' to confirm"
    
    if ($confirm -ne 'DELETE ALL') {
        Write-Host ""
        Write-Host "Cleanup cancelled" -ForegroundColor Green
        exit 0
    }
}

Write-Host ""
Write-Host "Starting cleanup process..." -ForegroundColor Yellow
Write-Host ""

# Step 1: Delete Terraform-managed resources
Write-Host "Step 1: Removing Terraform-managed resources..." -ForegroundColor Yellow
cd D:\wh15\terraform

if (Test-Path "terraform.tfstate") {
    terraform destroy -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Terraform resources destroyed" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Terraform destroy had issues, continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "  • No Terraform state found" -ForegroundColor White
}

# Step 2: Delete Minikube cluster
Write-Host ""
Write-Host "Step 2: Deleting Minikube cluster..." -ForegroundColor Yellow
minikube delete

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Minikube cluster deleted" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Minikube delete had issues, continuing..." -ForegroundColor Yellow
}

# Step 3: Clean Terraform files
Write-Host ""
Write-Host "Step 3: Cleaning Terraform temporary files..." -ForegroundColor Yellow
cd D:\wh15\terraform

if (Test-Path ".terraform") {
    Remove-Item -Path ".terraform" -Recurse -Force
    Write-Host "  ✓ Removed .terraform directory" -ForegroundColor Green
}

if (Test-Path "tfplan") {
    Remove-Item -Path "tfplan" -Force
    Write-Host "  ✓ Removed tfplan file" -ForegroundColor Green
}

if (Test-Path "terraform.tfstate") {
    Remove-Item -Path "terraform.tfstate*" -Force
    Write-Host "  ✓ Removed state files" -ForegroundColor Green
}

# Step 4: Clean generated Kubernetes manifests
Write-Host ""
Write-Host "Step 4: Cleaning generated Kubernetes manifests..." -ForegroundColor Yellow
$manifestsPath = "D:\wh15\k8s-manifests"
if (Test-Path $manifestsPath) {
    $manifests = Get-ChildItem $manifestsPath -Filter "*.yaml"
    if ($manifests.Count -gt 0) {
        Remove-Item "$manifestsPath\*.yaml" -Force
        Write-Host "  ✓ Removed $($manifests.Count) manifest files" -ForegroundColor Green
    } else {
        Write-Host "  • No manifest files found" -ForegroundColor White
    }
}

# Step 5: Clean backups (optional)
if (-not $KeepBackups) {
    Write-Host ""
    Write-Host "Step 5: Removing backup files..." -ForegroundColor Yellow
    $backupsPath = "D:\wh15\backups"
    if (Test-Path $backupsPath) {
        $backups = Get-ChildItem $backupsPath
        if ($backups.Count -gt 0) {
            Remove-Item "$backupsPath\*" -Recurse -Force
            Write-Host "  ✓ Removed all backups" -ForegroundColor Green
        } else {
            Write-Host "  • No backups found" -ForegroundColor White
        }
    }
} else {
    Write-Host ""
    Write-Host "Step 5: Keeping backup files (--KeepBackups flag set)" -ForegroundColor Cyan
}

# Step 6: Clean deployment reports
Write-Host ""
Write-Host "Step 6: Removing deployment reports..." -ForegroundColor Yellow
if (Test-Path "D:\wh15\deployment-report.txt") {
    Remove-Item "D:\wh15\deployment-report.txt" -Force
    Write-Host "  ✓ Removed deployment report" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     Cleanup Completed Successfully                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  • Terraform resources removed" -ForegroundColor White
Write-Host "  • Minikube cluster deleted" -ForegroundColor White
Write-Host "  • Temporary files cleaned" -ForegroundColor White
if ($KeepBackups) {
    Write-Host "  • Backups preserved" -ForegroundColor White
} else {
    Write-Host "  • Backups removed" -ForegroundColor White
}
Write-Host ""
Write-Host "Your environment has been reset to clean state" -ForegroundColor Green
Write-Host ""