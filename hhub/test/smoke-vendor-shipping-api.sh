#!/usr/bin/env bash
#
# smoke-vendor-shipping-api.sh — smoke-test the VENDOR SHIPPING JSON API
# (conflodis2 + apidefs2), the nst-vnd-shp entity.
#
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-vendor-shipping-api.sh
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-vendor-shipping-api.sh --write
#
# READ-ONLY by default. --write adds the POST and the PUTs that MUTATE a real row
# in the live database.
#
# Exit codes:  0 = every result matched its expectation
#              1 = at least one result did NOT match
#              2 = setup failure (unreachable, no session) — the API wasn't tested
#
# ── WHAT THIS ENTITY IS ─────────────────────────────────────────────────────
# nst-vnd-shp is a vendor's SHIPPING CONFIGURATION: one row per vendor for the
# vendor's whole lifetime (DOD_SHIPPING_METHODS) plus a COLLECTION of zones
# (DOD_VENDOR_SHIP_ZONES) that only the ZONEWISE method uses. Two tables, one
# entity — the reason is in nst-dal-vndshp.lisp's header, and the reason the
# suite has more to say than the payment twin is that the two tables must AGREE:
# the rate table's column headers ARE zone names.
#
#   POST   /hhub/api/v1/vendor/shipping
#   GET    /hhub/api/v1/vendor/shipping                      (list, tenant-wide)
#   GET    /hhub/api/v1/vendor/shipping/{vendorId}
#   PUT    /hhub/api/v1/vendor/shipping/{vendorId}
#   PUT    /hhub/api/v1/vendor/shipping/{vendorId}/rate-table
#   PUT    /hhub/api/v1/vendor/shipping/{vendorId}/zones
#
# NO DELETE, by design: "this vendor does not ship" is expressed IN BAND —
# active_flag "N", or defaultshippingmethod left null so no method is selected.
# A soft-deleted row would occupy the singleton slot while नियम-2 makes it
# invisible, so the vendor could never configure shipping again. CONSEQUENCE FOR
# THIS SCRIPT: it cannot clean up after itself — see the purge SQL at the end.
#
# NO /exists ENDPOINT either: the GET's 200-vs-404 IS the answer, and section 2
# asserts it there.
#
# ── KNOWN DEFECTS THIS SCRIPT ENCODES ───────────────────────────────────────
# Asserted against the CORRECT contract but reported as `KNOWN` (not `FAIL`) so a
# real regression stands out. If a KNOWN check starts passing, fix this script:
# the defect was repaired.
#
#  K1. 🚨 EVERY MULTI-WORD FIELD IS UNSETTABLE IN THE PUBLISHED SPELLING. This is
#      the same defect the payment suite found (its K1), and it is WORSE HERE
#      because almost every field of this entity is multi-word.
#        apidefs2 normalises JSON keys through api-camel->lisp-name
#        (nst-bl-apidefs2.lisp:266), which hyphenates at case boundaries:
#            "rateTableCsv"          → :RATE-TABLE-CSV
#            "freeShippingEnabled"   → :FREE-SHIPPING-ENABLED
#            "defaultShippingMethod" → :DEFAULT-SHIPPING-METHOD
#            "flatRatePrice"         → :FLAT-RATE-PRICE      … and so on
#        but nst-vnd-shp declares un-hyphenated initargs taken from the COLUMN
#        names: :RATETABLECSV, :FREESHIPENABLED, :DEFAULTSHIPPINGMETHOD,
#        :FLATRATEPRICE, … extract-domain-initargs is a MOP filter against the
#        declared initargs, so every one of them is DROPPED and the write
#        succeeds having changed nothing. The client is told 200.
#        WHICH FIELDS SURVIVE camelCase: only the single-word ones —
#        vendorId → :VENDOR-ID, activeFlag → :ACTIVE-FLAG, zones → :ZONES,
#        shpName → :SHP-NAME, rowId, company. 11 of 17 do NOT.
#        WORKAROUND, used by the write section below: send the keys in the FLAT
#        LOWER-CASE column spelling — {"freeshipenabled":"Y","flatrateprice":99}
#        — which normalises to :FREESHIPENABLED and DOES reach the entity. So the
#        API is usable today, but the request spelling differs from the response
#        spelling, which is the real defect: a client that reads
#        freeShippingEnabled back cannot send it in again.
#        FIX (nst-dal-vndshp.lisp): re-declare the initargs in the hyphenated form
#        the JSON contract already publishes. The slot NAMES and accessors can
#        stay as they are — the copiers read them by slot name.
#      🚨 THE TWO UPLOAD ROUTES ARE IMMUNE, and that is worth knowing before
#      "fixing" them: route-vndshp-upload-ratetable and -zones read the payload
#      themselves (vndshp-body-value) and accept BOTH spellings, so rateTableCsv
#      and zones reach the verb from the file-shaped body. Only the shared PUT and
#      the POST go through the ferry and lose the keys.
#
#  K2. THE 4xx TAXONOMY GAP (CONTEXT §7.2) on the WRITE-side refusals. The domain
#      signals vndshp-field-rejected with the reason named; the API maps any
#      condition to 500 where 400 is right. Affects: POST with no vendorId and PUT
#      with vendorId in the body (§5), and every L1–L5 law refusal (§6b).
#      MEASURED 2026-09-16: both of the read-only ones answer 500.
#
#  K3. 🚨 A MALFORMED FILTER IS REPORTED AS A DATABASE OUTAGE — AND THE 4xx
#      TAXONOMY FIX WILL NOT REACH IT. The same class as K2 with a different and
#      worse symptom; the response BODY is what shows it:
#
#        GET /hhub/api/v1/vendor/shipping?sort-by=nonsense      → 503
#        GET /hhub/api/v1/vendor/shipping?method=nonsense       → 503
#        GET /hhub/api/v1/vendor/shipping?status=suspended      → 503
#        GET /hhub/api/v1/vendor/shipping?offset=1 (no limit)   → 503
#
#      body: {"error":"unknown","reason":"The boundary could not answer: Shipping
#             enumerate, tenant 2: the database call did not answer — the
#             configuration list contents are unknown"}
#
#      THE DATABASE ANSWERED PERFECTLY. The client sent a bad filter. Three
#      falsehoods, in increasing order of cost:
#        1. the status is wrong — 400 is right, and 503 tells the client to RETRY
#           something that can never succeed;
#        2. the REASON is wrong — it names a boundary failure, so whoever reads the
#           API response or the log goes looking at MySQL;
#        3. a client typo is indistinguishable from a real outage, which is exactly
#           what the four-valued layer exists to keep apart.
#
#      THE MECHANISM, and why the taxonomy cannot fix it: the refusals come from
#      validate-vndshp-sort-args / vndshp-method-filter-clause /
#      vndshp-status-clause / the offset guard, and ALL of them run INSIDE
#      with-nst-db-read-all (nst-bl-vndshp.lisp, enumerate →
#      select-vndshp-by-filter). That macro's catch-all turns ANY error into a :U
#      knowledge object — the trap CONTEXT §6.5 records for with-nst-db-create,
#      here on the READ path — so the condition is gone before any taxonomy sees
#      it. Fixing the taxonomy changes make/!update's 500 into a 400 and leaves
#      these four at 503.
#      🚨 THE FIX IS THEREFORE IN THE DOMAIN, NOT THE TAXONOMY: validate the query
#      arguments and build the WHERE clauses BEFORE the macro is entered, so a
#      client error escapes as a condition while a genuine boundary failure still
#      becomes :U. The taxonomy (a separate, shared fix) then turns it into 400.
#      ⚠ NOT A SHIPPING-ONLY DEFECT. The warehouse's validate-sort-args and the
#      profile's enumerate have the same shape and want the same treatment; the
#      shipping suite is simply the first to assert on the response BODY rather
#      than only the status code — which is why the other suites' KNOWN entries say
#      500 where these say 503.
#
#  K4. 🚨 AN OFF FLAG PUBLISHES AS null, NOT false — AND IT CANNOT BE FIXED IN
#      THIS ENTITY. Measured on the config the create returned:
#
#        {"freeShippingEnabled":null,"flatRateEnabled":null,"zoneWiseEnabled":true,
#         "externalPartnerEnabled":null,"storePickupEnabled":null,…,"active":true}
#
#      The header of VndShipResponseModel says flags publish as BOOLEANS. T does
#      (→ true). NIL does NOT: cl-json's token table maps BOTH literals to NIL —
#
#          +json-lisp-symbol-tokens+ = (("true" . t) ("null" . nil) ("false" . nil))
#                                      common.lisp:75
#
#      — and the encoder takes the FIRST rassoc match, so a NIL value is written
#      as "null" and can never be written as "false". The explicit encoder would
#      honour (:false), but it is not what the tree uses: conflodis2 calls plain
#      encode-json-to-string (nst-bl-conflodis2.lisp:214), i.e. the GUESSING one,
#      for which (:false) is a one-element ARRAY.
#
#      So `null` is not a shipping slip — it is what the platform can currently
#      emit, and every entity publishing flags through *-flag->boolean has an off
#      flag reading as null: products, the vendor profile, vendor payment, and
#      shipping. A client cannot tell "off" from "not known", and cannot round-trip
#      it (payment actively REFUSES a null flag).
#      THE FIX IS NOT IN ANY ONE ENTITY: either switch conflodis2 to
#      with-explicit-encoder (which changes how EVERY list value in EVERY response
#      encodes — a real blast radius, and the reason it is not a one-line change),
#      or publish the raw "Y"/"N" the way the warehouse does. That is a convention
#      decision for whoever owns the wire contract, which is exactly what the
#      CONTEXT §11.4 split-contract note says about this seam.
#
# ── WHAT IS ASSERTED, AND WHAT IS NOT ───────────────────────────────────────
# BE HONEST ABOUT THIS WHEN READING A GREEN RUN — only TWO of the four Belnap
# states are asserted by default:
#
#   :T  asserted. §2 and §3.
#   :F  asserted. FIVE triggers, all about the VENDOR (this entity is addressed
#       by its parent, not by a row-id).
#   :C  ASSERTED ONLY IF A FIXTURE EXISTS. Needs a SOFT-DELETED shipping row: all
#       six live rows are deleted_state='N' and this surface has no delete!, so it
#       cannot be made over HTTP. With NS_SOFT_DELETED_VENDOR unset the suite
#       SKIPs and prints the SQL that creates it. 🚨 The assertion is on POST
#       (409), not on GET — only ?exists reads with :include-deleted.
#   :U  NOT ASSERTED IN A DEFAULT RUN, but PROVISIONED behind NS_EXPECT_U=1, which
#       pauses after login so the database can be stopped, runs the :U checks
#       alone, and exits (section 1b).
#
# ── WHY THE L1–L5 LAW PROBES ARE IN THE --write SECTION ONLY ────────────────
# The five laws are refusals, and a refusal writes nothing — so they LOOK like
# read-only tests. They are not, for a reason worth stating: a law probe is only
# safe while the law holds. If someone breaks L1, the same request stops being a
# refusal and becomes a real write. On the shared PUT that write lands on the
# DEMO VENDOR'S LIVE ROW, which is the row a real checkout prices against. So the
# probes run only under --write, where a write is expected and its effects are
# named in the cleanup. The read-only sections assert only refusals that are
# structurally incapable of writing: the singleton 409 and the referential 404,
# both of which come from make's :around BEFORE any INSERT.
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

# FIXTURES — every one verified against the live database (hhubdb, 2026-09-16).
# DOD_SHIPPING_METHODS holds six rows in total:
#
#   ROW VENDOR TENANT  FREE FLAT TABLE EXT PICKUP DEFAULT  ZONES
#    2     1     2      Y   N    Y    N    Y     TRS       5     ← zonewise, + partner creds
#    4     3     2      Y   Y    N    N    Y     FRS       5     ← flat rate, zones stored, zonewise OFF
#    7     4     2      Y   N    N    N    Y     FSH       0     ← free shipping, NO zones
#    3    17     5      Y   N    N    N    Y     FSH       5     ← another tenant
#    5    18     5      Y   NULL NULL NULL NULL  NULL    0     ← a genuinely partial row
#    6    19     5      Y   N    NULL N    Y     FSH       5
#
# The demo vendor IS the identity the suite logs in as: phone 9999999990 is
# DOD_VEND_PROFILE.ROW_ID 1, TENANT_ID 2, and its shipping row is the RICHEST one
# — zonewise enabled, default TRS, five zones, AND shippartnerkey /
# shippartnersecret populated. It is therefore the :T fixture, the 409 fixture and
# the secret-leak fixture.
DEMO_VENDOR="${NS_DEMO_VENDOR:-1}"
#
# A tenant-2 vendor with NO shipping row — the slot is genuinely free, so the
# create path and the :F checks have a target. Vendors 2, 5, 6, 7, 8, 9, 10 and 11
# were all in this state on 2026-09-16. THIS IS THE VALUABLE ONE: unlike the vendor
# profile suite, which had to invent a soft-deleted fixture, this entity's create
# path has a real empty slot already.
#
# 🚨 ITS DEFAULT IS EMPTY ON PURPOSE — the id is RESOLVED AT RUN TIME (§1a), because
# a --write run CONSUMES it: the create fills the slot and there is no delete!, so
# a hard-coded id works exactly once and the second run's :F checks fail against a
# vendor the first run had already filled. Set NS_FREE_VENDOR to pin one; leave it
# unset to let the suite probe NS_FREE_CANDIDATES and take the first that answers
# 404.
# NOTE the free vendors all have DOD_VEND_PROFILE.SHIPPING_ENABLED = 'N'. That
# column is the VENDOR's, not this entity's, and no verb here reads or writes it
# (a shipping configuration can exist while the vendor has shipping switched off
# — the checkout is what consults the flag). Recorded so nobody "fixes" it here.
FREE_VENDOR="${NS_FREE_VENDOR:-}"
#
# A tenant-2 vendor whose configuration has NO ZONES and zonewise OFF — the state
# a flat-rate or free-shipping vendor is legitimately in, and the fixture that
# proves a zone-less configuration is not an incomplete one.
FLAT_VENDOR="${NS_FLAT_VENDOR:-4}"
#
# A tenant-2 vendor with zones STORED while zonewise is DISABLED. The zonewise
# laws are skipped in that state by design (the matrix is not consulted), so this
# is the fixture that shows zones surviving a method change.
ZONED_VENDOR="${NS_ZONED_VENDOR:-3}"
#
# A vendor in ANOTHER tenant (17 is tenant 5) that HAS a configuration and zones.
# Read from a tenant-2 session it must be 404 — the tenant filter makes another
# tenant's vendor-id indistinguishable from one that never existed. That is the
# security-relevant assertion (OWASP API1:2023 BOLA): the id in the URL is an
# ADDRESS, never an authorization.
CROSS_TENANT_VENDOR="${NS_CROSS_TENANT_VENDOR:-17}"
#
# Optional. Set to a vendor whose shipping row is SOFT-DELETED to exercise :C.
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
  NS_FREE_VENDOR        pin the free-slot vendor (default: PROBED at run time)
  NS_FREE_CANDIDATES    ids to probe for a free slot  (default "2 5 6 7 8 9 10 11")
  NS_FLAT_VENDOR        a same-tenant vendor with no zones           (default 4)
  NS_ZONED_VENDOR       a same-tenant vendor with zones, zonewise off (default 3)
  NS_CROSS_TENANT_VENDOR a vendor in another tenant that HAS a row   (default 17)
  NS_SOFT_DELETED_VENDOR a vendor whose shipping row is soft-deleted  (unset)
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
  echo "       Same login as the warehouse, products and payment scripts — the session company IS the tenant." >&2
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

# expect-refused NAME WHY — a write that MUST be refused and must leave the stored
# state alone. The status is asserted as 500 (the taxonomy gap, K2) and the caller
# re-reads afterwards to prove nothing was written. Kept separate from
# expect-known so the read-back that follows reads as part of the same assertion.
expect-refused() {
  local name="$1" why="$2"
  if [ "$HTTP_CODE" = "500" ] || [ "$HTTP_CODE" = "400" ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s %s (refused)\n' "$G" "$N" "$name" "$HTTP_CODE"
    [ "$HTTP_CODE" = "500" ] && KNOWN=$((KNOWN+1))
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-46s got %s — NOT refused; the write may have landed\n' "$R" "$N" "$name" "$HTTP_CODE"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
  printf '        %s\n' "$why"
}

skip() { SKIP=$((SKIP+1)); printf '  %sSKIP%s %-46s %s\n' "$Y" "$N" "$1" "$2"; }
info() { printf '  %s----%s %-46s %s\n' "$Y" "$N" "$1" "$2"; }

# 🚨 THESE USE grep -o, NOT sed WITH A LEADING `.*`, AND THAT IS THE POINT.
# `sed -n "s/.*\"key\":\"\([^\"]*\)\".*/\1/p"` is GREEDY: the `.*` eats as much
# as it can, so it reports the LAST occurrence on the line, not the first. For
# `rowId` that is not the configuration's id at all — it is the LAST ZONE's,
# because the zones array comes later in the body. Two --write runs printed
# "created rowId=22"/"rowId=24" for configuration rows that were really ROW_ID 8
# and 9, and the cleanup SQL the suite prints would therefore have deleted
# nothing (the id belongs to DOD_VENDOR_SHIP_ZONES, not DOD_SHIPPING_METHODS).
# grep -o takes the FIRST match deterministically, which is what every use here
# means: the entity's own fields precede its nested zones.
body_field() {
  grep -o "\"$1\":\"[^\"]*\"" "$BODY" | head -1 | sed 's/^[^:]*://; s/^"//; s/"$//'
}
# 🚨 NUMBERS ARE NOT STRINGS, and this cost a false failure. JSON has ONE number
# type, so a money column comes back as `"flatRatePrice":99.0` — unquoted — and a
# `"key":"value"` pattern cannot see it. A write that SUCCEEDED (the row really
# did hold 99.00) was reported as `got absent`, which reads exactly like a dropped
# field. Use body_number for anything the response publishes as a NUMBER; a null
# value matches nothing and reads as empty, which is correct.
body_number() {
  grep -o "\"$1\":-\{0,1\}[0-9][0-9.]*" "$BODY" | head -1 | sed 's/^[^:]*://'
}
body_bool() {
  grep -o "\"$1\":\(true\|false\)" "$BODY" | head -1 | sed 's/^[^:]*://'
}
has_key() { grep -qF "\"$1\"" "$BODY"; }
# How many CONFIGURATIONS the response carries. "defaultShippingMethod" appears
# once per configuration and never inside a zone, unlike "rowId" — every zone has
# a rowId too, so counting that would count zones.
count_configs() { grep -o '"defaultShippingMethod"' "$BODY" | wc -l | tr -d ' '; }

section() { printf '\n== %s\n' "$1"; }

bail_if_not_loaded() {
  if grep -qF '"no_such_endpoint"' "$BODY"; then
    printf '\n%sThe vendor shipping routes are NOT REGISTERED in the running image.%s\n' "$R" "$N"
    printf 'This is the EXPECTED state on a fresh checkout: nst-bl-vndshpapi.lisp has\n'
    printf 'never been loaded. In the Lisp image:\n'
    printf '  (asdf:load-system :nstores)\n'
    printf '  (list-api-routes)      ; expect the 6 /hhub/api/v1/vendor/shipping rows\n'
    printf '  (list-action-routes)   ; expect route-vndshp-*\n'
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

req GET "/hhub/api/v1/vendor/shipping/$DEMO_VENDOR"
case "$HTTP_CODE" in
  401) printf '\n  %sFATAL%s login did not establish a vendor session (API answered 401).\n' "$R" "$N"
       exit 2 ;;
  000) printf '\n  %sFATAL%s could not reach the API endpoint.\n' "$R" "$N"; exit 2 ;;
esac
bail_if_not_loaded
printf '  session established (authenticated call answered %s)\n' "$HTTP_CODE"

# ── 1a. RESOLVE the free-slot fixture ───────────────────────────────────────
# 🚨 THE FIXTURE ROTS ITSELF, SO IT IS PROBED, NOT ASSUMED. A --write run CREATES
# a configuration for this vendor, and this surface has NO delete! — so the run
# retires the very :F fixture it used. A hard-coded id therefore works exactly
# once: the second --write run reported three failures that were all "vendor 2 now
# HAS a configuration", which reads like a broken domain and is not one.
#
# So, unless the operator names a vendor explicitly, walk the candidates and take
# the first that answers 404 — "this vendor has no configuration", which IS the
# property the :F checks and the create both need. The chosen id is printed, so a
# run says which fixture it used rather than leaving the reader to infer it.
if [ -z "${NS_FREE_VENDOR:-}" ]; then
  FREE_CANDIDATES="${NS_FREE_CANDIDATES:-2 5 6 7 8 9 10 11}"
  FREE_VENDOR=""
  for cand in $FREE_CANDIDATES; do
    req GET "/hhub/api/v1/vendor/shipping/$cand"
    if [ "$HTTP_CODE" = "404" ]; then FREE_VENDOR="$cand"; break; fi
  done
  if [ -z "$FREE_VENDOR" ]; then
    printf '\n  %sFATAL%s no free-slot fixture: every candidate (%s) already has a\n' "$R" "$N" "$FREE_CANDIDATES"
    printf '        shipping configuration. This surface has NO delete!, so --write runs\n'
    printf '        consume the candidates one by one. Either name another vendor with\n'
    printf '        NS_FREE_VENDOR=<id>, extend NS_FREE_CANDIDATES, or remove a row:\n'
    printf '          DELETE FROM DOD_VENDOR_SHIP_ZONES WHERE VENDOR_ID=<id>;\n'
    printf '          DELETE FROM DOD_SHIPPING_METHODS  WHERE VENDOR_ID=<id>;\n'
    exit 2
  fi
  printf '  free-slot fixture resolved: vendor %s answers 404 (no configuration)\n' "$FREE_VENDOR"
else
  printf '  free-slot fixture: vendor %s (named by NS_FREE_VENDOR — not probed)\n' "$FREE_VENDOR"
fi

# ── 1b. :U — the gated boundary-failure run ─────────────────────────────────
# PROVISION, NOT A DEFAULT. The :U state cannot be reached while the database is
# up: nothing an HTTP client can send makes the boundary fail. So the assertion
# lives here, gated, instead of being absent.
#
# 🚨 THE ORDER IS FORCED: LOGIN NEEDS THE DATABASE. `dodvendlogin` queries
# DOD_VEND_PROFILE, so killing MySQL before the session exists fails section 1
# with exit 2. The database must therefore be stopped AFTER login — which is why
# this block PAUSES rather than being a flag-and-go.
#
#   terminal 1:  NS_EXPECT_U=1 ./smoke-vendor-shipping-api.sh
#   terminal 2:  sudo systemctl stop mysql
#   terminal 1:  press Enter
#   terminal 2:  sudo systemctl start mysql
if [ "${NS_EXPECT_U:-}" = "1" ]; then
  printf '\n== 1b. :U boundary failure  (GATED RUN)\n'
  info "session is up" "now STOP the database, then press Enter"
  read -r _ || true
  req GET "/hhub/api/v1/vendor/shipping/$DEMO_VENDOR"
  expect ":U database unanswerable → 503" 503 "\"unknown\""
  req GET "/hhub/api/v1/vendor/shipping/$FREE_VENDOR"
  expect ":U is not a miss → 503, NOT 404" 503 "\"unknown\""
  req GET "/hhub/api/v1/vendor/shipping"
  expect ":U on the list verb → 503" 503 "\"unknown\""
  req GET "/hhub/api/v1/vendor/shipping/abc"
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
# There is no /exists endpoint, on purpose: this GET's 200/404 IS the answer.
section "2. GET = the existence check (read-only)"

req GET "/hhub/api/v1/vendor/shipping/$DEMO_VENDOR"
expect ":T logged-in vendor → 200" 200 "\"rowId\""

if [ "$HTTP_CODE" = 200 ]; then
  info "keys published" "$(grep -o '"[a-zA-Z]*":' "$BODY" | tr -d '":' | tr '\n' ' ')"
  # The published surface, all fourteen. Nothing here is optional: a missing key
  # means a slot was dropped from the response model or from render-json.
  for k in rowId name freeShippingEnabled flatRateEnabled zoneWiseEnabled \
           externalPartnerEnabled storePickupEnabled minOrderAmount flatRateType \
           flatRatePrice defaultShippingMethod rateTableCsv zones active; do
    if has_key "$k"; then
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s present\n' "$G" "$N" "field $k"
    else
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s MISSING from the response\n' "$R" "$N" "field $k"
    fi
  done

  # 🚨 THE SECRETS. This table holds TWO — the external shipping partner's key and
  # secret, and the demo vendor's row HAS BOTH SET, so this is a real leak test and
  # not a check on empty columns. They are withheld STRUCTURALLY: neither has a
  # slot on VndShipResponseModel, so no edit to render-json can publish them.
  for k in shipPartnerKey shipPartnerSecret shippartnerkey shippartnersecret; do
    if has_key "$k"; then
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s LEAKED into the response\n' "$R" "$N" "secret $k"
    else
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s withheld\n' "$G" "$N" "secret $k"
    fi
  done
  # The कारक and the parent link. vendorId in particular is what !update REFUSES
  # for BOLA reasons, so it must not be published either.
  for k in vendorId tenantId company createdAt updatedAt deletedState; do
    if has_key "$k"; then
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s LEAKED into the response\n' "$R" "$N" "withheld $k"
    else
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s withheld\n' "$G" "$N" "field $k"
    fi
  done

  # THE ZONES RIDE INSIDE THE ENTITY — one query, not one per zone. The demo
  # vendor has five, so a response with no zone objects means the collection was
  # dropped on the way out.
  if grep -qF '"zoneName"' "$BODY"; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s zones published with the entity\n' "$G" "$N" "zones present"
    info "first zone" "$(grep -o '"zoneName":"[^"]*"' "$BODY" | head -1)"
    # The prefixes are published PARSED, not as the stored "(56 57 58 59)".
    if has_key "pincodePrefixes" && has_key "regionCodes"; then
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s prefixes parsed, regions resolved\n' "$G" "$N" "zone shape"
    else
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s pincodePrefixes/regionCodes missing\n' "$R" "$N" "zone shape"
    fi
    # ZONE-A of the demo vendor is 56,57,58,59 — Karnataka, so the prefix table
    # must have resolved it. This is the ONE assertion that proves
    # *vndshp-pin-prefix-regions* is wired to the wire.
    ZA="$(grep -o '"zoneName":"ZONE-A"[^}]*' "$BODY" | head -1)"
    case "$ZA" in
      *'"KA"'*) PASS=$((PASS+1)); printf '  %sPASS%s %-46s ZONE-A → KA (56-59 = Karnataka)\n' "$G" "$N" "region mapping" ;;
      *) FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s ZONE-A did not resolve to KA\n' "$R" "$N" "region mapping"
         printf '       zone object: %s\n' "$(printf '%s' "$ZA" | head -c 200)" ;;
    esac
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s NO zone objects in the response\n' "$R" "$N" "zones present"
    printf '       vendor %s has 5 live zone rows — expect zoneName/pincodePrefixes.\n' "$DEMO_VENDOR"
  fi
fi

# A same-tenant vendor with NO row: the "the slot is free" answer, which is what
# tells a client a POST is allowed — not a 5xx and not a 200 with nulls.
req GET "/hhub/api/v1/vendor/shipping/$FREE_VENDOR"
expect ":F same-tenant vendor, no row → 404" 404 "\"not_found\""

# A vendor whose configuration legitimately has NO ZONES. A zone-less
# configuration is a valid one for every method except zonewise, so the zones
# field must be present and empty — not absent, and not an error.
req GET "/hhub/api/v1/vendor/shipping/$FLAT_VENDOR"
expect ":T flat-rate vendor → 200 (no zones is valid)" 200 "\"rowId\""
if [ "$HTTP_CODE" = 200 ]; then
  if has_key "zones"; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s empty list, not a missing field\n' "$G" "$N" "zones key present"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s zones key absent\n' "$R" "$N" "zones key present"
  fi
  if grep -qF '"zoneName"' "$BODY"; then
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s vendor %s has 0 zone rows\n' "$R" "$N" "no phantom zones" "$FLAT_VENDOR"
  else
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s no zones invented\n' "$G" "$N" "no phantom zones"
  fi
fi

# ── 2b. the list verb (read-only) ───────────────────────────────────────────
# This entity HAS an enumerate, unlike the payment twin, because a configuration
# carries a COLLECTION. The tenant has three configurations (vendors 1, 3, 4).
section "2b. list: tenant-wide enumerate (read-only)"

req GET "/hhub/api/v1/vendor/shipping"
expect "GET list → 200" 200 "defaultShippingMethod"
CFG="$(count_configs)"
if [ "$CFG" -ge 1 ] 2>/dev/null; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-46s %s configuration(s)\n' "$G" "$N" "list is non-empty" "$CFG"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s counted %s\n' "$R" "$N" "list is non-empty" "${CFG:-0}"
fi

req GET "/hhub/api/v1/vendor/shipping?vendorId=$DEMO_VENDOR"
expect "GET list filtered by vendorId → 200" 200 "defaultShippingMethod"
if [ "$(count_configs)" = "1" ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-46s exactly 1\n' "$G" "$N" "vendorId filter selects one"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s got %s configurations\n' "$R" "$N" "vendorId filter selects one" "$(count_configs)"
fi

# method=table is the ZONEWISE filter — the one an operator actually wants, and
# the question this entity's list exists to answer.
req GET "/hhub/api/v1/vendor/shipping?method=table"
expect "GET list method=table (zonewise) → 200" 200 "defaultShippingMethod"
info "zonewise configurations in this tenant" "$(count_configs)"

req GET "/hhub/api/v1/vendor/shipping?limit=2"
expect "GET list limit=2 → 200" 200 "defaultShippingMethod"
if [ "$(count_configs)" -le 2 ] 2>/dev/null; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-46s %s row(s)\n' "$G" "$N" "limit honoured" "$(count_configs)"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s limit=2 returned %s\n' "$R" "$N" "limit honoured" "$(count_configs)"
fi

req GET "/hhub/api/v1/vendor/shipping?status=active"
expect "GET list status=active → 200" 200 "defaultShippingMethod"

# ── 3. BELNAP: the four states ──────────────────────────────────────────────
# Not enough that each state "returns something" — they must stay DISTINCT,
# because collapsing them is the failure mode this layer exists to prevent.
#
#   :T → 200  the configuration exists   :C → 409  two of our rules disagree
#   :F → 404  this vendor has none       :U → 503  we could not find out
#
# 🚨 :C IS ONLY EVER PRODUCED BY A CREATE. Only ?exists reads with
# :include-deleted; only make calls ?exists; fetch and !update both filter the
# deleted row out and answer :F. So :C is asserted on POST and the GET on the same
# fixture must be 404. See the :C block below.
#
# :F has FIVE triggers. Here the identity being addressed is the PARENT VENDOR, so
# the triggers are about the vendor, not about a row-id.
section "3. Belnap states"

# --- :T ---------------------------------------------------------------------
req GET "/hhub/api/v1/vendor/shipping/$DEMO_VENDOR"
expect ":T live configuration → 200 + entity" 200 "\"rowId\""

# --- :F ---------------------------------------------------------------------
req GET "/hhub/api/v1/vendor/shipping/$FREE_VENDOR"
expect ":F vendor with no configuration → 404" 404 "\"not_found\""

req GET "/hhub/api/v1/vendor/shipping/$CROSS_TENANT_VENDOR"
expect ":F another tenant's vendor → 404 (BOLA)" 404 "\"not_found\""

req GET "/hhub/api/v1/vendor/shipping/999999"
expect ":F absent vendor id → 404" 404 "\"not_found\""

req GET "/hhub/api/v1/vendor/shipping/abc"
expect ":F non-numeric id → 404 (not 500)" 404 "\"not_found\""

req GET "/hhub/api/v1/vendor/shipping/999999999999999999"
expect ":F absurd id → 404 (MySQL: 0 rows, no error)" 404 "\"not_found\""

# --- :C ---------------------------------------------------------------------
# 🚨 :C IS NOT OBSERVABLE THROUGH THE GET, AND THAT IS CORRECT. Only ?exists reads
# with :include-deleted, and only make calls ?exists. fetch and !update both call
# select-shipping-method-by-vendor-in-tenant WITHOUT it, so a soft-deleted row is
# filtered out of the WHERE clause and the read answers :F → 404. The
# contradiction ("the slot is taken" ⊔ "there is no configuration here") is a fact
# about the SLOT, which is what a CREATE asks — so it belongs on POST.
if [ -n "$SOFT_DELETED_VENDOR" ]; then
  req POST "/hhub/api/v1/vendor/shipping" \
      -H 'Content-Type: application/json' \
      -d "{\"vendorId\":$SOFT_DELETED_VENDOR}"
  expect ":C soft-deleted row holds the slot, POST → 409" 409 "\"conflict\""

  req GET "/hhub/api/v1/vendor/shipping/$SOFT_DELETED_VENDOR"
  expect ":F the same row is INVISIBLE to GET → 404" 404 "\"not_found\""
else
  skip ":C soft-deleted slot" "no fixture — see the SQL below"
  printf '       To create it (hhubdb), against a vendor in the SESSION tenant that has\n'
  printf '       no shipping row yet:\n'
  printf '         INSERT INTO DOD_SHIPPING_METHODS\n'
  printf '           (VENDOR_ID, TENANT_ID, DELETED_STATE, ACTIVE_FLAG, FREESHIPENABLED)\n'
  printf '           VALUES (%s, 2, '"'"'Y'"'"', '"'"'Y'"'"', '"'"'N'"'"');\n' "$FREE_VENDOR"
  printf '       then: NS_SOFT_DELETED_VENDOR=%s %s\n' "$FREE_VENDOR" "$(basename "$0")"
  printf '       (No --write needed: the 409 comes from make refusing BEFORE any\n'
  printf '        INSERT, so nothing is written.)\n'
  printf '       CAREFUL: this consumes the same vendor id %s that the :F free-slot\n' "$FREE_VENDOR"
  printf '       checks use. Use a DIFFERENT vendor (5, 6, 7, 8, 9, 10 or 11) and set\n'
  printf '       NS_FREE_VENDOR to another, or the :F assertions will fail.\n'
fi

# --- anti-collapse: the states are DISTINCT ---------------------------------
req GET "/hhub/api/v1/vendor/shipping/999999"
if [ "$HTTP_CODE" = 404 ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-46s 404 (a miss is NOT reported as 503)\n' "$G" "$N" "anti-collapse :F ≠ :U"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s :F answered %s, not 404\n' "$R" "$N" "anti-collapse :F ≠ :U" "$HTTP_CODE"
fi

req GET "/hhub/api/v1/vendor/shipping/$DEMO_VENDOR"
if [ "$HTTP_CODE" = 200 ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-46s 200 (existence is not reported as 404)\n' "$G" "$N" "anti-collapse :T ≠ :F"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s :T answered %s, not 200\n' "$R" "$N" "anti-collapse :T ≠ :F" "$HTTP_CODE"
fi

# A list is a SUCCESSFUL EMPTY RESULT, not a not-found fact: filtering on a method
# nobody enabled must answer an empty 200, never a 404.
req GET "/hhub/api/v1/vendor/shipping?method=external&vendorId=$FREE_VENDOR"
if [ "$HTTP_CODE" = 200 ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-46s 200, not 404\n' "$G" "$N" "anti-collapse empty list ≠ :F"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s empty list answered %s\n' "$R" "$N" "anti-collapse empty list ≠ :F" "$HTTP_CODE"
fi

skip ":U boundary failure" "not reachable while the DB is up — rerun with NS_EXPECT_U=1"

# ── 4. negative auth + routing (read-only) ──────────────────────────────────
section "4. negative cases (read-only)"

HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' "$BASE/hhub/api/v1/vendor/shipping/$DEMO_VENDOR" 2>"$ERR")"
expect "GET with NO session cookie" 401

req GET "/hhub/api/v1/vendor/shipping/$DEMO_VENDOR/nonsense"
expect "GET unbound sub-path → no_such_endpoint" 404 "\"no_such_endpoint\""

# The filter vocabulary. An unknown value must SIGNAL in the domain rather than
# being dropped — silently ignoring a filter the caller asked for is how
# '?is-primary-location=0' came to mean the opposite of itself in the warehouse.
req GET "/hhub/api/v1/vendor/shipping?method=nonsense"
expect-known "GET list ?method=nonsense" 400 "" \
  "KNOWN K3: vndshp-method-filter-clause signals with the valid set named — but it signals INSIDE with-nst-db-read-all, so the catch-all turns it into :U and the client is told 503 'unknown, retry'."

req GET "/hhub/api/v1/vendor/shipping?status=suspended"
expect-known "GET list ?status=suspended" 400 "" \
  "KNOWN K3: this entity has no suspend and no approval column and the domain says so — same :U conversion, so again 503 for a request that can never succeed."

req GET "/hhub/api/v1/vendor/shipping?sort-by=nonsense"
expect-known "GET list ?sort-by=nonsense" 400 "" \
  "KNOWN K3: the sort whitelist refuses it (it is what stands between a query string and arbitrary ORDER BY) — but inside the macro it becomes :U → 503."

req GET "/hhub/api/v1/vendor/shipping?offset=1"
expect-known "GET list ?offset without ?limit" 400 "" \
  "KNOWN K3: MySQL cannot express an offset on its own, so the verb refuses rather than returning page 1 forever — 503, not 400."

# 🚨 PRINT THE REASON, because the STATUS ALONE DOES NOT CARRY THE FINDING. The
# 503 says "unknown, try again"; the body says the database did not answer — and
# the database answered. That sentence is what turns a wrong status code into a
# wrong diagnosis, and it is invisible to a suite that only asserts codes.
info "the reason the wire gives" "$(sed -n 's/.*"reason":"\([^"]*\)".*/\1/p' "$BODY" | head -c 130)"
printf '       ^ a malformed filter, reported as a boundary failure. The database is fine.\n'
printf '         K3 in the header: the fix is to validate BEFORE with-nst-db-read-all, not\n'
printf '         in the taxonomy — by then the condition is already a :U object.\n'

# ── 5. the two laws reachable without writing (read-only) ───────────────────
# Both come from make's :around, which refuses BEFORE any INSERT — so these write
# nothing even if the law is later broken. That is what makes them safe to assert
# in a read-only run, and it is why the L1–L5 probes are NOT here (see the header).
section "5. singleton and referential laws (read-only: nothing is written)"

# THE SINGLETON LAW. This vendor already HAS a configuration, so a second create
# must be refused as a CONTRADICTION (409), not silently accepted and not 500. The
# database does NOT enforce it — DOD_SHIPPING_METHODS has no unique key — and the
# legacy checkout reads the FIRST row with NO ORDER BY, so a duplicate would not
# raise: it would silently change the price a customer is charged, by whichever row
# the planner returned first.
req POST "/hhub/api/v1/vendor/shipping" \
    -H 'Content-Type: application/json' \
    -d "{\"vendorId\":$DEMO_VENDOR}"
expect "POST for a vendor that already has a configuration" 409 "\"conflict\""

# THE REFERENTIAL LAW. Neither table declares a FOREIGN KEY, so MySQL would accept
# an orphan vendor_id; the domain applies the missing constraint by fetching the
# parent first. A vendor that does not resolve is 404 — the singleton question is
# moot, so it must NOT be a 409.
req POST "/hhub/api/v1/vendor/shipping" \
    -H 'Content-Type: application/json' \
    -d '{"vendorId":999999}'
expect "POST for a non-existent vendor → 404 (no FK in the schema)" 404 "\"not_found\""

req POST "/hhub/api/v1/vendor/shipping" \
    -H 'Content-Type: application/json' \
    -d '{"vendorId":"abc"}'
expect "POST with an unparseable vendorId → 404" 404 "\"not_found\""

# --- the KNOWN 4xx-taxonomy paths -------------------------------------------
req POST "/hhub/api/v1/vendor/shipping" \
    -H 'Content-Type: application/json' \
    -d '{}'
expect-known "POST with no vendorId" 400 "" \
  "KNOWN K2: vndshp-field-rejected names the field, but the taxonomy maps any condition to 500. 400 is right."

req PUT "/hhub/api/v1/vendor/shipping/$DEMO_VENDOR" \
    -H 'Content-Type: application/json' \
    -d "{\"vendorId\":$FREE_VENDOR}"
expect-known "PUT with vendorId in the body" 400 "" \
  "KNOWN K2: the parent link is refused by design (intra-tenant BOLA); only the status is wrong."

# ── 6. writes (opt-in) ──────────────────────────────────────────────────────
if [ "$WRITE" = 1 ]; then
  section "6. create / update / upload  (WRITES TO THE LIVE DATABASE)"

  # 🚨 THE KEYS BELOW ARE THE FLAT LOWER-CASE COLUMN SPELLING, DELIBERATELY.
  # That is the workaround for K1: camelCase keys normalise to hyphenated
  # initargs the entity does not declare, and are silently dropped. K1's own
  # assertion is at the end of this section, on the shared PUT.
  #
  # A valid zonewise pair, small enough to read: two zones, two weight bands,
  # contiguous from 0.5 kg, every cell a number.
  RT_OK='MIN,MAX,ZONE-A,ZONE-B\n0.5,1,40,80\n1,2,60,120'
  ZN_OK='[{"zoneName":"ZONE-A","pincodes":"11,12"},{"zoneName":"ZONE-B","pincodes":"56,57"}]'

  # CREATE — the free slot. Vendor 2 is a real tenant-2 vendor with no row.
  req POST "/hhub/api/v1/vendor/shipping" \
      -H 'Content-Type: application/json' \
      -d "{\"vendorId\":$FREE_VENDOR,\"tablerateshipenabled\":\"Y\",\"ratetablecsv\":\"$RT_OK\",\"zones\":$ZN_OK}"
  expect "POST create with a zonewise pair" 201 "\"rowId\""
  NEW_RID="$(body_field rowId)"
  [ -n "$NEW_RID" ] && printf '       created rowId=%s for vendor %s\n' "$NEW_RID" "$FREE_VENDOR"

  # DEFAULTS — the fields the caller did NOT send must be the documented class
  # choices: the five method flags "N" (the DDL default is NULL, which the legacy
  # readers treat as off), flatRateType "ORD" (the ONE real DDL default here), and
  # active "Y" (what every reader filters on).
  if [ "$HTTP_CODE" = 201 ]; then
    # 🚨 FIRST, IS THE BODY EVEN INTACT? A field extractor cannot tell "the server
    # did not send this key" from "the response stopped early", and on 2026-09-16
    # exactly that ambiguity cost an hour: the create's LAST key (`active`) read as
    # absent for one vendor while the same payload against two other vendors
    # returned it. Asserting the body parses turns a partial response into a named
    # failure instead of a mystery about a missing field.
    if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$BODY" 2>/dev/null; then
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s well-formed\n' "$G" "$N" "201 body parses as JSON"
    else
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s the body is NOT valid JSON — truncated?\n' "$R" "$N" "201 body parses as JSON"
      printf '       last 120 bytes: %s\n' "$(tail -c 120 "$BODY" | tr -d '\n')"
    fi
    for pair in "freeShippingEnabled:false" "flatRateEnabled:false" \
                "externalPartnerEnabled:false" "storePickupEnabled:false" \
                "active:true"; do
      k="${pair%%:*}"; want="${pair##*:}"; got="$(body_bool "$k")"
      if [ "$got" = "$want" ]; then
        PASS=$((PASS+1)); printf '  %sPASS%s %-46s %s\n' "$G" "$N" "default $k" "$got"
      elif [ -z "$got" ] && [ "$want" = "false" ] && has_key "$k"; then
        # 🚨 K4 — THE FLAG IS THERE, IT IS null, AND IT CANNOT BE false. Counted
        # separately from a missing key: `has_key` proves the field was published,
        # so this is the encoding defect and not a dropped slot.
        KNOWN=$((KNOWN+1))
        printf '  %sKNOWN%s %-45s null, want false\n' "$Y" "$N" "default $k"
        printf '        KNOWN K4: cl-json maps BOTH "null" and "false" to Lisp NIL and\n'
        printf '        rassoc takes the FIRST match (common.lisp:75 — ("null" . nil)\n'
        printf '        precedes ("false" . nil)), so with the default encoder a NIL\n'
        printf '        value can ONLY encode as null. The tree calls plain\n'
        printf '        encode-json-to-string (conflodis2:214), i.e. the guessing encoder,\n'
        printf '        for which (:false) is an ARRAY — so false is UNREACHABLE here\n'
        printf '        without changing shared core. TREE-WIDE: every entity publishing\n'
        printf '        flags this way has an off flag showing as null. See K4 in the header.\n'
      else
        FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s got %s, want %s\n' "$R" "$N" "default $k" "${got:-absent}" "$want"
        # Print the body, the way `expect` does for a status mismatch. A bare
        # "got absent" cannot distinguish a MISSING KEY from a VALUE this
        # extractor cannot read, and that ambiguity is what sent me to the wire
        # instead of to the script when this check last failed.
        printf '       body: %s\n' "$(head -c 200 "$BODY" | tr -d '\n')"
        printf '       key present? %s   raw text: %s\n' \
               "$(has_key "$k" && echo yes || echo NO)" \
               "$(grep -o "\"$k\":[^,}]*" "$BODY" | head -1)"
      fi
    done
    FRT="$(body_field flatRateType)"
    if [ "$FRT" = "ORD" ]; then
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s ORD (the DDL default)\n' "$G" "$N" "default flatRateType"
    else
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s got %s, want ORD\n' "$R" "$N" "default flatRateType" "${FRT:-absent}"
    fi
    # The two payload halves must have landed: the matrix AND its zones.
    if has_key "zoneName" && grep -qF 'ZONE-B' "$BODY"; then
      PASS=$((PASS+1)); printf '  %sPASS%s %-46s both zones stored\n' "$G" "$N" "create stored the zones"
    else
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s zones missing from the create response\n' "$R" "$N" "create stored the zones"
    fi
  fi

  # The singleton law again, now against the row we just made.
  req POST "/hhub/api/v1/vendor/shipping" \
      -H 'Content-Type: application/json' \
      -d "{\"vendorId\":$FREE_VENDOR}"
  expect "POST again for the same vendor → 409" 409 "\"conflict\""

  # UPDATE — partial. Only the supplied fields change.
  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR" \
      -H 'Content-Type: application/json' \
      -d '{"flatrateprice":99}'
  expect "PUT partial update (flatrateprice)" 200 "\"rowId\""

  req GET "/hhub/api/v1/vendor/shipping/$FREE_VENDOR"
  expect "GET after update" 200 "\"rowId\""
  FMP="$(body_number flatRatePrice)"
  if [ "$FMP" = "99" ] || [ "$FMP" = "99.0" ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s %s\n' "$G" "$N" "flatRatePrice round-trip" "$FMP"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s got %s, want 99\n' "$R" "$N" "flatRatePrice round-trip" "${FMP:-absent}"
  fi

  # 🚨 K1, THE ONE THAT MATTERS ON THE SHARED PUT. camelCase is the spelling the
  # response publishes, so a client WILL send it back. Here it must be DROPPED —
  # asserted as KNOWN — while the flat spelling above must work.
  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR" \
      -H 'Content-Type: application/json' \
      -d '{"minOrderAmount":1234}'
  info "PUT minOrderAmount=1234 (camelCase)" "$HTTP_CODE"
  req GET "/hhub/api/v1/vendor/shipping/$FREE_VENDOR"
  MOA="$(body_number minOrderAmount)"
  if [ "$MOA" = "1234" ] || [ "$MOA" = "1234.0" ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s minOrderAmount=1234 accepted\n' "$G" "$N" "camelCase keys round-trip"
  else
    KNOWN=$((KNOWN+1))
    printf '  %sKNOWN%s %-45s minOrderAmount=%s, want 1234\n' "$Y" "$N" "camelCase keys round-trip" "${MOA:-absent}"
    printf '        KNOWN K1: "minOrderAmount" normalises to :MIN-ORDER-AMOUNT but the\n'
    printf '        entity declares :MINORDERAMT, so extract-domain-initargs DROPS it and\n'
    printf '        the 200 above changed nothing. Send "minorderamt" instead. Fix in\n'
    printf '        nst-dal-vndshp.lisp — see the header.\n'
  fi

  # ── the two upload routes ─────────────────────────────────────────────────
  # /rate-table takes BOTH halves, which is what the legacy form submits.
  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR/rate-table" \
      -H 'Content-Type: application/json' \
      -d "{\"rateTableCsv\":\"$RT_OK\",\"zones\":$ZN_OK}"
  expect "PUT /rate-table (camelCase — the route reads it itself)" 200 "\"rowId\""
  printf '       (K1 does NOT apply to this route: it reads the payload with\n'
  printf '        vndshp-body-value and accepts rateTableCsv as well as ratetablecsv.)\n'

  # /zones replaces the collection and leaves the matrix alone. THREE names here
  # against a matrix of two columns would be refused, so the third must be added
  # to the table in the same breath — which is what this payload does NOT do: it
  # sends a zone set whose names still match, only wider prefixes.
  ZN_WIDER='[{"zoneName":"ZONE-A","pincodes":"11,12,13"},{"zoneName":"ZONE-B","pincodes":"56,57,58"}]'
  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR/zones" \
      -H 'Content-Type: application/json' \
      -d "{\"zones\":$ZN_WIDER}"
  expect "PUT /zones (zones only, matrix untouched)" 200 "\"rowId\""

  req GET "/hhub/api/v1/vendor/shipping/$FREE_VENDOR"
  if grep -qF '"13"' "$BODY"; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s the new prefix is stored\n' "$G" "$N" "zones-only write landed"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s prefix 13 absent after the zones put\n' "$R" "$N" "zones-only write landed"
  fi

  # ── THE FIVE LAWS, as refusals ────────────────────────────────────────────
  # Each payload breaks exactly one law. A refusal writes nothing, so after the
  # four probes the configuration is re-read and must be unchanged — that read-back
  # is the assertion, not the status code.
  section "6b. the L1–L5 laws refuse (and write nothing)"
  printf '  These are the states the legacy UI accepted silently and the checkout paid\n'
  printf '  for with a 0.00 charge or a type error. Status is asserted as 500\n'
  printf '  (KNOWN K2 — 400 is right); what matters is that the write is REFUSED.\n'

  RT_EMPTYCELL='MIN,MAX,ZONE-A,ZONE-B\n0.5,1,40,\n1,2,60,120'
  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR/rate-table" \
      -H 'Content-Type: application/json' \
      -d "{\"rateTableCsv\":\"$RT_EMPTYCELL\"}"
  expect-refused "L1 rate table with an empty price cell" \
    "an empty cell reaches checkout as float(\"\") and THROWS — the live table already has three on row 6."

  RT_GAP='MIN,MAX,ZONE-A,ZONE-B\n0.5,1,40,80\n2,3,60,120'
  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR/rate-table" \
      -H 'Content-Type: application/json' \
      -d "{\"rateTableCsv\":\"$RT_GAP\"}"
  expect-refused "L3 rate table with a gap between bands" \
    "a weight in the gap makes get-shipping-rate-from-table return NIL, and the caller does (> nil 0.0): a TYPE ERROR, not a fallback price."

  ZN_MISMATCH='[{"zoneName":"ZONE-A","pincodes":"11"},{"zoneName":"ZONE-C","pincodes":"90"}]'
  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR/rate-table" \
      -H 'Content-Type: application/json' \
      -d "{\"rateTableCsv\":\"$RT_OK\",\"zones\":$ZN_MISMATCH}"
  expect-refused "L2 zones whose names the matrix does not price" \
    "the zone resolves, the matrix has no such column, the checkout's cond falls through to NIL and the cart is charged NOTHING — silently."

  ZN_OVERLAP='[{"zoneName":"ZONE-A","pincodes":"11,56"},{"zoneName":"ZONE-B","pincodes":"56,57"}]'
  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR/zones" \
      -H 'Content-Type: application/json' \
      -d "{\"zones\":$ZN_OVERLAP}"
  expect-refused "L4 two zones claiming prefix 56" \
    "the checkout takes the FIRST zone whose regex matches and the rows come back with no ORDER BY — the master zone file already does this with prefix 30."

  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR/zones" \
      -H 'Content-Type: application/json' \
      -d '{"zones":[]}'
  expect-refused "L1 empty zone payload on the zones-only route" \
    "without the guard this would retire every zone row and answer 200 — a data-losing write reachable by sending nothing."

  req PUT "/hhub/api/v1/vendor/shipping/$FREE_VENDOR" \
      -H 'Content-Type: application/json' \
      -d '{"defaultshippingmethod":"FRS"}'
  expect-refused "L5 default method whose enable flag is not Y" \
    "the checkout asks for BOTH the code and its flag; with only one set, paid shipping is never calculated and delivery is FREE by accident."

  # THE READ-BACK — the point of the whole block. Four refusals must have left the
  # stored configuration exactly as it was.
  req GET "/hhub/api/v1/vendor/shipping/$FREE_VENDOR"
  expect "GET after the refusals — the row still exists" 200 "\"rowId\""
  if grep -qF '"13"' "$BODY" && ! grep -qF 'ZONE-C' "$BODY"; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-46s no refused write landed\n' "$G" "$N" "state unchanged"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-46s a REFUSED write changed the stored row\n' "$R" "$N" "state unchanged"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi

  printf '\n  cleanup: THIS SURFACE HAS NO DELETE, so the row just created stays.\n'
  printf '           To remove it, in mysql (hhubdb):\n'
  printf '             DELETE FROM DOD_VENDOR_SHIP_ZONES WHERE VENDOR_ID = %s;\n' "$FREE_VENDOR"
  printf '             DELETE FROM DOD_SHIPPING_METHODS WHERE VENDOR_ID = %s AND ROW_ID = %s;\n' \
         "$FREE_VENDOR" "${NEW_RID:-<rowId>}"
  printf '           Left in place, vendor %s now HAS a zonewise configuration —\n' "$FREE_VENDOR"
  printf '           which also retires the :F fixture for the next read-only run, and\n'
  printf '           %s is the default NS_FREE_VENDOR. Point it at another free vendor\n' "$FREE_VENDOR"
  printf '           (5, 6, 7, 8, 9, 10 or 11) before re-running, or remove the row.\n'
  printf '           NOTE: the refusals above wrote nothing, so the ONLY row added is\n'
  printf '           the one from the create, plus the zone rows it stored.\n'
else
  section "6. create / update / upload"
  printf '  SKIPPED — read-only run. Re-run with --write to exercise them.\n'
  printf '  (They create a real shipping configuration for vendor %s in the live\n' "$FREE_VENDOR"
  printf '   database, and probe the five laws as refusals against it.)\n'
fi

# ── summary ─────────────────────────────────────────────────────────────────
printf '\n─────────────────────────────────────────────\n'
printf 'passed %s   failed %s   known-defects %s   skipped %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
if [ "$FAIL" -gt 0 ]; then
  printf '\nfailed checks are UNEXPECTED (not in the known-defect list). Server detail:\n'
  printf '  ssh <server> tail -40 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
  printf 'REMEMBER: sentinel-derived responses (404/409/503) leave NO trace in that log —\n'
  printf 'only CONDITION-derived failures are recorded (vendor CONTEXT §8.6). A law\n'
  printf 'refusal IS condition-derived, so those at least leave a line.\n'
  exit 1
fi
if [ "$KNOWN" -gt 0 ]; then
  printf '\nThe %s known defect(s) above are encoded deliberately — see the header.\n' "$KNOWN"
  printf 'K1 is the one to fix first: until it is, 11 of the 17 fields cannot be set\n'
  printf 'over the shared PUT or the POST in the spelling the response publishes.\n'
fi
printf 'no unexpected failures\n'
exit 0
