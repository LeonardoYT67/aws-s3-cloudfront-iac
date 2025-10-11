<#
.SYNOPSIS
  Fixes CloudFront distribution origin if it still points to an old S3 bucket.

.DESCRIPTION
  Compares CloudFront's current origin domain name with the expected S3 bucket domain.
  If mismatch detected, updates the distribution with correct bucket (preserving all OAC and SSL settings).
#>

# ==== CONFIGURATION ====
$DistributionId = "E1DZ0BU4N0SWJ0"                   # Your CloudFront Distribution ID
$ExpectedBucket = "ayush-sre-static-site-test-again"  # The correct S3 bucket
$Region = "us-east-1"

# ==== STEP 1: Fetch Distribution Config ====
Write-Host "`n=== Checking CloudFront Origin Configuration ===" -ForegroundColor Cyan

$configFile = "cf-config-temp.json"
$etag = aws cloudfront get-distribution-config --id $DistributionId --query "ETag" --output text 2>$null
if (-not $etag) {
    Write-Host "❌ Could not retrieve CloudFront config. Check AWS CLI credentials or Distribution ID." -ForegroundColor Red
    exit
}

aws cloudfront get-distribution-config --id $DistributionId --query "DistributionConfig" --output json > $configFile

# ==== STEP 2: Read and Inspect Config ====
$config = Get-Content $configFile -Raw | ConvertFrom-Json
$currentOrigin = $config.Origins.Items[0].DomainName

Write-Host "`nCurrent Origin Domain:" -ForegroundColor Yellow
Write-Host "  $currentOrigin"

# ==== STEP 3: Compare and Fix ====
$expectedDomain = "$ExpectedBucket.s3.$Region.amazonaws.com"

if ($currentOrigin -eq $expectedDomain) {
    Write-Host "`n✅ CloudFront already points to the correct bucket: $expectedDomain" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Mismatch detected. Updating CloudFront origin..." -ForegroundColor Red

    # Update origin domain
    $config.Origins.Items[0].DomainName = $expectedDomain

    # Save updated config
    $config | ConvertTo-Json -Depth 20 | Out-File $configFile -Encoding utf8

    # Push update back to CloudFront
    aws cloudfront update-distribution `
        --id $DistributionId `
        --distribution-config file://$configFile `
        --if-match $etag | Out-Null

    Write-Host "`n✅ CloudFront origin successfully updated to: $expectedDomain" -ForegroundColor Green
}

# ==== STEP 4: Verification ====
Start-Sleep -Seconds 5
$verify = aws cloudfront get-distribution --id $DistributionId --query "Distribution.DistributionConfig.Origins.Items[0].DomainName" --output text
Write-Host "`n=== Verification ===" -ForegroundColor Cyan
Write-Host "CloudFront is now serving from: $verify" -ForegroundColor Green

if ($verify -match $ExpectedBucket) {
    Write-Host "`n🎉 Deployment origin verified and corrected successfully." -ForegroundColor Green
} else {
    Write-Host "`n❌ Origin update failed. Please review cf-config-temp.json manually." -ForegroundColor Red
}