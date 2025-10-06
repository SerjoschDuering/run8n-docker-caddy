# Docker Services Authentication Reference

**Document Version**: 1.0
**Last Updated**: 2025-10-06
**Services Covered**: Netdata, Dozzle, Filebrowser

---

## Table of Contents

1. [Quick Reference Summary](#quick-reference-summary)
2. [Netdata Authentication](#netdata-authentication)
3. [Dozzle Authentication](#dozzle-authentication)
4. [Filebrowser Authentication](#filebrowser-authentication)
5. [Security Recommendations](#security-recommendations)
6. [Troubleshooting](#troubleshooting)

---

## Quick Reference Summary

| Service | Built-in Auth | Auth Methods | Default Credentials | Environment Variables |
|---------|--------------|--------------|---------------------|----------------------|
| **Netdata** | ❌ No | IP-based access control only | N/A | None for auth |
| **Dozzle** | ✅ Yes | Simple (file-based), Forward-proxy | None (must configure) | `DOZZLE_AUTH_PROVIDER` |
| **Filebrowser** | ✅ Yes | JSON (default), Proxy, NoAuth | admin/[random password] | `FB_AUTH_METHOD` |

---

## Netdata Authentication

### Built-in Authentication Support
**Status**: ❌ **NO built-in username/password authentication**

### What Netdata Provides
Netdata does **NOT** have built-in username/password authentication. Instead, it offers:
- **IP-based access control** via `netdata.conf`
- **TLS/SSL encryption** support
- **Feature-specific access lists** for different endpoints

### Access Control Configuration

Access control is configured in `netdata.conf` under the `[web]` section:

```ini
[web]
    # Control who can connect to Netdata
    allow connections from = localhost 10.* 192.168.*

    # Control who can access the dashboard
    allow dashboard from = localhost 10.* 192.168.*

    # Control who can view badges
    allow badges from = *

    # Control who can stream metrics
    allow streaming from = *

    # Control who can access netdata.conf via HTTP
    allow netdata.conf from = localhost

    # Control who can make management API calls
    allow management from = localhost
```

### Docker Configuration Example

**Without Authentication** (IP-based access control only):
```yaml
services:
  netdata:
    image: netdata/netdata:latest
    container_name: netdata
    hostname: netdata.example.com
    ports:
      - "19999:19999"
    volumes:
      - netdata_config:/etc/netdata
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    cap_add:
      - SYS_PTRACE
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    restart: unless-stopped
```

### Recommended Solution: Use Reverse Proxy Authentication

Since Netdata lacks built-in authentication, use a reverse proxy (Nginx, Caddy, Traefik) with authentication:

**Example with Caddy**:
```
netdata.example.com {
    basicauth {
        admin $2a$14$hashed_password_here
    }
    reverse_proxy netdata:19999
}
```

**Example with Nginx + Basic Auth**:
```nginx
location / {
    auth_basic "Netdata Authentication";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://netdata:19999;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### Environment Variables (Non-Auth Related)

Netdata supports these environment variables (none for authentication):
```yaml
environment:
  - NETDATA_CLAIM_TOKEN=your_claim_token
  - NETDATA_CLAIM_URL=https://app.netdata.cloud
  - DISABLE_TELEMETRY=1
  - NETDATA_HEALTHCHECK_TARGET=cli
```

---

## Dozzle Authentication

### Built-in Authentication Support
**Status**: ✅ **YES - File-based and Forward-proxy authentication**

### Authentication Methods

1. **Simple (File-based) Authentication** - Recommended
2. **Forward-proxy Authentication** - For external auth providers

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOZZLE_AUTH_PROVIDER` | `none` | Set to `simple` or `forward-proxy` |
| `DOZZLE_AUTH_TTL` | - | Session duration (e.g., `48h`, `30m`) |
| `DOZZLE_AUTH_HEADER_USER` | `Remote-User` | Header for username (forward-proxy) |
| `DOZZLE_AUTH_HEADER_EMAIL` | `Remote-Email` | Header for email (forward-proxy) |
| `DOZZLE_AUTH_HEADER_NAME` | `Remote-Name` | Header for full name (forward-proxy) |
| `DOZZLE_AUTH_HEADER_FILTER` | `Remote-Filter` | Header for user filters (forward-proxy) |
| `DOZZLE_AUTH_HEADER_ROLES` | `Remote-Roles` | Header for user roles (forward-proxy) |
| `DOZZLE_AUTH_LOGOUT_URL` | - | Logout URL (forward-proxy) |

### Docker Compose Configuration Examples

#### Simple Authentication (File-based)

```yaml
services:
  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./dozzle/data:/data
    ports:
      - "8080:8080"
    environment:
      DOZZLE_AUTH_PROVIDER: simple
      DOZZLE_AUTH_TTL: 48h  # Session lasts 48 hours
    restart: unless-stopped
```

#### Creating Users

**Generate a user with Docker command**:
```bash
docker run -it --rm amir20/dozzle generate admin \
  --password mypassword \
  --email admin@example.com \
  --name "Admin User"
```

**Output** (save to `./dozzle/data/users.yml`):
```yaml
users:
  admin:
    email: admin@example.com
    name: Admin User
    password: $2a$12$hashed_bcrypt_password_here
    filter: ""
```

#### Multiple Users Example

Create `./dozzle/data/users.yml`:
```yaml
users:
  admin:
    email: admin@example.com
    name: Admin User
    password: $2a$12$U6Cxd1UMK28F7K6UrDvJf.REFHCg/DABg7OqaO9x3DEtzyVA9LxDy
    filter: ""

  developer:
    email: dev@example.com
    name: Developer
    password: $2a$12$anotherhashedpasswordhere
    filter: "name=myapp"  # Only see containers with name containing "myapp"
```

#### Forward-proxy Authentication (with Authelia/Cloudflare)

```yaml
services:
  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "8080:8080"
    environment:
      DOZZLE_AUTH_PROVIDER: forward-proxy
      DOZZLE_AUTH_HEADER_USER: Remote-User
      DOZZLE_AUTH_HEADER_EMAIL: Remote-Email
      DOZZLE_AUTH_HEADER_NAME: Remote-Name
      DOZZLE_AUTH_LOGOUT_URL: https://auth.example.com/logout
    restart: unless-stopped
```

### Default Credentials
**None** - You must create users manually using the `generate` command or create `users.yml` file.

### Security Notes
- Passwords are stored as bcrypt hashes
- SSL/HTTPS is NOT enabled by default - use reverse proxy for encryption
- Session duration can be customized with `DOZZLE_AUTH_TTL`

---

## Filebrowser Authentication

### Built-in Authentication Support
**Status**: ✅ **YES - Multiple authentication methods**

### Authentication Methods

1. **JSON Authentication** (Default) - Username/password stored in database
2. **Proxy Authentication** - Delegates to reverse proxy headers
3. **NoAuth** - No authentication (use with caution)

### Default Credentials

**Username**: `admin`
**Password**: Randomly generated on first startup (shown once in logs)

**Important**: The admin password is only displayed **once** during initial container startup. If you miss it, you must delete the database and restart.

### Environment Variables

Environment variables use the `FB_` prefix followed by the config option in uppercase:

| Variable | Description | Example |
|----------|-------------|---------|
| `FB_AUTH_METHOD` | Authentication method | `json`, `proxy`, `noauth` |
| `FB_DATABASE` | Database file path | `/database/filebrowser.db` |
| `FB_ROOT` | Root directory to serve | `/srv` |
| `PUID` | User ID (s6 image only) | `1000` |
| `PGID` | Group ID (s6 image only) | `1000` |

### Docker Compose Configuration Examples

#### Default Authentication (JSON)

```yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    volumes:
      - ./filebrowser/srv:/srv
      - ./filebrowser/database:/database
      - ./filebrowser/config:/config
    ports:
      - "8081:80"
    restart: unless-stopped
```

**First startup**: Check logs for random admin password:
```bash
docker logs filebrowser
```

#### With Custom User/Group (S6 Image)

```yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:s6
    container_name: filebrowser
    volumes:
      - ./files:/srv
      - ./filebrowser/database:/database
      - ./filebrowser/config:/config
    ports:
      - "8081:80"
    environment:
      PUID: 1000
      PGID: 1000
    restart: unless-stopped
```

#### No Authentication Setup

**Method 1: Using Command Flag**
```yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    command: --noauth
    volumes:
      - ./files:/srv
      - ./filebrowser/database:/database
    ports:
      - "8081:80"
    restart: unless-stopped
```

**Method 2: Using Environment Variable** (unofficial, may not work on all versions)
```yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    volumes:
      - ./files:/srv
      - ./filebrowser/database:/database
    ports:
      - "8081:80"
    environment:
      FB_NOAUTH: "true"
    restart: unless-stopped
```

**Method 3: Configure After First Start**
```bash
# Exec into running container
docker exec -it filebrowser filebrowser config set --auth.method noauth

# Or run before starting
docker run --rm -v $(pwd)/filebrowser/database:/database \
  filebrowser/filebrowser config set --auth.method noauth
```

#### Proxy Authentication

```yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    volumes:
      - ./files:/srv
      - ./filebrowser/database:/database
    ports:
      - "8081:80"
    environment:
      FB_AUTH_METHOD: proxy
      FB_AUTH_HEADER: Remote-User  # Header name from reverse proxy
    restart: unless-stopped
```

### User Management

#### Creating Additional Users (CLI)

```bash
# Exec into running container
docker exec -it filebrowser filebrowser users add newuser password \
  --perm.admin=false
```

#### Via Web Interface

1. Login as admin
2. Navigate to Settings → User Management
3. Click "New User"
4. Set username, password, and permissions
5. Assign home directory

### User Roles

- **Admin**: Full access to all files and user management
- **Regular User**: Access to assigned directory only
- **Custom Permissions**: Configure per-user file permissions (upload, download, delete, etc.)

### Configuration File Approach

Create `.filebrowser.json`:
```json
{
  "port": 80,
  "baseURL": "",
  "address": "",
  "log": "stdout",
  "database": "/database/filebrowser.db",
  "root": "/srv",
  "auth": {
    "method": "json"
  }
}
```

Mount it:
```yaml
volumes:
  - ./.filebrowser.json:/.filebrowser.json:ro
```

---

## Security Recommendations

### General Best Practices

1. **Always use HTTPS/TLS** - Use reverse proxy (Caddy, Nginx, Traefik) with SSL certificates
2. **Use strong passwords** - Minimum 16 characters, mix of letters, numbers, symbols
3. **Limit network exposure** - Use Docker networks, don't expose to public internet without auth
4. **Regular updates** - Keep Docker images up to date
5. **Principle of least privilege** - Only grant necessary permissions

### Service-Specific Recommendations

#### Netdata
- ✅ Use reverse proxy with authentication (Caddy, Nginx)
- ✅ Configure IP-based access control in `netdata.conf`
- ✅ Use Docker networks to isolate from public internet
- ❌ **DO NOT** expose port 19999 directly to the internet without auth

#### Dozzle
- ✅ Use `simple` authentication with strong passwords
- ✅ Set reasonable `DOZZLE_AUTH_TTL` (24-48 hours)
- ✅ Use user filters to limit container visibility per user
- ✅ Deploy behind reverse proxy with HTTPS
- ❌ **DO NOT** use `forward-proxy` without proper auth provider setup

#### Filebrowser
- ✅ Change default admin password immediately after first start
- ✅ Create separate user accounts instead of sharing admin
- ✅ Use `proxy` auth method if you have existing SSO/auth system
- ✅ Set appropriate file permissions with PUID/PGID
- ❌ **DO NOT** use `noauth` in production or on public networks
- ❌ **DO NOT** lose the initial admin password (save it immediately)

### Example: Complete Secure Setup with Caddy

```yaml
version: '3.8'

services:
  caddy:
    image: caddy:latest
    container_name: caddy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - monitoring
    restart: unless-stopped

  netdata:
    image: netdata/netdata:latest
    container_name: netdata
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    cap_add:
      - SYS_PTRACE
      - SYS_ADMIN
    networks:
      - monitoring
    restart: unless-stopped

  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./dozzle/data:/data
    environment:
      DOZZLE_AUTH_PROVIDER: simple
      DOZZLE_AUTH_TTL: 48h
    networks:
      - monitoring
    restart: unless-stopped

  filebrowser:
    image: filebrowser/filebrowser:s6
    container_name: filebrowser
    volumes:
      - ./files:/srv
      - ./filebrowser/database:/database
    environment:
      PUID: 1000
      PGID: 1000
    networks:
      - monitoring
    restart: unless-stopped

networks:
  monitoring:
    driver: bridge

volumes:
  caddy_data:
  caddy_config:
```

**Caddyfile**:
```
netdata.example.com {
    basicauth {
        admin $2a$14$hashed_password_here
    }
    reverse_proxy netdata:19999
}

dozzle.example.com {
    reverse_proxy dozzle:8080
}

files.example.com {
    reverse_proxy filebrowser:80
}
```

---

## Troubleshooting

### Netdata

#### Issue: Cannot access Netdata from other machines
**Solution**: Check `netdata.conf` access control settings:
```bash
docker exec -it netdata cat /etc/netdata/netdata.conf | grep "allow"
```

Modify to allow your network:
```ini
[web]
    allow connections from = localhost 192.168.*
    allow dashboard from = localhost 192.168.*
```

#### Issue: Reverse proxy shows "400 Bad Request"
**Solution**: Add proper proxy headers in reverse proxy config:
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

### Dozzle

#### Issue: "Authentication failed" even with correct password
**Solution**:
1. Check `users.yml` file exists in `/data` directory
2. Verify bcrypt password hash is correct
3. Regenerate user with `docker run ... dozzle generate`

```bash
# Check if users.yml exists
docker exec dozzle ls -la /data/

# Regenerate user
docker run -it --rm amir20/dozzle generate admin --password newpass
```

#### Issue: Session expires too quickly
**Solution**: Increase `DOZZLE_AUTH_TTL`:
```yaml
environment:
  DOZZLE_AUTH_TTL: 168h  # 1 week
```

#### Issue: Cannot see any containers after login
**Solution**: Check user filters in `users.yml`. Empty filter shows all containers:
```yaml
users:
  admin:
    filter: ""  # Shows all containers
```

### Filebrowser

#### Issue: Lost admin password and cannot login
**Solution**: Delete database and restart (creates new admin with new password):
```bash
docker-compose down
rm ./filebrowser/database/filebrowser.db
docker-compose up -d
docker logs filebrowser  # Get new password from logs
```

#### Issue: "admin/admin" doesn't work on first login
**Solution**: Filebrowser no longer uses "admin/admin" by default. Check container logs for random password:
```bash
docker logs filebrowser 2>&1 | grep -i password
```

#### Issue: `noauth` mode not working
**Solution**: Delete existing database before enabling noauth:
```bash
docker-compose down
rm ./filebrowser/database/filebrowser.db
docker run --rm -v $(pwd)/filebrowser/database:/database \
  filebrowser/filebrowser config init
docker run --rm -v $(pwd)/filebrowser/database:/database \
  filebrowser/filebrowser config set --auth.method noauth
docker-compose up -d
```

#### Issue: File permission errors
**Solution**: Set correct PUID/PGID to match host user:
```yaml
environment:
  PUID: 1000  # Your user ID
  PGID: 1000  # Your group ID
```

Find your IDs:
```bash
id -u  # User ID
id -g  # Group ID
```

#### Issue: Configuration changes don't persist after container restart
**Solution**: Use environment variables or mount config file:
```yaml
volumes:
  - ./filebrowser/config:/config
  - ./.filebrowser.json:/.filebrowser.json:ro
```

---

## References

### Official Documentation

- **Netdata**: https://learn.netdata.cloud/docs/netdata-agent/configuration/securing-agents/
- **Dozzle**: https://dozzle.dev/guide/authentication
- **Filebrowser**: https://filebrowser.org/configuration

### Useful Links

- Netdata Web Server Reference: https://learn.netdata.cloud/docs/netdata-agent/configuration/securing-agents/web-server-reference
- Dozzle Environment Variables: https://dozzle.dev/guide/supported-env-vars
- Filebrowser Installation: https://filebrowser.org/installation

### Community Resources

- Netdata GitHub Issues: https://github.com/netdata/netdata/issues
- Dozzle GitHub: https://github.com/amir20/dozzle
- Filebrowser GitHub: https://github.com/filebrowser/filebrowser

---

**Document Maintenance**: This document should be reviewed and updated quarterly or when major version updates occur for any of the covered services.
