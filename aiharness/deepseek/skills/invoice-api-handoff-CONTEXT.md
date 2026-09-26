# Handoff — the invoice API (session of 2026-09-25/26) · CONTEXT

**Read this when:** you are picking up the invoice API — designing the endpoints the
spec still wants, wiring or debugging an invoice route, or wondering whether any of it
has actually run. Read it BEFORE the code: §1 is the state of the running system, and
§5–§6 are the decisions already taken versus the ones still open.

**Status in one line:** the entity classes, the twelve प्रत्यय and the Tier-2 routes are
committed; seven of the spec's twelve endpoints are bound and the dispatcher answers
for them; **nothing has been exercised with a session** — no verb has run against the
database through these routes.

---

## 1. State of the running system — verified 2026-09-26 ≈09:20

| Check | Result |
|---|---|
| Lisp image | restarted; pid **1915**, up since ≈07:54 (the earlier process was wedged — see §8.3) |
| `compile-production` (00:08:11) | **`Failed: 0`**. The two api files compiled with style warnings only (17 + 7) — the expected cross-file undefined-function notes |
| ASDF build | `…/cache/…/hhub/invoice/nst-bl-invhapi.fasl` at **07:54**, i.e. the restart compiled and loaded the invoice files |
| `GET /hhub/api/v1/invoices`, no session | **401** — which proves the *binding resolves* (an unknown path answers `404 no_such_endpoint`) and that `api-authenticate` rejects it |
| Any authenticated call | **never run.** No create, list, detail, update, or line CRUD has been executed even once |

So the load path is proven and the surface is live; everything behind a session cookie
is UNRUN. That is the first real task for a new session (§9).

---

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

## 4. The twelve spec endpoints, and which seven exist

| Spec endpoint | Bound? | Route |
|---|---|---|
| `POST /api/v1/invoices` (201) | ✅ | `route-invh-create` |
| `GET /api/v1/invoices` | ✅ | `route-invh-list` |
| `GET /api/v1/invoices/{id}` | ✅ | `route-invh-detail` (the aggregate read, §5) |
| `PUT /api/v1/invoices/{id}` | ✅ | `route-invh-update` |
| `POST /api/v1/invoices/{id}/items` (201) | ✅ | `route-invitm-create` |
| `PUT /api/v1/invoices/{id}/items/{item-id}` | ✅ | `route-invitm-update` |
| `DELETE /api/v1/invoices/{id}/items/{item-id}` | ✅ | `route-invitm-delete` |
| `POST /api/v1/invoices/{id}/payment` | ❌ | a different कर्म — no प्रत्यय exists (§6.4) |
| `POST /api/v1/invoices/{id}/send` | ❌ | actor model, not a domain verb (§6.5) |
| `GET /api/v1/invoices/{id}/download` | ❌ | no PDF producer for the new entities (§6.6) |
| `GET /api/v1/invoices/{id}/public` | ❌ | **no `:public` auth scope exists** (§6.3) |
| `PUT /api/v1/invoices/settings` | ❌ | already implemented on the vendor profile (§6.7) |

Also registered but deliberately unbound: `route-invh-delete` (the spec defines no
invoice DELETE — consistent with the DRAFT-only rule) and `route-invh-fetch-by-invnum`
(the read that can answer `:C`; the spec has no endpoint for it).

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
3. **A `:public` auth scope** for `/public`. `api-authenticate` handles `:session` only
   and signals *unknown auth scope* otherwise, so this endpoint cannot be bound at all
   today. The live-link mechanism (external-url, expiry, password) is undecided too.
4. **`/payment`** — a payment is a different कर्म (`DOD_PAYMENT_TRANSACTION`,
   `proc.finance`'s `pay`), and moving the header's `payment-status` /
   `payment-allocated` / `balance-due` columns is a cross-entity rule.
5. **`/send`** — the actor model's `send-email-async` path plus the invoice email
   templates; needs a 202/shape decision, not a ferry.
6. **`/download`** — apidefs2 has the seam (`:response-format :csv` + `:content-type`
   + the dispatcher's string pass-through); what is missing is a PDF producer for the
   new entities.
7. **`/settings`** — already implemented as `PUT
   /hhub/api/v1/vendor/profile/{id}/invoice-settings` (verified end to end, writing
   `DOD_VEND_PROFILE.INVOICE_SETTINGS`). Binding it again would create a second writer
   for one blob; the spec's *placement* is what needs reconciling.
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
4. **`INVNUM` has only a plain KEY**, no UNIQUE constraint, so `?exists` on the header is
   a business check, not a database guarantee — and a soft-deleted row still holds its
   number (`:C` → 409).
5. **The item URL puts `:invheadid` in the payload**, which `!update` refuses; the route
   verifies the pairing and strips it. Without the strip every nested PUT would 409.

---

## 9. How to verify — and the one rule about the live image

- **Offline, first:** the isolated `compile-file` recipe in `knowledge/build-and-load-CONTEXT.md`
  §6 (a throwaway SBCL; it caught unreadable parens, a docstring-terminating quote and the
  binding-order bug this session), and `../tools/nst-symq` for any symbol question.
- **Against the running server:** you need a session cookie
  (`POST /hhub/dodvendlogin`; 302 for both success and failure — read `Location`, and
  remember the 2-concurrent-login cap and that sessions are bound to User-Agent + IP),
  then exercise the seven bound endpoints and compare against the spec's descriptions.
  `(list-api-routes)` and `(list-action-routes)` are the in-image diagnostics.
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
