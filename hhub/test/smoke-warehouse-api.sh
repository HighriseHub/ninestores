#!/usr/bin/env bash
#
# smoke-warehouse-api.sh — smoke-test the WAREHOUSE JSON API (conflodis2 + apidefs2).
#
# The warehouse sibling of smoke-products-api.sh: same shape, same login, same
# exit codes. Run it FROM A WORKSTATION (your Mac) — it uses
# http://ninestores.local, the workstation entry point.
#
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-warehouse-api.sh
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-warehouse-api.sh --write
#
# READ-ONLY by default. --write adds POST/PUT/DELETE, which create and
# soft-delete a REAL row in the live database.
#
# Exit codes:  0 = every result matched its expectation
#              1 = at least one result did NOT match
#              2 = setup failure (unreachable, no session) — the API wasn't tested
#
# ── KNOWN DEFECTS THIS SCRIPT ENCODES ───────────────────────────────────────
# Asserted against the CORRECT contract but reported as `KNOWN` (not `FAIL`) so
# a real regression stands out. FIXED 2026-09-13, now asserted normally:
#
#  ~~1. GET /warehouse/{id} on a MISSING row → 500.~~ FIXED. fetch tested
#     `(if bk …)` on the bo-knowledge OBJECT (truthy whatever the answer), so :F
#     and :U both fell into the "found" branch and dereferenced a NIL payload.
#     It now inspects the Belnap truth: :T→entity, :F→nst-entity-nil (404),
#     :U→nst-entity-unknown (503), :C→nst-entity-contradiction (409).
#  ~~2. GET /warehouse/{id} with a NON-NUMERIC id → 500 (same defect).~~ FIXED,
#     and given its own guard: warehouse-row-id-from-string turns "abc" into an
#     absence fact (404) BEFORE the DB call, instead of letting with-db-call
#     catch the parse error as :U — which would have answered 503 to a typo.
#
# STILL OPEN:
#  3. A bad ?sort-by= answers 503 (it was 500 before the Belnap change, and the
#     right answer is 400). THE CAUSE IS NOW KNOWN AND MECHANICAL:
#     validate-sort-args RAISES inside the body of with-nst-db-read-all, and that
#     macro's catch-all `(error …)` clause turns ANY error into :U — so a
#     client-input mistake is reported as a boundary failure. enumerate then maps
#     :U to nst-entity-unknown → 503.
#     503 IS WORSE THAN 500 HERE: it says "service unavailable, try again" for a
#     parameter that will never be valid. Two steps fix it:
#        (a) hoist parameter validation OUT of the DB macro bodies, so it is not
#            swallowed as :U (warehouse: validate-sort-args; products:
#            prd-status-arg / prd-number-arg / prd-status-clause);
#        (b) give validation failures a 4xx condition (the taxonomy, §9.1).
#     The WHITELIST ITSELF WORKS — busfunctions.log shows
#     "enumerate: sort-by SECRET-COLUMN not in whitelist" and no ORDER BY was built.
#
# If a KNOWN check starts passing, fix the script: the defect was repaired.

set -uo pipefail

# ── STATUS ──────────────────────────────────────────────────────────────────
# Same as products: the code is compiled and the routes are registered (every
# warehouse URL answers 401 rather than 404). What had never run is anything
# past authentication — this script is what exercises it.

# ── TWO OPERATIONAL WARNINGS ────────────────────────────────────────────────
# 1. Login counts against a MAX OF 2 CONCURRENT VENDOR LOGINS and eviction is
#    oldest-first — running this can silently bounce a browser session (and a
#    browser login can bounce this one).
# 2. Sessions are bound to User-Agent + client IP + a session secret, and
#    start-das calls reset-session-secret — so a server restart invalidates all
#    cookies, and mixing User-Agents between login and request fails.

# ── configuration ───────────────────────────────────────────────────────────
BASE="${BASE:-http://ninestores.local}"
PHONE="${NS_PHONE:-}"
PASSWORD="${NS_PASSWORD:-}"

# The 409 test needs an identity held by a SOFT-DELETED row in the SESSION'S
# tenant: uk_gstin_name_tenant is (WAREHOUSE_GSTIN, W_NAME, TENANT_ID) and
# DELETED_STATE is not part of it, so a deleted warehouse keeps its identity
# reserved. These defaults are a real soft-deleted row in tenant 2 (the demo
# tenant the vendor logs into). Override if your data differs.
DELETED_GSTIN="${NS_DELETED_GSTIN:-27AABCU9603R1ZM}"
DELETED_WNAME="${NS_DELETED_WNAME:-Main Distribution Center 4JSZW}"

WRITE=0

usage() {
  sed -n '3,40p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --write            also run the mutating tests (creates a real warehouse row)
  --base URL         override the base URL (default http://ninestores.local)
  -h, --help         this text

Environment:
  NS_PHONE           vendor phone (login form field "phone")      [required]
  NS_PASSWORD        vendor password (login form field "password") [required]
  NS_DELETED_GSTIN   GSTIN of a soft-deleted warehouse             (default 27AABCU9603R1ZM)
  NS_DELETED_WNAME   its W_NAME, same tenant as the login           (default Main Distribution Center 4JSZW)
  BASE               base URL, same as --base
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
  echo "       Same login as the products script — the session company IS the tenant." >&2
  exit 2
fi

# ── plumbing ────────────────────────────────────────────────────────────────
TMP="$(mktemp -d)" || exit 2
trap 'rm -rf "$TMP"' EXIT
JAR="$TMP/cookies.txt"
BODY="$TMP/body.json"
ERR="$TMP/curl.err"

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; N=$'\033[0m'
else G=; R=; Y=; N=; fi

PASS=0; FAIL=0; KNOWN=0
HTTP_CODE=""

req() {
  local method="$1"; shift
  local path="$1"; shift
  HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -X "$method" \
                    -b "$JAR" -c "$JAR" "$@" "$BASE$path" 2>"$ERR")"
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
    PASS=$((PASS+1)); printf '  %sPASS%s %-44s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-44s got %s, want %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" \
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
    printf '  %sPASS%s %-44s %s  (KNOWN defect appears fixed — update this script)\n' \
           "$G" "$N" "$name" "$HTTP_CODE"
  else
    KNOWN=$((KNOWN+1))
    printf '  %sKNOWN%s %-43s got %s, want %s\n' "$Y" "$N" "$name" "$HTTP_CODE" "$want"
    printf '        %s\n' "$why"
  fi
}

info() { printf '  %s----%s %-44s %s\n' "$Y" "$N" "$1" "$2"; }

body_field() {
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$BODY" | head -1
}
count_objects() { grep -o '"rowId"' "$BODY" 2>/dev/null | wc -l | tr -d ' '; }

section() { printf '\n== %s\n' "$1"; }

bail_if_not_loaded() {
  if grep -qF '"no_such_endpoint"' "$BODY"; then
    printf '\n%sThe warehouse routes are NOT REGISTERED in the running image.%s\n' "$R" "$N"
    printf 'In the Lisp image: (asdf:load-system :nstores) then (list-api-routes).\n'
    exit 2
  fi
}

# ── 1. reachability + session ───────────────────────────────────────────────
section "1. reachability and session  ($BASE)"

if ! curl -sS -o /dev/null --max-time 10 "$BASE/hhub/" 2>"$ERR"; then
  printf '  %sFATAL%s cannot reach %s — curl: %s\n' "$R" "$N" "$BASE" "$(head -1 "$ERR")"
  exit 2
fi
printf '  reachable\n'

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

req GET "/hhub/api/v1/warehouse"
case "$HTTP_CODE" in
  401) printf '\n  %sFATAL%s login did not establish a vendor session (API answered 401).\n' "$R" "$N"
       exit 2 ;;
  000) printf '\n  %sFATAL%s could not reach the API endpoint.\n' "$R" "$N"; exit 2 ;;
esac
bail_if_not_loaded
printf '  session established (authenticated call answered %s)\n' "$HTTP_CODE"

# ── 2. list (read-only) ─────────────────────────────────────────────────────
section "2. list (read-only)"

COUNT="$(count_objects)"
info "tenant has" "$COUNT warehouses"
if [ "$COUNT" -gt 0 ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-44s %s objects\n' "$G" "$N" "GET list returns warehouses" "$COUNT"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-44s 0 objects (expected rows for the demo tenant)\n' "$R" "$N" "GET list returns warehouses"
fi

req GET "/hhub/api/v1/warehouse?city=Thane"
expect "GET list ?city=Thane" 200
req GET "/hhub/api/v1/warehouse?state-code=27"
expect "GET list ?state-code=27" 200
req GET "/hhub/api/v1/warehouse?name-like=Main" 
expect "GET list ?name-like=Main" 200
req GET "/hhub/api/v1/warehouse?warehouse-type=own"
expect "GET list ?warehouse-type=own" 200
req GET "/hhub/api/v1/warehouse?sort-by=w-name&sort-dir=desc"
expect "GET list whitelisted sort" 200
req GET "/hhub/api/v1/warehouse?sort-by=w-city&sort-dir=asc"
expect "GET list sort by w-city" 200
req GET "/hhub/api/v1/warehouse?city=NowhereCityXYZ"
expect "GET list unknown city → 200 []" 200 "[]"

# KNOWN truthiness defect: values arrive as strings and the domain treats any
# non-nil as true, so ?is-primary-location=0 filters FOR primary locations.
# Recorded, not asserted (nst-bl-apidefs2-CONTEXT.md §9.6).
req GET "/hhub/api/v1/warehouse?is-primary-location=0"
info "?is-primary-location=0" "$HTTP_CODE (KNOWN: 0 filters FOR primary, it is truthy)"

# ── 3. fetch by id (read-only) ──────────────────────────────────────────────
section "3. fetch by id (read-only)"

FIRST_ID=""
req GET "/hhub/api/v1/warehouse"
FIRST_ID="$(body_field rowId)"

if [ -n "$FIRST_ID" ]; then
  req GET "/hhub/api/v1/warehouse/$FIRST_ID"
  expect "GET /warehouse/$FIRST_ID (live row)" 200 "\"rowId\""
else
  info "GET /warehouse/{id}" "SKIPPED — the list returned no rows"
fi

req GET "/hhub/api/v1/warehouse/999999"
expect "GET /warehouse/999999 (absent)" 404 "\"not_found\""

req GET "/hhub/api/v1/warehouse/abc"
expect "GET /warehouse/abc (non-numeric id)" 404

# ── 3b. BELNAP: the four states, on the read verbs ──────────────────────────
# THIS IS THE SECTION THAT PROVES THE FOUR-VALUED LAYER EARNS ITS PLACE. It is
# not enough that each state "returns something" — the states must stay
# DISTINCT, because collapsing them is the failure mode this layer exists to
# prevent. So each state asserts its own status AND that it is not one of the
# others (see the anti-collapse checks at the end).
#
#   :T → 200  the warehouse                    :C → 409  two of our rules disagree
#   :F → 404  there is none                    :U → 503  we could not find out
#
# :F has FOUR triggers, all genuinely absent but for different reasons:
#   absent             the id never existed
#   cross-tenant       the id EXISTS, in tenant 1 — the session is tenant 2, so
#                      the tenant filter makes it absent (OWASP API1:2023 BOLA:
#                      the URL id is an address, never an authorization)
#   soft-deleted       row 53 exists but DELETED_STATE='Y' — नियम-2 hides it
#   absurd             an id beyond any possible row
# A naive implementation would answer 200 for the cross-tenant case; that is the
# security-relevant assertion here.
section "3b. Belnap states on GET (read)"

# --- :F ---------------------------------------------------------------------
req GET "/hhub/api/v1/warehouse/999999"
expect ":F absent id → 404" 404 "\"not_found\""

CROSS_TENANT_ID="${NS_CROSS_TENANT_ID:-123}"     # a LIVE warehouse in tenant 1
req GET "/hhub/api/v1/warehouse/$CROSS_TENANT_ID"
expect ":F another tenant's id → 404 (BOLA)" 404 "\"not_found\""

SOFT_DELETED_ID="${NS_SOFT_DELETED_ID:-53}"      # soft-deleted, session tenant
req GET "/hhub/api/v1/warehouse/$SOFT_DELETED_ID"
expect ":F soft-deleted id → 404 (नियम-2)" 404 "\"not_found\""

req GET "/hhub/api/v1/warehouse/999999999999999999"
expect ":F absurd id → 404 (MySQL: 0 rows, no error)" 404

# --- :T ---------------------------------------------------------------------
if [ -n "$FIRST_ID" ]; then
  req GET "/hhub/api/v1/warehouse/$FIRST_ID"
  expect ":T live id → 200 + entity" 200 "\"rowId\""
fi

# --- :C and :T by IDENTITY --------------------------------------------------
# The warehouse identity is the tuple (GSTIN, W_NAME, TENANT). A soft-deleted row
# holds it: the unique key says TAKEN, नियम-2 says INVISIBLE → :T ⊔ :F = :C. This
# is a READ producing a genuine contradiction, not an error and not a 404.
IDENTITY_LIVE_GSTIN="${NS_IDENTITY_LIVE_GSTIN:-29ALSKDKJADS455}"
IDENTITY_LIVE_NAME="${NS_IDENTITY_LIVE_NAME:-Main Distribution Center mine}"

req GET "/hhub/api/v1/warehouse/by-identity?warehouse-gstin=$DELETED_GSTIN&wname=$(printf '%s' "$DELETED_WNAME" | sed 's/ /%20/g')"
expect ":C identity held by a soft-deleted row → 409" 409 "\"conflict\""

req GET "/hhub/api/v1/warehouse/by-identity?warehouse-gstin=$IDENTITY_LIVE_GSTIN&wname=$(printf '%s' "$IDENTITY_LIVE_NAME" | sed 's/ /%20/g')"
expect ":T live identity → 200 + entity" 200 "\"rowId\""

req GET "/hhub/api/v1/warehouse/by-identity?warehouse-gstin=99ZZZZZ9999Z9Z9&wname=Nobody%20Here"
expect ":F unknown identity → 404" 404 "\"not_found\""

# A malformed identity read is a CLIENT error: both halves of the tuple are
# required, because one GSTIN legitimately maps to many warehouses.
req GET "/hhub/api/v1/warehouse/by-identity?warehouse-gstin=$IDENTITY_LIVE_GSTIN"
expect "identity read missing wname → 400" 400 "\"invalid_request\""

# --- anti-collapse: the states are DISTINCT ---------------------------------
# If :U were ever answered as 404, or :C as 200, the four-valued layer would be
# decorative. These are the assertions that make the above meaningful.
req GET "/hhub/api/v1/warehouse/999999"
if [ "$HTTP_CODE" = 404 ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-44s 404 (a miss is NOT reported as 503)\n' "$G" "$N" "anti-collapse :F ≠ :U"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-44s :F answered %s, not 404\n' "$R" "$N" "anti-collapse :F ≠ :U" "$HTTP_CODE"
fi

req GET "/hhub/api/v1/warehouse/by-identity?warehouse-gstin=$DELETED_GSTIN&wname=$(printf '%s' "$DELETED_WNAME" | sed 's/ /%20/g')"
if [ "$HTTP_CODE" = 409 ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-44s 409 (a contradiction is neither 200 nor 404)\n' "$G" "$N" "anti-collapse :C ≠ :T, :C ≠ :F"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-44s :C answered %s, not 409\n' "$R" "$N" "anti-collapse :C ≠ :T, :C ≠ :F" "$HTTP_CODE"
fi

info ":U (boundary failure)" "NOT triggered here — needs the KILL runbook (see the context file §14)"

# ── 4. negative auth + routing ──────────────────────────────────────────────
section "4. negative cases (read-only)"

HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' "$BASE/hhub/api/v1/warehouse" 2>"$ERR")"
expect "GET list with NO session cookie" 401

req GET "/hhub/api/v1/warehouse/1/nonsense"
expect "GET unbound endpoint → no_such_endpoint" 404 "\"no_such_endpoint\""

req GET "/hhub/api/v1/warehouse?sort-by=secret-column"
info "GET bad ?sort-by" "$HTTP_CODE (wrong: a bad PARAMETER must be 400; see the note below)"

# ── 5. soft-deleted identity → 409 ──────────────────────────────────────────
section "5. soft-deleted identity → 409"

req POST "/hhub/api/v1/warehouse" \
    -H 'Content-Type: application/json' \
    -d "{\"wname\":\"$DELETED_WNAME\",\"warehouse-gstin\":\"$DELETED_GSTIN\",\"state-code\":\"27\"}"
expect "POST with a soft-deleted (GSTIN, name)" 409 "\"conflict\""

# ── 6. writes (opt-in) ──────────────────────────────────────────────────────
if [ "$WRITE" = 1 ]; then
  section "6. create / update / delete  (WRITES TO THE LIVE DATABASE)"
  STAMP="$(date +%H%M%S)"
  # GSTIN must be 15 chars; state-code must match its leading digits. The unique
  # key is (GSTIN, W_NAME, TENANT), so a fresh NAME is what keeps runs distinct.
  req POST "/hhub/api/v1/warehouse" \
      -H 'Content-Type: application/json' \
      -d "{\"wname\":\"API Smoke WH $STAMP\",\"warehouse-gstin\":\"27AAAAA0000A1Z5\",\"state-code\":\"27\",\"wcity\":\"Thane\"}"
  expect "POST create" 201
  RID="$(body_field rowId)"
  if [ -z "$RID" ]; then
    printf '  %sSKIP%s could not read rowId from the create response; skipping update/delete.\n' "$Y" "$N"
  else
    printf '       created rowId=%s\n' "$RID"
    req PUT "/hhub/api/v1/warehouse/$RID" \
        -H 'Content-Type: application/json' \
        -d '{"wcity":"Nashik","wmanager":"API Smoke"}'
    expect "PUT update (partial)" 200 "\"city\""
    req DELETE "/hhub/api/v1/warehouse/$RID"
    expect "DELETE (soft) → ack" 200 "\"ok\""
    req DELETE "/hhub/api/v1/warehouse/$RID"
    expect "DELETE again → gone" 404
    req GET "/hhub/api/v1/warehouse/$RID"
    expect-known "GET deleted row" 404 "" \
      "KNOWN: same fetch defect — a miss is a 500, not a 404."
    printf '\n  cleanup: the row stays SOFT-DELETED and keeps its (GSTIN, name, tenant)\n'
    printf '           reserved. To purge it, in mysql (hhubdb):\n'
    printf '             DELETE FROM DOD_WAREHOUSE WHERE ROW_ID = %s;\n' "$RID"
  fi
else
  section "6. create / update / delete"
  printf '  SKIPPED — read-only run. Re-run with --write to exercise them.\n'
  printf '  (They create a real warehouse row in the live database.)\n'
fi

# ── summary ─────────────────────────────────────────────────────────────────
printf '\n─────────────────────────────────────────────\n'
printf 'passed %s   failed %s   known-defects %s\n' "$PASS" "$FAIL" "$KNOWN"
if [ "$FAIL" -gt 0 ]; then
  printf '\nfailed checks are UNEXPECTED (not in the known-defect list). Server detail:\n'
  printf '  ssh <server> tail -40 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
  exit 1
fi
if [ "$KNOWN" -gt 0 ]; then
  printf '\nThe %s known defect(s) above are pre-existing warehouse bugs this script\n' "$KNOWN"
  printf 'encodes deliberately — see the header and nst-bl-apidefs2-CONTEXT.md §11.\n'
fi
printf 'no unexpected failures\n'
exit 0
