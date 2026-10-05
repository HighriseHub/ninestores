# SKILL: ABAC Policy + Transaction seeding and enforcement (Nine Stores / hhub)

**Read this when:** you are adding authorization to an endpoint (policy +
transaction rows), an endpoint that *should* be denied is allowed, or a governed
call fails closed on a URI mismatch. §8 is the recipe; §7 tells you whether
enforcement is even wired up yet.

**Status:** mechanism verified against the live tree and database 2026-09-19; corrected and re-measured 2026-10-05 — the server is STRICT (§4), the API seam is *still* unwired (§7), `apply-migrations` now loads the upgrade files itself (§8 Step 4), and §12 (*seeded* vs *enforced*) is rebuilt from live SQL, replacing a 2026-09-20 snapshot whose "still to seed" list had gone wrong. Every `file:line` below was re-measured that day.
**Applies to:** every endpoint that should be governed by an authorization policy — UI controllers *and* the `/hhub/api/v1/...` JSON API.
**Covers:** seeding a `DOD_AUTH_POLICY` row + a `DOD_BUS_TRANSACTION` row and **linking them**; writing the policy *function* the policy row names; registering the seed as a migration so it runs once per database; and knowing **whether the endpoint is actually enforced** afterwards (it may not be — §7).
**Reference implementations in the tree:** `installation/upgrades/nst-dbu-order-policy-transaction.lisp` (1 endpoint); `installation/upgrades/nst-dbu-warehouse-policy-transaction.lisp` (6 endpoints); `installation/upgrades/nst-dbu-product-policy-transaction.lisp` (6 API endpoints — written by this skill's first application; **11** `:trans-func` rows today, §12).

---

## 2. The model in one picture

`DOD_BUS_TRANSACTION` carries the `TRANS_FUNC` lookup key, the `URI`, the `TRANS_TYPE`, the `TENANT_ID`, and the `AUTH_POLICY_ID` that points at exactly one `DOD_AUTH_POLICY` row (its `ROW_ID`). That policy names the decision function (`POLICY_FUNC`) — a real Lisp function interned in `:nstores`, reached by `funcall` as `(funcall fn params)`, one argument: the params alist. **One policy per transaction, never shared.**

---

## 3. The three names that must agree — the #1 source of silent failure

This is the trap that costs the most time, so it is stated first.

| What | Where it lives | How it is matched |
|---|---|---|
| **Transaction lookup key** | `DOD_BUS_TRANSACTION.TRANS_FUNC` | **exact** string match (hash-table key) |
| Transaction name | `DOD_BUS_TRANSACTION.NAME` | *documentation only* — **never matched at runtime** |
| Policy decision function | `DOD_AUTH_POLICY.POLICY_FUNC` | interned in package `:nstores`, must be `fboundp` |

🚨 **`NAME` is not the lookup key — `TRANS_FUNC` is.** `get-system-bus-transactions-ht` (`core/dod-bl-bo.lisp:91-97`) builds its hash table with `(slot-value tran 'trans-func)` as the key; the macro's first argument *looks* like a name but is matched against `TRANS_FUNC`. This is why UI controllers pass **their own function name**:

```lisp
(with-hhub-transaction "com-hhub-transaction-create-warehouse-action" params ...)
;;                       ^ this string must equal DOD_BUS_TRANSACTION.TRANS_FUNC
```

If it does not match, the macro raises `hhub-abac-transaction-error` ("Did not find transaction …") and the request is **denied fail-closed** — not silently allowed. A mismatch is loud; a *missing policy function* is the quieter failure (§6).

**For an API endpoint there is no controller**, so `TRANS_FUNC` is the string `apidefs2` already builds (`core/nst-bl-apidefs2.lisp`, `api-run-route` `:730`):

```lisp
(format nil "api ~A ~A" (api-route-method route) (api-route-path route))
;; => "api PUT /hhub/api/v1/catalog/products/{id}"
```

Both the method (uppercased) and the **path template including `/hhub` and `{id}`** are part of the string. Do not hand-write these — generate them from the route table (§8 Step 0 → §10) and compare.

---

## 4. Column constraints that bite

Measured from the live `hhubdb` schema. 🧨 **THE DATABASE IS STRICT — corrected 2026-10-04, re-measured 2026-10-05.** The old claim here was *"MySQL runs non-strict, so an over-long value is silently truncated"*. It was wrong, and it cost a seed file seven rows: `SELECT @@global.sql_mode` answers `ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION`, so under `STRICT_TRANS_TABLES` an over-long value is **Error 1406**, not a truncation. The failure mode is worse than a refused migration: `apply-migrations` (`core/nst-sch-mig.lisp:161`) catches **per migration** and CONTINUES, and the `INSERT INTO DOD_SCHEMA_MIGRATIONS` runs only *after* the migration function returns — so the seed body has already run, the version is never recorded, and it re-runs forever, half-applied. The limit had never been probed: `MAX(LENGTH(DESCRIPTION))` in `DOD_AUTH_POLICY` is **97** of 100 (again 2026-10-05). Check any seed file with `aiharness/deepseek/tools/nst-verify-abac-seed.lisp`, which compares every string against the MEASURED width and exits 1 naming the row that does not fit.

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

🚨 **`DOD_SCHEMA_MIGRATIONS.version` is `varchar(50)` and is compared for equality against the string in `*migrations*`** — `(member version applied :test #'string=)`, registry at `core/nst-sch-mig.lisp:10`, loop at `:161`. A version written in full at over 50 characters can never equal its stored form: under the strict mode above the recording `INSERT` raises Error 1406 (after the seed body ran, so it re-runs on the next apply), and under a lenient mode it would be stored truncated and re-run for the same reason. **Always verify `length(version) <= 50`.**

⚠ **CORRECTION 2026-10-05 — the instance this file used to cite no longer re-runs.** It said `"01092026-insert-vendor-order-cancel-policy-and-transaction"` (57 chars) was stored as `"01092026-insert-vendor-order-cancel-policy-and-tra"` (50) and therefore re-executed on every run. The stored value is indeed that 50-char string, but `*migrations*` (`core/nst-sch-mig.lisp:70`) names the version in that **same truncated form**, so the equality check matches and it is skipped like any other. Measured 2026-10-05: no registry version exceeds 50 characters, all 75 registered versions match a row in `DOD_SCHEMA_MIGRATIONS` (76 rows), and this one is recorded as applied `2026-09-06 00:10:56`. The rule above still stands — it is the *next* long name written in full that costs a day.

---

## 5. The URI column is a PREFIX GUARD, not an address

`with-hhub-transaction` verifies the DB `URI` against the live request URI using `uri-prefix-boundary-p` (`core/dod-bl-utl.lisp:22`), which is **literal prefix matching**, with `*uri-boundary-chars*` = `(#\/ #\? #\# #\;)` (`:19`). Consequences:

- `"/hhub/api/v1/catalog/products"` **matches** a request for `/hhub/api/v1/catalog/products/42` — the next character is `/`, a boundary.
- `"/hhub/api/v1/catalog/products/{id}"` **never** matches `/hhub/api/v1/catalog/products/42`, because `{id}` is a template, not a literal. Storing the template makes **every** call fail closed with a URI-mismatch deny.

**Therefore: for API rows, store the collection prefix and leave `{id}` out of `URI`.** The row is identified by its unique `TRANS_FUNC`; the URI only proves the request is aimed at the resource the transaction claims to guard. This is safe because prefix matching admits *more* than the transaction's own paths — it can never admit a path *outside* its resource.

The request URI reaches the check through the `params` alist under the **string** key `"uri"`; a transaction with no URI defined, or a request carrying no URI, is a fail-closed deny:

```lisp
(setf params (acons "uri" (hunchentoot:request-uri*) params))
```

---

## 6. The PEP chain, and what a policy function receives

```
with-hhub-transaction  (core/dod-ui-utl.lisp:961)
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

There is also a lower-level macro, `with-hhub-pep` (`core/dod-ui-utl.lisp:1022`), which looks the transaction up by `TRANS_FUNC` via `select-bus-trans-by-trans-func` and calls `has-permission1 policy-id subject resource action env`. It returns the **string** `"Permission Denied"` on deny rather than redirecting. Prefer it only where a string return is genuinely wanted.

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

The API goes through the conflodis2 seam, which is a **stub** — re-checked 2026-10-05, unchanged:

```lisp
;; core/nst-bl-conflodis2.lisp:266
(defun call-with-action-transaction (thunk route request trans-func-name)
  "Default: no wrapper. Replace/bind to integrate ABAC + with-hhub-transaction."
  (declare (ignore route request trans-func-name))
  (funcall thunk))
```

Three separate gaps (`file:line` re-measured 2026-10-05):

1. `*action-route-transaction-function*` (`:271`) is **never rebound anywhere in the tree** — the only other mentions are docstrings in `dod-ui-pol.lisp` and the generated symbol graph.
2. `dispatch-route2` (`:294`) accepts `:trans-func-name` (`:295`) and **never uses it** — it is not even in the `declare ignore` at `:305` (the only `ignore` naming `trans-func-name` is the stub's own, at `:268`).
3. `dispatch-action` (`:280`) passes a **literal `nil`** into the seam.

So the transaction name is built in `apidefs2` (`:738`), travels to Ring 3, and evaporates. The section header says as much: *"v1 default runs the action verb unwrapped so routes are testable before the PEP/ABAC wiring lands."*

**To activate ABAC on the API**, four changes are needed:

1. Write a `call-with-api-action-transaction (thunk route request trans-func-name)` that builds the params alist — `("uri" . <request-uri*>)` plus `("company" . <the company apidefs2 already resolved>)` — and runs the thunk inside `with-hhub-transaction` (or calls `has-permission` directly).
2. Thread `trans-func-name` through `dispatch-route2` → `dispatch-action` → the seam.
3. Bind `*action-route-transaction-function*`.
4. **Add a 403 to the API taxonomy.** `api-status-for-condition` (`core/nst-bl-apidefs2.lisp:672`) maps only `api-client-error`→400, `api-not-authenticated`→401, `api-no-endpoint`→404, everything else→500. There is **no 403**, and the macro's deny path *redirects* (HTML) which is wrong for a JSON client. An `api-forbidden` condition mapping to 403 is required.

Until 1–4 land, **ABAC rows for API endpoints are inert for the API and live for the UI.** Seed them anyway — the shape is independent of when the seam lands, and it keeps one naming convention — but **never report an API endpoint as protected on the strength of its row existing.**

---

## 8. Recipe: add ABAC for a new endpoint

### Step 0 — before writing anything, enumerate the endpoints

Generate the `TRANS_FUNC` strings **from the route table**, never by hand: split each `register-api-route` form on `:method` / `:path` and build `"api <METHOD> <path>"`. Then diff that list against the `:trans-func` values in the seed file — they must match **byte for byte**. §10 is exactly that script, already written; run it rather than retyping the extraction.

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

The helpers live in `core/nst-sch-mig.lisp` (`sql-literal` `:232`, `auth-policy-inserted-p` `:245`, `bus-transaction-inserted-p` `:255`, `auth-policy-id-by-name` `:265`, `insert-auth-policy` `:276`, `insert-bus-transaction` `:295`). Both insert calls are **idempotent** (`auth-policy-inserted-p` / `bus-transaction-inserted-p` skip an existing live row), so re-running is safe.

🚨 **2026-10-04 — ONE HELPER, ONE DEFINITION: AN UPGRADE FILE SHADOWED THE CANONICAL HELPERS AND BROKE `DESCRIPTION`s CONTAINING AN APOSTROPHE.** `installation/upgrades/nst-dbu-policy-transaction.lisp` — the first policy seed — carried **its own copies** of all five helpers (`auth-policy-inserted-p`, `bus-transaction-inserted-p`, `auth-policy-id-by-name`, `insert-auth-policy`, `insert-bus-transaction`); they were written before the helpers moved into `core/nst-sch-mig.lisp` and were never removed. Because `apply-migrations` calls `load-upgrade-files` **FIRST**, that file loads *after* `nst-sch-mig.lisp` on every run, so **its older copies overwrote the canonical ones** and the canonical `insert-auth-policy` — the one that escapes every string through `sql-literal`, doubling single quotes — **was never called**. The symptom is what makes this worth reading: a seed whose first `DESCRIPTION` read *"List the session customer's orders…"* died with **Error 1064**, the offending SQL printed with the apostrophe **unescaped**, even though `sql-literal` was present, correct and fbound in the image — *the escaping was in the image the whole time and was never reached*. The five definitions are now DELETED from that file (117 lines changed), reason recorded in place. **Two lessons: never re-define a migration helper in an upgrade file — upgrade files load AFTER the canonical ones (alphabetically sorted) and silently win; and when an escaping helper appears not to work, check WHO IS DEFINED BEFORE YOU, not whether the helper is right.**

### Step 3 — register the migration

Add a `(version fn description)` triple to `*migrations*` at `core/nst-sch-mig.lisp:10`.

🚨 **`version` must be ≤50 characters** (§4). Format used by the tree: `DDMMYYYY-<kebab description>`.

### Step 4 — apply, THEN REFRESH THE CACHE

`installation/upgrades/*.lisp` files are **not** referenced by `nstores.asd`, deliberately — do not "helpfully" wire them in. ⚠ **CORRECTED 2026-10-05:** `apply-migrations` itself calls `load-upgrade-files` (`core/nst-sch-mig.lisp:128`) *before* touching the database, and a **pre-flight** refuses the whole run — *"REFUSING TO APPLY: ~D pending migration(s) have no function loaded. Nothing was written."*, naming the file through `upgrade-file-defining` (`:114`) — if a *pending* migration's function is still unloaded. So the working sequence is simply: put the file in `installation/upgrades/`, then run `(apply-migrations user pass)` — it loads the file, then applies it. A rebuild is no longer needed for the function to be visible (only for changed compiled code).

🚨 **Then call `(refreshiamsettings)` — or restart the acceptor.** The transaction/policy caches are built once at startup and are tenant-1-scoped (traps 9 and 10). Without the refresh the rows exist in the database but the running image cannot see them, and every call to the new endpoint fails closed as though the transaction were missing. This step is easy to forget because the SQL succeeds and the rows are visibly there in `mysql`.

### Step 5 — verify (§10) and state the enforcement status honestly (§7)

---

## 9. Traps, in the order they bite

1. **`TRANS_FUNC` vs `NAME`** — the lookup key is `TRANS_FUNC` (§3). A wrong key is a *loud* fail-closed deny; a right key with a missing policy function is quieter but also denies.
2. **`POLICY_FUNC` must exist** (§3, §6) — interned in `:nstores`, must be `fboundp`. Seeding a policy whose function was never written denies every call.
3. **`params` keys are STRINGS** (`"uri"`, `"company"`), not keywords (§6).
4. **`{id}` in `URI` never matches** — store the collection prefix (§5).
5. **`varchar` limits** — the table is in §4. ⚠ **THE MODE IS STRICT (corrected 2026-10-04): AN OVER-LONG VALUE IS Error 1406, NOT A SILENT TRUNCATION**, and the version column is compared for equality, so an over-long version can never be recorded and re-runs. Check a seed with `aiharness/deepseek/tools/nst-verify-abac-seed.lisp`.
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

10. **🚨 THE CACHES ARE MEMOIZED AT STARTUP — REFRESH AFTER SEEDING.** `*HHUBGLOBALLYCACHEDLISTSFUNCTIONS*` (`core/dod-ini-sys.lisp:83`) is built once by `hhub-gen-globally-cached-lists-functions` (`:314`) — which is where `transactions-ht` (index 7) and `policies-ht` (index 8) come from — and is otherwise only rebuilt by `refreshiamsettings` (`core/dod-bl-sys.lisp:11`), or as a side effect of `suspendaccount` / `restoreaccount` (`account/dod-bl-cmp.lisp:49`, `:57` — the rebuild is at `:55`).

    So **a freshly seeded transaction is not visible to a running image.** Seeding and *not* refreshing produces exactly the fail-closed deny of trap 9 and looks like a bad `TRANS_FUNC`. Refresh with any of:

    ```lisp
    (refreshiamsettings)                      ; in the image
    ;; or GET /hhub/refreshiamsettings          (com-hhub-transaction-refresh-iam-settings,
    ;;                                          dispatched at sysuser/dod-ui-sys.lisp:936; admin button at :590)
    ;; or restart the acceptor
    ```

11. **`get-ht-val` returns NIL for an absent key *and* for a present key whose value is nil** (`core/dod-bl-utl.lisp:661`) — the docstring says so explicitly. A transaction that exists but has a NULL `TRANS_FUNC` is therefore indistinguishable from one that does not exist, and denies.
12. **`DOD_AUTH_POLICY.NAME` is not unique by schema** — idempotency relies on the helper's own `NAME + TENANT_ID + DELETED_STATE='N'` check, so a soft-deleted row with the same name will cause a **duplicate** to be inserted on the next run.
13. **🚨 Adding rows to an ALREADY-APPLIED migration is a silent no-op.** `apply-migrations` never re-runs a version it has already recorded, so appending a block to an existing migration function puts the row in the *source* and never in the *database* — the worst possible outcome, because the file then reads as covered. **The version is the unit of "has this already happened"**, not the function. The insert helpers are idempotent, which is what makes a later migration over the same two tables safe. This bit twice on 2026-09-20, first for pricing and then for copy.
13b. **THE FIX IS ONE APPLY PER DAY, and it is a cadence rule, not a code rule.** *See §13.1 — the day's migration is EXTENDED as endpoints land and APPLIED ONCE, at the day's end.* Getting this wrong is what produced **four** product migrations on 2026-09-20: each endpoint was seeded and applied as it landed, and once a version is recorded the next endpoint cannot join it.
14. **A new endpoint needs a policy FUNCTION too, not just a seed row.** The migration's `POLICY_FUNC` string must name a `defun` in `core/dod-ui-pol.lisp`, or the policy row points at nothing. §10 checks this; the row alone is not the change.

---

### 13.1 One migration per day — the cadence

**One `*migrations*` version per calendar day**, named `<DDMMYYYY>-insert-<domain>-policies`, carrying every ABAC policy + transaction seeded that day. The rule is enforced not by discipline in the file but by **when you run `apply-migrations`**:

| when | what |
|---|---|
| while the day's work continues | **extend** the day's function — add a block per endpoint. Do **not** create a second version. |
| at the day's end (the 23:00 commit) | **apply once.** One version, one run, every endpoint seeded together. |
| an endpoint lands *after* the day's migration was applied | that needs a **second version**, and it is a signal the apply came too early — not a reason to give up on the rule. |

**Why applying early is the thing that breaks it.** A version is recorded at apply time and never re-runs, so an apply mid-day freezes that version and orphans every endpoint added afterwards. Batching the *apply* is what makes one version per day possible; the file is edited freely all day and that costs nothing.

**The escape hatch, and why it is not the same thing.** The insert helpers are idempotent, so a *function* can safely be called again by hand in the REPL — but doing that instead of adding a new version leaves the database and `DOD_SCHEMA_MIGRATIONS` disagreeing: a fresh database running `apply-migrations` would produce a different state from an existing one where the function was re-called manually. **Same version, two different databases** is precisely the divergence migrations exist to prevent. Use a new version.

**The 2026-09-20 exception, recorded rather than tidied.** That day carries four product migrations — `19092026-insert-product-policy-and-transactions` (6 endpoints), `20092026-insert-product-pricing-policies`, `20092026-insert-product-status-policy`, and `20092026-insert-product-copy-policy`. The first two were applied before the rule existed and the third before it was agreed, so they cannot be merged now: they are recorded, and merging would mean rewriting history that databases have already acted on. **The rule started with the next day** — the 2026-10-04 order-API set (`04102026-order-api-policies`, 10 endpoints in one version) is the rule working.

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
```

Expected: `TRANS_FUNC match : EXACT`, no missing policy funcs. Column widths are checked by `aiharness/deepseek/tools/nst-verify-abac-seed.lisp` (§4), which does the same query against the measured schema.

---

## 11. File map

`file:line` re-measured 2026-10-05.

| Concern | Location |
|---|---|
| `with-hhub-transaction`, `with-hhub-pep` | `hhub/core/dod-ui-utl.lisp:961`, `:1022` |
| `has-permission`, `has-permission1`; transaction cache + selectors | `hhub/core/dod-bl-bo.lisp:184`, `:177`; cache at `hhub/core/dod-bl-bo.lisp:85-128` (`get-system-bus-transactions` is tenant-1 only, `:88`; the hash builder `:91-97`) |
| Policy cache + selectors | `hhub/core/dod-bl-pol.lisp:107-116` (`get-system-auth-policies` is tenant-1 only, `:107`) |
| `*HHUBGLOBALLYCACHEDLISTSFUNCTIONS*` + builder | `hhub/core/dod-ini-sys.lisp:83`, `:314` (transactions-ht = index 7, policies-ht = index 8) |
| `refreshiamsettings` | `hhub/core/dod-bl-sys.lisp:11`; route at `sysuser/dod-ui-sys.lisp:936`, button at `:590` |
| `uri-prefix-boundary-p`, `*uri-boundary-chars*` | `hhub/core/dod-bl-utl.lisp:22`, `:19`; `get-ht-val` at `:661` |
| Policy functions (the decisions); seed migrations | `hhub/core/dod-ui-pol.lisp`; `installation/upgrades/nst-dbu-*-policy-transaction.lisp` |
| `*migrations*` registry, `apply-migrations`, loader; the seed helpers | `hhub/core/nst-sch-mig.lisp:10`, `:161`, `:128`; helpers `:245-344` (`sql-literal` `:232`) |
| ABAC condition classes; PEP test harness | `hhub/core/dod-bl-err.lisp:74-127`; `hhub/test/hhub-tst-abac-pep.lisp` |
| API seam (stub, §7); API status taxonomy (no 403, §7) | `hhub/core/nst-bl-conflodis2.lisp:266`, `:271`, `:280`, `:294`; `hhub/core/nst-bl-apidefs2.lisp:672` |

---

## 12. Current state as of 2026-10-05 — seeded vs enforced

This section replaces a 2026-09-20 snapshot whose two load-bearing claims had both gone stale: **"still to seed: vendor profile (5), vendor shipping (6), vendor payment methods (3)"** (all seeded and applied 2026-09-19) and **"copy: not yet applied"** (true only at that snapshot's own 19:17 timestamp — recorded at 19:33:55). Everything below was measured on 2026-10-05 from `DOD_SCHEMA_MIGRATIONS` and a sweep of `register-api-route` against live `api …` `TRANS_FUNC` rows.

**Every ABAC policy migration in `*migrations*` is applied — 12 of them:**

- **UI/controller rows:** warehouse, 6 endpoints (`25082026-insert-warehouse-policy-and-transactions`, applied 2026-09-06 00:10:55; its policy functions are **stubs returning `T`**); vendor order-cancel, 1 (`01092026-insert-vendor-order-cancel-policy-and-tra`, 2026-09-06 00:10:56 — §4).
- **Catalog API + the other API groups (applied 2026-09-19 23:42):** catalog 6 CRUD+list, `19092026-insert-product-policy-and-transactions` (23:42:29) — its seed file `nst-dbu-product-policy-transaction.lisp` now carries **11** `:trans-func` rows, pricing/status/copy/bulk/template having come later, and §10 reports `EXACT` for it; warehouse API 6 (`19092026-insert-warehouse-api-policies`), vendor profile 5 (`19092026-insert-vndapi-policies`), vendor shipping 6 (`19092026-insert-vndshpapi-policies`), vendor payment methods 3 (`19092026-insert-vndvpmapi-policies`).
- **Products, one version per endpoint** (§13.1): pricing (`20092026-insert-product-pricing-policies`, 2026-09-20 11:19:37), status (`20092026-insert-product-status-policy`, 19:17:15), copy (`20092026-insert-product-copy-policy`, 19:33:55), bulk + template (`20092026-insert-product-bulk-policies`, 2026-10-04 07:51:46).
- **Orders: 10 endpoints** in one version — `04102026-order-api-policies`, applied 2026-10-04 19:04:39. **Counts, 2026-10-05:** `DOD_SCHEMA_MIGRATIONS` 76 applied, `DOD_BUS_TRANSACTION` 94 rows, `DOD_AUTH_POLICY` 92 rows. (*Was* 68 / 81 / 79 at the old 2026-09-20 19:17 measurement, which was checked by row-ids 54–59, 80, 81.)

**Still to seed: the invoice channel.** The 2026-10-05 sweep found **52** registered API routes against **41** live `api …` `TRANS_FUNC` rows; the eleven without a row are the ten `/hhub/api/v1/invoices…` routes plus `api PUT /hhub/api/v1/vendor/profile/{id}/invoice-settings`. Nothing was found in the other direction — no seeded `TRANS_FUNC` lacks a registered route.

**None of the API rows are enforced.** The seam is still the pass-through stub of §7 (re-checked 2026-10-05), so every row above naming an `api …` `TRANS_FUNC` is **inert**: the rows exist and are read by nothing. The UI/controller rows are live. Copy is still the one product policy whose separation is a genuine authority split rather than a logging convenience (it creates a listing; the others change one).
