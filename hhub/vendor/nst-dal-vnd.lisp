;;; nst-dal-vnd.lisp — Vendor domain class + boundary models (nst-vnd)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; WHY A NEW FILE, AND NOT dod-dal-ven.lisp: the warehouse reference keeps the
;;; domain layer in its own nst-dal-*.lisp and leaves the legacy CLSQL view-classes
;;; untouched. products/ mixed the two into dod-dal-prd.lisp and that is recorded
;;; as a divergence to avoid. This file holds ONLY the new architecture.

(in-package :nstores)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; nst-vnd — the vendor domain entity
;;;
;;; INITFORMS MIRROR THE LIVE TABLE (verified by SHOW COLUMNS FROM DOD_VEND_PROFILE,
;;; 2026-09-13). NOT dod-dal-ven.lisp's dod-vend-profile view-class, and NOT
;;; installation/hhubplatform.sql — both are stale. dod-vend-profile is missing
;;; USERNAME, FULLNAME, CREATED and UPDATED entirely, and gives COUNTRY the
;;; accessor `city` (fixed separately in commit 71b8f84).
;;;
;;; WHY INITFORMS EXIST (same reason as nst-whs): without one a slot is UNBOUND
;;; until a caller supplies it, and the copier reads every field with a plain
;;; slot-value — so a caller that omits any field aborts with UNBOUND-SLOT. The
;;; internal web form posts most fields; an API client sends a handful. And
;;; tolerating nils in the copier alone would not fix it, because
;;; clsql:update-records-from-instance emits EVERY storable slot, writing an
;;; explicit NULL that bypasses the column DEFAULT and fails outright on a
;;; NOT NULL column.
;;;
;;; CLASS DEFAULT = THE SCHEMA DEFAULT where the DDL declares one. Where the
;;; column is NULLABLE WITH NO DEFAULT the class must still choose a value, and
;;; the choice made here is the one that leaves a newly self-registered vendor in
;;; the state the login contract already requires — see the STATUS block below.
;;; Each such choice is marked "class choice" and is a deliberate divergence from
;;; the DDL's NULL.
;;;
;;; NIL means "column is nullable": the value may legitimately be absent. The
;;; six NOT NULL columns with no default (NAME, ADDRESS, PHONE, USERNAME,
;;; PASSWORD, TENANT_ID) are deliberately left NIL rather than guessed, so the
;;; DATABASE refuses with the column named — that rule belongs there, not here.
;;;
;;; row-id and company keep NO initform: row-id is bound by bind-generated-row-id
;;; after the INSERT, and company must fail loudly when a caller forgets it.
;;;
;;; The credential columns (PASSWORD, SALT, PAYMENT_API_KEY, PAYMENT_API_SALT)
;;; exist here because the INSERT needs them. They are deliberately ABSENT from
;;; VendorResponseModel below — see the note there.
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass nst-vnd (nst-domain-entity)   ; NOT (business-object nst-domain-entity)
  (;; ROW — bound by bind-generated-row-id after the INSERT, never by a caller.
   (row-id
    :initarg :row-id
    :accessor row-id)

   ;; ── IDENTITY ────────────────────────────────────────────────────────────
   ;; UC_Vendor is UNIQUE (PHONE, TENANT_ID) — TENANT-SCOPED, and the ONLY
   ;; unique key besides the PK. This is the single biggest divergence from
   ;; nst-prd, whose PRODUCT_CODE is one global column. Consequence: ?exists
   ;; answers "taken IN THIS TENANT", which is actionable — the same phone is
   ;; free in another tenant. A soft-deleted vendor therefore reserves its
   ;; phone only within its own tenant.
   (vnd-phone
    :initarg :vnd-phone
    :accessor vnd-phone
    :initform nil
    :documentation "PHONE varchar(30) NOT NULL — half of UC_Vendor (with
                    TENANT_ID). No column default, so a vendor without a phone
                    is refused by the database. This is what ?exists checks.")
   (vnd-name
    :initarg :vnd-name
    :accessor vnd-name
    :initform nil
    :documentation "NAME varchar(70) NOT NULL, no column default. NOT part of
                    the unique key — two vendors in one tenant may share a name.")

   ;; ── CREDENTIALS ─────────────────────────────────────────────────────────
   ;; Never published: see VendorResponseModel.
   (username
    :initarg :username
    :accessor username
    :initform nil
    :documentation "USERNAME varchar(30) NOT NULL, no column default, and — a
                    trap — NOT part of any unique key. The login path matches
                    PHONE, so nothing enforces that usernames are distinct.")
   (password
    :initarg :password
    :accessor password
    :initform nil
    :documentation "PASSWORD varchar(100) NOT NULL — salted hash, never plaintext,
                    never published. Rotation is its own verb, not !update.")
   (salt
    :initarg :salt
    :accessor salt
    :initform nil
    :documentation "SALT varchar(128), nullable in the DDL — 3 of the 15 live
                    rows carry a real NULL, so a caller must expect nil here.")

   ;; ── PERSON ──────────────────────────────────────────────────────────────
   (firstname
    :initarg :firstname
    :accessor firstname
    :initform nil)
   (lastname
    :initarg :lastname
    :accessor lastname
    :initform nil)
   (fullname
    :initarg :fullname
    :accessor fullname
    :initform nil
    :documentation "varchar(50), nullable. Absent from dod-vend-profile's
                    view-class altogether — as are USERNAME and the timestamps.")
   (salutation
    :initarg :salutation
    :accessor salutation
    :initform nil)
   (vnd-title
    :initarg :vnd-title
    :accessor vnd-title
    :initform nil
    :documentation "TITLE varchar(255) — a job title, not a name prefix.")
   (birthdate
    :initarg :birthdate
    :accessor birthdate
    :initform nil)

   ;; ── ADDRESS ─────────────────────────────────────────────────────────────
   (vnd-address
    :initarg :vnd-address
    :accessor vnd-address
    :initform nil
    :documentation "ADDRESS varchar(70) NOT NULL, no column default.")
   (vnd-city
    :initarg :vnd-city
    :accessor vnd-city
    :initform nil)
   (vnd-state
    :initarg :vnd-state
    :accessor vnd-state
    :initform nil)
   (vnd-country
    :initarg :vnd-country
    :accessor vnd-country
    :initform nil)
   (vnd-zipcode
    :initarg :vnd-zipcode
    :accessor vnd-zipcode
    :initform nil)
   (vnd-picture-path
    :initarg :vnd-picture-path
    :accessor vnd-picture-path
    :initform nil)

   ;; ── CONTACT ─────────────────────────────────────────────────────────────
   (vnd-email
    :initarg :vnd-email
    :accessor vnd-email
    :initform nil
    :documentation "EMAIL varchar(255), nullable. NOT part of UC_Vendor — the
                    login path matches PHONE, not EMAIL, so two vendors may
                    share one address. EMAIL_ADD_VERIFIED is separate and
                    starts 'N'.")

   ;; ── PAYMENT ─────────────────────────────────────────────────────────────
   ;; PAYMENT_API_KEY and PAYMENT_API_SALT are secrets: on the entity, never in
   ;; the response model.
   (payment-gateway-mode
    :initarg :payment-gateway-mode
    :accessor payment-gateway-mode
    :initform "TEST"
    :documentation "DDL default 'TEST'. Live values are TEST or LIVE.")
   (payment-api-key
    :initarg :payment-api-key
    :accessor payment-api-key
    :initform nil
    :documentation "nullable; a SECRET — excluded from VendorResponseModel.")
   (payment-api-salt
    :initarg :payment-api-salt
    :accessor payment-api-salt
    :initform nil
    :documentation "nullable; a SECRET — excluded from VendorResponseModel.")
   (upi-id
    :initarg :upi-id
    :accessor upi-id
    :initform nil)

   ;; ── STATUS ──────────────────────────────────────────────────────────────
   ;; THE LOGIN CONTRACT: dod-vend-login requires
   ;;   approved_flag='Y' AND approval_status='APPROVED' AND deleted_state='N'
   ;; and matches on PHONE. So an API that writes these flags can lock a vendor
   ;; out of its own login, and none of them belongs in a generic !update —
   ;; approval is its own verb.
   ;;
   ;; The DDL declares every flag below NULLABLE WITH NO DEFAULT, so the values
   ;; here are class choices, not schema defaults. They are the state a newly
   ;; self-registered vendor must be in: not yet approved, not suspended, live.
   ;; approved_flag/approval_status match what the legacy path effectively
   ;; produced (dod-vend-profile declared :void-value "N"/"PENDING").
   (approved-flag
    :initarg :approved-flag
    :accessor approved-flag
    :initform "N"
    :documentation "class choice (DDL default NULL). 'Y' is required to log in.")
   (approval-status
    :initarg :approval-status
    :accessor approval-status
    :initform "PENDING"
    :documentation "class choice (DDL default NULL). Observed live values:
                    APPROVED | PENDING. The legacy :void-value was PENDING.")
   (approved-by
    :initarg :approved-by
    :accessor approved-by
    :initform nil
    :documentation "varchar(30) — the approver's identity, NULL until approved.")
   (active-flag
    :initarg :active-flag
    :accessor active-flag
    :initform "Y"
    :documentation "class choice (DDL default NULL). ALL 15 live rows are 'Y',
                    and NO login rule reads this column — unlike nst-prd, where
                    active_flag was what the :inactive filter wrongly keyed on.")
   (suspend-flag
    :initarg :suspend-flag
    :accessor suspend-flag
    :initform "N"
    :documentation "class choice (DDL default NULL). Not read by the login
                    contract; suspending a vendor is its own verb.")
   ;; deleted-state, tenant-id, created-at and updated-at are INHERITED from
   ;; nst-domain-entity — do not redeclare them. deleted-state's initform there
   ;; is "N", which is this table's intended state; CREATED and UPDATED map onto
   ;; created-at / updated-at, and the DB maintains both timestamps itself.

   ;; ── NOTIFICATIONS ───────────────────────────────────────────────────────
   (push-notify-subs-flag
    :initarg :push-notify-subs-flag
    :accessor push-notify-subs-flag
    :initform "N"
    :documentation "class choice (DDL default NULL). The legacy create-vendor
                    passed \"N\" explicitly.")
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified
    :initform "N"
    :documentation "class choice (DDL default NULL).")

   ;; ── SHIPPING ────────────────────────────────────────────────────────────
   (shipping-enabled
    :initarg :shipping-enabled
    :accessor shipping-enabled
    :initform "N"
    :documentation "DDL default 'N'.")

   ;; ── GST / TAX ───────────────────────────────────────────────────────────
   (gstnumber
    :initarg :gstnumber
    :accessor gstnumber
    :initform nil
    :documentation "varchar(20) — the column name is lower-case in the live
                    table, alone among the columns here.")
   (legal-name
    :initarg :legal-name
    :accessor legal-name
    :initform nil)
   (trade-name
    :initarg :trade-name
    :accessor trade-name
    :initform nil)
   (pan-number
    :initarg :pan-number
    :accessor pan-number
    :initform nil)
   (gst-state-code
    :initarg :gst-state-code
    :accessor gst-state-code
    :initform nil)
   (gst-registration-type
    :initarg :gst-registration-type
    :accessor gst-registration-type
    :initform "REGULAR"
    :documentation "DDL default 'REGULAR'.")
   (gst-filing-frequency
    :initarg :gst-filing-frequency
    :accessor gst-filing-frequency
    :initform "MONTHLY"
    :documentation "DDL default 'MONTHLY'.")
   (fy-start-month
    :initarg :fy-start-month
    :accessor fy-start-month
    :initform 4
    :documentation "tinyint, DDL default 4 (April — the Indian financial year).")

   ;; ── MISC ────────────────────────────────────────────────────────────────
   (invoice-settings
    :initarg :invoice-settings
    :accessor invoice-settings
    :initform nil
    :documentation "TEXT, nullable. dod-vend-profile's :void-value was the
                    string \"undefined\", which is a value the column never
                    holds — NIL is the honest representation of absence.")

   ;; ── TENANT — no initform on purpose: it must fail loudly if a caller
   ;; forgets it (the API injects the session company; the web form passes it).
   (company
    :initarg :company
    :accessor company))

  (:documentation
   "Vendor domain entity. Single-गण, but NOT a single-table entity: the vendor
    surface also spans DOD_VENDOR_TENANTS, DOD_VENDOR_AVAILABILITY_DAY,
    DOD_VPAYMENT_METHODS, DOD_VENDOR_APPOINTMENT and DOD_VENDOR_SETTINGS. This
    class covers DOD_VEND_PROFILE only — the profile slice.

    IDENTITY IS (PHONE, TENANT_ID) and is TENANT-SCOPED (UC_Vendor). So ?exists
    is a genuine two-column identity check here, and a soft-deleted row reserves
    its phone within its own tenant only.

    Every DOD_VEND_PROFILE column this class declares carries an initform, one
    per column, matching the DDL default (or the class choice documented above
    where the DDL has none). Add new columns here WITH their DDL default, or the
    class drifts from the schema again — which is exactly what happened to
    dod-vend-profile."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Boundary models
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass VendorRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object (Tree 2) for vendor operations.

    Deliberately SLOTLESS: carries NO per-field typed slots. All inbound data
    rides in the inherited `params` slot as a transport-shaped plist. The ferry
    (request->dispatch / extract-domain-initargs in nst-bl-adhara.lisp) reads
    (params rm) and MOP-filters that plist against whatever initargs nst-vnd
    actually declares — one universal translator, zero per-entity mapping code.

    row-id and any changed fields travel as plist keys in params, e.g.
    (:row-id 42 :vnd-name \"...\"). :tenant-id and audit keys are stripped by
    extract-domain-initargs and never accepted from a client.

    The domain->response copy is the OUTBOUND leg only; this inbound leg
    intentionally has no typed mirror of nst-vnd."))

(defclass VendorResponseModel (nst-boundary-object)
  ((row-id
    :initarg :row-id
    :accessor row-id)

   ;; IDENTITY
   (vnd-phone
    :initarg :vnd-phone
    :accessor vnd-phone)
   (vnd-name
    :initarg :vnd-name
    :accessor vnd-name)

   ;; PERSON
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (fullname
    :initarg :fullname
    :accessor fullname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (vnd-title
    :initarg :vnd-title
    :accessor vnd-title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)

   ;; ADDRESS
   (vnd-address
    :initarg :vnd-address
    :accessor vnd-address)
   (vnd-city
    :initarg :vnd-city
    :accessor vnd-city)
   (vnd-state
    :initarg :vnd-state
    :accessor vnd-state)
   (vnd-country
    :initarg :vnd-country
    :accessor vnd-country)
   (vnd-zipcode
    :initarg :vnd-zipcode
    :accessor vnd-zipcode)
   (vnd-picture-path
    :initarg :vnd-picture-path
    :accessor vnd-picture-path)

   ;; CONTACT
   (vnd-email
    :initarg :vnd-email
    :accessor vnd-email)

   ;; PAYMENT — mode and UPI id only; the key and salt are SECRETS
   (payment-gateway-mode
    :initarg :payment-gateway-mode
    :accessor payment-gateway-mode)
   (upi-id
    :initarg :upi-id
    :accessor upi-id)

   ;; STATUS
   (approved-flag
    :initarg :approved-flag
    :accessor approved-flag)
   (approval-status
    :initarg :approval-status
    :accessor approval-status)
   (approved-by
    :initarg :approved-by
    :accessor approved-by)
   (active-flag
    :initarg :active-flag
    :accessor active-flag)
   (suspend-flag
    :initarg :suspend-flag
    :accessor suspend-flag)

   ;; NOTIFICATIONS
   (push-notify-subs-flag
    :initarg :push-notify-subs-flag
    :accessor push-notify-subs-flag)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)

   ;; SHIPPING
   (shipping-enabled
    :initarg :shipping-enabled
    :accessor shipping-enabled)

   ;; GST / TAX
   (gstnumber
    :initarg :gstnumber
    :accessor gstnumber)
   (legal-name
    :initarg :legal-name
    :accessor legal-name)
   (trade-name
    :initarg :trade-name
    :accessor trade-name)
   (pan-number
    :initarg :pan-number
    :accessor pan-number)
   (gst-state-code
    :initarg :gst-state-code
    :accessor gst-state-code)
   (gst-registration-type
    :initarg :gst-registration-type
    :accessor gst-registration-type)
   (gst-filing-frequency
    :initarg :gst-filing-frequency
    :accessor gst-filing-frequency)
   (fy-start-month
    :initarg :fy-start-month
    :accessor fy-start-month)

   ;; MISC
   (invoice-settings
    :initarg :invoice-settings
    :accessor invoice-settings))

  (:documentation
   "Outbound boundary object for the vendor profile.

    THIS CLASS IS THE FIELD ALLOWLIST. render-json publishes every slot of the
    response model and nothing else, so exclusion — not a filter in the renderer
    — is what keeps a field off the wire.

    DELIBERATELY ABSENT, and this is a SECURITY boundary, not tidiness:
      password, salt, payment-api-key, payment-api-salt  — credentials.
      username                                            — half of the login
        credential pair; publishing it helps an attacker and no client needs it.
      tenant-id, company                                  — tenant scope. The
        caller already knows its own tenant; echoing it invites confusion and
        is how a leak would be noticed only after the fact.
      deleted-state, created-at, updated-at               — audit; not published,
        matching nst-prd's response model.

    nst-prd could get away with a plain allowlist because it held no secrets.
    A vendor row holds four, so the rule here is stronger: the secret must not
    exist on the response class at all."))
