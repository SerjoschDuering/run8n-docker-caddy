# n8n Optimization Plan for ARM Server (16 vCPUs, 32GB RAM)

## Overview
This document outlines the optimal n8n configuration for a single-instance deployment on the ARM server with 16 vCPUs and 32GB RAM, balanced with other services running on the same system.

## Key Research Findings

### 1. Task Runners & Package Management
- **Important**: Packages must be **pre-installed** in the Docker container - n8n does NOT dynamically install them
- `NODE_FUNCTION_ALLOW_EXTERNAL` only controls access to already-installed packages
- **Warning**: Task runners have known compatibility issues with external modules (as of 2024)
- Recommendation: Start without task runners if you need external packages, enable later when issues are resolved

### 2. SQLite Compatibility
- ✅ Works well for single instance regular mode
- **Capacity**: Good for up to 5,000-10,000 daily executions
- **Limits**:
  - Database size: 4-5GB maximum
  - Concurrent workflows: 10-15
  - Beyond these limits, migrate to PostgreSQL

### 3. Binary Data Management
- Use `filesystem` mode to prevent memory bloat
- Binary data TTL prevents disk space issues
- Note: Cannot use filesystem mode with queue mode (but single instance is fine)

## Recommended Configuration

### Resource Allocation
- **RAM**: 4GB (leaves plenty for other services)
- **CPU**: 2-3 vCPUs
- **Database**: SQLite (default, sufficient for moderate usage)
- **Mode**: Single instance (EXECUTIONS_MODE=regular)

### Environment Variables

```yaml
# Core Settings
EXECUTIONS_MODE: regular  # Single instance mode
N8N_CONCURRENCY: 15  # Good balance for 4GB RAM

# Memory Optimization
NODE_OPTIONS: "--max-old-space-size=3072"  # 3GB heap (leaving 1GB buffer)

# Binary Data Management (Prevents Memory Bloat)
N8N_DEFAULT_BINARY_DATA_MODE: filesystem
N8N_AVAILABLE_BINARY_DATA_MODES: filesystem
EXECUTIONS_DATA_PRUNE: true
EXECUTIONS_DATA_MAX_AGE: 168  # Keep executions for 7 days
N8N_BINARY_DATA_TTL: 60  # Clean binary data after 60 minutes

# Task Runners (Optional - Has Issues with External Packages)
# Uncomment these if you want to enable task runners
# N8N_RUNNERS_ENABLED: true
# N8N_RUNNERS_MODE: internal
# NODE_FUNCTION_ALLOW_BUILTIN: "*"  # Allow all built-in modules
# NODE_FUNCTION_ALLOW_EXTERNAL: "lodash,axios,moment,cheerio"  # Specific packages only

# Performance & Monitoring
N8N_METRICS: true
N8N_PAYLOAD_SIZE_MAX: 32  # MB limit for payloads
GENERIC_TIMEZONE: ${GENERIC_TIMEZONE}

# Security
N8N_BLOCK_ENV_ACCESS_IN_NODE: true  # Prevent code nodes from accessing env vars
```

### Custom Dockerfile for Pre-installed Packages

Create a `Dockerfile.n8n` file:

```dockerfile
FROM docker.n8n.io/n8nio/n8n:latest

USER root

# Install commonly needed npm packages
RUN npm install -g \
    lodash \
    axios \
    moment \
    cheerio \
    csv-parse \
    uuid \
    crypto-js \
    jsonwebtoken

USER node
```

### Docker Compose Configuration

Update the n8n service in `docker-compose-arm.yml`:

```yaml
n8n:
  build:
    context: .
    dockerfile: Dockerfile.n8n
  platform: linux/arm64
  restart: always
  expose:
    - "5678"
  env_file:
    - .env
    - .env-n8n-ai
  environment:
    # All environment variables from above
    - N8N_HOST=${DOMAIN_NAME}
    - N8N_PORT=5678
    - N8N_PROTOCOL=https
    - NODE_ENV=production
    - WEBHOOK_URL=https://${DOMAIN_NAME}/
    - EXECUTIONS_MODE=regular
    - N8N_CONCURRENCY=15
    - NODE_OPTIONS=--max-old-space-size=3072
    - N8N_DEFAULT_BINARY_DATA_MODE=filesystem
    - EXECUTIONS_DATA_PRUNE=true
    - EXECUTIONS_DATA_MAX_AGE=168
    - N8N_METRICS=true
    - N8N_PAYLOAD_SIZE_MAX=32
  volumes:
    - /data/n8n_data:/home/node/.n8n
    - /data/n8n_binary:/home/node/.n8n/binaryData
    - ${DATA_FOLDER}/local_files:/files
  deploy:
    resources:
      limits:
        memory: 4G
        cpus: '2.0'
  networks:
    - internal
    - public
```

## Implementation Steps

1. **Create Custom Dockerfile**
   ```bash
   cd /path/to/docker-compose-directory
   nano Dockerfile.n8n
   # Add the Dockerfile content above
   ```

2. **Update docker-compose-arm.yml**
   - Replace the n8n service configuration with the optimized version
   - Ensure all environment variables are properly set

3. **Create Binary Data Directory**
   ```bash
   sudo mkdir -p /data/n8n_binary
   sudo chown -R 1000:1000 /data/n8n_binary
   ```

4. **Deploy**
   ```bash
   docker-compose -f docker-compose-arm.yml build n8n
   docker-compose -f docker-compose-arm.yml up -d n8n
   ```

## Monitoring & Maintenance

### Check Resource Usage
```bash
docker stats n8n
```

### View Logs
```bash
docker-compose -f docker-compose-arm.yml logs -f n8n
```

### SQLite Database Location
- Path: `/data/n8n_data/database.sqlite`
- Backup regularly!

### Binary Data Cleanup
- Automatically handled by TTL settings
- Manual cleanup if needed: `rm -rf /data/n8n_binary/*`

## Performance Expectations

With this configuration:
- **Concurrent Workflows**: 10-15
- **Daily Executions**: Up to 5,000-10,000
- **Memory Usage**: 2-3GB typical, 4GB maximum
- **Response Time**: Fast for most workflows
- **Binary Data**: Automatically cleaned after 60 minutes

## Upgrade Path

When you outgrow SQLite (>5,000 daily executions):
1. Switch to PostgreSQL
2. Consider queue mode with multiple workers
3. Increase RAM allocation to 6-8GB

## Known Issues & Workarounds

### Task Runners with External Packages
- **Issue**: Task runners may fail with "Module is disallowed" errors even with proper configuration
- **Workaround**: Disable task runners if using external npm packages
- **Status**: Monitor n8n releases for fixes

### Memory Leaks
- **Issue**: Some versions show gradual memory increase
- **Workaround**: Restart n8n weekly via cron:
  ```bash
  0 3 * * 0 docker-compose -f docker-compose-arm.yml restart n8n
  ```

## Security Best Practices

1. **Limit Package Access**: Only allow specific packages, not wildcards
2. **Block Environment Access**: Set `N8N_BLOCK_ENV_ACCESS_IN_NODE=true`
3. **Use External Secrets**: Store credentials in environment variables, not in workflows
4. **Regular Updates**: Keep n8n image updated for security patches
5. **Network Isolation**: Use Docker networks to isolate services

## Support Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community Forum](https://community.n8n.io/)
- [n8n GitHub Issues](https://github.com/n8n-io/n8n/issues)