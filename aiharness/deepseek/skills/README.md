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
| need to load or check a file **against the live image**, or evaluate a form in it · a probe that hangs with no answer · a `-f` load failing with *"No source tables supplied to select statement"* while the same form evaluates fine | `knowledge/build-and-load-CONTEXT.md` §9 |
| changing the build driver or adding a file to the build list · a `(compile-production)` reporting **`Compiled: 0` / `Success Rate: 0.0%`** · incremental vs. full rebuild, or which one you just ran | `knowledge/compile-harness-CONTEXT.md` |
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
| **resuming work a previous session left unfinished** · "what is still open" · a deferred decision · an item deliberately parked · **the ORDERS batch — S0–S15 DONE, S16 IN PROGRESS (two of four suites run; the create's first `201` awaits an image restart)** | `PENDING-WORK-CONTEXT.md`, `order-adhara-stories-CONTEXT.md` |
| a password that authenticates with extra characters on the end · an 8-character effective password limit · choosing between argon2id / bcrypt / PBKDF2 here · `encrypt`-based credential storage | `PENDING-WORK-CONTEXT.md` §1 (the fix's done half is in `core/dod-bl-utl.lisp`) |
| the प्रत्यय / ferry / नियम architecture itself; a new entity | `knowledge/WAREHOUSE-NST-GRAMMAR-CONTEXT.md`, `knowledge/nst-bl-conflodis2-DESIGN.md` |
| **converting the ORDER header, order line or VENDOR order to the adhara grammar** (`nst-ordh`/`nst-orditm`/`nst-vordh`) · a story list for that work · what the `order → invoice` compound verb waits on · whose tenant an order belongs to · **why `installation/hhubplatform.sql` must not be trusted for the order tables** | `order-adhara-stories-CONTEXT.md` |
| **the VENDOR side of an order** (`GET`/`PUT /hhub/api/v1/vendor/orders…`, `nst-vordh`, the `DOD_VENDOR_ORDERS` row that `POST /orders` writes) · **a vendor row's `ORD_DATE` moved on its own**, or an order date that changed without anyone touching it · a vendor reading another vendor's or another tenant's order · which columns of the vendor order table exist · extending `dod-vendor-orders` instead of writing a new class | `vendor-orders-adhara-CONTEXT.md` (T9 is **vendor-only** — header `ORD_DATE` is a `date`, vendor `ORD_DATE` is a `timestamp ON UPDATE`; the 60-column measurement; V1–V7) |
| an email or notification the request waits on · a background job to write (email, SMS/WhatsApp, S3, webhook) · an actor that stopped processing, dropped messages, retried or dead-lettered · a caller blocked while an actor is working | `knowledge/nst-bl-act-CONTEXT.md` |
| asked for a GSTR-1 JSON export, ITC figures or GSTR-2B reconciliation · **"the ITC dashboard says zero"** although the invoices are ITC-eligible · a GST compliance table you expected to be populated is empty · adding a CA/accountant who files on a customer's or vendor's behalf | `knowledge/gst-gstr-compliance-CONTEXT.md` |
| **building or checking the GSTR-1 JSON** · which key a section uses · what belongs in `b2cs` vs `exemp` · the UQC / `inv_typ` / state-POS code lists · whether a key name is verified or inferred | `knowledge/gstr1-json-reference-CONTEXT.md` + `../tools/gstr1-reference.json` |
| designing or debugging the **invoice API** · an invoice endpoint that 401s, 404s or 409s · which of the spec's twelve invoice endpoints exist · whether the invoice routes have ever been exercised | `invoice-api-handoff-CONTEXT.md` |
| **an order route answers 500 `internal_error`** · a slot added to `*ordh-mirrored-slots*` or `*orditm-mirrored-slots*` · **a response field that is silently never sent** (published + withheld no longer adds up) · a duplicated JSON key · `deleted-state` leaking outbound | `../tools/nst-order-mirror-check.lisp` (offline, no image — performs `domain->response`'s exact setf per slot and sums the render allowlist; exits 1 and names the slot or the key) |
| **every authenticated invoice endpoint answers 500 `internal_error`** · `the slot …DELETED-STATE is missing from …NSTINVHRESPONSEMODEL` · a slot added to `*invh-mirrored-slots*` or `*invitm-mirrored-slots*` | `../tools/nst-invoice-mirror-check.lisp` (offline, no image — exits 1 and names the slot) + `invoice-api-handoff-CONTEXT.md` §1b |
| **the app will not come up after a restart** · `… is not a registered action route` at LOAD time · a new `register-api-route` binding added above its `register-action-route` | `../tools/nst-binding-order-check` (offline — exits 1, names the route) |
| **an order endpoint answers something unexpected** · which `/orders` paths exist over HTTP and what each one does · a **412** on an `If-Match` PUT · a mismatched `{ordnum}/{item-id}` pair answering 404 rather than 409 · why an order line cannot be moved between orders | `order/nst-bl-ordhapi.lisp` + `order/nst-bl-orditmapi.lisp` (the seven bound paths, the 412 seam, the verify-then-strip rule) + `order-adhara-stories-CONTEXT.md` S12/S13 and its reconnaissance section |
| **starting any story in the orders batch** · "are we about to hit a bug we could have known about" · a file that will not read · a SQL statement a reserved word will stop · what to check before APPLYING a migration | `../tools/nst-preflight.lisp` (offline; delimiter balance decided by the Lisp reader, MySQL reserved-word quoting, non-vacuity, and the DB-side queries to run) + the story file's §9b |
| **a document number, an order reference, or the April-March financial year** · a `{ref:N}`/`{prefix}`/`{fy}` token that renders emptily or literally · a key that fell back to a default instead of failing closed | `../tools/nst-verify-doc-numbering.lisp` (offline, no database — 116 checks over the FY rule, the ordh field-policy partition and the order/entity mirror lists, the counter SQL's quoting and the two hand-written SQL copies, the single-pass template renderer, the reference permutation and the fail-closed key; exits 1 and names the failure) |
| **the restart itself fails / the site is down with no acceptor** · `There is no class named …BUSINESSSERVER` at load time · a build-order change that crossed a load-time class dependency | PENDING-WORK §1c + `../tools/nst-offline-load.lisp` (offline — the regression test for the order) |
| 🚨 **`POST /orders` fails and the create has never worked** · 400 `"every line must name a product row-id (prd-id); got NIL"` although the body carries the key · 400 `"every line must carry a positive integer prd-qty"` when the client sent `qty` · **500 `The slot …SHIPPED-DATE is unbound in the object #<NST-ORDH>`** after a number was minted · **a NESTED JSON body entry read as NIL** · a decoded body whose nested keys are symbols while only strings are tested · `api-camel->lisp-name` answering `P-R-D-I-D` | `../tools/nst-verify-order-create.lisp` (offline, no image — the CREATE's two pure halves: `ordh-nested-param` against what cl-json **actually** produces through the real decode → `api-normalize-body-params` → `ordh-lines-array` path, and all THREE domaintodb copiers against a create that supplies only SOME fields, asserting an initformed `0.0`/`"N"` still copies; mutation-tested in both directions — revert either fix and it exits 1 naming the case). ⚠ THE DEFECTS IT FOUND: the create had **never once succeeded** over HTTP — a 400 in the read half, then a 500 in the write half, each invisible from the BL |
| **the public invoice link will not open, or asks for a password** · its expiry or attempt limit · an invoice link that has gone stale · **a customer replies "this link is expired" while the vendor's page looks fine** · the vendor's share icon is red, or needs to stop being red · changing `*invoice-ext-link-lifetime-seconds*` or `*invoice-ext-max-attempts*` · **the emailed/attached PDF is a picture of the PASSWORD FORM**, or the 4-digit prompt sits on top of the invoice | `knowledge/invoice-public-link-CONTEXT.md` (incl. **§the render token**) + `../tools/nst-verify-invoice-public-link.lisp` (offline, no image — 116 checks over the signature, expiry, forgery refusal, the gate, the `:render` marker, whose phone number the password is, AND the vendor's red share icon, rendered and asserted as markup) |
| **an intermittent `the slot … is missing from the object NIL`** · a `GETHASH` that should hit, missing · a redirect that lands where the thing it names cannot be found · **it works for existing records and never for new ones** · an id that breaks a JS selector or a character counter · about to use `hhub-random-password` for something that is not a password | `knowledge/identifier-and-token-hygiene-CONTEXT.md` (the two generators, the hostile-character table, the measured 21%, and the call sites not yet swept) |
| **`The function :DIV is undefined` while rendering a page** · a cl-who tag written inside `when`/`if` produced no markup · base64 that decodes to line noise · `:HMAC` is not a digest name | `knowledge/invoice-public-link-CONTEXT.md` §5 (seven measured traps) |
| **adding, moving or un-modalling a VENDOR setting** · an entry in the sidebar's Settings node · a settings page built from a template · about to copy `invoicesettings.html` / `invoicesettings.lisp` as your pattern · a settings save that wiped a field the page did not render | `vendor-settings-CONTEXT.md` (design + the traced invoice-settings mechanism and its eight traps) |

## Index — `knowledge/` (for keeping)

Durable mechanism knowledge. Not tied to a feature; corrected in place, never retired.

| Skill | Covers | Verified |
| Skill | Covers | Verified |
| [ABAC-policy-transaction-CONTEXT.md](knowledge/ABAC-policy-transaction-CONTEXT.md) | Seeding `DOD_AUTH_POLICY` + `DOD_BUS_TRANSACTION` and linking them; the `with-hhub-transaction` PEP chain; the `TRANS_FUNC`-is-the-lookup-key trap; tenant-1-only caches; the unwired API seam. | 2026-09-19 |
| [schema-migrations-CONTEXT.md](knowledge/schema-migrations-CONTEXT.md) | The migration framework: the `*migrations*` registry, DDL vs seed-data idempotency, the `varchar(50)` version trap, `load-upgrade-files` + pre-flight, SQL-literal escaping, and why migrations are deliberately not in the asd. | 2026-09-19 |
| [permissions-CONTEXT.md](knowledge/permissions-CONTEXT.md) | The two-account/one-group model, **what the agent can and cannot chmod** (§3 — `sudo` is dead, ownership is required), the diagnostics, `installation/fix-permissions.sh`, and the recurring write-path drift. | 2026-09-19 |
| [build-and-load-CONTEXT.md](knowledge/build-and-load-CONTEXT.md) | The harness, true of every file: the isolated compile-check recipe; the `compile.lisp` traps; **which build the running server actually serves** (project-local `.fasl` ≠ the ASDF cache, and a `502` means no acceptor); the mandatory `clsql:file-enable-sql-reader-syntax` line. Read this when a change "compiled" but did not take effect. | 2026-09-20 |
| [compile-harness-CONTEXT.md](knowledge/compile-harness-CONTEXT.md) | **The build driver's design authority** (`package/compile.lisp`): incremental-by-default with `clean-and-compile` as the only full rebuild (force is expressed by *deletion*, not a flag); the freshness gate and why a skipped file is still loaded; how to read a run (`*last-compilation-stats*`, and why the summary is silent about `skipped`); the conventions for adding a file to both the list and the `.asd`; and six measured traps. | 2026-09-25 |
| [belnap-four-states-CONTEXT.md](knowledge/belnap-four-states-CONTEXT.md) | The Belnap four-valued layer (SHARED CORE): the `:C` provenance-shape bug, making all four states provable, the missing knowledge→domain-result contract, and all four proven over the wire. | 2026-09-13 |
| [knowledge-conjoin-CONTEXT.md](knowledge/knowledge-conjoin-CONTEXT.md) | `knowledge-conjoin` — the truth-order MEET (⊓t) for sequencing steps, and why `bo-merge` is the wrong join; plus the `t` trap, the reason `Failed: 0` is not success. | 2026-09-13 |
| [SKILLS-MAINTENANCE-CONTEXT.md](knowledge/SKILLS-MAINTENANCE-CONTEXT.md) | **How this corpus is written and kept**: the `Read this when` convention, the amortized size budget, the daily append/consolidate cycle, and the retirement gate. Method, not content. | 2026-09-20 |
| [nst-bl-apidefs2-CONTEXT.md](knowledge/nst-bl-apidefs2-CONTEXT.md) | The JSON API layer itself: bound endpoints, the Belnap→HTTP status mapping, session/login rules, nginx deployment reality. | 2026-09-12 |
| [vendor-render-json-contract-CONTEXT.md](knowledge/vendor-render-json-contract-CONTEXT.md) | SETTLED: `render-json` stays in `adhara`, with the four arguments why, and the real defect underneath (the split contract). Do not re-litigate. | 2026-09-14 |
| [nst-bl-conflodis2-DESIGN.md](knowledge/nst-bl-conflodis2-DESIGN.md) | **The conflodis2 design authority** — Tier-2/3 route verbs, the ferry signatures, multi-entity assembly and the कारक. Cited by name in the headers of `nst-bl-conflodis2.lisp`, `nst-bl-apidefs2.lisp`, `nst-bl-whsapi.lisp` and `nst-bl-prdapi.lisp`. Note the `-DESIGN.md` suffix: it predates this directory's `-CONTEXT.md` convention and was kept so those citations stay recognisable. | undated |
| [WAREHOUSE-NST-GRAMMAR-CONTEXT.md](knowledge/WAREHOUSE-NST-GRAMMAR-CONTEXT.md) | **Authoritative architecture reference.** The Paninian grammar: `domain-ctx`, the प्रत्यय verbs, the ferry (लोप), नियम, and `nst-whs` as the first grammar-based entity. The legacy DDD stack is deprecated — do not extend it. | undated |
| [nst-bl-act-CONTEXT.md](knowledge/nst-bl-act-CONTEXT.md) | The actor model: the six invariants (producer never blocked, FIFO, contained failures, bounded mailbox, cooperative shutdown, ask/reply), the API and policy variables, how to write an idempotent behaviour, retries + dead letters + supervision, the status report and symptom→counter table, and the ten measured traps — including the lock-across-behaviour bug that made every "async" email block its caller (751 ms → 0 ms). Also states plainly what is **not** on actors and why. | 2026-09-23 |
| [gst-gstr-compliance-CONTEXT.md](knowledge/gst-gstr-compliance-CONTEXT.md) | The GST/GSTR surface: **the schema is already migrated and live while every GST feature table is empty** — GSTR-1 exports, the ITC lifecycle, GSTR-2B reconciliation, vendor filing status, buyer-vendor ITC-at-risk, the inbound-invoice view and its register/ITC classes. Eight verified traps (`ITC_AMOUNT` NULL on every row, the commented-out ITC summary, `HSNCODE`-not-`HSN_CODE`, the B2B-only view, two competing legal-name columns, no cess columns, no CA role, and mistaking schema presence for wiredness), five gating decisions, the six-slice plan, and the SQL recipe to re-verify it all. | 2026-09-23 |
| [invoice-public-link-CONTEXT.md](knowledge/invoice-public-link-CONTEXT.md) | **The public invoice link**: the two session-less routes, the token format (`base64url(payload).hex(hmac-sha256(payload, vendor.SALT))`) and why it is signed rather than stored, the five-minute lifetime and the password (**the CUSTOMER's last four phone digits since 2026-10-03** — it was the vendor's, whose own number is printed on every invoice they issue) with its attempt-limit rules, the invoice→customer resolution that needs, **the vendor's own verdict on the stored link** (`invoice-ext-url-status` → a RED share icon plus a title naming the NEXT button, which is what stops the customer being the one who discovers an expired link), **the `:render` token that lets the PDF pipeline through the gate without a password** (and the four call sites, including the customer's download button that must fetch the key it ARRIVED with), and **seven measured traps** — base64 is case-sensitive, cl-who does not convert tags inside `when`, cl-who single-quotes attributes, there is no `:hmac` digest name, a `let` closing before the form that uses it, `select-vendor-by-id` returns the legacy view-class, and minting fails closed for the three salt-less vendor rows. | 2026-10-03 |
| [identifier-and-token-hygiene-CONTEXT.md](knowledge/identifier-and-token-hygiene-CONTEXT.md) | **`hhub-random-password` is a PASSWORD generator and must never mint an identifier.** The hostile-character table (`&` truncates a query string, `+` is a space in a form body, `#` never reaches the server, `.`/`?` break a JS/CSS selector); why commit `6cb4c3d` (2026-09-13) made every identifier call site intermittent by fixing the password alphabet; the invoice-wizard incident it caused (`MISSING-SLOT INVOICEHEADER` from NIL on NEW invoices only) and its fix; **the four call sites still minting identifiers from it**; and the measurement that a hand-retry cannot see (1056/5000 keys mangled vs 0/5000). | 2026-10-03 |
| [gstr1-json-reference-CONTEXT.md](knowledge/gstr1-json-reference-CONTEXT.md) | **The complete GSTR-1 JSON reference.** All 18 data sections with their key paths; the invoice-level vs aggregated split that drives the assembler; the section-splitting rule the collector does not yet apply (a section is chosen per ITEM LINE, not per invoice); the authoritative UQC / `inv_typ` / POS / rate code lists from GSTN's own offline-tool template; and **per-section provenance marking which key names are verified against a real uploaded file and which are inferred**. Machine-readable sample: `../tools/gstr1-reference.json`. | 2026-09-25 |


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
| [actor-invoice-handoff-CONTEXT.md](actor-invoice-handoff-CONTEXT.md) | State of play for the invoice templates, invoice settings/logo and the actor model after the 2026-09-23/24 session: the four commits, the applied `INVOICE_SETTINGS` backfill, where the durable knowledge lives, the five open items offered but not done, and the two facts that cost the most time. Read this first in a new session on this work. | 2026-09-24 |
| [PENDING-WORK-CONTEXT.md](PENDING-WORK-CONTEXT.md) | **The deferred-work ledger.** What is still open, what is already DONE so it is not redone, the exact file:line sites, and the decision blocking each item. Currently: the live password-storage defect (steps 2–3), invoice-settings phase 2, the `DOD_VENDOR_SETTINGS` table, the ungated bulk-products smoke script, and **§9 the vendor Settings page (designed, parked 2026-10-03)**. **Enter here when resuming anything a previous session left unfinished.** | 2026-09-25 |
| [invoice-api-handoff-CONTEXT.md](invoice-api-handoff-CONTEXT.md) | The invoice API after the 2026-09-25/26 session: the four commits and what they contain; the verified state of the running system (build `Failed: 0`, dispatcher live and answering **401** for `GET /hhub/api/v1/invoices`, and **nothing exercised with a session**); the twelve spec endpoints and which seven are bound; the eight decisions already taken; the eight that are open, each with its blocker; the deliberate gaps in the code; and the five traps — including why a binding must follow its registration in load order, and how an in-image load wedges class definition for the life of the process. **Read this first in a new session on the invoice API.** | 2026-09-26 |
| [order-adhara-stories-CONTEXT.md](order-adhara-stories-CONTEXT.md) | **The order entities on the adhara grammar: S0–S15 DONE, S16 in progress — 638 lines, narrative archived.** Twenty-one decisions covering THREE entities (`nst-ordh` = `DOD_ORDER`, `nst-orditm` = `DOD_ORDER_ITEMS`, `nst-vordh` = `DOD_VENDOR_ORDERS`), ten bound endpoints across a customer and a vendor channel, `ORDNUM` minted as `ORD-<DOC_PREFIX>-<FY>-<seq>` from a **document prefix** on the customer (`DOD_CUST_PROFILE.DOC_PREFIX varchar(8)` — never `char`, which pads a space into every number; system-prefilled, customer-overridable, allocated not derived because derivations collide), rendered through the number-format template that **already exists** (`invoice-number-format`) extended with `{prefix}`/`{fy}` tokens — plus the **counter table** `{counter}` has never had, the `DFT` status code and the nine legacy filters that must learn it, and the `POST /orders` multi-entity assembly. Stories S0–S17 with acceptance criteria; nine traps; and **§10, a standards review (OWASP API Top 10 · NIST 800-53/800-63B · Google AIP · RFC · WCAG) with twenty findings**, written before the first story — including F1, the sequential counter as a competitor-enumeration oracle (now fixed by a non-sequential keyed reference), F2, where a sentence of the design itself licensed a tenant-less lookup, and F20, live AWS SMTP + reCAPTCHA credentials committed in `hhub/core/extkeys.lisp`. Two findings worth the read on their own: **§1 — `installation/hhubplatform.sql` is stale for these tables**, and believing it produced three wrong decisions (it hides that live `STATUS` is `char(3)` so `'DRAFT'` is unstorable, that `ORDNUM` has NO unique key, and that `DOD_ORDER` has no `VENDOR_ID` column at all); and **§3b — there is no order number in the database at all**, 485 of 485 orders and 462 of 462 vendor rows having a NULL `ORDNUM`, so the identity migration must *invent* numbers rather than backfill them. | 2026-09-27 |
| [vendor-orders-adhara-CONTEXT.md](vendor-orders-adhara-CONTEXT.md) | **The vendor order channel (`nst-vordh` over `DOD_VENDOR_ORDERS`), kept apart from the customer channel on purpose.** The live 60-column measurement (the legacy `dod-vendor-orders` class carries 26); **T9 measured as vendor-only** — `DOD_ORDER.ORD_DATE` is a `date` while `DOD_VENDOR_ORDERS.ORD_DATE` is a `timestamp ON UPDATE CURRENT_TIMESTAMP`, so the header's own `clsql:date` declaration drops the time-of-day here and AC (f)'s byte-identity assertion fails even with the auto-update defeated; the triple scope rule (`VENDOR_ID` **and** tenant **and** `DELETED_STATE`); `ORDNUM IS NULL` → 404 rather than a guess; promoting the interim writer `persist-vendor-orders` and retiring it; decisions V1–V7; the three `/vendor/orders` routes and the S13 (c) shadowing test they unblock. | 2026-10-04 |
| [vendor-settings-CONTEXT.md](vendor-settings-CONTEXT.md) | **The vendor Settings page: design settled, no code written.** One route (`/hhub/dodvendprofile?context=<group>/<section>`, already dispatched), one `*vendor-settings*` registry in `hhub/vendor/templates/` driving **both** the sidebar Settings node and the page, a template holding chrome + panes with `%Named Tokens%`, one `<form>` per pane posting to its existing action (no save JS), accordion of sections with group dividers plus a filter box. Also the **traced invoice-settings mechanism** it is modelled on — `*invoice-settings*`, the boot template cache, the single-key setter, the `invoice-settings` blob column, and the session-cached payment flags — and **eight traps in that precedent not to inherit** (positional `~A` placeholders, ids already drifted from the JS that reads them, whole-blob saves forcing per-field preservation hacks, the `(key value)`-vs-`(key . value)` duality, dead duplicate keys in the inline script, template CSS outside the injected markers, `read-from-string` without `*read-eval* nil`, and six redirects that would drop the vendor at the top of the page after a save). Records why `DOD_VENDOR_SETTINGS` — schema from the **parked AI decision-registry line** (`nst-bl-vaisettings`), with no Lisp reader or writer — is **not** a store for this page. | 2026-10-03 |

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
