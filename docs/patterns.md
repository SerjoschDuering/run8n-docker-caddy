# Integration Patterns

Common patterns for connecting services in your stack.

## Authentication Patterns

### Pattern 1: GoTrue + Static Site
```
┌─────────────┐      ┌─────────────┐
│ Static Site │ ───► │   GoTrue    │
│ (JS Client) │ ◄─── │ auth.run8n  │
└─────────────┘ JWT  └─────────────┘
```

**Client Code:**
```javascript
import { GoTrueClient } from '@supabase/gotrue-js'

const auth = new GoTrueClient({ url: 'https://auth.run8n.xyz' })

// Login
const { data } = await auth.signInWithOAuth({ provider: 'google' })

// Get token for API calls
const token = (await auth.getSession()).data.session?.access_token
```

### Pattern 2: GoTrue + n8n Webhook
```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Client    │ ───► │  n8n Hook   │ ───► │   GoTrue    │
│  (Bearer)   │      │ Verify JWT  │      │  (verify)   │
└─────────────┘      └─────────────┘      └─────────────┘
```

**n8n Code Node - Verify JWT:**
```javascript
const jwt = require('jsonwebtoken');
const JWT_SECRET = $env.SUPABASE_JWT_SECRET;

const authHeader = $input.first().headers.authorization;
const token = authHeader?.replace('Bearer ', '');

try {
  const decoded = jwt.verify(token, JWT_SECRET);
  return { user: decoded, authenticated: true };
} catch (err) {
  throw new Error('Unauthorized');
}
```

### Pattern 3: GoTrue + Windmill Script
```python
import jwt
import os

def verify_user(token: str) -> dict:
    """Verify GoTrue JWT token"""
    secret = os.environ["SUPABASE_JWT_SECRET"]
    try:
        payload = jwt.decode(token, secret, algorithms=["HS256"])
        return {"valid": True, "user_id": payload["sub"], "email": payload["email"]}
    except jwt.InvalidTokenError as e:
        return {"valid": False, "error": str(e)}
```

---

## Data Storage Patterns

### Pattern 4: n8n → NocoDB (Structured Data)
```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  n8n Flow   │ ───► │  NocoDB API │ ───► │  SQLite/PG  │
│  (webhook)  │      │  REST API   │      │  Database   │
└─────────────┘      └─────────────┘      └─────────────┘
```

**NocoDB API Call (n8n HTTP Request):**
```
POST https://nocodb.run8n.xyz/api/v2/tables/{table_id}/records
Headers:
  xc-token: YOUR_NOCODB_API_TOKEN
Body:
  {
    "Name": "{{$json.name}}",
    "Email": "{{$json.email}}",
    "Created": "{{$now}}"
  }
```

### Pattern 5: n8n → Qdrant (Vector Data)
```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  n8n Flow   │ ───► │   OpenAI    │ ───► │   Qdrant    │
│  (text)     │      │  Embedding  │      │  (vectors)  │
└─────────────┘      └─────────────┘      └─────────────┘
```

**n8n Code - Store in Qdrant:**
```javascript
const QDRANT_URL = 'http://qdrant:6333';
const COLLECTION = 'documents';

// After getting embedding from OpenAI
const embedding = $input.first().json.embedding;
const text = $input.first().json.text;
const id = $input.first().json.id;

// Upsert to Qdrant
const response = await fetch(`${QDRANT_URL}/collections/${COLLECTION}/points`, {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    points: [{
      id: id,
      vector: embedding,
      payload: { text, timestamp: Date.now() }
    }]
  })
});

return { success: response.ok };
```

### Pattern 6: Semantic Search (Qdrant)
```javascript
const QDRANT_URL = 'http://qdrant:6333';
const COLLECTION = 'documents';

// Query embedding from OpenAI
const queryVector = $input.first().json.embedding;

const response = await fetch(`${QDRANT_URL}/collections/${COLLECTION}/points/search`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    vector: queryVector,
    limit: 5,
    with_payload: true
  })
});

const results = await response.json();
return results.result;
```

---

## File Storage Patterns

### Pattern 7: n8n → Backblaze B2
```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  n8n Flow   │ ───► │  S3 Node    │ ───► │ Backblaze   │
│  (file)     │      │  (upload)   │      │  B2 Bucket  │
└─────────────┘      └─────────────┘      └─────────────┘
```

**n8n S3 Credentials:**
```
Region: us-west-004
Endpoint: https://s3.us-west-004.backblazeb2.com
Access Key: keyID from Backblaze
Secret Key: applicationKey from Backblaze
```

---

## Webhook Patterns

### Pattern 8: External → n8n → Process → Store
```
External     n8n Webhook    Process      Store
Service  →   /webhook/xxx → Transform → NocoDB/Qdrant
             ↓
          Validate JWT
          (if authenticated)
```

**Webhook URL format:**
```
https://run8n.xyz/webhook/{workflow-id}
https://run8n.xyz/webhook-test/{workflow-id}  # For testing
```

### Pattern 9: Scheduled Jobs (Windmill)
```python
# Windmill scheduled script
# Cron: 0 * * * * (every hour)

import requests

def main():
    # Fetch data
    response = requests.get("https://api.example.com/data")
    data = response.json()

    # Store in NocoDB
    requests.post(
        "https://nocodb.run8n.xyz/api/v2/tables/xxx/records",
        headers={"xc-token": os.environ["NOCODB_TOKEN"]},
        json=data
    )

    return {"processed": len(data)}
```

---

## Service Connection Reference

### Internal Network (Docker)
```
Service         Host              Port
─────────────────────────────────────────
n8n             n8n               5678
Windmill        windmill_server   8000
GoTrue          gotrue            9999
NocoDB          nocodb            8080
Qdrant          qdrant            6333 (HTTP), 6334 (gRPC)
PostgreSQL      supabase_db       5432
PostgreSQL      windmill_db       5432
Redis           redis             6379
SiYuan          siyuan            6806
```

### External URLs
```
Service         URL
─────────────────────────────────────────
n8n             https://run8n.xyz
Windmill        https://windmill.run8n.xyz
GoTrue          https://auth.run8n.xyz
NocoDB          https://nocodb.run8n.xyz
SiYuan          https://siyuan.run8n.xyz
Dashboard       https://dashboard.run8n.xyz
MCP Gateway     https://mcp.run8n.xyz
```
