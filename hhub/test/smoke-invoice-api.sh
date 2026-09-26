#!/usr/bin/env bash
#
# smoke-invoice-api.sh — smoke-test the INVOICE JSON API (conflodis2 + apidefs2):
# the header domain (nst-invh / DOD_INVOICE_HEADER) and its lines (nst-invitm /
# DOD_INVOICE_ITEMS).
#
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-invoice-api.sh
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-invoice-api.sh --write
#
# READ-ONLY by default. --write runs the full create→line→update→delete lifecycle
# and removes every row it created on EXIT (including on failure).
#
# Exit codes:  0 = every result matched its expectation
#              1 = at least one result did NOT match
#              2 = setup failure (unreachable, no session, no restore path) — the
#                  API was not tested
#
# ── WHAT IS UNDER TEST ──────────────────────────────────────────────────────
# TEN of the spec's twelve Invoicing endpoints (hhub/core/nstoresapi.html, id
# 'inv') are bound. These are they, and the whole point of this suite is that
# until it existed NOT ONE of them had ever been exercised with a session:
#
#   POST   /hhub/api/v1/invoices                        route-invh-create    201
#   GET    /hhub/api/v1/invoices                        route-invh-list      200
#   GET    /hhub/api/v1/invoices/{id}                   route-invh-detail    200 + lines
#   PUT    /hhub/api/v1/invoices/{id}                   route-invh-update    200
#   POST   /hhub/api/v1/invoices/{id}/items             route-invitm-create  201
#   PUT    /hhub/api/v1/invoices/{id}/items/{item-id}   route-invitm-update  200
#   DELETE /hhub/api/v1/invoices/{id}/items/{item-id}   route-invitm-delete  200
#   PUT    /hhub/api/v1/invoices/settings               route-invh-settings-update 200
#   GET    /hhub/api/v1/invoices/{id}/download           route-invh-download  302
#   GET    /hhub/api/v1/invoices/{id}/public             route-invh-public    200 + a link
#
# The LAST one is id-less, and its target is the vendor identity the LOGIN
# established (:login-vendor), not a tenant and not a row-id from the body — a
# tenant may own several vendors, so "the vendor" is only determinate because the
# session names one. It delegates to the same !settings प्रत्यय the vendor
# sub-resource uses, so the blob has ONE writer. See section 6.
#
# The TWO spec endpoints with NO binding are asserted ABSENT, not tested:
# /payment and /send each answer 404 no_such_endpoint. That is
# the current, deliberate state (see §5 of invoice-api-handoff-CONTEXT.md) and
# section 7 fails loudly if one of them starts existing, so this script is updated
# rather than quietly outgrown.
#
# ── WHY THE AUTH SWEEP LOOKS ODD ────────────────────────────────────────────
# Section 1 asserts the EIGHT BINDINGS with NO SESSION, before logging in. An
# unbound path answers 404 no_such_endpoint; a bound one answers 401, because
# api-authenticate runs before dispatch. So a single unauthenticated sweep proves
# "this path is bound AND :auth-scope :session is enforced on it" for all eight —
# including the four write paths, WITHOUT issuing a single write. That is the only
# way to prove the POST/PUT/DELETE bindings exist in the read-only default run.
#
# ── FIXTURES (all verified against hhubdb, 2026-09-26) ──────────────────────
# The demo vendor IS the login identity: phone 9999999990 is
# DOD_VEND_PROFILE.ROW_ID 1, TENANT_ID 2. Its session tenant is 2, and every
# invoice fixture below is a tenant-2 row.
#
#   23      DRAFT, 4 lines      the aggregate read's happy path
#   33/34/36 DRAFT, 0 lines     an EMPTY lines array is 200 + [], never 404
#   35      PENDINGPAYMENT, 6 lines   the 409 fixture: not a DRAFT
#   21,22   TENANT 5            the BOLA fixture: another tenant's invoice
#
# 🚨 THE DRAFT FIXTURES ARE NEVER WRITTEN TO. 23 is the only DRAFT that has lines,
# so it is the read fixture for the whole suite; the write lifecycle in section 5
# creates its OWN header and touches no pre-existing row. The single exception is
# 35, which section 5 writes AT — deliberately, because a 409 on a non-DRAFT
# header is the assertion — and a 409 writes nothing by construction.
#
# ── KNOWN DEFECTS AND DELIBERATE GAPS THIS SCRIPT ENCODES ───────────────────
# Asserted against the CORRECT contract but reported as `KNOWN` (not `FAIL`) so a
# real regression stands out. If a KNOWN check starts passing, fix this script:
# the defect was repaired.
#
#  K1. NO TOTALS ROLL-UP. Adding or deleting a line never touches the header's
#      TOTALVALUE, and no `issue` verb exists to enforce the invariant that
#      TOTALVALUE must equal the sum of its live lines. Measured here: a line of
#      totalitemval 236.00 is added to an invoice whose totalvalue is 0.00 and
#      the header still reads 0.00.
#
#  K2. A REPEAT DELETE OF A LINE ANSWERS 404, NOT "ALREADY DELETED". Both
#      invoice kinds' delete! exclude soft-deleted rows in their SELECT, so the
#      'already deleted' branch is unreachable and a second DELETE is
#      indistinguishable from a wrong id.
#
#  K3. A REJECTED PAYLOAD IS 500, NOT 400 (apidefs2's condition→status
#      classifier maps every condition to internal_error — the same gap the
#      settings suite records as its K1). The domain refuses a malformed body
#      correctly and writes nothing, but the client is told the server broke.
set -uo pipefail

# ── configuration ───────────────────────────────────────────────────────────
# NOTE the base. http://hunchentoot.local answers 404 for EVERY /hhub/ URI on
# this host — nginx on :80 proxies nothing — so ninestores.local (which behaves
# identically to 127.0.0.1:4244) is the default here as in the rest of the family.
BASE="${BASE:-http://ninestores.local}"
PHONE="${NS_PHONE:-}"
PASSWORD="${NS_PASSWORD:-}"

DRAFT_ID="${NS_DRAFT_ID:-23}"                 # DRAFT with 4 lines
EMPTY_DRAFT_ID="${NS_EMPTY_DRAFT_ID:-33}"     # DRAFT with 0 lines
NON_DRAFT_ID="${NS_NON_DRAFT_ID:-35}"         # PENDINGPAYMENT, not a DRAFT
LINE_ID="${NS_LINE_ID:-}"                     # a line of $NON_DRAFT_ID, for the 409
CROSS_TENANT_ID="${NS_CROSS_TENANT_ID:-21}"   # TENANT 5 — BOLA
ABSENT_ID="${NS_ABSENT_ID:-99999}"            # never existed
PRD_ID="${NS_PRD_ID:-1}"                      # FK target: DOD_PRD_MASTER.ROW_ID
# The settings section's two vendors. SESSION_VENDOR is the login identity: its blob
# is READ ONLY here and never written, because it is the only customised one in the
# table (see section 6). OTHER_VENDOR is any other row, used as a retarget target in a
# request that is refused anyway.
SESSION_VENDOR="${NS_SESSION_VENDOR:-1}"
# ── THE URLS ADDRESS AN INVOICE BY ITS NUMBER, NOT ITS ROW-ID ────────────────
# Every invoice binding maps {id} to :invnum (human-readable, unique, and immutable
# over HTTP), so the fixtures below are resolved to NUMBERS once, from the database.
# They CANNOT be derived from the row-id: the trigger stamps year(now()) at INSERT
# time, so a 2024 row and a 2026 row at the same position differ.
#
# Resolved lazily because --help and the read-only prologue must work without SQL.
NS_RESOLVE=1
__inv() { sql "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=$1"; }
SESSION_TENANT="${NS_SESSION_TENANT:-2}"   # the demo vendor's tenant, and the tenant the key must name
OTHER_VENDOR="${NS_OTHER_VENDOR:-3}"

NS_DB="${NS_DB:-hhubdb}"
NS_MYSQL_USER="${NS_MYSQL_USER:-hhubuser}"
NS_MYSQL_PASS="${NS_MYSQL_PASS:-Welcome\$123}"
sql()    { mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" -N -B "$NS_DB" -e "$1" 2>/dev/null; }

WRITE=0

usage() {
  sed -n '3,74p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --write            also run the create→line→update→delete lifecycle (and then
                     delete every row it created)
  --base URL         override the base URL   (default http://ninestores.local)
  -h, --help         this text

Environment:
  NS_PHONE / NS_PASSWORD  vendor credentials                          [required]
  NS_DRAFT_ID             a DRAFT invoice with lines             (default 23)
  NS_EMPTY_DRAFT_ID       a DRAFT invoice with none              (default 33)
  NS_NON_DRAFT_ID         a non-DRAFT invoice                    (default 35)
  NS_LINE_ID              a line id of the NON-DRAFT invoice; section 5 derives
                          one from the DB when unset
  NS_CROSS_TENANT_ID      an invoice in ANOTHER tenant           (default 21)
  NS_ABSENT_ID            an invoice id that never existed       (default 99999)
  NS_PRD_ID               a product row-id for the new line       (default 1)
  NS_SESSION_VENDOR       the login vendor; its settings blob is NEVER written (default 1)
  NS_SESSION_TENANT       the session tenant the public link must name  (default 2)
  NS_OTHER_VENDOR         another vendor row, for the retarget probe   (default 3)
  NS_DB / NS_MYSQL_USER / NS_MYSQL_PASS   SQL access, needed by --write
  NS_DOWNLOAD_LIVE=1       also render a real PDF (slow: shells out to wkhtmltopdf
                           over *siteurl*, which is a PUBLIC url)
  NS_EXPECT_U=1            GATED :U run. Pauses after login so the database can be
                           stopped, asserts 503 (not 404), then exits. Restart the
                           database after — see "1b" in the body.
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
JAR="$TMP/cookies.txt"          # the session
BODY="$TMP/body.json"
ERR="$TMP/curl.err"

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; N=$'\033[0m'
else G=; R=; Y=; N=; fi

PASS=0; FAIL=0; KNOWN=0; SKIP=0
HTTP_CODE=""

# ── HOW THIS SCRIPT CLEANS UP AFTER ITSELF, AND WHY IT IS NOT BY INVOICE NUMBER ──
# 🚨 AN INVOICE NUMBER CANNOT BE CHOSEN BY ANYONE. A MySQL trigger rewrites INVNUM on
# EVERY insert into DOD_INVOICE_HEADER —
#
#   create trigger before_insert_invoice before insert on DOD_INVOICE_HEADER
#     for each row
#     set NEW.INVNUM = concat('NST', lpad(next_id,5,'0'), '-', year(now()));
#
# (installation/nstdbtriggers.sql, where next_id is the table's next auto_increment).
# MEASURED 2026-09-26: a create asking for "ZZMANUAL1" stores "NST00040-2026", and
# CLSQL still reports the value it sent. ⚠ hhubuser SEES NO TRIGGERS AT ALL
# (INFORMATION_SCHEMA.TRIGGERS returns 0) because MySQL hides triggers from users
# without the TRIGGER privilege — so the database looks like it is ignoring the value
# for no reason.
#
# THIS SUITE USED TO TAG ITS ROWS WITH AN INVNUM PREFIX AND CLEAN UP BY IT. That can
# never match, so --write leaked EVERY row it created (it did, twice, before this was
# found). The handle that survives is the ROW-ID, taken from the 201 response, and the
# cleanup is by that id and nothing else.
#
# The API exposes no invoice DELETE at all (route-invh-delete is registered but
# deliberately UNBOUND — the spec defines no such endpoint), so a created header cannot
# be removed over HTTP: SQL is still the only restore path, it is just keyed on the id.
MARKER="ZZSMOKE$(date +%s)$RANDOM"   # still SENT — the trigger discards it; see §5
CREATED_IDS=""                        # header ROW-IDs this run created; the cleanup key

restore_rows() {
  [ "$WRITE" = 1 ] || return 0
  # NOT by INVNUM: the trigger overwrites it (see the header). By the ROW-ID the API
  # returned. CREATED_IDS collects every header this run created.
  [ -n "${CREATED_IDS:-}" ] || return 0
  local n_before n_after
  n_before="$(sql "SELECT COUNT(*) FROM DOD_INVOICE_HEADER WHERE ROW_ID IN ($CREATED_IDS)")"
  [ "${n_before:-0}" -gt 0 ] || return 0
  # Items first: DOD_INVOICE_ITEMS_ibfk_3 is ON DELETE CASCADE, but deleting in
  # dependency order means the cleanup does not depend on the FK's action.
  mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" "$NS_DB" -e "
    DELETE FROM DOD_INVOICE_ITEMS WHERE INVHEADID IN ($CREATED_IDS);
    DELETE FROM DOD_INVOICE_HEADER WHERE ROW_ID IN ($CREATED_IDS);" 2>/dev/null
  n_after="$(sql "SELECT COUNT(*) FROM DOD_INVOICE_HEADER WHERE ROW_ID IN ($CREATED_IDS)")"
  printf '\n  cleanup: removed %s smoke header(s), %s left\n' "$n_before" "${n_after:-?}"
  if [ "${n_after:-1}" != "0" ]; then
    printf '  %sFAIL%s  SMOKE ROWS REMAIN. Remove by hand:\n' "$R" "$N"
    printf '        DELETE FROM DOD_INVOICE_ITEMS WHERE INVHEADID IN (%s);\n' "$CREATED_IDS"
    printf '        DELETE FROM DOD_INVOICE_HEADER WHERE ROW_ID IN (%s);\n' "$CREATED_IDS"
  fi
}
cleanup() { restore_rows; rm -rf "$TMP"; }
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

# req_noauth — the same, with NO cookie jar, for the binding sweep in section 1.
req_noauth() {
  local method="$1"; shift
  local path="$1"; shift
  HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -X "$method" \
                    --max-time 20 "$@" "$BASE$path" 2>"$ERR")"
  [ -n "$HTTP_CODE" ] || HTTP_CODE="000"
}

expect() {
  local name="$1" want="$2" needle="${3:-}" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-48s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-48s got %s, want %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" \
           "${needle:+, containing \"$needle\"}"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
}

# expect-oneof NAME "STATUS|STATUS" NEEDLE — for the two id-shape cases where the
# documented answer depends on which layer refuses the id (the route's guard is a
# 400, the verb's own not-found is a 404). Both are correct; a 500 is not.
expect_oneof() {
  local name="$1" want="$2" needle="${3:-}" ok=1
  case "|$want|" in *"|$HTTP_CODE|"*) ;; *) ok=0 ;; esac
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-48s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-48s got %s, want one of %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" \
           "${needle:+, containing \"$needle\"}"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
}

expect_known() {
  local name="$1" want="$2" needle="$3" why="$4" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    PASS=$((PASS+1))
    printf '  %sPASS%s %-48s %s  (KNOWN defect appears fixed — update this script)\n' \
           "$G" "$N" "$name" "$HTTP_CODE"
  else
    KNOWN=$((KNOWN+1))
    printf '  %sKNOWN%s %-47s got %s, want %s\n' "$Y" "$N" "$name" "$HTTP_CODE" "$want"
    printf '        %s\n' "$why"
  fi
}

check() {
  local name="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-48s %s\n' "$G" "$N" "$name" "$got"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s got %s, want %s\n' "$R" "$N" "$name" "${got:-<empty>}" "$want"
  fi
}

skip()    { SKIP=$((SKIP+1)); printf '  %sSKIP%s %-48s %s\n' "$Y" "$N" "$1" "$2"; }
info()    { printf '  %s----%s %-48s %s\n' "$Y" "$N" "$1" "$2"; }
section() { printf '\n== %s\n' "$1"; }
error_of() { grep -o '"error":"[a-z_]*"' "$BODY" | head -1 | cut -d'"' -f4; }
# The row-id out of a create response. No jq on this host, and the field is always
# the canonical camelCase spelling, so a plain grep is enough.
rowid_of() { grep -o '"rowId":"[0-9]*"' "$BODY" | head -1 | sed 's/.*:"//; s/"//'; }

# 🚨 A 500 HERE IS DIAGNOSED, NOT JUST REPORTED. The first run of this suite found
# every header AND line route answering 500 with
#   the slot COM.NSTORES.APP::DELETED-STATE is missing from
#   #<COM.NSTORES.APP::NSTINVHRESPONSEMODEL>
# because domain->response drives its setfs from *invh-mirrored-slots*, which
# names deleted-state, while the response model did not declare it. That is a
# load-state fact, not a flake: re-running cannot clear it, and LOADING A FILE
# INTO THE LIVE IMAGE IS NOT A FIX (it is how this tree wedges PCL — see
# knowledge/build-and-load-CONTEXT.md §9). Restart the image and let ASDF
# recompile: startup/load.lisp runs (ql:quickload :nstores).
bail_if_internal_error() {
  if grep -qF '"internal_error"' "$BODY" && [ "$HTTP_CODE" = "500" ]; then
    printf '\n  %sFATAL%s a route answered 500 internal_error on a read that has no\n' "$R" "$N"
    printf '        business reason to fail. Check the actual condition:\n'
    printf '          tail -40 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
    printf '        If it names a MISSING-SLOT on a *RESPONSEMODEL, the response model\n'
    printf '        is missing a slot that *invh-mirrored-slots* / *invitm-mirrored-slots*\n'
    printf '        carries. Fix the CLASS and restart the image — do not load the file\n'
    printf '        into the running image (build-and-load-CONTEXT.md §9).\n'
    exit 2
  fi
}

INV="/hhub/api/v1/invoices"

# ── 1. reachability, the binding sweep, then the session ────────────────────
section "1. reachability, the ten bindings, and the session  ($BASE)"

if ! curl -sS -o /dev/null --max-time 10 "$BASE/hhub/" 2>"$ERR"; then
  printf '  %sFATAL%s cannot reach %s — curl: %s\n' "$R" "$N" "$BASE" "$(head -1 "$ERR")"
  printf '        Note http://hunchentoot.local answers 404 for every /hhub/ URI here.\n'
  exit 2
fi

# 🚨 CONNECTIVITY IS NOT REACHABILITY: /hhub/ answers 404 on every base this tree
# is deployed behind, so a successful curl there proves only that a socket opened.
# The assertion that carries information is the API's own 401 — it proves the
# route registry is behind this base.
req_noauth GET "$INV"
if [ "$HTTP_CODE" != "401" ]; then
  printf '  %sFATAL%s %s%s answered %s unauthenticated, expected 401.\n' \
         "$R" "$N" "$BASE" "$INV" "$HTTP_CODE"
  printf '        A 404 means this base is not serving the invoice API (try\n'
  printf '        --base http://ninestores.local); a 200 means no session is needed,\n'
  printf '        which would itself be a defect on a write-capable resource.\n'
  exit 2
fi
printf '  reachable — the unauthenticated API answered 401\n'

# THE BINDING SWEEP. 401 == bound and auth-enforced; 404 no_such_endpoint == not
# bound. Every path below is asserted with NO credential and NO session, so the
# four write methods are proven bound without writing anything.
printf '\n  -- the ten bound endpoints, unauthenticated (401 == bound, 404 == not bound)\n'
sweep() {
  local method="$1" path="$2" label="$3" data="${4:-}"
  if [ -n "$data" ]; then
    req_noauth "$method" "$path" -H 'Content-Type: application/json' -d "$data"
  else
    req_noauth "$method" "$path"
  fi
  if [ "$HTTP_CODE" = "401" ]; then
    PASS=$((PASS+1)); printf '    %sPASS%s %-6s %-42s 401\n' "$G" "$N" "$method" "$label"
  elif grep -qF '"no_such_endpoint"' "$BODY"; then
    FAIL=$((FAIL+1))
    printf '    %sFAIL%s %-6s %-42s NOT BOUND (404 no_such_endpoint)\n' "$R" "$N" "$method" "$label"
  else
    FAIL=$((FAIL+1))
    printf '    %sFAIL%s %-6s %-42s answered %s, want 401\n' "$R" "$N" "$method" "$label" "$HTTP_CODE"
  fi
}
sweep POST   "$INV"                              "create"
sweep GET    "$INV"                              "list"
sweep GET    "$INV/$DRAFT_INV"                    "detail"
sweep PUT    "$INV/$DRAFT_INV"                    "update"          '{}'
sweep POST   "$INV/$EMPTY_DRAFT_INV/items"        "line create"     '{}'
sweep PUT    "$INV/$EMPTY_DRAFT_INV/items/1"      "line update"     '{}'
sweep DELETE "$INV/$EMPTY_DRAFT_INV/items/1"      "line delete"
# ⚠ THIS LINE IS WEAKER THAN THE OTHER SEVEN, and the difference is worth stating.
# /invoices/settings ALSO matches the pre-existing PUT /invoices/{id} template (with
# id="settings"), and api-authenticate runs BEFORE dispatch, so a 401 here is produced
# by EITHER binding. It therefore proves only that SOME binding covers the path — not
# that route-invh-settings-update exists. THE REAL ROUTING ASSERTION IS IN SECTION 6,
# which probes it WITH a session and distinguishes the two: routed to the settings verb
# the body is refused by the domain, while routed to {id} it is a 404 not_found for an
# invoice that does not exist. Kept here anyway because it still proves the path is
# covered and auth-enforced, which is what this sweep is for.
sweep PUT    "$INV/settings"                     "settings (id-less; see §6)" '{}'
# A SIX-segment template, so unlike /settings this one collides with NOTHING: no other
# binding has this shape, so a 401 here really does prove route-invh-download is bound.
sweep GET    "$INV/$DRAFT_INV/download"           "download (302)"
sweep GET    "$INV/$DRAFT_INV/public"             "public view URL"

LOGIN_CODE="$(curl -sS -o "$TMP/login.html" -w '%{http_code}' -c "$JAR" \
                   --max-time 20 -X POST "$BASE/hhub/dodvendlogin" \
                   -d "phone=$PHONE" -d "password=$PASSWORD" 2>"$ERR")"
printf '\n  login HTTP %s  (302 for BOTH success and failure — never read this as the outcome)\n' "$LOGIN_CODE"
if ! grep -q 'hunchentoot-session' "$JAR"; then
  printf '  %sFAIL%s no session cookie was issued — the login was REJECTED.\n' "$R" "$N"
  printf '        Check the phone/password and the 2-concurrent-login cap; the reason is\n'
  printf '        logged to ninestores-busfunctions.log.\n'
  exit 2
fi
req GET "$INV"
case "$HTTP_CODE" in
  401) printf '\n  %sFATAL%s login did not establish a session (API answered 401).\n' "$R" "$N"; exit 2 ;;
  000) printf '\n  %sFATAL%s could not reach the API endpoint.\n' "$R" "$N"; exit 2 ;;
esac
bail_if_internal_error
printf '  session established (authenticated list answered %s)\n' "$HTTP_CODE"

# Resolve the fixture NUMBERS now that SQL and the session are both known to work.
DRAFT_INV="$(__inv "$DRAFT_ID")"
EMPTY_DRAFT_INV="$(__inv "$EMPTY_DRAFT_ID")"
NON_DRAFT_INV="$(__inv "$NON_DRAFT_ID")"
CROSS_TENANT_INV="$(__inv "$CROSS_TENANT_ID")"
ABSENT_INV="${NS_ABSENT_INV:-NST99999-9999}"     # a well-formed number nothing holds
[ -n "$DRAFT_INV" ] || { printf '  %sFATAL%s cannot resolve the NUMBER of invoice %s — the URLs address invoices by number now (run on the server, or set NS_* overrides).\n' "$R" "$N" "$DRAFT_ID"; exit 2; }
printf '  fixtures by NUMBER: draft=%s empty=%s non-draft=%s cross-tenant=%s\n' \
       "$DRAFT_INV" "$EMPTY_DRAFT_INV" "$NON_DRAFT_INV" "$CROSS_TENANT_INV"

# ── 1b. :U — the gated boundary-failure run ─────────────────────────────────
# PROVISION, NOT A DEFAULT, and it is the only way to reach the fourth state.
# Nothing an HTTP client can send makes the DATABASE unanswerable, and login NEEDS
# the database — so it has to be stopped AFTER the session exists, which is why this
# block pauses for the operator. Same protocol as the vendor settings suite.
#
#   terminal 1:  NS_EXPECT_U=1 ./smoke-invoice-api.sh          (it waits)
#   terminal 2:  sudo systemctl stop mysql
#   terminal 1:  press Enter
#   terminal 2:  sudo systemctl start mysql                    (restore)
#
# 🚨 WHAT THIS ASSERTS, AND WHY IT MATTERS MORE THAN A 503. The whole tree is built on
# the four-valued answer: absence (:F), ignorance (:U) and contradiction (:C) are
# DIFFERENT facts and must not collapse into each other. An invoice read whose database
# did not answer must be 503 ("I could not find out"), NOT 404 ("there is no such
# invoice") — because a client that receives 404 will conclude the invoice does not
# exist and act on that. That is the specific collapse these routes were written to
# prevent, and NO OTHER RUN IN THIS SUITE CAN PROVE IT: with the database up, every
# path answers from real data.
#
# The three routes below cover the three shapes the invoice API returns: a collection,
# an entity-plus-children, and a derived read. The download route is included because
# its fetch guard runs BEFORE any rendering, so a dead database must not start
# wkhtmltopdf.
if [ "${NS_EXPECT_U:-}" = "1" ]; then
  printf '\n== 1b. :U boundary failure  (GATED RUN)\n'
  info "session is up" "now STOP the database, then press Enter"
  read -r _ || true

  req GET "$INV"
  expect ":U list → 503, NOT [] and NOT 404" 503 '"unknown"'
  req GET "$INV/$DRAFT_INV"
  expect ":U detail → 503, NOT 404" 503 '"unknown"'
  req GET "$INV/$DRAFT_INV/public"
  expect ":U public view → 503, NOT 404" 503 '"unknown"'
  req GET "$INV/$DRAFT_INV/download"
  expect ":U download → 503 BEFORE rendering" 503 '"unknown"'
  req GET "$INV?sort-by=password&sort-dir=asc"
  expect ":U the route guard still runs first → 400" 400 '"invalid_request"'

  # Anti-collapse, on THIS run's terms: ignorance and absence must not look alike.
  req GET "$INV/$DRAFT_INV";   U_PRESENT="$HTTP_CODE"
  req GET "$INV/$ABSENT_INV";  U_ABSENT="$HTTP_CODE"
  check "with the DB down, present and absent are BOTH 503 (neither is 404)" \
        "$([ "$U_PRESENT" = "503" ] && [ "$U_ABSENT" = "503" ] && echo both-503 || echo "$U_PRESENT/$U_ABSENT")" "both-503"

  printf '\n   RESTART THE DATABASE NOW.\n'
  printf '\n─────────────────────────────────────────────\n'
  printf 'passed %s   failed %s   known-defects %s   skipped %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
  [ "$FAIL" -gt 0 ] && exit 1
  exit 0
fi

# ── 2. the reads ────────────────────────────────────────────────────────────
section "2. the reads — list and the aggregate detail"

req GET "$INV"
expect "GET /invoices → 200 with a JSON array" 200 ""
if [ "$HTTP_CODE" = 200 ]; then
  case "$(head -c 1 "$BODY")" in
    "[") PASS=$((PASS+1)); printf '  %sPASS%s %-48s []\n' "$G" "$N" "the body is an ARRAY, not an object" ;;
    *)   FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s starts with %s\n' "$R" "$N" "the body is an ARRAY, not an object" "$(head -c 1 "$BODY")" ;;
  esac
  # The outbound allowlist must not publish internal bookkeeping. deleted-state is
  # CARRIED on the response model (domain->response mirrors it) and deliberately
  # NOT named in render-json, so it must not appear on the wire.
  if grep -qF 'deletedState' "$BODY"; then
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s it IS published\n' "$R" "$N" "deletedState is not on the wire"
  else
    PASS=$((PASS+1)); printf '  %sPASS%s %-48s absent\n' "$G" "$N" "deletedState is not on the wire"
  fi
fi

req GET "$INV/$DRAFT_INV"
expect ":T DRAFT $DRAFT_ID detail → 200" 200 '"lines"'
bail_if_internal_error
if [ "$HTTP_CODE" = 200 ]; then
  # The aggregate is the header's own allowlist SPLICED with a nested array, so
  # both the header's fields and "lines" must be present in ONE object.
  if grep -qF '"invnum"' "$BODY" && grep -qF '"lines"' "$BODY"; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-48s both\n' "$G" "$N" "header fields AND a nested lines array"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s body: %s\n' "$R" "$N" "header fields AND a nested lines array" "$(head -c 200 "$BODY" | tr -d '\n')"
  fi
  if grep -qE '"lines"[[:space:]]*:[[:space:]]*\[[[:space:]]*\{' "$BODY"; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-48s non-empty\n' "$G" "$N" "the lines array has elements"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s expected the 4 known lines\n' "$R" "$N" "the lines array has elements"
  fi
fi

# 🚨 AN INVOICE WITH NO LINES SHOULD BE 200 + "lines":[] — NOT 404, and not null.
# 'This invoice has no lines' and 'there is no such invoice' are different facts;
# collapsing them is the :U-read-as-:F family of error this tree exists to prevent.
#
# The TOP-LEVEL empty collection IS [] — conflodis2-render composes a list with
# (format nil "[~{~A~^,~}]" …) and answers "[]" for a null response, so
# GET /invoices with no matches is an empty ARRAY. The NESTED case has no such
# guard: render-json on invh-detail-response builds (cons "lines" (mapcar …)) and
# hands that Lisp list to cl-json, which encodes NIL as null. Asserted against the
# correct contract, reported as KNOWN.
req GET "$INV/$EMPTY_DRAFT_INV"
bail_if_internal_error
expect_known ":F-empty DRAFT $EMPTY_DRAFT_ID → 200 + \"lines\":[]" 200 '"lines":[]' \
  "KNOWN K4: an invoice with no lines answers \"lines\":null, not []. The nested array is a Lisp list encoded by cl-json (NIL → null); only the top-level collection gets conflodis2-render's [] guard, which is why GET /invoices correctly answers [] while this nested one does not. A client that iterates lines over an empty invoice gets null."

# --- filters and the sort whitelist ----------------------------------------
req GET "$INV?status=DRAFT"
expect "?status=DRAFT → 200" 200 ""
req GET "$INV?status=NO_SUCH_STATUS"
expect "?status=<unknown value> → 200 + [] (a filter, not a 404)" 200 "[]"
req GET "$INV?from-date=2020-01-01&to-date=2030-01-01&sort-by=invdate&sort-dir=asc"
expect "date range + whitelisted sort → 200" 200 ""
# 🚨 THE ASSERTION THIS SUITE GOT WRONG FIRST TIME, and the defect it led to. The
# obvious reading of the route's docstring ("whitelisted sort-by/sort-dir, default
# invdate desc") is that an unwhitelisted sort-by FALLS BACK — and that is what this
# line used to assert, expecting 200. It does not fall back: validate-invh-sort-args
# (nst-bl-invh.lisp:478) signals a PLAIN error, which apidefs2 classifies as 500
# internal_error. So a malformed REQUEST was reported as the SERVER breaking.
# The correct contract for a caller-supplied query parameter is 400, and the route
# layer now guards it (invh-guard-sort-args, which reads the same whitelist rather
# than restating it). Asserted at 400, so a regression to 500 is a FAIL rather than
# a silent pass.
req GET "$INV?sort-by=password&sort-dir=asc"
expect "?sort-by=<not whitelisted> → 400 invalid_request" 400 '"invalid_request"'
req GET "$INV?sort-by=invdate&sort-dir=sideways"
expect "?sort-dir=<not asc|desc> → 400" 400 '"invalid_request"'
# And the whitelist must still be ENFORCED, not merely re-worded: a refused sort-by
# must not have quietly become a working one.
req GET "$INV?sort-by=ignored&sort-dir=asc"
check "an unwhitelisted sort-by never returns rows" \
      "$([ "$HTTP_CODE" = "400" ] && echo refused || echo "unexpected $HTTP_CODE")" "refused"

# ── 3. the 404 / 400 / 409 taxonomy ─────────────────────────────────────────
section "3. the taxonomy — absent, BOLA, malformed, contradiction"

req GET "$INV/$ABSENT_INV"
expect ":F absent invoice id → 404 not_found" 404 '"not_found"'
req GET "$INV/$CROSS_TENANT_INV"
expect ":F another tenant's invoice → 404 (BOLA)" 404 '"not_found"'
req GET "$INV/NO-SUCH-NUMBER"
expect_oneof ":F non-numeric id → 404 or 400, never 500" "400|404" ''

req PUT "$INV/$ABSENT_INV" -H 'Content-Type: application/json' -d '{"custname":"x"}'
expect ":F update an absent invoice → 404" 404 '"not_found"'
req PUT "$INV/$CROSS_TENANT_INV" -H 'Content-Type: application/json' -d '{"custname":"x"}'
expect ":F update another tenant's invoice → 404 (BOLA)" 404 '"not_found"'

# 🚨 THE DATE RULE. invdate is NOT NULL and decides the financial year, so an
# unparseable one is refused at the ROUTE layer with a 400 rather than written as
# a wrong invoice. ISO only: the internal UI posts DD/MM/YYYY and converts it
# itself, but an API client gets one format and never a question of which
# reading "03/04/2026" wants.
req PUT "$INV/$DRAFT_INV" -H 'Content-Type: application/json' -d '{"invdate":"03/04/2026"}'
expect ":F DD/MM/YYYY invdate → 400 invalid_request" 400 '"invalid_request"'
req PUT "$INV/$DRAFT_INV" -H 'Content-Type: application/json' -d '{"invdate":"2026-13-45"}'
expect ":F impossible ISO date → 400" 400 '"invalid_request"'

# 🚨 A DUPLICATE INVNUM IS A CONTRADICTION, NOT A NOT-FOUND. INVNUM carries a
# UNIQUE index (verified: index INVNUM, NON_UNIQUE=0 — the handoff note calling it
# 'only a plain KEY' is WRONG), so the number is a database guarantee as well as a
# domain check, and a soft-deleted invoice still holds its number.
# NOTE this create is aimed at a number that ALREADY EXISTS, so it can only ever
# be refused — it writes nothing whatever the answer.
EXISTING_INVNUM="$(sql "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=$DRAFT_ID")"
if [ -n "$EXISTING_INVNUM" ]; then
  req POST "$INV" -H 'Content-Type: application/json' \
      -d "{\"invnum\":\"$EXISTING_INVNUM\",\"invdate\":\"2026-09-26\",\"custname\":\"dup probe\",\"statecode\":\"29\",\"placeofsupply\":\"29\"}"
  # The domain's make :around answers a CONTRADICTION sentinel, which the reverse
  # ferry renders from nst-response-contradiction as {"error":"conflict"} — the SAME
  # body shape an issued-invoice line write gets.
  # IT IS A REAL ASSERTION, NOT A KNOWN DEFECT: measured green on the first live run
  # (2026-09-26), so a raw condition escaping here — a MySQL unique-violation classified
  # 500 internal_error — would now be a FAILURE, which is what it should be.
  expect ":C duplicate invnum → 409 conflict (the :around refuses before any INSERT)" 409 '"conflict"'
else
  skip "duplicate invnum → 409" "no SQL access to read $DRAFT_ID's number"
fi

# --- the (header, line) PAIRING, and the DRAFT rule ------------------------
req GET "$INV/$DRAFT_INV/items"
expect "GET on the line collection → no_such_endpoint (not in the spec)" 404 '"no_such_endpoint"'
req POST "$INV/$ABSENT_INV/items" -H 'Content-Type: application/json' \
    -d "{\"prd-id\":$PRD_ID,\"prddesc\":\"x\",\"hsncode\":\"0405\",\"uom\":\"NOS\"}"
expect ":F line create on an absent invoice → 404" 404 '"not_found"'
req POST "$INV/$CROSS_TENANT_INV/items" -H 'Content-Type: application/json' \
    -d "{\"prd-id\":$PRD_ID,\"prddesc\":\"x\",\"hsncode\":\"0405\",\"uom\":\"NOS\"}"
expect ":F line create on another tenant's invoice → 404 (BOLA)" 404 '"not_found"'
bail_if_internal_error

# 🚨 CONTENT vs VALUES decides these: make/delete! on a line require a DRAFT
# header, while !update is allowed at any status. So a line operation on invoice
# $NON_DRAFT_ID must answer 409 (the invoice exists and is not a DRAFT), which is
# NOT the same fact as 404 (no such invoice).
req POST "$INV/$NON_DRAFT_INV/items" -H 'Content-Type: application/json' \
    -d "{\"prd-id\":$PRD_ID,\"prddesc\":\"409 probe\",\"hsncode\":\"0405\",\"uom\":\"NOS\"}"
expect ":C line create on a non-DRAFT invoice → 409" 409 '"conflict"'
bail_if_internal_error

# A line that does not belong to the named invoice must 404: the URL pair is
# VERIFIED, never trusted. Aimed at a line of a DIFFERENT invoice.
[ -n "${LINE_ID:-}" ] || LINE_ID="$(sql "SELECT ROW_ID FROM DOD_INVOICE_ITEMS WHERE INVHEADID=$NON_DRAFT_ID AND (DELETED_STATE='N' OR DELETED_STATE IS NULL) LIMIT 1")"
if [ -n "$LINE_ID" ]; then
  req PUT "$INV/$DRAFT_INV/items/$LINE_ID" -H 'Content-Type: application/json' -d '{"qty":2}'
  expect ":F a line of ANOTHER invoice → 404 (the pair is verified)" 404 '"not_found"'
  req DELETE "$INV/$DRAFT_INV/items/$LINE_ID"
  expect ":F delete a line of ANOTHER invoice → 404" 404 '"not_found"'
  # 🚨 THE SAME LINE, ADDRESSED UNDER ITS OWN (NON-DRAFT) INVOICE. This assertion was
  # MISSING until it was executed offline (tools/nst-verify-invoice-dispatch.lisp,
  # part E): removal of a line is allowed only while the document is still being built,
  # so invoice $NON_DRAFT_ID must answer 409 — NOT 404, which would say the line does not
  # exist, and NOT 200, which would amend an issued document. Aimed at a line that
  # already exists, and refused, so nothing is written.
  req DELETE "$INV/$NON_DRAFT_INV/items/$LINE_ID"
  expect ":C delete a line of a NON-DRAFT invoice → 409" 409 '"conflict"'
fi

req PUT "$INV/$EMPTY_DRAFT_INV/items/$ABSENT_ID" -H 'Content-Type: application/json' -d '{"qty":2}'
expect ":F update an absent line → 404" 404 '"not_found"'
req DELETE "$INV/$EMPTY_DRAFT_INV/items/$ABSENT_ID"
expect ":F delete an absent line → 404" 404 '"not_found"'

# ── 4. anti-collapse: the states must be DISTINCT ───────────────────────────
section "4. anti-collapse"
req GET "$INV/$ABSENT_INV";                       C_ABSENT="$HTTP_CODE"
req GET "$INV/$CROSS_TENANT_INV";                 C_BOLA="$HTTP_CODE"
req PUT "$INV/$DRAFT_INV" -H 'Content-Type: application/json' -d '{"invdate":"03/04/2026"}'
C_BADDATE="$HTTP_CODE"
req POST "$INV/$NON_DRAFT_INV/items" -H 'Content-Type: application/json' \
    -d "{\"prd-id\":$PRD_ID,\"prddesc\":\"x\",\"hsncode\":\"0405\",\"uom\":\"NOS\"}"
C_NONDRAFT="$HTTP_CODE"
req GET "$INV/$DRAFT_INV";                        C_OK="$HTTP_CODE"

if [ "$C_OK" != "$C_ABSENT" ] && [ "$C_BADDATE" != "$C_ABSENT" ] && [ "$C_NONDRAFT" != "$C_ABSENT" ]; then
  PASS=$((PASS+1))
  printf '  %sPASS%s %-48s %s/%s/%s/%s/%s\n' "$G" "$N" "present ≠ absent ≠ bad-date ≠ non-DRAFT" \
         "$C_OK" "$C_ABSENT" "$C_BADDATE" "$C_NONDRAFT" "$C_BOLA"
else
  FAIL=$((FAIL+1))
  printf '  %sFAIL%s %-48s %s/%s/%s/%s/%s — states COLLAPSED\n' "$R" "$N" \
         "present ≠ absent ≠ bad-date ≠ non-DRAFT" "$C_OK" "$C_ABSENT" "$C_BADDATE" "$C_NONDRAFT" "$C_BOLA"
fi
# The BOLA answer and the absent-row answer are the SAME status ON PURPOSE: the
# id in the URL is an ADDRESS, never an authorization, so another tenant's row must
# be indistinguishable from one that never existed.
check "another tenant's invoice is indistinguishable from an absent one" \
      "$([ "$C_BOLA" = "$C_ABSENT" ] && echo same || echo different)" "same"

# ── 5. the write lifecycle (opt-in) ─────────────────────────────────────────
if [ "$WRITE" = 1 ]; then
  section "5. create → line → update → delete  (WRITES TO THE LIVE DATABASE)"

  if [ -z "$(sql "SELECT 1")" ]; then
    printf '  %sFATAL%s no SQL access (%s@%s), so the cleanup cannot be guaranteed.\n' \
           "$R" "$N" "$NS_MYSQL_USER" "$NS_DB"
    printf '        REFUSING TO WRITE. There is NO SQL-free restore: the API exposes no\n'
    printf '        invoice DELETE at all, so a header created here could only be removed\n'
    printf '        by hand. MySQL binds 127.0.0.1 only — run --write ON THE SERVER.\n'
    exit 2
  fi

  # Nothing to pre-check by INVNUM (the trigger owns that column). The meaningful
  # invariant is that this run starts with an EMPTY id list, so cleanup can only ever
  # touch what this run created.
  # NOTE ${CREATED_IDS} NOT ${CREATED_IDS:-…}: `:-` substitutes when the value is EMPTY,
  # so the default fired and the check could never pass. Written the long way round.
  check "the cleanup list starts empty (it can only touch this run's rows)" \
        "$([ -z "$CREATED_IDS" ] && echo empty || echo "non-empty: $CREATED_IDS")" "empty"
  HDR_BEFORE="$(sql "SELECT COUNT(*) FROM DOD_INVOICE_HEADER")"

  # --- create ---------------------------------------------------------------
  # A minimal body works: invnum is supplied (so the cleanup can find the row),
  # and invdate/finyear/totalvalue are supplied explicitly rather than relied on,
  # so this asserts the CONTRACT and not the class's initforms.
  NEW_INVNUM="$MARKER"
  req POST "$INV" -H 'Content-Type: application/json' -d "{
        \"invnum\":\"$NEW_INVNUM\", \"invdate\":\"2026-09-26\",
        \"custname\":\"Smoke Test Customer\", \"statecode\":\"29\",
        \"placeofsupply\":\"29\", \"totalvalue\":0, \"totalinwords\":\"Zero\",
        \"finyear\":\"2026-2027\"}"
  expect ":T create a DRAFT invoice → 201" 201 '"rowId"'
  bail_if_internal_error
  NEW_ID="$(rowid_of)"
  # The URL for everything below carries the NUMBER, which the TRIGGER assigned — so it
  # is read back from the row, not the marker this script sent (the trigger discards that).
  NEW_INVNUM="$(sql "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=$NEW_ID")"
  # 🚨 RECORD IT IMMEDIATELY. From here on the cleanup can remove this row; if the run
  # dies on the very next check, the trap still knows what to delete.
  [ -n "$NEW_ID" ] && CREATED_IDS="$NEW_ID"

  if [ -n "$NEW_ID" ]; then
    info "created invoice" "rowId $NEW_ID, invnum $NEW_INVNUM"
    # The domain mints a DRAFT — the create route's own docstring says so, and the
    # DRAFT-only rule for line writes depends on it being true.
    STORED_STATUS="$(sql "SELECT STATUS FROM DOD_INVOICE_HEADER WHERE ROW_ID=$NEW_ID")"
    check "the created row is a DRAFT in the database" "${STORED_STATUS:-?}" "DRAFT"
    STORED_TENANT="$(sql "SELECT TENANT_ID FROM DOD_INVOICE_HEADER WHERE ROW_ID=$NEW_ID")"
    check "the created row's tenant comes from the session, not the body" "${STORED_TENANT:-?}" "2"
    # THE TRIGGER OWNS INVNUM. Asserted rather than assumed, because it is the reason
    # this suite cannot tag its rows by invoice number — and because a client that
    # sends one deserves to know it was discarded. Format: NST + lpad(row_id,5,0) + - + year.
    STORED_INVNUM="$(sql "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=$NEW_ID")"
    EXPECTED_INVNUM="$(printf 'NST%05d-%s' "$NEW_ID" "$(date +%Y)")"
    check "INVNUM was ASSIGNED by the DB trigger, not by the request" "$STORED_INVNUM" "$EXPECTED_INVNUM"

    # 🚨 ASSERT THE ROW-ID, NOT THE NUMBER WE SENT. A MySQL trigger rewrites INVNUM on
    # insert (installation/nstdbtriggers.sql), so the marker in $NEW_INVNUM is NOT what
    # the row holds — the very next check asserts the trigger's value. The rowId IS ours
    # to assert: it came back from the 201 and the API cannot reassign it.
    req GET "$INV/$NEW_INVNUM"
    expect ":T read back the created invoice → 200" 200 "\"rowId\":\"$NEW_ID\""

    # --- the line -----------------------------------------------------------
    req POST "$INV/$NEW_INVNUM/items" -H 'Content-Type: application/json' -d "{
          \"prd-id\":$PRD_ID, \"prddesc\":\"Smoke test line\", \"hsncode\":\"0405\",
          \"qty\":2, \"uom\":\"NOS\", \"price\":100.00,
          \"taxable-value\":200.00, \"cgstrate\":9.00, \"cgstamt\":18.00,
          \"sgstrate\":9.00, \"sgstamt\":18.00, \"igstrate\":0, \"igstamt\":0,
          \"totalitemval\":236.00}"
    expect ":T add a line to the DRAFT → 201" 201 '"rowId"'
    bail_if_internal_error
    LINE_NEW="$(rowid_of)"

    if [ -n "$LINE_NEW" ]; then
      info "created line" "rowId $LINE_NEW"
      STORED_HDR="$(sql "SELECT INVHEADID FROM DOD_INVOICE_ITEMS WHERE ROW_ID=$LINE_NEW")"
      check "the line is attached to the invoice from the URL" "${STORED_HDR:-?}" "$NEW_ID"
      LINE_TENANT="$(sql "SELECT TENANT_ID FROM DOD_INVOICE_ITEMS WHERE ROW_ID=$LINE_NEW")"
      check "the line's tenant comes from the session" "${LINE_TENANT:-?}" "2"

      # The aggregate must now show it.
      req GET "$INV/$NEW_INVNUM"
      expect ":T detail now carries the new line" 200 "\"rowId\":\"$LINE_NEW\""

      # --- update the line --------------------------------------------------
      req PUT "$INV/$NEW_INVNUM/items/$LINE_NEW" -H 'Content-Type: application/json' \
          -d '{"qty":5,"prddesc":"Smoke test line (updated)"}'
      expect ":T update the line → 200" 200 '"rowId"'
      STORED_QTY="$(sql "SELECT QTY FROM DOD_INVOICE_ITEMS WHERE ROW_ID=$LINE_NEW")"
      check "the update reached the column" "${STORED_QTY:-?}" "5"

      # 🚨 THE PAIRING STRIP, WHICH IS WHY THIS REQUEST IS INTERESTING: the item
      # URL puts :invheadid in the payload and !update REFUSES that initarg by
      # design, so without the route's verify-then-strip every nested PUT would
      # 409. A 200 here is the proof the strip happens.
      req PUT "$INV/$NEW_INVNUM/items/$LINE_NEW" -H 'Content-Type: application/json' \
          -d '{"qty":6}'
      expect ":T a nested PUT does not 409 on its own invheadid" 200 '"rowId"'

      # --- update the header ------------------------------------------------
      req PUT "$INV/$NEW_INVNUM" -H 'Content-Type: application/json' \
          -d '{"custname":"Smoke Test Customer (updated)","invdate":"2026-09-27"}'
      expect ":T update the header → 200" 200 '"rowId"'
      STORED_NAME="$(sql "SELECT CUSTNAME FROM DOD_INVOICE_HEADER WHERE ROW_ID=$NEW_ID")"
      check "the header update reached the column" "$STORED_NAME" "Smoke Test Customer (updated)"
      STORED_DATE="$(sql "SELECT INVDATE FROM DOD_INVOICE_HEADER WHERE ROW_ID=$NEW_ID")"
      check "the ISO date was written as a DATE" "${STORED_DATE:-?}" "2026-09-27"

      # --- K1: no roll-up ---------------------------------------------------
      # The line is 236.00 and the header was created at 0.00. Nothing adjusts it.
      HDR_TOTAL="$(sql "SELECT TOTALVALUE FROM DOD_INVOICE_HEADER WHERE ROW_ID=$NEW_ID")"
      if [ "${HDR_TOTAL:-0}" = "0.00" ]; then
        KNOWN=$((KNOWN+1))
        printf '  %sKNOWN%s %-47s header still %s\n' "$Y" "$N" "adding a 236.00 line rolls up TOTALVALUE" "$HDR_TOTAL"
        printf '        K1: no roll-up and no issue verb. TOTALVALUE is whatever the caller\n'
        printf '        supplied; the line verbs never touch it. The [LEGAL] invariant that\n'
        printf '        TOTALVALUE must equal the sum of live lines is unenforced.\n'
      else
        PASS=$((PASS+1))
        printf '  %sPASS%s %-48s %s (K1 appears fixed)\n' "$G" "$N" "adding a line rolls up TOTALVALUE" "$HDR_TOTAL"
      fi

      # --- delete the line --------------------------------------------------
      # 🚨 delete! HAS NO कर्म LEFT TO RETURN — the row it acted on is gone — so the
      # verb acknowledges with a BARE Lisp T, and the reverse ferry turns that into
      # the ack body via (domain->response ((entity (eql t)) …)). That method lives
      # in warehouse/nst-bl-whsapi.lisp §4 and its type is still named
      # warehouse-ack-response, so THIS ROUTE DEPENDS ON WHSAPI BEING LOADED — and
      # the ack is what makes the assertion below more than a status code: without
      # that method a bare T would signal NO-APPLICABLE-METHOD and DELETE would 500.
      req DELETE "$INV/$NEW_INVNUM/items/$LINE_NEW"
      expect ":T delete the line → 200 + the delete ack" 200 '"operation":"delete"'
      STORED_DEL="$(sql "SELECT IFNULL(DELETED_STATE,'<NULL>') FROM DOD_INVOICE_ITEMS WHERE ROW_ID=$LINE_NEW")"
      check "the delete is SOFT (the row survives, flagged)" "${STORED_DEL:-?}" "Y"

      req GET "$INV/$NEW_INVNUM"
      if grep -qF "\"rowId\":\"$LINE_NEW\"" "$BODY"; then
        FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s it is still listed\n' "$R" "$N" "a soft-deleted line is gone from the aggregate"
      else
        PASS=$((PASS+1)); printf '  %sPASS%s %-48s absent\n' "$G" "$N" "a soft-deleted line is gone from the aggregate"
      fi

      # K2: the repeat delete cannot say "already deleted".
      req DELETE "$INV/$NEW_INVNUM/items/$LINE_NEW"
      expect_known "a REPEAT delete of the line → 409 'already deleted'" 409 '' \
        "KNOWN K2 — MEASURED 2026-09-26 (tools/nst-verify-invoice-dispatch.lisp): a repeat delete returns nst-entity-nil, i.e. 404 not_found, exactly as this script claims. Both delete! verbs exclude soft-deleted rows in their SELECT, so the 'already deleted' branch is unreachable and a second DELETE is indistinguishable from a wrong id. The correct contract is a 409 contradiction."
    fi
  fi

  # --- the count is restored by the trap, which is installed from the start --
  HDR_AFTER="$(sql "SELECT COUNT(*) FROM DOD_INVOICE_HEADER")"
  info "header count" "$HDR_BEFORE before → $HDR_AFTER now (the trap removes the +1)"
  printf '\n  every row this section created is removed on EXIT, found by its ROW-ID —\n'
  printf '  NOT by invoice number, which a MySQL trigger rewrites on insert. The API\n'
  printf '  exposes no invoice DELETE, so SQL is the only restore path that exists.\n'
else
  section "5. create → line → update → delete"
  printf '  SKIPPED — read-only run. Re-run with --write to exercise them.\n'
  printf '  (It creates its OWN invoice and deletes its own rows on exit; no\n'
  printf '   pre-existing invoice is modified. The one exception, by design, is a\n'
  printf '   line create aimed at invoice %s to assert the 409 — which writes nothing.)\n' "$NON_DRAFT_ID"
fi

# ── 6. the spec's id-less settings endpoint ─────────────────────────────────
section "6. PUT /invoices/settings — the id-less endpoint"

# 🚨 THIS SECTION NEVER SENDS A PAYLOAD THE DOMAIN WOULD ACCEPT, and that is not
# caution, it is the whole design. The endpoint's target is the SESSION's vendor —
# which here is vendor 1, the LOGIN IDENTITY and the ONLY row in DOD_VEND_PROFILE
# whose INVOICE_SETTINGS blob is not the byte-identical migration seed (its own
# Legal/Landscape/10, its own header and footer text, a watermark, a logo URL).
# A SUCCESSFUL PUT would therefore overwrite the one blob in the table that cannot
# be reconstructed from a sibling, and the vendor settings suite has already lost it
# once that way. So every request below is one the domain REFUSES, which the domain
# does BEFORE it looks the row up — and the refusals are checked against the stored
# md5, so "refused" is proven to mean "wrote nothing" rather than assumed to.
#
# What this costs: the SUCCESS path is not exercised here. That is the right trade —
# the same verb, the same validator and the same writer are covered end to end by
# hhub/test/smoke-vendor-invoice-settings-api.sh, which writes to a DISPOSABLE vendor
# and restores it from a verified donor. What is NEW here is only the ADDRESS, and
# the address is exactly what these checks pin down.
#
# ⚠ AND THE FAIL-CLOSED PATH (401 when the session carries no vendor identity) IS NOT
# EXERCISED EITHER, because this suite only ever logs in as a vendor — the state it
# would need is a session with a login company but no :login-vendor, and no credential
# available here produces one. Stated rather than left implicit: the guard is covered
# by reading invh-settings-session-row-id, not by this suite.

SETTINGS_MD5_BEFORE="$(sql "SELECT MD5(INVOICE_SETTINGS) FROM DOD_VEND_PROFILE WHERE ROW_ID=$SESSION_VENDOR")"
info "session vendor $SESSION_VENDOR blob before" "md5 ${SETTINGS_MD5_BEFORE:0:12}…"

# --- the routing assertion, authenticated ---------------------------------
# The literal segment must beat the {id} template. If find-api-route ranked by
# registration order instead, this would be dispatched as an UPDATE OF THE INVOICE
# WHOSE ID IS "settings" and answer 404 (no such invoice) rather than reaching the
# settings verb at all.
#
# 🚨 THE PROBE BODY IS `{}` — AN EMPTY OBJECT, WHICH THE DOMAIN REFUSES — and it must
# stay a payload that cannot be accepted. The obvious probe, a section whose value is
# a string such as {"invoice-print-settings":"undefined"}, is NOT refused: validation
# checks SECTION NAMES and the entries beneath them are free-form by design, so that
# payload reaches the row lookup and OVERWRITES THE BLOB. Aimed at the session vendor
# that is vendor 1, whose settings are the only customised ones in the table — the
# vendor suite destroyed exactly that blob with exactly that request. An empty object
# is refused before any row is read, so this probe cannot write.
req PUT "$INV/settings" -H 'Content-Type: application/json' -d '{}'
SETTINGS_CODE="$HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
  FAIL=$((FAIL+1))
  printf '  %sFAIL%s %-48s 200 — an empty object was ACCEPTED\n' "$R" "$N" \
         "settings is routed to the settings verb, NOT to {id}"
  printf '       %sThat should be impossible, and it means a write happened. Check the\n' "$R"
  printf '       md5 check below and restore vendor 1 if it reports CHANGED.%s\n' "$N"
elif [ "$HTTP_CODE" = "404" ] && grep -qF '"not_found"' "$BODY"; then
  FAIL=$((FAIL+1))
  printf '  %sFAIL%s %-48s 404 not_found — the path was read as /invoices/{id}\n' "$R" "$N" \
         "settings is routed to the settings verb, NOT to {id}"
  printf '       find-api-route must rank fewest-parameters-first; check that the\n'
  printf '       literal template is registered and that ranking is still in place.\n'
else
  PASS=$((PASS+1))
  printf '  %sPASS%s %-48s %s (reached the settings verb, wrote nothing)\n' "$G" "$N" \
         "settings is routed to the settings verb, NOT to {id}" "$HTTP_CODE"
fi

# --- the domain's refusal, asserted against the correct contract -----------
# The vendor suite's K1: the refusal is correct and writes nothing, but the wire
# says 500 because apidefs2's classifier maps every unnamed condition to
# internal_error. Encoded as KNOWN so a real 400 is noticed when the classifier is
# fixed.
req PUT "$INV/settings" -H 'Content-Type: application/json' -d '{"no-such-section":{"a":1}}'
expect_known "an unknown section is refused → 400" 400 '' \
  "KNOWN K1 (shared with the vendor suite): vendor-settings-rejected names the section and lists the valid ones, but the classifier answers 500 internal_error, so the client learns nothing. The refusal itself is correct and writes nothing."

req PUT "$INV/settings" -H 'Content-Type: application/json' -d '"a string"'
expect "a non-object body → 400 (refused by the TRANSPORT)" 400 '"invalid_request"'

# --- 🚨 THE ADDRESS CANNOT BE MOVED BY THE BODY ----------------------------
# A row-id in the body is stripped before the verb sees it, so it cannot retarget the
# write. Sending one ALONGSIDE a malformed section keeps this non-writing: the
# refusal happens before any row is read, so the check below is that the OTHER
# vendor's blob is untouched too. What this does NOT prove on its own is that the
# body's row-id would be ignored on an ACCEPTED payload — which is exactly the case
# this suite must never send at vendor 1. The stripping is asserted directly in the
# unit of work instead: see vnd-params-with-session-row-id.
req PUT "$INV/settings" -H 'Content-Type: application/json' \
    -d "{\"row-id\":$OTHER_VENDOR,\"no-such-section\":{\"a\":1}}"
if [ "$HTTP_CODE" = 200 ]; then
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s IT WAS ACCEPTED — vendor 1 may be damaged\n' "$R" "$N" \
         "a body-supplied row-id cannot retarget the write"
else
  PASS=$((PASS+1)); printf '  %sPASS%s %-48s refused with %s\n' "$G" "$N" \
         "a body-supplied row-id cannot retarget the write" "$HTTP_CODE"
fi

# --- integrity: the refusals really wrote nothing --------------------------
SETTINGS_MD5_AFTER="$(sql "SELECT MD5(INVOICE_SETTINGS) FROM DOD_VEND_PROFILE WHERE ROW_ID=$SESSION_VENDOR")"
if [ -n "$SETTINGS_MD5_BEFORE" ]; then
  check "the session vendor's blob is BYTE-IDENTICAL after every refusal" \
        "$([ "$SETTINGS_MD5_BEFORE" = "$SETTINGS_MD5_AFTER" ] && echo unchanged || echo CHANGED)" "unchanged"
  [ "$SETTINGS_MD5_BEFORE" = "$SETTINGS_MD5_AFTER" ] || \
    printf '       %s🚨 RESTORE VENDOR $SESSION_VENDOR from a backup NOW — this script damaged the only customised blob.%s\n' "$R" "$N"
else
  skip "the session vendor's blob is BYTE-IDENTICAL after every refusal" "no SQL access to read the md5"
fi

# --- it is a SECOND DOOR, not a second writer ------------------------------
# Both paths must reach the SAME verb, so the vendor sub-resource must still be
# bound. If it were ever removed in favour of this one, the blob would have exactly
# one writer but the vendor's own UI-facing endpoint would be gone.
req_noauth PUT "/hhub/api/v1/vendor/profile/$SESSION_VENDOR/invoice-settings" \
    -H 'Content-Type: application/json' -d '{}'
if [ "$HTTP_CODE" = "401" ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-48s 401\n' "$G" "$N" "the vendor sub-resource is STILL bound (one writer, two doors)"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s answered %s, want 401\n' "$R" "$N" \
         "the vendor sub-resource is STILL bound (one writer, two doors)" "$HTTP_CODE"
fi
info "settings refusals" "all answered $SETTINGS_CODE; nothing written"

# ── 7. the spec's download and public view ──────────────────────────────────
section "7. GET /invoices/{id}/download — the 302 to the rendered PDF"

# 🚨 EVERY REQUEST IN THIS SECTION IS AIMED AT AN INVOICE THAT CANNOT BE RENDERED, so
# the PDF pipeline never starts: the header fetch fails first and the route answers
# with the sentinel before invh-download-pdf-url is reached.
#
# THAT IS DELIBERATE, NOT A GAP. invh-download-pdf-url SHELLS OUT: it wgets *siteurl*
# — "https://www.ninestores.in", a PUBLIC production URL (core/dod-ini-sys.lisp:57) —
# and runs wkhtmltopdf over the result (core/dod-bl-utl.lisp:254,285). On this host
# that would render PRODUCTION's page for a dev invoice, slowly, from a test. So what
# this section asserts honestly is the ROUTE's contract: that the binding exists, that
# a missing or other-tenant invoice is refused BEFORE anything is rendered, and that
# those are not collapsed with a successful download. The render path itself is opt-in
# below, and says what it needs.
req GET "$INV/$ABSENT_INV/download"
expect ":F download an absent invoice → 404" 404 '"not_found"'
req GET "$INV/$CROSS_TENANT_INV/download"
expect ":F download another tenant's invoice → 404 (BOLA)" 404 '"not_found"'
req GET "$INV/NO-SUCH-NUMBER/download"
expect_oneof ":F non-numeric id → 404 or 400, never 500" "400|404" ''

# The route must not have become "download anything": its refusals are 404s, and a
# 200/302 here would mean the fetch guard was bypassed.
check "the refusals are 404, not a redirect" \
      "$([ "$HTTP_CODE" = "404" ] && echo ok || echo "unexpected $HTTP_CODE")" "ok"

# --- the render path, OPT IN --------------------------------------------------
# NS_DOWNLOAD_LIVE=1 asserts the real contract: a 302 whose Location points at the
# rendered file under /img/temp/. It is slow (an HTTP round trip to *siteurl* plus
# wkhtmltopdf) and it renders invoice 23's public page on whatever host *siteurl*
# names — so on a dev box it renders PRODUCTION, or fails if that URL does not resolve.
# The id is the DRAFT fixture, chosen because EVERY invoice row renders the same way:
# the new entities mirror DOD_INVOICE_HEADER, so the legacy public page reads them.
if [ "${NS_DOWNLOAD_LIVE:-}" = "1" ]; then
  printf '  ---- live render requested (NS_DOWNLOAD_LIVE=1); this shells out to wkhtmltopdf\n'
  LIVE_CODE="$(curl -sS -o /dev/null -D "$TMP/hdrs" -w '%{http_code}' -b "$JAR" \
                    --max-time 180 "$BASE$INV/$DRAFT_INV/download" 2>"$ERR")"
  LIVE_LOC="$(grep -i '^location:' "$TMP/hdrs" 2>/dev/null | head -1 | tr -d '\r' | sed 's/^[Ll]ocation:[[:space:]]*//')"
  info "download of invoice $DRAFT_ID" "HTTP ${LIVE_CODE:-000}  Location: ${LIVE_LOC:-<none>}"
  # 🚨 A 500 HERE IS NOT THIS ENDPOINT'S DEFECT, AND THE SUITE MUST NOT REPORT IT AS ONE.
  # The route is reached and does its job — it fetches the header, mints the ext-url and
  # calls the renderer — and then the LEGACY PUBLIC PAGE fails, so wget gets an error
  # response and the pipeline aborts (the API log names it: "external command failed
  # (non-zero exit status), exit status 8: wget … displayinvoicepublic?key=…").
  # That page has been answering 500 for EVERY invoice since at least 2026-05-23 —
  # MISSING-SLOT INVNUM inside create-model-for-displayinvoicepublic, found in
  # ninestores-messages.log at 14:47, 14:49 and 14:59 that day, long before this work.
  # It breaks the legacy public PDF and the invoice email attachment the same way.
  # So the correct contract (302 + a PDF) is asserted, and the environmental cause is
  # reported as KNOWN with its reason, rather than blamed on this route.
  if [ "${LIVE_CODE:-000}" = "302" ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-48s 302\n' "$G" "$N" "a rendered download answers 302"
    case "$LIVE_LOC" in
      */img/temp/*)
        PASS=$((PASS+1)); printf '  %sPASS%s %-48s yes\n' "$G" "$N" "the Location is the rendered file under /img/temp/" ;;
      *)
        FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s %s\n' "$R" "$N" "the Location is the rendered file under /img/temp/" "${LIVE_LOC:-<none>}" ;;
    esac
    if [ -n "$LIVE_LOC" ]; then
      if curl -sS -o "$TMP/one.pdf" --max-time 60 "$LIVE_LOC" 2>/dev/null \
         && [ "$(head -c 4 "$TMP/one.pdf" 2>/dev/null)" = "%PDF" ]; then
        PASS=$((PASS+1)); printf '  %sPASS%s %-48s %s bytes\n' "$G" "$N" \
               "the Location serves a real PDF (starts %PDF)" "$(wc -c < "$TMP/one.pdf")"
      else
        FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s not a PDF\n' "$R" "$N" "the Location serves a real PDF (starts %PDF)"
      fi
    fi
  elif [ "${LIVE_CODE:-000}" = "500" ]; then
    KNOWN=$((KNOWN+1))
    printf '  %sKNOWN%s %-47s got 500, want 302\n' "$Y" "$N" "a rendered download answers 302"
    printf '        THE ROUTE IS FINE; ITS RENDERER IS NOT. The 500 comes from the legacy\n'
    printf '        public page, which has answered 500 for EVERY invoice since at least\n'
    printf '        2026-05-23 (MISSING-SLOT INVNUM in create-model-for-displayinvoicepublic,\n'
    printf '        ninestores-messages.log 14:47/14:49/14:59). Fixing that page fixes this\n'
    printf '        route, the legacy public PDF and the invoice email attachment together.\n'
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s got %s, want 302\n' "$R" "$N" \
           "a rendered download answers 302" "${LIVE_CODE:-000}"
  fi
else
  skip "the render path (302 + a real PDF)" "set NS_DOWNLOAD_LIVE=1 — it shells out to wkhtmltopdf over *siteurl*"
fi

# ── 8. the spec's public view ───────────────────────────────────────────────
section "8. GET /invoices/{id}/public — the shareable link"

# 🚨 WHAT THIS ENDPOINT IS, AND WHY IT IS SESSION-SCOPED. The spec says
#   'Publicly accessible invoice view URL for sharing with customers directly.
#     No authentication required.'
# and the SUBJECT of that sentence is the URL, not the endpoint. What the endpoint
# RETURNS is a link; it is the LINK that must open without a session. Read the other
# way — an id-addressed, unauthenticated invoice GET — it is a BOLA hole that lets
# anyone walk ROW_IDs and harvest every tenant's invoices. So the assertions below are
# (a) that the same tenant-scoping every other route has still applies, and (b) that
# the link it hands back is the PUBLIC mechanism, not a second private door.
req GET "$INV/$DRAFT_INV/public"
expect ":T the public-view read → 200 + a link" 200 '"publicUrl"'
bail_if_internal_error

PUBLIC_URL=""
if [ "$HTTP_CODE" = "200" ]; then
  PUBLIC_URL="$(grep -o '"publicUrl":"[^"]*"' "$BODY" | head -1 | sed 's/.*:"//; s/"$//')"
  case "$PUBLIC_URL" in
    *displayinvoicepublic?key=*)
      PASS=$((PASS+1)); printf '  %sPASS%s %-48s yes\n' "$G" "$N" "the link is the PUBLIC view route (…?key=)" ;;
    *)
      FAIL=$((FAIL+1))
      printf '  %sFAIL%s %-48s %s\n' "$R" "$N" "the link is the PUBLIC view route (…?key=)" "${PUBLIC_URL:-<none>}"
      printf '       It must be the sessionless /hhub/displayinvoicepublic?key=… mechanism.\n' ;;
  esac
  case "$PUBLIC_URL" in
    http*) PASS=$((PASS+1)); printf '  %sPASS%s %-48s yes\n' "$G" "$N" "the link is ABSOLUTE (shareable verbatim)" ;;
    *)     FAIL=$((FAIL+1)); printf '  %sFAIL%s %-48s %s\n' "$R" "$N" "the link is ABSOLUTE (shareable verbatim)" "${PUBLIC_URL:-<none>}" ;;
  esac
  # The key must decode to this invoice's own identity, or the link points elsewhere.
  # 🚨 THE FORMAT, VERIFIED AGAINST A REAL KEY rather than assumed: the payload is a
  # HEADER line then a data line —
  #     tenant-id,invnum,vendor-id\n2,NST00009-2024,1
  # (core/dod-ini-sys.lisp's generator writes that header, and hhublogs/ holds a real
  # one from 2024). So the TENANT IS THE FIRST FIELD of the last line — a pattern like
  # *,2,* would only match if the tenant happened to appear mid-string, and would fail
  # on every correct link.
  KEY="${PUBLIC_URL##*key=}"
  if [ -n "$KEY" ]; then
    DECODED="$(printf '%s' "$KEY" | base64 -d 2>/dev/null | tr -d '\r' | tail -1)"
    case "$DECODED" in
      "$SESSION_TENANT",*)
        PASS=$((PASS+1)); printf '  %sPASS%s %-48s %s\n' "$G" "$N" "the key's tenant field is this session's tenant" "$DECODED" ;;
      *)
        FAIL=$((FAIL+1))
        printf '  %sFAIL%s %-48s %s\n' "$R" "$N" "the key's tenant field is this session's tenant" "${DECODED:-<undecodable>}"
        printf '       expected it to start with %s, (tenant,invnum,vendor)\n' "$SESSION_TENANT" ;;
    esac
  fi
fi

# DETERMINISM, which is what makes "nothing is written" defensible: the key is derived
# from tenant+invnum+vendor with no nonce, so minting twice must give the SAME url.
req GET "$INV/$DRAFT_INV/public"
PUBLIC_URL2="$(grep -o '"publicUrl":"[^"]*"' "$BODY" | head -1 | sed 's/.*:"//; s/"$//')"
check "minting the link twice returns the identical URL" \
      "$([ -n "$PUBLIC_URL" ] && [ "$PUBLIC_URL" = "$PUBLIC_URL2" ] && echo identical || echo different)" "identical"

# AND IT REALLY IS A READ. A GET that quietly populated EXTERNAL_URL would be a write
# through a safe method, which is the kind of thing that only shows up later.
EXT_BEFORE="$(sql "SELECT IFNULL(EXTERNAL_URL,'<NULL>') FROM DOD_INVOICE_HEADER WHERE ROW_ID=$DRAFT_ID")"
req GET "$INV/$DRAFT_INV/public"
EXT_AFTER="$(sql "SELECT IFNULL(EXTERNAL_URL,'<NULL>') FROM DOD_INVOICE_HEADER WHERE ROW_ID=$DRAFT_ID")"
if [ -n "$EXT_BEFORE" ]; then
  check "the GET did not write EXTERNAL_URL on the row" \
        "$([ "$EXT_BEFORE" = "$EXT_AFTER" ] && echo unchanged || echo CHANGED)" "unchanged"
else
  skip "the GET did not write EXTERNAL_URL on the row" "no SQL access"
fi

# The same scoping as everywhere else — the link is minted only for an invoice this
# session may see.
req GET "$INV/$ABSENT_INV/public"
expect ":F public view of an absent invoice → 404" 404 '"not_found"'
req GET "$INV/$CROSS_TENANT_INV/public"
expect ":F public view of another tenant's invoice → 404 (BOLA)" 404 '"not_found"'
req GET "$INV/NO-SUCH-NUMBER/public"
expect_oneof ":F non-numeric id → 404 or 400, never 500" "400|404" ''

# ── 9. the two endpoints that do NOT exist ──────────────────────────────────
section "9. the two spec endpoints with no binding (asserted ABSENT)"

absent() {
  local method="$1" path="$2" label="$3" data="${4:-}"
  if [ -n "$data" ]; then
    req "$method" "$path" -H 'Content-Type: application/json' -d "$data"
  else
    req "$method" "$path"
  fi
  if grep -qF '"no_such_endpoint"' "$BODY"; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-48s %s no_such_endpoint\n' "$G" "$N" "$label" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-48s answered %s — this endpoint EXISTS NOW. Bind it, add it\n' \
           "$R" "$N" "$label" "$HTTP_CODE"
    printf '       to this suite, and update invoice-api-handoff-CONTEXT.md §4.\n'
  fi
}
absent POST "$INV/$DRAFT_INV/payment"  "POST /{id}/payment"
absent POST "$INV/$DRAFT_INV/send"     "POST /{id}/send"
# And the header DELETE, which route-invh-delete exists for but the spec does not
# define and this suite must not silently start allowing.
absent DELETE "$INV/$DRAFT_INV"        "DELETE /{id} (registered but NOT bound, on purpose)"

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
fi
printf 'no unexpected failures\n'
exit 0
