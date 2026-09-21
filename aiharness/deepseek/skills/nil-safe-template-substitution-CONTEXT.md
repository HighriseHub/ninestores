# nil-safe template substitution — optional business fields vs `cl-ppcre`

**Read this when:** a page dies with **"The function COMMON-LISP:NIL is undefined"** and the
backtrace shows `CL-PPCRE::BUILD-REPLACEMENT` / `CL-PPCRE:REGEX-REPLACE-ALL` under a
`create-model-for-…` frame — i.e. the template rendered fine for every vendor but one.

**Verified:** 2026-09-21 (IST).

---

## 1. The mechanism, and why it is a whole class of bug

`cl-ppcre:regex-replace-all` accepts a **replacement function** as well as a replacement
string. A raw slot value that happens to be `NIL` is not treated as "nothing" — cl-ppcre
takes the `NIL` branch of that protocol and **calls it**, giving:

```
The function COMMON-LISP:NIL is undefined
Backtrace: ... CL-PPCRE::BUILD-REPLACEMENT ... CL-PPCRE:REGEX-REPLACE-ALL ...
```

Nothing in the error names the field. The log excerpt does **not** contain the offending
value; the only forensic hints are the rendered string's length and `(... 0 6929 6661 6680 ...)`
arguments, which locate *roughly* where substitution stopped. Do not read a field name out
of the log — this was overclaimed once. Confirm against data or the template instead.

So any `(setf tpl (cl-ppcre:regex-replace-all "%X%" tpl slot-value))` is a latent crash on
every field that is *legitimately* unset. In nstores that is a large set, by design:
GST numbers (vendors below the ₹40 lakh goods / ₹20 lakh services registration threshold),
customer GSTIN (B2C), transporter, vehicle number, reverse-charge, bank account, authorised
signatory, financial year, `unit-of-measure`, `sku`, `description`, optional parameters.

**The schema is the tell.** In `hhub/vendor/dod-dal-ven.lisp` the `Vendor` class and the
`dod-vend-profile` view class declare `gstnumber` **without** `:db-constraints :not-null`,
while `name`/`address` carry it. No constraint ⇒ NULL is a supported state ⇒ the renderer
must tolerate it.

## 2. The fix — one shared primitive

`nst-slot-str` lives in **`hhub/core/dod-ui-utl.lisp`** (defined ~line 57, right after
`extract-html-between-markets`):

```lisp
(defun nst-slot-str (object slot)
  (let ((v (slot-value object slot)))
    (if v (princ-to-string v) "")))
```

Use `(nst-slot-str obj 'slot)` for slot reads enabled by `with-slots`, and `(or x "")` for
locals, function results and hash lookups. Both are equivalent in effect; pick the one that
fits where you are.

**Load order matters:** `core/dod-ui-utl` is entry 66 in `hhub/nstores.asd`, ahead of
`customer/dod-ui-cus` (105) and `upi/dod-ui-upi` (178), so the moved function is defined
before its callers at load time. Recompile `dod-ui-utl` first.

## 3. Where the guards now stand (2026-09-21)

Patched, each verified by an SBCL reader parse check:

| File | What was guarded |
|---|---|
| `hhub/core/dod-ui-utl.lisp` | new `nst-slot-str` |
| `hhub/customer/dod-ui-cus.lisp` | `ordertemplatefill` (vendor block + all invheader substitutions); duplicate-customer page `%Customer Email%` / `%Customer Phone%` (~1684-1685), which are `hunchentoot:parameter` and NIL on a plain GET |
| `hhub/customer/nst-ui-prodetpag.lisp` | `unit-of-measure`, `product-sku`, `description` (~104-106) |
| `hhub/invoice/nst-ui-ihd.lisp` | `create-model-for-displayinvoiceemail` (10 sites) and `invoicetemplatefill` (~30 sites, vendor + invheader blocks) |
| `hhub/upi/dod-ui-upi.lisp` | `display-upi-widget` — `(when (and upiappurls (> (length upiappurls) 0)) …)`; `generateupiurlsforvendor` returns NIL with no `upi-id` |
| `hhub/vendor/dod-ui-ven.lisp` | `unit-of-measure`, `product-sku`, `description` (~2647-2650) |

`ordertemplatefill` is shared: the UPI order path (`hhub/upi/dod-ui-upi.lisp:64`) and the
read-only cart (`hhub/customer/dod-ui-cus.lisp:3065`) both call it, so guarding it once
covers both pages. Grep for the callee before patching each call site.

### Verified NON-issues — do not re-patch

These look identical at a glance and are already safe:

- `hhub/warehouse/nst-ui-warehouse.lisp:358-426`, `hhub/vendor/dod-ui-ven.lisp:3469-3497`,
  `hhub/customer/dod-ui-cus.lisp:3938-3974` — every dropdown branch replaces with
  `dropdown-html` built by `with-output-to-string` (always a string), and each `(t …)`
  fallback is already `(if value (princ-to-string value) "")`.
- `hhub/invoice/nst-ui-itm.lisp:308-310` — already `(or prddesc "")` / `(or hsncode "")` / `(or uom "")`.
- `hhub/core/nst-bl-aicore.lisp`, `hhub/core/nst-bl-ollama.lisp`, `hhub/core/dod-bl-utl.lisp:447-449`
  — literal constant replacements.
- `hhub/core/dod-bl-utl.lisp:279,282` — `fieldnames`/`entityname` come from a
  caller-supplied, hardcoded compile-time list.

## 4. Recipe — auditing this class in one pass

1. Enumerate every site: `grep -rn "regex-replace-all" hhub/ --include=*.lisp` (174 sites on
   2026-09-21). Do not sample; the sites are spread across eight files.
2. Drop the obviously-safe ones, then **read each survivor** — do not trust a grep filter:
   `grep -v "nst-ui-ihd" /tmp/allsubs.txt | grep -viE "format nil|\(or |princ-to-string|funcall|nst-slot-str"`
   still prints the "replace with `dropdown-html`" lines, which are safe for a reason the
   filter cannot see.
3. Patch, then **parse-check every edited defun** (see §5).
4. Re-run step 1 and confirm each remaining unguarded site has a written reason.

## 5. Verification without the running image — parse check

SBCL's reader catches unbalanced parens and reader-level breakage, which is what a
multi-line `setf` batch edit actually risks. Compile the *live server image* separately.

Extract each edited `defun` by paren-walking (skipping `;` comments and `"` strings),
concatenate, strip package markers (`pkg:sym` → `sym`) so the file reads without the app's
packages, then:

```
(with-open-file (s "/tmp/pc.lisp")
  (loop for f = (read s nil :eof) until (eq f :eof)
        count 1 into n finally (format t "~&PARSED ~A forms OK~%" n)))
```

Expected: `PARSED n forms OK` where n is the number of functions extracted.

**Traps met doing this:**
- Reading the *whole* file fails on `Package HUNCHENTOOT does not exist`. Stubbing the
  packages is not enough — `hunchentoot:parameter` then fails as a missing external symbol.
  Stripping the markers is what works.
- A `#\return` / `#\(` in the source breaks a naive paren counter. Track string and comment
  state, or expect a bogus imbalance.

## 6. Sharp edges

- **`(string-upcase (gethash k ht))` on a miss** returns `NIL` from `string-upcase`, not a
  string — same crash, one level deeper and less obvious. Guard the `gethash` itself:
  `(string-upcase (or (gethash state *NSTGSTSTATECODES-HT*) ""))`.
- **A `with-slots` whose bindings all become unused** cannot be swapped for `progn` by
  editing only the first line: the group's closing paren count changes. Balance it, then
  parse-check.
- The error names no field. If you must name one, say it is an inference and give the
  evidence (template offsets, schema constraints) — see §1.
