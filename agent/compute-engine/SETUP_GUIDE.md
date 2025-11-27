# Compute Engine Setup Guide

## Overview

Deploy your ThusSpokeRobotics blog on a **free** Google Compute Engine VM with Docker.

**Estimated time**: 1-2 hours
**Cost**: $0/month (free tier e2-micro VM)
**Downtime**: <5 minutes (DNS propagation)

---

## Prerequisites

1. **gcloud CLI** installed and authenticated
2. **GCP Project**: neural-diwan-435305
3. **Domain**: thusspokerobotics.xyz
4. **Container**: gcr.io/neural-diwan-435305/astro-blog:v1.0.0

---

## Architecture

```
Internet
   |
   v
Compute Engine VM (e2-micro - FREE)
   |
   +-- Docker
   |     |
   |     +-- Astro Blog Container (port 3000)
   |
   +-- Nginx Reverse Proxy
   |     |
   |     +-- Port 80 (HTTP) -> Redirect to HTTPS
   |     +-- Port 443 (HTTPS) -> Docker Container
   |
   +-- Certbot (Let's Encrypt SSL)
```

---

## Step-by-Step Setup

### Step 1: Create Compute Engine VM

```bash
# Create e2-micro VM (free tier eligible)
gcloud compute instances create astro-blog-vm \
  --project=neural-diwan-435305 \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --tags=http-server,https-server \
  --create-disk=auto-delete=yes,boot=yes,device-name=astro-blog-vm,image=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20241115,mode=rw,size=30,type=pd-standard \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=environment=production,app=astro-blog \
  --reservation-affinity=any

echo "VM created successfully!"
```

**Important**: Use `us-central1`, `us-west1`, or `us-east1` for free tier eligibility.

### Step 2: Create Firewall Rules

```bash
# Allow HTTP traffic
gcloud compute firewall-rules create allow-http \
  --project=neural-diwan-435305 \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

# Allow HTTPS traffic
gcloud compute firewall-rules create allow-https \
  --project=neural-diwan-435305 \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=https-server
```

### Step 3: Reserve Static IP (Optional but Recommended)

```bash
# Reserve a static external IP
gcloud compute addresses create astro-blog-ip \
  --region=us-central1 \
  --project=neural-diwan-435305

# Get the IP address
STATIC_IP=$(gcloud compute addresses describe astro-blog-ip \
  --region=us-central1 \
  --project=neural-diwan-435305 \
  --format='get(address)')

echo "Static IP: ${STATIC_IP}"

# Assign to VM
gcloud compute instances delete-access-config astro-blog-vm \
  --zone=us-central1-a \
  --project=neural-diwan-435305 \
  --access-config-name="external-nat"

gcloud compute instances add-access-config astro-blog-vm \
  --zone=us-central1-a \
  --project=neural-diwan-435305 \
  --access-config-name="external-nat" \
  --address=${STATIC_IP}
```

**Cost**: ~$7/month (you can skip this and use the ephemeral IP if VM stays running)

### Step 4: SSH into VM and Install Docker

```bash
# SSH into the VM
gcloud compute ssh astro-blog-vm \
  --zone=us-central1-a \
  --project=neural-diwan-435305
```

Once inside the VM, run:

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install -y docker-compose

# Install Nginx
sudo apt-get install -y nginx certbot python3-certbot-nginx

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
docker-compose --version
nginx -v

# Configure gcloud to authenticate with GCR
gcloud auth configure-docker

echo "Setup complete!"
```

**Exit and re-SSH** to apply the docker group membership.

### Step 5: Pull Docker Image

```bash
# SSH back into the VM
gcloud compute ssh astro-blog-vm \
  --zone=us-central1-a \
  --project=neural-diwan-435305

# Pull your Docker image from GCR
docker pull gcr.io/neural-diwan-435305/astro-blog:v1.0.0

# Test the container
docker run -d --name astro-blog-test -p 3000:3000 gcr.io/neural-diwan-435305/astro-blog:v1.0.0

# Check if it's running
curl http://localhost:3000

# Stop the test container
docker stop astro-blog-test
docker rm astro-blog-test
```

### Step 6: Create Docker Compose Configuration

Create `docker-compose.yml`:

```bash
cat > ~/docker-compose.yml << 'EOF'
version: '3.8'

services:
  astro-blog:
    image: gcr.io/neural-diwan-435305/astro-blog:v1.0.0
    container_name: astro-blog
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

# Start the container
docker-compose up -d

# Check logs
docker-compose logs -f
```

### Step 7: Configure Nginx as Reverse Proxy

Get your VM's external IP:

```bash
# On your local machine
VM_IP=$(gcloud compute instances describe astro-blog-vm \
  --zone=us-central1-a \
  --project=neural-diwan-435305 \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "VM IP: ${VM_IP}"
```

Update your DNS to point to this IP:
- `thusspokerobotics.xyz` A record -> `[VM_IP]`
- `www.thusspokerobotics.xyz` A record -> `[VM_IP]`

Back on the VM, configure Nginx:

```bash
# Create Nginx configuration
sudo tee /etc/nginx/sites-available/astro-blog << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name thusspokerobotics.xyz www.thusspokerobotics.xyz;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/astro-blog /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Step 8: Setup SSL with Let's Encrypt

```bash
# Obtain SSL certificate (wait for DNS to propagate first!)
sudo certbot --nginx -d thusspokerobotics.xyz -d www.thusspokerobotics.xyz --non-interactive --agree-tos -m your-email@example.com

# Certbot will automatically:
# 1. Obtain the certificate
# 2. Update Nginx configuration
# 3. Set up auto-renewal

# Test auto-renewal
sudo certbot renew --dry-run
```

### Step 9: Setup Auto-Update Script (Optional)

Create an update script:

```bash
cat > ~/update-blog.sh << 'EOF'
#!/bin/bash
set -e

echo "Updating Astro blog..."

# Authenticate with GCR
gcloud auth configure-docker --quiet

# Pull latest image
docker pull gcr.io/neural-diwan-435305/astro-blog:latest

# Update docker-compose.yml to use latest
sed -i 's/:v[0-9.]*/:latest/g' ~/docker-compose.yml

# Restart containers
cd ~
docker-compose pull
docker-compose up -d

# Clean up old images
docker image prune -f

echo "Update complete!"
EOF

chmod +x ~/update-blog.sh
```

### Step 10: Setup Systemd Service (Auto-start on boot)

```bash
# Create systemd service
sudo tee /etc/systemd/system/astro-blog.service << EOF
[Unit]
Description=Astro Blog Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/$(whoami)
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable astro-blog.service
sudo systemctl start astro-blog.service

# Check status
sudo systemctl status astro-blog.service
```

---

## Monitoring & Maintenance

### View Docker Logs

```bash
# SSH into VM
gcloud compute ssh astro-blog-vm --zone=us-central1-a --project=neural-diwan-435305

# View logs
docker-compose logs -f astro-blog

# Last 100 lines
docker-compose logs --tail=100 astro-blog
```

### Check Resource Usage

```bash
# CPU and memory usage
docker stats astro-blog

# Disk usage
df -h
docker system df
```

### Update the Blog

```bash
# SSH into VM
gcloud compute ssh astro-blog-vm --zone=us-central1-a --project=neural-diwan-435305

# Run update script
~/update-blog.sh
```

### Setup Automated Updates (Optional)

```bash
# Create cron job to check for updates daily at 2 AM
crontab -e

# Add this line:
0 2 * * * /home/$(whoami)/update-blog.sh >> /home/$(whoami)/update-blog.log 2>&1
```

---

## Cost Optimization

### Free Tier Limits (Always Free)

- **1 e2-micro VM**: us-central1, us-west1, or us-east1 only
- **30 GB Standard persistent disk**
- **1 GB network egress**: First 1 GB/month from North America to all regions (excluding China and Australia)

**Your blog easily fits within these limits!**

### Beyond Free Tier

If you exceed limits:
- **VM cost**: ~$7/month (if you leave us-central1)
- **Disk**: Included (30GB free)
- **Egress**: $0.12/GB after first 1GB/month
- **Static IP**: $7/month (only if VM is stopped)

**Total if optimized**: $0-10/month

---

## Backup & Disaster Recovery

### Backup Strategy

```bash
# Create VM snapshot
gcloud compute disks snapshot astro-blog-vm \
  --zone=us-central1-a \
  --project=neural-diwan-435305 \
  --snapshot-names=astro-blog-backup-$(date +%Y%m%d)

# List snapshots
gcloud compute snapshots list --project=neural-diwan-435305

# Restore from snapshot
gcloud compute instances create astro-blog-vm-restored \
  --source-snapshot=astro-blog-backup-YYYYMMDD \
  --zone=us-central1-a \
  --project=neural-diwan-435305
```

### Automated Backups

```bash
# Create weekly backup schedule
gcloud compute resource-policies create snapshot-schedule weekly-backup \
  --region=us-central1 \
  --max-retention-days=30 \
  --on-source-disk-delete=keep-auto-snapshots \
  --weekly-schedule-from-file=- << EOF
{
  "daysInCycle": 7,
  "startTime": "04:00"
}
EOF

# Attach to disk
gcloud compute disks add-resource-policies astro-blog-vm \
  --resource-policies=weekly-backup \
  --zone=us-central1-a \
  --project=neural-diwan-435305
```

**Cost**: ~$0.026/GB/month (~$0.78/month for 30GB disk)

---

## Security Best Practices

### 1. Setup Firewall

```bash
# Allow only HTTP/HTTPS, block everything else
gcloud compute firewall-rules create deny-all \
  --project=neural-diwan-435305 \
  --direction=INGRESS \
  --priority=65534 \
  --network=default \
  --action=DENY \
  --rules=all \
  --source-ranges=0.0.0.0/0

# SSH only from your IP
gcloud compute firewall-rules create allow-ssh-from-my-ip \
  --project=neural-diwan-435305 \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=[YOUR_IP]/32
```

### 2. Enable Automatic Security Updates

```bash
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 3. Setup Fail2Ban (SSH brute-force protection)

```bash
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 4. Regular Updates

```bash
# Create update script
cat > ~/system-update.sh << 'EOF'
#!/bin/bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y
EOF

chmod +x ~/system-update.sh

# Run weekly via cron
crontab -e
# Add: 0 3 * * 0 /home/$(whoami)/system-update.sh
```

---

## Troubleshooting

### Issue: Container not starting

```bash
# Check logs
docker-compose logs astro-blog

# Check if port is already in use
sudo netstat -tlnp | grep 3000

# Restart container
docker-compose restart astro-blog
```

### Issue: Nginx 502 Bad Gateway

```bash
# Check if Docker container is running
docker ps

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

### Issue: SSL certificate not renewing

```bash
# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Check certbot timer
sudo systemctl status certbot.timer
```

### Issue: Running out of disk space

```bash
# Clean Docker images
docker system prune -a

# Clean package cache
sudo apt-get clean
sudo apt-get autoremove -y

# Check disk usage
df -h
du -sh /var/lib/docker
```

---

## Comparison: Compute Engine vs Cloud Run

| Feature | Compute Engine | Cloud Run |
|---------|----------------|-----------|
| **Cost** | $0-10/month | $1-10/month |
| **Complexity** | Medium | Very Low |
| **Maintenance** | You manage | Google manages |
| **Scaling** | Manual | Automatic |
| **Cold starts** | None | Yes (unless min-instances=1) |
| **SSH access** | Yes | No |
| **Custom software** | Anything | Containers only |
| **Free tier** | Yes (e2-micro) | Yes (generous) |

**When to use Compute Engine:**
- You want FREE (and stay within free tier)
- You need SSH access
- You want to run multiple services
- You're comfortable with Linux administration

**When to use Cloud Run:**
- You want simplicity (zero maintenance)
- You don't need SSH access
- You prefer managed services
- You want auto-scaling

---

## Migration from GKE

### DNS Update

1. Get your VM's external IP:
   ```bash
   gcloud compute instances describe astro-blog-vm \
     --zone=us-central1-a \
     --project=neural-diwan-435305 \
     --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
   ```

2. Update DNS records:
   - Change `thusspokerobotics.xyz` A record from `34.31.187.182` to `[VM_IP]`
   - Change `www.thusspokerobotics.xyz` A record from `34.31.187.182` to `[VM_IP]`

3. Wait 5-30 minutes for DNS propagation

4. Test:
   ```bash
   curl -I https://thusspokerobotics.xyz
   ```

### Cleanup GKE

After verifying everything works for 1-7 days:

```bash
# Delete GKE cluster
gcloud container clusters list --project=neural-diwan-435305
gcloud container clusters delete [CLUSTER_NAME] --region [REGION] --project=neural-diwan-435305

# Release old static IP (if not needed)
gcloud compute addresses delete [OLD_IP_NAME] --region [REGION] --project=neural-diwan-435305
```

---

## Success Checklist

- [ ] VM created (e2-micro in free tier region)
- [ ] Firewall rules configured
- [ ] Docker installed and running
- [ ] Docker image pulled from GCR
- [ ] Docker Compose configured
- [ ] Nginx configured as reverse proxy
- [ ] DNS records updated
- [ ] SSL certificate obtained (Let's Encrypt)
- [ ] HTTPS working (https://thusspokerobotics.xyz)
- [ ] Systemd service enabled (auto-start on boot)
- [ ] Monitoring setup (logs, resource usage)
- [ ] Backup strategy implemented
- [ ] Security hardening complete
- [ ] Tested in production for 1-7 days
- [ ] GKE cluster deleted

---

## Quick Commands Reference

```bash
# SSH into VM
gcloud compute ssh astro-blog-vm --zone=us-central1-a --project=neural-diwan-435305

# View logs
docker-compose logs -f astro-blog

# Restart container
docker-compose restart astro-blog

# Update blog
~/update-blog.sh

# Check Nginx status
sudo systemctl status nginx

# Check SSL certificate expiry
sudo certbot certificates

# Check disk usage
df -h && docker system df
```
