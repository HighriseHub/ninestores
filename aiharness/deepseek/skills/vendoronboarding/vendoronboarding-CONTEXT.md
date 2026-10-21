# vendoronboarding — feature folder

**Read this when:** you are building anything in the **vendor onboarding** journey — the emails
a newly registered vendor receives, the state a vendor row is in (`PENDING` / `APPROVED` /
`REJECTED` / stranded), why a vendor cannot log in, the first-login experience, or the
"what do I do now" guidance on the vendor dashboard.

> **Feature:** vendor onboarding (persona 2 of 3). Siblings in scope later: customer onboarding,
> company-administrator onboarding. The whole-tree survey these files build on is
> `../onboarding-journeys-CONTEXT.md` — read that first for the code paths and traps; this folder
> is the build.
> **Status: PLAN — 2026-10-17. No email template, sender, constant or call site has been written.**

Files:

| File | Holds |
|---|---|
| `vendoronboarding-CONTEXT.md` (this) | scope, the vendor state machine, decisions, blockers, build order, file map |
| `vendoronboarding-EMAILS.md` | the E1–E7 template catalogue: trigger, recipient, subject, tokens, copy skeleton, code touch points |
| `vendoronboarding-FLOWS.md` | text flow charts as-is vs target, the first-login checklist, the after-login path |
| `vendoronboarding-ACTORS.md` | one email actor vs three persona actors (vendor / customer / admin): the assessment, the recommended shape, the build order |
| `vendoronboarding-TESTING.md` | the T0–T6 verification ladder, the per-symptom diagnostics, the FK-ordered test-data reset, and the leftovers that bite |

---

## 1. Scope and the one sentence

A vendor registers → **cannot log in** → nobody tells them why, or that they were approved, or
that they were rejected → and when they finally get in, the dashboard greets them with four
zeroes. This feature makes **every state self-explaining to the vendor in email, and to the
vendor on screen**, and hands the company administrator the one action that unblocks them.

**In scope:** vendor-facing emails (E1, E3, E4, E5, E6), the admin-facing email that triggers
approval (E2), wiring the already-written order email (E7), the first-login experience, the
dashboard checklist, and the login-page states.

**Out of scope (separate features):** a password system for vendors (OTP is the door and stays
the door), vendor self-service re-application automation, buyer onboarding, tenant onboarding,
the approval *policy* (who may approve) — that is `COMPADMIN` today and unchanged.

## 2. The state machine — what the vendor row can be, measured 2026-10-17

The row lives in `DOD_VEND_PROFILE`. Two columns decide everything:
`APPROVED_FLAG ('Y'|'N')` and `APPROVAL_STATUS ('PENDING'|'APPROVED'|'REJECTED')`.

```
        register                          admin clicks Approve
 (none) ─────────► PENDING ──────────────────────────────────► APPROVED
                     │  N + PENDING                                  Y + APPROVED
                     │  login: REFUSED                               login: ALLOWED
                     │  told: nothing          admin clicks Reject
                     │        └──────────────────────────────────► REJECTED
                     │                                              N + REJECTED
                     │                                              login: REFUSED, no reason
                     │
                     └──► STRANDED  Y + PENDING   ← locked out by BOTH halves of the filter
                          (a real row: ROW_ID 17, tenant 5, 2026-10-17)
```

The gate is `AND`, not `OR`: `hhub/vendor/dod-ui-ven.lisp:2419` (OTP) and `:2446` (password)
both demand `approved_flag='Y'` **and** `approval_status='APPROVED'`. `STRANDED` is therefore a
dead end, not a slow path — and today nothing tells the vendor which of the four states it is in.

## 3. Self-explanatory rules (the copy contract)

Every vendor email and every onboarding screen must satisfy all five. They are the acceptance
criteria for E1–E6, and the reason a template is rejected in review.

1. **Name the state in the first line.** "You are registered and waiting for approval" — not
   "Thanks for registering".
2. **Name the party who is holding it.** `Demo Company` and its administrator, or "our GST
   verification desk" — never a bare passive "your request is under process".
3. **One primary action per message.** Every mail has exactly one button that does the useful
   thing; everything else is text.
4. **Say what happens next, and who does it.** "We email you the moment `<Company>` approves —
   usually within one working day." A state with no next step is a bug, not a design.
5. **Never a dead end.** Every message carries an escape hatch: status lookup, the admin's
   contact, or support (`support@ninestores.in`).

Plus the mechanical rules that follow from §4: **no password language** (there is no password —
OTP only), **no invented facts** (do not print a GSTIN the vendor did not give, do not print a
SLA nobody agreed), and **no "Nine Store"** (no such tenant exists in `DOD_COMPANY`).

## 4. Decisions taken (and why)

| # | Decision | Why |
|---|---|---|
| D1 | **New templates use `%Named Token%` substitution — the `invoicetemplatefill` pattern — not `format` + `~A`.** Helper `hhub-fill-email-template` = one ordered `cl-ppcre:regex-replace-all` per token, string replacement, every value guarded (`(if value (princ-to-string value) "")`). | Revised 2026-10-17 on the owner's instruction to reuse the invoice mechanism (`invoice/nst-ui-ihd.lisp:1326`), and it is the better fit: CSS's sibling combinator `~` is a `format` directive, a wrong argument count kills the send at runtime, and the argument order lives only in the caller — while `%Named Token%` is self-documenting in the file and is the convention every HTML page already uses (`%Customer Email%`, `%Vendor PAN Number%`). The NIL trap is real and known: a raw NIL passed to `cl-ppcre` *as the replacement* is called as a function (`../nil-safe-template-substitution-CONTEXT.md`) — hence the guard. Verified 2026-10-17: `*HHUB-EMAIL-CSS-CONTENTS*` is **NIL** (`core/dod-ini-sys.lisp:35`), so the Lisp-rendered shell `with-single-column-email` (`email/templates/registration.lisp:62`) emits **unstyled** mail — do not use it. Each new file carries its own inline `<style>`, like the existing 14 KB templates. |
| D2 | **Senders go into the existing `hhub/email/templates/registration.lisp`**, not a new file. | A new `hhub/**` file needs four registrations (`.asd`, `package/compile.lisp`, plus the preflight lists) for no benefit; every sender already lives in this one file. |
| D3 | **No reference/registration number in the emails.** Identify by `store + registered phone + email`. | The only id is `ROW_ID`; printing it leaks platform volume and there is no vendor number series (`document-numbering-CONTEXT.md` covers orders and invoices only). |
| D4 | **E2 goes to the tenant's `COMPADMIN` users** — email + in-app link. | `DOD_ROLES` = SUPERADMIN(1) / OPERATOR(2) / **COMPADMIN(3)**; `DOD_USERS` carries `EMAIL` and `PHONE_MOBILE` and every live tenant has one COMPADMIN with an email. Caveat: the demo tenants use `…@example.com`, so the copy cannot promise a human reads it. |
| D5 | **`cust-reg.html` stops being the vendor welcome**; it stays for customers until the buyer feature. | One file serving both personas is the current defect (`onboarding-journeys-CONTEXT.md` §8). Persona split is the whole point of E1. |
| D6 | **The first-login checklist is computed, never stored.** | A checklist flag table is a new migration and can drift from the truth. Every item is a `SELECT`/slot read: profile fields, product count, shipping method count. Nothing to migrate. |
| D7 | **E6 (KYC nudge) is phase 2** and needs a scheduler, which does not exist for this purpose. | Do not invent a job runner for a nudge. Phase 1 puts the same message in-app (§7 of FLOWS) where there is already a human reading it. |

## 4b. Registration fields — the design (proposed 2026-10-19, NOT built)

**Why.** The form collects "Full Name", email and phone; the VEN block's GSTIN/PAN/bank fields are
**posted and discarded**; and `ADDRESS` is filled with `"<store name>, <store address>"` — the *buyer's*
store, not the vendor — because `fulladdress` is built from the read-only tenant fields. City, state,
pincode and country stay NULL on every vendor. So the vendor's own identity is not captured at all, the
invoice prints a person's name as the seller, and the prefix derives from that name.

**The split, decided 2026-10-19 by the owner: the SIGNUP captures identity and the document-prefix
inputs; TAX data is country-specific and belongs on the vendor PROFILE page** (which already posts
`gstnumber`, `pan-number`, `gst-state-code`, `gst-registration-type`, `legal-name`, `trade-name` — see
`vendor/dod-ui-ven.lisp:785-905`). That keeps the signup short, keeps jurisdiction-specific rules out of
a form that must work in every country, and matches the KYC-after-approval shape the readiness checklist
already assumes.

### Signup — identity + what `DOC_PREFIX` needs

| form field | required | column | note |
|---|---|---|---|
| Company legal name | ✔ | `LEGAL_NAME` (+ `NAME` fallback) | **≥ 3 alphanumerics** — see the prefix rule below |
| Trade / brand name | – | `TRADE_NAME` | preferred prefix source when present |
| **Document prefix** | – (prefilled, editable) | `DOC_PREFIX` | 3–8 `[A-Za-z0-9]`, unique across vendors **and** customers; blank = derive at first mint |
| Contact person | ✔ (today's "Full Name") | `NAME` | the human we OTP and email; no longer the invoice seller |
| Phone, Email | ✔ | `PHONE`, `EMAIL` | phone 10 digits / E.164 per the country profile |
| Country | ✔ ISO-2 | `COUNTRY` | defaults to the store's country, changeable (§4c cross-border rule) |
| Registered address, City, Region, Postal code | ✔ | `ADDRESS` (currently holds the *store's* address), `CITY`, `STATE` + region code, `ZIPCODE` | region rendered only when the country has regions |

**What `DOC_PREFIX` actually needs — measured in `core/dod-bl-utl.lisp:1489-1560`:**
`nst-doc-prefix-base` takes **whole words**, first word truncated to 8, then following words while the
total stays ≤ 8, borrowing from the next word to reach 3 — `"XYZ CORP LIMITED"` → `XYZCORP`, not
`XYZCORPL`. It returns **NIL when the name holds fewer than 3 alphanumerics**, and that is a refusal, not
a fallback. `nst-doc-prefix-candidates` then walks `base`, `base[0:6]+NN`, `base[0:5]+NNN`, and the
UNIQUE index on `DOC_PREFIX` is the real guarantee. So the only *information* the signup must guarantee
for numbering is a company name with 3+ alphanumerics — everything else (`{prefix}`) renders from the
stored value. Hence the optional editable prefix field: it is the documented "system-prefilled,
customer-overridable" intent, with no UI precedent in the tree today.

### Vendor profile page — the country-specific tax block

GSTIN (or VAT/Tax ID), tax registration type, filing frequency, PAN/secondary id, region code, bank/UPI —
rendered from the **same country profile** as §4c so an AE vendor sees a TRN field instead of GSTIN, and
validated there (format + region derived from the tax id). Two consequences to accept: the approval card
and E2 will usually show **"GSTIN not provided"** at approval time (tax arrives later), and the readiness
checklist keeps "GSTIN/PAN" as a *post-approval* item.

**Validation (server-side, BEFORE the OTP so the form keeps its values):** company name ≥ 3 alphanumerics;
prefix `^[A-Za-z0-9]{3,8}$` and not already taken; country a live ISO code; region/postal per the country
profile; phone per the country profile; duplicate `(PHONE, TENANT_ID)` refused with the existing friendly
page. GSTIN/PAN validation moves to the profile page with the fields.

## 4c. Making the signup forms multi-country ready (design, 2026-10-19, NOT built)

**The requirement:** vendor *and* customer signup should be global from the start, because the next
jurisdiction is coming. **The governing decision already recorded** in
`knowledge/multi-jurisdiction-tax-CONTEXT.md`: masters are global, and a second country is an
**independent entity** — so "global form" means *the form can capture a party belonging to any country*,
not that one store serves every country.

**What exists today, measured:**

| piece | state |
|---|---|
| `DOD_CURRENCY` (country, currency, code, symbol) | **exists**, but keyed by a free-text *display name* ("America", "India") |
| `get-account-currency` (`account/dod-bl-cmp.lisp:12`) | company.COUNTRY → currency via that table, else `*HHUBDEFAULTCURRENCY*` — so **currency is entity-scoped**, and no order/invoice carries a currency column |
| country / region master | **none** — no ISO codes, no province list |
| `*NSTGSTSTATECODES-HT*` | India only (code ↔ name) |
| `DOD_VEND_PROFILE.COUNTRY` | NULL on 14 vendors, `''` on 2 — never captured |
| amount in words | `convert-number-to-words-INR` and `-USD` (the USD one unused) |

**Design: a country PROFILE as data, and a generic tax identity.**

```
*registration-country-profiles*     ; one entry per country, drives BOTH forms
  (("IN" :name "India" :dial "+91" :currency "INR"
        :tax-label "GSTIN" :tax-validator :india-gstin :tax-required-if-domestic t
        :secondary-label "PAN" :secondary-validator :india-pan
        :region-label "State" :regions *NSTGSTSTATECODES-HT*
        :postal-regex "^[1-9][0-9]{5}$" :fy-basis :apr-mar)
   ("AE" …) ("US" …) …)
```

- The form **renders and validates from the profile**: adding a country becomes a data entry plus a
  validator function, not a controller change. Same mechanism for the customer form (its GSTIN/billing
  block is currently discarded exactly like the vendor's).
- **Generic tax identity columns** (small migration): `TAX_ID`, `TAX_ID_TYPE`, `TAX_REGION_CODE`. The
  India profile writes **both** the generic columns and the legacy `GSTNUMBER` / `GST_STATE_CODE` /
  `PAN_NUMBER`, so nothing that reads the legacy columns breaks.
- **`COUNTRY` becomes ISO-3166 alpha-2** (the free-text name stays for display). `DOD_CURRENCY` gains an
  ISO column, or is superseded by a `DOD_COUNTRY` master that carries currency, dial code, postal rule
  and the tax-id label — the currency lookup then keys on ISO rather than on "America".
- **Regions** become a master (`country_code, region_code, name`), seeded from
  `*NSTGSTSTATECODES-HT*` for IN, so `REGION`/`tax region` is no longer India-shaped.

**🚨 The cross-border rule, which is the real design point.** A **GSTIN is only meaningful when the
vendor's country equals the store's country.** A foreign vendor joining an Indian store has no GSTIN at
all — that supply is an **import** (reverse charge, no ITC as a normal purchase, e-way bill and IGST
questions of their own). So the profile carries `:tax-required-if-domestic` and the form must *relax* the
tax-id requirement when the countries differ, capture the foreign id (VAT/Tax ID) in `TAX_ID`, and flag
the party so downstream documents can behave differently. A form that hard-requires GSTIN globally would
lock every cross-border vendor out on day one.

**Phasing**
- **G1 — with phase 1 of §4b:** ISO `COUNTRY` dropdown on both forms (default = the store's country),
  the profile table with the **IN** entry, the three generic columns, and India writing both generic and
  legacy fields. No behaviour change for existing rows (`COUNTRY` NULL/'' reads as the store's country).
- **G2 — with the first non-India entity:** `DOD_COUNTRY` + regions master, currency by ISO, amount-in-
  words dispatcher, and a currency column on documents when cross-border documents become real.

## 5. Blockers to clear before the template that depends on them

| # | Blocker | Affects | Evidence |
|---|---|---|---|
| B1 | **Reject is broken at runtime.** `reject-vendor` reads `(slot-value companyadmin 'phone)` (`vendor/dod-bl-ven.lisp:38`) but the user class declares only `phone-mobile`, `phone-home`, `phone-office` (`sysuser/dod-dal-usr.lisp:36-44`). Reading a missing slot signals; the approve path correctly reads `phone-mobile` (`dod-bl-ven.lisp:24`). | E4 | Read 2026-10-17. **Not executed** — confirm against the image before touching it. |
| B2 | **There is no field to hold a rejection reason**, and `reject-vendor` writes `approval-status` only. | E4 | `dod-bl-ven.lisp:36-46` |
| B3 | ~~No helper returns "the admin emails for a tenant"~~ — **DONE 2026-10-18**: `select-compadmin-emails-for-tenant` (`sysuser/dod-bl-usr.lisp`). Caveat kept on purpose: the live tenants' admin addresses are `…@example.com` placeholders except tenant 2's second row. | E2 | measured 2026-10-17, built 2026-10-18 |
| B4 | **A vendor can never use a password** — registration sets none (`customer/dod-ui-cus.lisp:1626-1640`), so any "use your password" copy is false. | E1, E3 | code + `PENDING-WORK-CONTEXT.md` §1 |
| B5 | **Re-registration after a rejection hits the unique key** `UC_Vendor (PHONE, TENANT_ID)` with no `handler-case` → 500. | E4's "re-apply" instruction | measured `SHOW INDEX FROM DOD_VEND_PROFILE`, 2026-10-17 |
| B6 | 🚨 **FIXED 2026-10-18 — approving a vendor 500s with `the slot VND-PHONE is missing from the object #<VENDOR>`.** `dod-bl-ven.lisp` defined `copyvendor-dbtodomain` / `copyvendor-domaintodb`; `nst-bl-vnd.lisp` defines `copyVendor-dbtodomain` / `copyVendor-domaintodb` — **the same symbols, CL being case-insensitive** — and `nstores.asd` loads `nst-bl-vnd` (line 230) *after* `dod-bl-ven` (229), so the new layer's functions silently replaced the legacy ones. The approval path then handed a legacy `Vendor` object to a copier written for `nst-vnd` and it died on the first `vnd-`-prefixed slot. Fix: the legacy pair is renamed `dod-copyvendor-dbtodomain` / `dod-copyvendor-domaintodb` (6 references in that one file). | all approve/reject work; E3 | measured 2026-10-18, error from `/hhub/hhubvendorapproveaction`, `copyvendor-dbtodomain` in the backtrace. **The scan for this class is 12 lines** — every `defun`/`defmacro` name, case-folded, defined in both a `dod-*` and an `nst-*` file; it found **3**: these two (now fixed) and `process-file` (`dod-bl-utl.lisp` vs `nst-bl-domainsurvey.lisp`, **still open**). |
| B7 | 🚨 **FIXED 2026-10-19 — the first login of a new vendor 500s: `The slot COM.NSTORES.APP::TRUTH is unbound in #<BO-KNOWLEDGE>`.** `VPaymentMethodsService.doread` assigned `(bo-knowledge service)` **only on `:T`**, so a vendor with no `DOD_VPAYMENT_METHODS` row — which registration never creates — left the adapter holding `bo-knowledge`'s **unbound** default `truth`; the login path calls it from `addloginvendorsettings` (`dod-ui-ven.lisp:2541`). Fix: `truth` defaults to `+unknown+` (`nst-bl-beltrusys.lisp`) **and** `doread` propagates the DB knowledge unconditionally, so such a vendor reads `:F` = none configured. **E3 must not promise a working login until this is live** — it blocked the very moment the approval flow started working. | all of first-login; E3 | measured 2026-10-19 from the live 500; mechanism in `../knowledge/belnap-four-states-CONTEXT.md` §17 |
| B8 | 🚨 **FIXED 2026-10-19 — creating the first invoice 500s with `There is no applicable method for GETEXCEPTIONSTR … (#<TYPE-ERROR expected-type: LIST datum: UNDEFINED>)`.** A NULL `DOD_VEND_PROFILE.INVOICE_SETTINGS` reads back as the class's `:void-value "undefined"` (`dod-dal-ven.lisp:360-363`) **and an `update-records-from-instance` writes that string back into the column** — measured: vendors 24/25 hold the literal text `undefined` (9 bytes) while 17/18/19 hold the 2,716-byte seed. Login then stores `(read-from-string "undefined")` = the **symbol** in `:login-vendor-invoice-settings` (`dod-ui-ven.lisp:2508`) and the invoice page maps over it → `TYPE-ERROR LIST`. Fix: `read-invoice-settings-blob` (`dod-ui-ven.lisp`) parses only a real list, `*read-eval*` bound to NIL, everything else falls back to `*invoice-settings*`; plus a `GetExceptionStr` method on `condition` (`dod-bl-err.lisp`) so this class of error **reports itself** instead of raising NO-APPLICABLE-METHOD. **Root fix DONE 2026-10-19:** the `VEN` branch now creates the vendor with `:invoice-settings (nst-invoicesettings-seed-string)`. The three seed definitions live in `invoice/templates/invoicesettings.lisp` (loaded by every image) — the same `*nst-invoicesettings-print-defaults*` / `nst-invoicesettings-seed` / `nst-invoicesettings-seed-string` the backfill migration carries, so a created row has the **same shape as a migrated or saved one** (keyword keys, print section first). The migration file is deliberately untouched because it must also run standalone; its literals are kept in step by hand. The defensive `read-invoice-settings-blob` stays as the guard for rows that are already poisoned. | first invoice of every new vendor | measured 2026-10-19 on `DOD_VEND_PROFILE`; error from `/hhub/createinvoiceheader` |

## 6. Build order (one step per session, confirmed before starting)

1. **B4/B5 review** — decide whether E4 promises "re-apply" at all. If reject cannot be made safe cheaply, E4 says "contact the administrator", not "register again".
2. ~~**E1 + E2**~~ — **DONE 2026-10-17/18**, committed as `57e4e29`. The vendor is told it is waiting; the tenant's `COMPADMIN` addresses are told to approve. **Verified end to end 2026-10-19**: E1 lands in the vendor's inbox and E2 in the tenant administrator's, each in its own session.
3. ~~**E3**~~ — **DONE 2026-10-21**: `vend-approved.html` + sender + hook after `db-save`; the copy uses tax/payment, not bank.
4. **E5** — the status lookup, which also gives E1 its button and the login page its escape hatch.
5. ~~**B1 + B2 → E4**~~ — **DONE 2026-10-21**: `phone` → `phone-mobile`, a rejection-reason column + modal field, `vend-rejected.html` + sender.
6. **First-login UX** (FLOWS §5–§6): ~~login-page states~~ **DONE 2026-10-21** (pending/rejected/stranded/no-row); the dashboard checklist is still open.
7. **E7** — wire the existing, orphaned `vendor-order.html` after deleting its stray "Thanks for registering" line.
8. **E6** — only if a scheduler appears.

## 7. File map

| Concern | Where |
|---|---|
| Vendor row, approval columns, unique key | `DOD_VEND_PROFILE`; `UC_Vendor (PHONE,TENANT_ID)` |
| Vendor create (both personas' shared form) | `hhub/customer/dod-ui-cus.lisp:1598-1720` |
| Vendors' welcome mail today | `hhub/email/templates/registration.lisp:146` → `cust-reg.html` |
| Login gate (both halves) | `hhub/vendor/dod-ui-ven.lisp:2419`, `:2446` |
| Login page | `hhub/vendor/dod-ui-ven.lisp` (OTP login page), route `sysuser/dod-ui-sys.lisp:1132` |
| Approve / reject (BL) | `hhub/vendor/dod-bl-ven.lisp:17-46` |
| Approval queue (UI) | `hhub/sysuser/dod-ui-cad.lisp:43-59`, `472-535` |
| Dashboard home (to gain the checklist) | `hhub/vendor/dod-ui-ven.lisp:2885`, `3026` (`render-vendor-dashboard-home`) |
| Nav bar / vendor surface | `hhub/vendor/dod-ui-ven.lisp:2360-2384` |
| Template constants | `hhub/core/dod-ini-sys.lisp:42-48` |
| All email senders | `hhub/email/templates/registration.lisp` |
| Token substitution precedent + NIL trap | `../nil-safe-template-substitution-CONTEXT.md` |

## 8. Two deployment modes — marketplace vs dedicated portal

A B2B buyer has two choices, and the code treats both the same way: the approving `COMPADMIN` is whichever company owns the vendor's `TENANT_ID`.

| Mode | Tenant / store | Company administrator | Approves |
|---|---|---|---|
| Marketplace | a Nine Technologies store (e.g. Nine Stores Bakery) | a Nine Technologies employee | vendors, products and customers for that store |
| Dedicated | a new company row (e.g. ACME Bakery Procurement Portal) | the buyer's own employee, profile provisioned by Nine Technologies | its own vendors, products, customers and categories |

E2, E3, the vendor queue, the product queue and the post-signup admin-contact block are all tenant-scoped, so no template or sender hardcodes Nine Technologies. The dedicated portal needs a real `COMPADMIN` email and phone; a placeholder makes E2 and the contact block point at nobody.

## 9. Status at close — 2026-10-21

Built: E1–E4; the signup document prefix moved to warned profile dialogs; the post-signup pending page; the NULL-`APPROVAL_STATUS` product-approval fix; the login-page four states (pending/rejected/stranded/no-row).

Open: E5 (status lookup), the dashboard checklist, E7, E6, and tenant-scoped vendor identity.

The rejection reason needs `21102026-vendor-rejection-reason` applied **before** the build: `REJECTION_REASON` is mapped on `dod-vend-profile`, so a build without the column breaks every vendor select.

Non-negotiable still open: tenant-scoped vendor identity (`(phone, tenant)`). The rejection leg and the login-state panels are built; the legacy login is still phone-only across tenants, which matters for the dedicated-portal mode.
