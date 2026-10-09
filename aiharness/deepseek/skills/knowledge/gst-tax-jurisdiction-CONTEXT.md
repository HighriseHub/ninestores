# gst-tax-jurisdiction — freight on an invoice, and which state's tax applies

**What this file is:** the two GST questions the cart and the invoice keep meeting, settled with measurements.
The step-by-step record, every number and every mistake that produced these rules is
`../archive/gst-tax-jurisdiction-SNAPSHOT-2026-10-08.md`. The GST *return* surface is
`gst-gstr-compliance-CONTEXT.md`; the ord→inv junction is `ord-to-inv-junction-CONTEXT.md`.

## 1. A delivery charge is part of the value, taxed at the goods' rate

Delivery is in the taxable value (Section 15(2)(c) CGST "any other costs incurred by the supplier in relation
to the supply") and, being ancillary to the goods, a **COMPOSITE SUPPLY taxed at the principal supply's rate**
(Section 2(30) with Section 8) — NOT a flat 18%, which is right only when transport is a SEPARATE supply
(courier/logistics at 18% — the West Bengal appellate authority refused the exemption for a marketplace's
delivery fees: [CNBC-TV18](https://www.cnbctv18.com/business/companies/flipkart-delivery-transport-services-liable-for-18pc-gst-west-bengal-appellate-authority-ruling-aar-ws-l-19903766.htm/amp)
— or a GTA's own regime, Notification 13/2017 RCM and 22/2017 forward charge **[CONFIRM rates]**).
[Section 15, CBIC](https://taxinformation.cbic.gov.in/content/html/tax_repository/gst/acts/2017_CGST_act/active/chapter4/section15_v1.00.html) ·
[composite vs mixed, NJA](https://www.nja.gov.in/Concluded_Programmes/2020-21/P-1252_PPTs/1.Composite%20and%20Mixed%20Supply%20in%20GST.pdf) ·
[54th Council, GTA ancillary services](https://gstcouncil.gov.in/sites/default/files/Agenda/54_meeting_agenda_0.pdf)

**Market/software practice:** all three packages model freight as a separate TAXED item, and the
inclusive/exclusive choice is a SETTING, not a property of the buyer — Odoo documents "create a separate
Delivery Product for each [delivery] method" and an App exists purely to make the delivery rule's price
untaxed ([Odoo](https://app.readthedocs.org/projects/odoo-book/downloads/pdf/latest/),
[del_rule_price_untaxed](https://apps.odoo.com/apps/modules/19.0/del_rule_price_untaxed)); Zoho Books has a KB
article for adding shipping AS AN ITEM and a community thread about the friction
([Zoho](https://zohohelp.com/in/books/kb/gst/gst-shipping-charge.html),
[community](https://help.zoho.com/portal/es/community/topic/unable-to-charge-gst-on-shipping-packing-forwarding-charges-in-india));
Tally keeps an article on the tax liability of transportation charges
([Tally](https://tallysolutions.com/gst/tax-liability-on-transportation-charges-in-invoice/)). ⚠ Search
results only — cited as pointers, not readings.

## 2. The configured amount is GROSS — for every buyer

Measured: `DOD_SHIPPING_METHODS` has **no tax column** (`FLATRATEPRICE`, `FLATRATETYPE`, `MINORDERAMT`,
`RATETABLECSV`, the enabled flags) and `DOD_VENDOR_SHIP_ZONES` only zone names and zip ranges; the cart has
always charged the configured amount as it stands. So "100" means **the customer pays 100**, tax inside it:
taxable 84.75 + tax 15.25. Reading it as pre-tax for B2B silently raised the delivery price by 18% for
registered buyers — the same configured amount giving two different totals.

| goods ₹1000 @18% + delivery configured ₹100 | delivery LINE | taxable | tax | customer pays |
|---|---|---|---|---|
| B2B (the buyer gave a GSTIN) | yes — the ITC is visible on the order and the invoice | 84.75 | 15.25 | **₹1280.00** |
| B2C (no GSTIN) | no — one simple charge; the invoice carries the line | 84.75 | 15.25 | **₹1280.00** |

⚠ The pre-tax reading is real practice (a supplier quoting freight ex-GST to a business) but it is a PRICING
decision belonging in the vendor's configured amount, never a silent consequence of the buyer's registration.

## 3. The cart's pages: one rule for the total, one for the display

| value | what it is | what may use it |
|---|---|---|
| `SHIPPING_COST` (hash key and model local) | the charge **that is still a charge** — 0 when the delivery is one of the LINES (B2B: `shopcart-total` already has it), the charge when it is not (B2C) | **ARITHMETIC ONLY**: payable = `shopcart-total + shipping-cost` |
| `delivery-gross` / `delivery-display` | what the customer pays for delivery | **DISPLAY ONLY**: the "Shipping" row and the render-only header object the template prints |

Applied at `hhubcustshippingmethodspage`, `hhubcustpaymentmethodspage`, `hhubcustorderupipage` and
`dodcustshopcartro`. ⚠ **`create-model-for-custordercreate`'s values list is the ONE place that must keep
`shipping-cost` as the charge-left** — it is the DB-FACING one: the order stores it and the invoice's fallback
reads it, so passing the gross there would store the delivery twice and make the invoice add a second line.

**The charge is a LINE only for B2B**, from that vendor's `FREIGHT-<vendor-id>` product (seeded by
`installation/upgrades/nst-dbu-freight-product.lisp`; `DOD_ORDER_ITEMS.PRD_ID` has a live FK to the product
master) and taxed at the **principal goods' rate** — the highest-taxable-value goods line
(`nst-principal-rate-of`). The halves are DERIVED from the tax, not recomputed from the rates, so
`taxable + taxes = the line total` exactly (an inclusive 100 gives 7.63 + 7.62, not 7.63 twice).
Guards: a `PRD_TYPE='SERV'` line never touches stock; **multi-vendor carts are left alone** (one charge cannot
be attributed to several vendors — per-vendor shipping is its own step); the invoice asks
`nst-order-has-freight-line-p` first, so an order never carries two delivery charges.

## 4. The three-page flow, and where a state becomes a tax decision

| page | what it does | what the rules require of it |
|---|---|---|
| `dodcustordershipaddrpage` | pincode typed; JS calls `/hhub/hhubpincodecheck` → `get-pincode-details-adapter` → **data.gov.in, external**, Belnap-mapped; fills city + **state as a NAME**; fields editable ON PURPOSE. A local source exists: `DOD_INDIA_PINCODES.STATENAME` | resolve the typed text to a **GST state CODE** here; the PINCODE is an independent authority for the delivery state |
| `hhubcustshippingmethodspage` | computes the GST and the shipping; **the delivery line is created here** | compare **codes**; refuse rather than guess when a code is missing |
| `hhubcustpaymentmethodspage` | displays the money; shipping is computed from `shipzipcode` + the vendor's settings, NOT the state | show the delivery charge; do not re-add it |

**The live bug this fixed:** `update-gst-for-order-lineitem` compared the customer's typed state NAME against
the vendor row's `state` — a **CODE** for vendor 1 ("29") and a **NAME** for vendors 2-3 — so
`(equal "KARNATAKA" "29")` made every such sale INTER-state. Measured: order 488 carries IGST 205.20 with
CGST/SGST 0.00. It now compares through `nst-same-gst-state-p` (core), and an unresolvable state is **neither
same nor different** — never evidence of another state. ⚠ The B2B path was also **unreachable** until
2026-10-08: `display-gst-widget` was defined and called from NOWHERE, so `gstnumber` was always NIL.

## 5. Traps — every one of these cost a page or a wrong number

1. **`fround` is COMMON-LISP's standard function** — "round to the nearest INTEGER, as a float". Six money
   totals in `order/nst-bl-Order.lisp` and `invoice/nst-ui-ihd.lisp` used it, so totals were rounded to whole
   rupees (`(fround 3815.20)` = 3815.0, the 0.20 gap measured between legacy invoice 65's header and its own
   lines). All six now use `round-to-2-decimal` (core), as the line amounts do.
2. **The model/widget seam.** A page's widgets are a SEPARATE FUNCTION that sees only what the model RETURNS;
   a model-local used in them is an **UNBOUND-VARIABLE at render time** — invisible to the reader, the
   compiler and every offline harness (measured: `DELIVERY-DISPLAY` 500'd the payment page).
   `aiharness/deepseek/tools/nst-model-widget-check.lisp` now checks every pair in `hhub/` (103 pairs) and
   found 4 pre-existing page-breakers: `custshipmethodspage` (`company` — fixed: the model returns `custcomp`,
   so that page had been computing its CURRENCY SYMBOL from NIL), `displayinvoiceemail` (`draftemailtext`),
   `displayinvoicepublic` (`reason`), `showwarehouses` (`username`). The last three are LEFT ALONE.
3. **A vendor row's `ORDER_AMT` overstates its lines** when a qty>1 line carries tax: `calculate-order-item-cost`
   adds the WHOLE-LINE tax per unit and `get-order-items-total-for-vendor` then multiplies by qty — measured on
   order 472: vendor row 2045.44 against lines 1774.72. **NOT fixed.**
4. **The invoice header cannot hold an order number** (`VNUM` is varchar(20), an ORDNUM is 23-27 characters →
   silent truncation), it has **no shipping column**, and every printed total is computed from the **ITEMS** —
   so a charge that is not a line can neither print nor reconcile.
5. **A database-side trigger re-derives `INVNUM` from `ROW_ID`** (the verb minted `NST000duyrp6gvw1`, the row
   read `NST00070-2026`), and `hhubuser` cannot see `INFORMATION_SCHEMA.TRIGGERS` at all.
6. **`paninigrammar/` has no Document 3** (परिभाषा / नियम / state machines) although Documents 0, 1 and 4 cite
   it — the series runs 0, 1, 2, 4, 5.

## 6. Must the customer SEE the tax at checkout? — No

The disclosure duty attaches to the **tax invoice** (Rule 46: description, HSN/SAC, quantity, taxable value,
**rate and amount of tax**, place of supply, reverse-charge declaration), not to the cart. A shopfront must
disclose the **total price with every compulsory charge** (consumer-protection side, e.g. the CCPA penalty for
misleading pricing — [PIB](https://www.pib.gov.in/PressReleasePage.aspx?PRID=2171807&reg=3&lang=2);
[NACIN e-commerce/GST handbook](https://www.nacin.gov.in/ZCVisakhapatnam/Images/Documents/EBooks/e-Book%20on%20e-Commerce%20Operators%20and%20GST%20-%20NACIN%20Vizag%20(September,%202024).pdf)).
That is why the invoices the requester receives never show a freight GST figure: the freight sits inside a
delivered price, or is shown as a line with no separate breakup, or delivery is free. But the cart **must**
charge the tax on it — Section 15(2)(c) puts the freight in the value whether or not it was billed.

## 7. Open, and the proof of what is done

**Open:** the two `[CONFIRM]` questions for a CA (does the vendor deliver its own goods — composite — or is
transport separately contracted; is any vendor a GTA); per-vendor shipping for multi-vendor carts
(the ship-methods page still prices ONE vendor and copies the charge into every vendor row — measured on
order 222: two rows, both 70.00, order 70.00); the qty>1 vendor-total overstatement (§5.3); showing the
delivery row on a rendered ORDER, which prints the stored 0 for a new B2B order (the line carries it).

**Proof:** `nst-verify-cart-tax-state.lisp` — **80 pass / 0 fail**, writes nothing — drives the CART's own
call and asserts the state rule, the paise rule, the gross-for-everyone split, the B2B line, the B2C
charge, and the merge (including the display gross and the zeroed column).
`nst-verify-invoice-from-order.lisp` — **63 pass / 0 fail**, writing and undoing — the DRAFT, the lines, the
order's link columns, the duplicate 409, the व्यंजन refusal, लोप ३, and the legacy charge invoiced
inclusively so the invoice total EQUALS the order's.
