#!/usr/bin/env bash
#
# smoke-order-vendor-api.sh — the VENDOR order channel: /hhub/api/v1/vendor/orders
#
#   NS_VPHONE=… NS_VPASSWORD=… ./smoke-order-vendor-api.sh          # read-only
#   NS_VPHONE=… NS_VPASSWORD=… ./smoke-order-vendor-api.sh --write  # + a real PUT and its restore
#
# WHAT IS UNDER TEST
#   The THREE vendor endpoints of S9/S10/S11 over nst-vordh (DOD_VENDOR_ORDERS) — the vendor's own
#   header for its slice of the customer's order.
#
#     1. the three bindings unauthenticated, AND the fourth path that must NOT be bound.
#     2. the session vendor, and the vendor's own worklist.
#     3. the reads, and the TRIPLE SCOPE (V3): VENDOR_ID + TENANT_ID + DELETED_STATE.
#     4. the guards: the shared sort whitelist and the page cap.
#     5. the write policy: V8's four writable fields, and the fields that are REFUSED.
#     6. AC (f) — THE ONE THAT MATTERS MOST: after a PUT, ORD_DATE is BYTE-IDENTICAL and UPDATED has
#        advanced. --write performs it and restores the field it changed.
#
# ── WHY AC (f) IS THE ASSERTION THIS SUITE EXISTS FOR ───────────────────────────────────────
#   🚨 T9 IS VENDOR-ONLY. DOD_ORDER.ORD_DATE is a `date` with no auto-update, but
#   DOD_VENDOR_ORDERS.ORD_DATE is a `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
#   ON UPDATE CURRENT_TIMESTAMP`. Any UPDATE that OMITS the column rewrites it to now(). An
#   explicit assignment in the same statement beats the auto-update; omission does not.
#   The second half is subtler and is why V5 declares `(string 30)` and not `clsql:date`: reading
#   a timestamp as clsql:date DROPS the time of day, so writing the value back would move the row
#   to MIDNIGHT while looking correct. A test that only checks "ORD_DATE did not change to now()"
#   cannot see that: it must be BYTE-IDENTICAL. Measured 2026-10-04: 387 of 466 vendor rows are
#   CMP and 4 are VCN, so refusing a terminal update is not a corner case either.
#
# ── 🚨 THE SUITE'S OWN WRITERS MUST OBEY THE RULE THE SUITE TESTS ──────────────────────────
# MEASURED 2026-10-04, the hard way: the first version of this cleanup restored COMMENTS with
# `UPDATE DOD_VENDOR_ORDERS SET COMMENTS=… WHERE …` — OMITTING ORD_DATE — and so MOVED the
# fixture's ORD_DATE to now(), TWICE, before anyone noticed. The suite that exists to prove T9
# does not fire had fired it itself. Every hand-written UPDATE here therefore assigns
# `ORD_DATE=ORD_DATE`, and that idiom was MEASURED, not read off the documentation:
#
#   A. `SET COMMENTS='t9-probe-A', ORD_DATE=ORD_DATE`   → ORD_DATE PRESERVED (00:00:00)
#   B. `SET COMMENTS='t9-probe-B'`  (ORD_DATE omitted)  → ORD_DATE MOVED to now()
#
# The two damaged rows were restored to `ORD_DATE='2026-10-04 00:00:00'` — their API-created
# shape, since the header's `date` is copied into this `timestamp` and so lands at MIDNIGHT.
# Sibling row 464, which this suite never touched, reads exactly that, and run 1 of this suite
# measured the same value on row 466 BEFORE any of its own writes.
# ⚠ `SET COMMENTS=COMMENTS` PROVES NOTHING: MySQL skips the auto-update when no column actually
# changes, so a no-op UPDATE is not a control. The change has to be real (B above).
# ⚠ AND THE DOMAIN'S WRITE IS NOT THE SAME IDIOM: it writes the value it READ, which is exact to
# the second. A hand-written statement cannot know that value, which is why it self-assigns.
#
# ── FIXTURES (all measured against hhubdb, 2026-10-04) ─────────────────────────────────────
#   Vendors with rows: 1 (tenant 2, 395) · 17 (tenant 5, 48) · 3 (tenant 2, 15) · 2 (tenant 2, 6).
#   Vendor 1 PEN row 466 = ORD-DEMO-2026-27-JMAG2M (header order 490, PEN). Its CMP rows include
#   ORD-DEMO-2026-27-3MZ6YN; its VCN rows include ORD-GCUST837-2025-26-P6ULCX. 9 vendor rows are
#   soft-deleted. ORDNUM is NULL on ZERO rows (the backfill numbered all 466), so AC (e) has NO
#   live fixture — --write MANUFACTURES one by nulling a row it created, and restores it.
#   ⚠ THE SESSION VENDOR'S ROW-ID IS RESOLVED FROM THE DATABASE after login, never assumed: the
#   address is (ORDNUM, session vendor), so a wrong vendor id would make every check a 404 and the
#   suite would "pass" its refusal cases for the wrong reason.
#
# ── AC (c), TWO WAYS, AND THE CHEAPER ONE IS THE PRIMARY ────────────────────────────────────
#   §0 assumed AC (c) needs TWO vendor logins (the tree caps concurrent vendor logins at 2,
#   evicting the oldest). It does not: asking for a row that belongs to a DIFFERENT vendor IN THE
#   SAME TENANT, while signed in as this vendor, must answer 404 — and if the VENDOR_ID predicate
#   were missing it would answer 200. That is the same property, in one session, and it cannot be
#   confused by logout/eviction timing. The two-session variant is kept as an OPTIONAL extra behind
#   NS_VPHONE2/NS_VPASSWORD2.
#
# ── 🚨 A KNOWN DEFECT THIS SUITE ENCODES RATHER THAN FAILS (S16 AC (d)) ────────────────────
#   UPDATED IS FROZEN BY THE WRITE ITSELF, MEASURED 2026-10-04. `dod-vendor-order` declares
#   `(updated :column "UPDATED")` (nst-dal-vordh.lisp:352) and !update writes with
#   `clsql:update-records-from-instance`, which writes EVERY storable slot — so UPDATED is
#   assigned EXPLICITLY from the value that was read, and an explicit assignment beats
#   `ON UPDATE CURRENT_TIMESTAMP`. Measured through this suite: ORD_DATE byte-identical,
#   COMMENTS changed, and UPDATED 13:06:23 → 13:06:23.
#   ⚠ CONSEQUENCE: the ETag is built from UPDATED (nst-bl-vordhapi.lisp:213), so the validator
#   NEVER CHANGES and F8's If-Match cannot detect a concurrent write — silent last-write-wins,
#   which is the defect F8 exists to close. The stale-token 412 below proves the COMPARISON
#   works; it cannot prove a detector that has nothing to detect.
#   `dod-order` has the same shape (nst-dal-Order.lisp:747), so the customer channel shares it.
#   `nst-bl-ordh.lisp:890`'s claim that the write "cannot touch UPDATED" is about the mirrored
#   list, i.e. the JSON boundary — a different mechanism from the SQL write.
#   FIX (verified against the installed CLSQL): `clsql:update-records` is exported
#   (sql/fdml.lisp:204) and takes :av-pairs/:where, so the write can NAME its columns and omit
#   UPDATED — while KEEPING ord-date in them, which is what keeps AC (f)'s first half green.
#
# ── WHAT THIS SCRIPT DOES NOT COVER (stated, not implied) ──────────────────────────────────
#   * delivery of per-ITEM fulfilment: the vendor channel has NO line endpoints and nst-orditm's
#     enumerate has no :vendor-id, so a vendor cannot read or write the items it must ship. This
#     is a DESIGN GAP in the batch, not a defect of these routes, and it is recorded rather than
#     asserted as a pass. Nothing here tests it either way.
#   * per-vendor tax totals: the vendor row's TOTAL_* columns keep 0.00 by decision (V15).
#   * the :U branch (database stopped) — gated behind NS_EXPECT_U=1.
#
# Exit: 0 all checks passed · 1 at least one FAIL · 2 setup failure.

set -uo pipefail

BASE="${BASE:-http://ninestores.local}"
VPHONE="${NS_VPHONE:-}"
VPASSWORD="${NS_VPASSWORD:-}"

# ── A SUPPLIED COOKIE JAR (--cookies FILE, or NS_COOKIES) ───────────────────────────────────
# Authenticate ONCE — from a browser session, or one curl login — and point the suite at the jar
# instead of passing a password on the command line. The jar is COPIED into the run's temp dir
# first: curl's -c REWRITES the jar it is handed, and mutating a session file the caller owns is
# not this suite's business. With a jar supplied the credentials are NOT required and the login is
# skipped — but the session is still PROVEN by the first authenticated call, so a stale jar fails
# loudly as a SETUP failure instead of turning every check below into a 401.
COOKIES="${NS_COOKIES:-}"

# MEASURED 2026-10-04. Overridable because a fixture ages: a row can be fulfilled, cancelled or
# soft-deleted by ordinary use, and a suite that cannot be re-pointed is a suite that rots.
VENDOR_ID="${NS_VENDOR_ID:-1}"                       # DOD_VEND_PROFILE.ROW_ID for the login
ORDNUM_OPEN="${NS_ORDNUM_VOPEN:-ORD-DEMO-2026-27-JMAG2M}"     # vendor 1, PEN
ORDNUM_TERMINAL="${NS_ORDNUM_VTERM:-ORD-DEMO-2026-27-3MZ6YN}" # vendor 1, CMP
ORDNUM_VCN="${NS_ORDNUM_VVCN:-ORD-GCUST837-2025-26-P6ULCX}"   # vendor 1, VCN
# A row of ANOTHER vendor in the SAME tenant (vendor 3, tenant 2) — AC (c).
OTHER_VENDOR="${NS_OTHER_VENDOR:-3}"
OTHER_VENDOR_ORDNUM="${NS_OTHER_VENDOR_ORDNUM:-}"
ABSENT_ORDNUM="${NS_ABSENT_ORDNUM:-ORD-NOPE-2026-27-ZZZZZZ}"
CROSS_TENANT_ORDNUM="${NS_CROSS_TENANT_ORDNUM:-ORD-PAWAN-2023-24-WZCFYC}"   # tenant 5
# A row of the session vendor used ONLY to manufacture AC (e)'s NULL-ORDNUM fixture (none is left
# in the data). Kept apart from ORDNUM_OPEN so the cleanup's own ORDNUM lookup cannot be broken.
NULL_ROW_ID="${NS_NULL_ROW_ID:-465}"

NS_DB="${NS_DB:-hhubdb}"
NS_MYSQL_USER="${NS_MYSQL_USER:-hhubuser}"
NS_MYSQL_PASS="${NS_MYSQL_PASS:-Welcome\$123}"
# 2>&1 | grep -v '^mysql:' and NOT 2>/dev/null — a discarded error makes a broken query look
# like an empty table, which is how a missing column nearly became a "no rows" finding.
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
SUITE_REV="2026-10-04.3"
usage() {
  sed -n '3,52p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --write            also perform a real PUT (AC f) and restore the field it changed
  --cookies FILE     use an existing authenticated cookie jar instead of logging in
  --base URL         override the base URL   (default http://ninestores.local)
  -h, --help         this text

Environment:
  NS_VPHONE / NS_VPASSWORD   VENDOR credentials                    [required unless --cookies FILE]
  NS_VENDOR_ID               the login vendor's DOD_VEND_PROFILE.ROW_ID   (default 1)
  NS_VPHONE (with --cookies)  identity check only; no login happens when a jar is supplied
  NS_ORDNUM_VOPEN            one of its PEN rows     (default ORD-DEMO-2026-27-JMAG2M)
  NS_ORDNUM_VTERM            one of its CMP rows     (default ORD-DEMO-2026-27-3MZ6YN)
  NS_ORDNUM_VVCN             one of its VCN rows     (default ORD-GCUST837-2025-26-P6ULCX)
  NS_OTHER_VENDOR_ORDNUM     a row of ANOTHER vendor in the SAME tenant (AC c); resolved
                             from the database when unset
  NS_VPHONE2 / NS_VPASSWORD2 optional second vendor, for the two-session AC (c) variant
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
[ -n "$COOKIES" ] || { [ -n "$VPHONE" ] && [ -n "$VPASSWORD" ] || NEED_CREDS=1; }

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
CHANGED_ORDNUM=""     # the row --write touched, so the cleanup can restore it
COMMENTS_BEFORE=""    # its COMMENTS value before the PUT
cleanup() { restore_row; rm -rf "$TMP"; }

# ── AC (a): REMOVE / RESTORE EVERYTHING THIS RUN TOUCHED, INCLUDING ON FAILURE ─────────────
# This suite CREATES NOTHING (V9 binds no delete and the vendor channel has no create), so there
# is no row to remove — what must be undone is the FIELD the --write PUT changed. It is restored
# THROUGH THE DATABASE, because the alternative (a second PUT) would be a second write whose
# failure mode is another changed field; and the ORD_DATE restoration is deliberately NOT
# attempted by SQL: if the PUT corrupted it (T9), rewriting the column by hand would DESTROY the
# evidence AC (f) exists to produce. The suite reports it and leaves the row as it found it only
# when the check passed.
restore_row() {
  [ "$WRITE" = 1 ] || return 0
  [ -n "${CHANGED_ORDNUM:-}" ] || return 0
  local now setval
  # ⚠ NULL IS NOT ''. The first version captured the comment with CONCAT_WS + IFNULL(COMMENTS,''),
  # which makes a NULL comment indistinguishable from an empty one — so the restore wrote '' where
  # the row held NULL, and the round trip was NOT byte-exact. The marker makes the two different
  # values distinguishable, which is the whole point of a cleanup that claims to restore.
  now="$(sql "SELECT IF(COMMENTS IS NULL,'<<NULL>>',COMMENTS) FROM DOD_VENDOR_ORDERS WHERE ORDNUM='$CHANGED_ORDNUM' AND VENDOR_ID=$VENDOR_ID")"
  if [ "${now:-}" != "${COMMENTS_BEFORE:-}" ]; then
    if [ "${COMMENTS_BEFORE:-}" = "<<NULL>>" ]; then
      setval="NULL"
    else
      # Escaped with sed, NOT with ${var//\'/…}: inside ${…//pat/rep} a backslash is literal and
      # does not escape anything, so that spelling compares a quote against a BACKSLASH-quote and
      # silently matches nothing — the restore would then run with an unescaped value.
      setval="'$(printf '%s' "$COMMENTS_BEFORE" | sed "s/'/''/g")'"
    fi
    mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" "$NS_DB" -e \
      "UPDATE DOD_VENDOR_ORDERS SET COMMENTS=$setval, ORD_DATE=ORD_DATE WHERE ORDNUM='$CHANGED_ORDNUM' AND VENDOR_ID=$VENDOR_ID;" 2>/dev/null
    printf '\n  restored: COMMENTS on %s put back to %s\n' "$CHANGED_ORDNUM" "$COMMENTS_BEFORE"
  fi
}
trap cleanup EXIT

req() {
  local method="$1"; shift
  local path="$1"; shift
  HTTP_CODE="$(curl -sS -o "$BODY" -D "$TMP/head.txt" -w '%{http_code}' -X "$method" \
                    -b "$JAR" -c "$JAR" --max-time 20 "$@" "$BASE$path" 2>"$ERR")"
  local rc=$?
  if [ $rc -ne 0 ] || [ -z "$HTTP_CODE" ]; then
    HTTP_CODE="000"
    printf '  %snetwork%s  %s — curl: %s\n' "$R" "$N" "$method $path" "$(head -1 "$ERR")"
  fi
}
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
    PASS=$((PASS+1)); printf '  %sPASS%s %-54s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-54s got %s, want %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" \
           "${needle:+, containing \"$needle\"}"
    printf '       body: %s\n' "$(head -c 300 "$BODY" | tr -d '\n')"
  fi
}
expect_known() {
  local name="$1" want="$2" needle="$3" why="$4" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-54s %s  (KNOWN gap appears closed)\n' "$G" "$N" "$name" "$HTTP_CODE"
  else
    KNOWN=$((KNOWN+1)); printf '  %sKNOWN%s %-53s got %s, want %s\n' "$Y" "$N" "$name" "$HTTP_CODE" "$want"
    printf '        %s\n' "$why"
  fi
}
check() {
  local name="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    PASS=$((PASS+1)); printf '  %sPASS%s %-54s %s\n' "$G" "$N" "$name" "$got"
  else
    FAIL=$((FAIL+1)); printf '  %sFAIL%s %-54s got %s, want %s\n' "$R" "$N" "$name" "${got:-<empty>}" "$want"
  fi
}
# check_known NAME GOT WANT WHY — a MEASURED defect this suite encodes. The wanted answer is a
# PASS with a note to update the script; anything else is KNOWN and NEVER a FAIL, so a documented
# gap cannot be mistaken for a regression (S16 AC (d)).
check_known() {
  local name="$1" got="$2" want="$3" why="$4"
  if [ "$got" = "$want" ]; then
    PASS=$((PASS+1))
    printf '  %sPASS%s %-54s %s  (KNOWN defect appears FIXED — update this script)\n' "$G" "$N" "$name" "$got"
  else
    KNOWN=$((KNOWN+1))
    printf '  %sKNOWN%s %-53s got %s, want %s\n' "$Y" "$N" "$name" "${got:-<empty>}" "$want"
    printf '        %s\n' "$why"
  fi
}
skip()    { SKIP=$((SKIP+1)); printf '  %sSKIP%s %-54s %s\n' "$Y" "$N" "$1" "$2"; }
info()    { printf '  %s----%s %-54s %s\n' "$Y" "$N" "$1" "$2"; }
section() { printf '\n== %s\n' "$1"; }
ordnum_of() { grep -o '"ordnum":"[^"]*"' "$BODY" | head -1 | sed 's/.*:"//; s/"//'; }
count_of()  { grep -o '"ordnum":"' "$BODY" | wc -l | tr -d ' '; }
etag_of()   { grep -i '^etag:' "$TMP/head.txt" | head -1 | sed 's/^[Ee][Tt][Aa][Gg]: *//' | tr -d '\r'; }

bail_if_internal_error() {
  if grep -qF '"internal_error"' "$BODY" && [ "$HTTP_CODE" = "500" ]; then
    printf '\n  %sFATAL%s a route answered 500 internal_error on a read that has no business\n' "$R" "$N"
    printf '        reason to fail.  tail -40 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
    printf '        A MISSING-SLOT on NstVordhResponseModel means a slot carried by\n'
    printf '        *vordh-mirrored-slots* is missing from the class: fix the CLASS and RESTART.\n'
    printf '        Offline check: tools/nst-vordh-mirror-check.lisp\n'
    exit 2
  fi
}

VORD="/hhub/api/v1/vendor/orders"
SN="ORD-SMOKE-2026-27-AAAAAA"

# ── 1. the bindings, unauthenticated ────────────────────────────────────────
section "1. the bindings, unauthenticated  ($BASE)"
printf '  suite revision %s — if this is not the revision you expect, YOU ARE RUNNING A STALE COPY\n' "$SUITE_REV"

if ! curl -sS -o /dev/null --max-time 10 "$BASE/hhub/" 2>"$ERR"; then
  printf '  %sFATAL%s cannot reach %s — curl: %s\n' "$R" "$N" "$BASE" "$(head -1 "$ERR")"
  exit 2
fi

sweep() { local method="$1" path="$2" label="$3" want="${4:-401}" needle="${5:-}"
          req_noauth "$method" "$path"; expect "$label" "$want" "$needle"; }

sweep GET  "$VORD"           "GET  /vendor/orders (the vendor's worklist)"
sweep GET  "$VORD/$SN"       "GET  /vendor/orders/{ordnum} (detail)"
sweep PUT  "$VORD/$SN"       "PUT  /vendor/orders/{ordnum} (update)"
# V9 + D3: the vendor channel binds NO delete — a vendor erasing its slice would remove the row
# the CUSTOMER's order is accounted for by. This asserts the ABSENCE, which is the decision.
sweep DELETE "$VORD/$SN"     "DELETE /vendor/orders/{ordnum} — deliberately UNBOUND (V9)" 404 '"no_such_endpoint"'
sweep POST "$VORD"           "POST /vendor/orders — no vendor-side create (D3)"          404 '"no_such_endpoint"'
sweep GET  "/hhub/api/v1/orders" "the CUSTOMER path still resolves to its own route (not shadowed)" 401

if [ "$NEED_CREDS" = 1 ]; then
  printf '\n  %sSETUP%s NS_VPHONE / NS_VPASSWORD are not set, so the session, the reads, the\n' "$Y" "$N"
  printf '        scope checks and AC (f) were NOT RUN — the binding sweep is the whole of the\n'
  printf '        evidence this run produced. Exit 2 by AC (c).\n'
  printf '\n  PASS %s  FAIL %s  KNOWN %s  SKIP %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
  exit 2
fi

# ── WHY THE VENDOR LOGIN WAS REFUSED, ANSWERED FROM THE DATABASE ────────────────────────────
# dod-vend-login selects DOD_VEND_PROFILE on FOUR conditions — (PHONE, APPROVED_FLAG='Y',
# APPROVAL_STATUS='APPROVED', DELETED_STATE='N') — and then the same format-dispatching
# check-password, which fails closed. So "the password is wrong" is only one of five causes, and
# the four others are all visible in the row.
diagnose_login() {
  command -v mysql >/dev/null 2>&1 || {
    printf '        (no mysql client here — cannot diagnose this from the database)\n'; return; }
  local row
  row="$(sql "SELECT CONCAT_WS('|', ROW_ID, IFNULL(APPROVED_FLAG,'NULL'), IFNULL(APPROVAL_STATUS,'NULL'), IFNULL(DELETED_STATE,'NULL'), LENGTH(PASSWORD), IF(SALT IS NULL,'NULL',LENGTH(SALT))) FROM DOD_VEND_PROFILE WHERE PHONE='$VPHONE' LIMIT 1")"
  if [ -z "$row" ]; then
    printf '        DIAGNOSIS: no DOD_VEND_PROFILE row carries phone %s at all.\n' "$VPHONE"; return
  fi
  local id appr apprs ds plen slen
  IFS='|' read -r id appr apprs ds plen slen <<<"$row"
  printf '        DIAGNOSIS: vendor %s — approved_flag=%s approval_status=%s deleted_state=%s password_len=%s\n' \
         "$id" "$appr" "$apprs" "$ds" "${plen:-?}"
  [ "$appr" = "Y" ] || printf '        → APPROVED_FLAG must be Y; it is %s.\n' "$appr"
  [ "$apprs" = "APPROVED" ] || printf '        → APPROVAL_STATUS must be APPROVED; it is %s.\n' "$apprs"
  [ "$ds" = "N" ] || printf '        → DELETED_STATE must be N; it is %s.\n' "$ds"
  if [ "${plen:-0}" = "0" ]; then
    printf '        → PASSWORD IS EMPTY: no password can authenticate this vendor.\n'
  elif [ "${plen:-0}" -le 16 ]; then
    printf '        → a legacy encrypt value: ONLY THE FIRST 8 CHARACTERS ARE SIGNIFICANT.\n'
  fi
  [ "$slen" = "NULL" ] && printf '        → SALT IS NULL: check-password cannot verify anything against it.\n'
  printf '        Vendors that CAN log in (approved, live, credential present):\n'
  sql "SELECT CONCAT('          ', ROW_ID, '  phone ', PHONE) FROM DOD_VEND_PROFILE
       WHERE DELETED_STATE='N' AND APPROVED_FLAG='Y' AND APPROVAL_STATUS='APPROVED'
         AND PHONE IS NOT NULL AND PHONE<>'' AND PASSWORD IS NOT NULL AND PASSWORD<>''
       ORDER BY ROW_ID LIMIT 6"
}


# ── 2. the session ──────────────────────────────────────────────────────────
section "2. the session — POST /hhub/dodvendlogin"

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
                   --max-time 20 -X POST "$BASE/hhub/dodvendlogin" \
                   -d "phone=$VPHONE" -d "password=$VPASSWORD" 2>"$ERR")"
printf '  login HTTP %s  (302 for BOTH success and failure)\n' "$LOGIN_CODE"
if ! grep -q 'hunchentoot-session' "$JAR"; then
  printf '  %sFAIL%s no session cookie — the vendor login was REJECTED.\n' "$R" "$N"
  printf '        (also: the tree caps CONCURRENT vendor logins at 2 and evicts the OLDEST, so a\n'
  printf '        stale browser tab can hold the slot — this is NOT visible in the row below)\n'
  diagnose_login
  exit 2
fi
fi

req GET "$VORD"
case "$HTTP_CODE" in
  401) printf '\n  %sFATAL%s the login did not establish a VENDOR session (401). A signed-in\n' "$R" "$N"
       printf '        CUSTOMER is not a vendor: V11 answers a sentinel here, not an error.\n'; exit 2 ;;
  000) printf '\n  %sFATAL%s could not reach the API endpoint.\n' "$R" "$N"; exit 2 ;;
esac
bail_if_internal_error
expect "GET /vendor/orders with the session → 200" 200 '"ordnum"'

# The login's phone MUST name the vendor this suite thinks it is: the address is
# (ORDNUM, session vendor), so a mismatch turns every check into a 404 that "passes" the
# refusal cases for the wrong reason.
RESOLVED_VENDOR="$(sql "SELECT ROW_ID FROM DOD_VEND_PROFILE WHERE PHONE='$VPHONE'")"
info "session vendor resolved from the phone" "${RESOLVED_VENDOR:-<not found>} (suite assumes $VENDOR_ID)"
if [ -n "$COOKIES" ] && [ -z "$VPHONE" ]; then
  # ⚠ A SUPPLIED JAR NAMES NO PHONE, so the suite cannot confirm WHICH vendor it is signed in as —
  # and that matters more than it looks: the address is (ORDNUM, session vendor), so a wrong
  # NS_VENDOR_ID turns every fixture into a 404 and the REFUSAL checks below would then pass for
  # the wrong reason. Counted as a SKIP with the reason, never passed over in silence. Set
  # NS_VPHONE (identity only — no login happens) or NS_VENDOR_ID explicitly to close it.
  skip "the session vendor's identity is verified" \
       "a supplied cookie jar names no phone — set NS_VPHONE (or NS_VENDOR_ID) to have it checked"
elif [ -n "$RESOLVED_VENDOR" ] && [ "$RESOLVED_VENDOR" != "$VENDOR_ID" ]; then
  printf '  %sFATAL%s NS_VENDOR_ID=%s does not match the login phone (%s → %s). Re-run with\n' "$R" "$N" "$VENDOR_ID" "$VPHONE" "$RESOLVED_VENDOR"
  printf '        NS_VENDOR_ID=%s, or every fixture below addresses the wrong vendor.\n' "$RESOLVED_VENDOR"
  exit 2
fi

# ── 3. the reads, and the triple scope (V3) ─────────────────────────────────
section "3. the reads — the worklist, the detail, and the SCOPE"

req GET "$VORD?limit=1"
LIST_NUM="$(ordnum_of)"
if [ -z "$LIST_NUM" ]; then
  printf '  %sFATAL%s the vendor worklist is EMPTY, so no fixture below can be exercised.\n' "$R" "$N"
  exit 2
fi
info "the vendor's own worklist is non-empty" "$LIST_NUM …"

req GET "$VORD/$LIST_NUM"
bail_if_internal_error
expect "GET /vendor/orders/{ordnum} → 200, the vendor's own row" 200 '"ordnum"'
check "the detail answers the number that was asked for" "$(ordnum_of)" "$LIST_NUM"
ETAG="$(etag_of)"
check "the detail emits an ETag (F8's version token)" \
      "$([ -n "$ETAG" ] && echo yes || echo no)" "yes"
info "ETag" "${ETAG:-<none>}"

req GET "$VORD/$ABSENT_ORDNUM"
expect ":F an absent ordnum → 404 not_found" 404 '"not_found"'
ABSENT_BODY="$(cat "$BODY")"

# AC (c) — THE SCOPE CHECK THAT MATTERS. A row of ANOTHER vendor IN THE SAME TENANT must be
# invisible. Tenant scoping alone would return it; only the VENDOR_ID predicate stops that.
if [ -z "$OTHER_VENDOR_ORDNUM" ]; then
  # ⚠ EXCLUDE NUMBERS THIS VENDOR ALSO HOLDS: D20 duplicates one ORDNUM into every vendor row of a
  # multi-vendor order, so a shared number resolves to the SESSION vendor's own row and answers 200.
  # Without this the check fails for a reason that is the API being RIGHT.
  OTHER_VENDOR_ORDNUM="$(sql "SELECT vo.ORDNUM FROM DOD_VENDOR_ORDERS vo JOIN DOD_VEND_PROFILE v ON v.ROW_ID=vo.VENDOR_ID
                              WHERE vo.VENDOR_ID=$OTHER_VENDOR AND v.TENANT_ID=(SELECT TENANT_ID FROM DOD_VEND_PROFILE WHERE ROW_ID=$VENDOR_ID)
                                AND vo.DELETED_STATE='N' AND vo.ORDNUM IS NOT NULL
                                AND NOT EXISTS (SELECT 1 FROM DOD_VENDOR_ORDERS mine
                                                 WHERE mine.ORDNUM=vo.ORDNUM AND mine.VENDOR_ID=$VENDOR_ID)
                              LIMIT 1")"
fi
info "another vendor's row, same tenant (vendor $OTHER_VENDOR)" "${OTHER_VENDOR_ORDNUM:-<none found>}"
if [ -z "$OTHER_VENDOR_ORDNUM" ]; then
  skip "AC (c) another vendor's row → 404" "no row of vendor $OTHER_VENDOR in this tenant could be resolved"
else
  req GET "$VORD/$OTHER_VENDOR_ORDNUM"
  expect ":F AC (c) ANOTHER VENDOR'S row in the SAME tenant → 404" 404 '"not_found"'
  check "it is INDISTINGUISHABLE from an absent one (no existence oracle)" \
        "$(printf '%s' "$(cat "$BODY")" | sed "s|$OTHER_VENDOR_ORDNUM|«ordnum»|g")" \
        "$(printf '%s' "$ABSENT_BODY" | sed "s|$ABSENT_ORDNUM|«ordnum»|g")"
fi

req GET "$VORD/$CROSS_TENANT_ORDNUM"
expect ":F another TENANT's row → 404" 404 '"not_found"'

# ── 4. the guards (shared with the customer channel, deliberately) ──────────
section "4. the guards — sort and page"
req GET "$VORD?sort-by=nonsense"
expect "?sort-by=<not whitelisted> → 400 invalid_request" 400 '"invalid_request"'
req GET "$VORD?sort-by=ordnum&sort-dir=sideways"
expect "?sort-dir=<not asc|desc> → 400" 400 '"invalid_request"'
req GET "$VORD?limit=500"
expect "?limit=500 → 200 — CAPPED, not refused" 200 '"ordnum"'
check "the capped page carries at most 200 rows" \
      "$([ "$(count_of)" -le 200 ] && echo yes || echo no)" "yes"

# ── 5. the write policy (V8) — refusals first, so they cost nothing ─────────
section "5. the write policy — terminal, and the fields the vendor may NOT write"

req PUT "$VORD/$ORDNUM_TERMINAL" -H 'Content-Type: application/json' -d '{"comments":"smoke"}'
if [ "$HTTP_CODE" = "404" ]; then
  skip "AC (g) PUT a terminal row → 409" "ORDNUM_TERMINAL not reachable by this vendor"
else
  expect ":C AC (g) PUT on a CMP row → 409 conflict (387 of 466 live rows are CMP)" 409 '"conflict"'
fi
req PUT "$VORD/$ORDNUM_VCN" -H 'Content-Type: application/json' -d '{"comments":"smoke"}'
if [ "$HTTP_CODE" = "404" ]; then
  skip "AC (g) PUT a VCN row → 409" "ORDNUM_VCN not reachable by this vendor"
else
  expect ":C AC (g) PUT on a VCN row → 409 conflict" 409 '"conflict"'
fi

# V8: money is NOT here (a vendor grading its own invoice), the addresses are NOT here (they are
# the customer's instruction). Each is refused rather than ignored.
req PUT "$VORD/$ORDNUM_OPEN" -H 'Content-Type: application/json' -d '{"orderAmt":1.00}'
if [ "$HTTP_CODE" = "404" ]; then skip "PUT :order-amt → refused" "no reachable open fixture"
else expect ":C PUT :order-amt → refused (V8: money is not the vendor's to write)" 409 '"conflict"'; fi

req PUT "$VORD/$ORDNUM_OPEN" -H 'Content-Type: application/json' -d '{"shipAddrFull":"elsewhere"}'
if [ "$HTTP_CODE" = "404" ]; then skip "PUT :ship-addr-full → refused" "no reachable open fixture"
else expect ":C PUT :ship-addr-full → refused (V8: the address is the customer's instruction)" 409 '"conflict"'; fi

req PUT "$VORD/$ORDNUM_OPEN" -H 'Content-Type: application/json' -d '{"status":"CMP"}'
if [ "$HTTP_CODE" = "404" ]; then skip "PUT :status → refused" "no reachable open fixture"
else expect ":C PUT :status → refused (V8: a fact, not a transition)" 409 '"conflict"'; fi

req PUT "$VORD/$ORDNUM_OPEN" -H 'Content-Type: application/json' -H 'If-Match: "not-a-validator"' \
    -d '{"comments":"smoke"}'
if [ "$HTTP_CODE" = "404" ]; then skip "PUT with a stale If-Match → 412" "no reachable open fixture"
else expect "PUT with a stale If-Match → 412 (never 409)" 412 '"precondition_failed"'; fi

req PUT "$VORD/$ABSENT_ORDNUM" -H 'Content-Type: application/json' -d '{"comments":"smoke"}'
expect ":F PUT an absent ordnum → 404" 404 '"not_found"'

# ── 6. AC (f) — ORD_DATE byte-identical, UPDATED advanced ──────────────────
section "6. AC (f) — the PUT that must not move ORD_DATE  (T9, vendor-only)"

if [ "$WRITE" != 1 ]; then
  skip "AC (f) a real PUT with the ORD_DATE assertion" "read-only run; pass --write to perform it"
else
  ROW_BEFORE="$(sql "SELECT CONCAT_WS('|', ORD_DATE, UPDATED, IF(COMMENTS IS NULL,'<<NULL>>',COMMENTS)) FROM DOD_VENDOR_ORDERS
                     WHERE ORDNUM='$ORDNUM_OPEN' AND VENDOR_ID=$VENDOR_ID")"
  if [ -z "$ROW_BEFORE" ]; then
    printf '  %sSETUP%s cannot read the row for %s (vendor %s) — AC (f) cannot be asserted.\n' \
           "$Y" "$N" "$ORDNUM_OPEN" "$VENDOR_ID"
    exit 2
  fi
  ORD_DATE_BEFORE="${ROW_BEFORE%%|*}"
  REST="${ROW_BEFORE#*|}"; UPDATED_BEFORE="${REST%%|*}"; COMMENTS_BEFORE="${REST#*|}"
  CHANGED_ORDNUM="$ORDNUM_OPEN"
  info "ORD_DATE before" "$ORD_DATE_BEFORE"
  info "UPDATED before"  "$UPDATED_BEFORE"

  NEW_COMMENT="smoke $(date +%Y-%m-%dT%H:%M:%S)"
  req PUT "$VORD/$ORDNUM_OPEN" -H 'Content-Type: application/json' \
      -d "{\"comments\":\"$NEW_COMMENT\"}"
  bail_if_internal_error
  if [ "$HTTP_CODE" != "200" ]; then
    FAIL=$((FAIL+1))
    printf '  %sFAIL%s %-54s got %s, want 200\n' "$R" "$N" "PUT a writable field (V8: :comments)" "$HTTP_CODE"
    printf '       body: %s\n' "$(head -c 400 "$BODY" | tr -d '\n')"
  else
    PASS=$((PASS+1)); printf '  %sPASS%s %-54s 200\n' "$G" "$N" "PUT a writable field (V8: :comments)"

    ROW_AFTER="$(sql "SELECT CONCAT_WS('|', ORD_DATE, UPDATED, IF(COMMENTS IS NULL,'<<NULL>>',COMMENTS)) FROM DOD_VENDOR_ORDERS
                      WHERE ORDNUM='$ORDNUM_OPEN' AND VENDOR_ID=$VENDOR_ID")"
    ORD_DATE_AFTER="${ROW_AFTER%%|*}"
    REST2="${ROW_AFTER#*|}"; UPDATED_AFTER="${REST2%%|*}"; COMMENTS_AFTER="${REST2#*|}"
    info "ORD_DATE after" "$ORD_DATE_AFTER"
    info "UPDATED after"  "$UPDATED_AFTER"

    # THE ASSERTION, and it is BYTE-IDENTITY, not "close enough". A clsql:date read drops the
    # time of day, so a wrong declaration moves the row to MIDNIGHT — which a "did it change?"
    # test would call a change, and a "is it still today?" test would miss entirely.
    check "AC (f) ORD_DATE is BYTE-IDENTICAL" \
          "$([ "$ORD_DATE_AFTER" = "$ORD_DATE_BEFORE" ] && echo identical || echo "MOVED: $ORD_DATE_BEFORE → $ORD_DATE_AFTER")" \
          "identical"
    check_known "AC (f) UPDATED has ADVANCED (the write did happen)" \
          "$([ "$UPDATED_AFTER" \> "$UPDATED_BEFORE" ] && echo advanced || echo "NOT advanced ($UPDATED_BEFORE → $UPDATED_AFTER)")" \
          "advanced" \
          "KNOWN DEFECT (measured 2026-10-04): UPDATED is FROZEN by the write itself — the class
        declares (updated :column \"UPDATED\") and update-records-from-instance assigns it
        explicitly, so ON UPDATE never fires. F8's ETag therefore never changes and If-Match
        cannot detect a concurrent write. See the boxed note in this file's header."
    check "the field the PUT set actually changed" \
          "$([ "$COMMENTS_AFTER" = "$NEW_COMMENT" ] && echo yes || echo "no ($COMMENTS_AFTER)")" "yes"

    if [ "$ORD_DATE_AFTER" != "$ORD_DATE_BEFORE" ]; then
      printf '\n  %sT9 IS LIVE%s ORD_DATE moved on an ordinary vendor PUT. The column is a timestamp\n' "$R" "$N"
      printf '        with ON UPDATE CURRENT_TIMESTAMP; the write must carry the value it READ, in the\n'
      printf '        same statement, and ord-date must stay in *vordh-mirrored-slots*. The suite leaves\n'
      printf '        the row as it is: rewriting the column by hand would destroy this evidence.\n'
    fi
  fi
fi

# ── 7. AC (e) — a NULL ORDNUM answers 404, never a guess ───────────────────
section "7. AC (e) — a vendor row whose ORDNUM is NULL"

NULL_FIXTURE="$(sql "SELECT COUNT(*) FROM DOD_VENDOR_ORDERS WHERE ORDNUM IS NULL")"
info "live rows with a NULL ORDNUM" "$NULL_FIXTURE (the backfill numbered all 466)"
if [ "$WRITE" != 1 ]; then
  skip "AC (e) a NULL-ORDNUM row → 404" "no live fixture; --write manufactures one and restores it"
else
  # MANUFACTURED, because the data has none left. The row is a DIFFERENT one from AC (f)'s
  # ($NULL_ROW_ID, default 465 = ORD-DEMO-2026-27-LPU692), because nulling the row AC (f) just
  # wrote would make the cleanup's own lookup by ORDNUM fail. The failure mode of a bad restore
  # here is a vendor row that stays permanently unaddressable, so the restore is VERIFIED.
  NULL_SAVED="$(sql "SELECT CONCAT_WS('|', ORDNUM, VENDOR_ID) FROM DOD_VENDOR_ORDERS WHERE ROW_ID=$NULL_ROW_ID")"
  NULL_NUM="${NULL_SAVED%%|*}"
  if [ -z "$NULL_NUM" ] || [ "${NULL_SAVED#*|}" != "$VENDOR_ID" ]; then
    printf '  %sSETUP%s row %s is not a readable row of vendor %s — AC (e) not asserted.\n' \
           "$Y" "$N" "$NULL_ROW_ID" "$VENDOR_ID"
  else
    mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" "$NS_DB" -e \
      "UPDATE DOD_VENDOR_ORDERS SET ORDNUM=NULL, ORD_DATE=ORD_DATE WHERE ROW_ID=$NULL_ROW_ID;" 2>/dev/null
    req GET "$VORD/$NULL_NUM"
    expect ":F AC (e) a row whose ORDNUM is NULL + the number it used to have → 404" 404 '"not_found"'
    mysql -u "$NS_MYSQL_USER" -p"$NS_MYSQL_PASS" "$NS_DB" -e \
      "UPDATE DOD_VENDOR_ORDERS SET ORDNUM='$NULL_NUM', ORD_DATE=ORD_DATE WHERE ROW_ID=$NULL_ROW_ID;" 2>/dev/null
    check "the fixture row's ORDNUM was restored" \
          "$(sql "SELECT ORDNUM FROM DOD_VENDOR_ORDERS WHERE ROW_ID=$NULL_ROW_ID")" "$NULL_NUM"
  fi
fi

# ── 8. the optional two-session variant of AC (c) ──────────────────────────
section "8. the optional second vendor (AC (c), two sessions)"
if [ -z "${NS_VPHONE2:-}" ] || [ -z "${NS_VPASSWORD2:-}" ]; then
  skip "AC (c) via a SECOND vendor login" "set NS_VPHONE2/NS_VPASSWORD2 to run it (the primary form is §3, one session)"
else
  printf '  note: the tree caps CONCURRENT vendor logins at 2 and evicts the OLDEST, so the\n'
  printf '        first session may already be dead — which is why §3 proves the same property.\n'
  JAR2="$TMP/cookies2.txt"
  curl -sS -o /dev/null -c "$JAR2" --max-time 20 -X POST "$BASE/hhub/dodvendlogin" \
       -d "phone=$NS_VPHONE2" -d "password=$NS_VPASSWORD2" 2>"$ERR"
  if ! grep -q 'hunchentoot-session' "$JAR2"; then
    skip "AC (c) via a second vendor login" "the second vendor's login was rejected"
  else
    HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -b "$JAR2" -c "$JAR2" --max-time 20 \
                      "$BASE$VORD/$ORDNUM_OPEN" 2>"$ERR")"
    expect ":F vendor 2 cannot see vendor 1's row (AC c)" 404 '"not_found"'
  fi
fi

# ── 9. the design gap this suite records and does NOT test ────────────────
section "9. recorded, not asserted"
printf '  ---- the vendor cannot reach its own LINES. GET /vendor/orders/{ordnum} carries no nested\n'
printf '       items, and nst-orditm'"'"'s enumerate has no :vendor-id — so the ITEMS a vendor must ship\n'
printf '       are reachable only through the CUSTOMER channel, which lists the whole order including\n'
printf '       other vendors'"'"' lines. A per-item fulfilment surface is a design decision for the\n'
printf '       vendor channel, not a defect of these routes. Nothing above tests it either way.\n'

printf '\n== summary\n'
printf '  PASS %s   FAIL %s   KNOWN %s   SKIP %s\n' "$PASS" "$FAIL" "$KNOWN" "$SKIP"
printf '  KNOWN items are documented gaps, not passes: the list is in the header of this file.\n'
if [ "$FAIL" -gt 0 ]; then printf '  %sFAILED%s\n' "$R" "$N"; exit 1; fi
exit 0
