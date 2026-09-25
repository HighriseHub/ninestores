;;; nst-dal-invitm.lisp — Domain class: invoice LINE ITEM (DOD_INVOICE_ITEMS)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ───────────────────────────────────────────────────────────────────────────
;;; Same rule as nst-dal-invh.lisp and nst-dal-warehouse.lisp: every slot takes
;;; an initform mirroring the DDL, because CLSQL writes EVERY storable slot and
;;; an explicit NULL bypasses the column DEFAULT.
;;;
;;; DDL source: installation/hhubplatform.sql, CREATE TABLE DOD_INVOICE_ITEMS.
;;; There is NO upgrade migration touching this table — unlike the header, whose
;;; e-invoice / GSTR / ITC / payment columns arrive from
;;; nst-dbu-gstupgrades.lisp. That is why this class is small and that one is
;;; not: the class mirrors each table's LIVE schema, not a wish.
;;;
;;; ⚠ NO CESS COLUMNS EXIST ON THIS TABLE — CGST/SGST/IGST only. A compensation
;;; cess (or the older cess on some HSN codes) has nowhere to go in
;;; DOD_INVOICE_ITEMS, and a GSTR-1 export that claims a cess figure computed
;;; here would be inventing a column. This is a schema gap, not a verb gap.
;;;
;;; The legacy DDD classes for this table — InvoiceItem / InvoiceItemRequestModel
;;; / InvoiceItemResponseModel (nst-dal-itm.lisp) and the copiers
;;; copyInvoiceItem-* (nst-bl-itm.lisp) — are still loaded and still serve the
;;; internal UI. Every name here is therefore new (nst-invitm,
;;; NstInvitmRequestModel, NstInvitmResponseModel, nst-copy-invoice-item-*).
;;;
;;; DECLARED, NOT YET DRIVEN: no प्रत्यय exist for nst-invitm. This file defines
;;; the entity so the header aggregate can be designed against a real type; the
;;; item verbs (make/fetch/enumerate/!update/delete!) are a deliberate next step
;;; and nothing in nst-bl-invh.lisp reads or writes a row of this table.
;;; ───────────────────────────────────────────────────────────────────────────

(defclass nst-invitm (nst-domain-entity)
  (;; ── ROW ────────────────────────────────────────────────────────────────
   (row-id
    :initarg :row-id
    :accessor row-id)
   ;; ── PARENT ─────────────────────────────────────────────────────────────
   (invheadid
    :initarg :invheadid
    :accessor invheadid
    :initform nil
    :documentation
    "INVHEADID mediumint NOT NULL, FK DOD_INVOICE_HEADER(ROW_ID) ON DELETE
     CASCADE — the nst-invh row-id this line belongs to, as an INTEGER.

     Left NIL deliberately rather than 0: a line with no header is not a
     draft, it is invalid, and both the NOT NULL column and
     DOD_INVOICE_ITEMS_ibfk_3 refuse it. (This differs from nst-whs's
     owner-entity-id, whose 0 genuinely means 'no owner'.) The tenant of a
     line is NOT taken from the header — it is the inherited tenant-id, checked
     by नियम-1 like every other entity.")
   ;; ── WHAT IS BEING SOLD ─────────────────────────────────────────────────
   (prd-id
    :initarg :prd-id
    :accessor prd-id
    :initform nil
    :documentation "PRD_ID mediumint NOT NULL, FK DOD_PRD_MASTER(ROW_ID).")
   (prddesc
    :initarg :prddesc
    :accessor prddesc
    :initform nil
    :documentation
    "PRDDESC text NOT NULL. The description AS PRINTED — a snapshot, not a
     join to the product: an issued invoice must keep reading the way it was
     issued after the product is renamed or discontinued.")
   (hsncode
    :initarg :hsncode
    :accessor hsncode
    :initform nil
    :documentation
    "HSNCODE varchar(10) NOT NULL — note the column is HSNCODE here, while
     DOD_GST_HSN_CODES uses HSN_CODE. Both spellings are real; a query that
     copies one into the other silently returns nothing.")
   ;; ── QUANTITY AND PRICE ─────────────────────────────────────────────────
   (qty
    :initarg :qty
    :accessor qty
    :initform 0
    :documentation "QTY smallint NOT NULL — 0 is this class's choice; the DDL gives no default.")
   (uom
    :initarg :uom
    :accessor uom
    :initform nil
    :documentation "UOM varchar(10) NOT NULL. Must be a GST UQC code for GSTR-1, not free text.")
   (price
    :initarg :price
    :accessor price
    :initform 0
    :documentation "PRICE decimal(10,2) NOT NULL — the UNIT price, before discount and before tax.")
   (discount
    :initarg :discount
    :accessor discount
    :initform 0.0
    :documentation "DISCOUNT decimal(10,2) DEFAULT 0.00.")
   ;; ── TAX BREAKDOWN ──────────────────────────────────────────────────────
   (taxable-value
    :initarg :taxable-value
    :accessor taxable-value
    :initform 0
    :documentation
    "TAXABLE_VALUE decimal(15,2) NOT NULL — the line value the tax is charged
     on: (qty × price) − discount. NOT derived by any verb yet.")
   (cgstrate
    :initarg :cgstrate
    :accessor cgstrate
    :initform 0.0
    :documentation
    "CGSTRATE decimal(5,2) NOT NULL — the RATE, stored per line. 0.0 is correct
     and expected on an inter-state line: only one of the CGST+SGST pair and
     IGST is non-zero.")
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt
    :initform 0.0)
   (sgstrate
    :initarg :sgstrate
    :accessor sgstrate
    :initform 0.0)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt
    :initform 0.0)
   (igstrate
    :initarg :igstrate
    :accessor igstrate
    :initform 0.0)
   (igstamt
    :initarg :igstamt
    :accessor igstamt
    :initform 0.0)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval
    :initform 0
    :documentation
    "TOTALITEMVAL decimal(15,2) NOT NULL — taxable value + all tax amounts.
     [LEGAL: the header's TOTALVALUE must equal the sum of this over its
     non-deleted lines before the invoice is issued — nothing enforces that
     today, and the check belongs to issue]")
   ;; ── LINE STATE ─────────────────────────────────────────────────────────
   (status
    :initarg :status
    :accessor status
    :initform "PENDING"
    :documentation
    "STATUS varchar(20) DEFAULT 'PENDING' — PENDING / FINAL, per the DOD
     template. A separate lifecycle from the header's DRAFT/FINAL/PAID."))
  (:documentation
   "Invoice LINE ITEM domain entity — DOD_INVOICE_ITEMS.

    A CHILD entity: it exists only under an nst-invh, through invheadid. It is
    NOT an aggregate root and it is NOT a शिवसूत्र entity of its own — Document
    2 maps the single entity `inv` to BOTH DOD_INVOICE_HEADER and
    DOD_INVOICE_ITEMS, which is why this class carries no गण of its own: the
    verbs that touch a line are the invoice verbs (proc.finance's invoice /
    issue, proc.tax's classify-hsn / generate-irn).

    Inherits id / tenant-id / created-at / updated-at / deleted-state from
    nst-domain-entity. TENANT_ID is set from domain-ctx only.

    An item's tenant and its header's tenant must agree. Nothing checks that
    yet — when the item प्रत्यय are written, the check is 'the header this line
    points at is visible to this ctx', i.e. fetched under the same tenant, and
    it must refuse rather than trust the invheadid the caller supplied."))

;;; ═══════════════════════════════════════════════════════════════════════════
;;; Tree 2 — the boundary objects for nst-invitm
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass NstInvitmRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object for invoice-line operations. Slotless, like every
    request model in this grammar — the fields ride in `params` and
    extract-domain-initargs MOP-filters them against nst-invitm's own initargs.
    Body keys are therefore initarg names (prddesc, hsncode, taxable-value… )."))

(defclass NstInvitmResponseModel (nst-boundary-object)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (invheadid
    :initarg :invheadid
    :accessor invheadid)
   (prd-id
    :initarg :prd-id
    :accessor prd-id)
   (prddesc
    :initarg :prddesc
    :accessor prddesc)
   (hsncode
    :initarg :hsncode
    :accessor hsncode)
   (qty
    :initarg :qty
    :accessor qty)
   (uom
    :initarg :uom
    :accessor uom)
   (price
    :initarg :price
    :accessor price)
   (discount
    :initarg :discount
    :accessor discount)
   (taxable-value
    :initarg :taxable-value
    :accessor taxable-value)
   (cgstrate
    :initarg :cgstrate
    :accessor cgstrate)
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstrate
    :initarg :sgstrate
    :accessor sgstrate)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt)
   (igstrate
    :initarg :igstrate
    :accessor igstrate)
   (igstamt
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval)
   (status
    :initarg :status
    :accessor status))
  (:documentation
   "Outbound boundary object for nst-invitm, mirrored 1:1 with the entity. No
    domain->response or render-json method exists for it yet — those arrive with
    the item प्रत्यय. Declared now so the header aggregate has a named outbound
    type to grow into."))
