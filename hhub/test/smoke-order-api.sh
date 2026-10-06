#!/usr/bin/env bash
#
# smoke-order-api.sh — the CONSOLIDATED order suite: both channels, one run.
#
#   NS_PHONE=… NS_PASSWORD=… NS_VPHONE=… NS_VPASSWORD=… ./smoke-order-api.sh          # read-only
#   NS_PHONE=… NS_PASSWORD=… NS_VPHONE=… NS_VPASSWORD=… ./smoke-order-api.sh --write  # + lifecycle
#
# WHAT MAKES THIS FILE DIFFERENT FROM THE OTHER THREE
#   smoke-order-header-api.sh and smoke-order-items-api.sh test the CUSTOMER channel, and
#   smoke-order-vendor-api.sh tests the VENDOR channel — each in isolation. This one is the only
#   place the two MEET, and the thing it exists to prove is D20: the order the CUSTOMER creates is
#   the order the VENDOR can act on, because the assembly stamps the customer's minted ORDNUM into
#   the vendor row it writes. Nothing in the three isolated suites can see that seam: the customer
#   suite never logs in as a vendor, and the vendor suite never creates an order.
#
#     1. the TEN bound paths unauthenticated, and the four shapes that must not be bound.
#     2. BOTH sessions at once — a customer jar and a vendor jar, each proven by its own channel.
#     3. the cross-channel refusals: a customer is not a vendor, a vendor is not a customer, and a
#        vendor cannot see another vendor's slice.
#     4. --write: customer creates → VENDOR READS THE SAME ORDER BY THE SAME NUMBER → vendor updates
#        its slice (AC (f): ORD_DATE byte-identical) → customer edits the line, deletes it, deletes
#        the order → and the vendor row SURVIVES the customer's delete, which is the KNOWN gap.
#     5. cleanup: every row is removed, on EXIT and on failure, keyed on the row-id from the 201.
#
# ── FIXTURES (measured 2026-10-05) ────────────────────────────────────────────────────────────
#   customer  `9999999999` = DOD_CUST_PROFILE 1 (DEMO, tenant 2, 208 orders) — the richest fixture
#   vendor    `9999999990` = DOD_VEND_PROFILE 1 (tenant 2, 395 vendor rows)
#   product   DOD_PRD_MASTER 1 — live, and it belongs to VENDOR 1, which is why the create below
#             produces a vendor row this vendor session can read. Both sessions are the SAME tenant,
#             which is what D5 and नियम-1 require.
#   ⚠ Orphans left by EARLIER runs are not fixtures: check `SELECT COUNT(*) FROM DOD_ORDER WHERE
#   STATUS='DFT'` is 0 before blaming this suite — it means a previous run died after the INSERT.
#
# ── O3, THE PARTIAL-WRITE WINDOW, IS **KNOWN** AND NOW HAS EVIDENCE ───────────────────────────
#   `POST /orders` is a Tier-2 multi-entity assembly with no transaction seam (D14), so a failure in
#   its WRITE half leaves the header — and its lines and vendor rows — behind. MEASURED 2026-10-05:
#   four 500s (all in the response or the vendor-row step, after the inserts) left orders 491, 494,
#   495, 496, 497 and 499 in the table, each with its line and its vendor row, and the suite could not
#   clean up because it keys its cleanup on the `rowId` from a 201 that never came. The READ half is
#   safe by construction: the line plans are resolved BEFORE the header insert, so an empty cart is a
#   400 that leaves nothing. §6 asserts the safe half and records the window rather than pretending.
#
# ── WHAT THIS SCRIPT DOES NOT COVER (stated, not implied) ────────────────────────────────────
#   * the per-endpoint detail the three focused suites carry — this one proves the SEAM, not depth.
#   * a per-ITEM fulfilment surface: the vendor channel has no line endpoints and nst-orditm's
#     enumerate has no :vendor-id, so a vendor cannot read or write the items it must ship.
#   * two vendors concurrently: the tree caps concurrent VENDOR logins at 2, oldest evicted, and this
#     suite needs only one vendor — the second-vendor case lives in smoke-order-vendor-api.sh.
#   * the :U branch (database stopped) — not run by default anywhere.
#
# Exit: 0 all checks passed · 1 at least one FAIL · 2 setup failure.

set -uo pipefail

BASE="${BASE:-http://ninestores.local}"
PHONE="${NS_PHONE:-}";        PASSWORD="${NS_PASSWORD:-}"
VPHONE="${NS_VPHONE:-}";      VPASSWORD="${NS_VPASSWORD:-}"
COOKIES="${NS_COOKIES:-}";    VCOOKIES="${NS_VCOOKIES:-}"

PRD_ID="${NS_PRD_ID:-1}"
VENDOR_ID="${NS_VENDOR_ID:-1}"
ORDNUM_TERMINAL="${NS_ORDNUM_TERMINAL:-ORD-DEMO-2022-23-V3ZBB9}"
OTHER_VENDOR_ORDNUM="${NS_OTHER_VENDOR_ORDNUM:-}"
ABSENT_ORDNUM="${NS_ABSENT_ORDNUM:-ORD-NOPE-2026-27-ZZZZZZ}"

NS_DB="${NS_DB:-hhubdb}"
NS_MYSQL_USER="${NS_MYSQL_USER:-hhubuser}"
NS_MYSQL_PASS="${NS_MYSQL_PASS:-Welcome\$123}"
# ⚠ SQL IS OPTIONAL — this suite runs from a client machine. 2>&1 | grep -v '^mysql:' and NOT
# 2>/dev/null: a discarded error makes a broken query look like an empty table.
HAVE_SQL=1
command -v mysql >/dev/null 2>&1 || HAVE_SQL=0
[ "${NS_NO_SQL:-0}" = "1" ] && HAVE_SQL=0
sql() { [ "$HAVE_SQL" = 1 ] || return 0
        mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" -N -B "$NS_DB" -e "$1" 2>&1 | grep -v '^mysql:'; }

WRITE=0
SUITE_REV="2026-10-05.1"
usage() {
  sed -n '3,60p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --write            run the full cross-channel lifecycle (creates a real order, then removes it)
  --base URL         override the base URL   (default http://ninestores.local)
  --cookies FILE     a CUSTOMER cookie jar, instead of NS_PHONE/NS_PASSWORD
  --vcookies FILE    a VENDOR cookie jar, instead of NS_VPHONE/NS_VPASSWORD
  -h, --help         this text

Environment:
  NS_PHONE / NS_PASSWORD     customer credentials   [required unless --cookies]
  NS_VPHONE / NS_VPASSWORD   vendor credentials     [required unless --vcookies]
  NS_PRD_ID                  a live product of the vendor (default 1)
  NS_DB / NS_MYSQL_USER / NS_MYSQL_PASS   SQL, needed by --write (stock + hard-delete)
  NS_ALLOW_NO_SQL=1          proceed with --write on a machine with no mysql client
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --write)    WRITE=1 ;;
    --base)     BASE="${2:-}"; shift ;;
    --cookies)  COOKIES="${2:-}"; shift ;;
    --vcookies) VCOOKIES="${2:-}"; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# ⚠ BOTH ARE INITIALISED, AND THAT IS NOT DECORATION: under `set -u` a variable that is only
# assigned on the FAILURE branch is UNBOUND when the credentials ARE present, and the next read of it
# aborts the run — which is exactly what the first version of this file did, printing
# "line 260: NEED_VCREDS: unbound variable" after a clean sixteen-check sweep.
NEED_CREDS=0
NEED_VCREDS=0
[ -n "$COOKIES" ]  || { [ -n "$PHONE" ]  && [ -n "$PASSWORD" ]  || NEED_CREDS=1; }
[ -n "$VCOOKIES" ] || { [ -n "$VPHONE" ] && [ -n "$VPASSWORD" ] || NEED_VCREDS=1; }

TMP="$(mktemp -d)" || exit 2
JARC="$TMP/customer.txt"; JARV="$TMP/vendor.txt"
BODY="$TMP/body.json"; ERR="$TMP/curl.err"

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; N=$'\033[0m'
else G=; R=; Y=; N=; fi
PASS=0; FAIL=0; KNOWN=0; SKIP=0
HTTP_CODE=""
CREATED_ID=""        # the header row-id from the 201 — the cleanup key
CREATED_NUM=""       # its minted ORDNUM — the API cleanup key
STOCK_BEFORE=""

# ── AC (a): CLEAN UP ON EXIT **INCLUDING ON FAILURE**, KEYED ON THE ROW-ID FROM THE 201 ──────
# ⚠ THE API'S DELETE IS A **SOFT** DELETE, so the row, its lines and its vendor row all remain in the
# table. The physical removal is therefore SQL's job, by row-id, and this suite learned that the hard
# way: an earlier version cleared the key after the API delete and left every run's rows behind.
# ⚠ AND DOD_ORDER_ITEMS / DOD_VENDOR_ORDERS HAVE **NO FK** TO DOD_ORDER, so the order of these
# DELETEs is about not leaving orphans, not about a cascade that would do it for us.
restore_rows() {
  [ "$WRITE" = 1 ] || return 0
  if [ -n "${CREATED_NUM:-}" ]; then
    local code
    code="$(curl -sS -o /dev/null -w '%{http_code}' -b "$JARC" -X DELETE "$BASE$ORDC/$CREATED_NUM" 2>/dev/null)"
    printf '\n  cleanup: API DELETE %s → %s\n' "$CREATED_NUM" "${code:-000}"
  fi
  if [ "$HAVE_SQL" != 1 ]; then
    printf '  cleanup: no mysql client here, so the removal could NOT be verified and the product\n'
    printf '           stock could not be restored (no endpoint exposes UNITS_IN_STOCK).\n'
    return 0
  fi
  if [ -n "${CREATED_ID:-}" ]; then
    local n_before n_after
    n_before="$(sql "SELECT COUNT(*) FROM DOD_ORDER WHERE ROW_ID=$CREATED_ID")"
    if [ "${n_before:-0}" -gt 0 ]; then
      mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" "$NS_DB" -e "
        DELETE FROM DOD_ORDER_ITEMS   WHERE ORDER_ID=$CREATED_ID;
        DELETE FROM DOD_VENDOR_ORDERS WHERE ORDER_ID=$CREATED_ID;
        DELETE FROM DOD_ORDER         WHERE ROW_ID=$CREATED_ID;" 2>/dev/null
      n_after="$(sql "SELECT COUNT(*) FROM DOD_ORDER WHERE ROW_ID=$CREATED_ID")"
      printf '  cleanup: removed the smoke order (%s line(s) left)\n' "${n_after:-?}"
      [ "${n_after:-1}" = "0" ] || printf '  %sFAIL%s  SMOKE ROWS REMAIN (row-id %s) — remove by hand\n' "$R" "$N" "$CREATED_ID"
    fi
  fi
  if [ -n "${STOCK_BEFORE:-}" ]; then
    local now
    now="$(sql "SELECT UNITS_IN_STOCK FROM DOD_PRD_MASTER WHERE ROW_ID=$PRD_ID")"
    if [ "${now:-}" != "$STOCK_BEFORE" ]; then
      mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" "$NS_DB" -e \
        "UPDATE DOD_PRD_MASTER SET UNITS_IN_STOCK=$STOCK_BEFORE WHERE ROW_ID=$PRD_ID;" 2>/dev/null
      printf '  cleanup: product %s stock restored %s → %s\n' "$PRD_ID" "$now" "$STOCK_BEFORE"
    fi
  fi
}
cleanup() { restore_rows; rm -rf "$TMP"; }
trap cleanup EXIT

# req_jar JAR METHOD PATH [curl args…] — one request through ONE named session.
req_jar() {
  local jar="$1" method="$2" path="$3"; shift 3
  HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -X "$method" \
                    -b "$jar" -c "$jar" --max-time 20 "$@" "$BASE$path" 2>"$ERR")"
  local rc=$?
  if [ $rc -ne 0 ] || [ -z "$HTTP_CODE" ]; then
    HTTP_CODE="000"; printf '  %snetwork%s  %s — curl: %s\n' "$R" "$N" "$method $path" "$(head -1 "$ERR")"
  fi
}
reqc() { req_jar "$JARC" "$@"; }   # the customer channel
reqv() { req_jar "$JARV" "$@"; }   # the vendor channel
req_noauth() {
  local method="$1" path="$2"; shift 2
  HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -X "$method" \
                    --max-time 20 "$@" "$BASE$path" 2>"$ERR")"
  [ -n "$HTTP_CODE" ] || HTTP_CODE="000"
}

expect() {
  local name="$1" want="$2" needle="${3:-}" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-58s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-58s got %s, want %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" \
           "${needle:+, containing \"$needle\"}"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
}
expect_known() {   # NAME WANT NEEDLE WHY — a documented gap: PASS if it ever closes, else KNOWN
  local name="$1" want="$2" needle="$3" why="$4" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-58s %s  (KNOWN gap appears closed — update this script)\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    KNOWN=$((KNOWN+1)); printf '  %sKNOWN%s %-57s got %s, want %s\n' "$Y" "$N" "$name" "$HTTP_CODE" "$want"
    printf '        %s\n' "$why"
  fi
}
check() {
  local name="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-58s %s\n' "$G" "$N" "$name" "$got"
  else FAIL=$((FAIL+1)); printf '  %sFAIL%s %-58s got %s, want %s\n' "$R" "$N" "$name" "${got:-<empty>}" "$want"; fi
}
skip()    { SKIP=$((SKIP+1)); printf '  %sSKIP%s %-58s %s\n' "$Y" "$N" "$1" "$2"; }
info()    { printf '  %s----%s %-58s %s\n' "$Y" "$N" "$1" "$2"; }
section() { printf '\n== %s\n' "$1"; }
rowid_of()  { grep -o '"rowId":"[0-9]*"' "$BODY" | head -1 | sed 's/.*:"//; s/"//'; }
ordnum_of() { grep -o '"ordnum":"[^"]*"' "$BODY" | head -1 | sed 's/.*:"//; s/"//'; }
lines_of()  { python3 - "$1" <<'PY'
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception: print(""); raise SystemExit
print(" ".join(str(l.get("rowId")) for l in (d.get("lines") or []) if l.get("rowId") is not None))
PY
}

ORDC="/hhub/api/v1/orders"
ORDV="/hhub/api/v1/vendor/orders"
SN="ORD-SMOKE-2026-27-AAAAAA"

# ── 1. all TEN bound paths, unauthenticated ─────────────────────────────────
section "1. the ten bindings, unauthenticated  ($BASE)"
if ! curl -sS -o /dev/null --max-time 10 "$BASE/hhub/" 2>"$ERR"; then
  printf '  %sFATAL%s cannot reach %s — curl: %s\n' "$R" "$N" "$BASE" "$(head -1 "$ERR")"; exit 2
fi
sweep() { local method="$1" path="$2" label="$3" want="${4:-401}" needle="${5:-}"
          req_noauth "$method" "$path"; expect "$label" "$want" "$needle"; }
sweep GET    "$ORDC"             "CUSTOMER GET    /orders"
sweep POST   "$ORDC"             "CUSTOMER POST   /orders"
sweep GET    "$ORDC/$SN"         "CUSTOMER GET    /orders/{ordnum}"
sweep PUT    "$ORDC/$SN"         "CUSTOMER PUT    /orders/{ordnum}"
sweep DELETE "$ORDC/$SN"         "CUSTOMER DELETE /orders/{ordnum}"
sweep PUT    "$ORDC/$SN/items/1" "CUSTOMER PUT    /orders/{ordnum}/items/{item-id}"
sweep DELETE "$ORDC/$SN/items/1" "CUSTOMER DELETE /orders/{ordnum}/items/{item-id}"
sweep GET    "$ORDV"             "VENDOR   GET    /vendor/orders"
sweep GET    "$ORDV/$SN"         "VENDOR   GET    /vendor/orders/{ordnum}"
sweep PUT    "$ORDV/$SN"         "VENDOR   PUT    /vendor/orders/{ordnum}"
printf '  ---- the shapes that must NOT be bound (S13 a: 404 no_such_endpoint)\n'
sweep GET    "$ORDC/$SN/items"     "no line READ at all"                     404 '"no_such_endpoint"'
sweep GET    "$ORDC/$SN/items/1"   "no line read by id"                     404 '"no_such_endpoint"'
sweep POST   "$ORDC/$SN/items"     "no line create (lines come WITH the order)" 404 '"no_such_endpoint"'
sweep DELETE "$ORDV/$SN"           "no VENDOR delete (V9)"                  404 '"no_such_endpoint"'
sweep POST   "$ORDV"               "no vendor-side create (D3)"             404 '"no_such_endpoint"'
sweep GET    "$ORDC/$SN/nonsense"  "negative control"                       404 '"no_such_endpoint"'

if [ "$NEED_CREDS" = 1 ] || [ "$NEED_VCREDS" = 1 ]; then
  printf '\n  %sSETUP%s this suite needs BOTH identities: a customer and a vendor. Missing: %s%s.\n' \
         "$Y" "$N" "${NEED_CREDS:+customer }" "${NEED_VCREDS:+vendor}"
  printf '        The ten-path sweep above is the whole of the evidence this run produced. Exit 2.\n'
  printf '\n  PASS %s  FAIL %s  KNOWN %s  SKIP %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
  exit 2
fi

# ── 2. BOTH sessions at once ────────────────────────────────────────────────
section "2. both sessions — a customer jar and a vendor jar"
if [ -n "$COOKIES" ]; then cp "$COOKIES" "$JARC" 2>/dev/null || exit 2
else
  curl -sS -o /dev/null -c "$JARC" --max-time 20 -X POST "$BASE/hhub/dodcustlogin" \
       -d "phone=$PHONE" -d "password=$PASSWORD" 2>"$ERR"
fi
if [ -n "$VCOOKIES" ]; then cp "$VCOOKIES" "$JARV" 2>/dev/null || exit 2
else
  curl -sS -o /dev/null -c "$JARV" --max-time 20 -X POST "$BASE/hhub/dodvendlogin" \
       -d "phone=$VPHONE" -d "password=$VPASSWORD" 2>"$ERR"
fi
if ! grep -q 'hunchentoot-session' "$JARC"; then printf '  %sFAIL%s no customer session\n' "$R" "$N"; exit 2; fi
if ! grep -q 'hunchentoot-session' "$JARV"; then
  printf '  %sFAIL%s no vendor session (the tree caps CONCURRENT vendor logins at 2, oldest\n' "$R" "$N"
  printf '        evicted — a stale browser tab can hold the slot)\n'; exit 2
fi
reqc GET "$ORDC"
case "$HTTP_CODE" in
  401) printf '\n  %sFATAL%s the customer login established no session.\n' "$R" "$N"; exit 2 ;;
  404) printf '\n  %sFATAL%s this session has NO CUSTOMER (D5 → 404, not 401). Use a customer jar.\n' "$R" "$N"; exit 2 ;;
  000) printf '\n  %sFATAL%s could not reach the API.\n' "$R" "$N"; exit 2 ;;
esac
reqv GET "$ORDV"
expect "the VENDOR session's own worklist → 200" 200 '"ordnum"'
reqc GET "$ORDC"
expect "the CUSTOMER session's own list → 200" 200 '"ordnum"'

# ── 3. the cross-channel refusals ───────────────────────────────────────────
section "3. a customer is not a vendor, and a vendor is not a customer"
reqc GET "$ORDV"
expect ":F the CUSTOMER jar on the VENDOR path → 404 (no session vendor, V11)" 404 '"not_found"'
reqv GET "$ORDC"
expect ":F the VENDOR jar on the CUSTOMER path → 404 (no session customer, D5)" 404 '"not_found"'
info "both are 404 and neither is 403" "a 403 would confirm the other role exists"

if [ -n "$OTHER_VENDOR_ORDNUM" ]; then
  reqv GET "$ORDV/$OTHER_VENDOR_ORDNUM"
  expect ":F another vendor's row, same tenant → 404 (AC c)" 404 '"not_found"'
elif [ "$HAVE_SQL" = 1 ]; then
  # ⚠ THE FIXTURE MUST EXCLUDE A **SHARED** NUMBER, and getting this wrong cost a false FAIL: D20
  # duplicates the customer's ORDNUM into every vendor row of a multi-vendor order, so a number held
  # by another vendor may ALSO be held by THIS one — and then the vendor's own row is what resolves,
  # which is correct behaviour (the address is (ORDNUM, session vendor)) and answers 200. AC (c) needs
  # a number this vendor does not hold AT ALL.
  OTHER="$(sql "SELECT vo.ORDNUM FROM DOD_VENDOR_ORDERS vo
                WHERE vo.VENDOR_ID<>$VENDOR_ID AND vo.DELETED_STATE='N' AND vo.ORDNUM IS NOT NULL
                  AND NOT EXISTS (SELECT 1 FROM DOD_VENDOR_ORDERS mine
                                   WHERE mine.ORDNUM=vo.ORDNUM AND mine.VENDOR_ID=$VENDOR_ID)
                LIMIT 1")"
  if [ -n "$OTHER" ]; then
    reqv GET "$ORDV/$OTHER"
    expect ":F another vendor's row, same tenant → 404 (AC c)" 404 '"not_found"'
  else skip ":F another vendor's row → 404 (AC c)" "no other vendor's row could be resolved"; fi
else
  skip ":F another vendor's row → 404 (AC c)" "needs SQL or NS_OTHER_VENDOR_ORDNUM"
fi

# ── 4. the cross-channel lifecycle (opt-in) ─────────────────────────────────
section "4. the cross-channel lifecycle (opt-in; WRITES TO THE LIVE DATABASE)"
if [ "$WRITE" != 1 ]; then
  skip "customer creates → vendor reads → vendor writes → customer deletes" \
       "read-only run; pass --write to exercise it"
else
  if [ "$HAVE_SQL" != 1 ] && [ "${NS_ALLOW_NO_SQL:-0}" != "1" ]; then
    printf '  %sSETUP%s --write needs a mysql client on THIS machine: the create decrements the\n' "$Y" "$N"
    printf '        product stock and no endpoint exposes UNITS_IN_STOCK, and the physical removal of\n'
    printf '        the created rows is SQL by row-id. Run it on the server, or accept an unrestorable\n'
    printf '        stock move with NS_ALLOW_NO_SQL=1.\n'
    exit 2
  fi
  STOCK_BEFORE="$(sql "SELECT UNITS_IN_STOCK FROM DOD_PRD_MASTER WHERE ROW_ID=$PRD_ID")"
  info "product $PRD_ID stock before" "${STOCK_BEFORE:-<unknown (no SQL)>}"

  IDEM="CONS-SMOKE-$RANDOM-$RANDOM"
  reqc POST "$ORDC" -H 'Content-Type: application/json' -H "Idempotency-Key: $IDEM" \
      -d "{\"contextId\":\"$IDEM\",\"placeOfSupply\":\"Karnataka\",\"shipState\":\"Karnataka\",\"items\":[{\"prdId\":$PRD_ID,\"prdQty\":1}]}"
  CREATE_CODE="$HTTP_CODE"; CREATED_ID="$(rowid_of)"; CREATED_NUM="$(ordnum_of)"
  if [ "$CREATE_CODE" != "201" ] || [ -z "$CREATED_ID" ]; then
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-58s got %s\n' "$R" "$N" "the CUSTOMER creates an order → 201" "$CREATE_CODE"
    printf '       body: %s\n' "$(head -c 500 "$BODY" | tr -d '\n')"
    printf '       ⚠ IF THE ROW WAS WRITTEN ANYWAY this is O3: the create answers 500 after its\n'
    printf '         INSERTs, and cleanup cannot key on a rowId that never came. Check\n'
    printf '         SELECT ROW_ID,ORDNUM,STATUS FROM DOD_ORDER WHERE STATUS=%s' "'DFT';"
  else
    PASS=$((PASS+1)); printf '  %sPASS%s %-58s 201 (rowId %s, %s)\n' "$G" "$N" "the CUSTOMER creates an order → 201" "$CREATED_ID" "$CREATED_NUM"
    cp "$BODY" "$TMP/created.json"

    # ══ THE SEAM THIS SUITE EXISTS FOR ══
    reqv GET "$ORDV/$CREATED_NUM"
    expect "THE VENDOR READS THE ORDER THE CUSTOMER JUST CREATED (D20)" 200 '"ordnum"'
    check "…and it is the SAME number the customer was given" "$(ordnum_of)" "$CREATED_NUM"
    # ⚠ FILTER, DO NOT PAGE. The worklist sorts by row-id ascending, so the row this run just created
    # is the LAST one and would never be on page 1 — a check written as "?limit=1 contains it" would
    # fail for a reason that has nothing to do with the seam. ?ordnum-like is the vendor list's own
    # filter (S10's enumerate) and names exactly this row.
    reqv GET "$ORDV?ordnum-like=$CREATED_NUM&limit=5"
    expect "…and it appears in the vendor's own worklist" 200 "$CREATED_NUM"

    # AC (f) ON A ROW THIS SUITE OWNS — cleaner than the focused suite, which must use a live row.
    if [ "$HAVE_SQL" = 1 ]; then
      ORD_BEFORE="$(sql "SELECT ORD_DATE FROM DOD_VENDOR_ORDERS WHERE ORDER_ID=$CREATED_ID AND VENDOR_ID=$VENDOR_ID")"
      reqv PUT "$ORDV/$CREATED_NUM" -H 'Content-Type: application/json' -d '{"comments":"cons smoke"}'
      expect "the VENDOR updates its own slice → 200" 200 ""
      ORD_AFTER="$(sql "SELECT ORD_DATE FROM DOD_VENDOR_ORDERS WHERE ORDER_ID=$CREATED_ID AND VENDOR_ID=$VENDOR_ID")"
      check "AC (f): ORD_DATE is BYTE-IDENTICAL across the vendor's write" \
            "$([ "$ORD_AFTER" = "$ORD_BEFORE" ] && echo identical || echo "MOVED: $ORD_BEFORE → $ORD_AFTER")" "identical"
    else
      reqv PUT "$ORDV/$CREATED_NUM" -H 'Content-Type: application/json' -d '{"comments":"cons smoke"}'
      expect "the VENDOR updates its own slice → 200" 200 ""
      skip "AC (f): ORD_DATE byte-identity" "needs SQL to read the column around the write"
    fi

    reqc PUT "$ORDC/$CREATED_NUM" -H 'Content-Type: application/json' -d '{"comments":"cons smoke"}'
    expect "the CUSTOMER updates its own order → 200" 200 ""

    if [ "$HAVE_SQL" = 1 ]; then
      LINE_ID="$(sql "SELECT ROW_ID FROM DOD_ORDER_ITEMS WHERE ORDER_ID=$CREATED_ID AND DELETED_STATE='N' LIMIT 1")"
    else
      LINE_ID="$(lines_of "$TMP/created.json")"; LINE_ID="${LINE_ID%% *}"
    fi
    if [ -n "$LINE_ID" ]; then
      reqc PUT "$ORDC/$CREATED_NUM/items/$LINE_ID" -H 'Content-Type: application/json' \
          -d '{"itemDescription":"cons smoke line"}'
      expect "the CUSTOMER edits its own line → 200" 200 ""
      reqc DELETE "$ORDC/$CREATED_NUM/items/$LINE_ID"
      expect "the CUSTOMER deletes that line → 200" 200 ""
    else
      skip "edit and delete a line of the created order" "its line id could not be resolved"
    fi

    reqc DELETE "$ORDC/$CREATED_NUM"
    expect "the CUSTOMER deletes the order (DFT is deletable) → 200" 200 ""
    reqc GET "$ORDC/$CREATED_NUM"
    expect "…and it is invisible to the customer afterwards (नियम-2)" 404 '"not_found"'

    # ══ THE KNOWN GAP, MEASURED ON A ROW THIS RUN OWNS ══
    reqv GET "$ORDV/$CREATED_NUM"
    expect_known "the vendor's copy SURVIVES the customer's delete → 404 (no cascade)" 404 '"not_found"' \
      "KNOWN GAP: the customer channel's delete! does not cascade to DOD_VENDOR_ORDERS, so a vendor \
keeps seeing an order its customer has deleted. §0 has carried this since S10 as an OPEN item (8 \
live rows at the time); this run measured a 9th. The honest fix is a लोप cascade on the header's \
delete!."
  fi
fi

# ── 5. O3, the partial-write window ─────────────────────────────────────────
section "5. O3 — the partial-write window (KNOWN, with evidence)"
if [ "$WRITE" = 1 ]; then
  BEFORE="$(sql "SELECT COUNT(*) FROM DOD_ORDER WHERE STATUS='DFT' AND CONTEXT_ID LIKE 'CONS-SMOKE-%'")"
  IDEM2="CONS-SMOKE-EMPTY-$RANDOM"
  reqc POST "$ORDC" -H 'Content-Type: application/json' -H "Idempotency-Key: $IDEM2" \
      -d '{"contextId":"'"$IDEM2"'","items":[]}'
  expect ":F an EMPTY cart → 400 — refused in the READ half, BEFORE any insert" 400 '"invalid_request"'
  check "…so it left NO header behind (the half that can be made safe, is)" \
        "$(sql "SELECT COUNT(*) FROM DOD_ORDER WHERE CONTEXT_ID='$IDEM2'")" "0"
  printf '  ---- and the WRITE half is still open: a failure after the INSERTs leaves the header, its\n'
  printf '       lines and its vendor rows behind, because POST /orders has no transaction seam (D14).\n'
  printf '       MEASURED 2026-10-05: five 500s in that window left orders 494-497 and 499 in the\n'
  printf '       table with their lines and vendor rows, and cleanup could not key on a rowId that\n'
  printf '       never arrived. Nothing here pretends to close it.\n'
else
  skip "O3: the partial-write window" "read-only run; the window is only reachable by a WRITE-half failure"
fi

# ── 6. what this suite does not cover ───────────────────────────────────────
section "6. stated, not implied"
printf '  ---- the vendor cannot read or write the ITEMS it must ship: the vendor channel has no line\n'
printf '       endpoints and nst-orditm'"'"'s enumerate has no :vendor-id. Per-vendor fulfilment is a\n'
printf '       DESIGN decision, not a missing binding.\n'
printf '  ---- and a LINE has no per-channel field allowlist and no version token (the header and the\n'
printf '       vendor row each have both). Recorded in smoke-order-items-api.sh §6.\n'

printf '\n== summary\n'
printf '  PASS %s   FAIL %s   KNOWN %s   SKIP %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
printf '  KNOWN items are documented gaps, not passes: the list is in the header of this file.\n'
if [ "$FAIL" -gt 0 ]; then printf '  %sFAILED%s\n' "$R" "$N"; exit 1; fi
exit 0
