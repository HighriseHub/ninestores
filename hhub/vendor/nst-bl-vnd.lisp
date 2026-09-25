;;; nst-bl-vnd.lisp — Tier-1 प्रत्यय for nst-vnd (vendor profile)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Shapes follow products/dod-bl-prd.lisp, the newest Tier-1 layer, which in turn
;;; follows warehouse/nst-bl-warehouse.lisp. Every vendor-specific difference is a
;;; consequence of the DOD_VEND_PROFILE schema and is stated where it bites.
;;;
;;; THE ONE STRUCTURAL DIFFERENCE FROM nst-prd, up front: vendor identity is the
;;; TUPLE (PHONE, TENANT_ID) — UC_Vendor — whereas nst-prd's PRODUCT_CODE is one
;;; GLOBAL column. That inverts the ?exists reasoning (see that method) and scopes
;;; the soft-delete identity reservation to a single tenant.
;;;
;;; THREE VENDOR-ONLY DATABASE FACTS, all verified against the live table:
;;;
;;;   1. NO INSERT WAS POSSIBLE AT ALL until USERNAME was added to dod-vend-profile
;;;      (commit 71b8f84's sibling). USERNAME is NOT NULL with no column default,
;;;      the view-class had no slot for it, and the server runs
;;;      STRICT_TRANS_TABLES — so every insert through that class died with
;;;      ERROR 1364 "Field 'USERNAME' doesn't have a default value".
;;;   2. select-vendor-by-id (dod-bl-ven.lisp) IS NOT TENANT-SCOPED. It filters on
;;;      deleted-state and row-id only. The verbs below therefore use their own
;;;      tenant-scoped selectors; reusing the legacy one would be a straight
;;;      OWASP API1:2023 BOLA hole.
;;;   3. THE ROW CARRIES SECRETS — PASSWORD, SALT, PAYMENT_API_KEY,
;;;      PAYMENT_API_SALT. nst-prd could get away with a plain response-model
;;;      allowlist because it held none. Here !update needs a lockout and the
;;;      response model must not declare the fields at all.

(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; copyVendor-domaintodb / copyVendor-dbtodomain
;;;
;;; The two legs of the लोप crossing between nst-vnd (vendor/nst-dal-vnd.lisp) and
;;; the CLSQL view-class dod-vend-profile (vendor/dod-dal-ven.lisp). Source is read
;;; with slot-value, destination written through with-slots — the same shape as
;;; copyProduct-* and copyWarehouse-*.
;;;
;;; DECISION 1 — TENANT COMES FROM THE `company` SLOT, the company OBJECT, not from
;;; the entity's inherited tenant-id. DOD_VEND_PROFILE.TENANT_ID is an FK to
;;; DOD_COMPANY.ROW_ID, and nst-vnd's :company initarg is the slot the web form
;;; passes and the JSON API injects. Reading the object means a missing company
;;; signals instead of silently writing a NULL tenant.
;;;
;;; DECISION 2 — deleted-state IS FORCED TO "N" on the inbound leg. An INSERT is
;;; by definition not a deletion, and DELETED_STATE is nullable with no column
;;; default, so leaving it to the entity would write NULL and every later
;;; [= [:deleted-state] "N"] read would miss the row.
;;;
;;; DECISION 3 — SLOT NAMES DIFFER ON THE TWO SIDES, DELIBERATELY. The domain
;;; class prefixes the ambiguous columns (vnd-name, vnd-phone, vnd-city, …) so
;;; they cannot collide with the legacy accessors of the same natural name in the
;;; shared :nstores package; the view-class uses the plain names. A with-slots on
;;; the destination therefore says `name` and a slot-value on the source says
;;; `vnd-name`. Getting that backwards signals UNBOUND-SLOT, which is the products
;;; file's warning about `prd-company` all over again.
;;;
;;; row-id is deliberately NOT written on the inbound leg — it is AUTO_INCREMENT
;;; and is bound onto the entity afterwards by bind-generated-row-id.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun copyVendor-domaintodb (source destination)
  "nst-vnd → dod-vend-profile. See the header above for decisions 1–3."
  (let ((company (slot-value source 'company)))
    (with-slots (name address phone username email firstname lastname fullname
                 salutation title birthdate city state country zipcode
                 gstnumber picture-path password salt
                 payment-gateway-mode payment-api-key payment-api-salt upi-id
                 active-flag suspend-flag approved-flag approval-status
                 approved-by push-notify-subs-flag email-add-verified
                 shipping-enabled invoice-settings
                 legal-name trade-name pan-number gst-state-code
                 gst-registration-type gst-filing-frequency fy-start-month
                 deleted-state tenant-id)
        destination
      ;; IDENTITY + CREDENTIALS
      (setf phone             (slot-value source 'vnd-phone))
      (setf name              (slot-value source 'vnd-name))
      (setf username          (slot-value source 'username))
      (setf password          (slot-value source 'password))
      (setf salt              (slot-value source 'salt))
      ;; PERSON
      (setf firstname         (slot-value source 'firstname))
      (setf lastname          (slot-value source 'lastname))
      (setf fullname          (slot-value source 'fullname))
      (setf salutation        (slot-value source 'salutation))
      (setf title             (slot-value source 'vnd-title))
      (setf birthdate         (slot-value source 'birthdate))
      ;; ADDRESS + CONTACT
      (setf address           (slot-value source 'vnd-address))
      (setf city              (slot-value source 'vnd-city))
      (setf state             (slot-value source 'vnd-state))
      (setf country           (slot-value source 'vnd-country))
      (setf zipcode           (slot-value source 'vnd-zipcode))
      (setf picture-path      (slot-value source 'vnd-picture-path))
      (setf email             (slot-value source 'vnd-email))
      ;; PAYMENT — the key and salt are secrets; they cross here because the
      ;; INSERT needs them, and nowhere else.
      (setf payment-gateway-mode (slot-value source 'payment-gateway-mode))
      (setf payment-api-key      (slot-value source 'payment-api-key))
      (setf payment-api-salt     (slot-value source 'payment-api-salt))
      (setf upi-id               (slot-value source 'upi-id))
      ;; STATUS
      (setf active-flag       (slot-value source 'active-flag))
      (setf suspend-flag      (slot-value source 'suspend-flag))
      (setf approved-flag     (slot-value source 'approved-flag))
      (setf approval-status   (slot-value source 'approval-status))
      (setf approved-by       (slot-value source 'approved-by))
      ;; NOTIFICATIONS / SHIPPING
      (setf push-notify-subs-flag (slot-value source 'push-notify-subs-flag))
      (setf email-add-verified    (slot-value source 'email-add-verified))
      (setf shipping-enabled      (slot-value source 'shipping-enabled))
      ;; GST / TAX
      (setf gstnumber            (slot-value source 'gstnumber))
      (setf legal-name           (slot-value source 'legal-name))
      (setf trade-name           (slot-value source 'trade-name))
      (setf pan-number           (slot-value source 'pan-number))
      (setf gst-state-code       (slot-value source 'gst-state-code))
      (setf gst-registration-type (slot-value source 'gst-registration-type))
      (setf gst-filing-frequency (slot-value source 'gst-filing-frequency))
      (setf fy-start-month       (slot-value source 'fy-start-month))
      (setf invoice-settings     (slot-value source 'invoice-settings))
      ;; INVARIANTS
      (setf deleted-state     "N")                          ; decision 2
      (setf tenant-id         (slot-value company 'row-id))  ; decision 1
      destination)))

(defun copyVendor-dbtodomain (source destination)
  "dod-vend-profile → nst-vnd. The inbound direction of the crossing.

   Row-id and every business field are copied. TENANT_ID AND COMPANY ARE NOT: the
   caller constructs the nst-vnd with :tenant-id from the domain-ctx (so नियम-1 has
   something to check) and re-attaches the company object itself when a later write
   needs it — because copyVendor-domaintodb derives TENANT_ID from that slot, and an
   entity hydrated here and passed to !update would otherwise write a NIL tenant.

   THE with-slots LIST BELOW IS THE DESTINATION'S SLOT NAMES — nst-vnd's, which are
   the vnd-prefixed ones — while every (slot-value source ...) reads dod-vend-profile's
   PLAIN names. The two sides genuinely differ (see the header, decision 3), and
   getting this list wrong is not a style problem: a name in the list that the
   destination does not have makes the matching (setf ...) a FREE VARIABLE. It
   compiles, because CL only warns, and dies at runtime. The trap is that the names
   which happen to coincide on both sides (firstname, password, gstnumber) keep
   working, so a partial mismatch looks fine until the vnd- prefixed fields are
   touched."
  (with-slots (row-id vnd-phone vnd-name username password salt
               firstname lastname fullname salutation vnd-title birthdate
               vnd-address vnd-city vnd-state vnd-country vnd-zipcode
               vnd-picture-path vnd-email
               payment-gateway-mode payment-api-key payment-api-salt upi-id
               active-flag suspend-flag approved-flag approval-status approved-by
               push-notify-subs-flag email-add-verified shipping-enabled
               gstnumber legal-name trade-name pan-number gst-state-code
               gst-registration-type gst-filing-frequency fy-start-month
               invoice-settings)
      destination
    (setf row-id            (slot-value source 'row-id))
    ;; IDENTITY + CREDENTIALS. password/salt ARE copied onto the domain entity —
    ;; they must be, or a hydration followed by a write would blank them. They are
    ;; kept off the wire by the RESPONSE MODEL, not by hiding them from the domain.
    (setf vnd-phone         (slot-value source 'phone))
    (setf vnd-name          (slot-value source 'name))
    (setf username          (slot-value source 'username))
    (setf password          (slot-value source 'password))
    (setf salt              (slot-value source 'salt))
    ;; PERSON
    (setf firstname         (slot-value source 'firstname))
    (setf lastname          (slot-value source 'lastname))
    (setf fullname          (slot-value source 'fullname))
    (setf salutation        (slot-value source 'salutation))
    (setf vnd-title         (slot-value source 'title))
    (setf birthdate         (slot-value source 'birthdate))
    ;; ADDRESS + CONTACT
    (setf vnd-address       (slot-value source 'address))
    (setf vnd-city          (slot-value source 'city))
    (setf vnd-state         (slot-value source 'state))
    (setf vnd-country       (slot-value source 'country))
    (setf vnd-zipcode       (slot-value source 'zipcode))
    (setf vnd-picture-path  (slot-value source 'picture-path))
    (setf vnd-email         (slot-value source 'email))
    ;; PAYMENT
    (setf payment-gateway-mode (slot-value source 'payment-gateway-mode))
    (setf payment-api-key      (slot-value source 'payment-api-key))
    (setf payment-api-salt     (slot-value source 'payment-api-salt))
    (setf upi-id               (slot-value source 'upi-id))
    ;; STATUS
    (setf active-flag       (slot-value source 'active-flag))
    (setf suspend-flag      (slot-value source 'suspend-flag))
    (setf approved-flag     (slot-value source 'approved-flag))
    (setf approval-status   (slot-value source 'approval-status))
    (setf approved-by       (slot-value source 'approved-by))
    ;; NOTIFICATIONS / SHIPPING
    (setf push-notify-subs-flag (slot-value source 'push-notify-subs-flag))
    (setf email-add-verified    (slot-value source 'email-add-verified))
    (setf shipping-enabled      (slot-value source 'shipping-enabled))
    ;; GST / TAX
    (setf gstnumber            (slot-value source 'gstnumber))
    (setf legal-name           (slot-value source 'legal-name))
    (setf trade-name           (slot-value source 'trade-name))
    (setf pan-number           (slot-value source 'pan-number))
    (setf gst-state-code       (slot-value source 'gst-state-code))
    (setf gst-registration-type (slot-value source 'gst-registration-type))
    (setf gst-filing-frequency (slot-value source 'gst-filing-frequency))
    (setf fy-start-month       (slot-value source 'fy-start-month))
    (setf invoice-settings     (slot-value source 'invoice-settings))
    destination))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; A condition for a malformed request — the 4xx the taxonomy cannot yet express
;;;
;;; WHY THIS EXISTS AT ALL, given that products deliberately left required-field
;;; enforcement to the database ("refused by the database with the column named,
;;; which is the honest place for that rule"). It cannot be left there for vendors,
;;; because the refusal happens INSIDE with-nst-db-create, whose catch-all turns any
;;; error into :U — and :U maps to 503. A create missing a NOT NULL field is a
;;; permanent client error; answering 503 tells the client "unknown, try again" for
;;; something that will never succeed. Refusing before the call at least fails
;;; loudly and names the field.
;;;
;;; KNOWN WART, recorded rather than hidden: under the current error taxonomy
;;; (products/nst-bl-prdapi-CONTEXT.md §7.3) a signalled condition still leaves the
;;; API as a 500, not a 400. This must be mapped in the route/API layer; it is the
;;; same fix that covers validate-sort-args in the warehouse. Until then a 500 is a
;;; strictly better answer than a 503 — and neither is right.
;;; ═══════════════════════════════════════════════════════════════════════════

(define-condition vendor-required-field-missing (error)
  ((field :initarg :field :reader vendor-required-field-missing-field)
   (why   :initarg :why   :reader vendor-required-field-missing-why))
  (:report (lambda (condition stream)
             (format stream "nst-vnd: required field ~A is missing — ~A. This is a malformed request, not an unknown outcome; it must not be reported as 503."
                     (vendor-required-field-missing-field condition)
                     (vendor-required-field-missing-why condition)))))

(defparameter *vendor-required-create-fields*
  '((:vnd-name   . "NAME is NOT NULL with no column default")
    (:vnd-address . "ADDRESS is NOT NULL with no column default")
    (:vnd-phone  . "PHONE is NOT NULL, and is half of UC_Vendor (with TENANT_ID) — it is the identity ?exists checks")
    (:password   . "PASSWORD is NOT NULL with no column default; the stored value is a salted hash, never plaintext"))
  "The client-supplied NOT NULL columns with no database default. USERNAME is
   deliberately ABSENT: it is NOT NULL too, but it is in no unique key and the
   login path matches PHONE, so make derives it rather than demanding it — see
   vendor-username-for. TENANT_ID is likewise absent: it comes from the session
   (नियम-1), never from the caller.")

(defun vendor-required-create-fields-missing (initargs)
  "Returns the subset of *vendor-required-create-fields* the caller did not supply
   with a NON-NIL value. An explicit :vnd-name nil is as absent as no key at all —
   nil is not a value this schema can store for any of them."
  (loop for (field . why) in *vendor-required-create-fields*
        unless (getf initargs field)
          collect (cons field why)))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Tier-1 प्रत्यय for nst-vnd — ?exists (प्रत्यभिज्ञा) and make (सृजन)
;;; ═══════════════════════════════════════════════════════════════════════════

(defun select-vendor-by-phone-in-tenant (phone tenant-id &key include-deleted)
  "Lookup by (PHONE, TENANT_ID) — the tuple UC_Vendor enforces, and the ONLY
   unique key on DOD_VEND_PROFILE besides the primary key.

   TENANT-SCOPED, mirroring the key exactly. This is the INVERSE of
   select-product-by-code, which had to be global because PRODUCT_CODE's index is
   global: there, a tenant-scoped pre-check would answer 'free' in precisely the
   case where the INSERT was about to fail, so the pre-check predicted the wrong
   thing. Here the index itself includes TENANT_ID, so the pre-check predicts the
   INSERT correctly and ?exists can honestly say 'taken in THIS tenant' — which is
   actionable, because the same phone is free in another tenant.

   :INCLUDE-DELETED T returns the row whatever its DELETED_STATE, which is what
   makes the soft-delete contradiction detectable — see ?exists.

   Returns ONE ROW OR NIL, like every other by-identity selector in this tree: the
   CAR is taken here. That is not cosmetic. with-db-call hands its payload to
   ?exists, which reads a SLOT off it, so returning the raw clsql:select list made
   ?exists call slot-value on a CONS and turned the intended 409 into a 500 in the
   products twin."
  (car (if include-deleted
           (clsql:select 'dod-vend-profile
                         :where [and [= [:phone] phone]
                                     [= [:tenant-id] tenant-id]]
                         :caching *dod-database-caching* :flatp t)
           ;; The [= [:deleted-state] "N"] reading relies on the view-class's
           ;; :void-value "N", which is how this schema's nullable char(1) flags are
           ;; mapped (NULL ↔ "N") — the convention every selector here uses.
           (clsql:select 'dod-vend-profile
                         :where [and [= [:deleted-state] "N"]
                                     [= [:phone] phone]
                                     [= [:tenant-id] tenant-id]]
                         :caching *dod-database-caching* :flatp t))))

(defmethod ?exists ((entity-class (eql 'nst-vnd)) (phone string) (ctx domain-ctx)
                    &key &allow-other-keys)
  "Is the vendor identity (PHONE, TENANT) already taken?

   A Belnap answer, because the honest answer is not yes/no:
     :F  free IN THIS TENANT — nothing holds the phone here and creation may proceed
     :T  a LIVE vendor holds it here (a plain fact of existence)
     :C  a SOFT-DELETED row holds it HERE. UC_Vendor includes no DELETED_STATE, so
         the row still occupies the phone while नियम-2 makes DELETED_STATE='Y' rows
         invisible to every verb — 'the phone is taken' and 'no vendor is there' are
         both true at once. Callers must escalate to a human.
     :U  the database could not be consulted — which is NOT 'probably free'.

   THE TENANT COMES FROM ctx, NEVER FROM A KEYWORD. ?exists carries
   &key &allow-other-keys for CLOS congruence with adhara's generic function, and
   nst-whs genuinely uses it (its key is the tuple GSTIN + WNAME + tenant, so it
   declares &key WNAME). Here the extra half of the identity is the TENANT, and
   accepting it from the caller would let a client probe another tenant's phone
   numbers — the ?exists form of the BOLA the fetch verbs already refuse. The
   keyword is therefore accepted and IGNORED, deliberately; the session tenant from
   ctx always wins."
  (declare (ignore entity-class))
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (let ((knowledge (with-db-call
                         (select-vendor-by-phone-in-tenant phone tenant-id
                                                           :include-deleted t)
                       "nst-vnd/?exists (phone, tenant, deleted rows included)")))
      (cond
        ;; Free, unknown, or the (impossible under a unique key) multi-row :C — pass
        ;; through whatever the database reported.
        ((not (eq (bo-knowledge-truth knowledge) :T)) knowledge)
        ;; dod-vend-profile declares no accessor for deleted-state (only a slot), so
        ;; read the slot rather than an accessor of the same name.
        ((string= (slot-value (bo-knowledge-payload knowledge) 'deleted-state) "Y")
         ;; Identity held by a row the domain considers gone: :T (it is there) ⊔ :F
         ;; (no vendor there) = :C, provenance recording which two rules collided.
         (bo-merge knowledge
                   (make-bo-knowledge
                    :truth :F
                    :payload nil
                    :provenance "नियम-2: DELETED_STATE='Y' rows are invisible to every verb")))
        (t knowledge)))))

(defun vendor-username-for (initargs)
  "USERNAME is NOT NULL with no column default, is in NO unique key, and the login
   path matches PHONE — so nothing in the schema gives it meaning, and demanding it
   from an API client would be ceremony. A caller that supplies one keeps it; a
   caller that does not gets the phone value, which is the identifier the platform
   actually authenticates by. This is a CLASS/verb choice, documented because the
   column's NOT NULL makes some value mandatory and silence would be the wrong one."
  (or (getf initargs :username)
      (getf initargs :vnd-phone)))

(defmethod make :around ((entity-class (eql 'nst-vnd)) (ctx domain-ctx) &rest initargs)
  "Refuse BEFORE the INSERT is attempted. Only a CONFIRMED-FREE identity passes:
   :U is not 'probably free', and :C is a question for a human.

   An :around method rather than a :before, for the reason recorded in the products
   and warehouse twins: a :before method cannot return a value, so raising was its
   only way to refuse, and every refusal reached the boundary as a 500 —
   indistinguishable from a crash and from 'not found'. An :around can return, so
   the check answers in the domain's own four values:

     ?exists :F → confirmed free in this tenant → proceed with the INSERT
     ?exists :T → a LIVE vendor holds the phone   → contradiction → 409
     ?exists :C → a SOFT-DELETED vendor holds it  → contradiction → 409
     ?exists :U → could not check                 → unknown       → 503

   Skips silently when no :vnd-phone was supplied, because the required-field guard
   in the primary method reports that case with a named field instead."
  (let ((phone (getf initargs :vnd-phone)))
    (if (null phone)
        (call-next-method)
        (let ((check (?exists 'nst-vnd phone ctx)))
          (case (bo-knowledge-truth check)
            (:F (call-next-method))              ; confirmed free — proceed
            (:T (make-instance 'nst-entity-contradiction
                               :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                               :reason (format nil "Vendor phone ~A: a LIVE vendor already holds this number in this tenant (UC_Vendor = UNIQUE(PHONE, TENANT_ID)). The create contradicts existing state, so it is neither done nor impossible." phone)))
            (otherwise
             (domain-sentinel-from-knowledge
              check ctx
              :reason (lambda (truth)
                        (case truth
                          (:C (format nil "Vendor phone ~A is held in this tenant by a SOFT-DELETED vendor: the row is still in DOD_VEND_PROFILE and UC_Vendor includes no DELETED_STATE, while नियम-2 makes such a row invisible to every verb. Human decision needed: undelete that vendor, or register this one under a different number." phone))
                          (otherwise (format nil "Vendor phone ~A: the uniqueness check did not come back free" phone)))))))))))

(defmethod make ((entity-class (eql 'nst-vnd)) (ctx domain-ctx) &rest initargs)
  "सृजन प्रत्यय — register one vendor.

   कारक: the tenant comes from ctx alone (नियम-1), passed as the INTEGER row-id,
   because check-niyam compares (tenant-id entity) against
   (slot-value (domain-ctx-tenant ctx) 'row-id), and only two integers can be
   equal. The company OBJECT is still needed for a different job: it is what
   copyVendor-domaintodb turns into the row's TENANT_ID.

   THE company SLOT IS SET UNCONDITIONALLY FROM ctx. extract-domain-initargs does
   NOT strip :company — it is not in adhara's *reserved-initargs* — so a caller that
   supplies :company would otherwise have its value survive into the copier, which
   derives TENANT_ID from that slot. That is a tenant escape (create a vendor in
   another tenant), and `unless` was the wrong guard in the products twin. The
   products routes carry no :inject-company for exactly this reason.

   CREDENTIAL NOTE, stated because it is a design decision and not an accident:
   PASSWORD is required from the caller, so an API create SETS THE VENDOR'S LOGIN
   CREDENTIAL. That is a privileged act, and whatever credential the route layer
   authenticates decides who may perform it. It is not this verb's business to
   guess — but it is this verb's business to say so."
  (declare (ignore entity-class))
  (let ((missing (vendor-required-create-fields-missing initargs)))
    (when missing
      ;; Report the FIRST missing field, with its own reason, rather than a list —
      ;; a client fixing one field at a time gets a stable, actionable message.
      (error 'vendor-required-field-missing
             :field (caar missing)
             :why (cdar missing))))
  (let* ((company (domain-ctx-tenant ctx))
         (entity (apply #'make-instance 'nst-vnd
                        :tenant-id (slot-value company 'row-id)
                        initargs))
         (dbobj (make-instance 'dod-vend-profile)))
    (setf (company entity) company)
    ;; IDENTITY — USERNAME is NOT NULL with no column default and no unique key;
    ;; derived rather than demanded. See vendor-username-for.
    (unless (username entity) (setf (username entity) (vendor-username-for initargs)))
    ;; LIFECYCLE. Each default applies only when the caller said nothing, so an
    ;; explicit active-flag "N" is preserved. The class initforms already carry
    ;; these, so this is belt-and-braces for a caller that passes an explicit NIL —
    ;; and it is the place a future registration workflow would hook.
    (unless (active-flag entity)     (setf (active-flag entity) "Y"))
    (unless (approved-flag entity)   (setf (approved-flag entity) "N"))
    (unless (approval-status entity) (setf (approval-status entity) "PENDING"))
    (unless (suspend-flag entity)    (setf (suspend-flag entity) "N"))
    (copyVendor-domaintodb entity dbobj)
    (let ((knowledge (with-nst-db-create (:source "nst-vnd/make")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
            entity)
        (:F ;; The unique key rejected the row: the phone was taken between the
            ;; :around check and this INSERT — a lost race, not a client mistake.
            ;; Same domain fact as the :T case there → the same answer: :C → 409.
            (make-instance 'nst-entity-contradiction
                           :tenant-id (slot-value company 'row-id)
                           :reason (format nil "Vendor phone ~A rejected at the database — UC_Vendor already holds it in this tenant (uniqueness race lost after the :around check passed)." (vnd-phone entity))))
        (:U ;; The boundary failed: NOT a refusal, and we do not know whether the row
            ;; was written. → 503, never 404 and never a misleading 500.
            (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Vendor create: the database call did not answer — the row may or may not have been written, so this is unknown, not failed"))
        (:C ;; Unreachable without a :pre-flight form, which this call does not
            ;; supply — a programming error if it ever appears.
            (error "Unreachable: no :pre-flight form was supplied to with-nst-db-create in this call — a :C here means the macro contract changed without this method being updated"))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                          (bo-knowledge-truth knowledge)))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Tier-1 प्रत्यय for nst-vnd — fetch (स्मरण), !update (!state), delete! (लोप)
;;; ═══════════════════════════════════════════════════════════════════════════

(defun vendor-row-id-from-string (id)
  "Row-ids arrive as STRINGS: apidefs2 passes path params through unchanged, and
   every id crosses the API boundary as a JSON string. Returns the integer row-id,
   or NIL when the string cannot address a row at all — a caller asking for
   /vendors/abc is asking for something that cannot exist, which is a not-found
   fact (:F), not a 500."
  (when (stringp id)
    (handler-case (parse-integer id :junk-allowed nil)
      (error () nil))))

(defun select-vendor-by-id-in-tenant (row-id tenant-id)
  "Row-id lookup WITHIN A TENANT.

   NOT select-vendor-by-id (dod-bl-ven.lisp) — that one filters on deleted-state and
   row-id ONLY and is not tenant-scoped, so using it here would let a session in
   tenant 2 read tenant 1's vendor by guessing its row-id. That is OWASP API1:2023
   BOLA, and it is a pre-existing hole in the legacy layer, not one this file may
   inherit. Filtering DELETED_STATE='N' also makes 'soft-deleted' and 'never
   existed' deliberately indistinguishable — see delete!."
  (car (clsql:select 'dod-vend-profile
                     :where [and [= [:deleted-state] "N"]
                                 [= [:row-id] row-id]
                                 [= [:tenant-id] tenant-id]]
                     :caching *dod-database-caching* :flatp t)))

(defmethod fetch ((entity-class (eql 'nst-vnd)) (id string) (ctx domain-ctx))
  "स्मरण प्रत्यय — recall one vendor by row-id, WITHIN THE SESSION TENANT.

   select-vendor-by-id-in-tenant is tenant-scoped, so another tenant's row-id
   produces exactly the same answer as a row-id that does not exist: nst-entity-nil.
   The id in the URL is an ADDRESS, never an authorization.

   Returns a real nst-vnd or a Belnap sentinel — never a bare CL nil (adhara §6's
   fetch contract)."
  (declare (ignore entity-class))
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (row-id (vendor-row-id-from-string id)))
    (if (null row-id)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a vendor row (row-ids are integers)" id))
        (let ((knowledge (with-db-call (select-vendor-by-id-in-tenant row-id tenant-id)
                                       "nst-vnd/fetch (row-id, session tenant)")))
          ;; ONE conversion, in adhara — not a hand-rolled case per verb.
          (domain-result-from-knowledge
           knowledge ctx
           :hydrate (lambda (dbobj)
                      (let ((entity (make-instance 'nst-vnd :tenant-id tenant-id)))
                        (copyVendor-dbtodomain dbobj entity)
                        ;; The company object is not part of the row, and
                        ;; copyVendor-domaintodb derives the written TENANT_ID from
                        ;; it — an entity hydrated here and handed to !update would
                        ;; otherwise write a NIL tenant.
                        (setf (company entity) company)
                        entity))
           :reason (lambda (truth)
                     (case truth
                       (:F (format nil "Vendor row-id ~A not found in this tenant" row-id))
                       (:U (format nil "Vendor row-id ~A: the database call did not answer — whether the row exists is unknown" row-id))
                       (:C (format nil "Vendor row-id ~A returned more than one row — the primary key is not holding" row-id)))))))))

(defparameter *vendor-update-forbidden-fields*
  '(:password :salt :payment-api-key :payment-api-salt)
  "Initargs !update REFUSES. These are the four secret-bearing columns on the row.

   WHY REFUSE RATHER THAN SILENTLY DROP THEM. Stripping them is what the products
   verb does with :row-id, and there it is right — a row-id in the body is an
   address the caller cannot usefully lie about. A dropped :password is different:
   the client would believe it rotated a credential that was never touched. Failing
   closed is the only honest option, and credential rotation belongs to its own verb
   with its own authorization, not to a generic field update.

   Note this is a POLICY list about the TRANSPORT (what an API client may set), not
   about the domain — the copiers move all four fields, because the INSERT needs
   them. The domain entity is allowed to carry secrets; the update verb is not
   allowed to accept them from outside.")

(defmethod !update ((entity-class (eql 'nst-vnd)) (row-id string) (ctx domain-ctx)
                    &rest update-args)
  "!state प्रत्यय — partial update by row-id. Only the initargs actually supplied
   change (CLOS reinitialize-instance), so an omitted field keeps its stored value:
   the entity is hydrated from the row BEFORE the new values are applied, and the
   whole instance is written back.

   No :pre-flight is passed to with-nst-db-update because existence was already
   established by the SELECT below.

   :row-id is stripped from UPDATE-ARGS: it is the ADDRESS of the कर्म, not a field
   of it, and the UPDATE always targets the row the SELECT returned anyway.

   SECRETS ARE REFUSED — see *vendor-update-forbidden-fields*. This verb also writes
   the APPROVAL and SUSPEND flags, which the login contract reads
   (approved_flag='Y' AND approval_status='APPROVED' AND deleted_state='N'), so a
   caller using !update can lock a vendor out of its own login. That is a real
   authorization question for the route layer, and it is stated here rather than
   hidden: approval and suspension belong to their own verbs with a company-admin
   credential, and until those exist this verb is reachable only by whatever the
   binding authorizes."
  (declare (ignore entity-class))
  ;; Checked BEFORE the SELECT: a request carrying a forbidden field is malformed
  ;; regardless of whether the row exists, and telling the client about the field
  ;; beats telling it about a 404 it would then fix the wrong thing about.
  (dolist (field *vendor-update-forbidden-fields*)
    (when (getf update-args field)
      (error 'vendor-required-field-missing
             :field field
             :why "this field is a credential and may not be set through !update; credential rotation is its own verb with its own authorization")))
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (rid (vendor-row-id-from-string row-id)))
    (if (null rid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a vendor row (row-ids are integers)" row-id))
        (let ((dbobj (select-vendor-by-id-in-tenant rid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Vendor row-id ~A not found in this tenant (or already deleted)" row-id))
              (let ((entity (make-instance 'nst-vnd :tenant-id tenant-id)))
                (copyVendor-dbtodomain dbobj entity)     ; current stored state
                (setf (company entity) company)
                (let ((args (copy-list update-args)))
                  (remf args :row-id)
                  (apply #'reinitialize-instance entity args))  ; only supplied keys change
                ;; Same कारक rule as make: a caller-supplied :company must not be able
                ;; to move an EXISTING row to another tenant. Re-set AFTER the
                ;; reinitialize so the session company always wins.
                (setf (company entity) company)
                ;; NOTE: the copier forces DELETED_STATE to "N" on the way out.
                ;; Harmless here — select-vendor-by-id-in-tenant filters deleted rows,
                ;; so a deleted target never reaches this point (it answered :F above)
                ;; — but do not reuse copyVendor-domaintodb on a row you intend to
                ;; keep deleted.
                (copyVendor-domaintodb entity dbobj)
                (let ((knowledge (with-nst-db-update (:source "nst-vnd/!update")
                                    (clsql:update-records-from-instance dbobj)
                                    dbobj)))
                  (case (bo-knowledge-truth knowledge)
                    (:T entity)
                    (:U ;; The write did not complete and the row's state is unknown →
                        ;; 503, not a 500 and NOT 404: the vendor exists, we simply
                        ;; cannot report what happened to it.
                        (domain-sentinel-from-knowledge
                         knowledge ctx
                         :reason (format nil "Vendor update, row-id ~A: the database call did not answer — the row's current state is unknown" row-id)))
                    (:F ;; Unreachable: with-nst-db-update was called without
                        ;; :pre-flight, and the row was already confirmed by the SELECT.
                        (error "Unreachable: with-nst-db-update without :pre-flight cannot return :F (row-id ~A)" row-id))
                    (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-update"
                                      (bo-knowledge-truth knowledge)))))))))))

(defmethod delete! ((entity-class (eql 'nst-vnd)) (row-id string) (ctx domain-ctx))
  "लोप प्रत्यय — SOFT delete: DELETED_STATE set to \"Y\", the row kept.

   THE IDENTITY RESERVATION IS PER-TENANT, and that is the difference from products.
   UC_Vendor is UNIQUE(PHONE, TENANT_ID), so a soft-deleted vendor keeps its phone
   reserved WITHIN ITS OWN TENANT only; the same number is free in every other
   tenant and may be registered there. For nst-prd the reservation was global and
   permanent, because PRODUCT_CODE's index is. Re-creating the phone in the same
   tenant is therefore not 'free' but a contradiction: ?exists reports :C and make's
   :around refuses. That is designed, not an accident of the delete.

   select-vendor-by-id-in-tenant filters deleted rows, so 'already deleted' and
   'never existed' are indistinguishable here and share one :F answer; the reason
   string names both rather than claiming to know which.

   Returns T on success — the same ack every delete! in this tree returns. Over the
   JSON API conflodis2 encodes a non-response value, so this reaches the client as
   the literal body `true`; a richer ack is a route/API-layer decision.

   deleted-state is read and written through SLOT-VALUE: dod-vend-profile declares
   no accessor for that column."
  (declare (ignore entity-class))
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (rid (vendor-row-id-from-string row-id)))
    (if (null rid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a vendor row (row-ids are integers)" row-id))
        (let ((dbobj (select-vendor-by-id-in-tenant rid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Vendor row-id ~A not found in this tenant (or already deleted)" row-id))
              (let ((knowledge (with-nst-db-delete (:source "nst-vnd/delete!")
                                  (setf (slot-value dbobj 'deleted-state) "Y")
                                  (clsql:update-record-from-slot dbobj 'deleted-state)
                                  dbobj)))
                (case (bo-knowledge-truth knowledge)
                  (:T t)
                  (:U ;; The soft-delete did not complete and we cannot say whether the
                      ;; row was touched → 503 (unknown), not a 500 — which is
                      ;; indistinguishable from a crash and from "no such vendor".
                      (domain-sentinel-from-knowledge
                       knowledge ctx
                       :reason (format nil "Vendor delete, row-id ~A: the database call did not answer — whether the row was soft-deleted is unknown" row-id)))
                  (:F ;; Unreachable: with-nst-db-delete was called without :pre-flight.
                      (error "Unreachable: with-nst-db-delete without :pre-flight cannot return :F (row-id ~A)" row-id))
                  (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-delete"
                                    (bo-knowledge-truth knowledge))))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Tier-1 प्रत्यय for nst-vnd — enumerate (दर्शन)
;;;
;;; नियम-1 applies to the SCOPE filter (WHERE TENANT_ID = ctx.tenant); a per-row
;;; check would be redundant once the query itself is tenant-scoped, and adhara's
;;; own enumerate docstring says so.
;;;
;;; WHY NEW SQL RATHER THAN THE LEGACY SELECTORS. None of them can serve this list:
;;;   * select-vendors-for-company   is DELETED_STATE='N' + tenant only — no status
;;;     filter at all;
;;;   * get-vendors-for-approval     is hard-wired to approved_flag='N' AND
;;;     active_flag='Y' AND approval_status='PENDING', so it answers one question;
;;;   * select-vendor-by-id          is not tenant-scoped (see fetch);
;;;   * select-vendors-by-name       has no pagination and no sort control.
;;;
;;; THE STATUS VOCABULARY, read off the data rather than the old spec. A grouping of
;;; all 15 live rows (2026-09-13):
;;;
;;;   active_flag approved_flag approval_status suspend deleted rows
;;;      Y            Y            APPROVED          N       N     14
;;;      Y            Y            PENDING           N       N      1
;;;
;;; Three facts follow, and each changes what 'status' can honestly mean:
;;;   1. Every row is active_flag='Y' AND suspend_flag='N' AND deleted_state='N', so
;;;      'inactive' and 'suspended' match NOTHING today. Both are implemented anyway
;;;      — the columns exist and deactivation and suspension are real workflows — but
;;;      a client filtering on them should expect zero rows rather than conclude the
;;;      filter is broken. (Products has the identical situation with :inactive.)
;;;   2. only two approval_status values appear, APPROVED and PENDING. REJECTED is
;;;      still accepted as a status because the column can hold it and products'
;;;      table already carries one; refusing it would make a future rejection
;;;      unfilterable.
;;;   3. 'active' MEANS LISTED AND USABLE — active_flag AND approved_flag AND NOT
;;;      suspended — which is the predicate the login contract approximates
;;;      (approved_flag='Y' AND approval_status='APPROVED' AND deleted_state='N').
;;;      The two are deliberately not identical: this one is about listing, that one
;;;      is about authenticating, and approval_status is not consulted here because
;;;      approved_flag already carries the decision.
;;;
;;; NULL HANDLING — a latent trap, currently dormant, same as products. These flag
;;; columns are nullable with NO column default, so a future row written outside
;;; this code could carry a real NULL. Every predicate below compares literally, and
;;; the view-class maps a NULL to its :void-value — so a NULL would silently fail
;;; the predicate rather than error. The live table has ZERO NULLs in all five
;;; columns (verified); check the column before trusting a count.
;;; ═══════════════════════════════════════════════════════════════════════════

(defparameter *vnd-sort-whitelist*
  '((:row-id          . :row-id)
    (:name            . :name)
    (:phone           . :phone)
    (:city            . :city)
    (:approval-status . :approval-status))
  "The ONLY columns enumerate may sort by. sort-by is caller-controllable (it comes
   from a query string over HTTP), and this whitelist is what stands between that and
   arbitrary ORDER BY construction. Extend deliberately, one line at a time; never
   accept a raw column name from outside this list.

   NOTE the name: *whs-sort-whitelist* and *prd-sort-whitelist* already exist, and
   validate-sort-args reads the warehouse's directly. Reusing either name here would
   silently redefine another entity's sort validation — hence the vnd- prefix.")

(defun validate-vendor-sort-args (sort-by sort-dir)
  "Resolves (sort-by, sort-dir) against *vnd-sort-whitelist*, or signals."
  (let ((col (cdr (assoc sort-by *vnd-sort-whitelist*))))
    (unless col
      (error "enumerate: sort-by ~A not in whitelist ~A" sort-by *vnd-sort-whitelist*))
    (unless (member sort-dir '(:asc :desc))
      (error "enumerate: sort-dir must be :asc or :desc, got ~A" sort-dir))
    (values col sort-dir)))

(defun vnd-status-arg (value)
  "Query strings arrive as STRINGS, keywords come from internal callers. Returns a
   keyword, or NIL for 'no filter'."
  (cond ((null value) nil)
        ((keywordp value) value)
        ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
        ((stringp value) (intern (string-upcase value) :keyword))
        (t (error "enumerate: unusable status ~S" value))))

(defun vnd-status-clause (status)
  "Maps a status keyword to its WHERE clause. An UNKNOWN status signals rather than
   being dropped: silently ignoring a filter the caller asked for is how
   '?is-primary-location=0' ended up meaning the opposite of itself in the warehouse
   API (see nst-bl-apidefs2-CONTEXT.md §9.6)."
  (case status
    (:active    [and [= [:active-flag] "Y"]
                     [= [:approved-flag] "Y"]
                     [= [:suspend-flag] "N"]])
    (:inactive  [= [:active-flag] "N"])
    (:suspended [= [:suspend-flag] "Y"])
    (:pending   [= [:approval-status] "PENDING"])
    (:rejected  [= [:approval-status] "REJECTED"])
    (otherwise (error "enumerate: unknown status ~S — expected one of :active :inactive :suspended :pending :rejected"
                      status))))

(defun build-vendor-filter-clauses (tenant-id &key status approval-status
                                                  name-like city gst-number)
  "Assembles the WHERE clauses for a vendor list.
   DELETED_STATE = 'N' is FIXED, not a keyword: adhara's नियम-2 makes a deleted row
   invisible to every verb, so a verb that could opt out of this clause would be able
   to read back what it just deleted."
  (let ((clauses (list [= [:tenant-id] tenant-id]
                       [= [:deleted-state] "N"])))
    (when status          (push (vnd-status-clause status) clauses))
    (when approval-status (push [= [:approval-status] (string-upcase (string approval-status))] clauses))
    (when (and name-like (stringp name-like) (plusp (length (string-trim " " name-like))))
      ;; escape-like-wildcards lives in core/dod-bl-utl.lisp (asd line 62), which
      ;; loads BEFORE this file, so it resolves at compile time. Reused rather than
      ;; copied so the LIKE-escaping rule keeps ONE implementation.
      (push [like [:name] (format nil "%~A%" (escape-like-wildcards name-like))] clauses))
    (when (and city (stringp city) (plusp (length (string-trim " " city))))
      (push [like [:city] (format nil "%~A%" (escape-like-wildcards city))] clauses))
    ;; gstnumber is EXACT, not LIKE: it is an identifier, and a prefix match on a
    ;; tax id is a query nobody wants and a full scan everybody pays for.
    (when (and gst-number (stringp gst-number) (plusp (length (string-trim " " gst-number))))
      (push [= [:gstnumber] (string-trim " " gst-number)] clauses))
    clauses))

(defun select-vendors-by-filter (tenant-id &key status approval-status name-like
                                              city gst-number
                                              (sort-by :row-id) (sort-dir :desc)
                                              limit offset)
  "One filtered vendor SELECT. sort-by/sort-dir are validated, never interpolated."
  (multiple-value-bind (sort-col sort-dir) (validate-vendor-sort-args sort-by sort-dir)
    ;; MySQL requires a LIMIT for OFFSET to mean anything; refusing loudly beats
    ;; returning page 1 forever.
    (when (and offset (null limit))
      (error "enumerate: :offset ~A given without :limit — MySQL cannot express an offset on its own" offset))
    (apply #'clsql:select 'dod-vend-profile
                          :where (apply #'clsql:sql-and
                                        (build-vendor-filter-clauses
                                         tenant-id :status status
                                                   :approval-status approval-status
                                                   :name-like name-like
                                                   :city city
                                                   :gst-number gst-number))
                          :order-by (list (list sort-col sort-dir))
                          :caching *dod-database-caching* :flatp t
                          (append (when limit  (list :limit limit))
                                  (when offset (list :offset offset))))))

(defmethod enumerate ((entity-class (eql 'nst-vnd)) (ctx domain-ctx)
                      &key status approval-status name-like city gst-number
                           (sort-by :row-id) (sort-dir :desc) limit offset)
  "दर्शन प्रत्यय — the tenant's vendors, filtered.

   Returns a LIST of nst-vnd, or the EMPTY LIST when nothing matches. An empty list is
   a successful empty result, not a not-found fact: apidefs2 renders it as 200 [] and
   reserves 404 for a sentinel."
  (declare (ignore entity-class))
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (knowledge (with-nst-db-read-all
                        (:source "nst-vnd/enumerate"
                         :pk-extractor (lambda (d) (slot-value d 'row-id)))
                      (select-vendors-by-filter
                       tenant-id
                       :status (vnd-status-arg status)
                       :approval-status approval-status
                       :name-like name-like :city city :gst-number gst-number
                       :sort-by sort-by :sort-dir sort-dir
                       :limit limit :offset offset))))
    (case (bo-knowledge-truth knowledge)
      (:T (mapcar (lambda (dbobj)
                    (let ((entity (make-instance 'nst-vnd :tenant-id tenant-id)))
                      (copyVendor-dbtodomain dbobj entity)
                      ;; Same reason as fetch: the company object is not part of the
                      ;; row, and copyVendor-domaintodb derives the written TENANT_ID
                      ;; from it.
                      (setf (company entity) company)
                      entity))
                  (bo-knowledge-payload knowledge)))
      (:F '())                                  ; empty list — a success, not 404
      (:U ;; The list could not be read → 503. NOTE the type change: enumerate normally
          ;; returns a LIST, so a caller must inspect the result rather than assume
          ;; one. That is the price of not claiming an empty list when we could not
          ;; read it.
          (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Vendor enumerate, tenant ~A: the database call did not answer — the vendor list contents are unknown" tenant-id)))
      (:C ;; Duplicate PKs in the result set — data integrity, a human must look → 409.
          (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Vendor enumerate, tenant ~A: the result set contained duplicate primary keys — data integrity issue, investigate DOD_VEND_PROFILE directly" tenant-id)))
      (otherwise (error "Unrecognized bo-knowledge-truth ~A from nst-vnd/enumerate"
                        (bo-knowledge-truth knowledge))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; The reverse ferry — domain->response + render-json for the vendor profile
;;;
;;; ONLY TWO METHODS ARE DEFINED HERE, deliberately. The rest of this surface is
;;; already ENTITY-GENERIC in this tree, and redefining ANY of it would silently
;;; replace the warehouse's and products' versions — same generic function, same
;;; specializer:
;;;
;;;   * domain->response on nst-entity-nil / -unknown / -contradiction specializes on
;;;     the SENTINEL classes, not on nst-whs, so a vendor fetch miss already ferries
;;;     to nst-response-nil → 404 with no vendor-specific code.
;;;   * domain->response on (eql t) — the delete! ack — dispatches on T by the same
;;;     reasoning, which is why a vendor delete! needs no new method either.
;;;   * render-json on LIST, and domain->response-list, are thin mapcars over the
;;;     per-element methods, so they already cover VendorResponseModel.
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod domain->response ((entity nst-vnd) (ctx domain-ctx))
  "Reverse ferry (adhara §4): nst-vnd → VendorResponseModel.

   entity is the ONLY dispatching argument that may be an nst-domain-entity, and the
   entity itself never crosses into Ring 4 — only the boundary object does.

   THE CLASS IS THE ALLOWLIST, and for vendors that is a SECURITY boundary rather
   than tidiness, because the row holds four secrets. Password, salt,
   payment-api-key and payment-api-salt have no slot on VendorResponseModel to copy
   into, so they cannot reach a client even by a later edit to render-json. The
   कारक — tenant-id and company — are likewise absent from the response model."
  (declare (ignore ctx))
  (let ((destination (make-instance 'VendorResponseModel)))
    ;; IDENTITY
    (setf (row-id destination)         (row-id entity))
    (setf (vnd-phone destination)      (vnd-phone entity))
    (setf (vnd-name destination)       (vnd-name entity))
    ;; PERSON
    (setf (firstname destination)      (firstname entity))
    (setf (lastname destination)       (lastname entity))
    (setf (fullname destination)       (fullname entity))
    (setf (salutation destination)     (salutation entity))
    (setf (vnd-title destination)      (vnd-title entity))
    (setf (birthdate destination)      (birthdate entity))
    ;; ADDRESS + CONTACT
    (setf (vnd-address destination)    (vnd-address entity))
    (setf (vnd-city destination)       (vnd-city entity))
    (setf (vnd-state destination)      (vnd-state entity))
    (setf (vnd-country destination)    (vnd-country entity))
    (setf (vnd-zipcode destination)    (vnd-zipcode entity))
    (setf (vnd-picture-path destination) (vnd-picture-path entity))
    (setf (vnd-email destination)      (vnd-email entity))
    ;; PAYMENT — the MODE and the UPI id only. The key and the salt are not copied
    ;; because there is nowhere to copy them to; see the class documentation.
    (setf (payment-gateway-mode destination) (payment-gateway-mode entity))
    (setf (upi-id destination)         (upi-id entity))
    ;; STATUS
    (setf (approved-flag destination)  (approved-flag entity))
    (setf (approval-status destination) (approval-status entity))
    (setf (approved-by destination)    (approved-by entity))
    (setf (active-flag destination)    (active-flag entity))
    (setf (suspend-flag destination)   (suspend-flag entity))
    ;; NOTIFICATIONS / SHIPPING
    (setf (push-notify-subs-flag destination) (push-notify-subs-flag entity))
    (setf (email-add-verified destination)    (email-add-verified entity))
    (setf (shipping-enabled destination)      (shipping-enabled entity))
    ;; GST / TAX
    (setf (gstnumber destination)      (gstnumber entity))
    (setf (legal-name destination)     (legal-name entity))
    (setf (trade-name destination)     (trade-name entity))
    (setf (pan-number destination)     (pan-number entity))
    (setf (gst-state-code destination) (gst-state-code entity))
    (setf (gst-registration-type destination) (gst-registration-type entity))
    (setf (gst-filing-frequency destination)  (gst-filing-frequency entity))
    (setf (fy-start-month destination) (fy-start-month entity))
    ;; MISC
    (setf (invoice-settings destination) (invoice-settings entity))
    destination))

(defun vnd-flag->boolean (value)
  "Delegates to prd-flag->boolean in products/dod-bl-prd.lisp rather than repeating
   the Y/N → boolean rule, per the reuse discipline that escape-like-wildcards now
   follows too: one implementation of a rule, even when it lives in a sibling
   entity's file. The name is kept so vendor code does not read as though it were
   product code; the shared implementation should eventually move to core, the way
   escape-like-wildcards just did."
  (prd-flag->boolean value))

(defmethod render-json ((r VendorResponseModel) (ctx domain-ctx))
  "Single vendor → JSON ALIST.

   The contract is split in this tree on purpose: a per-ENTITY method returns a Lisp
   structure, while the per-LIST and sentinel methods return already-encoded text, and
   the dispatcher's render hop normalises the two.

   SECURITY CONTRACT: this alist IS the field allowlist, and it is the LAST gate in
   front of four secrets. It publishes nothing that VendorResponseModel does not
   declare — and that class declares no password, salt, payment-api-key or
   payment-api-salt.

   IDS ARE STRINGS via response-id-string, the one id convention for every entity:
   rowId arrives from an integer column.

   NAMING follows the platform's JSON convention — the entity prefix is dropped where
   the field is self-evident (VND_NAME → \"name\", VND_CITY → \"city\").

   FLAG CONVENTION: the lifecycle flags publish as BOOLEANS, so their keys are named
   for what they are — \"active\", \"approved\", \"suspended\" — not \"...Flag\". This
   follows products and diverges from warehouse, which publishes activeFlag as the raw
   string \"Y\"/\"N\". That divergence is flagged, un-unified, and worth one deliberate
   pass before any of these three endpoints has external consumers."
  (declare (ignore ctx))
  (list
   ;; IDENTITY
   (cons "rowId"                 (response-id-string (row-id r)))
   (cons "phone"                 (vnd-phone r))
   (cons "name"                  (vnd-name r))
   ;; PERSON
   (cons "firstName"             (firstname r))
   (cons "lastName"              (lastname r))
   (cons "fullName"              (fullname r))
   (cons "salutation"            (salutation r))
   (cons "title"                 (vnd-title r))
   (cons "birthdate"             (birthdate r))
   ;; ADDRESS + CONTACT
   (cons "address"               (vnd-address r))
   (cons "city"                  (vnd-city r))
   (cons "state"                 (vnd-state r))
   (cons "country"               (vnd-country r))
   (cons "zipcode"               (vnd-zipcode r))
   (cons "picturePath"           (vnd-picture-path r))
   (cons "email"                 (vnd-email r))
   ;; PAYMENT — mode and UPI id only; the key and salt are not in this alist and have
   ;; no slot to be read from.
   (cons "paymentGatewayMode"    (payment-gateway-mode r))
   (cons "upiId"                 (upi-id r))
   ;; STATUS
   (cons "approved"              (vnd-flag->boolean (approved-flag r)))
   (cons "approvalStatus"        (approval-status r))
   (cons "approvedBy"            (approved-by r))
   (cons "active"                (vnd-flag->boolean (active-flag r)))
   (cons "suspended"             (vnd-flag->boolean (suspend-flag r)))
   ;; NOTIFICATIONS / SHIPPING
   (cons "pushNotifySubscribed"  (vnd-flag->boolean (push-notify-subs-flag r)))
   (cons "emailVerified"         (vnd-flag->boolean (email-add-verified r)))
   (cons "shippingEnabled"       (vnd-flag->boolean (shipping-enabled r)))
   ;; GST / TAX
   (cons "gstNumber"             (gstnumber r))
   (cons "legalName"             (legal-name r))
   (cons "tradeName"             (trade-name r))
   (cons "panNumber"             (pan-number r))
   (cons "gstStateCode"          (gst-state-code r))
   (cons "gstRegistrationType"   (gst-registration-type r))
   (cons "gstFilingFrequency"    (gst-filing-frequency r))
   (cons "fyStartMonth"          (fy-start-month r))
   ;; MISC
   (cons "invoiceSettings"       (invoice-settings r))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; The invoice-settings प्रत्यय — a STRUCTURE, not a set of columns
;;;
;;; !update already accepts :invoice-settings, because it is a declared initarg and
;;; extract-domain-initargs forwards it. What it cannot do is say anything about the
;;; VALUE: it assigns a TEXT column and moves on. That column holds a printed alist
;;; of nested sections — 4,101 to 4,330 characters in the fifteen rows in the
;;; database — and three readers parse it back with read-from-string, one of them
;;; (nst-vendor-invoicesettings, nst-ui-ihd.lisp:209) with no listp guard, so a NULL
;;; column — which the legacy ORM hands back as the 9 characters "undefined" —
;;; becomes the SYMBOL UNDEFINED and the next assoc on it is a type error three
;;; frames from the cause. That is a missing domain invariant, and this प्रत्यय is
;;; where it belongs: the website, the API and a REPL caller all get it, because none
;;; of them reaches the column without going through a verb.
;;; ═══════════════════════════════════════════════════════════════════════════

(define-condition vendor-settings-rejected (error)
  ((why :initarg :why :reader vendor-settings-rejected-why))
  (:report (lambda (condition stream)
             (format stream "nst-vnd/invoice-settings: ~A This is a malformed request, not an unknown outcome; it must not be reported as 503."
                     (vendor-settings-rejected-why condition)))))

(defun vendor-settings-sections ()
  "The section names a vendor's blob may carry, DERIVED from the shipped defaults
   rather than restated, so a section added to *invoice-settings* is legal for a
   vendor the moment it ships and this list cannot drift from the renderer."
  (mapcar #'car *invoice-settings*))

(defun vendor-settings-read (string)
  "Parse the column's printed alist. *READ-EVAL* is NIL because the text comes from a
   TEXT column: a stored #. reader macro would otherwise execute on read, and a
   storage column is not a place to evaluate code from."
  (when (string-equal (string-trim '(#\Space #\Tab #\Newline #\Return) string) "undefined")
    (error 'vendor-settings-rejected
           :why "the column holds the string \"undefined\", which is dod-vend-profile's void value for a NULL column, not a settings blob."))
  (handler-case
      (let ((*read-eval* nil)
            (form (read-from-string string nil :eof)))
        (if (eq form :eof)
            (error 'vendor-settings-rejected :why "the column holds no readable Lisp form.")
            form))
    (vendor-settings-rejected (c) (error c))
    (error (c) (error 'vendor-settings-rejected
                      :why (format nil "the column does not hold a readable settings alist (~A)." c)))))

(defun vendor-settings-key-designator-p (x)
  "True when X can name a settings key — a symbol, a string or a character."
  (or (symbolp x) (stringp x) (characterp x)))

(defun vendor-settings-name->key (name)
  "A settings key NAME — a string, a keyword, or a symbol — → the SYMBOL the readers
   match on, interned in the package the shipped defaults live in.

   WHY THE PACKAGE MATTERS, AND IT MATTERS ONLY FOR SECTIONS. nst-get-vendor-
   invoiceprintsettings (nst-ui-ihd.lisp:163) looks the print section up with

       (assoc 'invoice-print-settings settings :test #'equal)

   — a strict EQUAL on the interned symbol — so a section key arriving as the keyword
   :INVOICE-PRINT-SETTINGS is a DIFFERENT symbol, the lookup MISSES, and the very next
   line silently falls through to the shipped defaults instead of signalling. That is
   the dangerous shape of this bug: a JSON-written blob whose sections are keywords
   does not error, it quietly reverts the vendor's configuration to the shipped one.

   Entry keys need none of this: invoiceprintsettingentry matches on the hyphen-stripped
   upper-case NAME and accepts any symbol, precisely because keys saved from the
   settings page come back from JSON as hyphen-less keywords (:LOGOPATH)."
  (intern (string-upcase (string name)) (find-package :nstores)))

(defun vendor-settings-canonicalize-sections (settings)
  "SETTINGS → the same alist with every TOP-LEVEL section key replaced by its canonical
   symbol. NOTHING BELOW THE SECTION LEVEL IS TOUCHED, and that restraint is the point:

     * only sections are looked up with a strict EQUAL, so only sections need a
       canonical spelling (see vendor-settings-name->key);
     * entries are matched on their hyphen-stripped name and already tolerate the
       hyphen-less keywords a JSON body produces;
     * the subtree is FREE-FORM, so no rule can safely rewrite it. The shipped defaults
       prove it: default-tax carries

           (tax-rates ((name "Sales Tax") (rate 8.5)) ((name "Service Tax") (rate 12.0)))

       where every element is a cons, which is indistinguishable from a list of
       key/value pairs. A first version of this function recursed on that test and
       died calling STRING on the list (name \"Sales Tax\") — the seed data found it,
       not a test.

   A section whose car is not a key designator is passed through untouched so section
   validation reports it by name instead of this dying on a type error."
  (mapcar (lambda (section)
            (if (and (consp section) (vendor-settings-key-designator-p (car section)))
                (cons (vendor-settings-name->key (car section)) (cdr section))
                section))
          settings))

(defun vendor-settings-canonical (raw)
  "RAW → (values STORED-STRING PARSED). Accepts the string the column holds, or the
   alist an internal caller has in hand, or a JSON-decoded settings OBJECT — the three
   shapes a write can arrive as, so the verb has one contract instead of three.

   A STRING IS VALIDATED BUT STORED UNCHANGED — it is the column's own spelling, and
   re-printing it would rewrite formatting for nothing. A LIST HAS ITS SECTION KEYS
   CANONICALISED first, which is what makes a JSON body acceptable: its section keys
   arrive as keywords and would never match the readers' strict EQUAL (see
   vendor-settings-name->key). An alist that is already canonical is unchanged by that,
   so this is one rule, not two.

   The printed form binds *package* to :keyword, fully qualifying the symbols: that is
   the spelling migrate-2026Sep-backfill-vendor-invoice-settings writes, and the app's
   own save path (nst-ui-ihd.lisp:245) does NOT bind the package and so may have
   written bare symbols that only resolve inside com.nstores.app. New rows get the
   portable form."
  (cond
    ((null raw)
     (error 'vendor-settings-rejected :why "no :settings payload was supplied."))
    ((stringp raw)
     (values raw (vendor-settings-read raw)))
    ((listp raw)
     (let ((canonical (vendor-settings-canonicalize-sections raw)))
       (values (let ((*package* (find-package :keyword)))
                 (write-to-string canonical :readably t))
               canonical)))
    (t (error 'vendor-settings-rejected
              :why (format nil ":settings must be a string or a list, not ~S." (type-of raw))))))

(defun vendor-settings-validate (settings)
  "The structure law: a LIST of (SECTION . ENTRIES), every SECTION a name the shipped
   defaults already carry. Nothing deeper is checked — the entries are free-form by
   design and the renderer walks them by name, so a validator that guessed each
   section's inner shape would break the moment a section gained a field.

   The rejection names the CLOSEST known section when the symbol is merely the wrong
   one, because that is the failure a JSON caller actually hits: a keyword section
   reads as \"not a shipped section\" and the real problem is that it is the RIGHT name
   interned in the WRONG package."
  (unless (listp settings)
    (error 'vendor-settings-rejected
           :why (format nil "the settings blob is ~S, not a list — a NULL column read back through the legacy ORM as the string \"undefined\" is the usual cause." settings)))
  (let ((known (vendor-settings-sections)))
    (dolist (section settings settings)
      (unless (consp section)
        (error 'vendor-settings-rejected
               :why (format nil "~S is not a (section . entries) pair." section)))
      (unless (member (car section) known :test #'eq)
        (let ((namesake (find (symbol-name (car section)) known
                              :key #'symbol-name :test #'string-equal)))
          (error 'vendor-settings-rejected
                 :why (format nil "~S is not one of the shipped sections (~{~A~^, ~}).~@[ Its NAME matches ~S, which is a different symbol: the readers look the section up with (assoc 'invoice-print-settings … :test #'equal), so that spelling would be silently ignored.~]"
                              (car section) known namesake)))))))

(defmethod !settings ((entity-class (eql 'nst-vnd)) (row-id string) (ctx domain-ctx) &rest args)
  "संरचना प्रत्यय — replace the vendor's INVOICE_SETTINGS blob by row-id.

   THE PAYLOAD IS VALIDATED BEFORE THE ROW IS LOOKED UP, the same order !update uses
   for its forbidden fields: a malformed request is malformed whether or not the row
   exists, and answering it with a 404 sends the client to fix the wrong thing.

   STORED STATE IS LOADED FIRST and only the one slot changes, so this verb cannot
   blank a column it was not asked about — copyVendor-domaintodb writes every field,
   from the entity it is handed. That copier also forces DELETED_STATE to \"N\", which
   is harmless here for !update's reason: select-vendor-by-id-in-tenant filters
   deleted rows, so a deleted target answered :F above."
  (declare (ignore entity-class))
  (multiple-value-bind (stored parsed) (vendor-settings-canonical (getf args :settings))
    (vendor-settings-validate parsed)
    (let* ((company (domain-ctx-tenant ctx))
           (tenant-id (slot-value company 'row-id))
           (rid (vendor-row-id-from-string row-id)))
      (if (null rid)
          (make-instance 'nst-entity-nil
                         :tenant-id tenant-id
                         :reason (format nil "~S does not address a vendor row (row-ids are integers)" row-id))
          ;; else
          (let ((dbobj (select-vendor-by-id-in-tenant rid tenant-id)))
            (if (null dbobj)
                (make-instance 'nst-entity-nil
                               :tenant-id tenant-id
                               :reason (format nil "Vendor row-id ~A not found in this tenant (or already deleted)" row-id))
                ;; else
                (let ((entity (make-instance 'nst-vnd :tenant-id tenant-id)))
                  (copyVendor-dbtodomain dbobj entity)
                  (setf (company entity) company)
                  (setf (invoice-settings entity) stored)
                  (setf (company entity) company)
                  (copyVendor-domaintodb entity dbobj)
                  (let ((knowledge (with-nst-db-update (:source "nst-vnd/!settings")
                                      (clsql:update-records-from-instance dbobj)
                                      dbobj)))
                    (case (bo-knowledge-truth knowledge)
                      (:T entity)
                      (:U ;; The write did not complete and the row's state is unknown →
                          ;; 503, not 500 and NOT 404: the vendor exists, we just cannot
                          ;; say what happened to it.
                          (domain-sentinel-from-knowledge
                           knowledge ctx
                           :reason (format nil "Vendor settings update, row-id ~A: the database call did not answer — the row's current state is unknown" row-id)))
                      (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-update"
                                        (bo-knowledge-truth knowledge))))))))))))
