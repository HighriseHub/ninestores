# SKILL: Multi-jurisdiction tax and money — beyond Indian GST (Nine Stores / hhub)

**STATUS 2026-10-11: ARCHITECTURE NOTES. Three decisions are taken (§1); nothing else here is built, and
this file deliberately does NOT propose a framework to build now (§5).** Read it before designing anything
that touches tax rates, rounding, currency or a second country — and read §4 before adding a fourth
CGST-shaped column to any table.

Companions: `gst-tax-jurisdiction-CONTEXT.md` (§1 freight/composite supply, **§8 the one-rounder rule**),
`gst-sac-codes-CONTEXT.md` (the SAC master, still unseeded), `gst-gstr-compliance-CONTEXT.md` (the India
compliance surface), `schema-migrations-CONTEXT.md` (how a master is seeded and versioned).

---

## 1. The three decisions already taken (2026-10-11)

### 1.1 The HSN and SAC masters are COMMON tables. Their `TENANT_ID` is DECORATIVE.

Stated by the owner, and the code agrees: `DOD_GST_HSN_CODES` holds **21,255 rows, all `TENANT_ID 1`**,
while the products that read it live under **tenants 2 and 5** — so the lookup works today *only because
the tenant column is ignored in practice*:

* `select-hsn-code-by-code` (`products/dod-bl-gst.lisp:34`) hard-filters `[= [:tenant-id] 1]`;
* `get-gstvalues-for-product` (`:53`) hands it `:company (product-company product)` — the product's OWN
  company, whose tenant is 2 or 5 — and the filter discards that. Every goods line is taxed 2.50/2.50
  because of that mismatch, not because the data is scoped.

**Consequence, and the correction to make when either table is next touched:** the master is global
data — a statute's list, identical for every tenant. Its natural key is **`(COUNTRY_CODE, CODE,
EFFECTIVE_FROM)`**, not `(TENANT_ID, CODE)`. When the lookup is next edited, say the tenant dimension is
ignored **in one place** (or drop the filter and the column) rather than leaving a filter that reads as
scoping and is not. ⚠ `DOD_GST_SAC_CODES` — **0 rows**, see `gst-sac-codes-CONTEXT.md` — should adopt the
global shape *before* it is seeded, because seeding it tenant-scoped would bake in the same pretence.

### 1.2 A "Free GST Lookup Tool" is planned as a separate feature on `index.html`.

That is the natural consumer of a common master, and it is a NEW KIND OF ENDPOINT for this tree: **the
first read with no tenant and no session**. The precedent exists — the shared invoice view
(`com-hhub-transaction-display-invoice-public`, `invoice/nst-ui-ihd.lisp:1329`, registered at
`sysuser/dod-ui-sys.lisp:1149`) is a plain `with-mvc-ui-page … :role :vendor` controller with no
`with-vend-session-check` and no `with-hhub-transaction`, i.e. deliberately OUTSIDE the PEP, addressed by
a key. Note what differs:

* the PEP (`with-hhub-transaction`) is **tenant-scoped by design** — it reads the tenant-1 transaction scan
  and a company — so a global-master tool cannot use it and must be excluded on purpose, not by omission;
* the invoice public view exposes one tenant's DOCUMENT; this tool exposes a STATUTE's table — no data
  leaks, so the risk is abuse (an unauthenticated, uncached-per-request read), not disclosure;
* so the design questions are rate limiting, caching (the master is already cached in-image — index 12/13 of
  `*HHUBGLOBALLYCACHEDLISTSFUNCTIONS*`), and whether the search returns rates at all. See §6.3.

### 1.3 A second country will be an INDEPENDENT ENTITY.

The boundary for multi-country is therefore the **legal entity / tenant**, not a per-document flag. That is
the cheaper of the two possible worlds and it fixes where things live:

| global (statute data) | per entity / tenant (its own law and filings) |
|---|---|
| HSN/SAC rate masters, currency reference data, country list | tax POLICY (which components, inclusive/exclusive, rounding), registrations (GSTIN / VAT ID / TRN / EIN), document numbering, filing and reporting state, chart of money |

The alternative — ONE entity invoicing across borders, needing per-document jurisdiction policy — is
foreclosed for now. Do not build its machinery speculatively (§5).

---

## 2. Where India is baked in — measured

| concern | today | evidence |
|---|---|---|
| **tax shape** | CGST/SGST/IGST are COLUMNS: `DOD_ORDER_ITEMS` and `DOD_INVOICE_ITEMS` carry `CGSTRATE/CGSTAMT/SGSTRATE/SGSTAMT/IGSTRATE/IGSTAMT`; one intra/inter split | schema; a fourth tax (cess) already exists as `COMP_CESS`/`CESS_AMOUNT` and is largely unread |
| **jurisdiction** | the GST STATE, compared NAME-vs-CODE through `*NSTGSTSTATECODES-HT*` | `nst-same-gst-state-p`, `nst-gst-state-name-key`, `init-gst-statecodes` |
| **rate master** | `DOD_GST_HSN_CODES` has **no effective-from/to**; a rate change edits the only copy | `SHOW COLUMNS` — ROW_ID, HSN_CODE, HSN_CODE_4DIGIT, HSN_DESCRIPTION, CGST, SGST, IGST, COMP_CESS, COMP_CESS_FUNC, GST_HSN_FUNC, TENANT_ID |
| **currency** | derived from the company's `COUNTRY` (`get-account-currency`, `account/dod-bl-cmp.lisp:12` → cached country→currency map, else `*HHUBDEFAULTCURRENCY*`). **No currency column on `DOD_ORDER` or `DOD_INVOICE_HEADER`** | one company = one country = one currency; no FX rate anywhere in the tree |
| **amounts in words** | `convert-number-to-words-INR` called unconditionally (`nst-bl-invhapi.lisp:1334`, `nst-ui-ihd.lisp:1309`); **`convert-number-to-words-USD` exists and is unused** | crore/lakh; the seam exists, unwired |
| **identifiers** | `ORD-{prefix}-{fy}-{ref:6}` (`*nst-order-number-format*`, `core/dod-bl-utl.lisp:1412`) and `NST00117-2026`; `INVNUM` re-derived from `ROW_ID` by a DB trigger; FY = Apr–Mar (`nst-financial-year-label`) | a fiscal convention inside the number |
| **compliance** | `IRN`, `ACK_NUMBER`, `QR_CODE_PATH`, `GSTR1_PERIOD`, `GSTR2B_*`, ITC, RCM, TDS columns | one jurisdiction's filing model, per entity |
| **money** | `decimal(15,2)` everywhere; one rounder | 2 dp assumed |

**Already right:** everything AROUND the tax is jurisdiction-neutral — multi-tenant `TENANT_ID`, products,
cart, order, invoice, PDF/HTML rendering, ABAC, the adhara verbs. And as of 2026-10-11 there is exactly
**one** place that turns a line into money (`nst-line-money`, `core/dod-bl-utl.lisp`) with rates read from a
master rather than from code. That is the seam a second regime needs; the wrong move is a
`nst-line-money-us` or country branches inside the current one.

---

## 3. Two rounding facts that are live TODAY (and that a second currency would make untenable)

The one rounder is `round-to-2-decimal` = `(/ (round (* n 100)) 100.0)`. Measured:

| expression | result | what it means |
|---|---|---|
| `(round (* 0.125 100))` | **12** → 0.12 | CL's `round` is **half-to-EVEN**, not the half-up tax authorities and accountants assume (half-up gives 0.13) |
| `(round (* 1.005 100))` | **100** → 1.00 | money arrives as binary floats, so an apparent half is often not one (100.49999999999999) |
| `(round (* 2.675 100))` | 268 → 2.68 | the same artefact, the other way |

So the tie behaviour is decided by IEEE-754 today, not by policy. Multi-currency forces the issue anyway:
**JPY has 0 decimals, KWD/BHD/TND 3, CLF 4**, and several regimes legislate the mode (and *where* rounding
happens: per line, per tax component, or once per document — India's practice and the EU's differ from
each other as well). Make precision and mode explicit data even while the value is "INR, 2, half-up".

---

## 4. The shape the seam needs — data, not code

`nst-line-money`'s INPUTS become a policy value instead of three fixed rates. Nothing here needs to be
built now; this is the target the next change should not wander away from.

1. **Tax components**: a list of `(name, rate, base, compound?, inclusive?)` rather than CGST/SGST/IGST
   fields. India maps onto it exactly — CGST and SGST are two components on one base, IGST is one, cess is a
   fourth. Quebec's *GST charged on QST* is `compound? t`; Australia's tax-inclusive shelf price is
   `inclusive? t` **on the document** (today only the delivery charge is inclusive and the goods are
   exclusive — that asymmetry is India-specific and would be wrong in AU/NZ/JP).
2. **Jurisdiction key**: `(country, region, seller registration, buyer status, supply nature, tax date)`.
   India: `(IN, state, GSTIN, B2B|B2C, goods|service, date)`. The US needs county/city downward; the EU
   needs the two-party VAT-ID test. Destination-vs-origin is then per-country POLICY, not a global
   assumption.
3. **Rounding policy per currency**: precision + mode + the level it applies at.
4. **Document money**: `document currency` + `base currency` + `FX rate` on the order and the invoice; tax
   computed in the document currency and REPORTED in base, never the reverse.
5. **Effective-dated rates**: supersede a rate row, never edit it. India needs this for its own notified
   changes, and it is a prerequisite everywhere.
6. **Jurisdiction reporting seam**: "mint the document number" and "report / clear the document" as named
   functions. India's IRN upload is one implementation; Italy's SDI, Mexico's CFDI another.

---

## 5. Guardrails (cheap, low-regret) — and what NOT to do now

Do these as the files are touched anyway:

1. **Keep every money calculation inside `nst-line-money`** and let its inputs carry the policy, even while
   the policy is hardcoded India. A second regime then becomes a value, not a fork.
2. **Add `CURRENCY` (default INR) to `DOD_ORDER` and `DOD_INVOICE_HEADER`**, and let the header's
   `TOTALINWORDS` pick its locale function (`…-USD` already exists, unused). Additive, harmless now.
3. **Record the tax components actually applied** on each line — a child table or JSON — ALONGSIDE the
   existing three columns. This is the one schema change that makes history regime-independent, and India's
   three components fit the shape today.
4. **Effective-date the rate masters** (§4.5) and stop mutating them in place.
5. **Make the rounder's policy explicit** (§3), even if the implementation does not change.

**What NOT to do now:** do not genericise the CGST/SGST/IGST columns away, do not abstract the cart, and do
not build a rules engine with no second rule. This repo already carries the cautionary tale: eight GST
feature tables are migrated, live and **empty**, and the notes record schema-presence being mistaken for
wiredness more than once (`gst-gstr-compliance-CONTEXT.md`). A speculative multi-jurisdiction framework
would repeat that mistake at ten times the cost.

---

## 6. Consequences of "independent entity" (§1.3), spelled out

**6.1 Masters stay global; only policy is per entity.** With a separate entity per country, `TENANT_ID` on
the statute masters has no job at all (§1.1) — a country's rate list is a fact about the country, and two
entities in one country share it. Do not copy master rows per tenant to make the tenancy "consistent".

**6.2 The tenancy wart still has to be settled.** Masters are pinned to `TENANT_ID 1` while products live
under 2 and 5; that only works because the filter is ignored. Fix the direction when touched: the master
loses the tenant dimension (gains `COUNTRY_CODE` + `EFFECTIVE_FROM`), and the tenant keeps the policy that
CHOOSES among masters.

**6.3 The lookup tool is the first tenant-less read** (§1.2). Design it as such: outside the PEP on purpose,
addressed by a code rather than a document, served from the in-image master cache, with an explicit line
drawn about what it returns (a code's description and rates are public facts; anything about a tenant's
products or prices is not), plus rate limiting — none of which the invoice public view needed, because it
exposes exactly one document to someone who already holds its key.

**6.4 A second entity needs its own reporting state** even before its own tax engine: its numbering series,
its registration numbers, its filing calendar. That is why 6.3's "seam" matters more than the arithmetic.

---

## 7. The one gating question still open

**How granular, and how many regimes, within 24 months?** Two or three GST/VAT-style regimes (India + UAE +
UK, say) need nothing beyond §4's policy value on the existing seam. **US-style tax down to county/city
needs a jurisdiction-RESOLUTION service** (address → taxing authorities, nexus rules, per-authority rates)
that is a different project from a tax engine. Decide this before designing anything; the answer chooses
between "a field on the policy struct" and "a new subsystem".

**Trigger list** — start the real design when any of these becomes true: a second entity is registered; a
customer asks for an invoice in a currency other than the entity's; a rate change has to be dated; a
jurisdiction requires a clearance/reporting call (IRN is the first, already here).

---

## 8. How to re-measure all of this

```sql
SELECT TENANT_ID, COUNT(*) FROM DOD_GST_HSN_CODES GROUP BY TENANT_ID;   -- 1 / 21255
SELECT COUNT(*) FROM DOD_GST_SAC_CODES;                                 -- 0
SELECT DISTINCT TENANT_ID FROM DOD_PRD_MASTER;                          -- 2, 5
SHOW COLUMNS FROM DOD_ORDER;            -- no CURRENCY / FX column
SHOW COLUMNS FROM DOD_INVOICE_HEADER;   -- neither
SHOW COLUMNS FROM DOD_GST_HSN_CODES;    -- no EFFECTIVE_FROM / EFFECTIVE_TO
```

```lisp
(round (* 0.125 100))   ; 12  — half-to-even
(round (* 1.005 100))   ; 100 — a float artefact, not a half
```
