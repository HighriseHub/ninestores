# Document numbering — one mechanism, two series (orders and invoices)

**Read this when:** you are minting, formatting, changing or explaining a document number — an ORDER
(`ORD-…`), an INVOICE (`INV-…`), a new document type, or a prefix/counter/financial-year question; or
when a number looks wrong, unsorted, non-consecutive, or fails to render.

**Verified:** 2026-10-13 against the tree and the live database. The order series (S0b/S0c) is older and
unchanged; the invoice series is new the same day.

---

## 1. The shape is DATA, rendered by one function

`nst-format-doc-number (template values)` (`core/dod-bl-utl.lisp`) does a **single left-to-right pass**
over a template string, substituting braced `{token}` / `{token:width}` and the bare tokens `YYYY`/`MM`.
One pass is load-bearing: a substituted value is never re-scanned, so a prefix containing the letters of
a token cannot corrupt its own number. An unknown or missing token is an **error**, never blank.

| token | is |
|---|---|
| `{prefix}` | the issuer's `DOC_PREFIX` |
| `{fy}` | the April–March financial year, short form (`2026-27`) |
| `{ref:N}` | a keyed, NON-sequential, unguessable reference, N chars |
| `{counter:W}` | the sequential counter, zero-padded to W |
| `YYYY` / `MM` | bare tokens, for the legacy `INV-YYYY-MM-{counter}` shape |

## 2. 🚨 Orders and invoices differ ON PURPOSE — do not "harmonise" them

| | order | invoice |
|---|---|---|
| template | `ORD-{prefix}-{fy}-{ref:6}` | `INV-{prefix}-{fy}-{counter:6}` |
| serial | **non-sequential** | **consecutive** |
| why | a sequential order number lets a vendor count how many orders its customer placed with its **competitors** (F1) | **GST Rule 46(b) wants a CONSECUTIVE serial** for the financial year, and a non-sequential invoice number is what a tax invoice must NOT have |

Both use the same counter, the same formatter and the same prefix ladder; only the serial token differs.
`{ref:N}` stays in the vocabulary, so a vendor who ever wants opacity on invoices can have it as a **data
change to their setting**.

## 3. ⚠ `{counter}` WITHOUT A WIDTH DOES NOT SORT

`nst-doc-number-pad` treats width **NIL as NO PADDING**, so an unbraced `{counter}` renders `1`, `2`, …
`10` and `"…-10"` sorts **before** `"…-2"` in a text column. Always write `{counter:6}`. The counterpart:
a value LONGER than its declared width is an **error**, not a truncation — the refusal is the safety
property (a serial must never silently become a different number). `{ref:N}` reads its width from the
template the same way.

## 4. Where the pieces live

| piece | home |
|---|---|
| formatter, counter allocator, reference permutation, prefix ladder | `core/dod-bl-utl.lisp` |
| counter table | `DOD_DOC_COUNTER` (the counter `{counter}` never had — `installation/upgrades/nst-dbu-doc-counter.lisp`) |
| permutation key | `DOD_SYS_SECRET.DOC_REF_KEY` |
| CUSTOMER prefix (orders) | `DOD_CUST_PROFILE.DOC_PREFIX varchar(8)`, allocated on first use |
| VENDOR prefix (invoices) | `DOD_VEND_PROFILE.DOC_PREFIX varchar(8)`, allocated on first use |
| defaults | `*nst-order-number-format*`, `*nst-invoice-number-format*`; the vendor's own `invoice-number-format` setting wins over both |

**Allocation is a LADDER, never a derivation**: two parties named "XYZ Corp Ltd" and "XYZ Corporation"
both derive `XYZCORP`, and one token must not identify two issuers. Candidate order is base, then
`base+01…99`, then `base+001…999`, and the UNIQUE index is the real guarantee.

## 5. Traps that cost time (each measured)

1. 🚨 **`LAST_VALUE` is RESERVED in MySQL 8** (a window function): the counter column is `LAST_SEQ` and
   every identifier in the counter SQL is backticked.
2. **A counter scope is an identity, not a convenience.** Orders scope per `(customer, FY)`; invoices per
   `(vendor, FY)` — per customer would restart one vendor's series once per customer and break the
   consecutiveness GST cares about.
3. **`{ref:N}` is NOT injective** — an HMAC truncated to N chars can collide (birthday bound). The unique
   index catches it and the mint retries; widening `{ref:N}` removes the risk with no code change.
4. ⚠ **A MySQL trigger owned `INVNUM`** and overwrote it on EVERY insert with
   `NST<row_id>-<calendar year>` — a global series in the wrong year, discarding every minted number.
   It was DROPPED on 2026-10-13 (`nst-dbu-invoice-numbering.lisp`). Consequence to remember: **any code
   that reads back what it wrote is right, and any code that trusts its minted value is wrong** until the
   drop lands — `nst-invh`'s `make` re-reads the row for exactly this reason. The same trigger explains
   why a legacy create path that passed a session UUID in the number slot "worked" for years.
5. ⚠ **A new column needs FOUR declarations** — DB, domain class, response model, and the **CLSQL view
   class** the copier writes. See `invoice-api-reference-CONTEXT.md` §8.4.
6. ⚠ **`nst-symq`'s line numbers are a SNAPSHOT** of `nst-bl-funloodat.lisp` and go stale the moment a
   file is edited. It sent me to the wrong function on 2026-10-13; grep as well.

## 6. The self-check

`tools/nst-verify-doc-numbering.lisp` (offline, no database, no image) — **126 checks, 0 failures** on
2026-10-13, over the FY rule, the token renderer, the fail-closed key, the counter SQL's quoting and the
shared order-status lists. Run it before trusting a numbering change; it exists because a document number
is the one artefact a customer can compare against another customer's.
