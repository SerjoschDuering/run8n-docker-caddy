# MCP Deployment System - Setup Summary

## ✅ What Was Created

### 1. **Automated Deployment Infrastructure**
- ✅ `docker-compose-mcp.yml` - Container orchestration for MCP servers
- ✅ `deploy-mcp.sh` - Deployment script (called by GitHub Actions)
- ✅ `.github-workflow-template.yml` - Reusable GitHub Actions template
- ✅ `MCP-DEPLOYMENT.md` - Complete deployment documentation
- ✅ Updated `Caddyfile` with dynamic path-based routing

### 2. **SiYuan MCP Server Configuration**
- ✅ `.github/workflows/deploy.yml` - Automated deployment workflow
- Ready to deploy on push to `main` or `v2-clean-atomic-tools` branch

## 🚀 Next Steps

### Step 1: Setup on Hetzner Server (One-time)

SSH into your Hetzner server and run:

```bash
# 1. Copy files to server
cd /home/joo/run8n

# 2. Make deployment script executable
chmod +x deploy-mcp.sh

# 3. Create MCP network
docker network create mcp_network 2>/dev/null || echo "Network already exists"

# 4. Start MCP services
docker-compose -f docker-compose-mcp.yml up -d

# 5. Reload Caddy with new config
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# 6. Verify
docker ps | grep mcp
docker network ls | grep run8n_public
```

**Note:** For each new MCP server, you'll need to manually add a route in `Caddyfile`:
```
handle /myserver* {
    reverse_proxy myserver-mcp:3000
}
```
Then reload Caddy.

### Step 2: Configure GitHub Secrets (Per MCP Repo)

For each MCP server repo (e.g., siyuan-mcp-server):

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `HETZNER_SSH_KEY` | Your SSH private key (entire content) |
| `HETZNER_HOST` | Your server IP or hostname (e.g., `run8n.xyz`) |
| `HETZNER_USER` | SSH username (recommended: `github-deploy`, or `root`) |

**🔒 Security Recommendation:** Create a dedicated user `github-deploy` instead of using `root`. See [MCP-DEPLOYMENT.md](./MCP-DEPLOYMENT.md#ssh-key-setup-recommended-dedicated-user) for details.

**Generate SSH Key (if needed):**
```bash
ssh-keygen -t ed25519 -C "github-actions-mcp" -f ~/.ssh/hetzner_mcp_deploy

# Add public key to Hetzner
cat ~/.ssh/hetzner_mcp_deploy.pub
# Copy and add to: /root/.ssh/authorized_keys on Hetzner

# Copy private key for GitHub secrets
cat ~/.ssh/hetzner_mcp_deploy
# Paste entire content into HETZNER_SSH_KEY secret
```

### Step 3: Test Deployment

**For siyuan-mcp-server:**

```bash
cd /Users/Joo/01_Projects/siyuan-mcp-server

# Option 1: Push to trigger auto-deployment
git add .
git commit -m "Setup automated deployment"
git push origin v2-clean-atomic-tools

# Option 2: Trigger manually in GitHub UI
# Go to: Actions tab → Deploy MCP Server → Run workflow
```

Watch deployment:
- GitHub: `https://github.com/YOUR_USERNAME/siyuan-mcp-server/actions`
- Server logs: `ssh root@run8n.xyz "docker logs siyuan-mcp -f"`

### Step 4: Verify Deployment

Once deployed, test the endpoint:

```bash
# Health check (adjust based on your MCP server)
curl https://mcp.run8n.xyz/siyuan

# Check container
ssh root@run8n.xyz "docker ps | grep siyuan-mcp"
```

## 📦 Adding More MCP Servers

To add a new MCP server (e.g., `notion-mcp`):

### 1. Create Your MCP Server Repo

```bash
git clone https://github.com/YOUR_USERNAME/notion-mcp-server
cd notion-mcp-server
```

### 2. Copy Workflow Template

```bash
cp /Users/Joo/01_Projects/n8n_dep/run8n-docker-caddy/.github-workflow-template.yml \
   .github/workflows/deploy.yml
```

### 3. Update Workflow Config

Edit `.github/workflows/deploy.yml`:

```yaml
env:
  MCP_NAME: notion  # ← Change this
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
```

### 4. Add to docker-compose-mcp.yml

On Hetzner, edit `/home/joo/run8n/docker-compose-mcp.yml`:

```yaml
  notion-mcp:
    image: ghcr.io/YOUR_USERNAME/notion-mcp-server:latest
    restart: unless-stopped
    container_name: notion-mcp
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

### 5. Configure GitHub Secrets

Add the same 3 secrets (HETZNER_SSH_KEY, HETZNER_HOST, HETZNER_USER).

### 6. Push and Deploy!

```bash
git add .
git commit -m "Setup automated deployment"
git push origin main
```

Your MCP server will be available at: `https://mcp.run8n.xyz/notion`

## 🎯 Architecture Benefits

✅ **Zero Manual Deployment** - Push to GitHub → Auto-deployed
✅ **Dynamic Routing** - No Caddy config needed per server
✅ **Path-Based URLs** - Clean, simple: `mcp.run8n.xyz/{name}`
✅ **Resource Isolated** - Each MCP in its own container
✅ **Version Controlled** - All config in Git

## 📚 Documentation

- **Full Guide**: [MCP-DEPLOYMENT.md](./MCP-DEPLOYMENT.md)
- **Workflow Template**: [.github-workflow-template.yml](./.github-workflow-template.yml)
- **Deployment Script**: [deploy-mcp.sh](./deploy-mcp.sh)

## 🐛 Troubleshooting

### Workflow Fails

Check GitHub Actions logs for specific error.

### Can't SSH from GitHub Actions

1. Verify private key has no extra newlines
2. Test SSH locally: `ssh -i ~/.ssh/hetzner_mcp_deploy root@run8n.xyz`
3. Check `authorized_keys` on server

### Container Not Starting

```bash
ssh root@run8n.xyz
docker logs {name}-mcp --tail 100
```

### URL Returns 404

1. Check Caddy: `docker logs caddy | grep mcp`
2. Verify container name follows pattern: `{name}-mcp`
3. Test direct access: `docker exec {name}-mcp curl localhost:3000`

## 🎉 Success Criteria

You'll know everything works when:

1. ✅ Push to GitHub triggers deployment
2. ✅ Container appears: `docker ps | grep mcp`
3. ✅ URL responds: `curl https://mcp.run8n.xyz/siyuan`
4. ✅ Client can connect with token in header

---

**Questions?** See [MCP-DEPLOYMENT.md](./MCP-DEPLOYMENT.md) for detailed docs.
