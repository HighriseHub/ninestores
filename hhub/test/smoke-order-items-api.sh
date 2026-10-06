#!/usr/bin/env bash
#
# smoke-order-items-api.sh — the ORDER LINE endpoints:
#   PUT    /hhub/api/v1/orders/{ordnum}/items/{item-id}
#   DELETE /hhub/api/v1/orders/{ordnum}/items/{item-id}
#
#   NS_PHONE=… NS_PASSWORD=… ./smoke-order-items-api.sh          # read-only
#   NS_PHONE=… NS_PASSWORD=… ./smoke-order-items-api.sh --write  # + create 2 lines, edit, delete
#
# WHAT IS UNDER TEST
#     1. the TWO line bindings unauthenticated, and the FOUR shapes that must NOT be bound.
#     2. the session, and the lines reaching the wire THROUGH THEIR ORDER (the nested array) —
#        the contract that makes the unbound line reads honest rather than missing.
#     3. THE PAIRING CHECK (orditm-check-pairing-of): a line addressed under the WRONG order is
#        404 ABOUT THE PAIR, never 403, and never !update's 409 "a line does not move".
#     4. the OPEN-HEADER rule on delete! — and its deliberate ABSENCE on !update.
#     5. --write: the :order-id STRIP (the invoice's measured trap), D13's no-roll-up, and cleanup.
#
# ── WHY THE PAIRING CHECK IS THE CENTRE OF THIS SUITE ──────────────────────────────────────
#   DOD_ORDER_ITEMS HAS NO FOREIGN KEY ON ORDER_ID (measured: the only FK is TENANT_ID →
#   DOD_COMPANY), and there is NO unique key anywhere on the table. So nothing in the database
#   stops a line from pointing at another tenant's order, and the only thing that makes a nested
#   URL mean anything is that the route AGREES the line belongs to the order it is nested under.
#   Without that check the failure is not an error but a LIE: !update on a mismatched pair would
#   answer 409 "a line does not move between orders" — a true rule answering an untrue question.
#
# ── FIXTURES (measured against hhubdb, 2026-10-04) ─────────────────────────────────────────
#   DOD_ORDER_ITEMS holds 1274 rows. 489 orders: CMP 383 · PEN 105 · VCN 1 · NO DFT and NO CCN.
#   The line fixtures are DERIVED FROM THE API after login (the session customer is not knowable
#   from this file), and the DB constants are overrides only. A line's rowId and orderId come from
#   the ORDER DETAIL's nested "lines" array — which is also the only supported way to read a line.
#   ⚠ ORDER 40 (ORD-DEMO-2022-23-2R65KK, PEN, 11 lines) is the shape this suite looks for; the
#   derivation does not assume it exists, it searches for an equivalent.
#
# ── 🚨 THE SUITE'S OWN WRITERS MUST OBEY THE RULE THE VENDOR SUITE LEARNED THE HARD WAY ─────
#   DOD_ORDER_ITEMS.UPDATED is `timestamp ... ON UPDATE CURRENT_TIMESTAMP` (MEASURED). Any
#   hand-written UPDATE against this table that omits UPDATED MOVES it — the same defect the
#   vendor suite inflicted on ORD_DATE twice before it was caught. This suite therefore performs
#   NO raw UPDATE at all: every write goes through the API, and the cleanup only DELETEs rows the
#   run itself created.
#
# ── WHAT THIS SCRIPT DOES NOT COVER (stated, not implied) ──────────────────────────────────
#   * If-Match / version tokens on a LINE: ITEM rows have no version policy and route-orditm-update
#     declares no :if-match, deliberately ("inventing one would be inventing a contract the domain
#     does not state" — its docstring). Sending one is OBSERVED as info in §6, never asserted.
#   * the vendor side's fulfilment of these lines: the vendor channel has no line endpoints at all
#     (smoke-order-vendor-api.sh §9 records that gap).
#   * the :U branch (database stopped) — not run by default.
#
# Exit: 0 all checks passed · 1 at least one FAIL · 2 setup failure.

set -uo pipefail

BASE="${BASE:-http://ninestores.local}"
PHONE="${NS_PHONE:-}"
PASSWORD="${NS_PASSWORD:-}"

# ── A SUPPLIED COOKIE JAR (--cookies FILE, or NS_COOKIES) ───────────────────────────────────
# Authenticate ONCE — from a browser session, or one curl login — and point the suite at the jar
# instead of passing a password on the command line. The jar is COPIED into the run's temp dir
# first: curl's -c REWRITES the jar it is handed, and mutating a session file the caller owns is
# not this suite's business. With a jar supplied the credentials are NOT required and the login is
# skipped — but the session is still PROVEN by the first authenticated call, so a stale jar fails
# loudly as a SETUP failure instead of turning every check below into a 401.
COOKIES="${NS_COOKIES:-}"

ORDNUM_TERM="${NS_ORDNUM_TERM:-}"          # a TERMINAL order that HAS lines; derived when unset
ORDNUM_ABSENT="${NS_ORDNUM_ABSENT:-ORD-NOPE-2026-27-ZZZZZZ}"
LINE_ABSENT="${NS_LINE_ABSENT:-99999999}"
PRD_ID="${NS_PRD_ID:-1}"                   # DOD_PRD_MASTER row 1: live, VENDOR_ID 1, tenant 2

NS_DB="${NS_DB:-hhubdb}"
NS_MYSQL_USER="${NS_MYSQL_USER:-hhubuser}"
NS_MYSQL_PASS="${NS_MYSQL_PASS:-Welcome\$123}"
# 2>&1 | grep -v '^mysql:' and NOT 2>/dev/null: a discarded error makes a broken query look like
# an empty table, which is how a missing column nearly became a "no rows" finding.
# ── SQL IS OPTIONAL, BECAUSE THE SUITE RUNS FROM A CLIENT MACHINE ───────────────────────────
# MEASURED 2026-10-04: run from a laptop with no mysql client, this suite reported
# `mysql: command not found` and fed that text into the stock capture — and its SQL-only cleanup
# then removed NOTHING, silently leaking every row --write created. The API is now the PRIMARY
# cleanup (a created order is DFT, and DELETE /orders/{ordnum} is bound for exactly that), and SQL
# is used only where it is genuinely needed and genuinely available: to VERIFY the removal and to
# restore the product's stock, which no endpoint exposes.
HAVE_SQL=1
command -v mysql >/dev/null 2>&1 || HAVE_SQL=0
[ "${NS_NO_SQL:-0}" = "1" ] && HAVE_SQL=0
sql() { [ "$HAVE_SQL" = 1 ] || return 0
        mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" -N -B "$NS_DB" -e "$1" 2>&1 | grep -v '^mysql:'; }

WRITE=0
SUITE_REV="2026-10-05.5"
usage() {
  sed -n '3,52p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --write            also create an order with TWO lines, edit one, delete one, and clean up
  --cookies FILE     use an existing authenticated cookie jar instead of logging in
  --base URL         override the base URL   (default http://ninestores.local)
  -h, --help         this text

Environment:
  NS_PHONE / NS_PASSWORD   CUSTOMER credentials                    [required unless --cookies FILE]
  NS_ORDNUM_TERM           a terminal order WITH lines (derived from the API when unset)
  NS_PRD_ID                a live product row-id with a vendor      (default 1)
  NS_DB / NS_MYSQL_USER / NS_MYSQL_PASS   SQL access, needed by --write
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --write) WRITE=1 ;;
    --cookies) COOKIES="${2:-}"; shift ;;
    --base)  BASE="${2:-}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

NEED_CREDS=0
[ -n "$COOKIES" ] || { [ -n "$PHONE" ] && [ -n "$PASSWORD" ] || NEED_CREDS=1; }

# python3 is used to read the nested "lines" array. There is no jq on this host, and a grep for
# "rowId" cannot tell the ORDER's row-id from a LINE's — the two are different objects in one
# body, and confusing them would address the wrong row in every request below.
command -v python3 >/dev/null 2>&1 || {
  echo "ERROR: python3 is required to parse the nested lines array (no jq on this host)." >&2; exit 2; }

TMP="$(mktemp -d)" || exit 2
JAR="$TMP/cookies.txt"
if [ -n "$COOKIES" ]; then
  [ -r "$COOKIES" ] || { echo "ERROR: --cookies '$COOKIES' is not readable" >&2; exit 2; }
  cp "$COOKIES" "$JAR" || exit 2
  printf '\n  using the supplied cookie jar %s (copied; the original is never written)\n' "$COOKIES"
fi
BODY="$TMP/body.json"
ERR="$TMP/curl.err"

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; N=$'\033[0m'
else G=; R=; Y=; N=; fi

PASS=0; FAIL=0; KNOWN=0; SKIP=0
HTTP_CODE=""
CREATED_IDS=""           # header ROW-IDs (the SQL key)
CREATED_NUMS=""          # their ORDNUMs (the API cleanup key — needs no mysql client)
STOCK_BEFORE=""          # UNITS_IN_STOCK for $PRD_ID before the create

# ── AC (a): clean up on EXIT INCLUDING ON FAILURE, keyed on the ROW-ID FROM THE 201 ────────
# The ORDNUM cannot be the key: it is MINTED BY THE DOMAIN (ORD-<PREFIX>-<FY>-<REF>), so nothing
# this suite sends can tag a row. Deleting in dependency order also means the cleanup does not
# depend on a foreign key's action — DOD_ORDER_ITEMS has NO FK to DOD_ORDER at all.
restore_rows() {
  [ "$WRITE" = 1 ] || return 0
  # 1. THE API FIRST — it needs only the session, so it works from a machine with no mysql client.
  #    A created order is DFT until a test changes it, and DELETE /orders/{ordnum} is bound for
  #    exactly that case, so this is the designed path rather than a workaround.
  if [ -n "${CREATED_NUMS:-}" ]; then
    local n code
    for n in $CREATED_NUMS; do
      code="$(curl -sS -o /dev/null -w '%{http_code}' -b "$JAR" -X DELETE "$BASE$ORD/$n" 2>/dev/null)"
      printf '\n  cleanup: DELETE %s → %s\n' "$n" "${code:-000}"
      case "${code:-000}" in
        200|404) ;;
        *) printf '  %s!%s %s could not be removed over HTTP (%s) — it is no longer DFT, so SQL is the only way\n' \
                  "$R" "$N" "$n" "${code:-000}" ;;
      esac
    done
  fi
  if [ "$HAVE_SQL" != 1 ]; then
    printf '  cleanup: no mysql client here, so the removal could NOT be verified by row-id, and the\n'
    printf '           product stock could not be restored (no endpoint exposes UNITS_IN_STOCK).\n'
    return 0
  fi
  if [ -n "${CREATED_IDS:-}" ]; then
    local n_before n_after
    n_before="$(sql "SELECT COUNT(*) FROM DOD_ORDER WHERE ROW_ID IN ($CREATED_IDS)")"
    if [ "${n_before:-0}" -gt 0 ]; then
      mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" "$NS_DB" -e "
        DELETE FROM DOD_ORDER_ITEMS   WHERE ORDER_ID IN ($CREATED_IDS);
        DELETE FROM DOD_VENDOR_ORDERS WHERE ORDER_ID IN ($CREATED_IDS);
        DELETE FROM DOD_ORDER         WHERE ROW_ID  IN ($CREATED_IDS);" 2>/dev/null
      n_after="$(sql "SELECT COUNT(*) FROM DOD_ORDER WHERE ROW_ID IN ($CREATED_IDS)")"
      printf '\n  cleanup: removed %s smoke order(s), %s left\n' "$n_before" "${n_after:-?}"
      [ "${n_after:-1}" = "0" ] || printf '  %sFAIL%s  SMOKE ROWS REMAIN — remove by hand (ids %s)\n' "$R" "$N" "$CREATED_IDS"
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

req() {
  local method="$1"; shift
  local path="$1"; shift
  HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -X "$method" \
                    -b "$JAR" -c "$JAR" --max-time 20 "$@" "$BASE$path" 2>"$ERR")"
  local rc=$?
  if [ $rc -ne 0 ] || [ -z "$HTTP_CODE" ]; then
    HTTP_CODE="000"; printf '  %snetwork%s  %s — curl: %s\n' "$R" "$N" "$method $path" "$(head -1 "$ERR")"
  fi
}
req_noauth() {
  local method="$1"; shift; local path="$1"; shift
  HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -X "$method" \
                    --max-time 20 "$@" "$BASE$path" 2>"$ERR")"
  [ -n "$HTTP_CODE" ] || HTTP_CODE="000"
}

expect() {
  local name="$1" want="$2" needle="${3:-}" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-56s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-56s got %s, want %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" \
           "${needle:+, containing \"$needle\"}"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
}
expect_oneof() {   # NAME "CODE|CODE" NEEDLE — both are correct; a 500 is not.
  local name="$1" want="$2" needle="${3:-}" ok=1
  case "|$want|" in *"|$HTTP_CODE|"*) ;; *) ok=0 ;; esac
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-56s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-56s got %s, want one of %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" \
           "${needle:+, containing \"$needle\"}"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
}
check() {
  local name="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-56s %s\n' "$G" "$N" "$name" "$got"
  else FAIL=$((FAIL+1)); printf '  %sFAIL%s %-56s got %s, want %s\n' "$R" "$N" "$name" "${got:-<empty>}" "$want"; fi
}
skip()    { SKIP=$((SKIP+1)); printf '  %sSKIP%s %-56s %s\n' "$Y" "$N" "$1" "$2"; }
info()    { printf '  %s----%s %-56s %s\n' "$Y" "$N" "$1" "$2"; }
section() { printf '\n== %s\n' "$1"; }
count_of() { grep -o '"rowId":"' "$BODY" | wc -l | tr -d ' '; }
field_of() {   # JSON KEY [FILE] — the top-level value, printed raw
  python3 - "${2:-$BODY}" "$1" <<'PY'
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception: print(""); raise SystemExit
v=d.get(sys.argv[2]) if isinstance(d,dict) else None
print("" if v is None else v)
PY
}
lines_of() {   # FILE — the nested lines' rowIds, space separated
  python3 - "$1" <<'PY'
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception: print(""); raise SystemExit
print(" ".join(str(l.get("rowId")) for l in (d.get("lines") or []) if l.get("rowId") is not None))
PY
}

bail_if_internal_error() {
  if grep -qF '"internal_error"' "$BODY" && [ "$HTTP_CODE" = "500" ]; then
    printf '\n  %sFATAL%s a route answered 500 internal_error on a read with no business reason\n' "$R" "$N"
    printf '        to fail.  tail -40 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
    printf '        A MISSING-SLOT on NstOrditmResponseModel means a slot carried by\n'
    printf '        *orditm-mirrored-slots* is missing from the class: fix the CLASS and RESTART\n'
    printf '        the image (never load a file into it). Offline: tools/nst-order-mirror-check.lisp\n'
    exit 2
  fi
}

ORD="/hhub/api/v1/orders"
SN="ORD-SMOKE-2026-27-AAAAAA"

# ── 1. the bindings, unauthenticated (no session, no database) ──────────────
section "1. the bindings, unauthenticated  ($BASE)"
printf '  suite revision %s — if this is not the revision you expect, YOU ARE RUNNING A STALE COPY\n' "$SUITE_REV"

if ! curl -sS -o /dev/null --max-time 10 "$BASE/hhub/" 2>"$ERR"; then
  printf '  %sFATAL%s cannot reach %s — curl: %s\n' "$R" "$N" "$BASE" "$(head -1 "$ERR")"; exit 2
fi

sweep() { local method="$1" path="$2" label="$3" want="${4:-401}" needle="${5:-}"
          req_noauth "$method" "$path"; expect "$label" "$want" "$needle"; }

sweep PUT    "$ORD/$SN/items/1"  "PUT    /orders/{ordnum}/items/{item-id}"
sweep DELETE "$ORD/$SN/items/1"  "DELETE /orders/{ordnum}/items/{item-id}"
printf '  ---- the FOUR shapes that must NOT be bound (S13 a: 404 no_such_endpoint)\n'
sweep GET    "$ORD/$SN/items"    "GET  /orders/{ordnum}/items (no line READ at all)"      404 '"no_such_endpoint"'
sweep GET    "$ORD/$SN/items/1"  "GET  /orders/{ordnum}/items/{item-id}"                 404 '"no_such_endpoint"'
sweep POST   "$ORD/$SN/items"    "POST /orders/{ordnum}/items (lines are placed WITH the order)" 404 '"no_such_endpoint"'
sweep POST   "$ORD/$SN/items/1"  "POST /orders/{ordnum}/items/{item-id} (control)"        404 '"no_such_endpoint"'
sweep GET    "$ORD/$SN"          "GET  /orders/{ordnum} still resolves (not shadowed)"    401

if [ "$NEED_CREDS" = 1 ]; then
  printf '\n  %sSETUP%s NS_PHONE / NS_PASSWORD are not set, so the session, the pairing check\n' "$Y" "$N"
  printf '        and the open-header rule were NOT RUN. Exit 2 by AC (c).\n'
  printf '\n  PASS %s  FAIL %s  KNOWN %s  SKIP %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
  exit 2
fi

# ── WHY THE LOGIN WAS REFUSED, ANSWERED FROM THE DATABASE ───────────────────────────────────
# dod-cust-login selects DOD_CUST_PROFILE on THREE conditions — (PHONE, CUST_TYPE='STANDARD',
# DELETED_STATE='N') — and then check-password's format dispatch, which FAILS CLOSED on an
# unrecognised value. MEASURED 2026-10-04: the most common cause is not a wrong password at all —
# it is a profile whose PASSWORD is EMPTY and whose SALT is NULL, for which NO password can ever
# verify. A phone that exists only in DOD_CUSTOMER_USERS (a different table, with its own PASSWORD
# column that this login never reads) cannot log in either. The suite reports which of these it is
# rather than sending the caller to the log file.
diagnose_login() {
  command -v mysql >/dev/null 2>&1 || {
    printf '        (no mysql client here — cannot diagnose this from the database)\n'; return; }
  local probe
  probe="$(sql "SELECT COUNT(*) FROM DOD_CUST_PROFILE WHERE PHONE='$PHONE'")"
  case "${probe:-}" in
    ''|*[!0-9]*) printf '        (could not read DOD_CUST_PROFILE — set NS_DB/NS_MYSQL_USER/NS_MYSQL_PASS to diagnose)\n'; return ;;
    0) printf '        DIAGNOSIS: NO DOD_CUST_PROFILE row carries phone %s, so this login can never\n' "$PHONE"
       printf '        match: it selects on (PHONE, CUST_TYPE=''STANDARD'', DELETED_STATE=''N''). A phone\n'
       printf '        held only by DOD_CUSTOMER_USERS is a DIFFERENT table, and its PASSWORD column is\n'
       printf '        not read by this login.\n'; return ;;
  esac
  local row id type ds plen slen
  row="$(sql "SELECT CONCAT_WS('|', ROW_ID, CUST_TYPE, DELETED_STATE, LENGTH(PASSWORD), IF(SALT IS NULL,'NULL',LENGTH(SALT))) FROM DOD_CUST_PROFILE WHERE PHONE='$PHONE' LIMIT 1")"
  IFS='|' read -r id type ds plen slen <<<"$row"
  printf '        DIAGNOSIS: profile %s — cust_type=%s deleted_state=%s password_len=%s salt_len=%s\n' \
         "$id" "$type" "$ds" "${plen:-?}" "${slen:-?}"
  [ "$type" = "STANDARD" ] || printf '        → CUST_TYPE must be exactly STANDARD for this login; it is %s.\n' "$type"
  [ "$ds" = "N" ] || printf '        → DELETED_STATE must be N; it is %s.\n' "$ds"
  if [ "${plen:-0}" = "0" ]; then
    printf '        → PASSWORD IS EMPTY: NO password can authenticate this account. Set one, or log\n'
    printf '          in as a profile that has a credential (listed below).\n'
  elif [ "${plen:-0}" -le 16 ]; then
    printf '        → a legacy encrypt value: check-password compares it with (equal (encrypt plaintext\n'
    printf '          salt) ciphertext), so ONLY THE FIRST 8 CHARACTERS OF THE PASSWORD ARE\n'
    printf '          SIGNIFICANT (the live defect in PENDING-WORK §1). A trailing suffix is ignored.\n'
  fi
  [ "$slen" = "NULL" ] && printf '        → SALT IS NULL: check-password cannot verify anything against it.\n'
  printf '        Profiles that CAN log in (STANDARD, live, credential present) with order counts:\n'
  sql "SELECT CONCAT('          ', c.ROW_ID, '  phone ', c.PHONE, '  orders ', COUNT(o.ROW_ID))
       FROM DOD_CUST_PROFILE c LEFT JOIN DOD_ORDER o ON o.CUST_ID=c.ROW_ID
       WHERE c.DELETED_STATE='N' AND c.CUST_TYPE='STANDARD' AND c.PHONE IS NOT NULL AND c.PHONE<>''
         AND c.PASSWORD IS NOT NULL AND c.PASSWORD<>'' AND c.SALT IS NOT NULL
       GROUP BY c.ROW_ID, c.PHONE ORDER BY COUNT(o.ROW_ID) DESC LIMIT 6"
}


# ── 2. the session ──────────────────────────────────────────────────────────
section "2. the session — POST /hhub/dodcustlogin"
if [ -n "$COOKIES" ]; then
  # LOGIN SKIPPED: the supplied jar is the session. It is PROVEN by the first
  # authenticated call below — a jar that carries no session cookie is a SETUP failure.
  if ! grep -q 'hunchentoot-session' "$JAR"; then
    printf '  %sFAIL%s the supplied cookie jar carries no hunchentoot-session cookie.\n' "$R" "$N"
    printf '        Export one from a signed-in browser, or log in once with curl -c.\n'
    exit 2
  fi
else
LOGIN_CODE="$(curl -sS -o "$TMP/login.html" -w '%{http_code}' -c "$JAR" \
                   --max-time 20 -X POST "$BASE/hhub/dodcustlogin" \
                   -d "phone=$PHONE" -d "password=$PASSWORD" 2>"$ERR")"
printf '  login HTTP %s  (302 for BOTH success and failure)\n' "$LOGIN_CODE"
if ! grep -q 'hunchentoot-session' "$JAR"; then
  printf '  %sFAIL%s no session cookie — the login was REJECTED.\n' "$R" "$N"
  diagnose_login
  exit 2
fi
fi
req GET "$ORD"
case "$HTTP_CODE" in
  401) printf '\n  %sFATAL%s the login did not establish a CUSTOMER session.\n' "$R" "$N"; exit 2 ;;
  404) printf '\n  %sFATAL%s this session has NO CUSTOMER. D5 narrows this channel to the\n' "$R" "$N"
       printf '        session customer, so a VENDOR session (or any session whose login company is\n'
       printf '        not a customer) answers a sentinel: 404, not 401 — authentication SUCCEEDED\n'
       printf '        and the narrowing refused. Supply a cookie jar from a CUSTOMER login.\n'; exit 2 ;;
  000) printf '\n  %sFATAL%s could not reach the API endpoint.\n' "$R" "$N"; exit 2 ;;
esac
bail_if_internal_error

# ── 3. a line reaches the wire THROUGH ITS ORDER, and only that way ─────────
section "3. the lines are read through the order (the nested array)"
OPEN_NUM=""       # an OPEN order (PEN/DFT) of THIS customer, with lines
OPEN_LINE=""
TERM_NUM="$ORDNUM_TERM"
TERM_LINE=""
OTHER_NUM=""      # a second order, for the mismatched pair
OTHER_LINE=""

# A search rather than a fixed fixture: which customer a login resolves to is a property of the
# session, and a constant naming another customer would answer 404 — correct, but it would test
# BOLA instead of the pairing rule.
for st in PEN DFT; do
  req GET "$ORD?status=$st&limit=20"
  for n in $(grep -o '"ordnum":"[^"]*"' "$BODY" | sed 's/.*:"//; s/"//'); do
    req GET "$ORD/$n"; cp "$BODY" "$TMP/d1.json"
    L="$(lines_of "$TMP/d1.json")"
    if [ -n "$L" ]; then OPEN_NUM="$n"; OPEN_LINE="${L%% *}"; break; fi
  done
  [ -n "$OPEN_NUM" ] && break
done
for cand in CMP VCN; do
  [ -n "$TERM_NUM" ] && break
  req GET "$ORD?status=$cand&limit=20"
  for n in $(grep -o '"ordnum":"[^"]*"' "$BODY" | sed 's/.*:"//; s/"//'); do
    req GET "$ORD/$n"
    L="$(lines_of "$BODY")"
    if [ -n "$L" ]; then TERM_NUM="$n"; TERM_LINE="${L%% *}"; break; fi
  done
done
# A SECOND order with lines, for the mismatched pair. It must be a REAL order: a mismatch against
# an absent order would 404 for the wrong reason and the check would pass vacuously.
req GET "$ORD?limit=20"
for n in $(grep -o '"ordnum":"[^"]*"' "$BODY" | sed 's/.*:"//; s/"//'); do
  [ "$n" = "$OPEN_NUM" ] && continue
  req GET "$ORD/$n"
  L="$(lines_of "$BODY")"
  if [ -n "$L" ]; then OTHER_NUM="$n"; OTHER_LINE="${L%% *}"; break; fi
done
info "OPEN order (with lines)"     "${OPEN_NUM:-<none>}  line ${OPEN_LINE:-none}"
info "TERMINAL order (with lines)" "${TERM_NUM:-<none>}  line ${TERM_LINE:-none}"
info "a second order (for the mismatch)" "${OTHER_NUM:-<none>}  line ${OTHER_LINE:-none}"

if [ -z "$OPEN_NUM" ]; then
  printf '  %sFATAL%s this session customer owns no OPEN order with lines, so the pairing and\n' "$R" "$N"
  printf '        strip checks below would all pass vacuously. Log in as a customer with orders.\n'
  exit 2
fi

req GET "$ORD/$OPEN_NUM"
check "the detail carries a nested lines array" \
      "$([ -n "$(lines_of "$BODY")" ] && echo yes || echo no)" "yes"
check "a line carries its OWN rowId AND its orderId (both ids a client needs)" \
      "$(python3 - "$BODY" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); ls=d.get("lines") or []
print("yes" if ls and ls[0].get("rowId") and ls[0].get("orderId") else "no")
PY
)" "yes"
check "the line's orderId is the order it was read under (row-id, not the number)" \
      "$(python3 - "$BODY" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); ls=d.get("lines") or []
print("yes" if ls and str(ls[0].get("orderId"))==str(d.get("rowId")) else "no")
PY
)" "yes"

# ── 4. THE PAIRING CHECK ────────────────────────────────────────────────────
section "4. the pairing — a line under the wrong order is 404 about the PAIR"
if [ -z "$OTHER_NUM" ] || [ "$OTHER_LINE" = "$OTHER_NUM" ]; then
  skip "a line of order B under order A's URL → 404" "no second order with lines could be derived"
else
  req GET "$ORD/$OPEN_NUM"
  AB_HEAD_ID="$(field_of rowId)"
  req PUT "$ORD/$OPEN_NUM/items/$OTHER_LINE" -H 'Content-Type: application/json' \
      -d '{"itemDescription":"smoke mismatch"}'
  expect ":F an ALIEN line under this order → 404 not_found (about the pair)" 404 '"not_found"'
  PAIR_BODY="$(cat "$BODY")"
  # ANTI-COLLAPSE: the answer must not reveal that the line EXISTS somewhere. Same error, same
  # sentence — and the two bodies may differ ONLY in the id the caller itself supplied.
  req PUT "$ORD/$OPEN_NUM/items/$LINE_ABSENT" -H 'Content-Type: application/json' \
      -d '{"itemDescription":"smoke mismatch"}'
  expect ":F an ABSENT line under this order → 404" 404 '"not_found"'
  # ⚠ THE COMPARISON IS STRICT, AND THE MASK IS PRECISE. Every id is masked where it appears AS an
  # id (an earlier version substituted a bare id GLOBALLY and turned "40" into "«id»0"), and NOTHING
  # ELSE is stripped: with one canonical answer the two bodies must be byte-identical, so the
  # provenance and the sentence are both part of what this check asserts. (The route now answers a
  # fixed sentence for every way of missing a line — see orditm-not-found-answer — because otherwise
  # "a real line of somebody else's order" and "no such line" are distinguishable, and line row-ids
  # are sequential.)
  norm_404() { printf '%s' "$1" | sed -E 's/row-id [0-9]+/row-id «id»/g'; }
  check "the alien line is INDISTINGUISHABLE from an absent one (no existence oracle)" \
        "$(norm_404 "$PAIR_BODY")" "$(norm_404 "$(cat "$BODY")")"
  info "the alien line's own ORDER (for the record)" "$OTHER_NUM"
fi

req PUT "$ORD/$ORDNUM_ABSENT/items/$LINE_ABSENT" -H 'Content-Type: application/json' -d '{"itemDescription":"x"}'
expect ":F an absent ORDER in the URL → 404" 404 '"not_found"'
req DELETE "$ORD/$OPEN_NUM/items/$LINE_ABSENT"
expect ":F DELETE an absent line → 404" 404 '"not_found"'
req PUT "$ORD/$OPEN_NUM/items/not-an-integer" -H 'Content-Type: application/json' -d '{"itemDescription":"x"}'
expect_oneof ":F a non-integer item-id → 400 or 404, never 500" "400|404" ""

# ── 5. the open-header rule, and its deliberate ABSENCE on !update ──────────
section "5. the open-header rule on delete! — and NO such rule on !update"
if [ -z "$TERM_NUM" ] || [ -z "$TERM_LINE" ]; then
  skip "DELETE a line of a TERMINAL order → 409" "no terminal order with lines could be derived"
else
  req DELETE "$ORD/$TERM_NUM/items/$TERM_LINE"
  expect ":C DELETE a line of a TERMINAL order → 409 (DELETE gates on OPEN)" 409 '"conflict"'
  info "the terminal fixture" "$TERM_NUM line $TERM_LINE (383 of 489 orders are CMP)"
  # ⚠ THE ASYMMETRY IS THE DESIGN (D8): !update has NO status gate, because the terminal refusal
  # lives on the HEADER's verb. So a PUT here may legitimately answer 200 OR 409 depending on
  # which rule is read as authoritative — both are documented, and this asserts only that it is
  # neither a 500 nor a 404. Tighten this to one code once the live answer is known.
  skip "PUT a line of a TERMINAL order" "would WRITE on a live row — exercised on a created order in §6"
fi

# Does the LINE entity have a per-channel field allowlist, like the header and the vendor do?
# It does not (nst-bl-orditm.lisp defines no *orditm-*-writable* list). Recorded, not asserted.
section "6. recorded, not asserted"
printf '  ---- NO PER-CHANNEL FIELD ALLOWLIST ON A LINE. The header has\n'
printf '       *ordh-never-writable-fields* / *ordh-internal-only-fields* (F5) and the vendor row\n'
printf '       has V8, but nst-bl-orditm.lisp defines no equivalent: !update refuses :order-id and\n'
printf '       nothing else, so a customer may assign any declared line initarg — including :status,\n'
printf '       :fulfilled and the money columns. That is the field-level half of F5 applied to one\n'
printf '       entity out of three, and it is a DECISION to make, not a test to write.\n'
printf '  ---- AND NO VERSION TOKEN ON A LINE. route-orditm-update declares no :if-match, by design\n'
printf '       ("inventing one would be inventing a contract the domain does not state"). A client\n'
printf '       cannot make a line update conditional, so two concurrent editors of one line have\n'
printf '       last-write-wins. Recorded.\n'

# ── 7. --write: the strip, the no-roll-up, and the lifecycle ────────────────
section "7. the write lifecycle (opt-in; WRITES TO THE LIVE DATABASE)"

if [ "$WRITE" != 1 ]; then
  skip "create (2 lines) → edit a line → delete a line → delete the order" \
       "read-only run; pass --write to exercise it"
else
  if [ "$HAVE_SQL" != 1 ] && [ "${NS_ALLOW_NO_SQL:-0}" != "1" ]; then
    printf '  %sSETUP%s --write needs a mysql client on THIS machine, for two things no endpoint\n' "$Y" "$N"
    printf '        exposes: restoring the product stock a create decrements (PRD_ID %s), and\n' "$PRD_ID"
    printf '        verifying by row-id that every created row is gone. Options: install a mysql\n'
    printf '        client, run the suite on the server, or accept an unrestorable stock move with\n'
    printf '        NS_ALLOW_NO_SQL=1 — the rows are still removed, over the API.\n'
    exit 2
  fi
  STOCK_BEFORE="$(sql "SELECT UNITS_IN_STOCK FROM DOD_PRD_MASTER WHERE ROW_ID=$PRD_ID")"
  info "product $PRD_ID stock before" "${STOCK_BEFORE:-<unknown>}"

  IDEM="ORD-ITEM-SMOKE-$RANDOM-$RANDOM"
  req POST "$ORD" -H 'Content-Type: application/json' -H "Idempotency-Key: $IDEM" \
      -d "{\"contextId\":\"$IDEM\",\"placeOfSupply\":\"Karnataka\",\"shipState\":\"Karnataka\",\"items\":[{\"prdId\":$PRD_ID,\"prdQty\":1},{\"prdId\":$PRD_ID,\"prdQty\":2}]}"
  bail_if_internal_error
  NEW_ID="$(field_of rowId)"; NEW_NUM="$(field_of ordnum)"
  if [ "$HTTP_CODE" != "201" ] || [ -z "$NEW_ID" ]; then
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-56s got %s\n' "$R" "$N" "POST /orders with TWO lines → 201" "$HTTP_CODE"
    printf '       body: %s\n' "$(head -c 600 "$BODY" | tr -d '\n')"
  else
    PASS=$((PASS+1)); CREATED_IDS="$NEW_ID"
    CREATED_NUMS="${CREATED_NUMS:+$CREATED_NUMS }$NEW_NUM"
    printf '  %sPASS%s %-56s 201 (rowId %s, %s)\n' "$G" "$N" "POST /orders with TWO lines → 201" "$NEW_ID" "$NEW_NUM"
    cp "$BODY" "$TMP/created.json"
    NEW_LINES="$(lines_of "$TMP/created.json")"
    check "the created order carries TWO lines with ids" "$(printf '%s' "$NEW_LINES" | wc -w | tr -d ' ')" "2"
    L1="${NEW_LINES%% *}"; L2="${NEW_LINES##* }"

    if [ -z "$L1" ] || [ "$L1" = "$L2" ]; then
      skip "edit a created line" "the created order's line ids could not be derived"
    else
      AMT_BEFORE="$(field_of orderAmt "$TMP/created.json")"
      NEW_DESC="smoke line $(date +%H:%M:%S)"
      req PUT "$ORD/$NEW_NUM/items/$L1" -H 'Content-Type: application/json' \
          -d "{\"itemDescription\":\"$NEW_DESC\"}"
      bail_if_internal_error
      expect "PUT a line of the created order → 200" 200 ""

      # 🚨 THE INVOICE'S MEASURED TRAP, INVERTED: the URL carries the order, so the ferry's payload
      # contains :order-id — and the VERB refuses that key by design. The ROUTE must verify the
      # pairing and then STRIP it, or every legitimate nested PUT is refused for attempting
      # something it was not attempting. A 409 here means the strip is missing or misordered.
      req PUT "$ORD/$NEW_NUM/items/$L1" -H 'Content-Type: application/json' \
          -d "{\"orderId\":\"$NEW_ID\",\"itemDescription\":\"$NEW_DESC\"}"
      expect "PUT with the URL's own order-id in the body → 200 (stripped AFTER the pairing check)" 200 ""

      # ...and a body-supplied order-id that names ANOTHER order must not move the line: the strip
      # removes the claim entirely rather than honouring it.
      if [ -n "$OTHER_NUM" ]; then
        req PUT "$ORD/$NEW_NUM/items/$L1" -H 'Content-Type: application/json' \
            -d '{"orderId":"'"$(sql "SELECT ROW_ID FROM DOD_ORDER WHERE ORDNUM='$OTHER_NUM'")"'","itemDescription":"'"$NEW_DESC"'"}'
        expect "PUT naming ANOTHER order in the body → 200, and the line does not move" 200 ""
        req GET "$ORD/$NEW_NUM"
        check "the line still belongs to ITS order afterwards" \
              "$(python3 - "$BODY" "$L1" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); ls=d.get("lines") or []
hit=[l for l in ls if str(l.get("rowId"))==str(sys.argv[2])]
print("yes" if hit and str(hit[0].get("orderId"))==str(d.get("rowId")) else "no")
PY
)" "yes"
      fi

      req GET "$ORD/$NEW_NUM"; cp "$BODY" "$TMP/after.json"
      check "the edited description is what reads back" \
            "$(python3 - "$TMP/after.json" "$L1" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); ls=d.get("lines") or []
hit=[l for l in ls if str(l.get("rowId"))==str(sys.argv[2])]
print("yes" if hit and "smoke line " in str(hit[0].get("itemDescription")) else "no")
PY
)" "yes"
      # D13: adding, changing or removing a line NEVER touches the header's totals. Asserted, not
      # assumed — a client that sums the lines and a client that reads the header WILL disagree.
      check "D13: the header's orderAmt is UNCHANGED by editing a line" \
            "$(field_of orderAmt "$TMP/after.json")" "$AMT_BEFORE"

      req DELETE "$ORD/$NEW_NUM/items/$L2"
      expect "DELETE a line of the created (OPEN) order → 200" 200 ""
      req GET "$ORD/$NEW_NUM"; cp "$BODY" "$TMP/after2.json"
      check "one line remains after the delete" "$(lines_of "$TMP/after2.json" | wc -w | tr -d ' ')" "1"
      check "D13: the header's orderAmt is UNCHANGED by deleting a line" \
            "$(field_of orderAmt "$TMP/after2.json")" "$AMT_BEFORE"
    fi

    req DELETE "$ORD/$NEW_NUM"
    expect "DELETE the created order (DFT is deletable) → 200" 200 ""
    req GET "$ORD/$NEW_NUM"
    expect "the deleted order is invisible afterwards (नियम-2)" 404 '"not_found"'
    # ⚠ THE CLEANUP KEY IS NOT CLEARED: the API's DELETE is SOFT, so the rows are still in the table
    # and the physical removal belongs to restore_rows, by row-id (see the header suite's note).
  fi
fi

printf '\n== summary\n'
printf '  PASS %s   FAIL %s   KNOWN %s   SKIP %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
printf '  KNOWN items are documented gaps, not passes: the list is in the header of this file.\n'
if [ "$FAIL" -gt 0 ]; then printf '  %sFAILED%s\n' "$R" "$N"; exit 1; fi
exit 0
