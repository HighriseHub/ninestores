# adhara verb results — the three shape traps that fail only at run time

**Read this when:** you are consuming the result of a domain verb (`fetch`, `enumerate`,
`make`), writing a guard on it, or debugging a `NO-APPLICABLE-METHOD` /
`UNBOUND-SLOT` / "a page rendered nothing" fault that the compiler was happy with.

**Verified:** 2026-10-13 on the live image, against the `nst-cinv` migration
(`invoice/nst-{dal,bl,ui}-cusinv.lisp`). All three faults below were hit for real in
one afternoon; none was caught by a compile, and none by a test of the code *around*
the fault.

---

## 1. 🚨 `(typep x 'nst-domain-entity)` IS TRUE FOR SUCCESS **AND** FOR EVERY FAILURE

This is the trap. It has been written by mistake **twice**, in the same file, with
**opposite symptoms** — which is why fixing one did not fix the other.

`nst-entity-nil`, `nst-entity-unknown` and `nst-entity-contradiction` all subclass
`nst-domain-entity` — **and so does every real domain entity**. So the predicate
distinguishes nothing:

```lisp
(typep (make-instance 'nst-cinv ...)     'nst-domain-entity)  ; => T
(typep (make-instance 'nst-entity-nil …) 'nst-domain-entity)  ; => T
```

It *reads* like "is this a domain value", which is why it keeps being reached for. The
question actually being asked is **"is this THE entity I asked for"**.

### The two incidents

| | incident 1 — the ITC summary | incident 2 — the details page |
|---|---|---|
| code | `(if (typep summary-entity 'nst-domain-entity) nil (domain->response summary-entity ctx))` | `(when (typep header 'nst-domain-entity) header)` |
| effect | **inverted**: success took the failure branch, so `summary` became NIL | success took the failure branch, so a real entity was treated as a sentinel |
| symptom | the card rendered `—` for all four figures — **no error at all** | `NO-APPLICABLE-METHOD` on `ENTITY-REASON` |
| reported as | nothing (found by review) | a 500 in the log |

### The right test

Test for the **one concrete type** that means success:

```lisp
(typep value 'nst-cinv)          ; entities are nst-cinv; sentinels are not
```

`nst-cinv` and the sentinel classes are **siblings** — `nst-cinv` does not inherit from
them — so the test is exact. `invoice/nst-bl-cusinv.lisp` names it:

```lisp
(defun cinv-invoice-found-p (value) (typep value 'nst-cinv))
```

⚠ **The exception, and it is not a pattern to copy:** in the *register* model the test
`(when (typep rows 'nst-domain-entity) rows)` is **correct**, because there `rows` is a
**list-or-sentinel** and a list is not an entity — so it picks out the sentinel exactly.
Same text, opposite correctness, decided by whether the value can be a single entity.
The register model carries a comment saying so.

### Why `entity-reason` makes incident 2 fatal

`entity-reason` is defined **only on the three sentinel classes**. Handing it a real
entity is not a wrong answer, it is a missing method. Anywhere you are about to call
`entity-reason`, you are asserting "this is a sentinel" — assert it with a predicate
that can tell.

```
MISSING-SLOT          -> you passed a boundary/response model where an entity is wanted
NO-APPLICABLE-METHOD  -> you passed an entity where a sentinel is wanted (or vice versa)
```

---

## 2. 🚨 A VERB'S HYDRATOR MUST MATCH THE VERB'S ARITY

`fetch` returns **one** कर्म; `enumerate` returns **a list**. Both hydrate a DB row into a
domain entity, and it is very easy to reach for the list builder in both — which is what
happened:

```lisp
;; fetch, WRONG — make-cinv-entity-list's mapcar always answers a LIST
:hydrate (lambda (dbobj) (make-cinv-entity-list (list dbobj) tenant-id))   ; => (#<NST-CINV>)
```

The verb then answered a **one-element list** where a single entity was promised. Three
symptoms, one cause, and only the first was noticed:

1. `(vendor-id header)` on the details page → `NO-APPLICABLE-METHOD` — the trace reads
   `:ARGS ((#<NST-CINV>))`, **a list inside the args list**, which is how you recognise it;
2. the PDF download's `(typep header 'nst-cinv)` guard was **false**, so every download
   answered 404 *"This invoice is not available."* — a plausible message for a feature
   that never worked;
3. the API's `GET …/{id}` returned **a JSON array of one object** with status 200,
   because `action->response` maps a list. A client reading `resp.invoiceNumber` gets
   `undefined`, and nothing anywhere reports a problem.

**The fix, and the general rule:** give each shape its **own named hydrator** —
`cinv-hydrate-dbobj` (one row → one entity) beside `make-cinv-entity-list` (rows → list).
A named hydrator is *offline-testable*; an inline `lambda` inside a verb that needs a
database is not. That is the whole reason this survived two verification passes: the copy
helper was tested, the verb's **return shape** was not.

---

## 3. `domain->response` HAS NO METHOD ON `NULL`, BY DESIGN

```lisp
(domain->response nil ctx)   ; => no applicable method, ctx shown in the args
```

A NIL is not a domain fact, so there is no honest response model to build from it.
`conflodis2`'s `action->response` guards `(null domain)` for exactly this reason — but a
**UI model that calls `domain->response` directly bypasses that guard**, so the guard has
to be re-stated at the call site. The flavour of the incident: a `let*` computed
`summary-entity` as NIL on one branch and then ferried it unconditionally, so the failure
path was fine and the ordinary path was fine, and only ONE filter combination crashed.

**Rule:** never call `domain->response` on a value you have not type-tested for the type
it has a method for. A sentinel is not that type either — sentinels have their own
`domain->response` methods (in `warehouse/nst-bl-whsapi.lisp` §4, domain-generic and
documented there as misplaced), and if that file is not loaded the sentinel dies with the
same `NO-APPLICABLE-METHOD`.

---

## 4. THE FERRY'S ENUMERATE LEG DROPS EVERY QUERY ARGUMENT

```lisp
(defmethod request->dispatch ((rm nst-request-model) (verb-symbol (eql 'enumerate)) …)
  (apply #'enumerate entity-class ctx (extract-domain-initargs rm entity-class)))
```

`extract-domain-initargs` forwards **only keys the entity class declares as initargs**.
Every real filter — `:vendor-id`, `:invheadid`, `:sort-by`, `:name-like` — is a *query
argument of the verb*, not a slot, so the ferry drops all of them. The call arrives with
no filters and silently returns an unfiltered list.

**The tree's idiom, in `whsapi`, `invhapi`, `invitmapi` and `cusinv` alike:** build the
query arguments in the route verb and `apply` them:

```lisp
(apply #'enumerate 'nst-cinv ctx (cinv-api-enumerate-args (params request) buyer))
```

`apply` also sidesteps a compile-time style warning: adhara declares
`(defgeneric enumerate (entity-class ctx &key))` with **no keys named**, so a direct
keyword call cannot be checked and warns `… is not a known argument keyword`.

⚠ **A consequence worth knowing before you name an argument:** because the ferry forwards
declared initargs, an argument whose name IS a slot of the entity **can be supplied by a
client**. `nst-cinv` declares `:buyer-id` (a published view column), so a verb taking
`:buyer-id` would accept it from a request body. The verbs therefore take `:for-buyer` —
a key **no slot declares**, so `extract-domain-initargs` can never produce it and the
ferry physically cannot deliver a client's buyer. **The name is the control.**

---

## 5. HOW TO TEST THIS CLASS OF FAULT WITHOUT A DATABASE

The faults above live in code that needs a live DB, which is why they reached production.
The remedy that worked, and the recipe to copy:

* **Extract the decision into a named function and call the real classes.** A guard's
  logic is as testable offline as a copy helper: construct the sentinels and the entity
  with `make-instance` (stub `mysql-now` — `nst-domain-entity`'s `created-at` initform
  calls it) and assert the predicate's behaviour on **each** shape, including `NIL` and a
  list.
* **Prove the trap, do not describe it.** Assert that
  `(compute-applicable-methods #'entity-reason (list <a real entity>))` is **empty**, and
  that it is non-empty for each sentinel. That turns "be careful" into a failing test.
* **Assert the hydrator's SHAPE, not its contents:** `(typep r 'nst-cinv)` and
  `(not (listp r))`, plus `(listp (make-cinv-entity-list …))` for the other direction, so
  neither can be "fixed" into the other.
* **Read the file for the forbidden pattern** after stripping comments — a comment that
  *quotes* the old code (which is good documentation) otherwise false-positives. And
  prefer searching the **exact old live form** over a prefix.
* ⚠ **A fixture built by hand must bind EVERY slot.** `copy-…-dbtodomain` reads every
  column with `slot-value`, and a boundary model has no initforms, so a partial fixture
  fails `UNBOUND-SLOT` — in the fixture, not the code. Pre-bind every slot (loop over
  `sb-mop:class-slots`), which is what CLSQL hands you from a real `SELECT`.
* ⚠ **A character-counting paren checker is not trustworthy.** On
  `vendor/dod-ui-ven.lisp` it reported **5 missing** where the reader found **1 extra**.
  Use `read` in a throwaway SBCL as the arbiter: load `package/packages.lisp`, call
  `clsql:file-enable-sql-reader-syntax`, then read the file form by form to `:eof`.
  `unmatched close parenthesis` vs `end of file` is the verdict.

---

## 6. A DOMAIN CLASS AND ITS ORM VIEW CLASS SHARE ACCESSOR NAMES — SO THE COPIER USES `slot-value`

When the domain entity is named after the view's columns (`invoice-number`, `total-amount`,
`itc-amount` … — the `nst-cinv` / `nst-whs` style), the domain class and the
`clsql:def-view-class` end up declaring **the same accessor symbols**. CLOS is fine with
that: they become methods on one generic function, dispatched by class.

⚠ **Inside the `-dbtodomain` copier that is a trap, not a convenience.** An accessor call
reads correctly *whichever* class the argument is, so

```lisp
(setf (total-amount destination) (total-amount source))   ; "obviously right"
```

is correct only **by dispatch**, and reads as if both sides were the destination's slot. A
copy-paste that swaps the two arguments still compiles, still type-checks, and silently
writes the destination into itself.

**The convention the tree uses: read the SOURCE with `(slot-value source 'x)` and write the
DESTINATION through `with-slots`.** `copy-dod-v-customer-invoice-register-dbtodomain` and
`copyWarehouse-dbtodomain` both do this deliberately.

Two related rules that go with it:

* **Sets the ITC slots in dependency order** — recorded ← the ledger column, derived ← the
  lines, then effective ← `(or recorded derived)`. The order is the meaning.
* ⚠ **The copier must be FIELD-COMPLETE**, and that is assertable offline: iterate the
  domain class's direct slots and assert every one is non-NIL after a copy from a fixture
  whose every column is set. That test is what makes "a slot added to the class but not to
  the copier" impossible to ship (see §5, the add-a-column recipe).
