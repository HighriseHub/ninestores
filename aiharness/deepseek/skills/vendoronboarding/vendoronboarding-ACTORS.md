# vendoronboarding — ACTORS: one email actor, or one per persona?

**Read this when:** you are deciding where an onboarding mail is queued — "should the vendor,
customer and company-admin mails share the email actor?", "why did a customer's order mail not go
out while a batch of vendor mails was running?", or you are about to add a fourth actor to
`nst-server-context.lisp`.

> **Status: STEP 2 BUILT 2026-10-17 — the `:vendor` persona actor, the alist and the dispatcher
> exist in code; `:customer` / `:admin` do not yet, and the `dead-letters` cap (§3 last note) is
> still open.** Nothing loaded into the live image: the actor is created by `start-nst-server`, so
> it appears on the next server start, not on a file load. Every figure below was read from source
> on that day; the queue/latency properties are properties of `hhub/core/nst-bl-act.lisp`, not
> measurements of the live box.

---

## 1. What exists today

| Actor | Global | Behaviour | Configured in |
|---|---|---|---|
| `Send Order Email Actor` | `*NSTSENDORDEREMAILACTOR*` | `send-order-email-behavior` | `nst-server-context.lisp:340-357` |
| `Send Email Actor` (**the generic one**) | `*NSTGENERICEMAILACTOR*` | `send-generic-email-behavior` | `nst-server-context.lisp:360-378` |
| S3 delete actor | `*NSTAWSS3FILEDELETEACTOR*` | file delete | `nst-server-context.lisp` |
| Actor supervisor | — | revives dead actor threads | `start-actor-supervisor` |

All email actors are configured identically: `:retry-limit 1`, `:retry-delay 2`,
`:max-queue-size 200`, `:stateful t` with a plain counter.

**Every mail in the tree already funnels into the generic actor.** `send-email-async`
(`email/templates/registration.lisp:173`) is the only path for a non-order mail — E1 already uses
it — and it falls back to a synchronous inline send when the actor is missing (early boot, tests):
`(if *NSTGENERICEMAILACTOR* …inline…)`. The order path is the only exception and it exists for
historical reasons, not for isolation.

**Rendering stays in the caller; the behaviour only does SMTP.** That is deliberate: the actor
thread touches no database. `send-generic-email-behavior` receives already-rendered
`(to subject body attachments)` and calls `hhubsendmail`. Any design here must keep that rule.

## 2. The question

Three dedicated actor threads — vendor, customer, company-admin — instead of the one generic
actor. Assessed against what the framework actually gives, not against an ideal.

## 3. Comparison, property by property

| Property | ONE generic actor (today) | THREE persona actors | Verdict |
|---|---|---|---|
| **Head-of-line blocking** | One FIFO. A batch of vendor onboarding mails occupies the single thread for one SMTP round trip **per message** — the actor suite measured that blocking at ~0.75 s per send. A customer's order confirmation waits behind it. | Each persona has its own FIFO, so a vendor batch cannot delay a customer mail. | **Split wins.** This is the real argument. |
| **Queue-full behaviour** | 200 messages, then `send-message` **refuses** and counts `DROPPED` (`nst-bl-act.lisp:375-390`). A vendor batch can fill the 200 and drop an unrelated customer mail. | Three independent 200-message mailboxes; one persona's burst cannot drop another's mail. Sizes can also differ per persona (customer mailbox larger). | **Split wins**, and it removes a silent-failure mode rather than adding one. |
| **Retry policy** | One policy for everything: `retry-limit 1`, `retry-delay 2`. A customer's order confirmation gets the same one retry as a marketing-style onboarding mail. | Per-persona policy: e.g. customer `retry-limit 3`/`delay 1` (transactional, time-critical), vendor `1`/`2`, admin `1`/`5`. | **Split wins**, but only if you actually set different values — identical configs make the split cosmetic. |
| **Failure isolation** | A behaviour that throws for every message (a broken template, say) burns retries on the shared thread and grows the shared dead-letter list. | The poison loop stays on its own thread; other personas keep sending. | **Split wins** for a *behaviour/template* failure. |
| **SMTP outage** | All mails dead-letter. | All mails dead-letter — same relay, same credentials, same `hhubsendmail`. | **No difference.** Do not sell this as resilience. Only separate transports (different domain/relay) would change it, and that is not in scope. |
| **Observability** | `actors-status-report` gives per-actor processed / failed / retried / dropped / dead-letter counts. With one actor you cannot tell a vendor mail from a customer mail. | `actors-status-report` answers "are vendor mails flowing?" directly; `actor-dead-letters` is per actor, so triage is per persona. | **Split wins.** |
| **Ordering** | Strict FIFO across everything — E1 (vendor) then E2 (admin) are guaranteed to be attempted in that order. | No ordering *between* personas. E1 and E2, which are queued together at registration, may be attempted in either order. | **Split loses.** Harmless for E1/E2 (different recipients, independent meaning), but do not rely on cross-persona ordering. |
| **Cost** | 1 thread, 1 global, 1 registration. | 3 threads, 3 globals, 3 registrations — unless you write it as one loop (see §4), which makes it one effect and one place to get the inverse right. | Slight cost, contained by construction. |
| **DB safety** | Actor thread does no DB work. | Same, **if and only if** nothing newly renders inside the behaviour. The moment a persona actor needs `select-vendor-by-id`, it inherits `*dod-db-instance*` cross-thread and you have a new class of bug. | **Rule, not a tradeoff:** render in the caller. |
| **Throughput** | Serial over one thread. | 3x serial, in parallel. At 15 vendors / 26 customers / 4 tenants this is irrelevant; it becomes relevant the day a batch is sent. | Neutral today. |

### One more fact that matters for any plan built on this

`dead-letters` is a **plain `push` list with no cap** (`nst-bl-act.lisp:277`) held in the actor
object. Three actors means three unbounded lists; a systematic failure on one persona grows that
list for the life of the image. Cap it (or drain it to the log and reset) **before** relying on it
for triage.

## 4. Recommendation

**Three persona actors, one shared behaviour, one dispatcher.** Adopt it — for isolation,
per-persona retry policy and per-persona triage — but implement it so the boilerplate does not
triple:

1. **Behaviours:** reuse `send-generic-email-behavior` for all three. Nothing persona-specific
   belongs on the actor thread.
2. **Globals:** one alist instead of three defvars, e.g. `*NST-EMAIL-ACTORS*` →
   `((:vendor . actor) (:customer . actor) (:admin . actor))`, in `dod-ini-sys.lisp` beside the
   existing two.
3. **One registration effect** in `nst-server-context.lisp`: build the three from a spec list
   (name, behaviour, retry-limit, retry-delay, max-queue-size), `register-actor` + `start-actor`
   each; the inverse destroys each and nils the alist. One place to get the inverse right
   (checklist item 6 of `ninestores-actor-model-CONTEXT.md`).
4. **One dispatcher**, keeping the existing signature and adding an optional key, so no existing
   caller changes:

   ```
   (defun send-email-async (to subject body &optional attachments &key persona)
     ... (let ((actor (or (cdr (assoc persona *NST-EMAIL-ACTORS*))
                          *NSTGENERICEMAILACTOR*)))
           ;; no actor for that persona (early boot, tests, or a typo) → the generic one → inline
           ...))
   ```

   The fallback chain is the point: a missing persona actor must degrade, never drop the mail.
5. **Call sites** pass `:persona :vendor` / `:customer` / `:admin`. E1 becomes
   `(send-email-async to subject body nil :persona :vendor)`.
6. **Leave `*NSTSENDORDEREMAILACTOR*` alone for now.** Folding it into `:customer` is a separate
   change with its own regression risk (`*NSTSENDORDEREMAILACTOR*` is written directly at
   `customer/dod-ui-cus.lisp:2521`); do it when the buyer feature starts, not as a side effect.

## 5. What this does not buy

- **No protection from an SMTP outage** — three queues, one relay, three sets of dead letters.
- **No cross-persona ordering** — E1/E2 are not guaranteed to be attempted in the order queued.
- **No DB access for actors** — still render in the caller.
- **No throughput gain that matters today** — it is isolation and diagnosability.
- **No protection from a bad bulk decision** — a vendor batch still takes ~0.75 s per message on
  the vendor thread; the customer thread stays responsive, but a 200-mail vendor batch is still a
  ~2.5 minute vendor-thread job. If batches become real, that needs its own design (throttle, or a
  separate batch actor), not more personas.

## 6. Decisions to take before implementing

| # | Decision | Suggested |
|---|---|---|
| A1 | Do we adopt the split at all, or is one actor enough until a batch exists? | Adopt — the queue-full drop and the shared retry policy are already wrong for transactional customer mail. |
| A2 | Per-persona retry limits/delays and mailbox sizes | customer `3 / 1 s / 500`; vendor `1 / 2 s / 200`; admin `1 / 5 s / 100` |
| A3 | Cap `dead-letters` (e.g. keep the last 50, log the rest) | Yes — separate small change, do it with the split |
| A4 | Refactor the legacy order actor into `:customer` now or later | Later (№6 above) |

## 7. Build order

1. ~~`dead-letters` cap~~ — **still open**; do it before relying on per-actor dead-letter triage.
2. **DONE 2026-10-17** — `*NST-EMAIL-ACTORS*` alist (`dod-ini-sys.lisp:193`), one registration
   effect building it from a list with the inverse that destroys and nils it
   (`nst-server-context.lisp:382-402`, `:name "Persona Email Actors"`), and the dispatcher
   `(send-email-async to subject body &optional attachments &key persona)` whose chain is
   persona → generic → inline. `:vendor` and — added 2026-10-18 with E2 — `:admin` ("Company Admin Email Actor") are in
   the list; every other caller and every other persona still lands on the generic actor
   unchanged. `:customer` is the only one left.
3. **Open** — differentiate retry limits / mailbox sizes per persona.
4. **Open** — add `:persona` to E2–E5 as they are written (E1 already passes `:vendor`).

### How step 2 was proved offline (no image, no database)

- `sbcl --non-interactive --load hhub/test/hhub-tst-att.lisp` → **PASS, exit 0**. That suite loads
  the **real** `registration.lisp`, so it is the gate for any change to `send-email-async`.
- A throwaway probe on top of the same image (`/tmp/persona-probe.lisp`, not in the repo) with the
  real actor framework and the recording `hhubsendmail` stub measured all three paths:

  | call | delivered by | generic processed |
  |---|---|---|
  | `… nil :persona :vendor` with a vendor actor registered | **vendor actor** (1) | 0 |
  | `…` (no key — every pre-existing caller) | generic (1) | 1 |
  | `… nil :persona :vendor` with **no** vendor actor registered | generic (2 — fallback, not dropped) | 2 |

- **The harness had to learn two things for this to load**, and both are real constraints on any
  future sender: it stubs **`cl-ppcre`** now (literal-only `regex-replace-all`; a NIL replacement
  still errors, a replacement *function* is unsupported), because `hhub-fill-email-template` calls
  it and `registration.lisp` had never used that package before; and it defines
  **`*NST-EMAIL-ACTORS*`** when unbound, or `send-email-async` would read an unbound variable in
  the bare image. A new sender that pulls in another package has to extend the same stub block.
