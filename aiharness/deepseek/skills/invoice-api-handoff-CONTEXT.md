# SKILL: Handoff — the invoice API (session of 2026-09-25/26) · CONTEXT

**Read this when:** you are picking up the invoice API — designing the endpoints the spec still
wants, wiring or debugging an invoice route, or wondering whether any of it has actually run. This
file is the STATE OF PLAY: what is bound, what has been exercised and when, what is open and what
blocks each item. Everything mechanical is `knowledge/invoice-api-reference-CONTEXT.md` (endpoints
§1 · addressing §2 · shapes and error vocabulary §3 · `/download` and `/public` §4 · the two
load-time traps §5–§6 · the offline recipe §7 · the measured route traps §8).

**Status: the API is LIVE and the smoke suite is GREEN** (updated 2026-09-26, after the reload).
`GET /hhub/api/v1/invoices` answers **200** where it answered 500 for the whole of §1b; **ten** of
the spec's twelve endpoints are bound; the suite passes **62/0 read-only** (81/0 with `--write`),
three documented KNOWNs, nothing unexpected — §1b's fix is verified against the running image, not
just offline. Consolidated **2026-10-05**: 693 lines → this file + the reference above, nothing
deleted; no fact is stated in both.

**Applies to:** `hhub/invoice/`, `hhub/test/smoke-invoice-api.sh`, the invoice bindings, and the
live hunchentoot image. Orders, products and the warehouse are other files' territory.

---

## 1. State of play — the running system (verified 2026-09-26 ≈09:20, then after the reload)

| Check | Result |
|---|---|
| Lisp image | restarted 2026-09-26; pid **1915**, up since ≈07:54 (the earlier process was wedged — reference §6) |
| `compile-production` (00:08:11) | **`Failed: 0`**. The two api files compiled with style warnings only (17 + 7) — the expected cross-file undefined-function notes |
| ASDF build | `…/cache/…/hhub/invoice/nst-bl-invhapi.fasl` at **07:54**, i.e. the restart compiled and loaded the invoice files |
| `GET /hhub/api/v1/invoices`, no session | **401** — which proves the *binding resolves* (an unknown path answers `404 no_such_endpoint`) and that `api-authenticate` rejects it |
| Any authenticated call | **never run** at the time of this table. §1b is what happened when the first one ran: a 500 on every route |
| After the §1b fix + reload (2026-09-26) | **200** with a JSON array; suite **62/0** read-only, **81/0** `--write` |

🚨 **AND THE IMAGE THAT ANSWERED 401 WAS RUNNING A DIFFERENT TREE FROM THE ONE ON DISK.** It
started at **07:54**; commit **`d6275d0` landed at 09:01:11** and changed both build lists
(`dod-ini-sys` above `hhub-bl-ent`, which broke the cold boot — PENDING-WORK §1c, fixed). So that
image was NOT evidence about the current sources, and its health was not evidence that a restart
would succeed — it proved only that the OLD order boots. **The durable rule: compare the process's
start time against the last build-list commit before trusting a running image.**

---

## 1b. The first exercise — and the 500 it found (2026-09-26)

`hhub/test/smoke-invoice-api.sh` was written and run. **Every authenticated invoice route answered
500 internal_error**, for a reason nothing offline could have seen:

```
condition: the slot COM.NSTORES.APP::DELETED-STATE is missing from
           #<COM.NSTORES.APP::NSTINVHRESPONSEMODEL>
```

`domain->response` for `nst-invh` drives its setfs from `*invh-mirrored-slots*`
(`nst-bl-invh.lisp:685`), and that list names `deleted-state` (line 631) — but neither
`NstInvhResponseModel` nor `NstInvitmResponseModel` declared the slot, so the `setf` signalled
MISSING-SLOT on every header AND line response. **The load path was proven and the surface was live
while nothing behind a session could ever work**, which is why it stayed undiscovered until a suite
exercised it.

**FIXED in source** (`nst-dal-invh.lisp`, `nst-dal-invitm.lisp`): both response models now declare
`(deleted-state :initarg :deleted-state :accessor deleted-state)`. Verified by diffing all 53 + 18
mirrored slots against both models: exactly ONE slot was missing per side, and nothing else.
`render-json` was left untouched, so it still does not reach the wire — the same split
`WarehouseResponseModel` uses (`nst-dal-warehouse.lisp:513` declares it, `nst-bl-warehouse.lisp`
does not publish it). **STATUS: VERIFIED LIVE 2026-09-26** — 200 where it answered 500, suite 62/0 and 81/0 `--write`.
The offline proofs came first and are reproducible from `../tools/nst-invoice-mirror-check.lisp`
(`aiharness/deepseek/tools/nst-invoice-mirror-check.lisp`): `compile-file` with `failure-p=NIL` on
both DAL files, and — the one that matters, since `compile-file` never evaluates the failing `setf`
— an isolated SBCL loading `packages.lisp`, `nst-bl-adhara.lisp` and both DAL files, whose **53/53
header and 18/18 item slots setf cleanly**; remove the slot from a throwaway copy and it reports
`MISSING on RESPONSE = (DELETED-STATE)`, `52/53`, and exits 1.

The other defects the FIRST execution of each route found — the create's mandatory row-id, the
integer-for-a-decimal `(OR NULL FLOAT)` insert, the `:void-value (clsql:get-time)` form that made
every header UPDATE a 503, and the `?sort-by` refusal that reported as a 500 instead of 400 — are
**reference §8 and §3**, with the harness that found them. Until a reload, the suite bails at
section 1 with a diagnosis and every read below it is UNRUN; do NOT load the changed files into the
live image (reference §6).

### THE COLD-BOOT FIX, CORRECTED: move the METHOD, not the file

The first version REORDERED the build and **was reverted — the build lists are UNCHANGED**. The
blocker is fixed in CODE: `initBusinessContexts` (its `defgeneric` and its one `defmethod`, which
specialize on `BusinessServer`/`BusinessContext`) was MOVED OUT of `core/dod-ini-sys.lisp` INTO
`core/hhub-bl-ent.lisp`, beside the classes it specializes on; `dod-ini-sys` keeps only its runtime
CALL to it, inside `initBusinessServer`. The load order satisfies all three constraints at once,
which no reordering could: the `with-bo-knowledge-check` macro (expansion binds `payload`) before
`hhub-bl-ent`, so `nst-bl-beltrusys` (21) < `hhub-bl-ent` (22); classes before the method that
specializes on them (a defmethod installs its specializer at LOAD time — both now in ONE file); and
`dod-ini-sys` (13) early for the globals later files read. **VERIFIED: `STAGE: LOADED`** from
`../tools/nst-offline-load.lisp`, the legacy read returns an `INVOICEHEADER`, and the dispatch
harness passes **51/0**. Full account, and what remains (commit it, then a real restart):
`PENDING-WORK-CONTEXT.md` §1c.

### The root cause was a comment

`nst-bl-invh.lisp` used to say, of the mirror list: *"ADD A NEW COLUMN HERE, in this one list.
**Nothing else needs to change** for the column to survive a create, a fetch and an update."* That
is false, and it is why `deleted-state` was ever in the hole. The list drives **three** consumers,
not two: the two copiers AND `domain->response`. The comment now says so, and names the symptom,
because the error surfaces in a file nobody edited. Related: this list-driven `domain->response`
form exists **only** for the two invoice entities — `nst-whs`'s is longhand, one `setf` per field, so
warehouse cannot drift this way, which is why nothing had a reason to check for it.

### 🚨 TWO REGRESSIONS THE INVOICE WORK INTRODUCED, AND BROKE THE VENDOR UI (2026-09-26)

Both surfaced as **"the invoice page on the UI is broken"**, and both were mine. They are recorded
together because they are the two ways a NEW domain can silently damage the LEGACY DDD layer that
still shares its process, package and files.

**1. A FUNCTION-NAME COLLISION REPLACED A LEGACY FUNCTION.** `nst-bl-invh.lisp` defined
`select-invoice-header-by-invnum`, a name `nst-bl-ihd.lisp:21` already uses — with a DIFFERENT
signature (legacy: `(invnum company)` taking a DOD-COMPANY object; mine:
`(invnum tenant-id &key include-deleted)`). Both are plain defuns in one package, and `nst-bl-invh`
loads LATER (asd 140 vs 130), so MINE WON and the legacy readers (`nst-bl-ihd.lisp:323, :370, :406`)
began passing a company object into a tenant-id parameter. CLSQL refused it:
`No type conversion to SQL for DOD-COMPANY is defined for DB MYSQL-DATABASE` — the read returned a
Belnap sentinel, and the legacy callers dereference it: `MISSING-SLOT ROW-ID … #<BUSINESSOBJECTUNKNOWN>` from
`select-all-invoice-items`. **FIXED by renaming mine to `nst-select-invoice-header-by-invnum`.** ⚠
The file's own header already states this rule for the CLASSES; it applies just as much to helper
FUNCTIONS. **Check for collisions before adding a defun to a new domain.** ⚠ A second, currently
harmless duplicate exists: `domain->response-list` is defined in both `nst-bl-invh.lisp` and
`nst-bl-warehouse.lisp` with identical bodies (warehouse wins), left in place rather than silently
tidied — the same trap.

**2. MOVING `hhub-bl-ent` EARLIER BROKE A MACRO EXPANSION.** The reverted cold-boot fix moved
`core/hhub-bl-ent` above `core/dod-ini-sys`, which also put it ABOVE `core/nst-bl-beltrusys` — and
`hhub-bl-ent` uses that file's `with-bo-knowledge-check` macro, whose expansion is what binds
`payload` (`with-slots (truth payload …)`). Compiled without the macro available, the form became a
FUNCTION CALL whose arguments include `payload` — unbound — so **every successful legacy read raised
`The variable PAYLOAD is unbound`**, taking the vendor invoice pages and the public invoice page
down. **FIXED by NOT reordering at all.**

**ATTRIBUTION METHOD, worth reusing:** both had to be separated from a PRE-EXISTING defect on the
same path, and two timestamped logs answer it — `~/hhublogs/ninestores-messages.log` and
`~/hhublogs/ninestores-busfunctions.log`. `No type conversion to SQL for DOD-COMPANY` appears on
**2026-07-24** and **2026-09-25 19:42**; `PAYLOAD is unbound` on **2026-03-02/03** and
**2026-08-29**; but `MISSING-SLOT ROW-ID … BUSINESSOBJECTUNKNOWN` appears ONLY from 15:07 today —
the fact that identified the regression as new. **Check the logs before believing either "it was
always broken" or "you broke it".**

### Fixtures and credentials (verified live, 2026-09-26)

* The suite logs in as phone **9999999990 / `Welcome1`** — the vendor row-id 1, tenant 2. `Welcome1`
  works because the password defect is still live (PENDING-WORK §1).
* Tenant-2 invoices: **23** = DRAFT with 4 lines (the aggregate read's happy path); **33/34/36** =
  DRAFT with 0 lines; **35** = PENDINGPAYMENT with 6 lines (the 409 fixture); **21/22** = TENANT 5
  (the BOLA fixture). Max header row-id 36, max line 247.
* 🚨 **`INVNUM` is `UNIQUE`**, so the `:C`/409 on a duplicate is a DATABASE guarantee and not only
  a `make :around` business check — and the earlier claim that no such key existed is corrected
  (reference §8.2).

---

## 2. What shipped

Four commits carry the invoice API (plus eight others from the same two days: the symbol DAG
tooling, the vendor `!settings` sub-resource, the smoke-script host rename, argon2id passwords,
GSTR-1, and three documentation commits).

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
| **The smoke suite for the bound endpoints** — read-only by default, `--write` for the lifecycle, and the only thing that has ever exercised these routes over HTTP | `hhub/test/smoke-invoice-api.sh` |
| **The API spec** (12 Invoicing endpoints, domain `id:'inv'`, role Vendor) | `hhub/core/nstoresapi.html` — a JS table `{m,p,d}`; grep for `id:'inv'` |
| The invoice code, end to end | DAL `hhub/invoice/nst-dal-invh.lisp` + `hhub/invoice/nst-dal-invitm.lisp` · Tier-1 verbs `hhub/invoice/nst-bl-invh.lisp` + `hhub/invoice/nst-bl-invitm.lisp` · Tier-2 routes and bindings `hhub/invoice/nst-bl-invhapi.lisp` + `hhub/invoice/nst-bl-invitmapi.lisp` · dispatcher `hhub/core/nst-bl-conflodis2.lisp` · JSON boundary and status mapping `hhub/core/nst-bl-apidefs2.lisp` |
| **The reference implementation to copy** | `hhub/warehouse/nst-bl-whsapi.lisp` (and `hhub/vendor/nst-bl-vndapi.lisp`) |
| Design authority for the route tier · the API layer's own context (§9.4: `?exists` cannot cross the ferry) · the grammar the verbs obey | `knowledge/nst-bl-conflodis2-DESIGN.md`, `knowledge/nst-bl-apidefs2-CONTEXT.md`, `knowledge/WAREHOUSE-NST-GRAMMAR-CONTEXT.md` |
| Deferred items, with file:line sites | `PENDING-WORK-CONTEXT.md` |

---

## 4. The twelve spec endpoints, and which ten exist

**Ten bound, two not.** Bound: the four `/invoices` routes, the three `/invoices/{id}/items` routes,
and the three added on 2026-09-26 (`/settings`, `/download`, `/public`). Not bound: `/payment` and
`/send`, which need a new कर्म or an actor job rather than a decision (§6.4, §6.5). Registered but
deliberately unbound: the invoice DELETE and the fetch-by-invoice-number read. **The full table, with
every route name and its bound date, is `knowledge/invoice-api-reference-CONTEXT.md` §1.**
Addressing — which segment carries what, why the number and not the row-id, and the route-layer
resolution that forces: reference §2.

---

## 5. Decisions already made — do not re-litigate

1. **Templates carry `/hhub`; the spec's paths do not.** nginx rewrites everything to `/hhub/$1`,
   and `register-api-route` rejects a template without the prefix.
2. **No `:inject-company` on any invoice binding.** `nst-invh`/`nst-invitm` read the inherited
   `tenant-id` from `domain-ctx`; unlike `nst-whs` they carry no legacy `COMPANY` slot.
3. **Path params beat the body**, which is why a body-supplied `row-id`/`invheadid` cannot displace
   the URL (the merge that forces this, and its consequence: reference §2).
4. **The line routes verify the (header, line) PAIRING** and 404 on a mismatch; and `:invheadid` is
   stripped before `!update`, which refuses it by design.
5. **Content vs. values** decides the status rules: `make`/`delete!` on a line require a DRAFT
   header; `!update` is allowed at any status.
6. **The aggregate `GET /{id}`** is decision 6: the shape it returns, and the `action->response`
   pass-through that carries it, are reference §3.
7. **`?exists` is not a uniqueness check** for either entity — a duplicate product line is
   legitimate, and no route exposes it. ⚠ This decision's old parenthetical, that `INVNUM` has no
   UNIQUE key, is **wrong** (reference §8.2).
8. **Dates at the API are ISO `YYYY-MM-DD`**, coerced at the route layer; anything else is a 400.

---

## 6. The design work that is genuinely open

1. **A compound `create-with-lines` write.** Its response shape is settled (decision 6); the blocker
   left is **atomicity** — `*action-route-transaction-function*` is a no-op, so a header could be
   written and line 3 refused.
2. **The GST breakdown** the spec lists under `GET /{id}`. Derivable from the line tax columns, but
   it is a DOMAIN computation: put it in `nst-bl-invh.lisp` beside the verbs, not in a render fold.
   The legacy `generate-gst-tax-breakdown` works on the OLD business objects (`nst-dal-itm.lisp`'s
   `add-item-to-tax-breakdown`).
3. **`/public` — RESOLVED 2026-09-26.** It never needed the `:public` auth scope; the mechanism and
   the BOLA argument are reference §4.2. ⚠ The link itself changed on 2026-10-03 — signed,
   five-minute expiry, password-gated; owner `knowledge/invoice-public-link-CONTEXT.md`.
4. **`/payment`** — a payment is a different कर्म (`DOD_PAYMENT_TRANSACTION`, `proc.finance`'s
   `pay`), and moving the header's `payment-status` / `payment-allocated` / `balance-due` columns is
   a cross-entity rule. **Blocker: the कर्म does not exist.**
5. **`/send`** — the actor model's `send-email-async` path plus the invoice email templates; needs a
   202/shape decision, not a ferry. **Blocker: that decision.**
6. **`/download` — RESCOPED and BOUND 2026-09-26.** No new producer was needed and delivery is a
   **302** (reference §4.1). ⚠ **Its real success path is blocked by a PRE-EXISTING defect**: the
   legacy public page answers 500 for every invoice since at least 2026-05-23, so the wget inside the
   pipeline fails — `PENDING-WORK-CONTEXT.md` §1e, which is why the suite carries it as a KNOWN.
7. **`/settings` — RESOLVED 2026-09-26.** One writer (`!settings`, `vendor/nst-bl-vnd.lisp`), two
   doors: the vendor sub-resource `PUT`, and the spec's id-less `PUT /hhub/api/v1/invoices/settings`
   (`route-invh-settings-update`, `vendor/nst-bl-vndapi.lisp`), which delegates to the same verb — a
   second door is not a second writer. **The id-less path's target is the vendor identity the LOGIN
   established** (`set-vendor-session-params`'s `:login-vendor`, `vendor/dod-ui-ven.lisp` — the row
   the vendor UI works on and the row `dod-controller-vendor-switch-tenant` re-binds) — not the
   tenant, which may own several vendor rows; `:row-id` is FORCED from the session, any inbound
   `:row-id` is dropped, and a session with no vendor identity is refused **401 and writes nothing**.
   `/invoices/settings` and `/invoices/{id}` both match 5 segments, and `find-api-route` ranks the
   0-parameter literal first, so no registration-order trick is needed (the ranking rule itself is
   owned by `knowledge/api-params-and-route-matching-CONTEXT.md` §2). The binding lives in the
   VENDOR api file because it must follow its action-route registration in load order (reference
   §5), and its URL is invoice-scoped while its verb is `nst-vnd`'s — the same reason the three
   `/invoices/{id}/items` bindings live in `nst-bl-invitmapi.lisp`. ⚠ **The suite cannot
   exercise the success path** (the session vendor is vendor 1, the only row whose blob is not the
   migration seed): it asserts routing, the domain's refusal and md5-identical blobs on refusal, and
   states the two paths it does not cover — success, and the 401 fail-closed branch, which the
   offline harness does reach (reference §7).
8. **No totals roll-up and no `issue` verb.** Adding or removing a line does not touch the header's
   `TOTALVALUE`, and `issue` — which must refuse a mismatch — does not exist.

---

## 7. Deliberate gaps in the code (not bugs)

- **No roll-up**: `TOTALVALUE` is whatever the caller supplied; the line verbs never adjust it,
  including `delete!`.
- **`:tenant-id` can be passed to a DIRECT `!update` call** and would move the row. The ferry strips
  it as reserved, so only the sanctioned path is protected; `nst-whs` and `nst-invh` share the hole.
  A one-line guard in all three is queued (the body-supplied `invnum` is the same shape — reference
  §2).
- **The "already deleted" branch in both `delete!`s is unreachable** — the select excludes
  soft-deleted rows, so a repeat delete answers 404 "not found". `nst-whs` has the same shape.
- **No `render-html` for the invoice entities**, so a `:html` dispatch of `route-invh-detail` would
  signal NO-APPLICABLE-METHOD. Every registered route is `:json`.
- **The Belnap sentinel ferry and the delete ack live in `warehouse/nst-bl-whsapi.lisp` §4**, which
  `nstores.asd` loads AFTER the invoice section — so every 404/409/503 from these routes depends on
  that file being loaded, `warehouse-ack-response` is still the ack type, and the promised relocation
  to adhara has not happened (bodies, producers and the type: reference §3).
- **A fourth copy of the row-id-from-string guard** (`invoice-item-row-id-from-string`). The
  promotion to adhara is queued as its own change, by the note in `nst-bl-invh.lisp`.
- **`INVNUM` is not settings-driven**: `make` mints a placeholder
  (`NST000<hhub-random-password 10>`); `invoice-general-settings`' `invoice-number-format` needs a
  counter decision — and the trigger that overwrites the column anyway is
  `PENDING-WORK-CONTEXT.md` §1d.

---

## 8. Traps — moved 2026-10-05

Measured in this session, now owned by `knowledge/invoice-api-reference-CONTEXT.md`: §5 **a binding
must follow its registration IN LOAD ORDER** · §6 **an in-image load can wedge class definition for
the life of the process** · §8.1 `DELETED_STATE` is `char(1) DEFAULT NULL` · §8.2 `INVNUM` is
`UNIQUE` · §8.3 the item URL's `:invheadid` is verified-then-stripped.

---

## 9. How to verify — and the one rule about the live image

- **Offline:** the recipe, the tools, the setup requirements and the measured coverage are reference
  §7 (general method: `knowledge/offline-checker-methodology-CONTEXT.md`). The isolated compile-check
  recipe itself is `knowledge/build-and-load-CONTEXT.md` §6.
- **Against the running server:** you need a session cookie (`POST /hhub/dodvendlogin`; 302 for both
  success and failure — read `Location`, and remember the 2-concurrent-login cap and that sessions
  are bound to User-Agent + IP), then exercise the ten bound endpoints and compare against the
  spec's descriptions. `(list-api-routes)` and `(list-action-routes)` are the in-image diagnostics.
  * Credentials that work: **phone `9999999990`, password `Welcome1`** — vendor row-id 1, tenant 2.
    `Welcome1` works because the password defect is still live (PENDING-WORK §1); do not read that as
    a valid credential check.
  * **`NS_EXPECT_U=1 ./hhub/test/smoke-invoice-api.sh`** is the GATED run for the fourth state: it
    pauses after login so the database can be stopped, then asserts that a database that did not
    answer is **503, not 404**, on the list, the aggregate read, the public view and the download —
    and that present and absent are BOTH 503, i.e. ignorance does not collapse into absence. It is
    the only proof of the `:U` contract.
- **DO NOT drive the image's Swank from an agent.** The tool that did (`tools/swank-eval.py`) was
  deleted on 2026-09-26 after it wedged the image (reference §6);
  `knowledge/build-and-load-CONTEXT.md` §9 says the same. Use the human's own SLIME, pure forms only
  — never `load`/`compile` a file into the live image.

---

## 10. Offered, not done

- **`~/.dsh/AGENTS.md`** still lists `swank-eval.py` as required tooling and claims it is *"the only
  way to check a changed `hhub/` file"* — it is not (§9), and the file is gone. The agent cannot
  write outside the workspace; a human has to fix that line.
- **`hhub/invoice/nst-bl-gstr1.lisp`** and the GSTR-1 tooling are committed but were never run
  against a session either — the collector's section-splitting rule is recorded as *not yet applied*
  in `knowledge/gstr1-json-reference-CONTEXT.md`.
- **Uncommitted and older than this work:** the five `paninigrammar/*.md` design documents (cited by
  name in the grammar code — a clone would lack them), the customer-user UI files (2026-09-22),
  `installation/pve-nic-tune.sh`, and a pile of scratch artifacts (`hhub/core/out.txt`,
  `nst-bl-ollama.lisp.bak`, `dod-ui-ord.lisp.orig`/`.rej`, `hhub/temp/*`).
- **An item-side HTML view** and a decision on whether any route should expose item `?exists`
  (currently: no — see §5.7).
