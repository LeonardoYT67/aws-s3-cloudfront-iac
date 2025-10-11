<#
.SYNOPSIS
  Idempotent + Rollback-Safe CloudFront Deployment for Ayush S3 Static Site

.DESCRIPTION
  - Checks if CloudFront distribution already exists (by Comment)
  - Reuses existing OAC or creates new one
  - Automatically backs up the current CloudFront configuration before any new deployment
  - Creates new CloudFront distribution only if none exists
  - Safe to re-run anytime (idempotent)
#>

# ==== CONFIGURATION ====
$BucketName = "ayush-sre-static-site-test-again"
$CommentTag = "Secure CloudFront distribution for Ayush static site"
$Region = "us-east-1"
$OACName = "Ayush-OAC"
$OutputConfig = ".\cf-config-final.json"
$BackupDir = ".\backups"

# ==== CREATE BACKUP DIRECTORY ====
if (-not (Test-Path $BackupDir)) {
    New-Item -Path $BackupDir -ItemType Directory | Out-Null
}

Write-Host "`n=== Starting CloudFront Deployment (Idempotent + Rollback Safe) ===" -ForegroundColor Cyan

# ==== STEP 1: Detect Existing CloudFront Distribution ====
Write-Host "Checking if CloudFront distribution already exists for: $BucketName ..." -ForegroundColor Yellow

$existingDistId = aws cloudfront list-distributions `
    --query "DistributionList.Items[?Comment=='$CommentTag'].Id" `
    --output text 2>$null

if ($existingDistId -and $existingDistId -ne "None") {
    Write-Host "`n✅ Found existing CloudFront distribution: $existingDistId" -ForegroundColor Green
    $domainName = aws cloudfront get-distribution --id $existingDistId --query "Distribution.DomainName" --output text

    # ==== BACKUP CURRENT CONFIG ====
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = "$BackupDir\cloudfront-backup-$($existingDistId)-$timestamp.json"
    aws cloudfront get-distribution-config --id $existingDistId --output json | Out-File $backupFile -Encoding utf8
    Write-Host "💾 Backup created: $backupFile" -ForegroundColor Yellow

    Write-Host "`n💡 Reusing existing CloudFront distribution (idempotent)." -ForegroundColor Cyan
    Write-Host "Access via: https://$domainName" -ForegroundColor Green
    exit 0
}

Write-Host "`nNo existing distribution found. Proceeding to create a new one..." -ForegroundColor Cyan

# ==== STEP 2: Get or Create Origin Access Control ====
$oacId = aws cloudfront list-origin-access-controls `
    --query "OriginAccessControlList.Items[?Name=='$OACName'].Id" --output text 2>$null

if (-not $oacId -or $oacId -eq "None") {
    Write-Host "`nCreating new Origin Access Control..." -ForegroundColor Cyan
    $oacId = aws cloudfront create-origin-access-control `
        --origin-access-control-config "{
            \"Name\": \"$OACName\",
            \"Description\": \"Access control for Ayush static site\",
            \"SigningProtocol\": \"sigv4\",
            \"SigningBehavior\": \"always\",
            \"OriginAccessControlOriginType\": \"s3\"
        }" `
        --query "OriginAccessControl.Id" --output text
    Write-Host "✅ Created new OAC: $oacId" -ForegroundColor Green
} else {
    Write-Host "✅ Reusing existing OAC: $oacId" -ForegroundColor Green
}

# ==== STEP 3: Create CloudFront Distribution Config ====
$bucketDomain = "$BucketName.s3.$Region.amazonaws.com"
Write-Host "`nBuilding CloudFront configuration for bucket: $bucketDomain" -ForegroundColor Yellow

@"
{
  "CallerReference": "$(Get-Date -Format yyyyMMddHHmmss)",
  "Comment": "$CommentTag",
  "Enabled": true,
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$BucketName",
        "DomainName": "$bucketDomain",
        "S3OriginConfig": { "OriginAccessIdentity": "" },
        "OriginAccessControlId": "$oacId"
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BucketName",
    "ViewerProtocolPolicy": "redirect-to-https",
    "TrustedSigners": { "Enabled": false, "Quantity": 0 },
    "TrustedKeyGroups": { "Enabled": false, "Quantity": 0 },
    "ForwardedValues": { "QueryString": false, "Cookies": { "Forward": "none" } },
    "DefaultTTL": 3600,
    "MinTTL": 0,
    "MaxTTL": 86400
  },
  "PriceClass": "PriceClass_All",
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true,
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "HttpVersion": "http2",
  "IsIPV6Enabled": true
}
"@ | Out-File $OutputConfig -Encoding utf8

# ==== STEP 4: Create CloudFront Distribution ====
Write-Host "`nCreating new CloudFront distribution..." -ForegroundColor Cyan
$distId = aws cloudfront create-distribution `
    --distribution-config file://$OutputConfig `
    --query "Distribution.Id" --output text

if ($distId) {
    $domain = aws cloudfront get-distribution --id $distId --query "Distribution.DomainName" --output text
    Write-Host "`n✅ CloudFront Distribution Created Successfully!" -ForegroundColor Green
    Write-Host "Distribution ID: $distId" -ForegroundColor Yellow
    Write-Host "Access via: https://$domain" -ForegroundColor Cyan
} else {
    Write-Host "❌ Failed to create CloudFront distribution." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green