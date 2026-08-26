#!/usr/bin/env bash
# Deploy docs/ to S3 + invalidate CloudFront.
# Site: https://shadowplayer.liuyang19900520.com
set -euo pipefail

BUCKET="shadowplayer.liuyang19900520.com"
DIST_ID="EOJATFWF8U3SJ"
DIR="$(cd "$(dirname "$0")/../docs" && pwd)"

echo "Uploading $DIR -> s3://$BUCKET"
aws s3 sync "$DIR" "s3://$BUCKET" \
  --delete \
  --exclude ".*" \
  --content-type "text/html; charset=utf-8" \
  --cache-control "public,max-age=300"

echo "Invalidating CloudFront cache"
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "/*" \
  --query 'Invalidation.Status' --output text

echo "Done: https://shadowplayer.liuyang19900520.com"
