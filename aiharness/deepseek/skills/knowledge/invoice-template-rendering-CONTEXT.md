# Invoice documents — the template system, and why a second renderer cannot match it

**Read this when:** you need to render an invoice (a page, a PDF, an email attachment),
you are choosing or changing an invoice layout, a customer's view of an invoice must match
the vendor's, or you are about to hand-write invoice markup.

**Verified:** 2026-10-13 by tracing the call graph with `nst-symq` and reading the code.
The extraction described in §5 was made and verified this session.

---

## 1. The headline

**There is a real template system. Use it.** It is five GST-compliant invoice layouts,
loaded at startup, filled by one function, and chosen per vendor. Anything you build by
hand from entity data will be a *second* rendering of the same invoice — and it will
differ in ways that matter (see §4).

---

## 2. The pieces

| Piece | Where |
|---|---|
| The layouts | `hhub/invoice/templates/gstinvoice{1,2,3A5,480mm,5A4}.html` |
| The default | `*NST-GSTINVOICE-DEFAULTTEMPLATENUM*` = **13** (`gstinvoice5A4`) — `core/dod-ini-sys.lisp:152` |
| The file paths | `*NST-GSTINVOICE-TEMPLATEFILE-1..5*`, `core/dod-ini-sys.lisp:146`–`150` |
| The number→name map | `*NST-GSTINVOICE-TEMPLATES-HT*` (9→1, 10→2, 11→3A5, 12→480mm, 13→5A4) |
| Loaded at startup | `nst-load-invoice-templates` (`dod-ini-sys.lisp:465`), called by `start-nst-server` |
| Template text for N | `(funcall (nst-get-cached-invoice-template-func :templatenum N))` → the HTML |
| **The vendor's choice** | `nst-get-vendor-invoicetemplatenum vendor` → reads that vendor's `INVOICE_SETTINGS`, validates against the map, falls back to 13 |
| **The filler** | `invoicetemplatefill`, `invoice/nst-ui-ihd.lisp` |
| Line rows | `generate-invoice-items-rows-public`, `invoice/nst-ui-itm.lisp:334` |
| QR code | `generateqrcodeforvendor` (writes a file under `/img`) |

### The template is a FRAGMENT, not a document

`gstinvoice5A4.html` opens with `<style>` — there is **no** `<!doctype>` and no `<html>`.
So it embeds cleanly inside an existing page's markup; nesting a full document is not a
problem. (The public page already embeds it inside the standard vendor page template.)

### The substitutions

`invoicetemplatefill (invoicetemplate invheader invoiceitems invoiceitemshtmlfunc
invoicetaxbreakdownfunc qrcodepath currency vendor)` replaces, in this order:
vendor name / address / phone / email / GST number → `%Template Logo Image%`,
`%Template Header%`, `%Template Footer%` (all three driven by the vendor's print settings;
"enable" gates the TEXT only, the logo is controlled by its path alone) → `%Invoice
Number%`, `%Order Number%`, `%Invoice Date%`, `%Invoice Status%`, `%Date of Supply%`,
`%State Code%`, `%Place of Supply%` (those two via `*NSTGSTSTATECODES-HT*`), `%Reverse
Charge%`, `%Vehicle Number%`, and the rest of the legacy header's slots.

Line rows come from a marked block repeated per item:

```
<!--ROW_SNIPPET_BEGIN--> … <!--ROW_SNIPPET_END-->
```

with `%srno%` and `%row prddesc%` / `hsncode` / `uom` / `qty` / `price` / `discount` /
`taxable` / `cgst` / `sgst` / `igst` / `totalitemval` substituted per line.
`remove-invoice-item-markers-from-template` strips the markers before the fill.
⚠ `generate-invoice-items-rows-public` **signals** if the markers are absent — a template
without them cannot be used for a multi-line invoice.

---

## 3. The data path, and the one thing it does NOT check

The filler's inputs come from the **legacy DDD adapters**:

```lisp
(processreadrequest    (make-instance 'InvoiceHeaderAdapter) hrequestmodel)   ; by (invnum, company)
(processreadallrequest (make-instance 'InvoiceItemAdapter)   irequestmodel)
```

The header adapter reads by **`(invnum, company)` alone**. It knows nothing about a buyer,
because the page that owned it was reached with a **signed key and a password**, never a
session.

🚨 **So if you call it while serving a logged-in customer, YOU must establish that the
invoice is theirs first.** Rendering a client-supplied invoice number without that check
shows **any** invoice in the company to **any** of its customers. See §5 for how the
customer details page does it.

---

## 4. Why not just build it from the register view

Measured against the whole `DOD_V_CUSTOMER_INVOICE_REGISTER` view DDL — it publishes 23
columns from `DOD_INVOICE_HEADER`, and these are **absent**:

`TOTALINWORDS`, `BANKACCNUM`, `BANKIFSCCODE`, `TNC`, `AUTHSIGN`, `TRANSMODE`
(`VNUM` is absent too — beware grepping for it, `INVNUM` matches as a substring).
`REVCHARGE`, `STATECODE`, `STATUS`, `GSTR1_PERIOD` **are** published.

So a hand-built page cannot print the amount in words, the bank details, the terms and
conditions, the authorised signatory or the vehicle number — all of which the template
carries. A second renderer also silently ignores the vendor's template number, logo,
header/footer text, watermark and paper size.

**That is the argument in one line:** the template is the invoice; a hand-built page is an
approximation of it, and the two will be compared side by side by a customer holding the
PDF.

---

## 5. `build-invoice-template-document` — the shared renderer

Extracted 2026-10-13 from the body of `create-model-for-displayinvoicepublic` so the
customer's invoice-details page renders the **same** document:

```lisp
(build-invoice-template-document invnum vendor company)   ; → filled HTML, or NIL
```

* **Callers:** `create-model-for-displayinvoicepublic` (the public page) and
  `create-model-for-customer-invoice-details` (`nst-ui-cusinv.lisp`).
* ⚠ **Not buyer-scoped** (§3). The customer page calls its own buyer-scoped
  `fetch 'nst-cinv` **first** and only then the builder — and the order is the security
  argument, not style.
* **Returns NIL rather than signalling** when the invoice does not resolve for `company`.
  The original inline code read `(slot-value invheader 'invnum)` unguarded, so an invoice
  deleted after its link was minted answered a **500**; the public page's widget now says
  *"This invoice is no longer available… The link itself was valid."*
* The extraction is text-faithful: all 12 steps, same order. Verified by comparing the
  ordered operation list against `git show HEAD`'s inline version.

---

## 6. The PDF pipeline (and what it costs)

```
generate-invoice-ext-url invnum vendor company :render t   ; signed, expiring, self-fetchable
  → downloadhtmlfile      ; wget into <resources>/temp/
  → generatepdf           ; wkhtmltopdf, returns the bare FILE NAME
  → 302 at <siteurl>/img/temp/<file>
```

* `:render t` is **required** for a server-side fetch: without the marker the fetch lands
  on the public page's password prompt and the "PDF" is **a picture of the password form**.
* ⚠ The pipeline **shells out and fetches the server's own public URL**, so it is slow and
  it needs `*siteurl*` to point at *this* deployment. That is a property of the pipeline,
  inherited by the vendor download, the API `/download` route and the email attachment
  alike.
* ⚠ `generatepdf`'s **exit code is not the test** — wkhtmltopdf exits 1 on the invoice page
  (an `about:blank` subresource) while still writing a correct PDF. The artifact decides:
  `%PDF` magic bytes + a size above the blank-page floor.
* ⚠ `generate-invoice-ext-url` **fails closed with a plain error** when the vendor has no
  `SALT`. Catch it and answer a sentence, not a 500.
* On a render token the public page **suppresses its own download button**, because
  wkhtmltopdf rewrites a relative href into an absolute one and would otherwise print a
  live, password-free render URL *inside the PDF*.

---

## 7. Booking a new consumer in — the checklist

1. **Resolve the vendor and company** (`select-vendor-by-id`, `select-company-by-id`).
2. **Verify ownership if you are serving a customer** — the builder will not.
3. Call `build-invoice-template-document`; handle **NIL** as "no document", not as an
   error and not as a blank page.
4. Emit the result with `cl-who:str` — **it must NOT be escaped** (it is already HTML).
5. Put your own controls **outside** the template, not inside it: the template is the
   vendor's document, and a button injected into it lands in the printed PDF.
