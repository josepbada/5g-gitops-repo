# Master automation pipeline for 5G Telco Cloud
param(
    [switch]$SkipValidation = $false,
    [switch]$SkipGitUpdate = $false,
    [switch]$CleanStart = $false
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  5G Telco Cloud - Master Automation Pipeline" -ForegroundColor Cyan
Write-Host "  Infrastructure as Code & Complete Deployment Automation" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Test-Prerequisites {
    Write-Section "STAGE 1: Prerequisites Check"
    $allGood = $true

    $tools = @(
        @{ Name = "Terraform"; Cmd = "terraform version" }
        @{ Name = "Docker"; Cmd = "docker info" }
        @{ Name = "Minikube"; Cmd = "minikube version" }
        @{ Name = "kubectl"; Cmd = "kubectl version --client" }
        @{ Name = "Git"; Cmd = "git --version" }
    )

    foreach ($tool in $tools) {
        Write-Host "Checking $($tool.Name)..." -ForegroundColor White
        try {
            Invoke-Expression $tool.Cmd | Out-Null
            Write-Host "  OK $($tool.Name) found" -ForegroundColor Green
        }
        catch {
            Write-Host "  FAIL $($tool.Name) not found" -ForegroundColor Red
            $allGood = $false
        }
    }

    if (-not $allGood) {
        Write-Host "ERROR: Missing prerequisites." -ForegroundColor Red
        exit 1
    }
    Write-Host "All prerequisites satisfied OK" -ForegroundColor Green
}

function Clear-Infrastructure {
    if ($CleanStart) {
        Write-Section "STAGE 2: Clean Existing Infrastructure"
        Write-Host "Checking for existing Minikube cluster..." -ForegroundColor White
        $mkStatus = minikube status 2>&1
        if ($mkStatus -match "Running") {
            Write-Host "  Existing cluster found. Deleting..." -ForegroundColor Yellow
            minikube delete
            Write-Host "  OK Cluster deleted" -ForegroundColor Green
        }
        else {
            Write-Host "  No existing cluster found" -ForegroundColor White
        }
    }
}

function Initialize-Terraform {
    Write-Section "STAGE 3: Terraform Initialization"
    Write-Host "Running Terraform initialization script..." -ForegroundColor White
    & "D:\wh15\scripts\init-terraform.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform initialization failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "Terraform initialized successfully OK" -ForegroundColor Green
}

function Deploy-Infrastructure {
    Write-Section "STAGE 4: Infrastructure Deployment"
    Write-Host "Deploying complete 5G Telco Cloud infrastructure..." -ForegroundColor White
    & "D:\wh15\scripts\deploy-infrastructure.ps1" -AutoApprove
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Infrastructure deployment failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "Infrastructure deployed successfully OK" -ForegroundColor Green
}

function Validate-Deployment {
    if (-not $SkipValidation) {
        Write-Section "STAGE 5: Deployment Validation"
        Write-Host "Running automated validation tests..." -ForegroundColor White
        & "D:\wh15\scripts\validate-deployment.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "WARNING: Some validation tests failed" -ForegroundColor Yellow
        }
        else {
            Write-Host "All validation tests passed OK" -ForegroundColor Green
        }
    }
}

function Update-GitRepository {
    if (-not $SkipGitUpdate) {
        Write-Section "STAGE 6: Version Control Update"
        Write-Host "Updating Git repository..." -ForegroundColor White
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $commitMsg = "Automated deployment completed at $timestamp"
        & "D:\wh15\scripts\git-update.ps1" -CommitMessage $commitMsg -Push
        Write-Host "Git repository updated OK" -ForegroundColor Green
    }
}

function New-DeploymentReport {
    Write-Section "STAGE 7: Deployment Report Generation"

    $reportPath = "D:\wh15\deployment-report.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $duration = $endTime - $startTime

    $clusterInfo = kubectl cluster-info 2>&1
    $deployments = kubectl get deployments -n open5gs -o wide 2>&1
    $services = kubectl get services -n open5gs -o wide 2>&1
    $pods = kubectl get pods -n open5gs -o wide 2>&1
    $networkPolicies = kubectl get networkpolicies -n open5gs 2>&1

    $lines = [System.Collections.ArrayList]::new()
    $lines.Add("==========================================") | Out-Null
    $lines.Add("  5G Telco Cloud Deployment Report") | Out-Null
    $lines.Add("==========================================") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("Deployment Date: $timestamp") | Out-Null
    $lines.Add("Deployment Duration: $duration") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("--- CLUSTER INFORMATION ---") | Out-Null
    $lines.Add("$clusterInfo") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("--- DEPLOYMENTS ---") | Out-Null
    $lines.Add("$deployments") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("--- SERVICES ---") | Out-Null
    $lines.Add("$services") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("--- PODS ---") | Out-Null
    $lines.Add("$pods") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("--- NETWORK POLICIES ---") | Out-Null
    $lines.Add("$networkPolicies") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("--- ACCESS INFORMATION ---") | Out-Null
    $lines.Add("Grafana: kubectl port-forward -n open5gs svc/grafana-service 3000:3000") | Out-Null
    $lines.Add("Prometheus: kubectl port-forward -n open5gs svc/prometheus-service 9090:9090") | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("--- DEPLOYED COMPONENTS ---") | Out-Null
    $lines.Add("Control Plane: AMF, SMF, NRF") | Out-Null
    $lines.Add("User Plane: UPF") | Out-Null
    $lines.Add("Database: MongoDB") | Out-Null
    $lines.Add("Monitoring: Prometheus, Grafana") | Out-Null
    $lines.Add("==========================================") | Out-Null

    $report = $lines -join "`n"
    $report | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Host $report
    Write-Host ""
    Write-Host "Deployment report generated: $reportPath" -ForegroundColor Green
}

# Main execution flow
try {
    Test-Prerequisites
    Clear-Infrastructure
    Initialize-Terraform
    Deploy-Infrastructure
    Validate-Deployment
    Update-GitRepository

    $endTime = Get-Date
    New-DeploymentReport

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  PIPELINE EXECUTION COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "Total execution time: $($endTime - $startTime)" -ForegroundColor Cyan
    Write-Host "Your 5G Telco Cloud is ready!" -ForegroundColor Green
    Write-Host ""
    exit 0
}
catch {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host "  PIPELINE EXECUTION FAILED" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    exit 1
}