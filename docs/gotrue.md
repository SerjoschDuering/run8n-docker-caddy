# GoTrue Authentication Service

Standalone authentication service for your custom apps. Endpoint: `https://auth.run8n.xyz`

## Quick Start

### 1. Deploy

```bash
# On your server, add OAuth credentials to .env, then:
docker-compose -f docker-compose-arm.yml up -d supabase_db gotrue
```

### 2. Test Health

```bash
curl https://auth.run8n.xyz/health
# Expected: {"version":"v2.168.0","name":"GoTrue","description":"..."}
```

## Using in Your Apps

### JavaScript/TypeScript

```bash
npm install @supabase/gotrue-js
```

```javascript
import { GoTrueClient } from '@supabase/gotrue-js'

const auth = new GoTrueClient({
  url: 'https://auth.run8n.xyz',
  autoRefreshToken: true,
  persistSession: true,
})

// Email/Password Sign Up
const { data, error } = await auth.signUp({
  email: 'user@example.com',
  password: 'securepassword123'
})

// Email/Password Sign In
const { data, error } = await auth.signInWithPassword({
  email: 'user@example.com',
  password: 'securepassword123'
})

// Google OAuth (redirects to Google)
await auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: 'https://yourapp.com/callback'
  }
})

// Get Current User
const { data: { user } } = await auth.getUser()

// Sign Out
await auth.signOut()
```

### Using Full Supabase Client

```bash
npm install @supabase/supabase-js
```

```javascript
import { createClient } from '@supabase/supabase-js'

// Use only for auth (no database connection needed)
const supabase = createClient(
  'https://auth.run8n.xyz',  // Auth URL
  'your-anon-key',           // From SUPABASE_ANON_KEY in .env
  {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
    }
  }
)

// Now use supabase.auth.* methods
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google'
})
```

### Python

```bash
pip install gotrue
```

```python
from gotrue import SyncGoTrueClient

client = SyncGoTrueClient(url="https://auth.run8n.xyz")

# Sign up
response = client.sign_up(email="user@example.com", password="password123")

# Sign in
response = client.sign_in_with_password(email="user@example.com", password="password123")
```

### Direct API Calls

```bash
# Sign Up
curl -X POST https://auth.run8n.xyz/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Sign In
curl -X POST https://auth.run8n.xyz/token?grant_type=password \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Get User (with access token)
curl https://auth.run8n.xyz/user \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Setting Up Google OAuth

### 1. Google Cloud Console

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project or select existing
3. Go to **APIs & Services → Credentials**
4. Click **Create Credentials → OAuth client ID**
5. Select **Web application**
6. Add authorized redirect URI: `https://auth.run8n.xyz/callback`
7. Copy **Client ID** and **Client Secret**

### 2. Update .env

```bash
GOOGLE_OAUTH_ENABLED=true
GOOGLE_CLIENT_ID=123456789-abc.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxx
```

### 3. Restart GoTrue

```bash
docker-compose -f docker-compose-arm.yml restart gotrue
```

### 4. Use in Your App

```javascript
// User clicks "Sign in with Google"
await auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: 'https://yourapp.com/dashboard'
  }
})
```

## Setting Up GitHub OAuth

### 1. GitHub Developer Settings

1. Go to [github.com/settings/developers](https://github.com/settings/developers)
2. Click **New OAuth App**
3. Set **Authorization callback URL**: `https://auth.run8n.xyz/callback`
4. Copy **Client ID** and generate **Client Secret**

### 2. Update .env

```bash
GITHUB_OAUTH_ENABLED=true
GITHUB_CLIENT_ID=your-client-id
GITHUB_CLIENT_SECRET=your-client-secret
```

## JWT Token Usage

GoTrue returns JWT tokens that you can verify in your backend:

```javascript
// Access token structure
{
  "aud": "authenticated",
  "exp": 1234567890,
  "sub": "user-uuid-here",
  "email": "user@example.com",
  "role": "authenticated",
  "user_metadata": {
    "full_name": "John Doe",
    "avatar_url": "https://..."
  }
}
```

### Verify JWT in Your Backend (Node.js)

```javascript
import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.SUPABASE_JWT_SECRET

function verifyToken(token) {
  try {
    const decoded = jwt.verify(token, JWT_SECRET)
    return { valid: true, user: decoded }
  } catch (err) {
    return { valid: false, error: err.message }
  }
}

// In your API route
app.get('/api/protected', (req, res) => {
  const token = req.headers.authorization?.split(' ')[1]
  const { valid, user } = verifyToken(token)

  if (!valid) {
    return res.status(401).json({ error: 'Unauthorized' })
  }

  res.json({ message: 'Hello', user })
})
```

## Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/signup` | POST | Register new user |
| `/token?grant_type=password` | POST | Sign in with email/password |
| `/token?grant_type=refresh_token` | POST | Refresh access token |
| `/user` | GET | Get current user (requires auth) |
| `/user` | PUT | Update user data (requires auth) |
| `/logout` | POST | Sign out |
| `/authorize?provider=google` | GET | Start OAuth flow |
| `/callback` | GET | OAuth callback |
| `/recover` | POST | Password recovery email |

## Troubleshooting

### Check logs
```bash
docker logs gotrue -f
```

### Common issues

**"Database connection failed"**
- Ensure supabase_db is healthy: `docker-compose ps`
- Check password in DATABASE_URL matches SUPABASE_POSTGRES_PASSWORD

**"OAuth callback error"**
- Verify redirect URI in OAuth provider matches exactly: `https://auth.run8n.xyz/callback`
- Check client ID and secret are correct

**"CORS error in browser"**
- Caddy config includes CORS headers
- Reload Caddy: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`

## Resource Usage

- **RAM**: ~100-150MB typical
- **CPU**: Minimal (< 0.1 core idle)
- **Disk**: Negligible (data in PostgreSQL)
