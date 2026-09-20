# products API — how to verify, and the verification record · CONTEXT

**Split out of `nst-bl-prdapi-CONTEXT.md` on 2026-09-20**, when that file passed the
400-line budget (README · *The daily size cycle*). Section numbers are preserved from
the parent so older cross-references still resolve. **Content is unchanged.**

**Covers:** the evidence that the products API works — the verification recipe (§10),
the 2026-09-13 probe transcript against the running server (§11), and the
`test/smoke-products-api.sh` runtime verification including the bug it exposed (§12).

**Read this when:** you need to know what is VERIFIED rather than merely reasoned, or
you are about to re-run the smoke test.

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
