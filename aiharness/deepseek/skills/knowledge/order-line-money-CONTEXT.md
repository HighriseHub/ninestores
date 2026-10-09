# Order-line money: what each stored column means, and the three ways a page misreads it

Measured 2026-10-09 on order 503 (`ORD-GCUST837-2026-27-RMJCMJ`, GUEST/B2C, `ORDER_AMT` 6832.87).
Every figure below was read out of `hhubdb`, not inferred. The story is short: **one stored line carries
money in two different bases** — a *unit* price and *whole-line* amounts — and the code that read them
mixed the two, in three separate places.

## §1 The columns of `DOD_ORDER_ITEMS`, and the base of each

| Column | Base | Meaning |
|---|---|---|
| `UNIT_PRICE` | per unit | the price the line was sold at, **before** discount |
| `DISC_RATE` | percent | line discount; `NULL` means none (the code branches on this, not on 0) |
| `TAXABLEVALUE` | **whole line** | `qty x (UNIT_PRICE - discount)`, rounded to the paise |
| `TOTALITEMVAL` | **whole line** | `TAXABLEVALUE` + the line's tax — the line total, and the figure that sums to `DOD_ORDER.ORDER_AMT` |
| `CGSTAMT` / `SGSTAMT` / `IGSTAMT` | **whole line** | the tax amounts; `0.00`, never `NULL`, on an untaxed line |
| `CGST` / `SGST` / `IGST` | percent | the RATES — 🚨 **`NULL` on every order measured from 475 to 503** (§5) |

Order 503's six lines, verbatim:

| Qty | `UNIT_PRICE` | `TAXABLEVALUE` | `TOTALITEMVAL` | CGST+SGST | rate cols |
|---|---|---|---|---|---|
| 1 | 1200.00 | 1140.00 | 1345.20 | 102.60 + 102.60 | NULL |
| 3 | 100.00 | 285.00 | 285.00 | 0.00 | NULL |
| 3 | 610.00 | 1738.50 | 1825.42 | 43.46 + 43.46 | NULL |
| 5 | 75.00 | 356.25 | 356.25 | 0.00 | NULL |
| 10 | 185.00 | 1757.50 | 1757.50 | 0.00 | NULL |
| 14 | 95.00 | 1263.50 | 1263.50 | 0.00 | NULL |

Sum of `TOTALITEMVAL` = **6832.87** = `DOD_ORDER.ORDER_AMT` = what the Place Order page showed. The
stored data was right the whole time; every defect below was a reader.

## §2 🚨 `calculate-order-item-cost` is a PER-UNIT cost — the qty x tax class

`hhub/order/dod-ui-odt.lisp`. It answered `(unit price net of discount) + sgstamt + cgstamt + igstamt`,
i.e. a **unit** price with **whole-line** tax added, and **every one of its nine call sites multiplies
the result by `prd-qty`**. A taxed line of qty > 1 therefore counted its tax `qty` times: the seller's
figure was inflated by exactly `(qty - 1) x that line's tax`.

On order 503 that is one line (qty 3, tax 86.92): `2 x 86.92 = 173.84`, and 6832.87 + 173.84 = **7006.71**
— the stored `DOD_VENDOR_ORDERS.ORDER_AMT`, and the "Total" the vendor's page printed. The fix divides
each tax amount by `prd-qty` inside the function, so `cost x qty` is the line total again.

Two traps inside that one function:

* **`check-null` SIGNALS** (`hhub/core/dod-bl-err.lisp`) — it is not a defaulting helper. It is safe only
  because the tax AMOUNT columns are `0.00` rather than `NULL` (measured on all six of 503's lines). It
  would error on a genuinely `NULL` amount; a new helper that must tolerate `NULL` has to test
  `numberp`, not call `check-null`.
* the discount branch tests `disc-rate` for non-nil, so `DISC_RATE = 0` takes the `else` branch — which
  happens to be arithmetically identical. Do not "simplify" it into `(* unit-price (/ disc-rate 100))`
  without the guard: that is a division by a possibly-`NIL` value.

## §3 `get-order-items-total-for-vendor` is NOT a display helper — it is WRITTEN to the database

`hhub/customer/dod-ui-cus.lisp`, called from `hhub/order/dod-bl-ord.lisp` `save-vendor-orders-in-db`
(≈ line 572), whose result `persist-vendor-orders` stores in `DOD_VENDOR_ORDERS.ORDER_AMT`. It is also
what the vendor API serves. So a defect in it is not a rendering bug: it is **persisted money**, and
repairing the code does not repair the rows already written (§6). It now rounds with
`round-to-2-decimal` — the sum of per-unit divisions lands a hair under the true figure in single-float
(6832.8699…), and this number is stored.

`fround` is COMMON-LISP's standard rounder and answers the nearest **whole integer** as a float:
`(fround 3815.20)` = 3815.0. It appeared in six money totals (`nst-bl-Order.lisp`, `nst-bl-ordh.lisp`,
`nst-ui-ihd.lisp`) and is the measured 0.20 gap between a legacy invoice's header and its own lines.
Money rounds with `round-to-2-decimal` (`hhub/core/dod-bl-utl.lisp`), always.

## §4 The three display defects on `/hhub/vorderdetailspage` (`ui-list-vend-orderdetails`)

1. **"Unit Price" printed `taxablevalue`** — a whole-line figure in a per-unit column (ghee showed
   1738.50 where the price is 610.00). It now prints `taxablevalue / qty`, the *net* per-unit price, so
   Unit Price x Qty = the taxable value and the row reconciles: rate + taxes = Sub-total.
2. **"Sub-total" printed `(* totalitemval prd-qty)`** — a line total multiplied by its own quantity
   again (oil: 1757.50 x 10 = 17575.00). `TOTALITEMVAL` *is* the line total; it now prints it as is.
3. **the rate columns printed `NIL`** — the format is `~$`, which renders a null as `NIL`, so the row
   read `Rs 102.60 @ NIL%`. `nst-order-item-tax-rate` (`dod-ui-odt.lisp`) now answers the stored rate,
   or derives the percentage from `amount / taxablevalue` when the stored rate is NULL (9.00% and 2.50%
   on 503's two taxed lines), or 0 when no tax was charged at all.

## §5 OPEN: the writer never stores the RATES (and sometimes stores no tax at all)

Measured 2026-10-09 across `DOD_ORDER_ITEMS`:

* **every** order from 475 to 503 has `CGST`/`SGST`/`IGST` `NULL` on **every** line;
* on order 503 only **2 of 6** lines stored any tax amount; the other four stored no GST whatsoever,
  although two of them are taxable goods;
* 27 lines in the table carry a tax amount with a `NULL` rate; 33 carry a rate.

The amounts that *are* written are correct (503's 102.60 = 9% of 1140.00), so the arithmetic path is
fine and the **writer is dropping the rates** — `update-gst-for-order-lineitem` sets the slots, so the
break is between the cart's line objects and `persist-order-items`. This is a GSTR-1-grade gap, not a
display one: a rate column that is never populated cannot feed a return. The display currently *derives*
the percentage, which is right for the reader and **hides** the writer gap — do not read a correct page
as evidence that the stored rates exist.

## §6 Data-repair discipline (a lesson this file paid for)

The wrong `ORDER_AMT` values were already persisted, so a code fix alone left order 503 wrong. A repair
keyed on an aggregate must be guarded, and this one was not at first:

```sql
-- 🚨 WITHOUT `line_total > 0` THIS ZEROES ROWS IT CANNOT DERIVE
... JOIN (SELECT ORDER_ID, VENDOR_ID, ROUND(SUM(TOTALITEMVAL),2) AS line_total
            FROM DOD_ORDER_ITEMS WHERE DELETED_STATE='N' GROUP BY ORDER_ID, VENDOR_ID) x ...
WHERE vo.DELETED_STATE='N' AND x.line_total > 0
  AND ABS(vo.ORDER_AMT - x.line_total) > 0.009
```

The pre-2026 demo orders **do** have live item rows, but those rows still carry `TOTALITEMVAL 0.00`
(the column was added later and never backfilled), so their "line total" is 0 — and an unguarded repair
read that as "the amount should be 0" and zeroed **371** rows (measured: 371 changed, all 371 previously
non-zero). **An un-derivable row is not a zero row.** The guard is now in
`installation/upgrades/nst-dbu-vendor-order-amount-repair.lisp`, whose header records this.

What saved the data — worth knowing before the next repair:

* **the ORDER header was never touched.** `DOD_ORDER.ORDER_AMT` equals `SUM(TOTALITEMVAL)` and equals
  the per-vendor recomputation in 346 of 371 demo rows, so it is an independent cross-check, and for a
  single-vendor order it *is* the vendor row's value. The demo rows were restored from it (and the four
  multi-vendor demo orders split correctly against it: 20.00 + 719.00 = 739.00).
* **measure the blast radius BEFORE the write**, not after: the same `SELECT` with and without the
  guard answers `0 rows` vs `371 rows` and costs one query.
* a `SELECT` printed before an `UPDATE` is the only before-image there is — binlog row images are not
  readable by the app user (`REPLICATION CLIENT` denied), and no dump of `hhubdb` exists (`/home/ubuntu/hhubdb.sql`
  is a 2024 schema seed of 11 KB). If a repair matters, dump the affected rows to a file first.

## §7 Where these readers live, and the rule they share

* the cart and the ship-methods page: `hhub/customer/dod-ui-cus.lisp` — **the two-value rule**
  (`SHIPPING_COST` = what the total may add, 0 when the delivery is already a LINE; `delivery-display` =
  what the customer is shown) is in `knowledge/gst-tax-jurisdiction-CONTEXT.md` §6. A display value
  reused as an arithmetic one is what added the delivery twice.
* the vendor's page: `ui-list-vend-orderdetails` (`hhub/vendor/dod-ui-ven.lisp`) and
  `calculate-order-item-cost` (§2).
* the customer's own order page: `ui-list-cust-orderdetails` (`hhub/order/dod-ui-odt.lisp`) — it reads
  `calculate-order-item-cost` too, so it inherited §2 and was fixed by the same change.

## §8 Registration

`nst-order-item-tax-rate` is new, so the generated DAG `hhub/core/nst-bl-funloodat.lisp` needs
regeneration before `nst-symq` knows it. The vendor-page change is UI-only: the running image must be
restarted before the browser shows any of §4; the `ORDER_AMT` repair (§6) needs no restart.
