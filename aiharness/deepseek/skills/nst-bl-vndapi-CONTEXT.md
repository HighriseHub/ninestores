# nst-bl-vndapi — Vendor profile on conflodis2 + apidefs2 · CONTEXT

**Read this when:** you are touching the vendor profile API — its status, schema,
architecture, प्रत्यय layer or decisions. §0 states plainly what has and has not run;
the operational half (resuming, the shipping/payment design) is in
`vendor-api-sessions-CONTEXT.md`.

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

## Where the rest of this material went

This file was split on **2026-09-20** to stay inside the 400-line budget (README ·
*The daily size cycle*). Nothing was deleted. Section numbers were preserved so the
references above still resolve.

| was | now lives in |
|---|---|
| §9–10, §12 — the `t` trap restated, how to resume, the 2026-09-14 session | `vendor-api-sessions-CONTEXT.md` |
| §11 — `render-json` stays in adhara (settled) | `vendor-render-json-contract-CONTEXT.md` |

Unrelated to the split, but worth knowing: the vendor work has since grown a pricing
analogue — see `nst-bl-prdpricing-CONTEXT.md`.
