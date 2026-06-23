#!/bin/bash
###############################################################################
# deploy.sh — Manual S3 deploy + CloudFront invalidation
# Used by Jenkins pipeline OR can be run standalone
# Author: Sri Charan Garikapati
###############################################################################

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────────────
S3_BUCKET="${S3_BUCKET_NAME:-}"
CF_DIST_ID="${CLOUDFRONT_DIST_ID:-}"
AWS_REGION="${AWS_DEFAULT_REGION:-ap-south-1}"
DIST_DIR="${1:-app/dist}"

# ── Validation ────────────────────────────────────────────────────────────────
if [[ -z "$S3_BUCKET" || -z "$CF_DIST_ID" ]]; then
    echo "❌ ERROR: S3_BUCKET_NAME and CLOUDFRONT_DIST_ID must be set as env vars"
    exit 1
fi

if [[ ! -d "$DIST_DIR" ]]; then
    echo "❌ ERROR: Build directory '$DIST_DIR' does not exist"
    echo "   Run 'npm run build' first"
    exit 1
fi

echo "═══════════════════════════════════════════════"
echo "  🚀 Deploying to AWS S3 + CloudFront"
echo "  Bucket  : s3://${S3_BUCKET}"
echo "  CF Dist : ${CF_DIST_ID}"
echo "  Region  : ${AWS_REGION}"
echo "  Source  : ${DIST_DIR}/"
echo "═══════════════════════════════════════════════"

# ── Step 1: Sync hashed assets (long cache) ───────────────────────────────────
echo ""
echo "📦 Step 1: Uploading hashed assets (JS, CSS, images)..."
aws s3 sync "${DIST_DIR}/" "s3://${S3_BUCKET}/" \
    --region "${AWS_REGION}" \
    --delete \
    --exclude "*.html" \
    --cache-control "public, max-age=31536000, immutable" \
    --sse AES256

echo "   ✅ Hashed assets uploaded"

# ── Step 2: Sync HTML files (short cache) ────────────────────────────────────
echo ""
echo "📄 Step 2: Uploading HTML files (short cache)..."
aws s3 sync "${DIST_DIR}/" "s3://${S3_BUCKET}/" \
    --region "${AWS_REGION}" \
    --exclude "*" \
    --include "*.html" \
    --cache-control "public, max-age=300, must-revalidate" \
    --sse AES256

echo "   ✅ HTML files uploaded"

# ── Step 3: CloudFront invalidation ──────────────────────────────────────────
echo ""
echo "🔄 Step 3: Invalidating CloudFront cache..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "${CF_DIST_ID}" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

echo "   Invalidation ID: ${INVALIDATION_ID}"
echo "   Waiting for completion (may take 1-3 minutes)..."

aws cloudfront wait invalidation-completed \
    --distribution-id "${CF_DIST_ID}" \
    --id "${INVALIDATION_ID}"

echo "   ✅ CloudFront cache invalidated"

# ── Step 4: Smoke test ────────────────────────────────────────────────────────
echo ""
echo "🧪 Step 4: Running smoke test..."
CF_DOMAIN=$(aws cloudfront get-distribution \
    --id "${CF_DIST_ID}" \
    --query 'Distribution.DomainName' \
    --output text)

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://${CF_DOMAIN}")

if [[ "$HTTP_STATUS" == "200" ]]; then
    echo "   ✅ Smoke test PASSED — HTTP $HTTP_STATUS"
else
    echo "   ⚠️  Smoke test returned HTTP $HTTP_STATUS"
fi

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ DEPLOYMENT COMPLETE"
echo "  URL: https://${CF_DOMAIN}"
echo "═══════════════════════════════════════════════"
