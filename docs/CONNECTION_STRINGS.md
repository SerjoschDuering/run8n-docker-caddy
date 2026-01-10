# run8n Stack Connection Strings

Quick reference for connecting to all run8n services.

## run8n_db (PostgreSQL + PostGIS)

The primary database for all apps. Now includes PostGIS for geospatial queries.

### Internal (from Docker services like Windmill, n8n)

```
postgres://supabase_admin:${SUPABASE_POSTGRES_PASSWORD}@run8n_db:5432/postgres
```

### External (CI/CD, local dev, DBeaver, TablePlus)

```
postgres://supabase_admin:${SUPABASE_POSTGRES_PASSWORD}@91.98.144.66:5432/postgres
```

### With specific schema

```bash
# GoTrue auth schema (used internally by GoTrue)
postgres://supabase_admin:PASSWORD@run8n_db:5432/postgres?search_path=auth

# Your app schema (create with: CREATE SCHEMA myapp;)
postgres://supabase_admin:PASSWORD@run8n_db:5432/postgres?search_path=myapp
```

### Prisma connection (for migrations)

```env
# In your app's .env file
DATABASE_URL="postgresql://supabase_admin:PASSWORD@91.98.144.66:5432/postgres?schema=myapp"
```

### PostGIS spatial queries

```sql
-- Enable PostGIS (run once per database)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Check PostGIS version
SELECT PostGIS_Full_Version();

-- Example: Find points within 1km of a location
SELECT * FROM locations
WHERE ST_DWithin(
  geom,
  ST_SetSRID(ST_MakePoint(24.7136, 46.6753), 4326)::geography,
  1000  -- meters
);
```

---

## Soketi WebSocket (Real-Time)

Pusher-compatible WebSocket server for real-time features.

### Public endpoint

```
wss://realtime.run8n.xyz
```

### JavaScript client (pusher-js)

```javascript
import Pusher from 'pusher-js';

const pusher = new Pusher(process.env.SOKETI_APP_KEY, {
  wsHost: 'realtime.run8n.xyz',
  wsPort: 443,
  wssPort: 443,
  forceTLS: true,
  encrypted: true,
  disableStats: true,
  enabledTransports: ['ws', 'wss'],
  cluster: '' // Leave empty for self-hosted
});

// Subscribe to a channel
const channel = pusher.subscribe('my-channel');
channel.bind('my-event', (data) => {
  console.log('Received:', data);
});

// Presence channel for user tracking
const presence = pusher.subscribe('presence-room-123');
presence.bind('pusher:subscription_succeeded', (members) => {
  console.log('Users online:', members.count);
});
```

### Server-side trigger (Node.js)

```javascript
const Pusher = require('pusher');

const pusher = new Pusher({
  appId: 'run8n-app',
  key: process.env.SOKETI_APP_KEY,
  secret: process.env.SOKETI_APP_SECRET,
  host: 'realtime.run8n.xyz',
  port: 443,
  useTLS: true
});

// Trigger an event
await pusher.trigger('my-channel', 'my-event', {
  message: 'Hello from server!'
});
```

### Windmill script (Python)

```python
import pusher

def main():
    client = pusher.Pusher(
        app_id='run8n-app',
        key=wmill.get_variable('f/soketi/app_key'),
        secret=wmill.get_variable('f/soketi/app_secret'),
        host='realtime.run8n.xyz',
        port=443,
        ssl=True
    )

    client.trigger('notifications', 'new_message', {
        'text': 'Hello from Windmill!'
    })
```

---

## Qdrant Vector Database

### Public API (with basic auth)

```
https://admin:PASSWORD@qdrant.run8n.xyz
```

Or with curl:

```bash
curl -u admin:PASSWORD https://qdrant.run8n.xyz/collections
```

### Internal (from Docker services - no auth needed)

```
http://qdrant:6333
```

### Python client

```python
from qdrant_client import QdrantClient

# External access
client = QdrantClient(
    url="https://qdrant.run8n.xyz",
    api_key=None  # Using basic auth via URL
)

# Or with requests + basic auth
import requests
from requests.auth import HTTPBasicAuth

response = requests.get(
    "https://qdrant.run8n.xyz/collections",
    auth=HTTPBasicAuth('admin', 'YOUR_PASSWORD')
)
```

### Internal access (from Windmill/n8n)

```python
from qdrant_client import QdrantClient

# No auth needed for internal network
client = QdrantClient(host="qdrant", port=6333)

# Create a collection
client.create_collection(
    collection_name="embeddings",
    vectors_config={"size": 384, "distance": "Cosine"}
)
```

---

## Other Services

### windmill_db (Internal only - Windmill's state)

```
postgresql://postgres:${WINDMILL_DB_PASSWORD}@windmill_db:5432/windmill
```

**Note:** Do NOT use this for your apps. Use `run8n_db` instead.

### Redis (Internal only)

```
redis://:${REDIS_PASSWORD}@redis:6379
```

Used by: NocoDB, Soketi, n8n (caching)

### GoTrue Auth API

```
https://auth.run8n.xyz
```

See `/Users/Joo/01_Projects/n8n_dep/run8n-docker-caddy/docs/gotrue.md` for full API reference.

---

## Quick Reference Table

| Service | Internal URL | External URL | Auth |
|---------|--------------|--------------|------|
| run8n_db | `run8n_db:5432` | `91.98.144.66:5432` | Password |
| Soketi | `soketi:6001` | `wss://realtime.run8n.xyz` | App Key |
| Qdrant | `qdrant:6333` | `https://qdrant.run8n.xyz` | Basic Auth |
| Redis | `redis:6379` | N/A | Password |
| GoTrue | `gotrue:9999` | `https://auth.run8n.xyz` | JWT |
| Windmill | `windmill_server:8000` | `https://windmill.run8n.xyz` | Session |
| NocoDB | `nocodb:8080` | `https://nocodb.run8n.xyz` | Basic Auth |

---

## Environment Variables Reference

Add these to your `.env` file:

```bash
# Database
SUPABASE_POSTGRES_PASSWORD=your_db_password

# Soketi WebSocket
SOKETI_APP_KEY=your_app_key
SOKETI_APP_SECRET=your_app_secret

# Qdrant
QDRANT_PASSWORD=your_qdrant_password

# Redis
REDIS_PASSWORD=your_redis_password
```

---

*Last updated: 2025-01-10*
