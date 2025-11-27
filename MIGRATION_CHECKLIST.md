# Cloud Run Migration Checklist for ThusSpokeRobotics

**Goal**: Migrate from GKE to Cloud Run and save $100+/month

**Estimated Time**: 1-2 hours total
**Estimated Savings**: $105-125/month ($1,260-1,500/year)

---

## ✅ Pre-Migration (You're here now!)

- [x] Analyzed current infrastructure (GKE)
- [x] Created migration guides in `agent/` folder
- [x] Identified comment system issue
- [x] Chose Giscus for comments (GitHub Discussions)
- [ ] **Next**: Set up Giscus (15 minutes)

---

## 📝 Part 1: Fix Comments (15-20 minutes)

### 1.1 Enable GitHub Discussions

1. Go to: https://github.com/[your-username]/ThusSpokeRobotics/settings
2. Scroll to **Features** section
3. Check ✅ **Discussions**
4. Click **Set up discussions**

### 1.2 Install Giscus App

1. Go to: https://github.com/apps/giscus
2. Click **Install**
3. Select **ThusSpokeRobotics** repository
4. Authorize

### 1.3 Get Giscus Configuration

1. Go to: https://giscus.app
2. Enter: `[your-username]/ThusSpokeRobotics`
3. Choose:
   - Mapping: `pathname`
   - Category: `Announcements`
   - Theme: `preferred_color_scheme`
4. **Copy these values**:
   - `data-repo`: `your-username/ThusSpokeRobotics`
   - `data-repo-id`: `R_...` (copy from giscus.app)
   - `data-category-id`: `DIC_...` (copy from giscus.app)

### 1.4 Tell Me Your Values

Once you have them, give me:
- Your GitHub username
- The `data-repo-id`
- The `data-category-id`

I'll update the component for you!

---

## 🚀 Part 2: Deploy to Cloud Run (30-45 minutes)

### 2.1 Build & Push Docker Image

```bash
# Authenticate Docker with GCR
gcloud auth configure-docker

# Build new image with Giscus
docker build -t gcr.io/neural-diwan-435305/astro-blog:v2.0.0 .

# Tag as latest
docker tag gcr.io/neural-diwan-435305/astro-blog:v2.0.0 \
           gcr.io/neural-diwan-435305/astro-blog:latest

# Push to GCR
docker push gcr.io/neural-diwan-435305/astro-blog:v2.0.0
docker push gcr.io/neural-diwan-435305/astro-blog:latest
```

### 2.2 Deploy to Cloud Run

```bash
cd agent/cloud-run
chmod +x deploy.sh
./deploy.sh v2.0.0
```

Or manually:

```bash
gcloud run deploy astro-blog \
  --image gcr.io/neural-diwan-435305/astro-blog:v2.0.0 \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000 \
  --cpu 1 \
  --memory 256Mi \
  --min-instances 0 \
  --max-instances 10 \
  --cpu-throttling \
  --timeout 60s \
  --project neural-diwan-435305
```

### 2.3 Test Cloud Run URL

```bash
# Get service URL
SERVICE_URL=$(gcloud run services describe astro-blog \
  --region us-central1 \
  --project neural-diwan-435305 \
  --format 'value(status.url)')

echo "Test at: $SERVICE_URL"

# Test it
curl -I $SERVICE_URL
```

Visit the URL in your browser and **test comments**!

---

## 🌐 Part 3: Custom Domain Setup (20-30 minutes)

### 3.1 Map Domain to Cloud Run

```bash
# Map primary domain
gcloud run domain-mappings create \
  --service astro-blog \
  --domain thusspokerobotics.xyz \
  --region us-central1 \
  --project neural-diwan-435305

# Map www subdomain
gcloud run domain-mappings create \
  --service astro-blog \
  --domain www.thusspokerobotics.xyz \
  --region us-central1 \
  --project neural-diwan-435305
```

### 3.2 Update DNS Records

Cloud Run will output DNS records like:

```
Please add the following DNS records:
  TYPE  NAME                    DATA
  A     thusspokerobotics.xyz   216.239.32.21
  A     thusspokerobotics.xyz   216.239.34.21
  A     thusspokerobotics.xyz   216.239.36.21
  A     thusspokerobotics.xyz   216.239.38.21
```

**Go to your DNS provider** (Namecheap, Cloudflare, Google Domains, etc.):

1. **Delete** the current A record pointing to `34.31.187.182`
2. **Add** the new A records from Cloud Run output
3. Do the same for `www.thusspokerobotics.xyz`

### 3.3 Wait for DNS Propagation

```bash
# Check DNS (repeat every 5 minutes)
dig thusspokerobotics.xyz

# Or use online tool
# https://dnschecker.org
```

Usually takes 5-30 minutes, sometimes up to 48 hours.

### 3.4 Verify SSL Certificate

```bash
# Check domain mapping status
gcloud run domain-mappings describe \
  --domain thusspokerobotics.xyz \
  --region us-central1 \
  --project neural-diwan-435305
```

Wait until:
- Status: `Active`
- Certificate: `Ready`

### 3.5 Test Production Domain

```bash
curl -I https://thusspokerobotics.xyz
curl -I https://www.thusspokerobotics.xyz
```

Both should return `200 OK` with `server: Google Frontend`

**Visit in browser**: https://thusspokerobotics.xyz

---

## 🔄 Part 4: Update CI/CD (15 minutes)

### 4.1 Update GitHub Actions

Edit `.github/workflows/main.yaml`:

**Replace** the GKE deployment section with:

```yaml
- name: Deploy to Cloud Run
  run: |
    gcloud run deploy astro-blog \
      --image gcr.io/neural-diwan-435305/astro-blog:${{ github.sha }} \
      --platform managed \
      --region us-central1 \
      --project neural-diwan-435305 \
      --quiet
```

### 4.2 Test CI/CD

```bash
# Commit and push a small change
git add .github/workflows/main.yaml
git commit -m "Update CI/CD to deploy to Cloud Run"
git push
```

Watch the GitHub Actions run and verify deployment succeeds.

---

## 📊 Part 5: Monitor (24-48 hours)

### 5.1 Check Cloud Run Metrics

Visit: https://console.cloud.google.com/run/detail/us-central1/astro-blog/metrics

Monitor:
- Request count
- Latency (p50, p95, p99)
- Error rate
- Container instances

### 5.2 Check Logs

```bash
# View recent logs
gcloud run services logs read astro-blog \
  --region us-central1 \
  --project neural-diwan-435305 \
  --limit 100

# Follow logs in real-time
gcloud run services logs tail astro-blog \
  --region us-central1 \
  --project neural-diwan-435305
```

### 5.3 Monitor Costs

Visit: https://console.cloud.google.com/billing

You should see costs dropping immediately:
- GKE control plane: $74/month → $0
- LoadBalancer: $18-20/month → $0
- Node pool: $12-15/month → $0

New costs:
- Cloud Run: $1-10/month (mostly egress)

---

## 🗑️ Part 6: Cleanup GKE (After 1 week)

**IMPORTANT**: Only do this after you're 100% confident Cloud Run works!

### 6.1 List GKE Resources

```bash
# List clusters
gcloud container clusters list --project=neural-diwan-435305

# List static IPs
gcloud compute addresses list --project=neural-diwan-435305
```

### 6.2 Delete GKE Cluster

```bash
gcloud container clusters delete [CLUSTER_NAME] \
  --region [REGION] \
  --project neural-diwan-435305
```

**This is IRREVERSIBLE!** Make sure:
- ✅ Cloud Run is working perfectly
- ✅ Domain is mapped and SSL works
- ✅ Comments work (Giscus)
- ✅ CI/CD deploys successfully
- ✅ You've monitored for at least 1 week

### 6.3 Release Static IP (Optional)

```bash
# Only if you're not using it
gcloud compute addresses delete [IP_NAME] \
  --region [REGION] \
  --project neural-diwan-435305
```

This saves ~$7/month.

### 6.4 Verify Savings

Check your billing dashboard:

**Before**: ~$115-135/month
**After**: ~$1-10/month
**Savings**: ~$105-125/month = **$1,260-1,500/year**

🎉 **Congratulations!**

---

## 📋 Quick Reference

### Useful Commands

```bash
# Deploy to Cloud Run
cd agent/cloud-run && ./deploy.sh v2.0.0

# View logs
gcloud run services logs read astro-blog --region us-central1 --limit 50

# Check service status
gcloud run services describe astro-blog --region us-central1

# List domain mappings
gcloud run domain-mappings list --region us-central1

# Check DNS
dig thusspokerobotics.xyz

# Test HTTPS
curl -I https://thusspokerobotics.xyz
```

### Important URLs

- **Cloud Run Console**: https://console.cloud.google.com/run
- **Giscus Config**: https://giscus.app
- **DNS Checker**: https://dnschecker.org
- **Your Blog**: https://thusspokerobotics.xyz

---

## 🆘 Troubleshooting

### Issue: Cloud Run deploy fails

```bash
# Check logs
gcloud run services logs read astro-blog --region us-central1 --limit 100

# Common fixes:
# 1. Check Dockerfile builds locally: docker build .
# 2. Verify port 3000 is exposed
# 3. Check environment variables
```

### Issue: Domain mapping fails

```bash
# Check status
gcloud run domain-mappings describe \
  --domain thusspokerobotics.xyz \
  --region us-central1

# Common fixes:
# 1. Wait longer (DNS can take 48 hours)
# 2. Verify DNS records are correct
# 3. Make sure repo is public (for Giscus)
```

### Issue: Comments don't load

- Check browser console for errors
- Verify GitHub Discussions are enabled
- Verify Giscus app is installed
- Check repo is **public**
- Verify `data-repo-id` and `data-category-id` are correct

### Issue: High latency / cold starts

```bash
# Set minimum instances to 1 (costs ~$7/month)
gcloud run services update astro-blog \
  --min-instances 1 \
  --region us-central1
```

---

## 🎯 Success Criteria

Before deleting GKE, verify:

- [ ] Cloud Run service is deployed and running
- [ ] Test URL (*.run.app) returns 200 OK
- [ ] Custom domain (thusspokerobotics.xyz) is mapped
- [ ] www subdomain is mapped
- [ ] DNS records are updated
- [ ] SSL certificate is active (HTTPS works)
- [ ] Comments load (Giscus widget appears)
- [ ] Can post a test comment (sign in with GitHub)
- [ ] CI/CD deploys to Cloud Run successfully
- [ ] Monitored for 1-7 days with no issues
- [ ] Billing shows reduced costs

**Then**: Delete GKE and celebrate! 🎉

---

## Timeline

| Task | Time | When |
|------|------|------|
| Setup Giscus | 15-20 min | Now |
| Update component | 5 min | After Giscus setup |
| Build & deploy | 30-45 min | Same day |
| Map domain | 20-30 min | Same day |
| Update CI/CD | 15 min | Same day |
| **Total active time** | **~2 hours** | **Day 1** |
| Monitor | Passive | Days 2-7 |
| Delete GKE | 5 min | After 1 week |

**You'll start saving money immediately!**

---

## Need Help?

1. **Giscus Setup**: Read `GISCUS_SETUP.md`
2. **Cloud Run Migration**: Read `agent/cloud-run/MIGRATION_GUIDE.md`
3. **Cost Analysis**: Read `agent/COST_CALCULATOR.md`
4. **Quick Start**: Read `agent/QUICK_START.md`

**Ready to start?** Let's set up Giscus! Give me:
1. Your GitHub username
2. The values from https://giscus.app
