# Cost Calculator & ROI Analysis

## Current Monthly Costs (GKE)

### Fixed Costs
| Service | Cost | Notes |
|---------|------|-------|
| GKE Control Plane | $74.00 | Standard regional cluster |
| Reserved Static IP | $7.00 | When not attached to running LB |
| **Subtotal (Fixed)** | **$81.00** | **Minimum cost even with zero traffic** |

### Variable Costs
| Service | Cost | Usage | Notes |
|---------|------|-------|-------|
| Node Pool (e2-small spot) | $12-15.00 | 730 hrs/month | Spot/preemptible pricing |
| LoadBalancer | $18-20.00 | 1 forwarding rule | $0.025/hour + processing |
| Network Egress | $5-10.00 | ~50-100GB | $0.12/GB (Americas) |
| Persistent Disk | $1-2.00 | ~30GB SSD | For cluster storage |
| **Subtotal (Variable)** | **$36-47.00** | | |

### Additional Services
| Service | Cost | Notes |
|---------|------|-------|
| GCR Storage | $0.50-1.00 | ~20GB images |
| Cloud Logging | $2-5.00 | Log storage & queries |
| Cloud Monitoring | $1-3.00 | Metrics & dashboards |
| **Subtotal (Additional)** | **$3.50-9.00** | | |

### **Total Current Cost**
```
Fixed:      $81.00
Variable:   $36-47.00
Additional: $3.50-9.00
────────────────────
TOTAL:      $120.50-137.00/month
```

**Average**: **$128.75/month** or **$1,545/year**

---

## Proposed Costs

### Option 1: Cloud Run

#### Free Tier (Always Free)
| Resource | Free Tier Limit | Your Usage | Within Free? |
|----------|-----------------|------------|--------------|
| Requests | 2M requests/month | ~50k | ✅ Yes |
| CPU-time | 360k vCPU-seconds | ~10k | ✅ Yes |
| Memory-time | 180k GiB-seconds | ~5k | ✅ Yes |
| Network Egress (NA) | 1 GB/month | ~50-100GB | ❌ No |

#### Billable Costs
| Service | Cost | Usage | Calculation |
|---------|------|-------|-------------|
| Requests | $0.00 | 50k/month | Within free tier (2M limit) |
| vCPU-seconds | $0.00 | 10k/month | Within free tier (360k limit) |
| Memory | $0.00 | 5k GiB-sec | Within free tier (180k limit) |
| Network Egress | $6-12.00 | 50-100GB | $0.12/GB |
| GCR Storage | $0.50-1.00 | ~20GB images | Same as current |
| **TOTAL** | **$6.50-13.00/month** | | |

#### Cost with Higher Traffic (100k visitors/month)
| Service | Cost | Usage | Calculation |
|---------|------|-------|-------------|
| Requests | $0.00 | 500k/month | Still within free tier |
| vCPU-seconds | $0.00 | ~50k/month | Still within free tier |
| Memory | $0.00 | ~25k GiB-sec | Still within free tier |
| Network Egress | $24-36.00 | 200-300GB | $0.12/GB |
| GCR Storage | $0.50-1.00 | ~20GB images | Same as current |
| **TOTAL** | **$24.50-37.00/month** | | |

**Savings at 10k visitors**: **$115.75/month** (90% reduction)
**Savings at 100k visitors**: **$91.75/month** (71% reduction)

---

### Option 2: Compute Engine (Free Tier)

#### Free Tier (Always Free in us-central1/us-west1/us-east1)
| Resource | Free Tier Limit | Your Usage | Within Free? |
|----------|-----------------|------------|--------------|
| e2-micro VM | 1 instance | 1 | ✅ Yes |
| Standard PD | 30 GB | 30 GB | ✅ Yes |
| Network Egress (NA) | 1 GB/month | ~50-100GB | ❌ No |
| Snapshots | Not included | Optional | ❌ No |

#### Billable Costs
| Service | Cost | Usage | Calculation |
|---------|------|-------|-------------|
| e2-micro VM | $0.00 | 730 hrs | Always free tier |
| 30GB Standard PD | $0.00 | 30 GB | Always free tier |
| Network Egress | $6-12.00 | 50-100GB | $0.12/GB (first 1GB free) |
| Snapshots (weekly) | $0.78 | 30GB backup | $0.026/GB/month |
| GCR Storage | $0.50-1.00 | ~20GB images | Same as current |
| **TOTAL** | **$7.28-13.78/month** | | |

#### Cost Outside Free Tier Regions
| Service | Cost | Usage | Calculation |
|---------|------|-------|-------------|
| e2-micro VM | $7.11 | 730 hrs | $0.00974/hour |
| 30GB Standard PD | $0.80 | 30 GB | $0.040/GB/month |
| Static IP (active) | $0.00 | Attached | Free when attached |
| Network Egress | $6-12.00 | 50-100GB | $0.12/GB |
| Snapshots | $0.78 | 30GB | $0.026/GB/month |
| GCR Storage | $0.50-1.00 | ~20GB images | Same as current |
| **TOTAL** | **$15.19-21.69/month** | | |

**Savings (free tier)**: **$121.47/month** (94% reduction)
**Savings (paid region)**: **$113.06/month** (88% reduction)

---

### Option 3: Cloud Storage + Cloud CDN (NOT RECOMMENDED)

#### Monthly Costs
| Service | Cost | Usage | Calculation |
|---------|------|-------|-------------|
| Cloud Storage | $0.05 | 2GB (dist) | $0.026/GB/month |
| Cloud CDN | $4-8.00 | 50-100GB | $0.04-0.08/GB (varies by region) |
| Cloud Load Balancer | $18.26 | 730 hrs | $0.025/hour + $0.01/GB processed |
| Cloud DNS | $0.60 | 1 zone | $0.40/zone + $0.40/1M queries |
| GCR Storage | $0.50-1.00 | ~20GB images | Same as current |
| **TOTAL** | **$23.41-27.91/month** | | |

**Savings**: **$105.34/month** (82% reduction)

**Why NOT recommended**: Adds complexity for minimal savings vs Cloud Run. Load Balancer alone costs $18/month. Only worth it for:
- **Very high traffic** (500k+ visitors/month)
- **Global audience** (need edge caching)
- **Large static assets** (videos, large images)

For your blog: **Cloud Run or Compute Engine are better options.**

---

## ROI Analysis

### Cloud Run Migration

| Metric | Value |
|--------|-------|
| **Migration Time** | 30 minutes |
| **Migration Cost** | $0 (no downtime charges) |
| **Monthly Savings** | $115.75 |
| **Annual Savings** | $1,389 |
| **Payback Period** | Immediate |
| **3-Year Savings** | $4,167 |
| **5-Year Savings** | $6,945 |

**Time ROI**: Even if you value your time at $200/hour, you break even in the first month.

### Compute Engine Migration (Free Tier)

| Metric | Value |
|--------|-------|
| **Migration Time** | 1-2 hours |
| **Migration Cost** | $0 |
| **Monthly Savings** | $121.47 |
| **Annual Savings** | $1,458 |
| **Payback Period** | Immediate |
| **3-Year Savings** | $4,374 |
| **5-Year Savings** | $7,290 |

**Time ROI**: At $200/hour, you break even in the first month (0.5 months if 2 hour migration).

---

## Traffic-Based Cost Projections

### Monthly Visitors vs Cost

| Monthly Visitors | Current (GKE) | Cloud Run | Compute Engine | Best Option |
|------------------|---------------|-----------|----------------|-------------|
| 1,000 | $128.75 | $4-6 | $7.28 | Cloud Run |
| 10,000 | $128.75 | $6.50-13 | $7.28-13.78 | Either |
| 50,000 | $128.75 | $15-25 | $10-20 | Compute Engine |
| 100,000 | $128.75 | $24.50-37 | $15-30 | Compute Engine |
| 500,000 | $145-180 | $80-120 | $50-100 | Compute Engine + CDN |
| 1,000,000+ | $200-300 | $150-250 | $100-200 | Cloud Run + CDN |

**Sweet spots**:
- **Cloud Run**: 1k-50k visitors (simplicity wins)
- **Compute Engine**: 10k-500k visitors (best cost per visitor)
- **Cloud Run + CDN**: 1M+ visitors (managed auto-scaling)

---

## Growth Scenarios

### Scenario 1: Blog Stays Small (10k visitors/month)

| Year | GKE Cost | Cloud Run Cost | Savings | Cumulative Savings |
|------|----------|----------------|---------|---------------------|
| 1 | $1,545 | $78-156 | $1,389-1,467 | $1,389-1,467 |
| 2 | $1,545 | $78-156 | $1,389-1,467 | $2,778-2,934 |
| 3 | $1,545 | $78-156 | $1,389-1,467 | $4,167-4,401 |

**3-year savings**: **$4,167-4,401**

### Scenario 2: Blog Grows Moderately (100k visitors/month by year 2)

| Year | GKE Cost | Cloud Run Cost | Savings | Cumulative Savings |
|------|----------|----------------|---------|---------------------|
| 1 | $1,545 | $78-156 | $1,389-1,467 | $1,389-1,467 |
| 2 | $1,545 | $294-444 | $1,101-1,251 | $2,490-2,718 |
| 3 | $1,545 | $294-444 | $1,101-1,251 | $3,591-3,969 |

**3-year savings**: **$3,591-3,969**

### Scenario 3: Blog Explodes (500k visitors/month by year 2)

| Year | GKE Cost | Cloud Run Cost | Compute Engine | Best Choice | Savings |
|------|----------|----------------|----------------|-------------|---------|
| 1 | $1,545 | $78-156 | $87-165 | Cloud Run | $1,389-1,467 |
| 2 | $1,740-2,160 | $960-1,440 | $600-1,200 | Compute Engine | $540-1,560 |
| 3 | $1,740-2,160 | $960-1,440 | $600-1,200 | Compute Engine | $540-1,560 |

**3-year savings**: **$2,469-4,587**

**Note**: At high traffic, consider:
- Multiple VMs with load balancing
- Cloud CDN for caching
- Hybrid: Cloud Run + CDN

---

## Hidden Costs & Considerations

### Current GKE Hidden Costs
- ❌ Time spent maintaining cluster (upgrades, patches)
- ❌ Time debugging Kubernetes issues
- ❌ Mental overhead of complex infrastructure
- ❌ Risk of cluster misconfiguration (security/cost)

**Estimated time cost**: 2-4 hours/month = **$400-800/month** at $200/hour

### Cloud Run Hidden Savings
- ✅ Zero maintenance time
- ✅ No cluster upgrades
- ✅ No certificate management (automatic)
- ✅ No scaling configuration

**Time saved**: 2-4 hours/month = **$400-800/month**

### Compute Engine Hidden Costs
- ⚠️ VM maintenance (updates, monitoring) ~1 hour/month
- ⚠️ SSL renewal (automated but requires setup)
- ⚠️ Scaling requires manual intervention

**Time cost**: ~1 hour/month = **$200/month** at $200/hour

---

## Break-Even Analysis

### Cloud Run
- **Upfront cost**: $0 (no migration fees)
- **Time investment**: 30 minutes ($100 at $200/hour)
- **Monthly savings**: $115.75
- **Break-even**: **1 month** (pays for time investment)

### Compute Engine
- **Upfront cost**: $0
- **Time investment**: 1-2 hours ($200-400 at $200/hour)
- **Monthly savings**: $121.47
- **Break-even**: **2 months** (pays for time investment)

---

## Decision Matrix

### Choose **Cloud Run** if:
| Factor | Weight | Score |
|--------|--------|-------|
| Simplicity important | High | 10/10 |
| Don't want maintenance | High | 10/10 |
| Traffic is low (<50k/mo) | Medium | 8/10 |
| Value time over money | High | 10/10 |
| **Total Score** | | **9.5/10** ✅ |

### Choose **Compute Engine** if:
| Factor | Weight | Score |
|--------|--------|-------|
| Want FREE | High | 10/10 |
| Need SSH access | Medium | 10/10 |
| Comfortable with Linux | High | 9/10 |
| Traffic is high (>50k/mo) | Medium | 9/10 |
| **Total Score** | | **9.5/10** ✅ |

### Keep **GKE** if:
| Factor | Weight | Score |
|--------|--------|-------|
| Need Kubernetes features | High | 0/10 (you don't) |
| Have multiple services | High | 0/10 (you don't) |
| Complex microservices | High | 0/10 (you don't) |
| **Total Score** | | **0/10** ❌ |

---

## Recommendation

### For Your Use Case (ThusSpokeRobotics Static Blog)

**Current traffic**: Low (assuming <10k visitors/month)
**Technical comfort**: High (you set up GKE, so you can handle anything)
**Priority**: Cost savings + Simplicity

### 🏆 Winner: **Cloud Run**

**Why**:
1. **90% cost reduction** ($128.75 → $6.50-13/month)
2. **Zero maintenance** (saves 2-4 hours/month)
3. **30-minute migration** (minimal time investment)
4. **Auto-scaling** (handles traffic spikes automatically)
5. **Same workflow** (use same Docker images)

**ROI**:
- **Monthly**: Save $115.75 + 2-4 hours
- **Annual**: Save $1,389 + 24-48 hours
- **3-Year**: Save $4,167 + 72-144 hours

### Alternative: **Compute Engine** (if you want FREE)

**Why**:
1. **94% cost reduction** ($128.75 → $7.28/month or $0 in free tier)
2. **Full control** (SSH access, run anything)
3. **1-2 hour migration** (still quick)
4. **No cold starts** (always on)

**Trade-off**: Slightly more maintenance (1 hour/month vs 0)

---

## Next Steps

1. ✅ **Decide**: Cloud Run (simple) or Compute Engine (free)
2. ✅ **Read**: Migration guide for your choice
3. ✅ **Migrate**: Follow step-by-step instructions
4. ✅ **Monitor**: Keep GKE running for 1 week as backup
5. ✅ **Celebrate**: Delete GKE and save $1,389/year!

**Questions?** Review the detailed guides in:
- `cloud-run/MIGRATION_GUIDE.md`
- `compute-engine/SETUP_GUIDE.md`
