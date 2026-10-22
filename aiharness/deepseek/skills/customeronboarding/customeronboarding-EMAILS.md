# customeronboarding — the C1–C4 email catalogue

**Read this when:** you are writing, wiring or reviewing a B2B buyer onboarding email — "which mail
goes out when", "what tokens", "who approves", "why did the buyer get nothing".

> **Status 2026-10-23: C1 BUILT and sending-path wired; C2–C4 SPEC ONLY.** The approval endpoints
> C3/C4 will fire from are not built yet — see `customeronboarding-ADMIN-API.md` §10.
> Scope was narrowed to the customer slice: vendors/products/categories/profile are out.

---

## 1. Mechanics (differs from the vendor catalogue in two places)

- **Cached, not read per send (2026-10-23).** `nst-load-email-templates` scans
  `hhub/email/templates/*.html` at boot and senders use `nst-cached-email-template`. Editing copy
  therefore needs an **image restart**. Deliberate: these mails are stable.
- **Actor:** `:customer` — "Customer Email Actor" (`core/nst-server-context.lisp`), responsible for
  onboarding **and** customer order mail. It exists; C7 does not yet.
- Constant + sender + audit line follow the vendor pattern exactly:
  `*HHUB-CUSTOMER-REGISTERED-TEMPLATE-FILE*`, `[customer-onboarding] C1 -> <address>` in
  `ninestores-busfunctions.log`, and `send-email-async … :persona :customer`.
- Copy shape is E1's: state → what it means → what you do → who holds it → escape hatch. **One**
  button, and only when the buyer can act.

## 2. Catalogue

### C1 — `cust-registered.html` · "we have you, someone must approve"

**Status: BUILT 2026-10-23** — template + constant + `send-customer-registered-email`
(`email/templates/registration.lisp:161`) + call site replacing the legacy B2C welcome in the CUS
branch (`customer/dod-ui-cus.lisp:1867`). Not yet mail-tested; needs a reload/restart.

| | |
|---|---|
| Trigger | end of the CUS branch of `com-hhub-transaction-customer&vendor-create`, after `update-records-from-instance` |
| To | `DOD_CUST_PROFILE.EMAIL` |
| Subject | `Registration received - %CompanyName% on Nine Stores` |
| Tokens | `%CustomerName% %CompanyName% %CustomerPhone% %CustomerEmail% %SupportEmail%` |
| Needs | nothing; every value is in the row just inserted |
| **No status link** | E1 can link E5; there is no buyer status page, so C1 deliberately has no button. Add `%StatusUrl%` only when one exists. |

Body: heading `Registration received - %CompanyName%`; "your business account … has been received.
This email is your receipt"; account table (store/phone/email); next steps (1 administrator reviews,
2 we email you on approval, **you cannot sign in until then**, no password — phone + one-time code);
escape hatch to `support@ninestores.in`.

### C2 — `cust-admin-pending.html` · "someone is waiting on you" (NEXT)

| | |
|---|---|
| Trigger | same call site as C1, immediately after it |
| To | tenant `COMPADMIN` emails — reuse `select-compadmin-emails-for-tenant` (`sysuser/dod-bl-usr.lisp`) |
| Subject | `Approval needed — %CustomerName% wants to buy from %CompanyName%` |
| Tokens | `%CustomerName% %CustomerPhone% %CustomerEmail% %CompanyName% %GSTINLine% %QueueUrl% %PendingCount%` |
| Needs | the customer approval page (`/hhub/hhubcustomerapprovalpage`) — **not built**; `%QueueUrl%` is a dead link until step 5 lands |

Send one mail per registration, never a digest — the latency is the bug.

### C3 — `cust-approved.html` · "you can sign in now"

| | |
|---|---|
| Trigger | inside `approve-customer` (Phase-1 domain function), after `!update` succeeds |
| To | the buyer |
| Subject | `Approved - you can sign in to %CompanyName%` |
| Tokens | `%CustomerName% %CompanyName% %CustomerPhone% %ApprovedDate% %LoginUrl% %SupportEmail%` |
| Needs | steps 3–4 of `customeronboarding-ADMIN-API.md` (domain function + endpoint); login URL `/hhub/customer-login.html` |

### C4 — `cust-rejected.html` · "no, and why"

| | |
|---|---|
| Trigger | inside `reject-customer`, after `!update` succeeds |
| To | the buyer |
| Subject | `Not approved - your account with %CompanyName%` |
| Tokens | `%CustomerName% %CompanyName% %ReasonLine% %AdminContactLine% %SupportEmail%` |
| Needs | `REJECTION_REASON` (migration applied 2026-10-22) + reason required at the endpoint (400 otherwise) |

`%ReasonLine%` falls back to "Not given" only for legacy rows; the endpoint refuses a blank reason.

## 3. Order of arrival

```
register ──► C1 (buyer: "pending") ──► C2 (admin: "act")     ← C2 not built
admin approves ──► C3 (buyer: "live")                        ← C3 not built
admin rejects  ──► C4 (buyer: "why")                         ← C4 not built
```

## 4. Deferred (do not build until C2–C4 are green)

`cust-profile-incomplete` (KYC nudge, needs a scheduler), credit-request mails, `cust-signin-help`
(no status page), `cust-order-placed` (C7 — then wire it to `:persona :customer`, and the vendor
order mail at `order/dod-bl-ord.lisp:582` to `:vendor`).
