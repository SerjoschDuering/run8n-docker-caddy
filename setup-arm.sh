#!/bin/bash

# ===========================================
# Setup script for ARM-based Hetzner server
# 16 vCPUs, 32GB RAM, 320GB Storage
# ===========================================

set -e

echo "🚀 Setting up ARM-optimized Docker stack..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running on ARM64
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    print_warning "This script is optimized for ARM64 architecture. Current architecture: $ARCH"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create data directories with proper structure
print_status "Creating data directories..."
sudo mkdir -p /data/{n8n_data,redis_data,supabase_postgres,windmill_postgres,windmill/{cache,logs,lsp_cache},nocodb_data,qdrant_storage,siyuan_data,prometheus,grafana,caddy_config}

# Set proper permissions
sudo chown -R 1000:1000 /data/n8n_data
sudo chown -R 1000:1000 /data/siyuan_data
sudo chown -R 472:472 /data/grafana 2>/dev/null || true

print_status "Data directories created"

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    print_status "Docker installed. Please log out and back in for group changes to take effect."
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    print_status "Docker Compose installed"
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_status "Creating .env file..."
    cat > .env << 'EOF'
# Domain Configuration
DOMAIN_NAME=your-domain.com
GENERIC_TIMEZONE=Europe/Berlin

# Data Storage
DATA_FOLDER=./data

# Database Passwords (CHANGE THESE!)
SUPABASE_POSTGRES_PASSWORD=changeme_supabase_db_password_32chars
WINDMILL_DB_PASSWORD=changeme_windmill_db_password_32chars
REDIS_PASSWORD=changeme_redis_password_32chars

# Service Passwords
NOCO_PASSWORD=changeme_nocodb_admin_password
SIYUAN_AUTH_CODE=changeme_siyuan_auth_code
GRAFANA_USER=admin
GRAFANA_PASSWORD=changeme_grafana_password

# S3 Configuration (Hetzner Object Storage or alternative)
S3_BUCKET=your-bucket-name
S3_REGION=eu-central
S3_KEY=your_access_key
S3_SECRET=your_secret_key
S3_ENDPOINT=https://eu-central-1.objectstorage.hetzner.cloud
# Or use MinIO locally: S3_ENDPOINT=http://minio:9000

# Supabase Keys (generate at https://supabase.com/docs/guides/self-hosting#generate-api-keys)
SUPABASE_JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# SMTP Configuration (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_ADMIN_EMAIL=admin@example.com
SMTP_SENDER_NAME=Your Service Name

# Additional Settings
DISABLE_SIGNUP=false
ENABLE_EMAIL_SIGNUP=true
EOF
    print_warning ".env file created. Please edit it with your actual values!"
else
    print_status ".env file already exists"
fi

# Create Caddyfile if it doesn't exist
if [ ! -f ./data/caddy_config/Caddyfile ]; then
    print_status "Creating Caddyfile..."
    mkdir -p ./data/caddy_config
    cat > ./data/caddy_config/Caddyfile << 'EOF'
# Main n8n instance
{$DOMAIN_NAME} {
    reverse_proxy n8n:5678 {
        flush_interval -1
    }
}

# Windmill
windmill.{$DOMAIN_NAME} {
    reverse_proxy windmill_server:8000
}

# NocoDB
nocodb.{$DOMAIN_NAME} {
    reverse_proxy nocodb:8080
}

# SiYuan
siyuan.{$DOMAIN_NAME} {
    reverse_proxy siyuan:6806
}

# Grafana (if enabled)
grafana.{$DOMAIN_NAME} {
    reverse_proxy grafana:3000
}

# Supabase (if enabled)
supabase.{$DOMAIN_NAME} {
    reverse_proxy supabase_kong:8000
}
EOF
    print_status "Caddyfile created"
fi

# Download NocoDB ARM binary if official Docker doesn't work
print_status "Downloading NocoDB ARM64 binary as fallback..."
curl -L https://github.com/nocodb/nocodb/releases/latest/download/nocodb-linux-arm64 -o nocodb-arm64
chmod +x nocodb-arm64
print_status "NocoDB ARM64 binary downloaded"

# Create docker network for caddy
docker network create caddy_data 2>/dev/null || true

# System optimizations for ARM
print_status "Applying system optimizations..."

# Increase file limits
cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF

# Optimize kernel parameters for containers
cat > /etc/sysctl.d/99-docker.conf << EOF
# Network optimizations
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# Memory optimizations
vm.max_map_count = 262144
vm.overcommit_memory = 1

# File system optimizations
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
EOF

sudo sysctl -p /etc/sysctl.d/99-docker.conf

print_status "System optimizations applied"

# Create a helper script for operations
cat > manage-stack.sh << 'EOF'
#!/bin/bash

case "$1" in
    start)
        docker-compose -f docker-compose-arm.yml up -d
        ;;
    stop)
        docker-compose -f docker-compose-arm.yml down
        ;;
    restart)
        docker-compose -f docker-compose-arm.yml restart
        ;;
    logs)
        docker-compose -f docker-compose-arm.yml logs -f ${2}
        ;;
    status)
        docker-compose -f docker-compose-arm.yml ps
        docker stats --no-stream
        ;;
    update)
        docker-compose -f docker-compose-arm.yml pull
        docker-compose -f docker-compose-arm.yml up -d
        ;;
    backup)
        echo "Creating backup..."
        tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz /data/
        echo "Backup created"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status|update|backup}"
        exit 1
        ;;
esac
EOF

chmod +x manage-stack.sh

print_status "Management script created: ./manage-stack.sh"

echo ""
echo "=========================================="
echo "       Setup Complete! Next Steps:"
echo "=========================================="
echo ""
echo "1. Edit the .env file with your actual values:"
echo "   nano .env"
echo ""
echo "2. Start the stack:"
echo "   ./manage-stack.sh start"
echo ""
echo "3. Check service status:"
echo "   ./manage-stack.sh status"
echo ""
echo "4. View logs:"
echo "   ./manage-stack.sh logs [service-name]"
echo ""
echo "5. Configure your DNS to point to this server:"
echo "   - ${DOMAIN_NAME} → Server IP"
echo "   - *.${DOMAIN_NAME} → Server IP (wildcard)"
echo ""
echo "=========================================="
echo "       Service URLs (after DNS setup):"
echo "=========================================="
echo "   n8n:       https://${DOMAIN_NAME}"
echo "   Windmill:  https://windmill.${DOMAIN_NAME}"
echo "   NocoDB:    https://nocodb.${DOMAIN_NAME}"
echo "   SiYuan:    https://siyuan.${DOMAIN_NAME}"
echo "   Grafana:   https://grafana.${DOMAIN_NAME}"
echo ""
print_warning "Remember to:"
print_warning "- Change all passwords in .env file"
print_warning "- Set up backups for /data directory"
print_warning "- Configure firewall (ports 80, 443 only)"
print_warning "- Monitor resource usage with: docker stats"