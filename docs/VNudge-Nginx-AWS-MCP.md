## Overview

This is the reference runbook for Nginx routing on `vnudge.com` for:

- **Static MCP architecture page**: `https://vnudge.com/AWS/mcp/`
- **Chatbot UI (Chainlit)**: `https://vnudge.com/AWS/mcp/AI` (and `.../AI/`)

Reference config is stored at:

- `config/nginx/vnudge.com.reference.conf` (clean “known-good”)
- `config/nginx/vnudge.com.live.conf` (snapshot of the live file at time of capture)

## Filesystem layout (static)

Nginx serves `/AWS/mcp/*` from:

- **Webroot**: `/var/www/vnudge.com`
- **Expected assets directory**: `/var/www/vnudge.com/AWS/mcp/`
  - `index.html`
  - `AWS.png`, `s3.png`, `ecr.png`, `cognito.svg`, `cloudwatch.svg`, `bedrock-agentcore.svg`, etc.

Because the diagram uses relative image URLs like `href="AWS.png"`, the images must be in the same directory as `index.html`.

## Upstreams (dynamic)

- **Chainlit chatbot**: `127.0.0.1:8001`
  - Must be running for `/AWS/mcp/AI` to work.
- **Main site/app**: `127.0.0.1:8000`
  - Handles everything else via `location /`.

## Why earlier issues happened

- **Images not loading**: the page referenced `AWS.png`, `cognito.svg`, etc. under `/AWS/mcp/`, but Nginx was proxying `/AWS/mcp/<file>` to the app on `:8000` instead of serving static files.
- **`{"detail":"Not Found"}` for chatbot**: Nginx forwarded requests to `:8000` or stripped the expected path due to `proxy_pass` path behavior.
- **Redirect loop**: one side redirected `/AI` → `/AI/` and the other redirected `/AI/` → `/AI`.
  - Fix: proxy both `/AWS/mcp/AI` and `/AWS/mcp/AI/` without redirects.

## Restore script

To restore the reference config onto the server:

- `scripts/restore-nginx-vnudge-mcp.sh`

It will:

- back up the current `/etc/nginx/sites-enabled/vnudge.com`
- install the stored reference config
- run `nginx -t`
- reload Nginx

## Quick verification commands

Run on the server:

```bash
curl -I https://vnudge.com/AWS/mcp/
curl -I https://vnudge.com/AWS/mcp/AWS.png
curl -I https://vnudge.com/AWS/mcp/AI
curl -I https://vnudge.com/AWS/mcp/AI/

ss -ltnp | grep :8001 || true
```

