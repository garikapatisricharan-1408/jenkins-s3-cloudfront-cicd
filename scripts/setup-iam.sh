#!/bin/bash
###############################################################################
# setup-iam.sh — Bootstrap least-privilege IAM user for Jenkins
# Run ONCE before first deployment
# Author: Sri Charan Garikapati
###############################################################################

set -euo pipefail

PROJECT_NAME="${1:-frontend-app}"
S3_BUCKET="${2:-}"
CF_DIST_ARN="${3:-}"

if [[ -z "$S3_BUCKET" || -z "$CF_DIST_ARN" ]]; then
    echo "Usage: ./setup-iam.sh <project-name> <s3-bucket-name> <cloudfront-dist-arn>"
    exit 1
fi

IAM_USER="${PROJECT_NAME}-jenkins-deployer"

echo "🔐 Creating IAM user: ${IAM_USER}"
aws iam create-user --user-name "${IAM_USER}" --path "/ci/" || echo "User already exists"

echo "📋 Attaching least-privilege policy..."
aws iam put-user-policy \
    --user-name "${IAM_USER}" \
    --policy-name "${PROJECT_NAME}-deploy-policy" \
    --policy-document "{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Sid\": \"S3Deploy\",
                \"Effect\": \"Allow\",
                \"Action\": [\"s3:PutObject\",\"s3:GetObject\",\"s3:DeleteObject\",\"s3:ListBucket\"],
                \"Resource\": [\"arn:aws:s3:::${S3_BUCKET}\",\"arn:aws:s3:::${S3_BUCKET}/*\"]
            },
            {
                \"Sid\": \"CloudFrontInvalidate\",
                \"Effect\": \"Allow\",
                \"Action\": [\"cloudfront:CreateInvalidation\",\"cloudfront:GetInvalidation\",\"cloudfront:GetDistribution\"],
                \"Resource\": \"${CF_DIST_ARN}\"
            }
        ]
    }"

echo "🔑 Creating access keys..."
KEYS=$(aws iam create-access-key --user-name "${IAM_USER}")
ACCESS_KEY=$(echo "$KEYS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['AccessKey']['AccessKeyId'])")
SECRET_KEY=$(echo "$KEYS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['AccessKey']['SecretAccessKey'])")

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ IAM user created successfully"
echo "  Add these to Jenkins Credentials:"
echo ""
echo "  AWS_ACCESS_KEY_ID     = ${ACCESS_KEY}"
echo "  AWS_SECRET_ACCESS_KEY = ${SECRET_KEY}"
echo ""
echo "  ⚠️  Save the secret key now — it won't be shown again"
echo "═══════════════════════════════════════════════"
