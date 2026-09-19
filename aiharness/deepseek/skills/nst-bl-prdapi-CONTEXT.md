# nst-bl-prdapi — Products on conflodis2 + apidefs2 · CONTEXT

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
   response model and the render method, so they cannot leak. All 29 slots are published;
   none extra.
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

## 9. Two pre-existing platform findings (found, NOT fixed)

1. **`check-niyam` is never called anywhere in the request path.** Grep finds it only in its
   own definition (`nst-bl-adhara.lisp`) and in tests. So नियम-1 (tenant isolation) and
   नियम-2 (not-deleted guard) are **declared but not enforced** — on `nst-whs` as much as on
   `nst-prd`. The products verbs uphold both by construction, but nothing stops a
   hand-written caller.
2. **`dispatch-route2`'s debug print** (see §8.10).

---

## 10. How to verify (compilation is done; the runtime is not)

**PREFER THE SCRIPT:** `hhub/test/smoke-products-api.sh` — run it from a workstation. It is
read-only by default, asserts status codes instead of dumping bodies, detects the
not-loaded case, and prints cleanup SQL. `--write` adds the create/update/delete tests,
which put a real row in the live database.

```bash
NS_PHONE=… NS_PASSWORD=… ./smoke-products-api.sh            # read-only
NS_PHONE=… NS_PASSWORD=… ./smoke-products-api.sh --write    # + mutations
```

By hand:

```bash
# 1. ALREADY DONE — compilation is verified (§ header). Routes are registered in the
#    live image; no reload is needed. For the record, the diagnostics are:
#      (list-api-routes)        ; expect 5 warehouse + 5 product rows
#      (list-action-routes)     ; expect route-product-* among them
#
#    IMPORTANT: the acceptor was RESTARTED at 07:56 on 2026-09-13, and start-das calls
#    reset-session-secret — so any cookie older than that restart is dead. Log in fresh.

# 2. Session (302 is ambiguous for dodvendlogin — check Location + Set-Cookie):
curl -sS -D /tmp/h.txt -c /tmp/ns.jar -X POST http://hunchentoot.local/hhub/dodvendlogin \
  -d 'phone=<vendor phone>&password=<password>'
# WARNING: a curl login counts against the max-2 concurrent vendor logins and evicts the
# OLDEST session — it can silently bounce a browser session, and vice versa.

# 4. Read-only first — safest, and it exercises enumerate + render + status mapping:
curl -sS -i -b /tmp/ns.jar "http://hunchentoot.local/hhub/api/v1/catalog/products?status=active&limit=2"
#    expect 200 and a JSON array of 2 objects (87 active rows exist in tenant 5)
curl -sS -i -b /tmp/ns.jar "http://hunchentoot.local/hhub/api/v1/catalog/products?status=inactive"
#    expect 200 [] — NOT 404 (an empty list is a success)

# 5. A real row-id, never a <placeholder> (zsh treats < as a redirect):
curl -sS -i -b /tmp/ns.jar http://hunchentoot.local/hhub/api/v1/catalog/products/121
#    expect 200; an unknown/other-tenant id must be 404
```

**Logs** (all under `/home/hunchentoot/hhublogs/`): `ninestores-apilogs.log` (API failures +
backtraces), `ninestores-messages.log` (hunchentoot messages + `logIamhere`),
`ninestores-busfunctions.log` (DB create/update/delete/read-all errors).

**Useful live SQL** (credentials in `core/dod-ini-sys.lisp`; `hhubdb`, user `hhubuser`):

```sql
SHOW COLUMNS FROM DOD_PRD_MASTER;      -- the schema source of truth, NOT hhubplatform.sql
SHOW INDEX  FROM DOD_PRD_MASTER;       -- PRODUCT_CODE + PRODUCT_CODE_2, both unique
SELECT active_flag, approved_flag, approval_status, deleted_state, COUNT(*)
  FROM DOD_PRD_MASTER GROUP BY 1,2,3,4;
```

---

## 11. VERIFIED transcript (2026-09-13, probes against the running server)

Unauthenticated probes to `127.0.0.1:4244`. The distinction that carries the information is
**401 vs 404**: 401 means a route MATCHED and authentication then failed; 404
`no_such_endpoint` means no template matched. (Routing runs before auth in
`com-hhub-api-dispatch` — verified by these results.)

```
GET    /hhub/api/v1/catalog/products            → 401 unauthenticated
POST   /hhub/api/v1/catalog/products            → 401 unauthenticated
GET    /hhub/api/v1/catalog/products/118        → 401 unauthenticated
PUT    /hhub/api/v1/catalog/products/118        → 401 unauthenticated
DELETE /hhub/api/v1/catalog/products/118        → 401 unauthenticated

GET    /hhub/api/v1/catalog/products/118/images → 404 no_such_endpoint   (deliberately unbound ✓)
GET    /hhub/api/v1/catalog/products/nonsense   → 404 no_such_endpoint
GET    /hhub/api/v1/nope/nope                   → 404 no_such_endpoint
GET    /hhub/api/v1/warehouse                   → 401 unauthenticated   (pre-existing route)
```

**What this proves:** all five `register-api-route` bindings are registered and reachable;
method+path matching works; `api-authenticate` runs and the 401 path with its JSON error body
works; unknown paths 404; and an endpoint we chose NOT to bind is genuinely absent.
**What it does NOT prove:** anything past authentication — see §7.1.

Each probe also appended an entry to `ninestores-apilogs.log`, e.g.
`[2026-09-13 11:37:27] 401 unauthenticated GET /hhub/api/v1/catalog/products/template client=127.0.0.1`
— which is the API log working as designed.

Note `GET …/products/template` matched the `{id}` template (401 rather than 404): `template`
is NOT bound, so the parameterised template catches it. Harmless today, and exactly the
collision the literal-first ranking in `find-api-route` exists to resolve once a literal
`template` binding is added.

**Build evidence** (why a reload is NOT needed):

```
core/nst-bl-apidefs2    lisp 2026-09-12 23:57:04   fasl 2026-09-12 23:58:35
products/dod-bl-prd     lisp 2026-09-12 23:55:37   fasl 2026-09-12 23:58:36
products/dod-dal-prd    lisp 2026-09-12 23:31:58   fasl 2026-09-12 23:34:27
products/nst-bl-prdapi  lisp 2026-09-12 23:55:43   fasl 2026-09-13 00:00:22
acceptor (sbcl under detachtty) restarted 2026-09-13 07:56:33
```

---

## 12. RUNTIME VERIFICATION — smoke test, 2026-09-13

`test/smoke-products-api.sh` was run from a workstation against
`http://hunchentoot.local` with a real vendor session (`9999999990`). **12 passed, 1
failed.**

### What PASSED (and therefore what is now verified end to end)

```
session established (authenticated call answered 200)
GET list ?limit=2                       200   and returned exactly 2 objects
GET list ?status=active                 200
GET list ?status=inactive               200 []      ← empty list is 200, NOT 404
GET list ?name-like=LIVA                200
GET list whitelisted sort               200
GET list ?limit=2&offset=2              200
GET /products/<id>                      200
GET /products/999999                    404
GET /products/abc                       404         ← product-row-id-from-string guard works
GET list with NO session cookie         401
GET unbound endpoint                    404 no_such_endpoint
GET bad ?sort-by                        500         ← EXPECTED (taxonomy §7.3); should be 400
```

* **`?limit=2` returning exactly 2 objects is the proof that query-string support works** —
  before the `api-query-params` change that parameter was ignored entirely and the call
  returned every row. This is the single most valuable line in the run.
* `/products/abc` → 404 confirms the non-numeric-id guard: without it `parse-integer`
  would have raised and produced a 500.
* The whole read stack is exercised: `enumerate` → `select-products-by-filter` →
  `with-nst-db-read-all` → `copyProduct-dbtodomain` → `domain->response` → `render-json` →
  status mapping.

### What FAILED — and the bug behind it

```
FAIL POST with a soft-deleted product-code   got 500, want 409
     {"error":"internal_error","message":"the request could not be completed"}
```

The API log gave the condition and a full backtrace:

```
condition: the slot COM.NSTORES.APP::DELETED-STATE is missing from the object
           (#<COM.NSTORES.APP::DOD-PRD-MASTER …>)
6: ((:METHOD ?EXISTS ((EQL 'NST-PRD) STRING DOMAIN-CTX)) … "PRD-MPJ165U1Q7")
7: (ROUTE-PRODUCT-CREATE …)
```

**The slot was not missing.** The frame's arguments show the class was
`#<BUILT-IN-CLASS COMMON-LISP:CONS>` and the "object" was
`(#<DOD-PRD-MASTER …>)` — a LIST containing one row. `?exists` therefore called
`slot-value` on a CONS.

**Cause:** `select-product-by-code` returned `clsql:select`'s *list of rows*, whereas every
sibling by-identity selector in the file returns one row via `car`
(`select-product-by-id`, `select-product-pricing-by-id`, …). `with-db-call` hands its raw
payload straight to `?exists`, which reads a slot off it.

**Fix:** take the `car` inside `select-product-by-code`, so its shape matches its name and
its siblings. Doing it at the call site was rejected: the function is named "by-code",
singular, and callers should not have to know which shape each selector returns.

**Why nothing else noticed:** `copyProduct-dbtodomain` never reads `deleted-state` (it is
deliberately excluded), and `enumerate` legitimately expects a list. Only `?exists` and
`delete!` touch that slot, and only the former ran.

**Status: FIXED IN SOURCE, NOT YET RE-TESTED.** The running image still has the old
definition, so a reload is required before the 409 test can pass.

### Lesson worth keeping

Belnap payload shapes are implicit in this tree: `with-db-call` passes through whatever the
query returned (one row vs a list), while `with-nst-db-read-all` always yields a list. A
selector's return shape is therefore part of its contract even though nothing in its
signature says so. Match the sibling selectors' convention, and read the payload's SHAPE
from the call site's expectation rather than assuming.

### How to close it out

```lisp
;; in the running image (NOT a restart — a reload keeps sessions alive):
(asdf:load-system :nstores)
```

```bash
NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-products-api.sh --write
```

`--write` additionally exercises `make` (201), `!update` (200), `delete!` (200 ack),
repeat-delete (404) and the 409 `:C` path — the verbs that have still never run.

---

## 13. BUG #2 — provenance shape in the Belnap layer (SHARED CORE, fixed)

Found on the **second** run of the smoke test, after bug #1 was fixed. Same test, one layer
deeper, and this one is NOT products-specific.

```
condition: The value "nst-prd/?exists (product-code, deleted rows included)" is not of type LIST
0: (APPEND2 "nst-prd/?exists …" ("नियम-2: DELETED_STATE='Y' rows are invisible to every verb"))
1: ((:METHOD BO-MERGE-PROVENANCE (BO-KNOWLEDGE BO-KNOWLEDGE)) …)
2: ((:METHOD BO-MERGE (BO-KNOWLEDGE BO-KNOWLEDGE)) …)
3: (ROUTE-PRODUCT-CREATE …)
```

**Cause.** `bo-knowledge`'s `provenance` slot documents *"List of sources (strings or
symbols)"*, and `make-bo-knowledge` normalises whatever it is given into a list. But the
boundary macros in `core/nst-mult-logic.lisp` construct the class directly with
`make-instance 'bo-knowledge` (7 sites: `with-db-call`, `with-db-call-list`,
`with-db-read-all`, …) and pass `,source` straight through — so a knowledge object from
`with-db-call` carried a bare **string**. Every consumer in the tree appends provenance
(`bo-merge-provenance`, `bo-add-provenance`, and ~20 call sites in `hhub-bl-egn.lisp`,
`nst-bl-CustomerUser.lisp`), so the first merge did `(append "a string" (list …))` and
died.

**Fix** (`core/nst-bl-beltrusys.lisp`): a new `bo-provenance-as-list` helper plus an
`initialize-instance :after` method on `bo-knowledge` that forces the slot into list shape.
Enforced at the CLASS rather than at the 7 construction sites, so every path — including
future ones — obeys the contract the slot already declares. `make-bo-knowledge` now calls
the same helper instead of repeating the rule (the duplication is what allowed the two
paths to drift).

**This is a pre-existing platform bug, not a products one.** `nst-whs`'s `?exists` has the
identical shape (`with-db-call` + `bo-merge` to build the soft-delete `:C`), so the
WAREHOUSE 409 path would have failed the same way. It is listed as *"Not yet run: … the 409
:C path"* in `nst-bl-apidefs2-CONTEXT.md` §11 — which is exactly why it had never fired.
Fixing it in `beltrusys` repairs both.

**Verified after the fix:** `knowledge-join` really does map `:T ⊔ :F → +contradiction+`
(`core/nst-mult-logic.lisp:213`), so the path from `?exists` to a 409 completes:
`?exists` → `:C` → `route-product-create` returns `nst-entity-contradiction` → the
dispatcher's reverse ferry → `nst-response-contradiction` → `api-status-for-response` → 409
→ `render-json` → `{"error":"conflict","reason":…}`.

### The pattern worth naming

Both bugs were only reachable by RUNNING the code, and both sat on the same call chain:

1. `select-product-by-code` returned a list where its siblings return one row.
2. `with-db-call` returned knowledge whose provenance was a string where the class
   documents a list.

Neither is a compile error, neither is caught by a structural check, and neither is
reachable on the read-only path (the read path never merges knowledge and never reads
`deleted-state`). **Call the mutating tests as soon as a path is claimed to work.**

---

## 14. BELNAP: making all four states provable (2026-09-13)

The requirement: for a given API, prove that all four truth values pass — because
until they do, the four-valued layer is indistinguishable from ordinary error handling.

### 14.1 Where each state actually comes from (read this before designing a trigger)

| State | Produced by | Notes |
|---|---|---|
| **:T** | `with-db-call` when the form returns one non-nil value | |
| **:F** | `with-db-call` when the form returns nil | |
| **:U** | `with-db-call` when the form **raises anything** | logged to busfunctions.log |
| **:C** | `bo-merge` of two knowledges whose truths conflict (`knowledge-join`) — **or** duplicate PKs in the `*-read-all` variants | NOT a multi-row query! |

**THE TRAP:** `with-db-call`'s `:C` branch tests `(> (length results-list) 1)` on
`(multiple-value-list db-form)` — i.e. **multiple VALUES returned by the form**, not
multiple ROWS in the result set. A query returning 37 rows returns ONE value (a list)
and is therefore `:T` with a list payload. So:

> **A multi-row result is not a contradiction, and must never be reported as one.**
> It is a legitimate one-to-many answer whose honest shape is a list.

This corrected an earlier idea in this session ("37 live warehouses share one GSTIN, so
a by-GSTIN read is :C"). That was wrong: 37 rows is a *list*, and labelling it `:C`
would corrupt exactly the distinction the layer exists to protect.

The genuine `:C` for a **read** is the soft-deleted identity holder: the unique key says
the identity is TAKEN (`:T`) while नियम-2 says the row is INVISIBLE (`:F`) — two of the
domain's own rules disagree, and `bo-merge` resolves `:T ⊔ :F → :C`.

### 14.2 What changed

1. **`nst-whs`'s `fetch` was truth-blind** (`(if bk …)` on the bo-knowledge OBJECT,
   which is truthy whatever the answer). `:F` and `:U` both fell into the "found"
   branch and dereferenced a NIL payload → 500 for both, i.e. **the two states were
   indistinguishable**, which is the exact collapse this layer exists to prevent. It now
   maps `:T`→entity, `:F`→`nst-entity-nil` (404), `:U`→`nst-entity-unknown` (503),
   `:C`→`nst-entity-contradiction` (409).
2. **`warehouse-row-id-from-string`** guards the id parse, so `/warehouse/abc` is an
   ABSENCE fact (404) rather than being caught by `with-db-call` as `:U` — which would
   have answered 503 to a typo. (Mirrors `product-row-id-from-string`.)
3. **NEW VERB: `GET /hhub/api/v1/warehouse/by-identity`** — `route-warehouse-fetch-identity`
   addresses a warehouse by its IDENTITY tuple (GSTIN + wname + tenant) instead of its
   row-id, and returns all four states. This is the read that can legitimately answer
   `:C`. Both halves of the tuple are REQUIRED (400 otherwise): one GSTIN maps to many
   warehouses, so a GSTIN-only read is a one-to-many query, not a contradiction.
4. **ROUTE ORDER:** `by-identity` and `{id}` have the same segment count, so this endpoint
   only works because `find-api-route` now ranks literal segments above parameters. It is
   the live regression test for that ranking fix.

### 14.3 The tests (in `test/smoke-warehouse-api.sh`, section 3b)

`:F` is tested under **four different triggers**, because they are four different domain
facts — only one is the boring case:

| Trigger | Fixture | Why it matters |
|---|---|---|
| absent | id `999999` | the ordinary case |
| **cross-tenant** | id `123` (LIVE, but in tenant 1; session is tenant 2) | OWASP API1:2023 BOLA — a naive implementation answers 200 here |
| soft-deleted | id `53` (exists, `DELETED_STATE='Y'`) | नियम-2 hides it |
| absurd | `999999999999999999` | verified: MySQL returns 0 rows, no error → `:F`, NOT `:U` |

Plus `:T` by id and by identity, `:C` by identity, `:F` by identity, and a 400 for a
malformed identity read.

**ANTI-COLLAPSE ASSERTIONS** — the ones that make the rest meaningful: a miss must be 404
and must NOT be 503; a contradiction must be 409 and must NOT be 200 or 404. Without
these, "all four states pass" is decorative.

### 14.4 The one state still not proven over the wire: :U

`:U` needs a real boundary failure. Findings from investigating it:

* **A huge id does NOT work** — verified against MySQL: `= 999999999999999999`,
  `= 9223372036854775808` and `= 999999999999999999999999999999` all return **0 rows with
  no error**. Out-of-range comparison is just false. That path is `:F`.
* **Killing the connection works but is a one-shot runbook, not a suite test.** There is
  exactly ONE application connection (observable via `SHOW PROCESSLIST`: one idle
  `hhubuser` connection), and **nothing auto-reconnects** — `clsql:reconnect` appears in
  the tree only inside commented-out code. So a `KILL` breaks every DB-touching request
  until someone reconnects, and some UI controllers react to 2013/2006 by calling
  `stop-das`/`start-das`, i.e. a restart that invalidates all sessions.

`KILL` RUNBOOK (quiet window, deliberate, once — captures the transcript into this file):

```sql
-- 1. find the app's connection (the idle one, not yours)
SELECT id, time, state FROM information_schema.processlist
 WHERE USER='hhubuser' AND COMMAND='Sleep';
-- 2. KILL <that id>;
```
```bash
# 3. with a valid session, immediately: expect 503 {"error":"unknown"} — NOT 404
curl -sS -i -b jar "http://hunchentoot.local/hhub/api/v1/warehouse/127"
# 4. also expect the /by-identity read to answer 503 (not 409, not 404)
```
```lisp
;; 5. recover WITHOUT a restart and WITHOUT invalidating sessions:
(clsql:reconnect :database *dod-db-instance*)
```
Then re-run the GET to confirm 200 again. Alternative if a repeatable `:U` is wanted: a
**fault-injection seam** (a dev-only special that makes the named boundary call raise),
or a **split proof** (domain test that a boundary `:U` yields `nst-entity-unknown` + a
boundary test that `nst-entity-unknown` yields 503) — the latter proves the chain in
halves and never produces a 503 from a real request.

### 14.5 To activate all of this

```lisp
(asdf:load-system :nstores)     ; reload — the running image predates these changes
```
```bash
NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-warehouse-api.sh
```

---

## 15. THE MISSING CONTRACT — knowledge → domain result (core, 2026-09-13)

### 15.1 The diagnosis

conflodis2's *boundary* design was sound: `action->response` accepts an entity, a list,
a domain sentinel or a response model, and `api-status-for-response` maps the sentinels to
404/503/409. The *domain* side had no contract, and the four truth values were carried by
two types with **no bridge**:

| type | produced by | consumed by |
|---|---|---|
| `bo-knowledge` | the CRUD macros in `nst-mult-logic.lisp` | प्रत्यय methods |
| `nst-entity-nil` / `-unknown` / `-contradiction` | प्रत्यय methods | `domain->response` (the reverse ferry) |

Nothing converted between them, so every verb hand-rolled the mapping — and most verbs did
not convert at all: they **RAISED** on `:U` and `:C`. The pattern was stark:

> the classical part survived, the Belnap part was discarded.

Every verb handled "not found" with a sentinel, and answered *"I could not find out"* and
*"my own rules disagree"* with a plain error → **500**, indistinguishable from a crash and
from a legitimate 404. That is the same collapse found in `fetch` earlier in the day — it
was simply systemic on the write side.

### 15.2 New in `core/nst-bl-adhara.lisp` §5b

```lisp
knowledge-provenance-text        ; provenance → one readable string
knowledge-reason-for             ; :reason is a string OR a function of the truth
domain-sentinel-from-knowledge   ; the primitive: :F/:U/:C → the matching sentinel
domain-result-from-knowledge     ; the common case: :T → (:hydrate payload), else ↑
```

Three deliberate choices:

1. **`domain-sentinel-from-knowledge` REFUSES `:T`** — a `:T` is a fact, not a failure, and
   only the verb knows what to do with the payload (hydrate it, or — for `make` — treat it
   as a conflict). A verb that reaches it with `:T` has a control-flow bug, and 404/503/409
   would all be lies.
2. **`:reason` is per-state aware.** One message does not fit all three: for fetch,
   "row-id 999 not found in this tenant" is right for `:F`, but the same words in front of
   a `:U` would claim we looked and found nothing when we could not look at all — precisely
   the confusion this section exists to remove. It accepts a string or `(lambda (truth) …)`.
3. **`hydrate` has no default.** Substituting a sentinel for a payload the caller forgot to
   hydrate would turn a programming error into a plausible-looking 404.

Provenance is always appended to the reason: it is where the *why* lives (नियम-2's
explanation of a soft-deleted identity holder), and a 409 nobody can act on is worthless.

### 15.3 Write verbs: raising → four-valued

| Verb | `:F` | `:U` | `:C` |
|---|---|---|---|
| `make` | contradiction → **409** (lost race) | unknown → **503** | unreachable → error |
| `!update` | nil → 404 | unknown → **503** | unreachable → error |
| `delete!` | nil → 404 | unknown → **503** | unreachable → error |
| `enumerate` | `'()` → 200 `[]` | unknown → **503** | contradiction → **409** |

Two structural points:

* **`make :before` became `make :around`.** A `:before` method's return value is DISCARDED
  — raising was its only way to refuse, so every refusal became a 500. An `:around` method
  can short-circuit and return a value, keeping the "refuse before the INSERT" property
  while speaking in four values.
* **The `:C` law moved out of the routes into the verb.** `route-warehouse-create` and
  `route-product-create` each did the soft-deleted-identity pre-check themselves, so **only
  the HTTP path ever saw a 409** — the internal website and any REPL caller still crashed
  with a 500. The law belongs to the प्रत्यय, not to the transport; removing it deleted a
  duplicate implementation and fixed the non-HTTP callers.

`delete!` still returns `T` for its success ack — the known 5th return shape (§ review).
Left alone deliberately: it is a verified client-visible contract, and changing it is a
separate decision.

### 15.4 Still open from the same review

* **The contract is still not enforced.** `action->response`'s `((null domain) nil)`
  launders a verb that returns bare NIL into a **404** — indistinguishable from a genuine
  `:F`. The six real return shapes (entity | nil | unknown | contradiction | `T` ack | list)
  are documented nowhere in code.
* **No `knowledge-conjoin`.** `bo-merge`/`knowledge-join` is the truth-order JOIN (⊔t):
  `(T, U) → T`, i.e. *any source saying true wins*. Correct for gathering evidence, WRONG
  for sequencing steps — a compound verb like `order->invoice` built on it would report
  success when one step was merely unknown. Compound verbs need the truth-order MEET (⊓t):
  `T⊓T=T`, `T⊓F=F`, **`T⊓U=U`**. Do this BEFORE writing any compound verb.

---

## 16. VERIFIED — the four states over the wire (2026-09-13, 19:50)

`test/smoke-warehouse-api.sh` → **25 passed, 0 failed, 0 known-defects**, after reloading
the running image. The Belnap section 3b is the part that matters:

```
PASS :F absent id → 404                               404
PASS :F another tenant's id → 404 (BOLA)              404
PASS :F soft-deleted id → 404 (नियम-2)                 404
PASS :F absurd id → 404 (MySQL: 0 rows, no error)     404
PASS :T live id → 200 + entity                        200
PASS :C identity held by a soft-deleted row → 409     409   ← a READ producing :C
PASS :T live identity → 200 + entity                  200
PASS :F unknown identity → 404                        404
PASS identity read missing wname → 400                400
PASS anti-collapse :F ≠ :U                            404 (a miss is NOT 503)
PASS anti-collapse :C ≠ :T, :C ≠ :F                   409 (not 200, not 404)
```

The three `:F` fixtures were confirmed against the database, not merely asserted: row **127**
is live in the session tenant, row **123** is **live in tenant 1** (so its 404 is the
security-relevant BOLA case), and row **53** is soft-deleted in the session tenant.

`--write` also passed (201 / 200 / ack 200 / 404 / 404), and the storage layer was checked
directly — row **128** showed `w_city=Nashik`, `w_manager=API Smoke` (the partial update
persisted AND preserved the other fields) and `deleted_state='Y'`. So `make`, `!update` and
`delete!` are verified end to end, not just at the response layer.

**Status: `:T`, `:F` and `:C` are now proven over HTTP on a READ verb. `:U` is the only
state not yet triggered — it needs the KILL runbook (§14.4) or a fault-injection seam.**

### 16.1 NEW FINDING — the states that need a human are the ones that leave no trace

The API log records failures raised as **conditions** (`api-fail` → `api-log-error`). It does
**not** record failures that arrive as **Belnap sentinels**, because `api-run-route` derives
the status from the response and writes it directly.

Verified: the whole log contains **zero `503` entries**, and the bad-`sort-by` 503 from this
run is absent — while the `400`, `401` and `404 no_such_endpoint` from the same run *are*
present (those three come from conditions). So:

| answer | arrives as | logged? |
|---|---|---|
| 400 / 401 / 404 routing | condition | yes |
| 404 from `:F` | sentinel | **no** |
| **409 from `:C`** | sentinel | **no** |
| **503 from `:U`** | sentinel | **no** |

`:F` being quiet is arguably fine — a miss is ordinary traffic. But **`:U` ("I could not find
out") and `:C` ("my own rules disagree — a human must decide") are precisely the two
responses an operator needs to see**, and both are currently invisible in
`ninestores-apilogs.log`. For the sort-by case the cause is recoverable from
`busfunctions.log`, but a `:U` from a real boundary failure in a verb that does not log would
leave nothing anywhere.

**Recommendation:** in `api-run-route` (apidefs2), log the response-derived non-success
verdicts — at minimum `:U` and `:C`, with the sentinel's `reason`, which now carries the
provenance thanks to `domain-sentinel-from-knowledge`. One `when` around the existing
`api-write-json` call.

---

## 17. HANDOFF — starting the VENDOR API (read this first, in a fresh chat)

### 17.1 The vendor domain today looks exactly like products did on 2026-09-12

| | |
|---|---|
| `vendor/nst-bl-vendapi.lisp` | **stale spec** — 9 `register-outbound-route` entries for the pre-conflodis2 registry, same dead pattern `products/nst-bl-prodapi.lisp` had (names classes that do not exist, paths unreachable through nginx) |
| `vendor/dod-dal-venue.lisp`? no — | `vendor/dod-dal-ven.lisp`, `dod-dal-vad.lisp`, `dod-dal-vas.lisp`, `dod-dal-vpm.lisp` — the CLSQL view-classes |
| `vendor/dod-bl-ven.lisp` etc. | the legacy function layer |
| `vendor/dod-ui-ven.lisp` | the legacy UI — **5,000+ lines**, and it contains `dod-vend-login` |
| **`nst-vnd`** | **does not exist yet** — no domain class, no Tier-1 प्रत्यय, no action routes, no API bindings |

So the vendor work repeats the products path: domain class → Tier-1 प्रत्यय → reverse ferry →
action routes → API bindings. **Use `warehouse/` and `products/` as the templates**, not the
older `customer/`/`invoice/` API files, which still use the dead outbound-route style.

### 17.2 Files a fresh session should read, in this order

1. `core/nst-bl-apidefs2-CONTEXT.md` — the Ring-4 conventions, status mapping, deployment/nginx reality.
2. **this file** — §2 (schema discipline: verify the LIVE table, not `hhubplatform.sql`), §6 (the design decisions), §14–16 (Belnap, what is proven).
3. `hhub/warehouse/nst-bl-whsapi.lisp` — the reference route file (verbs, registrations, API bindings).
4. `hhub/products/nst-bl-prdapi.lisp` + `products/dod-bl-prd.lisp` — the newest domain: the Tier-1 प्रत्यय written from scratch.
5. `core/nst-bl-adhara.lisp` — §1 (sentinels), §5b (**the knowledge→domain-result converters**), §6 (the universal प्रत्यय + their documentation contracts).
6. `test/smoke-products-api.sh` / `test/smoke-warehouse-api.sh` — the test pattern, including `expect-known` and the Belnap section.

### 17.3 Environment facts that are NOT obvious and cost time

* **The app does NOT load the `.fasl` files beside the sources.** It loads from
  `/home/hunchentoot/.cache/common-lisp/sbcl-2.6.8-linux-x64/home/ubuntu/ninestores/hhub/`.
  `package/compile.lisp` (the "Nine Stores Compilation", logged to `hhub/logs/compilation-<ts>.log`)
  writes fasls BESIDE the sources — a successful compile there does **not** change the running image.
* **Reload the running image with `(asdf:load-system :nstores)`** — not a restart. A restart calls
  `reset-session-secret` and kills every session; a reload preserves them.
* **`nstores.asd` has no `:depends-on`.** `startup/load.lisp` preloads 16 dependency systems before
  `(ql:quickload :nstores)`. A bare load in a fresh image dies on `core/dod-dal-bo.lisp`
  with *"Package CLSQL does not exist"*.
* **`hunchentoot.local` resolves IPv6-only** on the server; use `127.0.0.1` (nginx :80, or the
  acceptor directly on :4244, where `/hhub/...` arrives unchanged).
* **Max 2 concurrent vendor logins, eviction oldest-first** — a curl login can silently bounce a
  browser session, and vice versa. Failed logins do not consume a slot.
* **Vendor login contract:** `dod-vend-login` matches `dod_vend_profile.phone` and requires
  `approved_flag='Y' AND approval_status='APPROVED' AND deleted_state='N'`; the password is
  salted-hashed (`check-password`) and unrecoverable. Failures are logged to
  `hhub/logs`-adjacent `ninestores-busfunctions.log` as
  `vendor-login-failed phone=… reason=vendor-not-found-or-disabled|password-mismatch`.
  `dodvendlogin` returns **302 for success AND failure** — never read the status as the outcome.
* **The API log only records CONDITION-derived failures.** Sentinel-derived `:F`/`:U`/`:C`
  responses are invisible there (§16.1).
* **Demo tenant is 2** (the login's company), which is what the warehouse/products fixtures assume.
  Products live in tenant 5 as well as 2 — do not assume one tenant.

### 17.4 Open items, in the order I would do them

1. **`knowledge-conjoin`** — the truth-order MEET (⊓t) for compound/sequenced verbs.
   `bo-merge`/`knowledge-join` is the optimistic JOIN: `(T, U) → T`. Correct for gathering
   evidence, **wrong** for sequencing, and it would silently report success for `order->invoice`
   when a step was merely unknown. Do this before any compound verb (§15.4).
2. **Log sentinel-derived `:U` and `:C`** in `api-run-route` — they are the two states that need a
   human, and neither leaves a trace today (§16.1). The sentinel `reason` now carries provenance.
3. **Hoist parameter validation out of the DB macro bodies** + a 4xx condition. Today
   `validate-sort-args` raises inside `with-nst-db-read-all`, whose catch-all `(error …)` turns it
   into `:U` → **503 for a permanently-invalid parameter** (it was 500 before; 503 is worse, it
   invites a retry). See the header of `test/smoke-warehouse-api.sh`.
4. **Enforce the verb return contract** — `action->response`'s `((null domain) nil)` launders a
   verb returning bare NIL into a 404 (§15.4).
5. **Prove `:U` over the wire** — the KILL runbook (§14.4) or a gated fault-injection seam.
   `:T`, `:F` and `:C` are done (§16).

### 17.5 A note on the four-state vocabulary, since it recurs

`with-db-call`'s `:C` fires on **multiple VALUES returned by the form**, NOT on multiple rows —
a 37-row result is `:T` with a list. Genuine `:C` comes from `bo-merge` of conflicting truths
(e.g. an identity held by a soft-deleted row: taken per the unique key, invisible per नियम-2).
Getting this wrong would corrupt the one distinction the layer exists to make (§14.1).

---

## 18. `knowledge-conjoin` — composing a SEQUENCE of steps (core, 2026-09-13)

Closes open item #1. **Not yet compiled or loaded** at the time of writing — run
`(asdf:load-system :nstores)` and then the probe below.

### 18.1 Why it is not `bo-merge`

`bo-merge`/`knowledge-join` is the **information-order join (⊔i)**: *more information wins*.

```
(T,T)=T   (T,F)=C   (T,U)=T   (T,C)=C
(F,F)=F   (F,U)=F   (U,U)=U   (·,C)=C
```

That is **correct for gathering evidence**: a source saying T out-ranks one saying nothing.

It is **wrong for sequencing**. A compound verb asks "did ALL of this happen?", and under ⊔i an
unknowable step is silently absorbed — `(T,U)=T` **reports success for an action with a step we
could not determine**. A false success is the most dangerous answer this architecture can give.

> **⊔i gathers evidence; conjoin composes steps.**

### 18.2 The rules

| steps | verdict | meaning |
|---|---|---|
| all `:T` | `:T` | the action completed |
| all `:F` | `:F` | definitively nothing happened — **and only then**, because `:F` is what tells a caller "safe to retry" |
| any `:C` | `:C` | a step is in contradiction; a human must look |
| some `:T` **and** some `:F` | `:C` | **PARTIAL APPLICATION** — step 1 says "completed", step 2 says "did not"; we were told both, which is exactly Belnap `:C`. Deliberately NOT `:F`: reporting failure would invite a blind retry that re-applies what DID commit |
| otherwise (any `:U`) | `:U` | a step is unknowable, so no outcome can be stated — also not `:F`, for the same retry reason |

### 18.3 Order-independence, and why it is N-ARY

These rules are a function of the **set** of step outcomes, not their order. The natural
**pairwise** version is NOT associative — `(T,U)→U` erases the fact that a `T` was seen, so a
later `F` can no longer detect the partial application:

```
((T,U),F) = (U,F) = U        but the set {T,U,F} is :C
((T,F),U) = (C,U) = C        while ((T,U),F) = U   — the same three steps!
```

A fold-left would therefore give **different verdicts for the same three step outcomes depending
on order**. Conjoin is deliberately n-ary, there is **no pairwise entry point to misuse**, and
`bo-conjoin*` does not fold — it reads the whole list at once.

### 18.4 Verified (design table checked exhaustively, 4³ combinations)

```
order-independence violations: 0
P1  :T only if all :T            0 violations
P2  :F only if all :F            0 violations
P3  :U never masked by T/F       0 violations
P4  :C never masked              0 violations
```

Contrast with `bo-merge`, on the cases that matter:

| steps | bo-merge | conjoin | |
|---|---|---|---|
| `T,U` | **T** | U | merge reports success for an unknown step |
| `F,U` | **F** | U | merge says "nothing happened" when it might have |
| `T,T,U` | **T** | U | |
| `F,F,U` | **F** | U | |
| `T,F` | C | C | agree — partial application |

### 18.5 New API

```lisp
;; core/nst-bl-beltrusys.lisp
*knowledge-truths*            ; the four valid truths; conjoin VALIDATES against it
(knowledge-conjoin truths)    ; (list of :T/:F/:U/:C) → one verdict   [n-ary]
(bo-conjoin  klist)           ; list of bo-knowledge → one bo-knowledge
(bo-conjoin* &rest klist)     ; convenience; NOT a fold

;; core/nst-bl-adhara.lisp §5b — the bridge that makes it usable from a verb
(domain-result-truth result)  ; entity|sentinel|list|T → :T/:F/:U/:C
```

`domain-result-truth` is the missing half: a प्रत्यय answers with an **entity or sentinel**, never
a `bo-knowledge`, so without it `bo-conjoin` is only reachable from code calling the CRUD macros
directly — which is not where compound verbs live.

`bo-conjoin` merges **provenance as a union**, which is the point: a compound verdict must be able
to name every step that produced it. The payload is the **decisive** step's — the first whose
truth equals the verdict, or, for a partial application (where `:C` appears in no single step),
the first `:F`, because that is the step that stopped the sequence.

Two documented warts:

* **`nil` is ambiguous in CL** (`nil` IS the empty list), so `domain-result-truth` cannot tell a
  bare-`nil` verb result from an empty collection. It reads `nil` as `:F`, which means an **empty
  `enumerate` composed into a compound verb reads as `:F`**. Inherent to the language, and one more
  reason the verb contract should require explicit sentinels (§15.4).
* An **empty step list signals** rather than answering `:T` — a vacuously-true verdict would let a
  mis-built step list masquerade as success (same discipline as `:hydrate` having no default).

### 18.6 A compound verb, then, looks like this

```lisp
(defun route-order-to-invoice (request ctx)
  (let* ((order   (make 'nst-ord ctx …))          ; each step answers with a result
         (invoice (make 'nst-inv ctx …))
         (verdict (bo-conjoin* (make-bo-knowledge :truth (domain-result-truth order)
                                                  :payload order :provenance "nst-ord/make")
                               (make-bo-knowledge :truth (domain-result-truth invoice)
                                                  :payload invoice :provenance "nst-inv/make"))))
    ;; verdict :T → the invoice entity;  :C → a contradiction the client must not
    ;; blind-retry;  :U → 503;  :F → 404.  Provenance names BOTH steps.
    (case (bo-knowledge-truth verdict)
      (:T (bo-knowledge-payload verdict))
      (otherwise (domain-sentinel-from-knowledge verdict ctx :reason "order->invoice")))))
```

---

## 19. THE `t` TRAP, and why "Failed: 0" cannot be trusted (2026-09-13, 20:xx)

### 19.1 The bug I introduced

`knowledge-conjoin` (§18) was written with five occurrences of:

```lisp
(every (lambda (t) (eq t +true+)) truths)      ; ← WRONG
```

**`t` is `COMMON-LISP:T`, a defined constant, and Common Lisp forbids it as a variable
name.** SBCL reports it as a compile ERROR:

```
;   COMMON-LISP:T names a defined constant, and cannot be used in an ordinary lambda list.
```

Renamed to `tr`. Also found the same illegal pattern **pre-existing** in
`customer/wallets/nst-bl-custwallets.lisp:694`, inside `get-spending-trends` — a latent
landmine in the wallet analytics path (see §19.3).

### 19.2 How it hid, and why this is the important part

This is not a story about a typo. Three things conspired to make a broken function look
shipped:

1. **SBCL writes the fasl ANYWAY.** Verified: `compile-file` signals the error, and a fasl
   is still produced. The definition is compiled into a **stub that raises when called**:
   ```
   Unhandled SB-INT:COMPILED-PROGRAM-ERROR
     Execution of a form compiled with errors.
   ```
   So the failure surfaces at *runtime*, as far from the typo as possible.
2. **The build script counted it as a success.** `package/compile.lisp` reported
   `Total Files: 122   Failed: 0` — and its log contains **zero** occurrences of SBCL's own
   `caught ERROR` text (`grep -c caught` = 0). It logs only `[WARNING]`/`[STYLE-WARNING]`/
   `[NOTE]`, so SBCL's error reporting never reaches the log. **"Failed: 0" means "the
   script saw no failure it recognises", not "the file compiled".**
3. **The build DELETES the old fasl before compiling** (`Deleting old .fasl: …`). A failed
   compile therefore replaces a working fasl with a broken one — strictly worse than leaving
   the stale one in place, and invisible if you only check that the fasl exists.

**Consequence for every verification claim in this file:** "it compiled" was never evidence.
The two compile logs earlier today (§ header, and the 19:33/20:00 runs) prove only that the
script did not *notice* a failure. The checks that do mean something are: the structural
parse, SBCL's raw output, and **calling the code**.

Suggested build hardening (not done):
* treat SBCL's `caught ERROR` / `caught N fatal ERROR conditions` as a FAILURE;
* report the raw compiler output, not a filtered summary;
* compile to a temp file and move it into place only on success, so a failed compile cannot
  destroy a good fasl.

### 19.3 VERIFIED — conjoin compiled AND CALLED

This time the code was not merely parsed: it was compiled and **executed** under a stub
environment (plain SBCL, no Quicklisp). **25 assertions, all passing.**

```
truth table (n-ary, order-independent)
  T=>T  T,T=>T  F=>F  F,F=>F  U=>U  C=>C
  T,F=>C   T,F,F=>C   T,U=>U   F,U=>U   T,F,U=>C   T,T,U=>U   F,F,U=>U
  T,C=>C   U,C=>C

bo-conjoin
  T+U verdict => U                      provenance union => (step/order step/invoice)
  decisive payload (:U step)            timestamp = max
  T+F = partial application => C         decisive payload = the FAILING step
  order-independence {T,U,F} => C

guards
  empty truth list signals · unrecognized truth signals · empty klist signals
```

The `bo-conjoin` behaviour that matters most is confirmed live: **`T + U` yields `:U`, not
`:T`** — the false success that `bo-merge` would have produced (§18.1) — and a partial
application yields `:C` with the failing step's payload.
