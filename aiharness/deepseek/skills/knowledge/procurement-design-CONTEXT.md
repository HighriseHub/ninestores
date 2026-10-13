# The procurement design — the NineStores vs SMB B2B gap analysis, and the Pāṇinian grammar it sits on

**Read this when:** you are deciding **what to build next** on the buy side (purchase request,
approval, delivery, GRN, three-way match, credit notes), you need the requester's own scorecard
and build order rather than a guess at one, or you are about to name a new procurement entity or
verb and want the grammar's slot for it.

**Status: reference + design intent — nothing in this file is an implementation claim.** The
scorecard percentages are the **requester's judgment estimates** (28 Sep 2026), taken against the
88-table schema and the live feature list, and the document says so itself: *"They are not an
audited benchmark."* Where a number was later measured in this tree, the measurement is cited
beside it rather than folded into the estimate.

**Owners of the parts:** step 1 (order → invoice) is `order-to-invoice-flow-CONTEXT.md` and
`knowledge/ord-to-inv-junction-CONTEXT.md` · the order entities are
`order-adhara-stories-CONTEXT.md` · the GST/ITC surface and the empty feature tables are
`knowledge/gst-gstr-compliance-CONTEXT.md` · the Pāṇinian architecture itself is
`knowledge/WAREHOUSE-NST-GRAMMAR-CONTEXT.md` and `knowledge/nst-bl-conflodis2-DESIGN.md`.

---

## 1. The headline

**Overall weighted coverage: about 34% of a typical SMB B2B procurement suite.** The seller side
(invoice, PDF, email) is much further along than the buyer-control side (approval, receipt,
three-way match, ITC review). The largest gaps are **purchase request/approval, goods receipt and
delivery records**.

The companion workbook `ninestores_procurement_gap_analysis.xlsx` is **not in this repository** —
it lived outside the tree; the editable scores and formulas it held are reproduced as the
scorecard in §4.

---

## 2. The reference flow — eleven stages

This is the chain a buyer-side suite is expected to cover, and the spine the grammar's संधि chain
formalises (§6):

| # | Stage | GST relevance |
|---|---|---|
| 1 | Vendor/buyer master and catalog (GSTIN, HSN, price lists) | GSTIN validation; **place of supply decides CGST/SGST vs IGST** |
| 2 | Purchase request and approval (by amount, department or budget) | No GST event; budget and vendor-compliance checks |
| 3 | Purchase order (from the approved request) | **Not a taxable event**; capture HSN and rate early |
| 4 | Send to vendor(s) — vendor accepts or acknowledges | — |
| 5 | Payment terms — advance at order time, or net terms | **Tax on advances for SERVICES only**; receipt and refund vouchers |
| 6 | Fulfilment and dispatch (full or partial; dispatch notice, delivery challan, e-way bill) | Delivery challan or invoice; **e-way bill for goods consignments above Rs 50,000** |
| 7 | Goods receipt note (GRN) — buyer confirms receipt, logs discrepancies | **Receipt of goods is a condition for ITC** |
| 8 | Vendor invoice (against the fulfilled order) | Tax invoice; **IRN** for e-invoice-liable sellers; GSTR-1 reporting |
| 9 | Buyer invoice review and three-way match (PO, GRN, invoice agree) | IMS accept/reject/pending; GSTR-2B; ITC claim in GSTR-3B |
| 10 | Payment against invoice | **Pay within 180 days or reverse ITC (Rule 37)**; MSME vendors within 45 days for the buyer's tax deduction; TDS 194Q where applicable |
| 11 | Returns and adjustments | Credit and debit notes adjust the tax and ITC |

### The three answers the design gives about order modification

- **Draft, before sending:** freely editable.
- **Sent, before vendor acceptance:** the buyer can edit or withdraw.
- **After acceptance:** changes go through an **amendment** — a new revision the vendor must
  accept — or the buyer cancels and reissues.
- **After delivery:** no changes to what was received.

**And the simplification this tree is entitled to:** with NineStores' **all-or-nothing fulfilment
rule**, an amendment is simply a re-acceptance of one revision, with **no partial quantities to
reconcile**. Partial shipments each need their own invoice or challan and their own e-way bill
when above Rs 50,000 — so **full-order-only is a legitimate simplification: one vendor order means
one invoice and one e-way bill.** Partial dispatch is deferred, by decision.

**Pay at order time or after?** Both are normal, driven by payment terms. For goods an advance
generally does not trigger GST and the tax point is the invoice; for **services** it does, and the
vendor issues a receipt voucher. → This is why the junction deliberately excludes payment:
`inv→pmt` is **प्रगृह्य** (an event, never a direct call) — see
`knowledge/ord-to-inv-junction-CONTEXT.md` §2.

---

## 3. Current GST facts the design relies on

Checked against 2026 sources by the document's author (**general guidance — verify specifics with
a CA**; this tree's own reading of the same rules is `knowledge/gst-gstr-compliance-CONTEXT.md`
and `knowledge/gst-tax-jurisdiction-CONTEXT.md`):

- **E-invoicing applies once aggregate turnover crossed Rs 5 crore in any financial year since
  FY 2017-18.**
- **Sellers at Rs 10 crore or more** must report to the IRP **within 30 days** of the invoice date.
- **An invoice without a valid IRN is invalid**, so the buyer **cannot claim ITC** on it.
- **The Invoice Management System (IMS)** lets buyers **accept, reject or keep invoices pending**
  before they reach GSTR-2B; **invoices with no action are treated as deemed accepted.**
- Sources cited: Tally Solutions e-invoicing guides (2026), GSTN IMS FAQs via ClearTax and Tally.

---

## 4. The scorecard (28 Sep 2026 — the requester's estimates)

| Capability | Weight | Coverage | Weighted | NineStores state as assessed then |
|---|---:|---:|---:|---|
| Master data, catalog, GSTIN/HSN | 8 | 70% | 5.6 | Catalog, pricing, HSN/SAC, org tables in place |
| Purchase request and approval | 12 | 10% | 1.2 | Not built; permission tracking only in legacy |
| PO create, amend, send, vendor accept | 12 | 55% | 6.6 | Buyer PO and vendor-order split; **no amendment flow** |
| Payment terms, advance, payment | 8 | 50% | 4.0 | Payment, wallet, UPI, advance-receipt structures exist |
| Fulfilment and dispatch record | 12 | 25% | 3.0 | **Full fulfil or full cancel only; no delivery entity** |
| GRN and three-way match | 10 | 10% | 1.0 | None |
| **Vendor invoicing (PDF, email, IRN, order-linked)** | 12 | **45%** | 5.4 | Standalone POS-style invoice, PDF and emails; **not order-linked** |
| Buyer invoice inbox and GSTR-2B/ITC | 10 | 30% | 3.0 | Groundwork only |
| Returns, credit and debit notes | 5 | 10% | 0.5 | Minimal |
| Reporting, exports, integrations | 11 | 30% | 3.3 | GSTR-1 export exists; little else |
| **Total** | **100** | **~34%** | **33.6** | |

**Unconfirmed assumption in the document, now CONFIRMED in this tree:** tables such as
`DOD_DELIVERY_ORDER`, `DOD_GOODS_RECEIPT_NOTE_HEADER/ITEMS`, `DOD_EWAY_BILL`,
`DOD_GST_RECONCILIATION` and `DOD_TDS_CERTIFICATES` exist in the schema but are **not wired into
live flows**. The requester confirmed the delivery, GRN and e-way bill tables are **empty and
unused**, so the scores stand — and this matches the tree's own measurement that **every GST
feature table is empty while its schema is live**
(`knowledge/gst-gstr-compliance-CONTEXT.md` §1-2). ⚠ The design document's §6 open item asks
whether the **GST reconciliation** tables are empty too; that file answers it: `DOD_GST_RECONCILIATION`
**0 rows**, `DOD_INVOICE_GST_RECONCILIATION` **0 rows**, `DOD_VENDOR_GSTR1_STATUS` **0 rows**,
`DOD_BUYER_VENDOR_ACCOUNT` **0 rows**, `DOD_GSTR1_EXPORTS` **0 rows**. So the buyer-invoice-inbox row
is at the **lower** end of its range and the overall total drops by about 1-1.5 points.

### And the same trap the scorecard's "Vendor invoicing" row walks past

The row reads the seller side as *"Standalone POS-style invoice, PDF and emails; not order-linked"* —
the **45%** number. What has happened since: the **order-linked junction exists** (2026-10-06,
proven 41/0/0 against the real DB), and what is **still** absent is the number that makes an
invoice a GST document, the IRN, the issue/dispatch seam and the buyer's ITC view. The epic's
own reconciliation is `order-to-invoice-flow-CONTEXT.md` §3 — **2 of 11 stories achieved, 6
partial, 3 with no code**, where the board still says `Backlog` for all eleven.

---

## 5. The build order (the requester's priorities, in their order)

| Priority | Item | Capability | Current | Target | Points | Cumulative |
|---|---|---|---:|---:|---:|---:|
| **1** | **Vendor order to invoice conversion** | Vendor invoicing | 45% | 75% | 3.6 | 37% |
| 2a | Delivery document as an active entity | Fulfilment and dispatch | 25% | 65% | 4.8 | 42% |
| 2b | Buyer receipt confirmation on the same delivery record | GRN and three-way match | 10% | 60% | 5.0 | 47% |
| 3 | Purchase request creation and approval (buyer side) | PR and approval | 10% | 65% | 6.6 | 54% |
| 4 | Buyer invoice inbox with accept/reject | Buyer invoice and ITC | 30% | 60% | 3.0 | 57% |
| 5 | Credit and debit notes | Returns and adjustments | 10% | 60% | 2.5 | 59% |

**The three priorities gain 20 points (34% → about 54%); all six gain 25.5 (→ about 59%).**

⚠ **Invoice-before-delivery is the natural GST order, and the reason priority 1 is not
independent of 2a:** for goods the invoice should exist at or before dispatch, and **an e-way bill
needs the invoice number and value**. So 2a inherits whatever priority 1 does about invoice
numbering (US-005, where the number is currently owned by a database trigger).

### The design decisions per step, verbatim in intent

**1. Order to invoice** — one invoice per vendor order, generated by the vendor at fulfilment ·
lines, quantity, price, HSN, tax and place of supply **frozen from the order**; the **order ID is
stored on the invoice** · **hard rule: no invoice for an unfulfilled or cancelled order** ·
correction after issue: **void only before dispatch and before any IRN; afterwards a credit
note** · **leave the existing standalone POS-style invoice path unchanged.** → The epic, the
eleven stories and their verdicts: `order-to-invoice-flow-CONTEXT.md`.

**2. Delivery document** — one per vendor order (full fulfilment only), referencing the invoice ·
the vendor enters dispatch date, transporter or vehicle, and e-way bill number · the **buyer
confirms receipt on the same record** (received date, accepted flag, reason if there is a
problem), so **this doubles as the GRN** · statuses: **dispatched, then received or refused** ·
**check whether the existing empty tables fit before creating new ones — reshaping is free while
they are empty** · and **decide what a refused or damaged delivery triggers** (order cancellation,
or a flag for a credit note).

**3. Purchase request and approval** — the request **precedes the cart/PO**; approval converts it
into the order · **start with one approval level and an amount threshold** · **the requester can
never approve their own request; overrides always need a logged reason** · later: a three-tier
chain (manager, department head, finance), vendor blocking, an emergency path, and approver roles
and thresholds **scoped per buyer tenant**.

---

## 6. The grammar's slot for each of these

The procurement work is designed against `paninigrammar/paninigrammarprocurement.md` (the
Pāṇinian domain grammar: verb-first, four rings, ten अधिकार), not against a noun-first schema.
The mapping a new entity or verb must fit:

- **अधिकार (purposive domains) the build order lands in:** **परिवर्तन** (conversion — `pr→ord`,
  `ord→inv`, `quot→ord`), **पूर्ति** (fulfilment — `ord, dlv, shp, grn`), **वित्त** (`pmt, wlt,
  txn, inv`), **कर** (`inv, itc, gst-ret, irn, eway`), **अनुज्ञा** (`apr, pol`),
  **योजना** (`pr, bom, budget, cart, sub`), **लेखा** (all entities).
- **प्रत्यय (operations)** a story must be written in: `make`, `fetch`, `list`, `!`, `×`,
  `?`, `→xx` (state transition), `history`; and the cross-domain `→` (transform, one entity
  spawns another), `⊢` (authorize), `∑` (aggregate), `⫘` (fulfil), `⇄` (sync).
- **समास (compound naming):** the order→invoice compound is **तत्पुरुष** `kṝ-aṅkana` /
  `invoice-from-ord`; a three-way match is **द्विगु** `tri-melana`; order-and-fulfilment as a
  domain grouping is **द्वंद्व समाहार**.
- **The valid GST-procurement संधि chain**, which is what makes the build order non-negotiable:

  ```
  yāc (request) → mudr (approve-request)  [स्वर]
  mudr → kṝ (order)                       [व्यंजन: budget-check is लोप]
  kṝ → mudr (approve-order)               [स्वर]
  mudr → pūr (supply)                     [व्यंजन: requires allocation]
  pūr → bhāg (deliver)                    [स्वर]
  bhāg → labh (receive)                   [स्वर]
  labh → mel (three-way-match)            [स्वर]
  mel → aṅk (invoice)                     [व्यंजन: match must pass]
  aṅk → mudr (approve-invoice)            [स्वर]
  mudr → dā (pay)                         [व्यंजन: payment terms check]
  aṅk → mel (reconcile-gstr2b)            [प्रगृह्य: different tax period]
  mel → daḥ (claim-itc)                   [स्वर: if reconciled]
  daḥ → nivṛt (reverse-itc)               [स्वर: if payment not made in 180 days]
  ```

  **Forbidden sequences — no संधि possible:** `dā → daḥ` (payment before ITC claim) ·
  `daḥ → kṝ` (a tax claim triggering a new order) · `labh → daḥ` (receipt straight to ITC, must
  go through `aṅk → mel`) · **`bhāg → dā` (delivery straight to payment, must go through `aṅk`)** ·
  `yāc → dā` (request straight to payment). ⚠ Note what `bhāg → dā` forbids and the current tree
  obeys: **payment is never part of the order→invoice junction**, and the junction's own comment
  says so — "nothing here may debit a wallet" (`hhub/invoice/nst-bl-invhapi.lisp:1052-1053`).

- **Two rules this document adds to that grammar's vocabulary, already in the code:**
  **व्यंजन** for a physical order (this schema has no GRN table, so `ORDER_FULFILLED='Y'` stands in
  for `grn-exists-and-accepted?`) and **लोप ३** for a service order (`ORDER_TYPE='SRVC'`, no
  fulfilment precondition). The duplicate guard is the बहुव्रीहि predicate `inv-ord-id-unique?`,
  and **`:U` must reach `:F`, never `:T`** — the wallet precedent, "no credit risk on
  uncertainty".

---

## 7. What this document does NOT settle

- **Partial dispatch.** Deferred by decision; every partial shipment would need its own invoice or
  challan and its own e-way bill above Rs 50,000.
- **The amendment flow.** The design gives the rule (draft → sent → accepted → delivered) and the
  simplification (re-accept one revision), but no entity, no revision key and no route.
- **What a refused or damaged delivery triggers** — an explicit open decision in step 2.
- **Approval scoping.** One level and one amount threshold first; per-tenant roles and thresholds
  later — which means the first version is **not** multi-tenant-configurable and must say so.
- **Anything measured in this tree.** The grammar and the scorecard are intent; for the state of
  the sell-side step, and for every claim about what exists in `hhub/`, read
  `order-to-invoice-flow-CONTEXT.md` and the files in its owner table.
