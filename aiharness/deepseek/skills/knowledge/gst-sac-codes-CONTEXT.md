# SKILL: SAC codes — the SERVICE side of the GST rate master (Nine Stores / hhub)

**STATUS 2026-10-11: NOT STARTED. These are notes for a later session, deliberately not a plan.**
Nothing in this file has been implemented, and the migration it describes does not exist yet. The
freight half of the problem it addresses is ALREADY FIXED a different way — see §2 and §7, and do not
undo that while doing this.

---

## 1. What is measured today (2026-10-11)

| thing | measurement |
|---|---|
| `DOD_GST_SAC_CODES` | **exists, and holds 0 rows** — nothing in the tree ever writes to it |
| its columns | `ROW_ID`, `SAC_CODE varchar(10) UNIQUE`, `SAC_CODE_4DIGIT varchar(6)`, `SAC_DESCRIPTION text`, `CONDITION_TXT text`, `CGST decimal(4,2)`, `SGST decimal(4,2)`, `IGST decimal(4,2)`, `GST_SAC_FUNC varchar(255)`, `TENANT_ID` |
| its view class | `dod-gst-sac-codes`, `products/dod-dal-prd.lisp:306` (`sac-code`, `sac-description`, `sac-code-4digit`, `condition-txt`, `cgst`, `sgst`, `igst`, `gst-sac-func`) |
| its ONLY reader | `get-all-gst-sac-codes`, `products/dod-bl-prd.lisp:14` → hash `SAC_CODE → SAC_DESCRIPTION` **only** — the cached path cannot yield a rate |
| cache wiring | index 13 of `*HHUBGLOBALLYCACHEDLISTSFUNCTIONS*` (`core/dod-ini-sys.lisp:329`), accessor `hhub-get-cached-gst-sac-codes-ht` (`:417`). Built ONCE at `START-DAS` → `(refreshiamsettings)` after any seed (the ABAC skill's §8 step 4 trap) |
| the GOODS side, for contrast | `DOD_GST_HSN_CODES`: **21,255 rows, all `TENANT_ID 1`**, and every selector filters `TENANT_ID = 1` (`products/dod-bl-gst.lisp:12-46`, e.g. `select-hsn-code-by-code` at `:34`) |
| who the products belong to | `SELECT DISTINCT TENANT_ID FROM DOD_PRD_MASTER` → **2 and 5**. The rate master's tenant is NOT the product's tenant |
| where a service's code lives | `DOD_PRD_MASTER` has **no SAC column**; a service row carries its SAC in `HSN_CODE`. Measured: `FREIGHT-1`, `ROW_ID 189`, `HSN_CODE '9965'`, `PRD_TYPE 'SERV'`, `TENANT_ID 2` |
| line tables | `DOD_ORDER_ITEMS` has BOTH `HSN_CODE` and `SAC_CODE`; `DOD_INVOICE_ITEMS` has `HSNCODE` only — no SAC column |

**The trap this table hides.** `get-gstvalues-for-product` (`products/dod-bl-gst.lisp:53`) resolves a
product's rate through the HSN master and, on a miss, takes the `:F` branch and returns
`(0.0 0.0 0.0 0.0)` (`:68`). A service product therefore resolves to a **zero rate silently** — no
error, no log. That is exactly how invoice `NST00117-2026` came to carry a freight line with taxable
114.29 and CGST/SGST 0.00.

---

## 2. Why this surfaced, and what is already fixed

`FREIGHT-<id>` products are `PRD_TYPE SERV` holding the SAC `9965` (goods transport services). There is
no `9965` row in `DOD_GST_HSN_CODES` (measured: 0), and the SAC table is empty, so the rate resolver
returned zeros. The delivery charge on an invoice was then written untaxed while the CART, the ORDER
line and the invoice's own legacy fallback all taxed it at the **principal goods' rate** (composite
supply, CGST §8) — invoices 113 and 117 are the two written under-taxed, 117 being ₹5.71 short of its
order (`TOTALVALUE` 1594.79 against the order's lines summing 1600.50).

⚠ **The fix was NOT to give the freight a SAC rate.** `hhub/invoice/nst-bl-invhapi.lisp` now maps the
order's own delivery line with an explicit `rates-override` carrying the principal goods' rates
(`invh-line-args-from-order-line`, §7 below). A delivery charge that rides with goods is part of THAT
supply; its own service code is deliberately not consulted. Keep the two questions separate:

* *"what rate does this service carry when sold on its own?"* → this file, the SAC master.
* *"what rate does a delivery charge carry on a goods invoice?"* → the principal goods' rate, already
  implemented, already asserted.

---

## 3. The questions to settle BEFORE writing the migration (this is the thought process)

1. **Precedence, written down.** A service sold on its own takes its SAC rate; an ancillary charge on a
   supply of goods takes the principal supply's rate (composite supply, CGST §8) and must ignore its own
   code. Decide where that rule lives so the cart and the invoice cannot answer differently — today the
   cart's `nst-freight-order-line` and the invoice agree only because both were changed together.
2. **Where the code is stored.** Keep putting a service's SAC in `DOD_PRD_MASTER.HSN_CODE` (no DDL, but
   the column lies about what it holds), or add `SAC_CODE` to `DOD_PRD_MASTER` (DDL migration, and then
   every product form, import and lookup that reads `hsn-code` needs to know which column to read).
   Related: `DOD_INVOICE_ITEMS` has no SAC column at all, so a service line's code can only print from
   `HSNCODE` unless that table gains one — which is a document-schema decision, not a code detail.
3. **Tenant semantics — DECIDED 2026-10-11, so this is no longer a question.** The masters are **COMMON
   tables**: a country's code list is a fact about the country, not about a tenant, and the `TENANT_ID` on
   them is **decorative** — `select-hsn-code-by-code` filters `TENANT_ID = 1` while
   `get-gstvalues-for-product` passes a tenant-2/5 company, and every rate resolves anyway. So: seed
   `DOD_GST_SAC_CODES` with its natural key **`(COUNTRY_CODE, SAC_CODE, EFFECTIVE_FROM)`** and NOT with a
   tenant dimension — seeding it tenant-scoped would bake in the same pretence the HSN table now carries.
   See `multi-jurisdiction-tax-CONTEXT.md` §1.1. ⚠ A read filtered by the PRODUCT's tenant returns nothing
   and reproduces the silent-zero bug that started this.
4. **Seed scope and provenance.** The service families actually sold (9965 goods transport, 9987/9983
   maintenance and installation, 9954 construction, 9985 support services…), or the full CBIC SAC list
   the way the 21,255 HSN rows were imported? Whatever is chosen, record where the list came from, as
   `installation/upgrades/hsnrates-2026Oct/SOURCES.md` does for HSN.
5. **What the resolver is, and what it does on a miss.** Extend `get-gstvalues-for-product` (HSN for
   goods, SAC for `PRD_TYPE 'SERV'`), or add a service-aware wrapper used only where services are sold.
   ⚠ **A miss must not be a zero rate.** Refuse instead, the way `invh-assemble-from-order` already
   refuses an unattributable delivery charge (`nst-entity-contradiction`, two branches) — an
   unresolvable rate on a line with a positive taxable value is a document that under-states tax.
6. **Callers move together.** `get-gstvalues-for-product` is used by the CART
   (`update-gst-for-order-lineitem`), the product UI and the order API's `ordhapi` path. Changing it
   changes what the cart charges, so cart and invoice must be changed in one batch or neither.
7. **The cache.** `get-all-gst-sac-codes` carries descriptions only. Either the resolver queries the
   table directly (mirroring `select-sac-code-by-code` on `select-hsn-code-by-code`) or the cached
   structure gains the rate triple — and if it is cached, `(refreshiamsettings)` is mandatory after the
   seed, or the rows will be invisible to the running image.
8. **`GST_SAC_FUNC`.** Unused today. Decide whether it mirrors HSN's `GST_HSN_FUNC` hook (`products/dod-dal-gst.lisp:188`) for conditional rates. ⚠ While there: `products/dod-dal-prd.lisp:343-344` declares the SAC slot `gst-sac-func` with `:accessor gst-hsn-func` — the HSN class's accessor name; fix it before anything reads that slot.

---

## 4. The migration, when it is written

Shape it exactly like `installation/upgrades/nst-dbu-hsnrates.lisp`:

* a file in `installation/upgrades/` (deliberately in **neither** `hhub/nstores.asd` nor
  `hhub/package/compile.lisp` — `apply-migrations` loads it via `load-upgrade-files`), plus an entry in
  `*migrations*` (`core/nst-sch-mig.lisp:10`);
* **version ≤ 50 characters** (`varchar(50)`, or the skip test never matches and it re-runs forever) and
  a description ≤ 100 characters (`DOD_AUTH_POLICY.DESCRIPTION`-style STRICT-mode trap);
* idempotent — skip an existing `SAC_CODE` (the column is `UNIQUE`) rather than blind-INSERT;
* every string through `sql-literal`; `TENANT_ID` chosen per §3.3;
* re-run it once and confirm it is a no-op before calling it applied.

---

## 5. Verification to write alongside it

An offline tool in the style of `aiharness/deepseek/tools/nst-verify-cart-tax-state.lisp` (loads
`:nstores` from source against the real DB, writes nothing):

1. a service product with a seeded SAC resolves that rate;
2. a service product with NO resolvable rate makes its line REFUSE (not zero-tax);
3. **regression for §7**: a goods order carrying a freight line still invoices that line at the
   principal goods' rate, whatever rate the SAC master holds for 9965.

---

## 6. File map

| Concern | Location |
|---|---|
| SAC table + view class | `products/dod-dal-prd.lisp:306` |
| SAC cache builder / accessor | `products/dod-bl-prd.lisp:14`; `core/dod-ini-sys.lisp:329`, `:417` |
| HSN rate master (the pattern to mirror) | `products/dod-bl-gst.lisp:12-46`, `products/dod-dal-gst.lisp:147`; seed `installation/upgrades/nst-dbu-hsnrates.lisp` |
| the resolver's zero-on-miss branch | `products/dod-bl-gst.lisp:68` |
| the invoice's freight/principal-rate rule (§7) | `hhub/invoice/nst-bl-invhapi.lisp` — `invh-line-args-from-order-line`, `invh-assemble-from-order`, `invh-freight-line-args`, `invh-principal-rate-triple` |
| the cart's own composite-supply rule | `order/dod-bl-odt.lisp` — `nst-freight-order-line`, `nst-cart-with-delivery-line` |
| freight product seed | `installation/upgrades/nst-dbu-freight-product.lisp` |

---

## 7. DO NOT REDO — what is already fixed (2026-10-11)

`invh-line-args-from-order-line` takes an optional `rates-override`, and `invh-assemble-from-order`
splits the order's lines so that the delivery line is mapped with the GOODS' principal rates
(`invh-principal-rate-triple` over the goods-only args) and the principal vote is taken by the goods
alone. That is deliberate: a delivery charge is a composite supply at the principal rate, so it must
never be re-pointed at the freight product's own code — not even once 9965 has a rate of its own.
Effective behaviour: the carried delivery line is taxed exclusively (114.29 + 2.86 + 2.85 = 120.00, the
order's own line total), the legacy inclusive fallback for a tax-free `SHIPPING_COST` is untouched, and
with no carried delivery line nothing changed at all.
