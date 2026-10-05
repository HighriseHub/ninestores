# The VENDOR order channel — `nst-vordh` over `DOD_VENDOR_ORDERS` · CONTEXT

**Read this when** you are building, reviewing or debugging the **vendor** side of an order
(`GET`/`PUT /hhub/api/v1/vendor/orders…`), the `nst-vordh` entity or its प्रत्यय, the `DOD_VENDOR_ORDERS`
row that `POST /orders` writes — or when a vendor row's `ORD_DATE` moved on its own.

**Scope boundary, deliberate.** The customer channel (`nst-ordh` = `DOD_ORDER`, `nst-orditm` =
`DOD_ORDER_ITEMS`, the seven `/orders` paths) lives in `order-adhara-stories-CONTEXT.md` and is **not
restated here**. The two channels share the document number, the status vocabulary and the grammar, and
share nothing else: **different table, different traps, different scope rule, different owner**. Where
this file needs something from the customer side it cites the decision number (D1–D21, S1–S17) instead
of copying it.

**Status:** written 2026-10-04 at the start of S9, when the state was *"design settled, no vendor code
written"* and the customer channel was already implemented and committed (`12ebb4f`, `2c792a5`,
`07b0471`, `37d67f0`). **Superseded in place 2026-10-04/05 — the vendor code now exists, loads and is
offline-verified: S9, S10 and S11 are all DONE** (§0, §2–§4). S14–S16 and the live half of the
acceptance criteria are the batch file's business.

---

## 0. RESUME HERE

| # | pass | artifact | status |
|---|---|---|---|
| **S9** | the island: class + entity + models | `hhub/order/nst-dal-vordh.lisp` (new, inert) | ✅ **DONE 2026-10-04** — 60/60 columns, mirror invariant asserted, checker mutation-tested (§2) |
| **S10** | the six प्रत्यय, vendor-scoped | `hhub/order/nst-bl-vordh.lisp` (new) | ✅ **DONE 2026-10-04** — six verbs, 16/16 offline, STAGE: LOADED (§3) |
| **S11** | routes + the three bindings, and the assembly rewired to `make` | `hhub/order/nst-bl-vordhapi.lisp` (new) | ✅ **DONE 2026-10-04** — S13 (c) closed, 12/12 route probe, interim writer deleted (§4) |
| after | seeds · build+offline load · smoke suites | S14 · S15 · S16 | as first written: *"S14 written + verified, **NOT APPLIED**; S15/S16 next"* — **behind the batch file, see below** |

⚠ **THIS ROW IS BEHIND THE BATCH FILE, WHICH OWNS THE STATE.** `order-adhara-stories-CONTEXT.md` §0/§6
record S14 **APPLIED 2026-10-04**, S15 **DONE 2026-10-04** and S16 **IN PROGRESS** with AC (a)
**PROVEN 2026-10-05** (the first `POST /orders` → 201, `rowId 497`); where they disagree, that file wins.
**START A NEW SESSION THERE** — it carries the batch-wide state (story status, next actions, open
decisions, verification recipe, the live-image/database state). THIS file is the vendor channel's own
record (decisions V1–V15, the 60-column measurement, T9's vendor-only trap), deliberately not a duplicate.

**The one thing to know before reading further:** `DOD_VENDOR_ORDERS` is *not* `DOD_ORDER` with a vendor
column bolted on. It is a **denormalised copy of the order header, one row per (order, vendor)**, with a
different `ORD_DATE` **type** (§1), a second scope axis (`VENDOR_ID` **and** tenant, §5 V3), and its own
legacy class that must not be extended (§5 V1).
---

## 1. MEASURED (2026-10-04, live `hhubdb` — not recalled, not read off a create-script)

Framework rule, learned three times in the customer batch: **`installation/hhubplatform.sql` is fiction
for these tables** (`order-adhara-stories-CONTEXT.md` §1). Every line below came from `SHOW CREATE TABLE`
/ `information_schema` on the running database.

```
DOD_VENDOR_ORDERS — 60 columns, ENGINE=InnoDB, AUTO_INCREMENT=467
  PRIMARY  (ROW_ID)
  UNIQUE   uk_vo_order_vendor (ORDER_ID, VENDOR_ID)     ← one row per order+vendor, and it is UNIQUE
  KEY      TENANT_ID · idx_vo_is_converted · idx_vo_place_of_supply_code · idx_vo_gstnumber · idx_vo_created_by
  FK       DOD_VENDOR_ORDERS_ibfk_1 (TENANT_ID) → DOD_COMPANY (ROW_ID)
  ORDNUM          varchar(50)  NULL            ← D20: minted on the header, COPIED here, never minted here
  ORD_DATE        timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP   🚨 T9
  REQ_DATE        timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
  SHIPPED_DATE    timestamp NULL
  CREATED/UPDATED timestamp, UPDATED carries ON UPDATE CURRENT_TIMESTAMP
  STATUS char(3) · ORDER_TYPE char(4) · PAYMENT_MODE char(3) · DELETED_STATE char(1) NOT NULL DEFAULT 'N'
  ORDER_SOURCE enum('POS','ONLINE','WHATSAPP','API') DEFAULT 'ONLINE'
  SUPPLY_TYPE enum('INTRA_STATE','INTER_STATE')
  CUST_ID/ORDER_ID/VENDOR_ID  mediumint NOT NULL    ← all three NOT NULL
  money: ORDER_AMT, TOTAL_TAXABLE_VALUE, TOTAL_CGST/SGST/IGST/CESS, TDS_AMOUNT,
         TOTAL_DISCOUNT, TOTAL_TAX, SHIPPING_COST  decimal(15,2)
  flags: REVERSE_CHARGE_APPLICABLE, EWAY_BILL_REQUIRED, TDS_APPLICABLE  tinyint(1) DEFAULT 0
```

**🚨 T9 IS VENDOR-ONLY — MEASURED, and this is the nuance that makes this table its own workstream.**
`DOD_ORDER.ORD_DATE` is **`date`** with no auto-update; `DOD_VENDOR_ORDERS.ORD_DATE` is a **`timestamp`
with `ON UPDATE CURRENT_TIMESTAMP`**. Consequences, all of them live:

1. **Any** `UPDATE` that omits `ORD_DATE` rewrites it to `now()`. An *explicit* assignment in the same
   statement beats the auto-update; omission does not.
2. The legacy writers have this defect today: `cancel-order-by-vendor` (`dod-bl-ord.lisp:330`) and
   `update-order` (`:313`) use `update-records-from-instance` / `update-record-from-slot`.
3. **The header's own type decision is wrong here.** `dod-order` declares `ORD_DATE` as `clsql:date`,
   which is correct for a `date` column — but reading a `timestamp` as `clsql:date` **drops the
   time-of-day**, so writing that value back silently moves the row to midnight: AC (f)'s byte-identity
   assertion fails *even when the auto-update is defeated*. See §5 V5 for the declaration this class
   uses instead.

**The legacy class is 34 columns behind.** `dod-vendor-orders` (`order/dod-dal-ord.lisp:15`) declares
**26** slots against **60** live columns, with zero phantom columns. It gained exactly one slot in the
customer batch — `ordnum` (D20) — because the interim vendor-row writer needed it before S9 existed.

**Type map used by every view class in this repo** (measured over the order DAL classes, so the new class
cannot invent a third convention): `decimal(15,2)→float` · `mediumint/int→integer` · `varchar(n)/char(n)
→(string n)` · `date→clsql:date` · `tinyint(1)→integer` · `text→string` · `enum→(string n)` sized to the
longest member · **`timestamp→(string 30)` when the value must round-trip** (§5 V5).

---

## 2. S9 — the island: `hhub/order/nst-dal-vordh.lisp`

### S9 — DONE (2026-10-04). The file exists and is inert.

| artifact | what was built |
|---|---|
| `hhub/order/nst-dal-vordh.lisp` (new, 6 top-level forms) | view class `dod-vendor-order` over **60/60** live columns · entity `nst-vordh` **56 slots** (row-id + 55 business) · `NstVordhRequestModel` (slotless) · `NstVordhResponseModel` **57 slots** · `*vordh-mirrored-slots*` **56 entries** |
| `hhub/package/compile.lisp:172` + `hhub/nstores.asd:149` | registered in **both** lists (a file in one list only compiles to a fasl nobody serves) |
| `aiharness/deepseek/tools/nst-vordh-mirror-check.lisp` (new) | the offline shape check: **11 checks, 0 problems** on the clean file |

**AC (a) ✓** — its own class; the legacy `dod-vendor-orders` class is untouched (its `ordnum` slot from the
customer batch is the only change it has ever had).

**AC (b) ✓ — a mechanical check, not a claim:** the class's declared 60 `:column` names are dumped from the
source and diffed against `information_schema.columns` for `DOD_VENDOR_ORDERS` → **set-equal: 0 missing, 0
phantom** (§1). A diff by table ordinal would show only reordering — CLSQL does not care, every slot names
its own `:column` — which is why the check compares sets.

**The mirror invariant, which is the one that caused the invoice outage:** entity-minus-row-id plus
`deleted-state` == the mirror list (56), and the mirror list plus `row-id` == the response model (57). One
entry with no response slot signals `MISSING-SLOT` on **every** response, so this is asserted offline, not
discovered as a 500.

**The checker was mutation-tested** — two mutations, both caught and named: (i) renaming one `:column` →
`FAIL the class is MISSING 1 live column(s): COUNTRY` + `FAIL … 1 PHANTOM column(s): COUNTRYS`; (ii) adding
one mirror entry with no entity slot →
`FAIL mirrored but NOT an entity slot (MISSING-SLOT on every response): GHOST-SLOT` + the matching
`domain->response would SETF` line. It also found a bug in the
checker's own summary line — `~:[FAIL (~D problem(s))~;PASS (~D check(s))~]` takes ONE `~D` after the
conditional, so a failing run read "FAIL (10 problem(s))" when it had 2. The rule behind all of this, the
`~:[…~;…~]` argument-count trap that bit three files in the customer batch, and the three other
checker-bug classes are `knowledge/offline-checker-methodology-CONTEXT.md` §1–§3.

**⚠ The two `nst-preflight.lisp` lists, both hit and fixed:** `*files*` (delimiter balance) **and**
`*hhub-new-files*` (build registration) are **separate**, and a file in the first but not the second is
balanced and then **silently skipped** — a pass that means nothing. Both are now updated, and the preflight
reports `ok hhub/order/nst-dal-vordh.lisp (6 top-level forms)` (methodology file §4).

Inert, exactly like `nst-dal-ordh.lisp` — a class, an entity, two boundary models, a mirrored-slot list; no
प्रत्यय, no copiers, no render. **AC (a) and (b) live here.**

**Three artifacts, in the order the file declares them:**

1. **The ORM view class over ALL 60 live columns** — new, named `dod-vendor-order` (singular; the legacy
   `dod-vendor-orders` stays exactly as it is). Recipe copied from `dod-order`
   (`nst-dal-Order.lisp:482`): slotless base `()`, `row-id` is `:db-kind :key :db-constraints :not-null
   :column "ROW_ID" :type integer`, and the class ends `(:base-table "DOD_VENDOR_ORDERS")`. Every slot
   names its own `:column` — kebab-case here is a coincidence of this table, not a rule (the header's four
   non-derivable names are the counter-example). **No `:db-kind :join` slots:** `customer`/`order`/
   `vendorobject` on the legacy class are joins, not domain state, and this batch's doctrine excludes them
   (`nst-dal-ordh.lisp`'s header says so); a verb needing the vendor's or customer's own row calls the
   tenant-scoped BL lookup, as the customer-channel assembly already does.
2. **Tree-1 entity `nst-vordh (nst-domain-entity)`** — never `BusinessObject`, never a boundary class;
   `row-id`/`tenant-id`/`created-at`/`updated-at`/`deleted-state` inherited, never redeclared (नियम-1: the
   tenant can only come from `domain-ctx`). Money slots get an explicit `:initform 0.0` and char flags
   `"N"`/`"Y"` — CLSQL declares these `decimal` columns `(OR NULL FLOAT)` and *validates on insert*, so an
   ordinary JSON integer `0` fails the INSERT and surfaces as `:U`/503 "the database call did not answer".
   That cost the invoice batch two days; it is a fixed defect, not style.
3. **`NstVordhRequestModel` (SLOTLESS), `NstVordhResponseModel`, `*vordh-mirrored-slots*`** — slotless
   inbound because `request->dispatch` reads only `(params rm)`; the response model because
   `domain->response` setfs every mirrored slot onto it; `deleted-state` is **declared on the response
   model and mirrored although it is inherited**, because that one missing declaration is what made every
   invoice endpoint answer 500 (`nst-invoice-mirror-check.lisp`).

---

## 3. S10 — the six प्रत्यय, and the vendor scope rule

### S10 — DONE (2026-10-04). `hhub/order/nst-bl-vordh.lisp`, 36 top-level forms.

Six universals as everywhere (`make` `fetch` `enumerate` `!update` `delete!` `?exists`), on the ADHARA
grammar — `domain-ctx` last, `with-db-call`, sentinels not nil — all Belnap (`entity` or `nst-entity-*`
sentinel; `:U` never phrased as "not found"), the tenant only ever from `domain-ctx` (नियम-1). **Every
read is scoped in the SQL, and triple-scoped** (§5 V3): `VENDOR_ID = the logged-in vendor` **AND** `TENANT_ID = the
session tenant` **AND** `DELETED_STATE = 'N'`. Dropping any one of the three is a
cross-tenant or cross-vendor read; AC (c) states it as a *measurable* criterion — a second vendor's row in
the same tenant must be invisible to the first.

| प्रत्यय | what it does, and the decision inside it |
|---|---|
| `?exists` | By ORDNUM **for this vendor** (`&key vendor-id`). `:F` free / `:T` live holder / `:C` soft-deleted holder or >1 row / `:U` DB silent. The vendor is a KEY, not a filter: another vendor holding the same number is the NORMAL case, so an answer without `:vendor-id` is about the tenant and is not a green light to insert. Scoped existence is also what the route layer uses to tell 404 from 409. |
| `make` | One row per (order, vendor), **carrying the minted `ORDNUM`** (D20) — called by `route-ordh-create`'s D14 assembly, one row per distinct vendor. **`:around` gives idempotency keyed on the table's own `uk_vo_order_vendor`** — a retried assembly returns the existing row instead of meeting the unique key as a raw INSERT failure, after the header and its lines were already written. Guards: the four NOT NULL keys, then the vendor resolved through `select-vendor-by-id-in-tenant` (the legacy writer's lookup has no tenant predicate — that BOLA shape is not inherited). Forced values PEN / "N" / "N". **This promotes the interim writer** `ordh-vendor-order-insert` (deleted in S11, §5 V14) and the legacy `persist-vendor-orders` (`dod-bl-ord.lisp:590`), which §5 V6 retires once `nst-vordh` owns the write. |
| `fetch` | By ROW-ID, tenant + live; unparsable id → `nst-entity-nil`, never an error. The channel addresses it by **ORDNUM**, scoped — the route resolves `{ordnum}` + session vendor → row-id (§5 V10/V12). **A row whose `ORDNUM` is NULL answers 404, never a guess** (AC e): 462 of the 462 pre-migration rows were NULL, so an `ORDNUM IS NULL` fallback would hand every caller the same wrong row. |
| `enumerate` | The vendor's worklist; `:vendor-id` **required**, and its absence is a REFUSAL, not an unfiltered list. Paginated, scoped; empty page = `'()` = 200 `[]`. The customer's number is *visible* here by design (D20/F1 — the resolved commercial-confidentiality position). |
| `!update` | Five questions in order: exists → vendor matches → not terminal → channel may write these fields (§5 V8) → If-Match matches. Writes whole-row from the hydrated entity. Refuses the six keys that would move identity or scope (`:vendor-id :tenant-id :ordnum :row-id :order-id :cust-id`, AC d); refuses a **terminal** status (`*order-terminal-statuses*` = CMP/VCN/CCN, AC g); **re-assigns `ORD_DATE` explicitly** (AC f, §5 V5). |
| `delete!` | Internal channels only (§5 V9); soft-delete is a single-column write so nothing else can move. Follows D8, the लोप cascade already used on the customer side. |

**AC coverage, stated rather than implied**

| AC | where it is enforced |
|---|---|
| (c) a vendor sees only its own rows | **in the BL**, on `enumerate`, by requiring `:vendor-id` — fail-closed, so no future caller can obtain the cross-vendor list by forgetting an argument |
| (d) cannot move to another vendor/tenant, cannot change ORDNUM | three ways: `:vendor-id`/`:ordnum`/`:order-id`/`:cust-id` are **stripped** (unassignable), a `:vendor-id` supplied as scope is **verified against the row** before the write, and `:tenant-id` can only come from ctx |
| (e) NULL ORDNUM → 404, never a guess | **structural, not a branch**: `[= [:ordnum] ordnum]` cannot match NULL, so such a row is unreachable and the answer is `:F`. There is deliberately no `OR ORDNUM IS NULL` fallback |
| (f) ORD_DATE byte-identical, UPDATED advanced | **by construction**: `ord-date` is in `*vordh-mirrored-slots*`, the copier walks that list, and the write is whole-row — so the value READ is written BACK, and an explicit assignment beats `ON UPDATE`. `updated` is not in the list, so it keeps its own auto-update. V5's `(string 30)` is what makes the round trip exact |
| (g) terminal status refused | first gate in the verb. Not a corner case: **387 of 466 live rows are CMP**, 4 VCN. (a)(b) are S9's, re-asserted here at 16/16 |

**AC (f) must not be weakened**, because it is the only way the T9 corruption becomes visible: *after
`PUT /vendor/orders/{ordnum}`, `ORD_DATE` is byte-identical to what it was before, and `UPDATED` has
advanced.* A test that does not assert this cannot see the bug.

**Verification — 16/16 offline, and the checks were themselves mutation-tested:**
`aiharness/deepseek/tools/nst-vordh-mirror-check.lisp` now covers the DAL **and** the BL:
`the JSON allowlist is complete: 56 published + 1 withheld = 57 carried by the response model` and
`the field policy partitions the entity: 13 + 1 + 4 + 28 + 16 keys, every slot in exactly one list,
no control key is a slot`. `nst-preflight` PASS (0 problems); offline load **STAGE: LOADED** with
`nst-bl-vordh.fasl` rebuilt.

**Four bugs the checks found — three of them in the checker, which is the point of mutation-testing.** All
four, with the exact finding and the fix, are the four bug CLASSES at
`knowledge/offline-checker-methodology-CONTEXT.md` §2: the `[` reader (a HEALTHY file called unreadable),
`find-render-json` walking one level too shallow, the published-slot extractor seeing only a bare
`(accessor r)`, and the JSON universe being the RESPONSE MODEL rather than the mirror list.

⚠ **One substantive rule carried from S10 into S11:** **`!update` consumes scope/control keys before the
field policy** (the S12 defect, restated for a scope key: a `:vendor-id` reaching the policy would be
refused as an escalation, and would refuse every legitimate update).

**Also fixed — TWO REDUNDANT `tenant-id` PARAMETERS** (found by the human reading the code, 2026-10-04).
`nst-vendor-order-insert` took `(entity ctx tenant-id)` and never used the argument — the tenant travels ON
THE ENTITY (from the ctx, नियम-1) and the copier pins it there, so it was a *second answer* to 'whose row is
this', whose quiet failure mode is a caller whose tenant disagreed with the entity's writing a row whose
`TENANT_ID` contradicts the entity it was built from, with nothing complaining. It is **DELETED rather than
muted** (`(declare (ignore …))` would have hidden the redundancy the warning pointed at), and the same
pattern in `ordh-create-vendor-rows (lines header ctx tenant-id)` — papered over with
`(declare (ignorable …))` — was deleted with its call site, so all four touched files now compile with
**0 warnings**. Why neither `ql:quickload :silent t` nor the offline-load log showed it (SBCL is silent about
an unused *required* parameter; it warns about `let`/`&optional`/`&key`, not this), and the `compile-file` +
`*error-output*` sweep that finds it, are `order-adhara-stories-CONTEXT.md` §0 trap 7.

**Still open from S10 — one policy question; the two other items were executed in S11 (§4):**
* **The 8-row divergence, MEASURED:** 8 vendor rows are live while their header order is
  `DELETED_STATE='Y'` (and 9 PEN rows are themselves soft-deleted). AC (c) scopes by the vendor ROW,
  so the vendor channel will still show those 8. The real fix is not in this file: the customer
  channel's `delete!` does not cascade to vendor rows, and arguably it should — otherwise deletion
  is a lie in one direction. Flagged rather than silently changed.
* S10's two other open items — the assembly rewire (`ordh-vendor-order-insert` → `(make 'nst-vordh …)`, then
  deleting that function) and the route-level vendor narrowing for `fetch`/`delete!` (V10) — were **both
  EXECUTED in S11** (§4, §5 V12/V14).

---

## 4. S11 — the three routes and their bindings

### S11 — DONE (2026-10-04). `hhub/order/nst-bl-vordhapi.lisp`, 20 top-level forms.

**Evidence:** `nst-preflight` **PASS (0 problems)** (exit 0, read from the process, not from a pipe);
`nst-binding-order-check` **PASS** (52 bindings, every one after its registration in load order); offline
load **STAGE: LOADED** with `nst-bl-vordhapi.fasl` rebuilt; and **S13 (c) CLOSED** —
`aiharness/deepseek/tools/nst-vordh-route-probe.lisp` **12 checks, 0 problems** against the LOADED route
table: the three vendor paths resolve to their own routes, all five customer paths still resolve to theirs
(not shadowed), the `{ordnum}` segment carries its value into the params alist, and two negative controls —
an unbound path, and `DELETE` on the vendor path, which V9 deliberately does not bind — resolve to *nothing*.

**V14 and V15 executed — and V15 is why the promotion was worth doing.** `ordh-vendor-order-insert` is
**DELETED** from `nst-bl-ordhapi.lisp`; the assembly calls `(make 'nst-vordh ctx …)` through two new
functions there — `ordh-vendor-row-date` (the header's `clsql:date` → the `YYYY-MM-DD` string V5's
`(string 30)` slots take) and `ordh-vendor-row-initargs` (~45 fields off the header) — and
`ordh-create-vendor-rows` now tests `(typep written 'nst-vordh)` instead of the old `(eq written t)`. One
writer for the row; that is what stops two drifting.

**V15, and why the promotion was worth doing:** the interim writer could only reach the 26 columns the
legacy class declares, so `SHIPCITY`/`SHIPSTATE`/`SHIPZIPCODE`, the four billing columns and the entire tax
block were NULL on every API-created vendor row; the vendor row is now self-sufficient. **The order's
`TOTAL_*` columns are still deliberately NOT copied** — they are the ORDER's figures, and writing them into
one vendor's row would overstate that vendor's slice by every other vendor's share. They keep the 0.00
defaults; per-vendor tax arithmetic is a later pass's.

**The trap that cost this pass two minutes and is worth recording:** a probe or tool that reads the
tree's own symbols must be `in-package :nstores` AFTER the tree loads — a tool left in `CL-USER` fails
with `The function COMMON-LISP-USER::FIND-API-ROUTE is undefined` *after* a four-minute load, which reads
exactly like a missing binding (`knowledge/offline-checker-methodology-CONTEXT.md` §4).

`hhub/order/nst-bl-vordhapi.lisp`. The spec (`nst-bl-apidefs2.lisp` / `nst-bl-conflodis2.lisp`) has **no**
vendor-orders endpoint at all — these three paths are ours (D3). The live vendor family already carries
`/api/v1/vendor/profile`, `/payment`, `/shipping` in `vendor/nst-bl-vndapi.lisp`.

**The three routes, with the parameters each one pins:**

| method | path | verb and pinned parameters |
|---|---|---|
| GET | `/hhub/api/v1/vendor/orders` | `enumerate` — `:vendor-id` **from the session** (never the query string), plus the caller's `status`/`ordnum-like`/`from-date`/`to-date`/`sort-by`/`sort-dir`/`limit`/`offset`; the sort/page guards are the SHARED ones (`nst-ordh-sort-column` with `*vordh-sort-whitelist*`, `nst-ordh-page-limit`) so the vendor channel cannot invent a second meaning for `:asc` |
| GET | `/hhub/api/v1/vendor/orders/{ordnum}` | `vordh-row-from-url`, then `fetch` by the resolved row-id; emits `ETag` from a **re-read** row |
| PUT | `/hhub/api/v1/vendor/orders/{ordnum}` | `vordh-row-from-url`, then `!update` with `:vendor-id` from the session, the caller's `If-Match`, and the body's fields — which the BL's field policy then judges (V8) |

Each is a Tier-2 action route (`register-action-route`) with its `register-api-route` binding **in the
same file, immediately below the registration** — a binding that precedes its registration is refused at
LOAD time, which is a startup failure, not a 404 (`../tools/nst-binding-order-check` catches it offline;
the rule is `order-adhara-stories-CONTEXT.md` T1). `:auth-scope :session`; the creates elsewhere in the
batch carry `success-status` 201, these three carry none (no create here). Path params beat the body
(`api-params-for-request` precedence), so `{ordnum}` cannot be displaced by a body key — and AC (d)'s
"cannot move a row to another vendor or tenant" is enforced at the route by stripping
`:vendor-id`/`:tenant-id` **after** the address has been resolved.

**This closes S13 (c)**, which has been untestable since the customer channel shipped: `/vendor/orders`
and `/orders` must not shadow each other under `find-api-route`'s fewest-parameters-first ranking.

**The session (measured, not assumed): a vendor session already yields a correct tenant in `domain-ctx`
with no work from this file** — `make-action-domain-ctx` takes it from `conflodis2-login-company`
(`core/nst-bl-conflodis2.lisp:148`), which resolves the acting company **vendor → customer → user**
(अधिकरण), and the vendor identity comes from `conflodis2-session-value :login-vendor`
(`conflodis2.lisp:138`), **never** from `hunchentoot:session-value`: reading it directly signals
UNBOUND-VARIABLE outside a request, so "we cannot tell who you are" would reach a REPL caller as a 500
instead of the 401 this must answer. The precedent is `vendor/nst-bl-vndapi.lisp:353-364`; the whole trap is
`order-adhara-stories-CONTEXT.md` §0 trap 11.

**What S11 deliberately does NOT do:** no `DELETE` binding (V9 + D3), no `/fulfill` or `/cancel` (out of
scope), and **no nested lines** — a vendor legitimately needs to know *what* to ship, and that needs a
vendor-scoped line read in `nst-bl-orditm.lisp` (the line entity's enumerate filters by order, not by
vendor). The last is recorded as an open item rather than half-done here. Also **no new response class**:
the detail and list paths ferry `NstVordhResponseModel` through the shared `domain->response` and the
layer's list renderer, exactly as the customer channel does.

---

## 5. Decisions specific to the vendor channel — V1–V15

The customer batch's D1–D21 still govern the grammar, the number, the statuses and the ferries. These are
the ones this table adds, numbered **V** so they never collide with D. V1–V7 were settled before S9,
V8–V10 came out of S10, V11–V15 were agreed before S11 was written.

| # | decision | why |
|---|---|---|
| **V1** | `nst-vordh` gets its **own** view class over all 60 columns; the legacy `dod-vendor-orders` class is left alone. | D9, and T5: extending it in place changes a live SELECT's column list as a *side effect of an order change*. |
| **V2** | The new class declares **no** `:join` slots. | Joins are not domain state; the legacy class's three joins are what made it look "complete" while it carried 26 of 60 columns. |
| **V3** | Scope is `VENDOR_ID` **and** tenant **and** `DELETED_STATE='N'`, in the BL, on every read. | F2's lesson: a sentence of a design licensed a tenant-less lookup once already. The vendor axis is new — a tenant-correct read can still be the wrong *vendor*. |
| **V4** | `ORDNUM IS NULL` → **404**, never a fallback to `ORDER_ID`/`ROW_ID`. | 462/462 legacy rows are NULL; a "best effort" address would silently return a stranger's order. |
| **V5** | In the new class, **`ORD_DATE`/`REQ_DATE`/`SHIPPED_DATE` are declared `(string 30)`**, not `clsql:date`. The `!update` re-assigns `ORD_DATE` from the value it read, in the same statement. | T9 vendor-only: the column is a `timestamp` that auto-updates, so (i) omission rewrites it and (ii) a `clsql:date` read **drops the time**, making the write-back wrong even when (i) is handled. `(string 30)` round-trips byte-identically and is already the repo's production choice for `timestamp` slots (`dod-order`'s `CREATED`/`UPDATED`). **Prove it in S16** — measure the reader, not the DDL. |
| **V6** | `make` **promotes** the interim writer `persist-vendor-orders`; once `nst-vordh` owns the write, the legacy function is retired rather than left as a second path. | Two writers for one row is how the customer batch's ORDNUM hole reopens (S8b). |
| **V7** | `vendor-id`, `tenant-id`, `ordnum`, `row-id`, `order-id`, `cust-id` are **never** updatable through `PUT`. | AC (d): identity and scope are address, not payload. This is the vendor analogue of S12 (c)'s verify-then-strip rule. |
| **V8** | The vendor may write exactly four fields: `:order-fulfilled :shipped-date :comments :external-url`. **Money is not here** (a vendor grading its own invoice), **the addresses are not here** (they are the customer's instruction), **the lifecycle is not here** (`:status`/`:is-cancelled` move through a verb, not a field assignment; the vendor states FACTS and the transition is a later verb's business). Internal channels additionally get 28 fields — the schedule, addresses, tax identity, payment mode. **The one decision in S10 worth a second opinion: it is deliberately narrow, and widening it is one line at a time.** | F5/OWASP API3; an allowlist whose default is ALLOW is not an allowlist |
| **V9** | `delete!` refuses every external channel. D3 binds no delete route on this channel, and a vendor erasing its slice would remove the row the CUSTOMER's order is accounted for by. A vendor that stops supplying CANCELS (VCN) — a cancellation keeps the history. | D3 + the accounting relationship |
| **V10** | The vendor channel's address is the **ORDNUM**, scoped by the session vendor, not a row-id — `(ORDNUM, VENDOR_ID)` is the row's natural key. Where the grammar permits a key (`enumerate`, `?exists`, and `:vendor-id` read off `!update`'s `&rest`) the BL enforces the vendor; where it does not (`fetch` and `delete!` are congruent at three fixed arguments), the ROUTE narrows — exactly as `ordh-header-from-url` does for the customer today. **The residual risk is stated: a direct caller of `fetch` that skips the route gets tenant scope only.** | the generics in `nst-bl-adhara.lisp:704-754` |
| **V11** | **No session vendor ⇒ `nst-entity-nil` (404), not 403 and not an error.** The layer above already answers 401 for no session at all; by the time a route runs, "signed in but not as a vendor" is a *narrowing* fact, exactly as "signed in but not as this customer" is on the customer channel. | mirrors S12 (d) |
| **V12** | **The address resolver is `vordh-row-from-url`**, and it is the ONLY place the vendor narrows `fetch`/`!update`/`delete!` (V10). It takes `{ordnum}` + the session vendor, resolves through S10's `nst-select-vendor-order-rows-by-ordnum`, and answers one 404 for every way of failing — wrong number, another vendor's row, another tenant, soft-deleted, NULL ORDNUM. **A 403 would confirm that another vendor's row exists.** | F1/D5, the customer channel's own reasoning |
| **V13** | **`If-Match` is supported on the PUT and answered as 412, never 409**, with the response written by the route (`api-write-json`) because the shared classifier knows no 412 — the same documented exception S12/S13 carries. The fresh validator is **re-read** after the write if an ETag is emitted; a token taken from the verb would be STALE (UPDATED is DB-managed). | RFC 9110 + S12/S13 |
| **V14** | **The assembly is rewired to `(make 'nst-vordh …)` and `ordh-vendor-order-insert` is DELETED** (executed — §4). `ordh-create-vendor-rows` stays in the customer api file as the assembly's LOOP (one row per distinct vendor, written LAST so a refused line leaves no orphan row); only the raw class write moves. | S8b's lesson: two writers for one row is how the ORDNUM hole reopens |
| **V15** | **The row `make` writes carries the header's address, tax and schedule block** (executed — §4) — what the legacy `persist-vendor-orders` never wrote; the interim writer says so explicitly and defers the decision here. The vendor must be able to ship and to tax without reading the customer's header, and DOD_VENDOR_ORDERS has the columns for exactly that. The one conversion that is not a copy: the header's `ord-date`/`req-date` are **`clsql:date` objects** and this class declares `(string 30)` (V5), so they go through `get-datestr-from-obj-yyyymmdd`. | V5 + the table's own denormalised design |

---

## 6. Traps carried, and the one way each is caught

| # | trap | caught by |
|---|---|---|
| T9 | `ORD_DATE` rewritten by the auto-update (vendor-only, §1) | AC (f) byte-identity assertion + V5 |
| T6 | an in-image class definition that errors **wedges `ensure-class` for the process life** (SBCL PCL global mutex); only a restart recovers | S15: **restart, never `load`** — and check the acceptor with `ss -ltn \| grep 4244`, because a live `sbcl` does not imply a live acceptor |
| D20 | every vendor row carries the customer's `ORDNUM` | intended: it is what F1's resolution chose. Do not "fix" it by minting per vendor — the number is the customer's document. |
| — | the vendor **login cap**: 2 concurrent vendors, evicted oldest-first (`build-and-load-CONTEXT.md` §7) | any S16 test that needs two vendors to prove AC (c) must log in sequentially, not concurrently |

## 7. Verification recipe (offline first — this batch's rule)

```sh
cd /home/ubuntu/ninestores
XDG_CACHE_HOME=$PWD/.asdf-cache sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-preflight.lisp   # reader balance · SQL quoting · build registration
aiharness/deepseek/tools/nst-binding-order-check              # every binding follows its registration
XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --script aiharness/deepseek/tools/nst-offline-load.lisp   # → STAGE: LOADED
```

The batch's full recipe (six tools, plus the one-time `/tmp/nst-asdf/clsql-dist` prerequisite) is
`order-adhara-stories-CONTEXT.md` §0; it is not repeated here.

Live-only, and therefore S16's: the 401/404 sweep over the three vendor paths, the second-vendor
invisibility test (AC c), and the `ORD_DATE` byte-identity assertion (AC f).
