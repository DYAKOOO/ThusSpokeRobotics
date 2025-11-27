# GCP Cost Optimization Guide for ThusSpokeRobotics

## 📊 Quick Summary

Your current **Kubernetes (GKE)** setup costs **$115-135/month** for a simple static blog. This is massive over-engineering.

### Recommended Solutions

| Solution | Monthly Cost | Effort | Savings | Best For |
|----------|--------------|--------|---------|----------|
| **Cloud Run** ⭐ | $1-10 | 30 min | 90-99% | Simplicity & auto-scaling |
| **Compute Engine** | $0-10 | 1-2 hrs | 92-100% | Full control & FREE tier |
| **Current (GKE)** | $115-135 | - | - | Complex apps (overkill for you) |

**TL;DR**: Use **Cloud Run** for zero maintenance and 90% cost reduction.

---

## 📁 What's in This Folder?

```
agent/
├── README.md                        # This file
├── INFRASTRUCTURE_ANALYSIS.md       # Detailed analysis of current setup
│
├── cloud-run/                       # Cloud Run migration (RECOMMENDED)
│   ├── MIGRATION_GUIDE.md          # Step-by-step migration guide
│   ├── deploy.sh                   # One-click deployment script
│   ├── rollback.sh                 # Rollback script
│   └── cloud-run-deploy.yaml       # GitHub Actions workflow
│
└── compute-engine/                  # Compute Engine setup (FREE alternative)
    ├── SETUP_GUIDE.md              # Detailed setup instructions
    ├── docker-compose.yml          # Docker Compose configuration
    ├── nginx-config.conf           # Nginx reverse proxy config
    └── setup-vm.sh                 # Automated VM setup script
```

---

## 🎯 Which Solution Should You Choose?

### Use **Cloud Run** if:
- ✅ You want the **simplest solution** (zero server management)
- ✅ You don't need SSH access to servers
- ✅ You prefer managed services over DIY
- ✅ You want automatic scaling (0 to thousands)
- ✅ You're okay with ~$1-10/month cost

**Effort**: 30 minutes | **Savings**: ~$105-125/month (90% reduction)

👉 **Start here**: [`cloud-run/MIGRATION_GUIDE.md`](cloud-run/MIGRATION_GUIDE.md)

---

### Use **Compute Engine** if:
- ✅ You want **FREE** (Google Cloud free tier)
- ✅ You need full SSH access and control
- ✅ You're comfortable with Linux server administration
- ✅ You might want to run multiple services on one VM
- ✅ You want zero cold starts

**Effort**: 1-2 hours | **Savings**: ~$115-135/month (100% if within free tier)

👉 **Start here**: [`compute-engine/SETUP_GUIDE.md`](compute-engine/SETUP_GUIDE.md)

---

## 📈 Current Infrastructure (What You Have)

### GKE Setup Breakdown

**Application**: Astro static blog (`gcr.io/neural-diwan-435305/astro-blog:v1.0.0`)

**Kubernetes Resources**:
- 1x Deployment (1-3 replicas via HPA)
- 1x LoadBalancer Service (static IP: 34.31.187.182)
- 1x Ingress (NGINX + Let's Encrypt SSL)
- 1x HPA (Horizontal Pod Autoscaler)
- 1x VPA (Vertical Pod Autoscaler - disabled)
- Prometheus + ServiceMonitor + OpenCost
- Keel (automated deployments)
- Cert-manager (SSL certificates)

**Resource Usage**: 50m CPU, 64Mi RAM (very light!)

**Monthly Cost Breakdown**:
```
GKE Control Plane:        $74.00/month  (80% of cost!)
Spot Node Pool (e2-small): $12-15/month
LoadBalancer:             $18-20/month
Static IP:                 $7.00/month  (when not attached)
Network Egress:            $5-10/month
─────────────────────────────────────
TOTAL:                   $115-135/month
```

### The Problem

1. **Over-engineered**: Using a full Kubernetes cluster for a static blog
2. **Expensive control plane**: GKE charges $74/month just to manage the cluster
3. **Unnecessary complexity**: 10+ YAML files to maintain
4. **Maintenance burden**: Cluster upgrades, certificate renewals, monitoring setup

For a **static blog with minimal traffic**, this is like using a tank to go grocery shopping.

---

## 🚀 Quick Start Guide

### Option 1: Cloud Run (Recommended)

```bash
# 1. Navigate to the cloud-run directory
cd agent/cloud-run

# 2. Run the deployment script
chmod +x deploy.sh
./deploy.sh v1.0.0

# 3. Map your custom domain
gcloud run domain-mappings create \
  --service astro-blog \
  --domain thusspokerobotics.xyz \
  --region us-central1 \
  --project neural-diwan-435305

# 4. Update DNS records (follow instructions from command output)

# 5. Wait for SSL to be provisioned (~5-10 min)

# 6. Done! Delete your GKE cluster after verification
```

**Total time**: 30 minutes
**New monthly cost**: $1-10

---

### Option 2: Compute Engine (Free Tier)

```bash
# 1. Create VM
gcloud compute instances create astro-blog-vm \
  --project=neural-diwan-435305 \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=30GB \
  --tags=http-server,https-server

# 2. SSH into VM
gcloud compute ssh astro-blog-vm --zone=us-central1-a

# 3. Download and run setup script
curl -fsSL https://raw.githubusercontent.com/[your-repo]/agent/compute-engine/setup-vm.sh -o setup-vm.sh
chmod +x setup-vm.sh
./setup-vm.sh

# 4. Update DNS to point to VM IP

# 5. Setup SSL
sudo certbot --nginx -d thusspokerobotics.xyz -d www.thusspokerobotics.xyz

# 6. Done! Delete your GKE cluster after verification
```

**Total time**: 1-2 hours
**New monthly cost**: $0 (free tier)

---

## 💰 Cost Comparison

### Current State (GKE)
```
Service                  Cost/Month
─────────────────────────────────────
GKE Control Plane        $74.00
Node Pool (e2-small)     $12-15.00
LoadBalancer             $18-20.00
Static IP (reserved)     $7.00
Network Egress           $5-10.00
─────────────────────────────────────
TOTAL                    $115-135.00
```

### Cloud Run (Managed)
```
Service                  Cost/Month
─────────────────────────────────────
Requests (10k/month)     $0.00  (free tier)
CPU time                 $0.00  (free tier)
Memory                   $0.00  (free tier)
Domain mapping           $0.00
Network Egress           $1-5.00
─────────────────────────────────────
TOTAL                    $1-10.00 ✅ 92-99% SAVINGS
```

**Assuming 10k monthly visitors**:
- Free tier covers: 2M requests/month
- Your usage: ~50k requests/month
- Well within free tier!

### Compute Engine (VM)
```
Service                  Cost/Month
─────────────────────────────────────
e2-micro VM              $0.00  (always free*)
30GB Standard disk       $0.00  (always free*)
Network Egress (1GB)     $0.00  (1GB free)
Additional egress        $0.12/GB
─────────────────────────────────────
TOTAL                    $0-10.00 ✅ 92-100% SAVINGS
```

*Always Free in us-central1, us-west1, us-east1

---

## ⚡ Feature Comparison

| Feature | GKE | Cloud Run | Compute Engine |
|---------|-----|-----------|----------------|
| **Auto-scaling** | ✅ (HPA) | ✅ (Built-in) | ❌ (Manual) |
| **SSL/HTTPS** | ✅ (cert-manager) | ✅ (Automatic) | ✅ (Certbot) |
| **Custom domain** | ✅ | ✅ | ✅ |
| **Zero downtime** | ✅ | ✅ | ⚠️ (Single VM) |
| **SSH access** | ❌ | ❌ | ✅ |
| **Metrics** | ✅ (Prometheus) | ✅ (Cloud Monitoring) | ⚠️ (DIY) |
| **Cold starts** | ❌ | ⚠️ (~1s) | ❌ |
| **Maintenance** | High | None | Low |
| **Complexity** | Very High | Very Low | Low |
| **Control** | Full | Limited | Full |

---

## 📝 Migration Checklist

### Pre-Migration
- [ ] Read `INFRASTRUCTURE_ANALYSIS.md`
- [ ] Choose between Cloud Run or Compute Engine
- [ ] Read the appropriate migration guide
- [ ] **Important**: Keep GKE running during migration for rollback

### During Migration
- [ ] Deploy to new platform (Cloud Run or VM)
- [ ] Test thoroughly on test URL
- [ ] Map custom domain
- [ ] Update DNS records
- [ ] Wait for DNS propagation (5-30 minutes)
- [ ] Verify HTTPS works
- [ ] Monitor for 24-48 hours

### Post-Migration
- [ ] Monitor traffic and performance for 1-7 days
- [ ] Update CI/CD pipeline
- [ ] Update documentation
- [ ] Delete GKE cluster (irreversible - make sure everything works!)
- [ ] Release old static IP (if not needed)
- [ ] Celebrate your $100+/month savings! 🎉

---

## 🛠️ Troubleshooting

### Cloud Run Issues

**Problem**: Container fails to start
```bash
# Check logs
gcloud run services logs read astro-blog --region us-central1 --project neural-diwan-435305

# Common fixes:
# 1. Ensure port matches (--port 3000)
# 2. Check environment variables
# 3. Verify container works locally
```

**Problem**: Domain mapping fails
```bash
# Check status
gcloud run domain-mappings describe --domain thusspokerobotics.xyz --region us-central1

# Common fixes:
# 1. Wait for DNS propagation (up to 1 hour)
# 2. Verify DNS records are correct
# 3. Check domain ownership verification
```

### Compute Engine Issues

**Problem**: Can't SSH into VM
```bash
# Use gcloud ssh (not regular ssh)
gcloud compute ssh astro-blog-vm --zone=us-central1-a

# If still fails, check firewall rules
gcloud compute firewall-rules list
```

**Problem**: Nginx 502 Bad Gateway
```bash
# Check if Docker is running
docker ps

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# Restart services
docker-compose restart
sudo systemctl restart nginx
```

---

## 📚 Additional Resources

### Documentation
- **Cloud Run**: https://cloud.google.com/run/docs
- **Compute Engine**: https://cloud.google.com/compute/docs
- **GCP Free Tier**: https://cloud.google.com/free

### Tools
- **Cost Calculator**: https://cloud.google.com/products/calculator
- **GCP Console**: https://console.cloud.google.com
- **Domain Mapping**: https://cloud.google.com/run/docs/mapping-custom-domains

### Support
- **Cloud Run FAQ**: https://cloud.google.com/run/docs/faq
- **GCP Support**: https://cloud.google.com/support
- **Community**: https://stackoverflow.com/questions/tagged/google-cloud-platform

---

## ❓ FAQ

### Q: Will I lose any features by moving away from Kubernetes?

**A**: For a static blog, no. You'll actually gain simplicity. The only "features" you lose are Kubernetes-specific APIs that you don't need.

### Q: What about my Prometheus metrics?

**A**: Cloud Run has built-in metrics (requests, latency, errors). Compute Engine can run Prometheus if needed. For a blog, built-in metrics are sufficient.

### Q: Can I still use my GitHub Actions CI/CD?

**A**: Yes! Just update the deployment step. Examples are included in `cloud-run/cloud-run-deploy.yaml`.

### Q: What if I need to rollback?

**A**: Keep your GKE cluster running for 1-7 days. If issues arise, just point DNS back to the old IP. Rollback scripts are included.

### Q: Is Cloud Run really cheaper than a VM?

**A**: For low traffic, yes. Cloud Run scales to zero (pays nothing when idle). VMs run 24/7 but can be free (free tier). At high traffic (100k+ visits/month), they're similar.

### Q: Will my Docker container work as-is?

**A**: Yes! Both Cloud Run and Compute Engine use your existing container without modifications.

### Q: What about cold starts on Cloud Run?

**A**: First request after idle period may take 1-3 seconds. For a blog, this is acceptable. Set `--min-instances 1` if you need instant response (costs ~$7/month).

### Q: Should I keep my GCR images?

**A**: Yes, GCR storage is cheap (~$0.026/GB/month). Keep your images there.

---

## 🎯 Next Steps

1. **Read**: [`INFRASTRUCTURE_ANALYSIS.md`](INFRASTRUCTURE_ANALYSIS.md) for detailed breakdown
2. **Choose**: Cloud Run (simple) or Compute Engine (free)
3. **Migrate**: Follow the guide in respective folder
4. **Monitor**: Keep GKE running for 1-7 days as backup
5. **Cleanup**: Delete GKE cluster and celebrate savings!

---

## 💡 Pro Tips

### Cloud Run
- Start with `--min-instances 0` to save maximum cost
- Use `--max-instances 10` to prevent runaway costs
- Enable Cloud CDN only if you have global traffic (adds cost)
- Use traffic splitting for zero-downtime deployments

### Compute Engine
- Use us-central1, us-west1, or us-east1 for free tier
- Setup automated backups (snapshots ~$0.80/month)
- Use Watchtower for automatic image updates
- Enable unattended-upgrades for security patches

### General
- Delete old GKE resources to avoid lingering charges
- Monitor billing for the first month
- Set up budget alerts in GCP Console
- Keep your Docker images in GCR (minimal cost)

---

**Questions?** Open an issue or check the detailed guides in each folder.

**Ready to save $100+/month?** Let's go! 🚀
