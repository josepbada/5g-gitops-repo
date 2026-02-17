# PowerShell script to validate 5G Telco Cloud deployment
# This script performs automated tests and compliance checks

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "5G Telco Cloud Deployment Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "telco5g"
$passed = 0
$failed = 0

# Test 1: Check if namespace exists
Write-Host "Test 1: Verifying namespace exists..." -ForegroundColor Yellow
$nsExists = kubectl get namespace $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  PASSED: Namespace '$namespace' exists" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAILED: Namespace '$namespace' does not exist" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 2: Check if all deployments are ready
Write-Host "Test 2: Verifying all deployments are ready..." -ForegroundColor Yellow
$expectedDeployments = @("amf", "smf", "upf", "nrf", "prometheus", "grafana")
foreach ($deployment in $expectedDeployments) {
    $ready = kubectl get deployment $deployment -n $namespace -o jsonpath='{.status.readyReplicas}' 2>&1
    $desired = kubectl get deployment $deployment -n $namespace -o jsonpath='{.spec.replicas}' 2>&1
    
    if ($LASTEXITCODE -eq 0 -and $ready -eq $desired) {
        Write-Host "  PASSED: Deployment '$deployment' is ready ($ready/$desired replicas)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAILED: Deployment '$deployment' is not ready ($ready/$desired replicas)" -ForegroundColor Red
        $failed++
    }
}
Write-Host ""

# Test 3: Check if all services exist
Write-Host "Test 3: Verifying all services exist..." -ForegroundColor Yellow
$expectedServices = @("amf-service", "smf-service", "upf-service", "nrf-service", "prometheus-service", "grafana-service")
foreach ($service in $expectedServices) {
    $svcExists = kubectl get service $service -n $namespace 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  PASSED: Service '$service' exists" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAILED: Service '$service' does not exist" -ForegroundColor Red
        $failed++
    }
}
Write-Host ""

# Test 4: Check if network policies are applied
Write-Host "Test 4: Verifying NetworkPolicies..." -ForegroundColor Yellow
$expectedPolicies = @("amf-network-policy", "smf-network-policy", "upf-network-policy")
foreach ($policy in $expectedPolicies) {
    $policyExists = kubectl get networkpolicy $policy -n $namespace 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  PASSED: NetworkPolicy '$policy' is applied" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAILED: NetworkPolicy '$policy' is not applied" -ForegroundColor Red
        $failed++
    }
}
Write-Host ""

# Test 5: Check resource quotas
Write-Host "Test 5: Verifying ResourceQuota..." -ForegroundColor Yellow
$quotaExists = kubectl get resourcequota telco5g-quota -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  PASSED: ResourceQuota 'telco5g-quota' is configured" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAILED: ResourceQuota 'telco5g-quota' is not configured" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 6: Check LimitRange
Write-Host "Test 6: Verifying LimitRange..." -ForegroundColor Yellow
$limitExists = kubectl get limitrange telco5g-limits -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  PASSED: LimitRange 'telco5g-limits' is configured" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAILED: LimitRange 'telco5g-limits' is not configured" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 7: Check if pods are running
Write-Host "Test 7: Verifying pods are running..." -ForegroundColor Yellow
$allPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$runningPods = 0
$totalPods = $allPods.items.Count

foreach ($pod in $allPods.items) {
    if ($pod.status.phase -eq "Running") {
        $runningPods++
    }
}

if ($runningPods -eq $totalPods) {
    Write-Host "  PASSED: All pods are running ($runningPods/$totalPods)" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  FAILED: Not all pods are running ($runningPods/$totalPods)" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test 8: Check ConfigMaps
Write-Host "Test 8: Verifying ConfigMaps..." -ForegroundColor Yellow
$expectedConfigMaps = @("amf-config", "smf-config", "upf-config", "nrf-config")
foreach ($cm in $expectedConfigMaps) {
    $cmExists = kubectl get configmap $cm -n $namespace 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  PASSED: ConfigMap '$cm' exists" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FAILED: ConfigMap '$cm' does not exist" -ForegroundColor Red
        $failed++
    }
}
Write-Host ""

# Test 9: Check Prometheus accessibility
Write-Host "Test 9: Testing Prometheus accessibility..." -ForegroundColor Yellow
$prometheusPod = kubectl get pods -n $namespace -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>&1
if ($LASTEXITCODE -eq 0) {
    $portForward = Start-Job -ScriptBlock {
        kubectl port-forward -n telco5g svc/prometheus-service 9090:9090
    }
    Start-Sleep -Seconds 5
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9090" -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "  PASSED: Prometheus is accessible" -ForegroundColor Green
            $passed++
        }
    } catch {
        Write-Host "  FAILED: Prometheus is not accessible" -ForegroundColor Red
        $failed++
    } finally {
        Stop-Job -Job $portForward
        Remove-Job -Job $portForward
    }
} else {
    Write-Host "  FAILED: Prometheus pod not found" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Display summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($passed + $failed)" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "All validation tests passed!" -ForegroundColor Green
    Write-Host "5G Telco Cloud deployment is healthy" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some validation tests failed" -ForegroundColor Yellow
    Write-Host "Please review the failed tests and fix issues" -ForegroundColor Yellow
    exit 1
}