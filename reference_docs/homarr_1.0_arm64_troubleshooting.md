# Homarr v1.0+ ARM64 Configuration & Troubleshooting Reference

**Last Updated:** 2025-10-06
**Platform:** ARM64 (Hetzner Cloud)
**Image:** `ghcr.io/homarr-labs/homarr:latest` (NEW) / `ghcr.io/ajnart/homarr:latest` (DEPRECATED)

---

## Table of Contents

1. [Critical Issues & Root Causes](#critical-issues--root-causes)
2. [Environment Variables - Required vs Optional](#environment-variables---required-vs-optional)
3. [ARM64 Compatibility](#arm64-compatibility)
4. [Docker Configuration](#docker-configuration)
5. [Reverse Proxy Setup (Caddy)](#reverse-proxy-setup-caddy)
6. [Volume & Permission Issues](#volume--permission-issues)
7. [Troubleshooting 500 Errors](#troubleshooting-500-errors)
8. [Debug & Logging](#debug--logging)
9. [Working Configuration Example](#working-configuration-example)

---

## Critical Issues & Root Causes

### Issue 1: Missing SECRET_ENCRYPTION_KEY (Most Common)

**Symptoms:**
- 500 Internal Server Error immediately on startup
- Container exits after showing error message
- No web interface accessible

**Root Cause:**
Starting with Homarr v1.0, the `SECRET_ENCRYPTION_KEY` environment variable is **REQUIRED** (not optional). This key encrypts sensitive data (passwords, API tokens) in the database.

**Solution:**
```bash
# Generate a 64-character hex key
openssl rand -hex 32

# Add to docker-compose.yml
environment:
  - SECRET_ENCRYPTION_KEY=your_generated_64_char_hex_string
```

**Why It Matters:**
Without this key, Homarr will refuse to start. The container will show a suggested key in the error message before exiting.

---

### Issue 2: Wrong Docker Image Repository

**Symptoms:**
- Using `ghcr.io/ajnart/homarr:latest`
- No updates received
- Possible ARM64 compatibility issues

**Root Cause:**
Homarr v1.0 renamed the image from `ghcr.io/ajnart/homarr` to `ghcr.io/homarr-labs/homarr`. The old repository is archived and no longer receives updates.

**Solution:**
```yaml
# OLD (deprecated)
image: ghcr.io/ajnart/homarr:latest

# NEW (correct)
image: ghcr.io/homarr-labs/homarr:latest
```

---

### Issue 3: Connection Refused (ECONNREFUSED)

**Symptoms:**
- Error: `connect ECONNREFUSED ::1:41779` in logs
- Container shows "unhealthy" status
- Not reachable from local IP or domain
- Works initially but fails after reboot

**Root Cause:**
Network configuration issues, particularly with:
- `network_mode: host` causing port binding conflicts
- Internal service communication failures
- DNS resolution problems inside container

**Solutions:**
1. **Use bridge networking instead of host mode:**
   ```yaml
   networks:
     - public
   # Remove: network_mode: host
   ```

2. **Check for port conflicts:**
   ```bash
   # Check if port 7575 is already in use
   netstat -tulpn | grep 7575
   ```

3. **Verify container networking:**
   ```bash
   docker inspect homarr | grep -A 10 "Networks"
   ```

**Related Issues:**
- GitHub Issue #2281 (ECONNREFUSED on Orange Pi ARM64)
- GitHub Issue homarr-labs/homarr#2498 (networking configuration)

---

### Issue 4: Volume Path Migration (v0.x → v1.0)

**Symptoms:**
- 500 errors after upgrading from v0.x to v1.0
- Data not loading
- Configuration lost

**Root Cause:**
Homarr v1.0 changed the internal volume structure:
- **Old (v0.x):** `/data` → various subdirectories
- **New (v1.0):** `/appdata` → restructured (NOT backwards compatible)

**Solution:**
```yaml
# OLD volumes (v0.x)
volumes:
  - /opt/run8n_data/homarr/configs:/app/data/configs
  - /opt/run8n_data/homarr/icons:/app/public/icons
  - /opt/run8n_data/homarr/data:/data

# NEW volumes (v1.0+)
volumes:
  - /opt/run8n_data/homarr/appdata:/appdata
  # Optional: Docker integration
  - /var/run/docker.sock:/var/run/docker.sock
```

**Migration Required:**
You cannot directly migrate from v0.x to v1.0 with the same data structure. Plan for manual reconfiguration.

---

## Environment Variables - Required vs Optional

### Required Variables

| Variable | Purpose | How to Generate |
|----------|---------|-----------------|
| `SECRET_ENCRYPTION_KEY` | Encrypts secrets in database | `openssl rand -hex 32` |

**Critical:** Without this, Homarr will not start.

---

### Optional Variables - General

| Variable | Default | Purpose |
|----------|---------|---------|
| `PUID` | `0` | User ID to run container |
| `PGID` | `0` | Group ID to run container |
| `LOG_LEVEL` | `info` | Logging verbosity (`debug`, `info`, `warn`, `error`) |
| `NO_EXTERNAL_CONNECTION` | `false` | Disable all internet requests |
| `ENABLE_DNS_CACHING` | `false` | Enable DNS caching |

---

### Optional Variables - Authentication

| Variable | Purpose | When to Use |
|----------|---------|-------------|
| `AUTH_PROVIDER` | Authentication provider | `credentials` (default), `oidc`, etc. |
| `AUTH_SECRET_KEY` | NextAuth secret (different from encryption key) | For session management |
| `BASE_URL` | Full URL of your Homarr instance | **Required for OIDC/SSO** and reverse proxies |

**BASE_URL Configuration:**
- Format: `https://dashboard.run8n.xyz` (no trailing slash)
- **Required when:**
  - Using OIDC/SSO authentication
  - Running behind reverse proxy
  - Setting up OAuth providers
- **Without BASE_URL:** Homarr may send `http://localhost:7575` as redirect URLs, breaking authentication

---

### Optional Variables - Database

| Variable | Default | Purpose |
|----------|---------|---------|
| `DB_DRIVER` | `better-sqlite3` | Database driver |
| `DB_DIALECT` | `sqlite` | Database type |
| `DB_URL` | `/appdata/db/db.sqlite` | Database connection URL |

---

### Optional Variables - Redis

| Variable | Default | Purpose |
|----------|---------|---------|
| `REDIS_IS_EXTERNAL` | `false` | Use external Redis |
| `REDIS_HOST` | - | Redis hostname |
| `REDIS_PORT` | `6379` | Redis port |
| `REDIS_PASSWORD` | - | Redis authentication |

---

### Optional Variables - Docker Integration

| Variable | Purpose |
|----------|---------|
| `DOCKER_HOSTNAMES` | Comma-separated Docker hostnames |
| `DOCKER_PORTS` | Comma-separated Docker ports |

---

## ARM64 Compatibility

### Official ARM64 Support Status

**Supported:** ✅ ARM64 (aarch64)
**Dropped:** ❌ ARMv7 (32-bit ARM)

Starting with Homarr v1.0:
- **ARM64 is fully supported** on the new `ghcr.io/homarr-labs/homarr` image
- **ARMv7 support dropped** due to upstream dependencies and build framework limitations
- Recommendation: Use cheap ARM64 SBCs (Raspberry Pi 4+, Orange Pi 3, etc.)

---

### Known ARM64 Issues

**Issue:** Container becomes unhealthy after reboot (Orange Pi 3 LTS, OMV7)
- **Platform:** Open Media Vault 7 on Orange Pi 3 LTS
- **Status:** Reported as networking configuration issue
- **Workaround:** Use bridge networking instead of host mode

---

### Recommended ARM64 Configuration

```yaml
services:
  homarr:
    image: ghcr.io/homarr-labs/homarr:latest
    platform: linux/arm64  # Explicit platform declaration
    restart: unless-stopped
    expose:
      - "7575"
    volumes:
      - /opt/run8n_data/homarr/appdata:/appdata
      - /var/run/docker.sock:/var/run/docker.sock  # Optional
    environment:
      - SECRET_ENCRYPTION_KEY=${HOMARR_SECRET_KEY}
      - AUTH_PROVIDER=credentials
      - BASE_URL=https://dashboard.run8n.xyz
    networks:
      - public
    deploy:
      resources:
        limits:
          memory: 200M
          cpus: '0.4'
```

---

## Docker Configuration

### Minimal Working Docker Compose

```yaml
services:
  homarr:
    container_name: homarr
    image: ghcr.io/homarr-labs/homarr:latest
    restart: unless-stopped
    volumes:
      - ./homarr/appdata:/appdata
    environment:
      - SECRET_ENCRYPTION_KEY=your_64_character_hex_string
    ports:
      - '7575:7575'
```

---

### Full Production Docker Compose (ARM64)

```yaml
services:
  homarr:
    image: ghcr.io/homarr-labs/homarr:latest
    platform: linux/arm64
    container_name: homarr
    restart: unless-stopped
    expose:
      - "7575"
    volumes:
      - /opt/run8n_data/homarr/appdata:/appdata
      - /var/run/docker.sock:/var/run/docker.sock:ro  # For Docker integration
    environment:
      # Required
      - SECRET_ENCRYPTION_KEY=${HOMARR_SECRET_KEY}

      # Authentication
      - AUTH_PROVIDER=credentials
      - BASE_URL=https://dashboard.run8n.xyz

      # Optional: Performance tuning
      - LOG_LEVEL=info
      - PUID=1000
      - PGID=1000
    networks:
      - public
    deploy:
      resources:
        limits:
          memory: 200M
          cpus: '0.4'
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:7575"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

### Standalone Docker Command

```bash
docker run \
  --name homarr \
  --restart unless-stopped \
  -p 7575:7575 \
  -v /opt/run8n_data/homarr/appdata:/appdata \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e SECRET_ENCRYPTION_KEY='your_64_character_hex_string' \
  -e BASE_URL='https://dashboard.run8n.xyz' \
  -d ghcr.io/homarr-labs/homarr:latest
```

---

## Reverse Proxy Setup (Caddy)

### Why Caddy Works Out-of-the-Box

Caddy handles Homarr proxying **automatically** without special configuration:
- ✅ WebSocket support built-in (no additional config needed)
- ✅ Automatic HTTPS with Let's Encrypt
- ✅ Automatic header forwarding (`X-Forwarded-*`)
- ✅ Host header preservation

---

### Minimal Caddyfile Configuration

```caddyfile
dashboard.run8n.xyz {
    reverse_proxy homarr:7575
}
```

That's it! Caddy handles everything else automatically.

---

### Full Caddyfile Configuration (with options)

```caddyfile
dashboard.run8n.xyz {
    # Basic reverse proxy
    reverse_proxy homarr:7575 {
        # Optional: Custom headers
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}

        # Optional: Health check
        health_uri /api/health
        health_interval 30s
        health_timeout 5s
    }

    # Optional: Security headers
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options SAMEORIGIN
        X-XSS-Protection "1; mode=block"
        Referrer-Policy strict-origin-when-cross-origin
        -Server
    }

    # Optional: Access logs
    log {
        output file /var/log/caddy/dashboard.log
        format json
    }
}
```

---

### Path-Based Routing (Multiple Services)

```caddyfile
dashboard.run8n.xyz {
    # Homarr at root
    handle {
        reverse_proxy homarr:7575
    }

    # Other services at paths
    handle /monitor* {
        uri strip_prefix /monitor
        reverse_proxy netdata:19999
    }

    handle /logs* {
        uri strip_prefix /logs
        reverse_proxy dozzle:8080
    }
}
```

---

### WebSocket Configuration

**No special configuration needed!** Caddy automatically upgrades HTTP connections to WebSocket.

If you need explicit WebSocket handling:

```caddyfile
dashboard.run8n.xyz {
    reverse_proxy homarr:7575 {
        # Explicitly allow WebSocket upgrades (already default)
        transport http {
            versions h1 h2c
        }
    }
}
```

---

### Homarr Environment Variables for Reverse Proxy

When using Caddy (or any reverse proxy), set:

```yaml
environment:
  - BASE_URL=https://dashboard.run8n.xyz  # Your full domain
  - AUTH_PROVIDER=credentials
```

**Without BASE_URL:** Homarr may generate incorrect redirect URLs for authentication.

---

## Volume & Permission Issues

### Correct Volume Structure (v1.0+)

```yaml
volumes:
  - /opt/run8n_data/homarr/appdata:/appdata
  # NOT: /app/data/configs, /app/public/icons, /data (old v0.x paths)
```

---

### Directory Creation & Permissions

```bash
# Create directories
sudo mkdir -p /opt/run8n_data/homarr/appdata

# Set ownership (if running as non-root)
sudo chown -R 1000:1000 /opt/run8n_data/homarr

# Set permissions
sudo chmod -R 755 /opt/run8n_data/homarr
```

---

### Common Permission Errors

**Error:** `Error: EACCES: permission denied, open '/appdata/db/db.sqlite'`

**Solution:**
```bash
# Fix ownership
sudo chown -R 1000:1000 /opt/run8n_data/homarr

# Or run as root (not recommended)
environment:
  - PUID=0
  - PGID=0
```

---

### Docker Socket Permission Issues

**Error:** `Error: EACCES: permission denied, open '/var/run/docker.sock'`

**Solution:**
```bash
# Add container user to docker group (or use read-only mount)
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

---

## Troubleshooting 500 Errors

### Step 1: Check Environment Variables

```bash
# Verify SECRET_ENCRYPTION_KEY is set
docker exec homarr env | grep SECRET_ENCRYPTION_KEY

# Should output:
# SECRET_ENCRYPTION_KEY=your_64_char_hex_string
```

**If empty:** Add to docker-compose.yml and recreate container.

---

### Step 2: Check Container Logs

```bash
# View recent logs
docker logs homarr --tail 100

# Follow logs in real-time
docker logs homarr -f

# Look for specific errors
docker logs homarr 2>&1 | grep -i error
```

**Common error messages:**
- `SECRET_ENCRYPTION_KEY is required` → Add the environment variable
- `EACCES: permission denied` → Fix volume permissions
- `ECONNREFUSED` → Network configuration issue
- `Database migration failed` → Delete `/appdata/db` and restart (data loss!)

---

### Step 3: Verify Volume Permissions

```bash
# Check volume mount
docker inspect homarr | grep -A 20 "Mounts"

# Check directory ownership on host
ls -la /opt/run8n_data/homarr/

# Fix permissions if needed
sudo chown -R 1000:1000 /opt/run8n_data/homarr
```

---

### Step 4: Test Container Networking

```bash
# Check if Homarr is listening on port 7575
docker exec homarr netstat -tulpn | grep 7575

# Or use wget inside container
docker exec homarr wget -O- http://localhost:7575

# Check container IP and network
docker inspect homarr | grep -E "IPAddress|NetworkMode"
```

---

### Step 5: Verify Reverse Proxy

```bash
# Test direct access (bypassing Caddy)
curl -v http://localhost:7575

# Test through Caddy
curl -v https://dashboard.run8n.xyz

# Check Caddy logs
docker logs caddy | grep -i homarr
```

---

### Step 6: Check Database Integrity

```bash
# Access container
docker exec -it homarr sh

# Check if database file exists
ls -la /appdata/db/db.sqlite

# Exit container
exit
```

**If database is corrupted:**
```bash
# Stop container
docker stop homarr

# Backup and remove database
sudo mv /opt/run8n_data/homarr/appdata/db /opt/run8n_data/homarr/appdata/db.backup

# Restart container (fresh database)
docker start homarr
```

**Warning:** This will delete all Homarr configurations.

---

## Debug & Logging

### Enable Debug Logging

```yaml
environment:
  - LOG_LEVEL=debug  # Options: debug, info, warn, error
```

Restart container:
```bash
docker compose -f docker-compose-arm.yml restart homarr
```

---

### View Logs with Timestamps

```bash
docker logs homarr --timestamps --tail 200
```

---

### Export Logs to File

```bash
docker logs homarr > homarr-logs-$(date +%Y%m%d-%H%M%S).txt
```

---

### Access Container Shell

```bash
# Alpine-based container (sh)
docker exec -it homarr sh

# Check running processes
ps aux

# Check listening ports
netstat -tulpn

# Test internal connectivity
wget -O- http://localhost:7575

# Exit
exit
```

---

### Check Homarr Version

```bash
docker exec homarr cat /package.json | grep version
```

Or check Docker image tag:
```bash
docker inspect homarr | grep "Image"
```

---

## Working Configuration Example

### Current Issue in Your Setup

**Problem identified:**
```yaml
# Your current configuration (docker-compose-arm.yml line 451-470)
homarr:
  image: ghcr.io/ajnart/homarr:latest  # ❌ WRONG - deprecated image
  platform: linux/arm64
  restart: unless-stopped
  expose:
    - "7575"
  volumes:
    - /opt/run8n_data/homarr/configs:/app/data/configs  # ❌ WRONG - old v0.x paths
    - /opt/run8n_data/homarr/icons:/app/public/icons    # ❌ WRONG
    - /opt/run8n_data/homarr/data:/data                 # ❌ WRONG
  environment:
    - AUTH_PROVIDER=credentials
    - AUTH_SECRET_KEY=${HOMARR_SECRET_KEY}  # ⚠️ Should be SECRET_ENCRYPTION_KEY
  networks:
    - public
```

---

### Corrected Configuration

```yaml
homarr:
  image: ghcr.io/homarr-labs/homarr:latest  # ✅ CORRECT - new image
  platform: linux/arm64
  container_name: homarr
  restart: unless-stopped
  expose:
    - "7575"
  volumes:
    - /opt/run8n_data/homarr/appdata:/appdata  # ✅ CORRECT - v1.0 path
    - /var/run/docker.sock:/var/run/docker.sock:ro  # Optional: Docker integration
  environment:
    # Required
    - SECRET_ENCRYPTION_KEY=${HOMARR_SECRET_KEY}  # ✅ CORRECT - encryption key

    # Authentication
    - AUTH_PROVIDER=credentials

    # Reverse Proxy
    - BASE_URL=https://dashboard.run8n.xyz  # ✅ IMPORTANT for OIDC/SSO

    # Optional: Performance
    - LOG_LEVEL=info
    - PUID=1000
    - PGID=1000
  networks:
    - public
  deploy:
    resources:
      limits:
        memory: 200M
        cpus: '0.4'
  healthcheck:
    test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:7575"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

---

### Deployment Steps to Fix Your Issue

```bash
# 1. Stop current Homarr container
docker compose -f docker-compose-arm.yml stop homarr

# 2. Backup existing data (old structure)
sudo cp -r /opt/run8n_data/homarr /opt/run8n_data/homarr-backup-$(date +%Y%m%d)

# 3. Create new v1.0 directory structure
sudo mkdir -p /opt/run8n_data/homarr/appdata
sudo chown -R 1000:1000 /opt/run8n_data/homarr

# 4. Update docker-compose-arm.yml with corrected configuration above

# 5. Pull new image
docker pull ghcr.io/homarr-labs/homarr:latest

# 6. Remove old container
docker compose -f docker-compose-arm.yml rm -f homarr

# 7. Start with new configuration
docker compose -f docker-compose-arm.yml up -d homarr

# 8. Check logs for errors
docker logs homarr -f
```

---

### Expected Logs (Success)

```
[INFO] Starting Homarr v1.x.x
[INFO] Database connected: /appdata/db/db.sqlite
[INFO] Server listening on http://0.0.0.0:7575
[INFO] Ready to accept connections
```

---

### Check Access

```bash
# 1. Test direct container access
curl -I http://localhost:7575

# Should return: HTTP/1.1 200 OK

# 2. Test through Caddy
curl -I https://dashboard.run8n.xyz

# Should return: HTTP/2 200

# 3. Open in browser
# https://dashboard.run8n.xyz
# Should show Homarr login/setup page
```

---

## Quick Fixes Summary

| Symptom | Quick Fix |
|---------|-----------|
| 500 error immediately | Add `SECRET_ENCRYPTION_KEY` |
| Container exits on start | Generate and set `SECRET_ENCRYPTION_KEY` |
| Connection refused | Use bridge networking, check port conflicts |
| Data not loading after upgrade | Migrate volumes from `/data` to `/appdata` |
| OIDC redirect issues | Set `BASE_URL` environment variable |
| Permission denied errors | `sudo chown -R 1000:1000 /opt/run8n_data/homarr` |
| No updates available | Switch to `ghcr.io/homarr-labs/homarr:latest` |

---

## Additional Resources

- **Official Documentation:** https://homarr.dev/docs
- **Docker Installation:** https://homarr.dev/docs/getting-started/installation/docker/
- **Environment Variables:** https://homarr.dev/docs/advanced/environment-variables/
- **Reverse Proxy Guide:** https://homarr.dev/docs/advanced/proxy/
- **GitHub Repository:** https://github.com/homarr-labs/homarr (new)
- **GitHub Issues:** https://github.com/homarr-labs/homarr/issues
- **Community Discord:** Check documentation for invite link

---

## Changelog

- **2025-10-06:** Created initial reference document
  - Documented SECRET_ENCRYPTION_KEY requirement
  - Identified image repository change (ajnart → homarr-labs)
  - Documented v0.x → v1.0 volume path migration
  - Added ARM64 compatibility notes
  - Added Caddy reverse proxy configuration
  - Provided working configuration example

---

**Next Steps for Your Deployment:**

1. Update `docker-compose-arm.yml` with corrected configuration
2. Generate `SECRET_ENCRYPTION_KEY` if not already in `.env`
3. Recreate Homarr container with new image and volumes
4. Monitor logs during startup
5. Access https://dashboard.run8n.xyz to verify

**Estimated Time to Fix:** 5-10 minutes
