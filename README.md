# Self-Hosted Services Stack on Digital Ocean

A production-ready Docker Compose setup for running multiple self-hosted services with automatic HTTPS, optimized for Digital Ocean droplets with limited resources (4GB RAM).

## 🚀 Services Included

### Core Infrastructure
- **Caddy**: Automatic HTTPS reverse proxy with Let's Encrypt SSL certificates
- **Redis**: In-memory data store for caching and queues

### Productivity & Automation
- **n8n**: Visual workflow automation tool - create complex automations without code
- **Windmill**: Developer platform for turning scripts into workflows, APIs, and UIs (13x faster than Airflow)

### Databases & Data
- **NocoDB**: Open-source Airtable alternative - turn any database into a smart spreadsheet
- **Supabase**: Open-source Firebase alternative with PostgreSQL, auth, storage, and real-time subscriptions
- **Qdrant**: High-performance vector database for AI/ML applications

### Knowledge Management
- **SiYuan**: Privacy-first, self-hosted note-taking and knowledge management (Notion alternative)

## 🏗️ Architecture

- **Storage**: All persistent data on Digital Ocean Volume (`/mnt/volume_fra1_01/`)
- **Backups**: Automatic via Digital Ocean Volume Snapshots
- **File Storage**: Digital Ocean Spaces (S3-compatible) for Supabase & Windmill artifacts
- **Security**: Resource limits, network isolation, localhost-only databases
- **Domains**: Each service on its own subdomain (e.g., `supabase.run8n.xyz`)

## 📊 Resource Usage (4GB System)

| Service | RAM | CPU | Purpose |
|---------|-----|-----|---------|
| n8n + Redis | ~1GB | 0.5 | Automation workflows |
| Supabase | ~1GB | 1.0 | Backend-as-a-Service |
| Windmill | ~1.2GB | 1.3 | Script orchestration |
| NocoDB | ~200MB | 0.2 | Database UI |
| Qdrant | ~300MB | 0.3 | Vector search |
| SiYuan | ~300MB | 0.2 | Note-taking |
| **Total** | ~4GB | ~3.5 vCPU | Full stack |

## 🌐 Service URLs

After deployment, access your services at:

- **n8n**: https://yourdomain.com
- **Supabase**: https://supabase.yourdomain.com
- **Windmill**: https://windmill.yourdomain.com
- **NocoDB**: https://nocodb.yourdomain.com
- **SiYuan**: https://siyuan.yourdomain.com

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository>
   cd run8n-docker-caddy
   ```

2. **Copy and configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

3. **Use secure configuration**
   ```bash
   cp docker-compose-secure.yml docker-compose.yml
   ```

4. **Create required directories**
   ```bash
   mkdir -p /mnt/volume_fra1_01/{supabase_postgres,windmill_postgres,windmill/worker_cache}
   ```

5. **Deploy**
   ```bash
   docker compose up -d
   ```

## 📚 Documentation

- [Secrets Setup Guide](./secrets-setup-guide.md) - Detailed guide for all environment variables
- [Supabase Research](./supabase-research.md) - Supabase configuration details
- [Windmill Research](./windmill-research.md) - Windmill configuration details
- [Integration Plan](./integration-plan.md) - Architecture and resource planning

## 🔒 Security Features

- Resource limits prevent OOM kills
- Kong API Gateway on localhost only
- Network isolation between service groups
- No Docker socket mounting for Windmill
- Automatic SSL via Caddy
- All databases on localhost only

## 📋 Prerequisites

Self-hosting requires technical knowledge, including:

* Setting up and configuring servers and containers
* Managing application resources and scaling
* Securing servers and applications
* DNS configuration for subdomains
* Basic PostgreSQL administration
* Docker and Docker Compose

## 💾 Backup Strategy

1. **Automatic**: Digital Ocean Volume Snapshots (configured at DO level)
2. **Manual**: Database dumps to S3
   ```bash
   docker exec supabase_db pg_dump -U supabase_admin postgres > backup.sql
   docker exec windmill_db pg_dump -U postgres windmill >> backup.sql
   ```

## 📈 Monitoring

Monitor resource usage:
```bash
docker stats
```

View logs:
```bash
docker compose logs -f [service-name]
```

## ⚠️ Important Notes

- Minimum requirement: 4GB RAM, 2 vCPU
- Recommended: 8GB RAM for comfortable operation
- First-time setup creates default accounts (change passwords immediately)
- SMTP is optional (can be configured later for email features)

## 🆘 Support

- [n8n Forums](https://community.n8n.io/)
- [Supabase Docs](https://supabase.com/docs)
- [Windmill Docs](https://windmill.dev/docs)

## 📄 License

MIT License - See LICENSE file for details