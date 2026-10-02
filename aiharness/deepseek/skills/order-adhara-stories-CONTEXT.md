# Order entities on the adhara grammar — design decisions + stories · CONTEXT

**Read this when:** you are converting the ORDER header, the order line or the VENDOR
order to the Paninian (adhara) grammar — i.e. writing `nst-ordh` / `nst-orditm` /
`nst-vordh`, their प्रत्यय, their routes or their smoke tests — or you are about to build
the `order → invoice` compound verb and need to know what it waits on.

**Status:** DESIGN SETTLED 2026-09-27. **S0 CLOSED** — all three live tables are measured
against their view classes (§3) and every data question is answered (§3b). **No code
written. Nothing is blocked.** The batch's headline discovery is in §3b: **there is no order
number anywhere in the database** — 485 of 485 orders and 462 of 462 vendor rows have a NULL
`ORDNUM`, so S0b must *invent* 485 numbers, not merely backfill them. The ORDNUM design is
now specified as `ORD-<DOC_PREFIX>-<FY>-<seq>`: a **document prefix** on the customer, system
-prefilled and customer-overridable, with a global `UNIQUE (ORDNUM)`. That dissolves the
per-tenant/global conflict the first design hit — but it exposed two prerequisites this batch
must now carry: a **counter table** (`{counter}` has no backing store anywhere in the tree) and
the existing **number-format template** (`invoice-number-format`, `invoicesettings.lisp:32`),
which the prefix must JOIN as a token rather than replace. **A standards review (OWASP API Top 10 / NIST / Google AIP / RFC / WCAG) was done before the first story — §10, nineteen findings, of which F1-F6 change acceptance criteria in stories not yet written.** The rulings are closed — R1
(`DOC_PREFIX varchar(8)`, never `char`) is DECIDED, R2–R4 are taken as recommended — so **S0c is
fully unblocked and needs nothing from the database**, while S0b is writable now and only wants
its dry-run data before it is APPLIED.

---

## 0. RESUME HERE — starting 2026-09-28 15:30 IST, one story per pass

**Nothing is blocked and no code has been written.** The design is frozen; the rulings are closed
(R1 decided, R2–R4 taken); the schema is measured. What follows is the running order, and the
dependencies are real, not conveniences:

| # | Story | Depends on | Needs from the human |
|---|---|---|---|
| **1** | **S0c** — the document-number vocabulary | **nothing at all** | ✅ **DONE 2026-09-28** (see the S0c block). Only the migration still needs APPLYING. |
| **2** | **S0b** — the identity migrations (prefix column, allocation, mint, keys) | S0c | the customer-population join **before APPLYING** (not before writing) |
| **3** | **S0d** — `DOC_PREFIX` on the customer entity + profile page | S0b (the column) | — |
| **3b** | **S0e** — the §10 standards findings (**read §10 first**) | nothing | **two decisions left: F12 (PUT vs PATCH) and F16 (does `POST /orders` include OTP + wallet?)**. F1 is resolved (§10's decision record). |
| **4** | **S1, S2** — the two DAL files (`nst-ordh`, `nst-orditm`) | nothing (pure classes) | ✅ **DONE 2026-09-28** |
| **5** | **S3–S6** — the header's six प्रत्यय, ferry, render | S1, S0c | S3 ✅ **DONE**; S4 ✅ **DONE**; S5–S6 next |
| **6** | **S7** — the line's six प्रत्यय | S2, S3–S6 | — |
| **7** | **S8, S8b** — the legacy `DFT` retrofit, and the funnels that mint | S0b, S0d | — |
| **8** | **S9/S10/S11, S12–S16** — the vendor entity, routes, bindings, seeds, build, suites | everything above | one live `PEN` order as a fixture; a `mysqldump` of the three tables before S0b is APPLIED |

**Why S0c is first:** it is the only story that needs nothing — no database, no dump, no new entity
— and both the order mint *and* the invoice's own aspirational `invoice-number-format` have been
missing it. It builds the counter table and the template renderer that everything else calls.

**§10 is the standards review (OWASP API Top 10 · NIST · Google AIP · RFC · WCAG), written 2026-09-28
before the first story.** Nineteen findings; **F1–F6 change the acceptance criteria of stories we are
about to write**, so read it before S1 and settle F1/F12/F16 as decisions rather than mid-implementation.

**Two things to settle at the start of the pass, not mid-story:** R2–R4 are still vetoable until
S0b is applied (they are marked ✅ TAKEN in § S0b), and the S0c commit is deliberately
**cross-domain** — it touches `invoice/templates/invoicesettings.lisp` and
`vendor/nst-bl-vnd.lisp` — so its acceptance criterion (e) is *the invoice's existing
`invoice-number-format` renders exactly as before*. That is the guard against T5.

**Design authority / copy source:** the invoice batch, `nst-invh` + `nst-invitm`
(commits `5a0b61c`, `f018cbe`, `feb5a5f`, `e0c934e`). Its decisions and its state of play
are in `invoice-api-handoff-CONTEXT.md` — this file applies it, it does not restate it.
Generic template: `hhub/nst-adhara-GENERIC-migration-playbook.md`. Grammar:
`knowledge/WAREHOUSE-NST-GRAMMAR-CONTEXT.md`.

---

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

**Lesson to carry: measure the live table, then design.** The two ORDER view classes
turned out to be exact (§3) — the drift was entirely in the create-script. Where a
create-script and a live dump disagree, **the dump wins and the create-script is treated
as historical intent**.

---

## 2. Decisions taken (do not re-litigate)

| # | Decision |
|---|---|
| **D1** | **Scope: THREE entities.** `nst-ordh` = `DOD_ORDER` (the customer's order); `nst-orditm` = `DOD_ORDER_ITEMS` (its lines); `nst-vordh` = `DOD_VENDOR_ORDERS` (the per-vendor slice, one row per vendor on a multi-vendor order). **Deferred**: `DOD_ORDER_TRACK`, `DOD_ORDER_ITEMS_TRACK`. |
| **D2** | **Naming.** Symbols `nst-ordh` / `nst-orditm` / `nst-vordh`; models `NstOrdhRequestModel`/`NstOrdhResponseModel`, `NstOrditmRequestModel`/`NstOrditmResponseModel`, `NstVordhRequestModel`/`NstVordhResponseModel`; files `order/nst-dal-ordh.lisp`, `nst-dal-orditm.lisp`, `nst-dal-vordh.lisp`, `nst-bl-ordh.lisp`, `nst-bl-orditm.lisp`, `nst-bl-vordh.lisp`, `nst-bl-ordhapi.lisp`, `nst-bl-orditmapi.lisp`, `nst-bl-vordhapi.lisp`. `nst-ord` was rejected: one letter from the legacy `nst-dal-Order.lisp` on disk, and D16 exists to stop exactly that collision. `nst-ordv` was rejected in favour of **`nst-vordh`**, the name the requester chose. |
| **D3** | **HTTP surface.** <br>**Customer channel**: `POST /orders`, `GET /orders`, `GET /orders/{ordnum}` (aggregate, nested lines), `PUT /orders/{ordnum}`, `DELETE /orders/{ordnum}`, `PUT /orders/{ordnum}/items/{item-id}`, `DELETE /orders/{ordnum}/items/{item-id}`. <br>**Vendor channel**: `GET /vendor/orders`, `GET /vendor/orders/{ordnum}`, `PUT /vendor/orders/{ordnum}` — the live vendor family already carries `/api/v1/vendor/profile`, `/payment`, `/shipping` (`vendor/nst-bl-vndapi.lisp`), and the spec has **no** vendor-orders endpoint at all, so these paths are ours. <br>**Registered but deliberately unbound**: `route-orditm-list`, `route-orditm-fetch` (lines reach the wire through the nested `GET /orders/{ordnum}`). <br>**Out of scope**: cart endpoints (a different aggregate), `/fulfill`, `/cancel`, `/orders/batch/daily`, `/orders/calendar`. |
| **D4** | **`ORDNUM` is the address, and it is the CROSS-PARTY key.** Both channels address by it, because the vendor learns it from the customer ("the customer might send email or call the vendor and ask about the order based on the ORDNUM"). It is therefore: minted by `make` (D6), **immutable over HTTP** (stripped from every update payload, the invoice's §4b trap), and the URL-resolution step happens in the ROUTE layer (`ordh-header-from-url`), because a verb method cannot tell a number from a row-id — both are strings. ⚠ **The column is NULL on 485 of 485 existing orders (§3b), so this decision is not yet realisable in the data.** It becomes real only at S0b part 1; until then every existing order is unaddressable and the route answers 404 for all of them. |
| **D5** | **अधिकरण and scope.** Customer and vendor are **in the SAME tenant**: `:login-customer-company` is the customer row's `company` JOIN (`customer/dod-ui-cus.lisp:3603,3628`) and the customer's placement path passes that company as `DOD_ORDER.TENANT_ID` (`dod-ui-cus.lisp:2586,2619`). So नियम-1 is unchanged — tenant = session login company — and the parties are a scope **narrowing inside it**: <br>• customer session → `CUST_ID = :login-customer-id` on `nst-ordh`; <br>• vendor session → `VENDOR_ID = :login-vendor`'s row-id **on `nst-vordh`**, never on the header (the column does not exist, §1). <br>**Scope is read from the SESSION, never the payload**; an inbound `:vendor-id`/`:cust-id` is ignored, not honoured and not refused (the body-supplied-`invnum` trap). An order naming neither the session's customer nor its vendor is **404, not 403**. <br>⚠ **Inferred from code paths, not measured** — no DB access. One live `DOD_ORDER` row plus its `:login-customer-company` confirms it. **If a live row contradicts it, stop and re-open D5**, because every scope filter is built on it. |
| **D6** | **`ORDNUM` is minted as `ORD-<DOC_PREFIX>-<FY>-<REF>`** — e.g. `ORD-XYZCORP-2026-27-7K4M2Q`. `DOC_PREFIX` is a **document prefix on the CUSTOMER** (`DOD_CUST_PROFILE.DOC_PREFIX varchar(8)`, system-prefilled, customer-overridable, globally unique), intended as the identity prefix for every document that customer owns. `FY` is the short April–March form derived from `ORD_DATE` (there is **no `FINYEAR` column** on the live table); the published suffix is **`{ref:6}`** — a non-sequential, unguessable rendering (F1's decision record) of a counter scoped **per (customer, document type, financial year)**, so `ORD-XYZCORP-2026-27-7K4M2Q` rather than `...-00001`. A caller-supplied `:ordnum` is stripped. Because the prefix is globally unique, **`UNIQUE (ORDNUM)` is GLOBAL** and a number-only lookup is legitimate — orders and invoices agree in shape (`INVNUM` is global too, via its embedded row-id). **The shape is DATA, not code**: it renders through the number-format template that already exists (`invoice-number-format`, `invoice/templates/invoicesettings.lisp:32`), extended with `{prefix}`, `{fy}` and `{ref:6}` tokens and an `order-number-format` sibling key. ⚠ **Two prerequisites ride with this decision:** a **counter table** (`{counter}` has no backing store anywhere — S0b §C) and the prefix allocator. **The prefix must be ALLOCATED, never derived on the fly** — derivations collide (`XYZ Corp Limited`, `XYZ Corporation`), and a colliding prefix fails the global index. |
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

`dod-order` and `dod-order-items` were diffed **mechanically** against the dumps:

| Class | Site | Verdict |
|---|---|---|
| `dod-order` | `order/nst-dal-Order.lisp:482-751`, `(:base-table "DOD_ORDER")` | **58 declared columns / 58 live, zero drift on either side.** Reusable as-is. |
| `dod-order-items` | `order/nst-dal-OrderItem.lisp:295-481`, `(:base-table "DOD_ORDER_ITEMS")` | 30 declared / 32 live — the two omitted are `CREATED`/`UPDATED`, both DB-managed. Correct as written. Reusable as-is. |
| `dod-vendor-orders` | `order/dod-dal-ord.lisp:15-172` — bare slots, **no `:column` clauses** | 🚨 **Drifted, measured: 26 declared columns against 60 live — 34 missing, and ZERO phantom columns** (nothing it declares is absent from the live table, so its existing SELECTs do not fail; it simply cannot carry the new semantics). The 34: `ORDNUM`, `CUSTNAME`, `ORDER_TYPE`, `CONTEXT_ID`, `ORDER_SOURCE`, `IS_CONVERTED_TO_INVOICE`, `IS_CANCELLED`, `CANCEL_REASON`, `EXPECTED_DELIVERY_DATE`, `INVOICE_NUMBER`, `INVOICE_DATE`, `SHIPADDR`, `BILLADDR`, `EXTERNAL_URL`, `CREATED_BY_USER_ID`, `APPROVED_BY_USER_ID`, `PLACE_OF_SUPPLY`, `PLACE_OF_SUPPLY_CODE`, `SUPPLY_TYPE`, `TOTAL_TAXABLE_VALUE`, `TOTAL_CGST`, `TOTAL_SGST`, `TOTAL_IGST`, `TOTAL_CESS`, `TOTAL_DISCOUNT`, `TOTAL_TAX`, `GSTNUMBER`, `GSTORGNAME`, `REVERSE_CHARGE_APPLICABLE`, `EWAY_BILL_REQUIRED`, `TDS_APPLICABLE`, `TDS_AMOUNT`, `CREATED`, `UPDATED`. All were added by `migrate-2026March-modify-vendor-order-table`, which **is** registered (`core/nst-sch-mig.lisp:46`) — so the migration ran and the *class* is what lagged. `nst-vordh` gets its own class; this one is left for the legacy UI. |

**Live `DOD_ORDER` facts that shape the entity** (58 columns):
- **No `VENDOR_ID`, no `USER_ID`.** `CUST_ID mediumint NOT NULL` (FK → `DOD_CUST_PROFILE`),
  `TENANT_ID` (FK → `DOD_COMPANY`), `CREATED_BY_USER_ID` (FK → `DOD_CUSTOMER_USERS`, `ON DELETE SET NULL`).
- `STATUS char(3) DEFAULT NULL`; `PAYMENT_MODE char(3)`; `ORDER_TYPE char(4)`;
  `ORDER_SOURCE enum('POS','ONLINE','WHATSAPP','API')`; `SUPPLY_TYPE enum('INTRA_STATE','INTER_STATE')`.
- `ORDNUM varchar(50) DEFAULT NULL` — **not unique, nullable**.
- **Two address sets**: `SHIP_ADDRESS varchar(200)` + `SHIPADDR text`; `BILLADDRESS varchar(200)` + `BILLADDR text`.
- The order→invoice seam: `IS_CONVERTED_TO_INVOICE char(1) DEFAULT 'N'`, `INVOICE_NUMBER varchar(50)`, `INVOICE_DATE date`.
- Three `tinyint(1)` flags — `REVERSE_CHARGE_APPLICABLE`, `EWAY_BILL_REQUIRED`, `TDS_APPLICABLE` — plus `TDS_AMOUNT`.
- `EXTERNAL_URL varchar(2048) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci` — **the only `utf8mb3` column in a `utf8mb4` table**; comparing or joining it can raise *illegal mix of collations*.
- `DELETED_STATE char(1) DEFAULT NULL` — the T3 nullability trap applies.
- Keys: `PRIMARY(ROW_ID)`, `TENANT_ID`, `CUST_ID`, `idx_created_by_user`, `idx_gstnumber`, `idx_converted`, `idx_place_of_supply`. **`AUTO_INCREMENT=487`** — live data exists, so the suites have fixtures.

**Live `DOD_ORDER_ITEMS` facts** (32 columns):
- `ORDER_ID`, `VENDOR_ID`, `PRD_ID` all `NOT NULL`; **no FK to `DOD_ORDER`** (only `idx_order`) —
  so the "every verb proves the parent" rule (S7) is load-bearing, not belt-and-braces.
- `STATUS char(3)`, `FULFILLED char(1)`, `DELETED_STATE char(1) DEFAULT NULL`.
- Tax: **rates** `CGST`/`SGST`/`IGST`/`CESS_RATE`/`DISC_RATE`/`ADDL_TAX1_RATE` (the odd name is
  the live one) and **amounts** `CGSTAMT`/`SGSTAMT`/`IGSTAMT`/`CESS_AMOUNT`/`DISCOUNT_AMOUNT`,
  plus `TAXABLEVALUE`/`TOTALITEMVAL`, `MRP`, `UNIT_PRICE`.
- GST descriptors: `HSN_CODE`, `SAC_CODE`, `ITEM_DESCRIPTION`, `UQC`,
  `ITC_ELIGIBLE enum('ELIGIBLE','INELIGIBLE','BLOCKED') DEFAULT 'ELIGIBLE'`.
- **`AUTO_INCREMENT=1262`** — live lines exist.

---

## 3b. The DATA, measured 2026-09-27

Same session as the dumps. Six measurements, and together they close every open data question:

| Query | Result | What it decides |
|---|---|---|
| `DOD_VENDOR_ORDERS WHERE ORDNUM IS NULL` | **462 — i.e. EVERY row** (`AUTO_INCREMENT=463`, so the table holds exactly 462 rows) | 🚨 **The vendor channel's number-address works for ZERO existing rows.** `ORDNUM` arrived on this table by migration and **nothing has ever written it**. Not a corner case: "the customer quotes the ORDNUM and the vendor looks it up" fails 462 times out of 462. |
| `DOD_ORDER … GROUP BY ORDNUM HAVING COUNT(*)>1` (non-NULL) | **empty — zero duplicates** | S0b part 1 needs **no resolution pass**; the unique index can be added directly. (The refuse-loudly guard stays, because a future run must not silently assume this.) |
| `DOD_VENDOR_ORDERS … GROUP BY ORDER_ID, VENDOR_ID HAVING COUNT(*)>1` | **empty — zero duplicates** | S0b part 2 needs **no resolution pass** either, and the `(ORDER_ID, VENDOR_ID)` uniqueness legacy code already assumes is in fact already true in the data. |
| `DOD_ORDER GROUP BY STATUS` | **`CMP` 383 · `PEN` 101 · `VCN` 1 · no NULL · no `DFT`** (485 rows) | Three things: (a) **no row anywhere carries `DRAFT`** — the create-script's `DEFAULT 'DRAFT'` provably never applied, which independently confirms §1; (b) every row has a status, so S8's retrofit has no NULL-status case to survive; (c) 383 of 485 orders are already terminal `CMP`, so S8's `DFT` change touches the 101 `PEN` rows' read paths and nothing else. |
| `DOD_ORDER WHERE ORDNUM IS NULL` | **485 — i.e. EVERY order** | 🚨🚨 **THERE IS NO ORDER NUMBER IN THE DATABASE AT ALL.** Not "some legacy rows": 485 of 485 orders *and* 462 of 462 vendor rows are NULL. `ORDNUM` has never been written by anything, on any path. |
| `DOD_ORDER WHERE TENANT_ID IS NULL` | **0** | No row has an undefined tenant. This mattered while the ORDNUM series was per tenant; it still matters for नियम-1 scoping and for the routes, and it confirms `TENANT_ID` in the index shape is never NULL in practice. |
| The part-3 backfill run by hand | `Rows matched: 462  Changed: 0` | **The same fact from the other direction.** The `JOIN` matched all 462 vendor rows and set nothing, because `o.ORDNUM` was NULL for every parent. A backfill that *copies from the parent* structurally **cannot** solve this — the value it would copy does not exist. |

**Consequences — this is the batch's single biggest fact:**

1. **⚠ `ORDNUM` is not "the address" yet; it is a column waiting to be filled.** D4's decision stands, but **until S0b part 1 mints numbers, `GET /orders/{ordnum}` answers 404 for every order that exists**, and the API could address only orders it created itself. That is tolerable only because the mint ships in the same batch — it does.
2. **"Backfill" and "invent" are now two different jobs, and S0b needs both.** Part 3 copies a value that already exists (it stays, as a repair for rows the legacy funnel creates before S8b lands — and it is provably a no-op today, because it has nothing to copy). **Part 1 must INVENT 485 numbers** — a different class of change: D6's sequence rule, a deterministic assignment order, and a record of what was assigned.
3. **What a customer or vendor sees today is not NULL — it is `"000"`.** The shopcart render path sets `(ordnum "000")` (`customer/dod-ui-cus.lisp:3039`, `upi/dod-ui-upi.lisp:49`) and the confirmation template prints it (`dod-ui-cus.lisp:2494`, `%Order Number%`). So the human-readable order number today is a literal `"000"` shared by every order rendered through that path, while the persisted column is NULL. **Nothing external can break when the numbers are minted**, because no external reference to a per-order number has ever existed — which is exactly what makes part 4 safe instead of a data-rewrite risk. It is also why the address was never usable.
4. **The hole reopens by itself** unless the legacy creation funnels are taught to mint: `persist-order` (`dod-bl-ord.lisp:357`) never passes `:ordnum`, and it is the single choke point for customer-placed orders (`create-order` and `create-order-from-shopcart` both call it); `persist-vendor-orders` (`:559`) is the choke point for vendor rows. → **story S8b.**

**Consequence for `POST /orders` (D14).** 485 orders exist and 462 vendor rows — and those
462 form at most 462 distinct orders (zero duplicate pairs), so **at least 23 orders have no
vendor row at all** and are therefore invisible to the vendor channel by construction. The
assembly must write one row per distinct vendor or the same hole opens for every order the
new API creates.

---

## 4. Target shape

```
order/nst-dal-ordh.lisp       nst-ordh + NstOrdhRequestModel + NstOrdhResponseModel
order/nst-dal-orditm.lisp     nst-orditm + its two boundary models
order/nst-dal-vordh.lisp      nst-vordh + its two boundary models
order/nst-bl-ordh.lisp        the six प्रत्यय, copy helpers, domain->response, render-json
order/nst-bl-orditm.lisp      same, plus the child लोप helper the header's delete! calls
order/nst-bl-vordh.lisp       same, scoped by the session vendor
order/nst-bl-ordhapi.lisp     Tier-2 action verbs + register-action-route + the 5 customer bindings
order/nst-bl-orditmapi.lisp   same + the 2 item bindings
order/nst-bl-vordhapi.lisp    same + the 3 vendor bindings
hhub/package/compile.lisp     + the nine files, DAL → BL → headerapi → itemapi → vordhapi
hhub/nstores.asd              + the same nine, same order
installation/upgrades/nst-dbu-ordnum-identity.lisp      (S0b — the ORDNUM migration)
installation/upgrades/nst-dbu-ordapi-policy-transaction.lisp  (S13)
hhub/test/smoke-order-header-api.sh   the header's own suite
hhub/test/smoke-order-items-api.sh    the line's own suite
hhub/test/smoke-order-vendor-api.sh   the vendor channel's suite
hhub/test/smoke-order-api.sh          the consolidated suite
```

**Load order is load-bearing four times.** The three `nst-bl-*` files reference each other
(the header's `delete!` → the item लोप helper; every item verb → the header's select and
status helper; the vendor-order verbs → the header's reader), so the order is
**`nst-bl-ordh` → `nst-bl-orditm` → `nst-bl-vordh`**, exactly as `nst-bl-invh` precedes
`nst-bl-invitm`; the price is one expected undefined-function style-warning. Each api file
must follow the BL file whose verbs it dispatches (D12).

---

## 5. OPEN

| # | Item | Recommendation |
|---|---|---|
| **O1** | ~~The `DOD_VENDOR_ORDERS` dump~~ — **CLOSED 2026-09-27.** The drift is measured (26 declared / 60 live, 34 missing, zero phantom columns) and the class decision is made: `nst-vordh` gets its own class and the legacy one is left alone (S9). | Resolved; the only residue is the data question in §9 item 1. |
| **O2** | **Re-pointing the five existing row-id guards at the new `nst-row-id-from-string`.** | **Not in this batch.** Each sits in a different loading-sensitive domain file, and a mechanical re-point across five domains is its own commit with its own build/load proof. Ledger it in `PENDING-WORK-CONTEXT.md` when S0b lands. |
| **O3** | **The partial-write window on `POST /orders`** (D14). | Document as a KNOWN; assert in the suite that a refused line leaves a header (i.e. make the gap VISIBLE and measured rather than assumed harmless). If you want it fixed here, say so — it is a change to the seam all ~40 bound endpoints share. |
| **O4** | **Does `DELETE /orders/{ordnum}` exist for a customer?** | Yes for an **open** order by its own customer (D8). The spec defines no order DELETE, so this is an addition — the invoice precedent is the opposite (`route-invh-delete` registered but unbound, because GST forbids deleting an issued invoice). An order has no such legal bar **before** invoicing; after `IS_CONVERTED_TO_INVOICE = 'Y'` it should refuse with a contradiction, like an issued invoice. ⚠ **S5 CORRECTED THIS: not "an open order" but a `DFT` one** — `PEN` is a placed order, and only `DFT` is deletable. |

---

## 6. Stories

One commit-shaped unit each. "AC" = demonstrated before the story closes.

### S0 — Measure the live schema *(CLOSED 2026-09-27)*
**Result:** §3. Two classes exact, one drifted, four design errors found in a create-script
that had been believed (§1). *Retained as a story because the lesson is the deliverable.*

### S0b — The identity migrations (`ORDNUM` minted, its unique key, the vendor natural key)
`installation/upgrades/nst-dbu-ordnum-identity.lisp`, registered in `*migrations*` as
`("27092026-ordnum-identity" migrate-2026Sep-ordnum-identity "…")` — the registry's
`ddmmyyyy-slug` convention (`core/nst-sch-mig.lisp:44-71`), invoked by `(funcall fn)`.
**FOUR parts, and they run in this order** — parts 1 and 3 are different jobs (invent a
value vs copy one), and the unique index is only worth anything once part 1 has produced
distinct values.

#### The mint, specified (part 1) — this is the deliverable of the design round

**The number — RE-SPECIFIED 2026-09-27 (THIRD round): a CUSTOMER DOCUMENT PREFIX.**
`ORD-<DOC_PREFIX>-<FY>-<REF>`, e.g. `ORD-XYZCORP-2026-27-7K4M2Q` for "XYZ CORP LIMITED" — where
`REF` is **not** a sequential number: it is a non-sequential, unguessable rendering of the counter,
for the reason and by the mechanism recorded in §10's F1 decision record.

`DOC_PREFIX` is a new column on `DOD_CUST_PROFILE`: a short **document prefix**, system-prefilled
from the customer's company name and **overridable by the customer**, intended as the identity
prefix for EVERY document that customer owns — procurement request, order, and whatever comes
next — not merely the order number. The example above is **26 characters**, well inside
`varchar(50)`.

**History in one line, because two designs were withdrawn here:** round 1 said
`ORD-<FINYEAR>-<seq>` and broke, because a per-tenant series cannot satisfy a global unique key;
round 2 said a 3-character `CUSTCODE` and would have collapsed under collisions. This round
generalises the same insight — *the identity must come from the document's owner* — to a longer,
human-editable prefix, and both earlier failure modes are addressed below.

**⚠ `varchar(8)`, NOT `char(8)`.** The request said "a char of say 6-8 chars", and `char(8)` pads
with **spaces**: a stored `XYZCORP` read back from `char(8)` is `"XYZCORP "`, and that trailing
space would land **inside every document number** (`ORD-XYZCORP -2026-27-...`). Store
canonicalised (uppercase, `A-Z0-9` only, bare) in a **`varchar(8)`**.

**⚠ SYSTEM-PREFILLED IS NOT THE SAME AS DERIVED.** The prefill is a *derivation*
("XYZ CORP LIMITED" -> `XYZCORP`) and derivations collide — `XYZ Corp Limited` and
`XYZ Corporation` both give `XYZCORP`. Because the field is STORED, the prefill is therefore an
**allocation with de-duplication** (R2), and once stored it IS the identity: the customer may
override it (R3), but nothing ever re-derives it.

**B — THE COLLISION THAT MATTERS MOST: a number-format template ALREADY EXISTS.**
`invoice-general-settings` already carries
`(invoice-number-format "INV-YYYY-MM-{counter}")` (`invoice/templates/invoicesettings.lisp:32`) —
a per-**VENDOR** setting (the blob lives on `DOD_VEND_PROFILE.INVOICE_SETTINGS`) with `YYYY`/`MM`/
`{counter}` tokens, validated against `vendor-settings-sections`
(`vendor/nst-bl-vnd.lisp:1032,1148`). -> **Do NOT invent a second numbering mechanism.** Add two
tokens to that existing vocabulary — `{prefix}` (the CUSTOMER's `DOC_PREFIX`) and `{fy}` (the
April-March short form) — and give orders a sibling key `order-number-format` defaulting to
`"ORD-{prefix}-{fy}-{counter:5}"`. Then the **shape is data**, one mechanism serves orders and
procurement requests alike, and the two ownership levels stop competing: the SHAPE is the vendor's
setting, the PREFIX is the customer's field. (No procurement-request entity exists yet in the tree
— only the paninigrammar design docs mention `pr` — so orders are the first consumer and the
mechanism must be built for reuse, not for orders.)

**C — THE COUNTER PROBLEM, which the template exposes and both earlier rounds missed.**
`{counter}` has **no backing store: no counter or sequence table exists anywhere in the tree**
(checked, including `installation/upgrades/`). The reason the invoice template is aspirational is
that a MySQL trigger owns its number instead: `before_insert_invoice`
(`installation/nstdbtriggers.sql:4-9`) **overwrites** `INVNUM` on every insert as
`concat('NST', lpad(next_id,5,'0'), '-', year(now()))` — reading the TABLE's `auto_increment`, and
using the **calendar** year rather than the financial year.

And with a **user-editable template you cannot recover the next counter by parsing existing
numbers**: the prefix may itself contain digits, the tokens may be reordered, and `{counter:5}`
padding is cosmetic. So `max(existing)+1` — the mechanism BOTH earlier rounds rested on — is **not
reliable once the format is data**. The honest answer is a small **counter table**
(`DOD_DOC_COUNTER`: doc-type, tenant-id, customer-id, finyear, last-value) with an atomic
increment, or `SELECT ... FOR UPDATE` inside the mint transaction.
-> This **supersedes** the earlier "retry on duplicate key, 5 times" concurrency design: a counter
row makes allocation deterministic and race-free, and the unique index drops from being *the*
mechanism to being a **backstop**. It is also the missing piece the invoice settings already need —
`nst-dal-invh.lisp:85` says the invoice number "SHOULD follow
invoice-general-settings' invoice-number-format", and nothing implements that today.

**D — where the prefix is allocated.** "Prefilled by the system" has no free home: **at least six
places create a customer row** (`customer/nst-bl-Customer.lisp:866,893,1310,1333` — the last is the
GUEST path — and `customer/dod-ui-cus.lisp:1594,2705`), and MySQL cannot derive it in a column
DEFAULT. Recommend: the allocator lives with the counter family (below), is called by the grammar's
customer `make` (`nst-bl-Customer.lisp:561` — the one funnel for every grammar-path creation), the
migration backfills every existing customer, and **NULL is a legal state** that the allocator fills
on first use. That leaves the six legacy sites untouched without inventing a second rule.

**CONFIRMED ABSENT 2026-09-27:** the requester verified that **no such column exists on
`DOD_CUST_PROFILE` today** — so this is an ADD, not a reconcile, and the name is settled before
anything depends on it.

**E — the footprint on the already-migrated customer entity.** `nst-customer` is already on this
grammar, so `DOC_PREFIX` is a **~5-place** change and the override needs **no new verb**: the class
slot and the response-model slot (`customer/nst-dal-Customer.lisp`, view class at `:797`), the two
copiers (`nst-bl-Customer.lisp:676,687`), and the render allowlist (`:661`/`:668`) — the
field-complete copier pair being precisely the thing whose drift produced the invoice's
MISSING-SLOT 500 on every route. The **override** rides the existing `!update 'nst-customer`
(`nst-bl-Customer.lisp:622`). The **profile page** is `customer/templates/customerprofile.html`:
display the prefix, add the override input, and apply the warehouse form's lesson (a hidden `id`,
so the row-id survives the POST).

**F — the invoice trigger is the blocker for "any other document".** If `{prefix}` is to appear on
invoices, `before_insert_invoice` must be retired or rewritten: it OVERWRITES `INVNUM` on every
insert, so the application cannot set it; it uses the calendar year; and it is currently the ONLY
source of `INVNUM`'s uniqueness. **Out of scope for the orders batch** — but it is the single
prerequisite for the prefix reaching the invoice family, and it deserves its own change.

**RULINGS — R1 is DECIDED, and R2-R4 are TAKEN AS RECOMMENDED (2026-09-27), each vetoable until
the migration is applied.** The requester confirmed the same day that **the column does not exist
yet**, so the name is free to settle now rather than becoming a rename later:

| # | Question | Recommendation |
|---|---|---|
| **R1** ✅ **DECIDED** | Name, charset, length and stored form of the column. The requester proposed a *document prefix* and then also accepted `CUSTCODE`. | **`DOC_PREFIX`** — kept over `CUSTCODE` because the field prefixes DOCUMENTS of every type (procurement request, order, and whatever comes next) rather than identifying the customer, and the number template will reference it as the `{prefix}` token; `CUSTCODE` would read as an entity key and invite precisely the conflation this field exists to avoid. **`DOD_CUST_PROFILE.DOC_PREFIX varchar(8)`**, uppercase `A-Z0-9` only, stored bare (no separators, no padding) — see the `char(8)` trap above. Refuse blank, and refuse anything shorter than 3 characters. |
| **R2** ✅ **TAKEN** | The de-duplication rule when two customers derive the same prefix. | Base = first 8 alphanumerics; if taken, truncate to 6 and append a 2-digit probe (`XYZCOR01`, `XYZCOR02`, ...); if those are exhausted, 5 + 3. Always inside the 8 characters, always recognisable, always deterministic given allocation order. |
| **R3** ✅ **TAKEN** | May the customer override the prefix once documents exist? | **No** — refuse with a contradiction once any document carries it. Minted numbers stay valid either way (each embeds the prefix it was minted with), but a change silently breaks every lookup-by-prefix and leaves the customer's current prefix disagreeing with their own history. |
| **R4** ✅ **TAKEN** | Does the counter table land in THIS batch? | **Yes** — the order mint cannot be built without it, and it is the same missing piece the invoice settings already need. One small table plus its allocator, and it retires the retry loop. |

**Edge case — the customer whose name yields nothing.** `DOD_ORDER.CUST_ID` is **`NOT NULL`**, so
every order has a customer to draw a prefix from. The live edge case is a customer row whose name
columns are all NULL or empty: the allocator must **refuse loudly** rather than invent a
meaningless prefix, and the migration must report which customers it could not prefix.

**Guest customers.** The guest creation path (`nst-bl-Customer.lisp:1333`) reuses **one guest row
per tenant** (phone `9999999999`), so every guest order in a tenant would share one prefix and one
series. Coherent, but it needs stating — and it needs a count (a `CUST_TYPE` count is in §9).

**Where the mint lives, and how it is shaped.** One function family in `core/dod-bl-utl.lisp`
(where the FY rule lands anyway, and which loads at build position 128 / asd 62 — before every
domain file): `nst-doc-prefix (cust-id)` -> allocate-or-read the stored prefix; `nst-next-doc-counter
(doc-type tenant-id cust-id finyear)` -> the atomic increment (R4); `nst-format-doc-number (doc-type
template prefix finyear counter)` -> the rendered string, the ONE place template tokens are
interpreted; plus the two FY labels. `make` calls the family; the migration calls it per customer
and then per document.

**The mint runs in LISP, not in SQL.** 485 rows is nothing to read, and the April–March rule
must not be re-expressed as a SQL `CASE` — that would be the second copy of a legal rule this
section exists to prevent.

**Determinism and the dry run.** Assignment order is `ROW_ID ASC` within (customer, document type,
FY), and prefix allocation is by customer `ROW_ID`, so both are reproducible. The migration has a
**read-only mode** that prints the proposed `customer -> prefix` table (with every de-duplication
it had to perform) and, per (customer, FY), the row-id and counter ranges. Dry run and real run must
agree for an unchanged table, and the prefix table is the part a human must eyeball — a bad prefix
is permanent once R3 freezes it.

**Concurrency.** With a counter row (R4) the increment is atomic, so two concurrent creates cannot
collide — the design **no longer depends on a retry loop**, which is what both earlier rounds had to
rest on while the counter was derived by scanning existing numbers. The unique indexes remain as a
**backstop**, and the mint still fails closed (a contradiction, never a silent duplicate) if one
fires, because that would mean the counter itself is wrong. **Prefix allocation is the riskier
half**: a half-allocated prefix is worse than a missing document number, so allocate and persist the
prefix BEFORE minting the number.

#### The four parts

1. 🚨 **THE MINT** (above) — 485 of 485 orders have NULL `ORDNUM` (§3b): there is no order number in
   the database at all, so this part **invents** 485 values. It now has three jobs: (a) `ALTER TABLE
   DOD_CUST_PROFILE ADD COLUMN DOC_PREFIX varchar(8)`; (b) allocate and store a unique prefix for
   every customer who has orders (R2), reporting every de-duplication it performed; (c) assign that
   customer's numbers in `ROW_ID ASC` order, scoped per (customer, FY).
2. **Unique keys** — `ADD UNIQUE KEY uk_ordnum (ORDNUM)` on `DOD_ORDER`, **GLOBAL**: the
   `(TENANT_ID, ORDNUM)` composite is **WITHDRAWN**, because the customer prefix carries the
   differentiation. Plus **`UNIQUE (DOC_PREFIX)` on `DOD_CUST_PROFILE`** (R1/R2), which is what
   makes the global order-number key hold. Both refuse loudly, naming the values, on a duplicate.
3. **The vendor backfill**: `UPDATE DOD_VENDOR_ORDERS vo JOIN DOD_ORDER o ON o.ROW_ID =
   vo.ORDER_ID SET vo.ORDNUM = o.ORDNUM WHERE vo.ORDNUM IS NULL`. All 462 vendor rows are
   NULL, and copying from the parent is *structurally* the right repair — but it is
   **provably a no-op right now** (run by hand: `Rows matched: 462  Changed: 0`, §3b) and
   becomes meaningful only **after part 1 has given the parents numbers**. Then it must report
   462 changed, and 0 thereafter. It stays as the standing repair for rows the legacy funnel
   creates before S8b lands. The join is explicit because `DOD_VENDOR_ORDERS` has **no FK** to
   `DOD_ORDER`.
4. **`DOD_VENDOR_ORDERS` natural key**: `ADD UNIQUE KEY uk_vo_order_vendor (ORDER_ID,
   VENDOR_ID)` — enforcing the invariant `get-vendor-order-instance` already assumes with its
   `(car …)`. **Never** `UNIQUE(ORDNUM)` on this table: the number repeats once per vendor by
   design (D20).

#### Acceptance criteria

(a) idempotent — a second run is a no-op for all four parts;
(b) each part reports its own row count: **485 minted** then 0, **462 backfilled** then 0;
(c) parts 2–4 refuse loudly, naming the offending values, if they ever find a duplicate;
(d) `SHOW INDEX` afterwards shows `uk_ordnum` on `DOD_ORDER` **global** (the composite shape is
    withdrawn), a **UNIQUE key on `DOD_CUST_PROFILE.DOC_PREFIX`**, and `uk_vo_order_vendor` on
    `DOD_VENDOR_ORDERS`, and **no unique key on `DOD_VENDOR_ORDERS.ORDNUM`**;
(e) **the definition of done, in counts**: `SELECT COUNT(*) FROM DOD_ORDER WHERE ORDNUM IS NULL`
    -> **0**; `SELECT COUNT(*) FROM DOD_VENDOR_ORDERS WHERE ORDNUM IS NULL` -> **0**; a customer of
    an order with no prefix -> **0**; and `SELECT COUNT(DISTINCT ORDNUM) FROM DOD_ORDER` -> **485**
    — **legitimate again**, because each number embeds its own customer's prefix. (It was NOT
    legitimate under the withdrawn per-tenant series, where two tenants' sequences overlap by
    design.);
(f) the mint is deterministic — the dry run's mapping equals the real run's for an unchanged
    table, so the assignment is reviewed before it is applied;
(g) a spot check: the lowest `ROW_ID` in a tenant's earliest financial year reads
    `ORD-<that customer's prefix>-<FY>-<6 base32 chars>`, and **every** number matches
    `^ORD-[A-Z0-9]{3,8}-[0-9]{4}-[0-9]{2}-[2-9A-HJKMNP-Z]{6}$` — the suffix alphabet is explicit and
    load-bearing (F14): digits `2-9` plus `A-Z` less the look-alikes `I`, `L`, `O`;
(h) the per-(customer, FY) report accounts for all 485 rows — the counts sum to 485, no row is
    assigned twice, and **every de-duplication is printed with both customer names**, so a human can
    see why a prefix was nudged;
(i) **the de-duplication rule is exercised end to end**: a second customer whose name derives the
    same base gets a **different** prefix (R2), a customer of the same name in a **second tenant**
    does not break `uk_ordnum`, and two concurrent mints for one customer yield two **distinct**
    numbers (R4's counter) — the regression tests for the failure this file found twice, once for
    tenants and once for derived codes;
(j) `make` (S3) mints through the same function, and the two cannot drift: the function has
    exactly one definition and the migration does **not** embed a second copy.

### S0c — The document-number vocabulary (the template the prefix joins)
**✅ STATUS: IMPLEMENTED + VERIFIED OFFLINE, 2026-09-28.** Five files, no build-list change
(all four existing files were already in both lists, and migrations are deliberately outside
them). The offline check is `aiharness/deepseek/tools/nst-verify-doc-numbering.lisp` —
self-contained, **105 checks, 0 failures, exit 0** — and every file was also compile-checked
against a HEAD control: identical outcomes, no warning naming a symbol this story added.

| File | What it carries |
|---|---|
| `installation/upgrades/nst-dbu-doc-counter.lisp` **(new)** + a `*migrations*` entry `("28092026-create-doc-counter" …)` | `DOD_DOC_COUNTER` (the store `{counter}` never had) and `DOD_SYS_SECRET`, seeding `DOC_REF_KEY` from `createciphersalt` |
| `core/dod-bl-utl.lisp` | `nst-date-ymd`, `nst-financial-year-label` (**moved here**), `-short`, `-month`, `*nst-doc-ref-alphabet*`, `nst-doc-ref-key`, `nst-doc-sql-token-safe-p`, `nst-next-doc-counter`, `nst-doc-reference`, `nst-doc-number-{values-lookup,pad,token-width}`, `nst-format-doc-number`, `nst-order-number-for` |
| `invoice/templates/invoicesettings.lisp` | `(order-number-format "ORD-{prefix}-{fy}-{ref:6}")` beside the invoice's own format |
| `invoice/nst-bl-invh.lisp` | the moved defun **deleted**, with a pointer left where it was |

**PLAN CORRECTION — measured, not assumed: `vendor/nst-bl-vnd.lisp` needed NO change.**
`vendor-settings-sections` is `(mapcar #'car *invoice-settings*)` and validates SECTIONS, not the
keys inside them, so a new key in `invoice-general-settings` is automatically legal. The earlier
plan named that file; the measurement did not.

**TWO BUGS THE CHECK FOUND (both fixed before this landed):**

1. **`nst-doc-number-token-width` answered NIL for every template** — its `(return …)` exits the
   LOOP, and a trailing form after the loop discarded the value. ⚠ The "token absent → NIL"
   expectation passed for the WRONG REASON, which is why the check now asserts four width cases
   rather than one.
2. **The acceptance criterion's own regex was wrong** — `[A-Z0-9]{3,6}` against R1's `varchar(8)`.
   `ORD-XYZCORP-…` is 7 characters, so the test that was meant to approve the format rejected it.
   `{3,8}` now, in the doc, the code comment and the check.

**AND ONE REAL DEFECT FOUND IN THE FUNCTION THAT MOVED — a latent crash in the INVOICE path.**
`nst-financial-year-label` destructured SIX values from `clsql-sys:decode-date`. Measured in this
CLSQL: a DATE struct returns **4** values `(day month year dow)`, a wall-time **signals**, an
integer **signals**. So for a DATE struct — exactly what the ORM yields, and exactly what
`nst-bl-invh.lisp:238-240` passes (`(clsql-sys:get-date)`) — `month` bound to NIL and `(>= month 4)`
signalled a TYPE-ERROR. The path is reached only when the caller does not supply `:finyear`, which
the invoice suite does, so it has never run. **`nst-date-ymd` fixes it** — `date-ymd` for a DATE
struct (verified against a December date, so a year/month/day mix-up cannot pass by luck),
`parse-datestring` for an ISO string, and a clear signal for anything else.
⚠ **After the next restart, re-run the invoice suite**: `make 'nst-invh` without `:finyear` now
COMPUTES the year instead of crashing.

**⚠ THE FIRST LIVE RUN FAILED — ON A RESERVED WORD — AND THE FIX IS IN.** The migration died on the
real database with:

```
Error 1064 / You have an error in your SQL syntax … near 'LAST_VALUE    INT NOT NULL DEFAULT 0,
CREATED       TIMESTAMP NOT NULL DEFAULT' at line 8
```

**MySQL 8.0 RESERVES `LAST_VALUE`** — it is a window function (`LAST_VALUE() OVER …`). Three things
came out of it:

* the column is **`LAST_SEQ`** now, and **every identifier in BOTH hand-written SQL copies is
  backtick-quoted**, so the next word the server claims cannot stop a `CREATE` or the allocation;
* **nothing was recorded and nothing was created:** `apply-migrations` writes the version only AFTER
  the function returns, so the failure left `DOD_SCHEMA_MIGRATIONS` untouched and neither table
  exists — **a corrected re-run is clean and idempotent**;
* the offline check now guards the class, **six checks stronger (43 total)**: it reads both source
  files and asserts every column is backtick-quoted, that no column appears unquoted, and that the
  allocation SQL and the DDL have not drifted. **Mutation-tested** — reintroducing the unquoted
  `LAST_VALUE` makes it exit **1** with three named failures, and restoring it returns 43/0.

**⚠ STILL TO DO FOR S0c, AND IT IS YOURS:** **re-run the migration** — `(apply-migrations user pass)`,
or the DDL by hand — to create the two tables and seed the key. Until then `nst-doc-ref-key` fails
closed with a clear message, which is the designed behaviour and not a bug.
`{counter}` has no backing store and the existing format is aspirational, so this story makes the
mechanism real **once**, for every document type:
- extend the token vocabulary with **`{prefix}`** (the customer's `DOC_PREFIX`), **`{fy}`** (the
  April–March short form) and **`{ref:N}`** — a **non-sequential, unguessable** rendering of the counter
  (F1's decision record), alongside the existing `YYYY`/`MM`/`{counter}`; give `{counter}` an explicit
  width (`{counter:5}`) because the padding is part of the number's meaning. **Invoices keep `{counter}`**
  (GST wants consecutive serials and the trigger owns that number); **orders use `{ref:6}`** — one
  vocabulary, two document types with opposite legal requirements;
- add the sibling key **`order-number-format`** (`"ORD-{prefix}-{fy}-{counter:5}"`) to
  `invoice-general-settings` in `*invoice-settings*` **and** to `vendor-settings-sections`
  (`vendor/nst-bl-vnd.lisp:1032,1148`), the validator that would otherwise reject the new key;
- **the counter table** (R4): `DOD_DOC_COUNTER` (doc-type, tenant-id, customer-id, finyear,
  last-value) plus its atomic allocator, in a migration registered in `*migrations*`.
**AC**: (a) a number is produced by `nst-format-doc-number` from (doc-type, template, prefix, FY,
counter) and **changing the template changes the number with no code change** — the test that
proves the shape is data; (b) an unknown token is refused loudly, never emitted literally;
(c) the counter increments atomically — two concurrent allocations never return the same value;
(d) the validator accepts the new key and still rejects an unknown one; (e) the invoice's own
`invoice-number-format` renders exactly as before, so this story changes no existing behaviour;
(f) the trigger question (S0b §F) is **recorded but not touched**.

### S0d — `DOC_PREFIX` on the customer, end to end
*(the customer entity is already on this grammar — `nst-customer` has all six प्रत्यय at
`customer/nst-bl-Customer.lisp:543-644`)*
The column and its rules, then the entity and the page:
- **the column itself is S0b's** — its migration does the ALTER and the backfill (a column, an
  allocated value and the numbers built from it are one atomic change). **S0d owns the ENTITY and
  the PAGE**, and must not touch the DDL: canonical form is uppercase `A-Z0-9`, stored bare,
  **never `char`** (it pads with spaces, and the pad would land inside every document number);
- **the five places in the migrated entity**: class slot + response-model slot
  (`customer/nst-dal-Customer.lisp`, view class at `:797`), both copiers
  (`nst-bl-Customer.lisp:676,687`), and the render allowlist (`:661`/`:668`);
- **the override** rides the existing `!update 'nst-customer` (`nst-bl-Customer.lisp:622`) — no new
  verb — subject to R3's freeze rule;
- **the profile page** `customer/templates/customerprofile.html`: display it, add the override
  input, and add the hidden `id` the warehouse form had to learn about.
**AC**: (a) the allocator is called from the grammar's customer `make` (`:561`), so a customer
created that way has a prefix with no extra step, and the six legacy creation sites stay untouched
(NULL is a legal state, filled on first use); (b) the de-duplication rule (R2) is deterministic and
stays inside 8 characters; (c) an override is refused with a contradiction once any document exists
(R3), and existing documents' numbers are unchanged by the refusal; (d) the copier pair is
field-complete — proven by the mirror-check pattern, because an incomplete copier pair is exactly
what produced the invoice's MISSING-SLOT 500 on every route; (e) the profile page round-trips:
display, override, re-display.

### S0b — PART 1 DONE (2026-09-28): the prefix rule and the format default

**Landed in `core/dod-bl-utl.lisp`:** `*nst-order-number-format*` (the shape as a code
default), `nst-doc-prefix-valid-p`, `nst-doc-prefix-tokens`, `nst-doc-prefix-base`,
`nst-doc-prefix-candidates`, `nst-allocate-doc-prefix`, `nst-doc-prefix-taken`,
`nst-doc-prefix-read`, `nst-doc-prefix-assign`. **Verified offline: the tool is now 73 checks,
0 failures** (30 of them new, all pure — no database).

**FINDING — the derivation is WORD-BASED, and the offline check is what caught it.** The first
version took the first 8 CHARACTERS of the name, which turns "XYZ CORP LIMITED" into
**`XYZCORPL`** — gibberish to the vendor reading the number aloud. The requester's own worked
example says `XYZCORP`, i.e. whole words. The rule now: the first word (truncated only if it
alone exceeds 8); then each following word while the total fits; and if the total is still under
3 characters, enough characters from the next word to reach 3 (so "A.B. Traders" → `ABT` rather
than a refusal). Both spellings in the doc's own example — `XYZ CORP LIMITED` and
`XYZ Corp Pvt Ltd` — derive `XYZCORP`, which is exactly the collision R2 exists for.

**FINDING — the de-duplication ladder needed de-duplicating.** The 6+2 and 5+3 rungs can
produce the SAME string for a base whose sixth character is a digit: `XYZCO0` yields `XYZCO001`
from both. The ladder is a heuristic either way — the `UNIQUE` index on `DOC_PREFIX` is the
guarantee — but a repeated rung wastes one and would confuse a dry run's report, so the
candidates are now `remove-duplicates`d and the check asserts the invariant.

**⚠ OPEN QUESTION THIS PART RAISED — where the ORDER number's SHAPE should live.** S0c put
`order-number-format` in `*invoice-settings*`' `invoice-general-settings`, which is a
**per-VENDOR** blob (`DOD_VEND_PROFILE.INVOICE_SETTINGS`). But an order is the CUSTOMER's
document and can span several vendors, so "the vendor's order-number format" names nothing
determinate — there is no single vendor to ask. Part 1 therefore uses a code default
(`*nst-order-number-format*`), and the key in the blob is currently **a setting that changes
nothing**. Three ways out: (a) **remove the key** — it was added hours ago and nothing reads it,
and the tree has already deleted one dead settings key (`*invoice-settings-alist*`); (b) make it
a **tenant-level** setting, which needs a tenant settings store that does not exist; (c) leave it
as documentation of the intended shape. **Recommendation: (a)**, because a customer-editable
setting that silently does nothing is worse than no setting. The shape stays DATA either way —
`nst-format-doc-number` renders whatever template it is handed.

**PART 2 DONE (2026-09-28): the migration.** `installation/upgrades/nst-dbu-ordnum-identity.lisp`,
registered as `("28092026-ordnum-identity" …)`. Five ordered steps: the `DOC_PREFIX` ALTER;
prefix allocation for the customers who have orders; the 485-number mint; the vendor-row copy
(which returned `Changed: 0` when run by hand and is meaningful now that the parents have numbers);
and the three unique keys **LAST, so they validate steps 2–4 rather than decorate them** —
`uk_ordnum`, `uk_cust_doc_prefix`, `uk_vo_order_vendor`. Every write is idempotent (only NULL
columns are touched), so a failure halfway through is finished by a re-run; MySQL commits DDL
implicitly, so a single transaction is not achievable and the header says so.

**The dry run, and why it is the same code path:** `(let ((*nst-ordnum-migration-dry-run* t))
(migrate-2026Sep-ordnum-identity))` after `(load-upgrade-files …)` — it writes NOTHING and prints
the prefix table and the number range per (customer, financial year). It renders through the SAME
`nst-order-number-for` the real run uses, with the counter **supplied rather than allocated** —
because allocating writes to `DOD_DOC_COUNTER`, and a dry run that assembled the number by another
route would be reviewing different code. The offline check asserts the two paths agree.

**PREDICTIONS FROM THE LIVE DATA, now asserted as test cases.** The requester supplied the customer
population (25 customers, 7 with orders, 485 orders between them), and the seven name→prefix pairs
are in the offline tool: `GCUST837` (216 orders), `DEMO` (206), `KND` (49), `GUEST` (10), `LGI` (2),
`CUST17` (1), `PAWAN` (1) — **all distinct, so the ladder does not fire on existing data**, and the
dry run can be read against a prediction rather than a hope. Two things the data settled:

* `LEGAL_NAME` and `COMPANY_NAME` are NULL on **all seven**, so the chain collapses to
  `legal-company-name` else `name` — and the precedence earns its keep on customer 27, whose `name`
  is the synthetic `G33us22337333444` while its legal name yields `LGI`.
* **226 of the 485 orders (47%) belong to two GUEST rows**, so nearly half the minted numbers will
  carry a synthetic prefix. Accepted and recorded: a B2C guest has no company to name.

**THE BUG ONLY THE COMPILER COULD FIND — AND THE WRONG FIX, WHICH IS THE USEFUL PART.**
The migration did not compile: the file was one paren short, reported as `READ error … end of file
… in form starting at line: 118` — the `defun` itself. A paren-depth scan confirmed one unclosed
`(`, but **hand-counting placed the missing paren at the wrong site**: it was added at the end of
the `flet`'s function-specs list, which CLOSED THE FLET EARLY. The next compile then reported the
symptom in a place that looks unrelated to the cause:

```
note: deleting unused function (FLET ADD-INDEX :IN MIGRATE-2026SEP-ORDNUM-IDENTITY)
style-warning: undefined function: COM.NSTORES.APP::ADD-INDEX      ; at the CALL site
```

i.e. a **local** function reported as a missing **global** one. The real site was line 155: the
`dolist` in step 2 was never closed, so **every form after it sat one level too deep** — which is
why a scan of the `flet` alone looked balanced and the whole file still balanced at EOF. Fixing it
needed the depth printed **per line, next to the running total**, plus removing the paren wrongly
added at 207 (net zero change, opposite directions). The lesson for every story here: *an unbalanced
file is not fixed by making the total reach zero* — the depth must be right at each form boundary,
and a mis-scoped local function is how the compiler tells you it is not.

⚠ **AND THE FIRST COMPILE ALSO PROVED THE IMAGE WAS STALE.** The requester's attempt reported
`undefined function: NST-DOC-PREFIX-BASE` / `NST-ALLOCATE-DOC-PREFIX` / `NST-DOC-PREFIX-TAKEN`,
`undefined variable: *NST-ORDER-NUMBER-FORMAT*`, and *"NST-ORDER-NUMBER-FOR is called with seven
arguments, but wants exactly five"* — every one of which is `core/dod-bl-utl.lisp` **as it was
before this batch**. The migration calls functions that did not exist until today, so **the image
must be RESTARTED (ASDF recompiles the changed files) before the migration can compile or run** —
and per the standing rule, never by loading the file into the live image.

### S8 — DONE (2026-09-28): the status vocabulary gets ONE home, and the legacy layer learns DFT

**The defect, restated because the fix is only meaningful against it:** the new API mints
`STATUS='DFT'` while **seven legacy reads tested the literal `"PEN"`** — so an order created
through the new API was invisible to every legacy list, count and view. Not a typo: a rule with
one spelling per layer.

**WHAT LANDED.** `core/dod-bl-utl.lisp` now owns the vocabulary (D17):
`*order-open-statuses*` = `("DFT" "PEN")`, `*order-terminal-statuses*` = `("CMP" "VCN" "CCN")`,
and the predicates `order-open-status-p` / `order-terminal-status-p`. Then:

| File | Retrofit |
|---|---|
| `order/dod-bl-ord.lisp` | `count-vendor-orders-pending` → the OPEN set; the three `(status (if (equal fulfilled N) …))` reads become clause-valued (`status-clause`): **the OPEN set when unfulfilled, CMP when fulfilled**; `count-vendor-orders-completed` **left alone, and labelled** (COMPLETED is the pair CMP+fulfilled Y — a cancelled order is terminal and is NOT completed, so widening it to either set would count it wrongly) |
| `order/dod-bl-odt.lisp` | three pending reads → the OPEN set; two completed reads left alone, labelled |
| `order/dod-ui-odt.lisp` | the item display gate `(and (equal status "PEN") …)` → `order-open-status-p` — without this a DFT item renders as NEITHER Pending NOR Fulfilled, i.e. two empty cells |
| `order/nst-bl-ordh.lisp`, `order/nst-bl-orditm.lisp` | **their private copies ARE DELETED** and both now read the shared lists. `*ordh-deletable-statuses*` (DFT only) stays: it answers a different question |

**⚠ THE AC (a) DEPENDENCY, STATED RATHER THAN DISCOVERED LATER.** "A DFT order appears in the
legacy vendor pending list" needs TWO halves, and S8 is only one of them: the **filters** (done —
`IN ('DFT','PEN')`) and **the rows**. The vendor list reads `DOD_VENDOR_ORDERS`, so a new order
appears there only once the vendor rows exist and carry DFT — which is **S9–S11 (`nst-vordh`) and
the D14 assembly in S12/S13**. The order-side and item-side lists are satisfied by S8 alone.

**VERIFIED — and this story has DATA, not just a source check.**
* The live vocabulary, measured across all three tables: **CMP 383 / PEN 102 / VCN 1** on
  `DOD_ORDER`, **1063 / 192 / 4** on `DOD_ORDER_ITEMS`, **387 / 72 / 4** on `DOD_VENDOR_ORDERS` —
  and **ZERO rows of DFT or CCN anywhere**, so AC (a) is reachable only after the API creates one
  (which needs the image: S16).
* **AC (b) IS MEASURED, NOT ASSERTED**: the retrofitted predicate returns the SAME COUNT as the
  literal it replaces, on every table the retrofitted reads touch —
  `STATUS='PEN'` **95/179/63** vs `STATUS IN ('DFT','PEN')` **95/179/63** for
  order/items/vendor rows, with the completed counts (383/1063/387) untouched.
* **And the membership itself**: against a five-row probe of the whole vocabulary,
  `IN ('DFT','PEN')` matches **DFT and PEN and nothing else** (1,1,0,0,0) — the code the API mints
  is inside the set the legacy reads now use, which is the point of the story.
* `nst-verify-doc-numbering.lisp` gained **section 13** (10 checks; **126 checks, 0 failures**):
  core owns both sets and both predicates; the open set is exactly DFT+PEN; both sets disjoint with
  three-character codes; **no entity file keeps a private copy**; **no read anywhere under `hhub/`
  tests STATUS against the literal PEN** (a tree-wide count — the retrofit's completion criterion);
  the six surviving `CMP` equality sites are named and counted; the item view gates on the
  predicate; and the legacy **creation** paths still write PEN (AC (c)). **Mutation-tested four
  ways**: one OPEN read reverted (2 checks fire), a private copy of the list re-introduced, the UI
  gate reverted, and the completed read widened to the terminal set — each fails with the check
  that names it, and all files were restored byte-identical.
* Preflight **PASS**, and it caught **its own gap** while doing this: the three legacy files were
  added to its change set, and `dod-bl-ord.lisp` then failed to READ — *"Package UUID does not
  exist"* — because `:uuid` was missing from the harness's dependency list. **A dependency missing
  from the harness is indistinguishable from a broken source file**, which is the lesson that
  list's own comment already stated; fixed, and all three files are now reader-checked
  (47 / 22 / 19 forms).

**NOT YET VERIFIED:** the runtime behaviour of the retrofitted clauses — CLSQL rendering
`[in [:status] *order-open-statuses*]` (the in-tree shape, already shipped in
`dod-bl-odt.lisp`'s `get-completed-order-items-for-vendor`) and every legacy page that reads it.
That needs the image and belongs to **S16**, alongside the API-side suites.

**LEDGER:** the S8 AC's own wording should be split the way the dependency note above is —
its half (a) is not reachable by this story alone. And `count-vendor-orders-completed` remains a
literal CMP+fulfilled pair by decision; if a future status means "completed" too, it must be added
there deliberately, which the section-13 count will force.

### S7 — DONE (2026-09-28): `nst-bl-orditm.lisp` — the six प्रत्यय, and the लोप cascade

**A NEW FILE, `hhub/order/nst-bl-orditm.lisp`** (29 top-level forms, registered in **both** build
lists), plus the header's `delete!` now cascading, plus **four corrections to earlier stories**.

* **EVERY VERB PROVES THE PARENT, THROUGH ONE FUNCTION** (`nst-fetch-visible-order-header`), so a
  new verb cannot invent a weaker check: `:order-id` is a caller-supplied integer, and a verb that
  trusted it would expose another tenant's lines to anyone who guessed one (OWASP API1/BOLA). The
  extra SELECT per verb is the price.
* **⚠ AND THE DATABASE WILL NOT CATCH IT, WHICH IS MEASURED RATHER THAN ASSUMED.** SHOW INDEX and
  `information_schema.KEY_COLUMN_USAGE` on the live `DOD_ORDER_ITEMS` (2026-09-28): PRIMARY
  (ROW_ID), TENANT_ID, idx_order, idx_vendor, idx_product, idx_hsn — **no unique key anywhere** —
  and exactly **ONE foreign key, TENANT_ID → DOD_COMPANY.ROW_ID**. NOTHING constrains ORDER_ID,
  VENDOR_ID or PRD_ID, so a line pointing at another tenant's order is a row MySQL stores happily.
* **The status split.** `make`/`delete!` require an **OPEN** header (`*ordh-open-statuses*` = DFT,
  PEN — the header file's list, referenced rather than copied); `!update` has **no** status gate,
  because the terminal refusal belongs to the HEADER verb (D8) and a line is reachable only through
  its header. The parent proof still refuses an invisible/soft-deleted header — the reachability
  half. Note the header's DELETABLE list (DFT only, S5) is deliberately narrower than the line
  verbs' OPEN list: the लोप helper therefore performs **no** status check, since it would be asking
  a different question and would be a second place for two rules to drift.
* **AC (d) landed as a REFUSAL**: `!update` on a line refuses `:order-id` with a contradiction —
  a line does not migrate between orders. ⚠ **AND THE ROUTE MUST STRIP IT AFTER VERIFYING THE
  PAIRING**, exactly as `route-invitm-update` does for `:invheadid`, because
  `PUT /orders/{ordnum}/items/{item-id}` carries the order in its ADDRESS: the invoice measured
  what a guard that refuses the key the URL names does — *"refuses every legitimate request —
  which is exactly what happened the first time this was written"*. Recorded here because the
  failure is invisible from the verb. **S12/S13 own that half.**
* **`?exists` is NOT an identity check, and `make` does not call it.** There is no unique key on
  (ORDER_ID, PRD_ID) and the same product twice is a legitimate order, so `:T` is a warning a form
  reads, never a refusal — the opposite of `nst-ordh`'s `?exists`, whose `:T` drives the make
  :around. `make` has no :around for the same reason (nothing to be idempotent about: a line has no
  minted identity and no dangerous repeat).

**FOUR CORRECTIONS TO EARLIER STORIES, EACH FROM MEASURING SOMETHING THAT HAD BEEN ASSUMED.**

1. **A REAL DEFECT IN S3/S5: integer money values would have failed every INSERT.** `dod-order`
   declares its money and rate columns `float`, and CLSQL VALIDATES a slot's declared type — so an
   ordinary JSON integer (`{orderAmt: 100}`) is refused by the client library and reaches the
   caller as `:U`/503 *"the database call did not answer"*. The header's `domaintodb` copier now
   widens integer→float per slot via `nst-coerce-for-db-slot`. **The invoice batch had already
   measured this and lost a day to it twice**, and reading its copier is what exposed the gap here.
2. **THE THREE COERCION HELPERS MOVED TO `core/dod-bl-utl.lisp`** (`nst-db-slot-type`,
   `nst-db-float-slot-p`, `nst-coerce-for-db-slot`), from `invoice/nst-bl-invh.lisp`: they are
   generic, they now have callers in two files, and **the order files load BEFORE the invoice's, so
   a version living there is unreachable from them**. Same symbols and package, so every existing
   call site is unchanged. (D16's argument, applied to a second rule.)
3. **THE DRIVER'S BUILD ORDER WAS WRONG AND IS FIXED.** `order/nst-bl-ordh.lisp` calls
   `nst-select-customer-by-id` (the document prefix belongs to the CUSTOMER), which
   `package/compile.lisp` compiled **after** it — an undefined-function style-warning that a cold
   build would carry forever, and one that `nstores.asd` never had because it lists the customer
   files first. The two order-adhara files now sit after `customer/nst-bl-Customer.lisp` in the
   driver too. **MEASURED RESULT: the header has exactly ONE forward reference
   (`nst-soft-delete-order-items-for-header`) and the line file has ZERO — which is AC (e), stated
   as a count rather than as an impression.**
4. **S6'S THIRD `render-json` METHOD ON `list` IS REMOVED**, and the reasoning belongs to the
   invoice's item file (`nst-bl-invitm.lisp:705-712`): the method is **ELEMENT-AGNOSTIC**, so the
   one already in the tree renders an order list correctly, and a second method with the **same
   specializers does not coexist with it** — CLOS keeps the later definition. S6's copy had an
   identical body, so nothing broke; that is luck, not design. This file and the item file now
   define neither that method nor `domain->response-list`, and the dependency (enumerate's list
   path renders through a method in `nst-bl-whsapi.lisp`/`nst-bl-invh.lisp`, both in the same
   build) is **recorded instead of hidden**.

**THE CASCADE, AND THE SENTENCE IT REPLACES.** The header's `delete!` now runs लोप on the lines
**first** and leaves the header UNTOUCHED if that does not fully succeed, reporting the tally when
the header write then fails — the invoice's measured ordering (lines → header, because a
half-finished delete with the header LIVE is reachable and re-runnable, while the reverse leaves
lines nothing can reach). ⚠ **S5's docstring said `DOD_ORDER_ITEMS`' foreign key was `ON DELETE
CASCADE` and therefore inert. THAT WAS WRONG — COPIED FROM THE INVOICE'S COMMENT INSTEAD OF
MEASURED: there is no foreign key on `ORDER_ID` at all.** Corrected in place; the true reason a
cascade is needed here is that no key exists to fire, and a soft delete would never issue the hard
DELETE that fires one anyway.

**VERIFIED — offline, and nothing else.** Preflight **PASS** (0 problems; the new file reads as 29
forms and is registered in both lists); `nst-verify-doc-numbering.lisp` **116 checks, 0
failures**; `nst-order-mirror-check.lisp` now covers **both** entities' render allowlists —
**54/54** and **28/28** setfs, `published + withheld = every slot` for each (55 and 29) — and is
**mutation-tested three more ways** for the line: a field removed from `render-json` (caught twice,
as an unpublished slot AND as a duplicated key, because that is what the mutation produced), the
withheld `deleted-state` published, and a phantom slot added to the line's mirror list (caught by
both the response-model and the entity-class check). All restored byte-identical.

**NOT YET VERIFIED:** every behaviour — the parent proof refusing another tenant's line, `make` on a
terminal order, the cascade, and `:order-id`'s refusal. All of it needs the image and the database,
so it is **S16's suite**. Nothing in the new file has executed.

**LEDGER (opened by S7):** `nst-order-item-id-from-value` is the invoice's `invitm-id-from-value`
under a third name and belongs with the row-id guard in `core/dod-bl-utl.lisp`; the live
`DOD_ORDER_ITEMS` has **no foreign key on ORDER_ID/VENDOR_ID/PRD_ID** — a schema gap worth its own
decision (an FK would make the orphan state unreachable at the engine level, but it is a migration
over 1180 live rows); and the लोप helper's read is bounded at 200 lines with that bound stated
rather than inherited.

### S6 — DONE (2026-09-28): the reverse ferry, the JSON allowlist, and the mirror check

**Added to `hhub/order/nst-bl-ordh.lisp`** — 52 → **59 top-level forms**: the withheld set, the
two render guards, `domain->response` + `domain->response-list`, and the two `render-json`
methods. Plus a new offline tool, `aiharness/deepseek/tools/nst-order-mirror-check.lisp`.
⚠ **S7 REMOVED TWO OF THOSE FORMS AGAIN** (the `render-json` method on `list` and
`domain->response-list`): both are ELEMENT-AGNOSTIC and already exist once in the tree, and a
second method with the same specializers REPLACES the first rather than coexisting with it. See
S7's correction 4.

* **`domain->response` IS LIST-DRIVEN** (mirror list → `setf` loop), the shape that took the whole
  invoice API down, and the reason the check exists. `NstOrdhResponseModel` carries **55 slots**:
  the 54 mirrored slots plus `row-id`, which the ferry sets explicitly. ⚠ The MOP read also
  returns the two slots the class **inherits from the boundary tree** — `nst-boundary-object`'s
  synthetic `id` (a uuid, NOT the row's row-id) and `nst-response-model`'s `params`. Neither is
  domain state; the check found both on its first run and they are now named in
  `*boundary-inherited-slots*` rather than filtered silently.
* **`render-json` publishes 54 keys and withholds exactly one, and THE SUM IS THE POINT.**
  `*ordh-json-withheld-slots*` = `(deleted-state)` — नियम-2's own predicate, which the invoice
  withholds for the same reason. The invoice's allowlist has **no completeness assertion**, so a
  slot added to its response model simply never leaves the system: no error, no 5xx, just a quietly
  incomplete document — the missing-slot 500's mirror image, and just as silent. Here
  `published + withheld = every slot` is asserted, so a new slot forces a decision.
* **THREE RENDER CONVENTIONS, ALL MEASURED FROM THE COLUMN DECLARATIONS** (not guessed): the three
  `tinyint(1)` flags (`reverse-charge-applicable`, `eway-bill-required`, `tds-applicable`) go
  through `nst-ordh-json-flag`, because **0 is truthy in Lisp** and the naive form reports a false
  flag as true; the **`char(1)` Y/N flags leave as the codes the column stores** — applying the
  boolean guard to them would answer T for the string `N`, the same lie one type over; the four
  DATE columns leave as `YYYY-MM-DD` via `get-datestr-from-obj-yyyymmdd` (core, loaded early
  enough to call), and the four integer ids leave as strings via `response-id-string`.
* **THREE THINGS WERE DELIBERATELY NOT REDEFINED, because they already exist and dispatch on
  type**: the domain-sentinel ferry (`nst-entity-nil/-unknown/-contradiction` →
  `nst-response-*`, `warehouse/nst-bl-whsapi.lisp:280-290`), the sentinel rendering
  (`:320-333`), and the `(eql t)` **ack** path — which is how `delete!`'s bare `T` renders at all.
  ⚠ The ack's SHAPE is universal but its class is called **`warehouse-ack-response`**, a name-level
  wart worth knowing before it is mistaken for a bug; renaming a shared boundary class is a
  shared-file change, not this story's.

**THE CHECK (`nst-order-mirror-check.lisp`, modelled on the invoice's, and stronger).**
§1 performs `domain->response`'s exact `setf` for every mirrored slot of **both** entities —
**54/54** on the header, **28/28** on the line — and reads the lists **from source**. §2 adds what
the invoice tool has no equivalent of: it reads the `render-json` alist out of the BL source,
collects the response-model slot behind each key, and asserts the sum above, that no key is
**duplicated** (most encoders keep one and silently drop the other field), and that no withheld
slot is published. **`VERDICT: PASS`.** ⚠ It found two things on its first run, both real and both
mine: the two boundary-inherited slots above, and — before them — nothing; the first FAIL was the
check being right and the check-list being wrong.

**MUTATION-TESTED FOUR WAYS**, each failing with the check that names it: a field removed from
`render-json` (`NEITHER PUBLISHED NOR WITHHELD: (COMMENTS)`), a duplicated key, `deleted-state`
published while withheld, and a phantom slot added to a mirror list (which fails **both** the
response-model and the entity-class check). Restored byte-identical afterwards.

**⚠ AN HOUR OF PAREN ARCHAEOLOGY, AND THE FIX IS A PROCESS FIX.** The new tool went through three
wrong closing parens — twice by counting a `(return nil)`'s own closer as a container — and the
failures were *misleading*: `Special form is an illegal function name: GO` (a local function named
`go` is illegal — GO is a CL special operator: **measured**, not guessed) and `return for unknown
block: NIL` (a consequence of an unbalanced `finally` line swallowing the next `defun`).
**What actually fixed it was a depth scanner validated against two KNOWN-GOOD files first** — the
invoice tool and the preflight — so that "balanced" was a claim with evidence rather than a
feeling. AND THE REAL LESSON: **a new checker must be added to the preflight's `*files*` list the
moment it exists** (done in this story). §1's reader check is what catches an unbalanced tool, and
a tool that will not load cannot run its own self-check — the same disease the list's own comment
already described.

**VERIFIED:** preflight **PASS** (0 problems; 59 forms here, the new tool reader-checked as 18);
`nst-verify-doc-numbering.lisp` **116 checks, 0 failures**; `nst-order-mirror-check.lisp`
**PASS** with the four mutations above. **NOT YET VERIFIED:** any actual JSON. No byte has been
encoded and no route has rendered — the alist is verified by reading source, not by encoding it,
which is S16's suite (and `render-json`'s list method returns TEXT, so the encoder is the one part
of this story that no offline check touches).

**LEDGER (opened by S6):** the withheld-set COMPLETENESS assertion is worth back-porting to the
invoice (`*invh-withheld-slots*` + the same check) — its allowlist can currently drop a field in
silence; `invh-json-flag` / `invh-json-timestamp` / `invh-json-date` and the order's
`nst-ordh-json-flag` / `nst-ordh-json-date` / `nst-ordh-version-token` are **three to six spellings
of three rules** and belong in `core/dod-bl-utl.lisp` (the order file loads FIRST, so it cannot
call the invoice's); and `render-json` on a `list` is now defined in **three** files with an
identical body (warehouse, invoice, order) because a `list` method cannot be specialized per
entity.

### S5 — DONE (2026-09-28): `!update` and `delete!`

**Added to `hhub/order/nst-bl-ordh.lisp`** — 31 → **52 top-level forms**: seven policy lists,
eight policy/token helpers, the update's two step functions, the soft-delete step function, and
the two verb methods.

**THE FOUR QUESTIONS, IN THIS ORDER, AND WHY.** *is there such a row* (absence first — a 404 is
about the ADDRESS, and a caller that named a row which is not there should not be lectured about
field policy) → *is it terminal* (a fact about the ROW, the most specific answer available) →
*may this channel write these fields* (a fact about the REQUEST) → *does the caller's validator
match* (a fact about TIMING). Every refusal is a returned `nst-entity-*` **before any write**, so
a refused update has written nothing.

* **F5 landed as a PARTITION, not a blacklist.** Four lists — **39 caller-writable, 3
  internal-only, 6 never-writable, 6 identity keys plus the 5 the ferry reserves** — cover the
  entity's 54 slots **exactly once**. The writable list is enumerated POSITIVELY, because an
  allowlist whose default is allow is not an allowlist; a slot in NO list becomes a check
  failure rather than a field no user can ever edit and nobody can explain.
  The per-channel half is real, not decorative: `:http` (and any unknown or NIL channel — **fail
  closed**, and a NIL channel is not hypothetical: `dod-ui-cus.lisp` builds ctx with no channel)
  may not write `:status`/`:order-fulfilled`/`:shipped-date`; `:ui`/`:agent`/`:batch`/`:scheduler`
  may.
* **STRIPPED vs REFUSED is a measured distinction, and the measurement is the invoice's.**
  `api-params-for-request` merges the path parameters and the JSON body into ONE plist, so
  `PUT /orders/{ordnum}` arrives carrying `:ordnum` — and the invoice records what a guard that
  refuses such a key did: *"refuses every legitimate request — which is exactly what happened the
  first time this was written"* (`nst-bl-invhapi.lisp:377-383`). So the identity keys are
  **STRIPPED** — which is the invoice's own *"one-line verb guard"*, and it closes the direct-call
  `:tenant-id` hole **in the verb**, where the ferry cannot reach — and only body-only keys are
  **REFUSED**, where a refusal can never hit a legitimate request and makes the attempt visible.
* **F8 landed as a string comparison against the row's `UPDATED`.** `:if-match` is a control key
  the verb consumes (`*ordh-update-control-keys*`), never an assignable field; the weak prefix
  `W/` and the quotes are stripped because they are RFC 9110 SYNTAX rather than part of the
  version (a byte-for-byte comparison would reject the validator this API had just handed out);
  the token is never parsed, so there is no date arithmetic and no timezone to get wrong.
  ⚠ **IT CANNOT RIDE THE FERRY**: `extract-domain-initargs` forwards only keys the class
  declares, so `:if-match` reaches the verb only when the ROUTE calls the verb itself. **S12/S13
  must pass it, and a route that forgets it loses the precondition silently** — stated here
  because that failure is invisible from this file.
* **A DEFECT IN S3'S SELECTOR, FOUND BY S5.** `nst-select-order-header-by-row-id` had **no
  `DELETED_STATE` clause** while its own docstring promised *"the live order header"*; the
  invoice's equivalent selector has carried `[or [= … N] [is … nil]]` from the start. So a
  soft-deleted order came back as live — `fetch` would have served it and `!update`/`delete!`
  would have WRITTEN it, while नियम-2 says a `Y` row is invisible to every verb. Fixed in place,
  with the NULL-vs-`N` trap restated. Both new verbs read through that selector, which is why it
  surfaced in this story rather than in S4's.

**THE AC WON, AND TWO DECISIONS WERE CORRECTED RATHER THAN THE CODE.** `*ordh-deletable-statuses*`
is `("DFT")` — **not** D8's *"open only"* and not O4's *"an open order"*. S5's own acceptance
criterion says *delete on `PEN` refuses, on `DFT` succeeds*, and that is also the safer reading: a
`PEN` row is a PLACED order (the legacy placement path writes one `DOD_VENDOR_ORDERS` row per
vendor, D20), so soft-deleting it orphans vendor rows nothing can reach — and **all 485 existing
orders are `PEN`**. A placed order is CANCELLED, not deleted: the `[LEGAL]` line the invoice draws
at an issued invoice. **D8 and O4 are corrected above; reverting is one list.**

**STATED GAPS, not implied ones.** (1) ~~**The lines are NOT cascaded.**~~ **CLOSED IN S7**, and the wording below was ALSO wrong about why: there is no foreign key on `ORDER_ID` at all (measured 2026-09-28) — the invoice's `ON DELETE CASCADE` sentence does not describe this table. The original text, kept for the record: `DOD_ORDER_ITEMS`'s
`ON DELETE CASCADE` fires only on a hard DELETE, and a soft delete never issues one — the invoice
MEASURED this exact shape and fixed it with लोप on the lines first.
`nst-soft-delete-order-items-for-header` belongs to **S7**, in the file that owns the line entity,
and S7's AC says the lines vanish from `enumerate`; until then a deleted header leaves
reachable-looking lines. (2) **The fresh validator is not returned**: `UPDATED` is DB-managed and
the CLSQL instance still holds the PRE-write value, so a token read from it would be stale and
would make every later `If-Match` fail — the route layer re-reads, and RFC 9110 permits omitting
the ETag. (3) **`!update` is deliberately NOT blocked once the order is converted to an invoice**:
the invoice's own verb is not blocked after generation either, because the settings state that
policy the other way — O4's conversion bar is about DELETION, where the document stops existing,
not about content. (4) **`make` is unchanged**: F5's *"(and make)"* half is already satisfied in
S3 by three mechanisms (forced values, stripped keys, the open-status gate), and the fields create
still passes (`:cust-name`, `:shipped-date`, `:cancel-reason`) are content rather than
escalations. Applying the partition to create would also have to carve `:status` out of it,
because create has its own gate; **that is the one decision S5 leaves open.**

**VERIFIED — offline, and nothing else.** Preflight **PASS** (0 problems: reader-balanced, 52
forms, 40 SQL statements none bare, registered in **both** build lists). The numbering tool gained
**section 12** — the partition above, plus the two status lists against each other (every
deletable status must also be open; every code is three characters, because `STATUS` is `char(3)`)
and the control keys against the class — and now reports **116 checks, 0 failures**,
**mutation-tested four ways**: a slot removed from the writable list, a typo'd name in a strip
list, a field added to two lists, and a reserved key dropped from the strip list each fail with
the check that names them. The reserved-key check reads `*reserved-initargs*` **from
`nst-bl-adhara.lisp`** rather than transcribing it, and adding a key there fails it — proved by
mutating adhara and restoring it. ⚠ **One mutation initially "passed" because it hit the wrong
list**: the create and update strip lists share their first five lines, so the edit landed on S3's
list, which section 12 does not read. The check names the list it read, which is what made the
second attempt unambiguous.

**NOT YET VERIFIED:** every behaviour — the terminal refusal writing nothing (proved by re-reading
the row), the strip on a direct call, the `If-Match` mismatch, the `DFT`-only delete and `PEN`
refusing. All of it needs the image and the database, so it is **S16's suite**. Nothing in this
file has executed.

**LEDGER (opened by S5):** consolidate `invh-json-timestamp` and `nst-ordh-version-token` into
`core/dod-bl-utl.lisp` — this file loads BEFORE `invoice/nst-bl-invh.lisp`, so it cannot call it;
S12/S13 must pass `:if-match` (above) and map 412 distinctly from 409 (F13's missing case).

### S4 — DONE (2026-09-28): `fetch` and `enumerate`

**Added to `hhub/order/nst-bl-ordh.lisp`** (31 top-level forms now): the sort whitelist, the
sort/limit validators, the filter-clause builder, the filtered selector, the single-row
`by-ordnum` lookup the route layer will use, and the two verbs.

* **`fetch` is ROW-ID-keyed**, and the route layer resolves the URL's ORDNUM to a row-id first —
  the verbs stay row-id-keyed because CLOS dispatches on TYPE and an ORDNUM and a ROW_ID are
  both strings (the same reason the invoice batch put `invh-header-from-url` in its route tier).
  **Another tenant's row-id answers `:F`, not `:U` and not a permission error**: authorization is
  per-object by the shape of the SELECT, which is BOLA answered by construction rather than by a
  check somebody can forget.
* **The filters are QUERY ARGUMENTS, not entity initargs** — which is why the verb takes them
  directly: `extract-domain-initargs` forwards only keys the DOMAIN CLASS declares, so
  `:ordnum-like`/`:from-date`/`:limit` would be silently dropped by the ferry. The route layer
  builds them, exactly as `invitm-enumerate-args` does for invoice lines.
* **`nst-ordh-sort-column` is the analogue of `validate-invh-sort-args`, and it SIGNALS** — the
  route layer is what turns that into 400. A plain domain `error` reaches the API as a 500 ("the
  server broke") for a client that mistyped a query parameter the API itself publishes; that is
  the defect the invoice batch measured, so the whitelist is read in both places rather than
  restated. The domain check stays as the backstop for `:agent`/`:batch`/REPL callers.
* **§10 F7 landed**: `:limit` defaults to 50 and is **capped at 200 — capped, not refused**.
  Returning fewer rows than asked for is a legal answer (AIP-158), while an error would make an
  over-large page indistinguishable from a malformed one; a non-positive or non-integer limit
  does signal.
* **A STABLE secondary `ORDER BY row-id` is part of pagination, not decoration.** `ORD_DATE` is a
  `DATE`, so orders placed on one day TIE — and an ORDER BY with ties has no defined order
  between pages, so an offset-based reader can see one order twice and never see another. The
  secondary key makes the sequence total, which is what makes `:offset` safe.
* **The `[or [= deleted-state "N"] [is deleted-state nil]]` clause is copied from the invoice**,
  because this table shares the trap: `char(1) DEFAULT NULL`, so both NULL and `"N"` occur and a
  bare `[= … "N"]` hides rows. `[is … nil]` renders `IS NULL`; `[= … nil]` would render the
  literal NULL, which is true for no row at all.

**AND O2 LANDED WITH IT — the O2 DECISION WAS "consolidate in `dod-bl-utl.lisp`".**
`nst-row-id-from-string` now lives in `core/dod-bl-utl.lisp`, which is build position 128 / asd 62
— before `nst-bl-adhara` and before every domain file, so nothing can load ahead of it. The order
verbs are the **sixth CALL SITE, not the sixth copy**. ⚠ Re-pointing the five existing copies
(`vendor-row-id-from-string`, `warehouse-…`, `product-…`, `invoice-header-…`, `invoice-item-…`)
is still the ledger item: each sits in a different loading-sensitive file and deserves its own
build/load proof.

**VERIFIED:** preflight **PASS** (124 forms in `dod-bl-utl`, 31 here; 40 SQL statements, none bare);
**0 READ errors**; no warning naming a function this file defines. `:offset` was confirmed to be a
real CLSQL `select` keyword by an existing in-tree use (`customer/wallets/nst-bl-custwallets.lisp:526`)
rather than assumed.

**NOT YET VERIFIED:** the behaviour. Tenant isolation across filter combinations, the tie-stable
pagination and the route-layer 400 all need the image and the database, so they are S16's suite.

### S3 — DONE (2026-09-28): the header's `?exists` and `make`

**`hhub/order/nst-bl-ordh.lisp`** — 20 top-level forms, registered in **both** build lists and
added to the preflight's change set. It carries: two tenant-scoped select helpers plus
`nst-order-header-row-visible-p`; the two **list-driven** copy ferries; `?exists` (four-valued);
`make :around` (idempotency); and `make`, which delegates to a flat sequence of steps.

**TWO CORRECTIONS THAT CAME FROM THE CORPUS, NOT FROM A BUG — which is the point of §9b.**

1. **The refusal is `:around`, NOT `:before`.** This story's own text said `:before`; `nst-whs`
   records why that is wrong: *"A `:before` method cannot return a value (its result is
   discarded), so raising was the only way it could refuse — and every refusal then reached the
   boundary as a 500, indistinguishable from a crash."* **The doc is corrected here**, not the code.
2. **What the `:around` is FOR changed once the mint moved in.** Since `make` MINTS the ORDNUM, a
   caller rarely supplies an identity to pre-check — so the `:around` spends its return-a-value
   power on **idempotency** (§10 F6): a repeat of the same `:context-id` returns the existing
   order. CONTEXT_ID is already in the table and stamped by the legacy funnels with
   `(uuid:make-v1-uuid)`, so the key existed and needed honouring. The unique index on ORDNUM stays
   the real guard, with a bounded pre-check-and-retry for the birthday collision the `{ref:N}`
   truncation makes possible.

**THE PREFLIGHT FOUND TWO THINGS, AND BOTH WERE MINE.**

* **`make` was unbalanced — because it was nested ten levels deep.** The fix is not to count
  parens: the steps moved into `nst-order-header-create`, a plain function whose body is a
  sequence of `(unless ok (return-from … refusal))` at ONE level. *Depth is where paren errors
  live*, so the shape changed, not the arithmetic. (Found in the first preflight run, before any
  compile attempt.)
* **A false positive in the preflight's OWN SQL detector** — `(?i)^\s*CREATE` matched the docstring
  *"Create an order in the SESSION tenant …"* and reported the English word `OF` as an unquoted
  identifier. That is the crying-wolf failure mode again, twice in two sessions. The detector is now
  **case-sensitive with two-token openers** (`CREATE TABLE`, `ALTER TABLE`, `INSERT INTO`, `UPDATE \``,
  …), and was **re-verified against the real `LAST_VALUE` mutation** so the narrowing did not blind
  it: 116 "statements" became 40 real ones.

**VERIFIED:** preflight **PASS** (20 forms read; 40 SQL statements, none bare); compiles with **0
READ errors** and **no warning naming a function this file defines** — the check that catches a
self-referential typo — while the undefined names reported are all from files the minimal harness
does not load (`bo-knowledge-truth`, `bind-generated-row-id`, `domain-ctx-actor`, …).

**NOT YET VERIFIED, and stated rather than implied:** the BEHAVIOUR. Tenant isolation, the mint, the
`DFT` status, the idempotent replay and the four refusals all need the image and the database, so they
are S16's smoke suite. Nothing in this file has executed.

**S4–S6 next:** `fetch` + `enumerate`, then `!update` + `delete!`, then the reverse ferry.

### S1 + S2 — DONE (2026-09-28): the two order islands

**Two files, generated from the measured schema rather than typed:**

| File | Contents |
|---|---|
| `order/nst-dal-ordh.lisp` (248 lines) | `nst-ordh` — 54 slots (row-id + 53); slotless `NstOrdhRequestModel`; `NstOrdhResponseModel` (55 slots); `*ordh-mirrored-slots*` (54) |
| `order/nst-dal-orditm.lisp` (192 lines) | `nst-orditm` — 28 slots (row-id + 27); `NstOrditmRequestModel`; `NstOrditmResponseModel` (29); `*orditm-mirrored-slots*` (28) |

**NO NEW ORM CLASS** (D7): `dod-order` (58 columns) and `dod-order-items` (32) already map the live
tables exactly, and both files reuse them.

**⚠ THE VIEW CLASSES' SLOT NAMES ARE NOT DERIVABLE FROM THE COLUMN NAMES, and kebab-casing would
have produced four wrong ones:** `SHIP_ADDRESS` is **`ship-address-short`**, `SHIPADDR` is
**`ship-addr-full`**, `CUSTNAME` is **`cust-name`**, `GSTNUMBER` is **`gst-number`** (and `GST_ORG_NAME`
is `gst-org-name`). Extracted from the classes themselves, with a coverage assertion that the union of
the named groups equals the extracted field set minus the four the base class owns — the only reason
this is right rather than plausible.

**The arithmetic, and why it is 54 and not 58:** `TENANT_ID`, `DELETED_STATE`, `CREATED` and `UPDATED`
map to the inherited `tenant-id` / `deleted-state` / `created-at` / `updated-at` and are **not
redeclared**; `customer`/`company` (and `order`/`vendor`/`product`/`company` on the line) are
`:db-kind :join` and are therefore **not domain state**. 58 − 4 = 54; 32 − 4 = 28.

**MONEY AND RATE SLOTS CARRY AN EXPLICIT `0.0` INITFORM** — a fixed defect, not style: CLSQL declares
those decimals `(OR NULL FLOAT)` and validates on insert, so an ordinary JSON `0` fails the INSERT and
reaches the client as `:U`/503. The tinyint flags take `0` (integers) and the char(1) flags take `"N"`
(so a create writes what the column's own DEFAULT would).

**⚠ A DELIBERATE DEVIATION: `*ordh-mirrored-slots*` LIVES IN THE DAL FILE**, where the invoice keeps its
own in the BL. The list drives THREE consumers — both copy ferries and `domain->response`, which setfs
every listed slot onto the RESPONSE MODEL — so keeping it beside the two classes it must match makes the
three editable in one file. That is the whole T4 failure mode, and S6's mirror-check acceptance criterion
is already met by the offline check below.

**BOTH BUILD LISTS, both files** (`package/compile.lisp` and `nstores.asd`), placed AFTER
`nst-dal-OrderItem.lisp` so the ORM classes they reuse exist first.

**VERIFIED:** both compile **completely clean** — `warnings=NIL failure=NIL`, zero warnings, zero READ
errors. The tool's new section 11 asserts, per entity: every mirrored slot exists on the entity (or is
inherited), every one is on the **response model**, every entity slot is **mirrored out** (an unmirrored
slot silently vanishes from every response with no error — the reverse direction nobody checks by hand),
`row-id` is on the model but not in the list, and `deleted-state` is mirrored.
**105 checks, 0 failures**, and **mutation-tested**: dropping `deleted-state` from the list fails with
exactly that named check.

**THREE BUGS THE NEW CHECK FOUND IN ITSELF, all fixed** — worth recording because each looked like the
code was wrong when the *checker* was:
1. **Comments read as symbols.** A quoted slot list may carry `;;` headings (the invoice's does), and a
   naive scrape turned 54 mirrored slots into **98** with 40 phantom mismatches. The extractor now strips
   comments, honouring strings and escapes.
2. **A paren in a comment ended the list early.** The group heading `;; tax RATES (decimal(4,2))` has a
   `)`, and "the list ends at the first `)`" truncated it to **10 of 27** slots. Comments are now stripped
   *before* the bounds are found.
3. **`\s+` matches newlines** in multiline mode, so a slot match could begin at the preceding line break
   and keep a stray paren — reported as a slot literally named **`(row-id`**. The pattern is now `[ \t]+`.

### S0d — PART 1 DONE (2026-09-28): the prefix on the customer entity, and the override rules

**Five insertions and one guard, in two files:**

| File | Change |
|---|---|
| `customer/nst-dal-Customer.lisp` | `doc-prefix` slot on **`nst-customer`**, on **`nst-customer-response-model`**, and on the **`dod-cust-profile` view class** (`:type (string 8)`, `:column "DOC_PREFIX"`) |
| `customer/nst-bl-Customer.lisp` | `doc-prefix` added to **`*nst-customer-business-fields*`** and to **`*nst-customer-json-keys*`** (`"docPrefix"`), plus `nst-customer-document-count`, `nst-customer-doc-prefix-refusal`, and the guard in `!update` |

**THE RESPONSE-MODEL SLOT IS NOT OPTIONAL — AND THAT IS NOW CHECKED, NOT REMEMBERED.**
`*nst-customer-business-fields*` drives three consumers (both copy ferries **and**
`domain->response`, which setfs every field onto `nst-customer-response-model`), so a field in the
list with no slot on that class signals MISSING-SLOT on **every** customer response — the exact
defect that took the whole invoice API down (T4). The offline tool therefore gained a **source-only
mirror check**: it extracts the field list from the BL source and the declared slots from the DAL
source and asserts every field is a slot on **both** classes. Today: **72 fields, 73 slots each**
(the 73rd is `company`, which the list's own docstring excludes as a `:join`), `doc-prefix` in all
three places, and **91 checks, 0 failures**. ⚠ The check reads sources, so it needs no build, no
database and no image — and its extractor had to be fixed once already: a `((row-id` first slot is
missed by a one-paren pattern, which is the same trap the vendor-orders column scan hit.

**THE GUARD IS THREE LINES, ON PURPOSE.** `!update` gained:

```lisp
(let ((refusal (nst-customer-doc-prefix-refusal (parse-integer row-id) tenant-id
                                                (slot-value dbobj 'doc-prefix)
                                                (getf update-args :doc-prefix))))
  (when refusal (return-from !update refusal)))
```
A wrapping conditional would have re-indented the whole method, and **re-nesting is what broke the
parens of the ordnum-identity migration**. `return-from` inside a `defmethod` is legal — the method
body has an implicit block named by the generic function — **verified in isolation before use**, not
assumed.

**BOTH REFUSALS ARE CONTRADICTIONS, NOT SIGNALS** (R1's charset and R3's freeze): the domain cannot
say 400, so signalling would reach the client as a 500 and report the CALLER's mistake as a server
fault — the classifier gap recorded as F13. A contradiction is this domain's own vocabulary for
"understood and refused", and the sentinel ferry already renders it as 409. The current prefix is
read from the caller's already-tenant-scoped `dbobj`, not a second query, and the document count is
`WHERE CUST_ID = ? AND TENANT_ID = ?` — tenant-scoped even though the row-id would find it, because
a count that could see another tenant's documents is the BOLA shape this codebase keeps refusing.

**⚠ A wire-visible consequence:** adding `doc-prefix` to `*nst-customer-json-keys*` publishes
`"docPrefix"` in the customer JSON. Additive for clients, and the value is inside document numbers
anyway — but it is a change to an existing API's response shape, so it is stated rather than slipped in.

**PART 2 (still to do): the profile page** — `customer/templates/customerprofile.html`: display the
prefix, the override input (with a hidden `id`, the lesson the warehouse form had to learn), and
F18's accessibility bits (a real label, programmatic error text, no colour-only signalling).

### S1 — `nst-dal-ordh.lisp`
`nst-ordh` subclasses **`nst-domain-entity` only**; inherited `id`/`tenant-id`/`created-at`/
`updated-at`/`deleted-state` never redeclared; every business slot `:initarg` + `:accessor`.
`NstOrdhRequestModel` **slotless**. `NstOrdhResponseModel` mirrors exactly the slots
`*ordh-mirrored-slots*` names.
**AC**: (a) compiles `failure-p=NIL` under the isolated `compile-file` recipe; (b) no
`BusinessObject` / boundary parent; (c) **`STATUS` is declared 3 characters wide** (the
live column) and a comment records that the create-script's `DRAFT` is unstorable — **do
not "widen" it**; (d) money slots get `0.0` initforms and are declared so the CLSQL float
trap (T2) cannot recur; (e) every `:initarg` name is checked against the legacy `order`
class and its `orderRequestModel` slots; (f) `DELETED_STATE`'s nullability is handled by
the SELECT predicate (T3), not by a `:void-value`.

### S2 — `nst-dal-orditm.lisp`
Same shape for `nst-orditm` over `DOD_ORDER_ITEMS`; `:order-id` (parent FK) and
`:vendor-id` are first-class slots.
**AC**: as S1(a)-(e); plus `ITC_ELIGIBLE`'s enum, the six rate columns and the five amount
columns are all present, and no slot is declared for `CREATED`/`UPDATED` (DB-managed, D19).

### S3 — `nst-bl-ordh.lisp`: `?exists` + `make`
`?exists` on `ORDNUM`; `make` with the `:before` guard, the D6 mint, the `DFT` status (D7),
and the defaults `ORDER_FULFILLED "N"`, `IS_CONVERTED_TO_INVOICE "N"`, `IS_CANCELLED "N"`.
Symmetric, field-complete `nst-copy-order-header-domaintodb` / `-dbtodomain`.
**AC**: (a) `?exists` answers all four Belnap states and `:U` **aborts** the create;
(b) two `make` calls in one tenant and one financial year differ; (c) a caller-supplied
`:ordnum`/`:tenant-id` never reaches the row; (d) the tenant comes only from `ctx`;
(e) `STATUS` written is exactly 3 characters (assert, because a 5-character value would be
silently truncated by the column and the entity would look fine);
(f) `nst-financial-year-label` (`nst-bl-invh.lisp:65`) is reused — noting this makes the
order verbs depend on `nst-bl-invh`'s load position, which the asd already satisfies — or
the duplication is called out deliberately.

### S4 — `nst-bl-ordh.lisp`: `fetch` + `enumerate`
`fetch` tenant-scoped, returning an entity or a sentinel, **never bare nil**. `enumerate`
with a filter-clause builder, `*ordh-sort-whitelist*`, and the D5 scope argument
(`:cust-id`) as a **query argument** — not an initarg, so it cannot ride the ferry and the
route layer must pass it, exactly as `invitm-enumerate-args` does.
**AC**: (a) `(fetch 'nst-ordh <another tenant's ordnum> ctx)` → `nst-entity-nil`;
(b) no filter combination returns another tenant's row; (c) a `sort-by` outside the
whitelist signals, and the ROUTE layer turns it into **400**, not 500 (the invoice's
`invh-guard-sort-args` defect); (d) the not-deleted predicate is `[= 'N'] OR [IS NULL]`.

### S5 — `nst-bl-ordh.lisp`: `!update` + `delete!`
`!update` hydrates, `reinitialize-instance` for the partial update, writes back, and refuses
a terminal status with a contradiction. `delete!` sets `deleted-state "Y"`, only from an
open status, and refuses once `IS_CONVERTED_TO_INVOICE = 'Y'` (O4).
**AC**: (a) `!update` on a `CMP` order → `nst-entity-contradiction` → 409, having written
nothing (proved by re-reading the row); (b) `delete!` on `PEN` refuses, on `DFT` succeeds;
(c) `:tenant-id`, `:id`, `:created-at`, `:updated-at`, `:deleted-state` cannot be set
through the verb — the reserved-initarg hole the invoice records is **closed here**, not
copied a third time; (d) a direct `!update` cannot change `ORDNUM`.

### S6 — `nst-bl-ordh.lisp`: reverse ferry + `render-json` (+ the mirror check)
`domain->response`, `domain->response-list`, `render-json` as an explicit per-field
allowlist.
**AC**: (a) an offline check modelled on
`aiharness/deepseek/tools/nst-invoice-mirror-check.lisp` reads `*ordh-mirrored-slots*` and
`*orditm-mirrored-slots*` **from source**, performs `domain->response`'s exact `setf` for
every slot, reports `M/M` and **exits 1** on a missing slot; (b) it is mutation-tested
(remove one slot from a throwaway copy, watch it fail, restore); (c) the `tinyint(1)` flags
are rendered through the `invh-json-flag` guard — **`0` is truthy in Lisp**, so the naive
form reports a false flag as true.

### S7 — `nst-bl-orditm.lisp`: the six प्रत्यय
Every verb re-proves the parent by selecting its header through the tenant-scoped header
reader before touching a line — the authorization model, because `order-id` is a
caller-supplied integer (BOLA). `make`/`delete!` require an **open** header; `!update` does
not (content vs values). The header's `delete!` calls
`nst-soft-delete-order-items-for-header` (लोप helper at the bottom of this file).
**AC**: (a) a line id from another tenant answers a sentinel, never data; (b) `make` on a
`CMP`/`VCN` header is refused with a contradiction; (c) deleting a header soft-deletes its
lines, which then vanish from `enumerate` unless deleted rows are requested; (d) `:order-id`
cannot move a line between orders; (e) the mutually-referencing pair compiles with at most
the one expected style-warning.

### S8 — Teach the legacy layer about `DFT`
In `core/dod-bl-utl.lisp`: `*order-open-statuses*` = `("DFT" "PEN")` and
`order-open-status-p` (D17). Then retrofit every open-state test to the predicate:
- `order/dod-bl-ord.lisp:94` (`CMP` filter), `:108` (the `PEN` filter), `:127` (the derived
  `(if (equal fulfilled "N") "PEN" "CMP")` — the **write** side of the legacy status),
  `:134`, `:150`, `:166` (status-parameterised reads)
- `order/dod-bl-odt.lisp:44`, `:56`, `:71`, `:93`, `:109` (the same shape for lines)
- `order/dod-ui-odt.lisp:183` — the display gate `(and (equal status "PEN") (equal fulfilled "N"))`

**AC**: (a) an order created through the new API with `STATUS "DFT"` **appears** in the
legacy vendor pending list and in the legacy item views — that is the whole point, and it is
measurable before and after; (b) a legacy `PEN` order still works everywhere it did;
(c) the legacy creation paths still write `PEN` (unchanged, `dod-bl-ord.lisp:386,564`);
(d) no behaviour changes for `CMP`/`VCN`/`CCN`; (e) the touched functions are the nine
listed and nothing else.

### S8b — Stop the legacy funnels recreating the hole
S0b's mint fixes the 485 rows that exist. **It does not stop the next one.** `persist-order`
(`order/dod-bl-ord.lisp:357`) never passes `:ordnum`, and it is the **single choke point** for
customer-placed orders — `create-order` (`:396`) and `create-order-from-shopcart` (`:544`)
both funnel through it. Its vendor-side twin is `persist-vendor-orders` (`:559`), the choke
point for vendor rows. Teaching those two is the whole fix; teaching them anywhere else
misses paths.
**AC**: (a) the mint lives in `core/dod-bl-utl.lisp` (S0b part 1's reusable function) and both
funnels call it — no third copy of the sequence rule; (b) an order placed through the legacy
shopcart path after this change has a **non-NULL, unique `ORDNUM`**, demonstrated by placing
one and reading it back; (c) its `DOD_VENDOR_ORDERS` rows carry the same number; (d) the
existing `"000"` literal in the render path (`customer/dod-ui-cus.lisp:3039`,
`upi/dod-ui-upi.lisp:49`) is either removed or shown to be inert — a rendered `"000"` next to a
real minted number is worse than either alone; (e) `daily` order creation
(`run-daily-orders-batch`, `dod-bl-ord.lisp:602` → `create-order-from-pref` → `persist-order`)
is covered by the same choke point, and one batch-created order is checked by hand.

### S9 / S10 / S11 — `nst-vordh` (vendor channel): DAL, BL, api
`nst-vordh` over `DOD_VENDOR_ORDERS`, scoped by `VENDOR_ID = :login-vendor` **and** the
session tenant. `make` is called by `route-ordh-create`'s assembly (D14), one row per
distinct vendor on the order, **carrying the minted `ORDNUM`** (D20); `fetch`/`enumerate`/
`!update` serve the vendor channel; `delete!` follows D8.
**AC**: (a) it gets its **own** class covering all 60 live columns — the legacy
`dod-vendor-orders` class stays untouched for the legacy UI, because extending it in place
would change a live SELECT's column list as a side effect of an order change (T5); (b) the
new class is diffed mechanically against the dump and the verdict recorded in §3;
(c) `enumerate` under a vendor session returns **only** that vendor's rows — a second
vendor's row in the same tenant is invisible; (d) `PUT /vendor/orders/{ordnum}` cannot move
a row to another vendor or tenant, and cannot change `ORDNUM`; (e) a vendor order whose
`ORDNUM` is NULL → **404, not a guess**; (f) **after `PUT`, `ORD_DATE` is byte-identical**
and `UPDATED` advanced — the T9 / D21 assertion, which is the only way this corruption
becomes visible; (g) `!update` on a terminal status is refused.

### S12 — Tier-2 action verbs + `register-action-route`
`route-ordh-create` (the D14 assembly) / `-list` / `-detail` / `-update` / `-delete`,
`route-orditm-update` / `-delete`, `route-vordh-list` / `-detail` / `-update`, plus
registered-but-unbound `route-orditm-list` / `-fetch`. Each thin: resolve the URL, read the
session scope, call the ferry — all domain law stays in the BL layer. The `(order, line)`
pairing check is the copy of `invitm-check-pairing-of`; a mismatched pair is **404 about the
pair**, never 403.
**AC**: (a) `route-ordh-create` does **not** require a row-id (the invoice's first
`POST`-blocking defect was a shared normaliser that demanded one — a create has none);
(b) no route renders; each returns a domain result and lets the dispatcher reverse-ferry it;
(c) `:ordnum` and `:order-id` are stripped from update payloads; (d) no session identity →
**401 fail closed**, nothing written; (e) the assembly writes header, lines and vendor rows
in that order, and leaves no orphan vendor row if a line is refused.

### S13 — Ring-4 bindings (`register-api-route`)
The customer 7 + vendor 3 = **10 bindings**, each in the file that registers its action
route (D12), each carrying `/hhub` (the spec's paths omit it; nginx rewrites the rest),
`:auth-scope :session`, and `success-status` 201 on the creates.
**AC**: (a) an unauthenticated sweep answers **401** for all ten and **404
`no_such_endpoint`** for the two deliberately-unbound item routes; (b) path params beat the
body, so `{ordnum}`/`{item-id}` cannot be displaced; (c) `/vendor/orders` and
`/orders` do not shadow each other — confirm `find-api-route`'s fewest-parameters-first
ranking resolves both (the `/invoices/settings` vs `/invoices/{id}` precedent);
(d) `aiharness/deepseek/tools/nst-binding-order-check` exits 0.

### S14 — ABAC / transaction seeds
`installation/upgrades/nst-dbu-ordapi-policy-transaction.lisp`, one `insert-auth-policy` +
`insert-bus-transaction` pair per bound endpoint, registered in `*migrations*`.
**AC**: (a) idempotent; (b) each transaction links to its **own** `:policy-id`; (c) the
header states plainly that the seam is a no-op and these rows are carried, not enforced (D18).

### S15 — Build registration and the offline load
The nine files in **both** `hhub/package/compile.lisp` and `hhub/nstores.asd`, DAL → BL →
headerapi → itemapi → vordhapi.
**AC**: (a) `compile-production` reports `Failed: 0`, with only the expected cross-file
style-warnings; (b) `nst-binding-order-check` exits 0; (c) `nst-offline-load.lisp` reaches
`STAGE: LOADED` — the strongest check available without a restart; (d) **a restart is the
only way to load the new classes into the running image; never `load` a file into the live
image** (it can wedge class definition for the life of the process, T6).

### S16 — Smoke suites (four files)
`smoke-order-header-api.sh` (the five customer endpoints, the status gates `CMP`/`VCN`/`CCN`,
the sort-whitelist 400, the `IS_CONVERTED_TO_INVOICE` refusal), `smoke-order-items-api.sh`
(the pairing check both ways, the open-header rule, the `:order-id` strip),
`smoke-order-vendor-api.sh` (the three vendor endpoints, vendor-vs-vendor invisibility,
a NULL-`ORDNUM` row), `smoke-order-api.sh` (consolidated: the full
`create → add line → update → delete` lifecycle, both sessions — vendor `POST
/hhub/dodvendlogin` and customer `POST /hhub/dodcustlogin` — and the BOLA cases).
**AC**: (a) read-only by default; `--write` runs the lifecycle and removes every row it
created on EXIT **including on failure**, keyed on **row-id from the 201** (never on an
`ORDNUM` prefix — the invoice suite was once made to key on the prefix and never matched);
(b) the unauthenticated sweep proves the bindings without writing; (c) exit 0/1/2 with 2
reserved for setup failure, so "not tested" is never reported as a pass; (d) every
deliberate gap asserted as `KNOWN`, not `FAIL` — including **O3's partial-write window**;
(e) fixtures named with ids and a `verified <date>` marker; (f) the suite states what it
does **not** cover.

### S17 — (follow-on, NOT in this batch) the `invoice (ord ctx)` compound verb
What this batch unblocks. `invoice` is already declared and registered under
`:proc.finance` (`paninigrammar/document-1-procurement-dhatupatha-v2.md:114`,
`adhara:437-439`); it would crystallize an `nst-invh` from an `nst-ordh` and move
`IS_CONVERTED_TO_INVOICE` + `INVOICE_NUMBER` + `INVOICE_DATE` (§1). Its blockers are
**atomicity** (D14's seam) and the invoice-side `create-with-lines` gap. Do not start it here.

---

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

- Nine files exist, compile `failure-p=NIL`, and load in both build lists in the correct
  order; `compile-production` reports `Failed: 0`.
- All six प्रत्यय exist on all three entities, four Belnap states in and out; `:U` is never
  phrased as "not found".
- Ten bindings answer; two routes are registered and deliberately unbound.
- The mirror check passes `M/M` for all three entities and is mutation-tested.
- The `ORDNUM` unique index exists and `SHOW INDEX` proves it (S0b).
- The legacy layer recognises `DFT` as open, demonstrated by an API-created order appearing
  in the legacy vendor pending list (S8).
- Four smoke suites pass: read-only, and `--write` with cleanup.
- No new name collides with the legacy `order` domain. The only legacy files edited are the
  nine in S8, `dod-order`'s view class if the diff demands it, and both build lists.
- `PENDING-WORK-CONTEXT.md` records what this batch leaves open — at minimum O2 (the five
  un-re-pointed guards) and O3 if the seam is not fixed.

---

## 9. Input still owed

**The `DOC_PREFIX` round (2026-09-27) reopened this section**, and it is the only thing between the
design and S0b. Four inputs, then the rulings.

1. **`SHOW CREATE TABLE DOD_CUST_PROFILE;`** (with `SHOW COLUMNS`) — **downgraded from 🚨: the
   requester has confirmed the column does not exist**, so absence is settled and this is now about
   *mechanics only* (the table's charset/collation for the inherited default, and a column list to
   eyeball the ALTER against). It is needed **to APPLY the migration**, not to write it — S0c needs
   nothing from it, and S0b can be written and dry-run before it arrives.
2. 🚨 **The customer population and the real names** — the de-duplication rule cannot be validated
   on paper, only against actual data:
   ```sql
   SELECT COUNT(*) FROM DOD_CUST_PROFILE;
   SELECT c.ROW_ID, c.LEGAL_COMPANY_NAME, c.LEGAL_NAME, c.COMPANY_NAME, c.NAME, c.CUST_TYPE,
          COUNT(o.ROW_ID) AS orders
     FROM DOD_CUST_PROFILE c JOIN DOD_ORDER o ON o.CUST_ID = c.ROW_ID
    GROUP BY c.ROW_ID ORDER BY orders DESC;
   ```
   The join gives the ACTUAL customers behind the 485 orders with all four name candidates, so the
   prefill can be **dry-run against real names** before anything is frozen — and it is how the
   collision rate (and therefore whether 8 characters is roomy or tight) gets known rather than
   guessed.
3. **How many of the 485 orders are GUEST orders** — answered by the `CUST_TYPE` column above. The
   guest path reuses one row per tenant, so guest orders would share one prefix and one series.
4. **Is the invoice trigger live?** (`installation/nstdbtriggers.sql:4-9` — `before_insert_invoice`).
   It OVERWRITES `INVNUM` on every insert, so if `{prefix}` is ever to appear on invoices the trigger
   must be retired first (S0b §F). Not needed for orders; needed to know whether the invoice family
   is blocked, and by what.

**The rulings (all in S0b): R1** the column's charset/length/stored form, **R2** the
de-duplication rule, **R3** whether an override is allowed once documents exist, **R4** whether the
counter table lands in this batch (recommended: yes — the mint cannot be built without it).

**One live `DOD_ORDER` row for tenant 2**, with its items and its vendor rows (join explicitly on
`ORDER_ID` — neither child table has an FK to the header) is still wanted: it confirms D5's
same-tenant inference against data rather than code paths, and gives the four smoke suites fixtures
they can name instead of guess. **Prefer a `PEN` row** (101 exist) — the only open status the write
lifecycle can exercise. **It must be re-read after S0b's mint**, because its `ORDNUM` will have
changed from NULL to a real number.

Optional: how many **distinct `ORDER_ID`s** the 462 vendor rows cover. 485 orders against 462 pairs
(zero duplicates) already proves at least 23 orders have no vendor row, so the count is a nicety.

~~The tenant distribution~~ — **closed 2026-09-27, and it was never a gate.** The NULL-tenant count
came back **0**, and the prefix design has since removed the tenant from the number entirely.

**The prerequisite that is not a query, and it has grown tables:** S0b part 1 *writes* 485 order
numbers that have never existed **and** allocates customer prefixes, which R3 then freezes. Both are
one-way doors in practice. So the dry-run AC must be satisfied, and the backup is now three tables:
**`mysqldump` of `DOD_ORDER`, `DOD_VENDOR_ORDERS` and `DOD_CUST_PROFILE`** before applying. The
first two are 485 and 462 rows; the customer table's size is item 2's other purpose.

---

## 9b. Preflight — how NOT to discover the bugs as you go

**Read this when:** starting a story. The question that produced this section was *"you are
discovering bugs as you go — can we know in advance, and then not need the fix at all?"* The answer
is **mostly yes**, and the classification below says which half, and what now enforces it.

| Bug | Found how | Knowable in advance? | What enforces it now |
|---|---|---|---|
| The create-script is not the live schema (`STATUS char(3)`, no UNIQUE `ORDNUM`, no `VENDOR_ID`) | only when the design met a real dump | **Yes — measure first.** Three decisions were built on a stale file | preflight §4(a): the dumps, as a **gate before designing** |
| `decode-date` returns FOUR values for a DATE struct, six for a wall-time, signals on an integer | a crash at the first real call | **Yes — probe the reader, not the DDL** | preflight §4(b) |
| `LAST_VALUE` is a MySQL 8.0 reserved word (Error 1064, live) | the live migration run | **Yes — and better, made impossible**: quote every identifier | preflight §2 — **mutation-tested on the exact bug** |
| Unbalanced parens; then a "fix" that closed a `flet` early | the compiler (READ error) | **Yes — the reader decides it** | preflight §1 — delegated to the Lisp reader |
| A stale image and a stale ASDF cache | five notes that all blamed the wrong thing | **Yes — grep the fasl for a symbol you just added** | preflight §4(e); **content, not timestamps** |
| Mirror list vs two classes (MISSING-SLOT) | inherited precedent | **Yes — it is a set comparison** | `nst-verify-doc-numbering.lisp` §10–11, mutation-tested |
| Extractor bugs in the checkers themselves (×5: comments as symbols, a paren in a comment, `\s+` newlines, quotes in the anchor, a handler-case scope) | **only by running the checks against real files and reconciling every disagreement** | **Partially — and this is the irreducible half** | non-vacuity assertions + **mutation tests** |

### The four rules, in order of leverage

1. **Measure the substrate before designing on it.** Live schema, library contracts, the actual data.
   Most of this batch's cost came from designing on `hhubplatform.sql`, on a documented API contract,
   and on an assumption about 485 rows — all three measurable in minutes.
2. **Prefer a construction that makes the class impossible to one that detects it.** Quoting every SQL
   identifier does not *catch* reserved words; it makes them unable to matter. A list-driven copier
   cannot be field-incomplete. One funnel for a value cannot fork.
3. **Use the substrate's own parser.** The preflight's first version hand-wrote a Lisp scanner and was
   wrong three ways; the reader is exact by definition and is the same reader the compiler uses. The
   same instinct applies to the SQL: run the server's own parser by applying the DDL, not a mental model.
4. **Mutation-test every checker, and assert it found its inputs.** A check that has never failed is
   unverified, and a check that cries wolf is as expensive as one that misses. Every one of the five
   checker bugs above was found by *exercising the failure path*, never by reading the checker.

### A THIRD check: build registration — and the gap it found immediately

**A new `hhub/**` file needs TWO registrations**: `package/compile.lisp` (what
`compile-production` compiles) and `nstores.asd` (what the SERVER actually loads, via
`ql:quickload :nstores`). Nothing checked the second one, so the preflight now does — narrow on
purpose: it asserts **the files this batch added** are in both, and merely *notes* the rest.

⚠ **The two lists legitimately differ in 13 places** (the `test/*` files are compile-only, and
four files are loaded but never compiled), so an equality assertion would have cried wolf on all
of them. The narrow form is the one that can be trusted.

**AND IT IMMEDIATELY FOUND TWO PRE-EXISTING GAPS — files compiled and NEVER LOADED:**

* **`invoice/nst-bl-gstr1.lisp`** — the whole GSTR-1 collector. It is in `compile.lisp:284` and
  absent from `nstores.asd`, so `compile-production` writes a fasl nobody serves and the server
  never has the code. Nothing else in the tree references its functions. **That is consistent
  with — and a likely explanation of — the note in `knowledge/gst-gstr-compliance-CONTEXT.md`
  that the GSTR-1 collector "was never run against a session".** A feature can be written,
  compiled, reported green and be entirely absent from the running system.
* **`order/dod-dal-otk.lisp`** — a second `clsql:def-view-class` for the SAME `dod_order_track`
  table that `order/dod-dal-odt.lisp` also declares. Dead or superseded; recorded rather than
  guessed at.

Both are now in `PENDING-WORK-CONTEXT.md` §8. Neither is ours, and neither would have been found
by any check that existed before this section.

### The two tools, and when to run them

Both are offline — no database, no image, no build — and both exit non-zero on a finding.

* **`../tools/nst-preflight.lisp`** — before *claiming* any story done: delimiter balance (by the
  reader), SQL reserved-word quoting, **build registration for the files this batch added**,
  non-vacuity, and the printout of the database-side queries a human must run before the story is
  **applied**.
* **`../tools/nst-verify-doc-numbering.lisp`** — the behaviour checks: the FY rule, the single-pass
  template renderer, the reference permutation, the fail-closed key, the counter SQL's quoting, and
  the mirror-list/class invariants for the customer and both order entities.

**What no offline check can do, and must therefore be a human step:** the three database classes in
preflight §4(a)–(c). They are printed on every run precisely so they cannot be forgotten, because
every expensive mistake in this batch lives there.

---

## 10. Standards review — OWASP API Top 10 · NIST 800-53/800-63B · Google AIP · RFC · 2026-09-28

**Read this before writing the first story.** Twenty findings: nineteen about this batch (**the table
below**) and one pre-existing defect the review happened to walk into (**F20**, after the table — live
credentials in source, not caused by this work). **F1–F6 change acceptance criteria in stories we are about
to write**, so they are settled as decisions here rather than discovered during
implementation. Nothing here challenges the architecture: the grammar, the four Belnap states, the
ferry and the reserved-initarg filter came through the review clean.

**What the design already gets right** — recorded so this section is not misread as a list of failures:
- **No SQL-injection surface.** Every predicate is a parameterised CLSQL form (`[= [:ordnum] v]`), and
  `sort-by` cannot reach `ORDER BY` because of the whitelist — the classic hole, closed by construction.
- **No mass assignment of the tenant.** `*reserved-initargs*` strips `:tenant-id`/`:id`/`:created-at`/
  `:updated-at`/`:deleted-state` at the ferry; the tenant comes only from `ctx` (नियम-1).
- **404 rather than 403 for a foreign object** — the OWASP-correct choice (a 403 confirms existence).
- **`:U` is never collapsed into `:F`.** An outage cannot masquerade as absence.
- **The response is a per-field allowlist**, not the entity: nothing crosses the boundary by default.
- **The prefix may never be derived from GSTIN/PAN/phone** — already a written rule (and the DPDP/GDPR
  question: a company-name-derived prefix adds no personal data to a number that already travels in email).

### The findings

| # | Sev | Standard | Finding | Disposition |
|---|---|---|---|---|
| **F1** | **HIGH** ✅ **CONFIRMED** | OWASP API1/API9 · NIST AC-4 | 🚨 **The sequential counter leaks a customer's cross-vendor order volume.** The counter is per (customer, doc-type, FY), so ONE series spans a customer's orders across **all** vendors. **Two independent leak channels, and the second is the one that matters:** (i) `/vendor/orders/{ordnum}` answers 200 for the vendor's own slice and **404** otherwise, so the series can be walked; (ii) **a vendor needs no endpoint at all** — `DOD_VENDOR_ORDERS` carries the customer's number (D20), so a vendor holding `...-00001` and later `...-00005` **infers four orders with competitors**, and can keep counting, without sending a request. Honest characterisation: a *commercial-confidentiality* leak (a supplier can size its customer's total demand, which is negotiating leverage), not a data breach. | ✅ **RESOLVED 2026-09-28 — see the decision record below.** Not by re-scoping the counter: that option is **structurally impossible** here. |

### F1 — the decision record (2026-09-28)

**Why option (a), a per-(customer, vendor) counter, is ruled OUT** — and the requester's own observation
is what rules it out: *`DOD_ORDER` is for the customer, `DOD_VENDOR_ORDERS` is for the vendor.*
**One customer order spans several vendors** (one `DOD_ORDER`, N `DOD_VENDOR_ORDERS` rows, items carrying
`VENDOR_ID`). So a per-vendor counter would mint **N different numbers for ONE order** — and then the
customer could no longer quote "the" order number to a vendor, which is the stated reason the number
exists at all, and the vendor channel (`GET /vendor/orders/{ordnum}`) would have to address a per-vendor
identity instead of the customer's order. It would also collapse `UNIQUE (ORDNUM)`, since two vendors
would mint the same string from the same customer prefix. **The structure the requester pointed at is the
argument against (a).**

**Why option (c), rate-limit-and-accept, does not fix it:** rate limiting only touches channel (i). It has
**no effect on channel (ii)**, which needs no requests at all — so it would leave the primary leak open
while looking like a mitigation. *This corrects the framing in the first draft of this table, which offered
(c) as an equivalent option. It is not.*

**✅ RECOMMENDED — option (b), and do it in the token rather than the counter: keep an internal atomic
counter (deterministic, unique, dry-runnable) and publish a NON-SEQUENTIAL, UNGUESSABLE reference.**
`ORD-<DOC_PREFIX>-<FY>-<REF>` where `REF` is the counter value put through a **keyed permutation**
(HMAC-SHA-256 over tenant|customer|doc-type|finyear|counter, truncated, encoded in **base32 over an explicit 31-symbol alphabet** —
digits `2-9` plus `A-Z` less the look-alikes `I`, `L`, `O`: `23456789ABCDEFGHJKMNPQRSTUVWXYZ`) → `ORD-XYZCORP-2026-27-7K4M2Q`. Properties that make it the right fit:

- **Unguessable and un-inferable** → it closes **both** channels: gaps carry no information (the vendor's
  own numbers are non-adjacent), and walking the space is infeasible.
- **Deterministic** → the dry run still reproduces the real run exactly (AC (f) survives, which the
  random-suffix variant would forfeit), and the same (customer, FY, counter) always renders the same
  reference.
- **Unique by construction** → the permutation is injective, so the counter's uniqueness carries through;
  the unique index stays a backstop rather than the mechanism.
- **Structure preserved** → one customer order, one number, quoted across parties, addressed by both
  channels; D20's denormalisation stays safe, and the customer channel still reads as *the customer's own
  series*.

**Costs, stated:** the number stops being human-sortable (the counter remains the sort key internally), and
it must be said aloud over the phone — 6 base32 characters with no look-alike glyphs is chosen for exactly
that. ⚠ **And a key-management requirement:** the HMAC secret must come from **configuration, never
source** — this repository has already shipped a committed API key once (`nst-bl-vaisettings-CONTEXT.md`),
so a hardcoded key here would be a self-inflicted repeat.

**Two consequences elsewhere:** (1) the token vocabulary splits — **invoices keep `{counter}`** (GST wants
consecutive serials, and the invoice trigger already owns that number) while **orders use `{ref}`** — so
one vocabulary serves document types with opposite legal requirements. (2) `{ref}` needs a length token
like `{ref:6}`.

**✅ CONFIRMED BY THE REQUESTER 2026-09-28** — *"I like this format `ORD-XYZCORP-2026-27-7K4M2Q` rather than a
numeric one"*. **The no-key fallback below is withdrawn**, not merely deprioritised:
~~a CSPRNG suffix with a uniqueness check and a bounded retry — no key, but the dry run would verify
structure rather than exact strings~~.

**WHERE THE KEY LIVES — decided by precedent, not invented.** The tree already signs with a DB-stored
secret: the public invoice link is an *"HEX HMAC-SHA256 of PAYLOAD under VENDOR's own SALT"*, with the salt
stored on the vendor row and generated by `createciphersalt`. **Follow that: a system-level ref key stored
in the DATABASE, generated on first use** (a single-row secret alongside the counter table is the cheapest
home), **never in source**. Two reasons the source option is refused outright:

* 🚨 **`hhub/core/extkeys.lisp` is where this tree keeps secrets, and it keeps them IN GIT** — that file
  currently holds the **AWS SES SMTP username and password**, the **reCAPTCHA v2 secret** and the
  data.gov.in API key as plain `defvar`s (see F20). Putting the ref key there would defeat the whole point:
  anyone who can read the repository could enumerate every reference in the system.
* **No environment-variable mechanism exists anywhere in the tree** (no `getenv` of any spelling), so an
  env-var key would mean inventing a config path for this one feature — a second, undocumented convention.

**Fail closed if the key is absent:** refuse to mint rather than fall back to a default or a derived value.
A silent fallback would downgrade every reference to guessable while looking healthy.

**And one consequence of rotation worth writing down:** rotating the key can map two different counters onto
the same reference (counter 5 under key A, counter 9 under key B). Existing numbers are safe — they are
stored and never recomputed — but the collision is real for new ones, so **the unique index plus the bounded
retry is the guard**. Rotation is therefore supported, and the retry is not decoration.

| **F2** | **HIGH** | OWASP API1 | 🚨 **A sentence in this very file is the loophole.** D4 says a globally unique `ORDNUM` makes "a number-only lookup legitimate again". Uniqueness licenses an unambiguous **address**; it does **not** license a **tenant-less query**. Any resolution that drops the tenant predicate is textbook BOLA. | **MUST FIX (wording + code).** Rewrite D4's claim; every resolution stays `WHERE ORDNUM = ? AND TENANT_ID = ?`; add the AC that a valid ORDNUM from another tenant answers **404**. |
| **F3** | **HIGH** | OWASP API5 | **Authorization is unhooked.** The `DOD_AUTH_POLICY`/`DOD_BUS_TRANSACTION` rows are seeds, `:required-roles` is carried and read by nothing, and `*action-route-transaction-function*` is a no-op (D18). The only real protections are tenant scoping, channel narrowing and fail-closed 401 — anyone with a valid session of the right channel can call every endpoint. | **ACCEPTED RISK, stated.** Not a defect of this batch (the invoice endpoints share it), but it must be written down where the endpoints are, not left implicit. The 401-fail-closed AC is the mitigating control. |
| **F4** | **HIGH** | NIST 800-63B · OWASP API2 | **The live authentication defect undermines all of the above.** `check-password` compares only the first 8 bytes (`PENDING-WORK-CONTEXT.md` §1): any suffix is ignored. Session lifetime is 8h (customer) / session-bound to UA+IP, with no re-auth for sensitive writes. | **Out of scope, but must be named.** Any security statement about these endpoints is nominal until §1 lands. Cross-referenced, not solved here. |
| **F5** | **MED-HIGH** | OWASP API3 (BOPLA) | **`!update` has no field-level allowlist per channel** — it assigns any declared initarg, gated only by status. So a customer can set `:is-converted-to-invoice "Y"`, `:invoice-number`, `:invoice-date`, `:order-fulfilled "Y"`, or `:status "CMP"/"VCN"/"CCN"` directly, bypassing the fulfilment/cancel verbs **and the order→invoice link**. | **MUST FIX in S5.** A per-channel writable-field allowlist inside `!update` (and `make`), refusing everything else with a contradiction. This is the field-level half of the authorization model; the route-level scope narrowing does not substitute for it. |
| **F6** | **MED-HIGH** | Google AIP-155/industry | **`POST /orders` has no idempotency.** A retried create produces a duplicate order, burns counter values, and (via D14's assembly) duplicates vendor rows — with no transaction seam to roll any of it back. | **MUST FIX in S3/S12, and the fix is nearly free.** `DOD_ORDER.CONTEXT_ID varchar(100)` **already exists**, the legacy layer already stamps it with `(uuid:make-v1-uuid)` (`dod-bl-ord.lisp:406`), and `get-order-by-context-id` already reads it (`:255`). Require an idempotency key (header or `:context-id`), `?exists`-check it, and return the EXISTING order on a repeat. |
| **F7** | MED | OWASP API4 · AIP-158 | **No pagination or result cap on `enumerate`.** 485 rows today and unbounded growth; one `GET /orders` can exhaust memory/CPU. | **MUST FIX in S4.** `:limit` (default 50, **max 200**) plus a cursor/offset, documented in the binding. |
| **F8** | MED | AIP-154 · RFC 9110 | **No optimistic concurrency on `!update`.** Hydrate → write-all-slots is last-write-wins: two concurrent writers silently lose one's changes. | **FIX in S5.** `UPDATED` already has `ON UPDATE CURRENT_TIMESTAMP`, so it is a ready-made version token — ETag on read, `If-Match` on write, 412 on mismatch. |
| **F9** | MED | OWASP CSRF · AIP-193 | **CSRF is unaddressed.** Writes are authenticated by a session cookie, and nothing requires a JSON content type, an `Origin`/`Sec-Fetch-Site` check, or a `SameSite` cookie. | **FIX in S13.** Require `application/json` and reject others; validate `Origin`; set `SameSite` on the session cookie. |
| **F10** | MED | OWASP API4/API6 | **No rate limiting** — `apidefs2:617` says so in its own comment. Order placement is a sensitive business flow, and the counter is a burnable shared resource. | **FIX in S12/S13** (route-layer limit + a cap on counter increments per window), or ledger it as an accepted gap with the reason. |
| **F11** | MED | NIST AU-2/AU-3 · GST retention | **No audit trail, and the columns that exist are unwritten.** `emit-audit` is a stub, `:audit-level` is carried, the bus-transaction rows are seeds (S14) — and `CREATED_BY_USER_ID`/`APPROVED_BY_USER_ID` exist on the live table (`nst-dal-Order.lisp:504`) with **no writer anywhere**. | **PARTIAL FIX in S3, at near-zero cost:** populate `CREATED_BY_USER_ID` from the session at `make`. The rest stays on the ledger with the PEP work. |
| **F12** | MED | AIP-134 · RFC 9110 | **`PUT` carries merge semantics.** `!update` is a partial update exposed as PUT, which standards-following clients read as full replacement — and a field omitted from a full representation will not be cleared. | **DECISION REQUIRED.** Either use `PATCH` for orders, or document the deviation explicitly. ⚠ The invoice API already ships PUT-with-merge, so switching only orders creates two conventions in one product. |
| **F13** | LOW-MED | RFC 9457 · AIP-193 | **The error model is custom, and the classifier has gaps:** `api-status-for-condition` has **no 409 case** (so a sentinel-derived 409 is invisible to it), and a malformed body answers **500** where the contract says 400. | **FIX in S13 for the 400/409 part** (route-layer `api-client-error`); the error-envelope change is a shared-file change and belongs on the ledger. |
| **F14** | LOW | — | **The `A-Z0-9` charset is load-bearing, not cosmetic.** The number's delimiter is `-`, so a prefix containing `-`, or digits that mimic the FY, makes the number ambiguous to anything that splits it. And silent canonicalisation collides: `XYZ-CORP` → `XYZCORP` equals an existing `XYZCORP`. | **FIX in S0d:** the override must **REFUSE** a non-conforming value (so the user is told) rather than silently transform it — while the allocator may canonicalise at allocation time. And **no code may parse a number by splitting on `-`**: it is looked up whole. |
| **F15** | LOW | — | `UNIQUE (DOC_PREFIX)` permits **many NULLs**, so it does **not** enforce *every customer has a prefix*. That property is held by the allocator and the mint. | **Documentation.** Same class as the vacuous-duplicate measurement: do not read the index as the guarantee. |
| **F16** | LOW | product contract | **Our own spec promises more than we are building.** `nstoresapi.html:146` says `POST /orders` *"Atomically handles OTP verification, wallet deduction, and shipping address capture"*; this design is a document create. | **DECISION REQUIRED.** Either correct the spec text, or scope the batch wider — and if wallet deduction is in scope, financial controls apply and the single-entity design is insufficient. |
| **F17** | LOW | OWASP API9 | **The legacy writers stay live** — the legacy order UI actions and the old `/hhub/order*` handlers still create, cancel and fulfil orders, bypassing every new invariant (DFT, prefix, counter, scope). | **PARTIAL (S8b closes the prefix hole).** A full inventory/gating item goes on the ledger. |
| **F18** | LOW | WCAG 2.1 AA | The new profile field needs a real label, programmatic error text, and no colour-only signalling — the customer profile page is user-facing. | **FIX in S0d** (one line in the template's AC). |
| **F19** | LOW | OWASP API8 | `dispatch-route2` prints to stdout on every request (`PENDING-WORK` §5); log volume, not a leak — but it means request volume is unbounded in the logs too. | Already on the ledger; cross-referenced. |

### F20 — 🚨 pre-existing: live credentials committed in source (found by this review, NOT caused by this batch)

`hhub/core/extkeys.lisp` holds, as plain `defvar`s in a tracked file: the **AWS SES SMTP username and
password** (`*HHUBSMTPUSERNAME*` / `*HHUBSMTPPASSWORD*`), the **reCAPTCHA v2 site secret**, and the
**data.gov.in API key**. ⚠ And every file in this tree carries *"Distributed under the MIT License"* in its
header — so if the repository is ever published or shared beyond the team, these are live credentials in
public view, not merely an internal hygiene issue.

**Out of scope for this batch and NOT fixed here** (it is the vendor/notification domain, and rotating
production SMTP credentials is an operational act, not a commit). Recorded because **the new ref key must
not repeat it** (above), and because it belongs on the ledger where a human will see it: **rotate the three
secrets, move them to configuration, and add the file to a leak check.**

### S0e — the cross-cutting requirements, and who owns each

**Not new files.** S0e is a filter over the stories already planned, and it exists so no finding above
is lost between design and code:

| Finding | Owner story | Shape of the change |
|---|---|---|
| F1 (counter scope) | ✅ **CONFIRMED** | non-sequential `{ref}` token; invoices keep `{counter}`; the key is DB-stored (S0c) |
| F2, F5 | **S3, S5** | tenant predicate kept; per-channel writable-field allowlist |
| F6, F11 | **S3, S12** | idempotency on `:context-id`; stamp `CREATED_BY_USER_ID` |
| F7 | **S4** | `:limit`/cursor with a hard max |
| F8 | **S5** | ETag/`If-Match` on `UPDATED` |
| F9, F10, F13 | **S12, S13** | content-type + `Origin`; rate limit; 400/409 in the route layer |
| F12, F16 | **DECIDE NOW** | two contract questions, both cheap to answer and expensive to retrofit |
| F14, F18 | **S0d** | refuse rather than canonicalise; template labels |
| F15, F17, F19 | ledger | recorded, not this batch |
| **F20** | **ledger, then a human** | live credentials in `extkeys.lisp` — rotate, move to configuration, leak-check |

**Definition of done for S0e:** every finding in the table above is either **implemented with a named
site** or **explicitly accepted with a written reason** — no finding may be silently dropped, and none
may be discovered a second time during the smoke suites.

