# SKILL: Subscription plans and ABAC entitlements (Nine Stores / hhub)

**Read this when:** you are adding a plan limit or a plan-gated feature ("BASIC gets 5
vendors"), an account is blocked by a quota it should not be, a quota looks right and enforces
nothing, a `cond`-shaped attribute function returned NIL and something 500'd, you are about to
wire up trial expiry or a plan downgrade, or you need to know which plan values actually exist
before writing a check. **§2 is the mechanism, §3 the measured matrix, §4 the traps, §5 what
does not exist, §9 the live database.**

**Status:** measured against the tree **and** the live database **2026-10-13**; every
`file:line` below was read that day. 🚨 Live querying *corrected two claims* this file first made
from source alone: the seeded product attribute is
`com.hhub.attribute.vendor.maxproductcount` (**not** the `company.` name the seeder implies), and
`DOD_AUTH_POLICY_ATTR` holds **0 rows**, so its `ATTR_VAL` is not merely unread but never
populated. ⚠ Pass the password via `MYSQL_PWD`, **not** `-p'…'` inside `eval` — the `$` in it is
eaten by the shell and the login fails with a misleading `Access denied`.
⚠ **490 lines, over the 400-line read budget** — the daily consolidation pass should merge §1.3
into §3 and fold §9's table into §1, neither of which changes a fact.
**Applies to:** `hhub/core/dod-ui-attr.lisp` (the attributes), `hhub/core/dod-ui-pol.lisp`
(the policies), `hhub/account/dod-dal-cmp.lisp` (`SUBSCRIPTION_PLAN`), and every
`with-hhub-transaction` call site that consumes a quota.

---

## 1. What the plans are — measured, not advertised

Exactly three plan values exist, all free-form strings, none validated by any code:
`TRIAL`, `BASIC`, `PROFESSIONAL` — the superadmin dropdown
(`hhub/sysuser/dod-ui-sys.lisp:298-300`), stored in `DOD_COMPANY.SUBSCRIPTION_PLAN`
`varchar(50) NOT NULL DEFAULT 'TRIAL'` (`installation/DOD_COMPANY.sql:45`), slot at
`hhub/account/dod-dal-cmp.lisp:165-168`.

### 1.1 The published prices — one Lisp function, as page copy

`hhub-controller-pricing` (`hhub/core/dod-ui-site.lisp:191-206`) is the **only** place a price
appears in the repo:

```lisp
;; hhub/core/dod-ui-site.lisp:192-193
  (let ((names (list  "Trial" "Basic" "Professional"))
	(prices (list "00" "19,999" "29,999"))
```

Rendered as `&#8377;` + price + a literal `"00"` cent span + `/Year` (`:261-265`) — i.e.
**₹00.00 / ₹19,999.00 / ₹29,999.00 per year**. The digits are never stored as numbers, never
in a table, never on an invoice (`grep 19999|29999` finds nothing). **A price is display copy
in a controller, not data — nothing can bill against it.**

### 1.2 Trial: 90 days is a constant with nothing behind it

`*HHUBTRIALCOMPANYEXPIRYDAYS*` = `90` (`hhub/core/dod-ini-sys.lisp:106`). There is **no
trial start/end column** — expiry is derived from `DOD_COMPANY.CREATED`.
`trial-account-days-to-expiry` (`account/dod-bl-cmp.lisp:78`) and `trial-account-expired-p`
(`:85`) both exist, and 🚨 **`trial-account-expired-p` has NO callers anywhere**: not in a
policy, not in `with-hhub-transaction`, not on a route — the symbol DAG records
`(:CALLS-COUNT . 0) (:USED-BY-COUNT . 0)` (`nst-bl-funloodat.lisp:31735-31739`). The only
consumer of either is the superadmin company card, which prints a countdown
(`account/dod-ui-cmp.lisp:39-40,84-87`). **A TRIAL account does not expire; the trial is a plan
name plus a label.** ✅ **Confirmed against live data 2026-10-13:** company 4
(`SUBSCRIPTION_PLAN='TRIAL'`, created **2023-05-28**) is still live and unsuspended — 2.4 years
past the 90-day constant (§9).

### 1.3 Named in the sales material, absent from the code

| named elsewhere | reality in the tree |
|---|---|
| `HHUBTEST` | **documentation only** — inside the attribute *description* strings (`dod-seed-data.lisp:146-147`); no `equal`/`if`/`case` tests it. |
| `STANDARD` | never a `SUBSCRIPTION_PLAN`; `"STANDARD"` is a **customer** type (`customer/dod-ui-cus.lisp:1359`). |
| "FREE UPI / free shipping / free payment gateway" | not entitlements — shipping and payment are **per-vendor** flags, not plan attributes. |
| `COMMUNITY` as a fourth plan | a **`CMP_TYPE`** (store vertical) that *incidentally* acts as a fourth tier — §4.2. |
| Trial **signup** | 🚨 the "Sign Up – 90 Days Free!" CTA (`dod-ui-site.lisp:275`) is **lead capture, not provisioning**: step 2 builds an *unsaved* `dod-company` (`sysuser/dod-ui-sys.lisp:794`), parks it in the session (`:815`) and only **emails support** (`:825-833`, template `email/templates/registration.lisp:126-137`). A superadmin provisions the tenant by hand, and the session copy carries no `subscription-plan` at all. |

---

## 2. The mechanism — four layers, and only three of them run

```
DOD_COMPANY.SUBSCRIPTION_PLAN      ← the plan: a free-form string on the account
   ├─ com-hhub-attribute-company-* (dod-ui-attr.lisp:58-121)   ← THE PLAN TABLE
   │     (subscription-plan cmp-type) → a number or a boolean
   ├─ com-hhub-policy-*            (dod-ui-pol.lisp)           ← THE COMPARISON
   │     reads the plan off the company, calls the attribute,
   │     compares against a LIVE COUNT, signals to deny
   └─ with-hhub-transaction        (dod-ui-utl.lisp:961)       ← THE ENFORCEMENT
```

### 2.1 The plan table is a `cond` — one function per entitlement

```lisp
;; hhub/core/dod-ui-attr.lisp:58-63
(defun com-hhub-attribute-company-maxvendorcount (subscription-plan cmp-type)
  (cond ((equal cmp-type "COMMUNITY") 999)
        ((equal subscription-plan "BASIC") 5)
        ((equal subscription-plan "PROFESSIONAL") 10)
        ((equal subscription-plan "TRIAL") 1)))
```

Every entitlement attribute has this shape — `(subscription-plan cmp-type)`, a `COMMUNITY`
arm first, then one arm per plan, **and no `t` fallback**. The full set is
`dod-ui-attr.lisp:58-121`: `maxvendorcount`, `vendor-maxproductcount` (`:65`),
`prdbulkupload-enabled` (`:73`), `prdsubs-enabled` (`:81`), `wallets-enabled` (`:89`),
`codorders-enabled` (`:97`), `maxcustomercount` (`:105`), `maxprodcatgcount` (`:116`).

### 2.2 The policy does the comparison — against a live count, not a stored one

`com-hhub-policy-customer&vendor-create` (`hhub/core/dod-ui-pol.lisp:577-594`) reads
`subs-plan`/`cmp-type` off the company, takes `(length (select-vendors-for-company company))`
and `(length (select-customers-for-company company))`, resolves both maxima through the
attribute functions, and raises `hhub-abac-transaction-error` when either
`(<= (- max count) 0)`. Three things to internalise:

1. **The count is part of the decision and is read at decision time** — usage is never stored
   on the account. `select-vendors-for-company` (`vendor/dod-bl-ven.lisp:225`) is a full
   `select` with `:caching nil`, filtered `deleted-state='N' AND tenant-id=<company>`; the
   policy takes its **length in Lisp**.
2. **One transaction guards two different quotas.** `com-hhub-transaction-customer&vendor-create`
   is the *self-signup* endpoint (`customer/dod-ui-cus.lisp:1676-1690`), creating either a
   vendor or a customer by the session's `:reg-type` — so the combined policy is right for that
   endpoint, but **a tenant out of vendors is also refused a customer, and vice versa**.
3. **A refusal is an `error`, never a `nil`** — the message is user-facing, and `has-permission`
   converts any error into a deny (§4.3).

The product quota is the sibling shape — per vendor, and only on add: `dod-ui-pol.lisp:599-613`
counts `(select-products-by-vendor vendor company)` and gates on `(equal mode "add")` (note the
selector's `:limit` — **§4.4** makes that a defect for a quota, and the paid caps rely on it).

### 2.3 The capability gates are the same mechanism, boolean-shaped

`prdbulkupload-enabled`, `prdsubs-enabled`, `wallets-enabled` and `codorders-enabled` are
`cond`s returning `T`/`NIL` from the same `(subscription-plan cmp-type)` pair. They are
consumed two ways — **inside a policy**, and **directly by a page's model/widget to hide a
control**:

| consumption | site |
|---|---|
| policy (the enforcement) | bulk upload API — `dod-ui-pol.lisp:212-218`; legacy bulk — `:645`; `prdbulkuploadp` — `:619` |
| model/widget (presentation only) | `customer/nst-ui-prodetpag.lisp:23`, `customer/dod-ui-cus.lisp:1359,1365`, `products/dod-ui-prd.lisp:613,707`, `vendor/dod-ui-ven.lisp:159,186` |

🚨 **The presentation calls are not enforcement.** `dod-ui-cus.lisp:1359` merely decides
whether to *render* the subscriptions link and `:1365` the wallet link; a client that asks
for the route directly is governed only by whatever policy that route carries. When you add a
plan-gated feature, **grep both** — the display call, and the policy.

The API's bulk-upload policy is the **reference implementation of a plan gate done right**:
it refuses with the plan name in the message, and its docstring (`dod-ui-pol.lisp:183-199`)
records why the 100-row cap is *not* checked there (the cap is a property of the uploaded
file, so the parser owns it) — that split is a decision, not an omission.

---

## 3. The entitlement matrix, measured — against what the pricing page sells

`C` = `CMP_TYPE`, `P` = `SUBSCRIPTION_PLAN`. The `COMMUNITY` arm is tested **first**, so it
wins over the plan for any account whose `CMP_TYPE` is `COMMUNITY`.

The **advertised** column below is `pricing-table` (`hhub/core/dod-ui-site.lisp:202-205`) as
the controller actually renders it. Where the page and the code disagree, **the page is what a
customer has been shown.**

| entitlement | TRIAL | BASIC | PROFESSIONAL | advertised (T/B/P) | C=`COMMUNITY` | source |
|---|---:|---:|---:|---|---:|---|
| max vendors | 1 | 5 | 10 | 1 / 5 / 10 ✓ | **999** | `dod-ui-attr.lisp:58` |
| max products (per vendor) | 100 | 1000 | 3000 | 100 / 1000 / 3000 ✓ | **50** | `:65` |
| max customers | 50 | 500 | 1000 | 50 / 500 / 1000 ✓ | **100** | `:105` |
| max product categories | 10 | 20 | 50 | *not advertised* | 20 | `:116` |
| product subscriptions | ✗ | ✓ | ✓ | N / **N** / Y ✗ | ✗ | `:81` |
| wallets | ✗ | ✓ | ✓ | N / **N** / Y ✗ | ✓ | `:89` |
| COD orders | ✗ | ✗ | ✓ | N / N / Y ✓ | ✓ | `:97` |
| bulk product upload (CSV) | ✗ | ✓ | ✓ | N / Y / Y ✓ | ✗ | `:73` |
| rows per bulk upload | 100 | 100 | 100 | *not advertised* | 100 | `vendor-bulk-product-count` `:47` — **hardcoded, plan-blind** |
| product images & zoom | — | — | — | 1 / 5 / 10 | — | **no attribute, no policy, no code** |
| sub-domains | — | — | — | N / 2 / 5 | — | **no entitlement exists** |
| domain registration | — | — | — | N / N / Y | — | **no attribute, no policy, no code** |

🚨 **TWO ROWS ARE SOLD AND IMPLEMENTED THE OTHER WAY ROUND — live mis-sales, not typos:**

- **product subscriptions**: the page says BASIC ✗ / PROFESSIONAL ✓; the code returns **`T`
  for BASIC** (`:81-86`). A BASIC tenant already has the feature PROFESSIONAL is priced higher
  for.
- **wallets**: the page says N / N / Y; the code returns **`T` for BASIC** (`:89-94`) — and
  the seeded attribute *description* says `TRIAL = N  BASIC = N  PROFESSIONAL = Y`
  (`dod-seed-data.lisp:153`). **The code disagrees with the page and with its own catalogue row.**
- **COD orders** matches for the three plans, but silently grants COD to `COMMUNITY` (`:97-102`).

**`COMMUNITY` inverts the ladder** — 50 products is *below* TRIAL's 100 while 100 customers is
*above* TRIAL's 50 — while giving 999 vendors. It is not a tier; it is a vertical with a
promotional override (§4.2). **`maxprodcatgcount` is on no page at all** — a ninth entitlement
with no commercial definition.

### 3.1 🚨 The pricing page has 26 feature labels and only 20 columns of data

Measured 2026-10-13 by parsing both lists out of `dod-ui-site.lisp`: `pricing-features` has
**26** labels (`:196-200`), `features-active` has **26** flags (`:201`), and each of the three
`pricing-table` rows carries **20** values (`:203-205`). `format-pricing-plans` walks them in
lockstep, so the last **six** advertised features — **API Access, Blocked IPs, Save Cart,
Customer Groups, SEO Tools, Facebook Store** — have **no value in any plan column** and are all
flagged `NIL`, so they are hidden.

**The page is one edit from rendering a misaligned table: adding a 21st value to any row
silently shifts every label beneath it, and nothing would error.** Fix by keying the row
(a plist per plan) rather than by appending. **Product Images & Zoom** and **Revenue/Month**
(`Upto ₹1 Lac / 5 Lacs / 10 Lacs`) are advertised with **no enforcement anywhere** —
`DOD_COMPANY.REVENUE` is a plain nullable column that nothing checks.

### 3.2 `maxproductcount` is per VENDOR, but the number is the COMPANY's

`com-hhub-attribute-vendor-maxproductcount` takes the company's plan, and
`com-hhub-policy-vendor-add-product-action` counts `(select-products-by-vendor vendor company)`
— **one vendor's products**. So the 1000/3000 figure is a *per-vendor* cap despite being a
plan-level number: a BASIC tenant with its full 5 vendors may hold 5 × 1000 products. If the
commercial intent is a tenant-wide ceiling, this is a defect, and it is the kind of thing the
sales table cannot express. **OPEN — a product decision, not a bug to fix silently.**

---

## 4. Traps, in the order they bite

### 4.1 🚨 THE BIG ONE — `DOD_AUTH_ATTR_LOOKUP` IS NOT AN ENGINE, IT IS A DEAD CATALOGUE
The schema looks like a real ABAC attribute layer: `DOD_AUTH_ATTR_LOOKUP` (`NAME`,
`DESCRIPTION`, `ATTR_FUNC`, `ATTR_UNIQUE_FUNC`, `ATTR_TYPE`, `TENANT_ID`) linked to policies
through `DOD_AUTH_POLICY_ATTR.POLICY_ID`/`ATTRIBUTE_ID`/`ATTR_VAL`
(`installation/hhubplatform.sql:1223-1243`, `:1265-1280`), plus an admin UI at
`/hhub/listattributes`. **None of it participates in an authorization decision.**

- The **only** name→row lookup is `select-auth-attr-by-key` (`hhub/core/dod-bl-pol.lisp:33-39`)
  and it has **zero callers**.
- No code anywhere resolves `ATTR_FUNC` and `funcall`s it. `ATTR_FUNC` is written, cached
  (`dod-ini-sys.lisp:321,376`) and **rendered as copy-to-clipboard text** in the admin list
  (`dod-ui-pol.lisp:853-864`).
- `DOD_AUTH_POLICY_ATTR.ATTR_VAL` is written (`persist-auth-policy-attr`,
  `dod-bl-pol.lisp:243`) and **read by no policy**. **No attribute value lives in the database.**

**The real mechanism is a hardcoded `funcall` two names deep**: the policy names the
attribute function in its source, and passes it `(subscription-plan cmp-type)` read from the
company object. **Adding a row to `DOD_AUTH_ATTR_LOOKUP` changes nothing about enforcement** —
and neither does editing `ATTR_VAL`, which is the very row an admin would reach for first.
This is the trap the whole file exists for: *the metadata says the attribute is
database-driven; the code says it is a `cond`.*

### 4.2 🚨 `COMMUNITY` is a `CMP_TYPE`, and `CMP_TYPE` answers first
`company-type-dropdown` (`sysuser/dod-ui-sys.lisp:306-321`) lists thirteen **store
verticals** — GROCERY, APPAREL, HYPERMARKET, … and `COMMUNITY` (`APARTMENT/COMMUNITY`).
Only `COMMUNITY` is branched on by the attribute functions, and **it is tested before the
plan**, so `CMP_TYPE='COMMUNITY'` overrides the subscription entirely: **999 vendors on any
plan, including TRIAL.** Whether that is intended, and whether it should be a plan instead,
is **OPEN** — but it is currently the cheapest way to get unlimited vendors, so treat
`CMP_TYPE` as an entitlement input, not decoration.

### 4.3 An unrecognised plan DENIES — but the count behind it is unsynchronised
**Every attribute `cond` lacks a `t` clause** (§2.1). For an account whose `CMP_TYPE` is not
`COMMUNITY` and whose `SUBSCRIPTION_PLAN` is not one of the three — a fourth value typed into
the form, a row edited by hand, or `SUPER` on live company 1 (§9) — **every entitlement
attribute returns `NIL`**, and then:

- in a boolean policy → `(list nil nil)` → a silent, confusing deny;
- in an arithmetic policy → `(<= (- NIL 3) 0)` is a **TYPE-ERROR**, caught by
  `has-permission`'s catch-all (`hhub/core/dod-bl-bo.lisp:241-246`), logged with a backtrace,
  and returned as the **generic** *"Nine Stores General Authorization Error"* — an
  infrastructure-shaped failure for what is a missing plan value.

**Both fail closed (good) and both are undiagnosable (bad):** on an entitlement denial with no
plan-specific message, check `SUBSCRIPTION_PLAN` **first**, then
`*HHUBBUSINESSFUNCTIONSLOGFILE*`.

**And `length` is not a `COUNT(*), nor is the count locked.** `currvendorcount` counts rows in
Lisp after fetching them (`vendor/dod-bl-ven.lisp:225-227`, no caching), so **performance
scales with usage** on the hot path of every signup — and 🚨 **the CHECK-THEN-WRITE RACE is
unmitigated**: the policy counts, the controller inserts (`customer/dod-ui-cus.lisp:1693`), and
nothing between them is a transaction, a `SELECT … FOR UPDATE` (there is **no row locking
anywhere** in `hhub/` or `installation/`) or a unique constraint — so **two concurrent signups
at the last slot can both pass and both insert**. The only unique key on `DOD_VEND_PROFILE` is
`UC_Vendor (PHONE, TENANT_ID)`, which does not protect a count. Two precedents to copy:
`count-company-vendors` (`hhub/account/dod-bl-cmp.lisp:98-105`) already does the correct
server-side `COUNT(*)` and is **not** what the policy uses, and the order create now wraps its
writes in `clsql:with-transaction` (`order/nst-bl-ordhapi.lisp`, PENDING-WORK §11 row 1).

### 4.4 🚨 A QUOTA MUST NOT BE COUNTED WITH A CAPPED LIST SELECTOR — BASIC/PROFESSIONAL product caps can never fire
**`:limit` is a deliberate, house-wide convention, not a defect.** It appears at **55 sites
across 44 functions** in `hhub/` (16 with a literal number — 500 at `products/dod-bl-prd.lisp:75`,
200 at `:85/:97`, warehouse `:640-688`, invoice `nst-bl-ihd.lisp:45`, `nst-bl-itm.lisp:89,106`;
the rest take it from `*-enumerate-args`). The rationale: **fetch the top N for interactive list
pages, and write a purpose-built query when the whole set is needed.** Never remove a `:limit`
to fix a quota — the defect is the *reuse*.

`com-hhub-policy-vendor-add-product-action` (`dod-ui-pol.lisp:607`) counts with
`(length (select-products-by-vendor vendor company))` — a **list selector capped at 200**
(`products/dod-bl-prd.lisp:85`, `:order-by '([row-id] :desc)` so the 200 kept are the *newest*).
`(length …)` therefore **saturates at 200**, so `(<= (- maxproductcount currproductcount) 0)`
can never be true for `maxproductcount` = 1000 (BASIC) or 3000 (PROFESSIONAL):
🚨 **only the TRIAL cap of 100 can ever fire — a BASIC or PROFESSIONAL tenant has an unlimited
product count in practice.** The insert is wrapped (`products/dod-bl-prd.lisp:330`) but the
check ran earlier and outside it.

**The fix the owner has indicated:** add a **dedicated uncapped count** for the quota (e.g.
`count-products-by-vendor` doing `SELECT COUNT(*)`, per §4.3's `count-company-vendors`
precedent) and leave the list selector at 200. Two guardrails:

- **Any `:limit`-capped selector is unsafe to `length` for a quota** — sweep
  `grep -n ":limit" hhub/**/*.lisp` against callers inside `dod-ui-pol.lisp`. The product quota
  is the only entitlement counting through a capped selector today (vendor and customer use
  uncapped selects), but `select-products-by-company` carries a **500** cap (`:75`), so any
  future tenant-wide product count inherits the same bug with a larger ceiling.
- **It fails silently toward "allowed"** — a saturated count is always below the limit, so this
  cannot produce a false *denial*, only an unnoticed *permit*, and nothing logs it. ✅ Live
  2026-10-13: the largest count per `(tenant, vendor)` is **106**, well under 200, so this is a
  **latent** defect, not a live one (§9).

### 4.5 🚨 `SUBSCRIPTION_PLAN` arrives from a FORM FIELD — the plan is client-supplied
`com-hhub-transaction-create-company` (`sysuser/dod-ui-sys.lisp:838-874`) reads
`(hunchentoot:parameter "subscription-plan")` and `"cmp-type"` **straight off the request** and
passes them to `new-dod-company`. The transaction's policy, `com-hhub-policy-create-company`
(`dod-ui-pol.lisp:728-730`), checks **only** `(equal rolename "SUPERADMIN")` — **it never
validates the plan value.** The form's dropdown is a client-side suggestion.
**`PROFESSIONAL`, or `CMP_TYPE='COMMUNITY'` for 999 vendors, can be POSTed by any
superadmin-capable caller**, and the value is stored verbatim. A server-side whitelist plus a
real plan-change policy is required before plans can be sold.

### 4.6 Seeder and session traps — three ways this layer drifts unnoticed

**The seeder appends to the attribute SOURCE file.** `create-auth-attr-lookup`
(`dod-bl-pol.lisp:85-91`) does not only insert a row — it **opens
`~/ninestores/hhub/core/dod-ui-attr.lisp` and appends `(defun <attr-func> ())`** for every
attribute seeded, so the file is part-generated and re-seeding mutates tracked source with
zero-argument stubs. **Never add a migration that re-seeds attributes without reading this.**

**Two seeded attributes name functions that do not exist.** `com-hhub-attribute-company-maxproductcount`
(`dod-seed-data.lisp:147`) and `com-hhub-attribute-account-trial-maxvendors` (`:149`) are seeded
rows with no `defun` anywhere — the real product function is
`com-hhub-attribute-vendor-maxproductcount` (`dod-ui-attr.lisp:65`), and nothing consults a
trial-specific vendor limit. Because of §4.1 this is harmless *today*, which is exactly why it
went unnoticed: **the drift is invisible precisely where the catalogue is inert.**

⚠ **Corrected against the live database (§9):** the live row 59 is
`com.hhub.attribute.vendor.maxproductcount → com-hhub-attribute-vendor-maxproductcount` —
**correct, and it matches the shipped code**. The `company.`-prefixed name is the *seeder's*
drift, so **the seeder and the database disagree and the shipped code sides with the database** —
the more dangerous arrangement, because re-seeding a fresh database would introduce the broken
name and the failure would surface only if the catalogue were ever wired up.

**Plan changes are cached in the session.** The self-signup path puts the company object in the
session and the policy reads the plan from **that object** (`dod-ui-cus.lisp:1678,1686`), so a
plan or `CMP_TYPE` changed mid-flight is evaluated against the stale value — "the plan changed
and nothing happened" can be a session artefact rather than a data one.

---

## 5. What does NOT exist (do not assume these are implemented)

| capability | state |
|---|---|
| **Trial expiry** | **NOT ENFORCED.** `trial-account-expired-p` has no callers — the symbol DAG records `(:CALLS-COUNT . 0) (:USED-BY-COUNT . 0)` (`nst-bl-funloodat.lisp:31735-31739`). A trial runs forever. |
| **Self-service signup** | **NOTHING** — the CTA is a lead-capture form; a human provisions the tenant (§1.2). |
| **Billing / charging / renewal** | **NOTHING.** No price in any table, no currency, no recurring charge, no gateway subscription call. `DOD_PAYMENT_TRANSACTION` (`installation/paymenttransaction.sql:4-20`) is a customer→**vendor order** payment (FKs to ORDER_ID/CUSTOMER_ID/VENDOR_ID), not a ledger for Nine Stores' own fees. |
| **A plan/subscription table** | **NOTHING.** No `DOD_PLAN`, `DOD_SUBSCRIPTION`, `DOD_BILLING`, `DOD_TRIAL` or `DOD_ENTITLEMENT` table exists. Plan state is the single `DOD_COMPANY.SUBSCRIPTION_PLAN` varchar. ⚠ **`DOD_ORDER_SUBSCRIPTION` is a false friend** — it is a customer *product standing order* (PRD_ID, day-of-week flags, FREQUENCY), class `dod-ord-pref` in `hhub/subscription/dod-dal-opf.lisp:12,113`, and holds no price, no plan and no payment. |
| **Upgrade / downgrade** | **NOTHING.** No code path changes `SUBSCRIPTION_PLAN` except the superadmin form, and **there is no over-limit rule** — an account downgraded to TRIAL keeps its 10 vendors; the next create is simply refused. Nothing is deleted (correct), and nothing warns. |
| **Per-account overrides / exceptions** | **NOTHING.** `DOD_COMPANY` has **no limit column**; the limit is always derived from the plan inside the attribute function. The only "override" mechanism the schema offers, `ATTR_VAL`, is dead (§4.1). |
| **Plan audit trail** | **NOTHING** — a plan change is a plain `update-company`; no event, no `changed_by`, no reason. |
| **Suspension as a dunning tool** | The machinery exists (`suspendaccount`/`restoreaccount`, `account/dod-bl-cmp.lisp:48-62`; `SUSPEND_FLAG` checked by ~15 policies) but is **manual** — nothing sets it on non-payment. ⚠ The suspend/restore *policy* names in the seed (`dod-seed-data.lisp:33-34`) point at `com-hhub-policy-account-suspend`/`-restore`, which **are not defined anywhere** — two dangling policy rows in the bootstrap seed. |
| **Entitlement data on the ABAC API** | API routes for entitlements: none. All gates above are UI-path or the bulk-upload API (§2.3). |

---

## 6. Verifying a change to an entitlement

Run these **before** trusting any entitlement edit. The catalogue being dead (§4.1) means the
database will agree with you no matter what you changed.

```bash
cd /home/ubuntu/ninestores
# 1. Every attribute a policy cites must be a real defun — catches §4.6 drift.
grep -rho "com-hhub-attribute-[a-z0-9-]*" hhub/core/dod-ui-pol.lisp hhub/*/[a-z]*.lisp \
  | sort -u | while read f; do grep -rq "(defun $f " hhub/ || echo "MISSING DEFUN: $f"; done
# 2. An attribute nothing REACHES is decoration — and a plan gate needs BOTH halves,
#    the policy AND every presentation call site.
grep -rn "wallets\|prdsubs" hhub/core/dod-ui-pol.lisp hhub/customer/*.lisp hhub/products/*.lisp
```

**Exercise the four plan values, not one.** A `cond` with no `t` fails closed on a fourth
value (§4.3), so a test that only ever uses `BASIC` proves nothing about the arm that matters.
The adversarial set is `BASIC`, `PROFESSIONAL`, `TRIAL`, `CMP_TYPE='COMMUNITY'`, and **a value
outside all four** — expect a *deny*, and expect the log to name it (§4.3).

**Read the live state around any change** — the catalogue being dead (§4.1) means a schema read
cannot confirm an entitlement, so compare *usage against quota per tenant* with the plan it
claims (§9 is the 2026-10-13 baseline). ⚠ `MYSQL_PWD`, never `-p'…'` inside `eval` (§Status):

```bash
export MYSQL_PWD='Welcome$123'
mysql -u hhubuser hhubdb -N -B -e "SELECT ROW_ID,NAME,CMP_TYPE,SUBSCRIPTION_PLAN,SUSPEND_FLAG,DATE(CREATED) FROM DOD_COMPANY;"
mysql -u hhubuser hhubdb -N -B -e "SELECT TENANT_ID,COUNT(*) FROM DOD_VEND_PROFILE WHERE DELETED_STATE='N' GROUP BY TENANT_ID;"
```

**When adding an entitlement, check the count query is uncapped** (§4.4) — a new
`(length (select-<x>-by-…))` on a `:limit`-ed selector silently disables the limit it is
supposed to enforce.

---

## 7. File map

`file:line` read **2026-10-13**.

| Concern | Location |
|---|---|
| **The pricing page (the only price in the repo)** | `hhub/core/dod-ui-site.lisp:191-206` (`:192-193` prices, `:196-201` labels+flags, `:202-205` rows), renderer `:236-278`, CTA `:275` |
| The entitlement attributes (the plan table) | `hhub/core/dod-ui-attr.lisp:58-121` |
| Vendor/customer quota policy (combined) · product quota + its capped counter | `hhub/core/dod-ui-pol.lisp:577-594`; `:599-613` + `hhub/products/dod-bl-prd.lisp:78-86` (`:limit 200`) |
| Bulk-upload capability + row cap | `hhub/core/dod-ui-pol.lisp:183-219` (API), `:615-623`, `:638-650` (legacy) |
| Plan/type dropdowns (the only value lists) · signup takes the plan off the form | `hhub/sysuser/dod-ui-sys.lisp:297-321`; `:838-874` |
| Self-service signup = lead capture only | `hhub/sysuser/dod-ui-sys.lisp:794`, `:815`, `:825-833`; `hhub/email/templates/registration.lisp:126-137` |
| `DOD_COMPANY` plan slot + DDL · company create/suspend/restore | `hhub/account/dod-dal-cmp.lisp:141,165`; `installation/DOD_COMPANY.sql:41,45`; `hhub/account/dod-bl-cmp.lisp:26,48,56` |
| Count helpers (the `COUNT(*)` precedent) | `hhub/account/dod-bl-cmp.lisp:98-105`; the `length` one the policy uses: `hhub/vendor/dod-bl-ven.lisp:225` |
| Trial constant + the uncalled expiry predicate | `hhub/core/dod-ini-sys.lisp:106`; `hhub/account/dod-bl-cmp.lisp:78,85`; display only `hhub/account/dod-ui-cmp.lisp:39-40,84-87` |
| The product standing-order table (NOT subscriptions) | `installation/hhubplatform.sql:908`; `hhub/subscription/dod-dal-opf.lisp:12,113` |
| Dead attribute catalogue (schema + seeder + UI) | `hhubplatform.sql:1223-1243`, `:1265-1280`; `hhub/core/dod-bl-pol.lisp:33-39` (0 callers), `:85-91` (appends to source); `hhub/core/dod-seed-data.lisp:132-162`; `hhub/core/dod-ui-pol.lisp:853-864` |
| PEP chain and the error→deny conversion | `hhub/core/dod-ui-utl.lisp:961,1012`; `hhub/core/dod-bl-bo.lisp:184,241-246` |
| Attribute↔policy seeding + the ABAC PEP test harness | `ABAC-policy-transaction-CONTEXT.md`; `hhub/test/hhub-tst-abac-pep.lisp` |

---

## 8. Open decisions — do not assume an answer

1. **Is `maxproductcount` per-vendor or per-tenant?** (§3.2) — the code is per-vendor; a
   commercial "3,000 products" usually means the tenant.
2. **Is `COMMUNITY` an entitlement tier or a store vertical?** (§4.2) — it currently
   overrides all three plans for vendor count.
3. **Does wallets belong to BASIC?** (§3) — code says yes, the seeded description says no.
4. **What must happen when a TRIAL expires**, and when a downgrade leaves a tenant over its
   new limits — read-only, suspend, refuse-new-but-keep-existing, or warn? Nothing is defined,
   and `trial-account-expired-p` is the hook that was left for it.
5. **Where do prices live**, and what is billed? Nothing in the tree answers this.
6. **Should plan values be validated server-side** (§4.5), and should a plan change be an
   audited ABAC transaction of its own? Neither exists.
7. **Should the `DOD_AUTH_ATTR_LOOKUP` catalogue be wired up, or deleted?** (§4.1) — an inert
   table that reads as an engine is a liability either way; the decision is which.
8. **Which entitlements are real?** — nine exist in code, twelve are advertised. Resolve
   `prdsubs` and `wallets` (§3) and decide whether Product Images & Zoom, Sub-domains, Domain
   Registration, API Access and Revenue/Month are entitlements at all: **an advertised feature
   with no attribute and no policy is not gated, it is simply free.**
9. **Do the pricing page and the `cond` share one source?** (§3.1) — today the page is a
   26-label/20-column parallel list and the plan table is Lisp, nothing keeps them in step, and
   they already disagree.
10. **Company 2 is already OVER its vendor quota** (§9) — 11 live vendors on PROFESSIONAL's
   10. Decide whether that is a bug to repair, or the normal result of a plan change, and if
   the latter, **what the tree should do about it** (nothing warns today).

---

## 9. The live database, measured 2026-10-13

`mysql -u hhubuser hhubdb` with `MYSQL_PWD='Welcome$123'` — **`DOD_COMPANY` holds FOUR rows,
not the two rows the committed `installation/DOD_COMPANY.sql` dump shows** (that dump is stale;
do not treat `installation/*.sql` as the live data).

| `ROW_ID` | `NAME` | `CMP_TYPE` | `SUBSCRIPTION_PLAN` | vendors / quota | customers / quota | created |
|---:|---|---|---|---:|---:|---|
| 1 | super | `SUPER` | `TRIAL` | 0 / 1 | 0 / 50 | 2017-12-19 |
| 2 | Demo Company | `DEFAULT` | `PROFESSIONAL` | 🚨 **11 / 10** | 21 / 1000 | 2017-12-19 |
| 4 | Trial Account | `GROCERY` | `TRIAL` | 0 / 1 | 1 / 50 | **2023-05-28** |
| 5 | Basic Account | `DEFAULT` | `BASIC` | 4 / 5 | 4 / 500 | 2023-06-03 |

**What the measurements settle:**

- 🚨 **Trial expiry is demonstrably not enforced.** Company 4 has `SUBSCRIPTION_PLAN='TRIAL'`
  and was created **2023-05-28** — **2.4 years** past the 90-day constant — and is live and
  unsuspended. This is the empirical confirmation of §1.2, not an inference from the uncalled
  predicate.
- 🚨 **Company 2 is 1 vendor over its PROFESSIONAL quota (11 > 10) and still trading.** So
  either the quota was exceeded before the check existed, or a plan changed beneath it — and
  **nothing warns, nothing blocks reads, and the next vendor create is what fails** (§5). This
  is the live instance of the over-limit question, and it is worth asking the owner how the
  row got there before writing any repair.
- 🚨 **`CMP_TYPE='SUPER'` on company 1** — a **fifth** `CMP_TYPE` value that is in neither
  dropdown (`sysuser/dod-ui-sys.lisp:306-321` omits `SUPER`), so company 1 falls through every
  attribute `cond` to `NIL` (§4.3). Harmless only because company 1 is the policy tenant and
  its quotas are not exercised.
- **The `:limit 200` cap has not bitten yet.** The largest product count per `(tenant, vendor)`
  is **106** (tenant 2, vendor 1), against TRIAL's 100 — so tenant 2 is *just* over the TRIAL
  product allowance with a vendor at 106, and the count is well under the 200 saturation point.
  **§4.4 is a latent defect for BASIC/PROFESSIONAL, not a live one** — but it already
  demonstrates the second half of the problem: that 106-product vendor belongs to a tenant whose
  plan is PROFESSIONAL, so the TRIAL cap that *did* fire is not even its plan.

**Attribute catalogue, live:** `DOD_AUTH_ATTR_LOOKUP` holds **29 rows, all live** — and
`DOD_AUTH_POLICY_ATTR` holds **0**. So the "attribute value in the database" that §4.1 rules
out is not merely unread, it was **never populated**. Live row 59 is
`com.hhub.attribute.vendor.maxproductcount` → `com-hhub-attribute-vendor-maxproductcount`
(correct), confirming that `dod-seed-data.lisp:147`'s `company.`-prefixed name is the drifted
one and that the shipped `dod-ui-attr.lisp` agrees with the database, not with the seeder.

