# Cloud Run Migration Guide

## Overview

Migrate your ThusSpokeRobotics blog from GKE to Cloud Run with minimal downtime and 90% cost reduction.

**Estimated time**: 30 minutes
**Downtime**: <5 minutes (DNS propagation)
**Cost**: $1-10/month (vs current $115-135/month)

---

## Prerequisites

1. **gcloud CLI** installed and authenticated
2. **Docker** installed locally (optional, for testing)
3. **GCP Project**: neural-diwan-435305
4. **Current container**: gcr.io/neural-diwan-435305/astro-blog:v1.0.0
5. **Domain**: thusspokerobotics.xyz

---

## Step-by-Step Migration

### Step 1: Enable Cloud Run API

```bash
gcloud services enable run.googleapis.com --project=neural-diwan-435305
```

### Step 2: Deploy to Cloud Run

```bash
# Deploy your existing container to Cloud Run
gcloud run deploy astro-blog \
  --image gcr.io/neural-diwan-435305/astro-blog:v1.0.0 \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000 \
  --cpu 1 \
  --memory 256Mi \
  --min-instances 0 \
  --max-instances 10 \
  --cpu-throttling \
  --project neural-diwan-435305
```

**Parameters explained:**
- `--port 3000`: Your Astro blog listens on port 3000
- `--cpu 1`: 1 vCPU (sufficient for static site)
- `--memory 256Mi`: 256MB RAM (more than current 128Mi for safety)
- `--min-instances 0`: Scale to zero (save money)
- `--max-instances 10`: Cap for cost control
- `--cpu-throttling`: Reduce cost when idle
- `--allow-unauthenticated`: Public website

**Output:**
```
Service [astro-blog] revision [astro-blog-00001-xyz] has been deployed
and is serving 100 percent of traffic.
Service URL: https://astro-blog-xxxxxxxxxx-uc.a.run.app
```

### Step 3: Test the Deployment

```bash
# Get the Cloud Run service URL
SERVICE_URL=$(gcloud run services describe astro-blog \
  --region us-central1 \
  --project neural-diwan-435305 \
  --format 'value(status.url)')

echo "Service URL: $SERVICE_URL"

# Test the endpoint
curl -I $SERVICE_URL
```

Open the URL in your browser and verify the blog loads correctly.

### Step 4: Map Custom Domain

#### Option A: Using Cloud Run Domain Mappings (Recommended)

```bash
# Map your domain to Cloud Run
gcloud run domain-mappings create \
  --service astro-blog \
  --domain thusspokerobotics.xyz \
  --region us-central1 \
  --project neural-diwan-435305

# Also map www subdomain
gcloud run domain-mappings create \
  --service astro-blog \
  --domain www.thusspokerobotics.xyz \
  --region us-central1 \
  --project neural-diwan-435305
```

**This will output DNS records you need to add:**
```
Please add the following DNS records to your domain:
  TYPE  NAME                    DATA
  A     thusspokerobotics.xyz  216.239.32.21
  A     thusspokerobotics.xyz  216.239.34.21
  A     thusspokerobotics.xyz  216.239.36.21
  A     thusspokerobotics.xyz  216.239.38.21
  AAAA  thusspokerobotics.xyz  2001:4860:4802:32::15
  AAAA  thusspokerobotics.xyz  2001:4860:4802:34::15
  AAAA  thusspokerobotics.xyz  2001:4860:4802:36::15
  AAAA  thusspokerobotics.xyz  2001:4860:4802:38::15
```

#### Update DNS Records

Go to your DNS provider and:
1. **Delete** the current A record pointing to 34.31.187.182
2. **Add** the A records provided by Cloud Run
3. **Add** the AAAA records (IPv6) provided by Cloud Run
4. Do the same for www.thusspokerobotics.xyz

**DNS Propagation**: 5-30 minutes

### Step 5: Verify SSL Certificate

Cloud Run automatically provisions SSL certificates for your custom domain.

```bash
# Check domain mapping status
gcloud run domain-mappings describe \
  --domain thusspokerobotics.xyz \
  --region us-central1 \
  --project neural-diwan-435305
```

Wait until status shows `Active` and certificate is `Ready`.

### Step 6: Test Production Domain

```bash
# Test once DNS propagates
curl -I https://thusspokerobotics.xyz
curl -I https://www.thusspokerobotics.xyz
```

Both should return `200 OK` with `server: Google Frontend`.

### Step 7: Update CI/CD

Update your GitHub Actions workflow to deploy to Cloud Run instead of GKE.

Replace the deployment step in `.github/workflows/main.yaml`:

```yaml
# Old GKE deployment (remove this)
# - name: Deploy to GKE
#   run: |
#     kubectl apply -f deployment/

# New Cloud Run deployment (add this)
- name: Deploy to Cloud Run
  run: |
    gcloud run deploy astro-blog \
      --image gcr.io/neural-diwan-435305/astro-blog:${{ github.sha }} \
      --platform managed \
      --region us-central1 \
      --project neural-diwan-435305
```

See `cloud-run-deploy.yaml` for a complete example.

### Step 8: Monitor in Production

```bash
# View logs
gcloud run services logs read astro-blog \
  --region us-central1 \
  --project neural-diwan-435305 \
  --limit 50

# View metrics (Cloud Console)
# Go to: https://console.cloud.google.com/run/detail/us-central1/astro-blog/metrics
```

### Step 9: Cleanup GKE (After Verification)

**Wait 1-7 days** to ensure everything works, then delete GKE resources:

```bash
# List your clusters
gcloud container clusters list --project neural-diwan-435305

# Delete the cluster (THIS IS IRREVERSIBLE)
gcloud container clusters delete [CLUSTER_NAME] \
  --region [REGION] \
  --project neural-diwan-435305

# Release the static IP (if you want to delete it)
gcloud compute addresses delete astro-blog-ip \
  --region [REGION] \
  --project neural-diwan-435305
```

**Estimated savings**: ~$105-125/month

---

## Advanced Configuration

### Environment Variables

```bash
# Add environment variables
gcloud run services update astro-blog \
  --set-env-vars "NODE_ENV=production,LOG_LEVEL=info" \
  --region us-central1 \
  --project neural-diwan-435305
```

### Secrets (if needed later)

```bash
# Create a secret
echo -n "my-secret-value" | gcloud secrets create my-secret --data-file=- --project neural-diwan-435305

# Mount secret to Cloud Run
gcloud run services update astro-blog \
  --update-secrets MY_SECRET=my-secret:latest \
  --region us-central1 \
  --project neural-diwan-435305
```

### Traffic Splitting (Blue/Green Deployments)

```bash
# Deploy new revision without traffic
gcloud run deploy astro-blog \
  --image gcr.io/neural-diwan-435305/astro-blog:v2.0.0 \
  --no-traffic \
  --region us-central1 \
  --project neural-diwan-435305

# Get revision name
gcloud run revisions list \
  --service astro-blog \
  --region us-central1 \
  --project neural-diwan-435305

# Split traffic (90% old, 10% new)
gcloud run services update-traffic astro-blog \
  --to-revisions astro-blog-00001-xyz=90,astro-blog-00002-abc=10 \
  --region us-central1 \
  --project neural-diwan-435305

# After testing, route 100% to new
gcloud run services update-traffic astro-blog \
  --to-latest \
  --region us-central1 \
  --project neural-diwan-435305
```

### Custom Service Account

```bash
# Create service account for Cloud Run
gcloud iam service-accounts create cloud-run-blog \
  --display-name "Cloud Run Blog Service Account" \
  --project neural-diwan-435305

# Deploy with custom service account
gcloud run deploy astro-blog \
  --service-account cloud-run-blog@neural-diwan-435305.iam.gserviceaccount.com \
  --region us-central1 \
  --project neural-diwan-435305
```

---

## Monitoring & Observability

### Built-in Cloud Run Metrics

Available in Cloud Console:
- Request count
- Request latency (p50, p95, p99)
- Container instance count
- CPU/Memory utilization
- Error rate

**Dashboard**: https://console.cloud.google.com/run/detail/us-central1/astro-blog/metrics

### Custom Metrics (Prometheus to Cloud Monitoring)

Your app has Prometheus metrics on port 8080. You have two options:

#### Option 1: Remove Prometheus Metrics (Simplest)

You don't need custom metrics for a blog. Use Cloud Run's built-in monitoring.

Update your Dockerfile to remove the metrics port:
```dockerfile
EXPOSE 3000
# Remove: EXPOSE 8080
```

#### Option 2: Export to Cloud Monitoring (If you want to keep metrics)

Install Cloud Monitoring client in your app:
```bash
npm install @google-cloud/monitoring
```

Update your app to export metrics to Cloud Monitoring instead of Prometheus.

**Recommendation**: Use option 1 for simplicity.

### Alerting

Create alerts in Cloud Console:

```bash
# Example: Alert on high error rate
gcloud alpha monitoring policies create \
  --notification-channels=[CHANNEL_ID] \
  --display-name="Cloud Run Error Rate" \
  --condition-display-name="Error rate > 5%" \
  --condition-threshold-value=5 \
  --condition-threshold-duration=300s
```

---

## Cost Optimization Tips

### 1. Scale to Zero

Already configured with `--min-instances 0`. Your blog will cost $0 when idle.

### 2. Use CPU Throttling

Already configured with `--cpu-throttling`. CPU is throttled when not handling requests.

### 3. Right-size Memory

Monitor memory usage and reduce if possible:

```bash
# Check memory usage
gcloud run services describe astro-blog \
  --region us-central1 \
  --project neural-diwan-435305 \
  --format 'value(spec.template.spec.containers[0].resources.limits.memory)'

# Reduce to 128Mi if sufficient
gcloud run services update astro-blog \
  --memory 128Mi \
  --region us-central1 \
  --project neural-diwan-435305
```

### 4. Set Max Instances

Already configured with `--max-instances 10` to prevent runaway costs.

### 5. Enable Request Timeout

```bash
gcloud run services update astro-blog \
  --timeout 60s \
  --region us-central1 \
  --project neural-diwan-435305
```

---

## Rollback Plan

If something goes wrong:

### Rollback DNS (5 minutes)

1. Change A records back to `34.31.187.182`
2. Wait for DNS propagation
3. Your GKE cluster should still be running

### Rollback to Previous Cloud Run Revision

```bash
# List revisions
gcloud run revisions list \
  --service astro-blog \
  --region us-central1 \
  --project neural-diwan-435305

# Rollback to previous revision
gcloud run services update-traffic astro-blog \
  --to-revisions [PREVIOUS_REVISION]=100 \
  --region us-central1 \
  --project neural-diwan-435305
```

---

## Troubleshooting

### Issue: Container fails to start

```bash
# Check logs
gcloud run services logs read astro-blog \
  --region us-central1 \
  --project neural-diwan-435305 \
  --limit 100
```

**Common causes:**
- Port mismatch (ensure `--port 3000` matches your app)
- Container crashes on startup
- Missing environment variables

### Issue: Domain mapping fails

```bash
# Check domain mapping status
gcloud run domain-mappings describe \
  --domain thusspokerobotics.xyz \
  --region us-central1 \
  --project neural-diwan-435305
```

**Common causes:**
- DNS records not updated correctly
- DNS propagation delay (wait up to 1 hour)
- Domain verification required

### Issue: High latency / cold starts

If you see >1s response times on first request:

```bash
# Set minimum instances to 1 (costs ~$7/month)
gcloud run services update astro-blog \
  --min-instances 1 \
  --region us-central1 \
  --project neural-diwan-435305
```

**Trade-off**: Eliminates cold starts but costs $5-10/month.

---

## FAQ

### Q: Will my Docker container work as-is?

**A**: Yes! Your existing container runs perfectly on Cloud Run.

### Q: What about my metrics on port 8080?

**A**: Cloud Run only exposes the main port (3000). Your metrics port won't be accessible externally. Use Cloud Run's built-in metrics instead, or export to Cloud Monitoring.

### Q: Can I still use my GCR registry?

**A**: Yes! Cloud Run works with GCR, Artifact Registry, and Docker Hub.

### Q: What happens to my CI/CD pipeline?

**A**: Update to use `gcloud run deploy` instead of `kubectl apply`. See step 7.

### Q: How do I handle high traffic spikes?

**A**: Cloud Run auto-scales automatically. Set `--max-instances` to control costs.

### Q: Can I use Cloud CDN with Cloud Run?

**A**: Yes, but requires a Load Balancer (~$18/month). Only worth it for high traffic.

### Q: What about my static IP?

**A**: You won't need it. Cloud Run provides dynamic IPs, and custom domains use Google's anycast IPs.

---

## Success Checklist

- [ ] Cloud Run service deployed and running
- [ ] Test URL returns 200 OK
- [ ] Custom domain mapped (thusspokerobotics.xyz)
- [ ] WWW subdomain mapped (www.thusspokerobotics.xyz)
- [ ] DNS records updated
- [ ] SSL certificate active
- [ ] Production domain accessible via HTTPS
- [ ] CI/CD updated to deploy to Cloud Run
- [ ] Monitoring configured
- [ ] Tested in production for 1-7 days
- [ ] GKE cluster deleted (after verification)
- [ ] Celebrating $100+/month savings!

---

## Support

**Cloud Run Documentation**: https://cloud.google.com/run/docs
**Pricing Calculator**: https://cloud.google.com/products/calculator
**Support**: https://cloud.google.com/support

**Questions?** Check logs with:
```bash
gcloud run services logs read astro-blog --region us-central1 --project neural-diwan-435305
```
