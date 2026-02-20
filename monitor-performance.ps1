# Performance Monitoring Script for 5G UPF
# This script monitors CPU and memory usage of UPF pods

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "5G UPF Performance Monitor" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "5g-core"
$duration = 60  # Monitor for 60 seconds
$interval = 5    # Sample every 5 seconds
$iterations = $duration / $interval

Write-Host "Monitoring namespace: $namespace" -ForegroundColor Yellow
Write-Host "Duration: $duration seconds" -ForegroundColor Yellow
Write-Host "Sample interval: $interval seconds" -ForegroundColor Yellow
Write-Host ""

for ($i = 1; $i -le $iterations; $i++) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] Sample $i of $iterations" -ForegroundColor Green
    
    kubectl top pods -n $namespace --no-headers | ForEach-Object {
        $parts = $_ -split '\s+'
        $podName = $parts[0]
        $cpu = $parts[1]
        $memory = $parts[2]
        
        Write-Host "  $podName : CPU=$cpu Memory=$memory" -ForegroundColor White
    }
    
    Write-Host ""
    
    if ($i -lt $iterations) {
        Start-Sleep -Seconds $interval
    }
}

Write-Host "Monitoring complete!" -ForegroundColor Cyan