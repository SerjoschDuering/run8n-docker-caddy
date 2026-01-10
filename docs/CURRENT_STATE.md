# Run8n Stack - Current State

> Accurate snapshot of what exists today (2025-01-09)

## GitHub Organization

**GitHub Username:** `SerjoschDuering`

### Related Repositories on GitHub

| Repo | URL | Purpose | Status |
|------|-----|---------|--------|
| `run8n-docker-caddy` | github.com/SerjoschDuering/run8n-docker-caddy | Server infrastructure | ✅ Active |
| `siyuan-mcp-server` | github.com/SerjoschDuering/siyuan-mcp-server | MCP server (template example) | ✅ v2.0.0 |
| `rhino-mcp` | github.com/SerjoschDuering/rhino-mcp | Rhino MCP server | ✅ Active |
| `ClaudeCodeSlashPrompts` | github.com/SerjoschDuering/ClaudeCodeSlashPrompts | Slash command templates | ✅ Active |
| `mcp-miro` | github.com/SerjoschDuering/mcp-miro | Miro MCP integration | ✅ Active |

### Local Only (Not on GitHub)

| Folder | Path | Purpose | Notes |
|--------|------|---------|-------|
| `windmill-monorepo` | `/Users/Joo/01_Projects/windmill-monorepo/` | Windmill scripts | No git remote, nearly empty |
| `claude-code-skills` | `/Users/Joo/01_Projects/claude-code-skills/` | Skills development | Local only |
| `blender-mcp` | `/Users/Joo/01_Projects/blender-mcp/` | Blender MCP server | Local repo |

---

## Server Infrastructure

### Server Details

| Property | Value |
|----------|-------|
| **Provider** | Hetzner |
| **IP** | `91.98.144.66` |
| **Architecture** | ARM64 |
| **Specs** | 16 vCPU, 32GB RAM |
| **SSH Command** | `ssh -i ~/.ssh/id_ed25519_hetzner_2025 root@91.98.144.66` |

### Infrastructure Repository

**Location:** `/Users/Joo/01_Projects/n8n_dep/run8n-docker-caddy/`
**GitHub:** `https://github.com/SerjoschDuering/run8n-docker-caddy`
**Upstream:** `https://github.com/n8n-io/n8n-docker-caddy`

```
run8n-docker-caddy/
├── docker-compose-arm.yml      # Main compose file (597 lines)
├── Caddyfile                   # Reverse proxy config
├── .env.example                # Environment template
├── setup-arm.sh                # Server setup script
└── docs/
    ├── README.md               # Service documentation index
    ├── MASTER_PLAN.md          # Vision & roadmap (new)
    ├── ORGANIZATION_PLAN.md    # Org structure (new)
    ├── CURRENT_STATE.md        # This file
    ├── n8n.md
    ├── windmill.md
    ├── gotrue.md
    ├── nocodb.md
    ├── qdrant.md
    ├── postgres.md
    ├── redis.md
    ├── backblaze.md
    ├── patterns.md
    ├── api-reference.md
    ├── deployment.md
    └── troubleshooting.md
```

### Services Running

| Service | Internal Address | External URL | Status |
|---------|------------------|--------------|--------|
| **n8n** | `n8n:5678` | `run8n.xyz` | ✅ Running |
| **Windmill** | `windmill:8000` | `windmill.run8n.xyz` | ✅ Running |
| **GoTrue** | `gotrue:9999` | `auth.run8n.xyz` | ✅ Running |
| **NocoDB** | `nocodb:8080` | `nocodb.run8n.xyz` | ✅ Running |
| **PostgreSQL** | `postgres:5432` | ❌ Not exposed | ✅ Running |
| **Redis** | `redis:6379` | ❌ Not exposed | ✅ Running |
| **Qdrant** | `qdrant:6333` | ❌ Not exposed | ✅ Running |
| **SiYuan** | `siyuan:6806` | `siyuan.run8n.xyz` | ✅ Running |
| **Homarr** | `homarr:7575` | `dashboard.run8n.xyz` | ✅ Running |
| **Netdata** | `netdata:19999` | Via dashboard | ✅ Running |
| **Dozzle** | `dozzle:8080` | Via dashboard | ✅ Running |

### Server Directory Structure

```
/opt/run8n_data/              # Persistent data
├── n8n/
├── postgres/
├── redis/
├── qdrant/
├── nocodb/
├── siyuan/
├── windmill/
├── static_sites/             # Served at sites.run8n.xyz
└── backups/

/srv/                         # Static sites (Caddy serves from here)
```

---

## Claude Code Skill

### Location

```
~/.claude/skills/run8n-stack/
├── SKILL.md                  # Main skill file (2946 bytes)
├── patterns.md               # General patterns (986 bytes)
├── mcp-servers.md            # MCP server docs (2182 bytes)
├── static-sites.md           # Static site deployment (618 bytes)
└── services/                 # Per-service documentation
    ├── auth.md               # GoTrue (3024 bytes)
    ├── data.md               # Database patterns (1100 bytes)
    ├── monitoring.md         # Netdata, Dozzle (1192 bytes)
    ├── n8n.md                # n8n workflows (660 bytes)
    ├── storage.md            # Backblaze S3 (1279 bytes)
    ├── vectors.md            # Qdrant (1079 bytes)
    ├── windmill.md           # Windmill overview (4036 bytes)
    ├── windmill-apps.md      # Windmill apps (3610 bytes)
    ├── windmill-flows.md     # Windmill flows (7838 bytes)
    ├── windmill-scripts.md   # Windmill scripts (5367 bytes)
    └── windmill-triggers.md  # Windmill triggers (5208 bytes)
```

### Skill Status

| Aspect | Status | Notes |
|--------|--------|-------|
| **Version controlled** | ❌ No | Just files, no git repo |
| **On GitHub** | ❌ No | Local only |
| **Install script** | ❌ No | Manual copy |
| **Service docs** | ✅ Yes | 11 files covering most services |
| **Windmill CLI** | ✅ Good | `wmill sync push/pull`, file structure |
| **Windmill Scripts** | ✅ Excellent | Python/TS templates, resources, patterns |
| **GoTrue Auth** | ✅ Good | JS client, JWT verification |
| **Stack Integrations** | ✅ Good | NocoDB, Redis, Postgres, Backblaze in Windmill |
| **Integration Patterns** | ✅ Good | Auth+API, RAG, pipelines |
| **Static Sites** | ✅ Good | Correct paths |
| **NocoDB Table Creation** | ⚠️ Brief | API mentioned, needs full examples |
| **Prisma patterns** | ❌ No | Not documented (decision needed) |
| **Stripe patterns** | ❌ No | Not documented |

---

## Windmill Monorepo

### Location

```
/Users/Joo/01_Projects/windmill-monorepo/
├── CLAUDE.md                 # Project instructions (2978 bytes)
├── wmill.yaml                # Workspace config (826 bytes)
├── wmill-lock.yaml           # Lock file (106 bytes)
├── reference_docs/           # Windmill documentation
└── f/                        # Scripts folder
    ├── _shared/              # Empty
    ├── app_custom/           # Empty
    ├── app_groups/           # Empty
    ├── app_themes/           # Empty
    └── test/                 # Only has test scripts
```

### Windmill Status

| Aspect | Status | Notes |
|--------|--------|-------|
| **On GitHub** | ❌ No | No git remote configured |
| **Infrastructure scripts** | ❌ No | None exist |
| **Auth scripts** | ❌ No | None exist |
| **Stripe scripts** | ❌ No | None exist |
| **Storage scripts** | ❌ No | None exist |
| **Production scripts** | ❌ No | Only test/hello_world |

---

## Templates

### Current Status

**No project templates exist yet.**

| Template | Status | Notes |
|----------|--------|-------|
| `run8n-static` | ❌ Does not exist | |
| `run8n-fullstack` | ❌ Does not exist | |
| `run8n-admin` | ❌ Does not exist | |
| `run8n-ai` | ❌ Does not exist | |
| `run8n-realtime` | ❌ Does not exist | |
| `run8n-container` | ❌ Does not exist | |
| `run8n-saas` | ❌ Does not exist | |
| `run8n-mcp` | ❌ Does not exist | Could be based on siyuan-mcp-server |

### Potential Template Source

The `siyuan-mcp-server` project has excellent structure that could serve as a template:

```
siyuan-mcp-server/
├── CLAUDE.md                 # Well-structured AI instructions
├── docs/
│   ├── CONFIGURATION.md      # Setup reference
│   ├── USER_GUIDE.md         # Usage workflows
│   ├── DEPLOYMENT.md         # Docker, Caddy, PM2, monitoring
│   ├── DEVELOPER_GUIDE.md    # Architecture, contributing
│   └── TOOL_REFERENCE.md     # API reference
├── Dockerfile                # Container config
├── smithery.yaml             # MCP packaging
├── manifest.json             # MCP manifest
└── src-v2/                   # TypeScript source
```

---

## CI/CD & Automation

### Current Status

| Aspect | Status | Notes |
|--------|--------|-------|
| **GitHub Actions** | ❌ None | No workflows configured |
| **Auto-deploy** | ❌ No | Manual SSH + docker compose |
| **Backups** | ❌ No | No automated backups |
| **Monitoring alerts** | ❌ No | Netdata runs but no alerts |
| **Health checks** | ⚠️ Partial | Docker healthchecks only |

---

## What Works Today

### ✅ Fully Working & Documented

1. **Static site deployment** - rsync to `/opt/run8n_data/static_sites/`, Caddy serves at `sites.run8n.xyz`
2. **n8n workflows** - Full functionality at `run8n.xyz`
3. **Windmill scripts** - CLI documented (`wmill sync push/pull`), excellent script patterns
4. **Windmill + Stack** - Documented integrations: NocoDB, Redis, PostgreSQL, Backblaze in Windmill scripts
5. **NocoDB** - Database UI at `nocodb.run8n.xyz`, REST API for CRUD documented
6. **GoTrue auth** - JS client, JWT verification patterns documented
7. **SiYuan notes** - At `siyuan.run8n.xyz`
8. **Monitoring** - Netdata, Dozzle via `dashboard.run8n.xyz`
9. **Integration patterns** - Auth+API, RAG, data pipelines documented

### ⚠️ Works But Not Exposed for Local Dev

1. **PostgreSQL** - Running, accessible from Windmill, not exposed externally
2. **Redis** - Running, accessible from Windmill, not exposed externally
3. **Qdrant** - Running, accessible from Windmill, not exposed externally

### ⚠️ Works But Needs More Documentation

1. **NocoDB programmatic table creation** - API exists, needs full examples
2. **Backblaze S3** - Pattern exists in Windmill docs, could use more examples

### ❌ Missing

1. **Project templates** - None exist
2. **Database migrations** - No Prisma setup (decision needed: Prisma vs NocoDB-first)
3. **Stripe integration** - Not implemented
4. **Windmill infra scripts** - Schema creation, backups, etc. not created
5. **CI/CD pipelines** - Not configured
6. **Automated backups** - Not set up
7. **Skill version control** - Not in git

---

## Immediate TODOs (Based on Reality)

### Phase 0: Fix Foundations (Today)

- [ ] Put skill in git: `cd ~/.claude/skills/run8n-stack && git init`
- [ ] Push skill to GitHub as `run8n-skill`
- [ ] Add git remote to windmill-monorepo
- [ ] Fix path references in docs (consistent `/srv` vs `/var/www`)

### Phase 1: Enable Database Access (This Week)

- [ ] Expose PostgreSQL with password auth (add to Caddyfile or firewall)
- [ ] Expose Qdrant via Caddy with basic auth
- [ ] Document NocoDB API token & usage
- [ ] Test connections from local machine

### Phase 2: First Template (This Week)

- [ ] Create `run8n-static` template (simplest)
- [ ] Create `run8n-mcp` template (based on siyuan-mcp-server)
- [ ] Create `run8n-fullstack` template

### Phase 3: Windmill Scripts (Next Week)

- [ ] `f/infra/create_db_schema.ts`
- [ ] `f/auth/verify_jwt.ts`
- [ ] `f/storage/presigned_url.ts`

---

## Reference Commands

### SSH to Server
```bash
ssh -i ~/.ssh/id_ed25519_hetzner_2025 root@91.98.144.66
```

### Deploy Static Site
```bash
rsync -avz --delete ./dist/ root@91.98.144.66:/srv/mysite/
```

### Windmill CLI
```bash
cd /Users/Joo/01_Projects/windmill-monorepo
wmill sync push  # Push to server
wmill sync pull  # Pull from server
```

### View Logs
```bash
ssh root@91.98.144.66 'docker logs -f n8n'
ssh root@91.98.144.66 'docker logs -f windmill'
```

---

*Last updated: 2025-01-09*
