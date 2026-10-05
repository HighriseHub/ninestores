#!/usr/bin/env bash
#
# 07-install-database.sh — MySQL 8: database, application user, and the schema.
#
# The application reads its credentials from globals in
# hhub/core/dod-ini-sys.lisp:
#     *crm-database-name*  "hhubdb"      *crm-database-user*  "hhubuser"
#     *crm-database-server* "localhost"  *crm-database-password* ...
# There is no config file and no environment variable: those defvars ARE the
# configuration, so this script's DB_* values must match them (or you edit them
# in the source before first start).
#
# ⚠ On MySQL 8 the default authentication plugin is caching_sha2_password. If
#   the Lisp side fails to authenticate ("Access denied" with a correct
#   password), re-create the user with IDENTIFIED WITH mysql_native_password —
#   that is the usual cause, and it is a one-line fix rather than a hunt.
#
# ⚠ installation/hhubplatform.sql is a schema snapshot, NOT a backup, and it is
#   known to be stale for some tables (the order tables in particular — see
#   aiharness/deepseek/skills/order-adhara-stories-CONTEXT.md §1). For a fresh
#   box it is a starting point; for a restore, use a real dump.

. "$(dirname "$0")/lib.sh"
require_root

have mysql || die "mysql client missing — run 02-install-packages.sh first"

log "MySQL service"
systemctl enable --now mysql
systemctl is-active --quiet mysql && ok "mysql is running"

# ── 1. database + user ──────────────────────────────────────────────────────
log "database $DB_NAME and user $DB_USER@$DB_HOST"
if [ -z "${DB_PASSWORD:-}" ]; then
  printf 'password for %s@%s: ' "$DB_USER" "$DB_HOST"
  read -rs DB_PASSWORD; echo
  [ -n "$DB_PASSWORD" ] || die "empty password refused"
fi
[ ${#DB_PASSWORD} -ge 12 ] || warn "password is shorter than 12 characters"

mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASSWORD';
ALTER USER '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'$DB_HOST';
FLUSH PRIVILEGES;
SQL
ok "database and grants in place"

mysql -u "$DB_USER" -p"$DB_PASSWORD" -h "$DB_HOST" -e "select 1" "$DB_NAME" >/dev/null \
  || die "the application user cannot connect — if MySQL 8 auth is the cause, see the header"
ok "credentials work"

# ── 2. schema / seed data ───────────────────────────────────────────────────
SEED="$REPO/installation/${SEED_SQL:-hhubplatform.sql}"
if [ -f "$SEED" ]; then
  existing="$(mysql -N -B -e "select count(*) from information_schema.tables where table_schema='$DB_NAME'")"
  if [ "$existing" -gt 0 ]; then
    warn "$DB_NAME already has $existing tables — NOT loading $SEED (that would be a destructive guess)"
    warn "to load anyway:  mysql $DB_NAME < $SEED"
  else
    log "loading schema from $SEED"
    mysql "$DB_NAME" < "$SEED"
    ok "loaded"
  fi
else
  warn "no seed SQL at $SEED — load the schema by hand"
fi

# ── 3. the migration/upgrade files ──────────────────────────────────────────
if [ -d "$REPO/installation/upgrades" ]; then
  log "upgrade files"
  printf '  %s file(s) in installation/upgrades — these are applied through the app\n' \
    "$(find "$REPO/installation/upgrades" -name '*.lisp' | wc -l)"
  printf '  mechanism: aiharness/deepseek/skills/knowledge/schema-migrations-CONTEXT.md\n'
fi

log "done. Next: verify.sh, then the first start"
