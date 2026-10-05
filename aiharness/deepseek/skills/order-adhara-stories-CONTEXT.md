# Order entities on the adhara grammar — design decisions + stories · CONTEXT

**Read this when:** you are converting the ORDER header, the order line or the VENDOR
order to the Paninian (adhara) grammar — i.e. writing `nst-ordh` / `nst-orditm` /
`nst-vordh`, their प्रत्यय, their routes or their smoke tests — or you are about to build
the `order → invoice` compound verb and need to know what it waits on.

**Status: DESIGN SETTLED 2026-09-27 · IMPLEMENTED THROUGH S15 (2026-10-04) · S16 IN PROGRESS
(AC (a) PROVEN live 2026-10-05).** Both channels are live code with their acceptance criteria verified
**offline**: the customer's (`nst-ordh` + `nst-orditm`) and the **vendor's** (`nst-vordh` — its own
file, `vendor-orders-adhara-CONTEXT.md`, decisions V1–V15). Left in S16: the items suite (written,
unrun) and the consolidated suite (not written); S17 (the `invoice (ord ctx)` compound verb) is out of
this batch. The batch's headline discovery is §3b: **there was no order number anywhere in the
database** — 485 of 485 orders and 462 of 462 vendor rows had a NULL `ORDNUM`. They have one now:
`ORD-<DOC_PREFIX>-<FY>-<seq>`, from a per-customer document prefix, permuted non-sequentially so the
series is not a competitor-enumeration oracle (F1), with `uk_ordnum` enforcing uniqueness. Both
prerequisites are DONE and APPLIED: the counter table `DOD_DOC_COUNTER` (+ `DOD_SYS_SECRET.DOC_REF_KEY`)
and the existing number-format template, which the prefix JOINs as a `{prefix}` token rather than
replaces.

**The standards review** (OWASP API Top 10 / NIST / Google AIP / RFC / WCAG — twenty findings, F20
pre-existing) is now its own file, `knowledge/order-standards-review-CONTEXT.md`: read F1–F6 before
changing behaviour and **F3** before touching authorization, because S14's seeded policy rows are
**carried, not enforced** (D18) and are not a control. **The offline harness**: the copy-paste recipe is
in §0 below; how a checker is proved, the four classes of checker bug, the registration rule and what no
offline check can do are in `knowledge/offline-checker-methodology-CONTEXT.md`.
**The narrative** behind every verdict below is in `archive/order-adhara-stories-NARRATIVE-2026-10-04.md`
(2127 lines, snapshot of 2026-10-04) — read it to re-derive a verdict, not to start work.

**Applies to:** the nine `hhub/order/` files, `hhub/core/dod-bl-utl.lisp`, `hhub/core/dod-ui-pol.lisp`,
`hhub/core/nst-sch-mig.lisp`, the four
`installation/upgrades/nst-dbu-{doc-counter,ordnum-identity,order-invariants,ordapi-policy-transaction}.lisp`
migrations, `hhub/test/smoke-order-*.sh`, and the offline harness under `aiharness/deepseek/tools/`.

---

## 0. RESUME HERE — state of play at 2026-10-04, for a NEW session

**Enter here, then open `vendor-orders-adhara-CONTEXT.md` if you are touching the vendor channel.**
Every verdict below cites the check that produced it, and **every check named is OFFLINE** — no
session, no server, no database write.

### Where the code is (all of it, by story)

| file | what it is | story |
|---|---|---|
| `hhub/order/nst-dal-ordh.lisp` · `hhub/order/nst-dal-orditm.lisp` | island entities + boundary models for `DOD_ORDER` (reuses `dod-order`, D7) and `DOD_ORDER_ITEMS` | S1/S2 |
| `hhub/order/nst-bl-ordh.lisp` | the header's six प्रत्यय, the ferries, the field policy, `render-json`, the domaintodb copier | S3–S6 |
| `hhub/order/nst-bl-orditm.lisp` | the line's six प्रत्यय + the parent proof + its copier | S7 |
| `hhub/order/nst-bl-ordhapi.lisp` · `hhub/order/nst-bl-orditmapi.lisp` | the customer channel: 9 action routes, 7 bindings, the D14 assembly, the 412 seam, the nested body readers · then the two line endpoints | S12/S13 |
| `hhub/order/nst-dal-vordh.lisp` | class `dod-vendor-order` over **all 60** live columns + the vendor island | S9 |
| `hhub/order/nst-bl-vordh.lisp` | the VENDOR channel's six प्रत्यय (V8/V9/V10 live here) + its copier | S10 |
| `hhub/order/nst-bl-vordhapi.lisp` | the vendor channel: 3 routes + 3 bindings + `vordh-row-from-url` + the ETag | S11 |
| `hhub/core/dod-bl-utl.lisp` | the ONE home of the status lists, the number mint, `nst-coerce-for-db-slot`, **`nst-db-slot-value-from-domain`** | S0c/S8/S16 |
| `hhub/core/nst-sch-mig.lisp` · `hhub/core/dod-ui-pol.lisp` | the `*migrations*` registry · the ten order-API policy functions | S0c/S14 |
| `installation/upgrades/nst-dbu-{doc-counter,ordnum-identity,order-invariants,ordapi-policy-transaction}.lisp` | the four migrations | S0b/S0c/S14 |
| `hhub/test/smoke-order-{header,items,vendor,api}-api.sh` | the four suites (header and vendor are WRITTEN AND RUN; items is written; the consolidated one is not written) | S16 |
| `aiharness/deepseek/tools/nst-{preflight,offline-load,binding-order-check,compile-production,verify-doc-numbering,verify-order-create,order-mirror-check,vordh-mirror-check,vordh-route-probe,verify-abac-seed}.lisp` | the offline harness — every one exits non-zero on a finding | all |

### Story status

**S0–S15 DONE; S16 IN PROGRESS (AC (a) proven 2026-10-05).** §6 is the per-story record — what each
story is, its AC, its verdict and the trap it paid for.

### The immediate next actions, in order

1. ~~Restart the image~~ ✅ done 2026-10-05, and ~~`--write` for AC (a)~~ ✅ **PROVEN** — the create
   answers 201 with a minted number, the replay and the full lifecycle (S16, §6).
2. **Run the items suite** (`smoke-order-items-api.sh`, written and unrun), then **write the consolidated
   one** (`smoke-order-api.sh`: both sessions, the full lifecycle, the BOLA cases, O3 asserted as `KNOWN`).
3. **Write S16's verdict into §6**, then close the batch against §8 and retire this file to `archive/` —
   but note that **10 `.lisp` files cite its path**, so that move needs those headers repointed in the
   same change.
4. **The KNOWN items**: `UPDATED`/F8 is frozen so the vendor ETag never changes (`PENDING-WORK §10`) ·
   O3's partial-write window · the `IS_CONVERTED_TO_INVOICE` refusal has no fixture · the vendor channel
   cannot reach its own LINES.

### Open decisions that need the human (not bugs — choices)

| # | question | where |
|---|---|---|
| **V8** | the vendor may write exactly **four** fields (`:order-fulfilled :shipped-date :comments :external-url`). Deliberately narrow: no money, no addresses, no lifecycle. Widening is one line. | `nst-bl-vordh.lisp` |
| — | **8 live vendor rows whose header order is soft-deleted** — the vendor channel still shows them. The honest fix is that the CUSTOMER channel's `delete!` cascades to vendor rows; it currently does not. | `nst-bl-ordh.lisp` |
| — | **No nested lines on the vendor detail.** A vendor needs to know *what* to ship; serving it needs a vendor-scoped line read in `nst-bl-orditm.lisp` (that entity's enumerate filters by order, not vendor). | S11 note |
| — | **Per-vendor tax totals are not computed** — the vendor row's `TOTAL_*` columns keep 0.00, because copying the ORDER's totals into one vendor's slice would overstate it. Per-vendor arithmetic is a later pass. | `ordhapi` V15 note |
| — | **The customer channel emits no ETag**, so its `If-Match` is unusable (the vendor channel does emit one). | `ordhapi` |
| **F12/F16** | PUT vs PATCH, and whether `POST /orders` includes OTP + wallet — still open from the standards review. | §10 record |

### The verification recipe — copy-paste, in this order

```sh
cd /home/ubuntu/ninestores
XDG_CACHE_HOME=$PWD/.asdf-cache sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-preflight.lisp
aiharness/deepseek/tools/nst-binding-order-check
sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-vordh-mirror-check.lisp
sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-verify-abac-seed.lisp
XDG_CACHE_HOME=$PWD/.asdf-cache sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-verify-doc-numbering.lisp
# the two that LOAD the tree (seconds from a warm fasl cache, minutes from cold):
XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-offline-load.lisp
XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-vordh-route-probe.lisp
```

**Prerequisite for the two tree-loading tools** (one-time, and `/tmp` is ephemeral):

```sh
mkdir -p /tmp/nst-asdf/clsql-dist
cp -rp /home/ubuntu/quicklisp/dists/quicklisp/software/clsql-20221106-git /tmp/nst-asdf/clsql-dist/
chmod -R u+w /tmp/nst-asdf/clsql-dist
```

⚠ **A check whose INPUT is missing must FAIL, not pass** — the rule, its evidence (`nst-preflight.lisp:55-71`) and the four classes of checker bug are in `knowledge/offline-checker-methodology-CONTEXT.md` §1–§2.

### Traps this batch paid for — each cost real time, none is obvious

1. **NEVER DEFINE A MIGRATION HELPER IN AN UPGRADE FILE.** `apply-migrations` calls `load-upgrade-files` FIRST, so upgrade files load **after** `core/nst-sch-mig.lisp` and their definitions **silently win**. The first policy seed carried its own copies of all five ABAC helpers, so the canonical `insert-auth-policy` — the one that escapes every string through `sql-literal` — **was never called**, and a `DESCRIPTION` containing an apostrophe (`"…the session customer's orders…"`) ended the SQL literal and died with **Error 1064** while the escaping sat in the image, correct and fbound. The five definitions are deleted; the rule is now in `knowledge/ABAC-policy-transaction-CONTEXT.md`. **When an escaping helper appears not to work, check who is defined before you.**
2. **A NEW `hhub/**` FILE NEEDS FOUR REGISTRATIONS, NOT TWO**: `hhub/package/compile.lisp`, `hhub/nstores.asd`, **and both lists inside `nst-preflight.lisp`** (`*files*` for reader balance and SQL quoting, `*hhub-new-files*` for the build-registration check). They are separate lists; a file in the first but not the second is balanced and then **silently skipped** — a pass that means nothing.
3. **TOOLS THAT READ `hhub/**` SOURCES NEED CLSQL'S READER SYNTAX.** The tree is full of `[= …]` SQL literals; with a stubbed package the reader answers `Package [ does not exist` and the tool reports a **healthy file as unreadable** — the same lesson `nst-preflight.lisp:55-71` records for a missing dependency. Either quickload clsql, or use a readtable with `[`/`]` as whitespace (what `nst-vordh-mirror-check.lisp` does; `ql:quickload :clsql` collides over uffi here).
4. **A probe must be `(in-package :nstores)` AFTER the tree loads** — the tree has ONE package, and a probe left in `CL-USER` fails with `FIND-API-ROUTE is undefined` *after* a four-minute load, which reads exactly like a missing binding.
5. **THE DATABASE IS `STRICT_TRANS_TABLES`, SO AN OVER-LONG VALUE IS Error 1406, NOT A TRUNCATION** — and `apply-migrations` catches per-migration and CONTINUES without recording the version, leaving a seed that re-runs forever, half-applied. Widths that bite: `DOD_AUTH_POLICY.DESCRIPTION` 100, `.NAME` 50, `DOD_BUS_TRANSACTION.NAME/URI/TRANS_FUNC` 100, `TRANS_TYPE` 15, `DOD_SCHEMA_MIGRATIONS.version` 50. `nst-verify-abac-seed.lisp` checks all of them.
6. **`TRANS_FUNC` IS THE LOOKUP KEY, NOT `NAME`**, and `insert-bus-transaction` defaults it to a string derived from the trans-TYPE alone — so omitting it gives every READ endpoint ONE key. The convention is `"api <METHOD> <path>"` with `{ordnum}` kept, while `URI` must be the **collection prefix** (a template URI never matches a real request).
7. **SBCL IS SILENT ABOUT AN UNUSED *REQUIRED* PARAMETER** (it warns about `let` bindings and about `&optional`/`&key`). Neither `ql:quickload :silent t` nor the offline-load log shows it — the human's build did. The sweep is `compile-file` per file with `*error-output*` captured; and when the warning points at a **redundant carrier** (two functions each took a `tenant-id` they never used), DELETE the parameter rather than silencing it.
8. **`~:[FAIL (~D problem(s))~;PASS (~D check(s))~]` CONSUMES ONLY ONE ARGUMENT AFTER THE CONDITIONAL** — so the FAIL branch prints the *check* count labelled "problem(s)", and a failing run reads `FAIL (10 problem(s))` when it had two. Three files in this batch lost time to it; **a report that lies about its own numbers is worse than no report.**
9. **A FORM-WALKING CHECKER IS CODE, AND NEEDS THE SAME SUSPICION AS THE CODE IT CHECKS.** Four bugs in one checker: a positional argument read as "the leading strings" when it was a `let` VARIABLE (`order-uri`); plist keywords paired from the head instead of after the positionals; a dotted `(cons label (cons value width))` read as a list; and two misplaced parens that silently turned an enclosing `if` into a four-argument form — which the compiler reports as *"Error while parsing arguments to special operator IF"*, not as a paren error.
10. **AC (f)'s MECHANISM IS THE MIRROR LIST, NOT A SPECIAL CASE.** `!update` writes the row WHOLE, and `ord-date` is in `*vordh-mirrored-slots*` — so the value read is written back, which is what defeats `ON UPDATE CURRENT_TIMESTAMP` (T9, **vendor-only**: the header's `ORD_DATE` is a `date`). Reading a `timestamp` as `clsql:date` DROPS the time of day, so the round trip would move the row to midnight while looking correct — hence `(string 30)` (V5).
11. **A VENDOR SESSION'S TENANT NEEDS NO WORK FROM AN API FILE**: `make-action-domain-ctx` builds it from `conflodis2-login-company`, which resolves vendor → customer → user. And read the session with `conflodis2-session-value`, **never** `hunchentoot:session-value` directly — outside a request the direct call signals UNBOUND-VARIABLE, so "we cannot tell who you are" becomes a 500 instead of 401.
12. **The scope filter's HOME is fixed by the grammar**: `fetch` and `delete!` are congruent at three fixed arguments (no `&key`), so a vendor-id CANNOT ride them — it rides `enumerate`, `?exists`, and `!update`'s `&rest` (consumed BEFORE the field policy, the S12 lesson), and the ROUTE narrows the other two.

### Live image and database state (measured 2026-10-04, 23:00)

* ⚠ *Superseded 2026-10-05:* the image then running had started **07:46** (PID 1919), carrying the
  nested-param fix but **not** the copier guard or the initforms, so the create died in the write half.
* **The API has created orders**: `rowId 491` (`ORD-DEMO-2026-27-XZ64UY`, `DFT`) was the first, left
  behind by a 500 that fired *after* the header and the line were written. It has been removed and the
  product's stock restored, so the database has **no DFT order and no orphan**. **Ordnums are live**: 0
  NULL on `DOD_ORDER` (489 rows) and 0 NULL on `DOD_VENDOR_ORDERS` (468). Vendor rows: `CMP` 387 ·
  `PEN` 75 · `VCN` 4 · 9 soft-deleted. `IS_CONVERTED_TO_INVOICE='Y'`: 0 rows.
* The four customer logins that work: **`9999999999` (profile 1, DEMO, 208 orders)** — the best fixture
  set — `9448613099` (27), `9999950355` (3). ⚠ `9972022281` has NO password at all, in either credential
  table, so no password can authenticate it. The vendor login is `9999999990`.

### Committed, and the commit convention

Three commits on 2026-10-04, each with a **two-line** message (subject, then one body line — no blank
separator; note this makes `git log --oneline` show both lines): `833392a` (S15/S16: the create path
fixed, the three suites, both new tools) · `f8107fb` (S1–S14's remaining files: the vendor channel, the
build lists, the ABAC seed) · `e9d8019` (token hygiene: nine call sites off `hhub-random-password`).
**28 paths remain uncommitted** — another workstream in flight (the `CustomerUser` entity, `wallets/`,
`products/pricing/`, `paninigrammar/`, the `site/public/*` files) and junk that must NOT be committed
(`.asdf-cache/`, `*.bak`, `out.txt`, `response`, `hhub/temp/`, the deleted Emacs lock file); one
deliberate exception, `installation/deploysite.sh`'s `DEST_BASE`, looks environment-specific. Full list:
archive §"Uncommitted, and the commit convention".

## 1. 🚨 READ THIS BEFORE TRUSTING ANY SCHEMA IN THE TREE

**`installation/hhubplatform.sql` is NOT the live schema for the order tables, and three
design decisions were wrong because it was believed.** Measured against the live
`SHOW CREATE TABLE` (2026-09-27):

| The create-script says | The live table says | Consequence |
|---|---|---|
| `STATUS varchar(20) DEFAULT 'DRAFT'` | **`STATUS char(3) DEFAULT NULL`** | `'DRAFT'` is **physically unstorable**. The `(string 3)` slot in the view class was RIGHT; an earlier draft of this file proposed "widening" it, and that proposal is **retracted**. |
| `UNIQUE KEY ORDNUM (ORDNUM)`, `NOT NULL` | **no unique key; `ORDNUM varchar(50) DEFAULT NULL`** | The mint's retry is **cosmetic** until a migration lands. Exactly the reverse of `INVNUM`, which the invoice batch assumed was NOT unique and measured to be unique. |
| `VENDOR_ID` / `USER_ID` on the header | **neither column exists** | A vendor channel **cannot** scope the header by `VENDOR_ID`. `VENDOR_ID` lives only on `DOD_ORDER_ITEMS` and `DOD_VENDOR_ORDERS`. |
| `INVNUM` on the header | **`INVOICE_NUMBER`** (+ `INVOICE_DATE`) | The order→invoice seam is named `IS_CONVERTED_TO_INVOICE` + `INVOICE_NUMBER` + `INVOICE_DATE`. |

**Lesson to carry: measure the live table, then design.** The two ORDER view classes turned out to be
exact (§3) — the drift was entirely in the create-script. Where a create-script and a live dump
disagree, **the dump wins and the create-script is treated as historical intent**.

---

## 2. Decisions taken (do not re-litigate)

| # | Decision |
|---|---|
| **D1** | **Scope: THREE entities.** `nst-ordh` = `DOD_ORDER` (the customer's order); `nst-orditm` = `DOD_ORDER_ITEMS` (its lines); `nst-vordh` = `DOD_VENDOR_ORDERS` (the per-vendor slice, one row per vendor on a multi-vendor order). **Deferred**: `DOD_ORDER_TRACK`, `DOD_ORDER_ITEMS_TRACK`. |
| **D2** | **Naming.** Symbols `nst-ordh` / `nst-orditm` / `nst-vordh`; models `NstOrdhRequestModel`/`NstOrdhResponseModel`, `NstOrditmRequestModel`/`NstOrditmResponseModel`, `NstVordhRequestModel`/`NstVordhResponseModel`; files `order/nst-dal-ordh.lisp`, `nst-dal-orditm.lisp`, `nst-dal-vordh.lisp`, `nst-bl-ordh.lisp`, `nst-bl-orditm.lisp`, `nst-bl-vordh.lisp`, `nst-bl-ordhapi.lisp`, `nst-bl-orditmapi.lisp`, `nst-bl-vordhapi.lisp`. `nst-ord` was rejected: one letter from the legacy `nst-dal-Order.lisp` on disk, and D16 exists to stop exactly that collision. `nst-ordv` was rejected in favour of **`nst-vordh`**, the name the requester chose. |
| **D3** | **HTTP surface.** <br>**Customer channel**: `POST /orders`, `GET /orders`, `GET /orders/{ordnum}` (aggregate, nested lines), `PUT /orders/{ordnum}`, `DELETE /orders/{ordnum}`, `PUT /orders/{ordnum}/items/{item-id}`, `DELETE /orders/{ordnum}/items/{item-id}`. <br>**Vendor channel**: `GET /vendor/orders`, `GET /vendor/orders/{ordnum}`, `PUT /vendor/orders/{ordnum}` — the live vendor family already carries `/api/v1/vendor/profile`, `/payment`, `/shipping` (`vendor/nst-bl-vndapi.lisp`), and the spec has **no** vendor-orders endpoint at all, so these paths are ours. <br>**Registered but deliberately unbound**: `route-orditm-list`, `route-orditm-fetch` (lines reach the wire through the nested `GET /orders/{ordnum}`). <br>**Out of scope**: cart endpoints (a different aggregate), `/fulfill`, `/cancel`, `/orders/batch/daily`, `/orders/calendar`. |
| **D4** | **`ORDNUM` is the address, and it is the CROSS-PARTY key.** Both channels address by it, because the vendor learns it from the customer ("the customer might send email or call the vendor and ask about the order based on the ORDNUM"). It is therefore: minted by `make` (D6), **immutable over HTTP** (stripped from every update payload, the invoice's §4b trap), and the URL-resolution step happens in the ROUTE layer (`ordh-header-from-url`), because a verb method cannot tell a number from a row-id — both are strings. ⚠ **Uniqueness licenses an ADDRESS, never a TENANT-LESS QUERY** (F2): every resolution stays `WHERE ORDNUM = ? AND TENANT_ID = ?`. ⚠ **The column is NULL on 485 of 485 existing orders (§3b), so this decision was not realisable in the data until S0b part 1**: before that every existing order was unaddressable and the route answered 404 for all of them. |
| **D5** | **अधिकरण and scope.** Customer and vendor are **in the SAME tenant**: `:login-customer-company` is the customer row's `company` JOIN (`customer/dod-ui-cus.lisp:3603,3628`) and the customer's placement path passes that company as `DOD_ORDER.TENANT_ID` (`dod-ui-cus.lisp:2586,2619`). So नियम-1 is unchanged — tenant = session login company — and the parties are a scope **narrowing inside it**: <br>• customer session → `CUST_ID = :login-customer-id` on `nst-ordh`; <br>• vendor session → `VENDOR_ID = :login-vendor`'s row-id **on `nst-vordh`**, never on the header (the column does not exist, §1). <br>**Scope is read from the SESSION, never the payload**; an inbound `:vendor-id`/`:cust-id` is ignored, not honoured and not refused (the body-supplied-`invnum` trap). An order naming neither the session's customer nor its vendor is **404, not 403**. <br>⚠ **Inferred from code paths, not measured** — no DB access. One live `DOD_ORDER` row plus its `:login-customer-company` confirms it. **If a live row contradicts it, stop and re-open D5**, because every scope filter is built on it. |
| **D6** | **`ORDNUM` is minted as `ORD-<DOC_PREFIX>-<FY>-<REF>`** — e.g. `ORD-XYZCORP-2026-27-7K4M2Q`. `DOC_PREFIX` is a **document prefix on the CUSTOMER** (`DOD_CUST_PROFILE.DOC_PREFIX varchar(8)`, system-prefilled, customer-overridable, globally unique), intended as the identity prefix for every document that customer owns. `FY` is the short April–March form derived from `ORD_DATE` (there is **no `FINYEAR` column** on the live table); the published suffix is **`{ref:6}`** — a non-sequential, unguessable rendering (F1's decision record) of a counter scoped **per (customer, document type, financial year)**, so `ORD-XYZCORP-2026-27-7K4M2Q` rather than `...-00001`. A caller-supplied `:ordnum` is stripped. Because the prefix is globally unique, **`UNIQUE (ORDNUM)` is GLOBAL**, and the number-only lookup that licenses is an **address**, not a tenant-less query (F2). **The shape is DATA, not code**: it renders through the number-format template that already exists (`invoice-number-format`, `invoice/templates/invoicesettings.lisp:32`), extended with `{prefix}`, `{fy}` and `{ref:6}` tokens and an `order-number-format` sibling key. ⚠ **Two prerequisites ride with this decision:** a **counter table** (`{counter}` has no backing store anywhere — S0b §C) and the prefix allocator. **The prefix must be ALLOCATED, never derived on the fly** — derivations collide (`XYZ Corp Limited`, `XYZ Corporation`), and a colliding prefix fails the global index. |
| **D7** | **The status vocabulary gains a code, and the legacy layer learns it.** `make` writes **`"DFT"`**; the legacy creation paths keep writing **`"PEN"`** (`dod-bl-ord.lisp:386,564`, `dod-bl-odt.lisp:166`) and are not changed. Therefore **open = `("DFT" "PEN")`** and terminal = `("CMP" "VCN" "CCN")`, as shared lists (D17). The legacy filters must be taught `DFT` — that is S8, with its sites enumerated there. |
| **D8** | **Status gates.** Header `make` → `DFT`. `nst-orditm` `make` and `delete!` → **header must be open**. `nst-vordh` `make` → mirrors its parent order's status. `!update` on any entity → allowed at any status **except terminal**. Header `delete!` and vendor-order `delete!` → **open only**. Two separate lists for the two questions ("may this be deleted?" vs "may its content change?"), as the invoice deliberately keeps them separate. ⚠ **S5 CORRECTED THE HEADER HALF: header `delete!` is `DFT`-only, not open-only** — S5's own AC said so, and a `PEN` row is a PLACED order whose vendor rows would be orphaned. See the S5 section. |
| **D9** | **No new ORM class for `nst-ordh`/`nst-orditm`** — `dod-order` and `dod-order-items` are verified exact against the live tables (§3). For `nst-vordh`, `dod-vendor-orders` declares 26 columns against 60 live: **`nst-vordh` gets its own class** and the legacy one is left alone for the legacy UI (§3, S9). |
| **D10** | **No `define-gana-verbs` for the six universal प्रत्यय** — they carry their own ferry methods (`core/nst-bl-adhara.lisp:233-259`), so `gana-package-for` is never consulted for them. `invoice`/`issue` are already registered under `:proc.finance` (`adhara:437-439`). Any गण verb this batch adds (`accept`, `cancel`, `dispatch`) would need one; none is in scope. |
| **D11** | **`:json` only** — no `render-html` for any of the three entities. |
| **D12** | **No edits to `core/nst-bl-conflodis2.lisp` or `core/nst-bl-apidefs2.lisp`.** Those files only *define* `register-action-route` (`conflodis2:82`) and `register-api-route` (`apidefs2:134`); both **calls** live in the entity's own `*-api.lisp`, because **a binding must follow its registration in load order** (`apidefs2` refuses otherwise, at load time from the fasl). |
| **D13** | **No totals roll-up** — adding, changing or deleting a line never touches `ORDER_AMT`/`TOTAL_TAX`/`TOTAL_DISCOUNT`/`TOTAL_TAXABLE_VALUE`/the `TOTAL_*GST` columns. This is the invoice's K1 gap restated deliberately: a direct header `!update` can set any total it likes, so a roll-up in the line verbs would not close the invariant anyway. |
| **D14** | **`POST /orders` is a Tier-2 multi-entity ASSEMBLY**, not one ferry: the header, N lines, and one `nst-vordh` row per distinct vendor. `*action-route-transaction-function*` is still the no-op (`conflodis2:266-273`), so **a failure midway leaves a partial order**. Decision: build the assembly and **document the partial-write window as a KNOWN in the suite**, not pretend atomicity. Solving it properly changes a seam all ~40 bound endpoints share and belongs in its own change. |
| **D15** | **`domain->response` stays list-driven** (mirror list → `setf` loop), as the invoice's is — that shape is what produced the MISSING-SLOT 500 on every invoice route, so each entity's mirror list gets its own offline check (S6) rather than relying on review. |
| **D16** | **The row-id-from-string guard is consolidated in `core/dod-bl-utl.lisp`** as `nst-row-id-from-string`. Mechanical reason: it is build position **128 / asd 62**, *before* `nst-bl-adhara` (149 / 90) and before every domain file, so nothing can load ahead of it. There are already **five** homes (`vendor-row-id-from-string` `nst-bl-vnd.lisp:460`, `warehouse-…`, `product-…`, `invoice-header-…` `nst-bl-invh.lisp:80`, `invoice-item-…` `nst-bl-invitm.lisp:116`), so the order verbs become the **sixth call site, not the sixth copy**. Re-pointing those five is a follow-up, not part of this batch (§5, O2). |
| **D17** | **The shared status predicates live in `core/dod-bl-utl.lisp` too**, beside the guard and for the same load-position reason: one `*order-open-statuses*` list and one `order-open-status-p`, read by both the new verbs and the retrofitted legacy filters (S8). |
| **D18** | **ABAC is seeded, not enforced** (D13 of the invoice batch): `:required-roles`/`:feature-flags`/`:audit-level` are carried and read by nothing, `dispatch-action` passes `trans-func-name` as `NIL`, and the `DOD_AUTH_POLICY` + `DOD_BUS_TRANSACTION` rows are seeds for the day the PEP lands. |
| **D19** | **`UPDATED` is DB-managed on all three tables** (`timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`) — so the invoice's *"nobody stamps UPDATED"* trap and its `:void-value` misuse **do not apply here**. Conversely, `make`/`!update` must not attempt to set it. |
| **D20** | **`ORDNUM` is DENORMALISED into `DOD_VENDOR_ORDERS`, and is duplicated there BY DESIGN** — one vendor row per (order, vendor), so N vendor rows of one multi-vendor order legitimately carry the same number. Therefore: <br>• the S0b unique index goes on **`DOD_ORDER` only**, and it is **GLOBAL on `ORDNUM`** — the `(TENANT_ID, ORDNUM)` composite was withdrawn once the customer code took over the differentiation (S0b); putting a key on the vendor table's `ORDNUM` would still be wrong, because the number repeats once per vendor of a multi-vendor order; <br>• the vendor entity's **natural key is `(ORDER_ID, VENDOR_ID)`** (which legacy code already assumes: `get-vendor-order-instance` `dod-bl-ord.lisp:113` takes `(car …)` of exactly that pair) and its **address is `(ORDNUM, session vendor)`**; <br>• the D14 assembly must **stamp the minted number into every vendor row it writes** — otherwise the vendor channel cannot address an order the API itself created; <br>• a legacy vendor row whose `ORDNUM` is NULL is a **404, not a guess** — measured, not hypothesised: **all 462 vendor rows are NULL and so are all 485 parent orders** (§3b), so S0b must **mint first (part 1) and backfill second (part 3)**; a backfill alone copies NULL into NULL, which is exactly what running it by hand proved (`Changed: 0`). |
| **D21** | **`!update` on `nst-vordh` writes EVERY slot, never one at a time** — forced by T9. The hydrate → `reinitialize-instance` → write-all-slots pattern preserves `ORD_DATE`; a single-slot write (as legacy `cancel-order-by-vendor` `dod-bl-ord.lisp:330` does) silently rewrites it to now. |

---

## 3. S0 — CLOSED: what the live tables actually are (measured 2026-09-27)

Measured with `SHOW CREATE TABLE`, never from the create-script:

* **`dod-order`** — 58 declared / 58 live, zero drift either way. Reused as-is (D9). `STATUS char(3)`,
  `ORDNUM varchar(50) NULL` (originally with no unique key), **no `VENDOR_ID` and no `USER_ID` column
  at all**, two address sets, the invoice seam (`IS_CONVERTED_TO_INVOICE`, `INVOICE_NUMBER`,
  `INVOICE_DATE`), and `EXTERNAL_URL` as the ONE `utf8mb3` column in a `utf8mb4` table — a join or
  compare on it can raise *illegal mix of collations*.
* **`dod-order-items`** — 30 declared / 32 live, the two omitted being `CREATED`/`UPDATED` (DB-managed).
  Reused as-is. **No FK on `ORDER_ID` and no unique key anywhere** — which is why every line verb
  proves its parent in code (S7).
* **`dod-vendor-orders`** — the legacy class declares **26 of 60** live columns, zero phantom, so the
  vendor entity got its own class (S9).

Keys: `PRIMARY(ROW_ID)`, `TENANT_ID`, `CUST_ID`, `idx_created_by_user`, `idx_gstnumber`,
`idx_converted`, `idx_place_of_supply`. `AUTO_INCREMENT=487`, so the suites have fixtures.

## 3b. The DATA, measured 2026-09-27 — the batch's biggest fact

| query | result | what it decided |
|---|---|---|
| `DOD_VENDOR_ORDERS WHERE ORDNUM IS NULL` | **462 — every row** | the vendor channel's number-address worked for ZERO existing rows |
| `DOD_ORDER WHERE ORDNUM IS NULL` | 🚨 **485 — every order** | **there was no order number in the database at all** |
| `… GROUP BY ORDNUM HAVING COUNT(*)>1` (non-NULL) | empty | no resolution pass needed before the unique index |
| `… GROUP BY ORDER_ID, VENDOR_ID HAVING COUNT(*)>1` | empty | the vendor natural key was already true in the data |
| `DOD_ORDER GROUP BY STATUS` | `CMP` 383 · `PEN` 101 · `VCN` 1 | no `DRAFT` anywhere — the create-script's default provably never applied |
| `DOD_ORDER WHERE TENANT_ID IS NULL` | **0** | नियम-1 scoping is never NULL in practice |

**Consequences.** (1) **"Backfill" and "invent" were two different jobs**: the migration had to INVENT
485 numbers, not copy them — the hand-run backfill answered `Changed: 0` because it was copying NULL
into NULL. (2) What a customer saw was not NULL but the literal `"000"`, so minting numbers could not
break an external reference — which is why part 4 was safe rather than a data rewrite. (3) The hole
reopens unless the legacy funnels mint too (**S8b**). (4) 462 vendor rows cover at most 462 distinct
orders, so **at least 23 orders have no vendor row** and are invisible to the vendor channel by
construction; the D14 assembly must write one row per distinct vendor.

## 4. Target shape and load order

Nine files, and the order is load-bearing: **`nst-bl-ordh` → `nst-bl-orditm` → `nst-bl-vordh`** (the
header's `delete!` calls the line लोप helper; every line verb calls the header's select; the vendor
verbs call the header's reader), with each `*-api.lisp` after the BL file whose verbs it registers
(D12 — a binding that precedes its registration is refused at LOAD time, so the app does not come up).
Both build lists carry all nine; the per-file map is in §0.

## 5. OPEN

| # | Item | Recommendation |
|---|---|---|
| **O1** | ~~The `DOD_VENDOR_ORDERS` dump~~ — **CLOSED 2026-09-27.** The drift is measured (26 declared / 60 live, 34 missing, zero phantom columns) and the class decision is made: `nst-vordh` gets its own class and the legacy one is left alone (S9). | Resolved; the only residue is the data question in §9 item 1. |
| **O2** | **Re-pointing the five existing row-id guards at the new `nst-row-id-from-string`.** | **Not in this batch.** Each sits in a different loading-sensitive domain file, and a mechanical re-point across five domains is its own commit with its own build/load proof. Ledger it in `PENDING-WORK-CONTEXT.md` when S0b lands. |
| **O3** | **The partial-write window on `POST /orders`** (D14). | Document as a KNOWN; assert in the suite that a refused line leaves a header (i.e. make the gap VISIBLE and measured rather than assumed harmless). If you want it fixed here, say so — it is a change to the seam all ~40 bound endpoints share. |
| **O4** | **Does `DELETE /orders/{ordnum}` exist for a customer?** | Yes for a **`DFT`** order by its own customer (D8, corrected by S5 — not "an open order": `PEN` is a placed order). The spec defines no order DELETE, so this is an addition — the invoice precedent is the opposite (`route-invh-delete` registered but unbound, because GST forbids deleting an issued invoice). An order has no such legal bar **before** invoicing; after `IS_CONVERTED_TO_INVOICE = 'Y'` it should refuse with a contradiction, like an issued invoice. |

---

## 6. Stories — one entry each: what it is · its AC · the verdict · the trap it paid for

**⚠ The narrative that used to fill this section is in `archive/order-adhara-stories-NARRATIVE-2026-10-04.md`** (2127 lines) — the row counts, the failed first attempts, the fixes that were wrong before they were right. The entries below are the same verdicts compressed to what a session needs in order to START work.

### S0 — measure the live schema · ✅ CLOSED 2026-09-27
`dod-order` (58 declared / 58 live) and `dod-order-items` (30 / 32, the two omitted being the DB-managed timestamps) were exact and are reused as-is; `dod-vendor-orders` declared 26 columns against 60 live, which is why the vendor entity got its own class (S9). **Trap it paid for:** §1 — `installation/hhubplatform.sql` is FICTION for these tables, and believing it produced three wrong design decisions. **Deliverable: §1 and §3, which are the reason to measure `SHOW CREATE TABLE` first.**
### S0b — the identity migrations · ✅ APPLIED 2026-10-03
`DOC_PREFIX varchar(8)` on `DOD_CUST_PROFILE` plus its allocator; the **mint of 485 order numbers** (`ORD-<PREFIX>-<FY>-<REF>`, where `REF` is a keyed permutation of an atomic counter — F1's non-enumerability decision); the 462-row vendor backfill; and three unique keys LAST, so they validate the backfill rather than decorate it (`uk_ordnum` GLOBAL on `DOD_ORDER`, `uk_cust_doc_prefix`, `uk_vo_order_vendor`). **Verdict, counted 2026-10-04: 0 NULL `ORDNUM` on both tables, all distinct. Traps:** "backfill" and "invent" were two different jobs, and one paren mis-scope made a *local* function report as a missing *global* one (`undefined function ADD-INDEX` at the call site). **Tool:** `nst-verify-doc-numbering.lisp`.
**Rulings (R1–R4, which the entries below refer to):** the column is **`DOC_PREFIX varchar(8)`**, uppercase `A-Z0-9`, stored **bare** — never `char`, which pads a space into every document number; **allocation de-duplicates** by a ladder (8 chars, then 6+2, then 5+3) because derivations collide (`XYZ Corp Ltd` and `XYZ Corporation` both yield `XYZCORP`); an override is **REFUSED** once any document carries the prefix (R3); and **the counter table lands in this batch** (R4), because the mint cannot be built without it.
### S0c — the document-number vocabulary · ✅ APPLIED
`DOD_DOC_COUNTER` (the counter `{counter}` never had), `DOD_SYS_SECRET.DOC_REF_KEY`, `nst-format-doc-number` and the tokens `{prefix}` `{fy}` `{ref:N}` `{counter:N}`, plus `order-number-format`. **Trap:** MySQL 8 RESERVES `LAST_VALUE`, so the column is `LAST_SEQ` and every identifier in both hand-written SQL copies is backticked. A second, latent one: the FY label destructured SIX values from a DATE struct that returns FOUR — a crash on the invoice path, reached only when the caller omits `:finyear`.
### S0d — `DOC_PREFIX` on the customer, end to end · ⚠ PART DONE 2026-09-28
The ENTRY half is done: the slot on `nst-customer`, its response model and the `dod-cust-profile` view class, both copiers, the render allowlist, `docPrefix` published in the customer JSON, and **two contradiction guards** (R1's charset; R3's freeze once any document carries the prefix). **NOT recorded as done: the profile-page override input** (S0b owns the DDL, S0d the page).
### S0e — the cross-cutting requirements · a filter, not files
It exists so that no finding in §10 is silently dropped: every one is either implemented at a NAMED site or accepted in writing. **Moved to `knowledge/order-standards-review-CONTEXT.md` (§S0e).**
### S1 + S2 — the two islands · ✅ DONE
`nst-ordh` and `nst-orditm`: entities, boundary models, `*…-mirrored-slots*`. No new ORM classes (D9) — the live tables matched the existing ones exactly.
### S3 — the header's `?exists` + `make` · ✅ DONE
The mint through `nst-order-number-for`, `STATUS` forced `DFT`, `is-converted-to-invoice` / `is-cancelled` / `order-fulfilled` forced `"N"`, `CREATED_BY_USER_ID` from the session (F11), and the idempotency key on `:context-id` (F6).
### S4 — `fetch` + `enumerate` · ✅ DONE
Scoped to the session customer (D5), paged per F7 (default 50, hard cap 200 — a larger `:limit` is **CAPPED, not refused**), sorted only by the whitelist, with the 400 living in the ROUTE so a mistyped parameter is not a 500.
### S5 — `!update` + `delete!` · ✅ DONE
The field policy: `*ordh-never-writable-fields*` and `*ordh-internal-only-fields*` are REFUSED (409), not stripped, because a refusal makes an attempted escalation visible. **`delete!` is `DFT`-only, NOT open-only** — a `PEN` order is a *placed* order whose vendor rows would be orphaned. Control keys are consumed BEFORE the field policy (the S12 defect: otherwise every `If-Match` update answers 409).
### S6 — the reverse ferry, `render-json`, the mirror check · ✅ DONE
The response is a per-field ALLOWLIST, never the entity. **Trap (T4): the mirror list drives THREE consumers** — the reverse ferry, the domaintodb copier, and the check — and the invoice's "nothing else needs to change" claim is how a missing slot made every route answer 500. **Tool:** `nst-order-mirror-check.lisp`.
### S7 — the line entity · ✅ DONE
Six प्रत्यय plus the लोप cascade the header's `delete!` calls. **Every verb proves its parent through ONE function** (`nst-fetch-visible-order-header`), because `DOD_ORDER_ITEMS` has NO foreign key on `ORDER_ID` — measured, not assumed. `!update` refuses `:order-id`; the ROUTE verifies the pairing and then strips it.
### S8 — the status vocabulary gets one home · ✅ DONE
`*order-open-statuses*` (`DFT`,`PEN`) and `*order-terminal-statuses*` (`CMP`,`VCN`,`CCN`) live in `core/dod-bl-utl.lisp` with their predicates, and **seven legacy reads stopped testing the literal `"PEN"`** — an order created by the new API had been invisible to every legacy list and count.
### S8b — stop the legacy funnels recreating the hole · ✅ DONE
`persist-order` and `persist-vendor-orders` — the single choke points for legacy-created orders and vendor rows — now mint the `ORDNUM`. Without this, the S0b mint's hole reopens on the first legacy-placed order.
### S9 — the vendor island · ✅ DONE
`dod-vendor-order` over **60/60** live columns, `nst-vordh` (56 slots), its response model and `*vordh-mirrored-slots*`; the legacy class is untouched (V1). **Trap:** T9 is VENDOR-ONLY — `DOD_VENDOR_ORDERS.ORD_DATE` is a `timestamp ON UPDATE`, so `(string 30)` and a whole-row write are required (V5). **Tool:** `nst-vordh-mirror-check.lisp`.
### S10 — the vendor's six प्रत्यय · ✅ DONE
Triple-scoped on every read (`VENDOR_ID` **and** tenant **and** `DELETED_STATE`), whole-row writes, the four writable fields of V8, and a terminal status refused (AC g — 387 of 466 live rows are `CMP`, so this is the common case, not a corner). `ORDNUM IS NULL` answers 404 structurally, never a guess.
### S11 — the three vendor routes + bindings · ✅ DONE
`GET`/`GET {ordnum}`/`PUT {ordnum}`; the assembly rewired to `(make 'nst-vordh …)` and the interim writer DELETED (one writer for one row); `{ordnum}` + session vendor resolved by `vordh-row-from-url`, which returns **one 404 for every way of failing** so no 403 confirms another vendor's row.
### S12 — the customer routes + the D14 assembly · ✅ DONE
`POST /orders` writes header → lines → stock → one vendor row per distinct vendor, and the **partial-write window is KNOWN, not papered over** (no transaction seam). **Trap:** the route must strip `:order-id` AFTER verifying the pairing — a verb guard that refuses the key its own address carries refuses every legitimate request, which the invoice batch measured on the identical shape.
### S13 — the ten bindings · ✅ DONE (+ live sweep 2026-10-04)
Seven customer paths and three vendor paths, each binding below its own registration (a binding that precedes its registration is refused at LOAD time, i.e. the app does not come up). **AC (a) proven live:** the seven customer paths answer 401 unauthenticated and the two deliberately unbound item shapes answer 404 `no_such_endpoint`; `/vendor/orders` and `/orders` do not shadow each other.
### S14 — the ABAC seeds · ✅ APPLIED 2026-10-04
Ten policy + transaction pairs, one per BOUND endpoint, and the ten policy functions they name. **Traps:** seven of ten `DESCRIPTION`s exceeded `varchar(100)` — on a STRICT server that is **Error 1406, and `apply-migrations` CONTINUES without recording the version**, leaving a seed that re-runs forever; and all ten `POLICY_FUNC`s initially named functions that did not exist, which would have DENIED every call the day the PEP lands. **Tool:** `nst-verify-abac-seed.lisp`. ⚠ The rows are CARRIED, not enforced (D18/F3).
### S15 — build registration and the offline load · ✅ DONE 2026-10-04
The nine files in BOTH lists, the driver's `Failed: 0` with `1+148+0 = 149`, and the offline load reaching `STAGE: LOADED`. **Trap:** the driver's handler wraps the LOAD as well as the compile, so one recompiled file reported **119 style warnings of which 6 were real** — read `Compiled`/`Skipped`/`Failed`, never `Style Warnings`. **Tool:** `nst-compile-production.lisp`.
### S16 — the four smoke suites · ⏳ IN PROGRESS (AC (a) PROVEN 2026-10-05)
**✅ AC (a) IS PROVEN: the API created its first order.** `POST /orders → 201`, `rowId 497`, `ORD-DEMO-2026-27-SFTR3E` — the minted number matching the documented shape — followed by the F6 idempotency replay answering **the same rowId**, the order reading back by its number, an empty cart refused `400`, a product that is not this tenant's `404`, `PUT 200`, `DELETE 200`, and the row invisible afterwards. **Header suite: 44 PASS / 0 FAIL / 1 SKIP.**
**Also proven live:** the vendor suite (30 / 0 / 1 KNOWN — AC (c) in ONE session, AC (e) with a manufactured NULL-ORDNUM row, AC (g) on `CMP` and `VCN`, AC (f)'s `ORD_DATE` byte-identity), and the header suite's whole read half (sweep, reads, guards, status gates, F5's field half, 412, BOLA with no existence oracle). **⚠ STILL OPEN:** the items suite (written, not run), the consolidated suite (not written), O3's window, and the `UPDATED`/F8 defect below.
**🚨 THE FOUR DEFECTS S16 FOUND — and the fact they shared: THE CREATE HAD NEVER ONCE WORKED.** (1) `ordh-nested-param` tested body keys for **strings** while cl-json yields **symbols** → every `POST /orders` was a 400. (2) The three domaintodb copiers read **unbound** slots → a 500, after the number was minted. (3) **90 entity slots had no initform** → the vendor-row builder signalled (the HTTP ctx has `:ACTOR NIL`). (4) `nst-vendor-order-insert` returned `bind-generated-row-id`'s value — the id **STRING** — instead of the entity, so the assembly answered `"471"` and `render-json` (no method for a string) 500'd **after a fully successful write**. Fixed by `nst-db-slot-value-from-domain` (`core/dod-bl-utl.lisp`), the 90 initforms, a symbol-key comparison, and the one-word return. **Every one was found by RUNNING, never by reading** — and each was invisible from the BL. **Tool:** `nst-verify-order-create.lisp` (23 checks, mutation-tested).
**TWO CASCADE FACTS, both measured in the same run:** the header's `delete!` **does** cascade to its LINES (S7's लोप — every line of the deleted order was `DELETED_STATE='Y'`), and it **does not** cascade to the VENDOR rows, which is §0's long-standing open item, now with a live reproduction. The header suite asserts the first and prints the second. **⚠ AND ONE DEFECT WAS THE SUITE'S OWN:** its lifecycle cleared the cleanup key after the API's DELETE, but that DELETE is a **soft** one — the rows are still in the table — so the SQL hard-delete never ran and every `--write` run left its order, line and vendor row behind. Fixed: the key is kept and the physical removal is `restore_rows`' job, by row-id, on the success path exactly as on the failure path.
⚠ **`UPDATED`/F8 is KNOWN**: the write freezes `UPDATED`, so the vendor ETag never changes and `If-Match` cannot detect a concurrent write — `PENDING-WORK §10`.
### S17 — the `invoice (ord ctx)` compound verb · ⛔ OUT OF THIS BATCH
What the batch unblocks. Blocked on D14's atomicity seam and the invoice-side `create-with-lines` gap.

## 7. Traps carried forward

| # | Trap | Why it applies here |
|---|---|---|
| **T1** | **A binding must follow its registration in load order.** `register-api-route` refuses a path whose action route is not registered yet, raised at LOAD time from the fasl. `compile-file` cannot see it and a name-level audit answers "yes". | Ten bindings across three api files. `nst-binding-order-check` is the static stand-in. |
| **T2** | **An integer for a decimal column fails the INSERT** and surfaces as `:U` (503) "the database call did not answer". Two separate fixes were needed: `0.0` initforms for the OMITTED field and coercion in the domaintodb copier for the SUPPLIED one. ⚠ The guard's first version silently never fired because CLSQL's declared type is the compound `(OR NULL FLOAT)`. | Both order tables are full of `decimal(15,2)`. |
| **T3** | **`DELETED_STATE char(1) DEFAULT NULL`** — both states (SQL NULL and `"N"`) occur in the data. `[= "N"]` alone hides rows; `[= … nil]` renders literal `= NULL`, true for no row. | Use `[is … nil]`, or the predicate in D17. |
| **T4** | **A mirror list drives three consumers, not two** (two copiers AND `domain->response`). The invoice's own comment claimed "nothing else needs to change" — that claim is how `deleted-state` came to be missing from the response model, and every route answered 500. | D15 / S6. |
| **T5** | **A new domain silently breaks the legacy DDD layer sharing its package and process.** `nst-bl-invh` defined `select-invoice-header-by-invnum`, a name the legacy `nst-bl-ihd.lisp:21` already used with a different signature; the new file loaded later, won, and took the vendor invoice page down. | `order/*` is dense with generic names: `create-order`, `update-order`, `delete-order`, `get-order-by-id`, `get-vendor-order-instance`, `copyorder-domaintodb`. **Check before adding a defun**; prefix every new helper with `nst-`. |
| **T6** | **Class definition can wedge the live image.** An in-image load that errors inside `ensure-class` parks a worker in the debugger holding SBCL's PCL global mutex; afterwards nothing can define a class or a struct, and only a restart recovers. | S15: restart, don't `load`. |
| **T7** | **`api-status-for-condition` has no 409 case**, so any 409 a client sees is sentinel-derived, and any unclassified condition arrives as a 500 wearing the same `internal_error` code a real crash wears. | A malformed payload must be refused in the ROUTE layer with `api-client-error` (400) where the contract says 400. |
| **T8** | **A create-script in the tree is not the schema.** §1 is the whole story: believing `hhubplatform.sql` produced three wrong decisions and one retracted proposal, in one sitting. | Measure the live table (S0), always. |
| **T9** | **`DOD_VENDOR_ORDERS.ORD_DATE` is `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`** — so **any** update to a vendor row rewrites the order date to `now()`, silently, unless `ORD_DATE` is *explicitly assigned* in the same statement (an explicit assignment beats the auto-update; omission does not). Legacy `cancel-order-by-vendor` (`dod-bl-ord.lisp:330`) and `update-order` (`:313`) use `update-records-from-instance`/`update-record-from-slot` and therefore have this defect today. | This is why D21 exists. It is also a **measurable acceptance criterion**: after `PUT /vendor/orders/{ordnum}`, assert `ORD_DATE` is byte-identical to what it was before. A test that does not assert this cannot see the corruption. |

---

## 8. Definition of done for the batch

- Nine files exist, compile `failure-p=NIL`, and load in both build lists in the correct order; `compile-production` reports `Failed: 0`.
- All six प्रत्यय exist on all three entities, four Belnap states in and out; `:U` is never phrased as "not found".
- Ten bindings answer; two routes are registered and deliberately unbound.
- The mirror check passes `M/M` for all three entities and is mutation-tested.
- The `ORDNUM` unique index exists and `SHOW INDEX` proves it (S0b).
- The legacy layer recognises `DFT` as open, demonstrated by an API-created order appearing in the legacy vendor pending list (S8).
- Four smoke suites pass: read-only, and `--write` with cleanup.
- No new name collides with the legacy `order` domain. The only legacy files edited are the nine in S8, `dod-order`'s view class if the diff demands it, and both build lists.
- `PENDING-WORK-CONTEXT.md` records what this batch leaves open — at minimum O2 (the five un-re-pointed guards) and O3 if the seam is not fixed.

## 9. Input arrived — nothing is owed

Every input this section used to ask for arrived on 2026-09-27/28, and the rulings are R1–R4 in S0b: `DOC_PREFIX` does not exist (confirmed, so it was an ADD); the customer population and the four name candidates came back (25 customers, 7 with orders, all seven prefixes distinct — the de-dup ladder does not fire on existing data); `CUST_TYPE` answered the guest question (**226 of 485 orders belong to two GUEST rows**, so nearly half the minted numbers carry a synthetic prefix); and the invoice trigger is recorded as the blocker for `{prefix}` ever reaching invoices (S0b §F, out of scope here). **Still worth doing before any FUTURE mint runs:** a `mysqldump` of `DOD_ORDER`, `DOD_VENDOR_ORDERS` and `DOD_CUST_PROFILE` — allocating a prefix and minting numbers are one-way doors in practice (R3 freezes a prefix once a document carries it), so the dry run's AC comes first.

## 9b. Preflight — how NOT to discover the bugs as you go

**Read this when:** starting a story. The question behind it was *"can we know in advance, and then not need the fix at all?"* Mostly yes — and **the method lives in the tools and in `knowledge/offline-checker-methodology-CONTEXT.md`** (how a checker is proved, the four classes of checker bug, the registration rule, what no offline check can do), not in prose here. What belongs beside the stories is below.

### The four rules, in order of leverage

Measure the substrate before designing on it — most of this batch's cost came from designing on `hhubplatform.sql`, on a documented API contract and on an assumption about 485 rows, all three measurable in minutes · prefer a construction that makes the class impossible to one that detects it · use the substrate's own parser (a hand-written Lisp scanner was wrong three ways; apply the DDL, do not model it mentally) · mutation-test every checker, and assert it found its inputs.

### The registration check, and the gap it found immediately

A new `hhub/**` file needs **two** registrations — `package/compile.lisp` and `nstores.asd` — and nothing checked the second. The preflight now does, narrowly: it asserts **this batch's files** are in both and merely *notes* the rest, because the two lists legitimately differ in 13 places (an equality assertion would have cried wolf on all of them). It immediately found two pre-existing files that are **COMPILED AND NEVER LOADED** — `invoice/nst-bl-gstr1.lisp` (the whole GSTR-1 collector, which explains why it "was never run against a session": it is absent from the running system) and `order/dod-dal-otk.lisp` (a second view class for a table another file already declares). Both are in `PENDING-WORK-CONTEXT.md` §8; neither is ours.

### The tools, and when to run them

All offline — no database, no image, no build — and all exit non-zero on a finding. `nst-preflight.lisp`: before claiming a story done — delimiter balance (by the reader), SQL reserved-word quoting, build registration, non-vacuity, and the queries a human must run before a story is APPLIED. `nst-verify-doc-numbering.lisp`: the FY rule, the template renderer, the reference permutation, the fail-closed key, the counter SQL's quoting, the mirror-list/class invariants. `nst-verify-order-create.lisp`: the create's two pure halves (the nested body reader against what cl-json actually produces; the copiers against a create supplying only some fields). The rest: `nst-compile-production.lisp` · `nst-order-mirror-check.lisp` · `nst-vordh-mirror-check.lisp` · `nst-vordh-route-probe.lisp` · `nst-verify-abac-seed.lisp` · `nst-binding-order-check`. **What no offline check can do, so it stays a human step:** the three database classes in preflight §4(a)–(c) — they print on every run precisely so they cannot be forgotten.

## 10. Standards review — moved to `knowledge/order-standards-review-CONTEXT.md`

**OWASP API Top 10 · NIST 800-53/800-63B · Google AIP · RFC · WCAG · 2026-09-28 — twenty findings** (nineteen about this batch + **F20**, a pre-existing defect the review walked into). The full review — **F1–F19** with severity, standard, finding and disposition; **F1's decision record** (the sequential counter as a competitor-enumeration oracle, closed by the keyed non-sequential `{ref}`, and why per-vendor counters are structurally impossible); **F20** (live AWS SES SMTP + reCAPTCHA + data.gov.in credentials committed in `hhub/core/extkeys.lisp`); **what the design already gets right**; and **§S0e, the finding→owner map** — is now in **`knowledge/order-standards-review-CONTEXT.md`**. **Read F1–F6 before changing behaviour; read F3 before touching authorization** (the S14 policy rows are carried, not enforced — D18). **F12/F16 are still undecided** (PUT vs PATCH; whether `POST /orders` includes OTP + wallet) and are the two open questions in §0.
