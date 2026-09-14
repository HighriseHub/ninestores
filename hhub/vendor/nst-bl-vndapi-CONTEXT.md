# nst-bl-vndapi — Vendor profile on conflodis2 + apidefs2 · CONTEXT

**Purpose of this file.** Working context for whoever continues the VENDOR migration
to the new architecture (adhara → conflodis2 → apidefs2). Read this before touching
`vendor/nst-dal-vnd.lisp`, `vendor/nst-bl-vnd.lisp`, or the view-class
`dod-vend-profile` in `vendor/dod-dal-ven.lisp`.

**Date of the work recorded here:** 2026-09-13 (evening session).

---

## 0. READ THIS FIRST — the verification status

**NOTHING HERE HAS BEEN COMPILED OR LOADED. NO VENDOR VERB HAS EVER RUN.**

That is the headline, and it is not modesty. The domain class and the प्रत्यय layer
are written and wired into the build, but the running image does not contain
`nst-vnd` — `find-class` would fail today. Everything below marked REASONED was
reasoned from the schema and from the products/warehouse precedents; only the items
marked VERIFIED were actually exercised.

| Claim | Status |
|---|---|
| Live schema of `DOD_VEND_PROFILE` | **VERIFIED** by direct SQL (`SHOW COLUMNS`, `SHOW INDEX`, `GROUP BY` over all 15 rows) |
| `USERNAME` blocks every INSERT (error 1364) | **VERIFIED** by a rolled-back `INSERT` against the live database |
| Column coverage: every live column has a slot or is inherited | **VERIFIED** by script, 44/44 accounted for |
| Structural parse of both new files | **VERIFIED** — top-level form count, depth 0, comment/string aware |
| Response model excludes all 6 secrets | **VERIFIED** by script over the response class |
| `domain->response` ↔ `render-json` ↔ response slots are 1:1 | **VERIFIED** by script — 35/35/35 |
| Build wiring order (`adhara` before `nst-dal-vnd` before `nst-bl-vnd`) | **VERIFIED** in `nstores.asd` |
| The class compiles | **UNVERIFIED BY ME.** The author compiled `nst-dal-vnd.lisp` manually (a `.fasl` dated 23:02 sits beside the source) and reported it clean. See §8.1 for why that proves less than it looks. |
| `nst-bl-vnd.lisp` compiles | **NOT RUN.** It was written after that compile. |
| Any verb, ferry, DB read/write, or JSON render | **NOT RUN.** |
| Routes / API bindings | **DO NOT EXIST YET.** See §7.1. |

---

## 1. Where things live

| File | Role |
|---|---|
| `vendor/nst-dal-vnd.lisp` | **NEW.** `nst-vnd` (domain entity, 41 declared slots + 5 inherited from `nst-domain-entity` = 46) + `VendorRequestModel` (slotless) + `VendorResponseModel` (35 slots) |
| `vendor/nst-bl-vnd.lisp` | **NEW.** The six Tier-1 प्रत्यय, the two copiers, the reverse ferry |
| `vendor/dod-dal-ven.lisp` | Legacy CLSQL view-class `dod-vend-profile` — **edited**: gained `username` and `fullname` slots (§6.1), and the COUNTRY slot's accessor was fixed from `city` |
| `vendor/nst-bl-vendapi.lisp` | **STALE, INERT.** 9 `register-outbound-route` entries for the pre-conflodis2 registry. Names classes that do not exist; paths unreachable. Same dead pattern the products file had. **See §8.4 — the filename hazard.** |
| `vendor/dod-bl-ven.lisp` | Legacy function layer, 403 lines. **`select-vendor-by-id` IS NOT TENANT-SCOPED — see §6.2.** |
| `vendor/dod-ui-ven.lisp` | Legacy UI, 3,482 lines. Contains `dod-vend-login`. Not migrated. |
| `core/nst-bl-adhara.lisp` | Sentinels, `request->dispatch`, `extract-domain-initargs`, the six universal प्रत्यय, `domain->response`, `render-json`, the knowledge→domain-result converters |
| `core/nst-bl-conflodis2.lisp` | Tier-2 dispatcher: `register-action-route`, `dispatch-route2` |
| `core/nst-bl-apidefs2.lisp` | Ring-4 JSON boundary: `register-api-route` |
| `core/nst-mult-logic.lisp` | `with-db-call`, `with-nst-db-create/update/delete/read-all`, `bind-generated-row-id` |

Build wiring (both `:serial t`, both now list both new files):
`hhub/package/compile.lisp` and `hhub/nstores.asd`.

**Ordering is load-bearing.** `nst-dal-vnd` names `nst-domain-entity` from adhara, and
`nst-bl-vnd` names the `dod-vend-profile` view-class and calls
`escape-like-wildcards` / `prd-flag->boolean` at CALL time (both live in files that
load later — harmless, see §8.3). Current positions: `adhara` at asd line 88,
`nst-dal-vnd` at 185, `nst-bl-vnd` at 189.

---

## 2. Commits from this session (all unpushed, ahead 10)

| Commit | What |
|---|---|
| `71b8f84` | fix the COUNTRY slot reusing the `city` accessor |
| `6fcd83e` | add the `nst-vnd` domain class and wire it into the build |
| `5079c3a` | add the nst-vnd प्रत्ययs, and the view-class slots `make` needs |
| `31d22e9` | core: knowledge→domain-result converters |
| `e08f945` | core: provenance normalization + `knowledge-conjoin` |
| `a80c553` | warehouse: four-state verbs + `by-identity` |
| `66fce1a` | products: `:C` law into `make`, tenant escape fix |
| `6cb4c3d` | password policy (`dod-bl-utl`, `dod-bl-ven`, `vendortrydemo.html`) |
| `4186240` | ollama refactoring validator |
| `8f6eb6e` | both API smoke suites |

The last seven are **inherited work** — written on 2026-09-13 but earlier in the day,
and committed on request. They are not vendor-specific, but they are what the vendor
layer is built on: without `domain-result-from-knowledge` the प्रत्यय have nothing to
convert with.

---

## 3. Schema and data facts (VERIFIED by SQL, 2026-09-13)

`installation/hhubplatform.sql` is stale for this table. Verified live on MySQL
**8.0.46**, `sql_mode` includes **`STRICT_TRANS_TABLES`**:

* **`UC_Vendor` is `UNIQUE (PHONE, TENANT_ID)`** — the only unique key besides the PK.
  Identity is a **tenant-scoped tuple**. Contrast `DOD_PRD_MASTER`, whose
  `PRODUCT_CODE` is one **global** column.
* The column is **`shipping_enabled`** (lower case) and **`gstnumber`** (lower case) —
  the only two not in this file's otherwise-consistent casing.
* **Six NOT NULL columns with no default:** `NAME, ADDRESS, PHONE, USERNAME, PASSWORD,
  TENANT_ID`.
* **`PASSWORD`, `SALT`, `PAYMENT_API_KEY`, `PAYMENT_API_SALT` are all on the row** —
  every other table migrated so far holds no secrets.
* **`USERNAME` is in NO unique key**, and the login path matches **`PHONE`**, so
  nothing enforces distinct usernames.
* Status distribution, all 15 rows:

  | active | approved | approval_status | suspend | deleted | rows |
  |---|---|---|---|---|---|
  | Y | Y | APPROVED | N | N | 14 |
  | Y | Y | PENDING | N | N | 1 |

  So `active_flag='Y'`, `suspend_flag='N'` and `deleted_state='N'` on **every** row:
  `:inactive` and `:suspended` filters match **nothing** today.
* **ZERO soft-deleted rows exist** — the `:C` soft-deleted-identity path has no
  fixture and must be created by the test, unlike products where one already existed.
* Status columns carry **zero NULLs** (the `:void-value` trap is dormant as in
  products), but **`SALT` has 3 real NULLs**.
* Vendors live in tenants **2 and 5**. The demo login `9999999990` is row 1, tenant 2.

---

## 4. Architecture in one screen

```
POST /hhub/api/v1/vendor/...               UI: /hhub/... (LEGACY — not migrated)
        │                                       │
        ▼                                       │  ← NOT the same path yet
com-hhub-api-dispatch (apidefs2)
  find-api-route    → literal beats {param}
  api-authenticate  → SESSION COMPANY (अधिकरण)
  api-params-for-request → company, path, body, query
        │
        └──────────────► dispatch-route2 (conflodis2)
                            ▼
                     route-vendor-create        one ACTION, entity-agnostic
                            ▼
                  request->dispatch (Tier-1 ferry, adhara)
                            ▼
                     make ∘ nst-vnd
                            │
                   ┌────────┴────────┐
              domain->response   render-json
```

**Invariant restated:** the API adds transport, never business routes. Each endpoint
is a binding onto an already-registered verb, so an API call and (once the UI is
migrated) an internal page share one कारक build, one ferry, one set of domain laws.

---

## 5. The प्रत्यय layer, as designed

| प्रत्यय | Method | Vendor-specific shape |
|---|---|---|
| `?exists` | `((eql 'nst-vnd) (phone string) (ctx domain-ctx) &key &allow-other-keys)` | Tenant-scoped; answers "taken **in this tenant**" |
| `make` | `:around` + primary | required-field guard; owns the `:C` law |
| `fetch` | `((eql 'nst-vnd) (id string) (ctx domain-ctx))` | by row-id, tenant-scoped → BOLA-safe |
| `!update` | `((eql 'nst-vnd) (row-id string) (ctx domain-ctx) &rest changed-slots)` | credential lockout |
| `delete!` | `((eql 'nst-vnd) (row-id string) (ctx domain-ctx))` | soft delete; identity reserved **per tenant** |
| `enumerate` | `((eql 'nst-vnd) (ctx domain-ctx) &key …)` | 5 status keywords, 3 filters, whitelisted sort, pagination |

**Belnap mapping** (what apidefs2 turns into status codes):

| | `make` | `fetch` / `!update` / `delete!` | `enumerate` |
|---|---|---|---|
| `:T` | entity | entity | list |
| `:F` | contradiction (lost race) → **409** | nil sentinel → **404** | `'()` → **200 `[]`** |
| `:U` | unknown → **503** | unknown → **503** | unknown → **503** |
| `:C` | unreachable → error | contradiction → **409** | contradiction → **409** |

**Query surface for `enumerate`:** `status` (`active|inactive|suspended|pending|rejected`),
`approval-status`, `name-like`, `city`, `gst-number` (exact, not LIKE), `sort-by`,
`sort-dir`, `limit`, `offset`. Sort keys are whitelisted in `*vnd-sort-whitelist*`.
`:offset` without `:limit` is refused.

**Sort / filter name-collision discipline:** `*vnd-sort-whitelist*` and
`validate-vendor-sort-args` are deliberately NOT called `*whs-sort-whitelist*` /
`validate-sort-args`, because the latter reads the WAREHOUSE's whitelist and reusing
the name would silently redefine the warehouse's sort validation.

---

## 6. Decisions made, with the reasons

1. **`dod-vend-profile` gained `username` and `fullname` slots.** Not cosmetic — it was
   a hard blocker. `USERNAME` is NOT NULL with no column default, the view-class had no
   slot for it, and `clsql:update-records-from-instance` emits only the slots the class
   declares. Under `STRICT_TRANS_TABLES` **every INSERT through that class failed**:
   `ERROR 1364: Field 'USERNAME' doesn't have a default value`. The legacy
   `create-vendor` is broken against this schema for the same reason. `update-vendor-details`
   is unaffected because it takes an already-hydrated instance from a `select`.
2. **The new verbs use `select-vendor-by-id-in-tenant`, NOT the legacy
   `select-vendor-by-id`.** The legacy selector filters on `deleted-state` and `row-id`
   only — **it is not tenant-scoped**, so a session in tenant 2 could read tenant 1's
   vendor by guessing a row-id. That is a pre-existing OWASP API1:2023 BOLA hole in the
   legacy layer. It is NOT fixed here (out of scope, and `dod-ui-ven.lisp` may depend on
   the current behaviour) — **it is worth its own ticket.**
3. **`?exists` is the INVERSE of products'.** `UC_Vendor` includes `TENANT_ID`, so the
   query mirrors the key and the pre-check PREDICTS the INSERT correctly. Products had
   to check a global key and accept that its pre-check answered "free" in exactly the
   case where the write was about to fail.
4. **The `&key &allow-other-keys` on `?exists` is accepted and IGNORED.** It exists for
   CLOS congruence with adhara's generic function; here the second half of the identity
   is the TENANT, and taking it from a keyword would let a client probe another
   tenant's phone numbers. The session tenant from `ctx` always wins.
5. **`make` validates required fields BEFORE the INSERT.** Products deliberately left
   NOT NULL enforcement to the database, and for products that was safe. Here it is not:
   the refusal would happen inside `with-nst-db-create`, whose catch-all turns any error
   into `:U` → **503**, telling the client to retry something that will never succeed.
   A `vendor-required-field-missing` condition names the field instead.
6. **`USERNAME` is derived, not demanded** — from `:vnd-phone` when the caller supplies
   none. It is NOT NULL, in no unique key, and the login matches `PHONE`, so demanding
   it would be ceremony. This is a verb choice, documented because the column's NOT NULL
   makes some value mandatory and silence would be the wrong one.
7. **`!update` REFUSES the four secret fields** (`*vendor-update-forbidden-fields*`)
   rather than stripping them. Products strips `:row-id` and is right to; a dropped
   `:password` is different — the client would believe it rotated a credential that was
   never touched. Checked BEFORE the SELECT, so a malformed request is reported as
   malformed rather than as a 404. **Credential rotation needs its own verb with its own
   authorization.**
8. **The response model is the secret boundary.** `render-json` publishes every slot of
   `VendorResponseModel`, so the exclusion is structural: `password`, `salt`,
   `payment-api-key`, `payment-api-salt`, `username`, `tenant-id` and `company` have no
   slot to be copied into. `nst-prd` could rely on a plain allowlist because it held no
   secrets; this one cannot.
9. **`!update` can write `approved-flag`, `approval-status` and `suspend-flag`** — the
   columns the login contract reads (`approved_flag='Y' AND approval_status='APPROVED'
   AND deleted_state='N'`). **A caller can lock a vendor out of its own login.** This is
   an authorization question for the route layer and is documented in the method rather
   than silently excluding the fields. Approval and suspension deserve their own verbs.
10. **The class default for each column is the DDL default where one exists**, and a
    documented *class choice* where the column is nullable with no default. Those
    choices leave a new vendor in the state the login contract expects: not yet
    approved (`approved-flag "N"`, `approval-status "PENDING"`), not suspended, active.
    Note `active-flag` diverges from what the legacy path produced (`:void-value "N"`)
    toward the live data (all 15 rows are `'Y'`) — the docstring says so.
11. **`deleted-state` has no accessor on `dod-vend-profile`** — read/write it with
    `slot-value`. Same trap products documented.
12. **Slot naming is prefixed `vnd-` on the domain class** (`vnd-phone`, `vnd-name`,
    `vnd-city`) where the plain name would collide with a legacy accessor in the shared
    `:nstores` package, and plain where it would not (`username`, `firstname`,
    `salutation`). The view-class keeps the plain names. A `with-slots` on the
    destination therefore says `name` while a `slot-value` on the source says `vnd-name`;
    getting it backwards signals `UNBOUND-SLOT`.

---

## 7. Deliberately unfinished — do not re-derive

1. **There is NO route file.** `vendor/nst-bl-vndapi.lisp` does not exist. This is the
   immediate next step: `route-vendor-*` verbs, their `register-action-route` entries,
   and the `register-api-route` bindings — modelled on `products/nst-bl-prdapi.lisp`.
   The binding surface is **designed but not written**, and the URL prefix is still an
   open decision (`/hhub/api/v1/vendor/vendors` is redundant; products uses
   `/hhub/api/v1/catalog/products` and warehouse `/hhub/api/v1/warehouse`).
2. **The 4xx taxonomy gap (§7.3 of the products CONTEXT) now applies to three vendor
   paths**, not one: the required-field guard, the secret-field refusal in `!update`,
   and `validate-vendor-sort-args`. All three signal a condition, which leaves the API
   as a **500** where the right answer is **400**. This is the highest-value fix and it
   is shared with the warehouse's `validate-sort-args`. Until then, 500 is still better
   than the 503 those paths would otherwise produce.
3. **No tests.** No `test/nst-tst-vendor.lisp`, no `test/smoke-vendor-api.sh`. When one
   is written it needs its own `:C` fixture — no soft-deleted vendor exists.
4. **`vendor/nst-bl-vendapi.lisp` is dead weight AND a filename hazard.** Nine
   `register-outbound-route` calls, no live classes, unreachable paths. The new file is
   `nst-bl-vndapi.lisp` — one letter apart, exactly the `prodapi`/`prdapi` trap the
   products CONTEXT flags. **Reduce the old one to a spec or delete it before the new
   one lands.**
5. **The vendor UI is NOT migrated.** `dod-ui-ven.lisp` has no `route-vendor` /
   `request->dispatch` references. The core invariant — external call and internal page
   sharing one ferry — does not hold for vendors. There is no `render-html` for
   `VendorResponseModel`, so a UI caller on the new path hits `no-applicable-method`.
6. **Only the PROFILE entity is covered.** The vendor surface also spans
   `DOD_VENDOR_TENANTS`, `DOD_VENDOR_AVAILABILITY_DAY`, `DOD_VPAYMENT_METHODS`,
   `DOD_VENDOR_APPOINTMENT` and `DOD_VENDOR_SETTINGS`. Each is a later slice.

---

## 8. Sharp edges that cost real time

1. **A successful manual compile proves less than it looks.** The author's
   `nst-dal-vnd.fasl` sits **beside the source**; the app loads from
   `/home/hunchentoot/.cache/common-lisp/sbcl-2.6.8-linux-x64/home/ubuntu/ninestores/hhub/`.
   A fasl in the wrong place does not reach the running image. It does rule out the
   syntax-error class; it does not rule out the `t`-as-a-variable class, because SBCL
   writes a fasl even when `compile-file` signals — the definition becomes a stub that
   raises `SB-INT:COMPILED-PROGRAM-ERROR` only when called.
2. **Paren counting caught two real defects.** Both new files were written with a
   comment/string-aware scanner that counts **top-level forms** and prints where each
   one starts. `nst-bl-vnd.lisp` failed at depth 2: `make :around` and `make` were each
   missing a closer, so lines 373–994 were nested inside them. **A global
   balance check would NOT have caught this** — the file was only 2 off, and a
   compensating error elsewhere would have hidden it entirely. Count forms, not parens.
3. **Cross-file calls resolved at call time are fine.** `escape-like-wildcards`
   (warehouse) and `prd-flag->boolean` (products) both live in files that load AFTER
   `nst-bl-vnd.lisp`. This is the same situation products documented — harmless, and
   reuse beats copying so each rule keeps one implementation. `vnd-flag->boolean`
   delegates to `prd-flag->boolean` rather than duplicating the Y/N rule.
4. **A column-coverage script is worth the five minutes.** It caught that `EMAIL` had
   been omitted from the entity AND the response model on the first pass — a field
   silently missing from an API is not something a compile or a review catches easily.
   The check: strip the `vnd-` prefix from the class's slots, `comm` against
   `SHOW COLUMNS`, and confirm everything unmatched is one of the four inherited slots.
5. **CLI login is limited to 2 concurrent vendor sessions, evicted oldest-first**, so a
   `curl` login can silently bounce a browser session and vice versa. `dodvendlogin`
   returns **302 for success AND failure** — never read the status as the outcome.
6. **The API log records only CONDITION-derived failures.** Sentinel-derived `:F`/`:U`/
   `:C` responses leave no trace, so 503s and 409s are invisible in
   `ninestores-apilogs.log`.
7. **Two files in this tree are unreadable and will break bulk git operations**:
   `vendor-profile-update-prompt.md` and `products/nst-bl-prdapi-CONTEXT.md`, both
   `600 hunchentoot` while the shell runs as `ubuntu`. `git add -A`, `git commit -a` and
   `git stash` fail with `cannot hash`. Use explicit `git add <path>`, and consider a
   `chmod` sweep.
8. **The `dod-dal-ven.lisp` and `dod-bl-ven.lisp` diffs carry a whole-file CRLF → LF
   normalization** that was not made in this session. `git diff --ignore-cr-at-eol`
   isolates the real changes (20 added lines / 0 removed, and 52/11 respectively).

---

## 9. The `t` trap, restated because it will recur

`(lambda (t) …)` is illegal — `t` is `COMMON-LISP:T`, a defined constant. SBCL reports
it as a compile ERROR **and still writes a fasl**, so the failure surfaces at runtime as
`Execution of a form compiled with errors.` The build script counts it as a success. If
a new vendor function ever seems to do nothing, check for this first.

---

## 10. How to resume tomorrow

**The agreed order is: API DESIGN first, then TESTS.** That order is sound, and it is
worth being explicit about why — the test suite is not the polish step, it is the FIRST
TIME ANY OF THIS CODE RUNS. No vendor verb has ever executed. Writing the routes and
then the suite is the products sequence, and it worked there; the thing that made it
work was treating the suite as the execution, not as an afterthought.

### Step 0 — one form, before anything else

Not a stage, a precondition. Proves the tree you are about to build on actually loaded.

```lisp
;; A reload, NOT a restart — a restart calls reset-session-secret and kills sessions.
(asdf:load-system :nstores)
(find-class 'nst-vnd)                     ; expect #<STANDARD-CLASS NST-VND>
(length (closer-mop:class-slots (find-class 'nst-vnd)))   ; expect 46
;; 41 declared (row-id, company, 39 column slots) + 5 inherited
;; (id, tenant-id, created-at, updated-at, deleted-state).
;; NOTE: `id` and `((row-id` sit on a DOUBLE-paren line, so a naive
;; "^   (name" grep undercounts by one on each class. Count :initarg instead.
```

If `nst-bl-vnd.lisp` fails to compile, fix that first — everything below assumes it did.

### Step 1 — API design

1. **Write `vendor/nst-bl-vndapi.lisp`** — the `route-vendor-*` verbs, their
   `register-action-route` entries, and the `register-api-route` bindings, modelled on
   `products/nst-bl-prdapi.lisp` and `warehouse/nst-bl-whsapi.lisp`.
2. **Settle the URL prefix while designing it.** Products uses
   `/hhub/api/v1/catalog/products`, warehouse `/hhub/api/v1/warehouse`. A
   `/hhub/api/v1/vendor/vendors` is redundant; pick deliberately rather than by
   default, because the path is the one part of this surface that is expensive to
   change once a client exists.
3. **Decide who may call what.** `make` sets a vendor's PASSWORD, and `!update` can
   write `approved-flag`/`approval-status`/`suspend-flag` — the columns the login
   contract reads, so a caller can lock a vendor out of its own login. §6.9 records
   this; the binding layer is where it gets answered (`:inject-company`, credential
   requirements, which verbs are exposed at all).
4. **Delete or reduce `vendor/nst-bl-vendapi.lisp` BEFORE the new file lands** — see
   §7.4. `vendapi` and `vndapi` differ by one letter and the stale file is inert.
5. **Carry NO `:inject-company`** on vendor routes: the tenant is enforced by
   construction inside `make`/`!update`, the same reasoning as products, and doing it
   in the domain does not depend on the leftmost-initarg rule.

### Step 2 — Tests

6. **Write `test/smoke-vendor-api.sh`**, following `test/smoke-warehouse-api.sh` —
   read-only by default, `--write` for the mutating verbs, exit 2 for setup failure so
   "the API was never tested" is distinguishable from "the API is broken".
7. **It needs a fixture that does not exist yet: a soft-deleted vendor.** All 15 live
   rows are `deleted_state='N'`, so the `:C` path has nothing to trigger it. Create it
   with `--write` (or insert and soft-delete one), then assert that re-creating that
   phone in that tenant answers **409, not 201 and not 500** — and that the same phone
   is still **free in another tenant**, which is the per-tenant reservation UC_Vendor
   implies and the one thing that distinguishes this entity from products.
8. **Include the Belnap section.** All four truth values, with `:F` exercised through
   four triggers (absent id, cross-tenant id, soft-deleted id, absurd id), and the
   anti-collapse assertions: a miss must be 404 and NOT 503; a contradiction must be
   409 and NOT 200 or 404.
9. **Expect these three paths to answer 500 where 400 is right** — the required-field
   guard, the `!update` secret refusal, and a bad `?sort-by=`. That is the known
   taxonomy gap (§7.2), not a new bug. Assert them as `KNOWN` rather than `FAIL`, the
   way the warehouse suite does, so a real regression stands out.

### Step 3 — then, and only then

10. **Fix the 4xx taxonomy (§7.2)** — it is now three vendor paths plus the warehouse's
    `validate-sort-args`. The tests from step 2 are what tell you the fix worked.

**The database credentials** are in `core/dod-ini-sys.lisp` (`hhubdb`, user
`hhubuser`). **The files worth reading first**, beyond this one:
`core/nst-bl-apidefs2-CONTEXT.md`, `products/nst-bl-prdapi-CONTEXT.md`,
`products/nst-bl-prdapi.lisp`, `core/nst-bl-adhara.lisp` §1/§5b/§6, and
`test/smoke-warehouse-api.sh` for the test pattern including its Belnap section.

**And the standing rule this project keeps re-learning:** compile-time success is not
evidence. Both bugs the products work found on 2026-09-13 were only reachable by RUNNING
the code, and both sat on the same call chain — a selector returning a list where its
siblings returned one row, and a knowledge object whose provenance was a string where
the class documents a list. Neither is a compile error, neither is caught by a
structural check, and neither is reachable on the read-only path.

---

## 11. SETTLED — `render-json` stays in adhara. Do not re-litigate this.

Asked on 2026-09-14: *given that apidefs2 is the JSON API layer and already emits JSON,
is `render-json` in adhara still needed?* The answer is **yes, keep it**, and the
reasoning is recorded here because the question is a good one and will occur again.

### 11.1 It is on every request path, and apidefs2 could not replace it

```
api-run-route (apidefs2:575)
 └─ api-render-json (:415)
     └─ conflodis2-render  (:225)
         ├─ render-json            ← its only 2 call sites, both here (:238, :245)
         └─ conflodis2-json-text → json:encode-json-to-string (:214)
 └─ api-write-json (:423)          ← content-type, status code, abort
```

apidefs2 DELEGATES to `render-json`; it does not supersede it. And it could not:
apidefs2's only encoder call is `api-error-json` (:432), which encodes a hand-built
alist. **There is no cl-json encoder for any response model anywhere in the tree** —
`json:encode-json-to-string` has nothing to walk for a `VendorResponseModel`.
Something must convert the object to an alist first, and that is `render-json`.

Three things live there that apidefs2 structurally cannot know:

1. **The field allowlist** — the security boundary. For vendor it is what keeps
   `password`, `salt`, `payment-api-key` and `payment-api-salt` off the wire.
2. **Wire naming** — `vnd-name` → `"name"`, `rowId`, camelCase throughout.
3. **Type conversion** — Y/N → boolean (`vnd-flag->boolean`), integer id → JSON
   string (`response-id-string`).

These are DOMAIN decisions — which fields exist, what a flag means, how an id crosses
a boundary. Put them in apidefs2 and the API layer starts holding business rules, which
is the invariant the whole architecture exists to prevent.

### 11.2 There is no "crisscross" — the dependency is already inverted

Checked 2026-09-14, because the claim was worth testing rather than accepting:

* **adhara names no entity in code.** Every occurrence of `nst-whs`/`nst-prd`/`nst-vnd`
  is a comment or docstring, except one line inside
  `test-niyam-fires-on-domain-entity-not-boundary` (a test constructing an `nst-whs`).
* **apidefs2 names no entity in code.** Its mentions (lines 82, 83, 354) are all
  comments.

```
adhara          defgeneric render-json  ← pure contract, names nothing
   ↑
vendor/warehouse/products   defmethod  ← the domain-specific decisions
   ↑
conflodis2      calls render-json
   ↑
apidefs2        calls conflodis2-render
```

Dependencies point inward; adhara depends on nothing. Textbook dependency inversion,
already implemented.

### 11.3 The "core render-json + a derived one" alternative is already what exists

That is `defgeneric` (the core seam) + `defmethod` (the derived specialisation). No
base class, no override machinery — CLOS multiple dispatch does the split for free.

**And the obvious "core" implementation is a trap.** A default method on
`nst-boundary-object` that reflects all slots would publish `password`, `salt`,
`payment-api-key` and `payment-api-salt` for vendor the moment someone forgets to
write a method. Today a missing method signals `no-applicable-method` — **it fails
closed.** A reflective default would fail **open**. The objection to that alternative
is safety, not complexity.

### 11.4 The real defect is the SPLIT CONTRACT — a separate, smaller task

`render-json` does two incompatible jobs depending on which method you are in:

| Returns a **Lisp alist** (3) | Returns already-encoded **JSON text** (7) |
|---|---|
| `WarehouseResponseModel`, `ProductResponseModel`, `VendorResponseModel` | `nst-customer-response-model`, `warehouse-ack-response`, `nst-response-nil` / `-unknown` / `-contradiction`, `render-json ((responses list))`, `ping-response` |

`ping-response` returns a hardcoded JSON string literal. Consequences:

* `conflodis2-json-text` must sniff the value's TYPE to guess its meaning —
  `(if (stringp rendered) rendered (json:encode-json-to-string rendered))`. A string
  means "already JSON" in one method and would mean "a JSON string value" in another.
* Encoding is duplicated across **five** sites: `conflodis2:214`, `whsapi:310`,
  `whsapi:337`, `Customer:669`, `apidefs2:432`.
* Nothing validates that the text-returning methods emit well-formed JSON.

**The fix, when someone takes it on:** make `render-json` ALWAYS return a Lisp
structure, and let apidefs2/conflodis2 own 100% of encoding. Then
`conflodis2-json-text` loses its branch, there is one encoder instead of five, and
`render-json` has a single job — *which fields, which names, which types*. The name
becomes slightly wrong at that point; that is a rename, not a redesign.

**Scope warning.** This is a SHARED-CORE change: ~7 methods across warehouse, products,
customer and the ping route. Do not fold it into the vendor work. Both smoke suites
must be re-run afterwards.

**`render-html` is a different case and stays regardless.** There is no apidefs2 HTML
layer; the UI is its consumer, and it carries the same split-contract smell for the
same reason.

**Either way the generic function stays.** Deleting it would silently break ten
methods rather than removing them.

---

## 12. SESSION 2026-09-14 — status, findings, and the shipping/payment design

### 12.1 Where the vendor API stands (end of 2026-09-14)

**Seven commits, all unpushed** (`ahead 7` of
`origin/cus/feat/tax123-order-with-taxes`):

| Commit | What |
|---|---|
| `9b1cd12` | the vendor API CONTEXT file |
| `a689bdc` | resumption order set to API design → tests |
| `4196972` | **fix**: `copyVendor-dbtodomain` declared the VIEW-CLASS slots while its destination is `nst-vnd` — ten `vnd-` fields were free variables |
| `07a5066` | `escape-like-wildcards` moved to `core/dod-bl-utl.lisp` (it was in a warehouse file, called by three entity layers, two of which load earlier) |
| `5ae87cb` | the `render-json` decision recorded (§11) |
| `50ac635` | **the vendor profile API surface** — 5 verbs, 5 action routes, 5 bindings |
| `5ba1f70` | **SECURITY**: `*read-eval* nil` on the shipping-zone read |

**Built and committed:** `vendor/nst-dal-vnd.lisp` (nst-vnd + boundary models),
`vendor/nst-bl-vnd.lisp` (6 प्रत्यय + copiers + reverse ferry),
`vendor/nst-bl-vndapi.lisp` (routes + bindings), plus the `dod-vend-profile`
`username`/`fullname` slots in `vendor/dod-dal-ven.lisp`.

**What is genuinely verified:** the live schema; that `USERNAME` blocked every INSERT
until the slot was added (error 1364, reproduced); column coverage 44/44; the response
model's secret exclusion; the 1:1 map from response slots → `domain->response` →
`render-json` (35/35/35); structure of every new file (top-level form count, depth 0);
and the `read-eval` guard (proven — see §12.2).

The 1364 reproduction, since STATUS.md points here for it — run against the live
database and ROLLED BACK, so it proves the refusal without writing anything. It is
also what proved `dod-vend-profile` could not insert at all before the slot was added:

```sql
START TRANSACTION;
INSERT INTO DOD_VEND_PROFILE (NAME,ADDRESS,PHONE,PASSWORD,TENANT_ID)
  VALUES ('ZZTMP','ZZTMP','0000000000','x',2);
ROLLBACK;
-- ERROR 1364 (HY000): Field 'USERNAME' doesn't have a default value
```

**What is NOT verified — the headline.** **No vendor verb has ever been called.**
`?exists`, `make`, `fetch`, `!update`, `delete!` and `enumerate` have never run
against a database. Nothing has been fetched, written or rendered.

### 12.2 🚨 THE `read-from-string` CLASS — a second, larger RCE family

Found while designing shipping. **This is not one bug, it is a pattern**, and it is
still only partly fixed.

The tree uses `read-from-string` as a **deserialiser for structured data held in text
columns**. `read-from-string` invokes the reader, and `*read-eval*` defaults to `T`, so
`#.` is **evaluated**.

| Site | Data | Written by | Status |
|---|---|---|---|
| `shipping/dod-bl-osh.lisp:137` `zipcoderangecsv` | vendor | vendor UI | ✅ **FIXED `5ba1f70`** |
| `shipping/dod-bl-osh.lisp:74-80` `RATETABLECSV` — **7 calls** | vendor | vendor UI | ❌ **OPEN** |
| `vendor/dod-ui-ven.lisp:2429` `invoice-settings`, executed **at login** | vendor | vendor UI | ❌ **OPEN** |
| `vendor/dod-ui-ven.lisp:2457` the session copy of it | — | — | ❌ **OPEN** |
| `core/dod-ui-utl.lisp:113` **`safe-read-from-string`** — 18 call sites | vendor | products/invoice UI | ❌ **OPEN** |

**`safe-read-from-string` IS NOT SAFE.** It wraps `read-from-string` in a
`handler-case` that catches PARSE ERRORS and never binds `*read-eval*`. Proven:

```
(safe-read-from-string "#.(+ 40 2)")  =>  42
```

The name is worse than useless — it is actively misleading at 18 call sites, all on
`images-str` image columns.

**Why this is a BLOCKER for the vendor work, not a side-quest:** two of the open sites
are columns this API writes.

* **`RATETABLECSV` is the shipping rate table.** `nst-vnd-ship`, the entity §12.3
  designs, writes it. A CSV cell containing `#.(...)` executes on the next checkout.
* **`invoice-settings` is already writable through the `nst-vnd` `!update` that
  `50ac635` shipped.** It is not in `*vendor-update-forbidden-fields*`, so the vendor
  API ALREADY exposes a column that `dod-ui-ven.lisp:2429` evaluates at that vendor's
  next login.

**The fix, and why it is small:** binding `*read-eval* nil` inside
`safe-read-from-string` repairs **18 call sites in one edit**, and cannot break
legitimate data — no real value contains `#.`. Then three direct sites (the 7 rate-table
reads, and both `invoice-settings` reads).

**A warning about the guard, learned the hard way this session:** keep the reader, do
not replace it with a naive splitter. The stored values are lists of **REGEX FRAGMENTS**,
not digit prefixes — live rows contain `(577* 560001 …)`, `(0)`, `()`, and an embedded
newline — and each token is used as `(format nil "^~A" token)`. A splitter silently
changes which zones match. Replacing the reader is a follow-up needing a test over all
20 live rows.

### 12.3 The shipping + payment design — SETTLED, not yet built

**Entities.** Two are SINGLETONS per vendor; the DB enforces neither.

| Entity | Table | Rows | Shape |
|---|---|---|---|
| `nst-vnd` *(exists)* | `DOD_VEND_PROFILE` | 15 | credentials, `shipping_enabled`, `upi_id` |
| `nst-vnd-ship` | `DOD_SHIPPING_METHODS` | 6 | shipping config (below) |
| `nst-vnd-shipzone` | `DOD_VENDOR_SHIP_ZONES` | 20 | `zonename`, `zipcoderangecsv` — a COLLECTION |
| `nst-vnd-pay` | `DOD_VPAYMENT_METHODS` | 5 | **5 flags only** |

**`DOD_SHIPPING_METHODS` — the vendor's shipping configuration:**

| Concept | Column |
|---|---|
| FREE (above a threshold) | `FREESHIPENABLED` + `MINORDERAMT` `decimal(7,2)` |
| per ORDER vs per LINE ITEM | `FLATRATETYPE` = **`ORD`** \| **`ITM`**, with `FLATRATEPRICE` |
| weight × zone matrix | `TABLERATESHIPENABLED` + `RATETABLECSV` |
| external partner | `EXTSHIPENABLED` + `shippartnerkey` / `shippartnersecret` (**SECRETS**) |
| store pickup | `STOREPICKUPENABLED` |
| default | `defaultshippingmethod` = `FSH` \| `FRS` \| `TRS`, **NULL on 1 of 6 rows** |

`ORD` charges `FLATRATEPRICE` once; `ITM` charges it × item count (`dod-ui-cus.lisp:2922`).
`RATETABLECSV` is a `MIN,MAX,ZONE-A…ZONE-E` matrix read via `cl-csv`. **Its column names
ARE rows in `DOD_VENDOR_SHIP_ZONES`** — deleting or renaming a zone silently corrupts
every weight band, and nothing enforces the link. That is the most valuable law this
API could add.

**`DOD_VPAYMENT_METHODS` holds FLAGS ONLY** — `codenabled`, `upienabled`,
`payprovidersenabled`, `walletenabled`, `paylaterenabled`.

**THE CREDENTIALS ARE ALREADY ON `nst-vnd`** — `PAYMENT_API_KEY`, `PAYMENT_API_SALT`,
`PAYMENT_GATEWAY_MODE`, `UPI_ID`. Confirmed by the user and by the live table. So
`vendor/payment/gateway` and `vendor/payment/upi` are largely `!update` on `nst-vnd`,
and `DOD_VPAYMENT_PROVIDERS` (0 rows, referenced **nowhere** in the Lisp tree) is NOT
needed. They are already excluded from `VendorResponseModel`.

**Decisions taken (user-confirmed):**

1. **Singletons are 0-or-1 collections keyed by row-id**, with `?exists` on
   `(vendor-id, tenant)` and a `make` that refuses a duplicate. The standard six
   प्रत्यय work unchanged; `enumerate` returns 0 or 1 rows.
2. **The vendor row is authoritative** for gateway credentials.
3. **Vendor identity goes on the existing `actor` slot of `domain-ctx`.** Confirmed
   as viable: **`domain-ctx-actor` is read NOWHERE in the tree** — zero consumers — so
   reusing it costs nothing. The session does hold `:login-vendor` (the vendor OBJECT)
   and `:login-vendor-id` (the integer); `conflodis2-actor` currently ignores both and
   returns `:login-user` / `:login-user-role-name`.
   **Why this matters:** without it, `vendor-id` would come from the request, and
   **vendor X could read/write vendor Y's config inside the same tenant** — intra-tenant
   BOLA, which tenant scoping does NOT cover. The legacy UI dodges this by calling
   `(get-login-vendor)` from the hunchentoot session inside its controllers; route verbs
   are Tier-2 and must not do that.
4. **The secret lockout SPLITS** (decided, **not yet implemented**):
   `*vendor-update-forbidden-fields*` becomes `(:password :salt)` only. The
   `payment-*` fields become updatable — they are vendor-configurable and the web form
   writes them today. `password`/`salt` stay refused: letting a generic field update
   rotate the LOGIN credential without the current one is an account-takeover
   primitive, not a config edit.

5. **`shipping_enabled` lives on the VENDOR row**, not on `DOD_SHIPPING_METHODS`
   (confirmed: `dod-ui-ven.lisp` does `(setf (slot-value vendor 'shipping-enabled) …)`).
   Saving shipping config is therefore a cross-entity write.

### 12.4 The image state — check this before trusting anything

A load DID succeed on 2026-09-14 at 17:20-17:21, resolving the morning abort
(§8.1): `vendor/nst-bl-vnd.fasl` and `warehouse/nst-bl-warehouse.fasl` are both in the
app's ASDF cache now, and the warehouse entries were stale since Sep 13 07:57 before
that.

**BUT `vendor/nst-bl-vndapi.fasl` exists ONLY beside its source** (written 17:22:51,
after the load) and has **0 entries in the app's cache**. Per §8.1 the app loads from

```
/home/hunchentoot/.cache/common-lisp/sbcl-2.6.8-linux-x64/home/ubuntu/ninestores/hhub/
```

so a fasl beside the source does not reach the image. **The vendor routes are therefore
very likely NOT registered.** Verify before trusting any endpoint:

```lisp
(list-api-routes)      ; expect 5 warehouse + 5 product + 5 vendor rows
(list-action-routes)   ; expect route-vendor-* among them
```

### 12.5 Next steps, in order

1. **The `read-from-string` sweep** (§12.2) — the `safe-read-from-string` one-liner
   (18 sites) plus the three direct sites. **Do this BEFORE building shipping**, because
   `nst-vnd-ship` writes `RATETABLECSV`.
2. **Verify the image** (§12.4) — `(asdf:load-system :nstores)` and `(list-api-routes)`,
   then CALL the read verbs (`?exists`/`fetch`/`enumerate`). They have never run.
3. **Build `nst-vnd-ship` + `nst-vnd-shipzone`** (§12.3).
4. **Build `nst-vnd-pay`** — flags only.
5. **Implement the lockout split** (§12.3 decision 4).
6. **Put the vendor on `domain-ctx`'s `actor`** before any vendor-scoped route binds.
7. Then the 4xx taxonomy (§7.2), then tests (§10 step 2).

**And the standing rule:** compile-time success is not evidence. Today added two
proofs — a copier that compiled with ten warnings and would have failed on the first
fetch, and a helper named `safe` that executes arbitrary code.
