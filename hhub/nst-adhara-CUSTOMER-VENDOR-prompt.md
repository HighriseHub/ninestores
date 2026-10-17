# Prompt: Bring Customer & Vendor into the nst-bl-adhara.lisp (Panini-grammar) architecture

You are refactoring two Common Lisp domain aggregates — **Customer** and **Vendor** —
so they conform to the same "island + ferry" architecture the **Warehouse** aggregate now
follows. Use the Warehouse files as the **master template**: copy their structure, patterns,
naming, and error-handling shape, and adapt only the fields/behavior that differ.

---

## 1. Source of truth — read these first, in this order

1. `hhub/core/nst-bl-adhara.lisp` — the grammar/architecture. Defines the two class trees,
   the boundary models, the verbs, `request->dispatch` (THE FERRY), `extract-domain-initargs`
   (MOP field filter), `domain->response` (reverse ferry), and the render contracts. **This is
   the spec. Do not fight it.**
2. `hhub/warehouse/nst-dal-warehouse.lisp` — MASTER TEMPLATE: domain class + request/response
   models + ORM view-class.
3. `hhub/warehouse/nst-bl-warehouse.lisp` — MASTER TEMPLATE: verbs (make/fetch/enumerate/
   !update/delete!/?exists), domain->response / domain->response-list, render methods.
4. `hhub/warehouse/nst-ui-warehouse.lisp` — MASTER TEMPLATE: HTTP action handlers that ride
   the ferry.
5. The existing Customer/Vendor files to migrate (see §5).

---

## 2. The architecture in one paragraph (the mental model)

The **domain entity lives in the island** (Tree 1, subclass of `nst-domain-entity`).
A **request model ferries IN** across the boundary, **`request->dispatch`** is the ferry that
hands the request's params to a **verb** (`make`/`fetch`/`enumerate`/`!update`/`delete!`/
`?exists`) operating on the domain entity. The result is carried **OUT** by the **response
model** (`domain->response` → `nst-response-model`), then rendered to HTML/JSON. The request
model **dies at the ferry** (लोप) and the domain entity **never crosses into the UI**.

---

## 3. Hard rules (compliance checklist)

### 3.1 Domain class (the "in the island" entity)
- Subclass `nst-domain-entity`. **NEVER** inherit `BusinessObject`, `nst-boundary-object`,
  `nst-request-model`, or `nst-response-model`.
- Declare **every business field slot** with `:initarg <same-keyword> :accessor <name>`
  so the MOP (`extract-domain-initargs`) can introspect them automatically.
- **Do NOT redeclare** `id/tenant-id/created-at/updated-at/deleted-state` — they are inherited.
  `:tenant-id` is set from `ctx`, never from client input.
- Give the class a `:documentation` string.

### 3.2 Request model (inbound boundary) — get this RIGHT
- Subclass `nst-request-model`.
- **SLOTLESS.** Carry **no per-field typed slots**. All inbound data (including `:row-id`)
  travels as a plist in the inherited `params` slot.
- `params` already defaults to `nil` (do not re-add initforms unless you need one).
- Lesson learned: earlier we added 40+ typed field slots to `WarehouseRequestModel`; they were
  **dead weight** because `request->dispatch` reads only `(params rm)`, never the typed slots.
  Do not repeat that mistake.

### 3.3 Response model (outbound boundary)
- Subclass `nst-response-model` (per adhara). Note: `WarehouseResponseModel` still subclasses
  `nst-boundary-object` directly — treat that as a **known gap to fix**, and do the correct
  thing (`nst-response-model`) for Customer/Vendor.

### 3.4 Verbs — implement as CLOS methods specialized on `(eql '<class-symbol>)`
Model the bodies exactly on `nst-bl-warehouse.lisp`:
- `make 'nst-X ctx &rest initargs` — construct `make-instance` with `:tenant-id` from ctx +
  filtered initargs; run a `?exists` uniqueness `:before` check for any unique field (e.g.
  GSTIN); persist via the ORM copy + `with-nst-db-create` + `clsql:update-records-from-instance`;
  return a Belnap-typed result (`:T`/`:F`/`:U`/`:C`).
- `fetch 'nst-X id ctx` — tenant-scoped single read; return the entity or the
  `nst-entity-nil`/`-unknown`/`-contradiction` sentinel (never bare nil).
- `enumerate 'nst-X ctx &key <query filters>` — tenant-scoped list via a filter-clause helper
  (`build-*-filter-clauses` + `select-*-by-filter`), hydrated per-row, `bo-knowledge-truth`
  dispatch.
- `!update entity row-id ctx &rest changed-slots`, `delete!`, `?exists` — mirror warehouse.

### 3.5 The ferry in the UI layer
- Actions build a request model (with a `params` plist) and call
  `(request->dispatch rm '<verb> '<class> ctx)`. Do **not** call the verb directly from UI.
- Reverse ferry is `domain->response` / `domain->response-list`.
- `ctx` (`domain-ctx`) tenant must come from the **session**, never from client params
  (नियम-1 tenant isolation).
- Do not pass request models or domain entities to render functions; render only response models.

---

## 4. Corrections & gotchas we learned (apply them so you don't repeat them)

1. **Request model = slotless params bag.** (see §3.2) — highest-value lesson.
2. **`params` must be bound** — empty request models now get `params = nil` by default; never
   assume a slot has a value without an `:initform`.
3. **Delete old files from BOTH `compile.lisp` AND `nstores.asd`** (we missed the `.asd` the
   first time and it still referenced the removed `dod-*-wrh` files).
4. **`extract-domain-initargs` only forwards keys the DOMAIN class declares as initargs.** For
   constructor verbs (`make`, `?exists`) that is exactly right. But **query-filter keys on
   `enumerate` (e.g. `:name-like`, `:city`, `:sort-by`) are NOT domain slot initargs**, so the
   `enumerate` ferry hop currently drops them. Known limitation (a core-side
   `strip-reserved-initargs` forward is pending). If you need filtered `enumerate` through the
   ferry today, flag it rather than silently losing filters; otherwise call the enumerate verb
   directly only where the UI has no other choice, and annotate why.
5. **Domain→ORM copy functions** read domain slots and map to DB columns (e.g. domain `company`
   row-id → DB `tenant-id`). Keep the two copy helpers (`-domaintodb` / `-dbtodomain`) symmetric
   and field-complete.
6. **Never call the verb generics with a request model as the entity/class argument** — the
   domain verbs reject boundary objects (immunity test exists).
7. Keep `render-*` methods as explicit **per-field allowlists** (security): nothing leaks
   outbound unless that method's accessors read it.

---

## 5. Per-entity steps

### 5.1 Customer
The customer aggregate already has an `nst-*` triple:
`hhub/customer/nst-dal-Customer.lisp`, `hhub/customer/nst-bl-Customer.lisp`,
`hhub/customer/nst-ui-Customer.lisp`.
1. Read each and diff its structure against the warehouse template.
2. Refactor the domain class to the §3.1 rules; make any existing request model slotless per
   §3.2; point the response model at `nst-response-model` per §3.3.
3. Ensure every verb in §3.4 exists and is specialized correctly; add any missing
   `domain->response`, `render-html`/`render-json`, filter helpers.
4. Rewire UI action handlers to ride the ferry per §3.5.
5. Update `compile.lisp` and `nstores.asd` ordering (DAL → BL → UI). Retire/delete legacy
   `dod-*cus*` handlers only after their routes/functions are migrated.

### 5.2 Vendor
There is **no** `nst-dal/bl/ui-Vendor` triple yet (only legacy `dod-*vad*`/`-ven*`/`-vpm*` and
side `nst-bl-*` files). Vendor is the big build.
1. From the legacy `dod-dal-ven.lisp`/`dod-dal-vad.lisp` ORM/domain classes, extract the real
   Vendor field set and produce `hhub/vendor/nst-dal-Vendor.lisp` in the §3.1/§3.2/§3.3 shape
   (domain class + slotless request model + `nst-response-model` response model + ORM view-class).
2. Produce `hhub/vendor/nst-bl-Vendor.lisp` implementing all verbs in §3.4 by mirroring
   `nst-bl-warehouse.lisp`.
3. Produce `hhub/vendor/nst-ui-Vendor.lisp` action handlers riding the ferry per §3.5.
4. Register all three in `compile.lisp` and `nstores.asd` (DAL → BL → UI).
5. Migrate/delete legacy `dod-*ven*` files and update every other file that referenced them
   (including `nstores.asd` and any function index).

---

## 6. Definition of done
- Both aggregates compile and load in the new architecture with no references to removed legacy
  classes/files in the build path.
- Every verb + both ferries + render methods exist and mirror the warehouse template.
- No request model has typed field slots; every response model subclasses `nst-response-model`.
- `compile.lisp` and `nstores.asd` reference only live files, in the right order.
- No domain entity or request model is passed into a render function or a legacy verb.

## 7. Work incrementally & confirm
Change ONE aggregate (recommend Customer first, since a partial triple exists) and ONE concern
at a time. Show diffs, wait for approval between steps. If a design point conflicts with the
adhara spec, ask instead of improvising.
