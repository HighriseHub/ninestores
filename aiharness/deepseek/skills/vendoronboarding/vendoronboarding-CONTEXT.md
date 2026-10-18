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

## 5. Blockers to clear before the template that depends on them

| # | Blocker | Affects | Evidence |
|---|---|---|---|
| B1 | **Reject is broken at runtime.** `reject-vendor` reads `(slot-value companyadmin 'phone)` (`vendor/dod-bl-ven.lisp:38`) but the user class declares only `phone-mobile`, `phone-home`, `phone-office` (`sysuser/dod-dal-usr.lisp:36-44`). Reading a missing slot signals; the approve path correctly reads `phone-mobile` (`dod-bl-ven.lisp:24`). | E4 | Read 2026-10-17. **Not executed** — confirm against the image before touching it. |
| B2 | **There is no field to hold a rejection reason**, and `reject-vendor` writes `approval-status` only. | E4 | `dod-bl-ven.lisp:36-46` |
| B3 | ~~No helper returns "the admin emails for a tenant"~~ — **DONE 2026-10-18**: `select-compadmin-emails-for-tenant` (`sysuser/dod-bl-usr.lisp`). Caveat kept on purpose: the live tenants' admin addresses are `…@example.com` placeholders except tenant 2's second row. | E2 | measured 2026-10-17, built 2026-10-18 |
| B4 | **A vendor can never use a password** — registration sets none (`customer/dod-ui-cus.lisp:1626-1640`), so any "use your password" copy is false. | E1, E3 | code + `PENDING-WORK-CONTEXT.md` §1 |
| B5 | **Re-registration after a rejection hits the unique key** `UC_Vendor (PHONE, TENANT_ID)` with no `handler-case` → 500. | E4's "re-apply" instruction | measured `SHOW INDEX FROM DOD_VEND_PROFILE`, 2026-10-17 |
| B6 | 🚨 **FIXED 2026-10-18 — approving a vendor 500s with `the slot VND-PHONE is missing from the object #<VENDOR>`.** `dod-bl-ven.lisp` defined `copyvendor-dbtodomain` / `copyvendor-domaintodb`; `nst-bl-vnd.lisp` defines `copyVendor-dbtodomain` / `copyVendor-domaintodb` — **the same symbols, CL being case-insensitive** — and `nstores.asd` loads `nst-bl-vnd` (line 230) *after* `dod-bl-ven` (229), so the new layer's functions silently replaced the legacy ones. The approval path then handed a legacy `Vendor` object to a copier written for `nst-vnd` and it died on the first `vnd-`-prefixed slot. Fix: the legacy pair is renamed `dod-copyvendor-dbtodomain` / `dod-copyvendor-domaintodb` (6 references in that one file). | all approve/reject work; E3 | measured 2026-10-18, error from `/hhub/hhubvendorapproveaction`, `copyvendor-dbtodomain` in the backtrace. **The scan for this class is 12 lines** — every `defun`/`defmacro` name, case-folded, defined in both a `dod-*` and an `nst-*` file; it found **3**: these two (now fixed) and `process-file` (`dod-bl-utl.lisp` vs `nst-bl-domainsurvey.lisp`, **still open**). |

## 6. Build order (one step per session, confirmed before starting)

1. **B4/B5 review** — decide whether E4 promises "re-apply" at all. If reject cannot be made safe cheaply, E4 says "contact the administrator", not "register again".
2. **E1 + E2** together — the moment a row exists, the vendor is told and the admin is asked. This is the pair that removes the silent wait.
3. **E3** — the approval mail; needs the login URL and nothing else.
4. **E5** — the status lookup, which also gives E1 its button and the login page its escape hatch.
5. **B1 + B2 → E4** — reject must be fixed and given a reason before it can be announced.
6. **First-login UX** (FLOWS §5–§6): login-page states, then the dashboard checklist.
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
