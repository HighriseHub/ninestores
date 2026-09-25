# gst-gstr-compliance — the GST return / ITC surface: the schema already exists, almost nothing populates it

**Read this when:** you are asked to build a GSTR-1 JSON export, ITC figures, GSTR-2B
reconciliation, or a CA/accountant filing feature — or you need to know whether the GST
compliance tables exist, and whether anything actually writes to them.

**Verified:** 2026-09-23 against the live `hhubdb` database and the working tree at
commit `68bd4d2`. Re-verify with §9 before trusting a number here.

---

## 1. The headline, because it changes every estimate

**The entire database layer for the GST roadmap was designed, migrated and is live. The
application layer was never written, and every GST feature table is empty.**

The trap this file exists to prevent: a roadmap conversation about "GSTR-1 export",
"ITC claims" and "GSTR reconciliation" sounds like greenfield work. It is not. Roughly
a dozen tables, a view, and a set of business classes are already in place, several of
them carrying comments such as `-- ITC FIELDS (YOUR KILLER FEATURE)`. What is missing
is the generators, the matching engine, the endpoints and the authorisation.

## 2. State in one table — schema vs wired

Measured 2026-09-23 in `hhubdb` (`information_schema` + `COUNT(*)`).

| Thing | Exists | Populated |
|---|---|---|
| `DOD_GSTR1_EXPORTS` (GSTR-1 export history, `JSON_DATA`, `ARN`, `STATUS`) | yes | **0 rows** |
| `DOD_INVOICE_GSTR1_TRACKING` (per-invoice include/exclude + validation) | yes | not counted |
| `DOD_GST_RECONCILIATION` (per-customer-period ITC recon) | yes | **0 rows** |
| `DOD_INVOICE_GST_RECONCILIATION` (per-invoice 2B match) | yes | **0 rows** |
| `DOD_VENDOR_GSTR1_STATUS` (did the vendor file, days late, ITC at risk) | yes | **0 rows** |
| `DOD_BUYER_VENDOR_ACCOUNT` (per buyer-vendor: `ITC_MATCH_RATE`, `TOTAL_ITC_AT_RISK`) | yes | **0 rows** |
| `DOD_EWAY_BILL`, `DOD_TDS_CERTIFICATES`, `DOD_DELIVERY_ORDER`, `DOD_GOODS_RECEIPT_NOTE_HEADER` | yes (4/4) | — |
| `DOD_INVOICE_HEADER` ITC/GSTR-1/e-invoice columns | yes (7/7) | partially |
| `DOD_CUST_PROFILE` GST columns | yes (4/4) | 24 rows are `GST_CUSTOMER_TYPE='B2B'` |
| View `DOD_V_CUSTOMER_INVOICE_REGISTER` | yes | **31 rows** — real source data |
| `DOD_INVOICE_ITEMS` | yes | **245 rows**, HSN + rate/amount columns present |
| `compute-itc-summary` reachable from the register response | **no** — call commented out | — |

So there *is* real invoice data to build from (31 B2B inward invoices, 245 lines), and
no GST output of any kind has ever been produced.

## 3. The schema that exists — file map with line references

All in `installation/upgrades/nst-dbu-gstupgrades.lisp` unless noted. Every one of
these is registered in the migrations registry `hhub/core/nst-sch-mig.lisp`, so they
are not orphaned DDL.

| Line | What |
|---|---|
| `:5`, `:13` | `migrate-2026May-create-customer-inward-invoices-view` — creates `DOD_V_CUSTOMER_INVOICE_REGISTER`; registry row `nst-sch-mig.lisp:68` |
| `:517`, `:527` | `migrate-2026Jan-create-gstupgrade-tables` — `DOD_GSTR1_EXPORTS` (`TAX_PERIOD` `MMYYYY`, `FIN_YEAR`, `JSON_DATA LONGTEXT`, `JSON_FILE_PATH`, `UPLOADED_TO_GSTN`, `ARN`, `STATUS` GENERATED/DOWNLOADED/UPLOADED/FILED, B2B/B2CL/B2CS counts). Registry `:20` |
| `:576` | `DOD_INVOICE_GSTR1_TRACKING` — `INCLUDE_IN_GSTR1`, `EXCLUSION_REASON`, `LAST_INCLUDED_PERIOD`, `VALIDATION_STATUS`, `VALIDATION_ERRORS` |
| `:606`–`:620` | `DOD_VEND_PROFILE` += `LEGAL_NAME`, `TRADE_NAME`, `PAN_NUMBER`, `GST_STATE_CODE`, `GST_REGISTRATION_TYPE`, **`GST_FILING_FREQUENCY`**, `FY_START_MONTH` |
| `:623`–`:629` | `DOD_CUST_PROFILE` += `LEGAL_COMPANY_NAME`, **`GST_CUSTOMER_TYPE`**, `GSTIN` |
| `:636` | `DOD_BUYER_VENDOR_ACCOUNT` — `LAST_GSTR1_FILED_PERIOD`, `GSTR1_FILING_RELIABILITY_SCORE`, `ITC_MATCH_RATE`, `TOTAL_ITC_AT_RISK`, alert prefs. Registry `:30` |
| `:707` | `DOD_GST_RECONCILIATION` — matched / mismatched / missing-in-2B / extra-in-2B, `ITC_AS_PER_BOOKS` vs `ITC_AS_PER_GSTR2B` vs `ITC_DIFFERENCE`, `ITC_CLAIMABLE`, `ITC_AT_RISK`, `ISSUES_JSON`, **`GSTR2B_SOURCE ENUM('API','MANUAL_UPLOAD','CACHED')`**, `GSTR2B_FILE_PATH`. Registry `:31` |
| `:776` | `DOD_INVOICE_GST_RECONCILIATION` — per-invoice `MATCH_STATUS`, our-vs-2B amounts, mismatch type, resolution workflow, `ITC_CLAIMABLE`, `ITC_BLOCKED_REASON`. Registry `:32` |
| `:849` | `DOD_VENDOR_GSTR1_STATUS` — `FILING_STATUS`, `DUE_DATE`, `DAYS_LATE`, `TOTAL_ITC_AT_RISK`, reminder/escalation. Registry `:33` |
| `:915` | `DOD_INVOICE_HEADER` += e-invoice `IRN`/`ACK_NUMBER`/`ACK_DATE`, `UPLOADED_TO_GSTN`, `GSTR1_PERIOD`, `IN_GSTR2B`, `GSTR2B_MATCH_STATUS`, `ITC_ELIGIBLE`/`ITC_CLAIMED`/`ITC_CLAIM_MONTH`/`ITC_AMOUNT`, payment allocation, RCM lifecycle, indexes |
| `:963` / `:1031` | `DOD_EWAY_BILL` (registry `:47`) / `DOD_TDS_CERTIFICATES` (registry `:35`) |
| `:86`–`:379` | `DOD_DELIVERY_ORDER`, `DOD_DELIVERY_ITEMS`, `DOD_GOODS_RECEIPT_NOTE_HEADER`, `DOD_GOODS_RECEIPT_NOTE_ITEMS` (three-way match; registry `:48`,`:50`,`:51`,`:52`) |

**The view** (`:13`–`:81`) joins `DOD_INVOICE_HEADER` → `DOD_VEND_PROFILE` → `DOD_CUST_PROFILE`
and exposes vendor GSTIN/legal name/filing frequency, buyer GSTIN/type, the ITC
lifecycle, the GSTR-2B match fields, e-invoice fields, RCM and payment status. Note the
final predicate: `AND cp.GST_CUSTOMER_TYPE = 'B2B'` — **the register is B2B-only by
construction.**

**Item-level tax data** lives in `DOD_INVOICE_ITEMS` (245 rows) and is sufficient for
GSTR-1: `HSNCODE`, `UOM`, `QTY`, `TAXABLE_VALUE`, `CGSTRATE/SGSTAMT` triplets,
`DISCOUNT`, `TOTALITEMVAL`. The domain classes are `hhub/invoice/nst-dal-itm.lisp:12`–`:24`
(the HSN row + the rate-grouped breakdown container).

**HSN reference data**: `DOD_GST_HSN_CODES` and `DOD_GST_SAC_CODES` both exist;
CRUD is in `hhub/products/dod-bl-gst.lisp:49`,`:53`,`:133` and
`hhub/products/dod-ui-gst.lisp:19`,`:111`,`:167`.

## 4. The application layer that exists

`hhub/invoice/nst-{dal,bl,ui}-cusinvreg.lisp`, all three compiled
(`hhub/package/compile.lisp:272`–`:274`).

| Location | What |
|---|---|
| `nst-bl-cusinvreg.lisp:11` | `select-invoices-for-buyer (buyer-id tenant-id)` — reads the view via CLSQL |
| `nst-bl-cusinvreg.lisp:21` | `compute-itc-summary` — claimable / claimed / purchases / at-risk. **`:37` hardcodes `:at-risk 0`** |
| `nst-bl-cusinvreg.lisp:39` | `doReadAll` — the register response. **`:45` has the summary call commented out** |
| `nst-bl-cusinvreg.lisp:54` | `make-invoice-domain-object` — view row → `CustomerInvoiceEntry` |
| `nst-dal-cusinvreg.lisp:12`–`:16` | Adapter / Presenter / Service / HTMLView / **`JSONView`** (`:16`) |
| `nst-dal-cusinvreg.lisp:18`–`:22` | `RequestModel` — already carries `gst-period` (`:21`) |
| `nst-dal-cusinvreg.lisp:24`–`:36` | `CustomerInvoiceEntry` — incl. `gstr2b-match-status` (`:34`), `gst-period` (`:36`) |
| `nst-dal-cusinvreg.lisp:38`–`:43` | `CustomerITCSummary` — claimable / claimed / at-risk / purchases |
| `nst-dal-cusinvreg.lisp:256` | `:base-table dod_v_customer_invoice_register` |
| `nst-ui-cusinvreg.lisp:10`–`:15` | `com-hhub-transaction-customer-invoice-register-page`, `:role :customer` |
| `nst-ui-cusinvreg.lisp:17`,`:47`,`:99` | model / widgets / row renderer |

Reusable machinery for the work ahead:

- **JSON/CSV output with an explicit content type**: `hhub/core/nst-bl-apidefs2.lisp`
  (`:content-type` `:116`, the `:csv` route precedent `:148`–`:149`, `:215`). This is
  where a GSTR-1 JSON download belongs.
- **PDF pipeline**: now hardened — `hhub/core/dod-bl-utl.lisp` `downloadhtmlfile` /
  `generatepdf` (`hhub/core/dod-bl-utl.lisp:254` and `:285`). Customer-side invoice PDFs
  reuse it.
- **Invoice email with attachment**: `hhub/email/templates/registration.lisp:173`
  (`send-email-async`) and `hhub/invoice/nst-ui-ihd.lisp:538` (the vendor send handler,
  which builds the PDF attachment when its checkbox is ticked).

## 5. Traps

Each of these was hit or measured, not inferred.

1. **`DOD_INVOICE_ITEMS.HSNCODE`, not `HSN_CODE`.** The invoice item table uses
   `HSNCODE varchar(10)`; the DO/GRN item tables use `HSN_CODE`. Querying the wrong
   name fails `ERROR 1054 (42S22)` — which reads like "the column is missing" when it
   is merely spelled differently. Symptom: *"there is no HSN on the invoice items?"*
2. **`ITC_AMOUNT` is NULL on every existing row.** All 31 register rows are
   `ITC_ELIGIBLE=1, ITC_CLAIMED=0, GSTR2B_MATCH_STATUS='NOT_CHECKED'`,
   `SUM(ITC_AMOUNT)=NULL`, `SUM(TOTAL_AMOUNT)=199243.00`. So `compute-itc-summary`
   would report **claimable 0** today. ITC must be *derived* from item-level CGST/SGST/IGST
   (or persisted from somewhere that does not exist yet) — it cannot simply be read.
   Symptom: *"the ITC dashboard says zero despite 31 eligible invoices."*
3. **The register never returns its own summary.** `compute-itc-summary` is written but
   its call at `nst-bl-cusinvreg.lisp:45` is commented out, so `doReadAll` returns rows
   only. A reader who greps for the function finds it and assumes it runs.
4. **The register is B2B-only.** The view's final predicate is
   `cp.GST_CUSTOMER_TYPE = 'B2B'`; a B2C or unregistered customer sees an empty
   register with no error.
5. **Two competing customer name columns.** `DOD_CUST_PROFILE.LEGAL_NAME` (added
   `migrate-2026Jan-update-customer-table`) and `DOD_CUST_PROFILE.LEGAL_COMPANY_NAME`
   (added `migrate-2026Jan-create-gstupgrade-tables`, `:623`). The view reads
   `COALESCE(cp.LEGAL_NAME, cp.NAME)` — so `LEGAL_COMPANY_NAME` is written by nothing
   and read by nothing. Decide which one is authoritative before printing any legal
   name on a return.
6. **The item table has no cess columns.** `DOD_INVOICE_ITEMS` carries CGST/SGST/IGST
   only; the DO/GRN item tables do have `CESS_RATE`/`CESS_AMT`. A cess-bearing supply
   cannot be represented in GSTR-1 from the invoice rows as they stand.
7. **Schema presence is not wiredness.** Every GST feature table is real *and empty*.
   Both halves matter: the tables mean the work is wiring, not modelling; the zero rows
   mean every number in this file is "designed", not "working". Do not report an ITC
   reconciliation feature as existing because the table does.
8. **No CA role exists.** Measured role usage: `:customer` ×28, `:vendor` ×22,
   `:superadmin` ×9, `:compadmin` ×3, `:admin` ×1 — no accountant/CA role. Anything new
   must also carry ABAC policy + transaction rows or the PEP answers with a redirect
   (see `knowledge/ABAC-policy-transaction-CONTEXT.md`).
9. **Duplicate guarded index block.** `nst-dbu-gstupgrades.lisp:503`–`:506` adds
   `idx_gstin` twice under the same `index-exists-p` guard. Harmless (the second is a
   no-op) but it reads as though two indexes were intended.

## 6. Open decisions — these gate the work, not the effort

1. **Where does GSTR-2B data come from?** The schema already offers
   `GSTR2B_SOURCE ENUM('API','MANUAL_UPLOAD','CACHED')` + `GSTR2B_FILE_PATH`. The API
   route needs GSP credentials *and* per-taxpayer OTP authorisation — a commercial and
   legal commitment, not a coding one. `MANUAL_UPLOAD` (the CA downloads the 2B JSON
   from the portal and uploads it) needs neither. **Recommended first: manual upload,
   behind the same field, so API is a later swap.**
2. **Prepare-and-track, or actually file?** `UPLOADED_TO_GSTN` and `ARN` exist, so
   tracking is already modelled. Submitting a return to GSTN is GSP-only. Without a GSP
   contract the honest deliverable is "return-ready JSON + filing status tracking".
3. **ITC is claimed in GSTR-3B, not GSTR-1.** The platform can compute, reconcile and
   track ITC (`ITC_CLAIMABLE`/`ITC_CLAIMED`/`ITC_CLAIM_MONTH`/`ITC_BLOCKED_REASON`) but
   cannot itself claim it. Say this out loud early.
4. **GSTR-1 JSON schema version and section scope.** GSTN's schema is versioned and
   section-based (`b2b`, `b2cl`, `b2cs`, `cdnr`, `hsn`, `doc_issue`, `exp`). The export
   table's B2B / B2C-large / B2C-small counters hint at the intended scope. **Pin the
   version against GSTN's published schema — do not invent it**, and validate the
   generated JSON against a real sample before wiring the download.
5. **CA access on what?** Build on the (currently uncommitted) `CustomerUser` /
   `CustomerUserActivity` model, or a new delegated-actor entity with grant + scope +
   period + expiry + audit? This decision shapes the policy rows, the session model and
   the audit trail, so it comes first.

## 7. Proposed slicing

Ordered so each slice ships alone and nothing later invalidates anything earlier.

1. **Vendor GSTR-1 JSON export** — period → select invoices (`GSTR1_PERIOD`, status,
   `INCLUDE_IN_GSTR1`) → build section-scoped JSON → validate → persist to
   `DOD_GSTR1_EXPORTS` → download via an `apidefs2` route → stamp
   `DOD_INVOICE_GSTR1_TRACKING`. Uses only existing schema; no external API; the item
   rows already carry HSN and rates.
2. **Customer invoice register + PDF parity** — wire the commented-out summary (§5.3),
   derive and persist ITC (§5.2), add the customer invoice view and PDF, deliberately
   narrower than the vendor side.
3. **GSTR-2B ingestion + matching** — manual upload → populate
   `DOD_GST_RECONCILIATION` / `DOD_INVOICE_GST_RECONCILIATION` → the ITC gap report
   (books vs 2B vs at-risk).
4. **Vendor filing status + ITC-at-risk** — populate `DOD_VENDOR_GSTR1_STATUS` and
   `DOD_BUYER_VENDOR_ACCOUNT`; this is what makes a buyer's ITC defensible.
5. **CA delegation** — grants, policies, audit, acting on a customer's or vendor's behalf.
6. **(external dependency)** GSP API for 2B fetch and filing/ARN capture.

## 8. Vocabulary worth not confusing

- **GSTR-1** — outward supplies, filed by the *seller*; JSON upload. This is the export.
- **GSTR-2A / 2B** — inward supplies, *generated for the buyer* from suppliers' filings.
  2B is the static, ITC-authoritative one. This is the reconciliation input.
- **GSTR-3B** — the summary return where ITC is actually claimed.
- **ITC** — input tax credit the buyer may set off; blocked when the supplier has not
  filed, which is why `DOD_VENDOR_GSTR1_STATUS` and `TOTAL_ITC_AT_RISK` exist.
- **IRN / e-invoice** — separate mandate (turnover threshold); `IRN` columns exist on
  `DOD_INVOICE_HEADER` but the e-invoice flow is out of scope for the slices above.

## 9. How to re-verify this file

Line numbers and row counts rot. Re-run these before trusting §2, §3 or §5.

```sql
-- schema present?
SELECT table_name FROM information_schema.tables
 WHERE table_schema='hhubdb' AND table_name LIKE 'DOD_%GST%'
    OR table_name LIKE 'DOD_VENDOR_GSTR%';
SELECT column_name FROM information_schema.columns
 WHERE table_schema='hhubdb' AND table_name='DOD_INVOICE_HEADER'
   AND column_name IN ('ITC_CLAIMED','ITC_AMOUNT','GSTR1_PERIOD','IN_GSTR2B','IRN');
-- wired yet? (all zero on 2026-09-23)
SELECT COUNT(*) FROM DOD_GSTR1_EXPORTS;
SELECT COUNT(*) FROM DOD_GST_RECONCILIATION;
SELECT COUNT(*) FROM DOD_BUYER_VENDOR_ACCOUNT;
-- the source data, and the ITC hole
SELECT COUNT(*) FROM DOD_V_CUSTOMER_INVOICE_REGISTER;
SELECT ITC_ELIGIBLE, ITC_CLAIMED, GSTR2B_MATCH_STATUS, COUNT(*), SUM(ITC_AMOUNT)
  FROM DOD_V_CUSTOMER_INVOICE_REGISTER GROUP BY 1,2,3;
```

Connection facts are in `hhub/core/dod-ini-sys.lisp` (`*crm-database-*`); migrate via
`hhub/core/nst-sch-mig.lisp` (registry rows listed in §3).

```sh
# is the register summary still commented out?
grep -n "summary (compute-itc-summary" hhub/invoice/nst-bl-cusinvreg.lisp
# does the item table still spell it HSNCODE?
mysql -N -e "SHOW COLUMNS FROM DOD_INVOICE_ITEMS LIKE '%HSN%'" hhubdb
```
