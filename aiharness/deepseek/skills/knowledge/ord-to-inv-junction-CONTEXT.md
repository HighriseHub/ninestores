# The ord→inv junction — `invoice-from-ord` (Document 5 समास, measured 2026-10-06)

**What this file is for:** everything durable about turning an ORDER into an INVOICE in this tree —
the grammar that names it, the branch rule, the field mapping that matches today's code, and the five
traps that building it exposed. Session state for the order API is `../order-adhara-stories-CONTEXT.md`;
the invoice API's own handoff is `../invoice-api-handoff-CONTEXT.md`.

## 1. The junction already had a name

`paninigrammar/document-5-samaas.md`, category **"→ TRANSFORM (source entity becomes target entity)"**:

| D4 symbol | समास | CLOS method | constituents |
|---|---|---|---|
| `ord→inv` | **`invoice-from-ord`** (तत्पुरुष — "the invoice arising from ord") | `proc.bs:invoice-from-ord` | `three-way-match + invoice(ord) + irn? + issue(inv)` |

Its tool schema (Document 5's MCP catalog) is `{ord_id, tenant_id, actor_id}` — **the lines are NOT a
parameter**; the transformation derives them. `proc.bs` does not exist in `hhub/`, so the compound is
implemented in the tree's own idiom (`invh-create-from-order` + `route-invh-from-ord`).

## 2. Which संधि applies is CONTEXT — विसर्ग संधि (Document 4)

| order | junction | rule |
|---|---|---|
| physical goods (`ORDER_TYPE='SALE'`) | **व्यंजन** (mediated) | Document 4 lists `ord not fulfilled → invoice` under **INVALID sequences**. This schema has no GRN table, so `ORDER_FULFILLED='Y'` stands in for `grn-exists-and-accepted?` |
| service (`ORDER_TYPE='SRVC'`, the legacy `setAsServiceOrder` value) | **लोप ३** (elided) | "the entire पूर्तिगण verb chain is structurally absent" — no fulfilment precondition |

**Payment is NOT part of this junction.** `inv→pmt` is **प्रगृह्य** (an event, never a direct call), and
payment terms are a **विसर्ग** branch *after* issue. So COD/PREPAID/UPI/PG/CREDIT flex and prepayment do
not license invoicing before the mediator — they settle against an invoice that already exists.

**The duplicate guard is a named बहुव्रीहि predicate:** `inv-ord-id-unique?` (Document 4), "invoice
already exists for this ord — duplicate". Predicates return Belnap, and **`:U` must BLOCK** (the wallet
precedent: "no credit risk on uncertainty").

## 3. The field mapping — measured against today's code, not invented

Header: `custname`←order `custname` else the customer's `name` · `custid`←the customer's row-id ·
`vendor-id`←the SESSION vendor · `statecode`←the SELLER's GST state code · `placeofsupply`←the order's
place-of-supply code/name, else its ship-to state, else the customer's GSTIN digits, else the
customer's state · `custgstin`←the customer's GSTIN · `invnum`/`invdate`/`finyear`←derived by `make`
(`status` DRAFT) · `context-id`←the ORDER's context-id · `totalvalue`←Σ of this vendor's line totals ·
`totalinwords`←`convert-number-to-words-INR`.

Lines, exactly as `invoice/nst-ui-itm.lisp:108-153` builds a typed one: `price`←`unit-price` ·
`qty`←`prd-qty` · **`discount`←`disc-rate`, a PERCENT** (taxable = `qty × price × (1 − disc/100)`) ·
`hsncode`←the product's `hsn-code` · `uom`←`"<qty-per-unit> <unit-of-measure>"` (what live invoice lines
hold: `"1.0 LTR"`) · tax ← `get-gstvalues-for-product` (HSN rate) with intra/inter decided by
`statecode = placeofsupply`, because **the legacy order lines carry NO tax amounts at all** (measured:
rates NULL, amounts 0.00, while `totalitemval` already includes the tax — 1140.00 + 18% = 1345.20 ✓ the
derivation reproduces it).

### The delivery charge — a LINE, taxed at the goods' rate

Raised by the requester: order 492 was invoiced for ₹1437.35 and its ₹80.00 shipping was missing. The
invoice header has **no shipping column** and **every printed total is computed from the items**, so freight
can only appear as a LINE. It is now one, and the GST rule is the requester's confirming position —
composite supply, **the same rate as the principal goods** (Section 2(30) with Section 8), SAC 9965 on the
line, Section 15(2)(c) for the value inclusion: see `gst-tax-jurisdiction-CONTEXT.md` §1.

* the rate comes from `invh-principal-rate-triple` — the highest-taxable-value GOODS line — never from the
  freight product's SAC (which has no rate row at all: measured);
* the amount is the vendor's share of the order's charge (`invh-freight-share`): the WHOLE charge when this
  vendor is the order's only live vendor row, else pro-rata by taxable value with the largest vendor
  absorbing the rounding residual, so the shares sum to the order's charge exactly. ⚠ The vendor row's own
  `SHIPPING_COST` is a COPY of the order's (order 222: two rows, both 70.00, order 70.00) — never a
  per-vendor entitlement, and billing each copy would charge ₹140 for a ₹70 delivery;
* **it is never silently dropped.** Two refusals guard the money: no `FREIGHT-<vendor-id>` product to bill
  under, and an unattributable charge (no line carries a taxable value — measured on order 222, whose
  vendors' lines store `TAXABLEVALUE` 0.00). Both refuse with a plain sentence rather than writing ₹X short;
* the product row per vendor comes from `installation/upgrades/nst-dbu-freight-product.lisp`
  (`PRODUCT_CODE = FREIGHT-<vendor-id>`, `PRD_TYPE 'SERV'`, SAC 9965, price 0.00) — needed because
  `DOD_INVOICE_ITEMS.PRD_ID` has a live FK to the product master;
* ⚠ a cosmetic CLSQL warning — *"Cannot commit transaction ... no transaction in progress"* — is printed
  when the assembly refuses INSIDE the transaction: the explicit `clsql:rollback` already ended it and
  `with-transaction`'s normal return then tries to commit. The rollback is real (the verifier asserts
  nothing was written); only the message is noise.

## 4. 🚨 Traps measured while building it

1. **A database-side trigger re-derives `INVNUM` from `ROW_ID`.** The verb minted
   `NST000duyrp6gvw1`; the row stored `NST00070-2026`. What `make` RETURNS is not what the table
   STORES, so `nst-invh`'s "the caller's value wins" is false. ⚠ `hhubuser` **cannot see
   `INFORMATION_SCHEMA.TRIGGERS`** — the list looks EMPTY while the trigger fires. Any writer of the
   invoice's number must re-read the row (the assembly does, via `invh-stored-header-row`).
2. **`DOD_INVOICE_HEADER.VNUM` is `varchar(20)`** and an ORDNUM is 23–27 characters, so storing the
   order number there TRUNCATED it (`ORD-DEMO-2026-27-3MZ`). The correlation goes in `CONTEXT_ID`
   (`varchar(100)`), which the legacy layer already treats as a lookup key.
3. **The grammar's `ord-id` is MISSING from the table.** Document 2 declares
   `nst-inv (ord-id … :accessor inv-ord-id)` and Document 4 asserts `inv-ord-id-unique?`; live
   `DOD_INVOICE_HEADER` has `VENDOR_ID`/`CUSTID`/`CONTEXT_ID` and **no order column**, so uniqueness is
   answered from the order's `IS_CONVERTED_TO_INVOICE`/`INVOICE_NUMBER` instead. The column is the
   predicate's real home.
4. **`NstInvhResponseModel` does not derive from `nst-response-model`** (it derives from
   `nst-boundary-object`), so `action->response`'s pass-through clause misses it and the model reaches
   `domain->response` with no applicable method → 500. **A route returns the ENTITY or a sentinel; the
   dispatcher ferries.** `NstOrdhResponseModel` is safe by contrast — it does derive from it.
5. **`paninigrammar/` has NO Document 3** (परिभाषा / नियम / state machines) although Documents 0, 1 and
   4 all cite it — the series runs 0, 1, 2, 4, 5. The नियम the code quotes (नियम-1 tenant, नियम-2
   deleted) are therefore only in the code.

6. **An ABAC policy/transaction pair for a NEW action belongs in an upgrade file, not in
   `core/dod-seed-data.lisp`.** The boot seed (`seed-auth-policies`) makes the policy table a function
   of *which image booted last*; a migration is applied once, keyed by version in
   `DOD_SCHEMA_MIGRATIONS`, and re-running it is a no-op. Three things must agree or the row is a
   trap of its own: the migration registered in `*migrations*` (`nst-sch-mig.lisp`), its
   `POLICY_FUNC` **naming a function that exists** in `hhub/core/dod-ui-pol.lisp` (a row pointing at
   nothing DENIES EVERY CALL once the PEP lands), and `DOD_AUTH_POLICY.DESCRIPTION` under 100
   characters — the column is `varchar(100)` under `STRICT_TRANS_TABLES`, so an over-long value is
   Error 1406, and `apply-migrations` catches per-migration and CONTINUES without recording the
   version, leaving a permanently re-running partial insert. The pair applied here is
   `com.hhub.policy.vendor.order.invoice` + `com.hhub.transaction.vendor.order.invoice`
   (`/hhub/dodvenordinvoice`, `CREATE`).

## 5. Where it lives, and its proof

| artefact | what it holds |
|---|---|
| `hhub/order/nst-bl-ordh.lisp` | the junction's बहुव्रीहि predicates (`nst-order-header-invoiced-p`, `…-service-nature-p`, `…-fulfilled-p`) and `nst-order-invoice-link-mark` — three columns, one at a time, never through `!update`, which `*ordh-never-writable-fields*` reserves for this verb |
| `hhub/invoice/nst-bl-invhapi.lisp` §9 | `invh-create-from-order` (predicates → header → one line per vendor line → the order's link, **ONE transaction with an explicit rollback**) and `route-invh-from-ord` (action route; no HTTP binding yet) |
| `hhub/vendor/dod-ui-ven.lisp` | the **Generate Invoice** button, `com-hhub-transaction-vendor-order-invoice` (calls the route in-process through `dispatch-route2`), the flash banner, and the `INVOICE <num> (DRAFT)` label that replaces the button |
| `hhub/sysuser/dod-ui-sys.lisp` | the dispatcher line for `/hhub/dodvenordinvoice` |
| `installation/upgrades/nst-dbu-freight-product.lisp` | the delivery-charge product per vendor (`FREIGHT-<vendor-id>`, SAC 9965) — the invoice line's FK needs a real row |
| `installation/upgrades/nst-dbu-order-policy-transaction.lisp` + `hhub/core/dod-ui-pol.lisp` + `hhub/core/nst-sch-mig.lisp` | the ABAC seed — `migrate-2026Oct-ordinvoice-policy-and-transaction`, registered in `*migrations*`, and the `com-hhub-policy-vendor-order-invoice` function its `POLICY_FUNC` names |
| `aiharness/deepseek/tools/nst-verify-invoice-from-order.lisp` | **41 pass / 0 fail / 0 skip** against the real DB: the draft, six lines totalling the vendor row's own `ORDER_AMT` (1986.45), the three link columns, the duplicate 409, the व्यंजन refusal, लोप ३ on the same order as `SRVC`, 404 for an unknown number — and it UNDOES everything it wrote |

**⚠ OPEN, recorded rather than hidden:** the invoice line's `UOM` is not a GST UQC code (the class
docstring says GSTR-1 needs one; live data proves today's path stores `"1.0 LTR"`); the invoice header
has no shipping column, so shipping is not represented on it; the invoice domain still has no HTTP
binding for `route-invh-from-ord`; and `restore-order-link` style un-flagging ("a draft the vendor
abandons") has no verb — the flag is written when the DRAFT is generated, by decision.

## 6. How the button gets back to its own page

The Generate Invoice form is built with **`with-html-form-having-submit-event`** (`dod-ui-utl.lisp:179`),
not `with-html-form`. That macro emits the form **plus its own submit listener**
(`submitformevent-js` → `submitformandredirect`, `site/public/js/dod.js`), which runs the browser's
`checkValidity`, POSTs the form by AJAX, and then does **`location.replace(response)`** — so the
controller's answer is the DESTINATION.

Three consequences, each of which bit or nearly bit:

* the controller returns a **URL and nothing else** (`/hhub/vorderdetailspage?id=…`, via
  `with-mvc-redirect-ui` + `create-widgets-for-genericredirect`), which is how the vendor lands back on
  the page they clicked from — the same shape the product details page's actions use;
* because the WHOLE BODY is the destination, **nothing may print into it** — `conflodis2` prints a
  trace line per dispatch, so the controller binds `*standard-output*` to a throwaway stream around
  the call. That is load-bearing, not tidiness;
* the submit control must be a real `<button type="submit">`, because the shared handler hides
  `button[type='submit']` while the POST is in flight (a double click would otherwise fire twice).
  **A BESPOKE jQuery handler for the form must NOT be added on top**: the macro's listener is already
  there, both would fire, and one click would POST twice — the second refused as a duplicate, but two
  requests for one click is still wrong.

⚠ `site/public/js/dod.js` is **CRLF**, so a tool that rewrites the file (a Python `write_text`, say)
silently converts every line and turns a one-line edit into a 1023-line diff. This feature therefore
touches it **not at all**.

## 7. ⚠ OPEN — amount discrepancies in the invoice layer (raised 2026-10-06, to resolve 2026-10-07)

The requester accepted the first draft and reported that amounts still disagree somewhere in the invoice
layer. The candidates below are what has actually been MEASURED; the first two are the likely ones. The
freight change is in the tree but **not in the running image** until the next restart, so an image older
than that still bills the goods alone.

| # | symptom to look for | evidence | one-line check |
|---|---|---|---|
| **1** | an invoice that is **short by the delivery charge** | the freight line is new (2026-10-06) and the image predates it; before that, invoice 85 for order 492 was ₹1437.35 against a ₹1517.00 order | `SELECT SHIPPING_COST FROM DOD_ORDER WHERE ROW_ID=<ord>` against the invoice's `TOTALVALUE` |
| **2** | a line billed at **0%** that should not be | MEASURED on order 492: Tata salt, `HSN_CODE '000000'` → no `DOD_GST_HSN_CODES` row → rate 0 → the line carries no tax, and it can also become the PRINCIPAL line whose rate the freight copies | `SELECT p.PRD_NAME, p.HSN_CODE, h.CGST, h.SGST FROM DOD_PRD_MASTER p LEFT JOIN DOD_GST_HSN_CODES h ON h.HSN_CODE=p.HSN_CODE WHERE p.ROW_ID=<prd>` |
| **3** | order total ≠ the sum of its vendor rows | MEASURED on 492: `DOD_ORDER.ORDER_AMT` 1437.00 while the vendor row (and the invoice) say **1437.35** — a legacy aggregation gap that predates this feature | compare `ORDER_AMT` with the vendor row's `ORDER_AMT` |
| **4** | an ORDER line whose tax columns are 0 but whose total includes tax | MEASURED on order 488's line: `TOTALITEMVAL` 1345.20 with `CGSTAMT`/`SGSTAMT`/`IGSTAMT` all 0.00 — the invoice line recomputes the tax from the product's HSN rate and lands on 1345.20 anyway, but a comparison against the ORDER's own columns looks wrong | compare the order line's columns with the invoice line's |
| **5** | two vendors' freight shares that do not look like a clean split | by design: non-largest vendors are rounded to the paise and the LARGEST absorbs the residual, so the shares SUM to the order's charge exactly but an individual share can differ from a naive pro-rata by ≤0.01 | `invh-freight-share` on each vendor of the order |
| **6** | an invoice line disagreeing with a recomputation from the order | by design: `invh-line-taxable-value` prefers the order's STORED `TAXABLEVALUE` over recomputing qty × price × (1 − disc/100), because the stored value is the order's own arithmetic | compare the two |
| **7** | legacy invoices whose header total ≠ their lines | MEASURED: invoice 35 holds `TOTALVALUE` 3369.00 against lines summing 5714.63 — nothing this feature wrote (every invoice it creates sets `TOTALVALUE = Σ lines`, asserted by the verifier) | `SELECT h.TOTALVALUE, SUM(i.TOTALITEMVAL) … GROUP BY h.ROW_ID` |

**Not a discrepancy, checked and cleared:** the `DISCOUNT` column holds a **PERCENT** (live rows: 5.00 with
`TAXABLE_VALUE = QTY×PRICE×0.95`), which reads oddly against the class docstring's amount wording
("(qty × price) − discount") — but the printed header is *"Less: Discount%"* and `nst-ui-itm.lisp` computes
it as a percent, so print, data and code agree. The docstring is the outlier, not the data.
