# customeronboarding — the company-admin API (Panini routes), DESIGN

**Read this when:** you are adding a company-administrator capability (approve/reject a vendor,
a product, a customer; categories; profile), wondering **where the admin portal should call**,
or asking *"which endpoint does C1–C4 ride on?"*

> **Status 2026-10-23: §10 steps 1–2 DONE (migration applied, domain field plumbed); §5 endpoints NOT built.**
> The customer half (C1–C4) is the first consumer; vendors/products are phase 2.
> Companion: `customeronboarding-EMAILS.md` (C1–C4), `vendoronboarding-EMAILS.md` (E1–E5),
> `knowledge/nst-bl-apidefs2-CONTEXT.md` (transport, statuses, traps), `knowledge/nst-bl-conflodis2-DESIGN.md`.

---

## 1. Scope and the one sentence

The company administrator holds **six write powers** — approve/reject vendor, approve/reject
product, approve/reject customer — plus categories and the company profile. Today every one is a
legacy page handler that calls a BL function directly (`sysuser/dod-ui-cad.lisp:31-70` vendor,
`:435-458` product); **not one is an API endpoint**. This design expresses them as
`/hhub/api/v1/admin/…` bindings onto Panini action verbs, so the portal, curl and any future
front-end share **one** implementation of each approval law.

## 2. What the artifacts already give us (verified 2026-10-22)

| Fact | Where |
|---|---|
| **Zero** `/admin/*` endpoints bound; 35 unique v1 paths exist, none admin | `grep ':path "/hhub/api/v1/admin'` → nothing |
| Admin session already authenticates: `conflodis2-login-company` falls through to `:login-user-company` | `core/nst-bl-conflodis2.lisp` §3 |
| `api-authenticate` returns the **company object**, not T — the tenant reaches the domain before the verb | `core/nst-bl-apidefs2.lisp:454` |
| `api-client-error` → 400; **there is no 403** | `:672` `api-status-for-condition` |
| `required-roles` / `feature-flags` are **carried, never enforced** | `nst-bl-vndapi.lisp` header; apidefs2 §9 |
| `nst-customer` already has all six Tier-1 verbs | `customer/nst-bl-Customer.lisp:544-750` |
| Vendor/product approval queries exist | `get-vendors-for-approval` (`vendor/dod-bl-ven.lisp:213`), `get-products-for-approval` (`products/dod-bl-prd.lisp:37`) |

**Consequence:** auth needs no new work for the `:session` scope. Authorization needs *all* of it
— see §8.

## 3. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | Namespace `/hhub/api/v1/admin/{vendors,products,customers,categories,profile}` | Already specified by `core/nstoresapi.html:113-122`; only `/admin/profile` and `/admin/account/*` exist there today. Do not invent a second shape. |
| D2 | One action verb per capability, `route-adm-<entity>-<action>`, bound 1:1 | Transport adds no business routes (conflodis2 invariant). |
| D3 | `:inject-company` is **not** used on any admin route | The `nst-*` verbs take अधिकरण from `domain-ctx`; injection exists only for legacy entities that read a `company` initarg (warehouse). |
| D4 | `approved-by` comes from `(domain-ctx-actor ctx)`, never from the body | The actor is the credential. A body-supplied approver is a forged audit trail. |
| D5 | Reject **requires** `reason`; missing/blank → 400 `api-client-error` | C4/E4 send the reason to the customer; "Not given" is the fallback for legacy rows, not for a new request. |
| D6 | Only `N/PENDING` is approvable; any other transition → 409 | The state machine is the law, not the UI. 409 is the existing contradiction path (`nst-response-contradiction`). |
| D7 | The **law** (flags + email) lives in `approve-<entity>` / `reject-<entity>` in the domain file; the route verb is one line | Same split as `doupdate` / `reject-vendor`; guarantees the UI, REPL and API all notify. |
| D8 | The admin portal calls these endpoints with `fetch()`, not the BL functions | Otherwise the endpoint is decorative and the "two implementations" problem returns. |
| D9 | Session scope only in phase 1 | Bearer keys do not exist yet (`api-authenticate` `:session` is the only arm). |

## 4. कारक for an admin action

| कारक | Value | Source |
|---|---|---|
| कर्ता (actor) | the CompAdmin `DOD_USERS` row | `:login-user` |
| अधिकरण (tenant) | the login company | session only (नियम-1) |
| कर्म (object) | `{id}` → `row-id` of the row being approved | path param |
| संप्रदान (recipient) | the customer/vendor email | the row, never the body |

Nothing else is trusted: `:row-id` is overwritten by the path, `:tenant-id` is stripped by
`extract-domain-initargs`, and `:approved-by` is overwritten by the verb.

## 5. Endpoint catalogue

Phase 1 is everything a customer approval needs. Phases 2–3 complete the admin surface.

| # | Capability | Method · Path | Action verb | Tier-1 | Phase |
|---|---|---|---|---|---|
| 1 | Pending customers | `GET /admin/customers/pending` | `route-adm-customer-pending` | select + hydrate | **1** |
| 2 | Approve customer | `PUT /admin/customers/{id}/approve` | `route-adm-customer-approve` | `!update ∘ nst-customer` | **1** |
| 3 | Reject customer | `PUT /admin/customers/{id}/reject` | `route-adm-customer-reject` | `!update ∘ nst-customer` | **1** |
| 4 | Pending vendors | `GET /admin/vendors/pending` | `route-adm-vendor-pending` | `get-vendors-for-approval` | 2 |
| 5 | Approve vendor | `PUT /admin/vendors/{id}/approve` | `route-adm-vendor-approve` | `!update ∘ nst-vnd` | 2 |
| 6 | Reject vendor | `PUT /admin/vendors/{id}/reject` | `route-adm-vendor-reject` | `!update ∘ nst-vnd` | 2 |
| 7 | Pending products | `GET /admin/products/pending` | `route-adm-product-pending` | `get-products-for-approval` | 2 |
| 8 | Approve product | `PUT /admin/products/{id}/approve` | `route-adm-product-approve` | `!update ∘ nst-prd` | 2 |
| 9 | Reject product | `PUT /admin/products/{id}/reject` | `route-adm-product-reject` | `!update ∘ nst-prd` | 2 |
| 10 | Categories | `GET/POST /admin/categories`, `DELETE /{id}` | `route-adm-category-*` | `nst-prdcatg` verbs | 3 |
| 11 | Company profile | `GET/PUT /admin/profile` | `route-adm-profile-*` | `!update ∘ nst-cmp` | 3 |
| 12 | Approval counts | `GET /admin/overview` | `route-adm-overview` | three counts | 3 |

Row 1–3 are the ones C1–C4 depend on. **Do not build 4–12 before 1–3 are green.**

## 5.1 Port matrix — every capability in the three legacy files

`dod-dal-usr.lisp` is 100 lines and holds **one** class (`dod-users`); `dod-bl-cad.lisp` is 36 lines
and holds **three** functions; the other ~600 lines are `dod-ui-cad.lisp`. That is the whole
"company admin" today. Each row below is a capability, where it lives now, and what Panini needs.

| Capability | Legacy source | Panini artifact | Exists? | Phase |
|---|---|---|---|---|
| Login | `dod-cad-login` `dod-ui-cad:374` | — (see §5.2) | — | out |
| Logout | `com-hhub-transaction-cad-logout:403` | — | — | out |
| Home counts + product tiles | `create-model-for-compadminhome:316-349` | `route-adm-overview` | ✗ | 3 |
| Admin profile read | `create-model-for-cadprofile:170-195` | `nst-user` `fetch` | **no `nst-user`** | 3 |
| Admin profile update | `create-model-for-cadupdatedetailsaction:242-259` → `update-user` | `nst-user` `!update` | **no `nst-user`** | 3 |
| Change password | `modal.account-admin-change-pin:198` — **empty body** | `nst-user` password policy | not built | 4 |
| Account external URL | `create-model-for-publishaccountexturl:149-168` → `generate-account-ext-url`/`update-company` | `nst-cmp` `!update` | **no `nst-cmp`** | 3 |
| Category list | `create-model-for-productcategoriespage:74-100` | `nst-prd-catg` `enumerate` | class exists (`products/dod-dal-prd.lisp:784`) | 2 |
| Category add | `com-hhub-transaction-prodcatg-add-action:124-136` → `add-new-node-prdcatg` | `nst-prd-catg` `make` | **no verbs** | 2 |
| Category delete | `dod-controller-delete-product-category:140-145` → `delete-prd-catg` | `nst-prd-catg` `delete!` | **no verbs** | 2 |
| Product pending list | `dod-controller-products-approval-page:460-472` | `route-adm-product-pending` | ✗ | 2 |
| Product approve | `create-model-for-cadproductapproveaction:442-457` → `approve-product` (`dod-bl-cad:21`) | `!update ∘ nst-prd` | verbs exist | 2 |
| Product reject | `create-model-for-cadproductrejectaction:422-438` → `reject-product` (`dod-bl-cad:29`) | `!update ∘ nst-prd` | verbs exist, **no reason column** | 2 |
| Vendor pending list | `dod-controller-vendor-approval-page:474-486` | `route-adm-vendor-pending` | ✗ | 2 |
| Vendor approve | `com-hhub-transaction-vendor-approve-action:45` → `doupdate` | `!update ∘ nst-vnd` | verbs exist | 2 |
| Vendor reject | `com-hhub-transaction-vendor-reject-action:31` → `reject-vendor` | `!update ∘ nst-vnd` | verbs exist | 2 |
| **Customer pending/approve/reject** | — | `nst-customer` `!update` | verbs exist | **1** |

**What is genuinely new:** only `nst-user` (the `dod-users` twin) and `nst-cmp` (the `dod-company`
twin) as domain classes; `nst-prd-catg` needs verbs, not a class. Everything in phase 1–2 rides
domains that already exist.

## 5.2 What is NOT ported: login and logout

`dod-cad-login` reads `dod-users` by phone with **no tenant scope and no role check**, then
`set-user-session-params`. It is the credential issuer, not a business capability, and the API's
`:session` scope *consumes* it — it does not replace it. Porting it would mean inventing token
issuance, which `api-authenticate` explicitly leaves for later (`apidefs2` §9.7). Phase 1: admin
signs in on the HTML form, then calls the API with the cookie. Same as the §11 recipe.

## 5.3 Traps in the legacy code — do not carry these over

1. **`approve-product` / `reject-product` overwrite the product's `description`** with the admin's
   note (`dod-bl-cad:21-35`). Approving via `approve-product id description company` silently
   replaces the vendor's own description; reject does the same and there is **no rejection column**
   on `dod-prd-master`. Do not port this shape — a decision note is not the product description.
2. **`change-password` is an empty function** (`modal.account-admin-change-pin`, `:198`). The modal
   opens, the form probably posts nowhere. Do not "port" it as if it worked.
3. **`dod-cad-login` has no tenant scope** — see §5.2. Two admins on different tenants with the same
   phone collide on `row-id` order.
4. **The home page counts only products** (`:322`) — vendors and customers have queues too; the
   `route-adm-overview` design must count all three, or it repeats the blind spot C2 exists to fix.
5. **`authorize` is a UI macro** (`with-cad-session-check`), not a policy. Moving to API does not
   make it safer — see §8.

## 6. The three phase-1 verbs

Signature is fixed: `(route-<action> request ctx)`, returns a domain object, a list, or a Belnap
sentinel. The dispatcher alone runs `domain->response` + render.

```lisp
;; pending — the list must be nst-customer, not raw dod-cust-profile rows:
;; domain->response has a method for nst-customer only.
(defun route-adm-customer-pending (request ctx)
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (mapcar (lambda (dbobj)
              (let ((e (make-instance 'nst-customer :tenant-id tenant-id)))
                (nst-copy-customer-dbtodomain dbobj e)
                e))
            (select-pending-customers-for-tenant tenant-id))))
```

```lisp
;; approve — the law is in the domain file (D7); the verb only supplies the actor
(defun route-adm-customer-approve (request ctx)
  (approve-customer (getf (params request) :row-id) ctx))

;; reject — reason is transport-validated, everything else is domain law
(defun route-adm-customer-reject (request ctx)
  (let ((reason (string-trim " " (or (getf (params request) :reason) ""))))
    (when (zerop (length reason))
      (api-client-error "reject requires a non-empty reason"))
    (reject-customer (getf (params request) :row-id) ctx reason)))
```

Bindings:

```lisp
(register-action-route 'route-adm-customer-approve
  :request-class 'nst-request-model :output-type :json
  :description "Approve a pending customer of the session tenant."
  :required-roles '(compadmin)   ;; carried, not enforced — §8
  :audit-level :full :tags '(admin customer api v1))

(register-api-route 'route-adm-customer-approve
  :method :put :path "/hhub/api/v1/admin/customers/{id}/approve"
  :path-params '(("id" . :row-id))
  :success-status 200 :auth-scope :session
  :description "Approve a pending customer: sets the login gate and sends C3. 404 outside the tenant, 409 unless the row is N/PENDING.")
```

## 7. The domain law (phase 1)

New in `hhub/customer/nst-bl-Customer.lisp`, beside the verbs, both returning what `!update`
returned (entity or sentinel):

```lisp
(defun approve-customer (row-id ctx)
  ;; 1. !update 'nst-customer with Y/APPROVED/actor-phone
  ;; 2. on an entity: send-customer-approved-email (C3) — handler-case, never fails the write
  ;; 3. return the entity)
(defun reject-customer (row-id ctx reason)
  ;; 1. !update with N/REJECTED/actor-phone/:rejection-reason reason
  ;; 2. on an entity: send-customer-rejected-email (C4)
  ;; 3. return the entity)
```

The transition guard (D6) is a `:before` on these two, reading the current row tenant-scoped:
`N/PENDING` proceeds; anything else returns `(make-instance 'nst-response-contradiction …)` so the
API answers **409** with a reason, and the portal shows the same sentence.

**Known trap:** `!update` hydrates then re-copies every field in `*nst-customer-business-fields*`.
`rejection-reason` was added to that list (2026-10-22) with `:initform nil` on both classes — without
the initform a create would fault on an unbound slot (apidefs2 §8.2).

## 8. Authorization — the gap this design does not close

`required-roles` is metadata. **Any authenticated session — a vendor's or a buyer's — can call an
admin endpoint today.** For a read that is bad; for approve/reject it is a privilege escalation.

Before these endpoints are reachable from anything but a trusted operator:

1. **Add `api-forbidden` → 403** in `api-status-for-condition` (`apidefs2:672`); the taxonomy has
   400/401/404/500 and no deny code.
2. **Resolve the role per request:** actor's role name from `(domain-ctx-actor ctx)` vs the route's
   `required-roles`, checked in the `*action-route-transaction-function*` seam (conflodis2 §5) —
   the one place both transports pass through.
3. **Refuse a vendor/buyer session on `/admin/*` outright**, not merely missing-role.

Recorded, not built. Phase 1 is exercised from the CompAdmin session only.

## 9. File layout and load order

| File | Change | Why here |
|---|---|---|
| `customer/nst-bl-cusadmapi.lisp` | **new** — 3 verbs + registrations + bindings | `customer/nst-bl-custapi.lisp` loads at `nstores.asd:82`, **before** conflodis2 (`:85`); it cannot call `register-action-route`. New file loads after `customer/nst-bl-Customer` (`:107`). |
| `vendor/nst-bl-vndapi.lisp` | extend (phase 2) | Already loads after conflodis2 + `nst-bl-vnd`. |
| `products/nst-bl-prdapi.lisp` | extend (phase 2) | Same. |
| `customer/nst-bl-Customer.lisp` | `approve-customer`, `reject-customer`, `select-pending-customers-for-tenant` | Domain file, beside the verbs. |
| `nstores.asd`, `package/compile.lisp` | one entry each, after `customer/nst-bl-Customer` | Serial load; comment the dependency. |
| `sysuser/dod-ui-cad.lisp` | page buttons → `fetch()`; sidebar link fixed | The currently mislabeled "Customer Approvals" points at `dasproductapprovals` (`:25`). |

## 10. Build order (one step per session, confirmed before starting)

1. Migration + backfill — **DONE 2026-10-22** (`22102026-customer-approval`, applied).
2. Domain field `rejection-reason` on `dod-cust-profile`, `nst-customer`, response model — **DONE**.
3. `select-pending-customers-for-tenant` + `approve-customer` + `reject-customer` + the PENDING guard. **← next**
4. `nst-bl-cusadmapi.lisp` — 3 verbs, 3 action routes, 3 API bindings.
5. asd + compile.lisp wiring; `(asdf:load-system :nstores)`; `(list-api-routes)` shows the three.
6. curl proof: pending → approve → 200; second approve → 409; reject without reason → 400.
7. Admin page on the endpoints; sidebar fix.
8. C1/C2 at the CUS registration call site; C3/C4 inside the two domain functions.
9. Login gate + a "pending" sentence on the customer login page.

## 11. Test recipe (after step 5)

```bash
# CompAdmin session (form login, not the API)
curl -sS -D /tmp/h.txt -c /tmp/ns.jar -X POST http://hunchentoot.local/hhub/hhubcadloginaction \
  -d 'email=<admin email>&password=<password>'

curl -sS -b /tmp/ns.jar http://hunchentoot.local/hhub/api/v1/admin/customers/pending
curl -sS -b /tmp/ns.jar -X PUT http://hunchentoot.local/hhub/api/v1/admin/customers/<id>/approve
curl -sS -b /tmp/ns.jar -X PUT -H 'Content-Type: application/json' \
  -d '{"reason":"GSTIN does not match the registered business"}' \
  http://hunchentoot.local/hhub/api/v1/admin/customers/<id>/reject
```

Expected: 200 / 200 / 409 on second approve / 400 on missing reason / 401 without a session.
Logs: `~/hhublogs/ninestores-apilogs.log` for 500s and backtraces.
