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

---

## 8. ONE ROUNDER, ONE AUTHORITY — the line-money rule (2026-10-11)

**The rule:** a line's money is produced in exactly ONE place, `nst-line-money` (`core/dod-bl-utl.lisp`,
next to `nst-shipping-tax-split`, which it uses for the inclusive case), and every channel calls it or
copies from a channel that did. It returns
`(values TAXABLE CGSTRATE SGSTRATE IGSTRATE CGSTAMT SGSTAMT IGSTAMT TOTALITEMVAL)`, all to the paise by
`round-to-2-decimal` — the one rounder, which the invoice layer's `invh-paise` now delegates to.

**Why it exists — THREE sites were computing the same line, differently:**

| channel | before |
|---|---|
| cart → order (`order/dod-bl-odt.lisp`, `update-gst-for-order-lineitem`) | rounded, code-aware state test |
| order → invoice (`invoice/nst-bl-invhapi.lisp`) | `invh-paise`, `(equal statecode placeofsupply)` |
| walk-in invoice (`invoice/nst-ui-ihd.lisp`, `invoice/nst-ui-itm.lisp`) | **NO rounding at all**, `equal` state test |

and a fourth stored whatever it was given: **`make 'nst-invitm` (the invoice-line API) has no money check
at all** — the client's figures go in verbatim, where the ORDER API deliberately checks its pair and
answers 409 (`nst-bl-orderhapi`: taxable vs `qty × price × (1 − disc/100)`, total vs base + taxes).

**Copy, do not recompute.** A channel that has a SOURCE transcribes it: `invh-line-args-from-order-line`
copies the order line's taxable value, amounts and total whenever the order stored a positive total, and
computes only for a legacy line that stored no money (rates: stored → principal-rate override → product
HSN). MEASURED, and the reason: invoice `NST00117-2026` re-derived a freight line the order had stored as
`2.86 + 2.85 = 120.00` and wrote `2.86 + 2.86 = 120.01`, so the header read 1600.51 against the order's
1600.50. A walk-in invoice has no source, so there the function IS the authority.

**The two branches, and why the inclusive one has a residual.** EXCLUSIVE (goods): `TAXABLE =
round(qty × price × (1 − disc/100))`, each half `round(TAXABLE × its rate/100)` independently. INCLUSIVE
(a charge the customer pays gross): TAXABLE is back-calculated, and the halves are derived FROM THE TAX,
the second taking the residual — rounding each rate separately adds a paise (₹120 at 2.5 + 2.5:
`114.29 + 2.86 + 2.85 = 120.00`, where `2.86 + 2.86 = 120.01`). ⚠ **The residual must itself be rounded**:
`(- 5.710000000000001 2.86)` is `2.8500000000000014` in binary floating point, which the `decimal(15,2)`
column silently repaired while every in-memory total carried the noise.

**And the state test is the code-aware one** (`nst-same-gst-state-p`), in every channel now — see §2 for
the NAME-vs-CODE bug it fixes.

**Proof:** `../tools/nst-check-one-rounder.lisp`-style probe (32 checks, read-only): `invh-paise` IS
`round-to-2-decimal`; the inclusive residual and the exclusive rule on the same ₹120 charge; a NAME and its
CODE answering one state; the cart's delivery line and the invoice's legacy fallback producing IDENTICAL
money; and order 505's three real lines transcribed to the invoice with **no drift** (the invoice's lines
sum to the order's own line total). Runs with `*NSTGSTSTATECODES-HT*` initialised or every state NAME
fails to resolve. Regressions re-run: `nst-verify-cart-tax-state.lisp` 80/0.

**Still open:** the invoice-line API's money (`make 'nst-invitm` — check-and-refuse, or compute), and the
SAC side of the rate lookup, which is `gst-sac-codes-CONTEXT.md`.

### 8.1 The verification lesson from the first pass (2026-10-11)

**A money-only assertion cannot catch a rate-column bug, and a suite can pass on two errors that agree.**
The first version of the transcription rule read the wrong three elements out of `nst-line-money`'s eight
values (`(first computed)` where the taxable value sits) and put the **taxable value into `CGSTRATE`**. The
read-only probe passed — it asserted taxable value, amounts and total, never the rates — and the
order→invoice suite's own rate check *passed too*, because the delivery line's "principal rate" was derived
from the same corrupted goods line, so corruption matched corruption. What caught it was the check that
compares the delivery line's **price** to `charge / (1 + rate)`: the line priced ₹40.00 of delivery at
**3.20** instead of 33.90. Two repairs: the probe now asserts `:cgstrate/:sgstrate/:igstrate` as well
(**41 checks**), and the rule is written with `nth 1/2/3`, not `first/second/third`.

**And two suites had drifted behind the code, silently:**

* `nst-verify-invoice-from-order.lisp`'s "unfulfilled" fixture had since been FULFILLED, so the व्यंजन rule
  could not refuse it and §5 went on to WRITE the invoice whose absence it then asserted. Re-pointed
  (order 443, one vendor-1 line, no delivery charge) and the premise is now **guarded**: a drifted fixture
  exits 2 instead of leaking an invoice.
* `nst-verify-invoice-dispatch.lisp` compared the public-link key to a literal that predates the
  `expires-at` field, so it could never pass again; it now decodes with the code's own
  `invoice-ext-b64-decode` and asserts the stable fields.

Both suites after the repairs: **order→invoice 63/0/0**, **invoice dispatch 51/0**.

### 8.2 The spare paise belongs in the TAXABLE VALUE — and the money arithmetic is INTEGER PAISE (2026-10-11)

**What was wrong.** §8's first version gave the odd paise of an inclusive charge to SGST: for a ₹80.00
delivery at 2.5 + 2.5 the tax inside is 3.81, which cannot split into two equal whole paise, so it wrote
**CGST 1.90 / SGST 1.91**. MEASURED on order 506's own line (row 1297). On an equal-rate intra-state supply
that asymmetry is what an accountant reads as a defect: **CGST and SGST must be the same figure.**

**The rule now (`nst-inclusive-paise-split`, core/dod-bl-utl.lisp).** The VALUE gives, not a tax head: take
the rate-derived taxable value and one paise either side, and use the first for which

    TAXABLE + (each half at its OWN rate) = the gross exactly

Then CGST = SGST whenever the rates are equal — equal *by construction*, each half exactly its rate × the
taxable value — and the line still totals what the customer paid. MEASURED:

| charge (inclusive) | before | now |
|---|---|---|
| ₹80.00 at 2.5 + 2.5 | 76.19 / 1.90 / 1.91 / 80.00 | **76.20 / 1.90 / 1.90 / 80.00** |
| ₹120.00 at 2.5 + 2.5 | 114.29 / 2.86 / 2.85 / 120.00 | **114.28 / 2.86 / 2.86 / 120.00** |
| ₹100.00 at 9 + 9 | 84.75 / 7.63 / 7.62 / 100.00 | **84.74 / 7.63 / 7.63 / 100.00** |
| ₹40.00 at 9 + 9 (the invoice fixture) | 33.90 / 3.05 / 3.05 / 40.00 | unchanged |
| ₹100.00 inter at 18% | 84.75 / IGST 15.25 / 100.00 | unchanged — **no paise solution exists** |

⚠ **THE LAST ROW IS THE HONEST LIMIT:** 84.74 → 15.25 → 99.99 and 84.75 → 15.26 → 100.01, so no taxable
value satisfies the identity. There the TOTAL is never sacrificed and one head takes the odd paise (the old
residual rule survives as the fallback). The price of the fix is one paise in the TAXABLE VALUE — the totals
never move.

🔑 **AND THE ARITHMETIC IS INTEGER PAISE, NOT FLOATS.** `(* 76.20 0.025)` is `1.9050000000000002` in
binary, so a float test lands a hair ABOVE the half-paise tie and rounds it up: the float version of the
solver **failed its own solution test on ₹80.00 and fell back to the residual — the very defect it was
written to remove.** Rates therefore become INTEGER BASIS POINTS (2.5% → 250) and taxable values integer
paise, so every product and division is exact and CL's `round` decides the tie deliberately. This is the
concrete instance of §3/§4 of `multi-jurisdiction-tax-CONTEXT.md`: the rounding MODE and PRECISION have to
be policy, because binary floats decide them otherwise.

**Verification.** The read-only one-rounder probe gained three inclusive cases, the equal-halves assertion
and the no-solution case — **61 checks, 0 fail**; `nst-verify-cart-tax-state.lisp` **80/0** after five of its
expectations were deliberately moved to the new rule (84.74 / 7.63 / 7.63, and the cart's tax total
180 + 15.26); `nst-verify-invoice-from-order.lisp` **63/0**; `nst-verify-invoice-dispatch.lisp` **51/0**.

### 8.3 The shipping PAGE must render the server's decision, never re-decide it (2026-10-11)

**Reported:** 2 × product 75 (₹750, 5% disc) — no GSTIN: STANDARD, items ₹1496.24 + delivery ₹120 =
₹1616.24. **With** a GSTIN: the shipping page said *"You've unlocked FREE Shipping!"* while the payment page
still showed ₹120 and ₹1616.24.

**The charge was right in BOTH.** The server's rule (`customer/dod-ui-cus.lisp:2986-2993`) tests the GOODS
with `>=` against the minimum and found 1496.24 < 1500 → standard, ₹120 — and the payment page is
self-consistent (`shopcart-total` 1616.24 + `shipping-cost` 0, the ₹120 riding inside the delivery LINE, with
the gross shown as the "Shipping Cost" line). Only the shipping PAGE lied, because
`display-cust-shipping-costs-widget` re-derived the decision from two values that had already changed meaning:

* it read the **stored `shipping-cost`** — which in B2B is 0 because the charge became one of the LINES
  (`chargeleft`), not because delivery is free — and used `(= shipping-cost 0)` as the "is it free?" test;
* it tested the threshold against `shopcart-total`, which by then **already contains the delivery line**
  (1616.24), so *being charged for delivery was what made the order look eligible for free delivery*;
* and it used `>` where the server uses `>=`, and would `TYPE-ERROR` on a NIL minimum.

**The fix:** `SHIPLST` is `(COST OPTIONS MINIMUM PAGE)` — `(nth 0 shiplst)` **is** the server's decision
(0 only when its own rule said free). The widget now branches on that, treats the minimum as TEXT only, and
has a fallback arm (no arm used to match when shipping was enabled, cost 0 and free shipping unconfigured —
and the whole section rendered nothing).

**Verified by driving the real widget** (read-only probe, `get-cust-order-params` stubbed in-process and
restored): 2 × cake B2C → STANDARD; 2 × cake **B2B → STANDARD** (the reported bug); 3 × cake (2244.36 ≥ the
minimum, server cost 0) → FREE. **4 pass / 0 fail.**

**The durable rule this is the third instance of:** on this page a **zero carries two meanings** —
"the delivery is already one of the LINES" and "the delivery is FREE" — so the value that MEANS "free" must
be the shipping rule's own output, and every threshold is tested ONCE, upstream, against the goods.

**Round two (same day), after the branch fix:** the page rendered Standard but its MESSAGE still congratulated
the customer, and its "Cost of Items" line showed the post-delivery-line total. Both were the SAME circular
test, in the renderer: `render-standard-shipping-page` used the `shopcart-total` it was handed for
"Cost of Items" AND for `(< shopcart-total freeshipminorderamt)` — and the model was passing the total that
ALREADY CONTAINED the delivery line (₹1616.24), so an order of ₹1496.24 of goods "qualified" for free
shipping while being charged ₹120. So:

* the **model keeps `goods-subtotal`** (bound BEFORE the delivery-line step re-setf's `shopcart-total`) and
  returns THAT as the page's subtotal;
* `render-standard-shipping-page` shows it as "Cost of Items", tests the threshold against it, and computes
  **Total = goods-subtotal + DELIVERY-DISPLAY** — the two visible parts now add up to the Total and to the
  payment page's figure, in B2B and B2C alike;
* `shipping-cost` (the total-arithmetic value) is deliberately UNUSED on that page — declared `ignore` with
  the reason, since using it is what showed "₹120.00" beside a Total that had added 0.

**Verified by driving the real widget + renderer** (read-only): 2 × cake B2C → Standard, 1496.24 + 120.00 =
1616.24, "Shop for ₹3.76 more"; 2 × cake **B2B** → the SAME figures and message (the reported bug); 3 × cake
→ FREE. **16 pass / 0 fail.**

⚠ **The two payment pages legitimately look different for the same money** — B2C shows *Amount Before Tax
1425.00 / After Tax 1496.24 / Shipping 120.00 / Total 1616.24* (the delivery stays an untaxed charge), B2B
shows *1539.28 / 1616.24 / 120.00 / 1616.24* (the delivery is a TAXED LINE: 1425.00 + 114.28 taxable, tax
71.24 + 5.72). That is the B2B/B2C design of §1, not a defect: the same ₹120 in both.
