;;; nst-dal-orditm.lisp — an ORDER LINE island entity and its boundary models (S1/S2)
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
;;; else: no प्रत्यय (nst-bl-orditm.lisp), no copiers, no render. This file is inert.
;;;
;;; MEASURED AGAINST THE LIVE DATABASE, NOT ASSUMED (2026-09-27/28):
;;;
;;;  * `dod-order-items` has 32 columns and the view class `dod-order-items`
;;;    (hhub/order/nst-dal-OrderItem.lisp:295) declares ALL of them — so THIS FILE ADDS NO ORM CLASS and
;;;    reuses that one (decision D7). Its slots are what is mirrored below.
;;;    
;;;    
;;;    
;;;    
;;;  * The columns the BASE CLASS already owns are NOT redeclared: TENANT_ID, DELETED_STATE,
;;;    CREATED and UPDATED map to the inherited tenant-id / deleted-state / created-at /
;;;    updated-at. So 32 - 4 = 28 slots here: row-id + 27 business fields.
;;;  * `order`, `vendor`, `product` and `company` are :db-kind :join and are NOT
;;;    domain state — the same exclusion nst-customer documents.
;;;  * FULFILLED and STATUS are char(1)/char(3), and ITC_ELIGIBLE is an enum whose value
;;;    is carried as the string the column holds (ELIGIBLE / INELIGIBLE / BLOCKED), not a boolean.
;;;    
;;;    
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

(defclass nst-orditm (nst-domain-entity)
  (
;;; identity of the row (set by the database; never client-supplied)
   (row-id :initarg :row-id :accessor row-id)
   (order-id :initarg :order-id :accessor order-id)
   (vendor-id :initarg :vendor-id :accessor vendor-id)
   (prd-id :initarg :prd-id :accessor prd-id)
   (hsn-code :initarg :hsn-code :accessor hsn-code)
   (sac-code :initarg :sac-code :accessor sac-code)
   (item-description :initarg :item-description :accessor item-description)
   (uqc :initarg :uqc :accessor uqc)
   (unit-price :initarg :unit-price :accessor unit-price :initform 0.0)
   (mrp :initarg :mrp :accessor mrp :initform 0.0)
   (prd-qty :initarg :prd-qty :accessor prd-qty)
   (cgst :initarg :cgst :accessor cgst :initform 0.0)
   (sgst :initarg :sgst :accessor sgst :initform 0.0)
   (igst :initarg :igst :accessor igst :initform 0.0)
   (cess-rate :initarg :cess-rate :accessor cess-rate :initform 0.0)
   (disc-rate :initarg :disc-rate :accessor disc-rate :initform 0.0)
   (addl-tax1-rate :initarg :addl-tax1-rate :accessor addl-tax1-rate :initform 0.0)
   (discount-amount :initarg :discount-amount :accessor discount-amount :initform 0.0)
   (cgstamt :initarg :cgstamt :accessor cgstamt :initform 0.0)
   (sgstamt :initarg :sgstamt :accessor sgstamt :initform 0.0)
   (igstamt :initarg :igstamt :accessor igstamt :initform 0.0)
   (cess-amount :initarg :cess-amount :accessor cess-amount :initform 0.0)
   (taxablevalue :initarg :taxablevalue :accessor taxablevalue :initform 0.0)
   (totalitemval :initarg :totalitemval :accessor totalitemval :initform 0.0)
   (fulfilled :initarg :fulfilled :accessor fulfilled)
   (status :initarg :status :accessor status)
   (itc-eligible :initarg :itc-eligible :accessor itc-eligible)
   (comments :initarg :comments :accessor comments)
  )
  (:documentation
   "an ORDER LINE (entity nst-orditm). Lives on the ISLAND (Tree 1), subclassing nst-domain-entity
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

(defclass NstOrditmRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object for nst-orditm. SLOTLESS on purpose: all data — including
    :row-id — travels in (params rm) as a plist, and the ferry MOP-filters that plist
    against the initargs nst-orditm declares. The request model DIES at the ferry (लोप):
    it is never returned, stored, or passed to a verb."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; Tree 2 OUT — the outbound boundary. Mirrors the entity field for field.
;;; ───────────────────────────────────────────────────────────────────────────

(defclass NstOrditmResponseModel (nst-response-model)
  (
   (row-id :initarg :row-id :accessor row-id)
   (order-id :initarg :order-id :accessor order-id)
   (vendor-id :initarg :vendor-id :accessor vendor-id)
   (prd-id :initarg :prd-id :accessor prd-id)
   (hsn-code :initarg :hsn-code :accessor hsn-code)
   (sac-code :initarg :sac-code :accessor sac-code)
   (item-description :initarg :item-description :accessor item-description)
   (uqc :initarg :uqc :accessor uqc)
   (unit-price :initarg :unit-price :accessor unit-price)
   (mrp :initarg :mrp :accessor mrp)
   (prd-qty :initarg :prd-qty :accessor prd-qty)
   (cgst :initarg :cgst :accessor cgst)
   (sgst :initarg :sgst :accessor sgst)
   (igst :initarg :igst :accessor igst)
   (cess-rate :initarg :cess-rate :accessor cess-rate)
   (disc-rate :initarg :disc-rate :accessor disc-rate)
   (addl-tax1-rate :initarg :addl-tax1-rate :accessor addl-tax1-rate)
   (discount-amount :initarg :discount-amount :accessor discount-amount)
   (cgstamt :initarg :cgstamt :accessor cgstamt)
   (sgstamt :initarg :sgstamt :accessor sgstamt)
   (igstamt :initarg :igstamt :accessor igstamt)
   (cess-amount :initarg :cess-amount :accessor cess-amount)
   (taxablevalue :initarg :taxablevalue :accessor taxablevalue)
   (totalitemval :initarg :totalitemval :accessor totalitemval)
   (fulfilled :initarg :fulfilled :accessor fulfilled)
   (status :initarg :status :accessor status)
   (itc-eligible :initarg :itc-eligible :accessor itc-eligible)
   (comments :initarg :comments :accessor comments)
   (deleted-state :initarg :deleted-state :accessor deleted-state)
   ;; deleted-state is CARRIED but NOT necessarily published: the mirrored-slot list
   ;; drives domain->response, which setfs it here, and render-json decides separately
   ;; what reaches the wire. Declaring it is what stops the MISSING-SLOT failure; whether
   ;; a client sees it is a render-json allowlist decision, made in the BL file.
   )
  (:documentation
   "Outbound boundary model for nst-orditm. Subclasses nst-response-model (per adhara),
    NOT nst-boundary-object. Its slot set is *orditm-mirrored-slots* made concrete — the two
    must not drift, and the offline check asserts it. Rendered only through render-*
    methods; the domain entity itself never crosses the boundary."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; The mirrored-slot list (see the header: it drives THREE consumers)
;;; ───────────────────────────────────────────────────────────────────────────

(defparameter *orditm-mirrored-slots*
  '(
  ;; parent and parties
    order-id vendor-id prd-id
  ;; what was ordered
    hsn-code sac-code item-description uqc
  ;; quantities and prices
    unit-price mrp prd-qty
  ;; tax RATES (decimal(4,2))
    cgst sgst igst cess-rate disc-rate addl-tax1-rate
  ;; tax and value AMOUNTS (decimal(15,2))
    discount-amount cgstamt sgstamt igstamt cess-amount taxablevalue
    totalitemval
  ;; fulfilment and compliance
    fulfilled status itc-eligible
  ;; other state
    comments
    ;; document state. INHERITED from nst-domain-entity and mirrored anyway, because the
    ;; RESPONSE model must carry it — the invoice's missing slot was exactly this one.
    deleted-state)
  "Every nst-orditm slot (except row-id, which domain->response sets explicitly) that
   domain->response copies onto NstOrditmResponseModel. It drives THREE consumers — both
   copy ferries and the reverse ferry — so a name added here must exist as a slot on the
   entity AND on the response model. tools/nst-verify-doc-numbering.lisp asserts that,
   offline: this list is the reason the invoice API once answered 500 on every route.")
