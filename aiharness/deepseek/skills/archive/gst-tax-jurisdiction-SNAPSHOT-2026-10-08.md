# ARCHIVE — gst-tax-jurisdiction, the step-by-step record as of 2026-10-08 (505 lines)

The rules live in `../knowledge/gst-tax-jurisdiction-CONTEXT.md`; THIS file is the narrative that produced
them, kept verbatim so no measurement is lost: the delivery charge as a line, the state comparison, the
paise rounding and `fround`, the model/widget seam, and the gross-versus-pre-tax decision with the market
research. Read it when a rule's reasoning is in question, not as the reference.

---

# gst-tax-jurisdiction — freight on an invoice, and which state's tax applies

**What this file is for:** the two GST questions the cart and the invoice keep running into — **how a
delivery charge appears on a tax invoice**, and **how the intra-state/inter-state decision is made** (which
state's tax applies). Both were raised by the ord→inv work in October 2026 and both are settled here with
measurements, not opinions. The GST *return* surface (GSTR-1/3B, ITC, the schema that exists for it) is
`gst-gstr-compliance-CONTEXT.md`; the ord→inv junction itself is `ord-to-inv-junction-CONTEXT.md`.

Sections: **§1** freight on a tax invoice (the law, the three treatments, and the implemented one) ·
**§2** the cart's state comparison (the live bug: IGST on an intra-state sale) · **§3** the three-page cart
flow and where the fix belongs.

---

## 1. Freight / shipping charges on a tax invoice — the law, the options, and what it decides in the code

Raised 2026-10-06 by the ord→inv work: order 492 was invoiced for ₹1437.35, the order's ₹80.00 shipping was
not on the invoice at all. Measured first, because it constrains everything else:

* `DOD_INVOICE_HEADER` has **no shipping column**, and the templates have shipping *addresses* only;
* **every printed total is computed from the items** — `%Total Value%` ← `calculate-invoice-totalaftertax
  (invoiceitems)` (`nst-ui-ihd.lisp:1310`), and the same for before-tax / GST / CGST. A header-only freight
  amount would never print, and the printed total would not add up to the bill;
* `DOD_INVOICE_ITEMS.PRD_ID` has a **live FK to `DOD_PRD_MASTER`** (`DOD_INVOICE_ITEMS_ibfk_2`), so a freight
  "line" needs a real product row; and
* the order's shipping is **copied into EVERY vendor row** — order 222 has two live vendor rows and BOTH
  carry 70.00 while the order carries 70.00. Billing "the vendor row's shipping" on each vendor's invoice
  would charge ₹140 for a ₹70 delivery.

So, in this schema, freight can only appear **as an invoice line** (or as value folded into a goods line).

### The law, as far as primary sources go

⚠ I read search snippets, not the circular texts. Items marked **[CONFIRM]** are the ones to put in front of
a CA before the shape is frozen; the rest are settled readings of the statute.

1. **Value of supply includes what the supplier charges for delivery.** Section 15(1) takes the transaction
   value; **Section 15(2)(c)** makes the value include *"incidental expenses, including commission and
   packing, charged by the supplier to the recipient of a supply and any other costs incurred by the supplier
   in relation to the supply"* — [CBIC, Section 15](https://taxinformation.cbic.gov.in/content/html/tax_repository/gst/acts/2017_CGST_act/active/chapter4/section15_v1.00.html),
   [ICSI Advance Tax Laws (the Section 15 table)](https://www.icsi.edu/media/webmodules/16112021_Advance_Tax_Laws.pdf),
   [TaxGuru on freight/packing/ancillary charges](https://taxguru.in/goods-and-service-tax/freight-packing-ancillary-charges-gst-textile-industry.html).
   **Consequence for us: omitting the ₹80 is not cosmetic — it understates the taxable value and
   under-collects the tax on it.**
2. **If delivery is part of the same supply, it is a COMPOSITE SUPPLY and takes the goods' rate.**
   Section 2(30) (naturally bundled, one principal supply) with **Section 8**: tax at the rate of the
   principal supply — [Composite Supply (NJA)](https://nja.gov.in/Concluded_Programmes/2017-18/P-1097_PPTs/7.Classification%20-%20Mixed%20and%20Composite%20Supply.pdf).
   A *mixed* supply (2(74)) — the highest of the rates — is the wrong category for delivered goods unless the
   items are genuinely independent.
3. **A SEPARATE transport supply is a different animal.** If transport is contracted separately (customer
   arranges it, or the supplier also acts as a transporter), it is its own supply at its own rate under its
   own SAC — and then **the place of supply can differ from the goods'**: goods follow the delivery location
   (Section 10(1)(a) IGST) while a transport *service* follows the recipient's location (Section 12(8)).
   Two places of supply on one invoice is the thing to avoid unless it is real.
4. **GTA (goods transport agency) is where the trap sits.** GTA services to a specified person are under
   **reverse charge** (Notification **13/2017**-CT(R)), and a GTA may instead opt for forward charge
   (Notification **22/2017**) **[CONFIRM the current rates/conditions]**. The 54th GST Council clarified the
   *ancillary* case — services like loading/unloading, packing, unpacking, transshipment provided by a GTA
   around the transport are part of the **composite supply of transport**, not separate supplies —
   [PIB release, 54th Council](https://www.pib.gov.in/PressReleasePage.aspx?PRID=2053324&reg=3&lang=2),
   [54th meeting agenda, item 2](https://gstcouncil.gov.in/sites/default/files/Agenda/54_meeting_agenda_0.pdf),
   and see [composite supply of transport of goods](https://gst-vinaykaushikandco.blogspot.com/2025/01/composite-supply-of-transport-of-goods.html).
   **Our case is one step earlier: the VENDOR supplies the goods and delivers them — the vendor is not
   selling transport, it is charging for delivery of its own goods.**
5. **Rule 46 (invoice particulars)** wants HSN, description, quantity, taxable value, rate and amount of tax
   per line, the place of supply, and whether tax is payable on reverse charge; **Rule 138 (e-way bill)** and
   the consignment-value threshold are already a legal flag in the grammar corpus (Document 4, flag 3).
6. **GSTR-1/HSN summary** aggregates per HSN and rate, so a freight line with its own HSN/SAC reports
   separately from the goods — visible in Table 12, and a reconciliation item.

### The three defensible treatments, and what each costs us

| # | treatment | correct when | code consequence |
|---|---|---|---|
| **A** | **Freight as a line, taxed at the PRINCIPAL supply's rate** (same HSN as the goods, or the goods' rate) | the vendor sells and delivers its own goods — the ordinary B2B case | our line tax is derived from the PRODUCT's HSN rate, so either the freight product must carry the goods' HSN **[data hack]**, or the conversion must override the rate for a composite line **[needs a rule]** |
| **B** | Freight as a separate SERVICE line at its own SAC/rate (18% or GTA 12%/RCM) | transport is genuinely separate (own contract, own supplier, or the vendor acting as GTA) | needs the vendor's GST standing, a SAC, and possibly a **second place of supply**; RCM must be declared on the invoice (`REVCHARGE` column and `%Reverse Charge%` exist) |
| **C** | Freight **included in the goods' taxable value**, no separate line | same facts as A, when the buyer does not want a line | least visible to the customer, and the invoice's own table adds up with no new concept — but the order page shows shipping separately, so the documents disagree in presentation |

**✅ IMPLEMENTED 2026-10-06 AS TREATMENT A** (the requester supplied the confirming position: composite
supply, freight at the same rate as the principal goods, SAC 9965 on the line). How it works in the code:
`invh-freight-line-args` prices the line at the vendor's share and takes its rate triple from
`invh-principal-rate-triple` — the **highest-taxable-value goods line**, the practical proxy for the
predominant element — so the SAC's own rate is never consulted (it has none: SAC 9965 is absent from
`DOD_GST_HSN_CODES`, measured). Verified: `nst-verify-invoice-from-order.lisp` asserts the freight line's
rate EQUALS the goods line's rate, its tax is the charge at that rate to the paise, and the invoice total is
the goods plus the delivery charge and its tax. The rule for mixed-rate goods (order 492's lines are 0% and
18%) is the highest-value line's rate; **if the CA prefers a pro-rata split across rate groups, that is the
one thing to change** — `invh-principal-rate-triple` is the only place it lives.
**What remains open:** the two `[CONFIRM]` questions below (FOR/delivered vs separate transport; any GTA),
and whether the freight product should stay visible in the vendor's catalogue (it is seeded approved+active,
so it appears in product lists — harmless, and arguably useful).

The reasoning that produced A, kept because a CA will ask for it:
**A, with the rate taken from the principal supply (the goods lines), not
from a service SAC** — one line titled *Transport / Freight charges*, its HSN the principal goods' HSN, tax
split intra/inter exactly like the other lines, so the invoice's table, its total and the HSN summary all
agree, and no second place of supply is introduced. B is only right if the CA says transport is a separate
supply; C understates nothing but hides the charge.

### Decisions this forces (and their code consequences)

* **[CONFIRM] Is the vendor delivering the goods itself (delivered/FOR price)?** → A vs B.
* **[CONFIRM] Is any vendor a GTA or using a GTA?** → whether `REVCHARGE` and the RCM sentence on the
  printed invoice must be set for the freight line.
* **Multi-vendor (decided 2026-10-06): split the ORDER's shipping across its vendors in proportion to their
  line value**, because each vendor raises its own invoice — so the shares must sum to the order's shipping,
  with a deterministic rounding rule (largest remainder to the paise). ⚠ The vendor row's own `SHIPPING_COST`
  is a COPY of the order's, never a per-vendor entitlement.
* **The freight product**: one per vendor (so `PRD_ID`'s FK is satisfied and GSTR-1 has a code) — seeded by
  migration like the ABAC pair, from values the requester supplies (name, HSN/SAC, rate, UQC).
* **Nothing is implemented until [CONFIRM] is answered**: the ₹80 omission is a compliance gap, and the
  shape chosen decides whether the conversion overrides a line's rate.

## 2. The CART's GST state comparison — interstate tax on an intra-state sale (diagnosed 2026-10-06)

Reported by the requester against `hhubcustpaymentmethodspage` ("it misses the state and jumps to IGST"),
with the pointer to `dodcustordershipaddrpage` where the state is collected. **The cause is one string
comparison, and the database proves it.**

**The comparison** — `update-gst-for-order-lineitem` (`order/dod-bl-odt.lisp:196`, the tree's ONE statement
of the intra/inter rule, called by BOTH the customer cart and the API's line writer):

    (intrastate (if (equal vstate placeofsupply) T NIL))     ; equal, on two RAW strings

and at the cart's call site (`customer/dod-ui-cus.lisp:2784`, inside
`create-model-for-custshipmethodspage`) the two sides are:

    (update-gst-for-order-lineitem lineitem itemproduct (string-upcase shipstate) (string-upcase vstate))
    shipstate ← (hunchentoot:parameter "shipstate")   ; a FREE-TEXT input, pre-filled with the customer's
                                                     ; saved state NAME — "Karnataka"
    vstate    ← (slot-value singlevendor 'state)     ; the vendor row's `state` column

**🚨 THE VENDOR COLUMN HOLDS EITHER A CODE OR A NAME, IN THE SAME TENANT (measured):** vendor 1 `STATE` =
**"29"**, vendors 2 and 3 = **"Karnataka"**. So `(equal "KARNATAKA" "29")` is NIL → **interstate → IGST**,
for a Karnataka seller selling to a Karnataka buyer. Every other comparison site in the tree compares CODES
with CODES (`nst-ui-itm.lisp:131`, `nst-bl-itm.lisp:63`, `nst-bl-invhapi.lisp` §9) — the cart is the one
that compares a NAME against a CODE.

**Evidence in live data:** order 488 (customer 12, Karnataka) from vendor 1 (Karnataka): its line carries
`IGST` **205.20** with `CGSTAMT`/`SGSTAMT` **0.00** and taxable 1140.00 — 18% interstate on an intra-state
sale. Order 492's lines likewise. ⚠ **This is also why an ORDER and its new INVOICE can disagree on the
split while agreeing on the total:** `invoice-from-ord` derives the tax from CODES (seller state vs place of
supply, both resolved through `*NSTGSTSTATECODES-HT*`), so it computes CGST+SGST 9+9 where the order line
says IGST 18. Same 18%, different halves.

**Blast radius:** the customer checkout, and the ORDER API's line writer
(`order/nst-bl-ordhapi.lisp:831-840`) which deliberately mirrors the legacy call — so API-created orders
inherit it. The legacy invoice domain and the new ord→inv path compare codes and are unaffected.

**The fix, when it is taken** (not started; the requester will resolve the amount work with it):

1. ONE canonical comparison in core — resolve both sides to a GST state CODE (`*NSTGSTSTATECODES-HT*` for
   name → code, `extract-state-code-from-gstin` for a GSTIN, a code passing through) and compare those.
   `invoice-from-ord` already carries this logic (`invh-state-code-of`) and it belongs in
   `core/dod-bl-utl.lisp` so BOTH the cart and the invoice call one function instead of two opinions;
2. make the shipping-address `state` field a CODE DROPDOWN over `*NSTGSTSTATECODES-HT*` — the vendor
   profile page already does exactly this (`with-html-dropdown "state" …`) — which removes the free-text
   typo class entirely (today "Karnatak", "KA" or "Bangalore" all silently become interstate);
3. normalise `DOD_VEND_PROFILE.STATE` to codes (vendor 1 is right; vendors 2-3 hold names);
4. ⛔ DECISION NEEDED: what to do when a state cannot be resolved at all — refuse the checkout with a plain
   sentence, fall back to the customer's profile state, or keep today's silent IGST? Today it is silent,
   and silence is how this survived.

## 3. The three-page cart flow — where a state becomes a tasx decision (design, 2026-10-06)

The requester's account of the flow, which the code confirms, and what it means for the fix in §11:

| page | what it does today (measured) | what the fix needs from it |
|---|---|---|
| **`dodcustordershipaddrpage`** — address | the customer types a **pincode**; JS (`pincodecheck`, `dod.js:404`) calls `/hhub/hhubpincodecheck` → `get-pincode-details-adapter` → **data.gov.in, external**, Belnap-mapped (:T complete / :F incomplete / :U 5xx-or-timeout / :C malformed). The reply fills `shipcity` ("division, district") and **`shipstate` with a state NAME**, plus `areaname` (locality). ⚠ The city/state fields are **plain text inputs, editable ON PURPOSE** — the fallback when that API is down is a human typing. A LOCAL source also exists: `DOD_INDIA_PINCODES.STATENAME` with the `*NST-ALL-INDIA-PINCODES*` hash and `getpincodedetails` | **resolve the typed text to a GST state CODE here**, where the customer can still correct it; store the CODE under its own session key (`shipstatecode`) and leave `shipstate` as the display text; the PINCODE is an independent authority for the delivery state |
| **`hhubcustshippingmethodspage`** — tax | `create-model-for-custshipmethodspage` (`dod-ui-cus.lisp:2784`) calls `update-gst-for-order-lineitem` with `(string-upcase shipstate)` against `(string-upcase vstate)`, where `vstate` = the vendor row's `state` — a CODE ("29") for vendor 1, a NAME for vendors 2-3 → **IGST on an intra-state sale**. The hash's `totalbeforetax` / `shopcart-total` are computed here | compare **codes** (`nst-same-gst-state-p`), seller resolved `GST_STATE_CODE` → `STATE` → GSTIN digits; **refuse** rather than guess when a code is missing (after page 1 that means a stale or forged session) |
| **`hhubcustpaymentmethodspage`** — payment + shipping | displays "Amount Before Tax" / "Amount After Tax (GST)" / "Shipping Cost" from the session hash; the shipping is computed at page 2 by `calculate-shipping-cost-for-order`, whose inputs are **`shipzipcode` + the vendor's shipping settings** (freeship/flatrate/tablerate/external, the vendor's own zipcode) — **not the state**. Store pickup zeroes it | **no change needed for the shipping rule** (it is pincode-based, so the state fix cannot disturb it); it SHOULD show the split explicitly — CGST+SGST or IGST — because "Amount After Tax (GST)" is why a wrong jurisdiction stayed invisible until the order existed |

**The principle the three pages share:** *the customer's typing is for the ADDRESS; the DECISION uses a resolved
GST state CODE, and it is resolved once, on the page where the customer can still fix it.*

**One home for the rule:** `nst-gst-state-code-of` (code passes through; name → code via
`*NSTGSTSTATECODES-HT*` and `DOD_INDIA_PINCODES.STATENAME`, tolerating punctuation and the hash's
"(NEWLY ADDED)" suffixes; a GSTIN → its first two digits) and `nst-same-gst-state-p`, in
`core/dod-bl-utl.lisp`, called by the cart, the ORDER API's line writer and the invoice path — retiring the
private copy in `nst-bl-invhapi.lisp` so no third opinion can appear.

**Data to settle with it:** `DOD_VEND_PROFILE.STATE` normalised to codes (vendor 1 is right, vendors 2-3 hold
names); and the printed template's `%State Code%` is fed the *name* today (`dod-ui-cus.lisp:2512` passes
`shipstate`) while `DOD_INVOICE_HEADER.STATECODE` stores a code — one more place where a name and a code are
treated as the same thing.

**⛔ THE THREE DECISIONS** (asked 2026-10-06, unanswered): (1) nothing resolves at page 1 — block with a
picker, accept the profile state, or accept and let the tax go IGST with a warning? (2) the pincode's state
and the typed state disagree — trust the pincode and tell the customer, trust the typing, or block? (3) show
the CGST+SGST/IGST split on the payment page?

## 4. ✅ STEP 1 DONE — the cart's rule, verified where it runs (2026-10-06)

`nst-same-gst-state-p` / `nst-gst-state-code-of` / `nst-gst-state-name-key` live in `core/dod-bl-utl.lisp`, and
`update-gst-for-order-lineitem` (`order/dod-bl-odt.lisp:209`) now compares CODES — one rule for the cart and
for the ORDER API's line writer, which calls the same function on purpose. The invoice side's private copy
delegates to the core helper so a third opinion cannot appear.

**Proof: `aiharness/deepseek/tools/nst-verify-cart-tax-state.lisp` — 28 pass / 0 fail, exit 0, WRITES
NOTHING** (reads and computations only, so there is no fixture to clean). It calls the cart's own function
with the cart's own arguments and reads the columns back:

| the pair (product 186, ₹1200 × 1 − 5%) | CGST | SGST | IGST | total |
|---|---|---|---|---|
| vendor 1 `"29"` × customer `"KARNATAKA"` — **after the fix** | 102.60 | 102.60 | **0.00** | 1345.20 |
| the same sale **as stored on order 488** | 0.00 | 0.00 | **205.20** | 1345.20 |

⚠ **The total never moved — only the halves did**, which is precisely why this survived: every total on every
page was right, so nothing looked wrong until an invoice had to choose a jurisdiction.

Also asserted: a genuinely inter-state sale still goes IGST (205.20, no CGST/SGST); vendors 2-3's name-vs-name
pair still works; the rate follows the PRODUCT (HSN 0405 → 2.5 + 2.5 → 28.98 each) and not the state; a GSTIN
yields its code; the hash's "(NEWLY ADDED)" suffix, punctuation and spacing do not decide tax; and two
different states are not the same.

**⚠ What step 1 does NOT cover, asserted so it is visible rather than assumed:** a MISTYPED state ("KARNATKA")
still falls through to IGST (205.20) — the address page's picker (step 3) is what stops that. The verification
prints it.

**Steps 2-6 remain** (see §3): resolve+store the code on the address page and make the pincode the authority ·
block with the state picker when nothing resolves · have the shipping-method page read the code · show
CGST+SGST/IGST on the payment page · normalise `DOD_VEND_PROFILE.STATE` and settle `%State Code%`.

## 5. ✅ MONEY TO THE PAISE — the cart's amounts, and six whole-rupee totals (2026-10-06)

Asked for after the state fix landed: "the CGST and SGST are calculated up to 4 decimals, 341.9145 — can you
make it 2". Two separate causes, both fixed, and the second one explains part of the requester's
"amount discrepancies in the invoice layer".

**1. The amounts are not rounded anywhere.** `3399.05 × 9% = 341.9145` — a 2-decimal value times a rate
carries four decimals. The `decimal(15,2)` COLUMNS rounded on write while the in-memory line (what the page
and every later sum reads) kept four, so the page and the row could disagree. `update-gst-for-order-lineitem`
(`order/dod-bl-odt.lisp`) now rounds the **taxable value first**, then taxes it, and computes the total from
the ROUNDED parts with the tree's own `round-to-2-decimal` (`core/dod-bl-utl.lisp:15`) — the same order the
invoice layer already used. Rounding the total instead of its parts would let `taxable + taxes ≠ total`.

**2. 🚨 SIX TOTAL HELPERS WERE ROUNDING MONEY TO WHOLE RUPEES.** `fround` is **COMMON-LISP's standard
function** — "round to the nearest integer, as a float" — NOT a 2-decimal rounder with an `f` prefix:

    (fround 3815.20) = 3815.0        (round-to-2-decimal 3815.20) = 3815.2

It was used in `calculate-order-totalbeforetax/aftertax` (`order/nst-bl-Order.lisp`) and
`calculate-invoice-totalbeforetax/aftertax/cgst+sgst/igst` (`invoice/nst-ui-ihd.lisp`) — i.e. **the cart's
displayed "Amount After Tax (GST)" and the legacy invoice's printed totals**. All six now call
`round-to-2-decimal`. ⚠ This is the measured origin of a gap recorded earlier as unexplained noise:
legacy invoice 65 holds `TOTALVALUE` 3815.00 against lines that sum to **3815.20**, and 0.20 is exactly what
fround discards. ⚠ Note also that both files define `calculate-invoice-total*` (a duplicate pair, load order
decides which is live) — both are fixed, so the behaviour no longer depends on that.

**Verification: `nst-verify-cart-tax-state.lisp` — 47 pass / 0 fail, exit 0, writes nothing.** The rounding
cases it carries: product 60 × 3 at 2.5% → taxable 1738.50, CGST/SGST **43.46** each (43.4625 unrounded),
total **1825.42**; product 186 × 3 at 9% → 307.80 clean, total 4035.60; every amount a whole number of
paise; and the totals check asserts **1825.42, not the 1825.0 that `fround` answered** — the check that
would have caught the whole-rupee bug.

⚠ **Behavioural consequence, stated rather than discovered later:** the amount the cart displays and charges
now equals the sum of its lines to the paise. Before, it was rounded to the rupee, so the charged figure
could differ by up to ₹0.99 from the invoice — and the server-side column never agreed with the page.

## 6. The shipping tables hold no tax — and the RATE is a real question, not a flat 18%

Measured: `DOD_SHIPPING_METHODS` carries `FLATRATEPRICE`, `FLATRATETYPE`, `MINORDERAMT`, `RATETABLECSV`,
`FREESHIPENABLED`, `TABLERATESHIPENABLED`, `EXTSHIPENABLED`, `STOREPICKUPENABLED` — **no tax column of any
kind** — and `DOD_VENDOR_SHIP_ZONES` carries only `ZONENAME` / `ZIPCODERANGECSV`. So the vendor's configured
amounts are plain prices with no tax treatment, and whether freight is taxed (and at what rate) is decided
OUTSIDE those tables — in the order's tax computation, which is where the requester says it belongs
(`hhubcustshippingmethodspage`, the page that assembles the money).

**Two positions both exist in authority, and the deciding fact is what the delivery IS:**

| the delivery is… | treatment | rate |
|---|---|---|
| the seller delivering its own goods at a delivered price — freight is ancillary to the goods | **composite supply** (Section 2(30) with **Section 8**: taxed as the principal supply) | **the goods' rate** — 18% goods → 18% freight, 12% goods → 12% freight |
| a **separate supply of a transport/logistics service** (a platform's delivery fee, a courier charge) | its own supply | **18%** for courier/logistics (SAC 9968) — and the West Bengal appellate authority has held exactly that for a marketplace's delivery fees, refusing the exemption: [CNBC-TV18 on the Flipkart ruling](https://www.cnbctv18.com/business/companies/flipkart-delivery-transport-services-liable-for-18pc-gst-west-bengal-appellate-authority-ruling-aar-ws-l-19903766.htm/amp) |
| transport by a **GTA** | its own supply, with its own regime | 5% or 12% under the forward-charge option (Notification 22/2017 as amended), or **reverse charge** on the recipient (Notification 13/2017) **[CONFIRM current rates]** |

So "a flat 18% on transport" is right for a *service*, and wrong for the seller's own delivery of goods —
which is what this application models (the vendor charges delivery on its own order of its own goods, and
that is the fact pattern the invoice flow already implements at the goods' rate).
[Composite vs mixed supply, NJA](https://www.nja.gov.in/Concluded_Programmes/2020-21/P-1252_PPTs/1.Composite%20and%20Mixed%20Supply%20in%20GST.pdf) ·
[Section 15(2)(c), CBIC](https://taxinformation.cbic.gov.in/content/html/tax_repository/gst/acts/2017_CGST_act/active/chapter4/section15_v1.00.html) ·
[54th Council agenda, GTA ancillary services](https://gstcouncil.gov.in/sites/default/files/Agenda/54_meeting_agenda_0.pdf)

⛔ **DECISION (for the CA): is a vendor's shipping charge a composite part of its goods supply, or a separate
transport service?** I recommend NOT hard-coding either: make it a **setting** — `composite` (take the
principal goods' rate, the default, what the invoice does today) or `own-rate` — because the two readings
are both defensible and the fact pattern decides. `own-rate` needs a rate source: SAC 9965 has **no row in
`DOD_GST_HSN_CODES`** (measured), so it needs either that row at the chosen rate or a rate field on the
freight product. Whatever is chosen, the CART and the INVOICE must call ONE rule — today the cart taxes
freight at nothing and the invoice taxes it at the goods' rate, which is the inconsistency to remove.

## 7. Must the CUSTOMER see the GST on shipping at checkout? — No

**GST law does not require a tax breakup at checkout.** The disclosure duty attaches to the **tax invoice**
(Rule 46: description, HSN/SAC, quantity, taxable value, **rate and amount of tax**, place of supply, and
whether tax is payable on reverse charge) and to the supplier actually charging the right tax — not to the
cart, the shipping page or the payment page. What a *shopfront* must disclose is the **total price**, with
every compulsory charge included: see the consumer-protection side, e.g. the CCPA's penalty for misleading
pricing ([PIB](https://www.pib.gov.in/PressReleasePage.aspx?PRID=2171807&reg=3&lang=2)), and the NACIN
e-commerce/GST handbook ([PDF](https://www.nacin.gov.in/ZCVisakhapatnam/Images/Documents/EBooks/e-Book%20on%20e-Commerce%20Operators%20and%20GST%20-%20NACIN%20Vizag%20(September,%202024).pdf)).

**Why the requester has not seen freight GST on the invoices they receive** — and none of these is a
loophole: the freight sits INSIDE a delivered price (one line, nothing shown); or a "Freight" line is shown
without a separate tax breakup (the tax is inside the totals); or delivery is free/bundled. A separate
GST-on-freight figure on a customer invoice is simply uncommon.

**What this means for us:** the cart MUST charge the tax on the freight — if it does not, the vendor pays it
out of pocket (Section 15(2)(c) puts the freight in the taxable value, so the tax is due on ₹1,100 even if
only ₹1,000 was billed), and the invoice — which must include it — disagrees with what the customer paid.
Displaying the split at checkout remains a UX choice, and the requester has already chosen to show it on the
payment page (§3, step 5).

## 8. ✅ STEP A DONE — the delivery charge is a taxed LINE in the cart (2026-10-06)

Where it happens: **`hhubcustshippingmethodspage`**, exactly as the requester said it should — the page that
assembles the money calls `nst-cart-with-delivery-line` (`order/dod-bl-odt.lisp`), which turns the vendor's
charge into a line from that vendor's `FREIGHT-<vendor-id>` product (seeded by the migration) and drops the
`SHIPPING_COST` hash key to **0**, so no page and no invoice counts it twice. The order-create model calls
the same merge as a safety net for a cart that did not come through that page.

**The treatment (decided 2026-10-06): the buyer's GSTIN decides.** B2B — a GSTIN on the order — is
**EXCLUSIVE** (a registered buyer wants the tax broken out and claims the ITC); B2C — no GSTIN — is
**INCLUSIVE** (the consumer pays the charge they were shown, tax inside it). Measured basis for using the
GSTIN and not the profile flag: 2 of 26 customers have a GSTIN while `GST_CUSTOMER_TYPE` claims B2B for 24
of 26, and `CUST_TYPE` is a login type.

The requester's own example, both ways, asserted by the tool (`nst-verify-cart-tax-state.lisp`, **76 pass /
0 fail**):

| goods ₹1000 @ 18% + delivery ₹100 | freight taxable | freight tax | line total | order total |
|---|---|---|---|---|
| **B2B** (GSTIN present) | **100.00** | **18.00** (9 + 9) | **118.00** | **₹1298.00** |
| **B2C** (no GSTIN) | **84.75** | **15.25** (7.63 + 7.62) | **100.00** | **₹1280.00** — unchanged |

⚠ **The halves are derived from the split, not recomputed from the rates:** an inclusive charge
back-calculates the tax (84.75 × 9% twice is 15.26, but the split says 15.25), so the second half takes the
residual and `taxable + taxes = the line total` exactly. The same rule is in the invoice's fallback.

**Guards, all in place:** a `PRD_TYPE='SERV'` line never touches stock (`update-stock-inventory` states it
outright rather than relying on a 0-stock no-op); **multi-vendor carts are LEFT ALONE** (one charge cannot be
attributed to several vendors — per-vendor shipping is step B); and the invoice's fallback asks
`nst-order-has-freight-line-p` first, so an order is never invoiced with two delivery charges.

**The invoice's fallback for LEGACY orders treats the stored charge as INCLUSIVE** — it was collected with no
tax on it, so the tax is taken out of what the customer already paid and the invoice total then EQUALS the
order's own total (asserted: order 488, ₹40 charge → taxable 33.90 + 6.10, invoice total = lines +
40.00 = **1385.20** = the order's total). `nst-verify-invoice-from-order.lisp`: **63 pass / 0 fail**.

**Leftovers, stated rather than discovered:**
* the payment page will show a `Shipping Cost 0.00` row, because the delivery now lives inside the lines —
  the TOTALS are right, the row is cosmetic (showing the line's gross there is a small follow-up);
* the vendor's fulfilment view will see the Freight line as an item it can mark fulfilled (the SERV guard
  covers STOCK, not the fulfilment list) — cosmetic, and the future vendor-delivery table should skip
  service lines;
* `total-tax` is now actually STORED for cart orders (it never was, so `TOTAL_TAX` was NULL while the lines
  carried tax) — computed from the lines, once, at the ship-methods page;
* **separately found, NOT fixed:** a vendor row's `ORDER_AMT` overstates its lines when a qty>1 line carries
  tax, because `calculate-order-item-cost` adds the WHOLE-LINE tax per unit and
  `get-order-items-total-for-vendor` then multiplies by qty — measured on order 472: vendor row 2045.44
  against lines 1774.72. Its own step.

## 9. ✅ STEP A2 — the GSTIN field works, and the charge is VISIBLE again (2026-10-06)

**🚨 THE B2B PATH WAS UNREACHABLE, AND NOW IT IS NOT.** `display-gst-widget`
(`customer/dod-ui-cus.lisp`) — the block holding the **GST Number** and **Org/Firm/Company Name** inputs —
was **defined and called from nowhere**, so `gstnumber` was always NIL at the address step and every sale
took the B2C (inclusive) path however registered the buyer was. It is now rendered on the ship-to form,
its fields are **visible by default** (the "GST Invoice" checkbox still hides them on request), and they are
**prefilled from the customer's own record**. And prefilling alone is not enough: `nst-order-gstin-param` is
the ONE reading of that value — what the buyer typed, else the GSTIN their profile holds — so a registered
buyer who submits without retyping is still treated as B2B.

**The delivery charge is displayed again, in three places, without being counted twice.** The mechanism:
`SHIPPING_COST` stays **0** for arithmetic (the charge is one of the lines, so the totals already carry it)
and a new hash key `delivery-gross` carries what the customer is shown — ₹118 for the B2B example, ₹100 for
B2C. It is read by:

* `hhubcustshippingmethodspage` — `display-cust-shipping-costs-widget` prefers the gross over the raw
  configured rate;
* `hhubcustpaymentmethodspage` — the "Shipping Cost" row shows the gross (it showed **0.00**);
* `dodcustshopcartro` — the header object it builds is **render-only** ("nothing here is ever written to a
  column"), so it carries the gross for the template while `ORDER-AMT` — the lines — already contains it.

`nst-verify-cart-tax-state.lisp`: **78 pass / 0 fail** (the merge now also returns the display gross, checked
at 118.00 for B2B and 100.00 for B2C). `nst-verify-invoice-from-order.lisp` unchanged and green.

**⚠ NOT verifiable offline, so it is the browser test:** that the address page renders the GST block (a UI
edit cannot be driven without a Hunchentoot session), and that the three displays read the way they should.
**Known cosmetics:** the shipping-METHOD rows still print the configured rate (₹100) while the summary row
prints the gross (₹118) — a vendor-fixed rate is quoted pre-tax on the option and inside the total is
correct, but showing the gross on the option too would read better; and the vendor's fulfilment view still
sees the Freight line as an item it can mark fulfilled.

## 10. 🚨 THE MODEL/WIDGET SEAM — and the tool that now checks it (2026-10-08)

The requester hit a 500 on `hhubcustpaymentmethodspage`: **`COM.NSTORES.APP::DELIVERY-DISPLAY is unbound`**.
Mine, and instructive: I bound `delivery-display` in the page's MODEL and used it in its WIDGETS, which are a
**separate function** that sees only what the model RETURNS. The value was never in the `values` list.

**⚠ WHY EVERY CHECK MISSED IT:** the reader is happy (so `nst-preflight.lisp` passes), the compiler is happy
(a free variable is not a syntax error, so a clean build passes), and **every offline harness passes because
none of them RENDERS a page**. Only the browser could catch it.

Fixed: `delivery-display` is now returned by `create-model-for-customerpaymentmethodspage` and bound by
`create-widgets-for-customerpaymentmethodspage`. Every OTHER identifier this workstream introduced was then
audited (`deliverygross`, `invoiced`, `invoicenumber`, `invoiceflash`) and each is correctly in both lists.

**NEW TOOL: `aiharness/deepseek/tools/nst-check-model-widgets.py`** — for every
`create-model-for-X` / `create-widgets-for-X` pair in `hhub/`, it extracts the model's last `(values …)` and
the widgets' first `(multiple-value-bind (…) …)` and reports the difference. **103 pairs checked.** It found
**4 pre-existing page-breakers**, i.e. the same latent bug elsewhere in the tree:

| page | the widgets bind, the model never returns |
|---|---|
| `hhub/customer/dod-ui-cus.lisp` — `custshipmethodspage` | `company` (**fixed 2026-10-08**: the model returns `custcomp`, so `display-cust-shipping-costs-widget` was computing the CURRENCY SYMBOL from NIL — that page has been rendering amounts without one) |
| `hhub/invoice/nst-ui-ihd.lisp` — `displayinvoiceemail` | `draftemailtext` |
| `hhub/invoice/nst-ui-ihd.lisp` — `displayinvoicepublic` | `reason` |
| `hhub/warehouse/nst-ui-warehouse.lisp` — `showwarehouses` | `username` |

The last three are outside this workstream and are LEFT ALONE, recorded here for a decision. Every page this
workstream touches is clean: the check reports **0 findings** for `dod-ui-cus.lisp`, `dod-ui-ven.lisp`,
`hhub/order/` and the invoice API.

## 11. 🚨 THE CONFIGURED SHIPPING AMOUNT IS GROSS — for every buyer (2026-10-08, supersedes §8's split)

The requester caught it: "whether it is a B2B or B2C customer, there should not be any difference in the final
amount collected right? I do not want to go with my intuition here." Two defects were real, and the third
question has a measurable answer.

**1. The double count (mine).** `dodcustshopcartro`'s model computes `order-amt = shipping-cost +
shopcart-total`, and `shopcart-total` ALREADY contains the delivery once the charge is a line — so the
display value I added there was counted a second time. Fixed: the total is `shopcart-total + the charge that
is STILL A CHARGE` (the `SHIPPING_COST` key, which is 0 when the line exists), while the DISPLAY row keeps
showing what the customer pays.

**2. B2C gets NO delivery line** (the requester's "easy understanding"): the consumer reads one charge
("Shipping ₹100") and the tax inside it is accounted on the INVOICE, where the existing fallback adds an
inclusive delivery line. B2B gets the LINE, because a registered buyer needs the freight's taxable value and
tax broken out to claim the ITC. **Both invoices therefore carry the same inclusive freight line** — the
difference is only whether the ORDER carries it too.

**3. 🚨 THE AMOUNT IS GROSS FOR EVERYONE — §8's exclusive-for-B2B split is REVERSED.** Measured basis:
`DOD_SHIPPING_METHODS` has **no tax column** (FLATRATEPRICE / RATETABLECSV / MINORDERAMT only), and the cart
has always charged the configured amount as it stands — so "100" means **the customer pays 100**. Reading it
as pre-tax for B2B silently raised the delivery price by 18% for registered buyers: the same configured
amount produced two different totals, which is exactly what was caught. Reading it as gross for everyone
gives ONE taxable value (84.75), ONE tax (15.25), ONE gross (100.00), and one seller's net — with the
registered buyer still claiming the 15.25. ⚠ The pre-tax reading is a real market practice (a supplier
quoting freight ex-GST to a business), but it is a PRICING decision that belongs in the vendor's configured
amount, not a silent consequence of the buyer's registration.

| goods ₹1000 @18% + delivery configured ₹100 | delivery line | taxable | tax | customer pays |
|---|---|---|---|---|
| **B2B** (GSTIN present) | yes — the ITC is visible on the order and the invoice | 84.75 | 15.25 | **₹1280.00** |
| **B2C** (no GSTIN) | no — one simple charge; the invoice carries the line | 84.75 | 15.25 | **₹1280.00** |

**Market and software practice (researched, 2026-10-08 — pointers, not readings):** all three packages model
freight as a **separate taxed item**, exactly as this tree now does — Odoo documents "create a separate
Delivery Product for each [delivery] method" and an Odoo App exists whose entire purpose is to make the
delivery rule's price *untaxed* ([Odoo docs](https://app.readthedocs.org/projects/odoo-book/downloads/pdf/latest/),
[del_rule_price_untaxed](https://apps.odoo.com/apps/modules/19.0/del_rule_price_untaxed)); Zoho Books has a
knowledge-base article on adding shipping charges **as an item** so GST applies, plus a community thread
about that friction ([Zoho KB](https://zohohelp.com/in/books/kb/gst/gst-shipping-charge.html),
[community](https://help.zoho.com/portal/es/community/topic/unable-to-charge-gst-on-shipping-packing-forwarding-charges-in-india));
Tally maintains a dedicated article on the **tax liability of transportation charges on an invoice**
([Tally](https://tallysolutions.com/gst/tax-liability-on-transportation-charges-in-invoice/)). The
inclusive-versus-exclusive choice is a SETTING in each, not a property of the buyer — which is the reading
adopted here. ⚠ I could not read those pages (search results only), so they are cited as pointers.

**Verified:** `nst-verify-cart-tax-state.lisp` **82 pass / 0 fail** — including "B2B: the line totals the
100.00 the vendor configured — the SAME the consumer pays" and "B2C pays 1280.00, exactly what the B2B buyer
pays". `nst-verify-invoice-from-order.lisp` **63 pass / 0 fail**.

## 12. 🚨 ONE RULE FOR EVERY CART PAGE: the total adds what is still a CHARGE (2026-10-08)

The requester found the delivery counted twice beside **Place Order** on `dodcustshopcartro` and on
`hhubcustshippingmethodspage`. Mine again, and the same mistake in a new shape: I had rebound a local named
`shipping-cost` to the **display** value (the gross) while the page's TOTAL added that same local — and for a
B2B cart the delivery is inside `shopcart-total` too, so it landed in the total twice.

**THE RULE, now applied to all four pages:**

| value | what it is | what may use it |
|---|---|---|
| `SHIPPING_COST` (the hash key / the model local) | the charge **that is still a charge** — 0 when the delivery is one of the LINES (B2B, because `shopcart-total` already contains it), the charge when it is not (B2C) | **ARITHMETIC ONLY**: payable = `shopcart-total + shipping-cost` |
| `delivery-gross` (the hash key) / `delivery-display` (the local) | what the customer **pays for delivery** (the line's total, or the charge) | **DISPLAY ONLY**: the "Shipping" row, and the render-only header object the template prints |

Applied at: `hhubcustshippingmethodspage` (its widget's total and its "Shipping Charges" row),
`hhubcustpaymentmethodspage`, `hhubcustorderupipage` (its `order-amt` was already right; only the display
changed), and `dodcustshopcartro` (the Place-Order total, the "Shipping" row, and the header object).

⚠ **`create-model-for-custordercreate`'s values list is the ONE place that must keep `shipping-cost` as the
charge-left**: it is the DB-FACING one — the order stores it, and the invoice's fallback reads it. Passing the
gross there would store the delivery twice on the order and make the invoice add a second freight line. It was
left untouched deliberately (three textually identical value lists exist; the readonly cart's was changed by
line, this one was not).

**Verification:** cart **80 pass / 0 fail**, invoice **63 pass / 0 fail**, `nst-check-model-widgets.py`
**0 findings** on `dod-ui-cus.lisp` and `dod-ui-upi.lisp`, preflight PASS on all four touched files.

**⚠ One cosmetic gap left, stated:** a *rendered ORDER* (`ordertemplatefill`, `dod-ui-cus.lisp:2532`) prints
the order's stored `SHIPPING_COST`, which is **0 for a new B2B order** — the delivery is visible as a LINE in
that order's items, so the document is complete, but its "Shipping Charges" row reads 0.00. Showing the line's
value there needs the order's items matched to the freight product; a follow-up, not a defect in the money.
