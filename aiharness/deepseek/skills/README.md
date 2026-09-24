# DeepSeek skills

Reusable working knowledge for the Nine Stores / hhub codebase. Each file is a
**skill**: a self-contained, verified description of how one mechanism works, how to
apply it, and the traps that cost time the first time round.

These live **outside** `hhub/` on purpose — they are context for the agent, not code
shipped with the system. Nothing here is loaded by `nstores.asd`.

## The two tiers — and why there are two

| | what it is | lifecycle |
|---|---|---|
| **`knowledge/`** | How the *system* works: architecture, frameworks, mechanisms. Not tied to any feature. | **For keeping.** Never auto-retired. Written once, corrected in place. |
| **top level (`*.md`)** | The **cyclic buffer** — context for the feature(s) being built right now. | Bounded. A feature file is retired once its feature ships and its *learnable* content has been folded into `knowledge/`. |
| **`archive/`** | Retired buffer files. | Kept, un-indexed. Never read unless opened; still greppable. |

**The cycle:** implement a feature → when it stabilises, extract what was *learned*
into the right `knowledge/` file (merging, not copying) → `git mv` the feature file
into `archive/` → drop its index row. The buffer stays at roughly the size of the
work in flight, while the total corpus grows.

**Why the buffer is bounded but nothing is deleted.** Deleting a buffer file looks
free and is not: five of these files are cited by **path** in `.lisp` headers and
`installation/` migrations (`knowledge/nst-bl-conflodis2-DESIGN.md` in 5 places,
`knowledge/ABAC-policy-transaction-CONTEXT.md` in 4), and `knowledge/nst-bl-conflodis2-DESIGN.md` has
**zero** inbound citations *from inside this directory* while four source files point
at it. A "delete what nothing here references" rule would break them. Archiving
keeps the working set small **and** keeps the citations live — see *Retiring a
skill*, which gates on exactly this.

## Start here — symptom → file

The index below says what each file *contains*. This table goes the other way, from
the problem in front of you to the file that answers it. **Enter by symptom when
something is wrong; enter by index when you are exploring.**

| symptom | open |
|---|---|
| "it compiled" but the server still runs the old code · a stale `*migrations*` registry · an endpoint that 404s · nginx `502` | `knowledge/build-and-load-CONTEXT.md` §7 |
| a compile error on `[…]` / SQL literals, or the reader macro | `knowledge/build-and-load-CONTEXT.md` §8 |
| need to compile-check one file without the running image | `knowledge/build-and-load-CONTEXT.md` §6 |
| a migration "ran" (or should have) and the DB is unchanged | `knowledge/schema-migrations-CONTEXT.md` |
| adding ABAC policy + transaction rows for an endpoint | `knowledge/ABAC-policy-transaction-CONTEXT.md` §8 |
| a write verb answered an unexpected status (`:T`/`:F`/`:U`/`:C`) | `knowledge/belnap-four-states-CONTEXT.md`, `knowledge/nst-bl-apidefs2-CONTEXT.md` |
| composing a compound verb (`order→invoice`); a `Failed: 0` that lied | `knowledge/knowledge-conjoin-CONTEXT.md` |
| a product's price, discount or discount window | `nst-bl-prdpricing-CONTEXT.md` |
| a product/catalog route, its JSON shape, or the product verbs | `nst-bl-prdapi-CONTEXT.md` |
| the vendor profile / vendor shipping / vendor payment API | `nst-bl-vndapi-CONTEXT.md`, `vendor-api-sessions-CONTEXT.md` |
| `run-intent` returns a score you cannot account for · a setting that "saved" but persisted nothing · the vendor Web REPL's **Eval** button does nothing · looking for JEV or a vendor settings **AI page** | `nst-bl-vaisettings-CONTEXT.md` |
| **"The function COMMON-LISP:NIL is undefined"** with `CL-PPCRE::BUILD-REPLACEMENT` in the backtrace | `nil-safe-template-substitution-CONTEXT.md` |
| a file you cannot write to; the two-account/one-group model | `knowledge/permissions-CONTEXT.md` |
| the प्रत्यय / ferry / नियम architecture itself; a new entity | `knowledge/WAREHOUSE-NST-GRAMMAR-CONTEXT.md`, `knowledge/nst-bl-conflodis2-DESIGN.md` |
| an email or notification the request waits on · a background job to write (email, SMS/WhatsApp, S3, webhook) · an actor that stopped processing, dropped messages, retried or dead-lettered · a caller blocked while an actor is working | `knowledge/nst-bl-act-CONTEXT.md` |
| asked for a GSTR-1 JSON export, ITC figures or GSTR-2B reconciliation · **"the ITC dashboard says zero"** although the invoices are ITC-eligible · a GST compliance table you expected to be populated is empty · adding a CA/accountant who files on a customer's or vendor's behalf | `knowledge/gst-gstr-compliance-CONTEXT.md` |

## Index — `knowledge/` (for keeping)

Durable mechanism knowledge. Not tied to a feature; corrected in place, never retired.

| Skill | Covers | Verified |
| Skill | Covers | Verified |
| [ABAC-policy-transaction-CONTEXT.md](knowledge/ABAC-policy-transaction-CONTEXT.md) | Seeding `DOD_AUTH_POLICY` + `DOD_BUS_TRANSACTION` and linking them; the `with-hhub-transaction` PEP chain; the `TRANS_FUNC`-is-the-lookup-key trap; tenant-1-only caches; the unwired API seam. | 2026-09-19 |
| [schema-migrations-CONTEXT.md](knowledge/schema-migrations-CONTEXT.md) | The migration framework: the `*migrations*` registry, DDL vs seed-data idempotency, the `varchar(50)` version trap, `load-upgrade-files` + pre-flight, SQL-literal escaping, and why migrations are deliberately not in the asd. | 2026-09-19 |
| [permissions-CONTEXT.md](knowledge/permissions-CONTEXT.md) | The two-account/one-group model, **what the agent can and cannot chmod** (§3 — `sudo` is dead, ownership is required), the diagnostics, `installation/fix-permissions.sh`, and the recurring write-path drift. | 2026-09-19 |
| [build-and-load-CONTEXT.md](knowledge/build-and-load-CONTEXT.md) | The harness, true of every file: the isolated compile-check recipe; the `compile.lisp` traps; **which build the running server actually serves** (project-local `.fasl` ≠ the ASDF cache, and a `502` means no acceptor); the mandatory `clsql:file-enable-sql-reader-syntax` line. Read this when a change "compiled" but did not take effect. | 2026-09-20 |
| [belnap-four-states-CONTEXT.md](knowledge/belnap-four-states-CONTEXT.md) | The Belnap four-valued layer (SHARED CORE): the `:C` provenance-shape bug, making all four states provable, the missing knowledge→domain-result contract, and all four proven over the wire. | 2026-09-13 |
| [knowledge-conjoin-CONTEXT.md](knowledge/knowledge-conjoin-CONTEXT.md) | `knowledge-conjoin` — the truth-order MEET (⊓t) for sequencing steps, and why `bo-merge` is the wrong join; plus the `t` trap, the reason `Failed: 0` is not success. | 2026-09-13 |
| [SKILLS-MAINTENANCE-CONTEXT.md](knowledge/SKILLS-MAINTENANCE-CONTEXT.md) | **How this corpus is written and kept**: the `Read this when` convention, the amortized size budget, the daily append/consolidate cycle, and the retirement gate. Method, not content. | 2026-09-20 |
| [nst-bl-apidefs2-CONTEXT.md](knowledge/nst-bl-apidefs2-CONTEXT.md) | The JSON API layer itself: bound endpoints, the Belnap→HTTP status mapping, session/login rules, nginx deployment reality. | 2026-09-12 |
| [vendor-render-json-contract-CONTEXT.md](knowledge/vendor-render-json-contract-CONTEXT.md) | SETTLED: `render-json` stays in `adhara`, with the four arguments why, and the real defect underneath (the split contract). Do not re-litigate. | 2026-09-14 |
| [nst-bl-conflodis2-DESIGN.md](knowledge/nst-bl-conflodis2-DESIGN.md) | **The conflodis2 design authority** — Tier-2/3 route verbs, the ferry signatures, multi-entity assembly and the कारक. Cited by name in the headers of `nst-bl-conflodis2.lisp`, `nst-bl-apidefs2.lisp`, `nst-bl-whsapi.lisp` and `nst-bl-prdapi.lisp`. Note the `-DESIGN.md` suffix: it predates this directory's `-CONTEXT.md` convention and was kept so those citations stay recognisable. | undated |
| [WAREHOUSE-NST-GRAMMAR-CONTEXT.md](knowledge/WAREHOUSE-NST-GRAMMAR-CONTEXT.md) | **Authoritative architecture reference.** The Paninian grammar: `domain-ctx`, the प्रत्यय verbs, the ferry (लोप), नियम, and `nst-whs` as the first grammar-based entity. The legacy DDD stack is deprecated — do not extend it. | undated |
| [nst-bl-act-CONTEXT.md](knowledge/nst-bl-act-CONTEXT.md) | The actor model: the six invariants (producer never blocked, FIFO, contained failures, bounded mailbox, cooperative shutdown, ask/reply), the API and policy variables, how to write an idempotent behaviour, retries + dead letters + supervision, the status report and symptom→counter table, and the ten measured traps — including the lock-across-behaviour bug that made every "async" email block its caller (751 ms → 0 ms). Also states plainly what is **not** on actors and why. | 2026-09-23 |
| [gst-gstr-compliance-CONTEXT.md](knowledge/gst-gstr-compliance-CONTEXT.md) | The GST/GSTR surface: **the schema is already migrated and live while every GST feature table is empty** — GSTR-1 exports, the ITC lifecycle, GSTR-2B reconciliation, vendor filing status, buyer-vendor ITC-at-risk, the inbound-invoice view and its register/ITC classes. Eight verified traps (`ITC_AMOUNT` NULL on every row, the commented-out ITC summary, `HSNCODE`-not-`HSN_CODE`, the B2B-only view, two competing legal-name columns, no cess columns, no CA role, and mistaking schema presence for wiredness), five gating decisions, the six-slice plan, and the SQL recipe to re-verify it all. | 2026-09-23 |


## Index — the cyclic buffer (active features)

Work in flight. Retired to `archive/` once the feature ships and its learnings land in `knowledge/`.

| Skill | Covers | Verified |
| Skill | Covers | Verified |
|---|---|---|
| [nst-bl-prdpricing-CONTEXT.md](nst-bl-prdpricing-CONTEXT.md) | The product pricing entity: the master-cache sync (the one writer of `CURRENT_PRICE`), what a missing key means on each path, the laws MySQL does not enforce, the reverse ferry, and the bound `PUT …/pricing` endpoint — with its verified 34/34 smoke run and the DB rows that prove it. | 2026-09-20 |
| [nst-bl-prdapi-CONTEXT.md](nst-bl-prdapi-CONTEXT.md) | The products/catalog API: where things live, schema facts (§3), architecture (§4), the bound surface (§5), decisions (§6), deliberately-unfinished (§7), sharp edges (§8). **Split 2026-09-20** — see the four files below. | 2026-09-13 — **partly stale, see below** |
| [products-api-verification-CONTEXT.md](products-api-verification-CONTEXT.md) | What is VERIFIED for products rather than merely reasoned: the verification recipe, the 2026-09-13 probe transcript, and the smoke-test run including the bug it exposed. | 2026-09-13 |
| [vendor-api-handoff-CONTEXT.md](vendor-api-handoff-CONTEXT.md) | The 2026-09-13 handoff for starting the vendor API. **HISTORICAL, partly superseded** — but §17.3's environment facts are durable and were expensive to learn. | 2026-09-13 |
| [nst-bl-vndapi-CONTEXT.md](nst-bl-vndapi-CONTEXT.md) | The vendor-profile migration: verification status (§0), where things live, schema facts, architecture, the प्रत्यय layer as designed, decisions, unfinished work, sharp edges. **Split 2026-09-20** — see the two files below. | 2026-09-13 |
| [vendor-api-sessions-CONTEXT.md](vendor-api-sessions-CONTEXT.md) | The vendor work's operational half: the `t` trap restated, how to resume (Steps 0–3), and the 2026-09-14 session — status, the `read-from-string` RCE class, and the SETTLED shipping + payment design. | 2026-09-14 |
| [nil-safe-template-substitution-CONTEXT.md](nil-safe-template-substitution-CONTEXT.md) | The `cl-ppcre` replacement-function trap: optional fields (GST, transporter, bank, `unit-of-measure`…) that are NIL at render time, the shared `nst-slot-str`, the six patched files, the verified non-issues not to re-patch, the audit + parse-check recipes, and the "the error names no field" correction. | 2026-09-21 |
| [nst-bl-vaisettings-CONTEXT.md](nst-bl-vaisettings-CONTEXT.md) | **The AI/JEV decision layer, and why nothing is wired**: the three colliding "settings" systems, the keyword scorer that is the real decision-maker (§3, with the reproduced `0.75/0.50`), the DDL that is a more advanced spec than the code, the vendor Web REPL that 404s on `POST /api/repl/eval`, what JEV is vs what an LLM can and cannot replace, the `read-eval` hole and the committed API key, and the ordered plan. | 2026-09-22 |

## Known staleness

Context files are snapshots; the code moves. Where a skill is known to have drifted,
that is recorded here rather than silently corrected — **the older snapshot is still
evidence of what was true then**, which is why a stale claim gets an entry here and
never a quiet rewrite.

- **`nst-bl-vaisettings-CONTEXT.md` §356 and §367** refer to `*invoice-settings-alist*`
  in `hhub/invoice/templates/invoicesettings.lisp`. **That defparameter was deleted on
  2026-09-23** — it was dead code: the definition was its only occurrence in the tree and
  no compiled file referenced the symbol. `*invoice-settings*` (now at `:10`) is the only
  invoice settings alist, and it is what the vendor migration
  (`installation/upgrades/nst-dbu-invoicesettings.lisp`) seeds `DOD_VEND_PROFILE.INVOICE_SETTINGS`
  from. The two references above are left in place as the snapshot they are.
- **`nst-bl-prdapi-CONTEXT.md` §7.4** lists `update-shipping` and `update-pricing`
  among seven unbound endpoints. **Both are now bound** and both were exercised for
  the first time on 2026-09-20 (`--write`, 34/34). See
  `nst-bl-prdpricing-CONTEXT.md` §9. **Five of the seven remain unbound.**
- **`nst-bl-prdapi-CONTEXT.md` §7.1** says *"EVERYTHING PAST AUTHENTICATION IS UNRUN"*.
  Resolved — `test/smoke-products-api.sh` passes for read **and** write.
- **Split 2026-09-20, nothing deleted** — `nst-bl-prdapi` (1,109) → 5 files,
  `nst-bl-vndapi` (713) → 3. `§N` numbers were preserved, so references now cross
  file boundaries; each retained file ends with a table saying where each group went.
  Verified mechanically: every non-blank line of both originals appears in exactly
  one output.
- **`nst-bl-prdapi-CONTEXT.md` §7.7** notes the products domain class went into
  `dod-dal-prd.lisp` rather than a `products/nst-dal-prd.lisp` as warehouse did. The
  pricing and category entities follow the same choice, so the divergence is now
  deliberate rather than accidental.
- **File drift:** the prdapi file's §7.8 records that `knowledge/nst-bl-apidefs2-CONTEXT.md`
  *"does not mention products, the query-param change, or the route-ranking change"*.
  It predates the products work and the addition of `api-query-params`.


---

## Writing and keeping skills

The conventions, the size budget, the update cadence and the retirement process live
in **[`knowledge/SKILLS-MAINTENANCE-CONTEXT.md`](knowledge/SKILLS-MAINTENANCE-CONTEXT.md)**.
They are read when *editing this corpus*, not when using it, so they are not kept here —
the README is the entry point and stays deliberately small.
