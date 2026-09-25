#!/usr/bin/env bash
#
# smoke-products-api.sh — smoke-test the PRODUCTS JSON API (conflodis2 + apidefs2).
#
# Run this FROM A WORKSTATION (your Mac), not from the server: it uses
# http://ninestores.local, which is the workstation entry point
# (nginx proxies /hhub/ straight to the acceptor on 127.0.0.1:4244).
#
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-products-api.sh
#   NS_PHONE=… NS_PASSWORD=… ./smoke-products-api.sh --write
#   BASE=http://ninestores.local NS_PHONE=… NS_PASSWORD=… ./smoke-products-api.sh
#
# READ-ONLY by default. The mutating tests (POST/PUT/DELETE) create and soft-delete
# a REAL row in the live database, so they run only with --write.
#
# Exit codes:  0 = every result matched its expectation
#              1 = at least one result did NOT match
#              2 = setup failure (unreachable, no session) — the API wasn't tested
#
# ── STATUS (2026-09-13) ─────────────────────────────────────────────────────
# The products code is COMPILED and the routes ARE REGISTERED in the running
# image (verified: every product URL answers 401 rather than 404; the image was
# rebuilt 23:58–00:00 and the acceptor restarted 07:56 on 2026-09-13). No reload
# is needed. What has NEVER run is anything PAST AUTHENTICATION — the Tier-1
# verbs, the ferry, the DB access and the JSON rendering. That is what this
# script tests.
#
# The not-loaded detector below is kept as a safety net: if the image is rebuilt
# without the routes you get a clear message instead of a wall of meaningless
# failures.
#
# A restart calls reset-session-secret, so log in fresh — a cookie issued before
# the 07:56 restart is dead.
#
# ── TWO OPERATIONAL WARNINGS ────────────────────────────────────────────────
# 1. Login counts against a MAX OF 2 CONCURRENT VENDOR LOGINS and eviction is
#    oldest-first — running this can silently bounce a browser session (and a
#    browser login can bounce this one).
# 2. Sessions are bound to User-Agent + client IP + a session secret, and
#    start-das calls reset-session-secret — so every server restart invalidates
#    all cookies, and mixing User-Agents between login and request fails.

set -uo pipefail

# ── configuration ───────────────────────────────────────────────────────────
BASE="${BASE:-http://ninestores.local}"
PHONE="${NS_PHONE:-}"
PASSWORD="${NS_PASSWORD:-}"
DELETED_CODE="${NS_DELETED_CODE:-PRD-MPJ165U1Q7}"   # held by a SOFT-DELETED row; drives the 409 test
WRITE=0

usage() {
  sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --write            also run the mutating tests (creates a real product row)
  --base URL         override the base URL (default http://ninestores.local)
  -h, --help         this text

Environment:
  NS_PHONE           vendor phone (login form field "phone")   [required]
  NS_PASSWORD        vendor password (login form field "password") [required]
  NS_DELETED_CODE    product-code held by a soft-deleted row (default PRD-MPJ165U1Q7)
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
  echo "       The login form posts fields named phone and password." >&2
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

PASS=0; FAIL=0; NOTLOADED=0
HTTP_CODE=""

# req METHOD PATH [extra curl args...]  → sets HTTP_CODE, writes body to $BODY
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
    PASS=$((PASS+1))
    printf '  %sPASS%s %-44s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-44s got %s, want %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" \
           "${needle:+, containing \"$needle\"}"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
}

# expect_re NAME STATUS REGEX
# Same contract as expect, but the body match is an EXTENDED REGEX rather than a
# fixed string. Needed for JSON booleans: {"active":true} and {"active": true} are
# both valid encodings and which one a server emits is not part of the contract, so
# a fixed-string match on either would be asserting the encoder's padding rather
# than our behaviour. Use expect (fixed) everywhere else.
expect_re() {
  local name="$1" want="$2" re="$3" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  grep -qE -- "$re" "$BODY" || ok=0
  if [ "$ok" = 1 ]; then
    PASS=$((PASS+1))
    printf '  %sPASS%s %-44s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-44s got %s, want %s matching /%s/\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" "$re"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
}

# info NAME — print a value without asserting (for things we cannot predict)
info() { printf '  %s----%s %-44s %s\n' "$Y" "$N" "$1" "$2"; }

body_field() {   # body_field NAME → first "name":"value" for a string value
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$BODY" | head -1
}
count_objects() { grep -o '"rowId"' "$BODY" 2>/dev/null | wc -l | tr -d ' '; }

section() { printf '\n== %s\n' "$1"; }

bail_if_not_loaded() {
  if grep -qF '"no_such_endpoint"' "$BODY"; then
    NOTLOADED=1
    printf '\n%sThe products routes are NOT REGISTERED in the running image.%s\n' "$R" "$N"
    printf 'Every product URL answered 404 no_such_endpoint. In the Lisp image:\n\n'
    printf '    (asdf:load-system :nstores)\n    (list-api-routes)        ; expect 5 warehouse + 5 products\n\n'
    printf 'Then re-run this script. Nothing else below would be meaningful.\n'
    exit 2
  fi
}

# ── 1. reachability + session ───────────────────────────────────────────────
section "1. reachability and session  ($BASE)"

if ! curl -sS -o /dev/null --max-time 10 "$BASE/hhub/" 2>"$ERR"; then
  printf '  %sFATAL%s cannot reach %s — curl: %s\n' "$R" "$N" "$BASE" "$(head -1 "$ERR")"
  printf '        Check that ninestores.local resolves from this machine and that nginx is up.\n'
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
  printf '        Check the phone/password, that the account is a vendor login, and the\n'
  printf '        2-concurrent-login limit. The reason is logged to ninestores-busfunctions.log.\n'
  exit 2
fi

# The only trustworthy authentication check is an authenticated call: a cookie
# can exist even when the login was rejected.
req GET "/hhub/api/v1/catalog/products?limit=1"
case "$HTTP_CODE" in
  401) printf '\n  %sFATAL%s login did not establish a vendor session (API answered 401).\n' "$R" "$N"
       printf '        The reason is logged to ninestores-busfunctions.log, not returned here.\n'
       printf '        Also check the 2-concurrent-login limit: this login may have been evicted.\n'
       exit 2 ;;
  000) printf '\n  %sFATAL%s could not reach the API endpoint.\n' "$R" "$N"; exit 2 ;;
esac
bail_if_not_loaded
printf '  session established (authenticated call answered %s)\n' "$HTTP_CODE"

# ── 2. read-only: list ──────────────────────────────────────────────────────
section "2. list (read-only)"

req GET "/hhub/api/v1/catalog/products?limit=2"
expect "GET list ?limit=2" 200
if [ "$HTTP_CODE" = 200 ]; then
  n="$(count_objects)"
  if [ "$n" = "2" ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-44s 2 objects\n' "$G" "$N" "limit honoured (query params arrived)"
  else FAIL=$((FAIL+1)); printf '  %sFAIL%s %-44s %s objects, want 2\n' "$R" "$N" "limit honoured (query params arrived)" "$n"; fi
  FIRST_ID="$(body_field rowId)"
else
  FIRST_ID=""
fi

req GET "/hhub/api/v1/catalog/products?status=active&limit=2"
expect "GET list ?status=active" 200
req GET "/hhub/api/v1/catalog/products?status=inactive"
expect "GET list ?status=inactive → 200 []" 200 "[]"
req GET "/hhub/api/v1/catalog/products?name-like=LIVA&limit=3"
expect "GET list ?name-like=LIVA" 200
req GET "/hhub/api/v1/catalog/products?sort-by=current-price&sort-dir=asc&limit=3"
expect "GET list whitelisted sort" 200
req GET "/hhub/api/v1/catalog/products?limit=2&offset=2"
expect "GET list ?limit=2&offset=2" 200

# ── 3. read-only: fetch ─────────────────────────────────────────────────────
section "3. fetch by id (read-only)"

if [ -n "${FIRST_ID:-}" ]; then
  req GET "/hhub/api/v1/catalog/products/$FIRST_ID"
  expect "GET /products/$FIRST_ID (live row)" 200 "\"rowId\""
else
  info "GET /products/{id}" "SKIPPED — the list returned no rows to take an id from"
fi
req GET "/hhub/api/v1/catalog/products/999999"
expect "GET /products/999999 (absent)" 404
req GET "/hhub/api/v1/catalog/products/abc"
expect "GET /products/abc (non-numeric id)" 404

# ── 4. negative auth + routing ──────────────────────────────────────────────
section "4. negative cases (read-only)"

HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' "$BASE/hhub/api/v1/catalog/products" 2>"$ERR")"
expect "GET list with NO session cookie" 401

req GET "/hhub/api/v1/catalog/products/1/images"
expect "GET unbound endpoint → no_such_endpoint" 404 "\"no_such_endpoint\""

info "GET bad ?sort-by" "(expect 500 today — error taxonomy unfinished; should be 400)"
req GET "/hhub/api/v1/catalog/products?sort-by=secret-column"
info "  result" "$HTTP_CODE"

# ── 5. the 409 contradiction (read-only, the interesting one) ───────────────
section "5. soft-deleted identity → 409"

req POST "/hhub/api/v1/catalog/products" \
    -H 'Content-Type: application/json' \
    -d "{\"product-code\":\"$DELETED_CODE\",\"prd-name\":\"Resurrect attempt\"}"
expect "POST with a soft-deleted product-code" 409 "\"conflict\""

# ── 6. writes (opt-in) ──────────────────────────────────────────────────────
if [ "$WRITE" = 1 ]; then
  section "6. create / update / delete  (WRITES TO THE LIVE DATABASE)"
  STAMP="$(date +%H%M%S)"
  req POST "/hhub/api/v1/catalog/products" \
      -H 'Content-Type: application/json' \
      -d "{\"prd-name\":\"API Smoke Test $STAMP\",\"hsn-code\":\"8517\",\"current-price\":199.00}"
  expect "POST create" 201
  RID="$(body_field rowId)"
  if [ -z "$RID" ]; then
    printf '  %sSKIP%s could not read rowId from the create response; skipping update/delete.\n' "$Y" "$N"
  else
    printf '       created rowId=%s\n' "$RID"
    req PUT "/hhub/api/v1/catalog/products/$RID" \
        -H 'Content-Type: application/json' \
        -d "{\"prd-name\":\"API Smoke Test $STAMP (edited)\"}"
    expect "PUT update (partial)" 200 "\"name\""

    # ── 6b. pricing — PUT /catalog/products/{id}/pricing ────────────────────
    # The pricing row is an ENTITY OF ITS OWN reachable through the product, and
    # this is the only endpoint whose write touches TWO ROWS: the pricing row and
    # the PRODUCT MASTER's cached currentPrice/currentDiscount. The master copy is
    # what the catalogue filter, the :current-price sort and the cart read, so a
    # test that only checked the pricing row would miss the failure that matters.
    # PRICE is chosen as a whole number so the JSON encoder cannot render it as
    # 98765.000000001 and make an exact substring match a coin flip.
    req PUT "/hhub/api/v1/catalog/products/$RID/pricing" \
        -H 'Content-Type: application/json' \
        -d '{"price":98765,"discount":7.5,"start-date":"01/01/2020","end-date":"31/12/2030","currency":"INR"}'
    expect "PUT pricing (all five fields)" 200 "\"discount\""

    req GET "/hhub/api/v1/catalog/products/$RID"
    expect "  ↳ product master's currentPrice followed" 200 "98765"

    # PARTIAL: camelCase spelling on purpose — the boundary accepts both, and
    # only the supplied fields may change. If the price came back as 1.00 the
    # create-path default leaked into the update path.
    req PUT "/hhub/api/v1/catalog/products/$RID/pricing" \
        -H 'Content-Type: application/json' -d '{"discount":9.99}'
    expect "PUT pricing (partial, camelCase: discount only)" 200 "\"discount\""

    req GET "/hhub/api/v1/catalog/products/$RID"
    expect "  ↳ price was LEFT ALONE, not reset to the default" 200 "98765"

    # The three refusals. Each must be a 400 (the caller's mistake), NOT a 500:
    # that is the whole reason prdpricing-validation-error exists as its own
    # condition rather than a plain error.
    req PUT "/hhub/api/v1/catalog/products/$RID/pricing" \
        -H 'Content-Type: application/json' -d '{"price":0}'
    expect "PUT pricing price=0 → 400" 400
    req PUT "/hhub/api/v1/catalog/products/$RID/pricing" \
        -H 'Content-Type: application/json' -d '{"discount":150}'
    expect "PUT pricing discount=150 → 400 (it is a PERCENTAGE)" 400
    req PUT "/hhub/api/v1/catalog/products/$RID/pricing" \
        -H 'Content-Type: application/json' \
        -d '{"price":10,"start-date":"31/12/2030","end-date":"01/01/2020"}'
    expect "PUT pricing reversed window → 400" 400
    req PUT "/hhub/api/v1/catalog/products/$RID/pricing" \
        -H 'Content-Type: application/json' -d '{}'
    expect "PUT pricing empty body → 400" 400

    # A miss is nst-entity-nil → 404, with no pricing-specific code behind it.
    req PUT "/hhub/api/v1/catalog/products/999999/pricing" \
        -H 'Content-Type: application/json' -d '{"price":10}'
    expect "PUT pricing on an absent product → 404" 404

    # ── 6c. product shipping dimensions — PUT /catalog/products/{id}/shipping ─
    # These four are NOT a shipping entity; they are columns on the product master
    # (shipping_*_cms, shipping_weight_kg) that the zonewise rate table is indexed
    # BY. This is the one product endpoint that never had a test, which is why the
    # section exists even though the route is older than pricing.
    # The length used is the EXACT smallint ceiling, 32767: it exercises the
    # boundary in the permissive direction, and it is distinctive enough that a
    # read-back substring match cannot accidentally hit a row-id or a timestamp.
    req PUT "/hhub/api/v1/catalog/products/$RID/shipping" \
        -H 'Content-Type: application/json' \
        -d '{"shipping-length-cms":32767,"shipping-width-cms":20,"shipping-height-cms":10,"shipping-weight-kg":5.5}'
    expect "PUT shipping (all four, at the smallint ceiling)" 200 "\"shippingLengthCms\""

    req GET "/hhub/api/v1/catalog/products/$RID"
    expect "  ↳ dimensions are readable back on the product" 200 "32767"

    # One past the ceiling, a fractional centimetre, a zero weight. The fractional
    # case is the one worth having: SHIPPING_*_CMS is smallint, and silently
    # truncating half a centimetre is the quiet data loss the validator refuses.
    req PUT "/hhub/api/v1/catalog/products/$RID/shipping" \
        -H 'Content-Type: application/json' -d '{"shipping-length-cms":32768}'
    expect "PUT shipping 32768 → 400 (one past the ceiling)" 400
    req PUT "/hhub/api/v1/catalog/products/$RID/shipping" \
        -H 'Content-Type: application/json' -d '{"shipping-width-cms":30.5}'
    expect "PUT shipping 30.5 cm → 400 (smallint, not truncated)" 400
    req PUT "/hhub/api/v1/catalog/products/$RID/shipping" \
        -H 'Content-Type: application/json' -d '{"shipping-weight-kg":0}'
    expect "PUT shipping weight 0 → 400" 400
    req PUT "/hhub/api/v1/catalog/products/$RID/shipping" \
        -H 'Content-Type: application/json' -d '{}'
    expect "PUT shipping empty body → 400" 400
    req PUT "/hhub/api/v1/catalog/products/999999/shipping" \
        -H 'Content-Type: application/json' -d '{"shipping-length-cms":10}'
    expect "PUT shipping on an absent product → 404" 404

    # ── 6d. product status — PUT /catalog/products/{id}/status ──────────────
    # Turn On / Turn Off from the vendor's action menu, as a constrained !update on
    # active-flag. The body is one field with two values; everything else about the
    # product must be unreachable through this path.
    # `inactive` means active_flag='N' (what the legacy Turn Off did) and does NOT
    # delist — so this asserts the READ-BACK too, because a status write that
    # returned 200 while changing nothing would pass a status-code-only test.
    req PUT "/hhub/api/v1/catalog/products/$RID/status" \
        -H 'Content-Type: application/json' -d '{"status":"inactive"}'
    expect "PUT status inactive" 200 "\"active\""
    req GET "/hhub/api/v1/catalog/products/$RID"
    expect_re "  ↳ product now reads inactive" 200 '"active"[[:space:]]*:[[:space:]]*false'

    req PUT "/hhub/api/v1/catalog/products/$RID/status" \
        -H 'Content-Type: application/json' -d '{"status":"active"}'
    expect "PUT status active" 200 "\"active\""
    req GET "/hhub/api/v1/catalog/products/$RID"
    expect_re "  ↳ and reads active again" 200 '"active"[[:space:]]*:[[:space:]]*true'

    # THE MASS-ASSIGNMENT CHECK, and the reason this endpoint bypasses the ferry.
    # The generic ferry MOP-filters params against EVERY nst-prd initarg, so if this
    # route had gone through request->dispatch these two extra keys would have been
    # applied. 98765 is the price the pricing section set above: if it survives a
    # write that claimed to be about status, the allowlist is structural.
    req PUT "/hhub/api/v1/catalog/products/$RID/status" \
        -H 'Content-Type: application/json' \
        -d '{"status":"active","current-price":1,"prd-name":"hijacked by a status write"}'
    expect "PUT status ignores extra fields" 200 "\"active\""
    req GET "/hhub/api/v1/catalog/products/$RID"
    expect "  ↳ price untouched by a status write" 200 "98765"

    req PUT "/hhub/api/v1/catalog/products/$RID/status" \
        -H 'Content-Type: application/json' -d '{"status":"enabled"}'
    expect "PUT status 'enabled' → 400 (not a synonym)" 400
    req PUT "/hhub/api/v1/catalog/products/$RID/status" \
        -H 'Content-Type: application/json' -d '{}'
    expect "PUT status empty body → 400" 400
    req PUT "/hhub/api/v1/catalog/products/$RID/status" \
        -H 'Content-Type: application/json' -d '{"status":true}'
    expect "PUT status non-string → 400" 400
    req PUT "/hhub/api/v1/catalog/products/999999/status" \
        -H 'Content-Type: application/json' -d '{"status":"inactive"}'
    expect "PUT status on an absent product → 404" 404

    # ── 6e. copy — POST /catalog/products/{id}/copy ─────────────────────────
    # A copy is a CREATE (सृजन): new row, new product-code, unapproved. The body is
    # EMPTY by design, so there is nothing for a client to mass-assign — the source is
    # read server-side. The assertions below are the three that would catch a wrong
    # implementation: a copy that reused the row, one that reused the product-code
    # (uniquely indexed → 409), or one that inherited approval.
    req POST "/hhub/api/v1/catalog/products/$RID/copy"
    expect "POST copy → 201" 201 "\"rowId\""
    expect "  ↳ name is prefixed 'Copy of '" 201 "Copy of "
    expect "  ↳ copy starts PENDING (approval not inherited)" 201 "\"approvalStatus\":\"PENDING\""
    expect "  ↳ price inherited from the source" 201 "98765"
    COPY_ID="$(body_field rowId)"

    if [ -z "$COPY_ID" ] || [ "$COPY_ID" = "$RID" ]; then
      FAIL=$((FAIL+1)); printf '  %sFAIL%s %-44s rowId=%s, source=%s\n' "$R" "$N" "  ↳ copy is a NEW row" "${COPY_ID:-<empty>}" "$RID"
    else
      PASS=$((PASS+1)); printf '  %sPASS%s %-44s %s (source %s)\n' "$G" "$N" "  ↳ copy is a NEW row" "$COPY_ID" "$RID"

      req GET "/hhub/api/v1/catalog/products/$COPY_ID"
      expect "GET the copy reads back" 200 "Copy of "

      COPY_CODE="$(body_field productCode)"
      req GET "/hhub/api/v1/catalog/products/$RID"
      SRC_CODE="$(body_field productCode)"
      if [ -n "$COPY_CODE" ] && [ "$COPY_CODE" != "$SRC_CODE" ]; then
        PASS=$((PASS+1)); printf '  %sPASS%s %-44s %s\n' "$G" "$N" "  ↳ fresh product-code, not inherited" "$COPY_CODE"
      else
        FAIL=$((FAIL+1)); printf '  %sFAIL%s %-44s copy=%s source=%s\n' "$R" "$N" "  ↳ fresh product-code, not inherited" "${COPY_CODE:-<empty>}" "${SRC_CODE:-<empty>}"
      fi
      expect "  ↳ source is UNCHANGED by the copy" 200 "API Smoke Test"

      req DELETE "/hhub/api/v1/catalog/products/$COPY_ID"
      printf '       cleanup: copy rowId=%s soft-deleted (a copy is a real row)\n' "$COPY_ID"
    fi

    req POST "/hhub/api/v1/catalog/products/999999/copy"
    expect "POST copy of an absent product → 404" 404

    req DELETE "/hhub/api/v1/catalog/products/$RID"
    expect "DELETE (soft)" 200 "\"ok\""
    req DELETE "/hhub/api/v1/catalog/products/$RID"
    expect "DELETE again → gone" 404
    req GET "/hhub/api/v1/catalog/products/$RID"
    expect "GET deleted row" 404
    printf '\n  cleanup: the row stays SOFT-DELETED and its product-code is reserved\n'
    printf '           forever by design. To purge it, in mysql (hhubdb):\n'
    printf '             DELETE FROM DOD_PRD_MASTER WHERE ROW_ID = %s;\n' "$RID"
  fi
else
  section "6. create / update / delete"
  printf '  SKIPPED — read-only run. Re-run with --write to exercise them.\n'
  printf '  (They create a real product row in the live database.)\n'
fi

# ── summary ─────────────────────────────────────────────────────────────────
printf '\n─────────────────────────────────────────────\n'
printf 'passed %s   failed %s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf '\nServer-side detail for any 5xx:\n'
  printf '  ssh <server> tail -40 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
  printf 'Login failures are logged to ninestores-busfunctions.log, not to the API log.\n'
  exit 1
fi
printf 'all expectations matched\n'
exit 0
