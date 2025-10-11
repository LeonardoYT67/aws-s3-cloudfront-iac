Write-Host "=== Finalizing S3 Bucket Policy for CloudFront ===" -ForegroundColor Cyan

# Variables
$BucketName = "ayush-sre-static-site"
$DistId = "E1DZ0BU4N0SWJ0"

# Remove Public Access Block
aws s3api delete-public-access-block --bucket $BucketName | Out-Null
Write-Host "Removed Public Access Block on $BucketName" -ForegroundColor Yellow

# Fetch AWS Account ID
$AccountId = (aws sts get-caller-identity --query "Account" --output text)
Write-Host "Using Account ID: $AccountId" -ForegroundColor Yellow

# Load JSON policy template and replace tokens
$template = Get-Content ".\s3-policy-template.json" -Raw
$template = $template.Replace("ACCOUNT_ID", $AccountId)
$template = $template.Replace("BUCKET_NAME", $BucketName)
$template = $template.Replace("DISTRIBUTION_ID", $DistId)

# Save final JSON policy
$template | Out-File -FilePath ".\s3-policy.json" -Encoding utf8
Write-Host "Created JSON policy at: $(Resolve-Path .\s3-policy.json)" -ForegroundColor Yellow

# Validate JSON syntax before applying
try {
    $null = $template | ConvertFrom-Json
    Write-Host "JSON validation successful." -ForegroundColor Green
} catch {
    Write-Host "❌ JSON is invalid! Please check syntax." -ForegroundColor Red
    exit 1
}

# Apply the S3 bucket policy
aws s3api put-bucket-policy --bucket $BucketName --policy file://s3-policy.json
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ S3 bucket policy applied successfully." -ForegroundColor Green
} else {
    Write-Host "❌ Failed to apply bucket policy. Check CloudFront OAC or JSON syntax." -ForegroundColor Red
}