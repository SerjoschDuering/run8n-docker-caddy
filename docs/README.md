# Run8n Stack Documentation

Knowledge base for rapid development on your self-hosted stack.

## Your Stack

| Service | Purpose | Endpoint | Docs |
|---------|---------|----------|------|
| **n8n** | Workflow automation | `run8n.xyz` | [n8n.md](./n8n.md) |
| **Windmill** | Scripts & workflows | `windmill.run8n.xyz` | [windmill.md](./windmill.md) |
| **GoTrue** | Authentication | `auth.run8n.xyz` | [gotrue.md](./gotrue.md) |
| **NocoDB** | Database UI | `nocodb.run8n.xyz` | [nocodb.md](./nocodb.md) |
| **Qdrant** | Vector search | Internal `:6333` | [qdrant.md](./qdrant.md) |
| **PostgreSQL** | Databases | Internal `:5432-5434` | [postgres.md](./postgres.md) |
| **Redis** | Caching | Internal `:6379` | [redis.md](./redis.md) |
| **Backblaze B2** | S3 storage | External | [backblaze.md](./backblaze.md) |

## Quick Patterns

### Authentication Flow
```
User → GoTrue (auth.run8n.xyz) → JWT Token → Your App Backend → Verify JWT
```

### Data Pipeline
```
n8n Webhook → Process Data → Store in NocoDB/Postgres → Index in Qdrant
```

### AI Workflow
```
Input → n8n/Windmill → Embed with OpenAI → Store in Qdrant → Query later
```

## Documentation Index

- [Integration Patterns](./patterns.md) - How services connect
- [API Quick Reference](./api-reference.md) - Endpoints & auth
- [Deployment Guide](./deployment.md) - Adding new services
- [Troubleshooting](./troubleshooting.md) - Common issues

## Using the Claude Skill

Load the `run8n-stack` skill for instant access to this knowledge:

```
/run8n-stack
```

Then ask questions like:
- "How do I authenticate users with GoTrue?"
- "Store vectors in Qdrant from n8n"
- "Create a NocoDB table via API"
