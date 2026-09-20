# SKILLS-MAINTENANCE — how the skill corpus is written and kept

**Read this when:** you are writing a new skill, updating an existing one, deciding
whether a file should be retired, or wondering why a context file is a particular
size. This file is the *method*; `../README.md` is the *index*.

**Verified:** 2026-09-20.

---

## Convention

- **Location:** `aiharness/deepseek/skills/`
- **Naming:** `<topic>-CONTEXT.md` for a cross-cutting mechanism, or
  `<source-file>-CONTEXT.md` when the skill is about one file.
- **Every skill must state:** what it covers, **when to use it**, the mechanism, a
  step-by-step recipe, the traps, and **the file map with line references** so a
  future session can jump straight to the source.
- **🚨 Every skill opens with a `Read this when:` line, and it is a SYMPTOM, not a
  topic.** One line, near the top, naming the situation that should make a reader
  open the file — *"a change compiled but did not take effect"*, not *"covers the
  build harness"*. This is the whole retrieval index: it is what the symptom table
  above points at, it costs one line, and unlike a separate keyword map it cannot
  drift from the content it describes. A skill without one is not finished.
- **Date every verified claim.** Line numbers and "current state" sections rot. Say
  when it was checked, and prefer "measured on <date>" over "is".
- **Separate what is enforced from what merely exists.** A row in a table, a
  registered route, or a declared slot is not proof the thing runs. If something is
  seeded but not wired, say so explicitly.


## Adding a skill

1. Write the file here, following the convention above.
2. Add a row to the index, with a **verified** date.
3. If the new skill makes an existing one wrong, record it under **Known staleness**
   (see that section's rule) rather than editing the older snapshot in place.
4. Cite real line numbers, and re-check them when you touch the file next — a stale
   line reference is worse than none, because it reads as verified.

---


## Keeping a skill current

### The 10-interaction rule

**After every 10 chat interactions, update the skill file(s) relevant to that chat —
during the chat, not afterwards.** One interaction is one user message and the
agent's response. Do not defer to a later cleanup pass: the session is where the
evidence is, and a deferred write is how a trap that cost an hour gets rediscovered
next week.

- **Write what was learned, not what happened.** A verified fact with its date, a trap
  and the symptom that identifies it, a correction to a claim already in the file, a
  decision and the reason behind it. Not a transcript.
- **Correct in place; do not accumulate.** A claim that is now wrong is fixed in the
  file that makes it. Appending a later paragraph that contradicts the first leaves
  the reader to work out which one wins.
- **A genuinely new mechanism gets its own file** rather than a new chapter bolted
  onto an unrelated one.

### The size budget — amortized

**`README.md` is capped as `180 + 2N` lines, where N is the number of indexed skills.**
The constants are measured, not chosen: the fixed prose is ~180 lines, and each skill
costs ~2 lines (one index row, ~one symptom row). At N=16 that is 212.

**A skill file is capped at 400 lines** — 600 intraday, back to 400 at the daily
commit (23:00). The two numbers do different jobs: 600 is a safety ceiling for one
working day, 400 is the size a file should be *read* at. Over 400 intraday is normal;
over 600 is a defect — consolidate early rather than defer.

**Why the batch.** Consolidating means reading a file whole and rewriting it, the
expensive half of the work. Once a day, with the day's material in hand, it costs far
less than after every append *and* gives a better result: duplicates and superseded
claims are only visible when you can see the whole day together.

**Why 600 is affordable.** A 344-line skill measured ≈4,900 tokens on 2026-09-20, so
600 lines is roughly 8,500–10,000 — and these files are read *on demand*, so the
headroom costs nothing until the file is relevant. That is why `README.md`, read to
*find* the others, gets no allowance.

The budget is in **lines, not words**: a 40-line table and 40 lines of prose cost about
the same to read but wildly different word counts. Lines are also the unit the one
published benchmark uses — [vLLM's agent-instruction
guide](https://docs.vllm.ai/en/latest/contributing/editing-agent-instructions/) puts an
always-loaded file under 200 and a domain guide under 300, and Claude Code's memory
docs land on the same 200. What they are *for* is [context
rot](https://research.trychroma.com/context-rot) — measured degradation as input grows,
even on trivial tasks — and the U-shaped recall of [Lost in the
Middle](https://aclanthology.org/2024.tacl-1.9/), where a document's middle is read
worst. A file's traps are exactly what ends up in the middle.

### Rules of the daily cycle

1. **APPEND IMMEDIATELY; CONSOLIDATE ONCE A DAY.** Appending as evidence arrives is
   cheap and the session is where it is fresh; consolidation is expensive and batched.
2. **🚨 A CORRECTION IS EXEMPT FROM THE BATCH — fix it when you find it.** A claim
   that is now *wrong* is not a size question. A file saying "never run" when it ran at
   11:19 is worse than no file. Size waits for the commit; being correct does not.
3. **THE DAILY PASS MERGES; IT DOES NOT MERELY DELETE.** Cutting detail to get under
   400 destroys the thing the file is for. Merge near-duplicates, retire superseded
   claims, replace restatement with a pointer. A day of pure appends *guarantees*
   duplication unless this pass reconciles it.
4. **SPLIT BY MECHANISM, NOT BY SIZE.** Move a self-contained part into a new skill,
   add an index row, leave a pointer. A split at an arbitrary line boundary produces
   two files that must both be read to understand either.
5. **Do not compress prose to fit a number.** Cut *scope*, not detail. Deleting
   duplication between two files is not compression.

Gate, before the 23:00 commit — worth wiring to a `pre-commit` hook:

```sh
cd aiharness/deepseek/skills && wc -l *.md knowledge/*.md | sort -n   # skills <= 400; README <= 180+2N
```

---

## Retiring a skill (the cyclic buffer's shrink step)

**A buffer file is retired when its feature has shipped and stabilised AND its
*learnable* content has been folded into `knowledge/`.** Retiring is a two-part
move, and the first part is the point of the whole cycle:

1. **Extract, do not copy.** Whatever the feature taught that is true of the
   *system* — a mechanism, a trap, a convention — belongs in the owning
   `knowledge/` file, merged into what is already there. If it is already there,
   add nothing. A buffer file that is retired without this step has thrown away the
   only durable thing it produced.
2. **`git mv <file> archive/` and drop its index row.** Not `rm`. The index row is
   the actual context cost; an archived file is never read unless opened.

**🚨 THE GATE — run it before every retirement.** A file may be cited by **path**
from `.lisp` headers, migrations and `STATUS.md`. Deleting one breaks those:

```sh
cd /home/ubuntu/ninestores
grep -rl "<FILENAME>" --include=*.lisp --include=*.asd --include=*.sh --include=*.md \
     hhub/ installation/ aiharness/deepseek/skills/
```

Any hit means: keep the file, or repoint the citation first. **Do not trust inbound
citations from inside this directory alone** — `nst-bl-conflodis2-DESIGN.md` has
zero of those and four source files point at it by path.
