# Self-Service Infrastructure Portal for 5G Telco Cloud

function Show-MainMenu {
    Clear-Host
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "     5G Telco Cloud - Self-Service Infrastructure" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  DEPLOYMENT OPTIONS:" -ForegroundColor Yellow
    Write-Host "  [1] Deploy Complete 5G Infrastructure" -ForegroundColor White
    Write-Host "  [2] Deploy Individual Component" -ForegroundColor White
    Write-Host "  [3] Deploy Monitoring Stack Only" -ForegroundColor White
    Write-Host ""
    Write-Host "  MANAGEMENT OPTIONS:" -ForegroundColor Yellow
    Write-Host "  [4] Scale Component Replicas" -ForegroundColor White
    Write-Host "  [5] Apply Network Policies" -ForegroundColor White
    Write-Host ""
    Write-Host "  OPERATIONS:" -ForegroundColor Yellow
    Write-Host "  [6] View Cluster Status" -ForegroundColor White
    Write-Host "  [7] View Component Logs" -ForegroundColor White
    Write-Host "  [8] Run Validation Tests" -ForegroundColor White
    Write-Host "  [9] Access Service (Port Forward)" -ForegroundColor White
    Write-Host ""
    Write-Host "  MAINTENANCE:" -ForegroundColor Yellow
    Write-Host "  [10] Backup Configuration" -ForegroundColor White
    Write-Host "  [11] Restore from Backup" -ForegroundColor White
    Write-Host "  [12] Clean Up Resources" -ForegroundColor White
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
}

function Deploy-CompleteInfrastructure {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Deploying Complete 5G Infrastructure" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "This will deploy:" -ForegroundColor White
    Write-Host "  - Kubernetes cluster (Minikube)" -ForegroundColor Cyan
    Write-Host "  - 5G Core components (AMF, SMF, UPF, NRF)" -ForegroundColor Cyan
    Write-Host "  - Monitoring stack (Prometheus, Grafana)" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Continue? (y/n)"
    if ($confirm -eq 'y') {
        & "D:\wh15\scripts\master-pipeline.ps1"
    }
    
    Read-Host "`nPress Enter to continue"
}

function Deploy-IndividualComponent {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Deploy Individual Component" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Available components:" -ForegroundColor White
    Write-Host "  [1] AMF" -ForegroundColor Cyan
    Write-Host "  [2] SMF" -ForegroundColor Cyan
    Write-Host "  [3] UPF" -ForegroundColor Cyan
    Write-Host "  [4] NRF" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "Select component (1-4)"
    
    $components = @{
        "1" = @{name="amf"; port=8080; replicas=2}
        "2" = @{name="smf"; port=8082; replicas=2}
        "3" = @{name="upf"; port=8083; replicas=3}
        "4" = @{name="nrf"; port=8081; replicas=2}
    }
    
    if ($components.ContainsKey($choice)) {
        $comp = $components[$choice]
        Write-Host ""
        Write-Host "Deploying $($comp.name.ToUpper())..." -ForegroundColor Yellow
        
        cd D:\wh15\terraform
        terraform apply -target=module.$($comp.name) -auto-approve
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "$($comp.name.ToUpper()) deployed successfully" -ForegroundColor Green
        }
    }
    
    Read-Host "`nPress Enter to continue"
}

function Deploy-MonitoringStack {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Deploy Monitoring Stack" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "This will deploy:" -ForegroundColor White
    Write-Host "  - Prometheus (metrics)" -ForegroundColor Cyan
    Write-Host "  - Grafana (visualization)" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Continue? (y/n)"
    if ($confirm -eq 'y') {
        cd D:\wh15\terraform
        terraform apply -target=module.monitoring -auto-approve
        
        Write-Host ""
        Write-Host "Monitoring stack deployed successfully" -ForegroundColor Green
    }
    
    Read-Host "`nPress Enter to continue"
}

function Scale-ComponentReplicas {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Scale Component Replicas" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Current deployments:" -ForegroundColor White
    kubectl get deployments -n telco5g
    
    Write-Host ""
    $componentName = Read-Host "Enter component name"
    $newReplicas = Read-Host "Enter new replicas"
    
    kubectl scale deployment $componentName -n telco5g --replicas=$newReplicas
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "$componentName scaled to $newReplicas replicas" -ForegroundColor Green
    }
    
    Read-Host "`nPress Enter to continue"
}

function Apply-NetworkPolicies {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Apply Network Policies" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    cd D:\wh15\ansible
    ansible-playbook -i inventory.yml playbooks/configure-5g-network.yml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Network policies applied" -ForegroundColor Green
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-ClusterStatus {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Cluster Status" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Cluster Info:" -ForegroundColor Cyan
    kubectl cluster-info
    
    Write-Host "`nDeployments:" -ForegroundColor Cyan
    kubectl get deployments -n telco5g
    
    Write-Host "`nServices:" -ForegroundColor Cyan
    kubectl get services -n telco5g
    
    Write-Host "`nPods:" -ForegroundColor Cyan
    kubectl get pods -n telco5g
    
    Read-Host "`nPress Enter to continue"
}

function Show-ComponentLogs {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  View Component Logs" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $componentName = Read-Host "Enter component name (amf/smf/upf/nrf)"
    
    Write-Host ""
    Write-Host "Recent logs for $componentName:" -ForegroundColor Cyan
    kubectl logs -n telco5g -l app=$componentName --tail=50
    
    Read-Host "`nPress Enter to continue"
}

function Run-ValidationTests {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Running Validation Tests" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    & "D:\wh15\scripts\validate-deployment.ps1"
    
    Read-Host "`nPress Enter to continue"
}

function Access-Service {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Access Service (Port Forward)" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Available services:" -ForegroundColor White
    Write-Host "  [1] Grafana (3000)" -ForegroundColor Cyan
    Write-Host "  [2] Prometheus (9090)" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "Select service (1-2)"
    
    if ($choice -eq "1") {
        Write-Host ""
        Write-Host "Access at: http://localhost:3000" -ForegroundColor Green
        kubectl port-forward -n telco5g svc/grafana-service 3000:3000
    }
    elseif ($choice -eq "2") {
        Write-Host ""
        Write-Host "Access at: http://localhost:9090" -ForegroundColor Green
        kubectl port-forward -n telco5g svc/prometheus-service 9090:9090
    }
}

function Backup-Configuration {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Backup Configuration" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "D:\wh15\backups\backup-$timestamp"
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    
    Write-Host "Creating backup..." -ForegroundColor Yellow
    
    kubectl get all -n telco5g -o yaml > "$backupPath\resources.yaml"
    
    Write-Host ""
    Write-Host "Backup created: $backupPath" -ForegroundColor Green
    
    Read-Host "`nPress Enter to continue"
}

function Restore-FromBackup {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Restore from Backup" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $backups = Get-ChildItem "D:\wh15\backups" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    
    if ($backups.Count -eq 0) {
        Write-Host "No backups found" -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue"
        return
    }
    
    Write-Host "Available backups:" -ForegroundColor White
    for ($i = 0; $i -lt $backups.Count; $i++) {
        Write-Host "  [$($i+1)] $($backups[$i].Name)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    $choice = Read-Host "Select backup (1-$($backups.Count))"
    $index = [int]$choice - 1
    
    if ($index -ge 0 -and $index -lt $backups.Count) {
        $backupPath = $backups[$index].FullName
        kubectl apply -f "$backupPath\resources.yaml"
        Write-Host ""
        Write-Host "Restore completed" -ForegroundColor Green
    }
    
    Read-Host "`nPress Enter to continue"
}

function Cleanup-Resources {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  Clean Up Resources" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "WARNING: This will remove all deployed resources!" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "Type 'DELETE' to confirm"
    
    if ($confirm -eq 'DELETE') {
        Write-Host ""
        Write-Host "Deleting resources..." -ForegroundColor Yellow
        cd D:\wh15\terraform
        terraform destroy -auto-approve
        
        Write-Host ""
        Write-Host "Deleting cluster..." -ForegroundColor Yellow
        minikube delete
        
        Write-Host ""
        Write-Host "Cleanup completed" -ForegroundColor Green
    }
    
    Read-Host "`nPress Enter to continue"
}

# Main loop
while ($true) {
    Show-MainMenu
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" { Deploy-CompleteInfrastructure }
        "2" { Deploy-IndividualComponent }
        "3" { Deploy-MonitoringStack }
        "4" { Scale-ComponentReplicas }
        "5" { Apply-NetworkPolicies }
        "6" { Show-ClusterStatus }
        "7" { Show-ComponentLogs }
        "8" { Run-ValidationTests }
        "9" { Access-Service }
        "10" { Backup-Configuration }
        "11" { Restore-FromBackup }
        "12" { Cleanup-Resources }
        "0" { 
            Write-Host ""
            Write-Host "Exiting..." -ForegroundColor Cyan
            exit 0
        }
        default {
            Write-Host ""
            Write-Host "Invalid option" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}