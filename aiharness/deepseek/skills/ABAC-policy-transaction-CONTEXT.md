# SKILL: ABAC Policy + Transaction seeding and enforcement (Nine Stores / hhub)

**Status:** verified against the live tree and database 2026-09-19.
**Applies to:** every endpoint that should be governed by an authorization policy —
UI controllers *and* the `/hhub/api/v1/...` JSON API.
**Reference implementations in the tree:**
- `installation/upgrades/nst-dbu-order-policy-transaction.lisp` (1 endpoint)
- `installation/upgrades/nst-dbu-warehouse-policy-transaction.lisp` (6 endpoints)
- `installation/upgrades/nst-dbu-product-policy-transaction.lisp` (6 API endpoints — written by this skill's first application)

---

## 1. When to use this skill

Use it whenever you add or modify an endpoint and the question *"who is allowed to call this, and under what conditions?"* needs an answer that lives in the database rather than in code. It covers:

- seeding a `DOD_AUTH_POLICY` row + a `DOD_BUS_TRANSACTION` row and **linking them**;
- writing the policy *function* the policy row names;
- registering the seed as a migration so it runs once per database;
- knowing **whether the endpoint is actually enforced** afterwards (it may not be — see §7).

---

## 2. The model in one picture

```
  DOD_BUS_TRANSACTION            DOD_AUTH_POLICY
  ┌────────────────────┐         ┌──────────────────┐
  │ TRANS_FUNC  ◄──────┼── the lookup key
  │ URI                │         │ POLICY_FUNC ─────┼──► a real Lisp function
  │ TRANS_TYPE         │         │   in :nstores    │    (funcall fn params)
  │ AUTH_POLICY_ID ────┼────────►│ ROW_ID           │
  │ TENANT_ID          │         │ TENANT_ID        │
  └────────────────────┘         └──────────────────┘
```

`TRANS_FUNC` is how a caller names what it wants checked. The transaction points at exactly one policy (`AUTH_POLICY_ID`), and the policy names the function that makes the decision. **One policy per transaction, never shared.**

---

## 3. The three names that must agree — the #1 source of silent failure

This is the trap that costs the most time, so it is stated first.

| What | Where it lives | How it is matched |
|---|---|---|
| **Transaction lookup key** | `DOD_BUS_TRANSACTION.TRANS_FUNC` | **exact** string match (hash-table key) |
| Transaction name | `DOD_BUS_TRANSACTION.NAME` | *documentation only* — **never matched at runtime** |
| Policy decision function | `DOD_AUTH_POLICY.POLICY_FUNC` | interned in package `:nstores`, must be `fboundp` |

🚨 **`NAME` is not the lookup key — `TRANS_FUNC` is.** `get-system-bus-transactions-ht` (`core/dod-bl-bo.lisp:91-97`) builds its hash table with `(slot-value tran 'trans-func)` as the key. The macro's first argument *looks* like a name but is matched against `TRANS_FUNC`. This is why UI controllers pass **their own function name**:

```lisp
(with-hhub-transaction "com-hhub-transaction-create-warehouse-action" params ...)
;;                       ^ this string must equal DOD_BUS_TRANSACTION.TRANS_FUNC
```

If it does not match, the macro raises `hhub-abac-transaction-error` ("Did not find transaction …") and the request is **denied fail-closed** — not silently allowed. A mismatch is loud; a *missing policy function* is the quieter failure (see §6).

**For an API endpoint there is no controller**, so `TRANS_FUNC` is the string `apidefs2` already builds (`core/nst-bl-apidefs2.lisp`, `api-run-route`):

```lisp
(format nil "api ~A ~A" (api-route-method route) (api-route-path route))
;; => "api PUT /hhub/api/v1/catalog/products/{id}"
```

Both the method (uppercased) and the **path template including `/hhub` and `{id}`** are part of the string. Do not hand-write these — generate them from the route table (§8) and compare.

---

## 4. Column constraints that bite

Measured from the live `hhubdb` schema. MySQL runs non-strict, so **an over-long value is silently truncated**, and a truncated value then never matches what the code holds.

| Column | Type | Trap |
|---|---|---|
| `DOD_AUTH_POLICY.NAME` | `varchar(50)` | keep ≤50 |
| `DOD_AUTH_POLICY.DESCRIPTION` | `varchar(100)` | keep ≤100 |
| `DOD_AUTH_POLICY.POLICY_FUNC` | `varchar(255)` | generous |
| `DOD_BUS_TRANSACTION.NAME` | `varchar(100)` | documentation only |
| `DOD_BUS_TRANSACTION.URI` | `varchar(100)` | see §5 |
| `DOD_BUS_TRANSACTION.TRANS_TYPE` | `varchar(15)` | use `READ` / `CREATE` / `UPDATE` / `DELETE` |
| `DOD_BUS_TRANSACTION.TRANS_FUNC` | `varchar(100)` | **the lookup key** |
| `DOD_SCHEMA_MIGRATIONS.version` | `varchar(50)` **UNIQUE** | 🚨 see below |

🚨 **`DOD_SCHEMA_MIGRATIONS.version` is `varchar(50)` and is compared for equality against the string in `*migrations*`.** `apply-migrations` (`core/nst-sch-mig.lisp:83`) skips a migration whose version is `(member version applied :test #'string=)`. MySQL truncates anything longer, so **a version string over 50 characters can never match its stored form and the migration re-runs on every `apply-migrations` call.**

A real instance exists: `"01092026-insert-vendor-order-cancel-policy-and-transaction"` is **57 characters** and is stored as `"01092026-insert-vendor-order-cancel-policy-and-tra"` (50). It is idempotent, so nothing breaks — but it re-executes every run. **Always verify `length(version) <= 50`.**

---

## 5. The URI column is a PREFIX GUARD, not an address

`with-hhub-transaction` verifies the DB `URI` against the live request URI using `uri-prefix-boundary-p` (`core/dod-bl-utl.lisp:22`), which is **literal prefix matching**, with `*uri-boundary-chars*` = `(#\/ #\? #\# #\;)` (`:19`).

Consequences:

- `"/hhub/api/v1/catalog/products"` **matches** a request for `/hhub/api/v1/catalog/products/42` — the next character is `/`, a boundary.
- `"/hhub/api/v1/catalog/products/{id}"` **never** matches `/hhub/api/v1/catalog/products/42`, because `{id}` is a template, not a literal. Storing the template makes **every** call fail closed with a URI-mismatch deny.

**Therefore: for API rows, store the collection prefix and leave `{id}` out of `URI`.** The row is identified by its unique `TRANS_FUNC`; the URI only proves the request is aimed at the resource the transaction claims to guard. This is safe because prefix matching admits *more* than the transaction's own paths — it can never admit a path *outside* its resource.

The request URI reaches the check through the `params` alist under the **string** key `"uri"`:

```lisp
(setf params (acons "uri" (hunchentoot:request-uri*) params))
```

A transaction with no URI defined, or a request carrying no URI, is a fail-closed deny.

---

## 6. The PEP chain, and what a policy function receives

```
with-hhub-transaction  (core/dod-ui-utl.lisp:947)
  ├─ get-ht-val <TRANS_FUNC> (hhub-get-cached-transactions-ht)   → must exist, else error
  ├─ uri-prefix-boundary-p  <db-uri> <request-uri>               → mismatch = deny
  └─ has-permission transaction params  (core/dod-bl-bo.lisp:184)
       ├─ transaction must carry AUTH_POLICY_ID, else deny
       ├─ policy = (get-ht-val policy-id (hhub-get-cached-auth-policies-ht))
       ├─ policy must carry POLICY_FUNC, else deny
       ├─ symbol = (find-symbol (string-upcase policy-func) :nstores)
       ├─ must be fboundp, else deny
       └─ (funcall symbol params)     ← THE DECISION. One argument: the params alist.
```

- **On allow** the body runs.
- **On deny** the macro `hunchentoot:redirect`s to `/hhub/permissiondenied` and aborts the request. *This is UI behaviour and is wrong for a JSON client* — see §7.
- `hhub-abac-uri-*` conditions are caught inside the macro and converted to the same deny, so **the macro never returns normally on a deny**.

There is also a lower-level macro, `with-hhub-pep` (`core/dod-ui-utl.lisp:1008`), which looks the transaction up by `TRANS_FUNC` via `select-bus-trans-by-trans-func` and calls `has-permission1 policy-id subject resource action env`. It returns the **string** `"Permission Denied"` on deny rather than redirecting. Prefer it only where a string return is genuinely wanted.

### The policy function

Signature and the two normal shapes, both taken from `core/dod-ui-pol.lisp`:

```lisp
;; STUB — allows everybody. This is what the warehouse set does. It is a
;; placeholder, not a policy; do not treat it as protection.
(defun com-hhub-policy-create-warehouse (&optional (params nil))
  :documentation "Policy for warehouse create"
  T)

;; REAL — deny when the tenant is suspended.
(defun com-hhub-policy-show-invoice-payment-page (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
         (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error
             :errstring (format nil "Account Name: ~A. This Account is Suspended."
                                (slot-value company 'name))))
    T))
```

**`params` is the controller-style ALIST with STRING keys** (`"uri"`, `"company"`), **not** the keyword plist the conflodis2 ferry reads (`:row-id`, `:prd-name`). Reading it with keyword keys finds nothing and — because `nil` is falsey in most guards — silently allows everything.

🚨 Note `:documentation "…"` after the lambda list is **not a docstring**; it is two body forms, a keyword and a string. It is the existing house style in `dod-ui-pol.lisp` and it works, but it registers no documentation. A real docstring is a bare string in first position.

A policy signals `hhub-abac-transaction-error` to deny with a specific message; returning `nil` denies with a generic one. `has-permission` catches any error, logs a backtrace to `*HHUBBUSINESSFUNCTIONSLOGFILE*`, and returns `(list nil "Nine Stores … Authorization Error…")` — so a **broken** policy denies rather than allows.

---

## 7. 🚨 Is the endpoint actually enforced? (the part that is easy to get wrong)

**Seeding rows does not enforce anything by itself.** The rows are read by whichever mechanism the endpoint's transport actually calls.

| Transport | Enforced today? | Why |
|---|---|---|
| **UI controller** (calls `with-hhub-transaction` directly) | ✅ **yes** | the macro is the PEP |
| **`/hhub/api/v1/...` JSON API** | ❌ **NO — not yet** | see below |

The API goes through the conflodis2 seam, which is a **stub**:

```lisp
;; core/nst-bl-conflodis2.lisp:258
(defun call-with-action-transaction (thunk route request trans-func-name)
  "Default: no wrapper. Replace/bind to integrate ABAC + with-hhub-transaction."
  (declare (ignore route request trans-func-name))
  (funcall thunk))
```

Three separate gaps, all verified 2026-09-19:
1. `*action-route-transaction-function*` (`:263`) is **never rebound anywhere in the tree**.
2. `dispatch-route2` (`:286`) accepts `:trans-func-name` and **never uses it** — it is not even in the `declare ignore` at `:297`.
3. `dispatch-action` (`:278-280`) passes a **literal `nil`** into the seam.

So the transaction name is built in `apidefs2` (`:568`), travels to Ring 3, and evaporates. The section header says as much: *"v1 default runs the action verb unwrapped so routes are testable before the PEP/ABAC wiring lands."*

**To activate ABAC on the API**, four changes are needed:
1. Write a `call-with-api-action-transaction (thunk route request trans-func-name)` that builds the params alist — `("uri" . <request-uri*>)` plus `("company" . <the company apidefs2 already resolved>)` — and runs the thunk inside `with-hhub-transaction` (or calls `has-permission` directly).
2. Thread `trans-func-name` through `dispatch-route2` → `dispatch-action` → the seam.
3. Bind `*action-route-transaction-function*`.
4. **Add a 403 to the API taxonomy.** `api-status-for-condition` (`core/nst-bl-apidefs2.lisp:502`) maps only `api-client-error`→400, `api-not-authenticated`→401, `api-no-endpoint`→404, everything else→500. There is **no 403**, and the macro's deny path *redirects* (HTML) which is wrong for a JSON client. An `api-forbidden` condition mapping to 403 is required.

Until 1–4 land, **ABAC rows for API endpoints are inert for the API and live for the UI.** Seed them anyway — the shape is independent of when the seam lands, and it keeps one naming convention — but **never report an API endpoint as protected on the strength of its row existing.**

---

## 8. Recipe: add ABAC for a new endpoint

### Step 0 — before writing anything, enumerate the endpoints

Generate the `TRANS_FUNC` strings **from the route table**, never by hand:

```bash
# For prdapi-style files: split on the registration form and read :method / :path.
python3 - <<'PY'
import re
api = open('hhub/products/nst-bl-prdapi.lisp', encoding='utf-8').read()
for body in api.split('(register-api-route ')[1:]:
    m = re.search(r':method\s+:(\w+)', body)
    p = re.search(r':path\s+"([^"]+)"', body)
    if m and p:
        print('"%s"' % ("api %s %s" % (m.group(1).upper(), p.group(1))))
PY
```

Then diff that list against the `:trans-func` values in the seed file. They must match **byte for byte**. A helper for exactly this comparison is at the end of this file (§10).

### Step 1 — write the policy functions

Add them to `core/dod-ui-pol.lisp`. Name them `com-hhub-policy-<area>-<verb>`. Return `T` to allow; signal `hhub-abac-transaction-error` to deny with a message. Prefer a **real** check (suspended tenant is the established one) over a stub `T`.

### Step 2 — write the seed migration

Create `installation/upgrades/nst-dbu-<domain>-policy-transaction.lisp`. Structure — one `let` block per endpoint, policy id captured and passed explicitly:

```lisp
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun migrate-2026Sep-insert-<domain>-policy-and-transactions ()
  "…Idempotent - safe to rerun."
  (let ((tenant-id 1))
    ;; --- VERB : METHOD /hhub/api/v1/... ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.<area>.<verb>"          ; <= 50 chars
             "One-line description of what is authorised." ; <= 100 chars
             "com-hhub-policy-api-<area>-<verb>"           ; must EXIST in dod-ui-pol.lisp
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.<area>.<verb>"
       "/hhub/api/v1/<area>"                     ; COLLECTION PREFIX — no {id}
       "READ"                                    ; READ|CREATE|UPDATE|DELETE
       :policy-id policy-id                      ; the link
       :trans-func "api GET /hhub/api/v1/<area>" ; exact apidefs2 string
       :tenant-id tenant-id))))
```

The helpers live in `core/nst-sch-mig.lisp:117-214`. Both calls are **idempotent** (`auth-policy-inserted-p` / `bus-transaction-inserted-p` skip an existing live row), so re-running is safe.

### Step 3 — register the migration

Add a `(version fn description)` triple to `*migrations*` at `core/nst-sch-mig.lisp:12`.

🚨 **`version` must be ≤50 characters** (§4). Format used by the tree: `DDMMYYYY-<kebab description>`.

### Step 4 — load and apply, THEN REFRESH THE CACHE

`installation/upgrades/*.lisp` files are **not** referenced by `nstores.asd` or by `nst-sch-mig.lisp`; the migration *functions* they define must be loaded into the image before `apply-migrations` can `funcall` them. The existing warehouse and order seeds are registered **and applied** (both appear in `DOD_SCHEMA_MIGRATIONS`), so the working sequence is: load the upgrade file (or rebuild the image with it), then run `(apply-migrations user pass)`.

🚨 **Then call `(refreshiamsettings)` — or restart the acceptor.** The transaction/policy caches are built once at startup and are tenant-1-scoped (traps 9 and 10). Without the refresh, the rows exist in the database but the running image cannot see them, and every call to the new endpoint fails closed as though the transaction were missing. This step is easy to forget because the SQL succeeds and the rows are visibly there in `mysql`.

### Step 5 — verify (§10) and state the enforcement status honestly (§7)

---

## 9. Traps, in the order they bite

1. **`TRANS_FUNC` vs `NAME`** — the lookup key is `TRANS_FUNC`. A wrong key is a *loud* fail-closed deny; a right key with a missing policy function is quieter but also denies.
2. **`POLICY_FUNC` must exist** — it is interned in `:nstores` and must be `fboundp`. Seeding a policy whose function was never written denies every call.
3. **`params` keys are STRINGS** (`"uri"`, `"company"`) — not keywords.
4. **`{id}` in `URI` never matches** — store the collection prefix.
5. **`varchar` truncation** — `DOD_SCHEMA_MIGRATIONS.version` 50, `DOD_AUTH_POLICY.NAME` 50, `DESCRIPTION` 100, `DOD_BUS_TRANSACTION.TRANS_FUNC` 100. MySQL is non-strict here; over-long values are **silently truncated**.
6. **One policy per transaction** — the tree is explicit that a policy is never shared between transactions.
7. **A broken policy fails closed** — `has-permission` converts any error to a deny. Good for safety, bad for debugging: read `*HHUBBUSINESSFUNCTIONSLOGFILE*`.
8. **Seeding ≠ enforcing on the API** (§7).
9. **🚨 `TENANT_ID` MUST BE 1 — the caches are built for tenant 1 ONLY.** This is the sharpest trap in the whole mechanism. Both lookup tables are populated from tenant-1-scoped queries:

   ```lisp
   ;; core/dod-bl-bo.lisp:88-89
   (defun get-system-bus-transactions () (select-bus-trans-by-company (select-company-by-id 1)))
   ;; core/dod-bl-pol.lisp:107-108
   (defun get-system-auth-policies () (get-auth-policies 1))
   ```

   A transaction or policy seeded under **any other tenant is invisible** to `with-hhub-transaction` — the lookup misses, the macro raises `hhub-abac-transaction-error`, and every call fails closed. `tenant-id 1` is the platform/super tenant (`DOD_COMPANY.ROW_ID = 1`, name `super`). Always seed tenant 1.

10. **🚨 THE CACHES ARE MEMOIZED AT STARTUP — REFRESH AFTER SEEDING.** `*HHUBGLOBALLYCACHEDLISTSFUNCTIONS*` (`core/dod-ini-sys.lisp:73`) is built once by `hhub-gen-globally-cached-lists-functions` (`:289`) — which is where `transactions-ht` (index 7) and `policies-ht` (index 8) come from — and is otherwise only rebuilt by `refreshiamsettings` (`core/dod-bl-sys.lisp:12`), or as a side effect of suspend/restore-account (`account/dod-bl-cmp.lisp:54`).

    So **a freshly seeded transaction is not visible to a running image.** Seeding and *not* refreshing produces exactly the fail-closed deny of trap 9 and looks like a bad `TRANS_FUNC`. Refresh with any of:

    ```lisp
    (refreshiamsettings)                      ; in the image
    ;; or GET /hhub/refreshiamsettings          (com-hhub-transaction-refresh-iam-settings,
    ;;                                          dispatched at core/dod-ui-sys.lisp:936;
    ;;                                          an admin button exists at :590)
    ;; or restart the acceptor
    ```

11. **`get-ht-val` returns NIL for an absent key *and* for a present key whose value is nil** (`core/dod-bl-utl.lisp:487`) — the docstring says so explicitly. A transaction that exists but has a NULL `TRANS_FUNC` is therefore indistinguishable from one that does not exist, and denies.

12. **`DOD_AUTH_POLICY.NAME` is not unique by schema** — idempotency relies on the helper's own `NAME + TENANT_ID + DELETED_STATE='N'` check, so a soft-deleted row with the same name will cause a **duplicate** to be inserted on the next run.

---

## 10. Verification snippet

Run this after every ABAC change. It catches the two failure modes that are otherwise invisible until runtime.

```bash
cd /home/ubuntu/ninestores && python3 - <<'PY'
import re
API  = 'hhub/products/nst-bl-prdapi.lisp'
SEED = 'installation/upgrades/nst-dbu-product-policy-transaction.lisp'
POL  = 'hhub/core/dod-ui-pol.lisp'

api = open(API, encoding='utf-8').read()
built = set()
for body in api.split('(register-api-route ')[1:]:
    m = re.search(r':method\s+:(\w+)', body); p = re.search(r':path\s+"([^"]+)"', body)
    if m and p: built.add("api %s %s" % (m.group(1).upper(), p.group(1)))

seed = open(SEED, encoding='utf-8').read()
tf   = re.findall(r':trans-func\s+"([^"]+)"', seed)
pol  = open(POL, encoding='utf-8').read()
funcs = re.findall(r'"(com-hhub-policy-[a-z0-9-]+)"', seed)

print("routes built     :", len(built))
print("TRANS_FUNC seeded:", len(tf))
print("NOT seeded       :", sorted(built - set(tf)) or "none")
print("SEEDED but not a route:", sorted(set(tf) - built) or "none")
print("TRANS_FUNC match :", "EXACT" if built == set(tf) else "*** MISMATCH ***")
print("policy funcs missing:", [f for f in funcs if ('(defun %s ' % f) not in pol] or "none")
PY

# column-width checks
mysql -u hhubuser -p'Welcome$123' hhubdb -e "
  SELECT version, LENGTH(version) FROM DOD_SCHEMA_MIGRATIONS ORDER BY LENGTH(version) DESC LIMIT 3;
  SELECT NAME, LENGTH(NAME) FROM DOD_AUTH_POLICY ORDER BY LENGTH(NAME) DESC LIMIT 3;"
```

Expected: `TRANS_FUNC match : EXACT`, no missing policy funcs, and every reported length within its column limit.

---

## 11. File map

| Concern | Location |
|---|---|
| `with-hhub-transaction`, `with-hhub-pep` | `hhub/core/dod-ui-utl.lisp:947`, `:1008` |
| `has-permission`, `has-permission1` | `hhub/core/dod-bl-bo.lisp:184`, `:177` |
| Transaction cache + selectors | `hhub/core/dod-bl-bo.lisp:85-128` (`get-system-bus-transactions` is tenant-1 only, `:88`) |
| Policy cache + selectors | `hhub/core/dod-bl-pol.lisp:107-116` (`get-system-auth-policies` is tenant-1 only, `:107`) |
| `*HHUBGLOBALLYCACHEDLISTSFUNCTIONS*` + builder | `hhub/core/dod-ini-sys.lisp:73`, `:289` (transactions-ht = index 7, policies-ht = index 8) |
| `refreshiamsettings` | `hhub/core/dod-bl-sys.lisp:12`; route at `core/dod-ui-sys.lisp:936`, button at `:590` |
| `uri-prefix-boundary-p`, `*uri-boundary-chars*` | `hhub/core/dod-bl-utl.lisp:22`, `:19`; `get-ht-val` at `:487` |
| Policy functions (the decisions) | `hhub/core/dod-ui-pol.lisp` |
| Policy/transaction seed helpers | `hhub/core/nst-sch-mig.lisp:117-214` |
| `*migrations*` registry, `apply-migrations` | `hhub/core/nst-sch-mig.lisp:12`, `:83` |
| Seed migrations | `installation/upgrades/nst-dbu-*-policy-transaction.lisp` |
| ABAC condition classes | `hhub/core/dod-bl-err.lisp:74-115` |
| PEP test harness | `hhub/test/hhub-tst-abac-pep.lisp` |
| API seam (stub, §7) | `hhub/core/nst-bl-conflodis2.lisp:258`, `:263`, `:278`, `:286` |
| API status taxonomy (no 403, §7) | `hhub/core/nst-bl-apidefs2.lisp:502` |

---

## 12. Current state as of 2026-09-19

- **Products / catalog API (6 endpoints):** policies + transactions seeded (`nst-dbu-product-policy-transaction.lisp`), policy functions written in `dod-ui-pol.lisp`, migration registered as `19092026-insert-product-policy-and-transactions` (47 chars). `TRANS_FUNC` strings verified to match `apidefs2` exactly. **Not yet enforced** — the API seam (§7) is still unbound.
- **Warehouse (6 endpoints):** seeded and applied (`25082026-insert-warehouse-policy-and-transactions`); policy functions are stubs returning `T`.
- **Vendor order-cancel (1 endpoint):** seeded and applied; version string is over-long and re-runs (§4).
- **Still to seed:** vendor profile (5), vendor shipping (6), vendor payment methods (3) — the remaining API endpoints created before the product work.
- `DOD_SCHEMA_MIGRATIONS` held 61 applied migrations; `DOD_BUS_TRANSACTION` 53 rows; `DOD_AUTH_POLICY` 51 rows.
