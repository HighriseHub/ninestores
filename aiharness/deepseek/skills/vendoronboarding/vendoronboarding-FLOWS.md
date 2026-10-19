# vendoronboarding — flows: signup → first login → what to do next

**Read this when:** you are designing or checking the **vendor first-login experience** — what the
vendor sees after the OTP, why the dashboard shows four zeroes, which checklist items can be
computed, or where a blocked login should land.

> **Status: PLAN — 2026-10-17.** Companion to `vendoronboarding-CONTEXT.md` (decisions) and
> `vendoronboarding-EMAILS.md` (E1–E7). Numbers in `measured` columns are live `hhubdb` reads
> from 2026-10-17.

---

## 1. Where the vendor is lost today

Silent at three seams, all confirmed in source:

1. **After registration** — one legacy B2C mail, no "wait for approval" (survey §4, step 7).
2. **At login while pending** — the OTP controller redirects to the login page with no message;
   the vendor cannot distinguish "wrong number" from "not yet approved" from "rejected".
3. **After approval while already logged in** — the dashboard (`vendor/dod-ui-ven.lisp:3026`)
   renders Orders / Today's Demand / Today's Revenue / Sale Invoices: four cards of zeros for a
   vendor with no catalog. Nothing on the page says what to do first, or that anything is missing.

## 2. Target journey — one picture

```
       ┌──────────────────────────── E-MAIL ───────────────────────────┐
register ─► E1 vendor "registered, waiting" ┄┄ E2 admin "approve this"
                 │  (E5 status lookup available from here on)
                 │
        ┌────────┴─────────┐
   approved            rejected
        │                  │
   E3 "live + 3 jobs"   E4 "why + who + escape"
        │
        ▼
   ┌───────────── FIRST LOGIN (screen, no new mail) ─────────────┐
   │ phone ──► OTP ──► /hhub/dodvendindex?context=home            │
   │                                                             │
   │  ┌── Getting started ─── 1 of 5 ────────────────────────┐   │
   │  │ ✔ GSTIN            missing → [Add GSTIN]              │   │
   │  │ ✘ PAN              missing → [Add PAN]                │   │
   │  │ ✘ Payout (UPI)     missing → [Set payout]             │   │
   │  │ ✘ First product    none    → [List a product]         │   │
   │  │ ✘ Shipping zone    none    → [Set zones]              │   │
   │  │ Finish these and your account is ready for orders.    │   │
   │  └───────────────────────────────────────────────────────┘   │
   │  then the existing cards: Orders · Demand · Revenue · Invoices│
   └─────────────────────────────────────────────────────────────┘
        │
        ▼
   first purchase order ─► E7 (wire the orphaned vendor-order.html)
        │
        ▼
   day 3 / day 7 still incomplete ─► E6 (phase 2, needs a scheduler)
```

## 3. The login page must answer four states, in place

Today one code path treats all four the same. Target: `dod-controller-vend-login-with-otp`
(`vendor/dod-ui-ven.lisp:2419`) resolves the phone **once** and re-renders the login page with a
state panel — **no new route, no new page** (see §4 on cost).

| Row state | Panel on the login page | Escape hatch |
|---|---|---|
| no row | "No vendor account for this number on this store." | [Register as a vendor] |
| `N/PENDING` | "Registered — waiting for `<Company>`'s administrator. Nothing needed from you." | [Email me my status] (E5) · [Nudge the admin] |
| `N/REJECTED` | "Not approved by `<Company>`." + reason when B2 has one | administrator contact |
| `Y/APPROVED` | normal login (today's behaviour) | — |
| `Y/PENDING` (stranded) | "Approved but not fully activated — we have flagged it." | [Email me my status] · support |

**Enumeration rule.** The panel is rendered from the row, for whoever holds that phone and passed
the OTP — that is not an oracle, because the OTP is the proof. The **email** request path (E5) is
different: it must answer the *same* sentence for every number ("If that number is registered we
have emailed it") and be rate-limited per phone.

## 4. Cost rule that shaped this design

**A new route is not free.** Every new page needs an ABAC policy + transaction pair seeded
(`../../knowledge/ABAC-policy-transaction-CONTEXT.md` §8), and the seeding is currently the
hand-rolled migration-per-page pattern that `seed-data-upsert-CONTEXT.md` calls out as open work.
So:

- The checklist lives **on the existing dashboard** (`/hhub/dodvendindex?context=home`), not on a
  `/onboarding` page.
- The login states are **re-rendered by the existing login controller**, not a new `/status` page.
- The **only** new route this feature needs is `POST /hhub/hhubvendstatusmail` for E5 — one
  policy+transaction pair, one controller, no page.

## 5. The checklist — five items, all computed, none stored (D6)

`render-vendor-dashboard-home` (`vendor/dod-ui-ven.lisp:3026`) gains a card above the metrics.
Each item is a read, and every one already has a page to send the vendor to.

| # | Item | Computed from | Live fill (2026-10-17) | Page |
|---|---|---|---|---|
| 1 | GSTIN on file | `DOD_VEND_PROFILE.gstnumber` non-empty | **12 of 15 have none** | vendor profile |
| 2 | PAN on file | `DOD_VEND_PROFILE.PAN_NUMBER` non-empty | **15 of 15 have none** | vendor profile |
| 3 | Payout route | `DOD_VEND_PROFILE.UPI_ID` non-empty **or** a payment-gateway setting | not measured | UPI / gateway settings |
| 4 | A product customers can order | `DOD_PRD_MASTER` for this vendor with `active_flag='Y'` **and** `approved_flag='Y'` (`products/dod-bl-prd.lisp:68-76`) | tenant 2: 146/171 approved; tenant 5: 10/17 | `dodvenproducts` |
| 5 | Shipping zones | `DOD_VENDOR_SHIP_ZONES` rows for the vendor | not measured | `hhubvendorshipmethods` |

### What registration already creates (verified 2026-10-19) — and what stays empty

| row | written by | consequence |
|---|---|---|
| `DOD_VENDOR_TENANTS`, `DEFAULT_FLAG='Y'` | `create-vendor-tenant` | the vendor belongs to the store |
| `DOD_SHIPPING_METHODS` — one free method, `MINORDERAMT` ₹500 | `create-free-shipping-method` | ⚠ **"a shipping method exists" is true for every new vendor** — the checklist must key on **zones**, never on methods |
| `DOD_PRD_MASTER` — `PRODUCT_CODE 'FREIGHT-<vid>'`, `SERV`, HSN 9965, price 0, auto-approved | `create-freight-product-for-vendor` (new, 2026-10-19) | the order→invoice delivery charge has a product row to attach to; without it `nst-select-freight-product` finds nothing and `nst-cart-with-delivery-line` **silently drops the charge** |
| `DOD_VEND_PROFILE.INVOICE_SETTINGS` — the seeded blob | the `VEN` branch's `:invoice-settings` initarg | invoice numbering and the settings page work from the first invoice |

Still empty, and that is exactly what the checklist below measures: **products 0**, **shipping zones 0**,
**`DOD_VPAYMENT_METHODS` 0**, **GSTIN/PAN blank**.

⚠ The freight product's **rate is not read from it**. The delivery charge is a composite supply taxed at
the principal goods line's rate (`knowledge/gst-tax-jurisdiction-CONTEXT.md` §1), so do not "fix" a 0 on
that line by seeding a 9965 rate — `get-gstvalues-for-product` would only turn a silent zero into a
wrong number.

### Two traps this table exists to stop

- **"Shipping configured" is always true on day one.** Registration creates a free shipping method
  (`customer/dod-ui-cus.lisp:1695` → `create-free-shipping-method`), so any checklist item keyed on
  "a shipping method exists" is satisfied before the vendor has done anything. Key it on **zones**,
  or on a non-default method.
- **"Publish a product" is a two-person job.** The customer-facing list demands
  `approved_flag='Y'` (`products/dod-bl-prd.lisp:74`) and a company administrator is the only
  approver (`sysuser/dod-bl-cad.lisp:24`, queue at `dod-ui-cad.lisp:459`). So item 4 must read
  "waiting for approval" when the product exists but is unapproved — three states, not two:
  *none* / *pending approval* / *live*.
- **Item 3 cannot say "bank details".** There are no bank columns on `DOD_VEND_PROFILE` — the
  `BANK_ACCOUNT_NUMBER` / `BANK_IFSC_CODE` columns exist only on `DOD_CUST_PROFILE` (measured
  `information_schema`). Vendors have `UPI_ID` plus per-transaction `IFSC_CODE`. Either the copy
  says "UPI / payout route", or a migration adds vendor bank columns first. **Decision needed
  before E3 is written**, because E3 promises the same three items.

## 6. After login — the ordered path, and what it must say

Not new functionality: the vendor surface already exists (nav bar `vendor/dod-ui-ven.lisp:2360-2384`,
products, shipping, payment modals, orders). The onboarding job is to **say which one is next**.

| Order | What the vendor does | Where it already lives | One-line reason shown on screen |
|---|---|---|---|
| 1 | GSTIN + PAN | vendor profile (`dodvendprofile`) | "These print on every tax invoice your buyer claims credit against." |
| 2 | Payout route (UPI / gateway) | UPI settings, payment-gateway modal | "Where we remit for accepted orders." |
| 3 | First products | `dodvenproducts` | "Customers can only order what is listed — and approved by `<Company>`." |
| 4 | Shipping zones / rates | `hhubvendorshipmethods` | "An order needs a way to reach the buyer." |
| 5 | Watch for orders | `dodvendindex?context=pendingorders` | "This is where purchase orders land." |

The dashboard card carries **one** primary button — the first incomplete item — never five. The
existing metric cards stay visible underneath, so the page does not change shape when onboarding
finishes.

## 7. Acceptance criteria for the first-login work

1. A vendor approved today can log in and, without asking anyone, state what is missing and what
   to click next.
2. Each of the five states in §3 is reachable in a test (write the row by hand, do not wait for a
   real approval) and renders the correct panel.
3. The checklist shows `n of 5` and re-reads on every load — a newly approved product flips item 4
   from "pending approval" to "live" on refresh, with no cache in the way. ⚠ Vendor pages hold a
   session product cache (`:login-prd-cache` set at login, `customer/dod-ui-cus.lisp:3778`); confirm
   whether the vendor side caches products before promising a live flip.
4. No new route except `POST /hhub/hhubvendstatusmail`.
5. Every string in §3's table and §6's column 4 exists in the copy file used by the emails, so
   mail and screen cannot drift.
