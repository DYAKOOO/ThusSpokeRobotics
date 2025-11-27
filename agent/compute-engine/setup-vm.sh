#!/bin/bash

# Automated VM Setup Script for ThusSpokeRobotics Blog
# Run this script after SSH-ing into your new VM

set -e

echo "============================================"
echo "ThusSpokeRobotics Blog VM Setup Script"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="thusspokerobotics.xyz"
EMAIL="your-email@example.com"  # Change this!
IMAGE="gcr.io/neural-diwan-435305/astro-blog:v1.0.0"

echo -e "${YELLOW}This script will install and configure:${NC}"
echo "  - Docker & Docker Compose"
echo "  - Nginx reverse proxy"
echo "  - Let's Encrypt SSL (Certbot)"
echo "  - Astro blog container"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
    echo "Setup cancelled."
    exit 0
fi

# Update system
echo -e "\n${GREEN}[1/8] Updating system packages...${NC}"
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
echo -e "\n${GREEN}[2/8] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}Docker installed successfully${NC}"
else
    echo -e "${YELLOW}Docker already installed${NC}"
fi

# Install Docker Compose
echo -e "\n${GREEN}[3/8] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    sudo apt-get install -y docker-compose
    echo -e "${GREEN}Docker Compose installed successfully${NC}"
else
    echo -e "${YELLOW}Docker Compose already installed${NC}"
fi

# Install Nginx and Certbot
echo -e "\n${GREEN}[4/8] Installing Nginx and Certbot...${NC}"
sudo apt-get install -y nginx certbot python3-certbot-nginx

# Enable and start services
echo -e "\n${GREEN}[5/8] Enabling services...${NC}"
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl enable nginx
sudo systemctl start nginx

# Configure Docker to use GCR
echo -e "\n${GREEN}[6/8] Configuring Docker for GCR...${NC}"
gcloud auth configure-docker --quiet

# Pull Docker image
echo -e "\n${GREEN}[7/8] Pulling Docker image...${NC}"
docker pull ${IMAGE}

# Create docker-compose.yml
echo -e "\n${GREEN}[8/8] Creating Docker Compose configuration...${NC}"
cat > ~/docker-compose.yml << 'COMPOSE_EOF'
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
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
COMPOSE_EOF

# Start Docker container
echo -e "\n${GREEN}Starting Docker container...${NC}"
docker-compose up -d

# Wait for container to be healthy
echo -e "${YELLOW}Waiting for container to start...${NC}"
sleep 10

# Test container
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}Container is running successfully!${NC}"
else
    echo -e "${RED}Warning: Container may not be running correctly${NC}"
    docker-compose logs
fi

# Configure Nginx
echo -e "\n${GREEN}Configuring Nginx...${NC}"
sudo tee /etc/nginx/sites-available/astro-blog << 'NGINX_EOF'
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
NGINX_EOF

sudo ln -sf /etc/nginx/sites-available/astro-blog /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
if sudo nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
    sudo systemctl reload nginx
else
    echo -e "${RED}Nginx configuration error${NC}"
    exit 1
fi

# Create systemd service for auto-start
echo -e "\n${GREEN}Creating systemd service...${NC}"
sudo tee /etc/systemd/system/astro-blog.service << SYSTEMD_EOF
[Unit]
Description=Astro Blog Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/${USER}
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=${USER}

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

sudo systemctl daemon-reload
sudo systemctl enable astro-blog.service

# Create update script
echo -e "\n${GREEN}Creating update script...${NC}"
cat > ~/update-blog.sh << 'UPDATE_EOF'
#!/bin/bash
set -e
echo "Updating Astro blog..."
gcloud auth configure-docker --quiet
docker pull gcr.io/neural-diwan-435305/astro-blog:latest
sed -i 's/:v[0-9.]*/:latest/g' ~/docker-compose.yml
cd ~
docker-compose pull
docker-compose up -d
docker image prune -f
echo "Update complete!"
UPDATE_EOF

chmod +x ~/update-blog.sh

echo -e "\n${GREEN}============================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Update your DNS records:"
echo "   thusspokerobotics.xyz A record -> $(curl -s ifconfig.me)"
echo "   www.thusspokerobotics.xyz A record -> $(curl -s ifconfig.me)"
echo ""
echo "2. Wait for DNS propagation (5-30 minutes)"
echo ""
echo "3. Run Certbot to get SSL certificate:"
echo "   sudo certbot --nginx -d thusspokerobotics.xyz -d www.thusspokerobotics.xyz -m ${EMAIL} --agree-tos --non-interactive"
echo ""
echo "4. Test your site:"
echo "   http://$(curl -s ifconfig.me)"
echo "   https://thusspokerobotics.xyz (after SSL setup)"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  View logs:     docker-compose logs -f"
echo "  Restart blog:  docker-compose restart"
echo "  Update blog:   ~/update-blog.sh"
echo "  Check status:  docker-compose ps"
echo ""
echo -e "${RED}IMPORTANT:${NC} You may need to log out and back in for Docker group membership to take effect."
echo ""
