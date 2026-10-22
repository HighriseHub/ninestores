# vendoronboarding — the email template catalogue (E1–E7)

**Read this when:** you are writing, wiring or reviewing a vendor onboarding email — "which mail
goes out when", "what tokens does this file take", "who is the recipient", "why hasn't the vendor
been told".

> **Status: E1–E5 BUILT (2026-10-22). E6 is phase 2; E7 exists but is still orphaned.**
> Companion to `vendoronboarding-CONTEXT.md` (decisions D1–D7) and `vendoronboarding-FLOWS.md` (where each mail sits in the journey).

---

## 1. Mechanics every template in this folder shares

- **File:** `hhub/email/templates/<name>.html`, self-contained — header, inline `<style>`, body,
  footer. Start from an existing file (they are ~14 KB of chrome) and replace the body between
  its markers; do **not** use the Lisp `with-single-column-email` shell — its CSS variable is
  `NIL` (`core/dod-ini-sys.lisp:35`), so it mails an unstyled page.
- **Constant:** one per file, in `hhub/core/dod-ini-sys.lisp:42-48`, named
  `*HHUB-<PERSONA>-<PURPOSE>-TEMPLATE-FILE*`.
- **Tokens:** `%Named Token%`, filled by one helper (§2). Never `format` (D1).
- **Sender:** appended to `hhub/email/templates/registration.lisp` (D2), named
  `send-vendor-<event>-email`, and it **must** go out through `send-email-async`
  (`registration.lisp:173`) — never `hhubsendmail` on the request thread.
- **Subject:** starts with the outcome, not the brand: "Approved — …", "Waiting for approval — …".
- **Body order, always:** state → what it means → what you do → what happens next / who holds it
  → one button → escape hatch (support + registered phone/email).
- **No password language, anywhere** (B4). The door is phone + OTP, every time.
- A send failure is silent to the caller (actor + dead letter). Anything user-visible that
  depends on a mail must also say the same thing on screen.
- **Every sender writes an audit line before it queues** (`hhub-log-message`, 2026-10-18):
  `[vendor-onboarding] E1 -> <address> (vendor …, tenant …)` and `E2 -> (<addresses>)`. Without it
  a "the mail went to the wrong inbox" report is unanswerable — only failures were logged, and the
  relay is AWS SES, whose rejections are silent. Read it with
  `sudo tail -40 /home/hunchentoot/hhublogs/ninestores-busfunctions.log | grep vendor-onboarding`.

## 2. The substitution helper — the invoice pattern, adapted (D1, revised 2026-10-17)

Invoice templates are filled by **`invoicetemplatefill`** (`invoice/nst-ui-ihd.lisp:1326`): one
`cl-ppcre:regex-replace-all` per `%Named Token%`, **string** replacement, every value guarded with
`(or x "")` or `(nst-slot-str obj 'slot)`, `/P` (line rows) built from a marked snippet block. The
email helper is the same shape, minus the row block (no vendor email has line rows yet):

```
(defun hhub-fill-email-template (template replacements)
  :documentation "Replace every (\"%Token%\" . VALUE) in TEMPLATE, in list order, the way invoicetemplatefill fills an invoice template. VALUE may be any printable or NIL."
  (dolist (pair replacements template)
    (let ((value (cdr pair)))
      (setf template (cl-ppcre:regex-replace-all (car pair) template
					 (if value (princ-to-string value) ""))))))
```

- Lives in `hhub/email/templates/registration.lisp`, above the senders. Callers pass an ordered
  `((token . value) …)` alist; order only matters if one token's text can contain another's name.
- **The guard is the point.** A `NIL` handed to `cl-ppcre` *as the replacement* is called as a
  function — `The function COMMON-LISP:NIL is undefined`
  (`../../knowledge/nil-safe-template-substitution-CONTEXT.md`). Passing a string always (or `""`)
  is what makes an unset GST number or a missing phone safe.
- `princ-to-string` means numbers and dates go in without pre-formatting; anything that needs a
  format (money, dates) is formatted **at the call site**, as `invoicetemplatefill` does.
- **2026-10-23 — the whole folder is cached at boot.** `nst-load-email-templates` (`dod-ini-sys.lisp:624`)
  scans `hhub/email/templates/*.html`; every sender now calls `nst-cached-email-template` (per-send
  fallback when the cache is down). A copy edit needs an image restart — accepted deliberately.
- **Rule for every new template file:** a `<!-- tokens: … -->` comment at the top listing every
  token it uses, so a reviewer can check the alist without reading the whole HTML.

## 3. Catalogue

Every row's "Needs" column is what must exist before the mail can be truthful.

### E1 — `vend-registered.html` · "we have you, here is what is happening"

**Status: BUILT 2026-10-17; status link added 2026-10-22** — file + constant `*HHUB-VENDOR-REGISTERED-TEMPLATE-FILE*` (`core/dod-ini-sys.lisp:49`) + sender `send-vendor-registered-email` (`registration.lisp:161`) + call site swapped for the legacy mail in the `VEN` branch (`customer/dod-ui-cus.lisp:1695-1700`), and queued with `:persona :vendor`.

| | |
|---|---|
| Trigger | end of the `VEN` branch of `com-hhub-transaction-customer&vendor-create`, replacing `send-registration-email` (`customer/dod-ui-cus.lisp:1700`) |
| To | `DOD_VEND_PROFILE.EMAIL` |
| Subject | `Registration received - %CompanyName% on Nine Stores` |
| Tokens | `%VendorName% %CompanyName% %VendorPhone% %VendorEmail% %StatusUrl% %SupportEmail%` |
| Needs | nothing (all values are in the row just inserted) |
| **Status link** | `%StatusUrl%` opens `/hhub/hhubvendloginv2?status=1`, which expands the login page's "Email me my status" form (E5). |

Body as built (kept here so spec and artifact cannot drift):

```
Registration received - %CompanyName%                    ← the state, in the heading

Hi %VendorName%, your vendor registration with %CompanyName% on Nine
Stores has been received. This email is your receipt - please keep it.
Nothing else is needed from you today.

  What we have on file
  Store: %CompanyName%
  Phone: %VendorPhone%
  Email: %VendorEmail%

What happens next
1. %CompanyName%'s administrator reviews your registration.
2. We email you the moment it is approved.

You cannot sign in until step 1 is complete. There is nothing to do on
your side right now.

Something above looks wrong? Reply to this email or write to %SupportEmail%.
```

**Why these words:** the vendor's first question is "can I log in now?", so the mail answers it
before they discover it on a bounced login; and "this email is your receipt" tells them what to
keep without inventing a reference number (D3).

### E2 — `vend-admin-pending.html` · "someone is waiting on you"

**Status: BUILT 2026-10-18** — file + constant `*HHUB-VENDOR-ADMIN-PENDING-TEMPLATE-FILE*`
(`core/dod-ini-sys.lisp:50`) + helper `select-compadmin-emails-for-tenant`
(`sysuser/dod-bl-usr.lisp`, the first code in the tree to read `DOD_USERS.EMAIL` for a
notification) + sender `send-vendor-admin-pending-email` (`registration.lisp`, queued with
`:persona :admin`, which brought up the **Company Admin Email Actor**) + call site immediately
after E1 in the `VEN` branch (`customer/dod-ui-cus.lisp:1701-1703`). Compile-verified; not yet
loaded into the running image.

| | |
|---|---|
| Trigger | same call site as E1, immediately after it |
| To | every `COMPADMIN` user of the vendor's tenant with a non-empty `EMAIL` (B3 helper) |
| Subject | `Approval needed — %VendorName% registered as a vendor` |
| Tokens | `%VendorName% %VendorPhone% %VendorEmail% %GSTINLine% %CompanyName% %QueueUrl% %PendingCount%` |
| Verified | **E2 arrives in the admin's inbox, 2026-10-19** (two separate Guerrilla sessions; E1 to the vendor, E2 to the tenant's `COMPADMIN`) |
| Needs | **B3 — DONE**: `select-compadmin-emails-for-tenant` returns the distinct non-empty `DOD_USERS.EMAIL` of the tenant's `COMPADMIN` role holders. ⚠ Delivery depends on that address being real: the live tenants still carry `…@example.com` placeholders (tenant 2's second admin row is a real mailbox), and a bounce is silent — the actor dead-letters SMTP failures, nothing reports them. |

```
%VendorName% has registered as a vendor with %CompanyName%.
Phone %VendorPhone% · %VendorEmail% · %GSTINLine%

They cannot sign in until you approve. %VendorCount% vendors are waiting.

[ Review and approve ]    ← %QueueUrl% = /hhub/hhubvendorapprovalpage
```

Send **one mail per registration**, never a digest, until a digest exists — the latency is the bug.

### E3 — `vend-approved.html` · "you are live, and here is the whole job"

**Status: BUILT 2026-10-21** — template + `*HHUB-VENDOR-APPROVED-TEMPLATE-FILE*` + `send-vendor-approved-email`, queued after `db-save` in `doupdate`.

| | |
|---|---|
| Trigger | `doupdate` for `VendorApprovalService` (`vendor/dod-bl-ven.lisp`), after `db-save` |
| To | `DOD_VEND_PROFILE.EMAIL` |
| Subject | `Approved - you can sign in to %CompanyName%` |
| Tokens | `%VendorName% %CompanyName% %VendorPhone% %ApprovedDate% %LoginUrl% %SupportEmail%` |
| Needs | nothing new; the copy uses tax/payment, not bank |

```
%VendorName%, you are approved by %CompanyName% on %ApprovedDate%.
Sign in with %VendorPhone% and the one-time code we SMS you - there is no password.

Finish these three, then you can take orders:
1. Tax and payment details - GSTIN and PAN print on every invoice; your UPI payout route tells us where to remit.
2. Your first product - customers can only order what is listed.
3. Where you ship - set your zones and charges.

[ Sign in and finish setup ]    <- %LoginUrl%
```

The three items are the dashboard checklist (`vendoronboarding-FLOWS.md` §6) grouped into tax/payment, first product and shipping.

### E4 — `vend-rejected.html` · "no, and here is why, and what to do"

**Status: BUILT 2026-10-21** — B1 fixed (`phone` → `phone-mobile`), B2 added (`REJECTION_REASON`), B5 avoided (no self-service re-apply promise), template + `*HHUB-VENDOR-REJECTED-TEMPLATE-FILE*` + `send-vendor-rejected-email`, queued from `reject-vendor` after the row update.

| | |
|---|---|
| Trigger | `reject-vendor` (`vendor/dod-bl-ven.lisp`), after the row update |
| To | `DOD_VEND_PROFILE.EMAIL` |
| Subject | `Not approved - your vendor registration with %CompanyName%` |
| Tokens | `%VendorName% %CompanyName% %ReasonLine% %AdminContactLine% %SupportEmail% %ReapplyLine%` |
| Needs | **DONE**: B1/B2; B5 avoided |

```
%CompanyName% has not approved your vendor registration.

Reason: %ReasonLine%          <- "Not given" when the administrator left it blank
%AdminContactLine%            <- the rejecting administrator's name, email and phone
%ReapplyLine%                 <- "Contact the administrator..." (no self-service re-apply)
Need help? %SupportEmail%
```

The reason column requires `21102026-vendor-rejection-reason` applied before the build.

### E5 — `vend-status.html` · the escape hatch, and E1's button

**Status: BUILT 2026-10-22** — login-page `<details>` form, `POST /hhub/hhubvendstatusmail`, in-memory rate limit (10 min per phone), E1 `%StatusUrl%` link, template + sender.

| | |
|---|---|
| Trigger | `POST /hhub/hhubvendstatusmail` from the login page ("Email me my status") and from E1 |
| To | **the vendor's registered email**, never echoed into the page |
| Subject | `Your %CompanyName% registration status` |
| Tokens | `%VendorName% %CompanyName% %StateLine% %NextStepLine% %ActionBlock% %SupportEmail%` |
| Needs | **DONE**: controller + route + template + sender; pending re-notifies E2; no-row or no-email sends nothing |

| Row state | `%StateLine%` | `%NextStepLine%` |
|---|---|---|
| `N/PENDING` | "Waiting for approval by %CompanyName%." | "The company administrator has been re-notified; nothing else is needed from you right now." |
| `Y/APPROVED` | "Approved. You can sign in now." | `%ActionBlock%` → login URL |
| `N/REJECTED` | "Not approved by %CompanyName%." | contact the administrator (see E4) |
| `Y/PENDING` (stranded) | "Approved, but the account is not fully activated." | "We have flagged this to %SupportEmail%; reply with your phone number." |
| no row / no email | no mail | the page sentence is unchanged |

The page response is always the same sentence ("If that number is registered, we have emailed the status") — that is what keeps this from becoming a phone-number oracle. Rate-limit per phone; only a row with an email gets a mail.

### E6 — `vend-kyc-nudge.html` · phase 2 (needs a scheduler, D7)

| | |
|---|---|
| Trigger | +3 days and +7 days after approval, while GSTIN / PAN / bank are empty |
| To | vendor |
| Subject | `%MissingCount% quick details before your first order` |
| Tokens | `%VendorName% %CompanyName% %MissingList% %ProfileUrl%` |
| Needs | a scheduled job — **not built**, and not worth inventing for this |

Phase 1 puts the identical message on the dashboard checklist, where a human is already looking.

### E7 — `vendor-order.html` · exists, orphaned, must be wired

| | |
|---|---|
| File | `hhub/email/templates/vendor-order.html` — **no constant, no caller** today |
| Trigger | order creation, vendor channel (`order/dod-bl-ord.lisp:582` already calls `send-order-mail` with a one-argument body) |
| Fix first | delete the stray `Thanks for registering ~A.` line that sits above `Order Details: ~A`; the file has two `~A` and the caller supplies one |
| Tokens after conversion | `%OrderNumber% %BuyerName% %OrderTotal% %LineTable% %OrderUrl%` |
| Also | decide: to the vendor's email, or to every vendor user? Today only one address is known |

This is the mail that closes the loop opened by E3 — approval is only useful if the next message
a vendor reads is an order.

---

## 4. Order of arrival, for review sanity

```
register ──► E1 (vendor: "waiting") ──► E2 (admin: "act")
admin approves ──► E3 (vendor: "live + 3 jobs")
admin rejects  ──► E4 (vendor: "why + who")
vendor lost    ──► E5 (vendor: "your state, now")   ← available at any point
vendor ordered ──► E7 (vendor: "work to do")
day 3 / day 7  ──► E6 (vendor: "still missing X")   ← phase 2
```

## 5. Template-by-template build checklist

For each mail, in this order, or it does not ship:

1. `.html` file in `hhub/email/templates/`, self-contained, with a `<!-- tokens: … -->` comment at
   the top listing every `%Token%` it uses.
2. Constant in `dod-ini-sys.lisp` next to the other six.
3. `send-vendor-…-email` in `registration.lisp`, using `nst-fill-tokens` + `send-email-async`,
   with a `handler-case` that logs and returns NIL so a mail failure cannot roll back the row.
4. Call site, inside the existing `with-hhub-transaction` where there is one.
5. Read the rendered string once (REPL or a scratch defun) and confirm no `%Token%` survived and
   no `NIL` printed. An unreplaced token or a stray `NIL` in body copy is the failure mode of this
   whole mechanism.
