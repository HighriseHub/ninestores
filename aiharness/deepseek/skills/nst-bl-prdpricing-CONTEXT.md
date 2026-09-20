# nst-bl-prdpricing — the product pricing entity and its API

**Covers:** `DOD_PRODUCT_PRICING` as a domain entity — the `nst-prd-pricing`
प्रत्यय file, the master-cache sync that keeps `DOD_PRD_MASTER.CURRENT_PRICE` in
step, the boundary models, and the still-unbound pricing endpoint.

**Read this when:** you are writing or debugging anything that sets a product's price,
discount, or discount window; when adding the `PUT …/pricing` route; when a
product's catalogue price disagrees with its pricing row; or when a change to
`nst-bl-prdpricing.lisp` seems not to take effect.

**Verified:** 2026-09-20, against the working tree (not the running image — see §0).

> Line numbers rot. Every reference below was measured on 2026-09-20 and the file
> was **1070 lines** at that moment. Re-check before trusting.

---

## 0. Status — now PROVEN against the live database

This is the single most important section, because this file has a standing rule
of its own (`nst-bl-prdpricing.lisp:7-11`) that two recorded incidents earned:

> *compile-time success is NOT evidence. Call the प्रत्यय before trusting any of this.*

**As of 2026-09-20 the rule has been satisfied**: `test/smoke-products-api.sh
--write` ran against the live server and passed **34/34**, and the result was then
confirmed by reading the two rows straight out of MySQL rather than trusting the
API's own response.

| fact | status on 2026-09-20 |
|---|---|
| `nst-bl-prdpricing.lisp` wired into `nstores.asd:151` / `compile.lisp:203` | **true** — compiles BEFORE `nst-bl-prdapi` (§7) |
| the file compiles | **true** (§6) |
| the pricing HTTP endpoint exists | **true** — `PUT /hhub/api/v1/catalog/products/{id}/pricing` (§9) |
| `set-product-pricing` has a caller | **true** — `route-product-update-pricing` |
| every pricing verb has RUN against the live DB | **true** — 2026-09-20, smoke `--write`, plus a direct SQL read (§9.3) |
| the two-row master-cache sync is real | **true** — measured, not inferred (§2) |
| the ABAC policy/transaction rows are applied | **true** — migration `20092026-insert-product-pricing-policies` (§9.2) |

🚨 **RUNNING IS NOT THE SAME AS ENFORCED.** The ABAC rows now exist and are linked,
but the PEP seam that reads them (`*action-route-transaction-function*`) is still a
pass-through stub, so **no authorization happens on any API call** — pricing
included. See `ABAC-policy-transaction-CONTEXT.md` §7.

Do not describe any of this as working. The verbs, the sync, the reverse ferry and
the defaults are all *written and compiled*, and that is the whole of the claim.

---

## 1. The mechanism in one paragraph

`DOD_PRODUCT_PRICING` is shaped like a price schedule but is a **SINGLETON PER
PRODUCT**: 83 live rows across 83 distinct `PRODUCT_ID`s, zero products with two
rows (measured 2026-09-19, recorded at `nst-bl-prdpricing.lisp:31-37`). So
`(product-id, tenant-id)` **is** the entity's identity, and every verb addresses a
pricing row by its **product-id**, never by the row's own `ROW_ID` — a client has
no way to learn a row-id, because there is no addressable collection. The row-id is
*published* in responses and never *accepted* as input.

`DISCOUNT` is a **percentage** (0–100; all live rows sit in 0.00…10.00), not a
rupee amount. The window `DiscountStart … DiscountEnd` is the period the discount
**runs**, and outside it the discount is **expired, not zero** — the checkout
already reads it that way (`vendor/dod-ui-ven.lisp:560`).

---

## 2. THE MASTER-CACHE SYNC — the trap this entity exists to close

`CURRENT_PRICE` / `CURRENT_DISCOUNT` live **twice**: on the pricing row and,
denormalised, on `DOD_PRD_MASTER`. The master copy is what the catalogue filter,
the whitelisted `:current-price` sort and the cart read. If the two drift, a
product advertises a price nobody can buy it at.

`prdpricing-sync-product-cache` (`:404`) is the **one writer** of the master copy.
It is called from **both** entity verbs, so both paths sync:

| path | call site |
|---|---|
| create | `make` → `:534` |
| update | `!update` → `:671` |

`set-product-pricing` does **not** call the sync itself; it calls `make`/`!update`
and inherits it. That is why grepping `set-product-pricing` for the sync finds
nothing — **this misled a reader once already.**

Two details that make the design stronger than the legacy controller it replaces
(`vendor/dod-ui-ven.lisp:340-370`, reached from
`/hhub/hhubvendprodpricingsaveaction`, registered at `sysuser/dod-ui-sys.lisp:1127`):

- The legacy controller wrote the two master slots **after** the pricing write, in
  the UI layer, with no transaction — so any other caller silently skipped it.
- The new sync runs **inside** `set-product-pricing`'s `clsql:with-transaction`
  (`:853` of the pre-2026-09-20 file; see §7), and a failed sync **rolls the pricing
  row back** rather than committing a price the catalogue disagrees with.

`prdpricing-sync-product-cache` distinguishes its answers honestly: `nst-prd`'s
`!update` returns **the entity, not T** on success, so the helper tests
`(typep cache 'nst-prd)` and otherwise passes the product verb's own Belnap
sentinel through unchanged.

**`delete!` deliberately does NOT sync** (`SECTION 7`, `:683`). Soft-deleting a
pricing row leaves the product still advertising its last cached price. That is
argued for in the file (the cache is a cache); it is the one place the cache drifts
**by design**, so do not "fix" it without reading that section.

---

## 3. Defaults and partial updates — read `set-product-pricing`'s docstring first

`set-product-pricing` (`:833`) is the aggregate verb and the intended entry point
for the API. Its docstring is the authority on what a **missing key** means, and
the answer differs by path:

- **update path** (a row exists): a missing key means **leave it alone**.
- **create path** (no row yet): a missing key means **take the house default** —
  `price` 1.00, `discount` 0.00, window `today … today+90 days`, currency from the
  account. All four are copied from what `create-product`/`nst-prd/make` already
  write (`dod-bl-prd.lisp:985-995`), so the two rows still agree at birth.

Both paths now build **one `supplied` arg list** (`:888`) containing only the keys
the caller actually stated, and the create path appends defaults via `(unless …)`
(`:908`).

🚨 **This was broken until 2026-09-20.** The update path passed all five keys to
`!update` unconditionally, so an omitted `:price` arrived as `NIL`,
`reinitialize-instance` set the slot to `NIL`, and `prdpricing-validate-price`
refused the row for having no price — **a partial update could not be expressed at
all**, and an omitted `:discount` was written as `NULL` rather than left alone. The
create path beside it had filtered with `(when …)` since it was written. If you
find a similar `(!update … :a a :b b)` shape elsewhere, check it the same way.

**NIL must never reach a validator.** `prdpricing-validate-price` and
`prdpricing-validate-window` both treat `NIL` as "required and missing" and signal.

---

## 4. The laws MySQL does not enforce (`SECTION 2`, `:192`)

No foreign key on `PRODUCT_ID` (and the column is nullable despite the view class
claiming `:NOT-NULL`), no unique key, no check constraint, no `NOT NULL` on the
window or currency. Everything is enforced in Lisp:

| law | function | rule |
|---|---|---|
| price | `prdpricing-validate-price` `:217` | > 0. 0 is **refused**, not stored — a zero price is more likely a failed upload than a giveaway |
| discount | `prdpricing-validate-discount` `:231` | percentage 0–100; `NIL` passes through and means "never stated", which is **not** the same as 0.00 |
| window | `prdpricing-validate-window` `:249` | end ≥ start; accepts CLSQL dates **or** `DD/MM/YYYY` strings via `get-date-from-string`. A reversed window is refused because it would make the discount expired on every day |
| expiry | `prdpricing-window-contains-p` `:274` | the **one** predicate the checkout and the API both use |

---

## 5. The reverse ferry (`SECTION 10`, `:932`) — and why it was missing

The boundary classes live in `dod-dal-prd.lisp` — `ProductPricingRequestModel`
(`:984`, slotless) and `ProductPricingResponseModel` (`:1014`, eight declared
slots) — and **both docstrings claim the ferry lives in `nst-bl-prdpricing.lisp`**
(`dod-dal-prd.lisp:1049`, `:978-981`).

**It did not exist.** Before 2026-09-20 there was no `domain->response` for
`nst-prd-pricing` nor `render-json` for `ProductPricingResponseModel` anywhere in
the tree. The classes were declared, the verbs returned entities, and
`action->response` (`conflodis2` §4) would have reached `domain->response` with
**no applicable method** — a 500 at the last hop, *after* the database had already
been written.

Added in `SECTION 10`:

- `domain->response` (`:959`) — 8 slots across; `tenant-id`/`prc-company` have no
  field to receive them.
- `prdpricing-date->string` (`:987`) — CLSQL date → `DD/MM/YYYY`, or `nil`.
- `prdpricing-response-discount-expired-p` (`:1001`) — **derived**, never stored.
- `render-json` (`:1022`) — the allowlist: `rowId productId price discount
  currency startDate endDate active discountExpired`.

**Do not define the sentinel or `(eql t)` methods here.** They are already
**entity-generic** in `warehouse/nst-bl-whsapi.lisp:280-299`, specializing on the
sentinel *classes* — so 404/409/503 fall out for free, and redefining them would
silently replace the warehouse's version. The same rule is recorded for products
at `dod-bl-prd.lisp:1419-1437`.

Two conventions worth keeping:

- **Dates go out in the format they come in.** `DD/MM/YYYY` is what
  `get-date-string` (`dod-bl-utl.lisp:603`) publishes and what
  `get-date-from-string` (`dod-bl-utl.lisp:537`) parses — exactly what
  `prdpricing-validate-window` accepts inbound. Any other format makes a value the
  client read impossible to write back.
- **`discountExpired` is published with no slot backing it.** That is the model's
  own instruction (`dod-dal-prd.lisp:1090-1099`): a stored boolean goes stale at
  midnight. It is derived from two fields already in the allowlist, so it leaks
  nothing.

---


---

## 6–8. Build and load — moved out

The three sections that stood here were about the **build harness**, not about
pricing, and they were needed by every file in the tree rather than this one. They
moved to `build-and-load-CONTEXT.md` on 2026-09-20 to stay inside the 400-line
ceiling, keeping their numbers and their content:

| was | now lives in |
|---|---|
| §6 — recipe: compile-check WITHOUT the running image | `build-and-load-CONTEXT.md` |
| §7 — the `compile.lisp` traps, and which build the server serves | `build-and-load-CONTEXT.md` |
| §8 — `clsql:file-enable-sql-reader-syntax` is mandatory | `build-and-load-CONTEXT.md` |

Read that file first whenever a change appears not to have taken effect.
## 9. The pricing endpoint — BUILT and RUNNING (2026-09-20)

```
PUT /hhub/api/v1/catalog/products/{id}/pricing
```

Bound as `route-product-update-pricing` in `products/nst-bl-prdapi.lisp`, with a
`register-action-route` (request-class `ProductPricingRequestModel`) and a
`register-api-route` (`:method :put`, `:path-params '(("id" . :row-id))`,
`:success-status 200`, `:auth-scope :session`).

Body, camelCase **or** hyphenated — both verified, not assumed:
`api-camel->lisp-name` (`core/nst-bl-apidefs2.lisp:266`) turns `startDate` and
`start-date` alike into `:START-DATE`, for body keys and query keys
indistinguishably. Fields: `price`, `discount`, `start-date`, `end-date`,
`currency`.

**UPSERT.** A product with no pricing row gets one; a product with one gets a
partial update. A client cannot tell the two apart, and does not need to.

**An empty body is a 400**, following `route-product-update-shipping` — a write
that did not happen must not report success. ⚠ Consequence worth knowing: because
at least one field is always required, the create-path defaults (§3) are reachable
from REPL and legacy callers but **not** from this endpoint. A client that says
nothing about a price has not asked for 1.00.

### 9.1 The conditions, and why there are two of them

`prdpricing-validation-error` was added to `nst-bl-prdpricing.lisp` on 2026-09-20,
signalled by the SECTION 2 validators (12 call sites converted; the `:U`/`:F`/`:C`
knowledge guards deliberately still raise plain `ERROR`). The route catches exactly
that condition and re-raises `api-client-error` → **400**.

That distinction is load-bearing rather than decorative. Catching plain `error` in
the route would make a malformed value (the client's fault, 400) indistinguishable
from a lost database connection (503) and from `"Unrecognized bo-knowledge-truth"`
(a real bug, 500) — reporting all three as a bad request and hiding the two that
need a human. Same shape as `prd-shipping-validation-error` (`dod-bl-prd.lisp:644`).

🚨 This endpoint does **not** inherit the platform-wide gap recorded at
`core/nst-bl-apidefs2.lisp:326-329`, where a bad query *value* still surfaces as a
500 because "the domain-validation condition taxonomy is still unfinished". The
conversion happens in the route, not through a global taxonomy, so the pricing
path is unaffected. Do not "simplify" it by deleting the handler-case.

### 9.2 Constraints that fell out of the design

- The route **cannot** use `request->dispatch`: `set-product-pricing` takes a
  **positional** product-id plus `&key`, so the ferry's
  `(request verb entity-class ctx)` shape cannot address it — the same reason
  `route-product-update-shipping` (`nst-bl-prdapi.lisp:175`) calls its verb
  directly. **The explicit allowlist is the point**: the generic ferry MOP-filters
  against *every* initarg, which for `nst-prd` was a mass-assignment hole.
- The path param arrives as `:row-id` via `rm-row-id`
  (`core/nst-bl-adhara.lisp:228`) and is passed as the **product-id**.
- **No `with-vend-session-check` and no `with-hhub-transaction` in the verb.**
  Session/tenant comes from the credential at ring 4 (`nst-bl-apidefs2.lisp:383-394`,
  `api-route-auth-scope :session`), which replaces the legacy macro; ABAC plugs in at
  the single seam `*action-route-transaction-function*`
  (`nst-bl-conflodis2.lisp:258-265`), whose v1 default is a pass-through.
  `clsql:with-transaction` inside `set-product-pricing` is a **different** thing —
  database atomicity for the two-row write — and must stay there.
- **An ABAC policy + transaction pair IS seeded for this endpoint** (2026-09-20),
  as its own migration `20092026-insert-product-pricing-policies` — separate
  because the product one was already applied and never re-runs. Not applied to
  any database yet, and inert until the seam above is bound. Full reasoning:
  `ABAC-policy-transaction-CONTEXT.md` §9 traps 13–14 and §12.
- On the **update** path an omitted key means *leave it alone*, **not** *reset to
  the 1.00 default* — otherwise a PUT touching only the discount would reset a ₹499
  price. This is the design decision that survived; the "400 or 200 on an empty
  body" question listed here previously was settled as **400**.
- `nstoresapi.html:136` already listed this endpoint in the design surface.

### 9.3 How to test it — and the 2026-09-20 RESULT

`test/smoke-products-api.sh`, section 6b, gated behind `--write`. It creates a
product, then:

| check | asserts |
|---|---|
| PUT all five fields | 200 |
| **GET the product** | master `currentPrice` followed — the two-row sync, the failure a pricing-row-only test would miss |
| PUT `{"discount":9.99}` (camelCase, partial) | 200, and **the price is still there, not reset to 1.00** |
| PUT `{"price":0}` / `{"discount":150}` / reversed window | **400, not 500** |
| PUT `{}` | 400 |
| PUT on product 999999 | 404 |

Price is a whole number so the JSON encoder cannot render it as `98765.000000001`
and make an exact substring match a coin flip.

**RESULT — all 34 checks passed, and the two rows were then read straight out of
MySQL rather than trusted from the API response:**

```
DOD_PRD_MASTER   row 124 : CURRENT_PRICE 98765.00  CURRENT_DISCOUNT 9.99   deleted_state Y
DOD_PRODUCT_PRICING row 85 : PRICE 98765.00  DISCOUNT 9.99  INR  2020-01-01 .. 2030-12-31
```

Four things that only a database read proves, now proven:

1. **The sync is real.** Master `CURRENT_PRICE` == pricing `PRICE`, both `98765.00`
   — the same number in both tables, which is the whole point of the feature.
2. **The partial update really is partial.** The second PUT sent `{"discount":9.99}`
   alone; the price survived at `98765.00` and was **not** reset to the 1.00
   default. This is the §3 bug, fixed and now demonstrated on live data rather
   than argued.
3. **The 400s rolled back.** After the rejected `price:0`, `discount:150` and
   reversed-window calls, the stored window is still `2020-01-01 .. 2030-12-31`
   and the price unchanged — `prdpricing-validation-error` escaping
   `clsql:with-transaction` unwinds it, as §9.1 claims.
4. **`delete!` still does not touch the pricing row** — master `deleted_state Y`,
   pricing row `deleted_state N`. The §2 asymmetry, confirmed rather than assumed.

**Shipping was exercised for the first time in the same run** (§9.4): all four
dimensions persisted, `32767/20/10/5.50`, and every refusal returned 400.

### 9.4 The shipping section (6c), added 2026-09-20

`PUT …/products/{id}/shipping` is a **different endpoint** — the four `shipping_*`
columns on the product master, not the vendor shipping *entity* (`nst-vnd-shp`,
which has its own `smoke-vendor-shipping-api.sh`). It had **no test at all** until
this one, despite being the template the pricing route copied.

The successful write deliberately uses **32767, the exact `smallint` ceiling**: it
tests the boundary in the permissive direction, and it is distinctive enough that
the read-back substring cannot collide with a row-id or a timestamp. Verified in
the DB above. The fractional case (`30.5 cm` → 400) is the one worth keeping —
`SHIPPING_*_CMS` is `smallint`, so silent truncation is the quiet data loss the
validator refuses by name.

**Known cosmetic staleness:** the script's section 4 still prints *"expect 500
today"* for a bad `?sort-by`; the observed answer is now **503**. That is the
platform-wide taxonomy gap (`core/nst-bl-apidefs2.lisp:326-329`), not a pricing
issue — and 503 is arguably worse than 500, because it invites a retry.

---

## 10. Related requirement — setting the account currency

Recorded 2026-09-20 as a **requirement only**, at
`hhub/core/nstoresapi.html` (the `PUT /api/v1/admin/account/currency` entry in the
Tenant-administration domain).

`get-account-currency` exists (`account/dod-bl-cmp.lisp:12`) and derives the
currency from the account's `country` via the cached currency table, falling back
to `*HHUBDEFAULTCURRENCY*`. **There is no writer**, so a tenant cannot change its
currency after provisioning.

A `set-account-currency` in the same file would need more than a setter: it needs
persistence on the company row and an audit trail, and it must answer whether the
change is a one-way switch at onboarding or a **live re-denomination of existing
prices** — every product priced in the old currency keeps its stored number. Those
are different endpoints.

---

## 11. File map

| file | what is there |
|---|---|
| `products/nst-bl-prdpricing.lisp` | the प्रत्यय — 1070 lines, SECTIONS 1–10 |
| `products/dod-dal-prd.lisp` | `nst-prd-pricing` class `:616`; `ProductPricingRequestModel` `:984`; `ProductPricingResponseModel` `:1014` |
| `products/dod-bl-prd.lisp` | `nst-prd` verbs; `domain->response`/`render-json` for products `:1417-1568`; `create-product` seeds the first pricing row `:985-995` |
| `products/nst-bl-prdapi.lisp` | product routes; `route-product-update-shipping` `:175` is the template for the pricing route |
| `account/dod-bl-cmp.lisp` | `get-account-currency` `:12` |
| `vendor/dod-ui-ven.lisp` | the legacy controller `:340-370`; `dod-reset-vendor-products-functions` `:2725` (vendor-UI cache only — no domain-layer memoization exists) |
| `core/dod-bl-utl.lisp` | `get-date-from-string` `:537`, `get-date-string` `:603` |
| `core/dod-ui-utl.lisp` | `response-id-string` `:913`, `with-vend-session-check` `:836`, `with-hhub-transaction` `:947` |
| `core/nst-bl-conflodis2.lisp` | `action->response` `:182`; ABAC seam `:258-265` |
| `warehouse/nst-bl-whsapi.lisp` | entity-generic sentinel responses `:280-299` |
| `package/compile.lisp` | file list `:105+`; prdpricing at `:203`; driver return `:419-420` |
| `test/smoke-products-api.sh` | smoke script; **no pricing section yet** |
