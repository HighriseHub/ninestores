# SKILL: Markup safety — authored HTML, excerpts, and the injected document (Nine Stores / hhub)

**STATUS 2026-10-11: the excerpt trap below is FIXED and verified; the wider finding it exposed (vendor
markup rendered raw on customer pages) is OPEN and recorded in §4.**

---

## 1. 🚨 A TRUNCATED EXCERPT OF AUTHORED MARKUP SHIPS A BROKEN DOCUMENT

**The bug, measured.** Product 75 (`Home Made Strawberry Cake`) has a **960-character description that holds
real markup** — 12 `<` and 12 `>`: a `<style>` block, `<div class="gradient-marquee">`, a `<marquee>`, an
`<hr>`, `<br>`s and a **YouTube `<iframe …>`**. Product 89's description is 118 characters of plain text.

Two pages show a **snippet** of that description. The customer cart (`product-qty-edit-html`,
`customer/dod-ui-cus.lisp`) took the first **150** characters with a raw `SUBSEQ` and wrote it with
`CL-WHO:STR` — which emits raw text, unescaped. The cut landed **inside the iframe**:

```
…serve you better \n<hr>\n<br>\n\n<iframe wid      ← the page shipped exactly this
```

An unterminated `<iframe wid` makes the browser read on until the next `>`, so everything between was
swallowed into the unfinished tag: the modal's own closing markup, the **remove (delete) anchor written
immediately after it**, the rest of the row, and the **following cart row**.

**The reported symptom was precisely that**, and it is what makes this worth a skill: a **two-item cart
showing ONE row, that row with no delete button**, and *no error anywhere* — nothing throws, no 500, nothing
in the log. The product card's own snippet (`products/dod-ui-prd.lisp`, 90 characters) cut inside the plain
sentence ("…one da") and rendered harmlessly, which is why the fault looked cart-specific and
product-75-specific. **A truncation whose boundary is arbitrary will eventually land inside a tag; the
shorter the excerpt, the luckier or unluckier it is.**

**The fix.** `nst-plain-excerpt (text limit)` (`core/dod-bl-utl.lisp`, dependency-free — no cl-ppcre):
complete tags removed, whitespace runs collapsed to one space, trimmed, and **if a `<` is left UNCLOSED,
everything from it onward is dropped**. Callers still pass the result through `CL-WHO:ESCAPE-STRING` so a
stray `&` or quote cannot break the document either:

```lisp
(:p (cl-who:str (cl-who:escape-string (nst-plain-excerpt description 150))))
```

⚠ `CL-WHO:ESC` IS NOT USABLE HERE: it is a *local flet* inside cl-who's html expansion, not an exported
function. Use `CL-WHO:ESCAPE-STRING` (exported) wrapped in `CL-WHO:STR`.

**Verification** (read-only, `nst-verify-excerpt.lisp`-style probe, **20 pass / 0 fail**): the excerpt carries
no `<` or `>`, is ≤ the limit, keeps the product's own words, collapses whitespace; product 75's card renders
**with its delete button and its remove modal**, no `<iframe>`/`<style>`/`<marquee>` in the row; and the
two-item cart table renders **both rows with 2 delete buttons**, balanced `<a>`/`</div>` counts, and no
`<iframe>` anywhere.

## 2. THE RULE

* **An excerpt is a SUMMARY and must never emit markup.** `SUBSEQ` of a stored text field is only safe when
  the field is known plain.
* **Markup in the database is data, not a template.** Treat every stored description as untrusted input at
  the moment it is rendered into a document, wherever it is rendered.
* **Prefer the narrow escape.** Where a field is deliberately rich (the full-description page), the read is
  not the place to fix it — the write is (§4).

## 3. WHERE THE DESCRIPTION IS RENDERED (measured 2026-10-11)

| site | what it does | state |
|---|---|---|
| `customer/dod-ui-cus.lisp`, `product-qty-edit-html` | 150-char snippet into the cart's edit modal | **fixed** (`nst-plain-excerpt` + escape) |
| `products/dod-ui-prd.lisp:503` | 90-char snippet on the product card | **fixed** (same helper, 90) |
| `products/dod-ui-prd.lisp:689` | the FULL description in a `<p>` | **raw by design** — the rich-description page; see §4 |
| `products/dod-ui-prd.lisp:207/314/341` | description into a `<textarea>` as content | raw; a `</textarea>` in the text would break out |
| `customer/nst-ui-prodetpag.lisp:75` | reads it for the details page | check before changing |

## 4. OPEN — the wider finding this exposed

**Vendor-authored markup is rendered RAW on customer pages.** The cart's own bug proves the door is open: an
`<iframe>` from a description reached the customer's page, so a `<script>` would too — **stored XSS with a
vendor's product form as the entry point**. The durable fix belongs at **write** time, not at every read:
sanitise the description where it is saved (`vendor/dod-ui-ven.lisp:1504`, `sysuser/dod-bl-cad.lisp:26/34`),
allowing a safe subset and dropping `script`/`iframe`/`style`/event attributes. Also decide the PRODUCT
question behind it: may a vendor author HTML at all, and if so with which tag set? Until that is decided, the
snippet sites stay defensively stripped (§1) and the full-description render stays a known exposure.

## 5. OPERATIONAL NOTE — A DESCRIPTION EDIT IS NOT INSTANTLY VISIBLE

The pages render the description from the **session product cache** (`:login-prd-cache`), which is replaced
wholesale by `select-products-by-company` at login (`customer/dod-ui-cus.lisp:3737` guest login, `:3791`
login, `:3839` OTP login). A guest holding an older cached copy keeps seeing the old description — **and the
old breakage** — until they log in again. Data-side repairs to a product therefore need a re-login, not a
page refresh, to show up.

**Related defect found in the same reading (still open):** the cart page pairs each line with a product from
that same cache via `search-item-in-list`, so a **cache miss is a NIL** — and `length` counts the NIL as an
item ("Shopping Cart - 2 Items") while the card cannot render it at all: measured, `slot PRD-NAME is missing
from the object NIL`, which kills the WHOLE table, not just the row (`ui-list-shopcart` builds its string
first). A cart page that resolves its products from the database by `prd-id` removes the class.
