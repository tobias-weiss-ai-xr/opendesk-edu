#!/bin/bash
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Setup SeaweedFS S3 buckets for integration with XWiki and Stalwart
# Prerequisites: SeaweedFS S3 credentials (access key + secret key)
#
# Usage: ./setup-seaweedfs-buckets.sh <access-key> <secret-key>
#   or:  source .env && ./setup-seaweedfs-buckets.sh

set -euo pipefail

ACCESS_KEY="${1:-${SEAWEEDFS_ACCESS_KEY:-}}"
SECRET_KEY="${2:-${SEAWEEDFS_SECRET_KEY:-}}"
S3_ENDPOINT="http://seaweedfs-all-in-one.opendesk.svc.cluster.local:8333"

if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
  echo "Usage: $0 <access-key> <secret-key>"
  echo "Or set SEAWEEDFS_ACCESS_KEY and SEAWEEDFS_SECRET_KEY env vars"
  exit 1
fi

# Alias for s3 client
S3="aws --endpoint-url $S3_ENDPATH"

echo "=== Setting up SeaweedFS S3 buckets ==="
echo ""

# Create bucket for XWiki attachments
echo "Creating bucket: xwiki-attachments"
$S3 s3 mb s3://xwiki-attachments 2>/dev/null && echo "  ✅ Created" || echo "  ⚠️  Already exists or failed"

# Create bucket for Stalwart mail blobs
echo "Creating bucket: stalwart-blobs"
$S3 s3 mb s3://stalwart-blobs 2>/dev/null && echo "  ✅ Created" || echo "  ⚠️  Already exists or failed"

echo ""
echo "=== Buckets created ==="
$S3 s3 ls

echo ""
echo "=== Next Steps ==="
echo ""
echo "1. XWiki S3 Attachment Storage:"
echo "   Install 'attachment-storage-s3' extension in XWiki → Admin → Extensions"
echo "   Then uncomment the s3 config in opendesk/helmfile/apps/xwiki/values.yaml.gotmpl"
echo ""
echo "2. Stalwart S3 Blob Storage:"
echo "   Set in opendesk-edu/helmfile/apps/edu/stalwart/values.yaml.gotmpl:"
echo "   stalwart:"
echo "     storage:"
echo "       blob:"
echo "         type: s3"
echo "         s3:"
echo "           bucket: stalwart-blobs"
echo "           endpoint: $S3_ENDPOINT"
echo "           accessKey: $ACCESS_KEY"
echo "           secretKey: $SECRET_KEY"
echo ""
echo "3. Then run: helmfile --environment edu sync"
