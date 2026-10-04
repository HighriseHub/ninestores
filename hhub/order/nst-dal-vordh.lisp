;;; nst-dal-vordh.lisp — the VENDOR ORDER island entity and its boundary models (S9)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Design: aiharness/deepseek/skills/vendor-orders-adhara-CONTEXT.md (S9, decisions V1-V7).
;;; The CUSTOMER channel is order/nst-dal-ordh.lisp and the stories file — deliberately NOT
;;; mixed with this one: different table, different traps, different scope rule.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THIS FILE IS
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; DOD_VENDOR_ORDERS is a DENORMALISED COPY OF THE ORDER HEADER, ONE ROW PER
;;; (ORDER, VENDOR) — a cart may span vendors, so one order has N of these rows and the
;;; customer's document number (ORDNUM, D20) is COPIED into every one of them. This file
;;; is the island for that row: a NEW view class, the Tree-1 entity, the slotless inbound
;;; boundary, the outbound response model, and the mirrored-slot list. Nothing else —
;;; no प्रत्यय (nst-bl-vordh.lisp), no copiers, no render. This file is inert.
;;;
;;; MEASURED AGAINST THE LIVE DATABASE, NOT ASSUMED (2026-10-04):
;;;
;;;  * The table has 60 columns. THIS FILE ADDS ITS OWN VIEW CLASS AND DECLARES ALL 60
;;;    (S9 AC a, decision V1). The legacy class `dod-vendor-orders` (order/dod-dal-ord.lisp:15)
;;;    declares 26 of them and is LEFT EXACTLY AS IT IS: extending it in place would change a
;;;    live SELECT's column list as a side effect of an order change (T5), which is how this
;;;    batch has broken production before.
;;;  * The legacy class carries three `:db-kind :join` slots (customer, order, vendorobject).
;;;    NONE IS DECLARED HERE (V2): a join is a traversal, not domain state — the same exclusion
;;;    nst-ordh documents. A verb that needs the vendor's or the customer's own row calls the
;;;    tenant-scoped BL lookup, as the customer channel's assembly already does.
;;;
;;; 🚨 ORD_DATE IS THE REASON THIS TABLE IS NOT "THE HEADER WITH A VENDOR COLUMN".
;;;
;;;   DOD_ORDER.ORD_DATE         is `date`       — no auto-update.
;;;   DOD_VENDOR_ORDERS.ORD_DATE is `timestamp`  — NOT NULL DEFAULT CURRENT_TIMESTAMP
;;;                                                ON UPDATE CURRENT_TIMESTAMP.
;;;
;;; So ANY update that OMITS ORD_DATE rewrites it to now(), silently (trap T9). Worse for this
;;; migration: reading a `timestamp` as `clsql:date` — which is exactly what dod-order correctly
;;; does for ITS `date` column, and what the legacy vendor class does here — DROPS THE TIME OF
;;; DAY, so writing the value back moves the row to midnight even when the auto-update has been
;;; defeated. AC (f) ("after PUT, ORD_DATE is byte-identical") would then fail while looking
;;; fixed. THEREFORE, per decision V5, the three vendor timestamps are declared `(string 30)`:
;;; the value round-trips byte-identically, and `!update` re-assigns it in the same statement.
;;; `(string 30)` over a timestamp column is this repo's own production choice (dod-order's
;;; CREATED/UPDATED). ⚠ PROVE IT, DO NOT TRUST IT: measure the reader in S16 by asserting AC (f)
;;; against the live row — preflight §5(b): a declared type is not what the reader RETURNS.
;;;
;;; SLOT NAMES ALIGN WITH THE HEADER ENTITY WHERE THE SAME COLUMN EXISTS (V-note). SHIP_ADDRESS
;;; is `ship-address-short`, SHIPADDR is `ship-addr-full`, SHIPZIPCODE is `ship-zipcode` — the
;;; vendor table carries the same pair the header does, and a client that can render one channel
;;; should not have to learn a second vocabulary for the same field. The two names that are NOT,
;;; and must not be "corrected": the header's `cust-name` (not `custname`) and the header's
;;; `order-fulfilled` (the vendor column is FULFILLED).
;;;
;;; ⚠ MONEY AND RATE SLOTS GET AN EXPLICIT `0.0` INITFORM, and that is a fixed defect, not
;;; style: CLSQL declares these decimal columns `(OR NULL FLOAT)` and VALIDATES on insert, so an
;;; ordinary JSON `0` — an INTEGER — fails the INSERT and surfaces to the client as `:U` / 503
;;; "the database call did not answer". The invoice batch lost a day to that twice: once for the
;;; omitted field (fixed by the initform) and once for the supplied one (fixed in the copier,
;;; which must coerce integer→float). The tinyint(1) flags take `0` because they are integers,
;;; and the char(1) flags take the value the column's own DEFAULT would ("N", and "Y" for
;;; BILLSAMEASSHIP).
;;;
;;; ⚠ WHY THE MIRRORED-SLOT LIST LIVES IN THIS FILE rather than in the BL: it must match these
;;; two classes EXACTLY, and that ONE list drives THREE consumers — both copy ferries AND
;;; domain->response, which setfs every listed slot onto the RESPONSE MODEL. A slot listed with
;;; no slot there signals MISSING-SLOT on every response: that is precisely how the whole invoice
;;; API answered 500 for weeks while every offline check passed. tools/nst-order-mirror-check.lisp
;;; asserts entity/response/list agreement offline, with no database and no image.
;;;
;;; No SQL of its own, so no `clsql:file-enable-sql-reader-syntax` here — matching
;;; order/dod-dal-ord.lisp, which declares its view classes with the line commented out.

;;; ───────────────────────────────────────────────────────────────────────────
;;; Tree 1, part 1 — the ORM view class over ALL 60 live columns (V1, V2)
;;; ───────────────────────────────────────────────────────────────────────────

(clsql:def-view-class dod-vendor-order ()
  (
   ;; ── identity ────────────────────────────────────────────────────────────
   (row-id
    :db-kind :key
    :db-constraints :not-null
    :column "ROW_ID"
    :type integer
    :initarg :row-id)
   (order-id
    :db-constraints :not-null
    :column "ORDER_ID"
    :type integer
    :initarg :order-id)
   (cust-id
    :db-constraints :not-null
    :column "CUST_ID"
    :type integer
    :initarg :cust-id)
   ;; the second scope axis: `uk_vo_order_vendor (ORDER_ID, VENDOR_ID)` is UNIQUE, so a
   ;; vendor can appear at most once on an order. NOT NULL, and never client-supplied.
   (vendor-id
    :db-constraints :not-null
    :column "VENDOR_ID"
    :type integer
    :initarg :vendor-id)
   ;; the customer's document number, COPIED from the header (D20). NULLABLE, and that is
   ;; load-bearing: 462 of the 462 pre-migration rows are NULL, which is why a fetch that
   ;; cannot resolve an ORDNUM must answer 404 rather than fall back to a row-id (AC e).
   (ordnum
    :column "ORDNUM"
    :type (string 50)
    :initarg :ordnum)

   ;; ── the three timestamps: declared (string 30), see the header (V5 / T9) ──
   (ord-date
    :db-constraints :not-null
    :column "ORD_DATE"
    :type (string 30)
    :initarg :ord-date)
   (req-date
    :db-constraints :not-null
    :column "REQ_DATE"
    :type (string 30)
    :initarg :req-date)
   (shipped-date
    :column "SHIPPED_DATE"
    :type (string 30)
    :initarg :shipped-date)
   (expected-delivery-date
    :column "EXPECTED_DELIVERY_DATE"
    :type clsql:date
    :initarg :expected-delivery-date)

   ;; ── lifecycle, document state ──────────────────────────────────────────
   (status
    :column "STATUS"
    :type (string 3)
    :initarg :status)
   (order-type
    :column "ORDER_TYPE"
    :type (string 4)
    :initarg :order-type)
   (order-source
    :column "ORDER_SOURCE"
    :type (string 10) ; enum('POS','ONLINE','WHATSAPP','API')
    :initarg :order-source)
   (order-fulfilled                        ; column is FULFILLED, the header slot name is kept
    :column "FULFILLED"
    :type (string 1)
    :initarg :order-fulfilled)
   (context-id
    :column "CONTEXT_ID"
    :type (string 100)
    :initarg :context-id)
   (is-converted-to-invoice
    :column "IS_CONVERTED_TO_INVOICE"
    :type (string 1)
    :initarg :is-converted-to-invoice)
   (is-cancelled
    :column "IS_CANCELLED"
    :type (string 1)
    :initarg :is-cancelled)
   (cancel-reason
    :column "CANCEL_REASON"
    :type string ; text
    :initarg :cancel-reason)
   (invoice-number
    :column "INVOICE_NUMBER"
    :type (string 50)
    :initarg :invoice-number)
   (invoice-date
    :column "INVOICE_DATE"
    :type clsql:date
    :initarg :invoice-date)
   (comments
    :column "COMMENTS"
    :type (string 255)
    :initarg :comments)
   (external-url
    :column "EXTERNAL_URL"
    :type (string 2048)
    :initarg :external-url)
   (payment-mode
    :column "PAYMENT_MODE"
    :type (string 3)
    :initarg :payment-mode)

   ;; ── the parties, denormalised ──────────────────────────────────────────
   (cust-name
    :column "CUSTNAME"
    :type (string 255)
    :initarg :cust-name)
   (created-by-user-id
    :column "CREATED_BY_USER_ID"
    :type integer
    :initarg :created-by-user-id)
   (approved-by-user-id
    :column "APPROVED_BY_USER_ID"
    :type integer
    :initarg :approved-by-user-id)

   ;; ── shipping ───────────────────────────────────────────────────────────
   (ship-address-short
    :column "SHIP_ADDRESS"
    :type (string 200)
    :initarg :ship-address-short)
   (ship-addr-full
    :column "SHIPADDR"
    :type string ; text
    :initarg :ship-addr-full)
   (ship-city
    :column "SHIPCITY"
    :type (string 50)
    :initarg :ship-city)
   (ship-state
    :column "SHIPSTATE"
    :type (string 50)
    :initarg :ship-state)
   (ship-zipcode
    :column "SHIPZIPCODE"
    :type (string 10)
    :initarg :ship-zipcode)
   (storepickupenabled
    :column "STOREPICKUPENABLED"
    :type (string 1)
    :initarg :storepickupenabled)

   ;; ── billing ────────────────────────────────────────────────────────────
   (bill-address-short
    :column "BILLADDRESS"
    :type (string 200)
    :initarg :bill-address-short)
   (bill-addr-full
    :column "BILLADDR"
    :type string ; text
    :initarg :bill-addr-full)
   (bill-city
    :column "BILLCITY"
    :type (string 50)
    :initarg :bill-city)
   (bill-state
    :column "BILLSTATE"
    :type (string 50)
    :initarg :bill-state)
   (bill-zipcode
    :column "BILLZIPCODE"
    :type (string 10)
    :initarg :bill-zipcode)
   (country
    :column "COUNTRY"
    :type (string 50)
    :initarg :country)
   (bill-same-as-ship
    :column "BILLSAMEASSHIP"
    :type (string 1)
    :initarg :bill-same-as-ship)

   ;; ── GST, and where the supply is taxed (the vendor's own state decides) ─
   (gst-number
    :column "GSTNUMBER"
    :type (string 20)
    :initarg :gst-number)
   (gst-org-name
    :column "GSTORGNAME"
    :type (string 50)
    :initarg :gst-org-name)
   (place-of-supply
    :column "PLACE_OF_SUPPLY"
    :type (string 50)
    :initarg :place-of-supply)
   (place-of-supply-code
    :column "PLACE_OF_SUPPLY_CODE"
    :type (string 2)
    :initarg :place-of-supply-code)
   (supply-type
    :column "SUPPLY_TYPE"
    :type (string 12) ; enum('INTRA_STATE','INTER_STATE')
    :initarg :supply-type)
   (reverse-charge-applicable
    :column "REVERSE_CHARGE_APPLICABLE"
    :type integer ; tinyint(1)
    :initarg :reverse-charge-applicable)
   (eway-bill-required
    :column "EWAY_BILL_REQUIRED"
    :type integer ; tinyint(1)
    :initarg :eway-bill-required)
   (tds-applicable
    :column "TDS_APPLICABLE"
    :type integer ; tinyint(1)
    :initarg :tds-applicable)
   (tds-amount
    :column "TDS_AMOUNT"
    :type float
    :initarg :tds-amount)

   ;; ── money: this vendor's slice of the order, NOT the order total ───────
   (order-amt
    :column "ORDER_AMT"
    :type float
    :initarg :order-amt)
   (total-taxable-value
    :column "TOTAL_TAXABLE_VALUE"
    :type float
    :initarg :total-taxable-value)
   (total-cgst
    :column "TOTAL_CGST"
    :type float
    :initarg :total-cgst)
   (total-sgst
    :column "TOTAL_SGST"
    :type float
    :initarg :total-sgst)
   (total-igst
    :column "TOTAL_IGST"
    :type float
    :initarg :total-igst)
   (total-cess
    :column "TOTAL_CESS"
    :type float
    :initarg :total-cess)
   (total-tax
    :column "TOTAL_TAX"
    :type float
    :initarg :total-tax)
   (total-discount
    :column "TOTAL_DISCOUNT"
    :type float
    :initarg :total-discount)
   (shipping-cost
    :column "SHIPPING_COST"
    :type float
    :initarg :shipping-cost)

   ;; ── audit and tenancy. TENANT_ID IS NOT REDECLARED ON THE ENTITY below
   ;;    (it is inherited there), but the VIEW CLASS must name the column.
   (tenant-id
    :column "TENANT_ID"
    :type integer
    :initarg :tenant-id)
   (deleted-state
    :column "DELETED_STATE"
    :type (string 1)
    :initarg :deleted-state)
   (created
    :column "CREATED"
    :type (string 30)
    :initarg :created)
   (updated
    :column "UPDATED"
    :type (string 30)
    :initarg :updated)
   )
  (:base-table "DOD_VENDOR_ORDERS")
  (:documentation
   "The vendor order row — one per (ORDER, VENDOR), UNIQUE on that pair. 60 slots, one per live
    column of DOD_VENDOR_ORDERS, measured 2026-10-04. A NEW class, not an extension of the legacy
    dod-vendor-orders (26 columns), because extending that one would change a live SELECT's column
    list as a side effect of an order change. No :join slots: a join is a traversal, not domain
    state. ORD_DATE/REQ_DATE/SHIPPED_DATE are (string 30) on purpose — see the file header."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; Tree 1, part 2 — the entity. Subclasses nst-domain-entity and NOTHING else.
;;; ───────────────────────────────────────────────────────────────────────────

(defclass nst-vordh (nst-domain-entity)
  (
   (row-id :initarg :row-id :accessor row-id :initform nil)
   (ordnum :initarg :ordnum :accessor ordnum :initform nil)
   (context-id :initarg :context-id :accessor context-id :initform nil)
   (ord-date :initarg :ord-date :accessor ord-date :initform nil)
   (req-date :initarg :req-date :accessor req-date :initform nil)
   (shipped-date :initarg :shipped-date :accessor shipped-date :initform nil)
   (expected-delivery-date :initarg :expected-delivery-date :accessor expected-delivery-date :initform nil)
   (order-type :initarg :order-type :accessor order-type :initform nil)
   (order-source :initarg :order-source :accessor order-source :initform nil)
   (status :initarg :status :accessor status :initform nil)
   (order-fulfilled :initarg :order-fulfilled :accessor order-fulfilled :initform "N")
   (order-id :initarg :order-id :accessor order-id :initform nil)
   (cust-id :initarg :cust-id :accessor cust-id :initform nil)
   (cust-name :initarg :cust-name :accessor cust-name :initform nil)
   (vendor-id :initarg :vendor-id :accessor vendor-id :initform nil)
   (created-by-user-id :initarg :created-by-user-id :accessor created-by-user-id :initform nil)
   (approved-by-user-id :initarg :approved-by-user-id :accessor approved-by-user-id :initform nil)
   (ship-address-short :initarg :ship-address-short :accessor ship-address-short :initform nil)
   (ship-addr-full :initarg :ship-addr-full :accessor ship-addr-full :initform nil)
   (ship-city :initarg :ship-city :accessor ship-city :initform nil)
   (ship-state :initarg :ship-state :accessor ship-state :initform nil)
   (ship-zipcode :initarg :ship-zipcode :accessor ship-zipcode :initform nil)
   (bill-address-short :initarg :bill-address-short :accessor bill-address-short :initform nil)
   (bill-addr-full :initarg :bill-addr-full :accessor bill-addr-full :initform nil)
   (bill-city :initarg :bill-city :accessor bill-city :initform nil)
   (bill-state :initarg :bill-state :accessor bill-state :initform nil)
   (bill-zipcode :initarg :bill-zipcode :accessor bill-zipcode :initform nil)
   (country :initarg :country :accessor country :initform nil)
   (bill-same-as-ship :initarg :bill-same-as-ship :accessor bill-same-as-ship :initform "Y")
   (storepickupenabled :initarg :storepickupenabled :accessor storepickupenabled :initform nil)
   (gst-number :initarg :gst-number :accessor gst-number :initform nil)
   (gst-org-name :initarg :gst-org-name :accessor gst-org-name :initform nil)
   (place-of-supply :initarg :place-of-supply :accessor place-of-supply :initform nil)
   (place-of-supply-code :initarg :place-of-supply-code :accessor place-of-supply-code :initform nil)
   (supply-type :initarg :supply-type :accessor supply-type :initform nil)
   (reverse-charge-applicable :initarg :reverse-charge-applicable :accessor reverse-charge-applicable :initform 0)
   (eway-bill-required :initarg :eway-bill-required :accessor eway-bill-required :initform 0)
   (tds-applicable :initarg :tds-applicable :accessor tds-applicable :initform 0)
   (tds-amount :initarg :tds-amount :accessor tds-amount :initform 0.0)
   (order-amt :initarg :order-amt :accessor order-amt :initform 0.0)
   (total-taxable-value :initarg :total-taxable-value :accessor total-taxable-value :initform 0.0)
   (total-cgst :initarg :total-cgst :accessor total-cgst :initform 0.0)
   (total-sgst :initarg :total-sgst :accessor total-sgst :initform 0.0)
   (total-igst :initarg :total-igst :accessor total-igst :initform 0.0)
   (total-cess :initarg :total-cess :accessor total-cess :initform 0.0)
   (total-tax :initarg :total-tax :accessor total-tax :initform 0.0)
   (total-discount :initarg :total-discount :accessor total-discount :initform 0.0)
   (shipping-cost :initarg :shipping-cost :accessor shipping-cost :initform 0.0)
   (is-converted-to-invoice :initarg :is-converted-to-invoice :accessor is-converted-to-invoice :initform "N")
   (invoice-number :initarg :invoice-number :accessor invoice-number :initform nil)
   (invoice-date :initarg :invoice-date :accessor invoice-date :initform nil)
   (is-cancelled :initarg :is-cancelled :accessor is-cancelled :initform "N")
   (cancel-reason :initarg :cancel-reason :accessor cancel-reason :initform nil)
   (comments :initarg :comments :accessor comments :initform nil)
   (external-url :initarg :external-url :accessor external-url :initform nil)
   (payment-mode :initarg :payment-mode :accessor payment-mode :initform nil)
   )
  (:documentation
   "the VENDOR ORDER row (entity nst-vordh). Lives on the ISLAND (Tree 1), subclassing
    nst-domain-entity ONLY — never BusinessObject and never a boundary class; an immunity test
    enforces that the two trees never meet. id/tenant-id/created-at/updated-at/deleted-state are
    INHERITED and never redeclared here. Every business slot carries :initarg and :accessor so the
    ferry's MOP filter (extract-domain-initargs) can introspect it; the five reserved initargs are
    stripped there, so the tenant can only ever come from domain-ctx (नियम-1) — and for THIS entity
    that is load-bearing twice over, because the row is scoped by vendor AND tenant (V3).

    `row-id`, `order-id`, `vendor-id` and `cust-id` are ADDRESS, not payload: they are read to
    resolve the row and are never updatable through the vendor channel (V7 / AC d). `ordnum` is
    the customer's document number (D20) and is likewise immutable here."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; Tree 2 IN — the inbound boundary. DELIBERATELY SLOTLESS: every inbound value,
;;; including :row-id, rides in the inherited `params` plist and dies at the ferry.
;;; Typed request-model slots were tried earlier in this migration and were dead
;;; weight, because request->dispatch reads only (params rm) and never a typed slot.
;;; ───────────────────────────────────────────────────────────────────────────

(defclass NstVordhRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object for nst-vordh. SLOTLESS on purpose: all data — including :row-id —
    travels in (params rm) as a plist, and the ferry MOP-filters that plist against the initargs
    nst-vordh declares. The request model DIES at the ferry (लोप): it is never returned, stored,
    or passed to a verb."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; Tree 2 OUT — the outbound boundary. Mirrors the entity field for field.
;;; ───────────────────────────────────────────────────────────────────────────

(defclass NstVordhResponseModel (nst-response-model)
  (
   (row-id :initarg :row-id :accessor row-id)
   (ordnum :initarg :ordnum :accessor ordnum)
   (context-id :initarg :context-id :accessor context-id)
   (ord-date :initarg :ord-date :accessor ord-date)
   (req-date :initarg :req-date :accessor req-date)
   (shipped-date :initarg :shipped-date :accessor shipped-date)
   (expected-delivery-date :initarg :expected-delivery-date :accessor expected-delivery-date)
   (order-type :initarg :order-type :accessor order-type)
   (order-source :initarg :order-source :accessor order-source)
   (status :initarg :status :accessor status)
   (order-fulfilled :initarg :order-fulfilled :accessor order-fulfilled)
   (order-id :initarg :order-id :accessor order-id)
   (cust-id :initarg :cust-id :accessor cust-id)
   (cust-name :initarg :cust-name :accessor cust-name)
   (vendor-id :initarg :vendor-id :accessor vendor-id)
   (created-by-user-id :initarg :created-by-user-id :accessor created-by-user-id)
   (approved-by-user-id :initarg :approved-by-user-id :accessor approved-by-user-id)
   (ship-address-short :initarg :ship-address-short :accessor ship-address-short)
   (ship-addr-full :initarg :ship-addr-full :accessor ship-addr-full)
   (ship-city :initarg :ship-city :accessor ship-city)
   (ship-state :initarg :ship-state :accessor ship-state)
   (ship-zipcode :initarg :ship-zipcode :accessor ship-zipcode)
   (bill-address-short :initarg :bill-address-short :accessor bill-address-short)
   (bill-addr-full :initarg :bill-addr-full :accessor bill-addr-full)
   (bill-city :initarg :bill-city :accessor bill-city)
   (bill-state :initarg :bill-state :accessor bill-state)
   (bill-zipcode :initarg :bill-zipcode :accessor bill-zipcode)
   (country :initarg :country :accessor country)
   (bill-same-as-ship :initarg :bill-same-as-ship :accessor bill-same-as-ship)
   (storepickupenabled :initarg :storepickupenabled :accessor storepickupenabled)
   (gst-number :initarg :gst-number :accessor gst-number)
   (gst-org-name :initarg :gst-org-name :accessor gst-org-name)
   (place-of-supply :initarg :place-of-supply :accessor place-of-supply)
   (place-of-supply-code :initarg :place-of-supply-code :accessor place-of-supply-code)
   (supply-type :initarg :supply-type :accessor supply-type)
   (reverse-charge-applicable :initarg :reverse-charge-applicable :accessor reverse-charge-applicable)
   (eway-bill-required :initarg :eway-bill-required :accessor eway-bill-required)
   (tds-applicable :initarg :tds-applicable :accessor tds-applicable)
   (tds-amount :initarg :tds-amount :accessor tds-amount)
   (order-amt :initarg :order-amt :accessor order-amt)
   (total-taxable-value :initarg :total-taxable-value :accessor total-taxable-value)
   (total-cgst :initarg :total-cgst :accessor total-cgst)
   (total-sgst :initarg :total-sgst :accessor total-sgst)
   (total-igst :initarg :total-igst :accessor total-igst)
   (total-cess :initarg :total-cess :accessor total-cess)
   (total-tax :initarg :total-tax :accessor total-tax)
   (total-discount :initarg :total-discount :accessor total-discount)
   (shipping-cost :initarg :shipping-cost :accessor shipping-cost)
   (is-converted-to-invoice :initarg :is-converted-to-invoice :accessor is-converted-to-invoice)
   (invoice-number :initarg :invoice-number :accessor invoice-number)
   (invoice-date :initarg :invoice-date :accessor invoice-date)
   (is-cancelled :initarg :is-cancelled :accessor is-cancelled)
   (cancel-reason :initarg :cancel-reason :accessor cancel-reason)
   (comments :initarg :comments :accessor comments)
   (external-url :initarg :external-url :accessor external-url)
   (payment-mode :initarg :payment-mode :accessor payment-mode)
   (deleted-state :initarg :deleted-state :accessor deleted-state)
   ;; deleted-state is CARRIED but NOT necessarily published: the mirrored-slot list drives
   ;; domain->response, which setfs it here, and render-json decides separately what reaches the
   ;; wire. Declaring it is what stops the MISSING-SLOT failure; whether a client sees it is a
   ;; render-json allowlist decision, made in the BL file.
   )
  (:documentation
   "Outbound boundary model for nst-vordh. Subclasses nst-response-model (per adhara), NOT
    nst-boundary-object. Its slot set is *vordh-mirrored-slots* made concrete — the two must not
    drift, and the offline mirror check asserts it. Rendered only through render-* methods; the
    domain entity itself never crosses the boundary."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; The mirrored-slot list (see the header: it drives THREE consumers)
;;; ───────────────────────────────────────────────────────────────────────────

(defparameter *vordh-mirrored-slots*
  '(
  ;; identity, dates and lifecycle
    ordnum context-id ord-date req-date shipped-date expected-delivery-date
    order-type order-source status order-fulfilled
  ;; the address of the row and its three parties. order-id/cust-id/vendor-id are mirrored
  ;; because the vendor must be able to see WHICH order and WHICH customer it is serving —
  ;; that is the vendor channel's whole purpose, and it is the D20-carrying row's own scope.
    order-id cust-id cust-name vendor-id created-by-user-id approved-by-user-id
  ;; addresses and place of supply
    ship-address-short ship-addr-full ship-city ship-state ship-zipcode
    bill-address-short bill-addr-full bill-city bill-state bill-zipcode
    country bill-same-as-ship storepickupenabled
  ;; GST
    gst-number gst-org-name place-of-supply place-of-supply-code supply-type
    reverse-charge-applicable eway-bill-required tds-applicable tds-amount
  ;; money — THIS VENDOR's slice, never the order total
    order-amt total-taxable-value total-cgst total-sgst total-igst total-cess
    total-tax total-discount shipping-cost
  ;; the order -> invoice link
    is-converted-to-invoice invoice-number invoice-date
  ;; other state
    is-cancelled cancel-reason comments external-url payment-mode
    ;; document state. INHERITED from nst-domain-entity and mirrored anyway, because the
    ;; RESPONSE model must carry it — the invoice's missing slot was exactly this one.
    deleted-state)
  "Every nst-vordh slot (except row-id, which domain->response sets explicitly) that
   domain->response copies onto NstVordhResponseModel. It drives THREE consumers — both copy
   ferries and the reverse ferry — so a name added here must exist as a slot on the entity AND on
   the response model. tools/nst-order-mirror-check.lisp asserts that, offline: this list is the
   reason the invoice API once answered 500 on every route.")
