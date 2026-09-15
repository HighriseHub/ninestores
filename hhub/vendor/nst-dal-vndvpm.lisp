;;; nst-dal-vndvpm.lisp — Vendor payment-methods domain class + boundary models
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; 🚨 NOT YET COMPILED. Nothing in this file has run. It is wired into
;;; nstores.asd and package/compile.lisp and sits after nst-bl-adhara (the
;;; boundary classes it names). Per the standing rule of this project — and its
;;; two recorded proofs, a copier that compiled with ten warnings and would have
;;; failed on the first fetch, and a helper named `safe` that executes arbitrary
;;; code — compile-time success is NOT evidence. Call the प्रत्यय before trusting
;;; any of this.
;;;
;;; WHY A NEW FILE, AND NOT dod-dal-vpm.lisp. That file is LIVE LEGACY, not dead
;;; weight: customer/dod-ui-cus.lisp:295 constructs VPaymentMethodsAdapter on the
;;; customer CHECKOUT path, and test/hhub-tst-vpm.lisp exercises it. It already
;;; holds a legacy entity (VPaymentMethods), a legacy CLSQL view-class
;;; (dod-vpayment-methods) and a legacy request/response model pair for this same
;;; table. Adding the new architecture there would give ONE TABLE two entity
;;; implementations and three boundary models in one file — the divergence
;;; nst-dal-vnd.lisp:7-10 records as the reason products/ is the cautionary
;;; example. This file holds ONLY the new architecture and leaves the legacy
;;; chain untouched and working.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; nst-vnd-vpm — the vendor payment-methods domain entity
;;;
;;; THE FIRST CHILD ENTITY IN THIS TREE. Every other nst-* entity (nst-vnd,
;;; nst-whs, nst-prd) is a ROOT. nst-vnd-vpm belongs to a vendor, so:
;;;   * its identity is (VENDOR-ID, TENANT) — the parent link is part of the key,
;;;   * it is a 0-or-1 SINGLETON per vendor, and
;;;   * VENDOR_ID is a foreign key to DOD_VEND_PROFILE.ROW_ID.
;;;
;;; THE DATABASE ENFORCES NONE OF THAT. DOD_VPAYMENT_METHODS has only a PRIMARY
;;; KEY on ROW_ID plus two plain NON-UNIQUE indexes on TENANT_ID and VENDOR_ID
;;; (verified by SHOW INDEX, 2026-09-15). Nothing stops a second row for the same
;;; vendor. The singleton law is therefore a DOMAIN law for ?exists / make to own,
;;; NOT a schema fact to rely on — the same shape as the DOD_SHIPPING_METHODS
;;; singleton that shipping will need.
;;;
;;; INITFORMS MIRROR THE LIVE TABLE (verified by SHOW COLUMNS FROM
;;; DOD_VPAYMENT_METHODS, 2026-09-15, MySQL 8.0.46). NOT
;;; installation/hhubplatform.sql, and NOT dod-dal-vpm.lisp's
;;; dod-vpayment-methods view-class, which diverges from the schema in the three
;;; places recorded under DECISIONS below.
;;;
;;; NIL means "column is nullable": the value may legitimately be absent.
;;; row-id and vendor-id keep NO initform on purpose — row-id is bound by
;;; bind-generated-row-id after the INSERT, and vendor-id must fail loudly when a
;;; caller forgets the parent, because a payment-methods row with no vendor is
;;; meaningless. Same rule as nst-vnd's `company`.
;;;
;;; DECISIONS — each a deliberate divergence from the live legacy view-class:
;;;
;;; 1. PAYLATERENABLED defaults to "N", NOT "Y". The DDL default is 'N' and
;;;    dod-vpayment-methods declares :void-value "Y". The LEGACY CLASS IS WRONG,
;;;    and the live data agrees with the DDL: rows 3, 4 and 12 hold 'N'.
;;;
;;; 2. ACTIVE_FLAG defaults to "Y" as a CLASS CHOICE, not a schema default. The
;;;    column is nullable with NO default. The legacy class hides that behind
;;;    :void-value "Y"; NIL is the honest representation of absence, so there is
;;;    genuinely no DDL default here and this value is CHOSEN. It matches all five
;;;    live rows ('Y') and keeps a new row visible to the readers that filter on
;;;    active_flag='Y' + deleted_state='N' (the shape at
;;;    shipping/dod-bl-osh.lisp:112-113).
;;;
;;; 3. upienabled's initarg is :UPIENABLED, not :ENABLED.
;;;    dod-vpayment-methods declares (:initarg :enabled), so a caller passing
;;;    :upienabled gets an UNBOUND SLOT while the column it means is UPIENABLED.
;;;    This file uses the correct name.
;;;
;;; 4. CREATED has NO slot — it is served by the INHERITED created-at and the
;;;    database maintains it. Same rule nst-dal-vnd.lisp:231-234 applies to
;;;    DOD_VEND_PROFILE. NOTE this table has NO updated column AT ALL, so the
;;;    inherited updated-at has no column behind it: it is a domain-layer
;;;    timestamp only, and a copier must NOT try to write it.
;;;
;;; 5. Slot names are PLAIN (codenabled, upienabled, …), matching the column
;;;    names and the legacy view-class. The overloading is deliberate — it is the
;;;    SAME column with the SAME meaning, so (codenabled x) answers correctly for
;;;    both a legacy object and this one. Contrast nst-vnd, which prefixed
;;;    vnd-phone / vnd-name / vnd-city because those plain names belonged to
;;;    DIFFERENT columns elsewhere. `active-flag` stays plain for the same reason
;;;    nst-vnd keeps it plain (nst-dal-vnd.lisp:218).
;;;
;;; THIS CLASS DECLARES THE FLAGS ONLY. The gateway credentials the API will
;;; expose under vendor/payment/gateway and vendor/payment/upi — PAYMENT_API_KEY,
;;; PAYMENT_API_SALT, PAYMENT_GATEWAY_MODE, UPI_ID — live on the VENDOR row, not
;;; here, and stay nst-vnd's slots. See §12.3 of nst-bl-vndapi-CONTEXT.md.
;;; ═══════════════════════════════════════════════════════════════════════════

(in-package :nstores)

(defclass nst-vnd-vpm (nst-domain-entity)   ; NOT (business-object nst-domain-entity)
  (;; ROW — bound by bind-generated-row-id after the INSERT, never by a caller.
   (row-id
    :initarg :row-id
    :accessor row-id)

   ;; ── PARENT ──────────────────────────────────────────────────────────────
   ;; No initform: a child row with no parent must fail loudly. This is the
   ;; column the singleton law is keyed on, together with the inherited tenant-id.
   ;; It is a FK to DOD_VEND_PROFILE.ROW_ID, and the DB does not enforce the
   ;; reference — DOD_VPAYMENT_METHODS declares no FOREIGN KEY constraint, so an
   ;; orphan vendor-id is accepted by MySQL and must be refused in the domain.
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id
    :documentation "FK → DOD_VEND_PROFILE.ROW_ID. UNENFORCED by the database —
                    no FOREIGN KEY constraint exists on this table, so the
                    domain must refuse a vendor-id that does not resolve within
                    the session tenant.")

   ;; ── THE FIVE FLAGS ──────────────────────────────────────────────────────
   ;; The whole entity. Each default is the LIVE DDL default, verified by
   ;; SHOW COLUMNS — not the legacy view-class's :void-value. See DECISIONS 1-3.
   (codenabled
    :initarg :codenabled
    :accessor codenabled
    :initform "Y"
    :documentation "Cash on delivery. char(1), nullable, DDL default 'Y'.")

   (upienabled
    :initarg :upienabled
    :accessor upienabled
    :initform "Y"
    :documentation "char(1), nullable, DDL default 'Y'. NOTE the initarg is
                    :upienabled — the legacy view-class wrongly declares
                    :enabled (DECISION 3).")

   (payprovidersenabled
    :initarg :payprovidersenabled
    :accessor payprovidersenabled
    :initform "Y"
    :documentation "Payment-gateway providers. char(1), nullable, DDL default 'Y'.
                    The CREDENTIALS this flag gates live on nst-vnd, not here.")

   (walletenabled
    :initarg :walletenabled
    :accessor walletenabled
    :initform "Y"
    :documentation "char(1), nullable, DDL default 'Y'.")

   (paylaterenabled
    :initarg :paylaterenabled
    :accessor paylaterenabled
    :initform "N"
    :documentation "char(1), nullable, DDL default 'N' — NOT 'Y' as the legacy
                    view-class claims (DECISION 1).")

   ;; ── STATUS ──────────────────────────────────────────────────────────────
   ;; No initform: inherited deleted-state already carries "N".
   (active-flag
    :initarg :active-flag
    :accessor active-flag
    :initform "Y"
    :documentation "char(1), NULLABLE WITH NO DDL DEFAULT. The \"Y\" here is a
                    CLASS CHOICE, not a schema default — see DECISION 2.
                    deleted-state, tenant-id, created-at and updated-at are
                    INHERITED from nst-domain-entity (DECISION 4).")

   ;; ── TENANT — no initform on purpose: it must fail loudly if a caller
   ;; forgets it (the API injects the session company; the web form passes it).
   (company
    :initarg :company
    :accessor company
    :documentation "The company OBJECT; DOD_VPAYMENT_METHODS.TENANT_ID is its
                    row-id. Same shape and same reasoning as nst-vnd's company
                    slot (nst-bl-vnd.lisp decision 1): the object is what a
                    copier reads row-id from, and what the ferry must not be
                    allowed to override from a request body."))

  (:documentation
   "Vendor payment methods — the five flags in DOD_VPAYMENT_METHODS, and only
    those. A CHILD entity: identity is (VENDOR-ID, TENANT) and it is a 0-or-1
    SINGLETON per vendor.

    NO SECRETS LIVE HERE. Unlike nst-vnd (password, salt, payment-api-key,
    payment-api-salt) and unlike the coming nst-vnd-ship (shippartnerkey,
    shippartnersecret), this table holds nothing that must stay off the wire.
    That is what makes it the right first entity to run the whole
    adhara → conflodis2 → apidefs2 chain against: a failure here is
    unambiguously a plumbing failure, not a boundary or secret-handling one.

    Live rows (2026-09-15): 5, held by vendors 1, 3, 4 (tenant 2) and 17, 19
    (tenant 5). VENDOR 18 HAS NO ROW — a real 0-row fixture for the `make` path
    that needs no setup, unlike the soft-deleted vendor the profile suite must
    invent. All five rows are deleted_state='N' and active_flag='Y'.

    THE SINGLETON IS NOT ENFORCED (see the header). `make` must refuse a second
    row for the same (vendor, tenant) in its own :around, and ?exists must answer
    on that same tuple — otherwise a vendor silently accumulates rows and the
    readers, which take the FIRST row and have no ORDER BY
    (get-shipping-method-for-vendor, shipping/dod-bl-osh.lisp:11-19, ends in
    (car (clsql:select …))), start returning whichever row the planner happens
    to hand back."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Boundary models
;;;
;;; Both descend from nst-bl-adhara.lisp's boundary tree, NEVER from
;;; nst-domain-entity — that inheritance is what adhara exists to prevent.
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass VpmRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object for vendor payment-method operations.

    Deliberately SLOTLESS, exactly like VendorRequestModel: it carries NO
    per-field typed slots. All inbound data rides in the inherited `params` slot
    as a transport-shaped plist, e.g. (:row-id 5 :vendor-id 1 :codenabled \"N\").
    The ferry (request->dispatch / extract-domain-initargs in nst-bl-adhara.lisp)
    reads (params rm) and MOP-filters that plist against whatever initargs
    nst-vnd-vpm actually declares — one universal translator, zero per-entity
    mapping code.

    Registered as the :request-class of every vpm action route, so it must stay
    slotless: a typed mirror here would be a SECOND place the field list is
    written down, and the two would drift the first time a column is added.

    :tenant-id and audit keys are stripped by extract-domain-initargs and never
    accepted from a client."))

(defclass VpmResponseModel (nst-boundary-object)
  ((row-id
    :initarg :row-id
    :accessor row-id)

   ;; THE FIVE FLAGS — the entire published surface.
   (codenabled
    :initarg :codenabled
    :accessor codenabled)
   (upienabled
    :initarg :upienabled
    :accessor upienabled)
   (payprovidersenabled
    :initarg :payprovidersenabled
    :accessor payprovidersenabled)
   (walletenabled
    :initarg :walletenabled
    :accessor walletenabled)
   (paylaterenabled
    :initarg :paylaterenabled
    :accessor paylaterenabled)

   (active-flag
    :initarg :active-flag
    :accessor active-flag))

  (:documentation
   "Outbound boundary object for vendor payment methods. SEVEN DECLARED slots.

    🚨 class-slots WILL REPORT EIGHT. The eighth is the inherited boundary `id`
    (a UUID from nst-boundary-object, nst-bl-adhara.lisp:76). It is NOT a
    published field and render-json must never emit it — the same shape as
    VendorResponseModel, where 35 declared slots are counted 35 and the
    inherited `id` is neither counted nor rendered. Counting :initarg forms is
    the reliable way to count declared slots here: a naive
    \"^   (name\" grep undercounts, because `id` and `((row-id` sit on
    DOUBLE-PAREN lines (nst-bl-vndapi-CONTEXT.md §10 step 0).

    render-json publishes EVERY DECLARED slot of a response model, so the field
    list is the security boundary and the exclusion is STRUCTURAL — a field not
    declared here has no slot for domain->response to copy into, and therefore
    cannot reach the wire by accident. That is why there is no reflective default
    method: a missing render-json method signals no-applicable-method, which
    FAILS CLOSED; a reflective default would publish whatever was added next,
    which fails OPEN.

    WITHHELD, and why each is withheld rather than merely absent-minded:

      vendor-id     the vendor is fixed by the session (and, once the actor work
                    lands, by domain-ctx's actor slot). Publishing it would let
                    a client believe it can address another vendor's row, which
                    is exactly the intra-tenant BOLA the actor slot closes.
      tenant-id     auto-injected from the session; never client-addressable.
      company       the tenant OBJECT — a boundary object has no business
                    carrying a domain entity out.
      created-at    database-maintained audit; not a client field.
      updated-at    has NO COLUMN behind it on this table at all (DECISION 4),
                    so publishing it would publish a value that goes nowhere.
      deleted-state NULLABLE and NULL on rows the legacy path created; a
                    soft-delete is expressed as a 404/409 at the boundary, not
                    as a field on a 200.

    WHAT IS NOT HERE THAT MIGHT BE EXPECTED: no gateway credentials. The API's
    vendor/payment/gateway and vendor/payment/upi endpoints are !update on the
    VENDOR row (nst-vnd), because PAYMENT_API_KEY, PAYMENT_API_SALT,
    PAYMENT_GATEWAY_MODE and UPI_ID are DOD_VEND_PROFILE columns. They are not
    this entity's fields and must not leak into it on the way past.

    domain->response and render-json for this class live with the प्रत्यय in
    nst-bl-vndvpm.lisp, NOT here — this file is the data shape only."))
