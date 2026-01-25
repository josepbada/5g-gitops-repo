# Image scanning script for 5G container images
# This script scans images and fails if critical vulnerabilities are found

param(
    [string]$ImageName = "nginx:1.24-alpine",
    [string]$OutputDir = "D:\hand14\scanning"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "5G Telco Image Security Scan" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Scanning image: $ImageName" -ForegroundColor Yellow
Write-Host ""

# Create output directory if it doesn't exist
New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null

# Generate timestamp for report filename
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = "$OutputDir/scan-report-$timestamp.json"

# Run Trivy scan
Write-Host "Running vulnerability scan..." -ForegroundColor Yellow
docker run --rm -v ${OutputDir}:/output aquasec/trivy:latest image --severity CRITICAL,HIGH -f json -o /output/scan-report-$timestamp.json $ImageName

# Check if scan found critical vulnerabilities
$scanResults = Get-Content $reportFile | ConvertFrom-Json

$criticalCount = 0
$highCount = 0

foreach ($result in $scanResults.Results) {
    if ($result.Vulnerabilities) {
        foreach ($vuln in $result.Vulnerabilities) {
            if ($vuln.Severity -eq "CRITICAL") {
                $criticalCount++
            }
            elseif ($vuln.Severity -eq "HIGH") {
                $highCount++
            }
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scan Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Critical Vulnerabilities: $criticalCount" -ForegroundColor $(if ($criticalCount -gt 0) { "Red" } else { "Green" })
Write-Host "High Vulnerabilities: $highCount" -ForegroundColor $(if ($highCount -gt 0) { "Yellow" } else { "Green" })
Write-Host ""
Write-Host "Full report saved to: $reportFile" -ForegroundColor Cyan
Write-Host ""

# Fail if critical vulnerabilities found (for CI/CD integration)
if ($criticalCount -gt 0) {
    Write-Host "SCAN FAILED: Critical vulnerabilities detected!" -ForegroundColor Red
    Write-Host "Please remediate critical vulnerabilities before deployment." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "SCAN PASSED: No critical vulnerabilities detected." -ForegroundColor Green
    if ($highCount -gt 0) {
        Write-Host "Warning: High severity vulnerabilities detected. Consider remediation." -ForegroundColor Yellow
    }
    exit 0
}