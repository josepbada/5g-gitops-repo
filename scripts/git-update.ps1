# PowerShell script to automate Git operations
# This script commits and pushes changes to GitHub

param(
    [string]$CommitMessage = "Update 5G infrastructure configuration",
    [switch]$Push = $true
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git Repository Update" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to repository root
cd D:\wh15

# Check if we're in a Git repository
$isGitRepo = Test-Path .git
if (-not $isGitRepo) {
    Write-Host "ERROR: Not a Git repository" -ForegroundColor Red
    Write-Host "Please run 'git init' first" -ForegroundColor Yellow
    exit 1
}

# Check Git status
Write-Host "Checking repository status..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "Files to be committed:" -ForegroundColor Yellow

# Show changes
$changes = git status --short
if ($changes) {
    Write-Host $changes -ForegroundColor White
} else {
    Write-Host "No changes to commit" -ForegroundColor Green
    exit 0
}

Write-Host ""

# Confirm commit
$confirm = Read-Host "Do you want to commit these changes? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Commit cancelled" -ForegroundColor Yellow
    exit 0
}

# Add all changes
Write-Host ""
Write-Host "Adding files to staging area..." -ForegroundColor Yellow
git add .

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to add files" -ForegroundColor Red
    exit 1
}

# Commit changes
Write-Host "Committing changes..." -ForegroundColor Yellow
git commit -m "$CommitMessage"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Commit failed" -ForegroundColor Red
    exit 1
}

Write-Host "Changes committed successfully" -ForegroundColor Green

# Push to remote if requested
if ($Push) {
    Write-Host ""
    Write-Host "Checking remote repository..." -ForegroundColor Yellow
    
    $remotes = git remote -v
    if (-not $remotes) {
        Write-Host "WARNING: No remote repository configured" -ForegroundColor Yellow
        Write-Host "To add a remote repository:" -ForegroundColor White
        Write-Host "  git remote add origin https://github.com/josepbada/5g-gitops-repo.git" -ForegroundColor White
        exit 0
    }
    
    # Push to remote
    Write-Host "Pushing to remote repository..." -ForegroundColor Yellow
    git push
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Push failed" -ForegroundColor Red
        Write-Host "You may need to set upstream branch:" -ForegroundColor Yellow
        Write-Host "  git push --set-upstream origin main" -ForegroundColor White
        exit 1
    }
    
    Write-Host "Changes pushed successfully" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git Update Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Latest commit:" -ForegroundColor Yellow
git log -1 --oneline