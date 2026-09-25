# GSTR-1 JSON — the complete reference, and what is verified vs. inferred

**Read this when:** building or checking the GSTR-1 JSON assembler, wondering which key a
section uses, or deciding what belongs in which section. The machine-readable sample is
`aiharness/deepseek/tools/gstr1-reference.json` (validated JSON, 25 top-level keys, all 18
data sections).

**Verified:** 2026-09-25 against GSTN's own offline-tool workbook
(`GSTR1_Excel_Workbook_Template_V1.5.xlsx`) and against a real uploaded GSTR-1 file.

---

## 1. 🚨 Provenance — read this before trusting any key name

Three sources, three different levels of certainty. **They are not interchangeable.**

| | source | what it establishes | certainty |
|---|---|---|---|
| **A** | `file_convertion.py` — a script whose output was **actually uploaded** | the exact KEY NAMES for the `b2b` path, and the `fp`/`idt` spellings | **verified** |
| **B** | GSTN's offline-tool workbook — **GSTN's own artifact** | WHICH fields exist in every section, and every code list | **authoritative** |
| **C** | the published GSTN schema | the KEY NAMES for every section other than `b2b` | **inferred — confirm before filing** |

Bucket C is the one to be careful with. Source B proves a `b2cs` row carries a Type, a Place
of Supply, a Rate and a Taxable Value; it does **not** spell the keys `typ` / `pos` / `rt` /
`txval`. Those come from the published schema and are internally consistent with the
verified `b2b` keys — but **only `b2b` has been checked against a file that the portal
accepted.** A CA's real sample would close the gap in one step; that is still worth asking
for.

`version` is the other open item: the verified file says **`GST2.2.6`**, taken from a
workbook template whose name is `..._V1.5`. That is an OLD token. The field is pinned; the
VALUE needs confirming against whatever the portal currently accepts.

---

## 2. The eighteen data sections

`b2b b2ba b2cl b2cla b2cs b2csa cdnr cdnra cdnur cdnura exp expa at ata atadj atadja exemp hsn doc_issue`

The template has a worksheet for each — which is where the list above comes from, so it is
not a recollection. The nine **`…a`** sections are the AMENDMENT variants of the nine
before them: `b2ba` amends `b2b`, `cdnra` amends `cdnr`, and so on. An amendment carries
both the ORIGINAL document coordinates (`oinum`/`oidt`, `ont_num`/`ont_dt`) and the revised
ones.

### 🚨 Two structural shapes, and the difference drives the whole assembler

**Invoice-level sections** — one entry per document, each carrying its own `itms` detail:

| section | key path |
|---|---|
| `b2b` / `b2ba` | `[ { ctin, cfs, inv:[ { inum, idt, val, pos, rchrg, inv_typ, etin, itms:[ {num, itm_det} ] } ] } ]` |
| `b2cl` / `b2cla` | `[ { pos, inv:[ { inum, idt, val, etin, itms:[…] } ] } ]` |
| `cdnr` / `cdnra` | `[ { ctin, cfs, nt:[ { ntty, nt_num, nt_dt, val, pos, rchrg, inv_typ, itms:[…] } ] } ]` |
| `cdnur` / `cdnura` | `[ { ntty, nt_num, nt_dt, val, typ, etin, itms:[…] } ]` |
| `exp` / `expa` | `[ { exp_typ, inv:[ { inum, idt, val, sbpcode, sbnum, sbdt, itms:[…] } ] } ]` |

**Aggregated sections** — one entry per RATE / PLACE-OF-SUPPLY / TYPE combination, built by
summing ITEM lines, with no invoice number anywhere:

| section | key path |
|---|---|
| `b2cs` / `b2csa` | `[ { sply_ty, rt, typ, pos, txval, iamt, camt, samt, csamt, etin } ]` |
| `at` / `ata` | `[ { pos, sply_ty, itms:[ {num, itm_det:{ rt, ad_amt, iamt, camt, samt, csamt }} ] } ]` |
| `atadj` / `atadja` | same shape as `at`, with `ad_amt` being the advance ADJUSTED |
| `exemp` | `[ { sply_ty, nil_amt, expt_amt, ngsup_amt } ]` |
| `hsn` | `{ data: [ { num, hsn_sc, uqc, qty, val, txval, iamt, camt, samt, csamt } ] }` |
| `doc_issue` | `{ doc_det: [ { doc_num, docs:[ { num, from, to, totnum, cancel, net_issue } ] } ] }` |

`itm_det` is identical everywhere, which is why one item builder serves every section:

```json
{ "rt": 18, "txval": 752.0, "iamt": 0.0, "camt": 67.68, "samt": 67.68, "csamt": 0.0 }
```

`rt` is the **COMBINED** rate (18 for a 9+9 supply) — established twice, independently: by
`calc_rate` in `file_convertion.py`, which computes `Tax*200/Total` (doubling one
component), and by `nst-bl-gstr1.lisp`, which derives the rate from the amounts and
reproduces the database's `CGSTAMT`/`SGSTAMT` exactly.

`at`/`atadj` use `ad_amt` where the others use `txval` — **an advance has no taxable value
yet**, which is the entire point of the section.

---

## 3. The section-splitting rule the collector does not yet apply

**A section is not chosen by invoice. `b2cs` and `exemp` are chosen per ITEM LINE.**

One invoice in the live database (`NST00004-2024`) mixes a 12%-taxed line with five
zero-rated ones. All six share one customer with no GSTIN, so invoice-level classification
puts the whole invoice in `b2cs` — and then reports the zero-rated lines at `rt: 0` inside
`b2cs`, which is wrong: **nil-rated, exempt and non-GST supplies belong in `exemp`, split by
`sply_ty`, and are not b2cs at all.**

So the assembler must split each invoice's item lines by tax status first, and aggregate:

* tax-bearing B2C lines → `b2cs`, keyed by `(sply_ty, rt, pos, typ)`
* `rt = 0` / exempt / non-GST lines → `exemp`, keyed by `sply_ty` alone

`gstr1-classify-invoice` in `nst-bl-gstr1.lisp` returns the INVOICE's section, which is
right for `b2b`/`b2cl`/`cdnr`/`exp` and is a starting point only for `b2cs`/`exemp`. This is
the first thing the assembler has to add.

**A worked example, from real data.** The 2026-09 month of tenant 2 aggregates to exactly
the collector's own total:

| rt | txval | camt | samt | where it goes |
|---|---|---|---|---|
| 12 | 3253.75 | 195.23 | 195.23 | `b2cs` |
| 18 | 2632.00 | 236.88 | 236.88 | `b2cs` |
| **4.70** | 1330.00 | 33.25 | **29.26** | `b2cs` — ⚠ see below |
| 0 | 3029.35 | 0 | 0 | **`exemp`**, not `b2cs` |

3253.75 + 2632.00 + 1330.00 + 3029.35 = **10245.10**, which is the taxable total
`gstr1-collect` reports for 2026-09. The split is consistent; only the destination differs.

⚠ **`rt: 4.70` is not a valid GST rate.** That line's `CGSTRATE 2.50 + SGSTRATE 2.20`
disagree with its `IGSTRATE 5.00`, so the invoice appears to have under-charged tax and the
line will likely be rejected on upload. `camt` and `samt` legitimately differ there (33.25
vs 29.26) because they are computed from what was actually charged. **The generator must
warn rather than correct** — choosing the nominal 5.00 would hide a real tax deficiency —
and a human has to fix the invoice.

---

## 4. Where each JSON section comes from in this codebase

| section | source |
|---|---|
| `gstin`, `fp`, `version`, `hash`, `gt`, `cur_gt` | vendor GSTIN + `gstr1-tax-period`; `gt`/`cur_gt` are version-dependent (v3.0+) |
| `b2b` | invoices with a customer GSTIN — `gstr1-classify-invoice` → `:b2b` |
| `b2cl` | invoice-wise B2C above the threshold, inter-state — `:b2cl` |
| `b2cs` | aggregated tax-bearing B2C lines (NOT YET BUILT) |
| `exemp` | aggregated nil/exempt/non-GST lines (NOT YET BUILT) |
| `hsn` | `DOD_INVOICE_ITEMS` grouped by `HSNCODE` + UQC — `HSNCODE`, not `HSN_CODE` |
| `doc_issue` | invoice-number ranges per series, with cancellations |
| `cdnr`/`cdnur` | credit/debit notes — **no such data exists in this schema yet** |
| `exp` | exports — no such data yet |
| `at`/`atadj` | advances — no such data yet |

`DOD_GSTR1_EXPORTS` already has the B2B / B2C-large / B2C-small counters the template's
summary rows correspond to, so the export row's counters map onto `len(b2b)`, `len(b2cl)`
and the `b2cs` aggregation.

---

## 5. Code lists — from the template's `master` sheet (GSTN's own)

These are authoritative; they are what the offline tool validates against.

**UQC — the complete official list (45).** `BAG BAL BDL BKL BOU BOX BTL BUN CAN CBM CCM CMS
CTN DOZ DRM GGK GMS GRS GYD KGS KLR KME MLT MTR MTS NOS PAC PCS PRS QTL ROL SET SQF SQM SQY
TBS TGM THD TON TUB UGS UNT YDS OTH`

`OTH` is the official fallback, so `*gstr1-uqc-map*`'s unmapped-token behaviour is right.
**That map is a subset, though** — it covers the units the live invoice rows use, not all
45. Worth extending from this list rather than waiting for a warning to reveal a gap.

**Invoice Type** (`inv_typ`) — the template's labels, and the code each means:

| template label | code |
|---|---|
| Regular | `R` |
| SEZ supplies with payment | `SEZWP` |
| SEZ supplies without payment | `SEZWOP` |
| Deemed Exp | `DE` |
| Sale from Bonded WH | `CBW` |

The first column is authoritative; the codes are bucket C — **confirm**.

**Also authoritative:** Export Type = `WOPAY` / `WPAY`; Reverse Charge = `N` / `Y`; Note Type
= `C` / `D`; b2cs Type = `OE` / `E`; Tax Rates = `0 0.1 0.25 3 5 12 18 28`; and the full
Place-of-Supply state list (`01-Jammu & Kashmir` … `37-Andhra Pradesh`, `97-Other
 Territory`). `pos` in the JSON is the **two-digit code only** — the label is a display
convenience of the sheet, and `file_convertion.py` strips it with `[:2]`.

---

## 6. Re-verifying this file

```bash
# the machine-readable sample is valid JSON with all 18 sections
python3 -c "import json;d=json.load(open('aiharness/deepseek/tools/gstr1-reference.json'));print(sorted(d))"

# the field list and the code lists come from GSTN's template — re-extract them
curl -sSL -o /tmp/t.xlsx https://raw.githubusercontent.com/harshith187/GST/master/GSTR1_Excel_Workbook_Template_V1.5.xlsx
# then read xl/workbook.xml for the sheet names and each sheet's row 4 for its field labels
```

The template is an xlsx, which is a zip: `xl/workbook.xml` names the sheets, `xl/sharedStrings.xml`
holds the strings, and each sheet's **row 4** is its field-header row (rows 1–3 are a summary
block, whose shapes are also worth reading — they are what `DOD_GSTR1_EXPORTS`' counters
correspond to).
