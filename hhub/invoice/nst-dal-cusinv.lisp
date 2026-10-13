;;; nst-dal-cusinv.lisp — CUSTOMER (INWARD) INVOICE REGISTER — DAL
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved. MIT License — see LICENSE.
;;;
;;; THE GRAMMAR: hhub/core/nst-bl-adhara.lisp. Tree 1 (island): nst-cinv,
;;; nst-cinv-itc-summary ← nst-domain-entity. Tree 2 (boundary): the three
;;; NstCinv* Request/ResponseModels ← nst-boundary-object. ⚠ Never intersect.
;;;
;;; THE PLAYBOOK: hhub/nst-adhara-GENERIC-migration-playbook.md (§5 = this file).
;;; MASTER TEMPLATES: warehouse/nst-dal-warehouse.lisp (structure),
;;;                   invoice/nst-dal-invh.lisp (the invoice domain's habits).
;;;
;;; REPLACES the DDD boundary classes that lived in invoice/nst-dal-cusinvreg.lisp —
;;; CustomerInvoiceRegister Adapter/Presenter/Service/HTMLView/JSONView/RequestModel
;;; and CustomerInvoiceEntry{,ResponseModel,ViewModel} — all retired-stack objects.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE SOURCE IS A READ-ONLY VIEW — WHICH IS WHY THREE VERBS DO NOT EXIST
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; DOD_V_CUSTOMER_INVOICE_REGISTER is a three-table join (DOD_INVOICE_HEADER ×
;;; DOD_VEND_PROFILE × DOD_CUST_PROFILE), defined by the
;;; migrate-2026May-create-customer-inward-invoices-view upgrade. Two consequences:
;;;
;;;   1. NO make / !update / delete! METHOD EXISTS ON nst-cinv — THE GRAMMAR'S OWN
;;;      RULE, NOT AN OMISSION: a join view cannot be INSERTed, and "this invoice is
;;;      deleted" is a fact about the VENDOR's document, not the buyer's register row.
;;;
;;;   2. THE VIEW IS B2B-ONLY: `AND cp.GST_CUSTOMER_TYPE = 'B2B'`, so a B2C buyer's
;;;      enumerate is an empty list with NO error.
;;;
;;; ⚠ THE VIEW PUBLISHES `ih.TENANT_ID` BUT `cp.ROW_ID AS BUYER_ID`, FROM TWO
;;; DIFFERENT TABLES: every verb filters on BOTH, or a row whose header tenant
;;; differs from the buyer's is half-matched. Do not relax that to one predicate.
;;; ───────────────────────────────────────────────────────────────────────────

(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Tree 1: the domain entity
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; EVERY SLOT CARRIES :initarg + :accessor + :initform NIL: the copy helper reads
;;; every slot with a plain accessor call, so a slot with no :initform is
;;; UNBOUND-SLOT on the first row that omits it. NIL means "genuinely absent".
;;;
;;; row-id keeps NO initform on purpose: it is the view's key (INVOICE_ID) and is
;;; bound by the copy helper from the row itself.
;;;
;;; id / tenant-id / created-at / updated-at / deleted-state are INHERITED from
;;; nst-domain-entity and are NOT redeclared — the ferry strips them from client
;;; params (*reserved-initargs*) and supplies tenant-id from domain-ctx.

(defclass nst-cinv (nst-domain-entity)   ; NOT (business-object nst-domain-entity)
  (;; ── THE VIEW'S KEY ──────────────────────────────────────────────────────
   (row-id
    :initarg :row-id
    :accessor row-id
    :documentation
    "DOD_V_CUSTOMER_INVOICE_REGISTER.INVOICE_ID = DOD_INVOICE_HEADER.ROW_ID — the
     buyer-facing address of the document; every fetch is by this value.")

   ;; ── IDENTITY OF THE DOCUMENT ────────────────────────────────────────────
   (invoice-number
    :initarg :invoice-number
    :accessor invoice-number
    :initform nil
    :documentation
    "INVNUM varchar(50) — the VENDOR's invoice number, the cross-party key the buyer
     quotes back. ⚠ Unique per tenant by uk and written by a MySQL trigger on
     DOD_INVOICE_HEADER (see PENDING-WORK §1d), never by any Lisp code.")
   (invoice-date
    :initarg :invoice-date
    :accessor invoice-date
    :initform nil
    :documentation "INVDATE date — a CLSQL date object, never the raw HTTP string.")
   (financial-year
    :initarg :financial-year
    :accessor financial-year
    :initform nil
    :documentation "FINYEAR varchar(9), e.g. \"2026-2027\" — April–March.")
   (gst-period
    :initarg :gst-period
    :accessor gst-period
    :initform nil
    :documentation
    "GSTR1_PERIOD varchar(7) \"YYYY-MM\" — the period the vendor files under, and what
     a GSTR-2B reconciliation would join on. ⚠ NULL ON EVERY ROW TODAY; reported as
     absent rather than defaulted, because a guessed tax period is worse than a missing one.")

   ;; ── VENDOR (the supplier of this inward supply) ─────────────────────────
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id
    :initform nil
    :documentation "FK to DOD_VEND_PROFILE.ROW_ID.")
   (vendor-name
    :initarg :vendor-name
    :accessor vendor-name
    :initform nil
    :documentation
    "COALESCE(vp.LEGAL_NAME, vp.NAME) — the view resolves the vendor's legal name
     first. Note the BUYER side does NOT do the same (see buyer-name).")
   (vendor-trade-name
    :initarg :vendor-trade-name
    :accessor vendor-trade-name
    :initform nil)
   (vendor-gstin
    :initarg :vendor-gstin
    :accessor vendor-gstin
    :initform nil
    :documentation
    "DOD_VEND_PROFILE.GSTNUMBER. ⚠ The single most load-bearing field on the page:
     ITC is only claimable against a supplier who is registered AND has filed. NULL
     for an unregistered vendor, reported as absent rather than as an empty string.")
   (vendor-gst-type
    :initarg :vendor-gst-type
    :accessor vendor-gst-type
    :initform nil
    :documentation "REGULAR / COMPOSITION / UNREGISTERED / SEZ.")
   (vendor-filing-frequency
    :initarg :vendor-filing-frequency
    :accessor vendor-filing-frequency
    :initform nil
    :documentation
    "MONTHLY / QUARTERLY. ⚠ Nullable and never populated today; the ITC-at-risk
     story needs it (a QUARTERLY filer's ITC legitimately appears a month later),
     which is why it is carried even though nothing reads it yet.")

   ;; ── BUYER (the session's own party) ─────────────────────────────────────
   (buyer-id
    :initarg :buyer-id
    :accessor buyer-id
    :initform nil
    :documentation
    "cp.ROW_ID — the DOD_CUST_PROFILE row the register is scoped by; it comes from
     the SESSION, never from a client param.")
   (buyer-name
    :initarg :buyer-name
    :accessor buyer-name
    :initform nil
    :documentation
    "COALESCE(cp.LEGAL_NAME, cp.NAME). ⚠ OPEN DEFECT, MEASURED 2026-10-13:
     LEGAL_NAME is NULL on every live B2B row and the real name sits unread in
     LEGAL_COMPANY_NAME, so this returns an ACCOUNT display name — not tax-document safe.")
   (buyer-gstin
    :initarg :buyer-gstin
    :accessor buyer-gstin
    :initform nil
    :documentation
    "cp.GSTIN. ⚠ Carried, but not evidence of registration: customer 27 has a GSTIN
     alongside GST_REGISTRATION_TYPE 'UNREGISTERED', and the view exposes the
     registration type only on the vendor side — a gap this slot cannot close.")
   (buyer-gst-type
    :initarg :buyer-gst-type
    :accessor buyer-gst-type
    :initform nil)

   ;; ── MONEY ───────────────────────────────────────────────────────────────
   (total-amount
    :initarg :total-amount
    :accessor total-amount
    :initform nil
    :documentation
    "ih.TOTALVALUE — the HEADER's own figure, NOT the sum of the lines. ⚠ MEASURED
     2026-10-13: they DISAGREE on 3 of the 4 live invoices for customer 27, and which
     is authoritative is undecided; itc-derived holds the line-derived figure.")
   (balance-due
    :initarg :balance-due
    :accessor balance-due
    :initform nil)
   (advance-adjusted
    :initarg :advance-adjusted
    :accessor advance-adjusted
    :initform nil)
   (payment-allocated
    :initarg :payment-allocated
    :accessor payment-allocated
    :initform nil)

   ;; ── ITC (the reason the page exists) ────────────────────────────────────
   (itc-eligible
    :initarg :itc-eligible
    :accessor itc-eligible
    :initform nil
    :documentation
    "BOOLEAN (tinyint), DDL default TRUE. ⚠ AN OPTIMISTIC DEFAULT, NOT A FINDING:
     nothing in the tree writes it, so it is 1 on every row — read it as 'not yet
     disqualified' (Section 17(5), a composition supplier, a missing GSTIN).")
   (itc-recorded
    :initarg :itc-recorded
    :accessor itc-recorded
    :initform nil
    :documentation
    "ih.ITC_AMOUNT DECIMAL(15,2) — the ITC LEDGER value, written when a credit is
     actually taken. 🚨 NULL ON EVERY ROW and no code path writes it (a whole-tree
     sweep finds only readers), so it is NOT the number the dashboard shows.")
   (itc-claimed
    :initarg :itc-claimed
    :accessor itc-claimed
    :initform nil
    :documentation
    "BOOLEAN (tinyint), DDL default FALSE, never written. ITC is claimed in
     GSTR-3B; this platform can track it but cannot claim it.")
   (itc-claim-month
    :initarg :itc-claim-month
    :accessor itc-claim-month
    :initform nil
    :documentation "ITC_CLAIM_MONTH varchar(7) \"YYYY-MM\". NULL on every row.")
   (itc-derived
    :initarg :itc-derived
    :accessor itc-derived
    :initform nil
    :documentation
    "THE ITC COMPUTED FROM THE INVOICE'S OWN LINE ITEMS — SUM(CGSTAMT + SGSTAMT +
     IGSTAMT) over lines that are not soft-deleted. Why derived: DOD_INVOICE_HEADER
     carries NO tax totals at all. ⚠ MUST be a per-invoice aggregate, never a join.")
   (itc-amount
    :initarg :itc-amount
    :accessor itc-amount
    :initform nil
    :documentation
    "THE EFFECTIVE FIGURE, and the one the register displays: the ledger value when
     a claim has been recorded, otherwise the derived one. Filled by the copy
     helper, not by the database.")

   ;; ── GSTR-2B RECONCILIATION ──────────────────────────────────────────────
   (in-gstr2b
    :initarg :in-gstr2b
    :accessor in-gstr2b
    :initform nil
    :documentation
    "BOOLEAN (tinyint), DDL default FALSE, never written — no 2B data has ever
     been ingested (DOD_GST_RECONCILIATION and DOD_INVOICE_GST_RECONCILIATION
     both hold 0 rows).")
   (gstr2b-match-status
    :initarg :gstr2b-match-status
    :accessor gstr2b-match-status
    :initform nil
    :documentation
    "ENUM('NOT_CHECKED','MATCHED','MISMATCHED','MISSING'), DDL default
     'NOT_CHECKED' — which is therefore the value on every row. It is the
     HONEST value: nothing has been checked. Do not render it as a failure.")
   (gstr2b-verified-date
    :initarg :gstr2b-verified-date
    :accessor gstr2b-verified-date
    :initform nil)

   ;; ── E-INVOICE ───────────────────────────────────────────────────────────
   (e-invoice-required
    :initarg :e-invoice-required
    :accessor e-invoice-required
    :initform nil
    :documentation "BOOLEAN (tinyint). The IRN mandate is turnover-threshold based; not implemented.")
   (irn
    :initarg :irn
    :accessor irn
    :initform nil
    :documentation
    "IRN varchar(64) — the GSTN Invoice Reference Number. ⚠ Always NULL here:
     the e-invoice flow is not built, and IRN is a vendor-side obligation
     (the supplier generates it, not the buyer).")
   (irn-date
    :initarg :irn-date
    :accessor irn-date
    :initform nil)
   (ack-number
    :initarg :ack-number
    :accessor ack-number
    :initform nil)

   ;; ── REVERSE CHARGE (RCM) ────────────────────────────────────────────────
   (reverse-charge
    :initarg :reverse-charge
    :accessor reverse-charge
    :initform nil
    :documentation
    "ih.REVCHARGE ENUM('Yes','No') DEFAULT 'No'. ⚠ MATTERS TO THIS PAGE: under RCM
     the BUYER pays the tax and takes the credit even though the vendor charged none,
     and the line totals do NOT contain that self-assessed tax.")
   (rcm-paid
    :initarg :rcm-paid
    :accessor rcm-paid
    :initform nil)
   (rcm-paid-date
    :initarg :rcm-paid-date
    :accessor rcm-paid-date
    :initform nil)

   ;; ── PAYMENT AND STATUS ──────────────────────────────────────────────────
   (payment-status
    :initarg :payment-status
    :accessor payment-status
    :initform nil
    :documentation
    "ENUM('UNPAID','PARTIALLY_PAID','PAID','OVERPAID') DEFAULT 'UNPAID'.
     ⚠ RELEVANT TO ITC AND NOT WIRED: Rule 37 requires the credit to be REVERSED if
     the buyer does not pay within 180 days — the data is here, no rule reads it.")
   (uploaded-to-gstn
    :initarg :uploaded-to-gstn
    :accessor uploaded-to-gstn
    :initform nil
    :documentation "BOOLEAN (tinyint) — the VENDOR's GSTR-1 upload status. Never written.")
   (gstn-upload-date
    :initarg :gstn-upload-date
    :accessor gstn-upload-date
    :initform nil)

   ;; ── PLACE OF SUPPLY ─────────────────────────────────────────────────────
   (place-of-supply
    :initarg :place-of-supply
    :accessor place-of-supply
    :initform nil
    :documentation
    "ih.PLACEOFSUPPLY varchar(50). [LEGAL] With the vendor's state this decides IGST
     vs CGST+SGST — i.e. WHICH head the derived credit is in. The line totals already
     carry the split; this slot is what lets a reader verify it.")
   (state-code
    :initarg :state-code
    :accessor state-code
    :initform nil
    :documentation "ih.STATECODE varchar(2) — the numeric GST state code, e.g. \"29\".")

   (invoice-status
    :initarg :invoice-status
    :accessor invoice-status
    :initform nil
    :documentation
    "ih.STATUS varchar(20). ⚠ On the live rows it reads 'PAID', which is a PAYMENT
     word in a STATUS column — the register's own payment-status is 'UNPAID' on three
     of the four. Neither is renamed; reporting both is the honest move."))

  (:documentation
   "One INWARD invoice as the BUYER sees it — the domain entity behind
    /hhub/nstcustinvoices and the customer-invoice API. Read-only by construction:
    no make / !update / delete! method exists, because the source is a join VIEW."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — Tree 1: the ITC summary, a DERIVED domain fact
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; WHY A DOMAIN ENTITY AND NOT A PLAIN FUNCTION RETURNING A PLIST: both ferries and
;;; render-html / render-json dispatch on the RESULT's TYPE, so a plist would die at the
;;; boundary with NO-APPLICABLE-METHOD — computing it in Ring 4 is what the grammar forbids.
;;;
;;;   itc-summary (verb) → nst-cinv-itc-summary (Tree 1, this file)
;;;     → domain->response → NstCinvItcSummaryResponseModel (Tree 2) → render-html
;;;
;;; It has no row in any table and no fetch by id: it is a FACT ABOUT a
;;; collection, re-derived on every read, which is why nothing here is cached.

(defclass nst-cinv-itc-summary (nst-domain-entity)
  ((invoices
    :initarg :invoices
    :accessor invoices
    :initform 0
    :documentation "COUNT(*) of the buyer's register rows — the ONLY figure on the card that is not a sum of money.")
   (claimable
    :initarg :claimable
    :accessor claimable
    :initform 0
    :documentation
    "SUM of itc-derived over rows with ITC_ELIGIBLE=1 AND ITC_CLAIMED=0 —
     credit available and not yet taken. 585.10 for buyer 27 / tenant 2.")
   (claimed
    :initarg :claimed
    :accessor claimed
    :initform 0
    :documentation "SUM over rows with ITC_CLAIMED=1. 0.00 until a claim workflow writes the flag.")
   (at-risk
    :initarg :at-risk
    :accessor at-risk
    :initform nil
    :documentation
    "🚨 ALWAYS NIL, AND NIL RATHER THAN 0 — deliberately. 'At risk' means the
     supplier has not filed, so the credit is not in the buyer's GSTR-2B; deciding it
     needs tables that BOTH HOLD 0 ROWS, and 0 would assert 'nothing is at risk'.")
   (purchases
    :initarg :purchases
    :accessor purchases
    :initform 0
    :documentation
    "SUM(TOTAL_AMOUNT) — the tax-inclusive value of the buyer's inward supplies.
     5763.35 for buyer 27. NOTE it sums the HEADER total, so it inherits the
     header-vs-lines disagreement documented on nst-cinv's total-amount slot."))
  (:documentation
   "The buyer's ITC position over the whole register — a DERIVED domain fact,
     assembled by the itc-summary verb and never persisted. tenant-id is inherited and
     IS set from ctx by that verb, keeping check-niyam satisfiable."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Tree 2: the inbound boundary (SLOTLESS)
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass NstCinvRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object for the customer invoice register — deliberately
    SLOTLESS: every field rides in the inherited `params` plist, which the ferry
    MOP-filters against whatever initargs nst-cinv declares."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Tree 2: the outbound boundaries
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; ⚠ THESE SUBCLASS nst-response-model, NOT nst-boundary-object DIRECTLY.
;;; WarehouseResponseModel and NstInvhResponseModel still sit under the latter, which
;;; playbook §4.3 names as a KNOWN GAP; nst-response-model is the new boundary root.
;;;
;;; These are the OUTBOUND ALLOWLIST SOURCE: a field that is not a slot here
;;; cannot be published by any render method, and a slot that is here still is
;;; not published until its render method reads it.

(defclass NstCinvResponseModel (nst-response-model)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   ;; IDENTITY
   (invoice-number
    :initarg :invoice-number
    :accessor invoice-number)
   (invoice-date
    :initarg :invoice-date
    :accessor invoice-date)
   (financial-year
    :initarg :financial-year
    :accessor financial-year)
   (gst-period
    :initarg :gst-period
    :accessor gst-period)
   ;; VENDOR
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id)
   (vendor-name
    :initarg :vendor-name
    :accessor vendor-name)
   (vendor-trade-name
    :initarg :vendor-trade-name
    :accessor vendor-trade-name)
   (vendor-gstin
    :initarg :vendor-gstin
    :accessor vendor-gstin)
   (vendor-gst-type
    :initarg :vendor-gst-type
    :accessor vendor-gst-type)
   (vendor-filing-frequency
    :initarg :vendor-filing-frequency
    :accessor vendor-filing-frequency)
   ;; BUYER
   (buyer-id
    :initarg :buyer-id
    :accessor buyer-id)
   (buyer-name
    :initarg :buyer-name
    :accessor buyer-name)
   (buyer-gstin
    :initarg :buyer-gstin
    :accessor buyer-gstin)
   (buyer-gst-type
    :initarg :buyer-gst-type
    :accessor buyer-gst-type)
   ;; MONEY
   (total-amount
    :initarg :total-amount
    :accessor total-amount)
   (balance-due
    :initarg :balance-due
    :accessor balance-due)
   (advance-adjusted
    :initarg :advance-adjusted
    :accessor advance-adjusted)
   (payment-allocated
    :initarg :payment-allocated
    :accessor payment-allocated)
   ;; ITC — recorded, derived and effective, all three, so that the ledger and
   ;; the arithmetic can never be mistaken for one another again.
   (itc-eligible
    :initarg :itc-eligible
    :accessor itc-eligible)
   (itc-recorded
    :initarg :itc-recorded
    :accessor itc-recorded)
   (itc-derived
    :initarg :itc-derived
    :accessor itc-derived)
   (itc-amount
    :initarg :itc-amount
    :accessor itc-amount)
   (itc-claimed
    :initarg :itc-claimed
    :accessor itc-claimed)
   (itc-claim-month
    :initarg :itc-claim-month
    :accessor itc-claim-month)
   ;; GSTR-2B
   (in-gstr2b
    :initarg :in-gstr2b
    :accessor in-gstr2b)
   (gstr2b-match-status
    :initarg :gstr2b-match-status
    :accessor gstr2b-match-status)
   (gstr2b-verified-date
    :initarg :gstr2b-verified-date
    :accessor gstr2b-verified-date)
   ;; E-INVOICE
   (e-invoice-required
    :initarg :e-invoice-required
    :accessor e-invoice-required)
   (irn
    :initarg :irn
    :accessor irn)
   (irn-date
    :initarg :irn-date
    :accessor irn-date)
   (ack-number
    :initarg :ack-number
    :accessor ack-number)
   ;; RCM
   (reverse-charge
    :initarg :reverse-charge
    :accessor reverse-charge)
   (rcm-paid
    :initarg :rcm-paid
    :accessor rcm-paid)
   (rcm-paid-date
    :initarg :rcm-paid-date
    :accessor rcm-paid-date)
   ;; PAYMENT AND STATUS
   (payment-status
    :initarg :payment-status
    :accessor payment-status)
   (uploaded-to-gstn
    :initarg :uploaded-to-gstn
    :accessor uploaded-to-gstn)
   (gstn-upload-date
    :initarg :gstn-upload-date
    :accessor gstn-upload-date)
   ;; PLACE OF SUPPLY
   (place-of-supply
    :initarg :place-of-supply
    :accessor place-of-supply)
   (state-code
    :initarg :state-code
    :accessor state-code)
   (invoice-status
    :initarg :invoice-status
    :accessor invoice-status))
  (:documentation
   "The outbound boundary shape of one register row — mirror of nst-cinv's
     publishable fields. This class is the ALLOWLIST SOURCE, not the allowlist: a
     field is published only when a render method reads it."))

(defclass NstCinvItcSummaryResponseModel (nst-response-model)
  ((invoices
    :initarg :invoices
    :accessor invoices)
   (claimable
    :initarg :claimable
    :accessor claimable)
   (claimed
    :initarg :claimed
    :accessor claimed)
   (at-risk
    :initarg :at-risk
    :accessor at-risk)
   (purchases
    :initarg :purchases
    :accessor purchases))
  (:documentation
   "Outbound boundary shape of the ITC summary. `at-risk` is NIL when it could
    not be determined and 0 only when it genuinely is zero — the renderers must
    keep that distinction visible (see nst-cinv-itc-summary's at-risk slot)."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 5 — the ORM mapping (CLSQL) for the VIEW
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; MOVED VERBATIM from invoice/nst-dal-cusinvreg.lisp, so accessor names and column
;;; spellings are unchanged; it is the persistence schema the itc-summary verb's
;;; derived table joins to (t.INVHEADID = r.INVOICE_ID), and it stays next to its class.
;;;
;;; :db-kind :key on INVOICE_ID is correct for a VIEW read: it tells CLSQL which
;;; column identifies a row. It does NOT make the view writable, and nothing here
;;; ever calls update-records-from-instance on it.
;;;
;;; ⚠ THIS IS A VIEW: every column is read-only in the object sense too. A slot
;;; added here with :db-kind :base would be a base-table column on a join view
;;; and any write attempt would be refused by MySQL, not by this code.

(clsql:def-view-class dod-v-customer-invoice-register ()
  (;; PRIMARY KEY
   (invoice-id
    :db-kind     :key
    :type        integer
    :initarg     :invoice-id
    :accessor    invoice-id)

   ;; INVOICE IDENTIFICATION
   (invoice-number
    :accessor    invoice-number
    :type        (string 50)
    :initarg     :invoice-number)
   (invoice-date
    :accessor    invoice-date
    :type        clsql:date
    :initarg     :invoice-date)
   (financial-year
    :accessor    financial-year
    :type        (string 9)
    :initarg     :financial-year)
   (gst-period
    :accessor    gst-period
    :type        (string 7)
    :initarg     :gst-period)

   ;; VENDOR DETAILS
   (vendor-id
    :accessor    vendor-id
    :type        integer
    :initarg     :vendor-id)
   (vendor-name
    :accessor    vendor-name
    :type        (string 255)
    :initarg     :vendor-name)
   (vendor-trade-name
    :accessor    vendor-trade-name
    :type        (string 255)
    :initarg     :vendor-trade-name)
   (vendor-gstin
    :accessor    vendor-gstin
    :type        (string 20)
    :initarg     :vendor-gstin)
   (vendor-gst-type
    :accessor    vendor-gst-type
    :type        (string 20)
    :initarg     :vendor-gst-type)
   (vendor-filing-frequency
    :accessor    vendor-filing-frequency
    :type        (string 10)
    :initarg     :vendor-filing-frequency)

   ;; BUYER DETAILS
   (buyer-id
    :accessor    buyer-id
    :type        integer
    :initarg     :buyer-id)
   (buyer-name
    :accessor    buyer-name
    :type        (string 255)
    :initarg     :buyer-name)
   (buyer-gstin
    :accessor    buyer-gstin
    :type        (string 15)
    :initarg     :buyer-gstin)
   (buyer-gst-type
    :accessor    buyer-gst-type
    :type        (string 20)
    :initarg     :buyer-gst-type)

   ;; INVOICE AMOUNTS
   (total-amount
    :accessor    total-amount
    :type        float
    :initarg     :total-amount)
   (balance-due
    :accessor    balance-due
    :type        float
    :initarg     :balance-due)
   (advance-adjusted
    :accessor    advance-adjusted
    :type        float
    :initarg     :advance-adjusted)
   (payment-allocated
    :accessor    payment-allocated
    :type        float
    :initarg     :payment-allocated)

   ;; ITC FIELDS
   (itc-eligible
    :accessor    itc-eligible
    :type        integer
    :initarg     :itc-eligible)
   (itc-amount
    :accessor    itc-amount
    :type        float
    :initarg     :itc-amount)
   (itc-claimed
    :accessor    itc-claimed
    :type        integer
    :initarg     :itc-claimed)
   (itc-claim-month
    :accessor    itc-claim-month
    :type        (string 7)
    :initarg     :itc-claim-month)

   ;; GSTR2B RECONCILIATION
   (in-gstr2b
    :accessor    in-gstr2b
    :type        integer
    :initarg     :in-gstr2b)
   (gstr2b-match-status
    :accessor    gstr2b-match-status
    :type        (string 20)
    :initarg     :gstr2b-match-status)
   (gstr2b-verified-date
    :accessor    gstr2b-verified-date
    :type        clsql:date
    :initarg     :gstr2b-verified-date)

   ;; E-INVOICE FIELDS
   (e-invoice-required
    :accessor    e-invoice-required
    :type        integer
    :initarg     :e-invoice-required)
   (irn
    :accessor    irn
    :type        (string 64)
    :initarg     :irn)
   (irn-date
    :accessor    irn-date
    :type        clsql:wall-time
    :initarg     :irn-date)
   (ack-number
    :accessor    ack-number
    :type        (string 20)
    :initarg     :ack-number)

   ;; RCM FIELDS
   (reverse-charge
    :accessor    reverse-charge
    :type        (string 3)
    :initarg     :reverse-charge)
   (rcm-paid
    :accessor    rcm-paid
    :type        integer
    :initarg     :rcm-paid)
   (rcm-paid-date
    :accessor    rcm-paid-date
    :type        clsql:date
    :initarg     :rcm-paid-date)

   ;; PAYMENT AND STATUS
   (payment-status
    :accessor    payment-status
    :type        (string 20)
    :initarg     :payment-status)
   (uploaded-to-gstn
    :accessor    uploaded-to-gstn
    :type        integer
    :initarg     :uploaded-to-gstn)
   (gstn-upload-date
    :accessor    gstn-upload-date
    :type        clsql:wall-time
    :initarg     :gstn-upload-date)
   (place-of-supply
    :accessor    place-of-supply
    :type        (string 50)
    :initarg     :place-of-supply)
   (state-code
    :accessor    state-code
    :type        (string 2)
    :initarg     :state-code)
   (invoice-status
    :accessor    invoice-status
    :type        (string 20)
    :initarg     :invoice-status)
   (tenant-id
    :accessor    tenant-id
    :type        integer
    :initarg     :tenant-id)
   (created-at
    :accessor    created-at
    :type        clsql:wall-time
    :initarg     :created-at)
   (updated-at
    :accessor    updated-at
    :type        clsql:wall-time
    :initarg     :updated-at))

  (:base-table dod_v_customer_invoice_register))
