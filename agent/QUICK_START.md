# Quick Start: Migrate ThusSpokeRobotics to Cloud Run

**Save $100+/month in 30 minutes!**

## Pre-Flight Check

Current setup:
- ✅ Domain: thusspokerobotics.xyz
- ✅ GKE cluster running
- ✅ Container: gcr.io/neural-diwan-435305/astro-blog:v1.0.0
- ✅ Current IP: 34.31.187.182

## Option 1: Cloud Run (Recommended) - 30 minutes

### Step 1: Deploy to Cloud Run (5 min)

```bash
cd agent/cloud-run
chmod +x deploy.sh
./deploy.sh v1.0.0
```

### Step 2: Map Domain (2 min)

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

### Step 3: Update DNS (5 min)

Copy the DNS records from the output and update your DNS provider:
- Delete A record pointing to 34.31.187.182
- Add the new A records from Cloud Run output

### Step 4: Wait & Test (15 min)

```bash
# Wait for DNS propagation (5-30 min)
# Test when ready:
curl -I https://thusspokerobotics.xyz
curl -I https://www.thusspokerobotics.xyz
```

### Step 5: Update CI/CD (3 min)

Replace your GitHub Actions deployment step with:

```yaml
- name: Deploy to Cloud Run
  run: |
    gcloud run deploy astro-blog \
      --image gcr.io/neural-diwan-435305/astro-blog:${{ github.sha }} \
      --platform managed \
      --region us-central1 \
      --project neural-diwan-435305
```

### Step 6: Cleanup (After 1 week)

Once you verify everything works:

```bash
# Delete GKE cluster
gcloud container clusters list --project=neural-diwan-435305
gcloud container clusters delete [CLUSTER_NAME] --region [REGION] --project=neural-diwan-435305
```

**Done! You're now saving $105-125/month!**

---

## Option 2: Compute Engine (FREE) - 1-2 hours

### Step 1: Create VM (2 min)

```bash
gcloud compute instances create thusspoke-blog-vm \
  --project=neural-diwan-435305 \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=30GB \
  --tags=http-server,https-server
```

### Step 2: Setup Firewall (1 min)

```bash
gcloud compute firewall-rules create allow-http \
  --project=neural-diwan-435305 \
  --allow=tcp:80 \
  --target-tags=http-server

gcloud compute firewall-rules create allow-https \
  --project=neural-diwan-435305 \
  --allow=tcp:443 \
  --target-tags=https-server
```

### Step 3: Run Setup Script (30-45 min)

```bash
# SSH into VM
gcloud compute ssh thusspoke-blog-vm --zone=us-central1-a

# Download and run setup script
wget https://raw.githubusercontent.com/[your-repo]/main/agent/compute-engine/setup-vm.sh
chmod +x setup-vm.sh
./setup-vm.sh
```

The script will:
- Install Docker & Docker Compose
- Install Nginx & Certbot
- Pull your container
- Configure Nginx reverse proxy
- Start the blog

### Step 4: Get VM IP (1 min)

```bash
# On your local machine
gcloud compute instances describe thusspoke-blog-vm \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

### Step 5: Update DNS (5 min)

Update your DNS records:
- Change `thusspokerobotics.xyz` A record to [VM_IP]
- Change `www.thusspokerobotics.xyz` A record to [VM_IP]

### Step 6: Setup SSL (5-30 min)

```bash
# SSH into VM
gcloud compute ssh thusspoke-blog-vm --zone=us-central1-a

# Run certbot (wait for DNS to propagate first!)
sudo certbot --nginx \
  -d thusspokerobotics.xyz \
  -d www.thusspokerobotics.xyz \
  --non-interactive \
  --agree-tos \
  -m your-email@example.com
```

### Step 7: Test (2 min)

```bash
curl -I https://thusspokerobotics.xyz
```

### Step 8: Cleanup (After 1 week)

```bash
# Delete GKE cluster
gcloud container clusters list --project=neural-diwan-435305
gcloud container clusters delete [CLUSTER_NAME] --region [REGION] --project=neural-diwan-435305
```

**Done! You're now on the FREE tier!**

---

## Comparison

| Metric | Cloud Run | Compute Engine |
|--------|-----------|----------------|
| **Time** | 30 min | 1-2 hrs |
| **Cost** | $1-10/month | $0-10/month |
| **Complexity** | Very Low | Low |
| **Maintenance** | None | ~1 hr/month |
| **Auto-scaling** | Yes | No |
| **Cold starts** | Yes (~1s) | No |
| **SSH access** | No | Yes |

## Which to Choose?

**Choose Cloud Run if:**
- You want the fastest migration (30 min)
- You don't want to manage servers
- You value time over a few dollars
- You might need auto-scaling

**Choose Compute Engine if:**
- You want FREE (within free tier)
- You need SSH access
- You're comfortable with Linux
- You have 1-2 hours to spare

## Troubleshooting

### Cloud Run: Container won't start

```bash
# Check logs
gcloud run services logs read astro-blog --region us-central1 --limit 50
```

### Compute Engine: Can't SSH

```bash
# Use gcloud ssh (not regular ssh)
gcloud compute ssh thusspoke-blog-vm --zone=us-central1-a --project=neural-diwan-435305
```

### DNS not propagating

```bash
# Check DNS propagation
dig thusspokerobotics.xyz
nslookup thusspokerobotics.xyz 8.8.8.8

# Can take up to 48 hours, but usually 5-30 minutes
```

### SSL certificate fails

```bash
# Make sure DNS is propagated first
# Check DNS:
curl http://thusspokerobotics.xyz  # Should reach your server

# Then run certbot again
```

## Need Help?

- **Cloud Run Guide**: `agent/cloud-run/MIGRATION_GUIDE.md`
- **Compute Engine Guide**: `agent/compute-engine/SETUP_GUIDE.md`
- **Cost Analysis**: `agent/COST_CALCULATOR.md`
- **Infrastructure Analysis**: `agent/INFRASTRUCTURE_ANALYSIS.md`

## Summary

**Current cost**: $115-135/month (GKE)
**New cost**: $0-10/month (Cloud Run or Compute Engine)
**Savings**: $105-135/month = **$1,260-1,620/year**

🎉 **Let's save some money!**
