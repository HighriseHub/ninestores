# onboarding-journeys — how a buyer, a vendor and a company administrator actually get in

**Read this when:** you are adding or changing an **onboarding email** (welcome,
pending, approved, rejected, KYC nudge), tracing **why a newly registered vendor cannot
log in**, wondering **who approves whom** after signup, or asking *"what does a new
customer/vendor/admin receive, in what order, from which function?"*

> **Scope:** the three personas named in the brief — CUSTOMER (buyer), VENDOR (seller),
> COMPANY ADMINISTRATOR (the approver and tenant requester) — plus the tenant (company)
> step that both personas silently depend on.
> **Status: LIVE CODE + EMAIL WORK IN FLIGHT.** Everything below was read from source and
> measured against `hhubdb` on **2026-10-17**. The proposed template set (§9) is NOT
> built. Line numbers were checked that day.

---

## 1. The one-paragraph shape

Registration is **store-scoped and OTP-only**. A person lands on `/`, picks a *store*
(a `DOD_COMPANY` tenant) out of a **public directory**, fills one form that serves both
personas (`reg-type = CUS | VEN`), proves the phone by SMS OTP, and a row is inserted
with **no password** and **`approved-flag "N"` / `approval-status "PENDING"`**. The
customer can log in immediately (nothing gates them). The vendor **cannot** — vendor
login requires `approved_flag='Y'` *and* `approval_status='APPROVED'`, which only a
company administrator's approval click sets. **The vendor is told none of this**: the
only email either persona receives is the legacy `cust-reg.html`, whose copy is a
community-marketplace B2C script, and the approval/rejection pair sends nothing at all.

---

## 2. Personas, entry points, gates

| Persona | Entry | Gate on login | Who releases the gate | Told about the gate? |
|---|---|---|---|---|
| CUSTOMER (buyer) | `/hhub/custsignup1.html` → store directory → form | **none** (phone + `cust-type STANDARD` + `deleted-state`) | itself; `approval-status` stays `PENDING` forever | n/a |
| VENDOR (seller) | same form, `reg-type VEN` | `approved_flag='Y'` **AND** `approval_status='APPROVED'` (`dod-ui-ven.lisp:2419`, `2446`) | company admin click → `dod-bl-ven.lisp:17` `doupdate` | **no** |
| COMPANY ADMIN | needs an existing user row; login `/hhub/cad-login.html` (`dod-ui-sys.lisp:961`) | role + tenant | **super admin** creates the user (`dod-ui-usr.lisp:12`) | **no** |
| (tenant) | `/hhub/hhubnewcompanyreqpage` (`dod-ui-sys.lisp:899`) | n/a — it is a *request*, not a signup | super admin runs `com-hhub-transaction-create-company` (`:834`) | **no** — the request goes to `support@` only |

**The buyer's tenant is a seller's store.** `tenant-id` is taken from the company whose
"Sign Up" card was clicked (`dod-ui-cus.lisp:1618-1620`), and the duplicate-phone check
is per-company (`nst-bl-Customer.lisp:1299`). There is **no buyer-company signup path**
and **no invite primitive** anywhere in the tree — vendors self-register off the public
directory. That is why cross-vendor ordering in the product brief does not yet line up
with what the code lets a buyer do.

---

## 3. CUSTOMER (buyer) — as-is

| # | Step | Code |
|---|---|---|
| 1 | `/` → "Stores" | `site/public/index.html:52` |
| 2 | Public store directory; each card posts `cname` | `dod-ui-cus.lisp:1748` → `account/dod-ui-cmp.lisp:98` |
| 3 | Form: tenant name + address **read-only**, reg-type, name, email, phone; customer block = GSTIN + billing address; reCAPTCHA | `dod-ui-cus.lisp:1426-1596` |
| 4 | Submit → reCAPTCHA → build in session; **GSTIN/billing never read** | `dod-ui-cus.lisp:1598-1680` (param list 1608-1622) |
| 5 | OTP SMS (AWS SNS), 2-min TTL | `dod-ui-sys.lisp:128-147`, `nst-bl-otp.lisp:11` |
| 6 | OTP verify → redirect to `dodcustregisteraction` | `dod-ui-sys.lisp:105-125` |
| 7 | ABAC transaction: insert + **one** email | `dod-ui-cus.lisp:1682-1720`; `send-registration-email` `registration.lisp:146` |
| 8 | OTP login works now, password login cannot (password is NULL) | `dod-ui-cus.lisp:2484`, `3793` |
| 9 | B2B KYC is **post-onboarding and optional**: legal name, industry, GSTIN/PAN/TAN, MSME, credit days/limit, contacts, bank | `dod-ui-cus.lisp:680-800` (`customerprofile.html`) |

## 4. VENDOR (seller) — as-is

| # | Step | Code |
|---|---|---|
| 1-4 | same directory + form; vendor block adds GSTIN, PAN, bank A/C, IFSC — **also discarded** | `dod-ui-cus.lisp:1510-1530`, `1610-1622` |
| 5-6 | OTP as above | `dod-ui-sys.lisp:128` |
| 7 | insert (`sleep 1`) → `create-vendor-tenant` (default-flag "Y") → free shipping method → **customer** welcome email | `dod-ui-cus.lisp:1686-1706`; `dod-bl-ven.lisp:370` |
| 8 | login attempt is **silently bounced** (no message, no reason) | `dod-ui-ven.lisp:2419`, `2446` |
| 9 | admin/company never notified; approval queue is poll-only | `sysuser/dod-ui-cad.lisp:472` |
| 10 | admin approves → `Y / APPROVED / approved_by`; **no email** | `dod-ui-cad.lisp:43` → `dod-bl-ven.lisp:17-33` |
| 11 | admin rejects → `N / REJECTED`; **no email, no reason field** | `dod-ui-cad.lisp:31` → `dod-bl-ven.lisp:36-46` |
| 12 | first real session; vendor KYC via `dodvendprofile` | `dod-ui-ven.lisp:853-900` |

## 5. COMPANY ADMINISTRATOR — as-is

| # | Step | Code |
|---|---|---|
| 1 | Does **not** exist at company creation: "create the Company Administrator" is a **comment, not code** | `dod-ui-sys.lisp:880` |
| 2 | Created only by a super admin (`sadmincreateusers`) | `dod-ui-usr.lisp:12-138` |
| 3 | Tenant request: company + T&C + reCAPTCHA → OTP `purpose "newstore"` → **email to `support@` only** | `dod-ui-sys.lisp:775-830` |
| 4 | Super admin creates the company by hand → `new-dod-company` + a GUEST customer row; requester is never emailed | `dod-ui-sys.lisp:834`; `dod-bl-cmp.lisp:26`; `nst-bl-Customer.lisp:1398` |
| 5 | Approves vendors at `/hhub/hhubvendorapprovalpage` (approve/reject buttons only — **no vendor detail, no GSTIN shown**) | `dod-ui-cad.lisp:472-535`, card at `:492-513` |
| 6 | Approves products separately | `dod-ui-cad.lisp:459`, `dod-bl-cad.lisp:24` |

---

## 6. Text flow chart — registration and the vendor gate

```
/  (site/public/index.html)
├── "Stores" ──► /hhub/custsignup1.html  ── company-search page
│                                   └── directory of ALL non-deleted DOD_COMPANY
│                                        (account/dod-ui-cmp.lisp:98)
│                                        card: [Sign Up]  [Shop Now]  [copy ext URL]
│                                                │ posts cname
│                                                ▼
│                     /hhub/custsignup1action  ── registration form
│                     tenant-name/address READ-ONLY, reg-type = CUS | VEN
│                     name, email, phone, reCAPTCHA
│                     VEN block: GSTIN/PAN/bank/IFSC   ← posted, then DISCARDED
│                     CUS block: GSTIN/billing addr    ← posted, then DISCARDED
│                                                │ POST
│                                                ▼
│                     /hhub/custsignup1step2  (dod-ui-cus.lisp:1598)
│                     recaptcha → object built IN SESSION ONLY
│                     approved-flag "N" · approval-status "PENDING" · password NULL
│                                                │
│                                                ▼
│                     generateotp&redirect → SMS (6-digit, 2-min TTL)
│                                                │
│                                                ▼
│                     /hhub/otppage → hhubotpsubmitaction
│                        match ─► context dodcustregisteraction
│                        miss  ─► "/" (silent, no retry, regenerate removed)
│                                                │
│                                                ▼
│          ┌──────────── com-hhub-transaction-customer&vendor-create ────────────┐
│          │ ABAC with-hhub-transaction (dod-ui-sys.lisp:1012)                    │
│          │                                                                     │
│          │  CUS: insert ──► send-registration-email(cust-reg.html) ──► login    │
│          │  VEN: insert ──► create-vendor-tenant ──► free shipping method      │
│          │       └──► send-registration-email(cust-reg.html) ──► VENDOR LOGIN  │
│          └─────────────────────────────────────────────────────────────────────┘
│                                                │
│                            ┌───────────────────┴────────────────────┐
│                            ▼ CUS                                     ▼ VEN
│              customer LOGIN works                    login filter: approved='Y'
│              (no approval check)                     AND status='APPROVED'
│              status stays PENDING forever                            │
│                                                                      │ NO
│                                                    silently back to /hhub/hhubvendloginv2
│                                                    NO email, NO reason, NO queue notice
│                                                                      │
│                                            admin sees it only if they open
│                                            /hhub/hhubvendorapprovalpage
│                                                                      │
│                    ┌─────────────────────────────────────────────────┤
│                    ▼ APPROVE                                         ▼ REJECT
│        dod-bl-ven.lisp:17 doupdate                      dod-bl-ven.lisp:36
│        Y / APPROVED / approved_by                        N / REJECTED
│        ✗ NO EMAIL SENT                                   ✗ NO EMAIL, NO REASON
│                    │                                                 │
│                    ▼                                                 ▼
│        vendor can log in                                vendor retries forever
│        (finds out by retrying)                          (never told)
```

## 7. Text flow chart — tenant (company) onboarding, and where the admin comes from

```
/hhub/hhubnewcompanyreqpage        (dod-ui-sys.lisp:899)
   └─► hhubnewstorerequeststep2    (dod-ui-sys.lisp:775)  company + T&C + reCAPTCHA
          └─► OTP (purpose "newstore")
                 └─► hhubnewcompreqemailaction (dod-ui-sys.lisp:826)
                        └─► MAIL ──► *HHUBSUPPORTEMAIL* = support@ninestores.in
                                     template: newcompanyrequest.html  (11 x ~A)
                        └─► page: "email sent"  ── requester receives NOTHING
                                    │
                                    │  (human, unscheduled)
                                    ▼
              super admin: com-hhub-transaction-create-company (dod-ui-sys.lisp:834)
                 ├─ new-dod-company            → DOD_COMPANY row        (dod-bl-cmp.lisp:26)
                 ├─ create-guest-customer      → GUEST row, phone 9999999999
                 ├─ "create the Company Administrator"  ← COMMENT, NOT CODE (:880)
                 └─ redirect /hhub/sadminhome   — requester receives NOTHING
                                    │
                                    ▼
              super admin: sadmincreateusers (dod-ui-usr.lisp:12) → admin user + role
                                    │
                                    ▼
              admin logs in /hhub/cad-login.html → approves products, vendors
```

## 8. Email inventory — wired, dead, orphan

Rendering is **file + `format nil`**: the template file is read on every send from
`*HHUB-EMAIL-TEMPLATES-FOLDER*` (`dod-ini-sys.lisp:42`), so every `~A` must have an
argument and **a stray `~` in the HTML breaks the send**. Delivery is asynchronous
(`send-email-async` `registration.lisp:173` on the email actor) — a failure dead-letters
in the log, it never surfaces to the caller or the user.

| Template | Sender (`registration.lisp`) | Args | Wired | Note |
|---|---|---|---|---|
| `cust-reg.html` | `send-registration-email:146` | 1 | **both personas** | HighriseHub B2C community copy; no next step; sent to vendors **before** approval |
| `cust-pass-reset.html` | `send-password-reset-link:112` | 2 (url x2) | yes | legacy feature, kept |
| `temppass.html` | `send-temp-password:119` | 2 (pass, url) | yes | mails a **plaintext** temp password; also the vendor reactivation path |
| `vend-pass-reset.html` | none | 1 | **dead** | body is a copy of `cust-reg.html` — title "New Customer Registration" |
| `vendor-order.html` | none | 2 | **orphan** | no constant, no caller; stray "Thanks for registering ~A" above `~A` order details |
| `newcompanyrequest.html` | `send-new-company-registration-email:126` | 11 | yes → support@ | internal only |
| `contactustemplate.html` | `send-contactus-email:139` | 5 | yes | fine |
| `guestcustorder.html` | `send-order-mail:151` + cached `dod-ini-sys.lisp:617` | 1 | yes | two render paths (`templatenum 1` is the only DB-cached one) |
| *(builder)* `customer-registration-html-content:79` | `send-test-email` only | `(customer verify-url)` | **dead** | a real "Activate Your Account" button with a verify URL and **no production caller** |

Measured 2026-10-17: `EMAIL_ADD_VERIFIED` is empty on **23 of 26** customer rows — email
verification has never run in production.

---

## 9. Open work — the template set to build (NOT built)

> **2026-10-18:** V1 (E1) and V4 (E2) are **built and committed** (`57e4e29`) — see
> `vendoronboarding/` for their copy, wiring, actors and the testing recipe. The rows below stay
> as the original plan; V3/V5 (persona split), V2 (reject), V6–V9 are still open.

Each row = new `.html` + one constant in `dod-ini-sys.lisp:42-48` + one sender defun in
`registration.lisp` + one call site. `V1` is the only one that unblocks a user who is
stranded *today*.

| ID | Template | To | Call site | Args |
|---|---|---|---|---|
| V1 | `vend-approved.html` | vendor | `dod-bl-ven.lisp:17` `doupdate` | name, company, login url |
| V2 | `vend-rejected.html` | vendor | `dod-bl-ven.lisp:36` `reject-vendor` | name, company, reason, support |
| V3 | `vend-registered.html` | vendor | `dod-ui-cus.lisp:1703` (VEN branch) | name, company, "awaiting GSTIN verification" |
| V4 | `vend-pending-admin.html` | company admin | same call site | vendor name, phone, GSTIN, queue url |
| V5 | `cust-welcome-b2b.html` | buyer | `dod-ui-cus.lisp:1712` (CUS branch) | name, company, 3 next steps |
| V6 | `cust-kyc-nudge.html` | buyer | scheduled, GSTIN still null | name, missing fields, profile url |
| V7 | `tenant-request-received.html` | requester | `dod-ui-sys.lisp:826` | name, company, SLA, support |
| V8 | `tenant-activated.html` | requester + admin | `dod-ui-sys.lisp:834` | company, admin login url, next steps |
| V9 | `vend-kyc-nudge.html` | vendor | post-approval, PAN/GSTIN incomplete | name, missing fields, profile url |

---

## 10. Traps (all hit while reading this on 2026-10-17)

1. **`approved-flag` alone is not the login gate** — vendor login demands flag **and**
   `approval_status`. A row can sit at `Y/PENDING` and be permanently locked out.
   Live example: `DOD_VEND_PROFILE.ROW_ID 17`, tenant 5, `approved_by 9999999997`.
2. **`cust-reg.html` serves vendors.** Anything written into it reaches both personas.
3. **Fields on the form are not fields on the row.** GSTIN/PAN/bank/billing are posted by
   `dod-ui-cus.lisp:1510-1542` and never appear in the insert (`:1608-1622`).
4. **No password is ever set at registration.** Password login exists for both personas and
   cannot succeed; OTP is the only door until a reset.
5. **Customers' `approval-status "PENDING"` is dead state** — no UI, no approver, no effect.
   Do not build a "customer approval" email without first deciding whether the gate is real.
6. **The SMS copy and the OTP store disagree**: template text says "Valid for 5 minutes"
   (`core/extkeys.lisp:36`), `*otp-default-ttl*` is **120 s** (`nst-bl-otp.lisp:11`), and
   the page countdown is 2 min. Regenerate was removed (`dod-ui-sys.lisp:95` comment).
7. **An OTP mismatch is silent**: straight to `/`, no message, no retry.
8. **There is no `Nine Store` tenant.** `DOD_COMPANY` = `1 super`, `2 Demo Company`,
   `4 Trial Account`, `5 Basic Account`. The landing "Demo Login" points at tenant 2. Any
   email copy naming "Nine Store" describes something the DB does not contain.
9. **`vend-pass-reset.html` and `vendor-order.html` are decoys** — reading either as the
   current vendor experience is wrong.
10. **Approval tells nobody, on any side** — not the vendor, not the admin at signup, not the
    tenant requester. Every one of those is an email that does not exist.
11. **The two personas have different duplicate handling.** Only the CUS branch pre-checks
    (`duplicate-customerp` → friendly page, `dod-ui-cus.lisp:1645-1652`); the VEN branch has
    none, so a retry is stopped only by the **unique** key `UC_Vendor (PHONE, TENANT_ID)` and
    the insert path has no `handler-case` → a 500, not a message. Measured 2026-10-17.
12. **Customer login is not tenant-scoped.** `dod-cust-login` selects by phone + `cust-type` +
    `deleted-state` only (`dod-ui-cus.lisp:3797`), while registration duplicate-checks *per
    company* — so the same phone joined to two stores resolves to whichever row the DB returns.
13. **Vendor re-registration is the only self-service recovery** and it is the path (11) that
    500s. A stranded vendor has no "resend", no "I already signed up" and no re-approve.

---

## 11. File map

| Concern | File:line |
|---|---|
| Store directory (public list of tenants) | `hhub/account/dod-ui-cmp.lisp:98-122` |
| Registration form + model + widgets | `hhub/customer/dod-ui-cus.lisp:1426-1596` |
| Session build + reCAPTCHA + OTP redirect | `hhub/customer/dod-ui-cus.lisp:1598-1680` |
| Insert (both personas), tenant, free shipping | `hhub/customer/dod-ui-cus.lisp:1682-1720` |
| OTP generate / page / verify / store TTL | `hhub/sysuser/dod-ui-sys.lisp:128-147`, `:34-125`; `hhub/core/nst-bl-otp.lisp:11` |
| Customer OTP + password login | `hhub/customer/dod-ui-cus.lisp:2484`, `3793` |
| Customer B2B KYC update | `hhub/customer/dod-ui-cus.lisp:680-800` |
| Vendor OTP + password login (the gate) | `hhub/vendor/dod-ui-ven.lisp:2419-2450` |
| Vendor approve / reject (BL) | `hhub/vendor/dod-bl-ven.lisp:17-46` |
| Vendor approval queue (UI) | `hhub/sysuser/dod-ui-cad.lisp:43-59`, `472-535` |
| Tenant request → support mail | `hhub/sysuser/dod-ui-sys.lisp:775-830` |
| Tenant create (super admin) | `hhub/sysuser/dod-ui-sys.lisp:834`; `hhub/account/dod-bl-cmp.lisp:26` |
| Admin user creation | `hhub/sysuser/dod-ui-usr.lisp:12-159` |
| Email senders + template constants | `hhub/email/templates/registration.lisp:105-181`; `hhub/core/dod-ini-sys.lisp:42-48` |
| Routes | `hhub/sysuser/dod-ui-sys.lisp:899-902`, `943`, `961`, `1010-1014`, `1048-1050`, `1074-1132` |
