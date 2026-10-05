#!/usr/bin/env bash
#
# lib.sh — shared helpers. Every kit script starts with:
#
#     . "$(dirname "$0")/lib.sh"
#
# which loads config.env, sets the strict flags and gives you log/warn/die.
# It deliberately does nothing else: no side effects on source.

set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${CONFIG:-$KIT_DIR/config.env}"

if [ ! -f "$CONFIG" ]; then
  printf '[fail] %s not found — copy config.env.example to config.env and edit it\n' "$CONFIG" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$CONFIG"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[fail]\033[0m %s\n' "$*" >&2; exit 1; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }

require_root() { [ "$(id -u)" = 0 ] || die "run this as root: sudo $0"; }
have()         { command -v "$1" >/dev/null 2>&1; }

# install a package only if it is missing; apt is quiet unless it acts
apt_ensure() {
  local missing=()
  for p in "$@"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  [ ${#missing[@]} -eq 0 ] && { ok "packages present: $*"; return 0; }
  log "installing: ${missing[*]}"
  DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
}

# render a template: @TOKEN@ -> config value, into $2 (use - for stdout)
render() {
  sed -e "s|@DOMAIN@|${DOMAIN}|g" \
      -e "s|@ALIASES@|${ALIASES}|g" \
      -e "s|@ADMIN_USER@|${ADMIN_USER}|g" \
      -e "s|@DEV_USER@|${DEV_USER}|g" \
      -e "s|@SSH_PORT@|${SSH_PORT}|g" \
      -e "s|@REPO@|${REPO}|g" \
      -e "s|@APP_USER@|${APP_USER}|g" \
      -e "s|@APP_GROUP@|${APP_GROUP}|g" \
      -e "s|@APP_HOME@|${APP_HOME}|g" \
      -e "s|@WWW_ROOT@|${WWW_ROOT}|g" \
      -e "s|@HTTP_PORT@|${HTTP_PORT}|g" \
      -e "s|@SWANK_PORT@|${SWANK_PORT}|g" \
      -e "s|@SHUTDOWN_PORT@|${SHUTDOWN_PORT}|g" \
      -e "s|@WEBPUSH_PORT@|${WEBPUSH_PORT}|g" \
      -e "s|@SMS_PORT@|${SMS_PORT}|g" \
      -e "s|@S3_PORT@|${S3_PORT}|g" \
      -e "s|@URL_PREFIX@|${URL_PREFIX}|g" \
      "$1" > "$2"
}

# confirm before an irreversible step
confirm() {
  printf '\033[1;33m%s\033[0m [y/N] ' "$1"
  read -r reply
  case "$reply" in y|Y|yes|YES) return 0 ;; *) die "aborted by user" ;; esac
}
