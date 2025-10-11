# 🧠 AWS S3 + CloudFront IaC Automation (PowerShell Masterpiece)
**_By Ayush Sharma_**

> 🚀 Automated, Idempotent, and Rollback-Safe Cloud Infrastructure-as-Code for AWS S3 + CloudFront.  
> ⚙️ Fully scripted static website deployment with OAC security, verification, and lifecycle automation.  
> 💪 Designed, debugged, and built end-to-end by Ayush Sharma over a 14-hour DevOps engineering sprint.

---

### 🗺️ Project Overview
This project provisions and secures a **static website hosted on Amazon S3** and distributed globally via **Amazon CloudFront** — all through **PowerShell IaC (Infrastructure as Code)**.

It includes idempotent re-runs, rollback safety, OAC (Origin Access Control) security, and validation stages — no console clicks, purely automated.

---

### 🏗️ Architecture Flow

```text
                ┌────────────────────────────────┐
                │      PowerShell IaC Runner      │
                │ (1-create → deploy → finalize)  │
                └────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │      Amazon S3 (Private)       │
              │ - Static site files (HTML/CSS) │
              │ - Bucket policy via JSON IaC   │
              └───────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │    CloudFront Distribution     │
              │ - Origin Access Control (OAC)  │
              │ - TLSv1 / HTTPS enforced       │
              │ - Global CDN delivery          │
              └───────────────────────────────┘
                              │
                              ▼
                     🌐 Public Access via
               `https://d14k2bh2uqehcb.cloudfront.net`
```

---

### 📂 Repository Structure

```
aws-s3-cloudfront-iac/
├── 1-create-s3.ps1
├── deploy-cloudfront.ps1
├── finalize-s3-cloudfront.ps1
├── finalize-cloudfront.ps1
├── master-iac-runner.ps1
├── s3-policy.json
├── cf-config-final.json
├── backups/
│   └── cloudfront-backup-*.json
└── images/
    ├── s3-policy-proof.png
    ├── cloudfront-success.png
    ├── browser-success.png
    └── forbidden-error.png
```

---

## ⚙️ IaC Scripts & Their Roles

| Stage | Script | Description | Idempotency | Rollback |
|-------|---------|-------------|--------------|-----------|
| 1️⃣ | **1-create-s3.ps1** | Creates/validates S3 bucket, configures static website, uploads HTML files. | ✅ Yes | 🟡 Manual (safe re-run) |
| 2️⃣ | **deploy-cloudfront.ps1** | Deploys or updates CloudFront distribution with OAC & HTTPS. | ✅ Yes | ✅ Backup-based |
| 3️⃣ | **finalize-s3-cloudfront.ps1** | Locks S3 policy to CloudFront-only access, removes public ACLs. | ✅ Yes | ⚙️ Auto-restores |
| 4️⃣ | **finalize-cloudfront.ps1** | Verifies deployment, clears cache, checks distribution URL. | ✅ Yes | – |
| 5️⃣ | **master-iac-runner.ps1** | One-command orchestrator; runs all above scripts with backup checkpoints. | 🚧 WIP | ✅ Full rollback chain |

---

## 🧩 Expected Outputs (Proof)

### 🪣 Step 1 – S3 Bucket Policy Configuration

```powershell
aws s3api put-bucket-policy --bucket ayush-sre-static-site `
--policy file://$env:USERPROFILE\aws-s3-cloudfront-iac\s3-policy.json
```

✅ *S3 bucket policy applied successfully*  
✅ *Static website configured (index.html, error.html)*

![S3 Policy Applied Proof](images/s3-policy-proof.png)

---

### 🌍 Step 2 – CloudFront Deployment

```powershell
PS> .\deploy-cloudfront.ps1
== Starting CloudFront Deployment (Idempotent + Rollback Safe) ==
CloudFront distribution updated with new OAC.
Updated bucket policy for CloudFront OAC access.
Access via: https://d14k2bh2uqehcb.cloudfront.net
```

✅ *Idempotent re-run safe*  
✅ *OAC applied, HTTPS enforced, PriceClass_All enabled*  

![CloudFront Deployment Success](images/cloudfront-success.png)

---

### ✅ Step 3 – Final Verification

Browser test (CloudFront endpoint):  
> https://d14k2bh2uqehcb.cloudfront.net/index.html

Expected output:
```
Ayush S3 Static Site
Deployed via AWS CLI (IaC Script)
```

![Browser Verification](images/browser-success.png)

---

## 🧱 Master Orchestrator (IaC Runner)

> **Script:** `master-iac-runner.ps1`  
> **Purpose:** One-command, full-stack deployer.  
> It executes all stages, takes backups, and performs rollback if any step fails.

Example output:
```powershell
=== MASTER IaC RUNNER STARTED ===
[2025-10-12 00:15:42] Running: 1-create-s3.ps1
[2025-10-12 00:20:11] Running: deploy-cloudfront.ps1
[2025-10-12 00:23:07] Running: finalize-s3-cloudfront.ps1
🎯 Deployment pipeline completed successfully!
=== MASTER IaC RUNNER ENDED ===
```

> 🧩 _If any step fails, the runner restores the previous CloudFront config from `/backups/` automatically._

---

## 🧰 Troubleshooting Journey (Real-World Debugs)

| Issue | Root Cause | Resolution |
|-------|-------------|-------------|
| ❌ **MalformedPolicy (PutBucketPolicy)** | JSON file contained BOM/invalid formatting | Converted via `ConvertTo-Json` and validated via `Get-Content -Raw` |
| ❌ **403 Forbidden (AccessDenied)** | Bucket wasn’t public; OAC yet to apply | Applied OAC-based access and re-deployed |
| ⚠️ **PowerShell Parsing Errors** | Missing closing braces and comment mismatch in master runner | Added structured `{}` and fixed comment block delimiters |
| ✅ **Final State** | Fully automated, HTTPS-enabled CloudFront distribution | Verified live URL & working website |

![403 Forbidden Debug](images/forbidden-error.png)

---

## 🔒 Security Highlights

- S3 bucket remains **private** — accessible **only through CloudFront OAC**.  
- **Public Access Block** enforced after deployment.  
- HTTPS only (`MinimumProtocolVersion: TLSv1`).  
- Supports **idempotent re-deployments** (no duplication).  
- Auto-backup of CloudFront configurations pre-deployment.  

---

## 🧾 Logs & Audit

All script executions append to:
```
iac-runner-log.txt
```
Each entry is timestamped with `yyyy-MM-dd HH:mm:ss`, ensuring audit traceability across stages.

---

## 🧩 Lessons & Takeaways

> “Automation isn’t about writing scripts — it’s about designing safety, repeatability, and trust into infrastructure.”

✅ You built a **secure, repeatable, AWS static hosting pipeline**  
✅ You implemented **Infrastructure-as-Code best practices**  
✅ You achieved **error recovery and rollback safety**

This project stands as a **DevOps-grade IaC showcase**, both technically and narratively.

---

## 📜 Author

**Ayush Sharma**  
AWS + DevOps Engineer | Cloud Automation Enthusiast  
📍 India  
💬 _“One .ps1 to rule them all.”_  
