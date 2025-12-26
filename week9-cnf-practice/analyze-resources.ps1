# 5G Core Resource Analysis Script
# Week 9 - Cloud-Native Architecture

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "5G Core Resource Consumption Analysis" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Get all pods in the namespace
$pods = kubectl get pods -n open5gs-core -o json | ConvertFrom-Json

Write-Host "Components Deployed:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

$totalMemoryRequestMB = 0
$totalMemoryLimitMB = 0
$totalCPURequest = 0
$totalCPULimit = 0

foreach ($pod in $pods.items) {
    $podName = $pod.metadata.name
    $appLabel = $pod.metadata.labels.app
    
    foreach ($container in $pod.spec.containers) {
        $memRequest = $container.resources.requests.memory
        $memLimit = $container.resources.limits.memory
        $cpuRequest = $container.resources.requests.cpu
        $cpuLimit = $container.resources.limits.cpu
        
        # Convert memory to MB
        $memRequestMB = if ($memRequest -match '(\d+)Mi') { [int]$matches[1] } else { 0 }
        $memLimitMB = if ($memLimit -match '(\d+)Mi') { [int]$matches[1] } else { 0 }
        
        # Convert CPU to decimal (m = milliCPU, 1000m = 1 CPU)
        $cpuReqNum = if ($cpuRequest -match '(\d+)m') { [decimal]$matches[1] / 1000 } else { 0 }
        $cpuLimNum = if ($cpuLimit -match '(\d+)m') { [decimal]$matches[1] / 1000 } else { 0 }
        
        $totalMemoryRequestMB += $memRequestMB
        $totalMemoryLimitMB += $memLimitMB
        $totalCPURequest += $cpuReqNum
        $totalCPULimit += $cpuLimNum
        
        Write-Host "$appLabel ($podName):" -ForegroundColor Green
        Write-Host "  Memory: Request=$memRequestMB MB, Limit=$memLimitMB MB" -ForegroundColor White
        Write-Host "  CPU: Request=$cpuReqNum, Limit=$cpuLimNum" -ForegroundColor White
        Write-Host ""
    }
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Resource Totals:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow
Write-Host "Total Memory Requests: $totalMemoryRequestMB MB" -ForegroundColor Green
Write-Host "Total Memory Limits: $totalMemoryLimitMB MB" -ForegroundColor Green
Write-Host "Total CPU Requests: $totalCPURequest cores" -ForegroundColor Green
Write-Host "Total CPU Limits: $totalCPULimit cores" -ForegroundColor Green
Write-Host ""

# Docker Desktop limits
$dockerMemoryMB = 5000
$dockerCPU = 4.0

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Docker Desktop Capacity:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow
Write-Host "Available Memory: $dockerMemoryMB MB" -ForegroundColor White
Write-Host "Available CPU: $dockerCPU cores" -ForegroundColor White
Write-Host ""

# Calculate utilization
$memUtilizationPct = [math]::Round(($totalMemoryLimitMB / $dockerMemoryMB) * 100, 1)
$cpuUtilizationPct = [math]::Round(($totalCPULimit / $dockerCPU) * 100, 1)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Resource Utilization:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow
Write-Host "Memory Utilization: $memUtilizationPct%" -ForegroundColor $(if ($memUtilizationPct -lt 70) { "Green" } elseif ($memUtilizationPct -lt 85) { "Yellow" } else { "Red" })
Write-Host "  Used: $totalMemoryLimitMB MB" -ForegroundColor White
Write-Host "  Available: $($dockerMemoryMB - $totalMemoryLimitMB) MB" -ForegroundColor White
Write-Host ""
Write-Host "CPU Utilization: $cpuUtilizationPct%" -ForegroundColor $(if ($cpuUtilizationPct -lt 70) { "Green" } elseif ($cpuUtilizationPct -lt 85) { "Yellow" } else { "Red" })
Write-Host "  Used: $totalCPULimit cores" -ForegroundColor White
Write-Host "  Available: $($dockerCPU - $totalCPULimit) cores" -ForegroundColor White
Write-Host ""

# Storage analysis
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Persistent Storage:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

$pvcs = kubectl get pvc -n open5gs-core -o json | ConvertFrom-Json
$totalStorageGB = 0

foreach ($pvc in $pvcs.items) {
    $pvcName = $pvc.metadata.name
    $storageSize = $pvc.spec.resources.requests.storage
    $storageSizeGB = if ($storageSize -match '(\d+)Gi') { [int]$matches[1] } else { 0 }
    $totalStorageGB += $storageSizeGB
    $status = $pvc.status.phase
    
    Write-Host "$pvcName : $storageSize ($status)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Total Storage Allocated: $totalStorageGB Gi" -ForegroundColor Green
Write-Host ""

# Health check
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Pod Health Status:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

$runningPods = 0
$totalPods = 0

foreach ($pod in $pods.items) {
    $totalPods++
    $podName = $pod.metadata.name
    $phase = $pod.status.phase
    $ready = $pod.status.conditions | Where-Object { $_.type -eq "Ready" } | Select-Object -First 1
    
    if ($phase -eq "Running" -and $ready.status -eq "True") {
        $runningPods++
        Write-Host "$podName : Running & Ready [OK]" -ForegroundColor Green
    } else {
        Write-Host "$podName : $phase" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Health Summary: $runningPods / $totalPods pods healthy" -ForegroundColor $(if ($runningPods -eq $totalPods) { "Green" } else { "Red" })
Write-Host ""

# Safety recommendations
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Resource Safety Assessment:" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

if ($memUtilizationPct -lt 70) {
    Write-Host "[OK] Memory utilization is SAFE (< 70%)" -ForegroundColor Green
    Write-Host "  Adequate headroom for system processes and burst traffic" -ForegroundColor White
} elseif ($memUtilizationPct -lt 85) {
    Write-Host "[WARNING] Memory utilization is MODERATE (70-85%)" -ForegroundColor Yellow
    Write-Host "  Consider reducing replicas or resource limits if issues occur" -ForegroundColor White
} else {
    Write-Host "[CRITICAL] Memory utilization is HIGH (> 85%)" -ForegroundColor Red
    Write-Host "  Risk of OOM errors. Reduce replicas or increase Docker Desktop memory" -ForegroundColor White
}

Write-Host ""

if ($cpuUtilizationPct -lt 70) {
    Write-Host "[OK] CPU utilization is SAFE (< 70%)" -ForegroundColor Green
    Write-Host "  Sufficient CPU capacity for workload demands" -ForegroundColor White
} elseif ($cpuUtilizationPct -lt 85) {
    Write-Host "[WARNING] CPU utilization is MODERATE (70-85%)" -ForegroundColor Yellow
    Write-Host "  Monitor for CPU throttling under load" -ForegroundColor White
} else {
    Write-Host "[CRITICAL] CPU utilization is HIGH (> 85%)" -ForegroundColor Red
    Write-Host "  Pods may be throttled. Consider reducing CPU limits" -ForegroundColor White
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Analysis Complete" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan