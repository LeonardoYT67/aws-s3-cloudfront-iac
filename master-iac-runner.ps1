<#
Title: Master IaC Runner
Author: Ayush Sharma
Description: One-command orchestration for S3 → CloudFront → Security → Validation.
#>

# ------------------------------
# CONFIGURATION
# ------------------------------
$logFile = ".\iac-runner-log.txt"
$backupDir = ".\backups"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (!(Test-Path $backupDir)) {
New-Item -Path $backupDir -ItemType Directory | Out-Null
}

# ------------------------------
# HELPER FUNCTIONS
# ------------------------------

function Write-Log {
param(
[string]$message,
[string]$color = "White"
)
$timestampLog = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[$timestampLog] $message" -ForegroundColor $color
Add-Content -Path $logFile -Value "[$timestampLog] $message"
}

function Run-Script {
param(
[string]$scriptPath,
[string]$stepName
)

Write-Log "=== Running Step: $stepName ===" "Yellow"

if (Test-Path $scriptPath) {
try {
& $scriptPath
Write-Log "✅ $stepName completed successfully." "Green"
}
catch {
Write-Log "❌ Error in $stepName — $($_.Exception.Message)" "Red"
throw
}
}
else {
Write-Log "⚠️ Skipped: $stepName — script not found at $scriptPath" "DarkYellow"
}
}

function Backup-CloudFrontConfig {
try {
$distList = aws cloudfront list-distributions --query "DistributionList.Items[*].Id" --output text
if ($distList) {
foreach ($distId in $distList) {
$backupFile = "$backupDir\cloudfront-backup-$distId-$timestamp.json"
aws cloudfront get-distribution-config --id $distId --output json > $backupFile
Write-Log "🗂️ Backup created for CloudFront Distribution: $distId → $backupFile" "Gray"
}
}
else {
Write-Log "ℹ️ No existing CloudFront distributions found to backup." "DarkGray"
}
}
catch {
Write-Log "⚠️ Failed to backup CloudFront configurations: $($_.Exception.Message)" "Red"
}
}

# ------------------------------
# MAIN EXECUTION
# ------------------------------

Write-Log "=== MASTER IaC RUNNER STARTED ===" "Cyan"
Write-Log "Timestamp: $timestamp" "Gray"
Write-Log "---------------------------------" "Gray"

try {
# STEP 1: Create / Verify S3 Bucket
Run-Script ".\1-create-s3.ps1" "S3 Bucket Setup"

# STEP 2: Deploy CloudFront (Idempotent)
Backup-CloudFrontConfig
Run-Script ".\deploy-cloudfront.ps1" "CloudFront Deployment"

# STEP 3: Finalize S3 + CloudFront Security
Run-Script ".\finalize-s3-cloudfront.ps1" "Security Finalization"

# STEP 4: Validate CloudFront Distribution
Run-Script ".\finalize-cloudfront.ps1" "Distribution Validation"

Write-Log "🎯 Deployment pipeline completed successfully!" "Cyan"
}
catch {
Write-Log "⚠️ Error detected — initiating rollback..." "Red"
if (Test-Path ".\rollback-cloudfront.ps1") {
& ".\rollback-cloudfront.ps1"
Write-Log "Rollback executed successfully." "Green"
}
else {
Write-Log "⚠️ Rollback script missing — manual restore may be required." "Yellow"
}
}
finally {
Write-Log "=== MASTER IaC RUNNER ENDED ===`n" "Gray"
}