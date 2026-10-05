#!/usr/bin/env bash
#
# 05-install-hunchentoot-service.sh — detachtty, the startup files, and the
# SysV init script that starts and stops the image.
#
# Why detachtty and not systemd: this is what the platform has always run, and
# it is what gives you `attachtty` — a terminal onto the LIVE image, which is
# how a running server is inspected and how a stuck one is understood. It comes
# at a price: the stop path is a TCP connection to port 6200, so `stop` needs
# the telnet CLIENT installed and cannot signal a process that died during load.
#
# Files written:
#   $REPO/startup/init.lisp            (from templates/init.lisp)
#   $REPO/startup/load.lisp            (from templates/load.lisp)
#   $REPO/startup/start-hunchentoot    (from templates/start-hunchentoot)
#   /etc/init.d/hunchentoot            (from templates/hunchentoot.initd)
#
# It does NOT start the server: read the startup files first, then run
# $REPO/startup/nst-start.sh (node servers first, then the image).

. "$(dirname "$0")/lib.sh"
require_root

T="$KIT_DIR/templates"

# ── 1. detachtty ────────────────────────────────────────────────────────────
log "detachtty"
if have detachtty; then
  ok "already installed ($(command -v detachtty))"
else
  apt_ensure detachtty 2>/dev/null || {
    log "not in apt — building from source"
    apt_ensure build-essential unzip
    work="$(mktemp -d)"
    wget -q -O "$work/detachtty.zip" \
      https://github.com/huetsch/detachtty/archive/refs/heads/master.zip
    unzip -q "$work/detachtty.zip" -d "$work"
    ( cd "$work"/detachtty-master && make && make install )
    install -m 755 "$work"/detachtty-master/detachtty /usr/local/bin/ 2>/dev/null || true
    install -m 755 "$work"/detachtty-master/attachtty /usr/local/bin/ 2>/dev/null || true
    rm -rf "$work"
  }
fi
if have attachtty; then ok "attachtty available for live-image access"; else warn "attachtty missing — no live-image terminal"; fi

# ── 2. startup files, rendered from templates ───────────────────────────────
log "startup files in $REPO/startup"
[ -d "$REPO/startup" ] || die "$REPO/startup missing — is $REPO the checkout?"
for f in init.lisp load.lisp start-hunchentoot; do
  if [ -f "$REPO/startup/$f" ] && [ "${FORCE:-0}" != "1" ]; then
    warn "$REPO/startup/$f exists — left alone (FORCE=1 to overwrite)"
    continue
  fi
  render "$T/$f" "$REPO/startup/$f"
  ok "wrote startup/$f"
done

chmod 755 "$REPO/startup/start-hunchentoot"
chmod 644 "$REPO/startup/init.lisp" "$REPO/startup/load.lisp"
chown -R "$APP_USER:$APP_GROUP" "$REPO/startup"
chgrp "$APP_GROUP" "$REPO/startup"/*

# ── 3. init script ──────────────────────────────────────────────────────────
log "/etc/init.d/hunchentoot"
if [ -f /etc/init.d/hunchentoot ] && [ "${FORCE:-0}" != "1" ]; then
  warn "an init script already exists — left alone (FORCE=1 to overwrite)"
else
  render "$T/hunchentoot.initd" /etc/init.d/hunchentoot
  chmod 755 /etc/init.d/hunchentoot
  ok "installed"
fi
update-rc.d hunchentoot defaults >/dev/null 2>&1 || true

# ── 4. sanity ───────────────────────────────────────────────────────────────
log "checks"
have telnet || warn "the telnet client is MISSING — 'stop' will silently do nothing"
[ -x "$REPO/startup/start-hunchentoot" ] || die "start-hunchentoot not executable"
ok "$(grep -c . "$REPO/startup/init.lisp") lines of init.lisp, shutdown port $SHUTDOWN_PORT"

log "done. The server is NOT started. Next: 06 install nginx, 07 database, then verify.sh"
