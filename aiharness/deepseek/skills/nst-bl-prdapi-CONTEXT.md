# SKILL: nst-bl-prdapi — Products on conflodis2 + apidefs2 · CONTEXT

**Read this when:** you are touching a product/catalog route or the product verbs — a
`/hhub/api/v1/catalog/products…` request that 404s, 409s or answers the wrong status; a product
JSON field that is missing, `null` or published under the wrong name; a list filter that is
silently ignored; or you need the products schema facts, the bound surface, or what was
deliberately left unfinished.

**Status:** the work of **2026-09-12/13** (§2 schema VERIFIED by SQL; compilation VERIFIED;
routing/auth VERIFIED by probe; read path exercised 12/13), the write path exercised
**2026-09-20** (**34/34** with `--write`), `status`/`copy`/`template`/`bulk` bound 2026-09-20,
§8b found 2026-09-20. **Split 2026-09-20; §7.1 and §7.4 reconciled against the source tree
2026-10-05.**

**Applies to:** `hhub/products/{dod-bl-prd,dod-dal-prd,nst-bl-prdapi,nst-bl-prodapi}.lisp`; the
products half of `hhub/core/{nst-bl-adhara,nst-bl-conflodis2,nst-bl-apidefs2,nst-mult-logic,nst-bl-beltrusys}.lisp`;
`test/smoke-products-api.sh`; the running image on `127.0.0.1:4244`.

**Purpose of this file.** Working context for whoever continues the PRODUCTS migration to the
new architecture (adhara → conflodis2 → apidefs2): what exists, why it is shaped that way, what
is verified, and what is deliberately unfinished. Read this before touching
`products/dod-bl-prd.lisp`, `products/dod-dal-prd.lisp` or `products/nst-bl-prdapi.lisp`.
**Date of the work recorded here:** 2026-09-12 (evening session); later sections carry their own
dates.

**READ THIS FIRST — the verification status.** The companion file
`core/nst-bl-apidefs2-CONTEXT.md` distinguishes *verified* (exercised against the running
server) from *reasoned, not yet run*. Here: **§2** is VERIFIED by direct SQL against the live
database; **COMPILATION** is VERIFIED (the four touched files produced `.fasl`s — `nst-bl-apidefs2`
23:58:35, `dod-bl-prd` 23:58:36, `nst-bl-prdapi` 00:00:22, `dod-dal-prd` 23:34:27, 2026-09-12/13 —
so all ~25 new forms compile: no paren errors, no wrong `&key`, no non-congruent `defmethod`, no
load-time failure); **ROUTING and AUTH (Ring 4)** is VERIFIED (2026-09-13 probes: the five product
bindings answer **401 unauthenticated** without a session, an unbound path **404
`no_such_endpoint`**); **READ** is exercised (2026-09-13, `test/smoke-products-api.sh` with a real
vendor session, **12 of 13 checks passed** — the failure being the soft-delete `:C` path answering
500 instead of 409, fixed in source that day); **WRITE** is exercised (2026-09-20, `--write`,
**34/34**, including `make` 201, `!update` 200 and `delete!` 200 ack). The recipe, transcript and
smoke record are §10–12 of `products-api-verification-CONTEXT.md`, which owns them.

**This header was corrected on 2026-09-13.** It was written on the evening of 2026-09-12 saying
nothing had been compiled or run — true when written, false within the hour: the image was
rebuilt at 23:58–00:00 and the acceptor restarted at **07:56 on 2026-09-13**, so it runs the
current code. A restart calls `reset-session-secret`, killing every older cookie.

---

## 1. Where things live

| File | Role |
|---|---|
| `hhub/products/dod-dal-prd.lisp` | **Legacy CLSQL view-classes** (`dod-prd-master`, `dod-product-pricing`, `dod-product-gst`, `dod-prd-catg`, `dod-gst-sac-codes`) **PLUS, appended at the end, the NEW domain layer**: `nst-prd`, `ProductRequestModel`, `ProductResponseModel` |
| `hhub/products/dod-bl-prd.lisp` | **Legacy product functions** (`persist-product`, `create-product`, `select-product-by-id`, …) **PLUS the NEW Tier-1 प्रत्यय**: `?exists`, `make`, `fetch`, `!update`, `delete!`, `enumerate`, plus `copyProduct-domaintodb` / `copyProduct-dbtodomain`, `generate-product-code`, `select-product-by-code`, `select-products-by-filter`, `domain->response`, `render-json` |
| `hhub/products/nst-bl-prdapi.lisp` | **NEW.** Route-action verbs (`route-product-*`), their `register-action-route` entries, and the `register-api-route` bindings |
| `hhub/products/nst-bl-prodapi.lisp` | **STALE, INERT.** Twelve `register-outbound-route` sketches for the pre-conflodis2 registry. None of the classes it names exist; its `/api/v1/...` paths are unreachable. See §7.5 |
| `hhub/core/nst-bl-adhara.lisp` | Domain root, sentinels, `request->dispatch`, `extract-domain-initargs`, `*reserved-initargs*`, the six universal प्रत्यय, `domain->response`, `render-json` |
| `hhub/core/nst-bl-conflodis2.lisp` | Tier-2 dispatcher: `register-action-route`, `dispatch-route2`, `make-action-domain-ctx` |
| `hhub/core/nst-bl-apidefs2.lisp` | Ring-4 JSON boundary: `register-api-route`, one `^/hhub/api/v1/` handler, status mapping. **Changed 2026-09-12/13 — §3** |
| `hhub/core/nst-mult-logic.lisp` + `hhub/core/nst-bl-beltrusys.lisp` | `with-db-call`, `with-nst-db-create/update/delete/read-all`, `bind-generated-row-id`; Belnap: `bo-knowledge`, `bo-knowledge-truth`, `bo-knowledge-payload`, `bo-merge`, `make-bo-knowledge` |

Build wiring (both are `:serial t`, and both now list `products/nst-bl-prdapi`):
`hhub/package/compile.lisp` (line 196) and `hhub/nstores.asd` (line 151).

**Ordering is load-bearing.** `nst-bl-prdapi.lisp` calls `register-action-route` at load time,
so it must come after `adhara`/`conflodis2`; and it names `nst-prd`/`ProductRequestModel`, so it
must come after `dod-dal-prd`/`dod-bl-prd`. In `nstores.asd` that means line 151 (the products
block), **not** line 81 next to `products/nst-bl-prodapi`, which sits *before* `adhara` at line
88.

---

## 2. Schema and data facts (VERIFIED by SQL, 2026-09-12)

`installation/hhubplatform.sql` **is stale for this table** — exactly as
`nst-bl-apidefs2-CONTEXT.md` warns for `DOD_WAREHOUSE`. Do not use it as the source of truth.
Verified live:

* `DOD_PRD_MASTER.PRODUCT_CODE varchar(50) NOT NULL UNIQUE` is the **ONLY unique key** — and the
  table carries it **twice** (`PRODUCT_CODE`, `PRODUCT_CODE_2`). Identity is a single global
  column, **not** a tuple and **not** tenant-scoped. There is **no** unique key on
  `(PRD_NAME, TENANT_ID)` and none on `SKU`.
* The live table has `current_price`, `current_discount`, `unit_of_measure` and ONE
  `qty_per_unit` (the .sql file shows `UNIT_PRICE` and a duplicated `QTY_PER_UNIT`).
* `PRD_TYPE` is the only column with a real default (`'SALE'`). Every other column is nullable
  with no default.
* **Zero NULLs** in `active_flag`, `approved_flag`, `approval_status`, `deleted_state` (all 107
  rows): those columns declare CLSQL `:void-value`s, so a NULL would read back as `"N"`/
  `"PENDING"` and no literal comparison could distinguish it. The trap is **dormant, not
  resolved**.
* Status distribution, all 107 rows — 87 `Y`/`Y`/APPROVED/not-deleted, 15 `Y`/`N`/PENDING/
  deleted, 2 `Y`/`Y`/APPROVED/deleted, 2 `Y`/`N`/PENDING/not-deleted, 1 `Y`/`N`/REJECTED/
  deleted (`active_flag`/`approved_flag`/`approval_status`/`deleted_state`). Three consequences:
  `approval_status` carries **three** values (the old API sketch offered only
  active|inactive|pending and had no way to ask for REJECTED); `active_flag` is `'Y'` on
  **every** row, so the `:inactive` filter matches **nothing** today; and what actually
  separates listed from unlisted is `approved_flag` + `deleted_state`, **not** `active_flag`.
* All 107 rows belong to tenant 5. `product_code` values look like `PRD-MPJ165U1Q7`.

---

## 3. What changed tonight

*(the 2026-09-12 evening session; §8b and §8c/§8d carry their own dates.)*

### New code (products)
`nst-prd` (30 slots, initforms mirror the LIVE schema) + `ProductRequestModel` (slotless) +
`ProductResponseModel` (29 slots) in `dod-dal-prd.lisp`; the six Tier-1 प्रत्यय, the two
copiers, and the reverse ferry in `dod-bl-prd.lisp`; routes + bindings in `nst-bl-prdapi.lisp`.

### Changes to shared core (`core/nst-bl-apidefs2.lisp`) — flagged because they affect the WAREHOUSE too

Both changes are **apidefs2 mechanism, not products API**, and now live in
**`knowledge/api-params-and-route-matching-CONTEXT.md`** — read it before touching either:

1. **`api-query-params` added and wired into `api-params-for-request`** — the API layer did not
   read the query string at all, so `GET /catalog/products?status=active` arrived with no
   `:status` key and every filter was silently ignored. Precedence is now
   company → path → body → **query**.
2. **`find-api-route` now ranks literal segments over parameters** (new helper
   `api-route-param-count`) — `…/{id}` used to match `…/template` depending on registration
   order.

The warehouse consequence is the one to know from here: its LIST endpoint's `?city=`/`?sort-by=`
filters now actually arrive — intended, but a **behaviour change to a live endpoint** that has
not been exercised.

### A real bug found in the products work, and fixed
`make` used `(unless (prd-company entity) (setf (prd-company entity) company))` and `!update`
let a caller-supplied `:company` survive into `copyProduct-domaintodb`, which derives `TENANT_ID`
from that slot. `:company` is deliberately **not** in `*reserved-initargs*`, so it passes
`extract-domain-initargs`. That is a **tenant escape** (create in another tenant; move an
existing row to another tenant). Not remotely exploitable — a JSON client cannot express a
company *object*, so it fails on `(slot-value company 'row-id)` rather than succeeding — but the
invariant did not hold by construction. **Fix:** `make` sets the company **unconditionally**
from `ctx`; `!update` re-sets it **after** `reinitialize-instance`. This is also why the
products routes carry **no `:inject-company`** (the warehouse gets the same guarantee from that
injection via leftmost-initarg precedence; the products fix does not depend on that rule). The
general form of this shape is §8.3.

---

## 4. Architecture in one screen

**The pipeline, end to end.** `POST /hhub/api/v1/catalog/products` → `com-hhub-api-dispatch`
(apidefs2: `find-api-route` → *literal beats `{param}`*; `api-authenticate` → SESSION COMPANY
(अधिकरण); `api-params-for-request` → company, path, body, query) → `dispatch-route2`
(conflodis2) → `route-product-create` (one ACTION, entity-agnostic) → `request->dispatch`
(Tier-1 ferry, adhara) → `make ∘ nst-prd` → `domain->response` / `render-json`. The UI path
(`/hhub/...`) is legacy and **not the same path yet** (§7.2).

**Invariant restated:** the API adds transport, never business routes — each products endpoint
is a binding onto an already-registered `route-product-*` verb, so an API call and (once §7.2 is
done) an internal page share one कारक build, one ferry, one set of domain laws.

---

## 5. The bound API surface

| Method | Path | → action route | Tier-1 | Status |
|---|---|---|---|---|
| GET | `/hhub/api/v1/catalog/products` | `route-product-list` | `enumerate` | 200; `[]` when empty |
| POST | `/hhub/api/v1/catalog/products` | `route-product-create` | `make` | **201**; 409 on soft-deleted code |
| GET | `…/catalog/products/{id}` | `route-product-fetch` | `fetch` | 200 / 404 |
| PUT | `…/catalog/products/{id}` | `route-product-update` | `!update` | 200 / 404 |
| DELETE | `…/catalog/products/{id}` | `route-product-delete` | `delete!` | 200 ack (`{"ok":true,"operation":"delete"}`) |
| PUT | `…/catalog/products/{id}/shipping` | `route-product-update-shipping` | `!update` | constrained to 4 fields |
| PUT | `…/catalog/products/{id}/pricing` | `route-product-update-pricing` | `set-product-pricing` | upsert; see `nst-bl-prdpricing-CONTEXT.md` |
| PUT | `…/catalog/products/{id}/status` | `route-product-update-status` | `!update` | constrained to `active-flag` |
| POST | `…/catalog/products/{id}/copy` | `route-product-copy` | `make` | 201; **no body**; added 2026-09-20 |
| GET | `…/catalog/products/template` | `route-product-template` | `create-products-csv2` | 200 `text/csv`; added 2026-09-20 |
| POST | `…/catalog/products/bulk` | `route-product-bulk-upload` | `create-bulk-products` | 200 per-row report; added 2026-09-20 |

**The last three rows are new here on 2026-10-05, not newly bound** (source tree, commit
`16faf7e`, 2026-09-20); the two CSV ones call plain functions, not Tier-1 प्रत्यय. §7.4 has the
reconciliation; `bulk-products-csv-CONTEXT.md` §8c–8d has the CSV pair's own record.

**THE THREE CONSTRAINED WRITES ARE THE INTERESTING ONES** (shipping, pricing, status). Each
reads its body explicitly and calls its verb directly instead of going through
`request->dispatch`, because the generic ferry MOP-filters params against *every* `nst-prd`
initarg — so a route using it would let a caller rename, reprice or re-approve a product by
adding one JSON key to a request that claims to be about something else.
`test/smoke-products-api.sh` §6d asserts exactly this: it sends
`{"status":"active","current-price":1,"prd-name":"hijacked …"}` and then checks the price is
still `98765`. `copy` is the same idea: its body is empty and the source is re-selected with the
session tenant, so nothing a client sends reaches the new row.

**`status` — added 2026-09-20.** Body `{"status":"active"|"inactive"}`; one field, two values. A
faithful port, not an invention: `dodvendactivateprod`/`dodvenddeactivateprod` →
`activate-product`/`deactivate-product` (`dod-bl-prd.lisp:27-38`), which set `active_flag` and
nothing else — reading those settled the question recorded in §7, that the published
`active|inactive` vocabulary might not match the schema's three lifecycle columns. `inactive`
means **`active_flag='N'`** and does **not** delist (that is `approved_flag`/`deleted_state`);
delisting, if it ever needs its own authority, wants its own endpoint, not a broader meaning here.

🚨 **Each new sub-resource needs its OWN migration.** Three product ABAC migrations exist —
`19092026-insert-product-policy-and-transactions` (6 endpoints),
`20092026-insert-product-pricing-policies`, `20092026-insert-product-status-policy` — because
`apply-migrations` never re-runs a recorded version, so a later endpoint cannot join an earlier
block. Verify with the §10 snippet in `knowledge/ABAC-policy-transaction-CONTEXT.md`; it must
report `EXACT`.

`{id}` is the numeric `ROW_ID`. Authorization is per-object: every verb re-selects with the
session tenant, so another tenant's row-id yields 404, never data (OWASP API1:2023 BOLA).

**Query params for list:** `status` (`active`\|`inactive`\|`pending`\|`rejected`), `catg-id`,
`vendor-id`, `name-like` (alias `keyword`), `min-price`, `max-price`, `sort-by`, `sort-dir`,
`limit`, `offset`. Sort keys are whitelisted (`*prd-sort-whitelist*`); `:offset` without `:limit`
is refused (MySQL cannot express it). They work at all only because of the `api-query-params`
change in §3. **Body keys are `nst-prd` initarg names** (`prd-name`, `hsn-code`,
`current-price`, …), camelCase accepted; IDs cross as JSON **strings**, with
`rowId`/`vendorId`/`catgId` normalised by `response-id-string`.

---

## 6. Decisions made, with the reasons

1. **Identity = `PRODUCT_CODE` alone**, global, because that is the only key the DB enforces. A
   tenant-scoped pre-check would answer "free" in exactly the case where the INSERT is about to
   fail. Accepted cost: `?exists` confirms *that* a code is taken, not by whom.
2. **Soft delete keeps the identity reserved.** `PRODUCT_CODE`'s unique index includes no
   `DELETED_STATE`, so a deleted product holds its code forever; re-creating it is a **:C
   contradiction**, not a fresh product. Designed, not incidental.
3. **`:C` is returned as `nst-entity-contradiction` by `route-product-create`**, so the
   disagreement ("the code is taken" vs नियम-2's "no such product") becomes a **409 with an
   actionable reason** rather than a 500 whose detail lives only in the log.
4. **The tenant is enforced by construction in the domain** (§3), not by API param precedence —
   hence no `:inject-company` on any products route.
5. **Status vocabulary derived from the data**, not from the old sketch — §2, §5.
6. **Lifecycle flags publish as JSON booleans** (`"active"`/`"approved"`/`"subscribed"`), whereas
   warehouse publishes `activeFlag` as raw `"Y"`/`"N"`. **Deliberate divergence, flagged and
   un-unified:** flipping to the warehouse convention is three cons cells in `render-json`. Unify
   before either endpoint has external consumers — and read §8b first, because that branch is
   exactly what cannot currently emit `false`.
7. **`render-json` is the field allowlist.** Tenant and company are absent from both the response
   model and the render method, so they cannot leak. **`catgId` and `externalUrl` were removed
   from both on 2026-09-21** — no longer published at all, so the remaining 27 slots are the 27
   published keys; none extra. (Removing a key is a three-JSON-site edit:
   `bulk-products-csv-CONTEXT.md` §8d.)
8. **`?exists` carries `&key &allow-other-keys`** for CLOS congruence with the GF in adhara,
   even though the product identity is a single column (nst-whs needs `WNAME`).
9. **`generate-product-code` is a function, not the class `:void-value`.** A `:void-value`
   expression is evaluated **once, at class-definition time**, so `dod-prd-master`'s own
   `(format nil "NST-~A" (hhub-random-password 10))` hands every instance the SAME code and the
   unique key rejects the second insert. `persist-product` computes its own code, which is why
   that latent bug never surfaced.

---

## 7. Deliberately unfinished — do not re-derive

1. **§7.1 — "EVERYTHING PAST AUTHENTICATION IS UNRUN" — RESOLVED 2026-09-20; do not re-open it
   as a gap.** It was the top item, and a *runtime* gap rather than a build one: no product verb
   had ever executed. `test/smoke-products-api.sh --write` has since run the mutating verbs
   against the live server and passed **34/34** (`nst-bl-prdpricing-CONTEXT.md` §9); the read
   path had already passed on 2026-09-13. Still unexercised: the 2026-09-20 surface — `copy`,
   `template`, `bulk` (§5).
2. **The products UI is NOT migrated.** `dod-ui-prd.lisp` has **0** references to
   `route-product`/`request->dispatch`/`conflodis2`: the website still calls legacy functions
   directly. So the architecture's core invariant — external call and internal page sharing one
   ferry — **does not hold for products yet**. There is no `products/nst-ui-prd.lisp` (warehouse
   has one). Corollary: **no `render-html`** exists for `ProductResponseModel`, so a UI caller on
   the new path would hit `no-applicable-method`.
3. **Error taxonomy (CONTEXT §9.1).** Domain refusals raise plain `error` → **500**, not 400: an
   unknown `?status=`, an unknown `?sort-by=`, an unparseable `?min-price=`, a non-numeric `{id}`
   handled by the domain all land there. `route-product-create`'s 409 is the only correct 4xx.
   The refusal is loud and correct; only the status code is wrong. **Highest-value next fix after
   the load check.** (The `§9.1` reference predates the 2026-09-20 split and no longer resolves
   inside this file — kept rather than guessed at. The same wart is in
   `hhub/vendor/nst-bl-vnd.lisp:226`.)
4. **§7.4 — the "seven sketched endpoints are unbound" list — RECONCILED 2026-10-05 against the
   source tree.** The seven were `update-status`, `update-shipping`, `copy`, `update-pricing`
   (then with no domain entity for `DOD_PRODUCT_PRICING` at all), `bulk-create` and
   `upload-images` (both blocked on multipart — `api-request-body-params` reads JSON only), and
   `template` (produces CSV and should not go through `api-write-json`). **Six are now bound:**
   `update-shipping` and `update-pricing` on 2026-09-20 (exercised, 34/34 — README · *Known
   staleness*), then `update-status`, `copy`, `template` and `bulk-create` in the same day's
   commit `16faf7e` (`hhub/products/nst-bl-prdapi.lisp:803-833`). **`upload-images` alone
   remains unbound** — no `register-api-route` exists for it, so it is unreachable and answers
   404 `no_such_endpoint`. Each endpoint's original reason is in `nst-bl-prdapi.lisp` SECTION 3,
   itself now partly stale: its SECTION 4 header still lists `bulk, template, images, status,
   copy` as unbound while binding four of them just below.
5. **`products/nst-bl-prodapi.lisp` is dead weight** — 12 `register-outbound-route` calls, no
   classes, unreachable paths. It contradicts the live surface, and the near-identical filename
   (`prodapi` vs `prdapi`) invites mistakes. Reduce it to a spec or delete it.
6. **No `nst-tst-*` suite.** Warehouse has `test/nst-tst-warehouse.lisp`; products has none — the
   only coverage is the two smoke scripts (`smoke-products-api.sh`, `smoke-bulk-products-api.sh`).
7. **Naming inconsistency.** The domain class went into `dod-dal-prd.lisp` (mixed new + legacy)
   rather than a `products/nst-dal-prd.lisp` as warehouse did. Works, and the pricing and category
   entities follow the same choice, so the divergence is now deliberate, not accidental.
8. **This-file/companion-file drift.** `core/nst-bl-apidefs2-CONTEXT.md` does not mention
   products, the query-param change, or the route-ranking change — it predates both. Those two now
   have an owner (`knowledge/api-params-and-route-matching-CONTEXT.md`); that file still needs a
   pointer from the apidefs2 one, which is a README/index edit.

---

## 8. Sharp edges that cost real time tonight

1. **Hand-written closing-paren runs are the main defect source.** Two defects were introduced
   and caught: `make` lost a closer (so it swallowed three following forms) while `!update`
   carried an extra one — the file was **globally balanced at depth 0** while being structurally
   wrong. **A global paren-balance check cannot catch compensating errors.** The check that
   works: count **top-level forms** per file and confirm each closes where it should,
   comment/string-aware. (`bulk-products-csv-CONTEXT.md` §8c is the same rule from the other end.)
2. **Read `[...]` CLSQL syntax correctly when writing a checker.** Aliasing `]` onto the `)` macro
   character is NOT faithful; CLSQL uses `set-syntax-from-char #\] #\)` plus a `[` macro that
   calls `read-delimited-list`. With the wrong alias, valid files appear broken.
3. **`:company` is NOT in `*reserved-initargs*`** (§3). Any new entity whose verb reads a
   caller-settable company slot has the same tenant-escape shape. `:tenant-id` IS reserved;
   `:company` is not.
4. **`hunchentoot:get-parameters` is a slot READER** and takes the request object — a zero-arg
   call is a wrong-arity error, and a `handler-case` around it will swallow that and make query
   filters a silent no-op. Use **`hunchentoot:get-parameters*`** (optional request, defaults to
   `*request*`). Verified in `hunchentoot-v1.3.1/request.lisp:364`.
5. **The reverse-ferry surface is entity-generic — do not re-define it per entity.**
   `domain->response` on `nst-entity-nil/-unknown/-contradiction` and on `(eql t)` live in
   `warehouse/nst-bl-whsapi.lisp` §4 and specialize on the **sentinel classes / the value**, not
   on `nst-whs`; `render-json` on `list` and `domain->response-list` live in
   `nst-bl-warehouse.lisp`. Redefining any of them silently REPLACES the warehouse's (same GF,
   same specializer). Products therefore adds exactly two methods.
6. **`conflodis2-render` intercepts lists itself**, so an empty catalog renders `[]` (200) — not
   `null` — and a list composes element-wise through the per-entity method. A per-list
   `render-json` method is NOT required (warehouse's is vestigial).
7. **Name collisions to avoid in a shared package:** `validate-sort-args` and
   `*whs-sort-whitelist*` belong to the warehouse and `validate-sort-args` reads THAT whitelist —
   hence `validate-product-sort-args` / `*prd-sort-whitelist*`. Same for `domain->response-list`,
   `render-json (list)` and the sentinel methods in item 5.
8. **`escape-like-wildcards` lives in `warehouse/nst-bl-warehouse.lisp`**, which loads *after* the
   products files. Resolved at call time, so harmless — reused rather than copied so the
   LIKE-escaping rule keeps one implementation.
9. **`deleted-state` has no accessor on `dod-prd-master`** — read/write it with `slot-value`, not
   an accessor.
10. **`conflodis2` has a stray `(format t "~&conflodis2: ~S → action verb ~S~%" …)`** on every
    dispatch. Debug noise in the message log; worth deleting.

---

## 8b. 🚨 FOUND 2026-09-20 — the products API cannot emit `false` · MOVED

→ **`knowledge/api-boolean-flags-CONTEXT.md`** (still **NOT FIXED**): the JSON boundary's defect,
not products' — `prd-flag->boolean` (`dod-bl-prd.lisp:1490`) returns Lisp `T`/`NIL`, cl-json's
guessing encoder maps `nil` → `null` and never `false`, so `vnd-flag->boolean`
(`nst-bl-vnd.lisp:930`) gives the vendor responses the same `"active":null`. That file holds the
symptom, the verified `(defclass json-false () ())` fix and its alternative; **§6.6 is the
products-side decision it collides with.**

---

## 9. Two pre-existing platform findings (found, NOT fixed)

1. **`check-niyam` is never called anywhere in the request path.** Grep finds it only in its own
   definition (`nst-bl-adhara.lisp`) and in tests. So नियम-1 (tenant isolation) and नियम-2
   (not-deleted guard) are **declared but not enforced** — on `nst-whs` as much as on `nst-prd`.
   The products verbs uphold both by construction, but nothing stops a hand-written caller.
2. **`dispatch-route2`'s debug print** (see §8.10).

---

## 8c–8d. The products.csv pair — MOVED

→ **`bulk-products-csv-CONTEXT.md`**: §8c (bulk/template findings 2026-09-20 — `MD5Digest` means
"touched", not "valid"; the one-product-ever bug; the open *fixture never appears in the template*
blocker) and §8d (the 23-column v2 contract — `DESCRIPTION` out of the CSV,
`CATG_ID`/`EXTERNAL_URL` withdrawn; read it before touching `*prd-bulk-csv-header*`,
`prd-bulk-csv-header-p`, `prd-csv-*`, `create-bulk-products` or `create-products-csv2`).

---

## Where the rest of this material went

Split **2026-09-20** for the 400-line budget (README · *The daily size cycle*), and again
**2026-10-05**. Nothing was deleted; each grouping kept its §-numbers so older references still
resolve:

| was | now lives in |
|---|---|
| §10–12 — how to verify, the probe transcript, the smoke-test verification | `products-api-verification-CONTEXT.md` |
| §13–16 — provenance bug, all four Belnap states, the knowledge→domain contract | `belnap-four-states-CONTEXT.md` |
| §17 — the 2026-09-13 vendor-API handoff (historical) | `vendor-api-handoff-CONTEXT.md` |
| §18–19 — `knowledge-conjoin` and the `t` trap | `knowledge-conjoin-CONTEXT.md` |
| §3's two `apidefs2` shared-core changes (2026-10-05) | `knowledge/api-params-and-route-matching-CONTEXT.md` |
| §8b — the API cannot emit `false` (2026-10-05) | `knowledge/api-boolean-flags-CONTEXT.md` |
| §8c–8d — the products.csv contract and the bulk/template findings (2026-10-05) | `bulk-products-csv-CONTEXT.md` — and `hhub/products/dod-bl-prd.lisp:764`'s *"section 8d"* citation resolves there |

The header still refers to §11 and §12, which now cross a file boundary. For the pricing layer,
see `nst-bl-prdpricing-CONTEXT.md`.
