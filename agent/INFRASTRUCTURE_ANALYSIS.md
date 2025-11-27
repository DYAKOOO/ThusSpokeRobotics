# Infrastructure Analysis & Cost Optimization

## Current State: Kubernetes (GKE)

### What You Have
- **Application**: Astro static blog (ThusSpokeRobotics - ML/Gaussian Splatting content)
- **Platform**: Google Kubernetes Engine (GKE) with spot instances
- **Domain**: thusspokerobotics.xyz
- **Static IP**: 34.31.187.182

### Current Components
1. **Deployment**: 1 replica Astro blog (gcr.io/neural-diwan-435305/astro-blog:v1.0.0)
2. **Service**: LoadBalancer with static IP
3. **Ingress**: NGINX with Let's Encrypt SSL
4. **Autoscaling**: HPA (1-3 pods) + VPA (disabled)
5. **Monitoring**: Prometheus + ServiceMonitor + OpenCost
6. **CD**: Keel (automated deployments from GCR)
7. **Resource Usage**: 50m CPU, 64Mi RAM (very light)

### Current Monthly Costs (Estimated)
- GKE Control Plane: ~$74/month
- Spot Node Pool (e2-small): ~$12-15/month
- LoadBalancer: ~$18-20/month
- Static IP: ~$7/month (when not attached to running LB)
- Egress/Bandwidth: ~$5-10/month
- **Total: ~$115-135/month**

### Problems
1. Massive over-engineering for a static blog
2. GKE control plane fee is 80% of your cost
3. Complexity: 10+ Kubernetes resources to manage
4. Requires cluster maintenance and updates

---

## Recommended Solution: Cloud Run (Serverless)

### Why Cloud Run?
- **Cost**: $1-10/month (pay-per-request, scales to zero)
- **Zero infrastructure management**: No VMs, no clusters
- **Built-in HTTPS/SSL**: Automatic certificates
- **Custom domains**: Built-in support
- **Auto-scaling**: 0 to thousands of instances
- **CI/CD**: Integrates with Cloud Build
- **Same Docker image**: Reuse your existing container

### Migration Effort
**Complexity**: ⭐ (Very Easy)
**Time**: 30 minutes
**Downtime**: <5 minutes (DNS propagation)

### Cost Breakdown
- **Free tier**: 2M requests/month, 360k vCPU-seconds, 180k GiB-seconds
- **Typical blog traffic (10k visits/month)**:
  - Requests: ~50k (well within free tier)
  - Compute: Minimal (each request ~200ms)
  - **Estimated: $1-3/month** (mostly for domain mapping)

### What You Keep
- Same Docker container
- Same GCR registry
- Automatic HTTPS
- Custom domain
- Rolling deployments
- Traffic splitting (for canary/blue-green)

### What You Lose
- Kubernetes-specific features (not needed for static blog)
- Prometheus metrics (Cloud Run has built-in monitoring)
- VPA/HPA (Cloud Run handles autoscaling automatically)

---

## Alternative 1: Compute Engine (VM with Docker)

### Why Compute Engine?
- **Cost**: FREE to $7/month
- **Google Cloud Free Tier**: 1 e2-micro VM (us-central1, us-west1, us-east1)
- **Full control**: Run anything you want
- **Simple setup**: Docker Compose + Nginx + Certbot

### Migration Effort
**Complexity**: ⭐⭐ (Easy)
**Time**: 1-2 hours
**Downtime**: <5 minutes

### Cost Breakdown
- **e2-micro VM**: FREE (always free tier in eligible regions)
- **30GB Standard PD**: FREE (always free tier)
- **Static IP**: $7/month (if kept running)
- **Egress**: First 1GB/month free, then $0.12/GB
- **Estimated: $0-10/month**

### Setup
1. e2-micro VM (1 vCPU, 1GB RAM)
2. Docker + Docker Compose
3. Nginx reverse proxy
4. Certbot for Let's Encrypt
5. Systemd for auto-restart

### Pros
- Completely free (within free tier limits)
- Full SSH access
- Can run multiple services
- No cold starts

### Cons
- Need to manage VM (updates, security)
- Manual SSL renewal (though automated via certbot)
- No automatic scaling (but you don't need it)
- Single point of failure (but sufficient for a blog)

---

## Alternative 2: Cloud Storage + CDN (Pure Static)

### Why Cloud Storage?
- **Cost**: $1-2/month
- **Simplest possible solution**
- **Maximum performance**: Served from CDN edge locations
- **No servers**: Pure static hosting

### Migration Effort
**Complexity**: ⭐⭐⭐ (Moderate)
**Time**: 2-3 hours
**Downtime**: <5 minutes

### Cost Breakdown
- **Cloud Storage**: $0.02/GB/month (your dist folder is probably <100MB)
- **Cloud CDN**: $0.04/GB egress (cheaper than Compute egress)
- **Load Balancer** (for HTTPS): ~$18/month (this is the main cost)
- **Cloud DNS**: $0.40/zone + $0.40/1M queries
- **Estimated: $20-25/month** (not cheaper due to LB cost)

### Note
This option is NOT cheaper because Google Cloud Load Balancer costs ~$18/month. Only worth it if you need:
- Global CDN performance
- DDoS protection
- Multi-region redundancy

**For a blog, this is overkill.**

---

## Alternative 3: Hybrid - Cloud Run + Cloud CDN

### Why Hybrid?
- **Cost**: $2-5/month
- **Best of both worlds**: Serverless + CDN caching
- **Global performance**: Assets served from edge
- **Dynamic capability**: Can add backend features later

### Migration Effort
**Complexity**: ⭐⭐ (Easy-Medium)
**Time**: 1-2 hours
**Downtime**: <5 minutes

### Setup
1. Deploy to Cloud Run (same as option 1)
2. Add Cloud CDN + Load Balancer in front
3. Cache static assets (images, CSS, JS)
4. Serve HTML from Cloud Run

### Note
Adds complexity and cost compared to pure Cloud Run. Only useful if:
- High traffic (100k+ visits/month)
- Global audience (need edge caching)
- Large assets (images, videos)

**Recommendation**: Start with Cloud Run, add CDN if needed.

---

## Comparison Table

| Solution | Monthly Cost | Complexity | Downtime Risk | Auto-scale | Maintenance |
|----------|--------------|------------|---------------|------------|-------------|
| **Current (GKE)** | $115-135 | Very High | Low | Yes | High |
| **Cloud Run** ⭐ | $1-10 | Very Low | Very Low | Yes | None |
| **Compute Engine** | $0-10 | Low | Medium | No | Low |
| **Cloud Storage + CDN** | $20-25 | Medium | Very Low | N/A | None |
| **Cloud Run + CDN** | $2-5 | Medium | Very Low | Yes | None |

---

## Final Recommendation

### 🏆 Use Cloud Run

**Why?**
1. **90% cost reduction**: $1-10/month vs $115-135/month
2. **Zero maintenance**: No clusters, VMs, or updates to manage
3. **Same workflow**: Use your existing Docker container
4. **Better features**: Auto-scaling, traffic splitting, built-in monitoring
5. **5 minutes to migrate**: Minimal risk

**When NOT to use Cloud Run:**
- You need persistent local storage (Cloud Run is stateless)
- You have long-running background jobs (15min timeout on Cloud Run)
- You need specific Kubernetes features

**For your use case (static Astro blog)**: Cloud Run is perfect.

---

## Migration Path

1. **Phase 1: Deploy to Cloud Run** (Keep GKE running)
   - Deploy same container to Cloud Run
   - Test thoroughly
   - Map to test subdomain

2. **Phase 2: Switch DNS**
   - Update DNS to point to Cloud Run
   - Monitor for issues

3. **Phase 3: Cleanup**
   - Delete GKE cluster
   - Keep GCR images (minimal cost)
   - Update CI/CD to deploy to Cloud Run

**Rollback plan**: Switch DNS back to GKE IP (5 minutes)

---

## Next Steps

1. Review the Cloud Run migration guide in `cloud-run/`
2. Review the Compute Engine setup in `compute-engine/`
3. Choose your preferred solution
4. Run the migration scripts

**Questions to consider:**
- What's your monthly traffic? (affects cost estimation)
- Do you need to add dynamic features later? (affects architecture choice)
- How comfortable are you with zero downtime? (affects migration strategy)
