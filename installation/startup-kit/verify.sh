#!/usr/bin/env bash
#
# verify.sh — read-only. Answers "is this box actually a working Nine Stores
# server?" without changing anything. Exits 1 if a check fails, and names it.
#
#   sudo ./verify.sh              # checks that need root (nginx -t, mysql, su)
#   ./verify.sh                   # still useful unprivileged; some checks skip
#
# Run it BEFORE starting the server (it will report "not listening" as a WARN,
# not a failure) and again after, when those become FAIL.

. "$(dirname "$0")/lib.sh"

fails=0
pass() { printf '\033[1;32m PASS\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m FAIL\033[0m %s\n' "$*"; fails=$((fails+1)); }
skip() { printf '\033[1;33m SKIP\033[0m %s\n' "$*"; }
warno(){ printf '\033[1;33m WARN\033[0m %s\n' "$*"; }

is_root() { [ "$(id -u)" = 0 ]; }

printf '\n=== Nine Stores — server verification (%s) ===\n' "$(hostname)"

# ── filesystem + accounts ───────────────────────────────────────────────────
[ -d "$REPO/hhub" ]        && pass "checkout: $REPO" || fail "no $REPO/hhub"
[ -d "$REPO/startup" ]     && pass "startup dir present" || fail "no $REPO/startup"
id "$APP_USER" >/dev/null 2>&1 && pass "app user $APP_USER exists" || fail "no user $APP_USER"
id -nG "$APP_USER" 2>/dev/null | tr ' ' '\n' | grep -qx "$APP_GROUP" \
  && pass "$APP_USER is in $APP_GROUP" || fail "$APP_USER NOT in $APP_GROUP"
for d in log run hhublogs; do
  [ -w "$APP_HOME/$d" ] || is_root || warno "$APP_HOME/$d not writable by $(id -un) (expected for $APP_USER)"
  [ -d "$APP_HOME/$d" ] && pass "$APP_HOME/$d exists" || fail "$APP_HOME/$d missing"
done
bad="$(find "$REPO" -maxdepth 2 ! -group "$APP_GROUP" | head -5)"
[ -z "$bad" ] && pass "tree is group $APP_GROUP at depth 2" \
              || fail "wrong group (first: $(echo "$bad" | head -1)) — run ../fix-permissions.sh"
[ -f "$APP_HOME/.sbclrc" ] && pass "~$APP_USER/.sbclrc (Quicklisp) present" \
                           || fail "~$APP_USER/.sbclrc missing — Quicklisp will not load"
[ -e "$APP_HOME/quicklisp/setup.lisp" ] && pass "Quicklisp reachable from $APP_HOME" \
                                        || fail "no Quicklisp at $APP_HOME/quicklisp"
[ -e "$APP_HOME/init.lisp" ] && pass "init.lisp linked into $APP_HOME" \
                             || fail "$APP_HOME/init.lisp missing"

# ── binaries ────────────────────────────────────────────────────────────────
for c in sbcl detachtty nginx mysql; do
  if have "$c"; then pass "$c at $(command -v "$c")"; else fail "$c not installed"; fi
done
have sbcl  && printf '   sbcl:  %s\n' "$(sbcl --version 2>&1 | head -1)"
have nginx && printf '   nginx: %s\n' "$(nginx -v 2>&1 | head -1)"
have attachtty && pass "attachtty (live image)" || warno "attachtty missing"
have telnet    && pass "telnet client (stop path)" || fail "telnet missing — 'stop' cannot signal the image"
have node      && pass "node: $(node --version)"   || fail "node missing (push/sms/s3 servers)"
have pm2       && pass "pm2 present"               || warno "pm2 missing"

# ── startup files ───────────────────────────────────────────────────────────
for f in init.lisp load.lisp start-hunchentoot; do
  [ -f "$REPO/startup/$f" ] && pass "startup/$f" || fail "startup/$f missing"
done
[ -x "$REPO/startup/start-hunchentoot" ] && pass "start-hunchentoot executable" \
                                         || fail "start-hunchentoot not executable"
grep -q "$SHUTDOWN_PORT" "$REPO/startup/init.lisp" 2>/dev/null \
  && pass "init.lisp uses shutdown port $SHUTDOWN_PORT" \
  || fail "init.lisp does not mention $SHUTDOWN_PORT — it will not stop"
[ -f /etc/init.d/hunchentoot ] && pass "/etc/init.d/hunchentoot" || fail "no init script"

# ── listening ports ─────────────────────────────────────────────────────────
printf '\n-- ports (all but 80/443 should be 127.0.0.1) --\n'
ss -ltn 2>/dev/null | awk 'NR>1{print "   "$4}' | sort -u
for p in "$HTTP_PORT" "$SWANK_PORT" "$SHUTDOWN_PORT"; do
  if ss -ltn 2>/dev/null | grep -q ":${p}\b"; then pass "listening on $p"
  else warno "nothing on $p (expected before the first start)"; fi
done
if ss -ltn 2>/dev/null | grep -qE '0\.0\.0\.0:(4244|4016|6200|3306)'; then
  fail "an internal port is exposed on 0.0.0.0 — bind it to 127.0.0.1"
else
  pass "internal ports are loopback-only"
fi

# ── nginx ───────────────────────────────────────────────────────────────────
if is_root; then
  nginx -t >/dev/null 2>&1 && pass "nginx -t clean" || fail "nginx config invalid (nginx -t)"
else
  skip "nginx -t (needs root)"
fi
[ -L "/etc/nginx/sites-enabled/$DOMAIN" ] && pass "vhost $DOMAIN enabled" \
                                          || fail "vhost $DOMAIN not enabled"
[ -L /etc/nginx/sites-enabled/default ] && warno "sites-enabled/default still present — it may shadow $DOMAIN"
[ -d "$WWW_ROOT" ] && pass "static root $WWW_ROOT" || fail "static root $WWW_ROOT missing"

# ── database ────────────────────────────────────────────────────────────────
if is_root; then
  systemctl is-active --quiet mysql && pass "mysql active" || fail "mysql not running"
  n="$(mysql -N -B -e "select count(*) from information_schema.tables where table_schema='$DB_NAME'" 2>/dev/null || echo err)"
  case "$n" in
    err) fail "cannot reach $DB_NAME" ;;
    0)   fail "$DB_NAME exists but has no tables" ;;
    *)   pass "$DB_NAME: $n tables" ;;
  esac
  mysql -N -B -e "select user,host,plugin from mysql.user where user='$DB_USER'" 2>/dev/null \
    | sed 's/^/   /'
else
  skip "mysql checks (need root)"
fi

# ── end to end (only meaningful if the acceptor is up) ──────────────────────
printf '\n-- end to end --\n'
if ss -ltn 2>/dev/null | grep -q ":${HTTP_PORT}\b"; then
  code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${HTTP_PORT}${URL_PREFIX}" || echo 000)"
  [ "$code" = "000" ] && fail "acceptor is listening but not answering on $HTTP_PORT" \
                      || pass "acceptor answers direct: HTTP $code"
  code="$(curl -s -o /dev/null -w '%{http_code}' -H "Host: $DOMAIN" "http://127.0.0.1/" || echo 000)"
  case "$code" in
    502) fail "nginx 502 — check $APP_HOME/log/hunchentoot.dribble, not nginx" ;;
    000) fail "nginx not answering on :80" ;;
    *)   pass "through nginx: HTTP $code" ;;
  esac
else
  skip "acceptor not running — start it with $REPO/startup/nst-start.sh"
fi

printf '\n=== %s ===\n' "$([ $fails -eq 0 ] && echo 'all checks passed' || echo "$fails check(s) FAILED")"
exit $([ $fails -eq 0 ] && echo 0 || echo 1)
