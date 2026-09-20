# The Belnap four-valued layer — provenance, all four states, and the wire · CONTEXT

**Split out of `nst-bl-prdapi-CONTEXT.md` on 2026-09-20** for the 400-line budget.
Section numbers are preserved from the parent. **Content is unchanged.**

**Covers:** SHARED CORE work (`core/nst-bl-adhara.lisp`, `core/nst-bl-apidefs2.lisp`)
done during the products session but not about products — the `:C` provenance-shape bug
(§13), making all four Belnap states provable (§14), the missing knowledge→domain-result
contract (§15), and the four states proven over the wire (§16).

**Read this when:** you are reasoning about `:T`/`:F`/`:U`/`:C`, writing a verb that must
return a sentinel, or asking why a failure produced a 503 where a 404 was expected.

**Companions:** `nst-bl-apidefs2-CONTEXT.md` (status mapping),
`knowledge-conjoin-CONTEXT.md` (the truth-order MEET, the `t` trap).

## 13. BUG #2 — provenance shape in the Belnap layer (SHARED CORE, fixed)

Found on the **second** run of the smoke test, after bug #1 was fixed. Same test, one layer
deeper, and this one is NOT products-specific.

```
condition: The value "nst-prd/?exists (product-code, deleted rows included)" is not of type LIST
0: (APPEND2 "nst-prd/?exists …" ("नियम-2: DELETED_STATE='Y' rows are invisible to every verb"))
1: ((:METHOD BO-MERGE-PROVENANCE (BO-KNOWLEDGE BO-KNOWLEDGE)) …)
2: ((:METHOD BO-MERGE (BO-KNOWLEDGE BO-KNOWLEDGE)) …)
3: (ROUTE-PRODUCT-CREATE …)
```

**Cause.** `bo-knowledge`'s `provenance` slot documents *"List of sources (strings or
symbols)"*, and `make-bo-knowledge` normalises whatever it is given into a list. But the
boundary macros in `core/nst-mult-logic.lisp` construct the class directly with
`make-instance 'bo-knowledge` (7 sites: `with-db-call`, `with-db-call-list`,
`with-db-read-all`, …) and pass `,source` straight through — so a knowledge object from
`with-db-call` carried a bare **string**. Every consumer in the tree appends provenance
(`bo-merge-provenance`, `bo-add-provenance`, and ~20 call sites in `hhub-bl-egn.lisp`,
`nst-bl-CustomerUser.lisp`), so the first merge did `(append "a string" (list …))` and
died.

**Fix** (`core/nst-bl-beltrusys.lisp`): a new `bo-provenance-as-list` helper plus an
`initialize-instance :after` method on `bo-knowledge` that forces the slot into list shape.
Enforced at the CLASS rather than at the 7 construction sites, so every path — including
future ones — obeys the contract the slot already declares. `make-bo-knowledge` now calls
the same helper instead of repeating the rule (the duplication is what allowed the two
paths to drift).

**This is a pre-existing platform bug, not a products one.** `nst-whs`'s `?exists` has the
identical shape (`with-db-call` + `bo-merge` to build the soft-delete `:C`), so the
WAREHOUSE 409 path would have failed the same way. It is listed as *"Not yet run: … the 409
:C path"* in `nst-bl-apidefs2-CONTEXT.md` §11 — which is exactly why it had never fired.
Fixing it in `beltrusys` repairs both.

**Verified after the fix:** `knowledge-join` really does map `:T ⊔ :F → +contradiction+`
(`core/nst-mult-logic.lisp:213`), so the path from `?exists` to a 409 completes:
`?exists` → `:C` → `route-product-create` returns `nst-entity-contradiction` → the
dispatcher's reverse ferry → `nst-response-contradiction` → `api-status-for-response` → 409
→ `render-json` → `{"error":"conflict","reason":…}`.

### The pattern worth naming

Both bugs were only reachable by RUNNING the code, and both sat on the same call chain:

1. `select-product-by-code` returned a list where its siblings return one row.
2. `with-db-call` returned knowledge whose provenance was a string where the class
   documents a list.

Neither is a compile error, neither is caught by a structural check, and neither is
reachable on the read-only path (the read path never merges knowledge and never reads
`deleted-state`). **Call the mutating tests as soon as a path is claimed to work.**

---

## 14. BELNAP: making all four states provable (2026-09-13)

The requirement: for a given API, prove that all four truth values pass — because
until they do, the four-valued layer is indistinguishable from ordinary error handling.

### 14.1 Where each state actually comes from (read this before designing a trigger)

| State | Produced by | Notes |
|---|---|---|
| **:T** | `with-db-call` when the form returns one non-nil value | |
| **:F** | `with-db-call` when the form returns nil | |
| **:U** | `with-db-call` when the form **raises anything** | logged to busfunctions.log |
| **:C** | `bo-merge` of two knowledges whose truths conflict (`knowledge-join`) — **or** duplicate PKs in the `*-read-all` variants | NOT a multi-row query! |

**THE TRAP:** `with-db-call`'s `:C` branch tests `(> (length results-list) 1)` on
`(multiple-value-list db-form)` — i.e. **multiple VALUES returned by the form**, not
multiple ROWS in the result set. A query returning 37 rows returns ONE value (a list)
and is therefore `:T` with a list payload. So:

> **A multi-row result is not a contradiction, and must never be reported as one.**
> It is a legitimate one-to-many answer whose honest shape is a list.

This corrected an earlier idea in this session ("37 live warehouses share one GSTIN, so
a by-GSTIN read is :C"). That was wrong: 37 rows is a *list*, and labelling it `:C`
would corrupt exactly the distinction the layer exists to protect.

The genuine `:C` for a **read** is the soft-deleted identity holder: the unique key says
the identity is TAKEN (`:T`) while नियम-2 says the row is INVISIBLE (`:F`) — two of the
domain's own rules disagree, and `bo-merge` resolves `:T ⊔ :F → :C`.

### 14.2 What changed

1. **`nst-whs`'s `fetch` was truth-blind** (`(if bk …)` on the bo-knowledge OBJECT,
   which is truthy whatever the answer). `:F` and `:U` both fell into the "found"
   branch and dereferenced a NIL payload → 500 for both, i.e. **the two states were
   indistinguishable**, which is the exact collapse this layer exists to prevent. It now
   maps `:T`→entity, `:F`→`nst-entity-nil` (404), `:U`→`nst-entity-unknown` (503),
   `:C`→`nst-entity-contradiction` (409).
2. **`warehouse-row-id-from-string`** guards the id parse, so `/warehouse/abc` is an
   ABSENCE fact (404) rather than being caught by `with-db-call` as `:U` — which would
   have answered 503 to a typo. (Mirrors `product-row-id-from-string`.)
3. **NEW VERB: `GET /hhub/api/v1/warehouse/by-identity`** — `route-warehouse-fetch-identity`
   addresses a warehouse by its IDENTITY tuple (GSTIN + wname + tenant) instead of its
   row-id, and returns all four states. This is the read that can legitimately answer
   `:C`. Both halves of the tuple are REQUIRED (400 otherwise): one GSTIN maps to many
   warehouses, so a GSTIN-only read is a one-to-many query, not a contradiction.
4. **ROUTE ORDER:** `by-identity` and `{id}` have the same segment count, so this endpoint
   only works because `find-api-route` now ranks literal segments above parameters. It is
   the live regression test for that ranking fix.

### 14.3 The tests (in `test/smoke-warehouse-api.sh`, section 3b)

`:F` is tested under **four different triggers**, because they are four different domain
facts — only one is the boring case:

| Trigger | Fixture | Why it matters |
|---|---|---|
| absent | id `999999` | the ordinary case |
| **cross-tenant** | id `123` (LIVE, but in tenant 1; session is tenant 2) | OWASP API1:2023 BOLA — a naive implementation answers 200 here |
| soft-deleted | id `53` (exists, `DELETED_STATE='Y'`) | नियम-2 hides it |
| absurd | `999999999999999999` | verified: MySQL returns 0 rows, no error → `:F`, NOT `:U` |

Plus `:T` by id and by identity, `:C` by identity, `:F` by identity, and a 400 for a
malformed identity read.

**ANTI-COLLAPSE ASSERTIONS** — the ones that make the rest meaningful: a miss must be 404
and must NOT be 503; a contradiction must be 409 and must NOT be 200 or 404. Without
these, "all four states pass" is decorative.

### 14.4 The one state still not proven over the wire: :U

`:U` needs a real boundary failure. Findings from investigating it:

* **A huge id does NOT work** — verified against MySQL: `= 999999999999999999`,
  `= 9223372036854775808` and `= 999999999999999999999999999999` all return **0 rows with
  no error**. Out-of-range comparison is just false. That path is `:F`.
* **Killing the connection works but is a one-shot runbook, not a suite test.** There is
  exactly ONE application connection (observable via `SHOW PROCESSLIST`: one idle
  `hhubuser` connection), and **nothing auto-reconnects** — `clsql:reconnect` appears in
  the tree only inside commented-out code. So a `KILL` breaks every DB-touching request
  until someone reconnects, and some UI controllers react to 2013/2006 by calling
  `stop-das`/`start-das`, i.e. a restart that invalidates all sessions.

`KILL` RUNBOOK (quiet window, deliberate, once — captures the transcript into this file):

```sql
-- 1. find the app's connection (the idle one, not yours)
SELECT id, time, state FROM information_schema.processlist
 WHERE USER='hhubuser' AND COMMAND='Sleep';
-- 2. KILL <that id>;
```
```bash
# 3. with a valid session, immediately: expect 503 {"error":"unknown"} — NOT 404
curl -sS -i -b jar "http://hunchentoot.local/hhub/api/v1/warehouse/127"
# 4. also expect the /by-identity read to answer 503 (not 409, not 404)
```
```lisp
;; 5. recover WITHOUT a restart and WITHOUT invalidating sessions:
(clsql:reconnect :database *dod-db-instance*)
```
Then re-run the GET to confirm 200 again. Alternative if a repeatable `:U` is wanted: a
**fault-injection seam** (a dev-only special that makes the named boundary call raise),
or a **split proof** (domain test that a boundary `:U` yields `nst-entity-unknown` + a
boundary test that `nst-entity-unknown` yields 503) — the latter proves the chain in
halves and never produces a 503 from a real request.

### 14.5 To activate all of this

```lisp
(asdf:load-system :nstores)     ; reload — the running image predates these changes
```
```bash
NS_PHONE=9999999990 NS_PASSWORD='…' ./smoke-warehouse-api.sh
```

---

## 15. THE MISSING CONTRACT — knowledge → domain result (core, 2026-09-13)

### 15.1 The diagnosis

conflodis2's *boundary* design was sound: `action->response` accepts an entity, a list,
a domain sentinel or a response model, and `api-status-for-response` maps the sentinels to
404/503/409. The *domain* side had no contract, and the four truth values were carried by
two types with **no bridge**:

| type | produced by | consumed by |
|---|---|---|
| `bo-knowledge` | the CRUD macros in `nst-mult-logic.lisp` | प्रत्यय methods |
| `nst-entity-nil` / `-unknown` / `-contradiction` | प्रत्यय methods | `domain->response` (the reverse ferry) |

Nothing converted between them, so every verb hand-rolled the mapping — and most verbs did
not convert at all: they **RAISED** on `:U` and `:C`. The pattern was stark:

> the classical part survived, the Belnap part was discarded.

Every verb handled "not found" with a sentinel, and answered *"I could not find out"* and
*"my own rules disagree"* with a plain error → **500**, indistinguishable from a crash and
from a legitimate 404. That is the same collapse found in `fetch` earlier in the day — it
was simply systemic on the write side.

### 15.2 New in `core/nst-bl-adhara.lisp` §5b

```lisp
knowledge-provenance-text        ; provenance → one readable string
knowledge-reason-for             ; :reason is a string OR a function of the truth
domain-sentinel-from-knowledge   ; the primitive: :F/:U/:C → the matching sentinel
domain-result-from-knowledge     ; the common case: :T → (:hydrate payload), else ↑
```

Three deliberate choices:

1. **`domain-sentinel-from-knowledge` REFUSES `:T`** — a `:T` is a fact, not a failure, and
   only the verb knows what to do with the payload (hydrate it, or — for `make` — treat it
   as a conflict). A verb that reaches it with `:T` has a control-flow bug, and 404/503/409
   would all be lies.
2. **`:reason` is per-state aware.** One message does not fit all three: for fetch,
   "row-id 999 not found in this tenant" is right for `:F`, but the same words in front of
   a `:U` would claim we looked and found nothing when we could not look at all — precisely
   the confusion this section exists to remove. It accepts a string or `(lambda (truth) …)`.
3. **`hydrate` has no default.** Substituting a sentinel for a payload the caller forgot to
   hydrate would turn a programming error into a plausible-looking 404.

Provenance is always appended to the reason: it is where the *why* lives (नियम-2's
explanation of a soft-deleted identity holder), and a 409 nobody can act on is worthless.

### 15.3 Write verbs: raising → four-valued

| Verb | `:F` | `:U` | `:C` |
|---|---|---|---|
| `make` | contradiction → **409** (lost race) | unknown → **503** | unreachable → error |
| `!update` | nil → 404 | unknown → **503** | unreachable → error |
| `delete!` | nil → 404 | unknown → **503** | unreachable → error |
| `enumerate` | `'()` → 200 `[]` | unknown → **503** | contradiction → **409** |

Two structural points:

* **`make :before` became `make :around`.** A `:before` method's return value is DISCARDED
  — raising was its only way to refuse, so every refusal became a 500. An `:around` method
  can short-circuit and return a value, keeping the "refuse before the INSERT" property
  while speaking in four values.
* **The `:C` law moved out of the routes into the verb.** `route-warehouse-create` and
  `route-product-create` each did the soft-deleted-identity pre-check themselves, so **only
  the HTTP path ever saw a 409** — the internal website and any REPL caller still crashed
  with a 500. The law belongs to the प्रत्यय, not to the transport; removing it deleted a
  duplicate implementation and fixed the non-HTTP callers.

`delete!` still returns `T` for its success ack — the known 5th return shape (§ review).
Left alone deliberately: it is a verified client-visible contract, and changing it is a
separate decision.

### 15.4 Still open from the same review

* **The contract is still not enforced.** `action->response`'s `((null domain) nil)`
  launders a verb that returns bare NIL into a **404** — indistinguishable from a genuine
  `:F`. The six real return shapes (entity | nil | unknown | contradiction | `T` ack | list)
  are documented nowhere in code.
* **No `knowledge-conjoin`.** `bo-merge`/`knowledge-join` is the truth-order JOIN (⊔t):
  `(T, U) → T`, i.e. *any source saying true wins*. Correct for gathering evidence, WRONG
  for sequencing steps — a compound verb like `order->invoice` built on it would report
  success when one step was merely unknown. Compound verbs need the truth-order MEET (⊓t):
  `T⊓T=T`, `T⊓F=F`, **`T⊓U=U`**. Do this BEFORE writing any compound verb.

---

## 16. VERIFIED — the four states over the wire (2026-09-13, 19:50)

`test/smoke-warehouse-api.sh` → **25 passed, 0 failed, 0 known-defects**, after reloading
the running image. The Belnap section 3b is the part that matters:

```
PASS :F absent id → 404                               404
PASS :F another tenant's id → 404 (BOLA)              404
PASS :F soft-deleted id → 404 (नियम-2)                 404
PASS :F absurd id → 404 (MySQL: 0 rows, no error)     404
PASS :T live id → 200 + entity                        200
PASS :C identity held by a soft-deleted row → 409     409   ← a READ producing :C
PASS :T live identity → 200 + entity                  200
PASS :F unknown identity → 404                        404
PASS identity read missing wname → 400                400
PASS anti-collapse :F ≠ :U                            404 (a miss is NOT 503)
PASS anti-collapse :C ≠ :T, :C ≠ :F                   409 (not 200, not 404)
```

The three `:F` fixtures were confirmed against the database, not merely asserted: row **127**
is live in the session tenant, row **123** is **live in tenant 1** (so its 404 is the
security-relevant BOLA case), and row **53** is soft-deleted in the session tenant.

`--write` also passed (201 / 200 / ack 200 / 404 / 404), and the storage layer was checked
directly — row **128** showed `w_city=Nashik`, `w_manager=API Smoke` (the partial update
persisted AND preserved the other fields) and `deleted_state='Y'`. So `make`, `!update` and
`delete!` are verified end to end, not just at the response layer.

**Status: `:T`, `:F` and `:C` are now proven over HTTP on a READ verb. `:U` is the only
state not yet triggered — it needs the KILL runbook (§14.4) or a fault-injection seam.**

### 16.1 NEW FINDING — the states that need a human are the ones that leave no trace

The API log records failures raised as **conditions** (`api-fail` → `api-log-error`). It does
**not** record failures that arrive as **Belnap sentinels**, because `api-run-route` derives
the status from the response and writes it directly.

Verified: the whole log contains **zero `503` entries**, and the bad-`sort-by` 503 from this
run is absent — while the `400`, `401` and `404 no_such_endpoint` from the same run *are*
present (those three come from conditions). So:

| answer | arrives as | logged? |
|---|---|---|
| 400 / 401 / 404 routing | condition | yes |
| 404 from `:F` | sentinel | **no** |
| **409 from `:C`** | sentinel | **no** |
| **503 from `:U`** | sentinel | **no** |

`:F` being quiet is arguably fine — a miss is ordinary traffic. But **`:U` ("I could not find
out") and `:C` ("my own rules disagree — a human must decide") are precisely the two
responses an operator needs to see**, and both are currently invisible in
`ninestores-apilogs.log`. For the sort-by case the cause is recoverable from
`busfunctions.log`, but a `:U` from a real boundary failure in a verb that does not log would
leave nothing anywhere.

**Recommendation:** in `api-run-route` (apidefs2), log the response-derived non-success
verdicts — at minimum `:U` and `:C`, with the sentinel's `reason`, which now carries the
provenance thanks to `domain-sentinel-from-knowledge`. One `when` around the existing
`api-write-json` call.

---
