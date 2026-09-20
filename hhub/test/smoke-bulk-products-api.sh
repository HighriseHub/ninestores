#!/usr/bin/env bash
#
# smoke-bulk-products-api.sh — smoke-test the BULK products.csv endpoints.
#
#   NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-bulk-products-api.sh
#
# Sibling of smoke-products-api.sh, kept SEPARATE on purpose: bulk upload has its
# own two endpoints (/catalog/products/template and /catalog/products/bulk), its
# own transport (multipart rather than JSON), and its own subscription rules. One
# script failing should not make the other unreadable.
#
# ── THE TWO ENDPOINTS, ONE CONTRACT ─────────────────────────────────────────
#   GET  /hhub/api/v1/catalog/products/template   text/csv, the file to fill in
#   POST /hhub/api/v1/catalog/products/bulk       upsert from that same file
#
# ── WHY THIS SCRIPT ROUND-TRIPS THE DOWNLOAD INSTEAD OF BUILDING A CSV ──────
# Every row carries an MD5Digest in column 10, computed over columns 0-9 with
# exact formatting — qty to 1 decimal, money to 2 (normalize-md5-fields,
# dod-ui-ven.lisp). A test that hand-writes a CSV must reproduce that formatting
# byte-for-byte in shell, and when it gets it wrong the failure looks like a bug in
# the endpoint. So this script DOWNLOADS the template and posts it back: the digests
# are correct by construction because the server produced them. The tamper test then
# changes ONE field and leaves the digest alone, which is exactly the mistake a human
# editing the file would make.
#
# ── WHAT THIS DOES TO LIVE DATA ─────────────────────────────────────────────
# It creates a real product (so the template has a row to carry), uploads, and
# soft-deletes it at the end. Run it against a real vendor account you can afford to
# write as. Exit codes are the same as the products script: 0 pass, 1 a mismatch,
# 2 setup failure.

set -uo pipefail

BASE="${BASE:-http://hunchentoot.local}"
PHONE="${NS_PHONE:-}"
PASSWORD="${NS_PASSWORD:-}"

if [ -z "$PHONE" ] || [ -z "$PASSWORD" ]; then
  echo "ERROR: set NS_PHONE and NS_PASSWORD (vendor credentials)." >&2
  exit 2
fi

TMP="$(mktemp -d)" || exit 2
trap 'rm -rf "$TMP"' EXIT
JAR="$TMP/cookies.txt"; BODY="$TMP/body"; ERR="$TMP/curl.err"
CSV="$TMP/products.csv"; EDITED="$TMP/edited.csv"; NEWROW="$TMP/newrow.csv"; BIG="$TMP/big.csv"

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; N=$'\033[0m'; else G=; R=; Y=; N=; fi
PASS=0; FAIL=0; HTTP_CODE=""

req() {                       # req METHOD PATH [extra curl args...]
  local method="$1"; shift; local path="$1"; shift
  HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' -X "$method" \
                    -b "$JAR" -c "$JAR" "$@" "$BASE$path" 2>"$ERR")" || HTTP_CODE="000"
  [ -n "$HTTP_CODE" ] || HTTP_CODE="000"
}

expect() {                    # expect NAME STATUS [SUBSTRING]
  local name="$1" want="$2" needle="${3:-}" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  if [ -n "$needle" ] && ! grep -qF -- "$needle" "$BODY"; then ok=0; fi
  if [ "$ok" = 1 ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-52s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else FAIL=$((FAIL+1)); printf '  %sFAIL%s %-52s got %s, want %s%s\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" "${needle:+, containing \"$needle\"}"
       printf '       body: %s\n' "$(head -c 240 "$BODY" | tr -d '\n')"; fi
}

expect_re() {                 # expect_re NAME STATUS REGEX  (JSON needs whitespace tolerance)
  local name="$1" want="$2" re="$3" ok=1
  [ "$HTTP_CODE" = "$want" ] || ok=0
  grep -qE -- "$re" "$BODY" || ok=0
  if [ "$ok" = 1 ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-52s %s\n' "$G" "$N" "$name" "$HTTP_CODE"
  else FAIL=$((FAIL+1)); printf '  %sFAIL%s %-52s got %s, want %s matching /%s/\n' "$R" "$N" "$name" "$HTTP_CODE" "$want" "$re"
       printf '       body: %s\n' "$(head -c 240 "$BODY" | tr -d '\n')"; fi
}

# json_number KEY — the value of "key":<number> in $BODY, or empty.
json_number() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\([0-9]\+\).*/\1/p" "$BODY" | head -1; }

info() { printf '  %s----%s %-52s %s\n' "$Y" "$N" "$1" "$2"; }
section() { printf '\n== %s\n' "$1"; }

# ── 1. session ──────────────────────────────────────────────────────────────
section "1. session"
curl -sS -o "$TMP/login.html" -c "$JAR" --max-time 15 -X POST "$BASE/hhub/dodvendlogin" \
     -d "phone=$PHONE" -d "password=$PASSWORD" >/dev/null 2>"$ERR"
if ! grep -q 'hunchentoot-session' "$JAR"; then
  printf '  %sFATAL%s login rejected (a 302 is returned for BOTH outcomes).\n' "$R" "$N"; exit 2
fi
req GET "/hhub/api/v1/catalog/products?limit=1"
case "$HTTP_CODE" in
  401) printf '  %sFATAL%s login did not establish a vendor session.\n' "$R" "$N"; exit 2 ;;
  000) printf '  %sFATAL%s cannot reach the API.\n' "$R" "$N"; exit 2 ;;
  404) printf '  %sFATAL%s the products routes are not registered in this image.\n' "$R" "$N"; exit 2 ;;
esac
printf '  session established (%s)\n' "$HTTP_CODE"

# A GUARD WORTH ITS LINES. On the first run of this script every bulk assertion
# below failed with 404, because the running image was ten hours older than the
# routes: the image was built at 10:34 and the source edited at 20:33. Without this
# check that reads as twelve endpoint bugs rather than one stale image.
req POST "/hhub/api/v1/catalog/products/bulk" -H 'Content-Type: application/json' -d '{}'
if grep -qF '"no_such_endpoint"' "$BODY"; then
  printf '\n  %sFATAL%s the bulk routes are NOT REGISTERED in the running image.\n' "$R" "$N"
  printf '        /catalog/products/bulk answered 404 no_such_endpoint. In the Lisp image:\n\n'
  printf '            (asdf:load-system :nstores)     ; recompile, then RELOAD\n'
  printf '            (list-api-routes)               ; expect the template + bulk rows\n\n'
  printf '        Nothing below would be meaningful until then.\n'
  exit 2
fi

# ── 2. create a product so the template has a row to carry ──────────────────
section "2. fixture — a real product for the template to include"
STAMP="$(date +%H%M%S)"
FIXNAME="BULK Smoke $STAMP"       # referenced by the awk edit in section 6
req POST "/hhub/api/v1/catalog/products" -H 'Content-Type: application/json' \
    -d "{\"prd-name\":\"$FIXNAME\",\"hsn-code\":\"8517\",\"current-price\":123.45}"
expect "POST create fixture product" 201 "\"rowId\""
RID="$(sed -n 's/.*"rowId":"\([0-9]*\)".*/\1/p' "$BODY" | head -1)"
if [ -z "$RID" ]; then printf '  %sFATAL%s no rowId — cannot continue.\n' "$R" "$N"; exit 2; fi
info "fixture rowId" "$RID"

# ── 3. the template download ────────────────────────────────────────────────
section "3. GET /catalog/products/template"
HTTP_CODE="$(curl -sS -o "$CSV" -w '%{http_code}' -b "$JAR" -c "$JAR" \
                  "$BASE/hhub/api/v1/catalog/products/template" 2>"$ERR")" || HTTP_CODE="000"
if [ "$HTTP_CODE" = "200" ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-52s %s\n' "$G" "$N" "GET template" "$HTTP_CODE"
else FAIL=$((FAIL+1)); printf '  %sFAIL%s %-52s got %s, want 200\n' "$R" "$N" "GET template" "$HTTP_CODE"; fi

# A CASCADE GUARD. Sections 4 to 6 upload the file THIS section downloads, so a failed
# download leaves them with nothing to send -- and the first run showed how misleading
# that looks: they reported 'products.csv could not be parsed as CSV ... "{error"'
# because the "CSV" they posted was this endpoint's own error JSON. ONE broken download
# read as six endpoint failures. Stop here instead, with the code and where to look.
if [ "$HTTP_CODE" != "200" ]; then
  printf '\n  %sFATAL%s the template download failed (HTTP %s).\n' "$R" "$N" "$HTTP_CODE"
  printf '        Sections 4-6 upload the file this section produces, so they cannot run.\n'
  printf '        body: %s\n' "$(head -c 200 "$CSV" | tr -d '\n')"
  printf '        Server side: tail -30 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
  exit 2
fi

# THE COLUMN CONTRACT, checked rather than assumed. Order is positional in the
# parser, so a moved column is silent corruption rather than a parse error.
# printf, not `head >` : the header line of a CSV whose last row has no trailing
# newline would otherwise be concatenated with the first generated row, silently
# producing 100 rows where 101 were intended -- which is exactly the boundary this
# section exists to test.
# tr -d '\r' because the generator writes CRLF (#\return #\linefeed), so head -1 of a
# correct file ends in a carriage return and an exact comparison fails on a header that
# is byte-identical apart from it -- which is exactly how this assertion failed first.
printf '%s\n' "$(head -1 "$CSV" | tr -d '\r')" > "$TMP/hdr"
if [ "$(cat "$TMP/hdr")" = "ProductID,ProductName,QtyPerUnit,UnitOfMeasure,UnitPrice,Discount,DiscountStart,DiscountEnd,UnitsInStock,SubscriptionFlag,MD5Digest" ]; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-52s\n' "$G" "$N" "  ↳ header is the 11-column contract, in order"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-52s\n       got: %s\n' "$R" "$N" "  ↳ header is the 11-column contract, in order" "$(head -c 200 "$TMP/hdr")"
fi

if grep -qF "BULK Smoke $STAMP" "$CSV"; then
  PASS=$((PASS+1)); printf '  %sPASS%s %-52s\n' "$G" "$N" "  ↳ the fixture product is in the file"
else
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-52s\n' "$R" "$N" "  ↳ the fixture product is in the file"
fi
info "rows in template" "$(( $(wc -l < "$CSV") - 1 ))"
info "content-type" "$(curl -sS -o /dev/null -D - -b "$JAR" "$BASE/hhub/api/v1/catalog/products/template" 2>/dev/null | grep -i '^content-type' | tr -d '\r')"

# ── 4. round-trip: post the downloaded file back unchanged ──────────────────
section "4. POST /catalog/products/bulk — the downloaded file, unchanged"
req POST "/hhub/api/v1/catalog/products/bulk" -F "file=@$CSV"
expect "POST bulk (multipart, unchanged file)" 200 "\"rows\""
# THE ROUND TRIP IS THE ASSERTION THAT MATTERS: every digest was produced by the
# server, so a non-zero skipped count means the download and the upload disagree
# about the field formatting — the silent failure this whole pair exists to avoid.
# 🚨 THIS ASSERTION LOOKS WRONG AND IS RIGHT. Every digest in the downloaded file was
# computed by the server over that row's own fields, so every row MATCHES -- and a
# MATCHING digest means 'unchanged, skip it'. The digest is a has-this-row-been-
# touched flag, not a validity check; see the header. So the correct expectation for
# an unedited file is that NOTHING applies.
expect_re "  ↳ nothing applied (all rows unchanged)" 200 '"applied"[[:space:]]*:[[:space:]]*0'
info "report" "$(head -c 200 "$BODY" | tr -d '\n')"

# ── 5. the same file as a RAW body, not multipart ───────────────────────────
section "5. the same POST as text/csv (the other transport)"
req POST "/hhub/api/v1/catalog/products/bulk" \
    -H 'Content-Type: text/csv' --data-binary "@$CSV"
expect "POST bulk (text/csv body)" 200 "\"rows\""
expect_re "  ↳ same answer from the other transport" 200 '"applied"[[:space:]]*:[[:space:]]*0'

# ── 6. 🚨 THE POINT OF THE WHOLE FEATURE: edit a row and have it APPLY ──────
section "6. edit the fixture's price, leave the digest stale, upload it back"
# Leaving the digest alone is exactly what a human does in a spreadsheet, and the
# now-mismatched digest is the signal that says 'this row changed'.
awk -v n="$FIXNAME" 'NR==1{print; next} $2==n {$5="777.77"; print; next} {print}' "$CSV" > "$EDITED"
if cmp -s "$CSV" "$EDITED"; then
  FAIL=$((FAIL+1)); printf '  %sFAIL%s %-52s the edit did not reach the file\n' "$R" "$N" "  ↳ the row was actually edited"
else
  PASS=$((PASS+1)); printf '  %sPASS%s %-52s\n' "$G" "$N" "  ↳ the row was actually edited"
fi
req POST "/hhub/api/v1/catalog/products/bulk" -F "file=@$EDITED"
expect "POST bulk (edited row)" 200 "\"rows\""
APPLIED="$(json_number applied)"
check "  ↳ the edited row IS applied" "applied=${APPLIED:-none} (want >= 1)" \
      "$([ -n "$APPLIED" ] && [ "$APPLIED" -ge 1 ] && echo 1 || echo 0)"

# AND THE CHANGE MUST BE REAL, not merely counted. This proves the workflow end to
# end: download, edit, upload, and the product actually moved.
req GET "/hhub/api/v1/catalog/products/$RID"
check "  ↳ the product's price is now 777.77" "$(grep -oF '777.77' "$BODY" | head -1)" \
      "$(grep -qF '777.77' "$BODY" && echo 1 || echo 0)"

# ── 6b. a NEW row: blank ProductID, blank digest ────────────────────────────
section "6b. a new product — blank ProductID and blank digest"
NEWNAME="BULK New $STAMP"
{ printf '%s\n' "$HDR"
  printf ',%s,1.0,NOS,55.00,0.00,01/01/2026,31/12/2026,7,N,\n' "$NEWNAME"
} > "$NEWROW"
req POST "/hhub/api/v1/catalog/products/bulk" -F "file=@$NEWROW"
expect "POST bulk (one new row)" 200 "\"rows\""
expect_re "  ↳ it is CREATED" 200 '"created"[[:space:]]*:[[:space:]]*1'
expect_re "  ↳ and it is not skipped" 200 '"skipped"[[:space:]]*:[[:space:]]*0'

# ── 7. the subscription cap ─────────────────────────────────────────────────
section "7. the 100-row ceiling"
# com-hhub-attribute-vendor-bulk-product-count = 100. The cap is checked against
# the RAW row count, so an over-long file is refused even though these rows would
# all be skipped for bad digests — the vendor's intent was 101 products.
{ cat "$TMP/hdr"; for i in $(seq 1 101); do printf '%s,BulkCapRow%s,1.0,NOS,1.00,0.00,01/01/2026,31/12/2026,1,N,deadbeef\n' "" "$i"; done; } > "$BIG"
info "rows in the over-long file" "$(( $(wc -l < "$BIG") - 1 ))"
req POST "/hhub/api/v1/catalog/products/bulk" -F "file=@$BIG"
expect "POST bulk over the ceiling → 400" 400

# ── 8. transports that carry nothing ────────────────────────────────────────
section "8. no file at all"
req POST "/hhub/api/v1/catalog/products/bulk" -H 'Content-Type: application/json' -d '{}'
info "POST bulk with no CSV" "$HTTP_CODE  (400 expected: 'no products.csv supplied')"
if [ "$HTTP_CODE" = "400" ]; then PASS=$((PASS+1)); printf '  %sPASS%s %-52s 400\n' "$G" "$N" "POST bulk with no CSV → 400"
else FAIL=$((FAIL+1)); printf '  %sFAIL%s %-52s got %s, want 400\n' "$R" "$N" "POST bulk with no CSV → 400" "$HTTP_CODE"; fi

# ── 9. cleanup ──────────────────────────────────────────────────────────────
section "9. cleanup"
req GET "/hhub/api/v1/catalog/products?name-like=$NEWNAME&limit=2"
NEWID="$(sed -n 's/.*"rowId":"\([0-9]*\)".*/\1/p' "$BODY" | head -1)"
if [ -n "$NEWID" ]; then
  req DELETE "/hhub/api/v1/catalog/products/$NEWID"
  info "deleted the bulk-created product" "$NEWID ($HTTP_CODE)"
else
  info "bulk-created product" "not found by name — check manually"
fi
req DELETE "/hhub/api/v1/catalog/products/$RID"
expect "DELETE the fixture product" 200 "\"ok\""
printf '  the fixture row stays SOFT-DELETED and its product-code stays reserved.\n'

printf '\n─────────────────────────────────────────────\n'
printf 'passed %s   failed %s\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf '\nNothing here is 5xx-tolerant: the bulk endpoints have never run before, so a\n'
  printf 'failure is more likely to be the endpoint than the assertion. Log:\n'
  printf '  tail -40 /home/hunchentoot/hhublogs/ninestores-apilogs.log\n'
  exit 1
fi
printf 'all expectations matched\n'
exit 0
