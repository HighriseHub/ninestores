# The Nine Stores actor model · CONTEXT

**Covers the framework, not any one feature.** `hhub/core/nst-bl-act.lisp` — the
mailbox/behaviour layer, its invariants, the API, how to write a behaviour, how it
fails, and how to run its tests.

* §2 the invariants that make it an actor model (and the two that were missing until
  2026-09-23)
* §3 the API and the policy variables
* §4 writing a behaviour — the contract, and the two disciplines it demands
* §5 failure, retries, dead letters, supervision
* §6 operating it: status, log lines, and symptom → counter
* §7 the traps that cost time here (measured, not guessed)
* §9 what is deliberately *not* on actors

**Read this when:** you are adding a fire-and-forget job (email, SMS/WhatsApp, an S3
object, a webhook), or an actor has stopped processing, dropped messages, retried
itself, or left something in its dead letters. Also read it before putting a
*result-bearing* operation on an actor — §10 explains why that is usually the wrong
tool even though `send-message-and-wait` now exists.

**The single most expensive lesson here:** the actor held its own lock *across* the
behaviour, so `send-message` — the "async" call — blocked the calling HTTP thread for
the whole SMTP/S3 round trip. Measured: **751 ms** blocked, **0 ms** once the
behaviour moved outside the lock (§7.1). Second most expensive: a behaviour that
errored killed the actor *thread* silently, with `thread-state` still reading
`:running`, so every later message queued forever and nothing was logged.

**Date of the work recorded here:** 2026-09-23.

---

## 0. Verification status

Everything below marked VERIFIED was exercised in this session; the rest is reasoned
from the code. The suite in the framework file passes, and it is the *only* thing
that should be trusted twice: `hhub/test/hhub-tst-act.lisp` (§8).

| Claim | Status |
|---|---|
| A producer is not blocked by a running behaviour | **VERIFIED BY MEASUREMENT** — 751 ms → 0 ms, 1 s behaviour (§7.1) |
| Messages are processed FIFO | **VERIFIED** suite §5; before the fix the backlog order was A, C, B (newest first) |
| A full mailbox refuses the message, counts it, logs it | **VERIFIED** suite §6, plus the observed log line |
| Retry with delay, then success; retries counted, not failures | **VERIFIED** suite §7 (`retried=2 failed=0`) |
| Permanent failure → dead letter, actor survives | **VERIFIED** suite §8 |
| A failing message does not stop the actor processing the next one | **VERIFIED** suite §9 |
| Ask/reply, timeout, and error-delivered-to-asker | **VERIFIED** suite §10 |
| Supervisor revives a killed actor thread, same object, mailbox intact | **VERIFIED** suite §11 |
| `destroy-actor` lets the in-flight behaviour finish | **VERIFIED** suite §12 |
| Email through the actor: caller returns, actor sends, failures retry then dead letter | **VERIFIED** with a stub SMTP sleeping 300 ms — `send-email-async` returned in 9 ms, `retried=1 failed=1 dead-letters=1 alive=T`, and it kept delivering afterwards |
| Harness redefines nothing when loaded with the real bt/uuid/logging/framework present | **VERIFIED** — source *and* compiled fasl |
| The suite **inside the running server** | **NOT RUN** — needs an app restart to load the new framework (§9) |
| Any actor beyond the two email actors | **DO NOT EXIST.** Only email is on actors today. |

---

## 1. Where things live

| File | Role |
|---|---|
| `hhub/core/nst-bl-act.lisp` | The framework **and its suite** (`test-counter-actor`, `run-actor-tests`, `counter-behavior`, the live `*counter*` example). Deliberately self-testing. |
| `hhub/test/hhub-tst-act.lisp` | The harness: guarded `bt`/`uuid`/`hhub-log-message` doubles (real SBCL threads underneath), loads the framework if absent, runs the suite, exits 1 on failure when non-interactive. |
| `hhub/core/nst-server-context.lisp` | Registration: the two email actors (`register-actor` + `start-actor`) and the supervisor, each as a `register-effect` with its inverse. |
| `hhub/core/dod-ini-sys.lisp` | The actor globals: `*NSTSENDORDEREMAILACTOR*`, `*NSTGENERICEMAILACTOR*`, and the dangling `*NSTAWSS3FILEDELETEACTOR*`. |
| `hhub/email/templates/registration.lisp` | `send-generic-email-behavior`, `send-email-async`, the order behaviour, and the five notification mails now routed through the actor. |
| `hhub/core/nst-bl-otp.lisp`, `hhub/core/nst-temporal-spatial-framework.lisp` | Use `bt:make-thread` directly — **not** actors. Not converted. |

---

## 2. The invariants

An actor here is one OS thread, a FIFO mailbox, a lock, a condition variable and a
behaviour (+ an optional state). The invariants the implementation keeps — each one
was a defect before 2026-09-23:

1. **A producer never waits for a behaviour.** `send-message` enqueues under the
   lock and returns; the behaviour runs with **no lock held**. A slow SMTP/S3 call
   delays only that actor.
2. **Messages are processed in the order sent.** Mailbox is head/tail, enqueue is
   O(1). (Was `push`/`pop` — newest first.)
3. **A failing behaviour is contained.** Retried per policy, then dead lettered,
   with counters and a log line. It can never kill the actor thread.
4. **The mailbox is bounded.** A full mailbox refuses the message, counts it as
   dropped and logs it — the actor never grows without limit behind a slow
   downstream.
5. **Shutdown is cooperative.** `destroy-actor` lets the message in flight finish
   (up to `*nst-actor-shutdown-grace*`) before the thread is killed; a killed
   thread can interrupt a half-applied DB write.
6. **A caller that needs an answer asks.** `send-message-and-wait` + `(actor-reply
   value)` inside the behaviour — with a timeout, and with the behaviour's error
   delivered instead of a hang.

---

## 3. The API

```lisp
(make-instance 'nst-actor
  :name "Send Email Actor"          ; unique, kebab/space both fine; supervisor keys on it
  :behavior #'send-generic-email-behavior
  :stateful t                       ; behaviour takes (state message), returns the new state
  :initial-state 0
  :state-clean-callback (function (lambda (actor) (declare (ignore actor)) nil))
  :retry-limit 1 :retry-delay 2     ; attempts = 1 + retry-limit, delay in seconds
  :max-queue-size 200)              ; NIL means unbounded
```

| Operation | Notes |
|---|---|
| `(send-message actor message &optional bulk-p)` | Returns **T** accepted / **NIL** refused (mailbox full). Never runs the behaviour. |
| `(send-message-and-wait actor message &key timeout)` | → `(values answer answered-p error)`; `error` is `:timeout`, `:mailbox-full`, or the behaviour's condition. |
| `(actor-reply value &optional error)` | Called **inside** a behaviour to answer an ask. Returns the value. |
| `(flush-actor actor)` | Processes a batch queued with `bulk-p` (see §7.6). |
| `(start-actor a)` / `(stop-actor a)` | `stop` waits; a plain `send-message` wakes it again, so a durable stop is `destroy-actor`. |
| `(destroy-actor a)` | Cooperative stop, unregisters, clears mailbox and state. |
| `(register-actor a)` / `(unregister-actor a)` | Puts an actor under the supervisor. |
| `(restart-actor a &key reason)` / `(supervise-actors)` | Revive a dead thread / health-check every registered actor. |
| `(start-actor-supervisor)` / `(stop-actor-supervisor)` | The 5 s health loop. |
| `(get-state a)` / `(actor-alive-p a)` / `(actor-queue-depth a)` | Reading state and health. |
| `(actor-status a)` / `(actors-status-report)` | Alist / text report — §6. |

Policy variables: `*nst-actor-supervisor-interval*` (5), `*nst-actor-shutdown-grace*`
(5), `*nst-actor-registry*`, `*actor-reply*` (bound around a behaviour; do not set it).

---

## 4. Writing a behaviour

```lisp
(defun send-generic-email-behavior (state messagefunc)   ; stateful : (state message)
  (multiple-value-bind (to subject body) (funcall messagefunc)
    (hhubsendmail to subject body)
    (incf state)))                                       ; the new state is the return value
```

* **Stateful** behaviours take `(state message)` and must **return the new state** —
  the old `(incf state)` pattern works only when the actor was created with a number
  (`:initial-state 0`). A hash-table state must be counted *into*:
  `(incf (gethash :uploads-processed state 0))` then return `state`. Incrementing the
  state object itself is a type error that (before §5's containment) killed the actor.
* **Non-stateful** behaviours take `(message)`; the actor must be created
  `:stateful nil`.
* **The message** is what the behaviour receives. Either a **thunk** returning the
  behaviour's inputs (`(lambda () (values to subject body))` — the established style,
  the closure carries the data) **or** an `actor-message` whose **payload** is passed
  through, so a payload may be a keyword, plist or object for typed dispatch.
* **Retries mean behaviours must be idempotent**, or the failure must be one where a
  repeat is harmless. A retried SMTP send can duplicate a mail; that is why emails
  carry `:retry-limit 1` and not more.
* **Keep behaviours short and self-contained.** They own no lock, so they cannot
  block senders — but they do block *their own* mailbox.
* **Do not pass live shared objects in and mutate them.** The classic example is the
  product-image behaviour writing `(slot-value product 'prd-image-path)` and calling
  `update-prd-details` from the actor thread while request threads hold the same
  product/vendor objects in session caches. Pass ids and values, and let one writer
  (the actor) own the row.
* **Answer the asker** when the work was a question: `(actor-reply url)`.
* **Log through `hhub-log-message`.** `logiamhere` — used all over the older code — has
  no definition anywhere in the tree (only a stub in a test file), so calling it
  raises `undefined function` at runtime.

---

## 5. Failure, retries, dead letters, supervision

* `:retry-limit n` → up to **n+1** attempts, `:retry-delay` seconds apart, counted in
  `actor-messages-retried`.
* Exhausted → `actor-messages-failed`, the message (with the error string and time)
  is pushed onto `actor-dead-letters`, a log line is written, and any asker gets the
  error. **Dead letters are the first place to look** when a notification "did not
  arrive": they hold the payload and the real error string.
* The supervisor (`supervise-actors`, every 5 s) revives an actor whose thread is not
  alive and whose state is not `:terminated`. It **replaces the thread on the same
  actor object**, so every global (`*NSTGENERICEMAILACTOR*`) and every closure that
  already refers to it keeps working, and messages left in the mailbox are processed
  by the revived thread. Restarts are counted in `actor-restart-count`.
* Supervision is deliberately *not* a restart-of-last-resort loop: it does not retry
  behaviour bugs, it only replaces a dead thread.

---

## 6. Operating it

`(actors-status-report)` is the one-liner to paste into the REPL or a log:

```
1 registered actor(s)
  NAME: Send Email Actor   ID: uuid-2   THREAD-STATE: WAITING   ALIVE: T
  QUEUE-DEPTH: 0   SENT: 1   PROCESSED: 1   FAILED: 0   RETRIED: 0   DROPPED: 0
  DEAD-LETTERS: 0   RESTARTS: 0   LAST-ACTIVE-AT: 3999156301
```

| Symptom | Read |
|---|---|
| Notifications stopped | `ALIVE` false → supervisor should have revived it; `RESTARTS` climbing → it is dying repeatedly (look for a dead letter). |
| "It is slow" | `QUEUE-DEPTH` rising steadily → the behaviour is slower than the arrival rate (§7.10: one thread per actor, no parallelism inside an actor). |
| Messages vanished | `DROPPED` > 0 → mailbox was full (§7.4). |
| A mail never arrived | `DEAD-LETTERS` > 0 → the payload and error are in `actor-dead-letters`; the log line says `giving up on <type> (<error>), dead lettered`. |
| Retrying forever | `RETRIED` climbing with `FAILED` 0 → transient downstream failure; each retry is logged with the attempt number. |

Log lines the framework emits (all through `hhub-log-message`): mailbox full, attempt
N failed/retrying, giving up/dead lettered, "did not stop within grace", supervisor
restarting. A standalone harness run prints them as `[actor] …`.

---

## 7. The traps that cost time here

1. **The behaviour must not run under the actor lock.** It did, so `send-message`
   blocked the caller: 751 ms behind a 1 s behaviour. Fixed by popping under the lock
   and calling the behaviour outside it. Any future edit that moves work back inside
   `with-lock-held` reintroduces a synchronous-sending bug that looks like SMTP being
   slow.
2. **Queue order was LIFO** (`push`/`pop`). Masked by trap 1 (producers were
   serialized, so a backlog rarely formed) — fixing one without the other silently
   reorders work. Backlog order is a suite assertion now.
3. **Missing `:initform`s** on `state`, `stateful`, `state-clean-callback`: an actor
   created without them had *unbound* slots, so `destroy-actor` and `get-state`
   raised. Defaults now exist; the email actor also passed a **0-arg** clean callback
   while `destroy-actor` called it with one argument — shutdown would have errored,
   which is exactly the moment nobody is watching.
4. **A full mailbox used to grow without bound.** `max-queue-size` was declared and
   never read. Policy is now *refuse and count*. A blocking policy is not offered:
   bordeaux-threads has no timed condition wait, so a producer would block forever.
5. **`destroy-actor` used to kill the thread outright** (`bt:destroy-thread`), which
   can interrupt a behaviour mid-way through a DB or S3 write. It now waits for the
   in-flight message first.
6. **`bulk-processing-mode-p` does not batch.** It queues without waking the actor;
   the batch is processed when something else wakes it, or on `flush-actor`. The old
   test asserted the queue-not-processed half; both halves are now asserted.
7. **`get-state` was a generic with no method** — the declared API would signal
   `no-applicable-method`. Trivial method added; it is part of the suite now.
8. **`send-message-and-wait` polls.** With no timed condition wait available it polls
   the reply envelope every 10 ms; that is fine for the timeout regime it is used in,
   and it is why `answered-p`/`error` are returned rather than assumed.
9. **`logiamhere` is undefined in this tree.** New code must use `hhub-log-message`.
10. **One OS thread per actor.** Dozens of actors, not thousands: this is mutex +
    condvar + thread, not a BEAM scheduler. The win here is *decoupling, isolation and
    retries*, not throughput — an actor processes one message at a time.

---

## 8. Running the tests

```
sbcl --non-interactive --load hhub/test/hhub-tst-act.lisp      # → PASS, exit 0; FAIL, exit 1
```

Thirteen scenario groups: lifecycle (stop/bulk/flush), destroy, **producer not
blocked**, **FIFO**, bounded mailbox, retry-then-success, dead letter, error
containment, ask/timeout/error, supervision + restart, cooperative shutdown, status
report. Inside the app image the harness reuses the loaded framework and the app's
own `bt`/`uuid`/`hhub-log-message`; standalone it shims those three over SBCL
primitives, so the suite still runs against real threads, mutexes and condition
variables. Loading the file twice, or loading its fasl beside the real libraries,
redefines nothing (asserted in §0).

The suite lives in the framework file on purpose: the actor model is tested where it
is implemented. `hhub-tst-act.lisp` is the *harness*, and it is deliberately **not** in
`package/compile.lisp` — it runs tests when loaded, which a server build must not do.

---

## 9. Adoption state, and what is deliberately not on actors

* **On actors today:** the order-email actor, and the generic email actor behind
  `send-email-async` — which now carries the invoice email (`create-model-for-sendinvoiceemail`)
  and five notification mails (password reset link, temporary password, new-company
  request, contact us, welcome). `send-order-mail` no longer spawns its own thread.
  **No application code calls `sb-thread:make-thread` for email any more.**
* **Not on actors, on purpose:** the product-image *upload* (its URL is needed by the
  request — §10), and the product-image **delete**. The delete uses the prefix
  `prd/<id>/`, which is the same prefix the new uploads land under, so an
  asynchronous delete can race and remove the images just uploaded. That needs a
  distinct object id per generation first.
* `*NSTAWSS3FILEDELETEACTOR*` is still a **dangling defvar** — declared, never
  constructed. Either implement it (with the generation fix above) or delete the
  global.
* The framework changes are **not yet in the running server** until it is restarted.

---

## 10. When *not* to use an actor

`send-message-and-wait` exists, but it does not make an actor the right home for an
operation whose result the request needs: the caller blocks on the same thread while
one actor thread does the work, so there is no latency win — only a new single-threaded
queue in front of the operation. Use an actor when **nobody is waiting**: the result is
not needed (notification, delete, webhook), or the work updates the store itself and
the UI can show progress or refresh. When the answer is needed synchronously, do it in
the request; when it is needed *eventually*, do it in the actor and let the actor write
the result where the page reads it from.
