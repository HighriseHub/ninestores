# vendor setting decisions — the AI settings layer that is not wired yet

**Read this when:** you are about to extend `nst-bl-vaisettings.lisp` toward a JEV-style
decision layer, **or** `(run-intent "…")` returns a score you cannot account for, **or**
`execute-setting` looks like it saved a setting but nothing persisted, **or** you are
looking for the "vendor settings AI page" and cannot find one, **or** the vendor Web REPL
page loads but its **Eval** button does nothing.

**Verified:** 2026-09-22 (IST) — live probes against the running hunchentoot, greps over
the working tree, one offline SBCL reproduction. Every line number and count below was
checked on that date.

---

## 0. Status in one paragraph

`nst-bl-vaisettings.lisp` contains a **working, JEV-shaped skeleton**: a closed setting
registry → a scored candidate list → a confidence ladder → an execution call, with a trace
slot. What it does *not* contain is a model, a persistence layer, or a place in the build.
It is a **prototype that ran for the first time on 2026-09-22** (see §3.3), lives only in
the running image, decides by keyword counting, and returns `:needs-confirmation` into a
branch **nothing consumes**. Everything in this file is either "exists but is not loaded"
or "is loaded but is not called" — there is no path in the repository that turns a vendor's
sentence into a stored setting.

---

## 1. The trap that costs the most time: three settings systems

All three call themselves "settings", share no keys, and are wired to nothing that
connects them. Grep confidently; they will not find each other.

| # | System | Key form | Where | State |
|---|---|---|---|---|
| 1 | REPL stub | string — `"invoice.print.paper-size"` | `vendor/nst-bl-vwebrepl.lisp:60-71` | **never compiled or loaded** (§6) |
| 2 | AI decision registry | symbol — `nst.vendor.invoicesetting.*` | `vendor/nst-bl-vaisettings.lisp:14-25` | loaded **only by hand** in the live image |
| 3 | Real invoice settings | symbol — `invoice-print-settings.font-size` | `invoice/templates/invoicesettings.lisp:10-32` (22 keys) | loaded, the only one actually rendered |

Plus two **tables** that were designed to hold #2 and hold nothing:

- `DOD_VENDOR_SETTINGS` — the value store. DDL at
  `installation/upgrades/nst-dbu-vendorsettings.lisp:4-38`.
- `DOD_VENDOR_SETTINGS_DEFINITION` — the registry. DDL at the same file `:40-70`.

🚨 **No Lisp reads or writes either table.** Repo-wide, the only mention outside the DDL
file is a docstring at `hhub/vendor/nst-dal-vnd.lisp:313`. The tables are pure schema. If
you assume "the settings are in the DB", you will spend an afternoon on a query that never
had a writer.

The real per-vendor accessors, for contrast, are session-based and unrelated to #2:

- `get-login-vendor-setting` — `vendor/dod-ui-ven.lisp:3133-3135`, a `gethash` on the
  `:login-vendor-settings-ht` session value.
- `addloginvendorsetting` / `addloginvendorsettings` — `:2555-2556` / `:2538-2554`; the
  latter seeds **payment-method keys only**.
- `get-vendor-invoice-settings` — `:2528-2536`, `read-from-string` of the
  `:login-vendor-invoice-settings` session value, falling back to `*invoice-settings*`.

So a key in system #2 does not exist in #1, and neither exists in the real store. Any
"setting" you set through the AI layer today would have no reader.

---

## 2. The decision mechanism, as it actually runs

The pipeline in `hhub/vendor/nst-bl-vaisettings.lisp`:

```
run-intent (text)                                  ; :173-183
  └─ llm->intent (text)                            ; :91-95   ← the only model call
       └─ build-llm-prompt prompt-for-llm text     ; :82-84, template :51-79
       └─ llm-generate → read-from-string → make-intent
  └─ resolve-setting (intent)                      ; :117-124
       └─ score-setting (intent setting)           ; :106-112 ← the actual decision
  └─ select-setting (candidates)                   ; :127-135 ← the ladder
  └─ build-execution-context → execute-setting     ; :159-166, :142-156
```

Three things to internalise, in order of how much they cost:

1. **The model does not decide.** It only rewrites the sentence into a plist. `score-setting`
   reads exactly one field — `(intent-description intent)` — and counts keyword hits:
   `(/ (float matches) (max 1 (length keywords)))`. Nothing else in the file reads a model
   output. The "probability" is a **keyword-overlap ratio**.
2. **The ladder is effectively binary.** Scores are quantised to `k/n` where `n` is the
   number of keywords in the entry. With `n = 4`, the reachable scores are `0, .25, .5, .75, 1.0`
   — so `>= 0.9` (`:130`) means **only a perfect 4/4 match auto-executes**, and everything
   else is `:needs-confirmation`. `>= 0.7` (`:132`) is where the top score lands in the
   common case. The thresholds are not tuning a distribution; they are splitting a
   four-valued set.
3. **The confirmation branch is a dead end.** `select-setting` returns
   `(:needs-confirmation candidates)` and **no function in the repository consumes it** —
   there is no `confirm-intent`, no second entry point to `build-execution-context`. The
   only reachable write path is the `t` branch at `:182`, i.e. a **perfect** score. That
   path ends in `execute-setting`, which validates the type, `format t`s a line, returns
   `T`, and stores nothing (`:142-156`, comment: *"placeholder for real persistence"*).
   🚨 **That placeholder is deliberate, not a defect** — the author staged the
   execution-code substitution for a later pass. It is a work-queue item, not a bug; do not
   "fix" it unprompted.

**Consequence:** the observable behaviour is exactly what a demo needs and nothing a
product needs. It cannot silently do the wrong thing — because it cannot do anything.

---

## 3. Accounting for a `run-intent` result

### 3.1 Reproduce the score without any model

This is the fastest way to prove to yourself where a number came from. Copy the two
registry entries and the three scoring defuns into a scratch file and run
`sbcl --script` — no network, no DB, no package. For
`"set vendor invoice setting send email after invoice payment is done"` on 2026-09-22:

```
TOKENS: ("set" "vendor" "invoice" "setting" "send" "email" "after" "invoice"
         "payment" "is" "done")
SEND-INVOICE-EMAIL-AFTER-PAID : keywords ("send" "email" "invoice" "paid")
    → send ✓ email ✓ invoice ✓ paid ✗                     = 3/4 = 0.75
ATTACH-PDF-TO-INVOICE-EMAIL   : keywords ("attach" "pdf" "invoice" "email")
    → invoice ✓ email ✓                                    = 2/4 = 0.50
DECISION: (:NEEDS-CONFIRMATION (…0.75… …0.50…))
```

This is **byte-identical to what the live image produced through DeepSeek on the same
input** — which is the point: the model's choice of words is the only variable. Had it
written *"paid"* instead of *"payment"*, the score would have been `1.0` and the setting
would have been written with no confirmation at all. **A synonym decides whether the system
asks.** That is the single most important property to fix before adding autonomy.

### 3.2 `tokenize` is the weak link (`:102-104`)

`(split-sequence:split-sequence #\Space text)` then `string-downcase`. Therefore:

- no stemming — `"payment"` never matches `"paid"` (the failure above);
- no punctuation stripping — `"email."` ≠ `"email"`, and a trailing newline or a
  multi-word `:description` shifts everything;
- case is handled, but only because both sides are downcased.

The blast radius is that `:description` is both the thing scored *and* whatever the model
chose to write. Two runs with identical user input can land in different bands.

### 3.3 The abandoned February version never ran

`nst-bl-vaisettings.lisp~` (mtime **2026-02-08**) is the abandoned copy. It is not a stale
duplicate of today's file — it is **broken**, and worth knowing before you "restore" it:

```lisp
;; ~ version, 2026-02-08              ;; working tree, 2026-09-22
(defun build-llm-prompt (text)        (defun build-llm-prompt (text user-input)
  (format text "~A" user-input))        (setf text (cl-ppcre:regex-replace-all
                                                "%user-input%" text user-input))
                                        text)
(llm->intent: (build-llm-prompt text) (llm->intent: (build-llm-prompt prompt-for-llm text)
              (ollama-generate prompt))             (llm-generate prompt))
```

The February form passed a literal string as a `format` destination and left `user-input`
free, and `llm->intent` never passed the template. **`run-intent` first worked on
2026-09-22.** Evidence: `hhub/vendor/nst-bl-vaisettings.fasl` is stamped `2026-09-22 22:46`,
the same minute as the `.lisp` mtime — the fingerprint of a hand-load in the live image.

---

## 4. The registry vs the schema that was designed for it

`*vendor-setting-registry*` (`:14-25`) holds **two** entries. Both are `:boolean`, both
`:domain :invoice`, both about invoice email. A decision between two near-identical options
is close to a coin flip — this is why every score above sits in `0.5–0.75` and why the
ladder carries no information. **A decision model is only as good as its option list; two
options is not a decision.**

🚨 **`DOD_VENDOR_SETTINGS_DEFINITION` is this registry, as data, and it is more advanced
than the code.** Its columns map onto the plist fields and then go further
(`installation/upgrades/nst-dbu-vendorsettings.lisp:40-70`):

| plist field | column |
|---|---|
| `:key` | `SETTING_KEY` |
| `:domain` | `INTENT_DOMAIN` |
| `:description` | `DESCRIPTION` |
| `:keywords` | `KEYWORDS` (JSON) |
| `:data-type` | `DATA_TYPE` (ENUM string/number/boolean/json) |
| — | `ALLOWED_VALUES` (JSON) ← the closed value set for validating a proposed value |
| — | **`CONFIDENCE_THRESHOLD` DECIMAL(3,2) DEFAULT 0.90** |
| — | `VISIBILITY_SCOPE` ENUM('vendor','admin','system') |
| — | `STATUS` |

`CONFIDENCE_THRESHOLD` is the hardcoded `0.9` in `select-setting` turned into **per-key
data** — exactly what a JEV-style layer needs, so a money-touching setting can demand 0.95
while a cosmetic one applies at 0.7. `ALLOWED_VALUES` supplies the closed value set.

And `execute-setting`'s signature already matches the value table column-for-column —
`VENDOR_ID`, `SETTING_KEY`, `SETTING_VALUE`, `CONTEXT_ID`, `TRACE`, with `SETTING_DEF_ID`
an FK to the definition row. Whoever wrote that function wrote it against this DDL, then
stubbed the persistence out. **The schema is the spec; the code is behind it.**

---

## 5. The "vendor settings AI page" does not exist

There is no AI page in vendor settings. `dodvendprofile` has no AI tab, and there is no
route matching AI/intent/agent/assist in `sysuser/dod-ui-sys.lisp`. Do not go looking.

What exists is the **vendor Web REPL** page, which is a different thing and is a static
mock:

| Piece | State (2026-09-22) |
|---|---|
| Route `^/hhub/vwebrepl` → `com-hhub-transaction-vendor-display-webrepl-page` | ✅ registered, `sysuser/dod-ui-sys.lisp:1155` |
| Page fn + model + widgets | ✅ `vendor/dod-ui-ven.lisp:12-28` |
| Template `:templenum 1` = `webrepltemplate.html` | ✅ wired — `core/dod-ini-sys.lisp:403-415`, var at `:33` |
| Live `GET /hhub/vwebrepl` | ✅ **302** → `/hhub/hhubvendloginv2` (the session gate, working as designed — not a fault) |
| Front end's `POST /api/repl/eval` (`templates/webrepltemplate.html:417`) | ❌ **404** — no dispatcher exists |
| Second path `POST /repl/eval` (`templates/webrepl.html:89`) | ❌ 404 as well |

So the page renders, the input box accepts text, the client-side `FORBIDDEN_PATTERNS`
check runs (`:326-364`) — and the request dies at the server. The banner at `:277`
advertising restricted operations is **security theatre**; there is no evaluator behind it.

The backend it was written against, `vendor/nst-bl-vwebrepl.lisp`, **has never been
compiled or loaded**: it is absent from both build lists (`hhub/nstores.asd` — 129
`:file` entries — and `hhub/package/compile.lisp`), and unlike the vaisettings file there
is **no `.fasl` for it anywhere**. Even if loaded it would fail: it defines package
`nstores.repl` and calls `db:fetch-setting` / `db:update-setting` / `db:fetch-all-settings`
on a **`db` package that does not exist**, plus an unbound `*current-seller-id*`, and
whitelists `validate-setting`, `export-settings`, `import-settings`, `reset-setting`,
`describe-setting`, `help` — **none of which are defined anywhere**. `evaluate-safe` has no
caller. The file ends with `;; ... implement other commands` (`:73`).

🚨 **Also note: `execute-setting` is not whitelisted in the REPL** (`:16-19`), so a *fixed*
REPL still could not reach it. The two subsystems only share a word.

---

## 6. JEV: what it is, and what an LLM does and does not replace

**Jev** (TypeSafe) is a hosted *decision* model: you supply a decision plus a **closed set of
options**, and it returns a chosen option with a probability/confidence and a rationale, with
no conversational text, aimed at classify/route/score at low latency —
[docs](https://openrouter.ai/docs/guides/community/jev),
[tutorial](https://openrouter.ai/docs/guides/community/jev-tutorial),
[when to use it](https://openrouter.ai/blog/tutorials/jev-vs-llm-when-to-use-each/),
[AIML API reference](https://docs.aimlapi.com/api-references/decision-models/typesafe/jev).
**Read the exact response contract from the docs before wiring it — do not guess field names
from this file.** (It is not integrated anywhere in this repo; there are zero `jev` hits.)

The three properties, and how a chat LLM like DeepSeek substitutes for each:

| JEV property | Substitutable? |
|---|---|
| **The contract** — decide, don't chat; closed choice set; rationale; act deterministically | ✅ **Fully.** This is *your* side of the wire. Enumerate registry keys, accept nothing else, act on the band. |
| **Decision quality** on a bounded registry | ✅ **Mostly (85–95% of the practical value).** Closed-set classification over a few dozen described keys is easy for a modern model, and it fixes the real bug: `"payment is done"` → `…AFTER-PAID` is semantic matching, which keyword counting structurally cannot do. Scaling 2 keys → 200 costs prompt length, not code. |
| **A threshold-safe probability** | ❌ **No.** An LLM's self-reported float is ranked but poorly calibrated and unstable across retries; an auto-execute band built on it can flip between runs on identical input. |
| **Latency / cost per decision at scale** | ❌ **No.** Orders of magnitude off; fine for an interactive vendor, wrong for a request path or thousands of rows. |

**Two mitigations that keep the confidence honest** (both cheap, both worth doing from day
one):

1. **Ask for an ordinal, not a float** — `:certain | :likely | :unsure` maps directly onto
   `execute | confirm | abstain`, and models are far more reliable at a 3-way ordinal than at
   a decimal. Manufacture the numeric confidence yourself.
2. **Derive confidence from agreement, not self-report** — repeat the decision, or
   cross-check against the deterministic scorer in §2, and use the *empirical* agreement as
   the threshold input. **Keep the keyword scorer as corroborator and offline fallback**
   (model agrees → execute; disagrees and not `:certain` → confirm; model unreachable →
   today's behaviour). That stays honest and auditable in a way a raw float never is.

**Where JEV would plug in:** a `:provider :jev` arm in `llm-generate`
(`core/nst-bl-ollama.lisp:50`), parallel to the existing DeepSeek and Ollama branches. The
lever that makes this cheap is the **decision log**: if every decision records input, the
candidate set, model choice, model score, heuristic score, agreement and the human's answer
to `:needs-confirmation`, that log becomes the dataset for *either* swapping in real JEV
*or* fine-tuning a small local classifier — with no change to the orchestrator, the bands,
the confirmation flow or the trace. Build the interface; keep the model swappable; let the
log decide.

---

## 7. Sharp edges — read before the first patch

- **🚨 `llm->intent` executes model output as code.** `(read-from-string response)` at `:94`
  with SBCL's default `*read-eval*` bound to `T` means a reply containing `#.(…)` runs
  **inside the live server image**. Fix this before trusting any model output, and prefer
  replacing `read` with JSON + strict schema validation + allowlist check against the
  registry — `llm-generate` already uses `json:decode-json-from-string`, so the plumbing
  exists.
- **The DeepSeek path was reached through an uncommitted one-line edit.** `llm->intent`
  calls `llm-generate` in the working tree; committed, it called `ollama-generate`, which
  pins `*ollama-default-model*` — `"qwen3.5:latest"`, **not** DeepSeek — so it silently took
  the Ollama branch to `192.168.0.100:11434` (`core/nst-bl-ollama.lisp:103-104`). Only
  `llm-generate`'s own default is `*deepseek-default-model*` (`:50`, `:20`).
- **`llm-generate` hardcodes the model in the payload** — `(:model . "deepseek-v4-flash")`
  at `:64`, ignoring `target-model`. Passing `:model "deepseek-reasoner"` still sends flash.
  The `:model` argument is decorative on the DeepSeek path.
- **🚨 A live API key is committed.** `core/extkeys.lisp:46-47` holds
  `*DEEPSEEKAPIKEY*` as a literal, and the file is *not* in `git status` — i.e. it is in
  repository history. Rotate it and move it to the environment.
- **Two `*ollama-url*` values are in play.** The working tree has `192.168.0.100` while the
  committed value is `192.168.0.110` (`:16`) — an uncommitted environment tweak that will
  bite the next person who reinstalls.
- **`nst-bl-aicore.lisp` is the same story, one level up.** The `DOD_PROCURE_*` AI-native
  procurement schema (15 tables, "Sourced. Confidence-scored." —
  `installation/upgrades/nst-dbu-aitables.lisp:61`, probabilities at `:889-892`) is queried
  by `core/nst-bl-aicore.lisp` (`:70, :197, :210, :220, :331, :340, :353, :369`), which is
  **also absent from `hhub/nstores.asd`**, and has only TDD stubs for tests
  (`hhub/test/nst-tst-aientity.lisp:9`, `nst-tst-aientfact.lisp:9`). Do not assume this
  layer is loaded because it is substantive.
- **Check build membership before believing a feature exists.** `hhub/nstores.asd` is the
  live load list (`startup/load.lisp:1-6` → `(ql:quickload :nstores)`);
  `hhub/package/compile.lisp` is a *second*, separate list. A file in neither is dead
  code that still reads like a feature. Presence of a `.fasl` next to the `.lisp` is the
  fingerprint of a manual load in the running image — real, but gone at the next restart.

---

## 8. Recipe — re-verifying any of this in five minutes

```sh
cd /home/ubuntu/ninestores

# 1. Is it actually in the build?  (expect: only core/nst-bl-ollama)
grep -in "vaisetting\|vwebrepl\|aicore\|ollama" hhub/nstores.asd hhub/package/compile.lisp

# 2. Was it ever loaded?  (expect: vaisettings.fasl only, no vwebrepl.fasl)
ls -l --time-style=long-iso hhub/vendor/*vaisettings*.fasl hhub/vendor/*vwebrepl*.fasl

# 3. Does the REPL's endpoint exist?  (expect 404; page itself 302s to login)
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" http://127.0.0.1/hhub/vwebrepl
curl -s -o /dev/null -w "%{http_code}\n" -X POST -H 'Content-Type: application/json' \
     -d '{"code":"(get-setting \"invoice.print.font-size\")"}' http://127.0.0.1/hhub/api/repl/eval

# 4. Who touches the settings tables?  (expect: only the docstring in nst-dal-vnd.lisp:313)
grep -rn "DOD_VENDOR_SETTINGS" --include=*.lisp hhub/
```

For the score in §3.1, do **not** call the model — replicate `tokenize` / `score-setting` /
`select-setting` in a scratch `sbcl --script`. If your scratch run and the live run disagree,
the difference is the model's wording, and that is the finding.

---

## 9. File map

| Path | What is there |
|---|---|
| `hhub/vendor/nst-bl-vaisettings.lisp` | The whole decision layer. Registry `:14-25`, prompt `:51-79`, `build-llm-prompt` `:82-84`, `llm->intent` `:91-95`, `tokenize` `:102-104`, `score-setting` `:106-112`, `resolve-setting` `:117-124`, `select-setting` `:127-135`, `execute-setting` `:142-156`, `build-execution-context` `:159-166`, `run-intent` `:173-183`. Not in either build list. |
| `hhub/vendor/nst-bl-vaisettings.lisp~` | **The abandoned 2026-02-08 copy — broken, see §3.3.** Not a duplicate. |
| `hhub/vendor/nst-bl-vwebrepl.lisp` | The REPL backend stub; never compiled. Whitelist `:16-19`, `evaluate-safe` `:33-57`, `db:` calls `:60-71`. |
| `hhub/core/templates/webrepltemplate.html` | The REPL front end (481 lines). Fetches `/api/repl/eval` at `:417`; client-side blacklist `:326-364`. |
| `hhub/vendor/dod-ui-ven.lisp` | The page `:12-28`; the real settings accessors `:2528-2556`, `:3133-3135`. |
| `hhub/core/dod-ini-sys.lisp` | `*NST-WEBREPL-TEMPLATE*` `:33`; `nst-load-core-templates` `:403-408`; `nst-get-cached-core-template-func` `:410-415`. |
| `hhub/core/nst-bl-ollama.lisp` | `llm-generate` dispatcher `:50`; DeepSeek arm (hardcoded model) `:64`; `ollama-generate` `:103-104`. In the asd at `:84`. |
| `hhub/core/extkeys.lisp` | `*DEEPSEEKAPIKEY*` literal at `:46-47` — committed secret. |
| `installation/upgrades/nst-dbu-vendorsettings.lisp` | `DOD_VENDOR_SETTINGS` `:4-38`; `DOD_VENDOR_SETTINGS_DEFINITION` `:40-70`. DDL only, never touched by Lisp. |
| `hhub/invoice/templates/invoicesettings.lisp` | The real settings: `*invoice-settings-alist*` `:10-32` (22 keys), `*invoice-settings*` `:34+`. |
| `hhub/test/nst-tst-aientity.lisp`, `nst-tst-aientfact.lisp` | TDD stubs for the `DOD_PROCURE_*` layer. |

---

## 10. Ordered plan (none of it started as of 2026-09-22)

1. **`*read-eval*` guard** on the model response — a live hole today (§7), and every step
   below increases how much model output is trusted.
2. **Register in `hhub/nstores.asd`** — the layer currently evaporates on server restart.
3. **Seed/hydrate the registry** — populate `DOD_VENDOR_SETTINGS_DEFINITION` with the real
   vendor setting keys (seeding the invoice-print overlap from `*invoice-settings-alist*`),
   and hydrate `*vendor-setting-registry*` from it, so the closed choice set is the actual
   set of vendor settings instead of a 2-row stub (§4). Per-key `CONFIDENCE_THRESHOLD`
   becomes the band.
4. **Decision contract** replacing `select-setting` — one value object
   `{choice, probability, rationale, action ∈ :execute|:confirm|:abstain, trace}`, with the
   confirmation branch actually consumed (§2.3).
5. **`:provider :jev` arm** in `llm-generate` — closed option list in, structured decision
   out, contract read from the docs (§6).
6. **Real persistence** in `execute-setting` → `DOD_VENDOR_SETTINGS`, whose columns already
   match its signature (§4). **Deliberately deferred by the author** — the `format t`
   placeholder is staged, not broken (§2.3).
7. **Log every decision** — input, candidate set, model choice/score, heuristic score,
   agreement, human answer. This is the dataset that makes JEV-vs-fine-tune a cheap swap (§6).

Entry 1 and 2 are the only two that are safe to do before a design decision. Entry 3 is the
one that decides whether this becomes a product or stays a demo.
