# The public invoice link — signed, expiring, password-gated

**Verified 2026-09-26** against the real database, offline, with no image reload
(`../tools/nst-verify-invoice-public-link.lisp`, 74 checks). Where this file states a
measurement, that tool is the evidence; where it states a design decision, the reasoning
is given so it can be re-litigated rather than re-discovered.

## 1. What it is, and the two routes

A customer with no session opens a GST invoice in a browser:

| Route | Handler | Reads the key |
|---|---|---|
| `^/hhub/displayinvoicepublic` | `com-hhub-transaction-display-invoice-public` → `create-model-for-displayinvoicepublic` | verifies, then renders the invoice |
| `^/hhub/publicinvoicepdf` | `com-hhub-transaction-invoice-public-pdf` → `create-model-for-invoice-public-pdf-url` | verifies, then re-mints to render the PDF |

Both live in `hhub/invoice/nst-ui-ihd.lisp`; the dispatcher entries are in
`hhub/sysuser/dod-ui-sys.lisp:1148` and `:1151`, and **neither checks a session** — the key
is the authorisation.

The PDF route exists separately because the old name would have been swallowed by the
vendor route: `^/hhub/downloadinvoice` is an unanchored prefix, so
`/hhub/downloadinvoicepublic` matched the vendor pattern first and bounced the customer to
a vendor login.

## 2. The token

```
key = base64url(payload) "." hex(hmac-sha256(payload, vendor.SALT))
```

The payload keeps the ORIGINAL shape so anything reading it positionally still works — a
header line plus one row, with the expiry **appended** as a fourth field:

```
tenant-id,invnum,vendor-id,expires-at
<tenant>,<invnum>,<vendor>,<universal-time expiry>
```

- Minter: `generate-invoice-ext-url (invnum vendor company)`.
- Verifier: `invoice-ext-key-parse (key)` → `(values PLIST REASON)`.
- Helpers: `invoice-ext-b64-encode` / `-decode`, `-key-payload`, `-key-signature`.

**WHY HMAC AND NOT A RANDOM TOKEN IN A TABLE.** Every caller mints on demand and uses the
link immediately, so there is nothing to store: the signature makes the token
self-validating and the expiry unforgeable without a table, a lookup or a cleanup job.

**WHY KEYED WITH THE VENDOR'S OWN `SALT`.** It already exists per vendor, never leaves the
system (the vendor response allowlist excludes it), and needs no migration. Per-vendor
means a token minted for one vendor cannot be forged for another.

**WHY NOT `PAYMENT_API_SALT`** — measured on all 15 live rows: `0` on row 1, `NULL` on the
rest. It cannot key anything.

## 3. The two knobs

| Knob | Value | Where |
|---|---|---|
| `*invoice-ext-link-lifetime-seconds*` | **300** (5 minutes) | `nst-ui-ihd.lisp` |
| `*invoice-ext-max-attempts*` | **5** | `nst-ui-ihd.lisp` |

⚠ **A STORED `EXTERNAL_URL` GOES STALE IN FIVE MINUTES.** `DOD_INVOICE_HEADER.EXTERNAL_URL`
is a column; anything that persists a link and hands it out later is now wrong. The email
path is safe because it renders the PDF immediately.

⚠ **LENGTHENING THE LIFETIME RE-OPENS A DENIAL-OF-SERVICE TRADE.** Five wrong passwords
lock the token — and an attacker who can reach the link can spend those five, locking out
the real customer. That is acceptable *only* because the link dies in five minutes anyway.

## 4. The password

The password is **the last four digits of the vendor's registered phone number**, from
`dod-vend-profile.phone` via `invoice-ext-password-digits`. Both sides are normalised by
`invoice-ext-four-digits`, which keeps the LAST four digits — so a stored `+91 99999 99990`
and a customer typing the whole number both reduce to `9990`.

**BE HONEST ABOUT WHAT THIS IS.** Four digits is 10,000 combinations, and the value is the
vendor's own phone number, often printed on the invoice being protected and routinely
quoted to customers. The password is a speed bump for a forwarded or mis-delivered link.
**The five-minute expiry is the actual control**, and the attempt limit is what stops the
password from being decorative.

### The gate

`invoice-ext-authorise (key expected submitted is-post)` → `(values STATE REASON LEFT)` with
STATE `:granted` / `:prompt` / `:locked`. Rules:

- **Only a POST carrying a non-blank password spends an attempt.** A GET never does —
  otherwise an attacker locks the real customer out by reloading the page — and a blank
  submission is one mis-click, not a guess.
- **Junk spends an attempt.** Anything non-blank counts, or a script sending nonsense would
  never trip the limit, and tripping the limit is the whole defence.
- **`:granted` is sticky.** A wrong password afterwards must not revoke it, or a customer
  with a second tab loses the page they are reading.
- **`:locked` is sticky.** The CORRECT password does not reopen it, or the limit is a delay
  rather than a limit.
- The comparison is `constant-time-string=` (`core/dod-bl-utl.lisp:957`).

State lives in `*invoice-ext-gate-table*` — an in-memory hash keyed by the token, guarded by
`*invoice-ext-gate-lock*` (`bt:make-lock`; Hunchentoot is multi-threaded), swept lazily by
`invoice-ext-gate-sweep` on each call. In memory on purpose: the state is worthless once the
token expires, and a database row for an expired token is a liability.

### Why the submitter and method are ARGUMENTS

`invoice-ext-authorise` takes `submitted` and `is-post` rather than calling
`hunchentoot:parameter` itself. `hunchentoot:parameter` cannot be called outside a request,
so reading it internally would make the whole gate untestable without a live server — which
an agent cannot restart here. **This was a design choice made FOR the offline harness.**

## 5. Traps — every one of these was measured, not reasoned about

1. 🚨 **base64 IS CASE-SENSITIVE.** `invoice-ext-b64-encode` was written with a
   `string-downcase` around it. That made every minted key decode to line noise, and since
   the signature is computed over the *decoded* payload, **every link failed verification**
   with `the link is malformed`. Case-folding belongs on hex (the signature), never on
   base64.
2. 🚨 **CL-WHO DOES NOT CONVERT `(:tag …)` INSIDE `when`/`if`.** It emits the form as
   ordinary Lisp and you get `The function :DIV is undefined` at runtime, mid-render.
   Wrap the conditional body in `(cl-who:htm …)`.
3. **CL-WHO writes single-quoted attributes** (`class='x'`). Asserting `name="password"`
   against correct code fails; normalise the quotes when testing markup.
4. 🚨 **THERE IS NO `:hmac` DIGEST NAME.** Ironclad's API is
   `(ironclad:make-hmac key :sha256)` → `(ironclad:update-hmac mac …)` →
   `(ironclad:hmac-digest mac)`, and **`update-hmac` declares its sequence as a simple octet
   vector — a string is not accepted.** Use `ironclad:ascii-string-to-byte-array`. This is
   the only HMAC in the tree.
5. **A `let` that closes before the form that uses its binding.** `expires` was bound in a
   `let` with the `(values …)` as a *sibling*, so every valid key signalled
   `UNBOUND-VARIABLE`. The compiler offered only a style-warning; the offline harness
   caught it.
6. **`select-vendor-by-id` returns the LEGACY `dod-vend-profile` view-class, not
   `nst-vnd`** — and it has BOTH `salt` and `phone` accessors
   (`hhub/vendor/dod-dal-ven.lisp`). Check the view-class, not the domain class, before
   assuming a slot is missing.
7. **Minting fails closed when a vendor has no `SALT`.** Measured on the live table: rows
   **17, 18 and 19 have `SALT` NULL *and* `PASSWORD` empty** — they cannot log in, so they
   cannot reach any caller of the minter. All five callers are vendor-session-driven
   (`get-login-vendor`) or require an already-valid key, so **no reachable flow is broken**
   by failing closed. A shared fallback key would have recreated the forgeability this
   removes, so failing closed is the deliberate choice.
8. **A URL-safe alphabet is not cosmetic here.** The link is built by plain `FORMAT` with no
   percent-encoding, so a `+` in base64 arrives at the server as a SPACE. `+`→`-`, `/`→`_`,
   padding stripped.

## 6. What the key used to be, and why that mattered

`base64("tenant-id,invnum,vendor-id\n<tenant>,<invnum>,<vendor>")` — structured,
predictable, **unsigned, with no expiry and no password**. Anyone holding one link could
decode the format and mint the key for ANY invoice in ANY tenant: a BOLA bypass
(OWASP API1:2023) wearing the costume of a capability URL. The rendered PDF was the same
story — a static file under `/img/temp/` named from the invoice number and universal time.
