# Handoff — the invoice API (session of 2026-09-25/26) · CONTEXT

**Read this when:** you are picking up the invoice API — designing the endpoints the
spec still wants, wiring or debugging an invoice route, or wondering whether any of it
has actually run. Read it BEFORE the code: §1 is the state of the running system, and
§5–§6 are the decisions already taken versus the ones still open.

**Status in one line (updated 2026-09-26, after the reload): the API is LIVE and the
smoke suite is GREEN.** `GET /hhub/api/v1/invoices` answers **200** where it answered 500
for the whole of §1b; **ten** of the spec's twelve endpoints are bound; the suite passes
**62/0 read-only** (and 81/0 with `--write`), with three documented KNOWNs and nothing
unexpected. §1b's fix is therefore verified against the running image, not just offline.

---

## 1. State of the running system — verified 2026-09-26 ≈09:20

| Check | Result |
|---|---|
| Lisp image | restarted; pid **1915**, up since ≈07:54 (the earlier process was wedged — see §8.3) |
| `compile-production` (00:08:11) | **`Failed: 0`**. The two api files compiled with style warnings only (17 + 7) — the expected cross-file undefined-function notes |
| ASDF build | `…/cache/…/hhub/invoice/nst-bl-invhapi.fasl` at **07:54**, i.e. the restart compiled and loaded the invoice files |
| `GET /hhub/api/v1/invoices`, no session | **401** — which proves the *binding resolves* (an unknown path answers `404 no_such_endpoint`) and that `api-authenticate` rejects it |
| Any authenticated call | **never run** at the time of this table. §1b is what happened when the first one ran: a 500 on every route |

🚨 **AND THE IMAGE IS RUNNING A DIFFERENT TREE FROM THE ONE ON DISK.** It started at
**07:54**; commit **`d6275d0` landed at 09:01:11** and changed both build lists
(`dod-ini-sys` moved above `hhub-bl-ent`, which broke the cold boot — see PENDING-WORK
§1c, fixed). So the running image's behaviour is NOT evidence about the current sources,
and its health is not evidence that a restart would succeed. The one thing the image
still proves is that the OLD order boots.

So the load path is proven and the surface is live; everything behind a session cookie
was UNRUN. §1b records the first exercise and the defect it found — read §1b before §9.

---

## 1b. The first exercise — and the 500 it found (2026-09-26)

`hhub/test/smoke-invoice-api.sh` was written and run. **Every authenticated invoice
route answered 500 internal_error**, for a reason nothing offline could have seen:

```
condition: the slot COM.NSTORES.APP::DELETED-STATE is missing from
           #<COM.NSTORES.APP::NSTINVHRESPONSEMODEL>
```

`domain->response` for `nst-invh` drives its setfs from `*invh-mirrored-slots*`
(`nst-bl-invh.lisp:685`), and that list names `deleted-state` (line 631) — but neither
`NstInvhResponseModel` nor `NstInvitmResponseModel` declared the slot, so the `setf`
signalled MISSING-SLOT on every header AND line response. **The load path was proven
and the surface was live while nothing behind a session could ever work**, which is
precisely why it stayed undiscovered until a suite exercised it.

**FIXED in source** (`nst-dal-invh.lisp`, `nst-dal-invitm.lisp`): both response models
now declare `(deleted-state :initarg :deleted-state :accessor deleted-state)`.
Verified by diffing all 53 + 18 mirrored slots against both response models: exactly
ONE slot was missing per side, and nothing else. `render-json` was left untouched, so
it still does not reach the wire — the same split `WarehouseResponseModel` uses
(`nst-dal-warehouse.lisp:513` declares it, `nst-bl-warehouse.lisp` does not publish it).

**STATUS: VERIFIED LIVE — the image was reloaded on 2026-09-26 and the fix holds.**
`GET /hhub/api/v1/invoices` answers **200** with a JSON array where it answered 500 for
every authenticated caller; the smoke suite runs **62 pass / 0 fail** read-only and
**81 pass / 0 fail** with `--write`. It was also verified offline two ways first, and
those remain the checks to use when the image cannot be reloaded:
1. *Compile*: isolated `compile-file`, `failure-p=NIL` on both DAL files.
2. *Behaviour* — the one that matters, because `compile-file` does not evaluate the
   `setf` that was failing: an isolated SBCL loads `packages.lisp`, `nst-bl-adhara.lisp`
   and both DAL files, then performs domain->response's EXACT operation (a `setf` of
   every mirrored slot onto the response model). **53/53 header and 18/18 item slots
   setf cleanly; zero MISSING-SLOT.** The check is reproducible and now lives as
   `aiharness/deepseek/tools/nst-invoice-mirror-check.lisp` — it reads the slot lists
   FROM SOURCE rather than copying them, and it has been mutation-tested: with the
   `deleted-state` slot removed from a throwaway copy it reports
   `MISSING on RESPONSE = (DELETED-STATE)`, `52/53`, and **exits 1**. So it is not
   passing vacuously.

Until a reload, the suite bails at section 1 with a diagnosis, and every read below it
is UNRUN. A reload is a restart (`startup/load.lisp` runs `(ql:quickload :nstores)`, so
ASDF recompiles the changed files); do NOT load them into the live image — class
redefinition in-image is the documented PCL-wedge risk (§8.3).

### THE COLD-BOOT FIX, CORRECTED: move the METHOD, not the file

The first version of this fix REORDERED the build — `core/hhub-bl-ent` above
`core/dod-ini-sys` in both lists — and that reordering is what caused regression 2 above.
**The build lists are now UNCHANGED (reverted).** The boot blocker is fixed in CODE
instead: `initBusinessContexts` (its `defgeneric` and its one `defmethod`, which
specialize on `BusinessServer`/`BusinessContext`) was MOVED OUT of
`core/dod-ini-sys.lisp` INTO `core/hhub-bl-ent.lisp`, beside the classes it specializes
on. `dod-ini-sys` keeps only its runtime CALL to it, inside `initBusinessServer`.

The load order now satisfies all three constraints at once, which no reordering could:

| constraint | why | order |
|---|---|---|
| the `with-bo-knowledge-check` macro before `hhub-bl-ent` | its expansion binds `payload` | `nst-bl-beltrusys` (21) < `hhub-bl-ent` (22) |
| the classes before the method that specializes on them | a defmethod installs its specializer at LOAD time | classes and method are now in ONE file |
| `dod-ini-sys` early for the globals later files read | d6275d0's intent | `dod-ini-sys` (13) |

**VERIFIED: `STAGE: LOADED`** from `../tools/nst-offline-load.lisp`, the legacy read
returns an `INVOICEHEADER`, and the dispatch harness still passes **51/0**.

### The root cause was a comment

`nst-bl-invh.lisp` used to say, of the mirror list: *"ADD A NEW COLUMN HERE, in this one
list. **Nothing else needs to change** for the column to survive a create, a fetch and
an update."* That is false, and it is why `deleted-state` was ever in the hole. The list
drives **three** consumers, not two: the two copiers AND `domain->response`. The comment
now says so, and names the symptom, because the error surfaces in a file nobody edited.

Related: this list-driven `domain->response` form exists **only** for the two invoice
entities — `nst-whs`'s is longhand, one `setf` per field, so warehouse cannot drift this
way. That is why the defect was unique to invoices and why nothing had a reason to
check for it.

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
`internal_error`). So any 409 a client sees is SENTINEL-derived, and any condition that
escapes unclassified arrives as a 500 wearing the same `internal_error` code a real
crash wears. That is the same gap the settings suite records as its K1.

**The renderers specialize on the DOMAIN-AGNOSTIC sentinel types**
(`nst-response-nil` / `-unknown` / `-contradiction`), so the invoice routes get this
vocabulary for free — but the whole sentinel ferry LIVES IN `warehouse/nst-bl-whsapi.lisp`
§4, which `nstores.asd` loads AFTER the invoice section (§7).

**The delete ack is the same story**: `route-invitm-delete` returns a bare Lisp `T`,
and the only thing between that `T` and a NO-APPLICABLE-METHOD 500 is
`(defmethod domain->response ((entity (eql t)) …))` at `whsapi:299` — which specializes
on the SYMBOL `T`, not on a warehouse type, and returns the still-misnamed
`warehouse-ack-response` → `{"ok":true,"operation":"delete"}`.

### An empty collection is `[]` at the top level and `null` when nested

Not one behaviour, two — and the difference is which layer emits it:

* **`GET /invoices` with no matches → `[]`.** `conflodis2-render` composes a list itself
  with `(format nil "[~{~A~^,~}]" …)` and answers `"[]"` for a NULL response
  (`nst-bl-conflodis2.lisp:200`), so an empty collection is correctly bracketed.
* **`GET /invoices/{id}` on an invoice with no lines → `"lines":null`, NOT `[]`.** The
  detail method builds `(cons "lines" (mapcar …))` (`nst-bl-invhapi.lisp:324`) and hands
  that Lisp list to cl-json, which encodes NIL as `null`. Asserted as the suite's KNOWN
  K4: a client that iterates `lines` over an empty invoice gets null.

### 🚨 TWO DEFECTS THAT MADE `POST /invoices` IMPOSSIBLE (found and FIXED 2026-09-26)

Both were found by the OFFLINE HARNESS (`../tools/nst-verify-invoice-dispatch.lisp`) on
the FIRST time `route-invh-create` was ever executed. Neither could have been caught by
reading the code, and neither was visible to the smoke suite, which had never run.

1. **The create route required a row-id.** `route-invh-create` normalised via
   `invh-normalised-request` → `inv-request-with-row-id-string` → `inv-row-id-param`,
   which SIGNALS `api-client-error` when no `:row-id` is present — and **a create has no
   row-id; the database mints one.** So EVERY `POST /hhub/api/v1/invoices` was refused
   with **400 "a row-id is required (a numeric id)"** before the verb ran. Fixed with a
   create-specific normaliser (`invh-create-normalised-request`): the row-id coercion
   belongs on fetch/!update/delete!, where a missing id IS a malformed request — a shared
   normaliser would have traded this 400 for a 500 from the verb's own `(row-id string)`
   dispatch.

2. **An integer for a decimal column failed the INSERT.** CLSQL declares the money
   columns `(OR NULL FLOAT)` and validates on insert, so `{"totalvalue": 0}` — ordinary
   JSON — produced
   `Invalid value 0 in slot TOTALVALUE, not of type FLOAT`, surfaced to the client as
   **`:U` (503) "the database call did not answer"**. Fixed in two places, and they are
   different problems: four class initforms that were the integer `0` for a float column
   are now `0.0` (covers the OMITTED field), and `nst-copy-invoice-header-domaintodb` /
   `nst-copy-invoice-item-domaintodb` now coerce integer→float for slots that admit
   floats (covers the SUPPLIED one, which is the common case).
   ⚠ **The coercion's first version silently never fired**: it tested `(eq type 'float)`
   and CLSQL's declared type is the compound `(OR NULL FLOAT)`. A guard that cannot fire
   reads as fixed — the correction is `nst-db-float-slot-p`.

3. **Every header UPDATE answered 503.** `PUT /invoices/{id}` returned
   `nst-entity-unknown` — `:U`, "the database call did not answer" — for a DB-level type
   error, which the business-functions log named exactly:

   ```
   NST-DB-UPDATE-ERROR: Invalid value GET-TIME in slot UPDATED, not of type WALL-TIME.
   ```

   `nst-dal-ihd.lisp`'s `updated` slot carried `:void-value (clsql:get-time)` — **a FORM
   where CLSQL wants a LITERAL.** CLSQL's own docstring (`sql/ooddl.lisp:234`):
   *":void-value specifies THE VALUE to store if the SQL value is NULL and defaults to
   NIL"*; its test suite passes values like `0` and `""`. So that line meant "when UPDATED
   is NULL store the list `(CLSQL:GET-TIME)`", and the `clsql:wall-time` type check then
   rejected it on every write. Removed (the documented default is NIL, and the column is
   `timestamp NULL DEFAULT NULL`).
   ⚠ **NOBODY STAMPS UPDATED NOW** — the DDL has no `ON UPDATE CURRENT_TIMESTAMP` and the
   copier excludes created/updated, so an auto-stamp needs a migration, not a void-value.
   ⚠ **The same misuse exists in `hhub/products/dod-dal-prd.lisp:156**
   (`:void-value (format nil "NST-~A" …)`), NOT changed here: it is the products domain,
   outside this work, and unverified. It is almost certainly the same class of bug.

**AND `INVNUM` IS NOT YOURS TO SET** — a MySQL trigger overwrites it on every insert
(see PENDING-WORK §1d). The smoke suite used to clean up by invoice-number prefix, which
therefore never matched; it now keys on the ROW-ID from the 201 response.

### 🚨 TWO REGRESSIONS THE INVOICE WORK INTRODUCED, AND BROKE THE VENDOR UI (2026-09-26)

Both surfaced as **"the invoice page on the UI is broken"**, and both were mine. They are
recorded together because they are the two ways a NEW domain can silently damage the
LEGACY DDD layer that still shares its process, package and files.

**1. A FUNCTION-NAME COLLISION REPLACED A LEGACY FUNCTION.** `nst-bl-invh.lisp` defined
`select-invoice-header-by-invnum`, a name `nst-bl-ihd.lisp:21` already uses — with a
DIFFERENT signature (legacy: `(invnum company)` taking a DOD-COMPANY object; mine:
`(invnum tenant-id &key include-deleted)`). Both are plain defuns in one package, and
`nst-bl-invh` loads LATER (asd 140 vs 130), so MINE WON and the legacy readers
(`nst-bl-ihd.lisp:323, :370, :406`) began passing a company object into a tenant-id
parameter. CLSQL refused it —
`No type conversion to SQL for DOD-COMPANY is defined for DB MYSQL-DATABASE` — the read
returned a Belnap sentinel, and the legacy callers dereference it:
`MISSING-SLOT ROW-ID … #<BUSINESSOBJECTUNKNOWN>` from `select-all-invoice-items`.
**FIXED by renaming mine to `nst-select-invoice-header-by-invnum`.** ⚠ The file's own
header already states this rule for the CLASSES; it applies just as much to helper
FUNCTIONS. **Check for collisions before adding a defun to a new domain.**
⚠ A second, currently harmless duplicate exists: `domain->response-list` is defined in
both `nst-bl-invh.lisp` and `nst-bl-warehouse.lisp` with identical bodies (warehouse wins).
Left in place rather than silently tidied, but it is the same trap.

**2. MOVING `hhub-bl-ent` EARLIER BROKE A MACRO EXPANSION.** The cold-boot fix (§ below)
moved `core/hhub-bl-ent` above `core/dod-ini-sys`, which also put it ABOVE
`core/nst-bl-beltrusys` — and `hhub-bl-ent` uses that file's `with-bo-knowledge-check`
macro, whose expansion is what binds `payload` (`with-slots (truth payload …)`). Compiled
without the macro available, the form became a FUNCTION CALL whose arguments include
`payload` — unbound — so **every successful legacy read raised
`The variable PAYLOAD is unbound`**, taking the vendor invoice pages and the public
invoice page down. **FIXED by NOT reordering at all**: see the boot fix below.

**ATTRIBUTION METHOD, worth reusing:** every one of these had to be separated from a
PRE-EXISTING defect on the same path. Two log files answer it —
`~/hhublogs/ninestores-messages.log` and `~/hhublogs/ninestores-busfunctions.log` — which
carry timestamps. `No type conversion to SQL for DOD-COMPANY` appears on **2026-07-24** and
**2026-09-25 19:42**; `PAYLOAD is unbound` on **2026-03-02/03** and **2026-08-29**; but
`MISSING-SLOT ROW-ID … BUSINESSOBJECTUNKNOWN` appears ONLY from 15:07 today. That last
fact is what identified the regression as new. **Check the logs before believing either
"it was always broken" or "you broke it".**

### A malformed request that reported as a crash (found and FIXED 2026-09-26)

`GET /invoices?sort-by=<anything not in the whitelist>` answered **500
internal_error**, not 400. `validate-invh-sort-args` (`nst-bl-invh.lisp:478`) signals a
PLAIN `error` — not one of apidefs2's named conditions — and
`api-status-for-condition` maps everything it does not name to 500. So a caller who
mistyped a query parameter the API itself publishes was told the *server* had broken,
indistinguishable from a real crash. Same defect class as the vendor settings suite's K1.

**Fixed in the ROUTE layer**, not the domain: `invh-guard-sort-args`
(`invoice/nst-bl-invhapi.lisp`) refuses an unusable sort-by/sort-dir with
`api-client-error` → **400 invalid_request**, and it READS `*invh-sort-whitelist*`
rather than restating the columns, so the two cannot drift. The domain check stays as
the backstop for the other channels (`:agent`, `:batch`, a REPL caller) that reach
`enumerate` directly. `?status` is deliberately still unvalidated: an unknown status
compares, matches nothing, and answers `200 []` — a legitimate empty result rather than
a malformed request.

⚠ **The suite asserted the WRONG thing first and had to be corrected**: it expected
`200` on the strength of the route docstring's phrase "whitelisted sort-by/sort-dir",
reading that as "falls back". It does not fall back. The suite now asserts `400`, so a
regression to `500` is a FAIL rather than a silent pass.

### Fixtures and credentials (verified live, 2026-09-26)

* The suite logs in as phone **9999999990 / `Welcome1`** — the vendor row-id 1, tenant 2.
  `Welcome1` works because the password defect is still live (PENDING-WORK §1).
* Tenant-2 invoices: **23** = DRAFT with 4 lines (the aggregate read's happy path);
  **33/34/36** = DRAFT with 0 lines; **35** = PENDINGPAYMENT with 6 lines (the 409
  fixture); **21/22** = TENANT 5 (the BOLA fixture). Max header row-id 36, max line 247.
* 🚨 **`INVNUM` IS UNIQUE** — index `INVNUM`, `NON_UNIQUE=0` (corrects §8.4, which says
  the opposite). It is unique across ALL tenants, and a soft-deleted row still holds its
  number, so `:C`/409 is a DATABASE guarantee and not only a `make :around` business check.

## 2. What shipped

Four commits carry the invoice API (plus eight others from the same two days: the symbol
DAG tooling, the vendor `!settings` sub-resource, the smoke-script host rename, argon2id
passwords, GSTR-1, and three documentation commits).

| Commit | Contents |
|---|---|
| `5a0b61c` | `nst-dal-invh.lisp`, `nst-dal-invitm.lisp` — the two domain classes + their boundary models |
| `f018cbe` | `nst-bl-invh.lisp`, `nst-bl-invitm.lisp` — the six Tier-1 verbs per entity |
| `feb5a5f` | `nst-bl-invhapi.lisp`, `nst-bl-invitmapi.lisp` — Tier-2 action routes + the seven API bindings |
| `e0c934e` | `hhub/nstores.asd` + `hhub/package/compile.lisp` — the six files in both build lists |

---

## 3. Where everything lives

| Concern | File |
|---|---|
| **The smoke suite for the seven bound endpoints** — read-only by default, `--write` for the lifecycle, and the only thing that has ever exercised these routes | `hhub/test/smoke-invoice-api.sh` |
| **The API spec** (12 Invoicing endpoints, domain `id:'inv'`, role Vendor) | `hhub/core/nstoresapi.html` — a JS table `{m,p,d}`; grep for `id:'inv'` |
| Entity classes + boundary models | `hhub/invoice/nst-dal-invh.lisp`, `hhub/invoice/nst-dal-invitm.lisp` |
| Tier-1 verbs (प्रत्यय) | `hhub/invoice/nst-bl-invh.lisp`, `hhub/invoice/nst-bl-invitm.lisp` |
| Tier-2 action routes + Ring-4 bindings | `hhub/invoice/nst-bl-invhapi.lisp`, `hhub/invoice/nst-bl-invitmapi.lisp` |
| Dispatcher (route registry, कारक, render) | `hhub/core/nst-bl-conflodis2.lisp`; JSON boundary + status mapping `hhub/core/nst-bl-apidefs2.lisp` |
| **The reference implementation to copy** | `hhub/warehouse/nst-bl-whsapi.lisp` (and `hhub/vendor/nst-bl-vndapi.lisp`) |
| Design authority for the route tier | `knowledge/nst-bl-conflodis2-DESIGN.md` |
| The API layer's own context (§9.4: `?exists` cannot cross the ferry) | `knowledge/nst-bl-apidefs2-CONTEXT.md` |
| The grammar the verbs obey | `knowledge/WAREHOUSE-NST-GRAMMAR-CONTEXT.md` |
| Deferred items, with file:line sites | `PENDING-WORK-CONTEXT.md` |

---

## 4. The twelve spec endpoints, and which ten exist

| Spec endpoint | Bound? | Route |
|---|---|---|
| `POST /api/v1/invoices` (201) | ✅ | `route-invh-create` |
| `GET /api/v1/invoices` | ✅ | `route-invh-list` |
| `GET /api/v1/invoices/{id}` | ✅ | `route-invh-detail` (the aggregate read, §5) |
| `PUT /api/v1/invoices/{id}` | ✅ | `route-invh-update` |
| `POST /api/v1/invoices/{id}/items` (201) | ✅ | `route-invitm-create` |
| `PUT /api/v1/invoices/{id}/items/{item-id}` | ✅ | `route-invitm-update` |
| `DELETE /api/v1/invoices/{id}/items/{item-id}` | ✅ | `route-invitm-delete` |
| `PUT /api/v1/invoices/settings` | ✅ | `route-invh-settings-update` — **BOUND 2026-09-26** (§6.7), in `vendor/nst-bl-vndapi.lisp`, delegating to the same `!settings` प्रत्यय the vendor sub-resource uses |
| `POST /api/v1/invoices/{id}/payment` | ❌ | a different कर्म — no प्रत्यय exists (§6.4) |
| `POST /api/v1/invoices/{id}/send` | ❌ | actor model, not a domain verb (§6.5) |
| `GET /api/v1/invoices/{id}/download` | ✅ | `route-invh-download` — **BOUND 2026-09-26** (§6.6), a 302 to the rendered file |
| `GET /api/v1/invoices/{id}/public` | ✅ | `route-invh-public` — **BOUND 2026-09-26** (§6.3), returns the shareable link |

**Ten bound, two not — and the two that remain are the ones needing a new कर्म or an
actor job, not a decision:** `/payment` (§6.4) and `/send` (§6.5). See §6.3 for why
`/public` turned out not to need the `:public` auth scope it was blocked on, and §6.6
for the delivery decision `/download` was built to sidestep.

Also registered but deliberately unbound: `route-invh-delete` (the spec defines no
invoice DELETE — consistent with the DRAFT-only rule) and `route-invh-fetch-by-invnum`
(the read that can answer `:C`; the spec has no endpoint for it).

---

## 4b. THE URL ADDRESSES AN INVOICE BY ITS NUMBER (decided 2026-09-26)

**All seven invoice bindings map their `{id}` segment to `:invnum`** — the human-readable
invoice number (`NST00023-2024`) — not the surrogate `ROW_ID`. `{item-id}` stays the
LINE's row-id: a line has no readable key, so inventing one (a per-invoice sequence) is a
separate decision nobody has taken.

* **The number is unique** (index `INVNUM`, `NON_UNIQUE=0`) and **immutable over HTTP**,
  which is what makes it a safe address. No `UNIQUE` on the row-id would matter; the
  number is the domain's backbone key — the vendor reads it, the customer quotes it, the
  GST return carries it.
* **🚨 THE RESOLUTION IS IN THE ROUTE LAYER, AND IT HAS TO BE.** The domain verbs
  specialize on `(id string)`, and an invoice number and a row-id are BOTH strings — CLOS
  dispatches on type, so no verb method can tell them apart. `invh-header-from-url` /
  `invh-request-with-header-row-id` (invoice/nst-bl-invhapi.lisp) resolve once per request;
  the verbs stay row-id-keyed and unchanged.
* **It answers the VERB'S four-valued result**: a number held by a SOFT-DELETED invoice is
  `:C` → **409**, not 404 — the number is consumed and the row is present, so 'no such
  invoice' would be false.
* **The number cannot be DERIVED from the row-id.** The trigger stamps `year(now())` at
  INSERT time, so a 2024 row and a 2026 row at the same position differ. Every fixture
  reads it from the table (`invnum-of` in the dispatch harness, `__inv` in the suite).
* ⚠ **BREAKING, deliberately:** `/invoices/23` no longer resolves. Nothing consumed the
  numeric form (the API was days old), so an "accept both" scheme was rejected in favour
  of one unambiguous address.

### 🚨 A BODY-SUPPLIED `invnum` IS STRIPPED, NOT REFUSED — and it CANNOT be refused

`api-params-for-request` merges the PATH parameters and the JSON body into **one** params
plist, so the `:invnum` naming the invoice in the URL is indistinguishable from an
`:invnum` a client put in the body. A guard that refuses `:invnum` therefore refuses every
legitimate request — measured, the first version did exactly that.

So `route-invh-update` DROPS the param and `!update` never sees it: **the number cannot be
changed over HTTP.** What is lost is the *refusal*: a client that sends `invnum` in the body
is ignored rather than told no, mitigated only by the response returning the row's actual
number. **AND A DIRECT `!update` CALL (REPL, `:agent`) COULD STILL SET IT** — the same shape
as the recorded `:tenant-id` hole, and it wants the same one-line verb guard for both.

---

## 5. Decisions already made — do not re-litigate

1. **Templates carry `/hhub`; the spec's paths do not.** nginx rewrites everything to
   `/hhub/$1`, and `register-api-route` rejects a template without the prefix.
2. **No `:inject-company` on any invoice binding.** `nst-invh`/`nst-invitm` read the
   inherited `tenant-id` from `domain-ctx`; unlike `nst-whs` they carry no legacy
   `COMPANY` slot, so the API need not inject one.
3. **Path params beat the body** (`api-params-for-request` order), which is why a
   body-supplied `row-id`/`invheadid` cannot displace the URL.
4. **The line routes verify the (header, line) PAIRING** and 404 on a mismatch; and
   `:invheadid` is stripped before `!update`, which refuses it by design.
5. **Content vs. values** decides the status rules: `make`/`delete!` on a line require a
   DRAFT header; `!update` is allowed at any status.
6. **The aggregate `GET /{id}`** returns the header's own allowlist *spliced* with a
   nested `"lines"` array, built by the action verb — the dispatcher's `action->response`
   has an explicit pass-through clause for a ready-made `nst-response-model`.
7. **`?exists` is not a uniqueness check** for either entity (a duplicate product line is
   legitimate; `INVNUM` has no UNIQUE key). No route exposes it.
8. **Dates at the API are ISO `YYYY-MM-DD`**, coerced at the route layer; anything else
   is a 400.

---

## 6. The design work that is genuinely open

1. **A compound `create-with-lines` write.** Its response shape is settled (decision 6);
   the blocker left is **atomicity** — `*action-route-transaction-function*` is a no-op,
   so a header could be written and line 3 refused.
2. **The GST breakdown** the spec lists under `GET /{id}`. Derivable from the line tax
   columns, but it is a DOMAIN computation: put it in `nst-bl-invh.lisp` beside the
   verbs, not in a render fold. The legacy `generate-gst-tax-breakdown` works on the OLD
   business objects (`nst-dal-itm.lisp`'s `add-item-to-tax-breakdown`).
3. **`/public` — RESOLVED 2026-09-26, and it never needed the `:public` auth scope.**
   THE EARLIER NOTE IN THIS FILE WAS WRONG, because it read the spec's sentence as a
   requirement on the ENDPOINT. The spec (`hhub/core/nstoresapi.html:168`) says:

     `GET /api/v1/invoices/{id}/public` — *"Publicly accessible invoice view URL for
     sharing with customers directly. No authentication required."*

   **THE SUBJECT OF "No authentication required" IS THE URL, NOT THE ENDPOINT.** What
   the endpoint returns is a *link* — "invoice view URL for sharing" — and it is that
   link which must open without a session. That is also the only safe reading: an
   id-addressed, unauthenticated invoice GET lets anyone walk `ROW_ID`s and harvest
   every tenant's invoices (OWASP API1:2023 BOLA), which is precisely what this suite's
   cross-tenant assertions exist to catch.

   **So the endpoint is a session-scoped read that MINTS a link** (`route-invh-public`,
   `invoice/nst-bl-invhapi.lisp`), and the public half is the mechanism ALREADY
   DEPLOYED: `GET /hhub/displayinvoicepublic?key=<base64 of tenant-id,invnum,vendor-id>`,
   dispatched in `sysuser/dod-ui-sys.lisp` and served by `nst-ui-ihd.lisp` with no
   session check — the key IS the capability. It selects the header by `invnum` +
   company, so it renders any row this API created, and needs nothing pre-stored.

   **No `:public` scope, no `api-authenticate` change, and no company-override seam**
   were needed. The two-layer blocker this file used to describe was an artefact of the
   narrow reading.

   ⚠ **AND THE LINK CARRIES NO EXPIRY AND NO PASSWORD** — that is the *existing*
   behaviour of the shared URL, unchanged by this route, and it is what remains open if
   a revocation policy is ever wanted. The link is DETERMINISTIC (`generate-invoice-ext-url`
   uses tenant+invnum+vendor with no nonce), so the route writes nothing and does not
   populate `EXTERNAL_URL`; a GET must not write, and re-minting gives the identical
   value. Persisting the link, and expiry, only start to matter when revocation does.
4. **`/payment`** — a payment is a different कर्म (`DOD_PAYMENT_TRANSACTION`,
   `proc.finance`'s `pay`), and moving the header's `payment-status` /
   `payment-allocated` / `balance-due` columns is a cross-entity rule.
5. **`/send`** — the actor model's `send-email-async` path plus the invoice email
   templates; needs a 202/shape decision, not a ferry.
6. **`/download` — RESCOPED 2026-09-26: NO NEW PDF OR HTML PRODUCER IS NEEDED.** The
   earlier note ("what is missing is a PDF producer for the new entities") was wrong,
   and three measured facts replace it:

   1. **The tables are shared.** `nst-invh` mirrors `DOD_INVOICE_HEADER`, and the LEGACY
      view class is declared against the SAME table — `(clsql:def-view-class
      dod-Invoice-Header … (:BASE-TABLE dod_invoice_header))`
      (`invoice/nst-dal-ihd.lisp:691,945`). So a row the NEW API created is visible to
      the legacy renderer with no mapping step. Nothing about the new entities is
      invisible to the old pipeline.
   2. **The legacy public page therefore already prints them.** It selects by
      `invnum` + company through the legacy adapter (`InvoiceHeaderRequestModel` →
      `processreadrequest` → `DOD_INVOICE_HEADER`), so it renders any invoice row.
   3. **The pipeline is `generate-invoice-ext-url` → `downloadhtmlfile` → `generatepdf`**
      (`invoice/nst-ui-ihd.lisp:652,724`): the ext-url mints the base64
      `tenant-id,invnum,vendor-id` key, `downloadhtmlfile` **wgets it back over HTTP**,
      and `generatepdf` shells out to `wkhtmltopdf` (`core/dod-bl-utl.lisp:254`),
      returning a bare FILE NAME under `*HHUBRESOURCESDIR*/temp/`. An `nst-invh` row
      carries all three inputs (`tenant-id`, `invnum`, `vendor-id`), so the route needs
      no new domain code — only the fetch and the delivery.

   **So the ONE open question was delivery. DECIDED 2026-09-26 — and the endpoint is
   now IMPLEMENTED and bound**, as `route-invh-download` +
   `route-invh-download`'s binding in `invoice/nst-bl-invhapi.lisp` (the ninth of the
   twelve). The three options were:

   | option | seam change | chosen? |
   |---|---|---|
   | 302 to `<siteurl>/img/temp/<name>` | **none** | ✅ **TAKEN** — what the legacy handler does (`com-hhub-transaction-invoice-public-pdf` redirects); a redirect is a status + `Location`, no body. A client that follows redirects receives the PDF, which is what the spec asks for |
   | JSON `{"url": …}` | **none** | rejected — honest for a JSON API, but the spec says "return a print-ready PDF" |
   | real PDF bytes | **yes** | DEFERRED, not rejected: needs a new `:response-format` value, a bytes-aware writer beside `api-write-text` (`hhub/core/nst-bl-apidefs2.lisp:581`), and an octet-vector clause in `action->response` (`hhub/core/nst-bl-conflodis2.lisp:195` is `stringp`-only) — a change to the seam ALL 40 bound endpoints share. **It belongs in its own change with its own tests**, and it buys nothing the 302 cannot already deliver |

   **The redirect is issued from the Tier-2 route verb**, which is the HTTP adapter —
   not from the domain and not from the render layer. `hunchentoot:redirect` sets
   `Location` + status and calls `abort-request-handler`, which THROWS to hunchentoot's
   own catch tag; apidefs2's error handling intercepts *conditions*, not throws, so the
   redirect unwinds cleanly and no body is written. That is why
   `route-invh-download` never returns a value on its success path, and why its route
   declares `:success-status 302` as DOCUMENTATION rather than as a value apidefs2 uses.

   ⚠ **A nil vendor or tenant is a `:U` (503), never a `:F` (404)** —
   `invh-download-pdf-url` returns an `nst-entity-unknown` for it. The invoice exists
   (the caller fetched it under its own tenant), so "no such invoice" would be false, and
   the pipeline cannot proceed either. That is the `:U`-read-as-`:F` collapse this tree
   exists to prevent.

   ⚠ **AND ONE OPERATIONAL CATCH THAT IS NOT ABOUT THE API AT ALL.** `downloadhtmlfile`
   fetches `*siteurl*`, which is `"https://www.ninestores.in"`
   (`core/dod-ini-sys.lisp:57`) — a PUBLIC production URL. The pipeline is therefore not
   self-contained: it makes an outbound HTTP round-trip to the site to render its own
   page. On a dev host that means fetching PRODUCTION (or failing), so `/download`
   cannot be exercised anywhere `*siteurl*` does not resolve to the serving host. Worth
   knowing before choosing bytes-over-redirect, because both options inherit it.
7. **`/settings` — RESOLVED 2026-09-26, no longer open.** The blob has one writer
   (`!settings`, `vendor/nst-bl-vnd.lisp`) and now **two doors**: the original `PUT
   /hhub/api/v1/vendor/profile/{id}/invoice-settings`, and the spec's id-less `PUT
   /hhub/api/v1/invoices/settings` (`route-invh-settings-update`,
   `vendor/nst-bl-vndapi.lisp`), which delegates to the same verb. A second door is not
   a second writer, which was the actual objection.

   **The id-less path's target is the oracle that was missing.** It is NOT the tenant —
   a tenant may own several vendor rows, so "the vendor" is not implied by the session
   company and picking one would silently edit a sibling. It is the vendor identity the
   LOGIN established: `set-vendor-session-params` stores `:login-vendor`
   (`vendor/dod-ui-ven.lisp`), the same row the vendor UI works on and the row
   `dod-controller-vendor-switch-tenant` re-binds. So a vendor session names exactly one
   vendor.

   **`:row-id` is FORCED from the session and any inbound `:row-id` is dropped first**, so
   the body cannot move the address; a session with no vendor identity is refused with
   **401 and writes nothing** (fail closed). The binding lives in the VENDOR api file
   because a binding must follow its action-route registration in load order, and its
   URL is invoice-scoped while its verb is `nst-vnd`'s — the same reason the three
   `/invoices/{id}/items` bindings live in `nst-bl-invitmapi.lisp`.

   **Routing:** `/invoices/settings` and `/invoices/{id}` are both 5 segments and both
   match the same path, so `find-api-route` decides — and it RANKS FEWEST PARAMETERS
   FIRST, so the 0-parameter literal wins over the 1-parameter template
   deterministically. No registration-order trick is required.

   ⚠ **The suite cannot exercise the success path here**: the session vendor is vendor 1,
   the only row whose blob is not the migration seed, so a successful PUT would destroy
   it. Section 6 asserts routing, the domain's refusal, and that refusals leave the blob
   byte-identical (md5), and states the two paths it does NOT cover (success, and the
   401 fail-closed branch).
8. **No totals roll-up and no `issue` verb.** Adding or removing a line does not touch
   the header's `TOTALVALUE`, and `issue` — which must refuse a mismatch — does not
   exist.

---

## 7. Deliberate gaps in the code (not bugs)

- **No roll-up**: `TOTALVALUE` is whatever the caller supplied; the line verbs never
  adjust it, including `delete!`.
- **`:tenant-id` can be passed to a DIRECT `!update` call** and would move the row. The
  ferry strips it as reserved, so only the sanctioned path is protected; `nst-whs` and
  `nst-invh` share the hole. A one-line guard in all three is queued.
- **The "already deleted" branch in both `delete!`s is unreachable** — the select excludes
  soft-deleted rows, so a repeat delete answers 404 "not found". `nst-whs` has the same
  shape.
- **No `render-html` for the invoice entities**, so a `:html` dispatch of
  `route-invh-detail` would signal NO-APPLICABLE-METHOD. Every registered route is `:json`.
- **The Belnap sentinel ferry and the delete ack live in `warehouse/nst-bl-whsapi.lisp`
  §4**, which `nstores.asd` loads AFTER the invoice section. Every 404/409/503 from these
  routes depends on that file being loaded, and the ack type is still named
  `warehouse-ack-response`. Relocation to adhara is promised by whsapi's own FLAG.
- **A fourth copy of the row-id-from-string guard** (`invoice-item-row-id-from-string`).
  The promotion to adhara is queued as its own change, by the note in `nst-bl-invh.lisp`.
- **`INVNUM` is not settings-driven**: `make` mints a placeholder
  (`NST000<hhub-random-password 10>`); `invoice-general-settings`'
  `invoice-number-format` needs a counter decision.

---

## 8. Traps that cost real time in this session

1. **`DELETED_STATE` is `char(1) DEFAULT NULL`** on both invoice tables (unlike
   `DOD_WAREHOUSE`'s `'N'`), and the CLSQL classes declare `:void-value "N"`, so legacy
   rows hold SQL NULL. "Not deleted" must be `[= 'N'] OR [IS NULL]`; a plain `[= "N"]`
   hides every invoice in the system. And `[= … nil]` renders literal `= NULL`, which is
   true for no row at all — use `[is … nil]`.
2. **A binding must follow its registration IN LOAD ORDER.** `register-api-route` refuses
   a path whose action route is not registered yet. Offline checks are blind to this:
   `compile-file` does not evaluate load-time registrations, and a name-level audit
   ("is every bound route registered somewhere?") answers yes. The static stand-in that
   works: walk the build's own file order and assert each binding follows its
   registration.
3. **Loading a file into the live image can wedge class definition for the life of the
   process.** An in-image load that errors inside `ensure-class` parks its worker thread
   in the debugger holding SBCL's PCL global mutex; afterwards NOTHING can define a class
   or a struct. Symptoms seen: `compile.lisp` never finishing at its `defstruct`
   (line 23), and `compile-production` stopping after
   `Up to date, loading without recompiling: core/dod-dal-pas.lisp` (whose
   `def-view-class` is at line 10). **The log line precedes the load** — the file named
   last is the one it is stuck *in*. Restart is the only recovery. The agent-side tool
   that caused it was deleted; see §9.
4. **`INVNUM` IS `UNIQUE`** — the index is named `INVNUM` on column `INVNUM` with
   `NON_UNIQUE=0`, unique across ALL tenants. So `?exists` on the header IS backed by the
   database and not only by a business check, and a soft-deleted row still holds its
   number (`:C` → 409) because `DELETED_STATE` is not part of the key. **This corrects
   the first version of this note**, which claimed there was no UNIQUE constraint —
   measured against `INFORMATION_SCHEMA.STATISTICS`, 2026-09-26.
5. **The item URL puts `:invheadid` in the payload**, which `!update` refuses; the route
   verifies the pairing and strips it. Without the strip every nested PUT would 409.

---

## 9. How to verify — and the one rule about the live image

- **Offline, first:** the isolated `compile-file` recipe in `knowledge/build-and-load-CONTEXT.md`
  §6 (a throwaway SBCL; it caught unreadable parens, a docstring-terminating quote and the
  binding-order bug this session), `../tools/nst-symq` for any symbol question, and
  `../tools/nst-invoice-mirror-check.lisp` for anything touching the invoice response
  models (it executes the `setf` that `compile-file` cannot).
- **✅ THERE IS NOW A FULL OFFLINE SYSTEM LOAD, and it is the strongest check available
  without a restart.** It was previously recorded here as impossible; that was wrong, and
  the reasoning is preserved below because the three earlier blockers are real and will
  bite again. `../tools/nst-offline-load.lisp` loads the whole system — every प्रत्यय, the
  ferries, `domain->response`, `render-json` — connected to the REAL database, with no web
  server and no acceptor (it never calls `start-das`). `../tools/nst-verify-invoice-offline.lisp`
  then drives the ACTUAL route functions and asserts the suite's contract. Measured
  2026-09-26: **32 pass / 0 fail**, and it writes nothing.
  * It proved the 500 fix end-to-end: `fetch 'nst-invh "23" ctx` → `domain->response` →
    `render-json` → JSON, the exact call that used to signal MISSING-SLOT.
  * It reached the settings route's **fail-closed 401** branch, which the smoke suite
    states it cannot cover.
  * **FINAL COVERAGE: 51 checks.** Added last: the `/download` SUCCESS path, with the two
    external producers stubbed — it proves the route mints the sessionless ext-url, calls
    the producer, and redirects to `<siteurl>/img/temp/<file>`. It does NOT prove a PDF is
    produced; that needs the real pipeline and `*siteurl*` pointing at the serving host.
    **Every path in the invoice API has now been executed at least once.** What no offline
    harness can reach — apidefs2's HTTP routing, the hunchentoot session, the response
    writers — is still only checked by the smoke suite over HTTP.
  * Expanded 2026-09-26 to **47 checks** covering every refusal the suite asserts but
    that had never been executed: PUT on an absent/foreign invoice, the non-ISO and
    impossible dates, the (header, line) pairing on BOTH update and delete, absent lines,
    and — the one contract with NO test anywhere — **DELETE of a line whose invoice is not
    a DRAFT, which is a `:C` (409)**, not a 404. That assertion is now in the suite too.
  * It MEASURED the suite's KNOWN K2: a repeat delete returns `nst-entity-nil` (404),
    exactly as the script claims, so the KNOWN is verified rather than assumed.
  * It caught a real 500 path in that same route: `hunchentoot:session-value` signals
    UNBOUND-VARIABLE outside an HTTP request, so the probe is now guarded and any failure
    to establish an identity is a 401 with nothing written.
  * The four setup requirements — no `:depends-on` in the asd; swank quickloaded first;
    a WRITABLE COPY of the clsql dist; and the `hhub-bl-ent`/`dod-ini-sys` load order —
    are documented in the tool's header, with the traps.
  * ⚠ `cp -r` of the live image's ASDF cache does NOT work: it gives every fasl a fresh
    mtime, so ASDF loads stale fasls and the failure looks like a source bug. Compile from
    source into a fresh `XDG_CACHE_HOME`.
  * The four blockers originally recorded here, kept because they are all still true:
    1. `hhub/nstores.asd` **has no `:depends-on`**; `startup/load.lisp` quickloads the 16
       dependencies first. Without that the build dies inside `core/dod-dal-bo.lisp` with
       *"Package CLSQL does not exist"*.
    2. `XDG_CACHE_HOME` must be writable (the file sandbox denies `~/.cache`).
    3. **`clsql-mysql` cannot be loaded by a non-owner** — its asd writes the foreign
       library into a source directory owned by `hunchentoot`, failing as an opaque
       `OPERATION-ERROR` that never mentions permissions.
    4. `init.lisp` quickloads **swank** before anything else and the tree reads the package
       at compile time; without it, *"READ error: Package SWANK does not exist"*.
- **Against the running server:** you need a session cookie
  (`POST /hhub/dodvendlogin`; 302 for both success and failure — read `Location`, and
  remember the 2-concurrent-login cap and that sessions are bound to User-Agent + IP),
  then exercise the ten bound endpoints and compare against the spec's descriptions.
  `(list-api-routes)` and `(list-action-routes)` are the in-image diagnostics.
  * Credentials that work: **phone `9999999990`, password `Welcome1`** — vendor row-id 1,
    tenant 2. `Welcome1` works because the password defect is still live
    (PENDING-WORK §1); do not read that as a valid credential check.
  * **`NS_EXPECT_U=1 ./hhub/test/smoke-invoice-api.sh`** is the GATED run for the fourth
    state. It pauses after login so the database can be stopped, then asserts that a
    database that did not answer is **503, not 404**, on the list, the aggregate read,
    the public view and the download — and that present and absent are BOTH 503, i.e.
    ignorance does not collapse into absence. Nothing else in the suite can reach that
    state, so it is the only proof of the `:U` contract.
- **DO NOT drive the image's Swank from an agent.** The tool that did
  (`tools/swank-eval.py`) was deleted on 2026-09-26 after it wedged the image (§8.3), and
  `knowledge/build-and-load-CONTEXT.md` §9 now says the same. Use the human's own SLIME
  for interactive work, and pure forms only — never `load`/`compile` a file into the
  live image from outside.

---

## 10. Offered, not done

- **`~/.dsh/AGENTS.md`** still lists `swank-eval.py` as required tooling and claims it is
  *"the only way to check a changed `hhub/` file"* — it is not (§9), and the file is gone.
  The agent cannot write outside the workspace; a human has to fix that line.
- **`hhub/invoice/nst-bl-gstr1.lisp`** and the GSTR-1 tooling are committed but were never
  run against a session either — the collector's section-splitting rule is recorded as
  *not yet applied* in `knowledge/gstr1-json-reference-CONTEXT.md`.
- **Uncommitted and older than this work:** the five `paninigrammar/*.md` design documents
  (cited by name in the grammar code — a clone would lack them), the customer-user UI
  files (2026-09-22), `installation/pve-nic-tune.sh`, and a pile of scratch artifacts
  (`hhub/core/out.txt`, `nst-bl-ollama.lisp.bak`, `dod-ui-ord.lisp.orig`/`.rej`,
  `hhub/temp/*`).
- **An item-side HTML view** and a decision on whether any route should expose item
  `?exists` (currently: no — see §5.7).
