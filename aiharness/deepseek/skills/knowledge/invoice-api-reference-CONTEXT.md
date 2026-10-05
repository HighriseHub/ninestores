# SKILL: The invoice API — endpoints, addressing, shapes and the load-order traps

**Read this when:** you are designing, wiring or debugging an invoice API route — "which of the
spec's twelve endpoints exist", "`{id}` answered 409 where I expected 404", "which producer emitted
this error body", "why does `/download` answer 302", "why did adding an invoice binding, or loading
a file into the image, wedge the process".

**Status:** the DURABLE half of `../invoice-api-handoff-CONTEXT.md` (state of play there); split out
**2026-10-05**. Facts carry their own dates — nearly all **2026-09-26** — and none was re-measured.

**Applies to:** `hhub/invoice/nst-bl-invhapi.lisp`, `hhub/invoice/nst-bl-invitmapi.lisp`, the
id-less settings binding in `hhub/vendor/nst-bl-vndapi.lisp`, and the `nst-bl-conflodis2` /
`nst-bl-apidefs2` seam they run on.

---

## 1. The twelve spec endpoints, and which ten are bound

Spec: `hhub/core/nstoresapi.html` — a JS table `{m,p,d}`; grep for `id:'inv'` (12 Invoicing
endpoints, domain `id:'inv'`, role Vendor). The bound/unbound state of play is the handoff §4.

| Spec endpoint | Bound? | Route |
|---|---|---|
| `POST /api/v1/invoices` (201) | ✅ | `route-invh-create` |
| `GET /api/v1/invoices` | ✅ | `route-invh-list` |
| `GET /api/v1/invoices/{id}` | ✅ | `route-invh-detail` (the aggregate read, §3) |
| `PUT /api/v1/invoices/{id}` | ✅ | `route-invh-update` |
| `POST /api/v1/invoices/{id}/items` (201) | ✅ | `route-invitm-create` |
| `PUT /api/v1/invoices/{id}/items/{item-id}` | ✅ | `route-invitm-update` |
| `DELETE /api/v1/invoices/{id}/items/{item-id}` | ✅ | `route-invitm-delete` |
| `PUT /api/v1/invoices/settings` | ✅ | `route-invh-settings-update` — **BOUND 2026-09-26** (handoff §6.7), in `vendor/nst-bl-vndapi.lisp`, delegating to the same `!settings` प्रत्यय the vendor sub-resource uses |
| `POST /api/v1/invoices/{id}/payment` | ❌ | a different कर्म — no प्रत्यय exists (handoff §6.4) |
| `POST /api/v1/invoices/{id}/send` | ❌ | actor model, not a domain verb (handoff §6.5) |
| `GET /api/v1/invoices/{id}/download` | ✅ | `route-invh-download` — **BOUND 2026-09-26** (§4.1), a 302 to the rendered file |
| `GET /api/v1/invoices/{id}/public` | ✅ | `route-invh-public` — **BOUND 2026-09-26** (§4.2), returns the shareable link |

Also registered but deliberately unbound: `route-invh-delete` (the spec defines no invoice DELETE
— consistent with the DRAFT-only rule) and `route-invh-fetch-by-invnum` (the read that can answer
`:C`; the spec has no endpoint for it).

---

## 2. THE URL ADDRESSES AN INVOICE BY ITS NUMBER (decided 2026-09-26)

**All seven invoice bindings map their `{id}` segment to `:invnum`** — the human-readable invoice
number (`NST00023-2024`) — not the surrogate `ROW_ID`. `{item-id}` stays the LINE's row-id: a line
has no readable key, and inventing one (a per-invoice sequence) is a decision nobody has taken.

* **The number is unique** (index `INVNUM`, `NON_UNIQUE=0`) and **immutable over HTTP**, which is
  what makes it a safe address: it is the domain's backbone key — the vendor reads it, the customer
  quotes it, the GST return carries it.
* **🚨 THE RESOLUTION IS IN THE ROUTE LAYER, AND IT HAS TO BE.** The verbs specialize on
  `(id string)`, and a number and a row-id are BOTH strings — CLOS dispatches on type, so no verb
  method can tell them apart. `invh-header-from-url` / `invh-request-with-header-row-id`
  (`invoice/nst-bl-invhapi.lisp`) resolve once per request; the verbs stay row-id-keyed.
* **It answers the VERB'S four-valued result**: a number held by a SOFT-DELETED invoice is `:C` →
  **409**, not 404 — the number is consumed and the row is present, so 'no such invoice' is false.
* **The number cannot be DERIVED from the row-id.** The trigger stamps `year(now())` at INSERT
  time, so a 2024 row and a 2026 row at the same position differ. Every fixture reads it from the
  table (`invnum-of` in the dispatch harness, `__inv` in the suite).
* ⚠ **BREAKING, deliberately:** `/invoices/23` no longer resolves. Nothing consumed the numeric
  form (the API was days old), so "accept both" was rejected for one unambiguous address.

### 🚨 A BODY-SUPPLIED `invnum` IS STRIPPED, NOT REFUSED — and it CANNOT be refused

`api-params-for-request` merges the PATH parameters and the JSON body into **one** params plist, so
the `:invnum` naming the invoice in the URL is indistinguishable from an `:invnum` a client put in
the body — a guard that refuses `:invnum` therefore refuses every legitimate request (measured: the
first version did exactly that). (The merge itself is shared-core `apidefs2` behaviour and is owned
by `api-params-and-route-matching-CONTEXT.md` §1; what follows is its invoice-specific consequence.)
So `route-invh-update` DROPS the param and `!update` never sees
it: **the number cannot be changed over HTTP.** Lost is the *refusal* — a body `invnum` is ignored
rather than refused, mitigated only by the response returning the row's actual number. **AND A
DIRECT `!update` CALL (REPL, `:agent`) COULD STILL SET IT** — the shape of the `:tenant-id` hole
(handoff §7), which wants the same one-line verb guard.

---

## 3. Request and response shapes, and the error vocabulary

### The error-body taxonomy, which the suite's needles depend on

Three DIFFERENT producers, and they do not share a vocabulary:

| body | produced by | for |
|---|---|---|
| `{"error":"not_found","reason":…}` | sentinel ferry on `nst-response-nil` (whsapi §4) | an absent / soft-deleted / other-tenant row |
| `{"error":"conflict","reason":…}` | sentinel ferry on `nst-response-contradiction` | a `:C` contradiction (not a DRAFT, duplicate number) |
| `{"error":"unknown","reason":…}` | sentinel ferry on `nst-response-unknown` | a `:U` boundary failure (503) |
| `{"error":"no_such_endpoint"}` | `api-error-code-for-status` (`apidefs2:679`) | EVERY condition-derived 404 — including an unbound PATH |
| `{"error":"invalid_request"}` | the same classifier, status 400 | a route-layer refusal (e.g. a non-ISO date) |

🚨 **The classifier has NO 409 case** (`apidefs2:679-685`: 400/401/404/405, then `t` →
`internal_error`), so any 409 a client sees is SENTINEL-derived, and any condition that escapes
unclassified arrives as a 500 wearing the same code a real crash wears — the gap the settings suite
records as its K1. **The renderers specialize on the DOMAIN-AGNOSTIC sentinel types**
(`nst-response-nil` / `-unknown` / `-contradiction`), so the invoice routes get the vocabulary for
free — but the whole sentinel ferry LIVES IN `warehouse/nst-bl-whsapi.lisp` §4, which `nstores.asd`
loads AFTER the invoice section. **The delete ack is the same story**: `route-invitm-delete`
returns a bare Lisp `T`, and the only thing between that `T` and a NO-APPLICABLE-METHOD 500 is
`(defmethod domain->response ((entity (eql t)) …))` at `whsapi:299` — which specializes on the
SYMBOL `T`, not a warehouse type, and returns the still-misnamed `warehouse-ack-response` →
`{"ok":true,"operation":"delete"}`.

### A malformed request that reported as a crash (found and FIXED 2026-09-26)

`GET /invoices?sort-by=<anything not in the whitelist>` answered **500 internal_error**, not 400:
`validate-invh-sort-args` (`nst-bl-invh.lisp:478`) signals a PLAIN `error`, which
`api-status-for-condition` maps to 500 — so a caller who mistyped a parameter the API itself
publishes was told the *server* had broken (the K1 class again). **Fixed in the ROUTE layer**:
`invh-guard-sort-args` (`invoice/nst-bl-invhapi.lisp`) refuses an unusable sort-by/sort-dir with
`api-client-error` → **400 invalid_request**, reading `*invh-sort-whitelist*` rather than restating
the columns, so the two cannot drift; the domain check stays as the backstop for the other channels
(`:agent`, `:batch`, a REPL caller) that reach `enumerate` directly. `?status` is deliberately
unvalidated: an unknown status matches nothing and answers `200 []`, a legitimate empty result. ⚠
**The suite asserted the WRONG thing first** — `200`, from the route docstring's "whitelisted
sort-by/sort-dir" read as "falls back". It does not; the suite now asserts `400`, so a regression
to `500` is a FAIL rather than a silent pass.

### An empty collection is `[]` at the top level and `null` when nested

Not one behaviour, two, and which layer emits it is the difference:

* **`GET /invoices` with no matches → `[]`**: `conflodis2-render` composes the list itself with
  `(format nil "[~{~A~^,~}]" …)` and answers `"[]"` for a NULL response
  (`nst-bl-conflodis2.lisp:200`), so an empty collection is correctly bracketed.
* **`GET /invoices/{id}` on an invoice with no lines → `"lines":null`, NOT `[]`**: the detail
  method builds `(cons "lines" (mapcar …))` (`nst-bl-invhapi.lisp:324`) and hands that Lisp list to
  cl-json, which encodes NIL as `null`. Asserted as the suite's KNOWN K4: a client that iterates
  `lines` over an empty invoice gets null.

**And the aggregate read itself**: `GET /{id}` returns the header's own allowlist *spliced* with a
nested `"lines"` array, built by the action verb — the dispatcher's `action->response` has an
explicit pass-through clause for a ready-made `nst-response-model`.

---

## 4. Delivery: `/download` (a 302) and `/public` (a minted link)

### 4.1 `/download` — RESCOPED 2026-09-26: NO NEW PDF OR HTML PRODUCER IS NEEDED

The earlier note ("what is missing is a PDF producer for the new entities") was wrong. Three
measured facts replace it: **the tables are shared** — `nst-invh` mirrors `DOD_INVOICE_HEADER` and
the LEGACY view class is declared against the SAME table, see `invoice/nst-dal-ihd.lisp:691,945`:
`(clsql:def-view-class dod-Invoice-Header … (:BASE-TABLE dod_invoice_header))`, so a row the NEW
API created is visible to the legacy renderer with no mapping step; **so the legacy public page is
the renderer**, selecting by `invnum` + company through the legacy adapter
(`InvoiceHeaderRequestModel` → `processreadrequest` → `DOD_INVOICE_HEADER`); and **the pipeline is
`generate-invoice-ext-url` → `downloadhtmlfile` → `generatepdf`** (`invoice/nst-ui-ihd.lisp:652,724`)
— the ext-url mints the base64 `tenant-id,invnum,vendor-id` key (four fields since 2026-10-03:
`knowledge/invoice-public-link-CONTEXT.md` §2), `downloadhtmlfile` **wgets it back over HTTP**, and
`generatepdf` shells out to `wkhtmltopdf` (`core/dod-bl-utl.lisp:254`), returning a bare FILE NAME
under `*HHUBRESOURCESDIR*/temp/`. An `nst-invh` row carries all three inputs (`tenant-id`, `invnum`,
`vendor-id`), so the route needs no new domain code — only the fetch and the delivery.

**So the ONE open question was delivery. DECIDED 2026-09-26 — the endpoint is IMPLEMENTED and
bound** (`route-invh-download` + its binding in `invoice/nst-bl-invhapi.lisp`, the ninth of the
twelve). The three options were:

| option | seam change | chosen? |
|---|---|---|
| 302 to `<siteurl>/img/temp/<name>` | **none** | ✅ **TAKEN** — what the legacy handler does (`com-hhub-transaction-invoice-public-pdf` redirects); a redirect is a status + `Location`, no body, and a client that follows redirects receives the PDF, which is what the spec asks for |
| JSON `{"url": …}` | **none** | rejected — honest for a JSON API, but the spec says "return a print-ready PDF" |
| real PDF bytes | **yes** | DEFERRED, not rejected: needs a new `:response-format` value, a bytes-aware writer beside `api-write-text` (`hhub/core/nst-bl-apidefs2.lisp:581`), and an octet-vector clause in `action->response` (`hhub/core/nst-bl-conflodis2.lisp:195` is `stringp`-only) — a change to the seam ALL 40 bound endpoints share. **It belongs in its own change with its own tests**, and buys nothing the 302 cannot deliver |

**The redirect is issued from the Tier-2 route verb**, the HTTP adapter — not the domain, not the
render layer. `hunchentoot:redirect` sets `Location` + status and calls `abort-request-handler`,
which THROWS to hunchentoot's own catch tag; apidefs2 intercepts *conditions*, not throws, so the
redirect unwinds cleanly with no body. That is why `route-invh-download` never returns a value on
its success path, and why its route declares `:success-status 302` as DOCUMENTATION rather than as
a value apidefs2 uses.

⚠ **A nil vendor or tenant is a `:U` (503), never a `:F` (404)** — `invh-download-pdf-url` returns
an `nst-entity-unknown`. The invoice exists (the caller fetched it under its own tenant), so "no
such invoice" would be false, and the pipeline cannot proceed either: the `:U`-read-as-`:F` collapse
this tree exists to prevent. ⚠ **AND THE FETCH MUST CARRY THE SERVER-SIDE RENDER TOKEN (since
2026-10-03)** — the public page is password-gated and wget has nobody to type a password;
`invh-download-pdf-url` mints with `:render t`, one of the four call sites (mechanism:
`knowledge/invoice-public-link-CONTEXT.md` §"the render token"). ⚠ **AND ONE OPERATIONAL CATCH THAT
IS NOT ABOUT THE API AT ALL**: `downloadhtmlfile` fetches `*siteurl*` =
`"https://www.ninestores.in"` (`core/dod-ini-sys.lisp:57`), a PUBLIC production URL, so the
pipeline makes an outbound round-trip to render its own page — on a dev host it fetches PRODUCTION
(or fails), and `/download` cannot be exercised anywhere `*siteurl*` does not resolve to the serving
host. Both delivery options inherit this. ⚠ **AND ITS REAL SUCCESS PATH IS CURRENTLY BLOCKED BY A
PRE-EXISTING DEFECT** (found later): the legacy public page answers **500 for EVERY invoice**, since
at least **2026-05-23**, so the wget fails with `external command failed … wget`. Owner:
`../PENDING-WORK-CONTEXT.md` §1e, which lists the other three flows the same page breaks; the
offline harness passes because it stubs the producers (§7).

### 4.2 `/public` — RESOLVED 2026-09-26, and it never needed the `:public` auth scope

THE EARLIER NOTE IN THE HANDOFF WAS WRONG, because it read the spec's sentence as a requirement on
the ENDPOINT. The spec (`hhub/core/nstoresapi.html:168`) says: *"Publicly accessible invoice view
URL for sharing with customers directly. No authentication required."* — **THE SUBJECT IS THE URL,
NOT THE ENDPOINT.** What the endpoint returns is a *link* ("invoice view URL for sharing"), and it
is that link which must open without a session. That is also the only safe reading: an
id-addressed, unauthenticated invoice GET lets anyone walk `ROW_ID`s and harvest every tenant's
invoices (OWASP API1:2023 BOLA), which is what the smoke suite's cross-tenant assertions catch.

**So the endpoint is a session-scoped read that MINTS a link** (`route-invh-public`,
`invoice/nst-bl-invhapi.lisp`), and the public half is the mechanism ALREADY DEPLOYED: the two
session-less routes `GET /hhub/displayinvoicepublic?key=<base64 of tenant-id,invnum,vendor-id>` and
`GET /hhub/publicinvoicepdf?key=…`, dispatched in `sysuser/dod-ui-sys.lisp` and served by
`nst-ui-ihd.lisp` with no session check — the key IS the capability. It selects by `invnum` +
company, so it addresses any row this API created, and needs nothing pre-stored. **No `:public`
scope, no `api-authenticate` change, and no company-override seam were needed.**

⚠ **WHAT THE LINK IS HAS CHANGED SINCE — 2026-10-03, and the handoff's 2026-09-26 note is
SUPERSEDED.** That note said the link carried no expiry and no password and was deterministic, so a
re-mint gave the identical value; **it is now signed, expires in five minutes and is
password-gated, and the payload carries an expiry field**, so a re-mint need not give the same
string. Owner, do not restate: `knowledge/invoice-public-link-CONTEXT.md` §1 (the two routes), §2
(the token), §3 (the two knobs), §4 (the password). Still true from 2026-09-26: the route WRITES
NOTHING and does not populate `EXTERNAL_URL` (a GET must not write), and the stored column's own
single writer is the invoice save (`invoice-public-link-CONTEXT.md` §3).

---

## 5. Trap: a binding must follow its registration IN LOAD ORDER

`register-api-route` refuses a path whose action route is not registered yet. Offline checks are
blind to this: `compile-file` does not evaluate load-time registrations, and a name-level audit
("is every bound route registered somewhere?") answers yes. The static stand-in that works: walk
the build's own file order and assert each binding follows its registration —
`../tools/nst-binding-order-check` (offline, no image, exits 1 and names the route). **Why it shapes
file placement:** the id-less `PUT /invoices/settings` binding therefore lives in
`vendor/nst-bl-vndapi.lisp` although its URL is invoice-scoped — the same reason the three
`/invoices/{id}/items` bindings live in `nst-bl-invitmapi.lisp`: a binding belongs in the file that
owns the action route it follows.

---

## 6. Trap: an in-image load can wedge class definition for the life of the process

An in-image load that errors inside `ensure-class` parks its worker thread in the debugger holding
SBCL's PCL global mutex; afterwards NOTHING can define a class or a struct. Symptoms seen:
`compile.lisp` never finishing at its `defstruct` (line 23), and `compile-production` stopping after
`Up to date, loading without recompiling: core/dod-dal-pas.lisp` (whose `def-view-class` is at line
10). **The log line precedes the load** — the file named last is the one it is stuck *in*. Restart
is the only recovery. The agent-side tool that caused it (`tools/swank-eval.py`) was deleted on
2026-09-26; `knowledge/build-and-load-CONTEXT.md` §9 says the same. **The corollary:** a reload is
a RESTART (`startup/load.lisp` runs `(ql:quickload :nstores)`, so ASDF recompiles the changed
files) — never `load`/`compile` a file into the running image from outside it.

---

## 7. Verifying the invoice API offline

General method (how these checkers are written and proved):
`knowledge/offline-checker-methodology-CONTEXT.md`. The invoice-specific recipe:

- **First**, the isolated `compile-file` recipe in `knowledge/build-and-load-CONTEXT.md` §6 (a
  throwaway SBCL; it caught unreadable parens, a docstring-terminating quote and the binding-order
  bug), `../tools/nst-symq` for any symbol question, and `../tools/nst-invoice-mirror-check.lisp`
  for anything touching the invoice response models (it executes the `setf` `compile-file` cannot).
- **✅ A FULL OFFLINE SYSTEM LOAD EXISTS** and is the strongest check available without a restart
  (once recorded as impossible — wrong). `../tools/nst-offline-load.lisp` loads the whole system —
  every प्रत्यय, the ferries, `domain->response`, `render-json` — against the REAL database, with no
  web server and no acceptor (it never calls `start-das`); `../tools/nst-verify-invoice-offline.lisp`
  then drives the ACTUAL route functions and asserts the smoke suite's contract. **32 pass / 0 fail**
  measured 2026-09-26, writing nothing.
  * It proved the 500 fix end-to-end (`fetch 'nst-invh "23" ctx` → `domain->response` →
    `render-json` → JSON, the call that used to signal MISSING-SLOT), reached the settings route's
    **fail-closed 401** branch (which the smoke suite cannot cover), MEASURED the suite's KNOWN K2
    (a repeat delete returns `nst-entity-nil`, 404), and caught a real 500 in that route:
    `hunchentoot:session-value` signals UNBOUND-VARIABLE outside an HTTP request, so the probe is
    guarded and any failure to establish an identity is a 401 with nothing written.
  * **51 checks final** (47 first: every refusal the suite asserts but had never executed — PUT on
    an absent/foreign invoice, the non-ISO and impossible dates, the (header, line) pairing on BOTH
    update and delete, absent lines, and the one contract with NO test anywhere, **DELETE of a line
    whose invoice is not a DRAFT = `:C` (409)**, not 404, now in the suite too). Added last: the
    `/download` success path with the two producers stubbed — it proves the route mints the
    sessionless ext-url, calls the producer and redirects to `<siteurl>/img/temp/<file>`; it does
    NOT prove a PDF is produced. **Every path in the invoice API has been executed at least once**;
    what no offline harness can reach — apidefs2's HTTP routing, the hunchentoot session, the
    response writers — is still only checked by the smoke suite over HTTP.
- `../tools/nst-verify-invoice-dispatch.lisp` is the companion dispatch harness — the FIRST thing
  ever to execute `route-invh-create` (§8) — and passes **51/0**.
- **Setup, all four required:** no `:depends-on` in the asd; swank quickloaded first; a WRITABLE
  COPY of the clsql dist; and the `hhub-bl-ent`/`dod-ini-sys` load order (the tool's header has the
  traps). ⚠ **`cp -r` of the live image's ASDF cache does NOT work** — every fasl gets a fresh
  mtime, so ASDF loads stale fasls and the failure looks like a source bug; compile from source into
  a fresh `XDG_CACHE_HOME`. **The four blockers, all still true:** (1) `hhub/nstores.asd` has no
  `:depends-on` and `startup/load.lisp` quickloads the 16 dependencies first — without that the
  build dies inside `core/dod-dal-bo.lisp` with *"Package CLSQL does not exist"*; (2)
  `XDG_CACHE_HOME` must be writable (the file sandbox denies `~/.cache`); (3) **`clsql-mysql` cannot
  be loaded by a non-owner** — its asd writes the foreign library into a source directory owned by
  `hunchentoot`, failing as an opaque `OPERATION-ERROR` that never mentions permissions; (4)
  `init.lisp` quickloads **swank** first and the tree reads the package at compile time — without
  it, *"READ error: Package SWANK does not exist"*.

---

## 8. Traps measured on these entities and their routes (2026-09-26)

### 🚨 TWO DEFECTS THAT MADE `POST /invoices` IMPOSSIBLE (found and FIXED 2026-09-26)

Both were found by the OFFLINE HARNESS (`../tools/nst-verify-invoice-dispatch.lisp`) on the FIRST
time `route-invh-create` was ever executed; neither could be caught by reading the code, and neither
was visible to the smoke suite, which had never run.

1. **The create route required a row-id.** `route-invh-create` normalised via
   `invh-normalised-request` → `inv-request-with-row-id-string` → `inv-row-id-param`, which SIGNALS
   `api-client-error` when no `:row-id` is present — and **a create has no row-id; the database
   mints one.** So EVERY `POST /hhub/api/v1/invoices` was refused with **400 "a row-id is required
   (a numeric id)"** before the verb ran. Fixed with a create-specific normaliser
   (`invh-create-normalised-request`): the row-id coercion belongs on fetch/`!update`/`delete!`,
   where a missing id IS a malformed request — a shared normaliser would have traded this 400 for a
   500 from the verb's own `(row-id string)` dispatch.
2. **An integer for a decimal column failed the INSERT.** CLSQL declares the money columns
   `(OR NULL FLOAT)` and validates on insert, so `{"totalvalue": 0}` — ordinary JSON — produced
   `Invalid value 0 in slot TOTALVALUE, not of type FLOAT`, surfaced as **`:U` (503) "the database
   call did not answer"**. Fixed in two places, different problems: four class initforms that were
   the integer `0` for a float column are now `0.0` (covers the OMITTED field), and
   `nst-copy-invoice-header-domaintodb` / `nst-copy-invoice-item-domaintodb` coerce integer→float
   for slots that admit floats (covers the SUPPLIED one, the common case). ⚠ **The coercion's first
   version silently never fired**: it tested `(eq type 'float)` and CLSQL's declared type is the
   compound `(OR NULL FLOAT)` — a guard that cannot fire reads as fixed; the correction is
   `nst-db-float-slot-p`.
3. **Every header UPDATE answered 503.** `PUT /invoices/{id}` returned `nst-entity-unknown` — `:U`,
   "the database call did not answer" — for a DB-level type error the business-functions log named
   exactly:
   ```
   NST-DB-UPDATE-ERROR: Invalid value GET-TIME in slot UPDATED, not of type WALL-TIME.
   ```
   `nst-dal-ihd.lisp`'s `updated` slot carried `:void-value (clsql:get-time)` — **a FORM where CLSQL
   wants a LITERAL.** CLSQL's docstring (`sql/ooddl.lisp:234`): *":void-value specifies THE VALUE to
   store if the SQL value is NULL and defaults to NIL"*, and its test suite passes values like `0`
   and `""`. The line meant "when UPDATED is NULL store the list `(CLSQL:GET-TIME)`", which the
   `clsql:wall-time` type check rejected on every write; removed (the default is NIL and the column
   is `timestamp NULL DEFAULT NULL`). ⚠ **NOBODY STAMPS UPDATED NOW** — no
   `ON UPDATE CURRENT_TIMESTAMP` in the DDL and the copier excludes created/updated, so an
   auto-stamp needs a migration, not a void-value. ⚠ **The same misuse exists in
   `hhub/products/dod-dal-prd.lisp:156`** (`:void-value (format nil "NST-~A" …)`), NOT changed
   here: products domain, outside this work, unverified — almost certainly the same bug class.

**AND `INVNUM` IS NOT YOURS TO SET** — a MySQL trigger overwrites it on every insert (the trigger,
and why `hhubuser` cannot see it in `INFORMATION_SCHEMA`, are `../PENDING-WORK-CONTEXT.md` §1d).
The suite used to clean up by invoice-number prefix, which never matched, leaking every row it
created; it now keys on the ROW-ID from the 201 response. Any cleanup keyed on an invoice number has
the same bug.

### The other three, at class level

1. **`DELETED_STATE` is `char(1) DEFAULT NULL`** on both invoice tables (unlike `DOD_WAREHOUSE`'s
   `'N'`), and the CLSQL classes declare `:void-value "N"`, so legacy rows hold SQL NULL. "Not
   deleted" must be `[= 'N'] OR [IS NULL]`; a plain `[= "N"]` hides every invoice in the system.
   And `[= … nil]` renders literal `= NULL`, true for no row at all — use `[is … nil]`.
2. **`INVNUM` IS `UNIQUE`** — index `INVNUM` on column `INVNUM` with `NON_UNIQUE=0`, unique across
   ALL tenants. So `?exists` on the header IS backed by the database and not only by a business
   check, and a soft-deleted row still holds its number (`:C` → 409) because `DELETED_STATE` is not
   part of the key. **This corrects the first version of this note** (which claimed there was no
   UNIQUE constraint) **and the handoff's decision 7**, measured against
   `INFORMATION_SCHEMA.STATISTICS`, 2026-09-26.
3. **The item URL puts `:invheadid` in the payload**, which `!update` refuses; the route verifies
   the pairing and strips it. Without the strip every nested PUT would 409.

---

**Extracted 2026-10-05 from `../invoice-api-handoff-CONTEXT.md`**, nothing deleted: §1 ← its §4;
§2 ← its §4b; §3 ← its §1b taxonomy/empty-collection/sort-args subsections; §4 ← its §6.3 and §6.6;
§5 ← §8.2; §6 ← §8.3; §7 ← §9 (offline half); §8 ← its §1b `POST /invoices` defects + §8.1/§8.4/§8.5.
