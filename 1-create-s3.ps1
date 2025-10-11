# =====================================================================
# AWS S3 Static Website Creation Script
# Author: Ayush Sharma
# Purpose: Create and configure S3 bucket for static website hosting
# =====================================================================

# Variables
$BucketName = "ayush-sre-static-site-test-again"
$Region = "us-east-1"
$LocalSitePath = "C:\aws-static-site"   # Folder containing index.html & error.html

Write-Host "=== STEP 1: Creating S3 Bucket ($BucketName) ===" -ForegroundColor Cyan
if ($Region -eq "us-east-1") {
    aws s3api create-bucket --bucket $BucketName --region $Region
} else {
    aws s3api create-bucket --bucket $BucketName --region $Region --create-bucket-configuration LocationConstraint=$Region
}

Write-Host "Bucket created successfully." -ForegroundColor Green

# Optional: Disable public access block for initial upload
Write-Host "Disabling public access block temporarily..." -ForegroundColor Yellow
aws s3api delete-public-access-block --bucket $BucketName

# Upload website files
Write-Host "Uploading website files from $LocalSitePath..." -ForegroundColor Cyan
aws s3 sync $LocalSitePath s3://$BucketName --acl public-read

Write-Host "Upload complete." -ForegroundColor Green

# Enable static website hosting
Write-Host "Enabling static website hosting..." -ForegroundColor Cyan
aws s3 website s3://$BucketName --index-document index.html --error-document error.html

# Display Website URL
$WebsiteURL = "http://$BucketName.s3-website-$Region.amazonaws.com"
Write-Host "✅ Static website hosted successfully: $WebsiteURL" -ForegroundColor Green

# Re-enable block public access for security before CloudFront setup
Write-Host "Re-enabling public access block for best practice..." -ForegroundColor Yellow
aws s3api put-public-access-block --bucket $BucketName --public-access-block-configuration '{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}'
Write-Host "✅ Public access block restored." -ForegroundColor Green

Write-Host "=== S3 Creation Complete ===" -ForegroundColor Cyan