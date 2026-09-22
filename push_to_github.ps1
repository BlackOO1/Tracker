# ============================================================
# push_to_github.ps1
# Run this script ONCE after installing Git to push everything
# to your GitHub repo: https://github.com/BlackOO1/Tracker.git
# ============================================================

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Budget Planner - Push to GitHub" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is available
try {
    $gitVersion = git --version 2>&1
    Write-Host "[OK] Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Git not found. Please install Git first:" -ForegroundColor Red
    Write-Host "Download from: https://git-scm.com/download/win" -ForegroundColor Yellow
    pause
    exit 1
}

$projectDir = "c:\Users\asima\OneDrive\Desktop\Project_app\Tracker"
Set-Location $projectDir

# Configure git identity (update with your details)
Write-Host ""
Write-Host "Configuring Git identity..." -ForegroundColor Yellow
git config --global user.email "your-email@example.com"
git config --global user.name "BlackOO1"

# Initialize git repo if not already done
if (-not (Test-Path ".git")) {
    Write-Host "Initializing git repository..." -ForegroundColor Yellow
    git init
    git branch -M main
}

# Add remote if not already added
$remotes = git remote 2>&1
if ($remotes -notlike "*origin*") {
    Write-Host "Adding GitHub remote..." -ForegroundColor Yellow
    git remote add origin https://github.com/BlackOO1/Tracker.git
} else {
    Write-Host "[OK] Remote origin already configured" -ForegroundColor Green
    git remote set-url origin https://github.com/BlackOO1/Tracker.git
}

# Stage all files
Write-Host ""
Write-Host "Staging all project files..." -ForegroundColor Yellow
git add .

# Commit
Write-Host "Committing..." -ForegroundColor Yellow
git commit -m "Initial commit: Budget Planner Flutter app"

# Push to GitHub
Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
Write-Host "(A browser window or prompt may appear - sign in with your GitHub account)" -ForegroundColor Cyan
git push -u origin main

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "  SUCCESS! Your code is now on GitHub!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Repository:  https://github.com/BlackOO1/Tracker" -ForegroundColor Cyan
Write-Host "  Build Status: https://github.com/BlackOO1/Tracker/actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "GitHub Actions will now automatically build your APK!" -ForegroundColor Green
Write-Host "Check the Actions tab in 5-10 minutes for your downloadable APK." -ForegroundColor Yellow
Write-Host ""
pause
