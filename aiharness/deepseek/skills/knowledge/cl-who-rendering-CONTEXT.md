# cl-who rendering — the traps that are silent, and the two macros that are not interchangeable

**Read this when:** you are writing or changing a renderer, a page renders **nothing** or
the wrong thing, a `<div>`'s body vanished, a nested helper's markup never appears, or a
page 500s with `The function :DIV is undefined`.

**Verified:** 2026-10-13, measured on the live image (SBCL 2.6.8 + the cl-who this tree
loads), while building the customer invoice register and details pages. Every snippet
below was executed, not reasoned about.

---

## 1. 🚨 THE TWO OUTPUT MACROS DO OPPOSITE THINGS

| macro | what it does | returns |
|---|---|---|
| `(cl-who:with-html-output (*stream* nil) …)` | **PRINTS** to the stream | a **meaningless tail** — the value of whichever `write-string` cl-who emitted last |
| `(cl-who:with-html-output-to-string (*stream* nil) …)` | **COLLECTS** | the markup, as a string |

The expansion of the first says it outright:

```lisp
(LET ((*STANDARD-OUTPUT* *STANDARD-OUTPUT*))
  (CHECK-TYPE *STANDARD-OUTPUT* STREAM)
  (MACROLET (…)
    (WRITE-STRING "<div class='c'>b</div>" *STANDARD-OUTPUT*)))
```

Measured consequences:

```lisp
(cl-who:with-html-output (*standard-output* nil) (:div :class "x" "hello"))
  ;=> "<div class='x'>hello</div>"   ; printed AND returned — this one is a coincidence
(cl-who:with-html-output (*standard-output* nil) (:div :class (f "c ~A" "x") "body"))
  ;=> ">body</div>"                  ; TRUNCATED: the last write-string only
(cl-who:with-html-output (*standard-output* nil) (:div "one") (:div "two"))
  ;=> "<div>two</div>"               ; the first form's value is discarded
```

So the printing macro's return value is an artefact of how cl-who split the markup into
`write-string` calls — it is a **prefix of the tail**, or the last sibling. A card built
with it returned `"</div></div></div>"`, and the caller's `cl-who:str` then printed that
junk onto the page while the real markup had already gone to the stream.

**Rule: a function that RETURNS markup uses `with-html-output-to-string`. A function that
PRINTS uses `with-html-output`. Decide which contract it has, and write it down.**

---

## 2. 🚨 `htm`, `str`, `fmt`, `esc` AND EVERY TAG KEYWORD ARE **MACROLET-LOCAL**

They are established by `with-html-output`/`-to-string`'s `macrolet`; they are **not**
global macros. Measured: `(macro-function 'cl-who:htm)` → **NIL**.

Two consequences, both of which bite:

* **A helper defined by `flet` or a top-level `defun` OUTSIDE the body cannot use them.**
  It compiles with an `undefined function: CL-WHO:HTM` **style warning** and then fails at
  **runtime** as a 500 the first time the page is opened. A tile helper written with
  `flet` around `cl-who:htm` did exactly this.
  **Fix:** the helper computes plain strings (that is testable too), and the tags are
  written inline in a body position. Or the helper opens its **own**
  `with-html-output-to-string` and returns a string.
* `cl-who:esc` is a local flet, not a callable function — see
  `markup-safety-CONTEXT.md`.

---

## 3. 🚨 `htm` DISCARDS THE VALUE OF A NESTED NON-TAG FORM

```lisp
(cl-who:with-html-output-to-string (*standard-output* nil) (:div (identity "<b>raw</b>")))
  ;=> "<div></div>"
(cl-who:with-html-output-to-string (*standard-output* nil) (:td (funcall (lambda () "<td>x</td>"))))
  ;=> "<td></td>"
```

A nested function's **returned** string is thrown away. Its **printed** output is not.

This is why `display-as-table`'s row callback must **print**: it is called as
`(funcall rowdisplayfunc item arguments)` inside an enclosing
`with-html-output-to-string`, and a row renderer that *returned* its `<td>`s would print
an empty table. `display-warehouse-row` prints for this reason, and so does
`display-customer-invoice-register-row` — whose `render-html` method therefore prints and
returns NIL, contradicting adhara's "render-html returns an HTML string" docstring. That
contradiction is forced, not sloppy: the two call sites have incompatible contracts.

---

## 4. ⚠ A BARE TAG INSIDE `when` IS A HARD ERROR, NOT SILENCE

```lisp
(cl-who:with-html-output-to-string (*standard-output* nil)
  (when t (:div :class "gone" "x")))
  ;=> ERROR: The function :DIV is undefined.
```

`when` is a non-tag body form, so cl-who evaluates it as Lisp and `:div` is read as a
function call. **Wrap it: `(when t (cl-who:htm (:div …)))`.**

Note the practical difference from what is often assumed: the failure is a **500**, not a
silently missing element. Either way it must be wrapped.

**Better still, for a conditional ROW:** build the row strings into a list and emit them
once — `(cl-who:str (format nil "~{~A~}" (remove nil rows)))`. That avoids the whole
question and lets a row be omitted cleanly.

`cl-who:str` inside `when` is fine — `str` is not a tag, so it just prints.

---

## 5. 🚨 ON THIS IMAGE `cl-who:str` DOES **NOT** ESCAPE. `escape-string` DOES.

This is the security-relevant one, and it contradicts the comment carried in
`warehouse/nst-ui-warehouse.lisp` ("every cell goes through cl-who:str, which
HTML-escapes").

```lisp
(cl-who:with-html-output-to-string (*standard-output* nil)
  (cl-who:str "a & b <script>alert(1)</script>"))
  ;=> "a & b <script>alert(1)</script>"          ; VERBATIM
(funcall (symbol-function 'cl-who:escape-string) "a & b <script>alert(1)</script>")
  ;=> "a &amp; b &lt;script&gt;alert(1)&lt;/script&gt;"
```

So `str` is an **output primitive, not a sanitiser**. Every cell carrying third-party free
text — a supplier's name, a product description, an address — must be escaped explicitly.

**What to use:** `cl-who:escape-string` (exported, callable, works anywhere) via a local
helper — `cinv-esc` in `nst-ui-cusinv.lisp`, `vendor-details-esc` in
`vendor/dod-ui-ven.lisp`. Both are also what makes `vendor-details-card` safe: a supplier
edits their own name and could otherwise put markup on every customer's page.

⚠ The stored-XSS finding itself is at the **WRITE** side and is still open — see
`markup-safety-CONTEXT.md`. Escaping at render is defence in depth, not the fix.

`cl-who:str` is however **exactly right** for emitting an already-rendered document (the
filled invoice template) — there it must not be escaped.

---

## 6. THE `with-html-div-*` HELPERS: TWO PROPERTIES, BOTH NON-OBVIOUS

`core/dod-ui-utl.lisp` defines `with-html-div-row`, `with-html-div-col-1/-2/-3/-8/-10/-12`
etc. as `(defmacro with-html-div-col-3 (&body body) \`(cl-who:with-html-output
(*standard-output* nil) (:div :class "col-3" ,@body)))`.

1. **They carry attributes as BODY forms.** `(with-html-div-col-3 :title "T" (:a …))`
   splices to `(:div :class "col-3" :title "T" (:a …))` — and cl-who reads the
   keyword/value pair as an attribute because that is the tag's own syntax. It looks wrong
   and is correct. It is also why they take a computed `style` but not a computed `class`.
2. **Each opens its own `with-html-output`** — the PRINTING macro. Nested inside an
   enclosing `with-html-output-to-string` it binds `*STANDARD-OUTPUT*` to the string
   stream already in force, so **a nested printing form IS captured**:

```lisp
(defun nested-printer () (cl-who:with-html-output (*standard-output* nil) (:td "CELL")))
(cl-who:with-html-output-to-string (*standard-output* nil) (:table (:tr (nested-printer))))
  ;=> "<table><tr><td>CELL</td></tr></table>"
```

That is what makes the strip menu (`cinv-itc-summary-html`) and `modal-dialog-v2` —
both printing — work inside a collecting parent.

---

## 7. RECIPE — RENDER A RENDERER OFFLINE

You can exercise real renderers with no server and no database:

```lisp
(ql:quickload '(:cl-who :clsql …))
(load "hhub/package/packages.lisp")
(load "hhub/core/dod-ui-utl.lisp")   ; the with-html-div-* macros must be REAL
(dolist (f '("hhub/core/nst-bl-adhara.lisp" …)) (load (compile-file f)))
;; construct boundary models by hand and set EVERY slot (a boundary model has no
;; initforms; a partial fixture fails UNBOUND-SLOT in the fixture, not the code)
```

* `dod-ui-utl.lisp` needs **`cl-smtp`** (and `parenscript`, `cl-ppcre`) at READ time —
  `Package CL-SMTP does not exist` reads exactly like a broken edit and is not one.
* Capture a **printing** renderer with `(with-output-to-string (*standard-output*) …)`.
  Call a **collecting** one directly.
* ⚠ A harness that sets `*invoke-debugger-hook*` and prints with `(format t …)` will
  **swallow its own error message** when the failure happens inside a
  `with-output-to-string` — the message goes into the string being collected. Print to
  `*debug-io*` instead. This cost a diagnosis cycle.
* Assert on the **rendered string**, not on internals: the tile hrefs, the `<td>` count,
  the 2-decimal money, the escaped entity, the single active strip cell. Those are the
  contracts that break.
