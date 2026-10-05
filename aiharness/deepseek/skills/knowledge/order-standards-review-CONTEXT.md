# SKILL: The order API's standards review — twenty findings and their dispositions

**Read this when:** you are about to change the behaviour, the authorization or the error handling of
an order endpoint (`/orders…`, `/vendor/orders…` on the adhara grammar) and need to know which
standards findings already landed on this code, which are accepted risks, and which are still
undecided — or you are looking for the reasoning behind the non-sequential `{ref}` document number.

**Status: review of 2026-09-28, moved out of `../order-adhara-stories-CONTEXT.md` §10 on 2026-10-05
(nothing deleted, nothing added).** The batch's story list, decisions D1–D21 and traps stay in that
file; §10 there is now a pointer to this one. Where a disposition names a story (S0d, S3, S4, S5, S12,
S13) that story's record is in the story file.

**Applies to:** `hhub/order/nst-bl-ordh.lisp`, `nst-bl-orditm.lisp`, `nst-bl-vordh.lisp` and their
`*-api.lisp` bindings; the seeds in `hhub/core/dod-ui-pol.lisp`; the number mint in
`hhub/core/dod-bl-utl.lisp`; and — for F4, F19, F20 — files outside this batch, cross-referenced rather
than owned here.

---

## 10. Standards review — OWASP API Top 10 · NIST 800-53/800-63B · Google AIP · RFC · 2026-09-28

**Read this before writing the first story.** Twenty findings: nineteen about this batch (**the table
below**) and one pre-existing defect the review happened to walk into (**F20**, after the table — live
credentials in source, not caused by this work). **F1–F6 change acceptance criteria in stories we are
about to write**, so they are settled as decisions here rather than discovered during
implementation. Nothing here challenges the architecture: the grammar, the four Belnap states, the
ferry and the reserved-initarg filter came through the review clean.

**What the design already gets right** — recorded so this section is not misread as a list of failures:
- **No SQL-injection surface.** Every predicate is a parameterised CLSQL form (`[= [:ordnum] v]`), and
  `sort-by` cannot reach `ORDER BY` because of the whitelist — the classic hole, closed by construction.
- **No mass assignment of the tenant.** `*reserved-initargs*` strips `:tenant-id`/`:id`/`:created-at`/
  `:updated-at`/`:deleted-state` at the ferry; the tenant comes only from `ctx` (नियम-1).
- **404 rather than 403 for a foreign object** — the OWASP-correct choice (a 403 confirms existence).
- **`:U` is never collapsed into `:F`.** An outage cannot masquerade as absence.
- **The response is a per-field allowlist**, not the entity: nothing crosses the boundary by default.
- **The prefix may never be derived from GSTIN/PAN/phone** — already a written rule (and the DPDP/GDPR
  question: a company-name-derived prefix adds no personal data to a number that already travels in email).

### The findings

| # | Sev | Standard | Finding | Disposition |
|---|---|---|---|---|
| **F1** | **HIGH** ✅ **CONFIRMED** | OWASP API1/API9 · NIST AC-4 | 🚨 **The sequential counter leaks a customer's cross-vendor order volume.** The counter is per (customer, doc-type, FY), so ONE series spans a customer's orders across **all** vendors. **Two independent leak channels, and the second is the one that matters:** (i) `/vendor/orders/{ordnum}` answers 200 for the vendor's own slice and **404** otherwise, so the series can be walked; (ii) **a vendor needs no endpoint at all** — `DOD_VENDOR_ORDERS` carries the customer's number (D20), so a vendor holding `...-00001` and later `...-00005` **infers four orders with competitors**, and can keep counting, without sending a request. Honest characterisation: a *commercial-confidentiality* leak (a supplier can size its customer's total demand, which is negotiating leverage), not a data breach. | ✅ **RESOLVED 2026-09-28 — see the decision record below.** Not by re-scoping the counter: that option is **structurally impossible** here. |
| **F2** | **HIGH** | OWASP API1 | 🚨 **A sentence in this very file is the loophole.** D4 says a globally unique `ORDNUM` makes "a number-only lookup legitimate again". Uniqueness licenses an unambiguous **address**; it does **not** license a **tenant-less query**. Any resolution that drops the tenant predicate is textbook BOLA. | **MUST FIX (wording + code).** Rewrite D4's claim; every resolution stays `WHERE ORDNUM = ? AND TENANT_ID = ?`; add the AC that a valid ORDNUM from another tenant answers **404**. |
| **F3** | **HIGH** | OWASP API5 | **Authorization is unhooked.** The `DOD_AUTH_POLICY`/`DOD_BUS_TRANSACTION` rows are seeds, `:required-roles` is carried and read by nothing, and `*action-route-transaction-function*` is a no-op (D18). The only real protections are tenant scoping, channel narrowing and fail-closed 401 — anyone with a valid session of the right channel can call every endpoint. | **ACCEPTED RISK, stated.** Not a defect of this batch (the invoice endpoints share it), but it must be written down where the endpoints are, not left implicit. The 401-fail-closed AC is the mitigating control. |
| **F4** | **HIGH** | NIST 800-63B · OWASP API2 | **The live authentication defect undermines all of the above.** `check-password` compares only the first 8 bytes (`PENDING-WORK-CONTEXT.md` §1): any suffix is ignored. Session lifetime is 8h (customer) / session-bound to UA+IP, with no re-auth for sensitive writes. | **Out of scope, but must be named.** Any security statement about these endpoints is nominal until §1 lands. Cross-referenced, not solved here. |
| **F5** | **MED-HIGH** | OWASP API3 (BOPLA) | **`!update` has no field-level allowlist per channel** — it assigns any declared initarg, gated only by status. So a customer can set `:is-converted-to-invoice "Y"`, `:invoice-number`, `:invoice-date`, `:order-fulfilled "Y"`, or `:status "CMP"/"VCN"/"CCN"` directly, bypassing the fulfilment/cancel verbs **and the order→invoice link**. | **MUST FIX in S5.** A per-channel writable-field allowlist inside `!update` (and `make`), refusing everything else with a contradiction. This is the field-level half of the authorization model; the route-level scope narrowing does not substitute for it. |
| **F6** | **MED-HIGH** | Google AIP-155/industry | **`POST /orders` has no idempotency.** A retried create produces a duplicate order, burns counter values, and (via D14's assembly) duplicates vendor rows — with no transaction seam to roll any of it back. | **MUST FIX in S3/S12, and the fix is nearly free.** `DOD_ORDER.CONTEXT_ID varchar(100)` **already exists**, the legacy layer already stamps it with `(uuid:make-v1-uuid)` (`dod-bl-ord.lisp:406`), and `get-order-by-context-id` already reads it (`:255`). Require an idempotency key (header or `:context-id`), `?exists`-check it, and return the EXISTING order on a repeat. |
| **F7** | MED | OWASP API4 · AIP-158 | **No pagination or result cap on `enumerate`.** 485 rows today and unbounded growth; one `GET /orders` can exhaust memory/CPU. | **MUST FIX in S4.** `:limit` (default 50, **max 200**) plus a cursor/offset, documented in the binding. |
| **F8** | MED | AIP-154 · RFC 9110 | **No optimistic concurrency on `!update`.** Hydrate → write-all-slots is last-write-wins: two concurrent writers silently lose one's changes. | **FIX in S5.** `UPDATED` already has `ON UPDATE CURRENT_TIMESTAMP`, so it is a ready-made version token — ETag on read, `If-Match` on write, 412 on mismatch. ⚠ **KNOWN defect: the write freezes `UPDATED`, so the vendor ETag never changes** (`PENDING-WORK` §10). |
| **F9** | MED | OWASP CSRF · AIP-193 | **CSRF is unaddressed.** Writes are authenticated by a session cookie, and nothing requires a JSON content type, an `Origin`/`Sec-Fetch-Site` check, or a `SameSite` cookie. | **FIX in S13.** Require `application/json` and reject others; validate `Origin`; set `SameSite` on the session cookie. |
| **F10** | MED | OWASP API4/API6 | **No rate limiting** — `apidefs2:617` says so in its own comment. Order placement is a sensitive business flow, and the counter is a burnable shared resource. | **FIX in S12/S13** (route-layer limit + a cap on counter increments per window), or ledger it as an accepted gap with the reason. |
| **F11** | MED | NIST AU-2/AU-3 · GST retention | **No audit trail, and the columns that exist are unwritten.** `emit-audit` is a stub, `:audit-level` is carried, the bus-transaction rows are seeds (S14) — and `CREATED_BY_USER_ID`/`APPROVED_BY_USER_ID` exist on the live table (`nst-dal-Order.lisp:504`) with **no writer anywhere**. | **PARTIAL FIX in S3, at near-zero cost:** populate `CREATED_BY_USER_ID` from the session at `make`. The rest stays on the ledger with the PEP work. |
| **F12** | MED | AIP-134 · RFC 9110 | **`PUT` carries merge semantics.** `!update` is a partial update exposed as PUT, which standards-following clients read as full replacement — and a field omitted from a full representation will not be cleared. | **DECISION REQUIRED.** Either use `PATCH` for orders, or document the deviation explicitly. ⚠ The invoice API already ships PUT-with-merge, so switching only orders creates two conventions in one product. |
| **F13** | LOW-MED | RFC 9457 · AIP-193 | **The error model is custom, and the classifier has gaps:** `api-status-for-condition` has **no 409 case** (so a sentinel-derived 409 is invisible to it), and a malformed body answers **500** where the contract says 400. | **FIX in S13 for the 400/409 part** (route-layer `api-client-error`); the error-envelope change is a shared-file change and belongs on the ledger. |
| **F14** | LOW | — | **The `A-Z0-9` charset is load-bearing, not cosmetic.** The number's delimiter is `-`, so a prefix containing `-`, or digits that mimic the FY, makes the number ambiguous to anything that splits it. And silent canonicalisation collides: `XYZ-CORP` → `XYZCORP` equals an existing `XYZCORP`. | **FIX in S0d:** the override must **REFUSE** a non-conforming value (so the user is told) rather than silently transform it — while the allocator may canonicalise at allocation time. And **no code may parse a number by splitting on `-`**: it is looked up whole. |
| **F15** | LOW | — | `UNIQUE (DOC_PREFIX)` permits **many NULLs**, so it does **not** enforce *every customer has a prefix*. That property is held by the allocator and the mint. | **Documentation.** Same class as the vacuous-duplicate measurement: do not read the index as the guarantee. |
| **F16** | LOW | product contract | **Our own spec promises more than we are building.** `nstoresapi.html:146` says `POST /orders` *"Atomically handles OTP verification, wallet deduction, and shipping address capture"*; this design is a document create. | **DECISION REQUIRED.** Either correct the spec text, or scope the batch wider — and if wallet deduction is in scope, financial controls apply and the single-entity design is insufficient. |
| **F17** | LOW | OWASP API9 | **The legacy writers stay live** — the legacy order UI actions and the old `/hhub/order*` handlers still create, cancel and fulfil orders, bypassing every new invariant (DFT, prefix, counter, scope). | **PARTIAL (S8b closes the prefix hole).** A full inventory/gating item goes on the ledger. |
| **F18** | LOW | WCAG 2.1 AA | The new profile field needs a real label, programmatic error text, and no colour-only signalling — the customer profile page is user-facing. | **FIX in S0d** (one line in the template's AC). |
| **F19** | LOW | OWASP API8 | `dispatch-route2` prints to stdout on every request (`PENDING-WORK` §5); log volume, not a leak — but it means request volume is unbounded in the logs too. | Already on the ledger; cross-referenced. |

### F1 — the decision record (2026-09-28)

**Option (a), a per-(customer, vendor) counter, is structurally IMPOSSIBLE here**: one customer order
spans several vendors (`DOD_ORDER` + N `DOD_VENDOR_ORDERS`, items carrying `VENDOR_ID`), so a
per-vendor counter would mint **N numbers for ONE order** — the customer could no longer quote "the"
order number, which is the reason the number exists — and it would collapse `UNIQUE (ORDNUM)`.
**Option (c), rate-limit-and-accept, does not fix it**: rate limiting touches only the endpoint channel
and has **no effect** on the one that needs no request at all.

**✅ CHOSEN — option (b), in the TOKEN rather than the counter:** keep an internal atomic counter
(deterministic, unique, dry-runnable) and publish a **non-sequential, unguessable** reference — the
counter through a **keyed permutation** (HMAC-SHA-256 over tenant|customer|doc-type|finyear|counter,
truncated, base32 over an explicit 31-symbol alphabet `23456789ABCDEFGHJKMNPQRSTUVWXYZ`: digits 2-9
plus A-Z less the look-alikes `I`, `L`, `O`). **Unguessable** (gaps carry no information, so both leak
channels close), **deterministic** (the dry run reproduces the real run, so AC (f) survives),
**unique by construction** (the permutation is injective, leaving the unique index a backstop), and
**structurally unchanged** (one order, one number, quoted across parties, addressed by both channels).

**Costs, stated:** the number stops being human-sortable (the counter stays the internal sort key) and
must be sayable aloud — hence the alphabet. **The key lives in the DATABASE, generated on first use,
NEVER in source** (a committed key would let anyone enumerate every reference), and **minting FAILS
CLOSED if the key is absent**. **Rotation** can map two counters onto one reference, so the unique
index plus the bounded retry is the guard — the retry is not decoration.

### F20 — 🚨 pre-existing: live credentials committed in source (not caused by this batch)

`hhub/core/extkeys.lisp` holds, as plain `defvar`s in a tracked file, the **AWS SES SMTP username and
password**, the **reCAPTCHA v2 secret** and the **data.gov.in API key** — and every file carries
"Distributed under the MIT License", so if the repository is shared these are public. **Out of scope
here and NOT fixed** (rotating production SMTP credentials is an operational act). Recorded because the
new ref key must not repeat it: **rotate the three, move them to configuration, add a leak check.**

### S0e — the cross-cutting requirements, and who owns each

**Not new files** — a filter over the findings above, so none is lost between design and code: every
one is either **implemented at a named site** or **explicitly accepted with a written reason**.
F1 → the `{ref}` token and a DB-stored key · F2/F5 → S3/S5 (tenant predicate; per-channel
writable-field allowlist) · F6/F11 → S3/S12 · F7 → S4 · F8 → S5 (ETag/`If-Match` — ⚠ **see the KNOWN
`UPDATED` defect, `PENDING-WORK §10`**) · F9/F10/F13 → S12/S13 · **F12/F16 → still to DECIDE** ·
F14/F18 → S0d · F15/F17/F19 → ledger · **F20 → ledger, then a human.** Reread before closing the
batch: none of these may be discovered a second time during the smoke suites.
