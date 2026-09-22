# nst-bl-prdapi — Products on conflodis2 + apidefs2 · CONTEXT

**Read this when:** you are touching a product/catalog route or the product verbs, or
you need the products schema facts, the bound surface, or the list of what was
deliberately left unfinished.

**Purpose of this file.** Working context for whoever continues the PRODUCTS migration
to the new architecture (adhara → conflodis2 → apidefs2). Read this before touching
`products/dod-bl-prd.lisp`, `products/dod-dal-prd.lisp` or `products/nst-bl-prdapi.lisp`.
It records what exists, why it is shaped that way, what is verified, and what is
deliberately unfinished.

**Date of the work recorded here:** 2026-09-12 (evening session).

**READ THIS FIRST — the verification status.** The companion file
`core/nst-bl-apidefs2-CONTEXT.md` distinguishes *verified* (exercised against the running
server) from *reasoned, not yet run*. For this file:

* **§2 (schema/data)** — VERIFIED by direct SQL against the live database.
* **COMPILATION** — VERIFIED. All four touched files were compiled after the last source
  edit and produced `.fasl`s (`nst-bl-apidefs2` 23:58:35, `dod-bl-prd` 23:58:36,
  `nst-bl-prdapi` 00:00:22, `dod-dal-prd` 23:34:27, 2026-09-12/13). So every one of the
  ~25 new forms compiles: no paren errors, no wrong `&key`, no non-congruent `defmethod`,
  no load-time failure.
* **ROUTING and AUTH (Ring 4)** — VERIFIED by probing the running server on 2026-09-13:
  all five product bindings answer **401 unauthenticated** without a session, while an
  unbound path answers **404 `no_such_endpoint`**. See §11.
* **READ PATHS EXERCISED (2026-09-13)** — `test/smoke-products-api.sh` ran against the live
  server with a real vendor session: **12 of 13 checks passed**. `enumerate`, the query
  filters, tenant scoping, `domain->response`, `render-json` and the 200/401/404 mapping are
  VERIFIED. See §12.
* **STILL UNRUN** — `make`, `!update` and `delete!`: the mutating verbs. The soft-delete
  `:C` path returned 500 instead of 409 for a reason that is now fixed but **not yet
  re-tested** (§12). Re-run the script with `--write` after reloading.

**This header was corrected on 2026-09-13.** The file was written on the evening of
2026-09-12 stating that nothing had been compiled or run; that was true when written and
became false within the hour. The image was rebuilt at 23:58–00:00 and the acceptor
restarted at **07:56 on 2026-09-13**, so it runs the current code. A restart also calls
`reset-session-secret`, invalidating every session cookie issued before it.

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
| `hhub/core/nst-bl-apidefs2.lisp` | Ring-4 JSON boundary: `register-api-route`, one `^/hhub/api/v1/` handler, status mapping. **Changed tonight — see §3** |
| `hhub/core/nst-mult-logic.lisp` | `with-db-call`, `with-nst-db-create/update/delete/read-all`, `bind-generated-row-id` |
| `hhub/core/nst-bl-beltrusys.lisp` | Belnap: `bo-knowledge`, `bo-knowledge-truth`, `bo-knowledge-payload`, `bo-merge`, `make-bo-knowledge` |

Build wiring (both are `:serial t`, and both now list `products/nst-bl-prdapi`):
`hhub/package/compile.lisp` (line 196) and `hhub/nstores.asd` (line 151).

**Ordering is load-bearing.** `nst-bl-prdapi.lisp` calls `register-action-route` at load
time, so it must come after `adhara`/`conflodis2`; and it names `nst-prd`/
`ProductRequestModel`, so it must come after `dod-dal-prd`/`dod-bl-prd`. In `nstores.asd`
that means line 151 (the products block), **not** line 81 next to
`products/nst-bl-prodapi`, which sits *before* `adhara` at line 88.

---

## 2. Schema and data facts (VERIFIED by SQL, 2026-09-12)

`installation/hhubplatform.sql` **is stale for this table** — exactly as
`nst-bl-apidefs2-CONTEXT.md` warns for `DOD_WAREHOUSE`. Do not use it as the source of
truth. Verified live:

* `DOD_PRD_MASTER.PRODUCT_CODE varchar(50) NOT NULL UNIQUE` is the **ONLY unique key** —
  and the table carries it **twice** (`PRODUCT_CODE`, `PRODUCT_CODE_2`). Identity is a
  single global column, **not** a tuple and **not** tenant-scoped. There is **no** unique
  key on `(PRD_NAME, TENANT_ID)` and none on `SKU`.
* The live table has `current_price`, `current_discount`, `unit_of_measure` and ONE
  `qty_per_unit` (the .sql file shows `UNIT_PRICE` and a duplicated `QTY_PER_UNIT`).
* `PRD_TYPE` is the only column with a real default (`'SALE'`). Every other column is
  nullable with no default.
* **Zero NULLs** in `active_flag`, `approved_flag`, `approval_status`, `deleted_state`
  (all 107 rows). This matters: those columns declare CLSQL `:void-value`s, so a NULL would
  read back as `"N"`/`"PENDING"` and no literal comparison could distinguish it. The trap is
  **dormant, not resolved**.
* Status distribution, all 107 rows:

  | active_flag | approved_flag | approval_status | deleted | rows |
  |---|---|---|---|---|
  | Y | Y | APPROVED | N | 87 |
  | Y | N | PENDING | Y | 15 |
  | Y | Y | APPROVED | Y | 2 |
  | Y | N | PENDING | N | 2 |
  | Y | N | REJECTED | Y | 1 |

  Three consequences: `approval_status` carries **three** values (the old API sketch
  offered only active|inactive|pending and had no way to ask for REJECTED);
  `active_flag` is `'Y'` on **every** row, so the `:inactive` filter matches **nothing**
  today; and what actually separates listed from unlisted is `approved_flag` +
  `deleted_state`, **not** `active_flag`.
* All 107 rows belong to tenant 5. `product_code` values look like `PRD-MPJ165U1Q7`.

---

## 3. What changed tonight

### New code (products)
`nst-prd` (30 slots, initforms mirror the LIVE schema) + `ProductRequestModel` (slotless) +
`ProductResponseModel` (29 slots) in `dod-dal-prd.lisp`; the six Tier-1 प्रत्यय, the two
copiers, and the reverse ferry in `dod-bl-prd.lisp`; routes + bindings in
`nst-bl-prdapi.lisp`.

### Changes to shared core (`core/nst-bl-apidefs2.lisp`) — flagged because they affect the WAREHOUSE too

1. **`api-query-params` added and wired into `api-params-for-request`.** The API layer
   previously merged only the session company, path params and the JSON body — it did **not
   read the query string at all**. A filtering endpoint was therefore unreachable over HTTP:
   `GET /catalog/products?status=active` arrived with no `:status` key and every filter was
   silently ignored. Precedence is now: company → path → body → **query** (lowest, because
   the body is the resource representation and a GET list has no body). Keys normalise
   through the same `api-json-key->param-key` as body keys. Empty values are **passed
   through, not dropped** (dropping turns "unusable value" into "no filter" and silently
   widens the result set — the §9.6 failure mode).
   **Consequence for warehouse:** its LIST endpoint's query filters (`?city=`, `?sort-by=`)
   now actually arrive. That is the intended fix, but it is a **behaviour change to a live
   endpoint** and has not been exercised.
2. **`find-api-route` now ranks literal segments over parameters** (new helper
   `api-route-param-count`). It used to return the FIRST template that matched while the
   registry is scanned newest-first, so `…/{id}` also matched `…/template` and the winner
   depended on registration order. Ties keep registry order (newest first).

### A real bug found in the products work, and fixed
`make` used `(unless (prd-company entity) (setf (prd-company entity) company))` and
`!update` let a caller-supplied `:company` survive into `copyProduct-domaintodb`, which
derives `TENANT_ID` from that slot. `:company` is deliberately **not** in
`*reserved-initargs*`, so it passes `extract-domain-initargs`. That is a **tenant escape**
(create in another tenant; move an existing row to another tenant). Not remotely
exploitable — a JSON client cannot express a company *object*, so it fails on
`(slot-value company 'row-id)` rather than succeeding — but the invariant did not hold by
construction. **Fix:** `make` sets the company **unconditionally** from `ctx`; `!update`
re-sets it **after** `reinitialize-instance`. This is also why the products routes carry
**no `:inject-company`** (the warehouse gets the same guarantee from that injection via
leftmost-initarg precedence; the products fix does not depend on that rule).

---

## 4. Architecture in one screen

```
POST /hhub/api/v1/catalog/products          UI: /hhub/... (LEGACY — see §7.2)
        │                                       │
        ▼                                       │  ← NOT the same path yet
com-hhub-api-dispatch (apidefs2)
  find-api-route    → literal beats {param}
  api-authenticate  → SESSION COMPANY (अधिकरण)
  api-params-for-request → company, path, body, query
        │
        └──────────────► dispatch-route2 (conflodis2)
                            ▼
                     route-product-create            one ACTION, entity-agnostic
                            ▼
                  request->dispatch (Tier-1 ferry, adhara)
                            ▼
                     make ∘ nst-prd
                            │
                   ┌────────┴────────┐
              domain->response   render-json
```

**Invariant restated:** the API adds transport, never business routes. Each products
endpoint is a binding onto an already-registered `route-product-*` verb, so an API call and
(once §7.2 is done) an internal page will share one कारक build, one ferry, one set of domain
laws.

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

**THE THREE CONSTRAINED WRITES ARE THE INTERESTING ONES** (shipping, pricing, status).
Each reads its body explicitly and calls its verb directly instead of going through
`request->dispatch`, because the generic ferry MOP-filters params against *every*
`nst-prd` initarg — so a route using it would let a caller rename, reprice or re-approve
a product by adding one JSON key to a request that claims to be about something else.
`test/smoke-products-api.sh` §6d asserts exactly this: it sends
`{"status":"active","current-price":1,"prd-name":"hijacked …"}` and then checks the price
is still `98765`.

**`status` — added 2026-09-20.** Body `{"status":"active"|"inactive"}`; one field, two
values. A faithful port, not an invention: `dodvendactivateprod`/`dodvenddeactivateprod`
→ `activate-product`/`deactivate-product` (`dod-bl-prd.lisp:27-38`), which set
`active_flag` and nothing else. Reading those settled a question this file had recorded
in §7 — that the published `active|inactive` vocabulary might not match the schema's
three lifecycle columns. `inactive` means **`active_flag='N'`** and does **not** delist
(that is `approved_flag`/`deleted_state`); if delisting ever needs its own authority it
wants its own endpoint, not a broader meaning here.

🚨 **Each new sub-resource needs its OWN migration.** Three product ABAC migrations now
exist — `19092026-insert-product-policy-and-transactions` (6 endpoints),
`20092026-insert-product-pricing-policies`, `20092026-insert-product-status-policy` —
because `apply-migrations` never re-runs a recorded version, so a later endpoint cannot
join an earlier block. Verify with the §10 snippet in
`knowledge/ABAC-policy-transaction-CONTEXT.md`; it must report `EXACT`.

`{id}` is the numeric `ROW_ID`. Authorization is per-object: every verb re-selects with the
session tenant, so another tenant's row-id yields 404, never data (OWASP API1:2023 BOLA).

**Query params for list:** `status` (`active`\|`inactive`\|`pending`\|`rejected`), `catg-id`,
`vendor-id`, `name-like` (alias `keyword`), `min-price`, `max-price`, `sort-by`, `sort-dir`,
`limit`, `offset`. Sort keys are whitelisted (`*prd-sort-whitelist*`). `:offset` without
`:limit` is refused (MySQL cannot express it).

**Body keys are `nst-prd` initarg names** (`prd-name`, `hsn-code`, `current-price`, …),
camelCase accepted. IDs cross as JSON **strings**; `rowId`/`vendorId`/`catgId` are
normalised by `response-id-string`.

---

## 6. Decisions made, with the reasons

1. **Identity = `PRODUCT_CODE` alone**, global, because that is the only key the DB
   enforces. A tenant-scoped pre-check would answer "free" in exactly the case where the
   INSERT is about to fail. Accepted cost: `?exists` confirms *that* a code is taken, not by
   whom.
2. **Soft delete keeps the identity reserved.** `PRODUCT_CODE`'s unique index includes no
   `DELETED_STATE`, so a deleted product holds its code forever; re-creating it is a **:C
   contradiction**, not a fresh product. This is designed, not incidental.
3. **`:C` is returned as `nst-entity-contradiction` by `route-product-create`**, so the
   disagreement ("the code is taken" vs नियम-2's "no such product") becomes a **409 with an
   actionable reason** rather than a 500 whose detail lives only in the log.
4. **The tenant is enforced by construction in the domain** (§3), not by API param
   precedence. Hence no `:inject-company` on any products route.
5. **Status vocabulary derived from the data**, not from the old sketch — see §2.
6. **Lifecycle flags publish as JSON booleans** (`"active"`/`"approved"`/`"subscribed"`),
   whereas warehouse publishes `activeFlag` as raw `"Y"`/`"N"`. **Deliberate divergence,
   flagged and un-unified:** flipping to the warehouse convention is three cons cells in
   `render-json`. Unify before either endpoint has external consumers.
7. **`render-json` is the field allowlist.** Tenant and company are absent from both the
   response model and the render method, so they cannot leak. **`catgId` and `externalUrl`
   were removed from both on 2026-09-21** — they are no longer published at all, so the
   remaining 27 slots are the 27 published keys; none extra.
8. **`?exists` carries `&key &allow-other-keys`** for CLOS congruence with the GF in
   adhara, even though the product identity is a single column (nst-whs needs `WNAME`).
9. **`generate-product-code` is a function, not the class `:void-value`.** A `:void-value`
   expression is evaluated **once, at class-definition time**, so `dod-prd-master`'s own
   `(format nil "NST-~A" (hhub-random-password 10))` hands every instance the SAME code and
   the unique key rejects the second insert. `persist-product` computes its own code, which
   is why that latent bug never surfaced.

---

## 7. Deliberately unfinished — do not re-derive

1. **EVERYTHING PAST AUTHENTICATION IS UNRUN.** Compilation is verified and the routes are
   registered in the live image (§ header, §11), but no product verb has ever executed: no
   `make`, `fetch`, `!update`, `delete!` or `enumerate`, no ferry, no DB read or write, no
   `render-json`. Exercising those needs an authenticated session — run
   `test/smoke-products-api.sh` (read-only by default) with vendor credentials.
   This is now the top item, and it is a *runtime* gap, not a build one.
2. **The products UI is NOT migrated.** `dod-ui-prd.lisp` has **0** references to
   `route-product`/`request->dispatch`/`conflodis2`: the website still calls legacy
   functions directly. So the architecture's core invariant — external call and internal
   page sharing one ferry — **does not hold for products yet**. There is no
   `products/nst-ui-prd.lisp` (warehouse has one). Corollary: **no `render-html`** exists
   for `ProductResponseModel`, so a UI caller on the new path would hit
   `no-applicable-method`.
3. **Error taxonomy (CONTEXT §9.1).** Domain refusals raise plain `error` → **500**, not
   400: an unknown `?status=`, an unknown `?sort-by=`, an unparseable `?min-price=`, a
   non-numeric `{id}` handled by the domain all land there. `route-product-create`'s 409 is
   the only correct 4xx. The refusal is loud and correct; only the status code is wrong.
   **Highest-value next fix after the load check.**
4. **Seven sketched endpoints are unbound** (each with its reason recorded in
   `nst-bl-prdapi.lisp` SECTION 3): `update-status`, `update-shipping`, `copy`,
   `update-pricing` (no domain entity for `DOD_PRODUCT_PRICING` at all), `bulk-create` and
   `upload-images` (multipart — `api-request-body-params` reads JSON only), `template`
   (produces CSV and should not go through `api-write-json`). All answer 404
   `no_such_endpoint`.
5. **`products/nst-bl-prodapi.lisp` is dead weight** — 12 `register-outbound-route` calls,
   no classes, unreachable paths. It now contradicts the live surface, and the
   near-identical filename (`prodapi` vs `prdapi`) invites mistakes. Reduce it to a spec or
   delete it.
6. **No tests.** Warehouse has `test/nst-tst-warehouse.lisp`; products has none.
7. **Naming inconsistency.** The domain class went into `dod-dal-prd.lisp` (mixed new +
   legacy) rather than a `products/nst-dal-prd.lisp` as warehouse did. Works, but diverges
   from the reference pattern.
8. **This-file/companion-file drift.** `core/nst-bl-apidefs2-CONTEXT.md` does not mention
   products, the query-param change, or the route-ranking change.

---

## 8. Sharp edges that cost real time tonight

1. **Hand-written closing-paren runs are the main defect source.** Two separate defects were
   introduced and caught: `make` lost a closer (so it swallowed three following forms) while
   `!update` carried an extra one — the file was **globally balanced at depth 0** while being
   structurally wrong. **A global paren-balance check cannot catch compensating errors.**
   The check that works: count **top-level forms** per file and confirm each closes where it
   should, comment/string-aware.
2. **Read `[...]` CLSQL syntax correctly when writing a checker.** Aliasing `]` onto the `)`
   macro character is NOT faithful; CLSQL uses `set-syntax-from-char #\] #\)` plus a `[`
   macro that calls `read-delimited-list`. With the wrong alias, valid files appear broken.
3. **`:company` is NOT in `*reserved-initargs*`** (§3). Any new entity whose verb reads a
   caller-settable company slot has the same tenant-escape shape. `:tenant-id` IS reserved;
   `:company` is not.
4. **`hunchentoot:get-parameters` is a slot READER** and takes the request object — a
   zero-arg call is a wrong-arity error, and a `handler-case` around it will swallow that
   and make query filters a silent no-op. Use **`hunchentoot:get-parameters*`** (optional
   request, defaults to `*request*`). Verified in `hunchentoot-v1.3.1/request.lisp:364`.
5. **The reverse-ferry surface is entity-generic — do not re-define it per entity.**
   `domain->response` on `nst-entity-nil/-unknown/-contradiction` and on `(eql t)` live in
   `warehouse/nst-bl-whsapi.lisp` §4 and specialize on the **sentinel classes / the value**,
   not on `nst-whs`. `render-json` on `list` and `domain->response-list` live in
   `nst-bl-warehouse.lisp`. Redefining any of them silently REPLACES the warehouse's
   (same GF, same specializer). Products therefore adds exactly two methods.
6. **`conflodis2-render` intercepts lists itself**, so an empty catalog renders `[]` (200) —
   not `null` — and a list composes element-wise through the per-entity method. A per-list
   `render-json` method is NOT required (warehouse's is vestigial).
7. **Name collisions to avoid in a shared package:** `validate-sort-args` and
   `*whs-sort-whitelist*` belong to the warehouse and `validate-sort-args` reads THAT
   whitelist — hence `validate-product-sort-args` / `*prd-sort-whitelist*`. Same for
   `domain->response-list`, `render-json (list)`, and the sentinel methods above.
8. **`escape-like-wildcards` lives in `warehouse/nst-bl-warehouse.lisp`**, which loads
   *after* the products files. Resolved at call time, so harmless — reused rather than
   copied so the LIKE-escaping rule keeps one implementation.
9. **`deleted-state` has no accessor on `dod-prd-master`** — read/write it with
   `slot-value`, not an accessor.
10. **`conflodis2` has a stray `(format t "~&conflodis2: ~S → action verb ~S~%" …)`** on
    every dispatch. Debug noise in the message log; worth deleting.

---

## 8b. 🚨 FOUND 2026-09-20 — the products API cannot emit `false`

**Status: diagnosed and fixed options verified; NOT YET FIXED.** Found by the §6d
read-back assertion added for the status endpoint — the assertion was correct and the
code is wrong, so the test stays.

**Symptom.** `PUT …/status {"status":"inactive"}` returns 200, the database really
does hold `ACTIVE_FLAG='N'` (verified by SQL on row 126), and the product GET then
reports:

```json
"active":null, "approved":null, "subscribed":null
```

**Cause, in two steps.** `prd-flag->boolean` (`dod-bl-prd.lisp:1490`) ends in
`(string-equal value "Y")`, so it returns **`T` or `NIL`** — not `T`/`NIL`-as-true/false,
but Lisp truth values. And `conflodis2-json-text` encodes with
`json:encode-json-to-string` under cl-json's **guessing encoder**, which maps

```
t   -> true
nil -> null        ← not false
```

So `"N"` and an unset flag both publish `null`, and **JSON `false` is unreachable from
an alist value with that encoder.** cl-json's `(:true)`/`(:false)` markers are for its
*explicit* encoder only; passing `'(:false)` in an alist makes the guessing encoder emit
an ARRAY (`[["active","false"]]`), which was verified rather than assumed.

**Blast radius — this is not products-only.** `vnd-flag->boolean`
(`nst-bl-vnd.lisp:930`) deliberately delegates to `prd-flag->boolean`, so the vendor
profile, vendor shipping and vendor payment responses have the same defect. Anywhere the
API promises a boolean flag, a client gets `true` or `null`.

**Why it went unnoticed.** Every existing assertion tested a flag that was ON, or did not
test the value at all. `"active":null` is falsy in JavaScript, so a client doing
`if (p.active)` behaves correctly by accident — but `p.active === false` does not, and
**a client cannot distinguish "off" from "never set"**, which is the distinction this
whole design is built on.

**The two verified fixes:**

| fix | effect |
|---|---|
| **A marker object.** `(defclass json-false () ())` + `(defmethod json:encode-json ((x json-false) &optional stream) (write-string "false" stream))`, then have `prd-flag->boolean` return it for false. | Verified: `{"active":false,"approved":true}`. Keeps the boolean contract; one small class, and every flag-returning response in the tree inherits the fix. |
| **Publish the raw `"Y"`/`"N"` strings**, as warehouse already does (`nst-bl-prdapi-CONTEXT.md` §5 records the divergence as deliberate). | No encoder problem at all, but it reverses a documented decision and gives up `if (p.active)`. |

Either way the change is **wire-visible for every product and vendor response**, so it is
a deliberate decision rather than a cleanup.

## 9. Two pre-existing platform findings (found, NOT fixed)

1. **`check-niyam` is never called anywhere in the request path.** Grep finds it only in its
   own definition (`nst-bl-adhara.lisp`) and in tests. So नियम-1 (tenant isolation) and
   नियम-2 (not-deleted guard) are **declared but not enforced** — on `nst-whs` as much as on
   `nst-prd`. The products verbs uphold both by construction, but nothing stops a
   hand-written caller.
2. **`dispatch-route2`'s debug print** (see §8.10).

---


---

## 8c. The bulk products.csv pair — findings, 2026-09-20 (evening)

**Status: BUILT, partially exercised, ONE KNOWN BLOCKER.** Endpoints:
`GET /catalog/products/template` (text/csv) and `POST /catalog/products/bulk`
(multipart or raw CSV). Smoke: `hhub/test/smoke-bulk-products-api.sh`, 11 pass / 7 fail
at the end of the day. Everything below was measured, not reasoned.

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

## Where the rest of this material went

This file was split on **2026-09-20** to stay inside the 400-line budget (README ·
*The daily size cycle*). Nothing was deleted. Four groupings moved to files of their own,
keeping their original §-numbers so that references elsewhere still resolve:

| was | now lives in |
|---|---|
| §10–12 — how to verify, the probe transcript, the smoke-test verification | `products-api-verification-CONTEXT.md` |
| §13–16 — provenance bug, all four Belnap states, the knowledge→domain contract | `belnap-four-states-CONTEXT.md` |
| §17 — the 2026-09-13 vendor-API handoff (historical) | `vendor-api-handoff-CONTEXT.md` |
| §18–19 — `knowledge-conjoin` and the `t` trap | `knowledge-conjoin-CONTEXT.md` |

The header above still refers to §11, §12 and §14–16: those references now cross a file
boundary. For the pricing layer, see `nst-bl-prdpricing-CONTEXT.md`.
