#!/usr/bin/env bash
#
# 01-harden-host.sh — locale, updates, the admin account, SSH key-only access,
# and a default-deny firewall. This is step 1 for a reason: everything after it
# assumes you can log in as a non-root user with a key.
#
# ⚠ THIS SCRIPT CHANGES THE SSH PORT AND DISABLES PASSWORD LOGIN.
#   Keep your current session open. Only close it once a SECOND terminal has
#   successfully run:  ssh -p $SSH_PORT $ADMIN_USER@<host>
#
#   SKIP_SSH=1 ./01-harden-host.sh   # do the rest, leave sshd alone

. "$(dirname "$0")/lib.sh"
require_root

# ── 1. locale + timezone ────────────────────────────────────────────────────
log "locale and time"
apt_ensure locales tzdata
if [ -n "${LOCALE:-}" ]; then
  locale-gen "$LOCALE"
  update-locale LANG="$LOCALE"
fi
# dpkg-reconfigure tzdata is interactive; set it non-interactively instead
[ -n "${TIMEZONE:-}" ] && ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime

# ── 2. updates ──────────────────────────────────────────────────────────────
log "apt update + upgrade"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# ── 3. admin account ────────────────────────────────────────────────────────
log "admin account: $ADMIN_USER"
if id "$ADMIN_USER" >/dev/null 2>&1; then
  ok "user exists"
else
  adduser --gecos "" --disabled-password "$ADMIN_USER"
fi
usermod -aG sudo "$ADMIN_USER"
install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_USER" "/home/$ADMIN_USER/.ssh"

if [ -s "/home/$ADMIN_USER/.ssh/authorized_keys" ]; then
  ok "authorized_keys present ($(wc -l < "/home/$ADMIN_USER/.ssh/authorized_keys") key(s))"
else
  warn "no authorized_keys for $ADMIN_USER yet."
  warn "from your LOCAL machine:  ssh-keygen -t ed25519 && ssh-copy-id -p $SSH_PORT $ADMIN_USER@<host>"
  warn "then re-run this script. Refusing to disable password auth without a key."
  SKIP_SSH=1
fi

# ── 4. sshd: key-only, non-default port, no root ────────────────────────────
if [ "${SKIP_SSH:-0}" = "1" ]; then
  warn "SKIP_SSH set — sshd_config NOT touched"
else
  log "sshd hardening (port $SSH_PORT)"
  install -d -m 755 /etc/ssh/sshd_config.d
  cat > /etc/ssh/sshd_config.d/99-ninestores.conf <<EOF
# Written by installation/startup-kit/01-harden-host.sh
Port $SSH_PORT
Protocol 2
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
X11Forwarding no
AllowUsers $ADMIN_USER
EOF
  sshd -t || die "sshd config invalid — nothing reloaded"
  systemctl reload ssh 2>/dev/null || systemctl reload sshd
  ok "sshd reloaded. VERIFY IN A SECOND TERMINAL BEFORE CLOSING THIS ONE."
fi

# ── 5. firewall: default deny, only the ports this box serves ───────────────
log "firewall"
apt_ensure ufw
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT"/tcp comment 'ssh'
ufw allow 80/tcp  comment 'http'
ufw allow 443/tcp comment 'https'
ufw allow proto icmp comment 'ping'
ufw --force enable
ok "ufw active — 4244/4016/6200/3306 stay loopback-only by design"

log "done. Next: 02-install-packages.sh"
