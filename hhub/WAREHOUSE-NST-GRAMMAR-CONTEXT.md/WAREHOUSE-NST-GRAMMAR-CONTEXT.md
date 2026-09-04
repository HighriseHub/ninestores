# NST Paninian Grammar — Warehouse as First Entity (Project Context)

*Authoritative reference for the new architecture. The legacy DDD stack is
deprecated and should NOT be extended. All warehouse logic now follows the
paninian-grammar rules in `nst-bl-adhara.lisp`.*

---

## 1. The Bad News (deprecated legacy stack — do NOT extend)

These files/classes belong to the OLD DDD architecture. Still load-bearing for
existing runs, but **new development must not build on them**:

| Legacy piece | File |
|---|---|
| `dispatch-route` , `register-outbound-route`, `call-context`, `make-adapter`, `make-presenter` | `hhub/core/nst-bl-conflodis.lisp` |
| `WarehouseAdapter`, `WarehouseService.doUpdate/doCreate/doRead`, `copyWarehouse-*` | `hhub/warehouse/dod-bl-wrh.lisp` |
| `WarehouseRequestModel` (a `RequestModel`, not an `nst-request-model`) | `hhub/warehouse/dod-dal-wrh.lisp` |
| Action handlers `com-hhub-transaction-*` | `hhub/warehouse/dod-ui-wrh.lisp` |
| The legacy DOD `Warehouse` business object + `WarehouseDBService` | `hhub/warehouse/dod-*.lisp` |

`dispatch-route` will be **reimplemented later** on top of the new grammar.
Until then the correct entry point is the gana verbs + `domain-ctx`.

Note: `copyWarehouse-dbtodomain` and `copyWarehouse-domaintodb` (in
`dod-bl-wrh.lisp`) are still used BY the NST verbs for DB↔domain field mapping.
They are load-bearing field maps, NOT architectural dependencies — keep them.

---

## 2. The Good News (authoritative NST stack)

The paninian grammar lives in **`hhub/core/nst-bl-adhara.lisp`**. Everything
inherits from one of two disjoint trees:

- **Tree 1 `nst-domain-entity`** — ROOT of all domain entities. Inert
  (Shiva). Actions come from verbs (Shakti).
- **Tree 2 `nst-boundary-object`** — boundary/adapter objects. NEVER inherits
  from Tree 1. NEVER accepted as primary dispatching arg by any verb.

The two trees must never intersect below `standard-object` (guarded by
`test-domain-entity-never-inherits-boundary`).

### Tree 1 — `nst-domain-entity` (core/nst-bl-adhara.lisp)
```lisp
(defclass nst-domain-entity ()
  ((id          :reader id      ; uuid:make-v1-uuid string
    :initform (format nil "~A" (uuid:make-v1-uuid)))
   (tenant-id   :initarg :tenant-id :accessor tenant-id)
   (created-at  :initform (mysql-now) :accessor created-at)
   (updated-at  :initform (mysql-now) :accessor updated-at)
   (deleted-state :initform "N" :accessor deleted-state)))
```
Belnap sentinels (domain facts, belong HERE):
- `nst-entity-nil` (reason "Not Found")
- `nst-entity-unknown` (reason "Unknown — boundary call inconclusive")
- `nst-entity-contradiction` (reason "Conflicting data")
Accessors `entity-reason`. All subclass `nst-domain-entity`.

### Tree 2 — `nst-boundary-object` + `nst-request-model`/`nst-response-model`/`nst-view-model` + Belnap `nst-response-nil/-unknown/-contradiction`, `nst-view-*`

---

## 3. `domain-ctx` — the carrier struct (Key)

```lisp
(defstruct domain-ctx
  (actor nil) (tenant nil) (channel nil) (recipient nil)
  (source nil) (override-reason nil))
```
- **kāraka (semantic-role) coverage 6, carried 5**: actor=कर्ता, tenant=अधिकरण,
  channel=करण, recipient=संप्रदान, source=अपादान. **कर्म (karma, the acted-upon
  object) is deliberately NOT a ctx field** — it is always the verb's own first
  argument (the entity).
- **GUARDRAIL 2**: every verb signature is `(entity ... ctx)`, ctx LAST,
  never the entity, never dispatched on.
- **NIYAM-1 exemption**: recipient/source may be cross-tenant (vendor →
  different tenant). NIYAM-1 still applies to the VERB's OWN entity arg.
- **NO `:U`-tainted references**: if source/recipient resolution returns :U,
  ctx construction must ABORT — never proceed with an uncertain value.
- **tenant extraction**: verbs extract the tenant integer via
  `(slot-value (domain-ctx-tenant ctx) 'row-id)`. So `:tenant` in the
  domain-ctx must be an object whose `row-id` slot holds the tenant-id.

Construction in UI code (vendor context, from `nst-ui-warehouse.lisp`):
```lisp
(make-domain-ctx :actor "VENDOR" :tenant company :channel "ONLINE"
                 :recipient vendor :source "VENDOR")
```
where `company = (get-login-vendor-company)`, `vendor = (get-login-vendor)`.

---

## 4. The प्रत्यय verbs — declared in nst-bl-adhara.lisp

```lisp
(defgeneric make        (entity-class ctx &rest initargs))  ; सृजन
(defgeneric fetch       (entity-class id ctx))              ; स्मरण
(defgeneric enumerate   (entity-class ctx &key))            ; दर्शन
(defgeneric !update     (entity row-id ctx &rest changed-slots)) ; !state
(defgeneric ?exists     (entity-class lookup-value ctx))    ; प्रत्यभिज्ञा
(defgeneric delete!     (entity row-id ctx))                ; लोप (soft)
```
Dispatch style:
- `make/fetch/enumerate/?exists` take entity-class as a SYMBOL (entity doesn't exist yet / not located).
- `!update/delete!` in nst-bl-warehouse take `(entity-class (eql 'nst-whs))` as first param too (class symbol dispatch), plus `row-id` (string), `ctx`, `&rest`.

---

## 5. The Ferry (`request->dispatch`) — लोप, structural

In `nst-bl-adhara.lisp`:
```lisp
(defgeneric request->dispatch (request-model verb-symbol entity-class ctx))
(defmethod  request->dispatch ((rm nst-request-model) (verb-symbol (eql '!update))
                               (entity-class symbol) (ctx domain-ctx))
  (apply #'!update entity-class (rm-row-id rm) ctx (extract-domain-initargs rm entity-class)))
```
- The `nst-request-model` DIES here — its slots are read ONCE to build initargs,
  the request-model itself is never returned/stored/passed to verbs.
- `rm-row-id` = `(getf (params rm) :row-id)`.
- `extract-domain-initargs` filters client params against the entity class's own
  declared initargs via MOP (SB-MOP), MINUS `*reserved-initargs*`:
  `(:tenant-id :id :created-at :updated-at :deleted-state)` — these five are
  NEVER settable from client params. tenant-id comes only from ctx.
- `gana-package-for` maps verb → गण package via `*verb->gana-package*`.
  Unregistered verb => clear error (GUARDRAIL 3).

---

## 6. नियम (rules) anchored on Tree 1

```lisp
(defmethod check-niyam :before ((entity nst-domain-entity) (ctx domain-ctx))
  ;; नियम-1 tenant isolation
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (assert (equal (tenant-id entity) tenant-id) nil "नियम १ ..."))
  ;; नियम-2 not-deleted guard
  (assert (not (equal (deleted-state entity) "Y")) nil "नियम २ ..."))
(defmethod emit-audit :after ((entity nst-domain-entity) (ctx domain-ctx)) ...)
```

---

## 7. `nst-whs` — the first grammar-based entity

Slots/initargs (from `hhub/warehouse/nst-dal-warehouse.lisp`). All declared
`:initarg` so `extract-domain-initargs` and `reinitialize-instance` work.

- row-id `:row-id`
- warehouse-uuid `:warehouse-uuid`, warehouse-code `:warehouse-code`
- wname, waddr1, waddr2, wpin, wcity, wstate, wcountry, wmanager, wphone,
  waltphone, wemail
- activeflag `:activeflag`
- ownership-type, owner-entity-type, owner-entity-id, vendor, operator-entity-type,
  operator-entity-id, legal-entity-type
- warehouse-gstin, gstin-status, legal-name, is-primary-location, state-code,
  registration-type, pan-number
- warehouse-type, warehouse-purpose
- default-transporter-id, default-transporter-name, eway-bill-enabled
- latitude, longitude
- valuation-method, hsn-wise-stock
- company `:company` (tenant object)

Inherited from `nst-domain-entity`: id, tenant-id, created-at, updated-at,
deleted-state.

`WarehouseResponseModel` (`nst-boundary-object` subclass in same file) mirrors
these slots as the outbound boundary shape.

---

## 8. `nst-whs` gana verbs (nst-bl-warehouse.lisp)

- **`?exists 'nst-whs gstin ctx`** — GSTIN uniqueness; Belnap :F means
  available (create allowed), NOT :f (case-insensitive bug was fixed).
- **`make :before`** — GSTIN uniqueness defense-in-depth BEFORE insert; DB
  UNIQUE constraint still the real guard for the TOCTOU race.
- **`make`** — creates `nst-whs`, generates uuid/code, `copywarehouse-domaintodb`,
  `with-nst-db-create`, binds generated row-id, returns entity. Belnap paths
  for :T/:F/:U/:C.
- **`fetch`** — returns entity or `nst-entity-nil`, never bare nil.
- **`!update`** (the key one):
  ```lisp
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (dbobj (select-warehouse-by-id (parse-integer row-id) tenant-id)))
    (if (null dbobj) (nst-entity-nil ...)
      (let ((entity (make-instance 'nst-whs :tenant-id tenant-id)))
        (copyWarehouse-dbtodomain dbobj entity)          ; hydrate current
        (apply #'reinitialize-instance entity update-args) ; CLOS partial update
        (copyWarehouse-domaintodb entity dbobj)
        (with-nst-db-update (:source "nst-whs/!update")
          (clsql:update-records-from-instance dbobj) dbobj)
        ...)))  ; :T => entity, :U => error
  ```
- **`delete!`** — soft-delete, sets deleted-state "Y".

**HANDLER CALL CONTRACT**: `!update` reads `(domain-ctx-tenant ctx)` and
`(parse-integer row-id)`. So the UI handler must supply a real `domain-ctx`
(not a conflodis `call-context`) and a non-blank string `row-id`.

---

## 9. UI layer conventions

- **`nst-ui-warehouse.lisp`** is the NST UI host. Holds vendor-facing actions:
  - `com-hhub-transaction-readall-warehouse`, `nst-controller-search-my-warehouse-action`,
    `com-nst-transaction-vendor-warehouse-details-page` (edit page), `create-model-for-addeditwarehouse`.
  - renders `WarehouseResponseModel` via `render-html` (cl-who, HTML-escaping).
- **`dod-ui-wrh.lisp`** currently holds `com-hhub-transaction-*-warehouse-action`
  handlers that still route through legacy `dispatch-route`. These are the
  ones being migrated to the grammar. The update handler should EVENTUALLY
  live in `nst-ui-warehouse.lisp` (or a new nst UI file), not in `dod-ui-wrh.lisp`.
- **Edit page flow** (`create-model-for-addeditwarehouse`):
  `(if id (fetch 'nst-whs id ctx))` — id = `(hunchentoot:parameter "id")` from
  URL `?id=<row>`. If id present => action=updatewarehouseaction, else =>
  action=createwarehouseaction (substituted into `%Warehouse Action%` in the
  template `hhub/warehouse/templates/warehousedetailspage.html`).
- **Session context split** (IMPORTANT):
  - `with-opr-session-check` + `get-login-company` = operator/superadmin session
    (company = `:login-user-company`).
  - `with-vend-session-check` + `get-login-vendor-company` = vendor session.
  - The NST readall/details/search handlers use the VENDOR session. Any gana
    update handler must match whichever session actually serves the POST.

---

## 10. Output rendering

- `domain->response` (entity→Tree 2 response) on single entity.
- `domain->response-list` (collection).
- `render-json` (single `WarehouseResponseModel`) → alist; list method applies
  `json:encode-json-to-string`. SECURITY: field allowlist per method.
- `render-html` lives in `nst-ui-warehouse.lisp`.

---

## 11. HTTP form fields exposed by warehousedetailspage.html

POST fields (name → initarg key unless noted):
```
wname, waddr1, waddr2, wpin, wcity, wstate, wcountry, wmanager,
wphone, waltphone, wemail, activeflag,
ownershiptype→:ownership-type, ownerentitytype→:owner-entity-type,
ownerentityid→:owner-entity-id, operatorentitytype→:operator-entity-type,
operatorentityid→:operator-entity-id, legalentitytype→:legal-entity-type,
warehousegstin→:warehouse-gstin, gstinstatus→:gstin-status,
legalname→:legal-name, pannumber→:pan-number, statecode→:state-code,
registrationtype→:registration-type, isprimarylocation→:is-primary-location,
warehousetype→:warehouse-type, warehousepurpose→:warehouse-purpose,
defaulttransporterid→:default-transporter-id,
defaulttransportername→:default-transporter-name,
ewaybillenabled→:eway-bill-enabled, valuationmethod→:valuation-method,
hsnwisestock→:hsn-wise-stock, latitude, longitude
```
`owner-entity-id`/`is-primary-location`/`eway-bill-enabled`/`hsn-wise-stock`
use the `(parse-integer (or (param) "0"/"1"))` guarded pattern.

**GAP**: the template has NO hidden `id` input. The row-id must survive the
POST — currently relying on the `?id=` query param which is fragile. Recommend
adding `<input type="hidden" name="id" value="...">` to the template.

---

## 12. Current state of the update handler (as of last session)

`com-hhub-transaction-update-warehouse-action` in `dod-ui-wrh.lisp` was
rewritten to:
1. read `id` from `(hunchentoot:parameter "id")`
2. build `domain-ctx` `(make-domain-ctx :actor "SUPERADMIN" :tenant company :channel "ONLINE" :recipient vendor :source "VENDOR")`
   with `company = (get-login-company)`, `vendor = (get-login-vendor)` — NOTE:
   this uses the OPR/Superadmin session, but the details page is vendor-session;
   verify which actually serves the POST.
3. gather all form fields into `update-args` (a full plist, including
   `:company` and `:vendor` at the end).
4. guard blank `id` → JSON error.
5. `(apply #'!update 'nst-whs id ctx update-args)`.
6. if `nst-entity-nil` → JSON error; else `domain->response` → `render-json` →
   `json:encode-json-to-string`.

**OPEN ITEMS / decisions still pending**:
- Should the handler eventually move to `nst-ui-warehouse.lisp` and use the
  `request->dispatch` ferry (request-model → verb) rather than calling
  `!update` directly? Per the grammar's लोप principle, the ferry is the
  sanctioned crossing; a direct verb call in a UI `let*` bypasses it. But if
  the ferry's HTTP wiring isn't ready yet, direct `!update` is acceptable
  transitional code.
- Blank checkbox/select fields: current defaults ((or param "0"/"1")) mean
  an empty field overwrites to 0/"1". If "blank stays unchanged" is required,
  keys must be dropped from `update-args` when param is nil.
- The verb-गण routing: `!update` dispatch goes through
  `gana-package-for`; `!update` is registered for the inventory/भण्डारगण. The
  handler calls it via the eql-specializer method directly, so gana lookup is
  not exercised in this path.

---

## 13. Key session/company accessors

| Accessor | File | Returns |
|---|---|---|
| `get-login-company` | account/dod-ui-cmp.lisp | `:login-user-company` (opr/superadmin) |
| `get-login-vendor-company` | account/dod-ui-cmp.lisp | `:login-vendor-company` (vendor session) |
| `get-login-vendor` | vendor/dod-ui-ven.lisp | `:login-vendor` |
| `get-login-vendor-id` | vendor/dod-ui-ven.lisp | `(row-id vendor)` |
| `get-login-customer-company` | account/dod-ui-cmp.lisp | customer company |

Company objects have a `row-id` slot (used as tenant-id via
`(slot-value company 'row-id)`).

---

## 14. File map (canonical NST warehouse)

| Concern | File |
|---|---|
| Paninian grammar root (trees, domain-ctx, verbs, ferry, नियम) | `hhub/core/nst-bl-adhara.lisp` |
| Warehouse domain class + ResponseModel | `hhub/warehouse/nst-dal-warehouse.lisp` |
| Warehouse gana verbs (make/fetch/enumerate/!update/delete!/?exists) + render-json/domain->response | `hhub/warehouse/nst-bl-warehouse.lisp` |
| Warehouse NST **internal** DB/domain field maps + legacy DOD business logic | `hhub/warehouse/dod-bl-wrh.lisp` (field maps load-bearing) |
| Warehouse NST UI actions + render-html | `hhub/warehouse/nst-ui-warehouse.lisp` |
| Warehouse legacy UI action handlers (being migrated) | `hhub/warehouse/dod-ui-wrh.lisp` |
| Warehouse edit form template | `hhub/warehouse/templates/warehousedetailspage.html` |
| Warehouse grammar doc | `hhub/warehouse/warehouse-grammar.md` |
| Warehouse tests | `hhub/test/nst-tst-warehouse.lisp` |
