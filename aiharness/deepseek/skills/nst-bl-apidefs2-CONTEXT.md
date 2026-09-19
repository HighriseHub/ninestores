# nst-bl-apidefs2 — API layer + warehouse action routes · CONTEXT

**Purpose of this file.** Working context for anyone (human or agent) continuing the
JSON API work on HHub. It records what exists, why it is shaped that way, what was
verified by running it, and what is deliberately unfinished. Read this before
touching `nst-bl-apidefs2.lisp`, `nst-bl-whsapi.lisp`, or the session/enforcement
code — most of the sharp edges below already cost hours once.

**Date of the work recorded here:** 2026-09-12. Everything marked *verified* was
exercised against the running server that day; everything else is *reasoned, not
yet run*.

---

## 1. Where things live

| File | Role |
|---|---|
| `hhub/core/nst-bl-adhara.lisp` | **CORE.** `nst-domain-entity`, `domain-ctx` (कारक passenger), `request->dispatch` (the Tier-1 ferry), `domain->response`, `render-json`/`render-html` generics, domain sentinels |
| `hhub/core/nst-bl-conflodis2.lisp` | Tier-2 route-action dispatcher: `action-route`, `register-action-route`, `dispatch-route2`, `make-action-domain-ctx`, the ring-4 render hop |
| `hhub/core/nst-bl-apidefs2.lisp` | **NEW (today).** Ring-4 JSON API boundary: `api-route`, `register-api-route`, one `/hhub/api/v1/` handler, JSON↔params, status mapping, API error log |
| `hhub/warehouse/nst-bl-whsapi.lisp` | **NEW (today).** Warehouse action verbs (`route-warehouse-*`) + action-route registrations + API bindings |
| `hhub/warehouse/nst-bl-warehouse.lisp` | Warehouse domain verbs: `?exists`, `make`, `fetch`, `!update`, `delete!`, `enumerate`, `domain->response`, `copyWarehouse-*` |
| `hhub/warehouse/nst-dal-warehouse.lisp` | `nst-whs` domain class (initforms mirror the DDL), `WarehouseRequestModel`, `WarehouseResponseModel` |
| `hhub/core/dod-ui-utl.lisp` | `logIamhere`, `with-hhub-transaction`, `response-id-string`, `hhub-websession-live-p`, `hhub-websession-start`, `hhub-remove-other-websession` |
| `hhub/core/nst-mult-logic.lisp` | `with-db-call`, `with-nst-db-create/update/delete`, `bind-generated-row-id`, `knowledge-join` |
| `hhub/core/nst-bl-beltrusys.lisp` | Belnap: `bo-knowledge`, `make-bo-knowledge`, `bo-merge`, truth accessors |
| `hhub/sysuser/dod-ui-sys.lisp` | `hunchentoot:*dispatch-table*` — the `/hhub/api/v1/` dispatcher is the FIRST entry |
| `hhub/core/dod-ini-sys.lisp` | `start-das` (acceptor on port **4244**), `*HHUBMAXVENDORLOGINS*` = 2, log file paths |
| `installation/upgrades/nst-dbu-warehouse.lisp` | **Schema source of truth for `DOD_WAREHOUSE`** (the older `installation/hhubplatform.sql` is a stale shape — no GSTIN column) |

Build wiring: `nstores.asd` **and** `package/compile.lisp` both list
`core/nst-bl-conflodis2`, `core/nst-bl-apidefs2`, `warehouse/nst-bl-whsapi`.
Ordering matters (`:serial t`): adhara → conflodis2 → apidefs2 → … → warehouse → whsapi → ui.

Runtime: `startup/load.lisp` → `(ql:quickload :nstores)` → `(start-das)`, listening on
**127.0.0.1:4244**; nginx fronts it (`upstream hunchentoot`).

---

## 2. Architecture in one screen

```
HTTP  PUT /hhub/api/v1/warehouse/47        UI  /hhub/vupdatewarehouseaction
        │                                       │
        ▼                                       │
com-hhub-api-dispatch (apidefs2)                │
  find-api-route  → api-route record            │
  api-authenticate → SESSION COMPANY (अधिकरण)   │
  api-params-for-request → params plist         │
        │                                       │
        └──────────────► dispatch-route2 ◄──────┘
                            │  (conflodis2, Tier 2)
                            ▼
                   route-warehouse-update        one ACTION, entity-agnostic
                            │
                            ▼
              request->dispatch (Tier 1 ferry, adhara)
                            │
                            ▼
                     !update ∘ nst-whs           the धातु verb on one कर्म
                            │
                    ┌───────┴────────┐
              domain->response   render-json
                    (reverse ferry, ring 4)
```

**Invariant:** the API adds *transport*, never business routes. An endpoint is a
binding from `(method, path)` to an **already-registered** `route-*` verb, so an
external call and the internal website share one कारक build, one ferry, one set of
domain laws. `register-api-route` refuses to bind a path to an unregistered verb.

**Invariant (नियम-1):** the tenant comes from the credential only.
`extract-domain-initargs` strips `:tenant-id` from payloads; `getf` precedence in
`api-params-for-request` makes a body-supplied `row-id`/`company` unable to override
the URL or the session.

---

## 3. Endpoints currently bound

All under `/hhub/api/v1` (the `/hhub` prefix is part of the path — see §7).

| Method | Path | → action route | Verb chain | Notable |
|---|---|---|---|---|
| PUT | `/warehouse/{id}` | `route-warehouse-update` | `!update ∘ nst-whs` | `:inject-company t`; **verified 200** |
| POST | `/warehouse` | `route-warehouse-create` | `make ∘ nst-whs` | `:inject-company t`, success 201; pre-check may return `:C` |
| GET | `/warehouse/{id}` | `route-warehouse-fetch` | `fetch ∘ nst-whs` | 404 on miss / other tenant |
| DELETE | `/warehouse/{id}` | `route-warehouse-delete` | `delete! ∘ nst-whs` | soft delete; ack body |
| GET | `/warehouse` | `route-warehouse-list` | `enumerate ∘ nst-whs` (direct) | query-string filters |

Action routes also registered without API bindings: the four above plus
`route-warehouse-*` (all five) and `route-ping` (smoke test in conflodis2).
`(list-api-routes)` and `(list-action-routes)` are the diagnostics.

**Body keys are `nst-whs` initarg names** (`wname`, `warehouse-gstin`, `state-code`,
`is-primary-location`, …), not DB column names. camelCase is accepted
(`warehouseGstin` → `:WAREHOUSE-GSTIN`).

---

## 4. Status mapping (apidefs2 §5)

| Situation | Status | Body |
|---|---|---|
| success | `api-route-success-status` (200; 201 for create) | rendered response |
| empty **list** result | 200 | `[]` (an empty list is success, not 404) |
| `nst-response-nil` (or `null` response) | 404 | `{"error":"not_found","reason":…}` |
| `nst-response-unknown` | 503 | `{"error":"unknown",…}` |
| `nst-response-contradiction` | **409** | `{"error":"conflict","reason":…}` |
| unauthenticated | 401 | `{"error":"unauthenticated",…}` |
| bad JSON / bad path params | 400 | `{"error":"invalid_request",…}` |
| unknown path | 404 | `{"error":"no_such_endpoint",…}` |
| anything else | 500 | `{"error":"internal_error","message":"the request could not be completed"}` |

The real condition for a 500 goes to the log, never to the client (OWASP improper
error handling). **The 500-vs-4xx taxonomy is unfinished** — see §9.

---

## 5. Decisions made today (with the reason)

1. **URL convention:** `METHOD /hhub/api/v1/{domain}/{resource}[/{id}][/{sub-action}]`.
   Sub-action segments are reserved for genuine verbs (approve/reject/status), not
   updates — hence `PUT /warehouse/{id}`, not `POST …/{id}/update`.
2. **Path id = numeric DB `row-id`.** Every domain verb addresses rows that way
   (`rm-row-id` → `parse-integer`). Authorization is per-object: the verb re-selects
   with `tenant-id` from the session, so another tenant's id yields 404, never data
   (OWASP API1:2023 BOLA). `warehouse-uuid` stays available if opaque ids are wanted.
3. **Auth = the existing session cookie** (`:session` scope). `api-authenticate`
   returns the **company object**, and `:inject-company` routes inject it into params
   as `:company`. Reason: `nst-whs` keeps a legacy `COMPANY` slot beside the
   inherited `TENANT-ID`, and `copyWarehouse-domaintodb` derives the DB row's tenant
   from it — the web form passes `:company` explicitly, a JSON body must never carry
   it. Bearer keys later = change only the auth scope.
4. **All ids are JSON strings** (`response-id-string`, nil → `null`). One convention
   for every entity; ids are opaque.
5. **Full record exposure kept for now** (no separate public allowlist). Revisit when
   a non-vendor consumer appears; the allowlist is `render-json` in the warehouse file.
6. **`?exists` answers in Belnap**, and its generic function now takes
   `&key &allow-other-keys` (see §8 for the CLOS trap).
7. **Soft delete keeps the identity reserved.** Verified schema: `uk_gstin_name_tenant`
   does not include `DELETED_STATE`, so a deleted row still holds its identity —
   re-creating the same GSTIN+name yields the **:C contradiction → 409**.
8. **Class initforms mirror the DDL defaults** (see §8).

---

## 6. Session / login rules (touched today)

- **Max 2 concurrent vendor logins** (`*HHUBMAXVENDORLOGINS*` = 2, `compadminsite` users
  analogous). Policy kept; two bugs fixed:
  - **Cookie clobbering:** `hunchentoot:remove-session` writes
    `Set-Cookie: hunchentoot-session=deleted` into the *current* reply, so evicting
    another device's session destroyed the cookie of the login that triggered it —
    the new login was unusable and the policy became self-defeating (orphan records
    consumed the quota). Fixed by `hhub-remove-other-websession` (throwaway
    `hunchentoot:*reply*`): the session is still removed from the session DB.
  - **Eviction order:** candidates came from a `maphash` walk (`nth 0`), so it evicted
    whichever session the hash yielded — observed killing an 8-second-old session
    while a 10-minute-old one survived three rounds. Now sorted oldest-first by
    `hhub-websession-start`.
- **Ghost records:** business-session records outlive their hunchentoot session
  (expiry/GC/removal) and used to count against the quota; `hhub-websession-live-p`
  (clock **and** session-DB membership) drives pruning in `enforcevendorsession`
  (`vendor/dod-ui-ven.lisp`) and `enforceusersession` (`sysuser/dod-bl-usr.lisp`).
- **The evicted device is silently bounced** (browser choice: no new UI).
- Session strings are bound to **User-Agent + client IP + session secret**, and
  `start-das` calls `(hunchentoot:reset-session-secret)` — so every restart invalidates
  all cookies, and a cookie minted for Firefox is rejected as a fake when curl
  presents it.
- `dodvendlogin` returns **302 for both success and failure**. Success →
  `…/hhub/dodvendindex?context=home`; failure → `…/hhub/hhubvendloginv2` (and the
  reason lands in `ninestores-busfunctions.log`). Never read the status as the outcome.

---

## 7. Deployment reality (nginx)

`/etc/nginx/sites-available/highrisehub.com`:

- `upstream hunchentoot { server 127.0.0.1:4244; }`
- `location /hhub/ { proxy_pass http://hunchentoot; }` → proxied **unchanged**
- `location / { if (!-f $request_filename) { rewrite ^/(.*)$ /hhub/$1 last; } }`

Therefore a path that already starts with `/hhub/` arrives at Lisp identically, while
anything else is rewritten to `/hhub/<path>`. That is why:

- endpoint templates are `/hhub/api/v1/...` and `register-api-route` **rejects** a
  template without the `/hhub/` prefix (see `api-path-deployment-prefix-p`);
- the dispatcher regex is `^/hhub/api/v1/`;
- the same string works both through nginx and directly against `127.0.0.1:4244`.
  (Only the *server* can use `127.0.0.1:4244`; from a workstation use
  `http://hunchentoot.local/hhub/api/v1/...`.)
- A future `location /api/ { proxy_pass http://hunchentoot; }` would let the prefix be
  dropped from templates + regex in one pass. Nothing else depends on it.

---

## 8. Sharp edges that cost real time

1. **CLOS congruence:** a generic function that accepts `&key`/`&rest` forces *every*
   method to accept them; a bare `(entity-class value ctx)` lambda list is rejected with
   *"differ in whether they accept &REST or &KEY"*. Measured combinations: `&key` GF
   + keyless method ✗; `&rest` GF + keyless method ✗; `&rest` GF + keyed method ✓;
   **`&key &allow-other-keys` GF + both styles ✓**. Hence `?exists` is declared
   `(entity-class lookup-value ctx &key &allow-other-keys)` and the `nst-customer`
   method carries `&key &allow-other-keys` purely for congruence.
2. **Unbound slots are loud, but late.** `nst-whs` had 39 initargs and **0 initforms**
   while `copyWarehouse-domaintodb` reads all 37 fields → a partial caller (the API!)
   aborted on the first missing one. Making the copier tolerant is *not* enough:
   CLSQL's `update-records-from-instance` emits **every** storable slot, so a nil
   becomes an explicit `NULL`, bypassing column DEFAULTs and failing on
   `NOT NULL … DEFAULT` columns. Fix: initforms on the class mirroring the DDL.
3. **Sentinels needed `:initarg :reason`.** `delete!`/`!update` build
   `(make-instance 'nst-entity-nil … :reason …)`; without the initarg SBCL rejects the
   unknown keyword, turning every "not found" into a 500. Fixed in adhara (additive).
4. **`bind-generated-row-id` bound only `id`** (the adhara string id), never the
   entity's `row-id` — so a freshly created entity failed in `domain->response`
   (UNBOUND-SLOT ROW-ID) *after* the INSERT succeeded. Now binds `row-id` too, guarded
   by `slot-exists-p` (only some entities declare it).
5. **`sb-debug:print-backtrace` here accepts only `:stream`/`:count`.** Passing
   `:condition` signals unknown-&key, and a `handler-case` guard silently degrades
   every 500 to `<backtrace unavailable>`.
6. **`handler-case` unwinds before its clauses run.** A backtrace taken in a clause
   shows only the handler's own frames. Capture must happen in **`handler-bind`**,
   which runs in the signal's dynamic context — that change is what made today's
   domain-level stack traces visible.
7. **`render-json`'s contract is split:** per-**entity** methods return a Lisp
   structure (an alist), per-**list**/sentinel methods return encoded text. The render
   hop now normalises both (`conflodis2-json-text`, `conflodis2-html-fragment`); the
   HTML side also had `display-warehouse-row` returning `nil` (it writes to
   `*standard-output*`), which `princ` turned into the literal text `NIL`.
8. **Re-registration must be idempotent:** domain files are re-evaluated on every
   reload, so `register-api-route` replaces its own `(method, path)` binding and only
   errors when a *different* route key claims the same path.
9. **`logIamhere` → `hunchentoot:log-message*`** → `~/hhublogs/ninestores-messages.log`,
   which is why enforcement traces appear there.

---

## 9. Deliberately unfinished (do not re-derive; extend)

1. **Error taxonomy.** A domain refusal (duplicate GSTIN, invalid sort key) is a plain
   `error` → **500 `internal_error`** with the real message only in the API log. Clients
   need 409/400. Needs a distinct condition (e.g. a domain-validation condition) raised
   by the domain and mapped in `api-status-for-condition`.
2. **Live duplicates are not `:C`.** Only a *soft-deleted* identity holder produces the
   contradiction; a live duplicate is refused by `make :before` (500 today, §9.1).
3. **UI does not receive `:C`.** `make :before` raises, so the internal create form shows
   an error rather than a contradiction page. Aligning means a guard in
   `nst-ui-warehouse.lisp`'s create model.
4. **`?exists` via the ferry is unusable** for `nst-whs`: `request->dispatch` passes
   `ctx` where the method expects the lookup value. Nothing calls it today (the route
   and `make :before` call the verb directly).
5. **Section 122 strictness.** With the pre-check aligned to the real key, the same
   GSTIN under a **different name** is allowed (the DB permits it). Enforcing "one GSTIN
   per tenant/globally" needs a schema change (`(GSTIN, TENANT)` unique) plus the
   pre-check following it.
6. **`is-primary-location` truthiness.** Query values arrive as strings and the domain
   treats any non-nil as true, so `?is-primary-location=0` filters *for* primary.
7. **Bearer API keys** — the `:session` auth scope is the only one implemented; the
   seam is `api-authenticate` + the `auth-scope` slot.
8. **Public vs internal field allowlist** — currently the same (decision §5.5).
9. **No rate limiting / no API key audit trail yet** (the API log records errors only).

---

## 10. How to work in this area (checklist)

**Add an endpoint for entity X**
1. Ensure the Tier-1 verbs exist (`make`/`fetch`/`!update`/`delete!`/`enumerate` for `X`).
2. Add a `route-<x>-<action>` verb in `X`'s own file (uniform signature
   `(request ctx)`; may call Tier-1 verbs directly).
3. `register-action-route` for that verb.
4. `register-api-route` with `:method`, `:path "/hhub/api/v1/…"`, `:path-params`,
   `:success-status` (201 for create), `:inject-company t` **only if** the domain verb
   reads a legacy company/tenant initarg that a client cannot supply.
5. Nothing to change in `hunchentoot:*dispatch-table*` — one handler serves all.

**Add a column/field to an entity**
Add it to the domain class **with an initform matching the DDL default** (nil when
nullable), or the class silently drifts from the schema and partial callers abort.

**Reload** `(asdf:load-system :nstores)`, then `(hunchentoot:started-p *http-server*)`
and `(hunchentoot:start *http-server*)` (or `(start-das)`) if the acceptor is down.

**Logs** (all under `/home/hunchentoot/hhublogs/`, app runs as user `hunchentoot`):
`ninestores-apilogs.log` (API failures + backtraces), `ninestores-messages.log`
(hunchentoot messages + `logIamhere`), `ninestores-access.log`, `ninestores-busfunctions.log`.

---

## 11. Verified transcript (2026-09-12)

```
GET  /hhub/vwarehousedetailspage?id=47        (session established via /hhub/dodvendlogin)

PUT  /hhub/api/v1/warehouse/47
     body {"wcity":"Thane","wmanager":"API Test"}
     → 200 {"rowId":"47","warehouseUuid":"08C93FB3-…","warehouseCode":"WH-EB70DB91",
            "city":"Thane", … 36 fields …}          ← full path proven end-to-end

curl -X PUT  (no session)                      → 401 {"error":"unauthenticated",…}
PUT  /api/v1/warehouse/47  (before /hhub fix)  → 404 no_such_endpoint
POST (6-field body, pre-initforms)             → 500 UNBOUND-SLOT WADDR1
POST (pre-bind-generated-row-id)               → 500 UNBOUND-SLOT ROW-ID **after INSERT**
POST same GSTIN+name again                     → 500 duplicate-identity refusal (genuine)
```

3-login enforcement runs showed: two candidates → exactly one eviction per login, the
current session never evicted, and (before the ordering fix) the *newest* session
evicted while the oldest survived.

**Not yet run:** create 201, fetch 200/404, list, delete ack, repeat-delete 404, the
409 `:C` path, `?is-primary-location` filters.

---

## 12. Test recipes

```bash
# from a workstation (nginx); never 127.0.0.1:4244 from a remote shell
curl -sS -i -b /tmp/ns.jar http://hunchentoot.local/hhub/api/v1/warehouse/<id>

# session first (302 is ambiguous — check Location + Set-Cookie)
curl -sS -D /tmp/h.txt -c /tmp/ns.jar -X POST http://hunchentoot.local/hhub/dodvendlogin \
  -d 'phone=<vendor phone>&password=<password>'

# create with only the fields the schema actually requires
curl -sS -i -b /tmp/ns.jar -X POST http://hunchentoot.local/hhub/api/v1/warehouse \
  -H 'Content-Type: application/json' \
  -d '{"wname":"Test DC Beta","warehouse-gstin":"29ABCDE1234F1Z8","state-code":"29"}'
```

**Shell cautions (cost time today):** use a real id, not `<placeholder>` — zsh treats
`<` as an input redirect; and do not paste trailing `#` comments into zsh
(`interactive_comments` is off by default), or the words become curl arguments.
