Write-Host "Generating Kubernetes manifests from Helm charts..." -ForegroundColor Green

# Define environments and components
$environments = @("dev", "staging", "prod")

$components = @(
    @{name="amf"; chart="5g-amf"},
    @{name="smf"; chart="5g-smf"},
    @{name="upf"; chart="5g-upf"}
)

foreach ($env in $environments) {

    Write-Host "`nProcessing environment: $env" -ForegroundColor Cyan

    # Namespace per environment
    $namespace = switch ($env) {
        "dev"     { "telco-5g" }
        "staging" { "telco-5g-staging" }
        "prod"    { "telco-5g-prod" }
    }

    foreach ($component in $components) {

        Write-Host "Generating manifests for component: $($component.name)"

        $chartPath   = "helm-charts/$($component.chart)"
        $valuesFile  = "environments/$env/$($component.name)-values-$env.yaml"
        $outputFile  = "rendered-manifests/$env/$($component.name)-manifests.yaml"
        $releaseName = "$($component.name)-$env"

        helm template $releaseName $chartPath `
            -f $valuesFile `
            --namespace $namespace `
            > $outputFile

        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✓ Generated: $outputFile" -ForegroundColor Green
        }
        else {
            Write-Host " ✗ ERROR generating: $outputFile" -ForegroundColor Red
        }
    }

