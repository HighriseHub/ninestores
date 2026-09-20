# STATUS.md — nstores architecture migration

**Read this first, every session. Budget: 9,000 chars — currently at the ceiling.**

A **checklist**, not a history — depth lives in the CONTEXT files at the bottom, read
**on demand**. Every factual line carries a `verify:`; no command ⇒ it does not belong
here. When a fact changes, **edit the line**, do not append.

**Working protocol** (process — no `verify:`): write code and hand it over; no harnesses,
no stub rigs; `compile-file` for syntax; the owner reports compile failures.

---

## Refresh — paste this to re-prove the whole file in one go

```bash
cd /home/ubuntu/ninestores
C=/home/hunchentoot/.cache/common-lisp/sbcl-2.6.8-linux-x64/home/ubuntu/ninestores/hhub
echo "unpushed:      $(git log --oneline @{u}..HEAD | wc -l)"
for f in nst-dal-vnd nst-bl-vnd nst-dal-vndshp nst-bl-vndshp nst-bl-vndshpapi; do
  t=$(stat -c '%y' $C/vendor/$f.fasl 2>/dev/null | cut -d. -f1)
  printf "image %-20s %s\n" "$f" "${t:-*** MISSING ***}"
done
echo "STATUS.md: $(stat -c%s hhub/STATUS.md) chars  [budget 9000 — if over, CUT]"
for f in shipping/dod-bl-osh vendor/dod-ui-ven core/dod-ui-utl; do
  printf "%-22s read-eval: %-3s reader: %-3s safe-read CALLERS: %s\n" "$f" \
    "$(grep -c 'read-eval' hhub/$f.lisp)" "$(grep -c 'read-from-string' hhub/$f.lisp)" \
    "$(grep -rn 'safe-read-from-string' --include=*.lisp hhub/ | grep -vc 'defun safe-read')"
done
# Credentials come from their one home, hhub/core/dod-ini-sys.lisp — never copied here.
DBPASS=$(grep -oP "(?<=crm-database-password\* \")[^\"]+" hhub/core/dod-ini-sys.lisp)
mysql -h localhost -u hhubuser -p"$DBPASS" hhubdb -N -B -e \
  "SELECT CONCAT('shipping rows: ', COUNT(*)) FROM DOD_SHIPPING_METHODS;" 2>/dev/null
```

---

## State as of 2026-09-16

| | |
|---|---|
| **Uncommitted** | the whole shipping slice · `verify: git status --short hhub/vendor` |
| **Vendor PROFILE API** | live: 5 verbs → 5 routes → 5 bindings |
| **PAYMENT API** (vpm) | built: 3 verbs → 3 routes → 3 bindings |
| **SHIPPING API** (vndshp) | built: 5 verbs → 6 routes → 6 bindings, TWO tables · `verify: grep -c register-api-route hhub/vendor/nst-bl-vndshpapi.lisp` |
| **Smoke suites** | warehouse, products, vendor payment, **shipping** · `verify: ls hhub/test/smoke-*` |
| **Any vendor verb called?** | **YES — 2026-09-16.** See below. |

**What the runs prove.** PROVEN live: the read path, the create (201, zones stored), both
upload routes, all six law refusals, and — after S3's fix — `!update` of a money field
(`99` → `FLATRATEPRICE 99.00`). Pending: one full green `--write` after the last edits.
**Compilation is not evidence** — neither is a green read-only suite.

---

## Verified (actually exercised, not reasoned)

| Claim | verify |
|---|---|
| nst-vnd-shp READS live: 14 keys, both secrets + all 5 कारक fields withheld, zones with prefixes/regions | suite §2 |
| The PIN-prefix table reaches the wire: ZONE-A → `KA` | suite §2 |
| Singleton → 2nd create 409; referential → absent vendor 404 (no FK) | suite §5 |
| Belnap `:F` five triggers incl. cross-tenant BOLA; empty list is 200 | suite §3 |
| Live zone rows hold REGEX FRAGMENTS (`577*`) and EMPTY lists (`()`) | `SELECT ZIPCODERANGECSV FROM DOD_VENDOR_SHIP_ZONES WHERE VENDOR_ID=19` |

## 🚨 BLOCKER 1 — the `read-from-string` sweep is INCOMPLETE

`*read-eval*` defaults to `T`, so `#.` in a text column **executes**. One site of five is
fixed — and `nst-vnd-shp` now WRITES the one at `dod-bl-osh.lisp:74-80`.

| Site | Data | verify |
|---|---|---|
| `dod-bl-osh.lisp:137` | `zipcoderangecsv` | ✅ FIXED `5ba1f70` |
| `dod-bl-osh.lisp:74-80` (7 calls) | `RATETABLECSV` ← **shipping writes this** | ❌ OPEN |
| `dod-ui-ven.lisp:2429` (at login) | `invoice-settings` | ❌ OPEN |
| `dod-ui-ven.lisp:2457` | session copy | ❌ OPEN |
| `dod-ui-utl.lisp:113` (18 callers) | image columns | ❌ OPEN |

`safe-read-from-string` IS NOT SAFE — it catches *parse errors*, never binds `*read-eval*`:
`(safe-read-from-string "#.(+ 40 2)") => 42`. Binding `*read-eval* nil` inside it fixes 18
callers in one edit. **Do NOT replace the reader with a splitter** — the values are regex
fragments; a splitter silently changes which zones match.

## 🚨 Five defects the live runs found (2026-09-16)

**S1 · Nested JSON objects are ALISTS, not plists — the create answered 500.** apidefs2
plist-ifies the TOP-LEVEL object but leaves NESTED ones as the decoded alist, so
`[{"zoneName":"ZONE-A"}]` arrives as `((:ZONE-NAME . "ZONE-A") …)`. The zone parser knew
only plists/conses, stored a zone NAMED `"(ZONE-NAME . ZONE-A)"`, and L2 refused it.
**FIXED.** ⚠ Any entity taking a JSON array of objects has the same exposure; none does.

**S2 · The platform's master shipping files fail our own laws.** `defaultshipratetable.csv`
has an EMPTY `ZONE-C` cell on all 16 rows and 6 cells under a 7-column header — an empty
cell makes the checkout call `float("")` and THROW — and `defaultshipzonepincodes.csv` ships
`ZONE-E,` with no prefixes. **FIXED IN CODE**: the seed is adopted only if it passes the
laws, else the config is created EMPTY, reason logged.

**S3 · A decimal price could not be sent, and the client was told the DB was down.** CLSQL
enforces the view-class's `:type float`: `PUT {"flatrateprice":99}` raised *"Invalid value 99
in slot FLATRATEPRICE"*, the catch-all made it `:U`, and the API answered **503 "the database
call did not answer"** — for a price. **FIXED + VERIFIED** in the copier (`vndshp-float-or-nil`).

**K1 (OPEN) · camelCase fields are dropped on the ferry legs.** `"rateTableCsv"` →
`:RATE-TABLE-CSV` but the entity declares `:RATETABLECSV`, so `extract-domain-initargs`
silently drops **11 of 17 fields** on POST and the shared PUT: 200, nothing changed. The
two upload routes are immune (they read the payload themselves).

**K4 (OPEN, TREE-WIDE) · An OFF flag publishes as `null`, not `false`.** cl-json maps BOTH
`"null"` and `"false"` to NIL and `rassoc` takes the FIRST (common.lisp:75), so with the
guessing encoder — what conflodis2 calls — NIL can ONLY be written `null`. Every entity
publishing flags via `*-flag->boolean` has this: products, profile, payment, shipping. A
client cannot tell "off" from "unknown" and cannot round-trip it. Fixing it means changing
shared core or publishing raw "Y"/"N" — the decision CONTEXT §11.4 already flags.

**K3 (OPEN) · A malformed filter is reported as a DATABASE OUTAGE.** `?sort-by=nonsense`,
`?method=nonsense`, `?status=suspended`, `?offset` without `?limit` → **503**
`{"error":"unknown","reason":"…the database call did not answer…"}`. The DB is fine; the
filter is bad. The refusals are raised INSIDE `with-nst-db-read-all`, whose catch-all turns
any error into `:U` — so **the 4xx taxonomy fix will NOT fix these**. Not shipping-only:
`validate-sort-args` (warehouse) and `enumerate` (profile) share the shape.

---

## Next steps, in order

1. **`(asdf:load-system :nstores)`** — S1/S2's fixes are on disk, NOT in the running image.
   Then re-run `smoke-vendor-shipping-api.sh --write`: it is the only thing that proves the
   write path, and it must be re-run after every fix below.
2. **K1** — re-declare `nst-vnd-shp`'s initargs in the hyphenated spelling the response
   publishes; slot names and accessors stay as they are.
3. **S3** — validate query args before `with-nst-db-read-all`, in every enumerate.
4. **BLOCKER 1** — the one-line `safe-read-from-string` fix, then the three direct sites.
5. **Clean up the `--write` fixture** — it now leaves a row for vendor 2 (`NS_FREE_VENDOR`);
   the SQL is in the suite's cleanup block.
6. **Then** the 4xx taxonomy (everything above answers 500 or 503 where 400 is right), and
   **the vendor on `domain-ctx`'s `actor`** — read nowhere today, so it is free, and without
   it vendor X can read or write vendor Y's config INSIDE one tenant.

## Where the depth lives — read on demand only

**Paths relative to the repository root; code under `hhub/`.**

| File | In git? | For |
|---|---|---|
| `vendor/nst-bl-vndapi-CONTEXT.md` | ✅ | the vendor API: decisions, schema, §11 render-json, §12 the shipping design |
| `vendor/nst-dal-vndshp.lisp`, `nst-bl-vndshp.lisp`, `nst-bl-vndshpapi.lisp` | ✅ | **S1/S2/K1, the L1–L5 laws, the UI→API map — in their headers** |
| `test/smoke-vendor-shipping-api.sh` | ✅ | the shipping suite; KNOWN list + fixtures in its header |
| `aiharness/deepseek/skills/nst-bl-prdapi-CONTEXT.md`, `…/nst-bl-apidefs2-CONTEXT.md` | ✅ | reference impl + Belnap findings; Ring-4 |
| `aiharness/deepseek/skills/knowledge/nst-bl-conflodis2-DESIGN.md` | ⚠️ untracked | Tier-2/3 — the conflodis2 design authority |
| `core/nst-bl-adhara.lisp` | ✅ | sentinels, the converters, the प्रत्यय contracts |

**⚠️ THE CONTEXT FILES NOW LIVE OUTSIDE `hhub/`**, under `aiharness/deepseek/skills/`, because
they are agent context rather than shipped code. They were previously untracked **and** mode
600 — a `chmod` was needed even on this machine — and are now mode 664 in `hhubgrp`, readable
by both accounts. `nst-bl-conflodis2-DESIGN.md` is the remaining untracked one.
· `verify: git ls-files --error-unmatch <path>`
