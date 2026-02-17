# PowerShell script to initialize Terraform for 5G Telco Cloud
# This script prepares the Terraform environment and validates configurations

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Terraform Initialization for 5G Telco Cloud" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
$workingDir = "D:\wh15\terraform"
Set-Location $workingDir

Write-Host "Step 1: Checking Terraform installation..." -ForegroundColor Yellow
terraform version
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform is not installed or not in PATH" -ForegroundColor Red
    exit 1
}
Write-Host "Terraform is installed correctly" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Checking Docker Desktop status..." -ForegroundColor Yellow
docker info | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker Desktop is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again" -ForegroundColor Red
    exit 1
}
Write-Host "Docker Desktop is running" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Initializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform initialization failed" -ForegroundColor Red
    exit 1
}
Write-Host "Terraform initialized successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Step 4: Validating Terraform configuration..." -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform configuration is invalid" -ForegroundColor Red
    exit 1
}
Write-Host "Terraform configuration is valid" -ForegroundColor Green
Write-Host ""

Write-Host "Step 5: Formatting Terraform files..." -ForegroundColor Yellow
terraform fmt -recursive
Write-Host "Terraform files formatted" -ForegroundColor Green
Write-Host ""

Write-Host "Step 6: Creating Terraform plan..." -ForegroundColor Yellow
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Terraform plan creation failed" -ForegroundColor Red
    exit 1
}
Write-Host "Terraform plan created successfully" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Terraform Initialization Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the plan: terraform show tfplan" -ForegroundColor White
Write-Host "2. Apply the plan: terraform apply tfplan" -ForegroundColor White
Write-Host "Or run the deployment script: .\scripts\deploy-infrastructure.ps1" -ForegroundColor White