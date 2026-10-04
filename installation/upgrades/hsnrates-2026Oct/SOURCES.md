# HSN → GST rate mapping: sources, method and confidence

Built 2026-10-03 by `build_rates.py` + `refine_rates.py` from the notifications in force,
then matched against the 21,255 rows of `hhubdb.DOD_GST_HSN_CODES` (all `TENANT_ID=1`).

## 1. Primary law used

| What | Instrument | In force from | Where the text came from |
|---|---|---|---|
| Goods rate schedules | **Notification 9/2025-Central Tax (Rate)**, 17.09.2025, G.S.R. 641(E) — supersedes 1/2017-CT(R) | 22.09.2025 | `raw/taxcode-9-2025.txt` (consolidated text carrying the amendment footnotes) |
| Amendment | **19/2025-CT(R)**, 31.12.2025 | 01.02.2026 | same consolidated text (footnote 7: Schedule VII 14% omitted, pan masala / 2401-2404 moved) |
| Amendment | **01/2026-CT(R)**, 30.04.2026 + corrigendum 06.05.2026 | 01.05.2026 | same consolidated text (footnotes 1,2,5,6) |
| Exempt / nil goods | **Notification 10/2025-CT(R)**, 17.09.2025, G.S.R. 660(E) — supersedes 2/2017-CT(R) | 22.09.2025 | `raw/notif-10-2025-ctr.txt` (extracted from the gazette page CG-DL-E-17092025-266210; primary PDF: https://egazette.gov.in/WriteReadData/2025/266210.pdf) |
| Compensation cess | 02/2025-CC(R) w.e.f. 22.09.2025, 03/2025-CC(R) w.e.f. 01.02.2026 | — | see §3 |

Schedules of 9/2025-CT(R) and the central-tax → IGST conversion actually applied:

| Schedule | CT rate | CGST | SGST | IGST | Entries parsed |
|---|---|---|---|---|---|
| I | 2.5% | 2.5 | 2.5 | **5** | 516 |
| II | 9% | 9 | 9 | **18** | 640 (incl. the residual entry S.No 639) |
| III | 20% | 20 | 20 | **40** | 18 |
| IV | 1.5% | 1.5 | 1.5 | **3** | 15 |
| V | 0.125% | 0.125 | 0.125 | **0.25** | 3 |
| VI | 0.75% | 0.75 | 0.75 | **1.5** | 2 |
| VII | 14% | — | — | — | **omitted 01.02.2026** — its six entries (2106 90 20 pan masala, 2401, 2402, 2403, 2404 11 00, 2404 19 00) now sit in Schedule III at 20% CT / **40% IGST** |

Residual: Schedule II S.No 639, "Any Chapter — Goods which are not specified in
Schedule I, III, IV, V, VI or VII" → **18% IGST**. That is the rate given to the 3,039
rows no schedule names.

Secondary/aggregator sources used only to *find* the notification text and to confirm the
2026 amendments (never for the numbers themselves):

* https://taxguru.in/goods-and-service-tax/cbic-revises-gst-rate-notification-under-finance-act-2026.html
* https://taxguru.in/goods-and-service-tax/compensation-cess-rates-slashed-nil-multiple-goods-february-2026.html
* https://gazettetracker.com/g/CG-DL-E-17092025-266210 (gazette record for 10/2025-CT(R))
* https://cbic-gst.gov.in/gst-goods-services-rates.html — still links only the 2017 schedules, so it is **not** usable for current rates.

## 2. What the old contents of the table were

Measured on the live database:

| | |
|---|---|
| rows | 21,255 (all `TENANT_ID=1`), 1,446 distinct `HSN_CODE_4DIGIT`, 1,329 of them carrying a 4-digit row |
| all-zero CGST/SGST/IGST | 21,214 |
| non-zero (and partly corrupt) | 41 — incl. `2.50/2.20/5.00` (CGST≠SGST), `6.00/6.00/6.00` (IGST≠CGST+SGST), `5.00/5.00/5.00` |
| `COMP_CESS` non-zero | 0 |

`installation/DOD_GST_HSN_CODES.sql` (the 2025 seed dump) holds exactly the same values,
so it is not a source of truth — it is the thing being migrated.

## 3. Compensation cess — nil on every good since 01.02.2026

* 02/2025-CC(R) w.e.f. 22.09.2025 substituted **Nil** for aerated beverages,
  coal/lignite/peat, specified motor vehicles, motorcycles >350 cc, personal-use aircraft,
  yachts and pleasure vessels.
* 03/2025-CC(R) w.e.f. 01.02.2026 substituted **Nil** for the remaining pan masala and
  tobacco entries.
* Therefore `COMP_CESS = 0.00` and `COMP_CESS_FUNC = NULL` for every row. No ad-valorem
  percentage and no ₹-per-unit formula is in force any more — the historical specific
  formulas (`₹400 per tonne` for coal, `₹ per 1000 sticks` for tobacco) are law of the
  past and must not be written into the table.
* Source: taxguru summary of the CBIC notifications, cross-checked against
  https://www.aaptaxlaw.com/gst-online/gst-compensation-cess-rate-goods-with-compensatory-cess.html
  ("current position as on 1 September 2026").

## 4. Method — why an entry cannot simply be applied to its heading

A cell in a schedule is often far broader than its description. Real examples parsed from
the notifications:

| Entry | Cell | Description |
|---|---|---|
| 10/2025 S.No 124 | `44 or 68` | Deities made of stone, marble or wood |
| 10/2025 S.No 117 | `3304` | Kajal, Kumkum, Bindi, Sindur, Alta |
| 10/2025 S.No 119 | `3926` | Plastic bangles |
| 9/2025 Sch I S.No 244 | `3304` | Talcum powder, Face powder |
| 9/2025 Sch I S.No 207 | `2710` | (a) Kerosene oil PDS, (b) bunker fuels … |
| 10/2025 S.No 99 | `1905` | Pappad, by whatever name it is known |
| 9/2025 Sch I S.No 232 | `3004` | Medicaments … (this one really does cover 3004) |

Applying the first six to their heading would put 0% on all plastics, all cosmetics and
all petroleum. So each (cell, entry) pair is classified by comparing the entry's wording
with the heading's own tariff definition — taken from the DB's 4-digit row, which carries
the exact CBIC heading text:

| tier | meaning | rows |
|---|---|---|
| **A** | wording is the heading's definition → applied to the heading | 15,904 |
| **B** | cell is a 6/8-digit tariff item → applied to that item | 242 |
| **C** | wording names specific articles → placed only on the child rows whose description matches (≥2-token phrase, 75% coverage) | 1,498 |
| **M** | heading split by entries with different rates and no single filler → leftovers take the lowest rate in the heading | 572 |
| **R** | no schedule names the goods → 18% residual | 3,039 |

Resulting distribution:

| IGST | rows |
|---|---|
| 0% | 1,077 |
| 0.25% | 86 |
| 1.5% | 8 |
| 3% | 136 |
| 5% | 5,704 |
| 18% | 14,096 |
| 40% | 148 |

## 5. Two policy switches (not data)

1. **`PACKAGED_POLICY` in `refine_rates.py`** — the law splits many food/agri headings into
   "pre-packaged and labelled" (taxable, 5%) and everything else (nil): 90 headings,
   ~1,376 rows. Default `"taxed"` (5%), which is the reading that fits a marketplace
   selling labelled goods. Set `"nil"` and re-run to get the loose-commodity reading.
2. **Tier M fallback** — for the 93 headings where entries disagree and none is generic
   (e.g. 4901: books 0% vs brochures 5%), the leftovers take the lowest rate and are
   flagged. 572 rows.

## 6. Spot checks (verified against the notification text)

| HSN | rate | basis |
|---|---|---|
| 0401 fresh/pasteurised milk | 0% | 10/2025 S.No 15 |
| 0402 milk & cream, concentrated | 5% | 9/2025 Sch I S.No 4 |
| 0902 tea | 5% | 9/2025 Sch I S.No 34 |
| 1006 rice | 5% | 9/2025 Sch I S.No 48 (packaged) |
| 2402 cigarettes | 40% | 9/2025 Sch III S.No 16 |
| 2710 petroleum oils | 18% | 9/2025 Sch II S.No 29 |
| 3004 medicaments | 5% | 9/2025 Sch I S.No 234 |
| 3926 other articles of plastics | 18%, bangles 0% | Sch II S.No 127 + 10/2025 S.No 119 |
| 4016 articles of vulcanised rubber | 18% | 9/2025 Sch II S.No 142 |
| 4901 printed books 0% / brochures 5% | split | 10/2025 S.No 132 + 9/2025 Sch I S.No 324 |
| 6109 t-shirts | 5% | 9/2025 Sch I S.No 388 (≤ ₹2500) |
| 7102 rough/sawn diamonds 0.25%, others 1.5% | split | Sch V S.No 1 + Sch VI S.No 1 |
| 7108 gold | 3% | 9/2025 Sch IV S.No 5 |
| 8471 computers | 18% | 9/2025 Sch II S.No 456 |
| 8703 cars 40%, other vehicles 18% | split | Sch III S.No 5–7 + Sch II |
| 9503 toys | 5% | 9/2025 Sch I S.No 497 |

## 7. Files

| File | What |
|---|---|
| `final_mapping.csv` | **the deliverable**: one row per `HSN_CODE` with the new rate, the tier it was matched at, the notification it came from, and the flags |
| `review_head_conflicts.csv` | the 93 headings whose entries disagree on the rate, and how each was resolved |
| `review_unplaced_sub_entries.csv` | 223 article-level entries that matched no child row (their article is not in the DB directory) |
| `raw/taxcode-9-2025.txt` | the consolidated text of 9/2025-CT(R) **as amended** (19/2025, 01/2026, corrigendum) — what the schedules were read from |
| `raw/notif-10-2025-ctr.txt` | full text of 10/2025-CT(R), the nil/exempt list (gazette CG-DL-E-17092025-266210) |
| `build_rates.py` | parses both notifications into (cell, entry) rules and walks the rate schedules |
| `refine_rates.py` | classifies each rule (head / item / sub / residual), resolves split headings, writes `final_mapping.csv` |
| `gen_migration.py` | compresses the 21,255-row mapping into 2,329 disjoint rules and writes the Lisp migration |
| `verify_migration.py` | read-only check: asks MySQL which rows each rule really matches in the live table, applies them in file order, diffs against `final_mapping.csv` → **PASS, 0 uncovered, 0 mismatches** |

### How to reproduce

```sh
# 1. the table as it stands, one line per HSN (the two parser scripts read this file)
mysql -u hhubuser -p<password> -N -B -e "SELECT HSN_CODE,HSN_CODE_4DIGIT,REPLACE(REPLACE(REPLACE(LEFT(HSN_DESCRIPTION,400),'\t',' '),'\n',' '),'\r',' '),CGST,SGST,IGST,IFNULL(COMP_CESS,'NULL') FROM hhubdb.DOD_GST_HSN_CODES ORDER BY HSN_CODE;" > db_codes.tsv
# 2. re-derive the mapping, the migration, and the proof
python3 build_rates.py && python3 refine_rates.py && python3 gen_migration.py && python3 verify_migration.py
```

`db_codes.tsv` is not committed (3.9 MB of export); step 1 recreates it. `PACKAGED_POLICY` in
`refine_rates.py` is the one policy switch — set it to `"nil"` to re-derive the mapping under
the loose-commodity reading of the pre-packaged split.


## 8. The migration

`installation/upgrades/nst-dbu-hsnrates.lisp` → `migrate-2026Oct-populate-hsn-gst-rates`,
registered in `hhub/core/nst-sch-mig.lisp` as `03102026-populate-hsn-gst-rates`
(the file is loaded on demand by `load-upgrade-files`; it is deliberately not in the asd).

* 2,329 rules: 1,330 `HSN_CODE LIKE '<prefix>%'` groups and 999 exact codes. A group is
  only a prefix when *every* row under that prefix carries the same rate, so the groups are
  disjoint and the order inside the list is deliberately shortest-matcher-first.
* Each rule writes `CGST`, `SGST`, `IGST` and `COMP_CESS = 0.00`. It rewrites absolute
  values, so re-running is safe.
* The 0.25% slab (Sch V, 86 rows of chapter 71) is 0.125% central tax each, which
  `decimal(4,2)` cannot hold: those rows are written **CGST 0.13 + SGST 0.12** so the
  intra-state total still equals 0.25%. Widening both columns to `decimal(5,3)` is the
  alternative, and needs DDL rights (`hhubuser` has no ALTER — only SELECT/INSERT/UPDATE/
  DELETE).
* Compile-checked in an isolated SBCL (§6 recipe): only the three expected
  `*DOD-DB-INSTANCE*` warnings, no read errors.
* Provenance is **not** written into the table (per decision): `GST_HSN_FUNC` and
  `COMP_CESS_FUNC` stay NULL, and the audit trail lives in `final_mapping.csv` +
  `review_head_conflicts.csv` + `review_unplaced_sub_entries.csv`.
* Run it with `(load-upgrade-files)` then `(apply-migrations <user> <password>)`.

## 9. Known limits — do not overstate the result

* 1,498 (C) + 572 (M) = 2,070 rows rest on wording matching or on a fallback, not on an
  explicit schedule entry. They must be reviewed by whoever signs the returns.
* 223 narrow entries (e.g. "Prasadam supplied by religious places") could not be tied to
  any row because the DB's directory has no matching article — those articles therefore
  keep the heading rate.
* Multi-rate headings that the law splits by *value* (6109 apparel ≤/> ₹2500) or by *use*
  (tractors, ambulances) cannot be resolved from the HSN code alone; the DB has one rate
  per code, so the value/size split stays a per-invoice decision.
* The DB directory has 1,329 of the tariff's 4-digit headings and no rows at all for some
  headings (e.g. 3304 cosmetics) — nothing can be filled for codes that are not there.
* Rates are as in force on 2026-10-03, i.e. 9/2025-CT(R) as amended up to 01/2026-CT(R).
  Any later amendment invalidates the file; re-run §1 before trusting it.
