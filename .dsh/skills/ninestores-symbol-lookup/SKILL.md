---
name: ninestores-symbol-lookup
description: Nine Stores symbol DAG — the generated function-lookup-table (hhub/core/nst-bl-funloodat.lisp) with per-symbol signature, calls, callers, docstring and depth/cost/impact metrics, plus the funcinfo-* query API and the nst-symq CLI. Load before exploring hhub for an unfamiliar symbol, before changing a function's interface (blast radius), or when a grep over the tree would cost more than one lookup.
whenToUse: You need to know what a hhub function takes, what it calls, who calls it, where it lives, or how far a change ripples; you are hunting for an existing utility before writing a new one; you are wiring or tracing a request path across bl-*/dal-*/ui-* layers.
---

# Nine Stores symbol lookup (the rich call DAG)

One generated table answers "what is this function, what does it call, who calls
it, and how big is the risk of touching it" — in a single tool call instead of a
grep-and-read sweep over `hhub/`.

| Layer | Where |
|---|---|
| Data (generated) | `hhub/core/nst-bl-funloodat.lisp` — `function-lookup-table` |
| Generator + query API | `hhub/core/nst-ui-prosymloo.lisp` |
| UI page | `/project-symbols-lookup-page` (superadmin) |
| Agent CLI | `aiharness/deepseek/tools/nst-symq` |
| In-image global | `*nst-function-symbols*` (bound in `hhub/core/nst-bl-ollama.lisp`) |

## Use the CLI first (no image needed)

```
aiharness/deepseek/tools/nst-symq info NAME          # the one-shot summary
aiharness/deepseek/tools/nst-symq calls NAME         # direct callees
aiharness/deepseek/tools/nst-symq callers NAME       # direct callers
aiharness/deepseek/tools/nst-symq subtree NAME [L]   # transitive callees, by level
aiharness/deepseek/tools/nst-symq impact NAME [L]    # transitive callers = blast radius
aiharness/deepseek/tools/nst-symq path A B           # shortest call path A -> B
aiharness/deepseek/tools/nst-symq search QUERY [N]   # name / docstring / keywords
aiharness/deepseek/tools/nst-symq stats              # table totals, entry points, heaviest
aiharness/deepseek/tools/nst-symq fields             # field names, and whether the table is rich
```

Exit codes: `0` ok, `1` unknown symbol or unreachable path, `2` usage or unreadable
table. `NST_SYMQ_TABLE=/path/to/table.lisp` overrides the default path. The CLI
reads the file and never loads it, so it is safe to run at any time.

Prefer `info NAME` over reading a function's file: it carries the signature, the
file, the first docstring line, the call edges and the metrics for a few dozen
tokens. Widen only when `info` is not enough (`subtree` to plan a read, `impact`
before an interface change).

## In-image API (REPL, same answers as the CLI)

```lisp
(funcinfo "format-invoice")            ; whole entry alist
(funcinfo "format-invoice" :calls)     ; one field; name may be package-qualified
(funcinfo-calls "x")   (funcinfo-callers "x")
(funcinfo-arglist "x") (funcinfo-file "x")
(funcinfo-search "invoice" :limit 25 :full nil)
(funcinfo-subtree "x" :depth 2)        ; reachable callees, nearest first
(funcinfo-impact "x"  :depth 2)        ; reachable callers (who a change can break)
(funcinfo-path "a" "b")                ; shortest call path, NIL when unreachable
(funcinfo-report "x")                  ; prints the compact summary, returns the entry
(funcinfo-stats)                       ; prints totals / entry points / heaviest subtrees
(funcinfo-refresh)                     ; re-read the data file into *nst-function-symbols*
```

The query index rebuilds itself whenever the table object changes, so no reset is
needed after a regeneration. If `*nst-function-symbols*` is unbound the API falls
back to reading `function-lookup-table` directly.

## Entry fields

Lisp keywords in the table; `snake_case` in the JSON the UI page receives
(`json:*lisp-identifier-name-to-json*` is bound to `funcinfo-json-key`).

| Field | Meaning |
|---|---|
| `:name` | upper-case symbol name (the table key) |
| `:type` | `FUNCTION` / `MACRO` / `GENERIC-FUNCTION` / `CLASS` / `CONSTANT` / `VARIABLE` |
| `:form` | defining operator: `DEFUN`, `DEFMETHOD`, `DEFMACRO`, `DEFINE-TOOL`, ... |
| `:package` | home package of the symbol |
| `:file` | absolute source path (from SWANK) |
| `:lambda-list` | signature, e.g. `(invoice-obj &key stream format-type)`; `""` when unavailable |
| `:docstring` | live documentation string (may be multi-line; the CLI prints line 1) |
| `:keywords` | curated search keywords carried over from the previous generation |
| `:meta` | curated `(meta ...)` alist, when the symbol declares one (absent otherwise) |
| `:calls` | project symbols this one calls, sorted, filtered to the project's own callables |
| `:used-by` | direct callers, sorted (the inverted edge) |
| `:calls-count`, `:used-by-count` | sizes of the two lists |
| `:depth` | longest call chain below this symbol (leaf = 0) |
| `:cost` | distinct transitive callees — the reading budget to understand it |
| `:impact` | distinct transitive callers — the blast radius of changing it |

## Reading classes and accessors

- A slot accessor is defined implicitly: `(queue :accessor actor-queue)` inside a
  `DEFCLASS` gives `ACTOR-QUEUE` the entry `:form DEFCLASS`, `:lambda-list (object)`
  (a `:writer (setf x)` reads `(new-value object)`), and no `:calls` of its own — it
  is a leaf.
- A class entry's `:calls` are only the symbols its **`:initform`** values call. Slot
  names are not calls, so `(funcinfo "invoiceitem" :calls)` is empty even though the
  class has 18 slots.
- `CLSQL:DEF-VIEW-CLASS` is treated exactly like `DEFCLASS` (same `:form`, no
  signature): its second list is its superclasses, not a lambda list.
- Definitions nested in `(eval-when ...)`, `(progn ...)` or `(when ...)` wrappers are
  found; such a nested definition is not re-scanned as part of its parent's body.
- The residue — symbols whose `:form` equals their `:type` — are macro-generated or
  aliased names no source file defines directly (~170 project-wide).

## Regenerating (must run inside the loaded image)

The graph needs the loaded system (`fboundp`, SWANK source locations), so it cannot
be produced by a script:

```lisp
(generate-lookup-file "nstores" "hhub/core/nst-bl-funloodat.lisp")
```

It returns **T and is completely silent — warnings included**; the generated file is the
result. Regeneration preserves the curated `:keywords` and `:meta` slots and refreshes
`*nst-function-symbols*` in place, so the REPL and the UI page pick up the new graph
without a reload.

Nothing is lost to that silence: a form that fails to
read is counted in `*sym-read-errors*`, a file that cannot be opened at all is recorded
in `*sym-unreadable-files*`, and both are printed by `(report-lookup-generation)` /
`nst-lookup-health`. To watch the scan live, bind the switch:

```lisp
(let ((*lookup-quiet* nil)) (generate-lookup-file "nstores" "hhub/core/nst-bl-funloodat.lisp"))
```

The generated file holds one form that returns a **closure** and nothing else:

```lisp
(funcall (function-lookup-table))   ; -> the alist of symbol entries
(function-lookup-table)             ; -> a closure; the REPL echoes a small object,
                                    ;    never the 1.8 MB of data
```

`funcinfo-*`, the UI model and `nst-bl-ollama.lisp` all go through
`funcall`; nothing on that path prints.

For the coverage numbers, ask for them:

```lisp
(report-lookup-generation)     ; bounded report: meta coverage, DAG wiring, unreadable files
(funcinfo-stats)               ; totals, types, entry points, heaviest subtrees
```

or load `aiharness/deepseek/tools/nst-lookup-health.lisp` and call
`(nst-lookup-health)` for the full picture including the reader-error list. If
`symbols with calls` is near zero, extraction failed; if `no defining form` is large,
the index stopped recognising definitions.

## Traps

- **A table generated before 2026-09-25 is legacy** (6-slot lists: name type file doc
  keywords meta). `nst-symq fields` says so; queries then answer without `calls` /
  `depth` / `cost` / `impact` until the image regenerates it.
- `:calls` contains **project callables only** — CL/library calls, self-recursion and
  class references are deliberately excluded, so an empty `:calls` means "calls
  nothing of ours", not "calls nothing".
- `:calls` comes from reading source forms: a function built by a macro that the
  reader cannot see (or a file it cannot parse) shows no outgoing edges. `used-by` is
  derived, so it is always consistent with `calls`.
- `:cost` / `:impact` are distinct-symbol counts, not runtime cost or call counts, and
  they ignore conditional branches. Use them to budget reading, not to reason about
  performance.
- The consumer tools in `nst-bl-ollama.lisp` (`tool-find-function-metadata`,
  `find-similar-functions`, `estimate-reference-count`) read this table through
  `funcinfo` / `entry-field`; keep both formats working if you change the entry shape.
- Classes, macros and variables are in the table too: check `:type` before assuming
  something is callable.
