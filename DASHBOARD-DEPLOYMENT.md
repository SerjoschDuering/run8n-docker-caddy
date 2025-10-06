# Dashboard Stack Deployment Guide

## Overview

This guide helps you deploy the internal dashboard stack on your Hetzner Cloud server:
- **Homarr** - Main dashboard with authentication
- **Netdata** - Server and container monitoring
- **Dozzle** - Real-time container logs
- **Filebrowser** - File management UI

**Total Resource Usage:** ~290MB RAM, 0.8 CPU

---

## Pre-Deployment Steps (On Your Local Machine)

✅ All configuration files are ready:
- `docker-compose-arm.yml` - Updated with 4 new services
- `caddy_config/Caddyfile` - Updated with 4 new routes
- `.env` - Homarr secret key added

---

## Deployment Steps (On Hetzner Server)

### 1. SSH into Your Hetzner Server

```bash
ssh root@your-hetzner-server-ip
# or
ssh user@run8n.xyz
```

### 2. Navigate to Project Directory

```bash
cd /path/to/run8n-docker-caddy
# Likely: cd /opt/run8n-docker-caddy or ~/run8n-docker-caddy
```

### 3. Pull Latest Changes

```bash
git pull origin main
# or copy files manually if not using git
```

### 4. Create Data Directories

```bash
sudo mkdir -p /opt/run8n_data/homarr/{configs,icons,data}
sudo mkdir -p /opt/run8n_data/netdata/{config,lib,cache}
sudo mkdir -p /opt/run8n_data/filebrowser

# Set proper permissions (adjust user if needed)
sudo chown -R 1000:1000 /opt/run8n_data/homarr
sudo chown -R 1000:1000 /opt/run8n_data/filebrowser
```

### 5. Verify .env File

```bash
# Check that HOMARR_SECRET_KEY is set
grep HOMARR_SECRET_KEY .env

# Should output:
# HOMARR_SECRET_KEY=XRRfXLbpT95FO78JntaRvCrcpmpz9U8BHf90d8M0G0M=
```

### 6. Deploy Services

```bash
# Pull latest images
docker compose -f docker-compose-arm.yml pull homarr netdata dozzle filebrowser

# Start the services
docker compose -f docker-compose-arm.yml up -d homarr netdata dozzle filebrowser

# Check if services are running
docker compose -f docker-compose-arm.yml ps | grep -E "homarr|netdata|dozzle|filebrowser"
```

### 7. Reload Caddy (for new routes)

```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## DNS Configuration

Before accessing the services, ensure these DNS records point to your Hetzner server IP:

```
dashboard.run8n.xyz  → A record → YOUR_SERVER_IP
monitor.run8n.xyz    → A record → YOUR_SERVER_IP
logs.run8n.xyz       → A record → YOUR_SERVER_IP
files.run8n.xyz      → A record → YOUR_SERVER_IP
```

Or use wildcard:
```
*.run8n.xyz → A record → YOUR_SERVER_IP
```

Wait 5-10 minutes for DNS propagation.

---

## First-Time Setup

### 1. Homarr (Main Dashboard)

**Access:** `https://dashboard.run8n.xyz`

1. First visit will show "Create your account" page
2. Create admin account:
   - Username: `admin` (or your choice)
   - Password: Choose a strong password
3. Login with your credentials

### 2. Configure Homarr Dashboard

After login:

1. **Enable Edit Mode:**
   - Click the pencil icon (top right)
   - Or press `Ctrl+K` → type "Edit" → Enter

2. **Add Service Cards:**
   - Click "Add a tile" → "App"
   - For each service:

     **Netdata (Monitoring):**
     - App name: `Server Monitoring`
     - URL: `https://monitor.run8n.xyz`
     - Icon: Search "chart" or "monitoring"

     **Dozzle (Logs):**
     - App name: `Container Logs`
     - URL: `https://logs.run8n.xyz`
     - Icon: Search "log" or "terminal"

     **Filebrowser (Files):**
     - App name: `File Manager`
     - URL: `https://files.run8n.xyz`
     - Icon: Search "folder" or "file"

     **n8n:**
     - App name: `n8n Automation`
     - URL: `https://run8n.xyz`
     - Icon: Search "n8n"

     **Windmill:**
     - App name: `Windmill`
     - URL: `https://windmill.run8n.xyz`
     - Icon: Search "windmill"

     **NocoDB:**
     - App name: `NocoDB`
     - URL: `https://nocodb.run8n.xyz`
     - Icon: Search "database"

     **SiYuan:**
     - App name: `SiYuan Notes`
     - URL: `https://siyuan.run8n.xyz`
     - Icon: Search "note"

3. **Optional: Add iframe Widgets**
   - Click "Add a tile" → "Widgets" → "iFrame"
   - Enter service URL
   - Note: Some services block iframes (security headers)

4. **Save Dashboard:**
   - Exit edit mode (click save/done)
   - Dashboard auto-saves

### 3. Filebrowser Initial Setup

**Access:** `https://files.run8n.xyz`

**Default credentials:**
- Username: `admin`
- Password: `admin`

**⚠️ Change password immediately:**
1. Login with default credentials
2. Click user icon → "Settings"
3. Change password
4. Update user permissions if needed

---

## Verification Checklist

After deployment, verify all services:

- [ ] `https://dashboard.run8n.xyz` - Homarr dashboard loads ✅
- [ ] `https://monitor.run8n.xyz` - Netdata shows server stats ✅
- [ ] `https://logs.run8n.xyz` - Dozzle shows container logs ✅
- [ ] `https://files.run8n.xyz` - Filebrowser shows /opt/run8n_data ✅
- [ ] All service cards in Homarr are clickable ✅
- [ ] SSL certificates are valid (green padlock) ✅

---

## Troubleshooting

### Service Not Starting

```bash
# Check service logs
docker compose -f docker-compose-arm.yml logs homarr
docker compose -f docker-compose-arm.yml logs netdata
docker compose -f docker-compose-arm.yml logs dozzle
docker compose -f docker-compose-arm.yml logs filebrowser

# Check if ports are exposed
docker compose -f docker-compose-arm.yml ps
```

### DNS Not Resolving

```bash
# Test DNS resolution
nslookup dashboard.run8n.xyz
nslookup monitor.run8n.xyz

# Check Caddy configuration
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# View Caddy logs
docker logs caddy
```

### Homarr Authentication Issues

```bash
# Check if secret key is set
docker exec homarr env | grep AUTH_SECRET_KEY

# Restart Homarr
docker compose -f docker-compose-arm.yml restart homarr
```

### Permission Errors

```bash
# Fix permissions
sudo chown -R 1000:1000 /opt/run8n_data/homarr
sudo chown -R 1000:1000 /opt/run8n_data/filebrowser
sudo chmod -R 755 /opt/run8n_data/homarr
```

### Services Not Accessible via HTTPS

```bash
# Check Caddy is running
docker ps | grep caddy

# Reload Caddy
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Check Caddy logs for SSL errors
docker logs caddy | grep -i error
```

---

## Resource Monitoring

Check resource usage after deployment:

```bash
# View container resource usage
docker stats homarr netdata dozzle filebrowser

# Should see approximately:
# homarr:       ~100-200MB RAM, 10-20% CPU
# netdata:      ~150-200MB RAM, 10-20% CPU
# dozzle:       ~10-64MB RAM,   <5% CPU
# filebrowser:  ~30-64MB RAM,   <5% CPU
```

---

## Updating Services

To update dashboard services in the future:

```bash
# Pull latest images
docker compose -f docker-compose-arm.yml pull homarr netdata dozzle filebrowser

# Recreate containers
docker compose -f docker-compose-arm.yml up -d homarr netdata dozzle filebrowser

# Remove old images
docker image prune -f
```

---

## Security Recommendations

1. **Homarr:**
   - Use strong passwords
   - Enable 2FA if available in future versions
   - Limit access to dashboard subdomain via firewall if needed

2. **Filebrowser:**
   - Change default password immediately
   - Create user accounts with limited permissions
   - Consider restricting to internal network only

3. **Netdata & Dozzle:**
   - These don't have built-in auth
   - Consider adding Caddy basic auth if exposing publicly
   - Or restrict to VPN/internal network

### Adding Basic Auth to Netdata/Dozzle (Optional)

Edit `Caddyfile`:

```caddyfile
monitor.run8n.xyz {
    basicauth {
        admin JDJhJDE0JHNvbWVoYXNoZWRwYXNzd29yZGhlcmU=
    }
    reverse_proxy netdata:19999
}

logs.run8n.xyz {
    basicauth {
        admin JDJhJDE0JHNvbWVoYXNoZWRwYXNzd29yZGhlcmU=
    }
    reverse_proxy dozzle:8080
}
```

Generate hash:
```bash
docker exec caddy caddy hash-password --plaintext "your-password"
```

---

## Next Steps

1. ✅ Deploy services on Hetzner
2. ✅ Configure Homarr dashboard with service cards
3. ✅ Test all services
4. 🔄 Optionally add basic auth to Netdata/Dozzle
5. 🔄 Create monitoring alerts in Netdata
6. 🔄 Customize Homarr theme and layout

---

## URLs Quick Reference

| Service | URL | Purpose |
|---------|-----|---------|
| **Homarr** | `https://dashboard.run8n.xyz` | Main dashboard |
| **Netdata** | `https://monitor.run8n.xyz` | Monitoring |
| **Dozzle** | `https://logs.run8n.xyz` | Logs |
| **Filebrowser** | `https://files.run8n.xyz` | Files |
| n8n | `https://run8n.xyz` | Automation |
| Windmill | `https://windmill.run8n.xyz` | Workflows |
| NocoDB | `https://nocodb.run8n.xyz` | Database UI |
| SiYuan | `https://siyuan.run8n.xyz` | Notes |

---

**Need Help?** Check container logs or review docker-compose-arm.yml configuration.
