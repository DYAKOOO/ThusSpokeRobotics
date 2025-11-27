#!/bin/bash

# Cloud Run Deployment Script
# Usage: ./deploy.sh [IMAGE_TAG]

set -e

# Configuration
PROJECT_ID="neural-diwan-435305"
SERVICE_NAME="astro-blog"
REGION="us-central1"
IMAGE_TAG="${1:-latest}"
IMAGE="gcr.io/${PROJECT_ID}/${SERVICE_NAME}:${IMAGE_TAG}"

echo "============================================"
echo "Cloud Run Deployment Script"
echo "============================================"
echo "Project: ${PROJECT_ID}"
echo "Service: ${SERVICE_NAME}"
echo "Region: ${REGION}"
echo "Image: ${IMAGE}"
echo "============================================"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo "Error: Not authenticated with gcloud"
    echo "Run: gcloud auth login"
    exit 1
fi

# Set project
echo "Setting project..."
gcloud config set project ${PROJECT_ID}

# Enable Cloud Run API (idempotent)
echo "Enabling Cloud Run API..."
gcloud services enable run.googleapis.com --project=${PROJECT_ID}

# Deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --port 3000 \
  --cpu 1 \
  --memory 256Mi \
  --min-instances 0 \
  --max-instances 10 \
  --cpu-throttling \
  --timeout 60s \
  --project ${PROJECT_ID} \
  --quiet

# Get service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${PROJECT_ID} \
  --format 'value(status.url)')

echo "============================================"
echo "Deployment successful!"
echo "============================================"
echo "Service URL: ${SERVICE_URL}"
echo ""
echo "Test the deployment:"
echo "  curl -I ${SERVICE_URL}"
echo ""
echo "View logs:"
echo "  gcloud run services logs read ${SERVICE_NAME} --region ${REGION} --project ${PROJECT_ID}"
echo ""
echo "Map custom domain:"
echo "  gcloud run domain-mappings create --service ${SERVICE_NAME} --domain thusspokerobotics.xyz --region ${REGION} --project ${PROJECT_ID}"
echo "============================================"
