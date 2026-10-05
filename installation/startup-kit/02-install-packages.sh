#!/usr/bin/env bash
#
# 02-install-packages.sh — every apt package the platform needs, in one place.
# Nothing here is optional enough to defer: each line has a reason.
#
#   build-essential   SBCL compiles the libraries it loads; also detachtty's make
#   libuv1-dev        cl-async (the async I/O the app uses) needs libuv
#   libmysqlclient-dev CLSQL's mysql backend links against it
#   mysql-server      MySQL 8 — the store of record
#   nginx             the edge: static tree, TLS, and the /hhub/ proxy
#   telnet            /etc/init.d/hunchentoot stops the image by telnetting 6200
#   unzip             detachtty ships as a zip on some mirrors
#   wkhtmltopdf       HTML -> PDF (invoices)
#   qrencode          QR rendering (UPI / payment links)
#   nodejs npm        the three node servers (push / SMS / S3)
#   wget curl git     fetching Quicklisp, the repo, releases

. "$(dirname "$0")/lib.sh"
require_root

apt-get update

log "core packages"
apt_ensure build-essential libuv1-dev libmysqlclient-dev \
           mysql-server nginx telnet unzip wget curl git ca-certificates

log "document + image tooling"
apt_ensure wkhtmltopdf qrencode fontconfig

log "node + pm2"
apt_ensure nodejs npm
if have pm2; then ok "pm2 present"; else npm install -g pm2; fi

log "versions"
for c in sbcl mysql nginx node npm; do
  have "$c" && printf '  %-8s %s\n' "$c" "$($c --version 2>&1 | head -1)"
done

log "done. Next: 03-install-sbcl.sh"
