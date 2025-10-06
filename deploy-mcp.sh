#!/bin/bash

# MCP Server Deployment Script
# Called by GitHub Actions to deploy/update MCP servers on Hetzner
# Usage: ./deploy-mcp.sh <mcp-name> <image-name>
# Example: ./deploy-mcp.sh siyuan ghcr.io/onigeya/siyuan-mcp-server:latest

set -e

MCP_NAME=$1
IMAGE_NAME=$2
COMPOSE_FILE="/mnt/volume_fra1_01/run8n-docker-caddy/docker-compose-mcp.yml"
CADDY_FILE="/mnt/volume_fra1_01/run8n-docker-caddy/caddy_config/Caddyfile"

# Validation
if [ -z "$MCP_NAME" ] || [ -z "$IMAGE_NAME" ]; then
    echo "❌ Error: Missing arguments"
    echo "Usage: ./deploy-mcp.sh <mcp-name> <image-name>"
    echo "Example: ./deploy-mcp.sh siyuan ghcr.io/onigeya/siyuan-mcp-server:latest"
    exit 1
fi

echo "🚀 Deploying MCP Server: $MCP_NAME"
echo "📦 Image: $IMAGE_NAME"

# Step 1: Pull latest image
echo "⬇️  Pulling latest Docker image..."
docker pull "$IMAGE_NAME"

# Step 2: Update compose file if needed
SERVICE_NAME="${MCP_NAME}-mcp"
if ! grep -q "$SERVICE_NAME:" "$COMPOSE_FILE"; then
    echo "⚠️  Service $SERVICE_NAME not found in docker-compose-mcp.yml"
    echo "Please add the service definition manually."
    exit 1
fi

# Step 3: Restart the MCP service
echo "🔄 Restarting MCP service..."
cd /mnt/volume_fra1_01/run8n-docker-caddy
docker-compose -f docker-compose-mcp.yml up -d "$SERVICE_NAME"

# Step 4: Caddy auto-routes (no manual config needed)
echo "✅ Caddy will auto-route: mcp.run8n.xyz/$MCP_NAME → $SERVICE_NAME:3000"

# Step 5: Health check
echo "🏥 Waiting for service to be healthy..."
sleep 5

if docker ps | grep -q "$SERVICE_NAME"; then
    echo "✅ MCP Server deployed successfully!"
    echo "🌐 Available at: https://mcp.run8n.xyz/$MCP_NAME"
else
    echo "❌ Deployment failed - container not running"
    docker logs "$SERVICE_NAME" --tail 50
    exit 1
fi
