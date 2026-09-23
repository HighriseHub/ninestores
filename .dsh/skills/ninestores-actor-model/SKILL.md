---
name: ninestores-actor-model
description: Nine Stores actor model (hhub/core/nst-bl-act.lisp) — mailboxes, behaviours, ask/reply, retries, dead letters, supervision, and the send-email-async path. Load before writing, wiring or debugging an actor or any fire-and-forget job (email, SMS/WhatsApp, S3, webhook) in hhub; it carries the API, the invariants and the traps, and points at the full KB article.
whenToUse: Adding a background or fire-and-forget job to hhub (email, SMS/WhatsApp notification, S3 object, webhook); converting a raw sb-thread:make-thread into actor work; debugging an actor that stopped processing, dropped messages, retried, dead-lettered, or blocked its caller.
---

# Nine Stores actor model

Authoritative detail: **`aiharness/deepseek/skills/knowledge/nst-bl-act-CONTEXT.md`**.
Read that before changing the framework or a behaviour; this file is the orientation
and the checklist.

## Files

| File | Role |
|---|---|
| `hhub/core/nst-bl-act.lisp` | Framework **and its suite** (`test-counter-actor` / `run-actor-tests`) |
| `hhub/test/hhub-tst-act.lisp` | Standalone harness (shims `bt`/`uuid`/`hhub-log-message`); runs the suite |
| `hhub/core/nst-server-context.lisp` | Registers the actors + supervisor as `register-effect`s |
| `hhub/email/templates/registration.lisp` | `send-generic-email-behavior`, `send-email-async`, the order behaviour |
| `hhub/core/dod-ini-sys.lisp` | Actor globals |

Run the tests with:

```
sbcl --non-interactive --load hhub/test/hhub-tst-act.lisp     # PASS exit 0, FAIL exit 1
```

## The five invariants (each was a defect before 2026-09-23)

1. A producer is **never** blocked by a behaviour — `send-message` enqueues and
   returns; the behaviour runs outside the actor lock.
2. Messages are processed **FIFO**.
3. A failing behaviour is **contained**: retried per policy, then dead lettered. It
   can never kill the actor thread.
4. The mailbox is **bounded**: full → the message is refused, counted (`DROPPED`) and
   logged.
5. Shutdown is **cooperative** — the message in flight finishes before the thread dies.

## Checklist — adding an actor

1. Write the behaviour in `:nstores`, stateful signature `(state message)` returning
   the **new state**; non-stateful `(message)`.
2. The message is a thunk returning the behaviour's inputs
   (`(lambda () (values to subject body))`) or an `actor-message` payload.
3. Make the behaviour **idempotent if you enable retries** — `:retry-limit n` means up
   to n+1 attempts, and a retried SMTP send can duplicate a mail.
4. Keep it short, and never pass in a live shared object to mutate: pass ids/values
   and let the actor be the single writer.
5. Log failures with **`hhub-log-message`** — `logiamhere` is undefined in this tree.
6. Register the actor (`register-actor`) and start it inside a `register-effect` with
   its inverse (`destroy-actor` + nil the global), as `nst-server-context.lisp` does.
7. If a caller needs the answer, add `(actor-reply value)` in the behaviour and ask
   with `send-message-and-wait` — but see the warning below.

## Do not use an actor when the request needs the result

`send-message-and-wait` blocks the caller on the same thread while one actor thread
does the work: no latency win, just a new single-threaded queue in front of the
operation. Actors are for work **nobody is waiting on** (notification, webhook, delete,
report) or work the actor itself persists so a later page load reads it. This is why
the image *upload* stays synchronous while the emails went async — and why the
product-image **delete** must stay synchronous until its object id is unique per
upload generation (the delete prefix is the same prefix the new uploads use).

## Debugging an actor

`(actors-status-report)` first — it prints name, thread state, alive, queue depth and
the counters (sent/processed/failed/retried/dropped/dead-letters/restarts):

* `ALIVE` false → the supervisor should have revived it; `RESTARTS` climbing means it
  keeps dying (check the dead letters).
* `QUEUE-DEPTH` rising → the behaviour is slower than the arrival rate; one actor
  processes one message at a time.
* A mail or object never arrived → `actor-dead-letters` holds the payload and the real
  error string; the log says `giving up on <type> (<error>), dead lettered`.
* Caller blocked while the actor works → someone moved the behaviour back under the
  lock. That is trap §7.1 in the KB and it looks exactly like a slow SMTP server.

One OS thread per actor: dozens of actors, not thousands. The win is decoupling,
isolation and retries — not throughput.
