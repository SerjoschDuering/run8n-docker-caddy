# Run8n Stack: Master Plan

> From 5/10 to 9/10 — An AI-native production engine

## Vision

**One command. Full-stack app. Live in 30 minutes.**

Claude Code as the control plane for:
- Static sites
- Frontend + backend apps
- Database-backed applications
- Auth-protected services
- AI/vector search apps
- Workflow automations
- Real-time collaboration tools

No GUI. No context-switching. Everything programmable.

---

## Current Server Setup

**Server:** Hetzner VPS `91.98.144.66` (ARM64, 16 vCPU, 32GB RAM)

| Service | Status | Internal | External | Notes |
|---------|--------|----------|----------|-------|
| **Caddy** | ✅ Running | - | `*.run8n.xyz` | Reverse proxy, TLS |
| **n8n** | ✅ Running | `n8n:5678` | `run8n.xyz` | Workflow automation |
| **Windmill** | ✅ Running | `windmill:8000` | `windmill.run8n.xyz` | Scripts, backends |
| **PostgreSQL** | ✅ Running | `postgres:5432` | ❌ Not exposed | Main database |
| **Redis** | ✅ Running | `redis:6379` | ❌ Not exposed | Cache, pub/sub |
| **Qdrant** | ✅ Running | `qdrant:6333` | ❌ Not exposed | Vector search |
| **NocoDB** | ✅ Running | `nocodb:8080` | `nocodb.run8n.xyz` | DB UI + REST API |
| **GoTrue** | ✅ Running | `gotrue:9999` | `auth.run8n.xyz` | Authentication |
| **SiYuan** | ✅ Running | `siyuan:6806` | `siyuan.run8n.xyz` | Note-taking |
| **Homarr** | ✅ Running | `homarr:7575` | `dashboard.run8n.xyz` | Service dashboard |
| **Backblaze B2** | ✅ External | - | S3 API | File storage |

### Current Repositories

| Repo | Location | GitHub |
|------|----------|--------|
| **Infrastructure** | `/Users/Joo/01_Projects/n8n_dep/run8n-docker-caddy/` | `SerjoschDuering/run8n-docker-caddy` |
| **Windmill Scripts** | `/Users/Joo/01_Projects/windmill-monorepo/` | Not on GitHub yet |
| **Claude Skill** | `~/.claude/skills/run8n-stack/` | Not on GitHub yet |

### Access Methods
```bash
# SSH access
ssh -i ~/.ssh/id_ed25519_hetzner_2025 root@91.98.144.66

# Windmill CLI
cd /Users/Joo/01_Projects/windmill-monorepo
wmill sync push/pull
```

---

## Architecture Vision

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CLAUDE CODE (Control Plane)                      │
│                                                                          │
│   /new-project my-app --template=fullstack                               │
│   /db create-table users                                                 │
│   /deploy my-app                                                         │
│   /logs my-app                                                           │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
            ┌────────────────────┼────────────────────┐
            │                    │                    │
            ▼                    ▼                    ▼
    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
    │   Template   │    │   Windmill   │    │    Direct    │
    │    Repos     │    │   Scripts    │    │  SSH/API     │
    │              │    │   (infra)    │    │              │
    └──────────────┘    └──────────────┘    └──────────────┘
            │                    │                    │
            └────────────────────┼────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         HETZNER SERVER                                   │
│                                                                          │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
│   │  Caddy  │  │Windmill │  │Postgres │  │  Redis  │  │ Qdrant  │       │
│   │ (proxy) │  │(backend)│  │  (DB)   │  │ (cache) │  │(vectors)│       │
│   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │
│                                                                          │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────────┐        │
│   │ GoTrue  │  │ NocoDB  │  │   n8n   │  │   Static Sites      │        │
│   │ (auth)  │  │(quick DB)│  │(automate)│  │   /var/www/*       │        │
│   └─────────┘  └─────────┘  └─────────┘  └─────────────────────┘        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Database Strategy: Two Paths

Both paths are valid. Choose based on project needs.

### Path A: Postgres + Prisma (Migrations as Source of Truth)

```
Best for: Proper apps, complex relations, team development

schema.prisma → migrations/ → Postgres
     ↑              ↑
  (source)      (versioned)

Workflow:
1. Edit prisma/schema.prisma
2. pnpm db:migrate --name add_feature
3. Commit migrations to git
4. Deploy runs migrations on prod
```

### Path B: NocoDB API (NocoDB as Source of Truth)

```
Best for: Quick CRUD apps, admin tools, prototypes

NocoDB API → creates tables → Postgres (backing store)
     ↑
  (source, via CLI)

Workflow:
1. Call NocoDB API to create/modify tables (programmatic, no GUI!)
2. Use NocoDB REST API for CRUD operations
3. Auto-generated endpoints, no backend code needed
```

### Path C: Hybrid (Prototype → Migrate)

```
1. Quick prototype with NocoDB API
2. Run db:snapshot → pulls into Prisma
3. Continue with Prisma migrations
```

### Realtime: Redis (Recommended)

```
Redis for:
- Pub/sub messaging
- Session storage
- Cache
- Real-time presence

Postgres LISTEN/NOTIFY exists but Redis is better for scale.
```

### Vectors: Qdrant

```
Qdrant for:
- Embedding storage
- Similarity search
- RAG applications
```

---

## Use Cases & Workflows

### 1. Landing Page + Waitlist
```
Template: run8n-static
Time: 10 minutes

Claude Code:
├── Create landing page HTML
├── NocoDB API → waitlist table
├── Windmill → /api/signup endpoint
└── Deploy to landing.run8n.xyz
```

### 2. SaaS App with Auth
```
Template: run8n-fullstack
Time: 30 minutes

Claude Code:
├── Clone template
├── Prisma schema → User, Project models
├── pnpm db:migrate
├── GoTrue integration (login/signup)
├── Windmill endpoints (CRUD)
├── Frontend (Vite + React/Vue)
└── Deploy to app.run8n.xyz
```

### 3. AI/RAG Application
```
Template: run8n-ai
Time: 30 minutes

Claude Code:
├── Clone template
├── Windmill: ingest → embed → Qdrant
├── Windmill: query → search → LLM response
├── Chat frontend
└── Deploy to chat.run8n.xyz
```

### 4. Internal Tool / Admin
```
Template: run8n-admin
Time: 15 minutes

Claude Code:
├── NocoDB API → create tables
├── Frontend uses NocoDB REST directly
├── (Optional) GoTrue for team auth
└── Deploy to admin.run8n.xyz
```

### 5. Workflow Automation
```
Template: run8n-workflow
Time: 20 minutes

Claude Code:
├── Define workflow in Windmill
├── Schedules, webhooks, integrations
├── Monitor via Windmill UI
└── No frontend needed
```

### 6. Real-time Collaboration
```
Template: run8n-realtime
Time: 45 minutes

Claude Code:
├── Redis pub/sub setup
├── WebSocket handler (Windmill or container)
├── Frontend with WS connection
├── Postgres for persistence
└── Deploy
```

---

## Template Specifications

### Template Repository Structure

```
run8n-{template-name}/
├── CLAUDE.md              # AI instructions (critical!)
├── README.md              # Human documentation
├── package.json           # Scripts
├── .env.example           # Environment template
│
├── prisma/                # Database (if applicable)
│   ├── schema.prisma
│   └── migrations/
│
├── src/                   # Frontend source
│   ├── index.html
│   └── ...
│
├── windmill/              # Backend scripts (if applicable)
│   └── f/
│       └── api/
│           └── endpoints.ts
│
├── scripts/
│   ├── deploy.sh          # One-liner deploy
│   ├── db-snapshot.sh     # NocoDB → Prisma
│   └── setup.sh           # First-time setup
│
└── .github/               # CI/CD (optional)
    └── workflows/
        └── deploy.yml
```

### CLAUDE.md Template Content

Each template's CLAUDE.md should contain:

```markdown
# {Project Name}

Template: run8n-{type}
Created: {date}

## Quick Start

\`\`\`bash
pnpm install
cp .env.example .env
# Edit .env with your values
pnpm dev
\`\`\`

## Project Configuration

- **Database:** {schema name or "none"}
- **Auth:** {GoTrue / none}
- **Storage:** {Backblaze / none}
- **Vectors:** {Qdrant / none}

## Database Workflow

| Action | Command |
|--------|---------|
| Create migration | `pnpm db:migrate` |
| Push schema (dev) | `pnpm db:push` |
| Snapshot from NocoDB | `pnpm db:snapshot` |
| Open studio | `pnpm db:studio` |

### Schema Authority Rules
- Dev prototyping in NocoDB: ✅ allowed
- After prototyping: run `db:snapshot` immediately
- Ongoing changes: Prisma migrations only
- Staging/Prod: Never use NocoDB for schema changes

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| /api/... | GET | ... |

## Deployment

\`\`\`bash
pnpm deploy        # Deploy to production
pnpm deploy:staging # Deploy to staging
\`\`\`

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| DATABASE_URL | Postgres connection | postgres://... |
| GOTRUE_URL | Auth endpoint | https://auth.run8n.xyz |
| ... | ... | ... |

## File Structure

- `src/` - Frontend code
- `windmill/` - Backend scripts
- `prisma/` - Database schema
- `scripts/` - Deployment and utilities

## Common Tasks

### Add a new API endpoint
1. Create script in `windmill/f/api/`
2. Run `wmill sync push`
3. Endpoint available at `windmill.run8n.xyz/api/w/main/...`

### Add a new database table
1. Edit `prisma/schema.prisma`
2. Run `pnpm db:migrate --name add_tablename`
3. Use Prisma client in Windmill scripts

### Add authentication to a page
1. Import GoTrue client from `src/lib/auth`
2. Wrap component with `<AuthGuard>`
3. Access user via `useAuth()` hook
```

---

## Claude Code Skill Content

The `run8n-stack` skill should contain:

### 1. Connection Information
```markdown
## Server Access

Server: 91.98.144.66
SSH: ssh -i ~/.ssh/id_ed25519_hetzner_2025 root@91.98.144.66

## Service URLs

| Service | URL |
|---------|-----|
| n8n | https://run8n.xyz |
| Windmill | https://windmill.run8n.xyz |
| NocoDB | https://nocodb.run8n.xyz |
| GoTrue | https://auth.run8n.xyz |
```

### 2. Quick Commands
```markdown
## Database Commands

# Create new project schema
ssh root@91.98.144.66 'psql -U postgres -c "CREATE SCHEMA project_NAME;"'

# List schemas
ssh root@91.98.144.66 'psql -U postgres -c "\\dn"'
```

### 3. API Patterns
```markdown
## NocoDB API

# Create table
curl -X POST "https://nocodb.run8n.xyz/api/v2/meta/bases/{base_id}/tables" \
  -H "xc-token: $NOCODB_TOKEN" \
  -d '{"table_name": "users", "columns": [...]}'

# List records
curl "https://nocodb.run8n.xyz/api/v2/tables/{table_id}/records" \
  -H "xc-token: $NOCODB_TOKEN"
```

### 4. Template Commands
```markdown
## Create New Project

# Clone template
git clone https://github.com/yourorg/run8n-fullstack my-app
cd my-app

# Setup
pnpm install
cp .env.example .env
# Configure DATABASE_URL to use project-specific schema
pnpm db:push
pnpm dev
```

### 5. Deployment Recipes
```markdown
## Deploy Static Site

rsync -avz --delete ./dist/ root@91.98.144.66:/srv/mysite/
# Caddy serves from /srv/ (mapped from /opt/run8n_data/static_sites/)

## Deploy with Custom Domain

# Add to Caddyfile on server:
mysite.run8n.xyz {
    root * /var/www/mysite
    file_server
}

# Reload Caddy
ssh root@91.98.144.66 'caddy reload -c /etc/caddy/Caddyfile'
```

---

## Scaling & Enterprise Path

### Phase 1: Single Server (Current)
- All services on one Hetzner VPS
- Good for: prototypes, small production apps
- Cost: ~€10-20/month

### Phase 2: Managed Database
- Move Postgres to Hetzner Managed DB or Supabase
- Benefits: backups, scaling, HA
- Cost: +€15-50/month

### Phase 3: Multiple Instances
- Duplicate stack to new servers
- Load balancer in front
- Shared managed DB
- Cost: +€20-50/month per instance

### Phase 4: Enterprise Client Deployment
- Same stack, client's infrastructure
- Options: Hetzner, AWS, Azure, on-prem
- Docker Compose is portable
- Windmill scripts export/import

---

## When to Switch to Full Containers

### Stay with Windmill
- API endpoints, webhooks
- Scheduled jobs, automations
- Simple CRUD backends
- < 500ms response time OK
- Solo or small team

### Switch to Docker/FastAPI/etc.
- Complex business logic (100+ files)
- Real-time WebSockets (persistent connections)
- Custom ML models, heavy compute
- Need < 50ms latency
- Team prefers traditional stack
- Outgrew "functions as backend"

### Hybrid Approach
- Windmill for: automations, simple endpoints, scheduled jobs
- Containers for: main backend, WebSockets, compute-heavy
- Both can coexist on same server

### Container Deployment Template (run8n-container)
```
run8n-container/
├── CLAUDE.md
├── README.md
├── docker-compose.yml          # Local dev: app + postgres + redis
├── docker-compose.prod.yml     # Production overrides
├── Dockerfile
│
├── backend/
│   ├── src/
│   │   ├── main.py             # FastAPI app
│   │   ├── routers/
│   │   ├── models/
│   │   └── services/
│   ├── requirements.txt
│   └── alembic/                # Migrations (alternative to Prisma)
│       └── versions/
│
├── frontend/
│   ├── src/
│   ├── package.json
│   └── vite.config.ts
│
├── scripts/
│   ├── deploy.sh               # Build + push + restart on server
│   ├── setup-server.sh         # First-time server setup
│   └── rollback.sh             # Quick rollback
│
└── .github/
    └── workflows/
        ├── ci.yml              # Test on PR
        └── deploy.yml          # Deploy on merge to main
```

**Server-side glue for containers:**
```bash
# On server: /opt/apps/{app-name}/
├── docker-compose.yml          # Pulled from repo
├── .env                        # Production secrets
└── data/                       # Persistent volumes

# Caddy config addition:
myapp.run8n.xyz {
    reverse_proxy localhost:8000
}

# Deploy script (called by CI/CD):
cd /opt/apps/myapp
git pull
docker compose pull
docker compose up -d
```

### SaaS / Stripe Template (run8n-saas)
```
run8n-saas/
├── CLAUDE.md
├── README.md
│
├── prisma/
│   └── schema.prisma           # User, Subscription, Plan models
│
├── src/
│   ├── lib/
│   │   ├── auth.ts             # GoTrue client
│   │   ├── stripe.ts           # Stripe client
│   │   └── db.ts               # Prisma client
│   │
│   ├── pages/
│   │   ├── pricing.tsx         # Plan selection
│   │   ├── checkout.tsx        # Stripe checkout
│   │   └── dashboard.tsx       # Protected area
│   │
│   └── components/
│       └── PaymentGuard.tsx    # Check subscription status
│
├── windmill/
│   └── f/
│       └── stripe/
│           ├── create_checkout_session.ts
│           ├── webhook_handler.ts      # Stripe webhooks
│           ├── get_subscription.ts
│           └── cancel_subscription.ts
│
└── scripts/
    └── setup-stripe.sh         # Configure webhook endpoints
```

**Stripe flow:**
```
User clicks "Subscribe"
    → Windmill: create_checkout_session
    → Redirect to Stripe Checkout
    → User pays
    → Stripe webhook → Windmill: webhook_handler
    → Update user subscription in DB
    → User redirected to dashboard
```

### MCP Server Template (run8n-mcp)

**Based on:** `SerjoschDuering/siyuan-mcp-server` - excellent existing structure

```
run8n-mcp/
├── CLAUDE.md                   # AI instructions (key docs index)
├── README.md                   # Human documentation
│
├── docs/
│   ├── CONFIGURATION.md        # Setup & environment
│   ├── USER_GUIDE.md           # Usage workflows
│   ├── DEPLOYMENT.md           # Docker, Caddy, PM2, systemd
│   ├── DEVELOPER_GUIDE.md      # Architecture, contributing
│   └── TOOL_REFERENCE.md       # API reference
│
├── src/
│   ├── index.ts                # Main entry point
│   ├── tools/                  # MCP tool implementations
│   └── utils/                  # Shared utilities
│
├── Dockerfile                  # Container build
├── docker-compose.yml          # Local dev with dependencies
├── manifest.json               # MCP manifest
├── smithery.yaml               # MCP packaging config
├── package.json
├── tsconfig.json
│
└── scripts/
    ├── deploy.sh               # Deploy to server
    └── build-mcpb.sh           # Build .mcpb package
```

**Deployment pattern (from siyuan-mcp-server):**
- Docker container on server
- Caddy reverse proxy for HTTPS
- PM2 or systemd for process management
- Health endpoint for monitoring

---

## TODO: From 5/10 to 9/10

### Phase 1: Enable Database Access (5→6)
- [ ] Expose Postgres port with password auth
- [ ] Configure pg_hba.conf for internal trust
- [ ] Expose Qdrant via Caddy with basic auth
- [ ] Get NocoDB API token
- [ ] Test connections from local machine
- [ ] Document connection strings

### Phase 2: Create First Template (6→7)
- [ ] Create `run8n-fullstack` template repo
- [ ] Include Prisma + GoTrue + Vite
- [ ] Write CLAUDE.md with all patterns
- [ ] Add deployment scripts
- [ ] Test: clone → develop → deploy in < 30 min

### Phase 3: Windmill Integration (7→7.5)
- [ ] Create `run8n-workflow` template
- [ ] Document Windmill script patterns
- [ ] Add infra scripts (create schema, etc.)
- [ ] Integrate with fullstack template

### Phase 4: All Templates (7.5→8)
- [ ] `run8n-static` - Landing pages
- [ ] `run8n-admin` - NocoDB-backed admin (NocoDB as source of truth)
- [ ] `run8n-ai` - Qdrant + embeddings
- [ ] `run8n-realtime` - Redis pub/sub + WebSockets
- [ ] `run8n-container` - Docker/FastAPI with CI/CD pipeline
- [ ] `run8n-saas` - Stripe + Auth + Database (monetization template)
- [ ] `run8n-mcp` - MCP server template (based on siyuan-mcp-server structure)

### Phase 5: Polish & Automation (8→9)
- [ ] Update Claude Code skill with all patterns
- [ ] Add CI/CD workflow templates
- [ ] Set up automated backups
- [ ] Add monitoring (uptime, errors)
- [ ] Create team onboarding docs
- [ ] Test enterprise deployment (new server)

---

## Success Criteria

**We've reached 9/10 when:**

1. `"Build me a SaaS with auth and database"` → live app in 30 minutes
2. `"Add AI search to this app"` → working in 15 minutes
3. `"Deploy this to client's server"` → same workflow, new IP
4. `"Add a team member"` → they can develop in < 1 hour
5. Zero GUI interaction required for any common task

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                    RUN8N QUICK REFERENCE                     │
├─────────────────────────────────────────────────────────────┤
│ NEW PROJECT                                                  │
│   git clone run8n-fullstack my-app && cd my-app             │
│   pnpm install && pnpm dev                                   │
├─────────────────────────────────────────────────────────────┤
│ DATABASE                                                     │
│   pnpm db:push          Quick sync schema                   │
│   pnpm db:migrate       Create migration                    │
│   pnpm db:snapshot      Pull NocoDB → Prisma                │
├─────────────────────────────────────────────────────────────┤
│ DEPLOY                                                       │
│   pnpm deploy           Deploy to production                │
│   pnpm deploy:staging   Deploy to staging                   │
├─────────────────────────────────────────────────────────────┤
│ WINDMILL                                                     │
│   wmill sync push       Push scripts to server              │
│   wmill sync pull       Pull scripts from server            │
├─────────────────────────────────────────────────────────────┤
│ SERVER                                                       │
│   ssh hetzner           Connect to server                   │
│   run8n logs app        View app logs                       │
└─────────────────────────────────────────────────────────────┘
```

---

*Last updated: 2025-01-09*
*Version: 0.1 (Planning Phase)*
