# SKILL: bulk-products-csv — the products.csv contract and the bulk/template endpoints

**Read this when:** a vendor's products.csv upload wrote nothing, or reported an
*unchanged* row as a problem; an upload 500s with `MISSING-SLOT PRICE`; you are adding,
removing or reordering a **products.csv** column, or changing what the `MD5Digest`
covers; a vendor re-uploads an old file and a field lands in the wrong column; a
`POST /catalog/products/bulk` or `GET /catalog/products/template` call misbehaves.

**Status:** both endpoints were **built 2026-09-20** (commit `16faf7e`) and exercised the same
day through `hhub/test/smoke-bulk-products-api.sh` (**11 pass / 7 fail**); the 23-column v2
contract was **written 2026-09-21** (commit `212b7cc`, dated 2026-09-22) and **nothing has been
compiled or run since the 23-column cut**. Originally `../nst-bl-prdapi-CONTEXT.md` §8c
and §8d; moved to this file on **2026-10-05**, §-numbers preserved, content unchanged.
Everything below was **measured, not reasoned**, except where it says otherwise.

**Applies to:** `hhub/products/dod-bl-prd.lisp` (`*prd-bulk-csv-header*`, `prd-csv-*`,
`create-bulk-products`, `create-products-csv2`, `product-csv-file-data-row`),
`hhub/products/nst-bl-prdapi.lisp` (`route-product-template`,
`route-product-bulk-upload`), `hhub/test/smoke-bulk-products-api.sh`, the legacy vendor
page `hhub/vendor/dod-ui-ven.lisp`.

---

## 8c. The bulk products.csv pair — findings, 2026-09-20 (evening)

**Status: BUILT, partially exercised, ONE KNOWN BLOCKER.** Endpoints:
`GET /catalog/products/template` (text/csv) and `POST /catalog/products/bulk`
(multipart or raw CSV). Smoke: `hhub/test/smoke-bulk-products-api.sh`, 11 pass / 7 fail
at the end of the day.

### 🚨 THE MD5digest IS A "HAS THIS ROW BEEN TOUCHED?" FLAG, NOT A TAMPER CHECK

`product-csv-file-data-row` ends `(unless (equal expected-md5 computed-md5) (list …))`
and the caller `(remove nil …)s` the result. So:

| digest | outcome |
|---|---|
| **matches** | row **SKIPPED** — unchanged, nothing to do |
| **differs** | row **APPLIED** — the vendor edited it |
| **blank** | row **APPLIED** — a new row |

Coherent (the CSV is a whole-catalogue export; the digest identifies which rows changed
without diffing the database) but the **opposite of what the name suggests**. This cost
three separate wrong implementations in one evening — the smoke test, then the verb,
each asserting that a match meant valid. State it wherever the digest is read.

### 🚨 BULK COULD CREATE EXACTLY ONE PRODUCT, EVER (fixed)

`product-csv-file-data-row` built the `dod-prd-master` row and never set `PRODUCT_CODE` —
which carries a **UNIQUE index** — so the first insert took `''` and every later one died
with `Error 1062 / Duplicate entry ''`. One live row held `''`. Fixed by setting
`:product-code (format nil "PRD-~A" (hhub-random-password 10))`, matching `persist-product`
(`dod-bl-prd.lisp:275`). **The vendor page had the same defect** — the API reuses its row
construction deliberately, so both were broken. Safe on update: `create-bulk-products`
copies a named slot list that excludes product-code.

### Other traps hit, in the order they bit

- **`(hunchentoot:content-type*)` is the REPLY's type** (`reply.lisp:87`). Reading it to
  detect an inbound multipart body always failed, so `raw-post-data` handed the verb the
  whole **multipart envelope**. The request header is `(hunchentoot:header-in* :content-type)`.
- **The template served a stale session cache.** `hhub-get-cached-vendor-products` funcalls
  the `:login-vendor-products-functions` session value; the legacy UI calls
  `dod-reset-vendor-products-functions` after every write and the API did not.
- **The generated CSV is CRLF**, so `head -1` of a *correct* file ends in a carriage
  return — an exact header comparison fails on a byte-identical string.
- **`create-products-csv2` crashed on any product with no pricing row** (`MISSING-SLOT
  PRICE`; 11 live products), and its `with-slots` list has `current-price` but **not**
  `current-discount`.
- **The body is unparsed** (`:request-format :raw`), so a literal `{}` parsed as one row
  and **inserted a junk product**. Now guarded by `prd-bulk-csv-header-p` — the header is
  the only part of the file that can be validated, since a blank ProductID is legal.

### ⚠️ OPEN, AND BLOCKING THE ONE ASSERTION THAT MATTERS

**The fixture product never appears in the template** (64 rows, fixture absent, every run).
The fixture is `approval_status='PENDING'` because that is what `POST /products` creates,
so the likely answer is that the vendor's product list excludes unapproved products —
correct behaviour, but it means **a vendor cannot see a product in the bulk template until
it is approved**. Decide first, then either change the list filter or point the smoke
test's edit at an existing catalogue product.

**Also open:** one generated row fails to re-parse (`bounding indices 0 and 6 are bad for a
sequence of length 5`) — the exporter emits a row with too few columns, so some product
cannot round-trip.

### The process lesson, which cost more than any single bug

**Paren balance is not a correctness check.** Four times in one day an edit left something
behind that the compiler could not see because the parens still balanced: `FIXNAME`
used but never defined; `EDITED`/`NEWROW` the same; `check`/`HDR` called but never
defined; and `(problems nil)`/`(rows nil)` turned from `let` **bindings** into **function
calls** by an edit that matched the first binding and closed the list early — a 500 on
every bulk request from a change whose purpose was to make the route stricter.

**When adding a binding to a `let`, match through the END of its binding list.** And after
any structural edit, read the region back: parsing is not meaning what you intended.

---

## 8d. The products.csv v2 contract — 23 columns, 2026-09-21

**Status: WRITTEN. Not compiled or run since the 23-column cut — see the gap below.**

`*prd-bulk-csv-header*` (`dod-bl-prd.lisp`) is now 23 columns. Columns 0-9 are the old v1
order, unchanged; 10-21 are new; `MD5Digest` is LAST and covers every cell before it.
**Vendors start afresh — a v1 file is rejected by `prd-bulk-csv-header-p`, by design.**

New: `HSNCode ProductType SKU ShippingLengthCms ShippingWidthCms
ShippingHeightCms ShippingWeightKg UPCCode EANCode JANCode ISBNCode SerialNo`.

### 🚨 DESCRIPTION IS OUT OF THE CSV — the UI OWNS IT (2026-09-21)

Measured, not assumed: `DESCRIPTION` is **`varchar(1024)`, not `TEXT`** — not unlimited — and
`sql_mode` is `STRICT_TRANS_TABLES`, so an over-long value is an **error 1406**, not a
truncation. Three live rows sit at exactly 1024. Since `route-product-bulk-upload` wraps
`create-bulk-products` in ONE `clsql:with-transaction` with no per-row handler, **a single
over-long description would roll back the entire upload** — the per-row report only covers
CSV *parsing*, never writes. (Pattern for the guard: `nst-bl-vndshp.lisp:1187`.)

It was dropped because **any projection of it is destructive**: the 18 live HTML descriptions
carry `<h1>/<p>/<ul>` and 31 contain real newlines and 34 commas. Exporting plain text so a
spreadsheet can edit it means a vendor changing *only a price* still has a non-blank
Description cell, which would overwrite the stored rich HTML on upload. A lossy export cannot
have a lossless import, so one field gets one editor — and the UI editor is the right one.

**NIL-SAFE BY CONSTRUCTION, all four sites:** the parser sets `:description nil` explicitly
(bound, not unbound — a bare omission would make `slot-value` signal UNBOUND-SLOT); the
update-path `with-slots` and its blank-cell dolist no longer name it at all; the generator
does not emit it. So a bulk upload can neither read nor clobber a description.

**Still open, and it is the real hazard of this cut:** `prd-bulk-csv-header-p` guards only the
**API** route. The legacy vendor page parses with `:skip-first-p T` and **no header check**
(`dod-ui-ven.lisp:540`), so a vendor re-uploading a pre-23-column file through the UI gets it
read positionally against the new header — an old `Description` cell lands as `HSNCode`, and
the corruption is silent. The UI path needs the same guard.

**`CATG_ID` was also withdrawn** (2026-09-21), on the same reasoning as `EXTERNAL_URL` below:
the category is set elsewhere, not by a spreadsheet cell. It went out of the header, the
generator, the parser's initargs and `create-bulk-products`' update-path `with-slots` — and
**out of the JSON response too**, along with `externalUrl` (both removed from `render-json`,
from `domain->response` and from `ProductResponseModel`, leaving 27 slots = 27 published
keys). Removing a column means removing it from all four CSV sites plus three JSON sites.

**`EXTERNAL_URL` is deliberately NOT a column.** It is internal: the browser's create-link
button mints it on demand (`generate-product-ext-url`, `dod-ui-ven.lisp:1449`) and copies it
to the clipboard. It is **also no longer in the JSON response** (withdrawn 2026-09-21), and it
stays out of `prd-copy-initargs` — it is the source's public share link, so a copy must not
inherit it. Removing it from the CSV also removed it from the parser's initargs **and** from
`create-bulk-products`' update-path `with-slots`; those two must move together, or the slot is
read unbound and the upload 500s.

* **One `HSNCode` column holds HSN or SAC** — there is only one DB column. Its `varchar(8)`
  cap is narrower than `DOD_GST_HSN_CODES.HSN_CODE varchar(10)`, and **76 of the 118 codes
  already in use are absent from that master table**, so it is not a validation source.
  `DOD_GST_SAC_CODES` has **0 rows** — service codes cannot be checked at all.
* **`ProductType` is pre-filled `SALE`** and accepts only `SALE`/`SERV` (live values are
  `SALE` and `SERV`, *not* `SERVICE`). `prd-csv-prd-type` falls back to `SALE`. The UI
  checkbox at `dod-ui-prd.lisp:197-203` still works and is still how a vendor marks a
  service.
* **The digest is now over every column.** The generator formats each field ONCE, hashes
  that string and writes that same string; the parser re-normalises the cells it read
  (trim only). Editing only the HSN therefore moves the digest and the row applies. Had the
  new columns been left out of the hash, every HSN-only edit would have been **silently
  skipped** — the §8c "match means skip" trap.
* **CSV quoting is now load-bearing.** `prd-csv-escape` RFC-4180 quotes a cell holding a
  comma, quote or newline: **34 of 105 live descriptions contain a comma and 31 contain a
  newline**, so an unquoted file was already structurally broken. Likely the same root
  cause as the still-open "bounding indices 0 and 6 … length 5" re-parse failure.
* **A blank cell means "no change"** on the update path (`prd-csv-or`), so a vendor cannot
  wipe a column by leaving it empty. The cost: **a field cannot be cleared through the
  CSV.** `ProductType` is the exception — blank falls back to `SALE`.
* Columns are now read by **name** (`prd-csv-cell` against the header constant), not by
  `nth`, so inserting a column can no longer silently relabel every field after it.
* `create-bulk-products`' update path grew the matching slot list. **Its `with-slots` reads
  an unbound slot as an error**, so a field added to the parser but not to the generated
  instance is a 500 — the `current-discount` lesson, one column over.
* `ProductCode` is deliberately neither exported nor settable (a reserved identity).
* 🚨 **A NON-ASCII DESCRIPTION CRASHED THE GENERATOR** (found 2026-09-21, fixed).
  Putting `Description` in the digest exposed `create-digest-md5`
  (`core/dod-bl-utl.lisp:721`), which used `ironclad:ascii-string-to-byte-array` and
  signalled `"… is not an ASCII character"` on the very first typographic apostrophe
  — live, on *"cow’s milk"*. Now UTF-8 via `sb-ext:string-to-octets`. **Pure-ASCII
  input yields identical bytes, so no existing digest moved**, and `sb-ext` was
  already used in that same file. `create-digest-sha1` (line 718) still carries the
  same defect and has no callers.
* Neither write path needed a charset fix: SBCL's default external format on this box
  is already UTF-8, and hunchentoot's `*hunchentoot-default-external-format*` is
  `+utf-8+`, matching the route's `text/csv; charset=utf-8`.

---

**Where this came from:** §8c and §8d of `../nst-bl-prdapi-CONTEXT.md`, split out on
2026-10-05 because this is the products.csv mechanism rather than the catalog API. That
file's §8c–8d heading is now a pointer here, and it is what
`hhub/products/dod-bl-prd.lisp:764` means by *"the 2026-09-21 note in
nst-bl-prdapi-CONTEXT.md section 8d"*.
