# MCP Server Deployment Guide

Automated deployment system for Model Context Protocol (MCP) servers on Hetzner Cloud using GitHub Actions.

## 🎯 Overview

This system enables **zero-touch deployment** of MCP servers:
- Push to GitHub → Automatic build & deployment
- Path-based routing: `mcp.run8n.xyz/{name}`
- Dynamic Caddy routing (no manual config)
- One GitHub repo per MCP server

## 🏗️ Architecture

```
┌─────────────────┐
│   GitHub Repo   │ Push to main
│ (MCP Server)    │────────┐
└─────────────────┘        │
                           ▼
                  ┌──────────────────┐
                  │ GitHub Actions   │
                  │ • Build Docker   │
                  │ • Push to GHCR   │
                  │ • Deploy via SSH │
                  └──────────────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │ Hetzner Server   │
                  │ • Pull image     │
                  │ • Restart service│
                  └──────────────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │ Caddy Gateway    │
                  │ mcp.run8n.xyz    │
                  │ /siyuan → siyuan-mcp:3000
                  │ /notion → notion-mcp:3000
                  └──────────────────┘
```

## 🚀 Quick Start: Deploy a New MCP Server

### 1. Prepare Your MCP Server Repository

Your repo needs:
- **Dockerfile** - Builds your MCP server
- **GitHub workflow** - Automates deployment

### 2. Copy GitHub Workflow

Copy `.github-workflow-template.yml` from this repo to your MCP repo:

```bash
mkdir -p .github/workflows
cp path/to/run8n-docker-caddy/.github-workflow-template.yml .github/workflows/deploy.yml
```

### 3. Configure Workflow

Edit `.github/workflows/deploy.yml`:

```yaml
env:
  MCP_NAME: myserver              # URL will be: mcp.run8n.xyz/myserver
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  DOCKER_CONTEXT: .
  DOCKERFILE: Dockerfile
```

### 4. Set GitHub Secrets

In your GitHub repo settings → Secrets and variables → Actions, add:

| Secret | Description | Example |
|--------|-------------|---------|
| `HETZNER_SSH_KEY` | SSH private key for Hetzner | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `HETZNER_HOST` | Hetzner server IP/hostname | `168.119.xxx.xxx` or `run8n.xyz` |
| `HETZNER_USER` | SSH username | `root` |

**Generate SSH key if needed:**
```bash
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/hetzner_deploy
# Add public key to Hetzner: ~/.ssh/hetzner_deploy.pub
# Add private key to GitHub secrets: ~/.ssh/hetzner_deploy
```

### 5. Add Service to docker-compose-mcp.yml

On Hetzner server, edit `/mnt/volume_fra1_01/run8n-docker-caddy/docker-compose-mcp.yml`:

```yaml
  myserver-mcp:
    image: ghcr.io/yourusername/myserver-mcp:latest
    restart: unless-stopped
    container_name: myserver-mcp
    expose:
      - "3000"
    environment:
      - PORT=3000
      - NODE_ENV=production
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.3'
    networks:
      - mcp_network
      - public
```

### 6. Deploy!

Push to main branch:
```bash
git add .
git commit -m "Add automated deployment"
git push origin main
```

GitHub Actions will:
1. ✅ Build Docker image
2. ✅ Push to GitHub Container Registry
3. ✅ SSH to Hetzner
4. ✅ Deploy/update container
5. ✅ Service available at `https://mcp.run8n.xyz/myserver`

## 📁 File Structure

### Hetzner Server (`/mnt/volume_fra1_01/run8n-docker-caddy/`)

```
run8n-docker-caddy/
├── caddy_config/
│   └── Caddyfile                    # Dynamic routing config
├── docker-compose.yml               # Main services
├── docker-compose-mcp.yml           # MCP services
├── deploy-mcp.sh                    # Deployment script
└── .github-workflow-template.yml    # Template for new MCP servers
```

### MCP Server Repository

```
your-mcp-server/
├── .github/
│   └── workflows/
│       └── deploy.yml               # Deployment workflow
├── src/
│   └── ...                          # Your MCP server code
├── Dockerfile                       # Docker build instructions
├── package.json
└── README.md
```

## 🔧 Manual Operations

### SSH into Hetzner

```bash
ssh root@run8n.xyz  # or your server IP
```

### Check Running MCP Servers

```bash
cd /mnt/volume_fra1_01/run8n-docker-caddy
docker-compose -f docker-compose-mcp.yml ps
```

### View Logs

```bash
docker logs siyuan-mcp -f
```

### Manually Deploy/Update

```bash
./deploy-mcp.sh siyuan ghcr.io/onigeya/siyuan-mcp-server:latest
```

### Restart All MCP Services

```bash
docker-compose -f docker-compose-mcp.yml restart
```

### Stop a Service

```bash
docker-compose -f docker-compose-mcp.yml stop siyuan-mcp
```

## 🌐 Caddy Dynamic Routing

Caddy automatically routes paths to containers using this pattern:

```
URL: mcp.run8n.xyz/{name}
  ↓
Container: {name}-mcp:3000
```

**Examples:**
- `mcp.run8n.xyz/siyuan` → `siyuan-mcp:3000`
- `mcp.run8n.xyz/notion` → `notion-mcp:3000`
- `mcp.run8n.xyz/s3` → `s3-mcp:3000`

**No manual Caddy configuration needed!** Just follow the naming convention: `{name}-mcp`

## 🔒 Security

### Token Security Model

MCP servers should be **stateless** - tokens sent by client in headers:

**✅ Correct (Client config):**
```json
{
  "mcpServers": {
    "siyuan": {
      "url": "https://mcp.run8n.xyz/siyuan",
      "transport": "streamable-http",
      "headers": {
        "X-SiYuan-Token": "YOUR_PRIVATE_TOKEN"
      }
    }
  }
}
```

**❌ Wrong (Server-side storage):**
```yaml
# DON'T do this!
environment:
  - SIYUAN_TOKEN=secret123  # Tokens should come from client!
```

### HTTPS

All MCP endpoints use HTTPS via Caddy + Let's Encrypt (automatic).

## 🐛 Troubleshooting

### Deployment Failed

Check GitHub Actions logs in your repo's Actions tab.

### Container Not Starting

```bash
docker logs {name}-mcp --tail 100
```

### Can't Access URL

1. Check container is running:
   ```bash
   docker ps | grep {name}-mcp
   ```

2. Check Caddy logs:
   ```bash
   docker logs caddy --tail 50
   ```

3. Test container directly:
   ```bash
   docker exec {name}-mcp curl http://localhost:3000
   ```

### Workflow Can't SSH

1. Verify SSH key in GitHub secrets (no newline at end)
2. Test SSH manually:
   ```bash
   ssh -i ~/.ssh/hetzner_deploy root@run8n.xyz
   ```

## 📝 Example: SiYuan MCP Server

See `/Users/Joo/01_Projects/siyuan-mcp-server/` for complete example:
- `.github/workflows/deploy.yml` - GitHub Actions workflow
- `Dockerfile` - Multi-stage build
- `src-v2/` - MCP server implementation

## 🎓 Best Practices

1. **Container naming**: Always use `{name}-mcp` convention
2. **Resource limits**: Set memory/CPU limits in docker-compose
3. **Health checks**: Add health endpoints to your MCP server
4. **Versioning**: Use semantic versioning for releases
5. **Documentation**: Include client config examples in README

## 📚 Related Documentation

- [Caddy Reverse Proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Docker Compose](https://docs.docker.com/compose/)
- [MCP Specification](https://modelcontextprotocol.io/)

## 🆘 Support

Issues or questions? Check:
1. GitHub Actions workflow logs
2. Docker container logs
3. Caddy access logs: `docker logs caddy`
