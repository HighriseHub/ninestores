#!/usr/bin/env bash
#
# 06-install-nginx.sh — the edge: static tree, TLS-ready vhost, and the proxy
# into the Lisp.
#
# The one non-obvious rule this vhost encodes: Hunchentoot has no concept of a
# virtual host, and define-easy-handler keeps a single global dispatch table, so
# one instance cannot route by Host header. The workaround (from the original
# article, still in production) is to give every route a prefix inside Lisp —
# /hhub/... here — and let nginx rewrite anything that is not a real static file
# into that prefix. One acceptor, many domains, no vhost support needed.
#
#   request for /some/page
#     -> /data/www/public/some/page exists?        serve it (static)
#     -> otherwise  rewrite to /hhub/some/page  ->  proxy_pass http://hunchentoot
#
# What this script does NOT do: TLS. Add certbot after the site answers on :80.

. "$(dirname "$0")/lib.sh"
require_root

# ── 1. nginx ────────────────────────────────────────────────────────────────
log "nginx"
apt_ensure nginx

# ── 2. static root ──────────────────────────────────────────────────────────
log "static root $WWW_ROOT"
install -d -m 755 "$WWW_ROOT"
if [ -d "$REPO/site/public" ]; then
  rsync -a --exclude '*.lisp' "$REPO/site/public/" "$WWW_ROOT/"
  ok "seeded from $REPO/site/public (installation/deploysite.sh keeps it in step later)"
else
  warn "$REPO/site/public not found — deploy the static assets yourself"
fi
chown -R www-data:www-data "$WWW_ROOT"

# ── 3. vhost ────────────────────────────────────────────────────────────────
log "vhost /etc/nginx/sites-available/$DOMAIN"
if [ -f "/etc/nginx/sites-available/$DOMAIN" ] && [ "${FORCE:-0}" != "1" ]; then
  warn "site file exists — left alone (FORCE=1 to overwrite)"
else
  render "$KIT_DIR/templates/nginx-site.conf.tpl" "/etc/nginx/sites-available/$DOMAIN"
  ok "written"
fi
ln -sfn "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/$DOMAIN"

# the stock default server would swallow everything that is not this vhost
if [ -L /etc/nginx/sites-enabled/default ]; then
  rm -f /etc/nginx/sites-enabled/default
  ok "removed sites-enabled/default"
fi

# ── 4. test, then reload (never restart into a broken config) ───────────────
log "nginx -t"
nginx -t || die "nginx config invalid — nothing reloaded"
systemctl reload nginx
ok "nginx reloaded"

log "done. Next: 07-install-database.sh, then verify.sh"
