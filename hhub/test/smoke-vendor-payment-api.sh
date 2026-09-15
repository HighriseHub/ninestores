#!/usr/bin/env bash
#
# smoke-vendor-payment-api.sh — smoke-test the VENDOR PAYMENT SETTINGS JSON API
# (conflodis2 + apidefs2), the nst-vnd-vpm entity.
#
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-vendor-payment-api.sh
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-vendor-payment-api.sh --write
#
# READ-ONLY by default. --write adds POST and PUT, which create and modify a REAL
# row in the live database.
#
# Exit codes:  0 = every result matched its expectation
#              1 = at least one result did NOT match
#              2 = setup failure (unreachable, no session) — the API wasn't tested
#
# ── WHAT THIS ENTITY IS, AND WHY THE SUITE IS SHORT ─────────────────────────
# nst-vnd-vpm is a SETTING, not a record: one row per vendor for the vendor's
# whole lifetime, five payment-method flags and nothing else. So this suite has
# THREE endpoints and no more:
#
#   POST   /hhub/api/v1/vendor/payment/methods
#   GET    /hhub/api/v1/vendor/payment/methods/{vendorId}
#   PUT    /hhub/api/v1/vendor/payment/methods/{vendorId}
#
# THERE IS NO LIST AND NO DELETE, by design, and their absence is the reason two
# whole sections of the warehouse suite have no counterpart here:
#   * no `enumerate` — a vendor never has more than one row, so "list" means
#     nothing; the client's read IS `GET {vendorId}`;
#   * no `delete!` — "this vendor accepts nothing" is expressed IN BAND by setting
#     the five flags to "N". A soft-deleted row would occupy the singleton slot
#     while नियम-2 makes it invisible, so the vendor could never configure
#     payments again. Leaving delete! undefined makes that state unreachable.
#     CONSEQUENCE FOR THIS SCRIPT: it cannot clean up after itself. See the
#     purge SQL at the end of section 6.
#
# THERE IS ALSO NO /exists ENDPOINT, deliberately. Existence is the GET's own
# 200-vs-404 answer, and section 2 and 3 assert it there. A separate route would
# answer a question the GET has just answered.
#
# ── KNOWN DEFECTS THIS SCRIPT ENCODES ───────────────────────────────────────
# Asserted against the CORRECT contract but reported as `KNOWN` (not `FAIL`) so a
# real regression stands out. If a KNOWN check starts passing, fix this script:
# the defect was repaired.
#
#  K1. 🚨 THE FLAG NAMES DO NOT SURVIVE THE JSON→INITARG CONVERSION, SO A CREATE
#      SILENTLY IGNORES EVERY FLAG. This is the most serious item here and it is
#      NOT the 4xx taxonomy:
#        apidefs2 normalises JSON keys through api-camel->lisp-name
#        (nst-bl-apidefs2.lisp:266), which camelCase→HYPHENATES:
#            "codEnabled"          → :COD-ENABLED
#            "upiEnabled"          → :UPI-ENABLED
#            "payProvidersEnabled" → :PAY-PROVIDERS-ENABLED
#            "walletEnabled"       → :WALLET-ENABLED
#            "payLaterEnabled"     → :PAY-LATER-ENABLED
#        but nst-vnd-vpm declares un-hyphenated initargs, taken from the COLUMN
#        names: :CODENABLED, :UPIENABLED, :PAYPROVIDERSENABLED, :WALLETENABLED,
#        :PAYLATERENABLED. extract-domain-initargs is a MOP filter against the
#        declared initargs, so every one of the five is DROPPED — and the row is
#        then written with the DDL defaults. A client that asked for cod disabled
#        gets cod ENABLED, and nothing reports a problem. "vendorId" → :VENDOR-ID
#        and "activeFlag" → :ACTIVE-FLAG DO match, so the create succeeds and only
#        the flags are wrong, which is why this hides.
#        FIX (one word per slot, in nst-dal-vndvpm.lisp): re-declare the initargs
#        in the hyphenated form the JSON contract already uses —
#        :cod-enabled, :upi-enabled, :pay-providers-enabled, :wallet-enabled,
#        :pay-later-enabled. The slot NAMES and accessors can stay plain, because
#        they match the legacy view-class and the copiers read them by slot name.
#      Until then, the only flag that can be set over HTTP is activeFlag.
#      WORKAROUND: keys sent UN-HYPHENATED and lower case —
#      {"codenabled":"N","paylaterenabled":"Y"} — normalise to :CODENABLED and
#      :PAYLATERENABLED and DO reach the entity. So the API is usable today, but
#      the request spelling differs from the response spelling, which is the real
#      defect: a client that reads codEnabled back cannot send it in again.
#
#  K2. POST with a missing/absent vendorId → 500. The domain raises
#      vpm-field-rejected, which names the field, and the API taxonomy turns any
#      condition into 500. 400 is right. (Same gap as the warehouse's
#      validate-sort-args and the profile's three paths.)
#
#  K3. PUT with a flag sent as JSON null → 500, want 400. Same cause, and the
#      refusal itself is CORRECT domain law — a NULL flag is read back as "Y"
#      through the legacy view-class and would silently ENABLE the method.
#
#  K4. PUT with vendorId in the BODY → 500, want 400. The parent link is refused
#      by design (re-pointing a settings row at another vendor is intra-tenant
#      BOLA); only the status code is wrong.
#
#  K5. POST with a vendorId that cannot address a vendor ("abc") → asserted as
#      404. The :around turns an unparseable id into a not-found sentinel BEFORE
#      the DB call, so this one is expected to PASS, not to be KNOWN.
#
# ── WHAT IS ASSERTED, AND WHAT IS NOT ───────────────────────────────────────
# BE HONEST ABOUT THIS WHEN READING A GREEN RUN — only TWO of the four Belnap
# states are asserted by default:
#
#   :T  asserted. Three checks (section 2 and 3).
#   :F  asserted. Five triggers (section 3).
#   :C  ASSERTED ONLY IF A FIXTURE EXISTS. Needs a SOFT-DELETED
#       payment-methods row: all five live rows are deleted_state='N' and this
#       surface has no delete!, so it cannot be made over HTTP. With
#       NS_SOFT_DELETED_VENDOR unset the suite SKIPs and prints the SQL that
#       creates it. 🚨 The assertion is on POST (409), not on GET — see section 3.
#   :U  NOT ASSERTED IN A DEFAULT RUN, but PROVISIONED. It requires the database
#       to become unanswerable mid-request, which nothing an HTTP client sends can
#       cause. The assertions EXIST and are gated behind NS_EXPECT_U=1, which
#       pauses after login so the DB can be stopped (see section 1b), runs the
#       :U checks alone, and exits. So the state stays covered by this file even
#       though a green default run does NOT prove :U answers 503 — it only proves
#       :F is not reported as 503.
#
# ── TWO OPERATIONAL WARNINGS ────────────────────────────────────────────────
# 1. Login counts against a MAX OF 2 CONCURRENT VENDOR LOGINS, evicted
#    oldest-first — running this can silently bounce a browser session (and a
#    browser login can bounce this one).
# 2. Sessions are bound to User-Agent + client IP + a session secret, and
#    start-das calls reset-session-secret — so a server restart invalidates all
#    cookies, and mixing User-Agents between login and request fails.

set -uo pipefail

# ── configuration ───────────────────────────────────────────────────────────
BASE="${BASE:-http://hunchentoot.local}"
PHONE="${NS_PHONE:-}"
PASSWORD="${NS_PASSWORD:-}"

# FIXTURES — all four verified against the live database (hhubdb, 2026-09-15).
#
# The demo vendor IS the identity the suite logs in as: phone 9999999990 is
# DOD_VEND_PROFILE.ROW_ID 1, TENANT_ID 2, and it already HAS payment settings
# (DOD_VPAYMENT_METHODS.ROW_ID 3). So it is the :T fixture and the 409 fixture.
DEMO_VENDOR="${NS_DEMO_VENDOR:-1}"
#
# A tenant-2 vendor with NO payment-settings row — the row DOES NOT EXIST, so the
# create path has a clean slot. Vendors 2, 5, 6, 7, 8, 9, 10 and 11 are all in
# this state; 5 is the default. THIS IS THE VALUABLE ONE: unlike the vendor
# profile suite, which had to invent a soft-deleted fixture, this entity's create
# path has a real empty slot already.
FREE_VENDOR="${NS_FREE_VENDOR:-5}"
#
# A vendor in ANOTHER tenant (17 is tenant 5) that DOES have settings. Read from a
# tenant-2 session it must be 404 — the tenant filter makes another tenant's
# vendor-id indistinguishable from one that never existed. That is the
# security-relevant assertion (OWASP API1:2023 BOLA): the id in the URL is an
# ADDRESS, never an authorization.
CROSS_TENANT_VENDOR="${NS_CROSS_TENANT_VENDOR:-17}"
#
# Optional. Set to a vendor whose settings row is SOFT-DELETED to exercise :C.
# No such row exists today and none can be made over HTTP — see the header.
SOFT_DELETED_VENDOR="${NS_SOFT_DELETED_VENDOR:-}"

WRITE=0

usage() {
  sed -n '3,50p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --write            also run the mutating tests (creates/modifies a real row)
  --base URL         override the base URL (default http://hunchentoot.local)
  -h, --help         this text

Environment:
  NS_PHONE              vendor phone (login form field "phone")      [required]
  NS_PASSWORD           vendor password                              [required]
  NS_DEMO_VENDOR        the logged-in vendor's row-id                (default 1)
  NS_FREE_VENDOR        a same-tenant vendor with no settings row    (default 5)
  NS_CROSS_TENANT_VENDOR a vendor in another tenant that HAS settings (default 17)
  NS_SOFT_DELETED_VENDOR a vendor whose settings row is soft-deleted  (unset)
  NS_EXPECT_U=1         GATED :U run. Pauses after login so the database can be
                        stopped, asserts 503, then exits. Restart the DB after.
  BASE                  base URL, same as --base
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
  echo "       Same login as the warehouse and products scripts — the session company IS the tenant." >&2
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

PASS=0; FAIL=0; KNOWN=0; SKIP=0
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

skip() { SKIP=$((SKIP+1)); printf '  %sSKIP%s %-46s %s\n' "$Y" "$N" "$1" "$2"; }
info() { printf '  %s----%s %-46s %s\n' "$Y" "$N" "$1" "$2"; }

body_field() {
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$BODY" | head -1
}
body_bool() {
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/p" "$BODY" | head -1
}
has_key() { grep -qF "\"$1\"" "$BODY"; }

section() { printf '\n== %s\n' "$1"; }

bail_if_not_loaded() {
  if grep -qF '"no_such_endpoint"' "$BODY"; then
    printf '\n%sThe vendor payment routes are NOT REGISTERED in the running image.%s\n' "$R" "$N"
    printf 'This is the EXPECTED state on a fresh checkout: nst-bl-vndvpmapi.lisp has\n'
    printf 'never been loaded. In the Lisp image:\n'
    printf '  (asdf:load-system :nstores)\n'
    printf '  (list-api-routes)      ; expect the 3 /hhub/api/v1/vendor/payment/methods rows\n'
    printf '  (list-action-routes)   ; expect route-vpm-*\n'
    printf 'Note a .fasl beside the source does NOT reach the app: it loads from\n'
    printf '/home/hunchentoot/.cache/common-lisp/… (vendor CONTEXT §8.1).\n'
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

req GET "/hhub/api/v1/vendor/payment/methods/$DEMO_VENDOR"
case "$HTTP_CODE" in
  401) printf '\n  %sFATAL%s login did not establish a vendor session (API answered 401).\n' "$R" "$N"
       exit 2 ;;
  000) printf '\n  %sFATAL%s could not reach the API endpoint.\n' "$R" "$N"; exit 2 ;;
esac
bail_if_not_loaded
printf '  session established (authenticated call answered %s)\n' "$HTTP_CODE"

# ── 1b. :U — the gated boundary-failure run ─────────────────────────────────
# PROVISION, NOT A DEFAULT. The :U state cannot be reached while the database is
# up: nothing an HTTP client can send makes the boundary fail, and this suite has
# no way to break the DB on demand. So the assertion lives here, gated, instead of
# being absent — the state stays COVERED BY THIS FILE even though a normal run
# cannot produce it.
#
# 🚨 THE ORDER IS FORCED: LOGIN NEEDS THE DATABASE. `dodvendlogin` queries
# DOD_VEND_PROFILE, so killing MySQL before the session exists fails section 1
# with exit 2 and never reaches the assertions. The database must therefore be
# stopped AFTER login — which is exactly why this block PAUSES and waits for the
# operator, rather than being a flag-and-go.
#
#   terminal 1:  NS_EXPECT_U=1 ./smoke-vendor-payment-api.sh
#                (wait for the prompt)
#   terminal 2:  sudo systemctl stop mysql        # or the KILL runbook, CONTEXT §14
#   terminal 1:  press Enter
#   terminal 2:  sudo systemctl start mysql       # restore
#
# It exits immediately after these two checks: with the database down every later
# section would fail for the same reason, and a dozen red lines would bury the two
# that carry the information.
if [ "${NS_EXPECT_U:-}" = "1" ]; then
  printf '\n== 1b. :U boundary failure  (GATED RUN)\n'
  info "session is up" "now STOP the database, then press Enter"
  read -r _ || true
  req GET "/hhub/api/v1/vendor/payment/methods/$DEMO_VENDOR"
  expect ":U database unanswerable → 503" 503 "\"unknown\""
  req GET "/hhub/api/v1/vendor/payment/methods/$FREE_VENDOR"
  expect ":U is not a miss → 503, NOT 404" 503 "\"unknown\""
  req GET "/hhub/api/v1/vendor/payment/methods/abc"
  expect ":U survives the parse guard → 503" 503 "\"unknown\""
  printf '\n  (The last one matters: a non-numeric id is turned into a NOT-FOUND fact\n'
  printf '   BEFORE any DB call, so it exercises a path that must NOT reach the\n'
  printf '   boundary at all. If it answers 503 the parse guard has been lost.)\n'
  printf '\n   RESTART THE DATABASE NOW.\n'
  printf '\n─────────────────────────────────────────────\n'
  printf 'passed %s   failed %s   known-defects %s   skipped %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
  [ "$FAIL" -gt 0 ] && exit 1
  exit 0
fi

# ── 2. GET is the exists check (read-only) ──────────────────────────────────
# There is no /exists endpoint, on purpose: this GET's 200/404 IS the answer. So
# these two checks are not "read tests" — they are the existence contract.
section "2. GET = the existence check (read-only)"

req GET "/hhub/api/v1/vendor/payment/methods/$DEMO_VENDOR"
expect ":T logged-in vendor → 200" 200 "\"rowId\""

if [ "$HTTP_CODE" = 200 ]; then
  info "keys published" "$(grep -o '"[a-zA-Z]*":' "$BODY" | tr -d '":' | tr '\n' ' ')"
  for k in rowId codEnabled upiEnabled payProvidersEnabled walletEnabled payLaterEnabled active; do
    if has_key "$k"; then
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s present\n' "$G" "$N" "field $k"
    else
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s MISSING from the response\n' "$R" "$N" "field $k"
    fi
  done
  # The withheld fields. A leak here is a correctness bug, not a credential leak —
  # this table holds no secrets — but vendorId in particular is the parent link
  # that !update refuses for BOLA reasons, so it must not appear.
  for k in vendorId tenantId company createdAt updatedAt deletedState; do
    if has_key "$k"; then
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s LEAKED into the response\n' "$R" "$N" "withheld $k"
    else
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s withheld\n' "$G" "$N" "field $k"
    fi
  done
fi

# A same-tenant vendor with NO row: this is the "the slot is free" answer, and it
# is what tells a client a POST is allowed — not a 5xx and not a 200 with nulls.
req GET "/hhub/api/v1/vendor/payment/methods/$FREE_VENDOR"
expect ":F same-tenant vendor, no row → 404" 404 "\"not_found\""

# ── 3. BELNAP: the four states ──────────────────────────────────────────────
# Not enough that each state "returns something" — they must stay DISTINCT,
# because collapsing them is the failure mode this layer exists to prevent.
#
#   :T → 200  the settings exist        :C → 409  two of our rules disagree
#   :F → 404  this vendor has none      :U → 503  we could not find out
#
# 🚨 :C IS ONLY EVER PRODUCED BY A CREATE, and the table above says 409 without
# saying where, which is how it gets tested in the wrong place. Only ?exists
# reads with :include-deleted; only make calls ?exists; fetch and !update both
# filter the deleted row out and answer :F. So :C is asserted on POST and the
# GET on the same fixture must be 404. See the :C block below.
#
# :F has FIVE triggers, all genuinely absent but for different reasons — and here
# the identity being addressed is the PARENT VENDOR, so the triggers are about
# the vendor, not about a row-id.
section "3. Belnap states"

# --- :T ---------------------------------------------------------------------
req GET "/hhub/api/v1/vendor/payment/methods/$DEMO_VENDOR"
expect ":T live settings → 200 + entity" 200 "\"rowId\""

# --- :F ---------------------------------------------------------------------
req GET "/hhub/api/v1/vendor/payment/methods/$FREE_VENDOR"
expect ":F vendor with no settings → 404" 404 "\"not_found\""

req GET "/hhub/api/v1/vendor/payment/methods/$CROSS_TENANT_VENDOR"
expect ":F another tenant's vendor → 404 (BOLA)" 404 "\"not_found\""

req GET "/hhub/api/v1/vendor/payment/methods/999999"
expect ":F absent vendor id → 404" 404 "\"not_found\""

req GET "/hhub/api/v1/vendor/payment/methods/abc"
expect ":F non-numeric id → 404 (not 500)" 404 "\"not_found\""

req GET "/hhub/api/v1/vendor/payment/methods/999999999999999999"
expect ":F absurd id → 404 (MySQL: 0 rows, no error)" 404 "\"not_found\""

# --- :C ---------------------------------------------------------------------
# 🚨 :C IS NOT OBSERVABLE THROUGH THIS GET, AND THAT IS CORRECT — NOT A LIMIT OF
# THE FIXTURE. Only ?exists reads the table with :include-deleted, and only make
# calls ?exists. fetch and !update both call select-vpm-by-vendor-in-tenant
# WITHOUT it, so a soft-deleted row is filtered out of the WHERE clause and the
# read answers :F → 404. The contradiction ("the slot is taken" ⊔ "there are no
# settings here") is a fact about the SLOT, which is what a CREATE asks about —
# so it belongs on POST and nowhere else.
#
# Hence TWO assertions on one fixture, and the first one is the interesting one:
#   POST → 409  the singleton law refuses, with a reason naming the soft-deleted row
#   GET  → 404  the row is invisible, exactly as नियम-2 requires
# A GET answering 409 here would mean the read had started leaking deleted rows.
if [ -n "$SOFT_DELETED_VENDOR" ]; then
  req POST "/hhub/api/v1/vendor/payment/methods" \
      -H 'Content-Type: application/json' \
      -d "{\"vendorId\":$SOFT_DELETED_VENDOR}"
  expect ":C soft-deleted row holds the slot, POST → 409" 409 "\"conflict\""

  req GET "/hhub/api/v1/vendor/payment/methods/$SOFT_DELETED_VENDOR"
  expect ":F the same row is INVISIBLE to GET → 404" 404 "\"not_found\""
else
  skip ":C soft-deleted slot" "no fixture — see the SQL below"
  printf '       To create it (hhubdb), against a vendor in the SESSION tenant that has\n'
  printf '       no settings row yet:\n'
  printf '         INSERT INTO DOD_VPAYMENT_METHODS\n'
  printf '           (VENDOR_ID, TENANT_ID, DELETED_STATE, ACTIVE_FLAG)\n'
  printf '           VALUES (%s, 2, '"'"'Y'"'"', '"'"'Y'"'"');\n' "$FREE_VENDOR"
  printf '       then: NS_SOFT_DELETED_VENDOR=%s %s\n' "$FREE_VENDOR" "$(basename "$0")"
  printf '       (No --write needed: both :C assertions are POST-free — the 409 comes\n'
  printf '        from make refusing BEFORE any INSERT, so nothing is written.)\n'
  printf '       CAREFUL: this consumes the same vendor id %s that the :F free-slot\n' "$FREE_VENDOR"
  printf '       checks use. Use a DIFFERENT vendor (2, 6, 7, 8, 9, 10 or 11) and set\n'
  printf '       NS_FREE_VENDOR to another, or the :F assertions will fail.\n'
fi

# --- anti-collapse: the states are DISTINCT ---------------------------------
req GET "/hhub/api/v1/vendor/payment/methods/999999"
if [ "$HTTP_CODE" = 404 ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-46s 404 (a miss is NOT reported as 503)\n' "$G" "$N" "anti-collapse :F ≠ :U"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s :F answered %s, not 404\n' "$R" "$N" "anti-collapse :F ≠ :U" "$HTTP_CODE"
fi

req GET "/hhub/api/v1/vendor/payment/methods/$DEMO_VENDOR"
if [ "$HTTP_CODE" = 200 ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-46s 200 (existence is not reported as 404)\n' "$G" "$N" "anti-collapse :T ≠ :F"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s :T answered %s, not 200\n' "$R" "$N" "anti-collapse :T ≠ :F" "$HTTP_CODE"
fi

skip ":U boundary failure" "not reachable while the DB is up — rerun with NS_EXPECT_U=1"

# ── 4. negative auth + routing (read-only) ──────────────────────────────────
section "4. negative cases (read-only)"

HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' "$BASE/hhub/api/v1/vendor/payment/methods/$DEMO_VENDOR" 2>"$ERR")"
expect "GET with NO session cookie" 401

req GET "/hhub/api/v1/vendor/payment/methods/$DEMO_VENDOR/nonsense"
expect "GET unbound sub-path → no_such_endpoint" 404 "\"no_such_endpoint\""

# The singleton law: this vendor already HAS settings, so a second create must be
# refused as a CONTRADICTION (409), not silently accepted and not 500. The
# database does NOT enforce this — DOD_VPAYMENT_METHODS has no unique key — so
# this is the only thing standing between a vendor and several contradictory
# settings rows.
section "5. duplicate create → 409 (read-only: nothing is written)"

req POST "/hhub/api/v1/vendor/payment/methods" \
    -H 'Content-Type: application/json' \
    -d "{\"vendorId\":$DEMO_VENDOR}"
expect "POST for a vendor that already has settings" 409 "\"conflict\""

# The referential law. DOD_VPAYMENT_METHODS declares NO FOREIGN KEY, so MySQL
# would accept an orphan vendor_id; the domain applies the missing constraint by
# fetching the parent first. A vendor that does not resolve is 404 — the singleton
# question is moot, so it must NOT be a 409.
req POST "/hhub/api/v1/vendor/payment/methods" \
    -H 'Content-Type: application/json' \
    -d '{"vendorId":999999}'
expect "POST for a non-existent vendor → 404 (no FK in the schema)" 404 "\"not_found\""

req POST "/hhub/api/v1/vendor/payment/methods" \
    -H 'Content-Type: application/json' \
    -d '{"vendorId":"abc"}'
expect "POST with an unparseable vendorId → 404" 404 "\"not_found\""

# --- the KNOWN 4xx-taxonomy paths -------------------------------------------
req POST "/hhub/api/v1/vendor/payment/methods" \
    -H 'Content-Type: application/json' \
    -d '{}'
expect-known "POST with no vendorId" 400 "" \
  "KNOWN K2: vpm-field-rejected names the field, but the taxonomy maps any condition to 500. 400 is right."

req PUT "/hhub/api/v1/vendor/payment/methods/$DEMO_VENDOR" \
    -H 'Content-Type: application/json' \
    -d '{"walletEnabled":null}'
expect-known "PUT with a null flag" 400 "" \
  "KNOWN K3: refusing a NULL flag is CORRECT domain law (a NULL reads back as \"Y\" and would silently ENABLE the method); only the status is wrong."

req PUT "/hhub/api/v1/vendor/payment/methods/$DEMO_VENDOR" \
    -H 'Content-Type: application/json' \
    -d "{\"vendorId\":$FREE_VENDOR}"
expect-known "PUT with vendorId in the body" 400 "" \
  "KNOWN K4: the parent link is refused by design (intra-tenant BOLA); only the status is wrong."

# ── 6. writes (opt-in) ──────────────────────────────────────────────────────
if [ "$WRITE" = 1 ]; then
  section "6. create / update  (WRITES TO THE LIVE DATABASE)"

  # CREATE — the free slot. Vendor 5 is a real tenant-2 vendor with no row.
  req POST "/hhub/api/v1/vendor/payment/methods" \
      -H 'Content-Type: application/json' \
      -d "{\"vendorId\":$FREE_VENDOR}"
  expect "POST create for a vendor with no settings" 201 "\"rowId\""
  NEW_RID="$(body_field rowId)"
  [ -n "$NEW_RID" ] && printf '       created rowId=%s for vendor %s\n' "$NEW_RID" "$FREE_VENDOR"

  # DEFAULTS — the flags the caller did NOT send must be the live DDL defaults.
  # PAYLATERENABLED is the interesting one: its DDL default is 'N' while the
  # legacy view-class claims :void-value "Y".
  if [ "$HTTP_CODE" = 201 ]; then
    for pair in "codEnabled:true" "upiEnabled:true" "payProvidersEnabled:true" \
                "walletEnabled:true" "payLaterEnabled:false" "active:true"; do
      k="${pair%%:*}"; want="${pair##*:}"; got="$(body_bool "$k")"
      if [ "$got" = "$want" ]; then
        PASS=$((PASS+1)); printf '  %sPASS%s %-46s %s\n' "$G" "$N" "default $k" "$got"
      else
        FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s got %s, want %s\n' "$R" "$N" "default $k" "${got:-absent}" "$want"
      fi
    done
  fi

  # The singleton law again, now against the row we just made.
  req POST "/hhub/api/v1/vendor/payment/methods" \
      -H 'Content-Type: application/json' \
      -d "{\"vendorId\":$FREE_VENDOR}"
  expect "POST again for the same vendor → 409" 409 "\"conflict\""

  # UPDATE — partial. Only supplied flags change.
  req PUT "/hhub/api/v1/vendor/payment/methods/$FREE_VENDOR" \
      -H 'Content-Type: application/json' \
      -d '{"walletEnabled":"N"}'
  expect "PUT update (partial)" 200 "\"rowId\""

  req GET "/hhub/api/v1/vendor/payment/methods/$FREE_VENDOR"
  expect "GET after update" 200 "\"rowId\""

  # 🚨 K1 — THE ONE THAT MATTERS. The create above took NO flags, so it cannot
  # show the defect. This is the assertion that does: ask for payLater ENABLED
  # and cod DISABLED, then read back. Both must hold.
  req PUT "/hhub/api/v1/vendor/payment/methods/$FREE_VENDOR" \
      -H 'Content-Type: application/json' \
      -d '{"codEnabled":"N","payLaterEnabled":"Y"}'
  info "PUT codEnabled=N, payLaterEnabled=Y" "$HTTP_CODE"
  req GET "/hhub/api/v1/vendor/payment/methods/$FREE_VENDOR"
  COD="$(body_bool codEnabled)"; PL="$(body_bool payLaterEnabled)"
  if [ "$COD" = "false" ] && [ "$PL" = "true" ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s cod=false payLater=true\n' "$G" "$N" "flags round-trip through PUT"
  else
    KNOWN=$((KNOWN+1))
    printf '  %sKNOWN%s %-45s cod=%s payLater=%s, want false/true\n' "$Y" "$N" \
           "flags round-trip through PUT" "${COD:-absent}" "${PL:-absent}"
    printf '        KNOWN K1: the JSON keys normalise to hyphenated initargs (:COD-ENABLED,\n'
    printf '        :PAY-LATER-ENABLED) but nst-vnd-vpm declares :CODENABLED and\n'
    printf '        :PAYLATERENABLED, so extract-domain-initargs DROPS both and the stored\n'
    printf '        values are whatever was there before. The client is told 200 and nothing\n'
    printf '        reports a problem. Fix in nst-dal-vndvpm.lisp — see the header.\n'
  fi

  printf '\n  cleanup: THIS SURFACE HAS NO DELETE, so the row just created stays.\n'
  printf '           To remove it, in mysql (hhubdb):\n'
  printf '             DELETE FROM DOD_VPAYMENT_METHODS\n'
  printf '              WHERE VENDOR_ID = %s AND ROW_ID = %s;\n' "$FREE_VENDOR" "${NEW_RID:-<rowId>}"
  printf '           Left in place, vendor %s now HAS settings with the DDL defaults —\n' "$FREE_VENDOR"
  printf '           which also retires the :F fixture for the next read-only run.\n'
else
  section "6. create / update"
  printf '  SKIPPED — read-only run. Re-run with --write to exercise them.\n'
  printf '  (They create a real payment-settings row for vendor %s in the live database.)\n' "$FREE_VENDOR"
fi

# ── summary ─────────────────────────────────────────────────────────────────
printf '\n─────────────────────────────────────────────\n'
printf 'passed %s   failed %s   known-defects %s   skipped %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
if [ "$FAIL" -gt 0 ]; then
  printf '\nfailed checks are UNEXPECTED (not in the known-defect list). Server detail:\n'
  printf '  ssh <server> tail -40 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
  printf 'REMEMBER: sentinel-derived responses (404/409/503) leave NO trace in that log —\n'
  printf 'only CONDITION-derived failures are recorded (vendor CONTEXT §8.6).\n'
  exit 1
fi
if [ "$KNOWN" -gt 0 ]; then
  printf '\nThe %s known defect(s) above are encoded deliberately — see the header.\n' "$KNOWN"
  printf 'K1 is the one to fix first: until it is, no flag can be set over HTTP.\n'
fi
printf 'no unexpected failures\n'
exit 0
