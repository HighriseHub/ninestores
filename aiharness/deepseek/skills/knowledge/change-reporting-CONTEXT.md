# SKILL: "Changed this turn" — the end-of-turn file report (Nine Stores / hhub)

**THE RULE, and it is an instruction to the agent, not knowledge about the code.**

> **Whenever a turn MODIFIES, CREATES or DELETES any file, the final message MUST end with a
> `Changed this turn:` section listing every file touched in THAT turn — one line each, the exact path
> and what changed in it. A turn that modifies nothing says so in one line instead.**

Requested by the owner on 2026-10-11, after a long session in which edits, tool repairs and documentation
were interleaved and the human had to reconstruct what had actually been written from the prose.

---

## 1. Why it exists

An agent's summary and its diff are different artefacts, and only one of them is the truth about what is now
on disk. In a single session this cost real time more than once: a fix was described as applied while a
second, contradictory edit sat in the same function; a tool was "fixed" in one place while a stale
expectation kept it red; documentation was appended to a knowledge file and never registered in the router,
so a later session could not find it. The footer makes the diff auditable at a glance, and it is the list
the human actually pastes into a commit message.

## 2. The format

End the message with, verbatim as a heading:

```
Changed this turn:
- `hhub/core/dod-bl-utl.lisp` — added `nst-line-money`, the one tax/rounding function.
- `aiharness/deepseek/tools/nst-verify-invoice-from-order.lisp` — fixture re-pointed + premise guard.
- `aiharness/deepseek/skills/README.md` — router row and durable-table row registered.
```

Rules that make it useful rather than decorative:

1. **Exact paths, in backticks**, so they are clickable in the GUI and greppable in a terminal.
2. **One line per file, saying WHAT changed** — never a bare list of names, and never a whole diff.
3. **Only the files changed in THIS turn.** Not the session, not the branch, not "also earlier I touched…".
   If a file was edited earlier and not now, it does not belong here.
4. **Deleted and renamed files are listed too**, marked as such — an absence is the easiest edit to miss.
5. **Newly created files are listed with the reason they exist**, because a file no one knows about is the
   same as no file.
6. If verification ran, the numbers already belong in the body of the message; do not re-list them here.
7. **A turn that only reads, greps, compiles or runs things modifies nothing** → write
   `Changed this turn: nothing (read-only: <what was measured>)`. Saying nothing at all is the failure mode
   this skill exists to remove, because "no footer" then means either "no changes" or "forgot".

## 3. What it is NOT

* Not a substitute for the honest summary of a change's RISK (a behaviour change, an untouched fixture, an
  unverified path still must be said in the body).
* Not a place for files a tool wrote as a side effect of a build (`*.fasl`, `/tmp` probes, ASDF caches) —
  those are not source changes. If a probe or temporary file was created and matters, name it in the body.
* Not optional because the turn's changes were small: the one-line fix is exactly the kind that goes
  unnoticed.
