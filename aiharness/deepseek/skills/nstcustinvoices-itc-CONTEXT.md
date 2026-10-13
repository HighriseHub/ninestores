# nstcustinvoices — customer inward invoice register + details: state of play

**Read this when:** picking up the customer invoice register (`/hhub/nstcustinvoices`), the
invoice details page, the customer ITC card, or the `nst-cinv` migration. **Also read it
when a task says "the ITC dashboard is wrong".**

**Verified:** 2026-10-13. Mechanism lives in three durable files — this one is the state of
play and the open list: `knowledge/adhara-verb-result-traps-CONTEXT.md`,
`knowledge/cl-who-rendering-CONTEXT.md`, `knowledge/invoice-template-rendering-CONTEXT.md`.

---

## 1. The original complaint, and its answer

> "the ITC summary shows ₹0.00 Claimable although the invoices are taxable"

**Cause:** `ITC_AMOUNT` is NULL on every row of the register view and **nothing in the tree
writes it**; `DOD_INVOICE_HEADER` has no tax-total columns at all (no `TOTCGST`/`TOTSGST`/
`TOTIGST` — querying one is `ERROR 1054`). The card read the ledger column, so it reported
zero for invoices carrying real tax.

**Answer:** ITC is now **derived from the invoice's own line items** —
`SUM(CGSTAMT+SGSTAMT+IGSTAMT)` per invoice, over lines that are not soft-deleted. For
customer 27 / tenant 2 that is **₹585.10**, where it used to read ₹0.00.

⚠ The `₹0.00 / ₹0 / ₹0.00 / 4` the old page printed is a fingerprint worth keeping: `0.00`
came from a `COALESCE(SUM(…),0)` over NULLs, `0` from a **hardcoded Lisp integer** for At
Risk, and `4` from `COUNT(*)` — the only correct figure. Mixed formatting in a card usually
means each figure has a different source; check that before trusting any of them.

---

## 2. What exists now

Four files, in build order, registered in **both** `package/compile.lisp` and `nstores.asd`:

| File | What |
|---|---|
| `invoice/nst-dal-cusinv.lisp` | `nst-cinv` + `nst-cinv-itc-summary` domain classes, slotless request model, two `nst-response-model` boundaries, the `dod-v-customer-invoice-register` view class |
| `invoice/nst-bl-cusinv.lisp` | verbs `fetch` / `enumerate` / `summarize-itc`, the derived-ITC query, the reverse ferry, `render-json` |
| `invoice/nst-ui-cusinv.lisp` | `^/hhub/nstcustinvoices` (register), `^/hhub/nstcustinvoicedetails`, `^/hhub/nstcustinvoicedownload` |
| `invoice/nst-bl-cusinvapi.lisp` | 3 action routes + 3 API bindings under `/hhub/api/v1/customer/` |

**The three files it replaces** — `nst-{dal,bl,ui}-cusinvreg.lisp` — are **unlisted from
both build files but still on disk**. They define the *same* page-entry, model, widget and
row-renderer names, so they must not be re-listed; deleting them is a tidy-up not yet done.

### The pages

* **Register** (`?itc=all|claimable|claimed|at-risk`): the four invoice types as a clickable
  **strip menu** (the `invoice-header-actions-menu` pattern), a table whose supplier column
  opens `MODAL.VENDOR-DETAILS`, and an invoice **number** linking to the details page. The
  card always shows **unfiltered** totals; only the table filters; the active strip cell is
  emphasised.
* **Details**: the **vendor's own invoice template, filled** — so the customer sees what the
  vendor sees (`knowledge/invoice-template-rendering-CONTEXT.md` §5) — with a PDF download
  button outside the document.

### The API

`GET /hhub/api/v1/customer/invoices`, `…/invoices/{id}`, `…/customer/itc-summary`. The
summary returns `atRisk: null` plus a **string** `atRiskReason`, never `0`: the JSON layer
cannot emit `false` (it becomes `null`), so no boolean flag is used.

---

## 3. Decisions taken, with the reason

* **Read-only entity.** No `make`, `!update` or `delete!` on `nst-cinv`: the source is a
  three-table join VIEW and the document belongs to the vendor. An invalid संधि is
  *unrepresentable*, not rejected.
* **Three ITC slots, not one** — `itc-recorded` (the ledger column, NULL everywhere),
  `itc-derived` (the line arithmetic), `itc-amount` (the effective figure). Collapsing them
  is how the ledger and the arithmetic got confused in the first place.
* **`at-risk` is NIL, not 0**: deciding it needs the supplier's GSTR-1 status and an
  ingested 2B, and `DOD_VENDOR_GSTR1_STATUS` / `DOD_BUYER_VENDOR_ACCOUNT` hold **0 rows**.
  `₹0` would assert "nothing is at risk".
* **`:at-risk` returns a sentinel**, so the API answers **503** with the reason rather than
  an empty list that reads as "you have none".
* **The buyer comes from the session, via `:for-buyer`** — a name no slot declares, so the
  ferry cannot deliver a client's buyer (`adhara-verb-result-traps` §4).
* **One supplier modal per distinct supplier**, not per row: the modal id derives from the
  vendor id, so a per-row modal emits duplicate DOM ids and `data-bs-target` binds to the
  first — clicking the second row silently opens the first.
* **The card is a fold over the table**, so card and rows cannot disagree.

---

## 4. Open items

1. **The three retired files are still on disk** (§2) — `git rm` them.
2. **The details page rides no ABAC transaction.** The register calls
   `with-hhub-transaction "com-hhub-transaction-customer-invoices-listpage"` because that
   row exists; the details page does not, because inventing a `TRANS_FUNC` name with no
   `DOD_BUS_TRANSACTION` row denies every request fail-closed. Seeding a row is the fix
   (`knowledge/ABAC-policy-transaction-CONTEXT.md`).
3. **apidefs2 has no 403** — `api-status-for-condition` maps 400/401/404/500 only, so
   "authenticated but not entitled" is answered 404.
4. **`hhub/invoice/nst-bl-invapi.lisp` names a class that no longer exists** —
   `:requestmodel-class 'CustomerInvoiceRegisterRequestModel` on the
   `:invoices/settings/update` route. `register-outbound-route` only *stores* symbols so it
   loads fine, and it was already wrong on its face (a settings route naming the register model).
5. **The generated symbol index is stale** — `core/nst-bl-funloodat.lisp` still maps ~45
   symbols to the retired file paths, so `nst-symq info NAME` reports old `:FILE` values.
   Regenerate; do not hand-edit.
6. **`hhub/invoice/nst-bl-gstr1.lisp` is in `compile.lisp` but NOT in `nstores.asd`**, so
   ASDF builds (and therefore the running server) never load GSTR-1 support while
   `compile-production` does. Pre-existing drift, found by a build-list sync check.
7. **Nothing in this domain has been run end-to-end against the database by the agent** —
   `clsql-mysql` does not compile in the sandbox. Every verification was structural,
   offline, or raw SQL. The rebuild is the first real run.

---

## 5. The view, and its field-level defects (measured 2026-10-13, live data)

Defined by `installation/upgrades/nst-dbu-gstupgrades.lisp`, migration
**`migrate-2026May-create-customer-inward-invoices-view`**. A three-table join
(`DOD_INVOICE_HEADER × DOD_VEND_PROFILE × DOD_CUST_PROFILE`) with
`AND cp.GST_CUSTOMER_TYPE = 'B2B'` — **the register is B2B-only by construction**, so a B2C
buyer sees an empty list with no error.

⚠ It publishes `cp.ROW_ID AS BUYER_ID` but `ih.TENANT_ID AS TENANT_ID` — **two different
tables**. Every verb filters on **both**; relaxing to one either shows another customer's
invoices or half-matches a row.

| Slot | Measured defect, still open |
|---|---|
| `buyer-name` | `COALESCE(cp.LEGAL_NAME, cp.NAME)`, and `LEGAL_NAME` is NULL on **every** B2B row. For customer 27 it returns the junk `"G33us22337333444"` while the real name `"LG Iyengars Bakery"` sits unread in `LEGAL_COMPANY_NAME`. **Which column is authoritative is undecided** — do not let this value onto a tax document. |
| `buyer-gstin` | Customer 27 has GSTIN `29SKJFDLAKAL345` while `GST_REGISTRATION_TYPE` is `'UNREGISTERED'`. The view does not expose the buyer's registration type, so it cannot disambiguate. |
| `total-amount` | `ih.TOTALVALUE`, the **header's** figure, which is **not** the sum of the lines: NST00025-2024 2950.00 vs 3017.56 (Δ **−67.56**), NST00030-2026 −0.36, NST00031-2026 **+0.25**. Which is authoritative is undecided. |
| `itc-derived` | Soft-deleted lines are excluded because **75 of 279** live `DOD_INVOICE_ITEMS` rows are `DELETED_STATE='Y'` **and still carry tax** — ₹3,126.32 on one invoice of customer 12 alone. Also **no CESS**: the table has CGST/SGST/IGST only, so a cess-bearing supply is understated by construction. A naive join would multiply each invoice by its line count and inflate every aggregate on the same query — hence the derived table. |
| `reverse-charge` | All four live rows are `'No'`, so the line-derived figure stands unadjusted. Under RCM the buyer pays the tax and takes the credit, so a future RCM row needs self-assessed tax **added** — which the line totals do not contain. |
| `invoice-status` | Reads `'PAID'` while `payment-status` reads `'UNPAID'` on three of four rows — two columns, two vocabularies, disagreeing. Both are reported. |

### ⚠ Adding a column to `nst-cinv`

Give the slot `:initarg` + `:accessor` + `:initform`, **and** add it to
`copy-dod-v-customer-invoice-register-dbtodomain` in `nst-bl-cusinv.lisp`. A slot added in
only one place is either UNBOUND at read time or never filled. (The copy helper is
field-complete by construction and is asserted slot-by-slot offline.)

⚠ `NstCinvRequestModel` must stay **slotless**: typed slots are dead weight because
`request->dispatch` reads only `(params rm)` and never a typed slot — the retired
`CustomerInvoiceRegisterRequestModel` had them and they made no difference while *appearing*
to be the contract. Do not reintroduce the shape.

---

## 6. The `?itc=` filter vocabulary, and what each one really answers

ITC is a **filter** rather than a column predicate because the four strip cells are four
different questions — and two of them cannot be answered from this view at all.

| filter | predicate | today |
|---|---|---|
| `:claimable` | `ITC_ELIGIBLE=1 AND ITC_CLAIMED=0` | a real predicate; ₹585.10 for buyer 27 |
| `:claimed` | `ITC_CLAIMED=1` | a real predicate, and **always empty** — nothing writes the flag |
| `:at-risk` | **not expressible** | refused in `build-cinv-filter-clauses`; `enumerate` answers the sentinel → 503 |
| `:all` / nil | no ITC clause | the whole register |

`select-cinvs-by-filter` orders **newest first by default** (`:invoice-date :desc`) — a
deliberate change of what the register shows first, not an accident of the rewrite.

⚠ `cinv-buyer-from-session` goes through `conflodis2-session-value`, which returns NIL for a
non-HTTP caller **rather than signalling** — that is what lets the buyer-scoping path be
exercised from an offline probe.

---

## 7. Two tidy-ups this work deliberately did not do

1. **`invh-json-flag` / `invh-json-date` / `invh-json-timestamp` are not invoice-header
   specific.** They are MySQL-boolean / DATE / TIMESTAMP → JSON scalar rules that happen to
   live in `nst-bl-invh.lisp`, and `nst-bl-cusinv.lisp` reuses them for that reason.
   Promoting them to `core/dod-ui-utl.lisp` — as `escape-like-wildcards` was promoted, for
   exactly the same reason — is its own change and was not smuggled into this one.
2. **The `render-json` empty-list defect is still live in `nst-bl-warehouse.lisp` and
   `nst-bl-invh.lisp`** (an empty list encodes as `null`, not `[]`, while both docstrings
   claim `[]`). Fixed here only. See `knowledge/api-boolean-flags-CONTEXT.md` §9.
