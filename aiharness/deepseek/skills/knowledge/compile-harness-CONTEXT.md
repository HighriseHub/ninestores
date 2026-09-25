# The compile driver (`package/compile.lisp`) — policy, conventions, traps · CONTEXT

**Read this when:** you are about to change `package/compile.lisp`, add a file to the
build, or a `(compile-production)` run reports **`Compiled: 0` / `Success Rate: 0.0%`**
and you cannot tell whether that is a healthy no-op or a broken build.

**Verified:** 2026-09-25, against `hhub/package/compile.lisp` **559 lines, HEAD
`05b855c`** (*"build: an up-to-date file is now LOADED, not silently skipped"*). The
driver was edited twice during the session that wrote this file, so **re-check any
line number here before acting on it** — the anchors below are exact at the commit
named, and that commit is the thing to quote if they disagree.

**Scope.** This file is the *design authority* for the driver: the incremental policy,
the entry points, how to read a run, and the conventions for changing the build.

**Not here:** *"it compiled but the server still runs the old code."* That is a
different symptom and it lives in
**[`build-and-load-CONTEXT.md`](build-and-load-CONTEXT.md) §7** — `compile.lisp`
writes `.fasl` files *beside the sources*, while the running server loads from the
ASDF cache under `/home/hunchentoot/.cache/common-lisp/`. **Compiling successfully
and changing what the server serves are different claims.**

---

## 1. The policy — incremental by default, full rebuild only on request

| Call | Deletes `.fasl` | Compiles | Loads |
|---|---|---|---|
| `(compile-production)` | no | **only changed files** | every file on the list |
| `(compile-debug)` | no | **only changed files** | every file on the list |
| `(clean-and-compile)` | **all 133** | **all 133** | all 133 |
| `(compile-hhub-files :clean t)` | identical to `clean-and-compile` | | |

**The default is incremental.** There is no `:incremental` flag, and none is needed:
`clean-and-compile` (`:533`) is a full rebuild by *deletion*, not by a mode switch. It
calls `compile-hhub-files :clean t`, which runs `clean-hhub-fasl-files` (`:497`) before
the loop (`:417`), so every source then fails the freshness test in §2 and is rebuilt.

That is the whole design, and it is worth stating plainly because it is easy to
"improve" wrongly: **do not add a `:force` argument.** Deletion already expresses
force, and a second mechanism would be a second thing to keep consistent.

---

## 2. The freshness rule

`compile-single-file` (`:293`) opens with the gate at **`:318–326`**:

```lisp
(when (and (probe-file fasl-path)
           (probe-file fullpath)
           (> (file-write-date fasl-path) (file-write-date fullpath)))
  (log-message "INFO" "Up to date, loading without recompiling: ~A" file)
  (load fasl-path)
  (incf (compilation-stats-skipped stats))
  (return-from compile-single-file t))
```

Four properties, each deliberate:

- **`>` is strict.** Equal timestamps rebuild. A filesystem with coarse timestamp
  granularity must fail towards compiling, never towards skipping.
- **A skipped file is still LOADED.** Skip means *"do not recompile"*, not *"do not
  touch"*. Without the `load`, a fresh SBCL plus a warm `.fasl` tree would compile
  nothing **and** load nothing, and every symbol would be missing. Commit `05b855c`
  is exactly that correction.
- **The count lands in `compilation-stats-skipped`** — a slot that existed from the
  start (`:28`) and was dead (always 0) until the gate was added.
- **The gate returns `t`**, so a skipped file is not counted as compiled or failed.

---

## 3. Reading a run (and the success-rate trap)

`compile-hhub-files` **returns zero values on purpose** (`:438`):

```lisp
(setf *last-compilation-stats* stats)
(values))
```

The REPL prints the primary value, so returning the struct echoed a raw
`#S(COMPILATION-STATS …)` onto the console after every build. `(values stats)` does
**not** fix this — one value is still the primary value. **Only zero values are
silent.** Inspect the last run through the variable instead:

```lisp
(compilation-stats-compiled *last-compilation-stats*)
(compilation-stats-skipped  *last-compilation-stats*)
```

🚨 **The summary under-reports a healthy run.** `print-compilation-summary` (`:441`)
never prints `Skipped`, and computes

```lisp
(success-rate (* 100 (/ (compilation-stats-compiled stats)   ; :446
                        (float (compilation-stats-total-files stats)))))
```

so an all-fresh run prints **`Compiled: 0` … `Success Rate: 0.0%`**. That reads as
catastrophe and is the *normal, correct* result of an incremental build that had
nothing to do. The invariant that distinguishes the two:

```
compiled + skipped + failed = total-files        (total-files = 133 today)
```

`0 + 133 + 0 = 133` → healthy no-op. `0 + 0 + 133` → the build is broken.
**Read `skipped`, not `Success Rate`.** This is the same class of lie as the
`Failed: 0` trap in [`knowledge-conjoin-CONTEXT.md`](knowledge-conjoin-CONTEXT.md).

---

## 4. Conventions when you change the build

1. **A new file goes in TWO places, and they are not generated from each other:**
   `get-hhub-file-list` (`:111`, list body `:111–290`) *and* `hhub/nstores.asd`
   (`:49–50` carries `package/packages`, `package/compile`). Shipping in one and not
   the other is the easiest way to get a file the server never sees.
2. **Order is load order.** `nstores.asd` is `:serial t` and the driver walks the list
   front to back, so a file must appear **after everything it calls**. A file listed
   too early compiles — with undefined-function style-warnings — and then fails at
   load time. When you reorder, leave the one-line comment saying why, as the
   `dal → bl → ui` and `prdpricing-before-prdapi` entries do.
3. **`compile.lisp` is not in its own list**, so `clean-and-compile` can never
   rebuild the driver; a stale `compile-hhub-files` keeps running in the image until
   you `C-c C-k` the buffer. See `build-and-load-CONTEXT.md` §7.1.
4. **Three entry points, and only three** — `compile-debug` (`:523`),
   `compile-production` (`:528`), `clean-and-compile` (`:533`). Call
   `compile-hhub-files` directly only for batch builds.
5. **`optimize-code` is a session-wide, irreversible change.** Non-nil reaches
   `(proclaim (get-optimization-settings *compilation-mode*))` (`:346`). `proclaim` is
   **global and cannot be undone** — it silently re-optimizes every later compilation
   in the SLIME session. Leave it `nil` interactively; it exists for batch builds.
6. **`*hhub-root*` is absolute** (`:13`, `/home/ubuntu/ninestores/hhub/`). The driver
   cannot build another checkout without rebinding it.
7. **Logs:** one timestamped file per run under `hhub/logs/` (`:16`), every line also
   echoed to the console. A build's evidence outlives the scrollback — read the log.

---

## 5. Traps (measured, 2026-09-25 unless dated otherwise)

1. **`clean-hhub-fasl-files` cannot clean the ASDF cache.** It iterates the same
   133-file list (`:504–506`) and so touches only the project-local `.fasl` files.
   A "clean build" therefore leaves the ASDF cache — the tree the server actually
   loads from — entirely untouched.
2. **The gate is mode-agnostic, so `:mode` does not invalidate anything.** A `.fasl`
   carries the optimization settings of whenever it was built. `(compile-debug)` right
   after a production build skips **all 133** files and keeps serving
   speed-3/safety-1 code. Switching modes requires
   `(clean-and-compile :mode :debug)`. A per-mode output directory is the real fix;
   it does not exist.
3. **An old `.fasl` is deleted BEFORE the compile that replaces it** (`:328–331`
   delete, `:348` `compile-file`). If that compile fails, the file is left with **no
   `.fasl` at all** — the *next* run rebuilds it, but anything loading from disk in
   between finds nothing. The `handler-case` records the failure and moves on.
4. **A no-op build still loads 133 files.** Skip means load (§2), so the floor cost of
   `(compile-production)` is load time, not zero. Do not read a fast run as "nothing
   happened".
5. **On this tree, right now, a bare `(compile-production)` compiles nothing.**
   Measured 2026-09-25 across all 133 files: **133 fresh, 0 stale, 0 missing** — every
   source is older than its own `.fasl`. Source mtimes span **2026-06-02 23:24 ..
   2026-09-24 08:09**; the `.fasl` files span **2026-09-20 10:25 .. 2026-09-24 21:45**.
   (An earlier draft of this file generalised those ranges from a three-file sample
   and got them wrong. Measure the whole list, not a sample.)
6. **`skipped` is invisible in the summary** (§3) — the only trap here that makes a
   correct build *look* wrong.

---

## 6. Recipe — check the tree's incremental state WITHOUT compiling

Read-only: loads the driver's *definitions* (no side effects at load time — no
compilation, no `.fasl` writes) and evaluates the gate's predicate over the list.

```bash
cd /home/ubuntu/ninestores && sbcl --non-interactive \
  --eval '(load "hhub/package/compile.lisp")' \
  --eval '(let ((fresh 0) (stale 0) (nofasl 0))
            (dolist (f (get-hhub-file-list))
              (let* ((p (concatenate (quote string) *hhub-root* f))
                     (fas (compile-file-pathname p)))
                (cond ((not (probe-file fas)) (incf nofasl))
                      ((> (file-write-date fas) (file-write-date p)) (incf fresh))
                      (t (incf stale)))))
            (format t "~&TOTAL=~D SKIP=~D REBUILD=~D NO-FASL=~D~%"
                    (+ fresh stale nofasl) fresh stale nofasl))'
```

Measured output, 2026-09-25: `TOTAL=133 SKIP=133 REBUILD=0 NO-FASL=0`.

- Expect two `STYLE-WARNING`s while loading (`CLEAN-HHUB-FASL-FILES`,
  `PRINT-COMPILATION-SUMMARY` reported as undefined functions) — the file is loaded
  out of dependency order. Harmless here; it is *not* a signal about your change.
  (Same lesson as `build-and-load-CONTEXT.md` §6: **read the condition list, not the
  flag.**)
- `NO-FASL > 0` after a build means trap 3 fired — a file lost its `.fasl` to a failed
  compile.
- This answers *"what would a build do?"* without a build. Use it before a
  `clean-and-compile` on the live tree.

---

## 7. File map — `hhub/package/compile.lisp` @ 559 lines, HEAD `05b855c`

| Line | What |
|---|---|
| `:13` | `*hhub-root*` — absolute; the driver builds only this checkout |
| `:16` | `*hhub-log-dir*` — `hhub/logs/` |
| `:23–34` | `compilation-stats` struct; `skipped` at `:28` |
| `:36–40` | `*last-compilation-stats*` — **how you read a run** (§3) |
| `:43–49` | `get-optimization-settings` — `:debug` / `:production` |
| `:61–74` | `log-message` — console + log file |
| `:80–102` | warning / style-warning / compiler-note handlers |
| `:111–290` | **`get-hhub-file-list`** — the 133-file ordered build list |
| `:293` | `compile-single-file` — one file, fresh or not |
| `:318–326` | **the incremental gate** (§2) |
| `:328–331` | delete old `.fasl` — *before* the compile (trap 3) |
| `:346` | `proclaim` — global optimization, irreversible |
| `:348` | `compile-file` |
| `:356` | `load` on the compile path |
| `:383` | `compile-hhub-files` — `:mode`, `:clean`, `:optimize-code` |
| `:417` | `clean-hhub-fasl-files` call when `:clean t` |
| `:438` | `(values)` — the zero-value return (§3) |
| `:441–494` | `print-compilation-summary` — omits `Skipped`; `success-rate` at `:446` |
| `:497–520` | `clean-hhub-fasl-files` — 133-file list only (trap 1) |
| `:523` / `:528` / `:533` | `compile-debug` / `compile-production` / `clean-and-compile` |
| `:537–556` | usage notes in comments — `optimize-code` is batch-only |

Companion file: **`hhub/nstores.asd`** (`:49–50`) — `package/packages` then
`package/compile`, `:serial t`. Keep it in step with `get-hhub-file-list` (§4.1).
