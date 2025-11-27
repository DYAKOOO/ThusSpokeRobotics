# 🚀 Deploy ThusSpokeRobotics to Cloud Run - Final Steps

**Status**: ✅ Comments working with Giscus! Ready to deploy!

**Time Required**: 15-30 minutes
**Cost After Migration**: $1-10/month (vs current $115-135/month)
**Savings**: $105-125/month = **$1,260-1,500/year**

---

## ✅ What's Done

- [x] Analyzed infrastructure (GKE → Cloud Run)
- [x] Fixed comment system (Giscus with GitHub Discussions)
- [x] Updated all code with Giscus configuration
- [x] Tested locally - **Comments work!**
- [x] Created deployment scripts
- [x] Updated domain to thusspokerobotics.xyz

---

## 🚀 Deploy Now (3 Easy Steps)

### Step 1: Build & Deploy to Cloud Run (10 minutes)

Open your terminal in this project directory and run:

```bash
./deploy-to-cloud-run.sh
```

**What it does:**
1. Builds Docker image with Giscus comments
2. Pushes to Google Container Registry
3. Deploys to Cloud Run
4. Gives you a test URL (*.run.app)

**Expected output:**
```
✅ Deployment complete!
📍 Service URL: https://astro-blog-xxxxxxxxxx-uc.a.run.app
```

**Test it:**
1. Visit the Service URL in your browser
2. Click on a blog post
3. Scroll down - you should see Giscus comments!
4. Try posting a comment

---

### Step 2: Map Custom Domain (5 minutes)

Once the deployment succeeds, run:

```bash
./map-domain.sh
```

**What it does:**
1. Maps thusspokerobotics.xyz to Cloud Run
2. Maps www.thusspokerobotics.xyz to Cloud Run
3. Shows you DNS records to update

**Expected output:**
```
📝 DNS RECORDS TO UPDATE

For thusspokerobotics.xyz:
  Type: A, Name: @, Value: 216.239.32.21
  Type: A, Name: @, Value: 216.239.34.21
  Type: A, Name: @, Value: 216.239.36.21
  Type: A, Name: @, Value: 216.239.38.21

For www.thusspokerobotics.xyz:
  Type: CNAME, Name: www, Value: ghs.googlehosted.com
```

---

### Step 3: Update DNS (10 minutes + wait time)

Go to your DNS provider (where you registered thusspokerobotics.xyz):

**Common DNS Providers:**
- Namecheap: https://www.namecheap.com/myaccount/login
- Google Domains: https://domains.google.com
- Cloudflare: https://dash.cloudflare.com
- GoDaddy: https://dcc.godaddy.com/control/dns

**DNS Changes:**

1. **DELETE** the old A record:
   ```
   Type: A
   Name: @ (or thusspokerobotics.xyz)
   Value: 34.31.187.182  ← DELETE THIS
   ```

2. **ADD** four new A records:
   ```
   Type: A, Name: @, Value: 216.239.32.21
   Type: A, Name: @, Value: 216.239.34.21
   Type: A, Name: @, Value: 216.239.36.21
   Type: A, Name: @, Value: 216.239.38.21
   ```

3. **UPDATE or ADD** CNAME for www:
   ```
   Type: CNAME
   Name: www
   Value: ghs.googlehosted.com
   ```

**Save changes** and wait 5-30 minutes for DNS propagation.

---

## 🔍 Verify Everything Works

### Check DNS Propagation

```bash
# Check if DNS has updated
dig thusspokerobotics.xyz

# Or use online tool
# https://dnschecker.org
```

Wait until you see the new IP addresses (216.239.x.x).

### Check Domain Mapping Status

```bash
gcloud run domain-mappings describe \
  --domain thusspokerobotics.xyz \
  --region us-central1 \
  --project neural-diwan-435305
```

Wait for:
- **Status**: `Active`
- **Certificate**: `Ready`

This usually takes 10-20 minutes after DNS propagates.

### Test Your Production Site

```bash
# Test HTTPS
curl -I https://thusspokerobotics.xyz
curl -I https://www.thusspokerobotics.xyz
```

Both should return:
```
HTTP/2 200
server: Google Frontend
```

### Visit in Browser

1. Go to: **https://thusspokerobotics.xyz**
2. Browse your blog
3. Click on a blog post
4. Scroll to comments - **Giscus should work!**
5. Post a test comment

---

## 🔄 Update GitHub Actions CI/CD

Once everything works, update your GitHub Actions to deploy to Cloud Run automatically.

Edit `.github/workflows/main.yaml`:

**Find the deployment section** and replace with:

```yaml
- name: Build and Push Docker Image
  run: |
    gcloud auth configure-docker
    docker build -t gcr.io/neural-diwan-435305/astro-blog:${{ github.sha }} .
    docker tag gcr.io/neural-diwan-435305/astro-blog:${{ github.sha }} \
               gcr.io/neural-diwan-435305/astro-blog:latest
    docker push gcr.io/neural-diwan-435305/astro-blog:${{ github.sha }}
    docker push gcr.io/neural-diwan-435305/astro-blog:latest

- name: Deploy to Cloud Run
  run: |
    gcloud run deploy astro-blog \
      --image gcr.io/neural-diwan-435305/astro-blog:${{ github.sha }} \
      --platform managed \
      --region us-central1 \
      --project neural-diwan-435305 \
      --quiet
```

**Commit and push:**

```bash
git add .github/workflows/main.yaml
git commit -m "Update CI/CD to deploy to Cloud Run"
git push
```

---

## 📊 Monitor Cloud Run

### View Metrics

Visit: https://console.cloud.google.com/run/detail/us-central1/astro-blog/metrics

Monitor:
- Request count
- Latency
- Error rate
- Container instances

### View Logs

```bash
# Recent logs
gcloud run services logs read astro-blog \
  --region us-central1 \
  --limit 100

# Follow in real-time
gcloud run services logs tail astro-blog \
  --region us-central1
```

---

## 🗑️ Delete GKE (After 1 Week)

**IMPORTANT**: Only do this after you're 100% confident everything works!

**Wait at least 1 week** to monitor Cloud Run, then:

### 1. List GKE Resources

```bash
# List clusters
gcloud container clusters list --project=neural-diwan-435305

# List IP addresses
gcloud compute addresses list --project=neural-diwan-435305
```

### 2. Delete Cluster

```bash
gcloud container clusters delete [CLUSTER_NAME] \
  --region [REGION] \
  --project neural-diwan-435305
```

⚠️ **This is IRREVERSIBLE!** Make sure:
- ✅ Cloud Run works perfectly for 1+ week
- ✅ Domain is mapped and HTTPS works
- ✅ Comments work (Giscus)
- ✅ CI/CD deploys successfully
- ✅ No errors in logs

### 3. Release Static IP (Optional)

```bash
# Only if you're not using it
gcloud compute addresses delete [IP_NAME] \
  --region [REGION] \
  --project neural-diwan-435305
```

Saves ~$7/month.

---

## 💰 Cost Comparison

### Before (GKE)
```
GKE Control Plane:    $74.00/month
Node Pool:            $12-15/month
LoadBalancer:         $18-20/month
Static IP:            $7.00/month
Egress:               $5-10/month
──────────────────────────────────
TOTAL:                $115-135/month
```

### After (Cloud Run)
```
Requests (free tier): $0.00
CPU time (free tier): $0.00
Memory (free tier):   $0.00
Egress:               $1-10/month
──────────────────────────────────
TOTAL:                $1-10/month
```

### Savings
```
Monthly:   $105-125
Annual:    $1,260-1,500
3-Year:    $3,780-4,500
```

🎉 **Congratulations on saving $1,260-1,500/year!**

---

## ✅ Final Checklist

Before deleting GKE, verify:

- [ ] Ran `./deploy-to-cloud-run.sh` successfully
- [ ] Cloud Run service is deployed
- [ ] Test URL (*.run.app) works
- [ ] Ran `./map-domain.sh` successfully
- [ ] Updated DNS records at provider
- [ ] DNS propagated (dig shows new IPs)
- [ ] SSL certificate is active (HTTPS works)
- [ ] https://thusspokerobotics.xyz loads
- [ ] https://www.thusspokerobotics.xyz loads
- [ ] Giscus comments work on production
- [ ] Can post comments successfully
- [ ] Updated GitHub Actions CI/CD
- [ ] CI/CD deploys to Cloud Run successfully
- [ ] Monitored for 1-7 days with no issues
- [ ] Ready to delete GKE!

---

## 🆘 Troubleshooting

### Docker build fails

```bash
# Check Dockerfile syntax
docker build .

# Check logs
docker build . 2>&1 | tee build.log
```

### Cloud Run deploy fails

```bash
# Check logs
gcloud run services logs read astro-blog --region us-central1 --limit 100

# Common fixes:
# 1. Ensure port 3000 is exposed in Dockerfile
# 2. Check environment variables
# 3. Verify image pushed to GCR
```

### DNS not propagating

```bash
# Check current DNS
dig thusspokerobotics.xyz
nslookup thusspokerobotics.xyz 8.8.8.8

# Can take up to 48 hours
# Usually 5-30 minutes
```

### SSL certificate pending

```bash
# Check status
gcloud run domain-mappings describe \
  --domain thusspokerobotics.xyz \
  --region us-central1

# Wait 10-30 minutes after DNS propagates
```

### Comments don't load

- Check browser console for errors
- Verify repo is public
- Verify Giscus app installed
- Check data-repo-id and data-category-id

---

## 📞 Support

**Documentation:**
- Cloud Run: https://cloud.google.com/run/docs
- Giscus: https://giscus.app
- Domain Mapping: https://cloud.google.com/run/docs/mapping-custom-domains

**Cost Calculator:**
- https://cloud.google.com/products/calculator

**DNS Checker:**
- https://dnschecker.org

---

## 🎯 Quick Commands Reference

```bash
# Deploy
./deploy-to-cloud-run.sh

# Map domain
./map-domain.sh

# Check DNS
dig thusspokerobotics.xyz

# Check domain mapping
gcloud run domain-mappings describe \
  --domain thusspokerobotics.xyz \
  --region us-central1

# View logs
gcloud run services logs read astro-blog --region us-central1

# Test HTTPS
curl -I https://thusspokerobotics.xyz
```

---

## 🚀 Ready to Deploy?

Run this command to start:

```bash
./deploy-to-cloud-run.sh
```

Good luck! 🎉
