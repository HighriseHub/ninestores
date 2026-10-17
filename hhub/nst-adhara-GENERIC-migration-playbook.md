# Playbook: Migrate any entity from the DDD base (`hhub-bl-ent.lisp`) to the island+ferry grammar (`nst-bl-adhara.lisp`)

> Generic step-by-step instructions, derived from `hhub/nst-adhara-CUSTOMER-VENDOR-prompt.md`.
> That prompt covered Customer & Vendor specifically; this playbook generalises it to **any** entity
> whose code was written on the old `hhub-bl-ent.lisp` architecture (`BusinessObject` /
> `RequestModel` / `ResponseModel` / `ViewModel` / `AdapterService` / `PresenterService` /
> `HTMLView` / `JSONView`, the `doCreate/doRead/doReadAll/doUpdate/doDelete` service verbs and
> `Process*Request` adapter verbs).
>
> Use the **Warehouse aggregate as the master template**. Copy its structure, patterns, naming and
> error handling verbatim; adapt only the fields and behaviour that differ per entity.
>
> Apply **one entity, one concern at a time** (see §11). When the agent says "migrate entity X",
> fill X into the placeholders below.

---

## 1. Source-of-truth files — read these first, in this order

1. `hhub/core/nst-bl-adhara.lisp` — **the spec / the grammar.** Domain tree (`nst-domain-entity`
   + Belnap sentinels), boundary tree (`nst-request-model` / `nst-response-model` / `nst-view-model`
   + sentinels), the carrier `domain-ctx`, the ferry `request->dispatch` (with the `make`/`fetch`/
   `enumerate`/`!update`/`delete!`/`?exists` methods), `extract-domain-initargs` (the MOP field
   filter), `*reserved-initargs*`, `domain->response` (reverse ferry), the `render-json`/
   `render-html` contracts, `build-domain-ctx-from-request`, नियम-1/2/3 and immunity tests.
   **Do not fight it.**
2. `hhub/warehouse/nst-dal-warehouse.lisp` — MASTER TEMPLATE (DAL): domain class + slotless
   request model + response model + ORM `clsql:def-view-class`.
3. `hhub/warehouse/nst-bl-warehouse.lisp` — MASTER TEMPLATE (BL): verbs, sort whitelist,
   filter-clause helper, query/select helpers, copy helpers (`-domaintodb` / `-dbtodomain`),
   `domain->response`, `domain->response-list`, `render-json`.
4. `hhub/warehouse/nst-ui-warehouse.lisp` — MASTER TEMPLATE (UI): HTTP action handlers that ride
   the ferry, plus `render-html` methods.
5. `hhub/core/hhub-bl-ent.lisp` — the OLD base this migration moves the entity OFF of (read only
   to know which legacy classes/verbs the entity currently uses, so you can retire them).
6. The entity's own existing `nst-*`/`dod-*` DAL / BL / UI files (see §5 "current files").

---

## 2. The architecture in one paragraph (the mental model)

The **domain entity lives in the island** (Tree 1, subclass of `nst-domain-entity`). A **request
model** (`nst-request-model`) ferries IN across the boundary as a slotless `params` bag; the ferry
**`request->dispatch`** hands the params to a **verb** (`make` / `fetch` / `enumerate` /
`!update` / `delete!` / `?exists`) operating on the domain entity. The result is carried OUT by the
**response model** (`domain->response` → `nst-response-model` subclass), then rendered to HTML/JSON
via `render-html` / `render-json`. The request model **dies at the ferry** (लोप) and the domain
entity **never crosses into the UI**.

Old→new mapping at a glance:

| Old (`hhub-bl-ent.lisp`) | New (`nst-bl-adhara.lisp`) |
|---|---|
| `BusinessObject` entity class | domain class subclassing **`nst-domain-entity`** |
| `BusinessObjectNIL/Unknown/Contradiction` | `nst-entity-nil` / `-unknown` / `-contradiction` |
| `RequestModel` **with typed field slots** | **slotless** `nst-request-model`; data rides in `(params rm)` |
| `ResponseModel` (subclass of `BusinessObject`) | `nst-response-model` (Tree 2) |
| `ViewModel`, `HTMLView`, `JSONView` | no view models — render **response models** directly |
| `AdapterService` + `ProcessCreate/Read/ReadAll/Update/DeleteRequest` | `request->dispatch` (**the ferry**) + verbs |
| `BusinessService` + `doCreate/doRead/doReadAll/doUpdate/doDelete` | verb methods `make`/`fetch`/`enumerate`/`!update`/`delete!`/`?exists` |
| `PresenterService` + `Create(All)ViewModel` | `domain->response` / `domain->response-list` / `render-*` |
| `setCompany` / db-* / `Copy-BusinessObject-To-DBObject` | `ctx` tenant + `-domaintodb`/`-dbtodomain` copy helpers |
| `register-outbound-route` DDD dispatch | action handler building rm + `request->dispatch` |

---

## 3. Per-entity naming & deliverables

Produce/refactor these three files (placeholders: `Customer` → `Vendor` → `Warehouse` …):

- `hhub/<gana-dir>/nst-dal-<Entity>.lisp` — domain class + slotless request model + response model
  + ORM `clsql:def-view-class`.
- `hhub/<gana-dir>/nst-bl-<Entity>.lisp` — the six verbs + copy/filter/query helpers +
  `domain->response` + `domain->response-list` + `render-json`.
- `hhub/<gana-dir>/nst-ui-<Entity>.lisp` — ferry-riding action handlers + `render-html` methods.

Pick a clear, unambiguous domain symbol (e.g. `nst-whs`) and name request/response models
consistently (e.g. `WarehouseRequestModel`, `WarehouseResponseModel`).

---

## 4. Hard rules (compliance checklist)

### 4.1 Domain class (the island entity)
- Subclass `nst-domain-entity`. **NEVER** inherit `BusinessObject`, `nst-boundary-object`,
  `nst-request-model`, or `nst-response-model`.
- Declare **every business field slot** with `:initarg <same-keyword> :accessor <name>` so the MOP
  (`extract-domain-initargs`) can introspect them automatically.
- **Do NOT redeclare** `id`/`tenant-id`/`created-at`/`updated-at`/`deleted-state` — they are
  inherited. `:tenant-id` is set from `ctx`, never from client input.
- Give the class a `:documentation` string. Note that the DB surrogate key is normally a `row-id`
  slot declared here (see warehouse).

### 4.2 Request model (inbound boundary) — get this RIGHT
- Subclass `nst-request-model`.
- **SLOTLESS.** Carry **no per-field typed slots**. All inbound data (including `:row-id`) travels
  as a plist in the inherited `params` slot.
- `params` already defaults to `nil` (do not re-add initforms unless you need one).
- Lesson learned: earlier typed field slots were **dead weight** because `request->dispatch` reads
  only `(params rm)`, never the typed slots. Do not repeat that mistake.

### 4.3 Response model (outbound boundary)
- Subclass **`nst-response-model`** (per adhara). Do not copy Warehouse's own `WarehouseResponseModel`
  still subclasses `nst-boundary-object` directly — that is a **known gap to fix**; do the correct
  thing (`nst-response-model`) for every entity you migrate.

### 4.4 Verbs — implement as CLOS methods specialized on `(eql '<class-symbol>)`
Mirror `nst-bl-warehouse.lisp`:
- `make 'nst-X ctx &rest initargs` — `make-instance` with `:tenant-id` from ctx + filtered
  initargs; run a `?exists` uniqueness `:before` check for any unique field (e.g. GSTIN); persist
  via ORM copy + `with-nst-db-create` + `clsql:update-records-from-instance`; Belnap result
  (`:T`/`:F`/`:U`/`:C`).
- `fetch 'nst-X id ctx` — tenant-scoped single read; return entity or the
  `nst-entity-nil`/`-unknown`/`-contradiction` sentinel (never bare nil).
- `enumerate 'nst-X ctx &key <query filters>` — tenant-scoped list via a filter-clause helper
  (`build-*-filter-clauses` + `select-*-by-filter`), hydrated per row, `bo-knowledge-truth`
  dispatch.
- `!update entity row-id ctx &rest changed-slots`, `delete!`, `?exists` — mirror warehouse.

### 4.5 The ferry in the UI layer
- Actions build a request model (params plist) and call
  `(request->dispatch rm '<verb> '<class> ctx)`. Do **not** call the verb directly from UI.
- Reverse ferry is `domain->response` / `domain->response-list`.
- `ctx` (`domain-ctx`) tenant must come from the **session**, never from client params
  (नियम-1 tenant isolation).
- Do not pass request models or domain entities to render functions; render only response models.

---

## 5. Step-by-step — DAL (`nst-dal-<Entity>.lisp`)

### 5.1 Inventory the current files first
Open the entity's current files (`dod-dal-*`, `nst-dal-*`, and BL/UI) and list:
- the real field set (from the ORM `clsql:def-view-class` or the legacy domain class),
- every existing verb/handler the UI calls,
- the legacy classes/functions those files reference (they must be retired).

### 5.2 Define the domain class
```lisp
(defclass nst-X (nst-domain-entity)
  ((row-id          :initarg :row-id          :accessor row-id)
   ;; UNIQUE IDENTIFIERS
   (uuid ...)   (code ...)
   ;; every other business field slot:
   ;; (slot :initarg :slot :accessor slot)  — one line per field
   ;; TENANT FK where the domain references a company:
   (company :initarg :company :accessor company))
  (:documentation "..."))
```
- Every slot you must carry from the DB gets `:initarg <same-kw> :accessor <name>`.
- Do not redeclare the five inherited audit/tenant slots.

### 5.3 Define the slotless request model
```lisp
(defclass <Entity>RequestModel (nst-request-model)
  ()
  (:documentation "Inbound boundary object. Deliberately SLOTLESS — all inbound
   data (including :row-id) rides in (params rm) as a plist. The ferry MOP-filters
   that plist against whatever initargs nst-X declares."))
```

### 5.4 Define the response model — subclass `nst-response-model`
Typed mirror of the domain fields the UI may need (an **outbound** allowlist source).

### 5.5 Add / keep the ORM view-class
The `clsql:def-view-class` that maps the real DB table (`dod_<table>`), including the tenant and
audit columns as plain slots. This is the persistence schema the verbs actually instantiate.

---

## 6. Step-by-step — BL (`nst-bl-<Entity>.lisp`)

Order the file roughly as warehouse does:
1. `(defparameter *<X>-sort-whitelist* ...)` — the only sort columns `enumerate` may accept; never
   accept a raw column name from outside it.
2. Any keyword→DB-enum string converter needed for enum-valued fields.
3. **`?exists`** method (Belnap) + the **`make :before`** uniqueness guard for unique fields.
4. **`make`** primary method (tenant from ctx → copy `-domaintodb` → `with-nst-db-create` →
   `clsql:update-records-from-instance` → Belnap case dispatch; on `:T` bind the generated row-id).
5. **`fetch`** — tenant-scoped single read returning entity or Belnap sentinel (never nil).
6. **`delete!`** and **`!update`** — mirror warehouse (hydrate from DB, `reinitialize-instance` for
   partial update, write back, Belnap dispatch).
7. **`enumerate`** — filter-clause builder + `select-*-by-filter` + per-row hydration +
   `bo-knowledge-truth` dispatch.
8. **`domain->response`** (explicit per-field copy) and **`domain->response-list`**.
9. **`render-json`** methods (single + list). `render-html` lives in the UI file.
10. **Legacy relocated helpers** — the `select-*` query functions and the two symmetric copy
    helpers `copy<Entity>-domaintodb` / `copy<Entity>-dbtodomain` that the verbs call.

### Known limitation — filtered `enumerate` through the ferry
`extract-domain-initargs` forwards only keys the domain class declares as initargs. Query-filter
keys on `enumerate` (e.g. `:name-like`, `:city`, `:sort-by`) are **not** domain slot initargs, so
the ferry currently drops them (a core-side `strip-reserved-initargs` forward is pending). If you
need a filtered `enumerate` through the ferry today, **flag it** rather than silently losing
filters; otherwise call the `enumerate` verb directly only where the UI has no other choice, and
annotate why in the code.

---

## 7. Step-by-step — UI (`nst-ui-<Entity>.lisp`)

1. Replace the DDD call chain (`AdapterService` → `Process*Request` → `PresenterService` →
   `HTMLView/JSONView`) with an action handler that:
   - builds a `<Entity>RequestModel` with a `params` plist,
   - builds a `domain-ctx` whose tenant comes from the **session** company,
   - calls `(request->dispatch rm '<verb> 'nst-X ctx)`,
   - carries the result out via `domain->response` / `domain->response-list`,
   - renders only the response models via `render-html`/`render-json`.
2. Add the `render-html` methods (per-field allowlist) for the entity's response model.
3. Migrate the registered routes/functions away from the legacy DDD dispatcher; retire the legacy
   `dod-*` handlers only after their routes/functions are migrated.

---

## 8. Registration — `compile.lisp` and `nstores.asd`

- Register the new DAL → BL → UI files **in that order** in `hhub/package/compile.lisp` **and**
  `hhub/nstores.asd`.
- **Delete/retire legacy files from BOTH** (we missed the `.asd` the first time and it still
  referenced removed files).
- Update every other file that referenced the removed legacy files/classes/functions (including
  `nstores.asd` and any function index).

---

## 9. Corrections & gotchas — apply so you don't repeat them

1. Request model = **slotless params bag** (§4.2) — highest-value lesson.
2. `params` must be bound — empty request models now get `params = nil` by default; never assume a
   slot has a value without an `:initform`.
3. Delete old files from BOTH `compile.lisp` AND `nstores.asd`.
4. `extract-domain-initargs` only forwards keys the DOMAIN class declares as initargs — see the
   `enumerate` filter note in §6.
5. Domain→ORM copy functions read domain slots and map to DB columns (e.g. domain `company`
   row-id → DB `tenant-id`). Keep the two copy helpers (`-domaintodb` / `-dbtodomain`) symmetric
   and field-complete.
6. Never call the verb generics with a request model as the entity/class argument — the domain
   verbs reject boundary objects (immunity test exists).
7. Keep `render-*` methods as explicit **per-field allowlists** (security): nothing leaks outbound
   unless that method's accessors read it.

---

## 10. Definition of done

- The entity compiles and loads in the new architecture with **no references to removed legacy
  classes/files in the build path**.
- Every verb + both ferries (`request->dispatch`, `domain->response`) + render methods exist and
  mirror the warehouse template.
- No request model has typed field slots; every response model subclasses `nst-response-model`.
- `compile.lisp` and `nstores.asd` reference only live files, in the right order (DAL → BL → UI).
- No domain entity or request model is passed into a render function or a legacy verb.
- (When asked) `run-all-adhara-tests` / `test-complete-immunity` passes.

---

## 11. Working & confirm protocol

- Migrate **ONE entity** and **ONE concern** at a time.
- Show diffs and **wait for approval between steps**.
- If a design point conflicts with the adhara spec, **ask instead of improvising**.

---

## 12. Per-entity facts to gather before starting entity X

Fill this in for each migration and paste it into the task prompt:

- Entity/domain symbol: `nst-___`
- Source gana directory + old file names (`dod-dal-*` / `nst-dal-*`, BL, UI)
- DB table name + authoritative field set (with types / column→slot names)
- Unique field(s) needing a `make :before` `?exists` guard (e.g. GSTIN, code, phone)
- Sort/filter fields the UI genuinely needs on `enumerate`
- Session tenant source for `ctx`
- Any legacy routes/functions to migrate or retire
