# Jenkins CI/CD Pipeline — AWS S3 + CloudFront + Security Hardening

![CI/CD](https://img.shields.io/badge/CI%2FCD-Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-S3%20%2B%20CloudFront-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![IaC](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Security](https://img.shields.io/badge/Security-IAM%20Hardened-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)

## 📌 Project Overview

End-to-end automated CI/CD pipeline for a React frontend application, deploying to **AWS S3** with **CloudFront CDN** for global content delivery. The pipeline is triggered on every Git push and delivers zero-touch continuous deployment with security hardening at every layer.

---

## 🏗️ Architecture Diagram

```
Developer Push (Git)
        │
        ▼
┌───────────────────┐
│   GitHub Webhook  │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Jenkins Pipeline  │
│  ┌─────────────┐  │
│  │ Checkout    │  │
│  │ Install     │  │
│  │ Build       │  │
│  │ Docker Build│  │
│  │ Test        │  │
│  │ S3 Deploy   │  │
│  │ CF Invalidate│ │
│  └─────────────┘  │
└───────────────────┘
         │
         ▼
┌───────────────────────────────────────────┐
│              AWS Cloud                     │
│  ┌───────────┐     ┌────────────────────┐ │
│  │  S3 Bucket│────▶│  CloudFront CDN    │ │
│  │ (Static   │     │  (Global Edge PoPs)│ │
│  │  Assets)  │     │  HTTPS + OAC       │ │
│  └───────────┘     └────────────────────┘ │
│  ┌───────────────────────────────────────┐│
│  │  IAM (Least Privilege + Role-Based)  ││
│  └───────────────────────────────────────┘│
└───────────────────────────────────────────┘
         │
         ▼
    End Users (HTTPS via CloudFront)
```

---

## 📁 Repository Structure

```
jenkins-s3-cloudfront-cicd/
├── Jenkinsfile                        # Main CI/CD pipeline definition
├── Dockerfile                         # Build environment containerization
├── docker-compose.yml                 # Local development stack
├── .dockerignore
├── terraform/
│   ├── main.tf                        # S3 + CloudFront + IAM resources
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf                     # Remote state (S3 backend)
├── jenkins/
│   ├── jenkins-setup.sh               # Jenkins + plugins installation
│   └── plugins.txt                    # Required Jenkins plugins list
├── scripts/
│   ├── deploy.sh                      # S3 sync + CloudFront invalidation
│   ├── setup-iam.sh                   # IAM role + policy bootstrap
│   └── cleanup.sh                     # Resource teardown script
├── app/
│   ├── src/
│   │   ├── index.html
│   │   ├── app.js
│   │   └── styles.css
│   └── public/
│       └── favicon.ico
└── .github/
    └── workflows/
        └── pr-checks.yml              # GitHub Actions PR validation
```

---

## 🚀 Tech Stack

| Category | Technology |
|---|---|
| CI/CD | Jenkins 2.x, GitHub Webhooks |
| Cloud | AWS S3, CloudFront, IAM, EC2 |
| IaC | Terraform >= 1.5 |
| Containerization | Docker |
| Security | IAM Least Privilege, OAC, HTTPS, Security Groups |
| Scripting | Bash, AWS CLI v2 |

---

## ⚙️ Prerequisites

- AWS Account with admin IAM access
- Jenkins server (EC2 t3.medium recommended)
- Terraform >= 1.5 installed
- Docker installed on Jenkins agent
- AWS CLI v2 configured
- GitHub repository with webhook access

---

## 🛠️ Setup Instructions

### Step 1 — Provision AWS Infrastructure (Terraform)

```bash
cd terraform/
terraform init
terraform plan -var="project_name=my-frontend" -var="environment=prod"
terraform apply -auto-approve
```

This provisions:
- S3 bucket (versioning + encryption enabled)
- CloudFront distribution with Origin Access Control (OAC)
- IAM role + policy for Jenkins deployment (least privilege)
- S3 bucket policy (CloudFront OAC only)

### Step 2 — Set Up Jenkins Server

```bash
chmod +x jenkins/jenkins-setup.sh
sudo ./jenkins/jenkins-setup.sh
```

### Step 3 — Configure Jenkins Credentials

In Jenkins → Manage Jenkins → Credentials → Global, add:
- `AWS_ACCESS_KEY_ID` — Secret Text
- `AWS_SECRET_ACCESS_KEY` — Secret Text
- `S3_BUCKET_NAME` — Secret Text
- `CLOUDFRONT_DISTRIBUTION_ID` — Secret Text
- `github-credentials` — Username/Password (GitHub token)

### Step 4 — Create Jenkins Pipeline Job

1. New Item → Pipeline
2. Pipeline → Pipeline script from SCM
3. SCM: Git → your repo URL
4. Branch: `*/main`
5. Script Path: `Jenkinsfile`
6. Add GitHub webhook: `http://<JENKINS_URL>/github-webhook/`

### Step 5 — Trigger First Build

```bash
git add .
git commit -m "feat: initial deployment"
git push origin main
```

Jenkins picks up the webhook → builds → deploys to S3 → invalidates CloudFront cache.

---

## 🔐 Security Hardening

### IAM Least Privilege
- Jenkins IAM user has **only** `s3:PutObject`, `s3:DeleteObject`, `s3:GetObject`, and `cloudfront:CreateInvalidation`
- No `s3:*` or `*` wildcards
- Scoped to specific S3 bucket ARN only

### CloudFront Origin Access Control (OAC)
- S3 bucket is **not** publicly accessible
- Only CloudFront can read from S3 via OAC
- All HTTP traffic auto-redirected to HTTPS

### EC2 Security Groups (Jenkins)
- Port 22 (SSH): Your IP only
- Port 8080 (Jenkins): Your IP only
- Port 443 (Outbound): Anywhere (for AWS API calls)

### S3 Bucket Hardening
- Public access block: **All enabled**
- Server-side encryption: AES-256
- Versioning: Enabled
- Lifecycle rules for old versions

---

## 📊 Pipeline Stages

| Stage | Action |
|---|---|
| **Checkout** | Pull latest code from GitHub |
| **Install Dependencies** | `npm install` inside Docker |
| **Build** | `npm run build` → generates `/dist` |
| **Docker Build** | Build containerized build env |
| **Security Scan** | Basic dependency audit |
| **Deploy to S3** | `aws s3 sync ./dist s3://$BUCKET` |
| **CloudFront Invalidate** | `aws cloudfront create-invalidation --paths "/*"` |
| **Notify** | Build status notification |

---

## 📈 Key Metrics Achieved

| Metric | Result |
|---|---|
| Deployment automation | ✅ 100% automated on git push |
| Manual deployment steps | Reduced to 0 |
| Global CDN edge PoPs | 400+ via CloudFront |
| Build environment consistency | 100% (Docker) |
| HTTPS enforcement | ✅ Enforced at CloudFront |
| S3 public access | ✅ Blocked (OAC only) |

---

## 🌍 Environment Variables

| Variable | Description | Where Set |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Jenkins IAM access key | Jenkins Credentials |
| `AWS_SECRET_ACCESS_KEY` | Jenkins IAM secret | Jenkins Credentials |
| `S3_BUCKET_NAME` | Target S3 bucket | Jenkins Credentials |
| `CLOUDFRONT_DISTRIBUTION_ID` | CF dist ID for invalidation | Jenkins Credentials |
| `AWS_DEFAULT_REGION` | AWS region | Jenkinsfile env block |

---

## 🧹 Cleanup

```bash
# Destroy all AWS resources
cd terraform/
terraform destroy -auto-approve

# Or use cleanup script
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

---

## 👤 Author

**Sri Charan Garikapati**  
DevOps Engineer | AWS Certified Cloud Practitioner  
📧 garikapatisricharan@gmail.com  
🔗 [LinkedIn](https://linkedin.com/in/Sricharan36) | [GitHub](https://github.com/garikapatisricharan-1408)
