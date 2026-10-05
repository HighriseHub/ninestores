# Offline checkers in this corpus — how they are written, and how they are proved · CONTEXT

**Read this when** you are writing or repairing an offline checker/probe under
`aiharness/deepseek/tools/` — a tool that reads `hhub/**` sources with no image and no database and
reports PASS/FAIL — or when a checker said something you do not believe (a healthy file reported
**unreadable**, a method reported **missing** from a file that has it, a field that IS sent reported
"never sent"), or when you have added a `hhub/**` file and need to know every list that must know it.

**Verified:** 2026-10-04, on the orders batch (S9/S10, `nst-vordh-mirror-check.lisp`). **Applies to:**
every `*-check`, `*-probe` and `*-verify` tool in `aiharness/deepseek/tools/`, and to
`nst-preflight.lisp`. The batch-specific findings these rules were paid for are in
`../vendor-orders-adhara-CONTEXT.md` (§2, §3, §4) and `../order-adhara-stories-CONTEXT.md` §0/§9b.

---

## 1. The rule: a check that cannot fail is not a check

1. **Mutation-test every checker, in both directions.** Break the thing it checks and confirm the tool
   exits non-zero *and names the specific finding*; then confirm it passes on the clean input. A probe
   that cannot fail proves nothing, including its own PASS.
2. **Assert the tool found its INPUTS, not just the absence of findings.** A check whose input is
   missing must FAIL, never quietly pass: `nst-preflight.lisp:55-71`'s lesson is *a missing dependency is
   indistinguishable from a broken file*.
3. **Every checker bug in the orders batch was found by exercising the failure path, never by reading
   the checker.** The failure path is where the checker's own assumptions get tested, so budget for it.
4. **Prefer a construction that makes the defect impossible to one that detects it** (quote every SQL
   identifier; drive a copier from one list). Then the checker only has to guard the seams.

## 2. The four classes of checker bug — each hit for real

| # | class | the instance (2026-10-04) |
|---|---|---|
| 1 | **The reader cannot read the tree.** | A stubbed `clsql` package answered `Package [ does not exist` for `[:row-id]`, and the tool reported a HEALTHY file as unreadable. Fix: a readtable with `[`/`]` as whitespace. `ql:quickload :clsql` collides over uffi here, which is why the tool stays dependency-free and leaves true reader balance to `nst-preflight`. |
| 2 | **A form is walked positionally and the position is wrong.** | `find-render-json` looked one level too shallow — `(second (elt f 2))` is the *ctx* specializer, not the class — so the check reported a method missing from a file that has it. |
| 3 | **The extractor recognises only the bare shape.** | The published-slot extractor only saw a bare `(accessor r)`, so every field WRAPPED for formatting — all dates, all flags, all identifiers — was reported as "mirrored but never sent". This failure mode looks exactly like a real defect: *a machine-checked claim is only as good as the machine's reading*. |
| 4 | **The check's universe is the wrong object.** | The JSON universe is the RESPONSE MODEL, not the mirror list (see below). Related: `:vendor-id` is a real SLOT, so it cannot live in a control-key list whose invariant is "none of these is a slot" — it is stripped instead. |

Class 4 in full, because the arithmetic is the point: the JSON universe is the RESPONSE MODEL, not the
mirror list — `published + withheld == mirror
+ row-id`, because `domain->response` sets row-id explicitly rather than walking the list.

## 3. The report must not lie about its own numbers

`~:[FAIL (~D problem(s))~;PASS (~D check(s))~]` takes **ONE** `~D` after the conditional, so the FAIL
branch printed the *check* count under the label "problem(s)" — a failing run read
`FAIL (10 problem(s))` when it had two. The mutation test found this in the checker's own summary line.
It now prints both counts explicitly. **The same trap bit three files in the orders batch** — print the
counts separately, and treat a report that lies about its own arithmetic as worse than no report.

## 4. What a checker must establish before it reads anything

* **`nst-preflight.lisp`'s TWO lists are separate, and both must be updated for a new `hhub/**` file:**
  `*files*` (delimiter balance, SQL reserved-word quoting) and `*hhub-new-files*` (build registration). A
  file in the first but not the second is **balanced and then silently skipped** for registration — a
  pass that means nothing. The batch's fuller rule is that a new `hhub/**` file needs **four**
  registrations (`hhub/package/compile.lisp`, `hhub/nstores.asd`, and both preflight lists).
* **A tool or probe that reads the tree's own symbols must be `(in-package :nstores)` AFTER the tree
  loads.** The tree has ONE package; a probe left in `CL-USER` fails with
  `The function COMMON-LISP-USER::FIND-API-ROUTE is undefined` *after* a four-minute load, which reads
  exactly like a missing binding.
* **Delimiter balance is decided by the Lisp reader, never by a hand-written scanner.** A hand-written
  one was wrong three ways in the orders batch.

## 5. What no offline check can do

Live behaviour stays a human step: a session-scoped 401/404 sweep, the database-side classes in
`nst-preflight` §4(a)–(c), and anything that needs the running image. Those print on every run precisely
so they cannot be forgotten — an offline tool's PASS is never a statement about the live system.

## 6. Where the tools are

The inventory and what each one covers is indexed in `../README.md` (the **symptom → file** table names
the tool that answers each symptom) and per tool in `../order-adhara-stories-CONTEXT.md` §0/§9b. Do not
re-list them here: a duplicated inventory drifts.
