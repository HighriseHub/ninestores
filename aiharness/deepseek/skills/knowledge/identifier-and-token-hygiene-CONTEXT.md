# Identifiers, tokens and `hhub-random-password` — why a password generator is not a key generator

**Read this when:** a page or route intermittently dies with **`the slot … is missing from the
object NIL`** (or a `GETHASH` that should hit, missing) · a redirect lands somewhere that cannot
find the thing it was told about · a generated id breaks a JS/CSS selector or a character
counter · an id works for existing rows but never for NEW ones · **you are about to reach for
`hhub-random-password` for anything that is not a password.**

**Verified:** 2026-10-03, against the real tree and a live measurement (recipe in §5).

---

## 1. The two generators, and the rule

| function | alphabet | use it for | NEVER for |
|---|---|---|---|
| `hhub-random-password` (`core/dod-bl-utl.lisp:542`) | 89 chars — lower, upper, digits **and 23 symbols**; guarantees one of each class | passwords, initial credentials, salts, confirm-password placeholders | **any identifier** |
| `hhub-random-token` (`core/dod-bl-utl.lisp:499`, immediately above it) | 36 chars `[a-z0-9]`, drawn through `secure-random` with rejection sampling | session keys, route parameters, HTML ids, file-name components, document codes, placeholder numbers | passwords (it cannot satisfy a complexity rule by construction) |

**THE RULE: if the value will travel in a URL, a form field, an HTML attribute, a JS/CSS
selector, a file name or a database key, it is an identifier — use `hhub-random-token`.**

## 2. 🚨 WHY THIS IS A LIVE BUG AND NOT A STYLE POINT

Until commit **`6cb4c3d` (2026-09-13) "raise the password policy and fix the random-password
alphabet"**, `hhub-random-password` was base-36: every identifier minted from it was safe, and
several places in this tree were (and still are) built on that assumption. The commit widened
the charset *on purpose*, for OWASP character-class compliance — and thereby made every one of
those call sites intermittent. **Nothing in the commit touched an identifier call site, so
nothing looked wrong.** The bug has been live since 2026-09-13.

And it is required to contain at least one symbol, so a hostile character is not a rare accident
of a long draw: the special class is placed first, always.

| character | what it does to an identifier |
|---|---|
| `&` | **truncates a query string** — `?k=AB&CD` arrives as `AB` |
| `#` | everything after it becomes a fragment and **never reaches the server** |
| `%` | starts a percent-escape: mis-decoded, or rejected outright |
| `+` | **is a SPACE in `application/x-www-form-urlencoded`** (every form body, and the query) |
| `?` | starts a second query string |
| `.` `[` `]` `(` `)` `,` `;` `:` | break a CSS/JS selector, and `[]`/`()` land inside a JS expression |
| `!` `@` `$` `^` `*` `{}` `_` `-` `=` | survive a URL, still unsafe in a JS identifier |

## 3. The incident that found it (2026-10-03)

**Symptom:** creating a NEW invoice (the shop's report: "on a new customer") answered a 500 —

```
When attempting to read the slot's value (slot-value), the slot
COM.NSTORES.APP::INVOICEHEADER is missing from the object NIL.
  7: (COM.NSTORES.APP::CREATE-MODEL-FOR-ADDPRDTOINVOICE)
```

**Mechanism.** The wizard mints its per-invoice session key in
`create-model-for-editinvoiceheaderpage` (`invoice/nst-ui-ihd.lisp`):

```lisp
(sessioninvkey (if inum inum (format nil "NST000~A" (hhub-random-password 10))))
```

That key is (1) put in a redirect **query string**
(`/hhub/vproductsforinvoicepage?sessioninvkey=…`), (2) carried in a **hidden form field**
through `createinvoiceaction`/`updateinvoiceaction`, and (3) used as the key of the
`:session-invoices-ht` hash in the hunchentoot session. Any `&`/`#`/`%`/`+` in it changes the
value somewhere along that path, `GETHASH` misses, `(slot-value NIL 'InvoiceHeader)` signals
`MISSING-SLOT`, and the customer sees a 500.

**WHY ONLY NEW INVOICES.** `(if inum inum …)` — an EXISTING invoice uses its real `INVNUM`
(`NST00023-2024`), which is clean. Only the new-invoice branch mints a random key. That is the
discriminator worth remembering: *"works for existing records, never for new ones"* is this bug.

**FIX:** the key now uses `hhub-random-token`. One line, plus the comment naming the class.

## 4. ⚠ THE SITES THAT STILL MINT IDENTIFIERS FROM THE PASSWORD GENERATOR

Measured 2026-10-03 by `grep -rn "hhub-random-password" hhub/`. **Not yet swept** — each is a
one-line change to `hhub-random-token`, and each needs the same judgement: is this value an
identifier (URL / id / code / file name) or genuinely a password?

| site | what it is | risk |
|---|---|---|
| `sysuser/dod-ui-sys.lisp:131` `generateotp&redirect` | the OTP `session-id`, carried as `/hhub/otppage?session=~A&phone=~A` | 🚨 **the same bug in the OTP flow**: the id can be mangled, so the code-entry page cannot find the OTP. (Also note the `phone` is interpolated unencoded, so a `+91…` number arrives as ` 91…`.) Parked with the OTP work, but real |
| `charcountid1` — `invoice/nst-ui-ihd.lisp:591,2863,2910,2972`, `customer/dod-ui-cus.lisp:2110`, `vendor/dod-ui-ven.lisp:1325`, `upi/dod-ui-upi.lisp:65,178,230`, `products/dod-ui-prd.lisp:187` (10 sites) | a JS element id interpolated into **JavaScript source**: `(format nil "countChar(~A.id, this, 1000)" charcountid1)` | ⚠️ a `.`/`?`/`[` in the id makes the emitted JS a syntax error or a wrong reference — the character counter silently stops |
| `vendor/dod-ui-ven.lisp:576` | `:product-code (format nil "PRD-~A" …)` | ⚠️ a **document code** with symbols in it: lands in the DB, in URLs, in `LIKE` searches, possibly in file names |
| `invoice/nst-bl-invh.lisp:236` | the API's placeholder `INVNUM` — `NST000<random>` | ⚠️ latent: live rows are clean (a MySQL trigger/format normalises the number), but a *document number* is the last place a `&` should ever appear |
| `core/dod-ui-utl.lisp:1252` | `with-html-form`'s `formid = "id<form-name><3 random>"` | low: the JS hooks target `#id<form-name>`, not the random id — but an id in an HTML attribute should still be safe |
| `dod-bl-usr.lisp:149`, `dod-bl-ven.lisp:302`, `customer/nst-bl-Customer.lisp:1325` | initial passwords / confirm-password | ✅ **correct as they are** — these ARE passwords |

## 5. Traps, and how to measure it

- 🚨 **`compile-file` CANNOT SEE IT, AND NEITHER CAN A MANUAL RETRY.** The value is valid Lisp
  and valid data; it only breaks when a *specific character* is drawn, so a hand-test passes
  most of the time. Measured: **1056 of 5000 (21%)** keys were mangled by the URL+form round
  trip with the old generator, and 0 of 5000 with the token. Treat "it worked when I tried" as
  no evidence at all.
- The measured recipe (a throwaway SBCL; `hhub-random-*` needs `packages.lisp` plus the usual
  deps, and `dod-bl-utl.lisp` needs `cl-yaml`): mint a key, build
  `(format nil "/x?sessioninvkey=~A" key)`, split the query on `&` and form-decode `+` → space,
  and compare with the original. `hhub-random-password`'s output loses ~1 draw in 5;
  `hhub-random-token`'s never does.
- **`#` never reaches the server**, so nothing in the access log or the app log shows it: the
  request simply arrives with a truncated/other parameter. Log-based diagnosis sees a key that
  "was never present".
- ⚠️ **A `loop` form worth knowing while writing the generator:** `when … do … and return` is
  not valid LOOP — `and` continues a *conditional* clause, and SBCL reports
  `LOOP code ran out where a form was expected` at macroexpansion. Use `block`/`return-from`.
- ⚠️ `hhub-random-token` draws through `secure-random:*generator*`, not `*random-state*`, and
  uses rejection sampling (`limit = (* 36 (floor 256 36))`) so the low letters are not
  favoured. It is an identifier generator, not a secret generator — `secure-random` there is
  hygiene, not a claim about the value's secrecy.
