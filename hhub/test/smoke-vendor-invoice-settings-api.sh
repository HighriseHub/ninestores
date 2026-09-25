#!/usr/bin/env bash
#
# smoke-vendor-invoice-settings-api.sh — smoke-test the VENDOR INVOICE SETTINGS JSON
# API (conflodis2 + apidefs2), the INVOICE_SETTINGS column on nst-vnd.
#
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-vendor-invoice-settings-api.sh
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-vendor-invoice-settings-api.sh --write
#
# READ-ONLY by default. --write adds the PUT that replaces a real vendor's blob.
#
# Exit codes:  0 = every result matched its expectation
#              1 = at least one result did NOT match
#              2 = setup failure (unreachable, no session, no restore path) — the
#                  API was not tested
#
# ── WHAT THIS RESOURCE IS, AND WHY THE SUITE HAS ONE WRITE ENDPOINT ─────────
# INVOICE_SETTINGS is not a row — it is a TEXT column on DOD_VEND_PROFILE holding a
# PRINTED LISP ALIST of eleven named sections. There is exactly one endpoint:
#
#   PUT  /hhub/api/v1/vendor/profile/{id}/invoice-settings
#
# and one read, which is NOT a settings endpoint:
#
#   GET  /hhub/api/v1/vendor/profile/{id}      → the invoiceSettings FIELD
#
# THERE IS NO DEDICATED GET, AND SECTION 3 ASSERTS ITS ABSENCE (`no_such_endpoint`),
# because the shape of the read is the open item: the field is published as the raw
# Lisp string, so a client can read the blob but cannot PUT it back (K3).
#
# THERE IS NO LIST AND NO DELETE. A vendor always has exactly one blob, so "list"
# means nothing and "delete" means nothing — the column has no default and the
# settings page reads it with strict (assoc 'invoice-print-settings … :test #'equal),
# so a NULL or a cleared blob silently reverts the vendor to the SHIPPED defaults
# rather than erroring (see vendor-settings-name->key). "Reset to defaults" would be
# a legitimate endpoint; it is not this one.
#
# ── THE RESTORE PROBLEM, WHICH IS WHY --write IS GUARDED ────────────────────
# 🚨 THE READ AND THE WRITE ARE DIFFERENT TYPES, so this suite CANNOT round-trip
# through HTTP: GET hands back a Lisp string and PUT demands a JSON object. It
# therefore cannot restore by PUTting back what it read. Four consequences, each
# deliberate:
#
#   1. IT NEVER WRITES TO THE DEMO VENDOR. Vendor 1 is the only CUSTOMISED row in
#      the table (Legal/Landscape/10 instead of the seed's A4/Portrait/12, its own
#      header and footer text, a watermark signed by its owner, and its own uploaded
#      logo URL). Every other vendor holds the byte-identical migration seed, so
#      vendor 1 is the only one whose blob cannot be reconstructed from a sibling.
#      It is the LOGIN IDENTITY and a read fixture; it is never the write target.
#   2. IT WRITES TO A DISPOSABLE VENDOR (2) and restores from a pristine DONOR (3)
#      that is asserted BYTE-IDENTICAL to it first — so the copy-back IS the target's
#      own value, not an approximation. If the two ever diverge, the script REFUSES
#      to write (exit 2) rather than guess a restore.
#   3. THE RESTORE IS A SQL SELF-JOIN, so the blob NEVER LEAVES MySQL. A previous
#      incident in this tree lost vendor 1's settings exactly here: a restore built
#      with `sql-literal` on the blob did not quote it, the UPDATE was invalid, and
#      because the failure was inside the cleanup the test value stayed in the row.
#      Worse, this column contains real NEWLINES and `mysql -N` escapes them as the
#      two characters `\n`, so a dump-then-restore turns them into literal backslash-n.
#      Letting the server do `SET t.x = d.x` sidesteps quoting and escaping entirely.
#   4. THE RESTORE IS ON A TRAP, and it VERIFIES ITSELF against an MD5 taken before
#      the first write. A cleanup that cannot report failure is not a cleanup.
#
# ── KNOWN DEFECTS THIS SCRIPT ENCODES ───────────────────────────────────────
# Asserted against the CORRECT contract but reported as `KNOWN` (not `FAIL`) so a
# real regression stands out. If a KNOWN check starts passing, fix this script: the
# defect was repaired.
#
#  K1. 🚨 A REJECTED BLOB IS 500, NOT 400. The domain refuses a malformed payload
#      correctly and writes nothing, but vendor-settings-rejected carries a precise
#      `why` that never reaches the wire: apidefs2's condition→status classifier
#      answers `internal_error` for every condition (nst-bl-vndvpmapi-CONTEXT's K2
#      is the same gap). A client that sent a bad section name is told the server
#      broke, and the three cases below — a bogus section, no payload at all, an
#      empty object — are indistinguishable from each other and from a real crash.
#
#  K2. 🚨 THE GENERIC PUT STILL WRITES INVOICE SETTINGS, UNVALIDATED. Phase 2 (remove
#      :invoice-settings from !update) is not done, so
#        PUT /hhub/api/v1/vendor/profile/{id}  {"invoiceSettings": "<any string>"}
#      answers 200 and replaces the blob with whatever it was handed — including a
#      blob whose sections are keywords or invented, which the readers then MISS and
#      silently replace with the shipped defaults. Measured 2026-09-25: a 4330-char
#      blob was replaced by 45 characters of `((COM.NSTORES.APP::NO-SUCH-SECTION
#      (:A . 1)))` with no error anywhere. Until this is closed, the validated
#      endpoint below is not the only way in, so its guarantee is partial.
#
#  K3. THERE IS NO JSON-SHAPED READ. GET publishes invoiceSettings as a Lisp string,
#      so read-modify-write of the whole blob is impossible over HTTP and every
#      client must construct the object itself.
#
set -uo pipefail

# ── configuration ───────────────────────────────────────────────────────────
# THE BASE DEFAULT DIFFERS FROM THE OTHER smoke-*.sh SCRIPTS, deliberately. Theirs is
# http://hunchentoot.local, which answers 404 for EVERY /hhub/ URI on this host —
# nginx on :80 does not proxy this application — so none of them can run here without
# --base. Measured 2026-09-25 across three paths:
#
#   base                    /hhub/   api/v1/vendor/profile/1   dodvendloginpage
#   http://ninestores.local   404            401                     302
#   http://127.0.0.1:4244     404            401                     302   (identical)
#   http://hunchentoot.local  404            404                     404   (dead)
#
# NOTE THAT /hhub/ IS 404 ON ALL OF THEM — the bare prefix is not a route anywhere, so
# a probe that only checks curl's exit status proves nothing about which application
# answered. Section 1 therefore asserts the API's own 401 instead.
BASE="${BASE:-http://ninestores.local}"
PHONE="${NS_PHONE:-}"
PASSWORD="${NS_PASSWORD:-}"

# FIXTURES — all verified against the live database (hhubdb, 2026-09-25).
#
# The demo vendor IS the login identity: phone 9999999990 is DOD_VEND_PROFILE.ROW_ID
# 1, TENANT_ID 2. It is ALSO the only row in the table whose blob is NOT the
# migration seed, which is why it is read and never written (see the header).
DEMO_VENDOR="${NS_DEMO_VENDOR:-1}"
#
# The write target and its donor. Vendors 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 17,
# 18 and 19 all hold the byte-identical 4330-character seed; 1 is the odd one out.
# The script asserts 2 = 3 before it writes anything.
TARGET_VENDOR="${NS_TARGET_VENDOR:-2}"
DONOR_VENDOR="${NS_DONOR_VENDOR:-3}"
#
# A vendor in ANOTHER tenant (17 is tenant 5). Read or written from a tenant-2
# session it must be 404 — the tenant filter makes another tenant's row-id
# indistinguishable from one that never existed. That is the security-relevant
# assertion (OWASP API1:2023 BOLA): the id in the URL is an ADDRESS, never an
# authorization. NOTE what this does NOT cover: any vendor of the SAME tenant may
# write any sibling's blob, because the verb scopes by tenant, not by owner.
CROSS_TENANT_VENDOR="${NS_CROSS_TENANT_VENDOR:-17}"
#
# A row-id that has never existed, and one that is not a number at all.
ABSENT_VENDOR="${NS_ABSENT_VENDOR:-99999}"

# The restore and the row-integrity checks need SQL. Overridable so the credentials
# do not have to live here; the default is the dev pair documented in
# core/dod-ini-sys.lisp and in the sibling CONTEXT files.
NS_DB="${NS_DB:-hhubdb}"
NS_MYSQL_USER="${NS_MYSQL_USER:-hhubuser}"
NS_MYSQL_PASS="${NS_MYSQL_PASS:-Welcome\$123}"
sql() { mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" -N -B "$NS_DB" -e "$1" 2>/dev/null; }
sql_ok() { mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" "$NS_DB" -e "$1" 2>/dev/null; }

WRITE=0

usage() {
  sed -n '3,80p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --write            also run the mutating tests (replaces a real vendor's blob)
  --base URL         override the base URL   (default http://ninestores.local)
  -h, --help         this text

Environment:
  NS_PHONE               vendor phone (login form field "phone")       [required]
  NS_PASSWORD            vendor password                              [required]
  NS_DEMO_VENDOR         the logged-in vendor's row-id, NEVER written   (default 1)
  NS_TARGET_VENDOR       the disposable write target                    (default 2)
  NS_DONOR_VENDOR        a pristine row with the SAME blob              (default 3)
  NS_CROSS_TENANT_VENDOR a vendor in another tenant                     (default 17)
  NS_ABSENT_VENDOR       a row-id that has never existed                (default 99999)
  NS_DB / NS_MYSQL_USER / NS_MYSQL_PASS   SQL access, for --write and the
                         row-integrity check               (default hhubdb/hhubuser)
  NS_EXPECT_U=1          GATED :U run. Pauses after login so the database can be
                         stopped, asserts 503, then exits. Restart the DB after.
  BASE                   base URL, same as --base
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --write)  WRITE=1 ;;
    --base)   BASE="${2:-}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$PHONE" ] || [ -z "$PASSWORD" ]; then
  echo "ERROR: set NS_PHONE and NS_PASSWORD (vendor credentials)." >&2
  echo "       Same login as the other smoke scripts — the session company IS the tenant." >&2
  exit 2
fi

# ── plumbing ────────────────────────────────────────────────────────────────
TMP="$(mktemp -d)" || exit 2
JAR="$TMP/cookies.txt"
BODY="$TMP/body.json"
ERR="$TMP/curl.err"

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; N=$'\033[0m'
else G=; R=; Y=; N=; fi

PASS=0; FAIL=0; KNOWN=0; SKIP=0
HTTP_CODE=""

# 🚨 THE RESTORE IS INSTALLED HERE, BEFORE ANYTHING CAN WRITE, and it is a no-op
# until something asks for it. Two reasons it is not defined next to the writes:
# a trap registered later is not protecting the earlier ones, and the whole point of
# a cleanup is that it runs when the script did NOT reach its own tidy ending.
# It restores INSIDE MySQL (the blob never passes through the shell, so there is no
# quoting and no `\n`-escaping hazard) and VERIFIES the result against an md5 taken
# before the first write. A cleanup that cannot report failure is not a cleanup.
RESTORE_NEEDED=0
TARGET_MD5=""
restore_blob() {
  [ "$RESTORE_NEEDED" = 1 ] || return 0
  sql_ok "UPDATE DOD_VEND_PROFILE t
            JOIN (SELECT INVOICE_SETTINGS s FROM DOD_VEND_PROFILE WHERE ROW_ID=$DONOR_VENDOR) d
            SET t.INVOICE_SETTINGS = d.s
          WHERE t.ROW_ID=$TARGET_VENDOR"
  local now_md5
  now_md5="$(sql "SELECT MD5(INVOICE_SETTINGS) FROM DOD_VEND_PROFILE WHERE ROW_ID=$TARGET_VENDOR")"
  printf '\n  restore: target %s blob md5 %s ' "$TARGET_VENDOR" "${now_md5:0:12}…"
  if [ "$now_md5" = "$TARGET_MD5" ]; then
    printf '%sOK%s (matches the pre-write md5)\n' "$G" "$N"
  else
    printf '%sFAILED%s — expected %s. THE ROW IS STILL MODIFIED.\n' "$R" "$N" "${TARGET_MD5:0:12}…"
    printf '    Restore by hand:\n'
    printf '      mysql %s -e "UPDATE DOD_VEND_PROFILE t JOIN (SELECT INVOICE_SETTINGS s\n' "$NS_DB"
    printf '        FROM DOD_VEND_PROFILE WHERE ROW_ID=%s) d SET t.INVOICE_SETTINGS=d.s\n' "$DONOR_VENDOR"
    printf '        WHERE t.ROW_ID=%s;"\n' "$TARGET_VENDOR"
  fi
}
cleanup() { restore_blob; rm -rf "$TMP"; }
trap cleanup EXIT

req() {
  local method="$1"; shift
  local path="$1"; shift
  HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -X "$method" \
                    -b "$JAR" -c "$JAR" --max-time 20 "$@" "$BASE$path" 2>"$ERR")"
  local rc=$?
  if [ $rc -ne 0 ] || [ -z "$HTTP_CODE" ]; then
    HTTP_CODE="000"
    printf '  %snetwork%s  %s — curl: %s\n' "$R" "$N" "$method $path" "$(head -1 "$ERR")"
  fi
}

# expect NAME STATUS [SUBSTRING]
expect() {
  local name="$1" want="$2" needle="${3:-}" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-46s got %s, want %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" \
           "${needle:+, containing \"$needle\"}"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
}

# expect-known NAME STATUS SUBSTRING "WHY" — asserts the CORRECT contract, but a
# mismatch is reported as a KNOWN defect (not a regression) with its cause.
expect-known() {
  local name="$1" want="$2" needle="$3" why="$4" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    PASS=$((PASS+1))
    printf '  %sPASS%s %-46s %s  (KNOWN defect appears fixed — update this script)\n' \
           "$G" "$N" "$name" "$HTTP_CODE"
  else
    KNOWN=$((KNOWN+1))
    printf '  %sKNOWN%s %-45s got %s, want %s\n' "$Y" "$N" "$name" "$HTTP_CODE" "$want"
    printf '        %s\n' "$why"
  fi
}

check() {
  local name="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s %s\n' "$G" "$N" "$name" "$got"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s got %s, want %s\n' "$R" "$N" "$name" "${got:-<empty>}" "$want"
  fi
}

skip() { SKIP=$((SKIP+1)); printf '  %sSKIP%s %-46s %s\n' "$Y" "$N" "$1" "$2"; }
info() { printf '  %s----%s %-46s %s\n' "$Y" "$N" "$1" "$2"; }
has_key() { grep -qF "\"$1\"" "$BODY"; }
section() { printf '\n== %s\n' "$1"; }
SETTINGS_PATH() { printf '/hhub/api/v1/vendor/profile/%s/invoice-settings' "$1"; }

bail_if_not_loaded() {
  if grep -qF '"no_such_endpoint"' "$BODY"; then
    printf '\n%sThe invoice-settings route is NOT REGISTERED in the running image.%s\n' "$R" "$N"
    printf 'This is the EXPECTED state on a fresh checkout: nst-bl-vndapi.lisp has not\n'
    printf 'been loaded since the route was added. In the Lisp image:\n'
    printf '  (load "/home/ubuntu/ninestores/hhub/vendor/nst-bl-vndapi.lisp")\n'
    printf '  (find-action-route (quote route-vendor-settings-update))   ; expect a route\n'
    printf '  (list-api-routes)  ; expect /hhub/api/v1/vendor/profile/{id}/invoice-settings\n'
    exit 2
  fi
}

# ── 1. reachability + session ───────────────────────────────────────────────
section "1. reachability and session  ($BASE)"

if ! curl -sS -o /dev/null --max-time 10 "$BASE/hhub/" 2>"$ERR"; then
  printf '  %sFATAL%s cannot reach %s — curl: %s\n' "$R" "$N" "$BASE" "$(head -1 "$ERR")"
  printf '        If you expected http://hunchentoot.local, note it answers 404 for\n'
  printf '        every /hhub/ URI on this host — see the base table above.\n'
  exit 2
fi

# 🚨 CONNECTIVITY IS NOT REACHABILITY. /hhub/ answers 404 on EVERY base listed above,
# so curl succeeding there only proves a socket opened — an nginx that proxies nothing,
# or a completely different application, passes that check. The assertion that carries
# information is the vendor API's own 401: it proves the route registry is behind this
# base AND that :auth-scope :session is enforced before dispatch.
req GET "/hhub/api/v1/vendor/profile/$DEMO_VENDOR"
if [ "$HTTP_CODE" != "401" ]; then
  printf '  %sFATAL%s %s/hhub/api/v1/vendor/profile/%s answered %s, expected 401.\n' \
         "$R" "$N" "$BASE" "$DEMO_VENDOR" "$HTTP_CODE"
  printf '        This base is not serving the vendor API. A 404 means nothing is proxied\n'
  printf '        (try --base http://ninestores.local); a 200 means a session already exists.\n'
  exit 2
fi
printf '  reachable — the unauthenticated API answered 401, so the route registry is behind this base\n'

LOGIN_CODE="$(curl -sS -o "$TMP/login.html" -w '%{http_code}' -c "$JAR" \
                   --max-time 15 -X POST "$BASE/hhub/dodvendlogin" \
                   -d "phone=$PHONE" -d "password=$PASSWORD" 2>"$ERR")"
printf '  login HTTP %s  (302 for BOTH success and failure — never read this as the outcome)\n' "$LOGIN_CODE"

if ! grep -q 'hunchentoot-session' "$JAR"; then
  printf '  %sFAIL%s no session cookie was issued — the login was REJECTED (a 302 is\n' "$R" "$N"
  printf '        returned for both outcomes, so the status tells you nothing).\n'
  printf '        Check the phone/password and the 2-concurrent-login limit; the reason\n'
  printf '        is logged to ninestores-busfunctions.log.\n'
  exit 2
fi

# THE SESSION PROBE IS A READ, and the REGISTRATION PROBE IS AIMED AT A VENDOR THAT
# DOES NOT EXIST — both deliberately non-writing. A registered route answers
# `not_found` for an absent row-id; an UNREGISTERED one answers `no_such_endpoint`.
# Same 404, different body, and no row is ever touched. The obvious probe — a PUT at
# the demo vendor — is the one thing this script must never do: it is the only
# customised blob in the table, and an accepted PUT would destroy it unrecoverably.
req GET "/hhub/api/v1/vendor/profile/$DEMO_VENDOR"
case "$HTTP_CODE" in
  401) printf '\n  %sFATAL%s login did not establish a vendor session (API answered 401).\n' "$R" "$N"
       exit 2 ;;
  000) printf '\n  %sFATAL%s could not reach the API endpoint.\n' "$R" "$N"; exit 2 ;;
esac
bail_if_not_loaded
printf '  session established (authenticated read answered %s)\n' "$HTTP_CODE"

req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' \
    -d "{\"invoice-print-settings\":{\"orientation\":\"portrait\"}}"
bail_if_not_loaded
printf '  settings route registered (absent row-id answered %s, "%s")\n' \
       "$HTTP_CODE" "$(grep -o '"error":"[a-z_]*"' "$BODY" | head -1 | cut -d'"' -f4)"

# ── 1b. :U — the gated boundary-failure run ─────────────────────────────────
# PROVISION, NOT A DEFAULT. Nothing an HTTP client can send makes the boundary
# fail, so the assertion is gated: login NEEDS the database, so it must be stopped
# AFTER the session exists — which is why this block pauses for the operator.
#
#   terminal 1:  NS_EXPECT_U=1 ./smoke-vendor-invoice-settings-api.sh   (wait)
#   terminal 2:  sudo systemctl stop mysql
#   terminal 1:  press Enter
#   terminal 2:  sudo systemctl start mysql                             (restore)
if [ "${NS_EXPECT_U:-}" = "1" ]; then
  printf '\n== 1b. :U boundary failure  (GATED RUN)\n'
  info "session is up" "now STOP the database, then press Enter"
  read -r _ || true
  req GET "/hhub/api/v1/vendor/profile/$DEMO_VENDOR"
  expect ":U database unanswerable → 503" 503 "\"unknown\""
  req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' \
      -d "{\"invoice-print-settings\":{\"orientation\":\"portrait\"}}"
  expect ":U write path → 503, NOT 404" 503 "\"unknown\""
  req PUT "$(SETTINGS_PATH abc)" -H 'Content-Type: application/json' \
      -d "{\"invoice-print-settings\":{\"orientation\":\"portrait\"}}"
  expect ":U survives the parse guard → 503" 503 "\"unknown\""
  printf '\n   RESTART THE DATABASE NOW.\n'
  printf '\n─────────────────────────────────────────────\n'
  printf 'passed %s   failed %s   known-defects %s   skipped %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
  [ "$FAIL" -gt 0 ] && exit 1
  exit 0
fi

# ── 2. the read: GET the vendor, read the FIELD ─────────────────────────────
section "2. the read — GET /vendor/profile/{id}, the invoiceSettings field"

req GET "/hhub/api/v1/vendor/profile/$DEMO_VENDOR"
expect ":T logged-in vendor → 200" 200 "\"invoiceSettings\""

if [ "$HTTP_CODE" = 200 ]; then
  # 🚨 THE ASSERTION THAT CARRIES THE MOST INFORMATION ON THIS ENDPOINT. The readers
  # find the print section with a STRICT (assoc 'invoice-print-settings … :test
  # #'equal), so a blob stored with KEYWORD sections is invisible to them and the
  # settings page silently falls back to the shipped defaults. A section symbol
  # printed as COM.NSTORES.APP::INVOICE-PRINT-SETTINGS is the canonical spelling
  # migrate-2026Sep-backfill-vendor-invoice-settings writes.
  if grep -qF 'COM.NSTORES.APP::INVOICE-PRINT-SETTINGS' "$BODY"; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s canonical section symbol\n' "$G" "$N" "blob carries the print section"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s the readers would MISS it and silently\n' "$R" "$N" "blob carries the print section"
    printf '       fall back to the shipped defaults — see vendor-settings-name->key\n'
  fi
  # K3: the read is a string, not an object. Asserted as KNOWN against the correct
  # contract (an object would make read-modify-write possible).
  if grep -qE '"invoiceSettings"[[:space:]]*:[[:space:]]*\{' "$BODY"; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s an object (K3 appears fixed)\n' "$G" "$N" "invoiceSettings is JSON-shaped"
  else
    KNOWN=$((KNOWN+1))
    printf '  %sKNOWN%s %-45s it is a STRING\n' "$Y" "$N" "invoiceSettings is JSON-shaped"
    printf '        K3: GET publishes the raw printed Lisp alist, so a client can read the\n'
    printf '        blob but cannot PUT it back (the write wants an object) and every\n'
    printf '        read-modify-write must construct the object itself.\n'
  fi
fi

# --- :F — the states that must NOT be :T ------------------------------------
req GET "/hhub/api/v1/vendor/profile/$CROSS_TENANT_VENDOR"
expect ":F another tenant's vendor → 404 (BOLA)" 404 "\"not_found\""
req GET "/hhub/api/v1/vendor/profile/$ABSENT_VENDOR"
expect ":F absent vendor id → 404" 404 "\"not_found\""
req GET "/hhub/api/v1/vendor/profile/abc"
expect ":F non-numeric id → 404 (not 500)" 404 "\"not_found\""

# ── 3. the PUT contract — routing and refusal, NON-WRITING BY CONSTRUCTION ──
# 🚨 EVERY REQUEST IN THIS SECTION IS AIMED AT A ROW THAT CANNOT BE WRITTEN — an
# absent row-id, a non-numeric one, or another tenant's. THE REASON IS STRUCTURAL,
# NOT A MATTER OF CARE: !settings validates the payload BEFORE it looks the row up,
# so a payload the domain REFUSES produces the same answer either way, while a
# payload it happens to ACCEPT can only ever reach a 404. That is what makes this
# section safe even though several of these bodies are payloads nobody has classified
# yet — an accepted payload aimed at the demo vendor would be a silent, unrecoverable
# overwrite of the only customised blob in the table.
#
# This is not hypothetical. The first version of this file sent the section-value
# case below at the DEMO vendor, expecting a refusal, on the reasoning that a section
# whose value is a string must be malformed. It is not refused — validation checks
# SECTION NAMES and the entries beneath them are free-form by design — so the script
# answered 200 and replaced vendor 1's eleven-section blob with
# `((…::INVOICE-PRINT-SETTINGS . "undefined"))`. Aimed at an absent row-id the same
# request is a harmless 404. Rule to keep: NEVER point a probe at the demo vendor.
section "3. the PUT contract — routing and refusal (no writes)"

# Routing failures: the URL, not the payload, is wrong, so these cannot reach a row.
# They too are aimed at the ABSENT row-id so that ONE GREP PROVES THE SAFETY PROPERTY:
# every line naming the demo vendor is a GET (or the variable's own definition).
req GET "$(SETTINGS_PATH "$ABSENT_VENDOR")"
expect "GET on the settings path → no_such_endpoint" 404 "\"no_such_endpoint\""
req POST "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' -d '{}'
expect "POST on the settings path → no_such_endpoint" 404 "\"no_such_endpoint\""
req PUT "/hhub/api/v1/vendor/profile/$ABSENT_VENDOR/no-such-thing" \
    -H 'Content-Type: application/json' -d '{}'
expect "PUT on an unbound sub-path → no_such_endpoint" 404 "\"no_such_endpoint\""

# A non-object body is refused by the TRANSPORT, before the domain sees it, and it
# is the one refusal whose message is precise (apidefs2: 'the request body must be
# a JSON object'). The verb itself accepts a string, but that path is unreachable
# over HTTP — which is why this suite cannot round-trip (see the header).
req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' -d '"a string"'
expect "PUT with a JSON string body → 400" 400 "\"invalid_request\""

req PUT "$(SETTINGS_PATH "$CROSS_TENANT_VENDOR")" -H 'Content-Type: application/json' \
    -d "{\"invoice-print-settings\":{\"orientation\":\"portrait\"}}"
expect "PUT another tenant's vendor → 404 (BOLA)" 404 "\"not_found\""
req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' \
    -d "{\"invoice-print-settings\":{\"orientation\":\"portrait\"}}"
expect "PUT absent vendor id → 404 (a WELL-FORMED payload)" 404 "\"not_found\""
req PUT "$(SETTINGS_PATH abc)" -H 'Content-Type: application/json' \
    -d "{\"invoice-print-settings\":{\"orientation\":\"portrait\"}}"
expect "PUT non-numeric id → 404 (not 500)" 404 "\"not_found\""

# --- the KNOWN 4xx-taxonomy paths (K1), and one design boundary -------------
# Aimed at the ABSENT row-id like everything else in this section. These payloads are
# REFUSED before the row lookup, so the answer does not depend on which row-id is in
# the URL — and if one of them were ever ACCEPTED, an absent row-id turns the write
# into a 404 instead of a silent overwrite.
req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' \
    -d '{"no-such-section":{"a":1}}'
expect-known "PUT with an unknown section → 400" 400 "" \
  "KNOWN K1: vendor-settings-rejected names the section and lists the valid ones, but the classifier maps every condition to 500 internal_error, so the client learns nothing."

req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' -d '{}'
expect-known "PUT with an empty object → 400" 400 "" \
  "KNOWN K1: 'no :settings payload was supplied' is a precise client error; the wire says 500 internal_error."

req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")"
expect-known "PUT with no body at all → 400" 400 "" \
  "KNOWN K1: same refusal, same generic 500. A PUT with no body is legal HTTP and the transport explicitly tolerates it (api-request-body-params returns NIL), so the 400 belongs here."

# THE DESIGN BOUNDARY, asserted rather than assumed. Validation checks SECTION NAMES;
# the entries beneath a section are FREE-FORM, deliberately, so that a section gaining
# a field does not require a validator change. The consequence is that a section whose
# value is a string is ACCEPTED and reaches the row lookup. Stated here because this
# is exactly the request that destroyed the demo vendor's blob the first time this
# script ran: aimed at a real row it is a silent overwrite, not a refusal.
req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' \
    -d '{"invoice-print-settings":"undefined"}'
expect "a section-valued STRING is ACCEPTED (entries are free-form) → 404" 404 "\"not_found\""

# ── 5. anti-collapse: the states must be DISTINCT ───────────────────────────
section "4. anti-collapse"
req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' -d '{}'
C_REFUSED="$HTTP_CODE"
req PUT "$(SETTINGS_PATH "$CROSS_TENANT_VENDOR")" -H 'Content-Type: application/json' \
    -d "{\"invoice-print-settings\":{\"orientation\":\"portrait\"}}"
C_MISSING="$HTTP_CODE"
req PUT "$(SETTINGS_PATH "$ABSENT_VENDOR")" -H 'Content-Type: application/json' -d '"s"'
C_BADBODY="$HTTP_CODE"
if [ "$C_REFUSED" != "$C_MISSING" ] || [ "$C_BADBODY" != "$C_REFUSED" ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-46s %s / %s / %s\n' "$G" "$N" \
         "'a bad payload' ≠ 'no such vendor' ≠ 'bad body'" "$C_REFUSED" "$C_MISSING" "$C_BADBODY"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s all three answered %s\n' "$R" "$N" \
         "'a bad payload' ≠ 'no such vendor' ≠ 'bad body'" "$C_REFUSED"
fi

# ── 6. writes (opt-in) ──────────────────────────────────────────────────────
if [ "$WRITE" = 1 ]; then
  section "5. replace / restore  (WRITES TO THE LIVE DATABASE)"

  if ! sql "SELECT 1" >/dev/null 2>&1 || [ -z "$(sql "SELECT 1")" ]; then
    printf '  %sFATAL%s no SQL access (%s@%s), so the restore cannot be guaranteed.\n' \
           "$R" "$N" "$NS_MYSQL_USER" "$NS_DB"
    printf '        REFUSING TO WRITE.\n'
    printf '        %sTHE CONSTRAINT IS THE HOST, NOT THE CREDENTIALS.%s MySQL binds\n' "$Y" "$N"
    printf '        127.0.0.1 only (/etc/mysql/mysql.conf.d/mysqld.cnf:31), so from a\n'
    printf '        workstation the restore is impossible and NO NS_MYSQL_* value changes\n'
    printf '        that — setting them is not the fix. A missing mysql client and a\n'
    printf '        refused connection both land here.\n'
    printf '        THE SUPPORTED WAY TO EXERCISE THE WRITE IS ON THE SERVER, where mysql\n'
    printf '        is local. Sections 1-4 are read-only and run anywhere, which is what a\n'
    printf '        workstation should use.\n'
    printf '        THERE IS NO SQL-FREE RESTORE because the read is a Lisp string and the\n'
    printf '        write demands a JSON object (K3) — see the header.\n'
    exit 2
  fi

  TARGET_MD5="$(sql "SELECT MD5(INVOICE_SETTINGS) FROM DOD_VEND_PROFILE WHERE ROW_ID=$TARGET_VENDOR")"
  DONOR_MD5="$(sql "SELECT MD5(INVOICE_SETTINGS) FROM DOD_VEND_PROFILE WHERE ROW_ID=$DONOR_VENDOR")"
  TARGET_LEN="$(sql "SELECT CHAR_LENGTH(INVOICE_SETTINGS) FROM DOD_VEND_PROFILE WHERE ROW_ID=$TARGET_VENDOR")"
  info "target $TARGET_VENDOR blob" "${TARGET_LEN:-?} chars, md5 ${TARGET_MD5:0:12}…"
  info "donor  $DONOR_VENDOR blob" "md5 ${DONOR_MD5:0:12}…"

  if [ -z "$TARGET_MD5" ] || [ "$TARGET_MD5" != "$DONOR_MD5" ]; then
    printf '\n  %sFATAL%s the target and the donor are NOT byte-identical, so copying the\n' "$R" "$N"
    printf '        donor back would not be a restore. REFUSING to write.\n'
    printf '        Pick a pair from: mysql %s -e "SELECT ROW_ID FROM DOD_VEND_PROFILE\n' "$NS_DB"
    printf '        WHERE INVOICE_SETTINGS = (SELECT INVOICE_SETTINGS FROM DOD_VEND_PROFILE\n'
    printf '        WHERE ROW_ID=%s);"\n' "$DONOR_VENDOR"
    exit 2
  fi

  # A representative slice of the other columns, so a copier that damages a NULL on
  # its way through the row is caught rather than discovered months later. The GST
  # block is the nullable-heavy part and therefore the informative one.
  ROW_SIG="MD5(CONCAT_WS('|', NAME, PHONE, GSTNUMBER, LEGAL_NAME, PAN_NUMBER,
           GST_STATE_CODE, GST_REGISTRATION_TYPE, APPROVAL_STATUS, APPROVED_FLAG,
           ACTIVE_FLAG, SHIPPING_ENABLED, DELETED_STATE, TENANT_ID))"
  ROW_SIG_BEFORE="$(sql "SELECT $ROW_SIG FROM DOD_VEND_PROFILE WHERE ROW_ID=$TARGET_VENDOR")"

  # The restore function and its trap are already installed (see the plumbing
  # section) — this block only supplies what it needs: DONOR_VENDOR and TARGET_MD5
  # are set above, and RESTORE_NEEDED is flipped immediately before the first write.

  # --- the validated endpoint: a two-section object --------------------------
  RESTORE_NEEDED=1
  req PUT "$(SETTINGS_PATH "$TARGET_VENDOR")" -H 'Content-Type: application/json' \
      -d '{"invoice-print-settings":{"orientation":"landscape","fontsize":"11"},
           "invoice-general-settings":{"default-currency":"INR"}}'
  expect "PUT a two-section object → 200 + entity" 200 "\"rowId\""

  if [ "$HTTP_CODE" = 200 ]; then
    # The response is the updated vendor profile, so the blob comes back canonical —
    # the section symbol is the assertion that matters, exactly as in section 2.
    if grep -qF 'COM.NSTORES.APP::INVOICE-PRINT-SETTINGS' "$BODY" \
       && grep -qF 'COM.NSTORES.APP::INVOICE-GENERAL-SETTINGS' "$BODY"; then
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s both sections canonical\n' "$G" "$N" "response blob is canonical"
    else
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s sections are not canonical symbols\n' "$R" "$N" "response blob is canonical"
      printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
    fi
    if grep -qF 'landscape' "$BODY" && grep -qF 'INR' "$BODY"; then
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s both values present\n' "$G" "$N" "values survived the write"
    else
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s a value was lost\n' "$R" "$N" "values survived the write"
    fi
  fi

  # The stored column, read from the DATABASE rather than from the response.
  STORED_LEN="$(sql "SELECT CHAR_LENGTH(INVOICE_SETTINGS) FROM DOD_VEND_PROFILE WHERE ROW_ID=$TARGET_VENDOR")"
  check "the COLUMN holds the new, much shorter blob" "$([ -n "$STORED_LEN" ] && [ "$STORED_LEN" != "$TARGET_LEN" ] && echo changed || echo unchanged)" "changed"
  info "stored blob" "$STORED_LEN chars (was $TARGET_LEN)"

  row_sig_after_write="$(sql "SELECT $ROW_SIG FROM DOD_VEND_PROFILE WHERE ROW_ID=$TARGET_VENDOR")"
  check "no OTHER column of the row changed" \
        "$([ "$row_sig_after_write" = "$ROW_SIG_BEFORE" ] && echo intact || echo DAMAGED)" "intact"

  # --- the section allowlist, POSITIVE case ----------------------------------
  # The negative case (an unknown section is refused) is in section 3 and needs no
  # write. The positive one cannot be asserted without writing, which is why it lives
  # here: the allowlist is DERIVED from the shipped *invoice-settings*, so a section
  # that ships is legal for a vendor the moment it ships.
  req PUT "$(SETTINGS_PATH "$TARGET_VENDOR")" -H 'Content-Type: application/json' \
      -d '{"invoice-pdf-settings":{"optimize-pdf-for-size":false}}'
  expect "a shipped section, alone → 200" 200 "\"rowId\""

  # --- K2: the generic PUT is still an unvalidated second door ----------------
  req PUT "/hhub/api/v1/vendor/profile/$TARGET_VENDOR" -H 'Content-Type: application/json' \
      -d '{"invoiceSettings":"((COM.NSTORES.APP::NO-SUCH-SECTION (:A . 1)))"}'
  K2_ACCEPTED="$(sql "SELECT CHAR_LENGTH(INVOICE_SETTINGS) FROM DOD_VEND_PROFILE WHERE ROW_ID=$TARGET_VENDOR")"
  expect-known "generic PUT accepts invoiceSettings → 400" 400 "" \
    "KNOWN K2: PUT /vendor/profile/{id} wrote the blob through !update with no validation at all. Measured: it was replaced by $K2_ACCEPTED characters of ((COM.NSTORES.APP::NO-SUCH-SECTION (:A . 1))). Until phase 2 removes :invoice-settings from !update, this endpoint is NOT the only way in."

  # The trap restores and verifies; nothing to do here but say so.
  printf '\n  the blob is restored on EXIT (including on failure), inside MySQL, verified by md5.\n'
else
  section "5. replace / restore"
  printf '  SKIPPED — read-only run. Re-run with --write to exercise them.\n'
  printf '  (They replace the blob of vendor %s in the live database and restore it from\n' "$TARGET_VENDOR"
  printf '   vendor %s, which must hold a byte-identical blob first.)\n' "$DONOR_VENDOR"
fi

# ── summary ─────────────────────────────────────────────────────────────────
printf '\n─────────────────────────────────────────────\n'
printf 'passed %s   failed %s   known-defects %s   skipped %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
if [ "$FAIL" -gt 0 ]; then
  printf '\nfailed checks are UNEXPECTED (not in the known-defect list). Server detail:\n'
  printf '  tail -40 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
  printf 'REMEMBER: sentinel-derived responses (404/409/503) leave NO trace in that log —\n'
  printf 'only CONDITION-derived failures are recorded.\n'
  exit 1
fi
if [ "$KNOWN" -gt 0 ]; then
  printf '\nThe %s known defect(s) above are encoded deliberately — see the header.\n' "$KNOWN"
  printf 'K2 is the one to fix first: until it is, a client can still write this column\n'
  printf 'with no validation at all, so this endpoint guarantees nothing on its own.\n'
fi
printf 'no unexpected failures\n'
exit 0
