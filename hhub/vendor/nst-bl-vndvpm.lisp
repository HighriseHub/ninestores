;;; nst-bl-vndvpm.lisp — Tier-1 प्रत्यय for nst-vnd-vpm (vendor payment settings)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; 🚨 NOT YET COMPILED, NOT YET RUN. Wired into nstores.asd and package/compile.lisp.
;;; Per this project's standing rule — with its two recorded proofs, a copier that
;;; compiled with ten warnings and would have failed on the first fetch, and a helper
;;; named `safe` that executes arbitrary code — compile-time success is NOT evidence.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THIS ENTITY IS, IN BUSINESS TERMS
;;;
;;; This is NOT a transaction, a catalogue or an account. It is a SETTING — which of
;;; five payment methods the vendor accepts. The vendor has exactly ONE such row for
;;; its whole lifetime, created once, then read and edited.
;;;
;;; The five flags: COD (cash on delivery), UPI, payment-gateway providers, prepaid
;;; wallet, pay-later. There is nothing else on the row. The credentials these flags
;;; gate — PAYMENT_API_KEY, PAYMENT_API_SALT, PAYMENT_GATEWAY_MODE, UPI_ID — are
;;; DOD_VEND_PROFILE columns and belong to nst-vnd, not here.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THREE VERBS, AND TWO DELIBERATE ABSENCES
;;;
;;;   ?exists   (प्रत्यभिज्ञा) — implemented because `make` REQUIRES it. adhara's
;;;                              make contract is explicit: "Any entity MUST run a
;;;                              ?exists uniqueness check BEFORE construction
;;;                              completes." It is a supporting law, not a fourth
;;;                              endpoint.
;;;   make      (सृजन)     — register the vendor's payment settings, once.
;;;   fetch     (स्मरण)    — recall them.
;;;   !update   (!state)   — change one or more flags.
;;;
;;;   delete!   — ABSENT ON PURPOSE. There is no business case for deleting a payment
;;;               setting. "The vendor accepts nothing" is expressed IN BAND by
;;;               setting the five flags to "N"; a soft-deleted row would occupy the
;;;               singleton slot while नियम-2 makes it invisible to every verb, so the
;;;               vendor could never configure payments again. Leaving delete!
;;;               undefined means that state is UNREACHABLE through this surface.
;;;               (It is still reachable out of band — the legacy UI and raw SQL can
;;;               write DELETED_STATE='Y'. That case is a data anomaly: ?exists reports
;;;               :C and make refuses with 409 rather than guessing. See ?exists.)
;;;
;;;   enumerate — ABSENT ON PURPOSE. A vendor never has more than one of these rows,
;;;               so "list" has no meaning. What a caller actually wants — "my payment
;;;               settings" — is `fetch`, addressed by the parent vendor.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; 🚨 THE SINGLETON IS A DOMAIN LAW, NOT A SCHEMA FACT
;;;
;;; DOD_VPAYMENT_METHODS has only a PRIMARY KEY on ROW_ID plus two plain NON-UNIQUE
;;; indexes (TENANT_ID, VENDOR_ID) — verified by SHOW INDEX. MySQL will accept six
;;; payment rows for one vendor without complaint. Nothing but this file's ?exists and
;;; make :around stands between a vendor and six contradictory settings rows.
;;;
;;; This is the FIRST IDENTITY IN THIS TREE THAT IS INVENTED RATHER THAN MIRRORED.
;;; nst-vnd reads its identity off UC_Vendor; nst-prd off PRODUCT_CODE's index; nst-whs
;;; off uk_gstin_name_tenant. Here there is no index to read, so the law is stated
;;; instead: at most one row per (VENDOR_ID, TENANT_ID).
;;;
;;; WHY IT MATTERS IN PRACTICE: the live reader takes the FIRST row and orders by
;;; ROW_ID DESC (select-vpayment-methods, dod-bl-vpm.lisp:170-178; the shipping twin
;;; at dod-bl-osh.lisp:11-19 has no ORDER BY at all). A duplicate would not raise — it
;;; would silently change which settings the checkout sees.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; 🚨 A NULL FLAG IS NOT "UNSET" — IT IS ACTIVELY WRONG, AND THIS FILE PREVENTS IT
;;;
;;; The five flags and ACTIVE_FLAG are char(1) NULLABLE columns with NO NOT NULL. The
;;; legacy view-class maps every one of them with :void-value, so a stored NULL is
;;; READ BACK AS A VALUE — "Y" for active/COD/UPI/providers/wallet, and "Y" for
;;; PAYLATERENABLED, which is itself wrong because the DDL default there is 'N'.
;;;
;;; And the live checkout compares the string directly:
;;;   (equal walletenabled "Y")     customer/dod-ui-cus.lisp:322
;;;
;;; So a NULL is not a neutral third state. It is a value that reads back as "Y", which
;;; would silently ENABLE a payment method the vendor never enabled. Therefore:
;;;
;;;   * `make`    — a caller that says nothing, or says an explicit NIL, gets the LIVE
;;;                 DDL DEFAULT. A NULL is never written. (vpm-apply-flag-defaults.)
;;;   * `!update` — an explicit NIL is REFUSED with the field named, rather than
;;;                 quietly repaired. In an update the caller is stating an intent, and
;;;                 there is no way to express "unset" that does not store a NULL. See
;;;                 the reasoning at the dolist in !update.
;;;
;;; The asymmetry is deliberate: at CREATE, absence is normal and a default is the
;;; only sensible reading. At UPDATE, absence of a key and a key holding NIL are
;;; different statements, and only one of them is expressible.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THIS FILE DOES NOT DO, AND WHY
;;;
;;;   * NO render-json / domain->response. Without them a JSON call signals
;;;     no-applicable-method. They are the next step, not an oversight — the verbs
;;;     must be callable from the REPL FIRST, because that is the only way to find out
;;;     whether any of this works. See the CONTEXT's standing rule.
;;;
;;;   * NO delete! / enumerate — see above.
;;;
;;;   * NO new SQL dialect for the parent check. The referential law below calls
;;;     `fetch 'nst-vnd`, reusing the profile's tenant-scoped, BOLA-refusing selector
;;;     rather than duplicating a vendor SELECT here.
;;;
;;;   * NO vendor-id from the REQUEST in the long run. `vendor-id` currently arrives as
;;;     an initarg / lookup value, which is exactly the intra-tenant BOLA that
;;;     domain-ctx's `actor` slot exists to close (CONTEXT §12.3 decision 3: vendor X
;;;     editing vendor Y's config inside one tenant). Every verb here reads it from its
;;;     argument for now; when the actor work lands, the RESOLUTION moves to one place
;;;     and these bodies do not change shape. Recorded so the gap is not mistaken for
;;;     a decision.
;;; ═══════════════════════════════════════════════════════════════════════════

(in-package :nstores)

(clsql:file-enable-sql-reader-syntax)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — The condition, and the flag table
;;; ═══════════════════════════════════════════════════════════════════════════

(define-condition vpm-field-rejected (error)
  ((field :initarg :field :reader vpm-field-rejected-field)
   (why   :initarg :why   :reader vpm-field-rejected-why))
  (:report (lambda (condition stream)
             (format stream "nst-vnd-vpm: field ~A was rejected — ~A. This is a malformed request, not an unknown outcome; it must not be reported as 503."
                     (vpm-field-rejected-field condition)
                     (vpm-field-rejected-why condition))))
  (:documentation
   "Raised when a caller supplies a field this entity cannot accept, for any of three
    distinct reasons — the message names which:
      1. a REQUIRED field is absent          (make: :vendor-id)
      2. a NON-EDITABLE field was supplied   (!update: :vendor-id, the parent link)
      3. a field was supplied as explicit NIL where NULL is not storable without
         changing meaning (!update: any flag)

    WHY A NEW CONDITION RATHER THAN vendor-required-field-missing. That one is
    nst-vnd's, its report string says so, and its name asserts 'missing' — which is
    false for reasons 2 and 3. Reusing it would put a vendor-profile word on a
    payment-settings failure. The 4xx taxonomy gap (CONTEXT §7.2) applies to this
    condition exactly as it does to the other three signalling paths: it reaches the
    API as a 500 where 400 is right, until that shared fix lands."))

(defparameter *vpm-flag-defaults*
  '((:codenabled          . "Y")   ; DDL default 'Y'
    (:upienabled          . "Y")   ; DDL default 'Y'
    (:payprovidersenabled . "Y")   ; DDL default 'Y'
    (:walletenabled       . "Y")   ; DDL default 'Y'
    (:paylaterenabled     . "N")   ; DDL default 'N' — NOT 'Y'; see the header
    (:active-flag         . "Y"))  ; CLASS CHOICE, not a DDL default (column is NULL)
  "The value each flag takes when the caller supplies none or an explicit NIL.

   These are the LIVE DDL DEFAULTS, read from SHOW COLUMNS FROM DOD_VPAYMENT_METHODS
   (2026-09-15), which is why PAYLATERENABLED is \"N\" and not \"Y\" — the legacy
   view-class dod-vpayment-methods declares :void-value \"Y\" for that column and is
   simply wrong; the live data agrees with the DDL (rows 3, 4 and 12 hold 'N').

   ACTIVE_FLAG is the one entry that is NOT a DDL default: the column is nullable with
   no default at all, so \"Y\" is a class/verb CHOICE, matching all five live rows and
   the predicate every reader filters on (deleted_state='N' AND active_flag='Y').

   The ORDER matters only for readability — this is a plist of independent flags.")


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — Copiers (the crossing between the two trees)
;;; ═══════════════════════════════════════════════════════════════════════════

(defun copyVpm-domaintodb (source destination)
  "nst-vnd-vpm → dod-vpayment-methods.

   THE VIEW-CLASS IS THE LEGACY ONE, deliberately — the same choice nst-vnd made with
   dod-vend-profile, and it is why nstore.asd loads this file after dod-dal-vpm. Two
   latent defects in that class are inherited rather than fixed here, because it is on
   the LIVE CHECKOUT PATH (customer/dod-ui-cus.lisp:295) and editing it is a change to
   working code, not to ours:
     * paylaterenabled carries :void-value \"Y\" where the DDL default is 'N';
     * upienabled declares :initarg :enabled, not :upienabled.
   Neither affects this copier: it writes through slot NAMES via with-slots, so the
   initarg defect is unreachable, and the :void-value defect only manifests on a read
   of a stored NULL — which this file never writes (see the header).

   DELETED_STATE IS FORCED TO \"N\" on the way out, and TENANT_ID comes from the
   company OBJECT. Both mirror copyVendor-domaintodb (nst-bl-vnd.lisp) decisions 1-2:
   the tenant is never a field a caller sets, and a row written here is by definition
   not deleted.

   NOTE the destination's `vendor` slot is a :DB-KIND :JOIN with :SET NIL — read-only,
   and deliberately NOT in the with-slots list below."
  (let ((company (slot-value source 'company)))
    (with-slots (vendor-id codenabled upienabled payprovidersenabled walletenabled
                 paylaterenabled active-flag deleted-state tenant-id)
        destination
      (setf vendor-id          (slot-value source 'vendor-id))
      (setf codenabled         (slot-value source 'codenabled))
      (setf upienabled         (slot-value source 'upienabled))
      (setf payprovidersenabled (slot-value source 'payprovidersenabled))
      (setf walletenabled      (slot-value source 'walletenabled))
      (setf paylaterenabled    (slot-value source 'paylaterenabled))
      (setf active-flag        (slot-value source 'active-flag))
      ;; INVARIANT — not copied from the source. See the docstring.
      (setf deleted-state "N")
      ;; INVARIANT — decision 1. A missing company signals here rather than writing a
      ;; NIL tenant, which is what a forgotten company slot should do.
      (setf tenant-id (slot-value company 'row-id))
      destination)))

(defun copyVpm-dbtodomain (source destination)
  "dod-vpayment-methods → nst-vnd-vpm. The inbound direction of the crossing.

   VENDOR-ID, TENANT-ID AND COMPANY ARE NOT COPIED FROM THE ROW:
     * the CALLER sets vendor-id, because it is the argument that selected this row —
       copying it from the row would let a stale row silently re-point the entity at a
       different vendor;
     * tenant-id and company are attached by the caller from domain-ctx, for the same
       reason nst-vnd's inbound copier does it: the tenant is a कारक, not a field.

   DELETED_STATE IS NOT COPIED EITHER, and that is load-bearing: the entity's inherited
   slot carries \"N\", every selector here filters deleted rows out, and copying a \"Y\"
   in would make नियम-2 (check-niyam) refuse the very write the caller is about to make.
   A row that reaches this function is by construction not deleted — see
   select-vpm-by-vendor-in-tenant."
  (with-slots (codenabled upienabled payprovidersenabled walletenabled
               paylaterenabled active-flag)
      destination
    ;; The view-class declares NO accessor for deleted-state (only a slot), so read the
    ;; flags through with-slots and never assume an accessor of the same name exists.
    (setf codenabled          (slot-value source 'codenabled))
    (setf upienabled          (slot-value source 'upienabled))
    (setf payprovidersenabled (slot-value source 'payprovidersenabled))
    (setf walletenabled       (slot-value source 'walletenabled))
    (setf paylaterenabled     (slot-value source 'paylaterenabled))
    (setf active-flag         (slot-value source 'active-flag))
    destination))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Helpers
;;; ═══════════════════════════════════════════════════════════════════════════

(defun vpm-vendor-id-from-string (value)
  "Returns the INTEGER vendor-id, or NIL when VALUE cannot address a vendor at all.

   Vendor-ids arrive as STRINGS across the API (apidefs2 passes path params through
   unchanged) and as INTEGERS from internal callers and from JSON bodies that carried a
   number. Both are accepted; anything else is NIL, which callers turn into a :F
   'cannot address a row' answer rather than a 500 — the same rule as
   vendor-row-id-from-string."
  (cond ((integerp value) value)
        ((stringp value)
         (handler-case (parse-integer value :junk-allowed nil)
           (error () nil)))
        (t nil)))

(defun select-vpm-by-vendor-in-tenant (vendor-id tenant-id &key include-deleted)
  "The singleton lookup, keyed on the identity this entity actually has:
   (VENDOR_ID, TENANT_ID).

   TENANT-SCOPED, so another tenant's vendor-id answers exactly as a vendor-id that
   does not exist. This is the entity's whole authorization model at the verb layer:
   the parent id in the URL is an ADDRESS, never an authorization.

   :INCLUDE-DELETED T is what makes the soft-deleted case DETECTABLE — a row the domain
   considers gone still occupies the singleton slot, because nothing in the schema
   stops it. That is the :C in ?exists.

   Returns ONE ROW OR NIL: the CAR is taken here, not by the callers. with-db-call hands
   its payload straight to ?exists, which reads a SLOT off it — returning the raw
   clsql:select LIST made the products twin call slot-value on a CONS and turned an
   intended 409 into a 500 (nst-bl-vnd.lisp, select-vendor-by-phone-in-tenant).

   ORDER BY ROW_ID DESC matches the live legacy reader (select-vpayment-methods,
   dod-bl-vpm.lisp:170-178) so that the two agree on WHICH row they mean if the
   singleton law is ever violated. It is a tie-breaker, not a law — the law is
   ?exists."
  (car (if include-deleted
           (clsql:select 'dod-vpayment-methods
                         :where [and [= [:vendor-id] vendor-id]
                                     [= [:tenant-id] tenant-id]]
                         :order-by '(([row-id] :desc))
                         :caching *dod-database-caching* :flatp t)
           ;; The [= [:deleted-state] "N"] reading relies on the view-class's
           ;; :void-value mapping NULL ↔ "N" — the convention every selector here uses.
           (clsql:select 'dod-vpayment-methods
                         :where [and [= [:deleted-state] "N"]
                                     [= [:vendor-id] vendor-id]
                                     [= [:tenant-id] tenant-id]]
                         :order-by '(([row-id] :desc))
                         :caching *dod-database-caching* :flatp t))))

(defun vpm-apply-flag-defaults (entity)
  "Fill every flag the caller left NIL with its DDL default. See the file header:
   a NULL here is read back as \"Y\" through the view-class's :void-value and would
   silently ENABLE a payment method.

   Only NIL is replaced. \"N\" is a value, not an absence, and survives untouched —
   which is the whole point, since \"off\" is the state a vendor most often wants."
  (dolist (pair *vpm-flag-defaults* entity)
    (unless (slot-value entity (car pair))
      (setf (slot-value entity (car pair)) (cdr pair)))))

(defun vpm-hydrate (dbobj vendor-id company)
  "dod-vpayment-methods → a fully-attached nst-vnd-vpm.

   The FOUR things the copier deliberately does NOT set are set here, in ONE place, so
   fetch and !update cannot disagree about them: row-id (the row's own primary key),
   vendor-id (the parent link), tenant-id (from the company OBJECT's row-id) and company
   itself.

   🚨 ROW-ID IS LOAD-BEARING AND WAS MISSING. copyVpm-dbtodomain copies only the flags —
   it is the INBOUND leg of a copier whose OUTBOUND twin writes the row — so nothing
   else binds row-id, and domain->response reads it on the way out. Omitting it made a
   fetch of an EXISTING row raise UNBOUND-SLOT ROW-ID inside domain->response and answer
   500, while a fetch of an ABSENT row was a clean 404: the failure only appeared on the
   success path. That is the same 500 bind-generated-row-id documents for the warehouse
   create API (nst-mult-logic.lisp:381-388), reproduced here on the read path. make is
   immune because it calls that helper after the INSERT; fetch and !update are not, and
   they both come through this function — hence one fix, one place.

   The company object matters beyond the row: copyVpm-domaintodb derives the written
   TENANT_ID from it, so an entity hydrated here and handed to !update without it would
   write a NIL tenant."
  (let ((entity (make-instance 'nst-vnd-vpm
                               :vendor-id vendor-id
                               :tenant-id (slot-value company 'row-id))))
    ;; THE ROW'S OWN KEY — see the warning above. Read from the view-class by slot,
    ;; not by accessor, matching the rest of the copiers.
    (setf (row-id entity) (slot-value dbobj 'row-id))
    (setf (company entity) company)
    (copyVpm-dbtodomain dbobj entity)
    entity))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — ?exists (प्रत्यभिज्ञा)
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod ?exists ((entity-class (eql 'nst-vnd-vpm)) (vendor-id string) (ctx domain-ctx)
                    &key &allow-other-keys)
  "Does this vendor already have a payment-settings row IN THIS TENANT?

   The lookup value is the VENDOR-ID, because (VENDOR_ID, TENANT_ID) is what must be
   unique here — not a row-id, and not any column of this table. This is the first
   ?exists in the tree whose uniqueness is purely a DOMAIN law: no index enforces it.

   A Belnap answer, because the honest answer is not yes/no:
     :F  free — nothing occupies the slot, so creation may proceed
     :T  a LIVE row exists (a plain fact of existence) → make must refuse
     :C  a SOFT-DELETED row occupies the slot. DELETED_STATE is not part of any key, so
         the row still holds it while नियम-2 makes it invisible to every verb — 'the
         settings exist' and 'this vendor has no settings' are both true at once.
         Unreachable through THIS surface (there is no delete!), but reachable by the
         legacy UI or raw SQL, so it is answered rather than assumed away.
     :U  the database could not be consulted — which is NOT 'probably free'.

   THE TENANT COMES FROM ctx, NEVER FROM A KEYWORD. The &key &allow-other-keys is
   CLOS congruence with adhara's generic function (the warehouse genuinely needs it,
   its key being GSTIN + WNAME + tenant). Here the other half of the identity is the
   TENANT, and accepting it from a caller would let a client probe another tenant's
   vendors. The keyword is accepted and IGNORED, deliberately; ctx always wins."
  (declare (ignore entity-class))
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
        (vid (vpm-vendor-id-from-string vendor-id)))
    (if (null vid)
        ;; Not addressable at all — a malformed identity, which is a :F fact about this
        ;; query, not an :U. Matches how fetch answers an unparseable id.
        (make-bo-knowledge
         :truth :F
         :payload nil
         :provenance (format nil "nst-vnd-vpm/?exists: ~S does not address a vendor (vendor-ids are integers)" vendor-id))
        (let ((knowledge (with-db-call
                             (select-vpm-by-vendor-in-tenant vid tenant-id
                                                             :include-deleted t)
                           "nst-vnd-vpm/?exists (vendor-id, tenant, deleted rows included)")))
          (cond
            ;; Free, unknown, or the (should-be-impossible) multi-row case — pass through
            ;; whatever the database reported.
            ((not (eq (bo-knowledge-truth knowledge) :T)) knowledge)
            ;; dod-vpayment-methods declares no accessor for deleted-state, only a slot.
            ((string= (slot-value (bo-knowledge-payload knowledge) 'deleted-state) "Y")
             ;; Occupied by a row the domain considers gone: :T (it is there) ⊔ :F (no
             ;; settings there) = :C, provenance recording which two rules collided.
             (bo-merge knowledge
                       (make-bo-knowledge
                        :truth :F
                        :payload nil
                        :provenance "नियम-2: DELETED_STATE='Y' rows are invisible to every verb")))
            (t knowledge))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 5 — make (सृजन)
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod make :around ((entity-class (eql 'nst-vnd-vpm)) (ctx domain-ctx) &rest initargs)
  "TWO pre-flight laws, and the ORDER between them is the design.

   adhara's make contract requires a ?exists check before construction completes. This
   is an :around rather than a :before for the reason the products and warehouse twins
   record: a :before cannot return a value, so raising was its only way to refuse, and
   every refusal reached the boundary as a 500 — indistinguishable from a crash and
   from 'not found'. An :around can return, so both laws answer in the domain's own
   four values.

   1. REFERENTIAL — the parent must exist in this tenant. DOD_VPAYMENT_METHODS declares
      NO FOREIGN KEY, so MySQL happily accepts an orphan VENDOR_ID; the constraint the
      schema is missing is applied here. It reuses `fetch 'nst-vnd`, so the profile's
      tenant scoping and BOLA refusal come for free and do not get a second
      implementation. A missing parent propagates the sentinel it returned — 404, NOT
      409: the singleton question is moot, and 'this vendor does not exist' is the
      accurate report.

   2. SINGLETON — only a CONFIRMED-FREE slot passes:
        ?exists :F → proceed
        ?exists :T → a live row exists            → contradiction → 409
        ?exists :C → a soft-deleted row holds it  → contradiction → 409
        ?exists :U → could not check              → unknown       → 503

      :C is refused rather than silently adopted. Adoption would be defensible for a
      settings row (there is no real-world identity being reused, unlike a phone
      number shared with a person), but it would erase the evidence that someone
      soft-deleted a live vendor's payment configuration out of band — and that is a
      fact worth a human's attention. There is no delete! on this entity, so :C can
      only mean an anomaly.

   Skips the singleton check when no :vendor-id was supplied, because the primary
   method reports that case with the field named instead."
  (let ((vendor-id (getf initargs :vendor-id)))
    (if (null vendor-id)
        (call-next-method)
        (let* ((company (domain-ctx-tenant ctx))
               (vid (vpm-vendor-id-from-string vendor-id)))
          (if (null vid)
              (make-instance 'nst-entity-nil
                             :tenant-id (slot-value company 'row-id)
                             :reason (format nil "~S does not address a vendor (vendor-ids are integers), so no payment settings can be created for it" vendor-id))
              ;; LAW 1 — referential. A real nst-vnd means the parent exists IN THIS
              ;; TENANT; anything else is a sentinel, returned unchanged.
              (let ((parent (fetch 'nst-vnd (princ-to-string vid) ctx)))
                (if (not (typep parent 'nst-vnd))
                    parent
                    ;; LAW 2 — singleton.
                    (let ((check (?exists 'nst-vnd-vpm (princ-to-string vid) ctx)))
                      (case (bo-knowledge-truth check)
                        (:F (call-next-method))     ; confirmed free — proceed
                        (:T (make-instance 'nst-entity-contradiction
                                           :tenant-id (slot-value company 'row-id)
                                           :reason (format nil "Vendor ~A already has payment settings in this tenant. This entity is a singleton setting: one row per vendor for its lifetime, created once. Edit the existing row instead — this is neither done nor impossible." vid)))
                        (otherwise
                         (domain-sentinel-from-knowledge
                          check ctx
                          :reason (lambda (truth)
                                    (case truth
                                      (:C (format nil "Vendor ~A has a SOFT-DELETED payment-settings row in this tenant. It occupies the singleton slot (DELETED_STATE is in no key) while नियम-2 makes it invisible to every verb. This surface has no delete!, so the row was deleted out of band — a human must decide whether to restore it or remove it. Human decision needed." vid))
                                      (otherwise (format nil "Vendor ~A: the singleton check did not come back free" vid)))))))))))))))

(defmethod make ((entity-class (eql 'nst-vnd-vpm)) (ctx domain-ctx) &rest initargs)
  "सृजन प्रत्यय — create the vendor's payment settings, ONCE.

   कारक: the tenant comes from ctx alone (नियम-1), passed as the INTEGER row-id, because
   check-niyam compares (tenant-id entity) against
   (slot-value (domain-ctx-tenant ctx) 'row-id) and only two integers can be equal. The
   company OBJECT is still needed for a different job: it is what copyVpm-domaintodb
   turns into the written TENANT_ID.

   THE company SLOT IS SET UNCONDITIONALLY FROM ctx. extract-domain-initargs does NOT
   strip :company, so a caller that supplied one would otherwise have its value survive
   into the copier, which derives TENANT_ID from that slot. That is a tenant escape —
   create a settings row in another tenant — and `unless` was the wrong guard in the
   products twin. Re-set AFTER make-instance, never before.

   :vendor-id IS THE ONLY REQUIRED FIELD, and it is required by domain law rather than
   by the schema: the COLUMN is nullable, but a payment-settings row with no vendor is
   meaningless, and (vendor-id, tenant) is the entire identity. There is deliberately NO
   *vpm-required-create-fields* list — the other five columns are nullable WITH
   defaults, so the profile twin's four-entry guard would have nothing to guard.

   ⚠ THIS METHOD RELIES ON THE LEFTMOST-INITARG RULE, and the reliance is proven rather
   than assumed (checked under SBCL 2.6.8: a keyword supplied twice takes the FIRST
   value). `:vendor-id` and `:tenant-id` are passed BEFORE the caller's initargs, so the
   normalized vendor-id and the ctx-derived tenant WIN over anything a caller sends —
   a string vendor-id cannot be smuggled in, and a caller-supplied :tenant-id cannot
   move the row to another tenant even if extract-domain-initargs were bypassed. If that
   precedence were ever reversed, both guards become no-ops. The company slot is guarded
   separately by the unconditional setf below, because extract-domain-initargs does not
   strip :company."
  (declare (ignore entity-class))
  (let ((vendor-id (getf initargs :vendor-id)))
    (when (null vendor-id)
      (error 'vpm-field-rejected
             :field :vendor-id
             :why "vendor-id is the entity's identity — the singleton is one row per (vendor-id, tenant). The column is nullable, but a payment-settings row that belongs to no vendor means nothing."))
    (let* ((company (domain-ctx-tenant ctx))
           (vid (vpm-vendor-id-from-string vendor-id))
           (entity (apply #'make-instance 'nst-vnd-vpm
                          :vendor-id vid
                          :tenant-id (slot-value company 'row-id)
                          initargs))
           (dbobj (make-instance 'dod-vpayment-methods)))
      (unless vid
        (error 'vpm-field-rejected
               :field :vendor-id
               :why (format nil "~S does not address a vendor (vendor-ids are integers)" vendor-id)))
      ;; कारक — unconditional, and AFTER make-instance. See the docstring.
      (setf (company entity) company)
      ;; A caller that said nothing, or said an explicit NIL, gets the DDL default. A
      ;; NULL would read back as "Y" and silently enable a payment method.
      (vpm-apply-flag-defaults entity)
      (copyVpm-domaintodb entity dbobj)
      (let ((knowledge (with-nst-db-create (:source "nst-vnd-vpm/make")
                          (clsql:update-records-from-instance dbobj)
                          dbobj)))
        (case (bo-knowledge-truth knowledge)
          (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
              entity)
          (:F ;; A database-level rejection. MECHANICALLY NEAR-UNREACHABLE HERE: this
              ;; table has no unique key and no FOREIGN KEY, so there is nothing for the
              ;; INSERT to violate — which is exactly why the singleton and referential
              ;; laws had to be written in the :around above. If this is ever reached,
              ;; the schema has gained a constraint and the :around checks have become
              ;; redundant, not sufficient.
              (make-instance 'nst-entity-contradiction
                             :tenant-id (slot-value company 'row-id)
                             :reason (format nil "Vendor ~A: the INSERT was rejected at the database. This table declares no unique key, so a rejection here means the schema changed under this verb — the :around singleton check is no longer sufficient. Investigate DOD_VPAYMENT_METHODS." (slot-value entity 'vendor-id))))
          (:U ;; The boundary failed: NOT a refusal, and we do not know whether the row was
              ;; written. → 503, never 404 and never a misleading 500.
              (domain-sentinel-from-knowledge
               knowledge ctx
               :reason (format nil "Vendor ~A payment-settings create: the database call did not answer — the row may or may not have been written, so this is unknown, not failed" (slot-value entity 'vendor-id))))
          (:C ;; Unreachable without a :pre-flight form, which this call does not supply.
              (error "Unreachable: no :pre-flight form was supplied to with-nst-db-create in this call — a :C here means the macro contract changed without this method being updated"))
          (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                            (bo-knowledge-truth knowledge))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 6 — fetch (स्मरण)
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod fetch ((entity-class (eql 'nst-vnd-vpm)) (id string) (ctx domain-ctx))
  "स्मरण प्रत्यय — recall the vendor's payment settings.

   🚨 ID IS THE VENDOR-ID, NOT A ROW-ID. This is the one place this entity departs from
   the tree's fetch convention, and it is forced rather than chosen: there is no
   enumerate on this entity (a vendor never has more than one row), so a client has no
   way to LEARN a row-id before asking for it. Addressing by the parent is therefore the
   only usable address — and it is also the honest one, because (vendor-id, tenant) IS
   this entity's identity.

   Returns a real nst-vnd-vpm or a Belnap sentinel — never a bare CL nil (adhara §6's
   fetch contract). A vendor with NO payment row (vendor 18 is such a vendor, live) gets
   nst-entity-nil → 404, which is the correct REST answer: absent until created."
  (declare (ignore entity-class))
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (vid (vpm-vendor-id-from-string id)))
    (if (null vid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a vendor (vendor-ids are integers)" id))
        (let ((knowledge (with-db-call
                             (select-vpm-by-vendor-in-tenant vid tenant-id)
                           "nst-vnd-vpm/fetch (vendor-id, session tenant)")))
          (domain-result-from-knowledge
           knowledge ctx
           :hydrate (lambda (dbobj) (vpm-hydrate dbobj vid company))
           :reason (lambda (truth)
                     (case truth
                       (:F (format nil "Vendor ~A has no payment settings in this tenant (none created, or the row was deleted out of band)" vid))
                       (:U (format nil "Vendor ~A payment settings: the database call did not answer — whether settings exist is unknown" vid))
                       (:C (format nil "Vendor ~A returned more than one payment-settings row — the singleton law is violated, which no key prevents. Investigate DOD_VPAYMENT_METHODS directly" vid)))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 7 — !update (!state)
;;; ═══════════════════════════════════════════════════════════════════════════

(defparameter *vpm-update-forbidden-fields*
  '(:vendor-id)
  "Initargs !update REFUSES. ONE field, and it is not a secret.

   WHY :vendor-id IS REFUSED RATHER THAN STRIPPED. It is the PARENT LINK — half of this
   entity's identity. Letting a generic field update rewrite it re-points a vendor's
   payment settings at a DIFFERENT VENDOR without touching the tenant, which is exactly
   the intra-tenant BOLA that tenant scoping cannot see: vendor X could hand its (or
   another vendor's) settings row to vendor Y inside one company. Re-parenting is not a
   configuration edit, it is a move, and it would need its own verb with its own
   authorization — one that does not exist and is not wanted.

   NOTE THE CONTRAST WITH nst-vnd, whose list is the four credential columns. This
   entity holds NO SECRETS — the flags are five booleans. The forbidden field here
   protects STRUCTURE, not confidentiality, and a reader who copies the profile's
   reasoning across will be looking for the wrong hazard.

   This is a POLICY list about the TRANSPORT (what a caller may set), not about the
   domain: the copier moves vendor-id, because the INSERT needs it.")

(defmethod !update ((entity-class (eql 'nst-vnd-vpm)) (vendor-id string) (ctx domain-ctx)
                    &rest update-args)
  "!state प्रत्यय — partial update of one vendor's payment settings.

   ADDRESSED BY VENDOR-ID, not row-id, for the same reason fetch is: the client has no
   way to learn a row-id. The generic function names this argument row-id; the name is
   positional, and the address this entity has is its parent.

   Only the initargs actually supplied change (CLOS reinitialize-instance), so an
   omitted flag keeps its stored value: the entity is hydrated from the row BEFORE the
   new values are applied, and the whole instance is written back.

   BOTH CHECKS RUN BEFORE THE SELECT, because a malformed request is malformed whether
   or not the target exists — and telling the client about its own bad field beats
   telling it about a 404 it would then go and fix the wrong thing about.

   No :pre-flight is passed to with-nst-db-update: existence was already established by
   the SELECT below."
  (declare (ignore entity-class))
  ;; CHECK 1 — non-editable fields, by PRESENCE rather than by value. nst-vnd tests
  ;; (getf args field), which lets an explicit :password nil through; here presence is
  ;; the honest test, because sending the field at all is the mistake.
  (dolist (field *vpm-update-forbidden-fields*)
    (when (member field update-args :test #'eq)
      (error 'vpm-field-rejected
             :field field
             :why "this is the parent link and half of this entity's identity — re-pointing a settings row at another vendor is not a configuration edit. Set the vendor whose settings you mean instead.")))
  ;; CHECK 2 — an explicit NIL flag. NOT repaired here (see the file header for why the
  ;; asymmetry with make is deliberate): in an update the caller is stating an intent,
  ;; the columns are nullable, and there is no way to express 'unset' that does not
  ;; store a NULL — which this table's view-class reads back as "Y", silently ENABLING
  ;; the method. Refusing names the field; quietly defaulting would invent a value the
  ;; caller did not ask for.
  (dolist (pair *vpm-flag-defaults*)
    (when (and (member (car pair) update-args :test #'eq)
               (null (getf update-args (car pair))))
      (error 'vpm-field-rejected
             :field (car pair)
             :why "supplied as NIL, but a NULL flag is not 'unset' — the view-class maps it back to a value and it would silently enable this payment method. Send \"N\" to disable it.")))
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (vid (vpm-vendor-id-from-string vendor-id)))
    (if (null vid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a vendor (vendor-ids are integers)" vendor-id))
        (let ((dbobj (select-vpm-by-vendor-in-tenant vid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Vendor ~A has no payment settings in this tenant — there is no row to update. Create them first." vid))
              (let ((entity (vpm-hydrate dbobj vid company)))   ; current stored state
                (let ((args (copy-list update-args)))
                  (remf args :row-id)
                  (apply #'reinitialize-instance entity args))  ; only supplied keys change
                ;; Same कारक rule as make: a caller-supplied :company must not be able to
                ;; move an EXISTING row to another tenant. Re-set AFTER the reinitialize
                ;; so the session company always wins.
                (setf (company entity) company)
                ;; Belt-and-braces against an explicit NIL reaching the copier on this
                ;; path: CHECK 2 above already refuses it, so this only fires if that
                ;; guard is removed. It writes the default rather than NULL.
                (vpm-apply-flag-defaults entity)
                (copyVpm-domaintodb entity dbobj)
                (let ((knowledge (with-nst-db-update (:source "nst-vnd-vpm/!update")
                                    (clsql:update-records-from-instance dbobj)
                                    dbobj)))
                  (case (bo-knowledge-truth knowledge)
                    (:T entity)
                    (:U ;; The write did not complete and the row's state is unknown →
                        ;; 503, not a 500 and NOT 404: the row exists, we simply cannot
                        ;; report what happened to it.
                        (domain-sentinel-from-knowledge
                         knowledge ctx
                         :reason (format nil "Vendor ~A payment-settings update: the database call did not answer — the row's current state is unknown" vid)))
                    (:F ;; Unreachable: with-nst-db-update was called without
                        ;; :pre-flight, and the row was already confirmed by the SELECT.
                        (error "Unreachable: with-nst-db-update without :pre-flight cannot return :F (vendor ~A)" vid))
                    (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-update"
                                      (bo-knowledge-truth knowledge)))))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 8 — The reverse ferry — domain->response + render-json
;;;
;;; ONLY TWO METHODS ARE DEFINED HERE, deliberately. The rest of this surface is
;;; already ENTITY-GENERIC in this tree, and redefining ANY of it would silently
;;; replace the warehouse's and products' versions — same generic function, same
;;; specializer:
;;;
;;;   * domain->response on nst-entity-nil / -unknown / -contradiction specializes on
;;;     the SENTINEL classes, not on nst-vnd-vpm, so a payment-settings fetch miss
;;;     already ferries to nst-response-nil → 404 with no payment-specific code
;;;     (warehouse/nst-bl-whsapi.lisp:280-299).
;;;   * domain->response on (eql t) — the delete! ack — dispatches on T, but this
;;;     entity has NO delete!, so that path is not reachable here at all.
;;;   * render-json on LIST, and domain->response-list, are thin mapcars over the
;;;     per-element methods, so they already cover VpmResponseModel
;;;     (warehouse/nst-bl-whsapi.lisp:526).
;;;   * render-json on the three sentinel response models
;;;     (warehouse/nst-bl-whsapi.lisp:320-335).
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod domain->response ((entity nst-vnd-vpm) (ctx domain-ctx))
  "Reverse ferry (adhara §4): nst-vnd-vpm → VpmResponseModel.

   entity is the ONLY dispatching argument that may be an nst-domain-entity, and the
   entity itself never crosses into Ring 4 — only the boundary object does.

   THE CLASS IS THE ALLOWLIST. Unlike nst-vnd, whose row holds four secrets and where
   this exclusion is a security boundary, THIS TABLE HOLDS NO SECRETS — the flags are
   five booleans and an active marker. So what is withheld here is withheld for
   correctness rather than confidentiality:

     vendor-id     the parent link. Publishing it would invite a client to believe it
                   can address another vendor's row, which is the intra-tenant BOLA the
                   actor slot (CONTEXT §12.3 decision 3) exists to close, and it is the
                   field !update REFUSES for exactly that reason.
     tenant-id     the कारक. Automatically injected from the session; never a client
                   field, and never client-addressable.
     company       the tenant OBJECT. A boundary object has no business carrying a
                   domain entity out of Tree 1.
     created-at    database-maintained audit. Not a client field.
     updated-at    has NO COLUMN behind it on this table at all — DOD_VPAYMENT_METHODS
                   has no updated column, so this slot is a domain-layer timestamp and
                   publishing it would publish a value that goes nowhere.
     deleted-state the row is either returned or it is not. A soft-delete is expressed
                   at the boundary as a 404, never as a field on a 200.

   The NO-SECRETS point is worth stating plainly because it changes what a mistake
   costs: if someone adds a slot to VpmResponseModel and copies it here by reflex, the
   worst case is an extra field on the wire — not a leaked credential, which is what the
   same mistake would mean in the profile twin."
  (declare (ignore ctx))
  (let ((destination (make-instance 'VpmResponseModel)))
    (setf (row-id destination)            (row-id entity))
    (setf (codenabled destination)        (codenabled entity))
    (setf (upienabled destination)        (upienabled entity))
    (setf (payprovidersenabled destination) (payprovidersenabled entity))
    (setf (walletenabled destination)     (walletenabled entity))
    (setf (paylaterenabled destination)   (paylaterenabled entity))
    (setf (active-flag destination)       (active-flag entity))
    destination))

(defmethod render-json ((r VpmResponseModel) (ctx domain-ctx))
  "Single vendor payment-settings record → JSON ALIST.

   The contract is split in this tree on purpose: a per-ENTITY method returns a Lisp
   structure, while the per-LIST and sentinel methods return already-encoded text, and
   the dispatcher's render hop normalises the two.

   THE ALIST IS THE FIELD ALLOWLIST and the LAST gate in front of the transport. It
   publishes nothing that VpmResponseModel does not declare, and that class declares no
   vendor-id, tenant-id, company, created-at, updated-at or deleted-state.

   IDS ARE STRINGS via response-id-string, the one id convention for every entity:
   rowId arrives from an integer column.

   FLAG CONVENTION: every flag publishes as a BOOLEAN through vnd-flag->boolean, so the
   keys are named for what they MEAN rather than for the column — \"codEnabled\", not
   \"codEnabledFlag\". This follows products and the vendor profile, and diverges from
   warehouse, which publishes activeFlag as the raw string \"Y\"/\"N\". That divergence
   is flagged, un-unified, and worth one deliberate pass before any of these endpoints
   has external consumers (nst-bl-vnd.lisp:957-961).

   ⚠ A NULL FLAG PUBLISHES AS TRUE — WHICH IS WHY make AND !update GUARD THE COLUMN.
   By the time a value reaches this method it has already been through the legacy
   view-class, whose :void-value maps a stored NULL to a STRING: \"Y\" for every flag on
   this table, including PAYLATERENABLED, even though the DDL default for that column is
   'N'. vnd-flag->boolean then turns \"Y\" into T (products/dod-bl-prd.lisp:1290, whose
   own docstring records exactly this NULL-through-:void-value path). So an unset flag
   does not publish as null or as false — it publishes as ENABLED, which is the single
   worst answer a payment switch can give. That is why make substitutes the live DDL
   default instead of writing a NULL, and why !update refuses a flag sent as an explicit
   nil outright. This method reports what is stored; it does not repair it, and it must
   not — a silent repair here would hide the one state a human needs to see."
  (declare (ignore ctx))
  (list
   ;; IDENTITY
   (cons "rowId"               (response-id-string (row-id r)))
   ;; THE FIVE FLAGS — the entire published surface of this entity.
   (cons "codEnabled"          (vnd-flag->boolean (codenabled r)))
   (cons "upiEnabled"          (vnd-flag->boolean (upienabled r)))
   (cons "payProvidersEnabled" (vnd-flag->boolean (payprovidersenabled r)))
   (cons "walletEnabled"       (vnd-flag->boolean (walletenabled r)))
   (cons "payLaterEnabled"     (vnd-flag->boolean (paylaterenabled r)))
   ;; STATUS
   (cons "active"              (vnd-flag->boolean (active-flag r)))))
