#!/bin/bash

# Cloud Run Rollback Script
# Usage: ./rollback.sh [REVISION_NAME]

set -e

# Configuration
PROJECT_ID="neural-diwan-435305"
SERVICE_NAME="astro-blog"
REGION="us-central1"
REVISION="${1}"

echo "============================================"
echo "Cloud Run Rollback Script"
echo "============================================"

# List available revisions
echo "Available revisions:"
echo ""
gcloud run revisions list \
  --service ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${PROJECT_ID} \
  --format "table(metadata.name,status.conditions[0].status,metadata.creationTimestamp)"

echo ""

# If no revision specified, prompt user
if [ -z "${REVISION}" ]; then
    echo "Usage: $0 [REVISION_NAME]"
    echo ""
    echo "Example:"
    echo "  $0 astro-blog-00001-abc"
    exit 1
fi

# Confirm rollback
echo "You are about to rollback to revision: ${REVISION}"
read -p "Are you sure? (yes/no): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
    echo "Rollback cancelled."
    exit 0
fi

# Perform rollback
echo "Rolling back to ${REVISION}..."
gcloud run services update-traffic ${SERVICE_NAME} \
  --to-revisions ${REVISION}=100 \
  --region ${REGION} \
  --project ${PROJECT_ID}

echo "============================================"
echo "Rollback successful!"
echo "============================================"
echo ""
echo "Current traffic allocation:"
gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${PROJECT_ID} \
  --format "table(spec.traffic[].revisionName,spec.traffic[].percent)"

echo ""
echo "View logs:"
echo "  gcloud run services logs read ${SERVICE_NAME} --region ${REGION} --project ${PROJECT_ID}"
echo "============================================"
