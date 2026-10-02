;;; nst-dal-ordh.lisp — the ORDER HEADER island entity and its boundary models (S1/S2)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Design: aiharness/deepseek/skills/order-adhara-stories-CONTEXT.md (S1 for the header,
;;; S2 for the line).

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THIS FILE IS
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; The Tree-1 island entity, the SLOTLESS inbound boundary model, the outbound
;;; response model, and the mirrored-slot list that drives domain->response. Nothing
;;; else: no प्रत्यय (nst-bl-ordh.lisp), no copiers, no render. This file is inert.
;;;
;;; MEASURED AGAINST THE LIVE DATABASE, NOT ASSUMED (2026-09-27/28):
;;;
;;;  * `dod-order` has 58 columns and the view class `dod-order`
;;;    (hhub/order/nst-dal-Order.lisp:482) declares ALL of them — so THIS FILE ADDS NO ORM CLASS and
;;;    reuses that one (decision D7). Its slot names are what is mirrored below.
;;;    ⚠ THOSE NAMES ARE NOT DERIVABLE FROM THE COLUMN NAMES: SHIP_ADDRESS is
;;;    `ship-address-short`, SHIPADDR is `ship-addr-full`, CUSTNAME is `cust-name`, GSTNUMBER
;;;    is `gst-number`. Extracted from the class rather than guessed — a kebab-case of
;;;    the column would have produced four wrong slot names.
;;;  * The columns the BASE CLASS already owns are NOT redeclared: TENANT_ID, DELETED_STATE,
;;;    CREATED and UPDATED map to the inherited tenant-id / deleted-state / created-at /
;;;    updated-at. So 58 - 4 = 54 slots here: row-id + 53 business fields.
;;;  * `customer` and `company` are :db-kind :join on the view class and are therefore NOT
;;;    domain state — the same exclusion nst-customer documents.
;;;  * STATUS is char(3) in the live table. That is why `dod-order`'s `(string 3)` is RIGHT
;;;    and why the create-script's `varchar(20) DEFAULT 'DRAFT'` is fiction: five-character
;;;    DRAFT cannot be stored at all. DO NOT WIDEN IT — the status vocabulary is 3 characters
;;;    and the open state this batch mints is DFT, not DRAFT (D7).
;;;
;;; ⚠ MONEY AND RATE SLOTS GET AN EXPLICIT `0.0` INITFORM, and that is a fixed defect, not
;;; style: CLSQL declares these decimal columns `(OR NULL FLOAT)` and VALIDATES on insert,
;;; so an ordinary JSON `0` — an INTEGER — fails the INSERT and surfaces to the client as
;;; `:U` / 503 "the database call did not answer". The invoice batch lost a day to exactly
;;; that, twice: once for the omitted field (fixed by the initform) and once for the
;;; supplied one (fixed in the copier, which must coerce integer→float for these slots).
;;; The tinyint(1) flags take `0` because they are integers, and the char(1) flags take
;;; "N" so that a create writes the same value the column's own DEFAULT would.
;;;
;;; ⚠ WHY THE MIRRORED-SLOT LIST LIVES IN THIS FILE rather than the BL file, where the
;;; invoice keeps its own: the list must match these two classes EXACTLY, and THAT list
;;; drives THREE consumers — both copy ferries AND domain->response, which setfs every
;;; listed slot onto the RESPONSE MODEL. A slot added to the list with no slot there
;;; signals MISSING-SLOT on every response: that is precisely how the whole invoice API
;;; answered 500 for weeks while every offline check passed. Keeping the list beside both
;;; classes makes the three editable in one place; tools/nst-verify-doc-numbering.lisp
;;; asserts they stay in step, offline, with no database and no image.

;;; ───────────────────────────────────────────────────────────────────────────
;;; Tree 1 — the entity. Subclasses nst-domain-entity and NOTHING else.
;;; ───────────────────────────────────────────────────────────────────────────

(defclass nst-ordh (nst-domain-entity)
  (
;;; identity of the row (set by the database; never client-supplied)
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
   (order-fulfilled :initarg :order-fulfilled :accessor order-fulfilled :initform "N")
   (cust-id :initarg :cust-id :accessor cust-id)
   (cust-name :initarg :cust-name :accessor cust-name)
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
   (invoice-number :initarg :invoice-number :accessor invoice-number)
   (invoice-date :initarg :invoice-date :accessor invoice-date)
   (is-cancelled :initarg :is-cancelled :accessor is-cancelled :initform "N")
   (cancel-reason :initarg :cancel-reason :accessor cancel-reason)
   (comments :initarg :comments :accessor comments)
   (external-url :initarg :external-url :accessor external-url)
   (payment-mode :initarg :payment-mode :accessor payment-mode)
  )
  (:documentation
   "the ORDER HEADER (entity nst-ordh). Lives on the ISLAND (Tree 1), subclassing nst-domain-entity
    ONLY — never BusinessObject and never a boundary class; an immunity test enforces the
    two trees never meet. id/tenant-id/created-at/updated-at/deleted-state are INHERITED
    and never redeclared here. Every business slot carries :initarg and :accessor so the
    ferry's MOP filter (extract-domain-initargs) can introspect it; the five reserved
    initargs (:id :tenant-id :created-at :updated-at :deleted-state) are stripped there,
    so the tenant can only ever come from domain-ctx (नियम-1)."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; Tree 2 IN — the inbound boundary. DELIBERATELY SLOTLESS: every inbound value,
;;; including :row-id, rides in the inherited `params` plist and dies at the ferry.
;;; Typed request-model slots were tried earlier in this migration and were dead
;;; weight, because request->dispatch reads only (params rm) and never a typed slot.
;;; ───────────────────────────────────────────────────────────────────────────

(defclass NstOrdhRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object for nst-ordh. SLOTLESS on purpose: all data — including
    :row-id — travels in (params rm) as a plist, and the ferry MOP-filters that plist
    against the initargs nst-ordh declares. The request model DIES at the ferry (लोप):
    it is never returned, stored, or passed to a verb."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; Tree 2 OUT — the outbound boundary. Mirrors the entity field for field.
;;; ───────────────────────────────────────────────────────────────────────────

(defclass NstOrdhResponseModel (nst-response-model)
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
   (cust-id :initarg :cust-id :accessor cust-id)
   (cust-name :initarg :cust-name :accessor cust-name)
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
   ;; deleted-state is CARRIED but NOT necessarily published: the mirrored-slot list
   ;; drives domain->response, which setfs it here, and render-json decides separately
   ;; what reaches the wire. Declaring it is what stops the MISSING-SLOT failure; whether
   ;; a client sees it is a render-json allowlist decision, made in the BL file.
   )
  (:documentation
   "Outbound boundary model for nst-ordh. Subclasses nst-response-model (per adhara),
    NOT nst-boundary-object. Its slot set is *ordh-mirrored-slots* made concrete — the two
    must not drift, and the offline check asserts it. Rendered only through render-*
    methods; the domain entity itself never crosses the boundary."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; The mirrored-slot list (see the header: it drives THREE consumers)
;;; ───────────────────────────────────────────────────────────────────────────

(defparameter *ordh-mirrored-slots*
  '(
  ;; identity, dates and lifecycle
    ordnum context-id ord-date req-date shipped-date expected-delivery-date
    order-type order-source status order-fulfilled
  ;; the two parties and who touched it
    cust-id cust-name created-by-user-id approved-by-user-id
  ;; addresses and place of supply
    ship-address-short ship-addr-full ship-city ship-state ship-zipcode
    bill-address-short bill-addr-full bill-city bill-state bill-zipcode
    country bill-same-as-ship storepickupenabled
  ;; GST
    gst-number gst-org-name place-of-supply place-of-supply-code supply-type
    reverse-charge-applicable eway-bill-required tds-applicable tds-amount
  ;; money
    order-amt total-taxable-value total-cgst total-sgst total-igst total-cess
    total-tax total-discount shipping-cost
  ;; the order -> invoice link
    is-converted-to-invoice invoice-number invoice-date
  ;; other state
    is-cancelled cancel-reason comments external-url payment-mode
    ;; document state. INHERITED from nst-domain-entity and mirrored anyway, because the
    ;; RESPONSE model must carry it — the invoice's missing slot was exactly this one.
    deleted-state)
  "Every nst-ordh slot (except row-id, which domain->response sets explicitly) that
   domain->response copies onto NstOrdhResponseModel. It drives THREE consumers — both
   copy ferries and the reverse ferry — so a name added here must exist as a slot on the
   entity AND on the response model. tools/nst-verify-doc-numbering.lisp asserts that,
   offline: this list is the reason the invoice API once answered 500 on every route.")
