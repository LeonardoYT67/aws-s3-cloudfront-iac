# =============================================
# Route53 + ACM Deployment (Stable Windows PowerShell Version)
# =============================================

$Region = "us-east-1"
$HostedZoneName = "ayush.internal"
$RecordName = "site"
$DistributionId = "E1DZ0BU4N0SWJ0"
$VPCId = "vpc-0262ff2fc46eed126"

Write-Host "Using VPC ID: $VPCId in $Region ..."
Write-Host "Starting Route53 + ACM setup for $HostedZoneName ..."

# Step 1: Create Private Hosted Zone
try {
    $zoneExists = aws route53 list-hosted-zones-by-name --dns-name $HostedZoneName --query "HostedZones[?Name=='$HostedZoneName.'] | [0].Id" --output text
    if ($zoneExists -and $zoneExists -ne "None" -and $zoneExists -ne "") {
        Write-Host "Hosted zone already exists: $HostedZoneName"
        $HostedZoneId = $zoneExists
    } else {
        $HostedZoneId = (aws route53 create-hosted-zone `
            --name $HostedZoneName `
            --caller-reference (Get-Date).Ticks `
            --hosted-zone-config Comment="Private hosted zone for $HostedZoneName",PrivateZone=true `
            --vpc VPCRegion=$Region,VPCId=$VPCId `
            --query 'HostedZone.Id' `
            --output text)
        Write-Host "Created private hosted zone: $HostedZoneName ($HostedZoneId)"
    }
} catch {
    Write-Host "Error creating hosted zone. Check VPC ID and IAM permissions."
    exit
}

# Step 2: Request ACM Certificate
$DomainName = "$RecordName.$HostedZoneName"
Write-Host "Requesting ACM certificate for $DomainName ..."
$CertArn = aws acm request-certificate --domain-name $DomainName --validation-method DNS --region $Region --query CertificateArn --output text
Write-Host "Certificate requested. ARN: $CertArn"

# Step 3: Create DNS Validation Record
Write-Host "Fetching DNS validation record details..."
Start-Sleep -Seconds 5
$ValidationRecord = aws acm describe-certificate --certificate-arn $CertArn --region $Region --query "Certificate.DomainValidationOptions[0].ResourceRecord" --output json | ConvertFrom-Json
$RecordNameFQDN = $ValidationRecord.Name
$RecordValue = $ValidationRecord.Value

$ChangeBatch = @{
    "Changes" = @(
        @{
            "Action" = "UPSERT"
            "ResourceRecordSet" = @{
                "Name" = $RecordNameFQDN
                "Type" = "CNAME"
                "TTL" = 300
                "ResourceRecords" = @(@{"Value" = $RecordValue})
            }
        }
    )
}

$ChangeBatch | ConvertTo-Json -Depth 10 | Out-File change-batch.json -Encoding utf8
aws route53 change-resource-record-sets --hosted-zone-id $HostedZoneId --change-batch file://change-batch.json | Out-Null
Write-Host "Validation CNAME record created successfully."

# Step 4: Wait for certificate validation
Write-Host "Waiting for ACM certificate validation (may take a few minutes)..."
aws acm wait certificate-validated --certificate-arn $CertArn --region $Region
Write-Host "Certificate validated successfully."

# Step 5: Attach ACM Certificate to CloudFront (PowerShell 5.1 compatible)
Write-Host "Attaching certificate to CloudFront distribution ($DistributionId)..."

# Fetch config and ETag
$distResponse = aws cloudfront get-distribution-config --id $DistributionId --output json | ConvertFrom-Json
$etag = $distResponse.ETag
$distConfig = $distResponse.DistributionConfig

# Rebuild ViewerCertificate section (overwrite existing one safely)
$viewerCert = New-Object PSObject
Add-Member -InputObject $viewerCert -MemberType NoteProperty -Name "ACMCertificateArn" -Value $CertArn
Add-Member -InputObject $viewerCert -MemberType NoteProperty -Name "SSLSupportMethod" -Value "sni-only"
Add-Member -InputObject $viewerCert -MemberType NoteProperty -Name "MinimumProtocolVersion" -Value "TLSv1.2_2021"
Add-Member -InputObject $viewerCert -MemberType NoteProperty -Name "CertificateSource" -Value "acm"

# Attach to config
$distConfig | Add-Member -MemberType NoteProperty -Name "ViewerCertificate" -Value $viewerCert -Force

# Write config to JSON
$distConfig | ConvertTo-Json -Depth 20 | Out-File cf-dist-config.json -Encoding utf8

# Apply the updated config to CloudFront
aws cloudfront update-distribution --id $DistributionId --if-match $etag --distribution-config file://cf-dist-config.json

Write-Host "✅ HTTPS configuration completed successfully!" -ForegroundColor Green