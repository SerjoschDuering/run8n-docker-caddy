# CapRover Integration Reference for ARM Stack

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [ARM64 Compatibility](#arm64-compatibility)
3. [Hetzner Cloud Specific Setup](#hetzner-cloud-specific-setup)
4. [Integration with Existing Caddy Setup](#integration-with-existing-caddy-setup)
5. [Docker Compose Integration](#docker-compose-integration)
6. [Database Integration](#database-integration)
7. [S3/Backblaze Storage Integration](#s3backblaze-storage-integration)
8. [Subdomain Routing Configuration](#subdomain-routing-configuration)
9. [Resource Requirements](#resource-requirements)
10. [Security Considerations](#security-considerations)
11. [Deployment Workflows](#deployment-workflows)
12. [Configuration Examples](#configuration-examples)
13. [Potential Conflicts](#potential-conflicts)
14. [Implementation Recommendations](#implementation-recommendations)

## Architecture Overview

CapRover is a free, open-source Platform-as-a-Service (PaaS) that provides:

- **Container Orchestration**: Uses Docker Swarm for container management
- **Reverse Proxy**: Built-in nginx for load balancing and routing
- **SSL Management**: Automatic Let's Encrypt SSL certificate provisioning
- **Web Interface**: Simple dashboard for app deployment and management
- **One-Click Apps**: Pre-configured applications and databases

### Core Components
- **Docker Engine**: Container runtime and API
- **nginx**: Reverse proxy and load balancer (fully customizable)
- **Let's Encrypt**: Automatic SSL certificate management
- **NetData**: System monitoring (optional)
- **Docker Swarm**: Container orchestration

## ARM64 Compatibility

✅ **Fully Supported as of 2024**

- Official Docker images support ARM64, AMD64, and ARMV7
- CapRover source code is architecture-agnostic
- Multi-architecture Docker builds: `docker buildx build --platform linux/arm64,linux/amd64`
- Tested on Ubuntu 22.04 with Docker 25+

### Historical Context
- Earlier versions didn't support ARM64
- Current versions (2024) provide official multi-architecture support
- No need for custom ARM64 builds

## Hetzner Cloud Specific Setup

### Prerequisites
- **Minimum VPS**: CX11 (1 vCPU, 2GB RAM, 20GB disk) - $3/month
- **Recommended**: CX21 (2 vCPU, 4GB RAM, 40GB disk) for production
- **ARM64 Support**: Hetzner Cloud ARM64 servers are fully supported and show excellent performance

### Required Firewall Ports
**Essential CapRover Ports:**
```bash
# HTTP/HTTPS for applications
80/tcp    # HTTP traffic
443/tcp   # HTTPS traffic
3000/tcp  # CapRover dashboard

# Docker Swarm (if using clustering)
2377/tcp  # Docker Swarm management
7946/tcp  # Docker Swarm node communication
7946/udp  # Docker Swarm node communication
4789/udp  # Docker overlay network

# Optional monitoring
996/tcp   # NetData monitoring (if enabled)
```

**Hetzner Cloud Firewall Configuration:**
```bash
# UFW commands for server-level firewall
ufw allow 80,443,3000,996,7946,4789,2377/tcp
ufw allow 7946,4789,2377/udp
ufw enable
```

**Hetzner Cloud Console Firewall Rules:**
1. **Inbound Rules:**
   - HTTP: Port 80, Source: 0.0.0.0/0
   - HTTPS: Port 443, Source: 0.0.0.0/0
   - CapRover Dashboard: Port 3000, Source: Your IP or 0.0.0.0/0
   - Docker Swarm: Ports 2377,7946,4789, Source: Internal network only

2. **Outbound Rules:**
   - Allow all outbound traffic (required for Let's Encrypt, Docker pulls)

### DNS Configuration for forms.run8n.xyz and sites.run8n.xyz

**Wildcard DNS Setup:**
```dns
# Required A records
*.forms.run8n.xyz    A    <HETZNER_SERVER_IP>
*.sites.run8n.xyz    A    <HETZNER_SERVER_IP>
forms.run8n.xyz      A    <HETZNER_SERVER_IP>
sites.run8n.xyz      A    <HETZNER_SERVER_IP>
```

**DNS Verification:**
```bash
# Test DNS resolution
nslookup forms.run8n.xyz
nslookup test.forms.run8n.xyz
nslookup sites.run8n.xyz
nslookup test.sites.run8n.xyz
```

### SSL Certificate Management Behind Caddy

**Challenge: Dual SSL Management**
- Caddy handles SSL termination for run8n.xyz
- CapRover wants to manage SSL for forms/sites subdomains
- Solution: Use `skipVerifyingDomains` configuration

**Configuration Steps:**
1. **Disable CapRover Domain Verification:**
```bash
# On Hetzner server after CapRover installation
echo '{"skipVerifyingDomains":"true"}' > /captain/data/config-override.json
docker service update captain-captain --force
```

2. **Caddy Configuration for Subdomain Delegation:**
```caddyfile
# Main Caddyfile on primary server
*.run8n.xyz {
    @forms host forms.run8n.xyz, *.forms.run8n.xyz
    handle @forms {
        reverse_proxy <HETZNER_SERVER_IP>:80 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
        }
    }

    @sites host sites.run8n.xyz, *.sites.run8n.xyz
    handle @sites {
        reverse_proxy <HETZNER_SERVER_IP>:80 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
        }
    }

    # Existing services continue unchanged
    # ... other routes
}
```

### Docker Socket Security on Hetzner

**Security Implications:**
- CapRover requires Docker socket access: `/var/run/docker.sock`
- This grants container root-level access to Docker daemon
- On Hetzner Cloud, additional security measures recommended

**Mitigation Strategies:**

1. **Server-Level Security:**
```bash
# Harden SSH access
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Setup fail2ban
apt install fail2ban
systemctl enable fail2ban
```

2. **Docker Socket Protection:**
```bash
# Create docker group and add non-root user
groupadd docker
usermod -aG docker $USER

# Set proper socket permissions
chmod 660 /var/run/docker.sock
chgrp docker /var/run/docker.sock
```

3. **Hetzner Cloud Security Groups:**
   - Create dedicated security group for CapRover server
   - Restrict port 3000 access to your IP only
   - Use internal networking for database connections

### Network Configuration for ARM64 Containers

**Docker Daemon Configuration:**
```json
# /etc/docker/daemon.json
{
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "default-runtime": "runc",
  "runtimes": {
    "runc": {
      "path": "runc"
    }
  }
}
```

**ARM64 Container Considerations:**
- Most popular images now support ARM64
- Use multi-arch images: `image:latest` typically includes ARM64
- For ARM64-specific builds: `image:latest-arm64`
- Check Docker Hub for architecture support

### Backup Strategies: Hetzner + Backblaze

**1. CapRover Data Backup:**
```bash
# Backup captain data directory
tar -czf captain-backup-$(date +%Y%m%d).tar.gz /captain

# Upload to Backblaze B2
export B2_APPLICATION_KEY_ID="your-key-id"
export B2_APPLICATION_KEY="your-key"
b2 upload-file your-bucket captain-backup-$(date +%Y%m%d).tar.gz captain-backup-$(date +%Y%m%d).tar.gz
```

**2. Database Backups:**
```bash
# PostgreSQL backup for CapRover apps
docker exec srv-captain--postgres pg_dump -U postgres dbname > backup.sql

# Upload to Backblaze
b2 upload-file your-bucket backup.sql postgres-backup-$(date +%Y%m%d).sql
```

**3. Application Data Backup:**
```bash
# Backup Docker volumes used by CapRover apps
docker run --rm -v captain-app-data:/data -v /tmp:/backup alpine tar czf /backup/app-data-backup.tar.gz /data

# Upload to Backblaze
b2 upload-file your-bucket /tmp/app-data-backup.tar.gz app-data-backup-$(date +%Y%m%d).tar.gz
```

### Hetzner-Specific Considerations

**1. Volume Mounting:**
- Use Hetzner Cloud Volumes for persistent data
- Mount volumes to `/captain` for CapRover data persistence
- Configure automatic backups through Hetzner Console

**2. Networking:**
- Use Hetzner private networks for database connections
- Configure internal IPs for service communication
- Enable IPv6 if your applications support it

**3. Security Groups:**
```bash
# Hetzner Cloud firewall via API
curl -H "Authorization: Bearer $HETZNER_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST https://api.hetzner.cloud/v1/firewalls \
  -d '{
    "name": "caprover-firewall",
    "rules": [
      {"direction": "in", "port": "80", "protocol": "tcp", "source_ips": ["0.0.0.0/0", "::/0"]},
      {"direction": "in", "port": "443", "protocol": "tcp", "source_ips": ["0.0.0.0/0", "::/0"]},
      {"direction": "in", "port": "3000", "protocol": "tcp", "source_ips": ["YOUR_IP/32"]}
    ]
  }'
```

**4. Hetzner DNS Integration:**
- Hetzner DNS API can be used for automatic DNS management
- Useful for Let's Encrypt DNS-01 challenges
- Can automate subdomain creation for new CapRover apps

### Installation Command for Hetzner Cloud

```bash
# One-command CapRover installation
docker run -p 80:80 -p 443:443 -p 3000:3000 \
  -e ACCEPTED_TERMS=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /captain:/captain \
  caprover/caprover

# Initial setup after installation
# 1. Visit http://YOUR_HETZNER_IP:3000
# 2. Login with password: captain42
# 3. Change password immediately
# 4. Configure domain: forms.run8n.xyz or sites.run8n.xyz
# 5. Enable HTTPS with Let's Encrypt
# 6. Apply skipVerifyingDomains if behind Caddy
```

### Specific Technical Q&A

**Q1: What exact firewall ports need to be open on Hetzner for CapRover?**
```bash
# Minimum required ports
80/tcp    # HTTP (apps and Let's Encrypt challenges)
443/tcp   # HTTPS (secure app access)
3000/tcp  # CapRover dashboard (restrict to your IP)

# Additional ports for clustering/advanced features
2377/tcp  # Docker Swarm management
7946/tcp  # Docker Swarm node communication
7946/udp  # Docker Swarm node communication
4789/udp  # Docker overlay network
996/tcp   # NetData monitoring (optional)
```

**Q2: How does CapRover handle SSL when running on non-standard ports (8080/8443)?**
- CapRover's nginx can be configured to run on custom ports
- Let's Encrypt challenges still work via HTTP-01 on port 80 (proxied)
- Use `skipVerifyingDomains: true` to bypass domain verification issues
- SSL certificates are still valid when accessed through Caddy proxy

**Q3: Can CapRover work without direct port 80/443 access (behind Caddy)?**
Yes, but requires specific configuration:
```bash
# CapRover on custom ports
docker run -p 8080:80 -p 8443:443 -p 3000:3000 caprover/caprover

# Caddy proxies to CapRover
reverse_proxy <hetzner-ip>:8080
```

**Q4: Security implications of mounting Docker socket in Hetzner environment?**
- **High Risk**: Container gets root access to Docker daemon
- **Mitigation**: Use dedicated server, proper firewall rules, SSH hardening
- **Best Practice**: Restrict CapRover dashboard to your IP only
- **Monitoring**: Enable fail2ban and regular security updates

**Q5: How to configure DNS delegation from Caddy to CapRover for subdomains?**
```caddyfile
# Delegate entire subdomain to CapRover server
*.forms.run8n.xyz, forms.run8n.xyz {
    reverse_proxy <HETZNER_SERVER_IP>:80 {
        header_up Host {host}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

**Q6: Does CapRover need special network configuration for ARM64 containers?**
No special configuration needed:
- CapRover automatically detects ARM64 architecture
- Multi-arch Docker images work seamlessly
- Use `docker buildx` for custom ARM64 builds if needed

**Q7: What backup strategies work with Hetzner + Backblaze for CapRover apps?**
```bash
# Automated backup script
#!/bin/bash
# Backup CapRover data
tar -czf /tmp/captain-backup.tar.gz /captain
docker exec postgres pg_dumpall > /tmp/db-backup.sql

# Upload to Backblaze B2
b2 upload-file bucket-name /tmp/captain-backup.tar.gz
b2 upload-file bucket-name /tmp/db-backup.sql
```

## Integration with Existing Caddy Setup

⚠️ **Complex Integration - Not Officially Supported**

### Challenges
1. **Dual Reverse Proxy Conflict**: CapRover uses nginx internally, creating potential conflicts with Caddy
2. **SSL Certificate Management**: Both systems want to handle Let's Encrypt certificates
3. **Domain Verification**: CapRover requires A records pointing directly to its IP
4. **Port Binding**: Both systems compete for ports 80/443

### Possible Integration Approaches

#### Option 1: CapRover Behind Caddy (Not Recommended)
```
Internet → Caddy (ports 80/443) → CapRover (custom ports) → Apps
```

**Issues:**
- Requires domain verification skipping: `echo '{"skipVerifyingDomains":"true"}' > /captain/data/config-override.json`
- SSL termination conflicts
- Officially unsupported

#### Option 2: Separate Port Ranges
```yaml
# Caddy handles existing services
caddy:
  ports:
    - "80:80"
    - "443:443"

# CapRover on different ports
caprover:
  ports:
    - "8080:80"
    - "8443:443"
```

#### Option 3: Separate Subdomains
- Caddy: `*.run8n.xyz` (existing services)
- CapRover: `forms.run8n.xyz`, `sites.run8n.xyz`

### Recommended Approach
Use **separate subdomain delegation** where Caddy proxies specific subdomains to CapRover:

```caddyfile
forms.run8n.xyz {
    reverse_proxy caprover:3000
}

sites.run8n.xyz {
    reverse_proxy caprover:3000
}
```

## Docker Compose Integration

⚠️ **Limited Support**

### Supported Parameters
- `image`
- `environment`
- `ports`
- `volumes`
- `depends_on`
- `hostname`

### Unsupported Features
- Complex networking configurations
- Custom bridge networks
- Advanced Docker Compose features

### Integration Methods

#### Method 1: One-Click App Template
1. Go to "One Click Apps/Databases"
2. Select "TEMPLATE"
3. Add CapRover template header:
```yaml
captainVersion: 4
caproverOneClickApp:
  variables: []
  instructions:
    start: Your docker-compose converted to CapRover
  displayName: Custom Stack
  description: Converted docker-compose stack
services:
  ########
  # Your docker-compose.yml content here (modified)
```

#### Method 2: Nginx Reverse Proxy
For existing Docker Compose stacks:
1. Add `captain-overlay-network` to your compose file
2. Create CapRover "Nginx Reverse Proxy" apps
3. Point to your container names as upstream

```yaml
# In your existing docker-compose.yml
networks:
  captain-overlay-network:
    external: true

services:
  your-service:
    networks:
      - captain-overlay-network
```

## Database Integration

### PostgreSQL Integration Options

#### Option 1: CapRover Managed PostgreSQL
```yaml
# One-click PostgreSQL deployment through CapRover
# Automatically gets srv-captain--postgres prefix
# Accessible at srv-captain--postgres:5432
```

#### Option 2: Existing NocoDB Database Integration
- CapRover apps can connect to external databases
- Use environment variables for connection strings
- Example connection to existing PostgreSQL:
```bash
DATABASE_URL=postgres://user:pass@host:5432/dbname
```

### Database Backup Strategies
- CapRover doesn't provide built-in PostgreSQL backups
- Recommended: Use third-party solutions like `tiredofit/docker-db-backup`
- Integration with S3-compatible storage for automated backups

## S3/Backblaze Storage Integration

✅ **Full S3 Compatibility**

### Backblaze B2 Features
- S3-compatible API
- 3x free egress compared to other providers
- Seamless integration with existing S3 tools

### Integration Methods

#### Environment Variables for Apps
```bash
S3_BUCKET=your-bucket-name
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
S3_ENDPOINT=https://s3.us-west-002.backblazeb2.com
S3_REGION=us-west-002
```

#### File Upload Apps
CapRover can deploy file upload services that automatically store to Backblaze:
- Static site generators with asset storage
- Form submission handlers with file uploads
- Image processing services

## Subdomain Routing Configuration

### Default Routing Pattern
```
appname.root.domain.com
```

### Custom Domain Configuration
1. **Via Web Dashboard**: Apps → Edit → Domain Settings
2. **Add Multiple Domains**: Support for multiple custom domains per app
3. **HTTPS**: One-click Let's Encrypt SSL
4. **Force HTTPS**: Automatic HTTP to HTTPS redirect

### URL Structure for Your Use Case
```
sites.run8n.xyz              # Main CapRover app
sites.run8n.xyz/siteName     # Path-based routing within app
forms.run8n.xyz              # Separate app for forms
```

### Path-Based Routing Implementation
```nginx
# Custom nginx config for path-based routing
location /siteName {
    proxy_pass http://srv-captain--siteName;
    # Additional proxy settings
}
```

## Resource Requirements

### Minimum Requirements
- **RAM**: 1GB (2GB+ recommended)
- **CPU**: 1 vCPU (2+ recommended)
- **Storage**: 10GB+ for Docker images and app data
- **Network**: Public IP address required

### Your Current Stack Capacity
- **Available**: 16 vCPUs, 32GB RAM
- **Current Usage**: ~8GB allocated to existing services
- **CapRover Overhead**: ~500MB-1GB for CapRover itself
- **Per App**: 128MB-512MB average per deployed app

### Recommended Allocation
```yaml
caprover:
  deploy:
    resources:
      limits:
        memory: 1G
        cpus: '1.0'
      reservations:
        memory: 512M
        cpus: '0.5'
```

## Security Considerations

### Network Security
- CapRover creates isolated overlay networks
- Default bridge network for captain services
- Apps isolated by default unless explicitly connected

### SSL/TLS
- Automatic Let's Encrypt certificates
- Force HTTPS available
- Custom certificate upload supported

### Access Control
- Web dashboard authentication
- API key management for deployments
- Role-based access (enterprise features)

### Firewall Requirements
```bash
# Required ports
80/tcp    # HTTP
443/tcp   # HTTPS
3000/tcp  # CapRover dashboard
7946/tcp  # Docker Swarm
7946/udp  # Docker Swarm
2377/tcp  # Docker Swarm
4789/udp  # Docker overlay network
```

## Deployment Workflows

### API Deployment Methods

#### 1. Git-Based Deployment
```bash
# Install CLI
npm install -g caprover

# Login
caprover login

# Deploy from git
caprover deploy
```

#### 2. Docker Image Deployment
```bash
# Via CLI
caprover deploy --imageName your-image:tag

# Via Web Dashboard
# Apps → Create → Deploy via ImageName
```

#### 3. Tarball Deployment
```bash
# Create deployment package
tar -czf app.tar.gz --exclude node_modules .

# Deploy via dashboard upload
```

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Deploy to CapRover
  uses: caprover/deploy-from-github@v1.0.1
  with:
    server: 'https://captain.your-domain.com'
    password: '${{ secrets.CAPROVER_PASSWORD }}'
    appName: 'your-app'
    image: 'your-image:${{ github.sha }}'
```

## Configuration Examples

### CapRover Installation with Existing Stack

#### 1. Add to docker-compose.yml
```yaml
services:
  caprover:
    image: caprover/caprover:latest
    restart: unless-stopped
    ports:
      - "3000:3000"  # Dashboard
      - "8080:80"    # HTTP apps (avoid conflict with Caddy)
      - "8443:443"   # HTTPS apps (avoid conflict with Caddy)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - captain-data:/captain
    environment:
      - ACCEPTED_TERMS=true
    networks:
      - captain-overlay-network
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'

networks:
  captain-overlay-network:
    driver: overlay
    attachable: true

volumes:
  captain-data:
```

#### 2. Caddy Configuration for CapRover Integration
```caddyfile
# Updated Caddyfile
*.run8n.xyz {
    @forms host forms.run8n.xyz
    handle @forms {
        reverse_proxy caprover:8080
    }

    @sites host sites.run8n.xyz
    handle @sites {
        reverse_proxy caprover:8080
    }

    # Existing services continue as before
    @n8n host run8n.xyz
    handle @n8n {
        reverse_proxy n8n:5678
    }

    # ... other existing routes
}

# CapRover dashboard (optional, for management)
captain.run8n.xyz {
    reverse_proxy caprover:3000
}
```

### Captain Definition File Example
```json
{
    "schemaVersion": 2,
    "dockerCompose": {
        "version": "3.3",
        "services": {
            "$$cap_appname": {
                "image": "your-app:latest",
                "environment": {
                    "DATABASE_URL": "postgres://user:pass@srv-captain--postgres:5432/db",
                    "S3_BUCKET": "$$cap_s3_bucket",
                    "S3_ENDPOINT": "$$cap_s3_endpoint"
                },
                "caproverExtra": {
                    "containerHttpPort": "3000"
                }
            }
        }
    }
}
```

## Potential Conflicts

### Service Conflicts

#### 1. Port Conflicts
- **Caddy**: Uses 80/443
- **CapRover**: Wants 80/443
- **Resolution**: Use custom ports for CapRover (8080/8443)

#### 2. Domain Management
- **Caddy**: Manages SSL for existing domains
- **CapRover**: Wants to manage SSL for its apps
- **Resolution**: Separate subdomain delegation

#### 3. Network Overlaps
- **Existing networks**: `public`, `internal`, `windmill_internal`, `supabase_internal`
- **CapRover networks**: `captain-overlay-network`
- **Resolution**: Explicit network configuration

### Resource Conflicts

#### Memory Competition
Current allocation (estimated):
```
n8n:           2048M
windmill_db:    512M
windmill_*:    2048M (total)
nocodb:        512M
qdrant:        768M
siyuan:        512M
redis:         256M
caddy:         ~100M
Total:        ~6.7GB

Available for CapRover: ~25GB
```

## Implementation Recommendations

### Phase 1: Parallel Installation
1. **Install CapRover** on custom ports (8080/8443)
2. **Configure subdomain delegation** in Caddy
3. **Test basic deployment** with simple static site
4. **Verify no conflicts** with existing services

### Phase 2: Integration Setup
1. **Configure database connectivity** to existing PostgreSQL
2. **Set up S3 integration** with Backblaze
3. **Deploy sample applications** for forms and sites
4. **Test complete workflow** end-to-end

### Phase 3: Production Deployment
1. **Deploy production applications**
2. **Configure monitoring and logging**
3. **Set up backup strategies**
4. **Document operational procedures**

### Recommended Configuration

```yaml
# Production CapRover configuration
services:
  caprover:
    image: caprover/caprover:latest
    restart: unless-stopped
    ports:
      - "3000:3000"    # Dashboard
      - "8080:80"      # HTTP (proxied via Caddy)
      - "8443:443"     # HTTPS (proxied via Caddy)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/volume_fra1_01/caprover_data:/captain
    environment:
      - ACCEPTED_TERMS=true
      - DEFAULT_PASSWORD=your-secure-password
    networks:
      - captain-overlay-network
      - public  # For integration with existing services
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'

networks:
  captain-overlay-network:
    driver: overlay
    attachable: true
```

### Alternative: Standalone CapRover Server
For maximum compatibility, consider running CapRover on a separate server:
- Dedicated ARM64 server for CapRover
- DNS delegation for forms.* and sites.* subdomains
- Database connectivity to main server
- Shared storage via S3/Backblaze

This approach eliminates all integration complexity while providing full CapRover functionality.

## Step-by-Step Hetzner Cloud Setup Guide

### Phase 1: Hetzner Cloud Server Setup

**1. Create Hetzner Cloud Server:**
```bash
# Via Hetzner Console or API
- Server Type: CX21 (2 vCPU, 4GB RAM) or higher
- Image: Ubuntu 22.04 LTS
- Location: Choose closest to your users
- Networking: Enable public IPv4
- SSH Keys: Add your public key
- Firewalls: Create new or use default
```

**2. Configure Hetzner Cloud Firewall:**
```bash
# Via Hetzner Console -> Firewalls -> Create Firewall
Name: caprover-firewall
Rules:
  Inbound:
    - SSH: Port 22, Source: Your IP/32
    - HTTP: Port 80, Source: 0.0.0.0/0, ::/0
    - HTTPS: Port 443, Source: 0.0.0.0/0, ::/0
    - CapRover: Port 3000, Source: Your IP/32
  Outbound:
    - All Traffic: Allow all
```

**3. Initial Server Configuration:**
```bash
# SSH into server
ssh root@YOUR_HETZNER_IP

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Configure firewall (server-level)
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw --force enable

# Harden SSH
sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart sshd
```

### Phase 2: DNS Configuration

**1. Configure DNS Records:**
```bash
# Add these A records to your DNS provider
# (Replace YOUR_HETZNER_IP with actual server IP)

forms.run8n.xyz      A    YOUR_HETZNER_IP
*.forms.run8n.xyz    A    YOUR_HETZNER_IP
sites.run8n.xyz      A    YOUR_HETZNER_IP
*.sites.run8n.xyz    A    YOUR_HETZNER_IP
```

**2. Verify DNS Propagation:**
```bash
# Test from local machine
nslookup forms.run8n.xyz
nslookup test.forms.run8n.xyz
nslookup sites.run8n.xyz
nslookup app.sites.run8n.xyz

# Should all return YOUR_HETZNER_IP
```

### Phase 3: CapRover Installation

**1. Install CapRover:**
```bash
# On Hetzner server
docker run -p 80:80 -p 443:443 -p 3000:3000 \
  -e ACCEPTED_TERMS=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /captain:/captain \
  --name caprover-captain \
  --restart=unless-stopped \
  caprover/caprover

# Wait for installation to complete (2-3 minutes)
docker logs caprover-captain -f
```

**2. Initial CapRover Setup:**
```bash
# Visit http://YOUR_HETZNER_IP:3000
# Default password: captain42

# In CapRover dashboard:
# 1. Change password immediately
# 2. Settings -> CapRover Root Domain: forms.run8n.xyz (or sites.run8n.xyz)
# 3. Enable HTTPS -> Enter email -> Enable HTTPS
# 4. Force HTTPS (recommended)
```

**3. Configure for Caddy Integration:**
```bash
# On Hetzner server - disable domain verification
echo '{"skipVerifyingDomains":"true"}' > /captain/data/config-override.json
docker service update captain-captain --force

# Verify configuration
cat /captain/data/config-override.json
```

### Phase 4: Caddy Integration (Main Server)

**1. Update Main Server Caddyfile:**
```caddyfile
# Add to your existing Caddyfile on main server
*.run8n.xyz {
    # CapRover subdomain delegation
    @forms host forms.run8n.xyz, *.forms.run8n.xyz
    handle @forms {
        reverse_proxy YOUR_HETZNER_IP:80 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
        }
    }

    @sites host sites.run8n.xyz, *.sites.run8n.xyz
    handle @sites {
        reverse_proxy YOUR_HETZNER_IP:80 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
        }
    }

    # Your existing routes continue unchanged
    @n8n host run8n.xyz
    handle @n8n {
        reverse_proxy n8n:5678
    }
    # ... other existing routes
}

# Optional: CapRover dashboard access
captain.run8n.xyz {
    reverse_proxy YOUR_HETZNER_IP:3000
}
```

**2. Reload Caddy Configuration:**
```bash
# On main server
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### Phase 5: Testing and Verification

**1. Test CapRover Access:**
```bash
# Test direct access (should work)
curl -I http://YOUR_HETZNER_IP:3000

# Test via Caddy proxy (should work)
curl -I https://forms.run8n.xyz
curl -I https://sites.run8n.xyz
```

**2. Deploy Test Application:**
```bash
# In CapRover dashboard:
# Apps -> Create New App
# App Name: hello-world
# Deploy Method: Deploy via ImageName
# Image Name: nginx:latest
# Enable HTTPS
# Custom Domain: hello.forms.run8n.xyz

# Test deployment
curl -I https://hello.forms.run8n.xyz
```

### Phase 6: Security Hardening

**1. Secure SSH Access:**
```bash
# Create non-root user
adduser deploy
usermod -aG docker deploy
usermod -aG sudo deploy

# Add SSH key for new user
mkdir /home/deploy/.ssh
cp /root/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh

# Disable root login
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd
```

**2. Install Security Tools:**
```bash
# Install fail2ban
apt install fail2ban -y

# Configure fail2ban for SSH
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 600
bantime = 3600
EOF

systemctl enable fail2ban
systemctl start fail2ban
```

**3. Setup Automated Backups:**
```bash
# Create backup script
cat > /home/deploy/backup-caprover.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/tmp/caprover-backups"
mkdir -p $BACKUP_DIR

# Backup captain data
tar -czf $BACKUP_DIR/captain-$DATE.tar.gz /captain

# Backup any databases (if running PostgreSQL in CapRover)
if docker ps | grep -q postgres; then
    docker exec $(docker ps -q -f name=postgres) pg_dumpall -U postgres > $BACKUP_DIR/postgres-$DATE.sql
fi

# Upload to Backblaze (configure B2 CLI first)
# b2 upload-file your-bucket $BACKUP_DIR/captain-$DATE.tar.gz
# b2 upload-file your-bucket $BACKUP_DIR/postgres-$DATE.sql

# Cleanup old backups (keep 7 days)
find $BACKUP_DIR -type f -mtime +7 -delete
EOF

chmod +x /home/deploy/backup-caprover.sh

# Add to crontab (daily backup at 2 AM)
echo "0 2 * * * /home/deploy/backup-caprover.sh" | crontab -
```

### Phase 7: Monitoring Setup

**1. Enable NetData (Optional):**
```bash
# In CapRover dashboard:
# Apps -> One-Click Apps/Databases -> NetData
# Deploy with default settings
# Access via: https://netdata.forms.run8n.xyz
```

**2. Setup Log Monitoring:**
```bash
# View CapRover logs
docker service logs captain-captain -f

# View application logs
docker service logs srv-captain--your-app-name -f
```

### Troubleshooting Common Issues

**1. SSL Certificate Issues:**
```bash
# Check Let's Encrypt logs
docker exec captain-captain cat /captain/logs/captain.log | grep -i ssl

# Manually request certificate
docker exec captain-captain ./pro-captain request-certificate --domain forms.run8n.xyz
```

**2. DNS Resolution Problems:**
```bash
# Test from CapRover server
nslookup forms.run8n.xyz
dig forms.run8n.xyz

# Check CapRover DNS settings
docker exec captain-captain cat /captain/data/config-captain.json | grep -i domain
```

**3. Proxy Issues:**
```bash
# Check nginx configuration
docker exec captain-captain cat /captain/data/nginx/server-blocks/conf.d/captain-root-domain-name.conf

# Test direct connection
curl -H "Host: forms.run8n.xyz" http://YOUR_HETZNER_IP
```

---

**Last Updated**: 2024-09-29
**CapRover Version Compatibility**: Latest (2024)
**Architecture**: ARM64, AMD64
**Integration Status**: Experimental (dual reverse proxy setup)