# Building and loading the Nine Stores image · CONTEXT

**Split out of `nst-bl-prdpricing-CONTEXT.md` on 2026-09-20**, when that file passed
the 400-line target (README · *The daily size cycle*). Section numbers are preserved
from the parent. **Content is unchanged.**

**Covers the harness, not any one entity.** Three things that are true of every file
in the tree and cost real time to learn:

* §6 — how to compile-check a single file WITHOUT the running image (the isolated
  compile recipe, and how to read its output).
* §7 — the `package/compile.lisp` traps, and which build the running server
  actually serves.
* §8 — `clsql:file-enable-sql-reader-syntax`, mandatory in any file using `[...]`
  SQL literals.

**Read this when:** a change "compiled" but the server does not have it; a
compilation appears to do nothing; or you are about to edit a file containing SQL
literals. This is the file for *why did my change not take effect*.

**The single most expensive lesson here:** *"it compiled" and "the running system
has it" are different claims, and they diverged twice on 2026-09-20.*

## 6. Recipe — compile-check this file WITHOUT the running image

The project's own databases are live, so a mistake here is expensive. A syntax
check is not enough: an unescaped `"` inside a docstring **terminates the string
and turns the following words into code**, and `read` cannot catch that in a bare
SBCL because `clsql` is missing.

What works (measured 2026-09-20, SBCL 2.6.8 + quicklisp):

```bash
cd /home/ubuntu/ninestores && mkdir -p .asdf-cache
XDG_CACHE_HOME=/home/ubuntu/ninestores/.asdf-cache sbcl --noinform --non-interactive \
  --eval '(load "~/quicklisp/setup.lisp")' \
  --eval '(dolist (s (list :clsql :hunchentoot :cl-json :cl-csv)) (ql:quickload s :silent t))' \
  --eval '(load "hhub/package/packages.lisp")' \
  --eval '(handler-case (multiple-value-bind (f w e) (compile-file "hhub/products/nst-bl-prdpricing.lisp" :output-file "/home/ubuntu/ninestores/.asdf-cache/check.fasl") (declare (ignore w)) (format t "~&RESULT: out=~A failure-p=~A~%" f e)) (error (c) (format t "~&RESULT: COMPILE ERROR: ~A~%" c)))'
```

- `XDG_CACHE_HOME` **is load-bearing.** ASDF otherwise writes to
  `~/.cache/common-lisp`, which the file sandbox denies; the failure surfaces as
  *"Can't create directory …/common-lisp/…"* and looks like a clsql problem.
  An ASDF `:output-translations` directive is **not** a substitute — `:root`
  rejects an absolute path ("Expected a relative pathname").
- **🚨 THE PACKAGE SET DEPENDS ON THE FILE, and a missing one looks like a broken
  edit.** `clsql` alone is enough for the entity and प्रत्यय files, but the **core**
  files reference more packages at READ time: `nst-bl-apidefs2.lisp` needs
  **hunchentoot** (line 335) and **cl-json**, and without them the compile stops with
  `READ error: Package HUNCHENTOOT does not exist` — reported as `caught ERROR`, so it
  reads exactly like a syntax mistake you just made. It is not: it is the harness.
  Load `clsql`, `hunchentoot`, `cl-json` and `cl-csv` before compiling anything in
  `core/` or `products/`. Learned the hard way on 2026-09-20 — three times, losing a
  cycle each to hunchentoot, then JSON, then CL-CSV. **A missing package always
  reports as `caught ERROR: READ error`, never as a warning**, so it is
  indistinguishable from a syntax mistake at a glance. Add the package, re-run, and
  only then go looking at your edit.
- `failure-p = T` is **expected** here and is not a verdict: this isolated compile
  cannot see the rest of the system, so every cross-file function is an
  undefined-function style-warning. **Read the condition list, not the flag.**
- **The real signal is `undefined variable:`** — that is how the docstring bug was
  caught (`IS` and `REQUIRED` reported as undefined variables). A clean run leaves
  only three, all `*DOD-DATABASE-CACHING*`, which is defined in a core file this
  recipe does not load.
- A fast paren-balance check is still worth running first; it catches most edits
  for free.

---

## 7. The compilation harness traps (`package/compile.lisp`)

`compile.lisp` is the build driver, **not** a file in its own list, and it is also
an asd entry (`nstores.asd:50`). Three traps:

1. **`clean-and-compile` cannot refresh the driver.** `get-hhub-file-list` does not
   contain `"package/compile"` (verified: zero matches), so cleaning and
   recompiling never rebuilds `compile-hhub-files` itself. Edit `compile.lisp` and
   a stale definition keeps running in the image until you `C-c C-k` the buffer.
   **Symptom seen:** a fix to `compile-hhub-files` appeared to do nothing.
2. **The REPL echoes the primary value.** `compile-hhub-files` used to end with a
   bare `stats`, so every `(compile-production)` printed a wall of
   `#S(COMPILATION-STATS …)`. **`(values stats)` does NOT fix this** — one value is
   still the primary value and still prints. Only **zero** values are silent.

   Current shape (`compile.lisp:36`, `:419-420`): the struct is published to
   `*last-compilation-stats*` and the function returns `(values)`. Read the last
   run from the variable.

3. **🚨 THE PROJECT-LOCAL `.fasl` IS NOT THE BUILD THE SERVER SERVES.** `compile.lisp`
   writes fasls *beside the sources*. The application loads from ASDF's cache —
   **`/home/hunchentoot/.cache/common-lisp/sbcl-2.6.8-linux-x64/home/ubuntu/ninestores/`**.
   A `(compile-production)` that writes `/…/hhub/products/x.fasl` and reports
   *Compiled: 7, Failed: 0* changes **nothing** the running server can see.

   **How to tell which build is live** — the answer is a timestamp, not an opinion:

   ```sh
   ls -la --time-style=+%H:%M:%S \
     /home/hunchentoot/.cache/common-lisp/sbcl-2.6.8-linux-x64/home/ubuntu/ninestores/hhub/core/nst-sch-mig.fasl
   ps -eo pid,user,lstart,cmd | grep '[s]bcl'
   ```

   Compare against your edit times. **Cost a real hour on 2026-09-20:** an edit to
   `nst-sch-mig.lisp` (which holds the `*migrations*` registry) sat uncompiled for
   eight minutes, `apply-migrations` ran "successfully" and applied nothing, and
   the failure was invisible — the migration list comes from **the image**, while
   `load-upgrade-files` reads its functions from **disk**, so the two disagree
   silently.

   **The reliable fix is a restart**, and it is also the only one that clears a
   stale registry: a new process loads through ASDF, which recompiles anything whose
   source is newer. `(asdf:load-system :nstores)` reloads without a restart and
   preserves sessions, but a registry entry added to a file the image already has
   loaded still needs that file recompiled first. Note what a restart costs:
   `start-das` calls `reset-session-secret`, killing every cookie, and logins are
   capped at **2 concurrent vendors, evicted oldest-first**.

   **Verify the endpoint is really there**, rather than inferring it — an
   unauthenticated call is a safe probe, because auth rejects before any write:

   ```sh
   curl -s -o /dev/null -w '%{http_code}\n' -X PUT -H 'Content-Type: application/json' \
     -d '{"price":1}' http://127.0.0.1:4244/hhub/api/v1/catalog/products/1/pricing
   # 401 = route registered, auth refused it (correct)
   # 404 no_such_endpoint = the image predates the route
   ```

   A related symptom: **nginx answering `502`** means the acceptor is not bound at
   all. Check `ss -ltn | grep 4244` — a live `sbcl` process does not imply a live
   acceptor.

`nst-bl-prdpricing.lisp` is listed at `compile.lisp:203` and `nstores.asd:151`.
**The order was swapped on 2026-09-20: prdpricing now compiles BEFORE
`nst-bl-prdapi.lisp`**, which used to come first. The route verb added that day
calls `set-product-pricing` and signals `prdpricing-validation-error`, so prdapi
depends on prdpricing and the old order would have emitted undefined-function
warnings at every rebuild. Both files carry a comment saying so.
Its own deps (`dod-dal-prd`, `dod-bl-prd`, `adhara`, and cross-file helpers
`response-id-string` from `dod-ui-utl.lisp:913` and `get-date-string` from
`dod-bl-utl.lisp:603`) are all compiled earlier.

**Measured 2026-09-20**, reporting both directions: `nst-bl-prdapi.lisp` compiles
`failure-p=NIL`; `nst-bl-prdpricing.lisp` compiles with `failure-p=T` in isolation
solely because of three `*DOD-DATABASE-CACHING*` undefined-variable warnings (§6).
Zero `caught ERROR` in either.

---

## 8. `clsql:file-enable-sql-reader-syntax` is MANDATORY in this file

`nst-bl-prdpricing.lisp:124` (immediately after `(in-package :nstores)`, `:123`).
The same line appears at `vendor/nst-bl-vnd.lisp:33` and
`vendor/nst-bl-vndshp.lisp:155`.

Without it, the `[and [= [:product-id] product-id] …]` forms at `:300-303`,
`:317-319` and elsewhere are **reader macros**, not function calls: the reader
produces the symbol `[AND` and compilation fails. The line must appear
**textually before** the first `[...]` form.

This was a live compile failure on 2026-09-20 and **is not documented anywhere
else**, including in `nst-bl-apidefs2-CONTEXT.md`.

---

## 9. Recipe — check a file against the LIVE image (the other half of §6)

§6 compiles a file in an isolated SBCL with a hand-picked package set. That is the
right tool when the running image is unavailable or you do not want to touch it.
**This is the right tool the rest of the time**, and it is strictly more truthful: the
image already has CLSQL, every project package, and the loaded system, so a file that
loads there has genuinely compiled against the real world.

The image starts a Swank server on `127.0.0.1:4016` — `startup/init.lisp` documents the
port as *"used for remote interaction with slime"*. `aiharness/deepseek/tools/swank-eval.py`
is the same door without an editor:

```bash
cd /home/ubuntu/ninestores
python3 aiharness/deepseek/tools/swank-eval.py -f /home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp
python3 aiharness/deepseek/tools/swank-eval.py -F /tmp/probe.lisp
python3 aiharness/deepseek/tools/swank-eval.py '(fboundp (quote !settings))'
```

`-f` **loads** (so it compiles and prints warnings); `-F` **evaluates** a file's single
top-level form; a bare form argument is evaluated in `NSTORES` (`-p` changes that).

### The traps, each of which cost a cycle

1. **`-f` and `-F` are NOT interchangeable, and CLSQL is why.** `load` compiles, so
   `clsql:select` expands through its **compiler macro**, and
   `(clsql:select 'dod-company :where "row_id = 2" :flatp t)` dies with *"No source
   tables supplied to select statement"* — while the identical form **evaluates**
   correctly. Anything touching CLSQL belongs in a `-F` file. `-F` also sidesteps every
   layer of shell quoting, which is what makes it the right way to hand over a probe
   full of docstrings and double quotes.
2. **Absolute paths only.** The image's `*default-pathname-defaults*` is not the repo,
   so a relative `hhub/…` path fails with *"file does not exist"*.
3. **The image runs as `hunchentoot`.** A probe written to `/tmp` must be world-readable
   (`chmod 644`) or the load answers *"Permission denied"*.
4. **The handshake is mandatory.** Swank sets up `*emacs-connection*` and its control
   thread on `connection-info`; a request sent before it is queued and **never
   answered**, which is indistinguishable from a hang. The `indentation-update` that
   follows is a few hundred KB and must be drained before anything else.
5. **The form must travel as a STRING** — `(swank:eval-and-grab-output "…")`. `emacs-rex`
   is read inside `SWANK-IO-PACKAGE`, so a bare form's `*package*` resolves to
   `SWANK-IO-PACKAGE::*PACKAGE*`, which is **unbound**, and the request lands in the
   debugger instead of evaluating.
6. **An errored request answers `(:debug …)`, not `(:return …)`.** Waiting for a
   `:return` that will never come is the second way this looks like a hang; the client
   detects `:debug` and aborts to top level.

All six are implemented and commented in the tool's own header.

### The rule that matters more than any of them

**A probe that writes to the database must restore in an `unwind-protect` whose cleanup
cannot itself fail — and it must restore THROUGH THE VERB, never by building SQL by
hand.**

Measured, 2026-09-25: a probe wrote a test blob to `DOD_VEND_PROFILE.INVOICE_SETTINGS`
for vendor 1 and restored it with

```lisp
(format nil "UPDATE DOD_VEND_PROFILE SET INVOICE_SETTINGS = ~A WHERE ROW_ID = 1"
        (sql-literal original))
```

`sql-literal` does **not** quote its argument — it escaped nothing and added no quotes,
so the statement embedded a raw 4,101-character Lisp alist and MySQL answered
`Error 1064`. The failure then happened *inside the cleanup*, so nothing restored the
row: the test value stayed. Vendor 1 was the only customised row in the table (all 14
others hold the migration seed), so there was no sibling to copy from and the original
had to be reconstructed from the image's own error echo of the failed statement.

Two lessons:
- `sql-literal` is for values whose quoting the migration author has already verified;
  do not assume it wraps a string in quotes.
- Restoring through the domain verb (whose string path stores verbatim) makes the
  cleanup as safe as the code under test. A hand-built statement is a second
  implementation with its own bugs, written at the moment you are least able to check it.

---
