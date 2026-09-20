# Vendor API — the `t` trap, resuming, and the 2026-09-14 session · CONTEXT

**Split out of `nst-bl-vndapi-CONTEXT.md` on 2026-09-20** for the 400-line budget.
Section numbers are preserved from the parent. **Content is unchanged.**

**Covers the operational and temporal material**, as opposed to the durable design
context that stayed in `nst-bl-vndapi-CONTEXT.md`:

* §9 — the `t` trap, restated for the vendor work because it will recur.
* §10 — how to resume: Step 0 (one form, before anything else), Step 1 (API design),
  Step 2 (tests), Step 3 (then, and only then).
* §12 — SESSION 2026-09-14: where the vendor API stands (§12.1), the
  `read-from-string` RCE class (§12.2), the shipping + payment design, SETTLED but not
  built (§12.3), the image state (§12.4), and next steps in order (§12.5).

**Read this when:** you are picking the vendor work back up, or you need the
shipping/payment design.

**Companions:** `nst-bl-vndapi-CONTEXT.md` (status, schema, architecture, decisions),
`vendor-render-json-contract-CONTEXT.md`, `knowledge-conjoin-CONTEXT.md`.

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
