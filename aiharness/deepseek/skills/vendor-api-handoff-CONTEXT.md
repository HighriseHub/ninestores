# Vendor API — the 2026-09-13 handoff · CONTEXT

**Read this when:** you need the environment facts that cost real time — where the
app actually loads its fasls from, why a restart differs from a reload, the vendor
login contract, the 2-concurrent-login limit (§17.3) — or the four-state vocabulary
note (§17.5).

**Ignore §17.1 and §17.4; they are history.**

**Split out of `nst-bl-prdapi-CONTEXT.md` on 2026-09-20** for the 400-line budget.
**Content is unchanged.**

**Status: HISTORICAL, and partly superseded.** This was a handoff written on 2026-09-13 to
start the vendor API; that work has since been done — see `nst-bl-vndapi-CONTEXT.md`.
So §17.1 is an inventory of what the vendor domain looked like BEFORE that work, and
§17.4's open items are partly closed (item 1, `knowledge-conjoin`, was completed the same
day — see `knowledge-conjoin-CONTEXT.md`).

**What is still current:** §17.3, the environment facts that cost real time — those are
durable and were expensive to learn. §17.5, the four-state vocabulary note.

## 17. HANDOFF — starting the VENDOR API (read this first, in a fresh chat)

### 17.1 The vendor domain today looks exactly like products did on 2026-09-12

| | |
|---|---|
| `vendor/nst-bl-vendapi.lisp` | **stale spec** — 9 `register-outbound-route` entries for the pre-conflodis2 registry, same dead pattern `products/nst-bl-prodapi.lisp` had (names classes that do not exist, paths unreachable through nginx) |
| `vendor/dod-dal-venue.lisp`? no — | `vendor/dod-dal-ven.lisp`, `dod-dal-vad.lisp`, `dod-dal-vas.lisp`, `dod-dal-vpm.lisp` — the CLSQL view-classes |
| `vendor/dod-bl-ven.lisp` etc. | the legacy function layer |
| `vendor/dod-ui-ven.lisp` | the legacy UI — **5,000+ lines**, and it contains `dod-vend-login` |
| **`nst-vnd`** | **does not exist yet** — no domain class, no Tier-1 प्रत्यय, no action routes, no API bindings |

So the vendor work repeats the products path: domain class → Tier-1 प्रत्यय → reverse ferry →
action routes → API bindings. **Use `warehouse/` and `products/` as the templates**, not the
older `customer/`/`invoice/` API files, which still use the dead outbound-route style.

### 17.2 Files a fresh session should read, in this order

1. `core/nst-bl-apidefs2-CONTEXT.md` — the Ring-4 conventions, status mapping, deployment/nginx reality.
2. **this file** — §2 (schema discipline: verify the LIVE table, not `hhubplatform.sql`), §6 (the design decisions), §14–16 (Belnap, what is proven).
3. `hhub/warehouse/nst-bl-whsapi.lisp` — the reference route file (verbs, registrations, API bindings).
4. `hhub/products/nst-bl-prdapi.lisp` + `products/dod-bl-prd.lisp` — the newest domain: the Tier-1 प्रत्यय written from scratch.
5. `core/nst-bl-adhara.lisp` — §1 (sentinels), §5b (**the knowledge→domain-result converters**), §6 (the universal प्रत्यय + their documentation contracts).
6. `test/smoke-products-api.sh` / `test/smoke-warehouse-api.sh` — the test pattern, including `expect-known` and the Belnap section.

### 17.3 Environment facts that are NOT obvious and cost time

* **The app does NOT load the `.fasl` files beside the sources.** It loads from
  `/home/hunchentoot/.cache/common-lisp/sbcl-2.6.8-linux-x64/home/ubuntu/ninestores/hhub/`.
  `package/compile.lisp` (the "Nine Stores Compilation", logged to `hhub/logs/compilation-<ts>.log`)
  writes fasls BESIDE the sources — a successful compile there does **not** change the running image.
* **Reload the running image with `(asdf:load-system :nstores)`** — not a restart. A restart calls
  `reset-session-secret` and kills every session; a reload preserves them.
* **`nstores.asd` has no `:depends-on`.** `startup/load.lisp` preloads 16 dependency systems before
  `(ql:quickload :nstores)`. A bare load in a fresh image dies on `core/dod-dal-bo.lisp`
  with *"Package CLSQL does not exist"*.
* **`hunchentoot.local` resolves IPv6-only** on the server; use `127.0.0.1` (nginx :80, or the
  acceptor directly on :4244, where `/hhub/...` arrives unchanged).
* **Max 2 concurrent vendor logins, eviction oldest-first** — a curl login can silently bounce a
  browser session, and vice versa. Failed logins do not consume a slot.
* **Vendor login contract:** `dod-vend-login` matches `dod_vend_profile.phone` and requires
  `approved_flag='Y' AND approval_status='APPROVED' AND deleted_state='N'`; the password is
  salted-hashed (`check-password`) and unrecoverable. Failures are logged to
  `hhub/logs`-adjacent `ninestores-busfunctions.log` as
  `vendor-login-failed phone=… reason=vendor-not-found-or-disabled|password-mismatch`.
  `dodvendlogin` returns **302 for success AND failure** — never read the status as the outcome.
* **The API log only records CONDITION-derived failures.** Sentinel-derived `:F`/`:U`/`:C`
  responses are invisible there (§16.1).
* **Demo tenant is 2** (the login's company), which is what the warehouse/products fixtures assume.
  Products live in tenant 5 as well as 2 — do not assume one tenant.

### 17.4 Open items, in the order I would do them

1. **`knowledge-conjoin`** — the truth-order MEET (⊓t) for compound/sequenced verbs.
   `bo-merge`/`knowledge-join` is the optimistic JOIN: `(T, U) → T`. Correct for gathering
   evidence, **wrong** for sequencing, and it would silently report success for `order->invoice`
   when a step was merely unknown. Do this before any compound verb (§15.4).
2. **Log sentinel-derived `:U` and `:C`** in `api-run-route` — they are the two states that need a
   human, and neither leaves a trace today (§16.1). The sentinel `reason` now carries provenance.
3. **Hoist parameter validation out of the DB macro bodies** + a 4xx condition. Today
   `validate-sort-args` raises inside `with-nst-db-read-all`, whose catch-all `(error …)` turns it
   into `:U` → **503 for a permanently-invalid parameter** (it was 500 before; 503 is worse, it
   invites a retry). See the header of `test/smoke-warehouse-api.sh`.
4. **Enforce the verb return contract** — `action->response`'s `((null domain) nil)` launders a
   verb returning bare NIL into a 404 (§15.4).
5. **Prove `:U` over the wire** — the KILL runbook (§14.4) or a gated fault-injection seam.
   `:T`, `:F` and `:C` are done (§16).

### 17.5 A note on the four-state vocabulary, since it recurs

`with-db-call`'s `:C` fires on **multiple VALUES returned by the form**, NOT on multiple rows —
a 37-row result is `:T` with a list. Genuine `:C` comes from `bo-merge` of conflicting truths
(e.g. an identity held by a soft-deleted row: taken per the unique key, invisible per नियम-2).
Getting this wrong would corrupt the one distinction the layer exists to make (§14.1).

---
