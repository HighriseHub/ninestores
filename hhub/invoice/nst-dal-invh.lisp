;;; nst-dal-invh.lisp — Domain class: invoice HEADER (DOD_INVOICE_HEADER)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ───────────────────────────────────────────────────────────────────────────
;;; WHY EVERY NAME HERE IS NEW
;;;
;;; The legacy DDD stack for this same table is still loaded and still serves
;;; the internal website: InvoiceHeader / InvoiceHeaderRequestModel /
;;; InvoiceHeaderResponseModel / InvoiceHeaderDBService (nst-dal-ihd.lisp,
;;; nst-bl-ihd.lisp, nst-ui-ihd.lisp), selected through the deprecated
;;; conflodis adapters. Nothing in this file replaces them, so no name is
;;; reused — a shared name would silently merge the two stacks and the भेरि
;;; (ferry) guarantees of nst-bl-adhara.lisp would be enforced against
;;; whichever definition happened to load last.
;;;
;;;   nst-invh                Tree 1 — the grammar entity (कर्म of the verbs)
;;;   NstInvhRequestModel     Tree 2 — inbound, slotless
;;;   NstInvhResponseModel    Tree 2 — outbound, mirrors the entity
;;;
;;; A later session retires the legacy trio; until then both exist.
;;;
;;; SIMILARLY the copiers in nst-bl-invh.lisp are nst-copy-invoice-header-*
;;; (the nst-copy-customer-* precedent), NOT copyInvoiceHeader-*, which is
;;; already taken by the legacy field map in nst-bl-ihd.lisp.
;;;
;;; ───────────────────────────────────────────────────────────────────────────
;;; INITFORMS MIRROR THE DDL — the same rule as nst-whs (nst-dal-warehouse.lisp),
;;; and for the same measured reason: CLSQL's update-records-from-instance emits
;;; EVERY storable slot, so a slot left unbound aborts the copier, and a slot
;;; holding NIL is written as an explicit NULL — bypassing the column DEFAULT and
;;; failing outright on the NOT NULL columns. Each default below is therefore the
;;; SCHEMA's default, copied deliberately from
;;;
;;;   installation/hhubplatform.sql                       (base table)
;;;   installation/upgrades/nst-dbu-gstupgrades.lisp      (e-invoice, GSTR-1/2B, ITC, payment, RCM)
;;;   installation/upgrades/nst-dbu-custusers.lisp        (LAST_VIEWED_*)
;;;
;;; THREE DELIBERATE CHOICES:
;;;
;;;  * NIL means "the column is nullable". The NOT NULL text columns with no
;;;    default (INVNUM, INVDATE, CUSTNAME, STATECODE, PLACEOFSUPPLY, FINYEAR,
;;;    TOTALINWORDS) are left NIL on purpose: the database refuses the INSERT and
;;;    names the column, which is the honest place for that rule. make fills the
;;;    three a verb can legitimately know (INVNUM, INVDATE, FINYEAR).
;;;  * TOTALVALUE gets 0 rather than NIL — its column is NOT NULL with no
;;;    default, and 0 is the value a DRAFT invoice actually has before any line
;;;    is added (the DB would otherwise refuse an empty draft).
;;;  * the booleans (E_INVOICE_REQUIRED, UPLOADED_TO_GSTN, IN_GSTR2B,
;;;    ITC_ELIGIBLE, ITC_CLAIMED, RCM_PAID) get the INTEGERS 0/1, not "Y"/"N":
;;;    they are MySQL BOOLEAN (tinyint) and dod-invoice-header declares them
;;;    :type integer, so a string would fail CLSQL's slot conversion on the way
;;;    out. This differs from nst-whs's ACTIVE_FLAG, which really is char(1).
;;;
;;; row-id deliberately keeps NO initform: it is bound by bind-generated-row-id
;;; after the INSERT.
;;;
;;; CREATED / UPDATED are NOT mirrored here. They are DB-side columns the
;;; dod-invoice-header view class already carries, and nst-domain-entity's own
;;; created-at / updated-at are the भूत-काल domain markers — two different
;;; concerns, exactly as in nst-whs.
;;; ───────────────────────────────────────────────────────────────────────────

(defclass nst-invh (nst-domain-entity)   ; NOT (business-object nst-domain-entity)
  (;; ── ROW ────────────────────────────────────────────────────────────────
   (row-id
    :initarg :row-id
    :accessor row-id)
   ;; ── IDENTITY OF THE DOCUMENT ───────────────────────────────────────────
   (invnum
    :initarg :invnum
    :accessor invnum
    :initform nil
    :documentation
    "INVNUM varchar(50) NOT NULL. There is NO sequential generator in this
     codebase: the legacy UI mints a placeholder — (format nil \"NST000~A\"
     (hhub-random-password 10)) in nst-ui-ihd.lisp — and lets the vendor edit
     it. make does the same when the caller supplies none, so a DRAFT created
     over the API is addressable immediately. The format a settings-driven
     number SHOULD follow is invoice-general-settings' invoice-number-format
     (\"INV-YYYY-MM-{counter}\", hhub/invoice/templates/invoicesettings.lisp);
     honouring it needs a counter and is not implemented here.")
   (invdate
    :initarg :invdate
    :accessor invdate
    :initform nil
    :documentation
    "INVDATE date NOT NULL — a CLSQL date object (see get-date-from-string),
     never the raw HTTP string. make defaults it to today.")
   (finyear
    :initarg :finyear
    :accessor finyear
    :initform nil
    :documentation
    "FINYEAR varchar(9) NOT NULL, e.g. \"2026-2027\". make derives it from
     invdate (April–March, the GST default) when the caller supplies none —
     see nst-financial-year-label. A tenant whose year starts elsewhere is
     described by nst-vnd's fy-start-month, which no verb reads yet.")
   (context-id
    :initarg :context-id
    :accessor context-id
    :initform nil
    :documentation
    "CONTEXT_ID varchar(100) — the internal UI's invoice-edit session key
     (sessioninvkey). Optional for an API caller.

     ⚠ IT IS NOT THE ORDER REFERENCE, although ord→inv copies the order's own
     context-id here: that value is a uuid:make-v1-uuid minted by the legacy CART
     (order/dod-bl-ord.lisp), so it identifies the browsing session that placed
     the order and NOTHING readable prints from it. The order reference this
     invoice must show and search by is order-number below.")
   ;; ── THE ORDER THIS INVOICE BILLS (ord→inv junction, design D1) ─────────
   (order-number
    :initarg :order-number
    :accessor order-number
    :initform nil
    :documentation
    "ORDER_NUMBER varchar(50) NULL — the ORDNUM of the order this invoice was
     raised from (e.g. ORD-GCUST837-2026-27-VNNCZ9). NULL for an invoice created
     by the STANDALONE POS-style path, which has no order: that path is
     deliberately never broken (design D4), so this column is nullable and every
     reader must therefore treat NIL as 'not order-linked' rather than as a
     defect.

     DENORMALISED ON PURPOSE — the number is the CROSS-PARTY key (order D4): the
     vendor quotes it and the customer quotes it back on the phone or by email,
     and the printed tax invoice and a search both need it WITHOUT joining
     DOD_ORDER. It is safe to denormalise because ORDNUM is unique
     (uk_ordnum) and immutable over HTTP (stripped from every update payload).
     ⚠ It could NOT go in VNUM: that column is varchar(20) and the measured
     maximum ORDNUM is 27 characters — storing it there truncated it.")
   (order-id
    :initarg :order-id
    :accessor order-id
    :initform nil
    :documentation
    "ORDER_ID mediumint NULL — DOD_ORDER.ROW_ID: the real link behind
     order-number, for the queries that need the row rather than the label.
     Nullable for the same reason, and RAW rather than a keyed reference token:
     this column is PROVENANCE, never an address a caller resolves a document
     from, so enumerability is not the exposure it is on an order number.")
   ;; ── PARTIES ────────────────────────────────────────────────────────────
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id
    :initform nil
    :documentation "VENDOR_ID mediumint, FK DOD_VEND_PROFILE. Nullable, so NIL is written.")
   (custid
    :initarg :custid
    :accessor custid
    :initform nil
    :documentation "CUSTID mediumint, FK DOD_CUST_PROFILE. Nullable.")
   (custname
    :initarg :custname
    :accessor custname
    :initform nil
    :documentation
    "CUSTNAME varchar(255) NOT NULL. Copied from the entity, NOT re-selected:
     the legacy copyInvoiceHeader-dbtodomain runs select-company-by-id +
     select-vendor-by-id + select-customer-by-id on every hydrate, which is
     why it cannot be reused for this class. The caller (or a later verb)
     supplies the snapshot; an invoice is a legal document and must keep
     reading the way it was issued even after the customer record changes.")
   (custaddr
    :initarg :custaddr
    :accessor custaddr
    :initform nil)
   (custgstin
    :initarg :custgstin
    :accessor custgstin
    :initform nil
    :documentation "CUSTGSTIN varchar(15) — the buyer's GSTIN as printed on the document.")
   (user-id
    :initarg :user-id
    :accessor user-id
    :initform nil
    :documentation "USER_ID mediumint, FK DOD_USERS — who created the invoice.")
   ;; ── ADDRESSES AND PLACE OF SUPPLY ──────────────────────────────────────
   (billaddr
    :initarg :billaddr
    :accessor billaddr
    :initform nil)
   (shipaddr
    :initarg :shipaddr
    :accessor shipaddr
    :initform nil)
   (placeofsupply
    :initarg :placeofsupply
    :accessor placeofsupply
    :initform nil
    :documentation "PLACEOFSUPPLY varchar(50) NOT NULL. [LEGAL: decides IGST vs CGST+SGST]")
   (statecode
    :initarg :statecode
    :accessor statecode
    :initform nil
    :documentation "STATECODE varchar(2) NOT NULL — GST state code, e.g. \"29\".")
   ;; ── TRANSPORT ──────────────────────────────────────────────────────────
   (revcharge
    :initarg :revcharge
    :accessor revcharge
    :initform "No"
    :documentation "REVCHARGE enum('Yes','No') DEFAULT 'No' — DDL default, spelled as the enum spells it.")
   (transmode
    :initarg :transmode
    :accessor transmode
    :initform nil)
   (vnum
    :initarg :vnum
    :accessor vnum
    :initform nil
    :documentation "VNUM varchar(20) — vehicle number.")
   ;; ── MONEY AND PRESENTATION ─────────────────────────────────────────────
   (totalvalue
    :initarg :totalvalue
    :accessor totalvalue
    :initform 0.0
    :documentation "TOTALVALUE decimal(15,2) NOT NULL with no DDL default — 0 is this class's choice, and the true value of a DRAFT with no lines yet.")
   (totalinwords
    :initarg :totalinwords
    :accessor totalinwords
    :initform nil
    :documentation "TOTALINWORDS varchar(255) NOT NULL — left NIL so the DB refuses and names the column.")
   (bankaccnum
    :initarg :bankaccnum
    :accessor bankaccnum
    :initform nil)
   (bankifsccode
    :initarg :bankifsccode
    :accessor bankifsccode
    :initform nil)
   (tnc
    :initarg :tnc
    :accessor tnc
    :initform nil)
   (authsign
    :initarg :authsign
    :accessor authsign
    :initform nil
    :documentation "AUTHSIGN varchar(100) — authorized signatory printed on the document.")
   ;; ── DOCUMENT STATE ─────────────────────────────────────────────────────
   (status
    :initarg :status
    :accessor status
    :initform "DRAFT"
    :documentation
    "STATUS varchar(20) DEFAULT 'DRAFT'. The lifecycle the verbs care about:
     DRAFT → FINAL (issued) → PAID, plus CANCELLED. [LEGAL: an issued invoice
     is never deleted — delete! refuses anything past DRAFT, and
     security-settings' allow-invoice-deletion is nil by default]")
   (external-url
    :initarg :external-url
    :accessor external-url
    :initform nil
    :documentation "EXTERNAL_URL varchar(2048) — the public/live invoice link, set by generate-invoice-ext-url.")
   ;; ── E-INVOICING (IRN) — migration 2026Feb ──────────────────────────────
   (e-invoice-required
    :initarg :e-invoice-required
    :accessor e-invoice-required
    :initform 0
    :documentation "E_INVOICE_REQUIRED BOOLEAN DEFAULT FALSE — turnover-threshold driven.")
   (irn
    :initarg :irn
    :accessor irn
    :initform nil
    :documentation "IRN varchar(64) UNIQUE — Invoice Reference Number from NIC.")
   (irn-date
    :initarg :irn-date
    :accessor irn-date
    :initform nil)
   (ack-number
    :initarg :ack-number
    :accessor ack-number
    :initform nil)
   (ack-date
    :initarg :ack-date
    :accessor ack-date
    :initform nil)
   (qr-code-path
    :initarg :qr-code-path
    :accessor qr-code-path
    :initform nil)
   ;; ── GSTR-1 / GSTR-2B COMPLIANCE ────────────────────────────────────────
   (uploaded-to-gstn
    :initarg :uploaded-to-gstn
    :accessor uploaded-to-gstn
    :initform 0
    :documentation "UPLOADED_TO_GSTN BOOLEAN DEFAULT FALSE — vendor filing status.")
   (gstn-upload-date
    :initarg :gstn-upload-date
    :accessor gstn-upload-date
    :initform nil)
   (gstr1-period
    :initarg :gstr1-period
    :accessor gstr1-period
    :initform nil
    :documentation "GSTR1_PERIOD varchar(7) — \"YYYY-MM\".")
   (in-gstr2b
    :initarg :in-gstr2b
    :accessor in-gstr2b
    :initform 0
    :documentation "IN_GSTR2B BOOLEAN DEFAULT FALSE — reflected in the buyer's 2B.")
   (gstr2b-match-status
    :initarg :gstr2b-match-status
    :accessor gstr2b-match-status
    :initform "NOT_CHECKED"
    :documentation
    "GSTR2B_MATCH_STATUS enum('NOT_CHECKED','MATCHED','MISMATCHED','MISSING')
     DEFAULT 'NOT_CHECKED'. The enum strings, not keywords — CLSQL writes the
     slot value straight through.")
   (gstr2b-verified-date
    :initarg :gstr2b-verified-date
    :accessor gstr2b-verified-date
    :initform nil)
   ;; ── ITC LIFECYCLE ──────────────────────────────────────────────────────
   (itc-eligible
    :initarg :itc-eligible
    :accessor itc-eligible
    :initform 1
    :documentation "ITC_ELIGIBLE BOOLEAN DEFAULT TRUE.")
   (itc-claimed
    :initarg :itc-claimed
    :accessor itc-claimed
    :initform 0
    :documentation "ITC_CLAIMED BOOLEAN DEFAULT FALSE.")
   (itc-claim-month
    :initarg :itc-claim-month
    :accessor itc-claim-month
    :initform nil
    :documentation "ITC_CLAIM_MONTH varchar(7) — \"YYYY-MM\".")
   (itc-amount
    :initarg :itc-amount
    :accessor itc-amount
    :initform nil
    :documentation
    "ITC_AMOUNT decimal(15,2), no default, NULL on every existing row — a
     documented trap of this schema. The ITC ledger reads this column; a verb
     that claims ITC must write it, nothing does yet.")
   ;; ── PAYMENT RECONCILIATION ─────────────────────────────────────────────
   (advance-adjusted
    :initarg :advance-adjusted
    :accessor advance-adjusted
    :initform 0.0
    :documentation "ADVANCE_ADJUSTED decimal(15,2) DEFAULT 0.00.")
   (payment-allocated
    :initarg :payment-allocated
    :accessor payment-allocated
    :initform 0.0)
   (total-allocated
    :initarg :total-allocated
    :accessor total-allocated
    :initform 0.0)
   (total-tds-deducted
    :initarg :total-tds-deducted
    :accessor total-tds-deducted
    :initform 0.0
    :documentation "TOTAL_TDS_DEDUCTED decimal(15,2) DEFAULT 0.00 — Section 194Q / 194C.")
   (balance-due
    :initarg :balance-due
    :accessor balance-due
    :initform nil
    :documentation "BALANCE_DUE decimal(15,2) — nullable, no default. TOTALVALUE − (allocated + TDS).")
   (advance-gst-reversed
    :initarg :advance-gst-reversed
    :accessor advance-gst-reversed
    :initform 0.0)
   (payment-status
    :initarg :payment-status
    :accessor payment-status
    :initform "UNPAID"
    :documentation "PAYMENT_STATUS enum('UNPAID','PARTIALLY_PAID','PAID','OVERPAID') DEFAULT 'UNPAID'.")
   ;; ── REVERSE CHARGE LIFECYCLE ───────────────────────────────────────────
   (rcm-paid
    :initarg :rcm-paid
    :accessor rcm-paid
    :initform 0
    :documentation
    "RCM_PAID BOOLEAN DEFAULT FALSE — the reverse-charge TAX already
     discharged. Distinct from REVCHARGE, which is only the flag. [LEGAL: an
     uncertain RCM position is an abort case, never a guess — see the
     domain-ctx provenance note in nst-bl-adhara.lisp]")
   (rcm-paid-date
    :initarg :rcm-paid-date
    :accessor rcm-paid-date
    :initform nil)
   ;; ── VIEW TRACKING — nst-dbu-custusers.lisp ─────────────────────────────
   (last-viewed-by-user-id
    :initarg :last-viewed-by-user-id
    :accessor last-viewed-by-user-id
    :initform nil
    :documentation "LAST_VIEWED_BY_USER_ID mediumint, FK DOD_CUSTOMER_USERS ON DELETE SET NULL.")
   (last-viewed-at
    :initarg :last-viewed-at
    :accessor last-viewed-at
    :initform nil)
   ;; ── THE EDIT LOCK (story E1/US-013) ────────────────────────────────────
   (invoice-locked
    :initarg :invoice-locked
    :accessor invoice-locked
    :initform "N"
    :documentation
    "INVOICE_LOCKED char(1) NOT NULL DEFAULT 'N'. 'Y' = the vendor has NOT authorised changes to this
     invoice; 'N' = they have (or nobody ever locked it).

     ⚠ THE COLUMN IS `INVOICE_LOCKED` AND NOT `LOCKED`, DELIBERATELY: LOCKED is a RESERVED WORD in
     MySQL 8, so a plain unquoted reference to it is a syntax error and every DML statement against
     this table would have to carry backticks. The migration helpers build statements with FORMAT,
     where a backtick is a live hazard; a column name that needs none is worth the three extra
     characters.

     🚨 WHETHER AN ORDER-ORIGINATED INVOICE ARRIVES LOCKED IS THE VENDOR'S SETTING, NOT OURS
     (requester's ruling, 2026-10-12): in India, people add more items in the nick of time after
     the order is placed as well, so the invoice is kept OPEN ENDED and left to the vendor's
     discretion. The junction therefore writes 'Y' ONLY when that vendor has asked for it —
     `invh-lock-order-derived-invoices-p` reads `lock-order-derived-invoices-invoice` under
     `security-settings` in the vendor's own invoice-settings blob, and an ABSENT key means 'N', so
     every existing vendor keeps an open-ended invoice. A single invoice can be locked or unlocked by
     hand whatever the setting says.

     ⚠ THE COLUMN'S DEFAULT IS 'N' AND MUST STAY 'N'. A DEFAULT of 'Y' would lock every STANDALONE
     POS-style invoice at creation — the path design D4 says is never broken — so the lock is only
     ever set explicitly, by the one caller that both knows an order is behind the document AND has
     read the vendor's choice.

     ⚠⚠ NOT YET ENFORCED BY A WRITE GUARD. This is the STATE and its AUDIT TRAIL; `!update` does not
     consult it yet, so the API cannot be relied on to refuse an edit to a locked invoice until that
     slice lands. Recorded here so the gap is not mistaken for a working control — see
     PENDING-WORK-CONTEXT.md §17.")
   (unlocked-by-user-id
    :initarg :unlocked-by-user-id
    :accessor unlocked-by-user-id
    :initform nil
    :documentation
    "UNLOCKED_BY_USER_ID mediumint — the USER who last unlocked or re-locked this invoice, FK
     DOD_USERS ON DELETE SET NULL (the LAST_VIEWED_BY_USER_ID precedent, so removing a user never
     removes the record of the unlock).

     ⚠ USUALLY NULL TODAY, AND THAT IS THE SAME LIMIT `DOD_ORDER.CREATED_BY_USER_ID` HAS: a VENDOR
     session does not set `:login-user`, so there is no user to name (nst-bl-ordh.lisp's
     nst-actor-user-row-id records the same fact on the order side). The vendor id below is the
     identity that IS always available, and it is the one that matters for 'who unlocked this'.")
   (unlocked-by-vendor-id
    :initarg :unlocked-by-vendor-id
    :accessor unlocked-by-vendor-id
    :initform nil
    :documentation
    "UNLOCKED_BY_VENDOR_ID mediumint — the VENDOR row that unlocked or re-locked this invoice, FK
     DOD_VEND_PROFILE. Always set from the SESSION (never from a payload), which is why it can carry
     the audit where unlocked-by-user-id cannot.")
   (unlocked-at
    :initarg :unlocked-at
    :accessor unlocked-at
    :initform nil
    :documentation
    "UNLOCKED_AT timestamp — WHEN the last Unlock or Lock happened. NULL means nobody has ever touched
     the lock, which is the state every order-originated invoice starts in.

     It is overwritten by the NEXT action of either kind, so on its own it does not say whether the
     invoice is currently locked — read invoice-locked for that. The two together are the audit: the
     state, and when it last changed and by whom."))
  (:documentation
   "Invoice HEADER domain entity — DOD_INVOICE_HEADER.

    The TRIPLE-JUNCTION entity of the grammar. One कर्म (this class) is acted on
    by verbs owned by three different गण, which is why gana-package-for routes
    per VERB and never per entity (nst-bl-adhara.lisp §test-gana-package-for-
    resolves-junction-entity-verbs-correctly):
      proc.finance    → invoice, issue, pay, settle, refund
      proc.tax        → generate-irn, generate-eway, claim-itc, file, amend
      proc.governance → approve, reject, audit

    Inherits id / tenant-id / created-at / updated-at / deleted-state from
    nst-domain-entity — do not redeclare them. In particular TENANT_ID is set
    ONLY from domain-ctx by the verb: it is in *reserved-initargs*, so a
    client-supplied :tenant-id is stripped at the ferry before it can reach
    here (नियम-1).

    There is deliberately NO company slot. nst-whs carries one because its
    copier derives the DB row's tenant from it, which forces the API to inject
    a session company into every payload (:inject-company). This class reads
    its tenant from the inherited tenant-id, so an invoice endpoint needs no
    such injection — the tenant is on ctx and nowhere else.

    The lines are DOD_INVOICE_ITEMS, a separate entity (nst-invitm,
    nst-dal-invitm.lisp). Nothing couples them yet: no line-items slot and no
    totals roll-up exist, because the item प्रत्यय are not written. Until they
    are, TOTALVALUE on a created header is whatever the caller supplied and is
    NOT derived from the lines. [LEGAL: a FINAL invoice must not be issued with
    a total that disagrees with its lines — that check belongs to issue, and
    must exist before issue is wired]"))

;;; ═══════════════════════════════════════════════════════════════════════════
;;; Tree 2 — the boundary objects for nst-invh
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass NstInvhRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object for invoice-header operations. Deliberately
    SLOTLESS, exactly like WarehouseRequestModel: every field rides in the
    inherited `params` plist and the ferry (request->dispatch /
    extract-domain-initargs, nst-bl-adhara.lisp) MOP-filters that plist against
    whatever initargs nst-invh declares. One universal translator, zero
    per-entity mapping code.

    So the JSON body keys are nst-invh INITARG names (custgstin, placeofsupply,
    gstin… ), not column names and not the legacy InvoiceHeaderRequestModel's
    typed slots. :tenant-id, :id, :created-at, :updated-at and :deleted-state
    are stripped by extract-domain-initargs and can never be supplied by a
    client."))

(defclass NstInvhResponseModel (nst-boundary-object)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   ;; IDENTITY OF THE DOCUMENT
   (invnum
    :initarg :invnum
    :accessor invnum)
   (invdate
    :initarg :invdate
    :accessor invdate)
   (finyear
    :initarg :finyear
    :accessor finyear)
   (context-id
    :initarg :context-id
    :accessor context-id)
   ;; THE ORDER THIS INVOICE BILLS — declared here because *invh-mirrored-slots*
   ;; drives domain->response over every mirrored slot, so a slot missing from this
   ;; model signals MISSING-SLOT and every authenticated invoice route answers 500.
   ;; The whole reason this class is written out at all.
   (order-number
    :initarg :order-number
    :accessor order-number)
   (order-id
    :initarg :order-id
    :accessor order-id)
   ;; THE EDIT LOCK and its audit trail. Declared here for the same reason order-number is: this class
   ;; is written out because *invh-mirrored-slots* drives domain->response over every mirrored slot, so
   ;; a slot missing from this model signals MISSING-SLOT and every invoice route answers 500.
   (invoice-locked
    :initarg :invoice-locked
    :accessor invoice-locked)
   (unlocked-by-user-id
    :initarg :unlocked-by-user-id
    :accessor unlocked-by-user-id)
   (unlocked-by-vendor-id
    :initarg :unlocked-by-vendor-id
    :accessor unlocked-by-vendor-id)
   (unlocked-at
    :initarg :unlocked-at
    :accessor unlocked-at)
   ;; PARTIES
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id)
   (custid
    :initarg :custid
    :accessor custid)
   (custname
    :initarg :custname
    :accessor custname)
   (custaddr
    :initarg :custaddr
    :accessor custaddr)
   (custgstin
    :initarg :custgstin
    :accessor custgstin)
   (user-id
    :initarg :user-id
    :accessor user-id)
   ;; ADDRESSES AND PLACE OF SUPPLY
   (billaddr
    :initarg :billaddr
    :accessor billaddr)
   (shipaddr
    :initarg :shipaddr
    :accessor shipaddr)
   (placeofsupply
    :initarg :placeofsupply
    :accessor placeofsupply)
   (statecode
    :initarg :statecode
    :accessor statecode)
   ;; TRANSPORT
   (revcharge
    :initarg :revcharge
    :accessor revcharge)
   (transmode
    :initarg :transmode
    :accessor transmode)
   (vnum
    :initarg :vnum
    :accessor vnum)
   ;; MONEY AND PRESENTATION
   (totalvalue
    :initarg :totalvalue
    :accessor totalvalue)
   (totalinwords
    :initarg :totalinwords
    :accessor totalinwords)
   (bankaccnum
    :initarg :bankaccnum
    :accessor bankaccnum)
   (bankifsccode
    :initarg :bankifsccode
    :accessor bankifsccode)
   (tnc
    :initarg :tnc
    :accessor tnc)
   (authsign
    :initarg :authsign
    :accessor authsign)
   ;; DOCUMENT STATE
   (status
    :initarg :status
    :accessor status)
   ;; deleted-state is CARRIED but NOT PUBLISHED: *invh-mirrored-slots* drives
   ;; domain->response over every mirrored slot, so the slot must exist here or the
   ;; setf signals MISSING-SLOT and every header route answers 500. render-json is
   ;; the outbound allowlist and deliberately does not name it, exactly as
   ;; WarehouseResponseModel does (see nst-dal-warehouse.lisp).
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (external-url
    :initarg :external-url
    :accessor external-url)
   ;; E-INVOICING
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
   (ack-date
    :initarg :ack-date
    :accessor ack-date)
   (qr-code-path
    :initarg :qr-code-path
    :accessor qr-code-path)
   ;; GSTR-1 / GSTR-2B
   (uploaded-to-gstn
    :initarg :uploaded-to-gstn
    :accessor uploaded-to-gstn)
   (gstn-upload-date
    :initarg :gstn-upload-date
    :accessor gstn-upload-date)
   (gstr1-period
    :initarg :gstr1-period
    :accessor gstr1-period)
   (in-gstr2b
    :initarg :in-gstr2b
    :accessor in-gstr2b)
   (gstr2b-match-status
    :initarg :gstr2b-match-status
    :accessor gstr2b-match-status)
   (gstr2b-verified-date
    :initarg :gstr2b-verified-date
    :accessor gstr2b-verified-date)
   ;; ITC
   (itc-eligible
    :initarg :itc-eligible
    :accessor itc-eligible)
   (itc-claimed
    :initarg :itc-claimed
    :accessor itc-claimed)
   (itc-claim-month
    :initarg :itc-claim-month
    :accessor itc-claim-month)
   (itc-amount
    :initarg :itc-amount
    :accessor itc-amount)
   ;; PAYMENT RECONCILIATION
   (advance-adjusted
    :initarg :advance-adjusted
    :accessor advance-adjusted)
   (payment-allocated
    :initarg :payment-allocated
    :accessor payment-allocated)
   (total-allocated
    :initarg :total-allocated
    :accessor total-allocated)
   (total-tds-deducted
    :initarg :total-tds-deducted
    :accessor total-tds-deducted)
   (balance-due
    :initarg :balance-due
    :accessor balance-due)
   (advance-gst-reversed
    :initarg :advance-gst-reversed
    :accessor advance-gst-reversed)
   (payment-status
    :initarg :payment-status
    :accessor payment-status)
   ;; RCM
   (rcm-paid
    :initarg :rcm-paid
    :accessor rcm-paid)
   (rcm-paid-date
    :initarg :rcm-paid-date
    :accessor rcm-paid-date)
   ;; VIEW TRACKING
   (last-viewed-by-user-id
    :initarg :last-viewed-by-user-id
    :accessor last-viewed-by-user-id)
   (last-viewed-at
    :initarg :last-viewed-at
    :accessor last-viewed-at))
  (:documentation
   "Outbound boundary object for nst-invh. Filled field by field by
    domain->response (nst-bl-invh.lisp) — the reverse ferry. NOT an
    nst-domain-entity and never accepted as a verb's primary argument
    (nst-bl-adhara.lisp §2).

    The entity's slots are mirrored 1:1 so the two cannot drift silently; the
    narrower, security-relevant decision is which of them render-json(s) — that
    allowlist lives in the method, not here."))
