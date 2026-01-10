# Run8n Organization Plan

> How we structure repositories, manage skills, and coordinate team development

## Overview

This document defines the organizational structure for the run8n stack - repositories, access control, skill management, and team workflows.

---

## Repository Landscape

### Current State

```
GitHub: SerjoschDuering/
│
├── run8n-docker-caddy           # ✅ Exists - Server infrastructure
├── siyuan-mcp-server            # ✅ Exists - MCP server (template reference)
├── rhino-mcp                    # ✅ Exists - Rhino MCP server
├── ClaudeCodeSlashPrompts       # ✅ Exists - Slash command templates
└── [other projects]

Local Only (not on GitHub):
├── windmill-monorepo            # /Users/Joo/01_Projects/windmill-monorepo/
└── run8n-stack skill            # ~/.claude/skills/run8n-stack/
```

### Proposed Structure

```
GitHub: SerjoschDuering/
│
├── run8n-docker-caddy           # Server configuration (rename considered: run8n-infra)
├── run8n-skill                  # Claude Code skill (TO BE CREATED)
├── run8n-windmill               # Windmill scripts (TO BE PUSHED)
├── run8n-templates              # Project starter templates (TO BE CREATED)
└── [project-repos]              # Individual project repositories
```

### Repository Purposes

#### 1. `run8n-infra` (Server Infrastructure)

**Purpose:** Single source of truth for server configuration

```
run8n-infra/
├── docker-compose.yml           # All core services
├── docker-compose.override.yml  # Local dev overrides (optional)
├── Caddyfile                    # Reverse proxy / routing
│
├── config/                      # Service configurations
│   ├── postgres/
│   │   └── pg_hba.conf
│   ├── redis/
│   │   └── redis.conf
│   ├── qdrant/
│   │   └── config.yaml
│   └── gotrue/
│       └── gotrue.env
│
├── scripts/
│   ├── setup-server.sh          # Bootstrap new server
│   ├── deploy-infra.sh          # Pull & restart services
│   ├── backup.sh                # Database backups
│   ├── restore.sh               # Restore from backup
│   ├── add-app.sh               # Register new app with Caddy
│   └── health-check.sh          # Service health monitoring
│
├── docs/
│   ├── MASTER_PLAN.md           # Vision and roadmap
│   ├── ORGANIZATION_PLAN.md     # This document
│   ├── ONBOARDING.md            # New team member guide
│   └── services/                # Per-service documentation
│       ├── postgres.md
│       ├── windmill.md
│       └── ...
│
└── .env.example                 # Template (never real secrets!)
```

**Deployment:**
```bash
# On server: /opt/run8n/
git pull origin main
docker compose up -d
caddy reload --config Caddyfile
```

---

#### 2. `run8n-skill` (Claude Code Skill)

**Purpose:** Version-controlled AI skill for the stack

```
run8n-skill/
├── run8n-stack.md               # Main skill file
│
├── patterns/                    # Reusable code patterns
│   ├── auth-gotrue.md           # GoTrue authentication
│   ├── database-prisma.md       # Prisma patterns
│   ├── database-nocodb.md       # NocoDB API patterns
│   ├── storage-s3.md            # Backblaze S3 patterns
│   ├── vectors-qdrant.md        # Qdrant patterns
│   ├── realtime-redis.md        # Redis pub/sub patterns
│   └── payments-stripe.md       # Stripe integration
│
├── recipes/                     # Step-by-step workflows
│   ├── new-project.md
│   ├── add-database.md
│   ├── deploy-app.md
│   └── setup-stripe.md
│
├── install.sh                   # Symlink to ~/.claude/skills/
├── update.sh                    # Pull latest + reinstall
│
└── README.md                    # Installation instructions
```

**Installation:**
```bash
git clone git@github.com:run8n/run8n-skill.git ~/run8n-skill
cd ~/run8n-skill
./install.sh
# Restart Claude Code
```

**Update:**
```bash
cd ~/run8n-skill
git pull
# Skill auto-reloads on next Claude Code session
```

---

#### 3. `run8n-windmill` (Windmill Scripts)

**Purpose:** Shared Windmill scripts and infrastructure automations

```
run8n-windmill/
├── wmill.yaml                   # Windmill workspace config
│
├── f/                           # Scripts (functions)
│   ├── infra/                   # Infrastructure management
│   │   ├── create_db_schema.ts
│   │   ├── list_schemas.ts
│   │   ├── backup_database.ts
│   │   └── health_check.ts
│   │
│   ├── auth/                    # GoTrue helpers
│   │   ├── create_user.ts
│   │   ├── verify_jwt.ts
│   │   └── reset_password.ts
│   │
│   ├── storage/                 # S3/Backblaze helpers
│   │   ├── presigned_upload.ts
│   │   ├── presigned_download.ts
│   │   └── list_files.ts
│   │
│   ├── stripe/                  # Payment processing
│   │   ├── create_checkout.ts
│   │   ├── webhook_handler.ts
│   │   └── manage_subscription.ts
│   │
│   └── common/                  # Shared utilities
│       ├── db.ts
│       ├── http.ts
│       └── validation.ts
│
├── flows/                       # Multi-step workflows
│   ├── onboard_user.yaml
│   └── daily_backup.yaml
│
└── resources/                   # Connection configs
    └── types/
```

**Sync:**
```bash
# Push local changes to Windmill
wmill sync push

# Pull remote changes
wmill sync pull
```

---

#### 4. `run8n-templates` (Project Templates)

**Purpose:** Starter templates for different project types

```
run8n-templates/
├── README.md                    # Template overview & selection guide
│
├── static/                      # Static sites
│   ├── CLAUDE.md
│   ├── index.html
│   ├── styles.css
│   └── deploy.sh
│
├── fullstack/                   # Frontend + Windmill + Prisma
│   ├── CLAUDE.md
│   ├── package.json
│   ├── prisma/
│   ├── src/
│   ├── windmill/
│   └── scripts/
│
├── admin/                       # NocoDB-backed admin panels
│   ├── CLAUDE.md
│   ├── package.json
│   ├── src/
│   └── scripts/
│
├── ai/                          # RAG / Vector search apps
│   ├── CLAUDE.md
│   ├── ...
│
├── realtime/                    # Redis + WebSocket apps
│   ├── CLAUDE.md
│   ├── ...
│
├── container/                   # FastAPI + Docker
│   ├── CLAUDE.md
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── backend/
│   ├── frontend/
│   └── .github/workflows/
│
├── saas/                        # Stripe + Auth + Database
│   ├── CLAUDE.md
│   └── ...
│
└── mcp/                         # MCP Server template (based on siyuan-mcp-server)
    ├── CLAUDE.md                # Key docs index
    ├── docs/                    # CONFIGURATION, DEPLOYMENT, USER_GUIDE, etc.
    ├── src/                     # TypeScript source
    ├── Dockerfile
    ├── manifest.json
    └── smithery.yaml
```

**Usage:**
```bash
# Create new project from template
cp -r ~/run8n-templates/fullstack ./my-new-app
cd my-new-app
pnpm install
# Edit .env, start developing
```

---

## Server-Side Structure

### Directory Layout on Server

```
/opt/
├── run8n/                       # Clone of run8n-docker-caddy
│   ├── docker-compose-arm.yml
│   ├── Caddyfile
│   ├── .env                     # PRODUCTION SECRETS (not in git!)
│   └── docs/
│
├── run8n_data/                  # Persistent data volumes
│   ├── n8n/
│   ├── postgres/
│   ├── redis/
│   ├── qdrant/
│   ├── nocodb/
│   ├── windmill/
│   ├── siyuan/
│   ├── static_sites/            # Mounted to /srv in Caddy container
│   └── backups/
│
└── apps/                        # Deployed applications (containerized)
    ├── my-saas/
    │   ├── docker-compose.yml
    │   ├── .env
    │   └── data/
    └── another-app/

/srv/                            # Static sites (Caddy serves from here)
├── landing/                     # sites.run8n.xyz/landing
├── docs/                        # sites.run8n.xyz/docs
└── blog/                        # sites.run8n.xyz/blog
```

**Note:** `/srv` is mapped from `/opt/run8n_data/static_sites/` inside the Caddy container.

### Secrets Management

| Level | Method | Location |
|-------|--------|----------|
| **Solo/Small** | `.env` files | On server, not in git |
| **Team** | Doppler/Infisical | Injected at runtime |
| **Enterprise** | HashiCorp Vault | Centralized secrets |

**Never in git:**
- Database passwords
- API keys (Stripe, OpenAI, etc.)
- JWT secrets
- S3 credentials

---

## Team Access Control

### Roles & Permissions

| Role | Infra | Skill | Templates | Windmill | Projects | Server SSH |
|------|-------|-------|-----------|----------|----------|------------|
| **Owner** | Admin | Admin | Admin | Admin | Admin | Root |
| **Admin** | Write | Write | Write | Admin | Write | Sudo |
| **Developer** | Read | Read | Read | Write | Write | Deploy only |
| **Contractor** | None | Read | Read | Read | Assigned | None |

### Access by Repository

```yaml
# run8n-infra (sensitive)
owners: [cto, devops-lead]
maintainers: [senior-devs]
readers: [all-devs]

# run8n-skill
owners: [tech-lead]
maintainers: [senior-devs]
readers: [all-devs, contractors]

# run8n-templates
owners: [tech-lead]
maintainers: [all-devs]
readers: [contractors]

# run8n-windmill
owners: [tech-lead]
maintainers: [all-devs]
readers: [contractors]

# project repos
owners: [project-lead]
maintainers: [assigned-devs]
```

---

## Skill Management for Teams

### Installation (Each Team Member)

```bash
# 1. Clone skill repo
git clone git@github.com:SerjoschDuering/run8n-skill.git ~/run8n-skill

# 2. Run install script
cd ~/run8n-skill
./install.sh

# Creates symlink:
# ~/.claude/skills/run8n-stack/ -> ~/run8n-skill/

# 3. Restart Claude Code
```

### Current Skill Structure (to be version controlled)

```
~/.claude/skills/run8n-stack/
├── SKILL.md                  # Main skill file
├── patterns.md               # General patterns
├── mcp-servers.md            # MCP server documentation
├── static-sites.md           # Static site deployment
└── services/                 # Per-service docs (11 files)
    ├── auth.md
    ├── data.md
    ├── windmill.md
    └── ...
```

### Updating the Skill

```bash
# When skill is updated by admin:
cd ~/run8n-skill
git pull

# Skill is automatically updated (symlinked)
# Restart Claude Code to reload
```

### Skill Versioning

```bash
# Tag releases
git tag -a v1.0.0 -m "Initial stable skill"
git push --tags

# Team can pin to version if needed
git checkout v1.0.0
```

---

## CI/CD Architecture

### Infrastructure Updates

```yaml
# .github/workflows/deploy-infra.yml (in run8n-infra)
name: Deploy Infrastructure
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_IP }}
          username: root
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/run8n
            git pull
            docker compose pull
            docker compose up -d
            caddy reload --config Caddyfile
```

### Application Deployments

```yaml
# .github/workflows/deploy.yml (in project repos)
name: Deploy App
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build frontend
        run: pnpm build

      - name: Deploy to server
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_IP }}
          username: deploy
          key: ${{ secrets.DEPLOY_KEY }}
          script: |
            cd /opt/apps/${{ github.event.repository.name }}
            git pull
            docker compose up -d --build
```

---

## Onboarding Checklist

### New Team Member Setup

```markdown
## Developer Onboarding

### Day 1: Access
- [ ] GitHub/GitLab account added to run8n org
- [ ] SSH key added to server (deploy user)
- [ ] Windmill account created
- [ ] NocoDB account created

### Day 1: Local Setup
- [ ] Clone run8n-skill → run install.sh
- [ ] Clone run8n-templates
- [ ] Clone assigned project repos
- [ ] Install Windmill CLI (`wmill`)
- [ ] Test connection to dev database

### Day 2: Orientation
- [ ] Read MASTER_PLAN.md
- [ ] Read ORGANIZATION_PLAN.md
- [ ] Walk through existing project
- [ ] Make a test deployment

### First Week
- [ ] Complete first feature/fix
- [ ] Push to Windmill (if applicable)
- [ ] Deploy to staging
```

---

## Migration Plan (Current → Proposed)

### Current State Assessment
- [ ] Audit existing repos
- [ ] Document current server setup
- [ ] Identify what's in git vs. only on server
- [ ] List all active projects

### Phase 1: Consolidate Infrastructure
- [ ] Create `run8n-infra` repo
- [ ] Move docker-compose, Caddyfile to repo
- [ ] Version all config files
- [ ] Test deploy from repo

### Phase 2: Skill Repository
- [ ] Create `run8n-skill` repo
- [ ] Move/create skill markdown
- [ ] Write install script
- [ ] Test with team member

### Phase 3: Templates
- [ ] Create `run8n-templates` repo
- [ ] Build first template (fullstack)
- [ ] Test: create project → deploy

### Phase 4: Documentation
- [ ] Complete MASTER_PLAN.md
- [ ] Complete ORGANIZATION_PLAN.md
- [ ] Write ONBOARDING.md
- [ ] Per-service documentation

---

## Open Questions

1. **Git hosting:** GitHub, GitLab, or self-hosted Gitea?
2. **Secrets management:** Start with `.env` or immediately use Doppler?
3. **CI/CD:** GitHub Actions, or Windmill for deployments?
4. **Template distribution:** Git clone or `degit` / `npx create-*`?
5. **Skill updates:** Manual pull or automated sync?

---

*Last updated: 2025-01-09*
