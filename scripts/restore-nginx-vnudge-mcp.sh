#!/usr/bin/env bash
set -euo pipefail

REF_CONF="/var/www/velocis/config/nginx/vnudge.com.reference.conf"
DEST_CONF="/etc/nginx/sites-enabled/vnudge.com"

echo "[1/5] Preconditions"
if [ ! -f "$REF_CONF" ]; then
  echo "Missing reference config: $REF_CONF" >&2
  exit 1
fi

echo "[2/5] Backup current nginx config (if exists)"
if [ -f "$DEST_CONF" ]; then
  cp -a "$DEST_CONF" "$DEST_CONF.bak.$(date +%Y%m%d%H%M%S)"
fi

echo "[3/5] Restore reference config"
cp -a "$REF_CONF" "$DEST_CONF"

echo "[4/5] Validate and reload nginx"
nginx -t
systemctl reload nginx

echo "[5/5] Quick checks"
curl -I https://vnudge.com/AWS/mcp/ | head -n 10 || true
curl -I https://vnudge.com/AWS/mcp/AWS.png | head -n 10 || true
curl -I https://vnudge.com/AWS/mcp/AI | head -n 10 || true
curl -I https://vnudge.com/AWS/mcp/AI/ | head -n 10 || true
echo "Done."

