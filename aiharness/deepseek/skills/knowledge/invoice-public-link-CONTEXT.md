# The public invoice link — signed, expiring, password-gated

**Verified 2026-10-03** against the real database, offline, with no image reload
(`../tools/nst-verify-invoice-public-link.lisp`, 116 checks). Where this file states a
measurement, that tool is the evidence; where it states a design decision, the reasoning
is given so it can be re-litigated rather than re-discovered.

**Three changes since 2026-09-26, all below:** the server-side `:render` token that keeps the
password gate out of the PDF pipeline, the password moving from the VENDOR's phone number to
the CUSTOMER's, and the vendor-side red share icon (§3) that finally tells the vendor a link
is dead before a customer has to.

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

- Minter: `generate-invoice-ext-url (invnum vendor company &key render)`.
- Verifier: `invoice-ext-key-parse (key)` → `(values PLIST REASON)`; the PLIST carries
  `:render` as well as `:tenant-id` / `:invnum` / `:vendor-id` / `:vendor` / `:company` /
  `:expires-at`.
- Helpers: `invoice-ext-b64-encode` / `-decode`, `-key-payload`, `-key-signature`,
  `invoice-ext-public-url`.

⚠ A **fifth** field appears on a SERVER-SIDE RENDER token only (`…,expires-at,1`). A plain
mint still emits four, so every link stored in `EXTERNAL_URL` before 2026-10-03 verifies
unchanged. See *the render token*, below.

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
is a column; anything that persists a link and hands it out later is now wrong. **NOTHING
READS IT FOR RENDERING ANY MORE** (2026-10-03): the email attachment and the vendor's
Download button both MINT, and the email body's `%INVOICE_LINK%` mints too — it was
interpolating the column and mailing a dead link. The column keeps one legitimate writer,
the invoice save, and its value is the link the vendor copies to send by hand.

### The vendor's own view of the link — the share icon goes RED (2026-10-03)

**THE BUG: only the customer could tell a link was dead.** The vendor clicks the share icon on
`editinvoicepage`, the page copies `EXTERNAL_URL`, and by then that link is at least five
minutes old — so it is pasted into WhatsApp, the customer replies *"this link is expired"*,
and the vendor has no way to know before sending. The customer was the health check.

**THE FIX, exactly as the business asked for it:** the icon is **red** when the link cannot be
opened, and the vendor re-issues it by pressing **NEXT** on the same page (which posts
`updateinvoiceaction` → `create-model-for-updateInvoiceHeader` mints a fresh link →
`doupdate` persists it → the page reloads with the icon back to normal colour).

| Piece | What it does |
|---|---|
| `invoice-ext-url-status (url &optional now)` | `:valid` / `:expired` / `:unusable`, decoded **from the link itself** — no row read, no SALT |
| `invoice-ext-key-of-url (url)` | the token after `key=`, the one place that knows where it is |
| `invoice-ext-url-share-title (status)` | the popover title: *"Share LIVE Invoice Link"* when valid, and when not, **the instruction, naming the NEXT button** |
| `invoice-header-actions-menu` | `fa-solid fa-link` vs `fa-solid fa-link text-danger`, and the title |

- 🚨 **IT IS A DISPLAY CHECK AND MUST NEVER BECOME A GATE.** It does not verify the HMAC and
  says nothing about whether the invoice exists. The verifier pins the boundary from both
  sides: a link with a **junk signature reads `:valid`** (it carries a live expiry) while the
  gate refuses it with `the link is not one this system issued`. Authorisation stays
  `invoice-ext-key-parse`.
- **`:unusable` IS NOT `:expired`, AND THE LIVE DATA IS WHY THE ARM EXISTS.** It means the link
  carries no usable expiry: empty, hand-trimmed, or a LEGACY unsigned
  `base64("tenant,invnum,vendor")` link. Measured 2026-10-03, the only **two** non-empty
  `EXTERNAL_URL` values in tenant 2 (rows 35, 30) are exactly that shape and the verifier
  refuses them with `the link is malformed` — so a vendor holding one is not waiting for a
  refresh, they are holding a link that has never worked since the signature landed.
- **⚠ IT DOES NOT STOP THE COPY.** The icon turns red and says what to do; clicking it still
  copies the (dead) link. Blocking the copy — an `alert` instead of the clipboard write when
  the status is not `:valid` — is the obvious follow-up and is deliberately not done here.
- ⚠ **BOUND THE STATUS OUTSIDE THE CL-WHO FORM.** cl-who converts tag forms only in a body
  position and does **not** recurse into a `let`, so a binding placed inside the markup breaks
  the tags around it (the same trap as `(:div …)` inside `when`, §5.2). It is bound in the
  `let` above `with-html-output`.
- ⚠ **A LIVE ROW IS THE WRONG FIXTURE FOR THIS.** The vendor re-saving an invoice is the fix
  flow, so a check that reads a real `EXTERNAL_URL` would flip to `:valid` the first time
  anyone used the feature and then PASS vacuously. The harness BUILDS the legacy and the
  expired link instead, and asserts the rendered markup in both directions.

⚠ **LENGTHENING THE LIFETIME RE-OPENS A DENIAL-OF-SERVICE TRADE.** Five wrong passwords
lock the token — and an attacker who can reach the link can spend those five, locking out
the real customer. That is acceptable *only* because the link dies in five minutes anyway.

## 4. The password

🚨 **THE PASSWORD IS THE CUSTOMER'S, NOT THE VENDOR'S (changed 2026-10-03).** It is **the
last four digits of the phone number the invoice was BILLED TO** — `DOD_CUST_PROFILE.PHONE`
of the invoice's own `CUSTID`, via `invoice-ext-customer-of-invoice` →
`invoice-ext-password-digits`. Both sides are normalised by `invoice-ext-four-digits`, which
keeps the LAST four digits — so a stored `+91 99999 99990` and a customer typing the whole
number both reduce to `9990`.

**WHY IT MOVED, AND WHY THAT IS THE SECURITY ARGUMENT RATHER THAN A PREFERENCE.** The
vendor's number is on every invoice that vendor issues: printed on the page being protected
and quoted to every customer who asks. So the old password protected the invoice from
everyone *except its own addressee* — the one party a forwarded link should still have to
prove itself to. The customer's number is the thing the link's intended reader has and a
passer-by does not. ⚠ It is still only four digits, and the customer's own number is on the
invoice too.

**BE HONEST ABOUT WHAT THIS IS.** Four digits is 10,000 combinations, and the number is
printed on the document it protects and known to whoever the link was forwarded to. The
password is a speed bump for a mis-delivered link. **The five-minute expiry is the actual
control**, and the attempt limit is what stops the password from being decorative.

### Resolving the customer — the one row read the gate is allowed

`invoice-ext-customer-of-invoice (invnum company)`: the header by invnum + tenant, then the
customer by its `CUSTID`. It is safe because **the key has already been signature-verified
and expiry-checked** by the time it runs, and nothing from the read is rendered.

- It reads **exactly what the page's own model reads** (`nst-bl-ihd.lisp` `doread`), so a
  customer the page can bill is a customer the gate can ask a password of.
- ⚠ **IT FAILS CLOSED ON AN INACTIVE OR SOFT-DELETED CUSTOMER.** `select-customer-by-id`
  requires `ACTIVE_FLAG='Y'` *and* `DELETED_STATE='N'` — deliberately the stricter read for a
  gate, but it is the line that would stop a deactivated customer opening their own invoice.
  Measured 2026-10-03: all 25 live customer rows are `'Y'`/`'N'`, so nothing reachable is in
  that state. `nst-select-customer-by-id` (the new domain's reader) drops the ACTIVE_FLAG
  clause if that trade is ever revisited.
- 🚨 **DO NOT USE THE `customer` JOIN SLOT.** `dod-invoice-header` declares one on `CUSTID`
  (`:DB-KIND :JOIN`), but `select-invoice-header-by-invnum` is `:FLATP T` and never resolves
  a join: the slot comes back NIL and the gate would refuse **every** link. Read `CUSTID`.
- ⚠ **A RENDER TOKEN SKIPS THIS LOOKUP ENTIRELY**, not merely its answer: the PDF pipeline
  must not depend on the customer row resolving, so a deactivated customer cannot stop an
  invoice being rendered for the vendor who owns it.
- The message when it fails: *"the customer this invoice was billed to has no phone number
  on record, so this invoice cannot be protected"* — and the prompt itself says *"the phone
  number this invoice was billed to"*, because a prompt naming the vendor makes the customer
  type digits that cannot match, spending one of five attempts.

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

`invoice-ext-authorise-grant (grant rawkey expected submitted is-post)` is the seam the page
calls: it is `invoice-ext-authorise` UNLESS the verified key carries `:render` (below), in
which case it answers `:granted` without consulting the password at all. Pure, so the
render short-circuit is provable offline — the page model it lives in needs a live HTTP
request to run.

State lives in `*invoice-ext-gate-table*` — an in-memory hash keyed by the token, guarded by
`*invoice-ext-gate-lock*` (`bt:make-lock`; Hunchentoot is multi-threaded), swept lazily by
`invoice-ext-gate-sweep` on each call. In memory on purpose: the state is worthless once the
token expires, and a database row for an expired token is a liability.

### 🚨 THE RENDER TOKEN — WHY THE PDF PIPELINE MUST NOT MEET THE GATE (2026-10-03)

**The gate broke every PDF in the system, and the symptom is worth recognising.** The PDF
pipeline renders an invoice by `generate-invoice-ext-url` → `downloadhtmlfile` (wget) →
`generatepdf` (wkhtmltopdf) — it FETCHES ITS OWN PUBLIC PAGE. wget is a browser with no
session and nobody to type a password, so the fetch returned the PROMPT and wkhtmltopdf
rendered THAT: the emailed attachment, the vendor's Download button, the customer's
Download button and the API's `GET /invoices/{id}/download` all became a PDF of a
four-digit password form — and, because the prompt is markup inside the page rather than a
replacement for it, the form sat ON TOP of the invoice content.

**The fix is a fifth SIGNED payload field**, `invoice-ext-render-marker` (`"1"`):

```
tenant-id,invnum,vendor-id,expires-at[,1]
```

- Minted only by `(generate-invoice-ext-url invnum vendor company :render t)`; a plain mint
  still emits four fields, so **every link stored in `EXTERNAL_URL` before this change
  still verifies**.
- `invoice-ext-key-parse` reports it as `:render` in its plist; `invoice-ext-authorise-grant`
  grants on it; the page skips the password and the `no phone number on record` refusal.
- **IT IS INSIDE THE SIGNATURE ON PURPOSE.** The fetch makes an outbound round trip to
  `*siteurl*`, which may be ANOTHER deployment of the same code, so an in-memory exemption
  would not travel. A query parameter (`&render=1`) would travel and would hand every
  customer a password bypass. Adding or stripping the fifth field fails `:SIGNATURE`
  (both directions are asserted in the verifier).
- ⚠ **IT IS A BEARER CAPABILITY: it opens an invoice with no password**, so it must never be
  handed to a browser, stored in a column, or put in an email.

**THE FOUR CALL SITES, and the rule each one follows:**

| caller | mints | why |
|---|---|---|
| `invoice-pdf-attachment` (the email attachment) | `:render t` | the server fetches it; the customer is not there to type |
| `create-model-for-downloadinvoice` (vendor UI button) | `:render t` | vendor session; **was reading the stored `EXTERNAL_URL`** |
| `invh-download-pdf-url` (API `/download`) | `:render t` | already tenant-checked by the route |
| `create-model-for-invoice-public-pdf-url` (customer's button) | **nothing** — it fetches `(invoice-ext-public-url (hunchentoot:parameter "key"))` | the gate's unlocked state is keyed BY THE TOKEN |

🚨 **THE FOURTH ROW IS THE SUBTLE ONE.** That function used to mint a FRESH link — same
invoice, valid signature, **different token** — and since the gate is keyed by the token, the
server's own fetch arrived as a stranger and got the prompt rendered into the customer's PDF.
Fetching the key the customer actually unlocked makes the gate answer the server exactly as
it answered them. It also keeps fail-closed: reached without the password, the fetch returns
the prompt page, so a hand-built key leaks nothing. **If you ever re-mint there again, you
re-break it.**

⚠ **AND THE EMAIL BODY'S `%INVOICE_LINK%` WAS DEAD.** It interpolated the STORED
`EXTERNAL_URL`, which §3 says is five minutes stale — so a customer opening the mail an hour
later was told "the link expired" however promptly they clicked. `create-model-for-displayinvoiceemail`
now MINTS a fresh link (with NO `:render`, because that one goes to a browser and must still
ask for the password).

**EVIDENCE:** `../tools/nst-verify-invoice-public-link.lisp` §9, 15 checks — a customer's link
is not a render token, a render link is, the marker is the fifth FIELD (read positionally, not
searched for), adding/stripping it is refused by the signature, and the gate decision itself
is driven directly (`:granted` with no password, `:prompt` without the marker and with a NIL
grant). **116 passed / 0 failed**, 2026-10-03; 74 of those are the original checks, so none of
the changes regressed anything. §6 additionally resolves the LIVE invoice's customer against the
database and proves the gate compares against **that** row: `(customer Gcust837333444 -> 9999
· vendor Demo Vendor -> 9990)`, and the vendor's `9990` is REFUSED where `9999` is accepted.

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
