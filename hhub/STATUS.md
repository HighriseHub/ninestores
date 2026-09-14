# STATUS.md — nstores architecture migration

**Read this first, every session. Budget: ~2k tokens — it is currently ~1.7k (7,000 chars).**

This is a **checklist**, not a history. Deep rationale lives in the CONTEXT files at the
bottom and is read **on demand**. If this file starts growing like them, it has failed —
one CONTEXT file is ~10k tokens, so this must stay a fraction of that.

**Discipline:** every factual line carries a `verify:` command. No command ⇒ the claim
does not belong here. When a fact changes, **edit the line** — do not append a new one.

---

## Refresh — paste this to re-prove the whole file in one go

```bash
cd /home/ubuntu/ninestores
C=/home/hunchentoot/.cache/common-lisp/sbcl-2.6.8-linux-x64/home/ubuntu/ninestores/hhub
echo "unpushed:      $(git log --oneline @{u}..HEAD | wc -l)"
for f in nst-dal-vnd nst-bl-vnd nst-bl-vndapi; do
  t=$(stat -c '%y' $C/vendor/$f.fasl 2>/dev/null | cut -d. -f1)
  printf "image %-14s %s\n" "$f" "${t:-*** MISSING ***}"
done
t=$(stat -c '%y' $C/warehouse/nst-bl-warehouse.fasl 2>/dev/null | cut -d. -f1)
printf "image %-14s %s\n" warehouse "${t:-*** MISSING ***}"
echo  "STATUS.md size:  $(stat -c%s hhub/STATUS.md) chars   [budget 9000 — if over, CUT, do not append]"
for f in shipping/dod-bl-osh vendor/dod-ui-ven; do
  printf "%-22s read-eval guards: %-3s reader calls: %s\n" "$f" \
    "$(grep -c 'read-eval' hhub/$f.lisp)" "$(grep -c 'read-from-string' hhub/$f.lisp)"
done
printf "%-22s read-eval guards: %-3s safe-read-from-string CALLERS: %s\n" core/dod-ui-utl \
  "$(grep -c 'read-eval' hhub/core/dod-ui-utl.lisp)" \
  "$(grep -rn 'safe-read-from-string' --include=*.lisp hhub/ | grep -v 'defun safe-read-from-string' | wc -l)"
# Credentials are read from their one home, hhub/core/dod-ini-sys.lisp — never
# copied into this file. Keep it that way: one source of truth for a secret.
DBPASS=$(grep -oP "(?<=crm-database-password\* \")[^\"]+" hhub/core/dod-ini-sys.lisp)
mysql -h localhost -u hhubuser -p"$DBPASS" hhubdb -N -B -e \
  "SELECT CONCAT('DOD_VEND_PROFILE columns: ', COUNT(*)) FROM information_schema.columns
   WHERE table_schema='hhubdb' AND table_name='DOD_VEND_PROFILE';" 2>/dev/null
```

---

## State as of 2026-09-14

| | |
|---|---|
| **Unpushed commits** | 8 · `verify: git log --oneline @{u}..HEAD \| wc -l` |
| **Vendor profile API** | built in the tree: 5 verbs → 5 action routes → 5 bindings · `verify: grep -c register-api-route hhub/vendor/nst-bl-vndapi.lisp` |
| **In the running image** | `nst-dal-vnd` 17:20:25, `nst-bl-vnd` 17:20:26, `nst-bl-vndapi` **MISSING** · `verify: the refresh block` |
| **Warehouse in the image** | 17:21:22 — current; it was stale from Sep 13 07:57 until the 17:20 load · `verify: refresh block` |
| **Any vendor verb ever called?** | **NO. Not once.** · `verify: nothing — this is a negative, see below` |

**The negative is the important one.** No `?exists`, `make`, `fetch`, `!update`, `delete!`
or `enumerate` has ever run against a database. The only way to falsify it is to call one.
**Compilation is not evidence** — 2026-09-14 produced two proofs: a copier that compiled
with ten warnings and would have failed on the first fetch, and a helper named `safe`
that executes arbitrary code.

---

## Verified (each was actually exercised, not reasoned)

| Claim | verify |
|---|---|
| `DOD_VEND_PROFILE` = 44 live columns; `nst-vnd` declares 41 (+5 inherited = 46) | refresh block |
| `USERNAME` NOT NULL + no default ⇒ **every** INSERT failed (error 1364) | `mysql … "SHOW COLUMNS FROM DOD_VEND_PROFILE"` |
| Response model excludes all 6 secrets; ferry ↔ response ↔ JSON is 1:1 (35/35/35) | `grep -c '(cons "' hhub/vendor/nst-bl-vnd.lisp` |
| Every new file: top-level form count, depth 0 | see the checker in the session log |
| `read-eval` guard blocks the payload, parses all 20 live zone rows identically | `grep -n read-eval hhub/shipping/dod-bl-osh.lisp` |
| Identity is `(PHONE, TENANT_ID)` — tenant-scoped, unlike products | `mysql … "SHOW INDEX FROM DOD_VEND_PROFILE"` |

## 🚨 BLOCKER 1 — the `read-from-string` sweep is INCOMPLETE

The tree deserialises text columns with `read-from-string`, and `*read-eval*` defaults to
`T`, so `#.` **executes**. One site of five is fixed.

| Site | Data | verify |
|---|---|---|
| `shipping/dod-bl-osh.lisp:137` | `zipcoderangecsv` | ✅ FIXED `5ba1f70` |
| `shipping/dod-bl-osh.lisp:74-80` (7 calls) | `RATETABLECSV` | ❌ OPEN |
| `vendor/dod-ui-ven.lisp:2429` (at login) | `invoice-settings` | ❌ OPEN |
| `vendor/dod-ui-ven.lisp:2457` | session copy | ❌ OPEN |
| `core/dod-ui-utl.lisp:113` (18 callers) | image columns | ❌ OPEN |

**`safe-read-from-string` IS NOT SAFE** — it catches *parse errors* and never binds
`*read-eval*`:

```
(safe-read-from-string "#.(+ 40 2)")  =>  42
```

**Why this blocks the vendor work:** two open sites are columns this API writes —
`RATETABLECSV` (which `nst-vnd-ship` would write) and `invoice-settings` (which the
`!update` shipped in `50ac635` **already accepts**, executed at that vendor's next login).

**Fix:** binding `*read-eval* nil` inside `safe-read-from-string` repairs 18 callers in
one edit. Then the 7 rate-table reads and both `invoice-settings` reads.
**Do NOT replace the reader with a splitter** — the stored values are regex fragments
(`577*`, `(0)`, `()`), and a splitter silently changes which zones match.

## 🚨 BLOCKER 2 — the vendor routes are probably not registered

`nst-bl-vndapi.fasl` exists **beside its source** (17:22) and has **no cache entry**. The
app loads from `/home/hunchentoot/.cache/…`, so that fasl does not reach it. · `verify: refresh block`

```lisp
(list-api-routes)      ; expect 5 warehouse + 5 product + 5 vendor
(list-action-routes)   ; expect route-vendor-*
```

---

## Next steps, in order

1. **The `read-from-string` sweep** (Blocker 1). Do it *before* building shipping — `nst-vnd-ship` writes `RATETABLECSV`.
2. **`(asdf:load-system :nstores)`**, then `(list-api-routes)`, then **call** `?exists`/`fetch`/`enumerate`. Nothing has run.
3. **Build `nst-vnd-ship` + `nst-vnd-shipzone`** — design settled, see §12.3 of the vendor CONTEXT.
4. **Build `nst-vnd-pay`** — 5 flags only.
5. **Implement the secret-lockout split**: `*vendor-update-forbidden-fields*` → `(:password :salt)`; `payment-*` become updatable.
6. **Put the vendor on `domain-ctx`'s `actor` slot** before any vendor-scoped route binds. `domain-ctx-actor` is read **nowhere** in the tree, so this is free — and without it `vendor-id` comes from the request, letting one vendor read another's config **inside the same tenant**.
7. Then the 4xx taxonomy (3 vendor paths answer 500 where 400 is right), then tests.

## Open environment issues

| | verify |
|---|---|
| `hhub/products/nst-bl-prdapi-CONTEXT.md` is mode 600 `hunchentoot` → `git add -A` fails on it | `ls -l hhub/products/nst-bl-prdapi-CONTEXT.md` |
| `hhub/vendor/nst-bl-vendapi.lisp` is stale, inert, and one letter from the live `nst-bl-vndapi.lisp` | `grep -c register-outbound-route hhub/vendor/nst-bl-vendapi.lisp` |

## Where the depth lives — read on demand only

| File | For |
|---|---|
| `hhub/vendor/nst-bl-vndapi-CONTEXT.md` | the vendor API: decisions, schema, §11 render-json, §12 this session |
| `hhub/products/nst-bl-prdapi-CONTEXT.md` | the reference implementation and the Belnap findings |
| `hhub/core/nst-bl-apidefs2-CONTEXT.md` | Ring-4 conventions |
| `test/smoke-warehouse-api.sh` | the test pattern, incl. the Belnap section |
| `core/nst-bl-adhara.lisp` §1/§5b/§6 | sentinels, the knowledge→result converters, the प्रत्यय contracts |
