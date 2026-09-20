# `knowledge-conjoin` and the `t` trap · CONTEXT

**Split out of `nst-bl-prdapi-CONTEXT.md` on 2026-09-20** for the 400-line budget.
Section numbers are preserved from the parent. **Content is unchanged.**

**Covers:** `knowledge-conjoin` — the truth-order MEET (⊓t) for composing a SEQUENCE of
steps, and why it is not `bo-merge` (§18) — and the `t` trap, the reason a compile report
saying `Failed: 0` cannot be read as success (§19).

**Read this when:** you are building a compound verb (`order→invoice`), or you have just
seen a compilation report success while the code was broken.

**Related:** `belnap-four-states-CONTEXT.md`; `nst-bl-vndapi-CONTEXT.md` §9 restates the
`t` trap for the vendor work.

## 18. `knowledge-conjoin` — composing a SEQUENCE of steps (core, 2026-09-13)

Closes open item #1. **Not yet compiled or loaded** at the time of writing — run
`(asdf:load-system :nstores)` and then the probe below.

### 18.1 Why it is not `bo-merge`

`bo-merge`/`knowledge-join` is the **information-order join (⊔i)**: *more information wins*.

```
(T,T)=T   (T,F)=C   (T,U)=T   (T,C)=C
(F,F)=F   (F,U)=F   (U,U)=U   (·,C)=C
```

That is **correct for gathering evidence**: a source saying T out-ranks one saying nothing.

It is **wrong for sequencing**. A compound verb asks "did ALL of this happen?", and under ⊔i an
unknowable step is silently absorbed — `(T,U)=T` **reports success for an action with a step we
could not determine**. A false success is the most dangerous answer this architecture can give.

> **⊔i gathers evidence; conjoin composes steps.**

### 18.2 The rules

| steps | verdict | meaning |
|---|---|---|
| all `:T` | `:T` | the action completed |
| all `:F` | `:F` | definitively nothing happened — **and only then**, because `:F` is what tells a caller "safe to retry" |
| any `:C` | `:C` | a step is in contradiction; a human must look |
| some `:T` **and** some `:F` | `:C` | **PARTIAL APPLICATION** — step 1 says "completed", step 2 says "did not"; we were told both, which is exactly Belnap `:C`. Deliberately NOT `:F`: reporting failure would invite a blind retry that re-applies what DID commit |
| otherwise (any `:U`) | `:U` | a step is unknowable, so no outcome can be stated — also not `:F`, for the same retry reason |

### 18.3 Order-independence, and why it is N-ARY

These rules are a function of the **set** of step outcomes, not their order. The natural
**pairwise** version is NOT associative — `(T,U)→U` erases the fact that a `T` was seen, so a
later `F` can no longer detect the partial application:

```
((T,U),F) = (U,F) = U        but the set {T,U,F} is :C
((T,F),U) = (C,U) = C        while ((T,U),F) = U   — the same three steps!
```

A fold-left would therefore give **different verdicts for the same three step outcomes depending
on order**. Conjoin is deliberately n-ary, there is **no pairwise entry point to misuse**, and
`bo-conjoin*` does not fold — it reads the whole list at once.

### 18.4 Verified (design table checked exhaustively, 4³ combinations)

```
order-independence violations: 0
P1  :T only if all :T            0 violations
P2  :F only if all :F            0 violations
P3  :U never masked by T/F       0 violations
P4  :C never masked              0 violations
```

Contrast with `bo-merge`, on the cases that matter:

| steps | bo-merge | conjoin | |
|---|---|---|---|
| `T,U` | **T** | U | merge reports success for an unknown step |
| `F,U` | **F** | U | merge says "nothing happened" when it might have |
| `T,T,U` | **T** | U | |
| `F,F,U` | **F** | U | |
| `T,F` | C | C | agree — partial application |

### 18.5 New API

```lisp
;; core/nst-bl-beltrusys.lisp
*knowledge-truths*            ; the four valid truths; conjoin VALIDATES against it
(knowledge-conjoin truths)    ; (list of :T/:F/:U/:C) → one verdict   [n-ary]
(bo-conjoin  klist)           ; list of bo-knowledge → one bo-knowledge
(bo-conjoin* &rest klist)     ; convenience; NOT a fold

;; core/nst-bl-adhara.lisp §5b — the bridge that makes it usable from a verb
(domain-result-truth result)  ; entity|sentinel|list|T → :T/:F/:U/:C
```

`domain-result-truth` is the missing half: a प्रत्यय answers with an **entity or sentinel**, never
a `bo-knowledge`, so without it `bo-conjoin` is only reachable from code calling the CRUD macros
directly — which is not where compound verbs live.

`bo-conjoin` merges **provenance as a union**, which is the point: a compound verdict must be able
to name every step that produced it. The payload is the **decisive** step's — the first whose
truth equals the verdict, or, for a partial application (where `:C` appears in no single step),
the first `:F`, because that is the step that stopped the sequence.

Two documented warts:

* **`nil` is ambiguous in CL** (`nil` IS the empty list), so `domain-result-truth` cannot tell a
  bare-`nil` verb result from an empty collection. It reads `nil` as `:F`, which means an **empty
  `enumerate` composed into a compound verb reads as `:F`**. Inherent to the language, and one more
  reason the verb contract should require explicit sentinels (§15.4).
* An **empty step list signals** rather than answering `:T` — a vacuously-true verdict would let a
  mis-built step list masquerade as success (same discipline as `:hydrate` having no default).

### 18.6 A compound verb, then, looks like this

```lisp
(defun route-order-to-invoice (request ctx)
  (let* ((order   (make 'nst-ord ctx …))          ; each step answers with a result
         (invoice (make 'nst-inv ctx …))
         (verdict (bo-conjoin* (make-bo-knowledge :truth (domain-result-truth order)
                                                  :payload order :provenance "nst-ord/make")
                               (make-bo-knowledge :truth (domain-result-truth invoice)
                                                  :payload invoice :provenance "nst-inv/make"))))
    ;; verdict :T → the invoice entity;  :C → a contradiction the client must not
    ;; blind-retry;  :U → 503;  :F → 404.  Provenance names BOTH steps.
    (case (bo-knowledge-truth verdict)
      (:T (bo-knowledge-payload verdict))
      (otherwise (domain-sentinel-from-knowledge verdict ctx :reason "order->invoice")))))
```

---

## 19. THE `t` TRAP, and why "Failed: 0" cannot be trusted (2026-09-13, 20:xx)

### 19.1 The bug I introduced

`knowledge-conjoin` (§18) was written with five occurrences of:

```lisp
(every (lambda (t) (eq t +true+)) truths)      ; ← WRONG
```

**`t` is `COMMON-LISP:T`, a defined constant, and Common Lisp forbids it as a variable
name.** SBCL reports it as a compile ERROR:

```
;   COMMON-LISP:T names a defined constant, and cannot be used in an ordinary lambda list.
```

Renamed to `tr`. Also found the same illegal pattern **pre-existing** in
`customer/wallets/nst-bl-custwallets.lisp:694`, inside `get-spending-trends` — a latent
landmine in the wallet analytics path (see §19.3).

### 19.2 How it hid, and why this is the important part

This is not a story about a typo. Three things conspired to make a broken function look
shipped:

1. **SBCL writes the fasl ANYWAY.** Verified: `compile-file` signals the error, and a fasl
   is still produced. The definition is compiled into a **stub that raises when called**:
   ```
   Unhandled SB-INT:COMPILED-PROGRAM-ERROR
     Execution of a form compiled with errors.
   ```
   So the failure surfaces at *runtime*, as far from the typo as possible.
2. **The build script counted it as a success.** `package/compile.lisp` reported
   `Total Files: 122   Failed: 0` — and its log contains **zero** occurrences of SBCL's own
   `caught ERROR` text (`grep -c caught` = 0). It logs only `[WARNING]`/`[STYLE-WARNING]`/
   `[NOTE]`, so SBCL's error reporting never reaches the log. **"Failed: 0" means "the
   script saw no failure it recognises", not "the file compiled".**
3. **The build DELETES the old fasl before compiling** (`Deleting old .fasl: …`). A failed
   compile therefore replaces a working fasl with a broken one — strictly worse than leaving
   the stale one in place, and invisible if you only check that the fasl exists.

**Consequence for every verification claim in this file:** "it compiled" was never evidence.
The two compile logs earlier today (§ header, and the 19:33/20:00 runs) prove only that the
script did not *notice* a failure. The checks that do mean something are: the structural
parse, SBCL's raw output, and **calling the code**.

Suggested build hardening (not done):
* treat SBCL's `caught ERROR` / `caught N fatal ERROR conditions` as a FAILURE;
* report the raw compiler output, not a filtered summary;
* compile to a temp file and move it into place only on success, so a failed compile cannot
  destroy a good fasl.

### 19.3 VERIFIED — conjoin compiled AND CALLED

This time the code was not merely parsed: it was compiled and **executed** under a stub
environment (plain SBCL, no Quicklisp). **25 assertions, all passing.**

```
truth table (n-ary, order-independent)
  T=>T  T,T=>T  F=>F  F,F=>F  U=>U  C=>C
  T,F=>C   T,F,F=>C   T,U=>U   F,U=>U   T,F,U=>C   T,T,U=>U   F,F,U=>U
  T,C=>C   U,C=>C

bo-conjoin
  T+U verdict => U                      provenance union => (step/order step/invoice)
  decisive payload (:U step)            timestamp = max
  T+F = partial application => C         decisive payload = the FAILING step
  order-independence {T,U,F} => C

guards
  empty truth list signals · unrecognized truth signals · empty klist signals
```

The `bo-conjoin` behaviour that matters most is confirmed live: **`T + U` yields `:U`, not
`:T`** — the false success that `bo-merge` would have produced (§18.1) — and a partial
application yields `:C` with the failing step's payload.
