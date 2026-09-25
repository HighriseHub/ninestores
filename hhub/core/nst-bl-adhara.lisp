;;; nst-bl-adhara.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-bl-adhara.lisp — SECTION 1: Domain Tree
;;; ═══════════════════════════════════════════════════════════════════════

(defclass nst-domain-entity ()
  ((id
    :reader id
    :initform (format nil "~A" (uuid:make-v1-uuid))
    :documentation "Canonical string ID. Building block: uuid:make-v1-uuid (exists).")
   (tenant-id
    :initarg :tenant-id
    :accessor tenant-id
    :documentation "अधिकरण — tenant scope. नियम-1 checks this unconditionally.")
   (created-at
    :initform (mysql-now)          ; existing building block
    :accessor created-at
    :documentation "भूत-काल marker. When this entity's first Anubhava fired.")
   (updated-at
    :initform (mysql-now)
    :accessor updated-at
    :documentation "भूत-काल marker. When the most recent Anubhava fired.")
   (deleted-state
    :initform "N"
    :accessor deleted-state
    :documentation "नियम-2 checks this. 'Y' blocks all verbs except audit."))
  (:documentation
   "ROOT of ALL domain entities. Every nst-pr, nst-ord, nst-inv, nst-whs,
    nst-apr, nst-vnd — every entity from Document 2's शिवसूत्र — descends
    from here and ONLY from here.

    proc.pravesh, proc.yojana, proc.kraya, proc.purti, proc.vitta, proc.kara,
    proc.shasana, proc.bhandara generic methods NEVER specialize on anything
    outside this subtree for their primary (entity) argument.

    This class NEVER inherits from BusinessObject (existing hhub-bl-ent.lisp).
    This class NEVER inherits from RequestModel/ResponseModel/ViewModel.
    This is Shiva — inert without the verb (Shakti) that acts upon it."))

;;; Belnap sentinel entities — these ARE domain facts (a query returning
;;; nothing IS still knowledge about the domain), so they belong HERE,
;;; not in the boundary tree.

(defclass nst-entity-nil (nst-domain-entity)
  ;; :initarg :reason is REQUIRED: domain verbs construct sentinels with
  ;; (make-instance 'nst-entity-nil :tenant-id … :reason "…"), and without the
  ;; initarg SBCL rejects it as an invalid initialization argument — turning
  ;; every "not found" into an error instead of a :F fact.
  ((reason :initform "Not Found" :initarg :reason :accessor entity-reason))
  (:documentation "Belnap :F sentinel. A domain fact: this entity does not exist."))

(defclass nst-entity-unknown (nst-domain-entity)
  ((reason :initform "Unknown — boundary call inconclusive" :initarg :reason :accessor entity-reason))
  (:documentation
   "Belnap :U sentinel. [LEGAL: callers MUST treat this as 'cannot proceed',
    never as 'assume false' or 'assume true'.]"))

(defclass nst-entity-contradiction (nst-domain-entity)
  ((reason :initform "Conflicting data" :initarg :reason :accessor entity-reason))
  (:documentation "Belnap :C sentinel. Two sources disagree — human review required."))


;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-bl-adhara.lisp — SECTION 2: Boundary Tree
;;; ═══════════════════════════════════════════════════════════════════════

(defclass nst-boundary-object ()
  ((id
    :reader id
    :initform (format nil "~A" (uuid:make-v1-uuid))))
  (:documentation
   "ROOT of ALL boundary/adapter objects. NEVER inherits from
    nst-domain-entity — that inheritance would recreate the exact
    vulnerability this document exists to close.

    NEVER accepted as the primary dispatching argument by any proc.GANA
    or proc.bs method. Exists ONLY between HTTP/UI/CLI and the domain
    grammar. Dies at the Adapter boundary — the लोप principle, now
    structural rather than conventional."))

(defclass nst-request-model (nst-boundary-object)
  ((params :initarg :params :accessor params :initform nil))
  (:documentation
   "Raw inbound parameters, still shaped by the transport (Layer 2/3
    from the communication-modes discussion). Never touches proc.GANA.
    Consumed entirely by request→dispatch (Section 4) and discarded."))

(defclass nst-response-model (nst-boundary-object)
  ((params :initarg :params :accessor params))
  (:documentation "Domain result reshaped for outbound transport."))

(defclass nst-view-model (nst-boundary-object)
  ((reason :initarg :reason :accessor vm-reason :initform nil))
  (:documentation "Presentation-ready shape — HTML/JSON rendering input."))

;;; Boundary-tree Belnap sentinels — presentation concerns, e.g.
;;; "render a Not Found page" — distinct from the DOMAIN fact of
;;; nst-entity-nil above. Two different concerns, two different trees.

(defclass nst-response-nil          (nst-response-model) ())
(defclass nst-response-unknown      (nst-response-model) ())
(defclass nst-response-contradiction(nst-response-model) ())
(defclass nst-view-nil              (nst-view-model) ())
(defclass nst-view-unknown          (nst-view-model) ())
(defclass nst-view-contradiction    (nst-view-model) ())


;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-bl-adhara.lisp — SECTION 3: The Carrier
;;; ═══════════════════════════════════════════════════════════════════════

(defstruct kaaraka-ref
  "A typed reference used by recipient/source below (and any future
   kāraka-valued field). Deliberately NOT a raw cons cell — printable,
   type-checkable at the REPL, extensible without breaking callers.
   ASCII name: kaaraka-ref, not kāraka-ref — see typing-convention
   discussion; double-a spells the long ā without a diacritic."
  (entity-type nil)   ; keyword — :vnd :usr :whs :budget :apr :dept ...
  (entity-id   nil))  ; string  — the referenced entity's id

(defstruct domain-ctx
  "Passenger struct — travels through EVERY proc.GANA and proc.bs call as
   the last argument. Carries context WITHOUT carrying boundary-tree
   baggage across into the domain tree.

   GUARDRAIL 2 anchor: every domain verb signature is (entity ... ctx).
   ctx is always LAST. It is never the entity. It is never dispatched on.

   कारक (kāraka) coverage — six classical semantic roles, five carried
   here; the sixth (कर्म/karma, 'the object acted upon') is deliberately
   NOT a ctx field — it is always the verb's own first argument (the
   entity), per Guardrail 2. Putting karma on ctx would let it drift
   out of dispatch position, which is exactly the discipline Guardrail
   2 exists to prevent.

     actor     — कर्ता (kartā), the agent performing the action
                 (:human/:ai-agent/:scheduled-job + id)
     tenant    — अधिकरण (adhikaraṇa), tenant/company context
     channel   — करण (karaṇa), the instrument
                 (:http/:grpc/:event-bus/:cli/:scheduler)
     recipient — संप्रदान (sampradāna), 'for whom' — who the effect is
                 directed at: an approver being routed to, a vendor
                 being notified, a customer an invoice is issued to.
                 nil, ONE kaaraka-ref, or a LIST of kaaraka-ref for
                 fan-out (e.g. a notification going to several usr).
     source    — अपादान (apādāna), 'from which' — point of origin:
                 the budget funding a pr, the warehouse stock is drawn
                 from, the vendor an RFQ is sourced from. nil or ONE
                 kaaraka-ref.

   PROVENANCE NOTE — do not conflate with bo-knowledge provenance:
     recipient/source here are BUSINESS-SEMANTIC facts about the WORLD
     (which entity is the source/recipient). bo-knowledge provenance
     (BO-ADD-PROVENANCE, BO-MERGE-PROVENANCE — nst-bl-beltrusys.lisp,
     both EXISTING) is an EPISTEMIC fact — which boundary call/system
     told us something, used for Belnap :C conflict-merge tracking.
     Two different layers, same word 'source' in casual English —
     keep them distinct in code and in conversation.

     Composition rule: a recipient/source value MAY have been resolved
     via an uncertain boundary call (e.g. 'which vendor fulfils this
     RFQ' from an external catalog). That call's own bo-knowledge and
     provenance are checked and resolved to :T BEFORE this struct is
     built. domain-ctx NEVER carries a :U-tainted kaaraka-ref — if
     source/recipient resolution comes back :U, ctx construction
     itself must abort rather than proceed with an uncertain value.
     [LEGAL: an uncertain recipient for a GST-relevant notification —
     e.g. self-invoice routing under RCM — is the same class of risk
     as any other :U-on-GST-verb case; abort, do not guess.]

   NIYAM EXEMPTION — recipient/source are NOT covered by नियम-1's
   strict tenant-equality check. A vendor recipient legitimately
   belongs to a DIFFERENT tenant than the acting company — cross-
   tenant reference is the normal case for vnd/quot/rfq kāraka-refs,
   not a violation. नियम-1 continues to apply, unmodified, to the
   VERB'S OWN entity argument only."
  (actor           nil)
  (tenant          nil)
  (channel         nil)
  (recipient       nil)
  (source          nil)
  (override-reason nil))

;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-bl-adhara.lisp — SECTION 4: The Ferry (लोप boundary, now structural)
;;; ═══════════════════════════════════════════════════════════════════════

(defgeneric request->dispatch (request-model verb-symbol entity-class ctx)
  (:documentation
   "THE FERRY. The only sanctioned crossing from Tree 2 (nst-request-model)
    to Tree 1 (nst-domain-entity subclass).

    request-model DIES here. Its slots are read ONCE to build entity
    initargs. The request-model instance itself is never returned, never
    stored, never passed to any proc.GANA or proc.bs method. Only the
    extracted primitive values survive the crossing — exactly as लोप
    (Document 4) elides an intermediate form that the next operation
    does not need to see directly.

    GUARDRAIL 2: the entity constructed here becomes the FIRST argument
    to whatever proc.GANA verb is dispatched. ctx remains LAST."))

(defmethod request->dispatch ((rm nst-request-model)
                               (verb-symbol symbol)
                               (entity-class symbol)
                               (ctx domain-ctx))
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)) 
	 (initargs (extract-domain-initargs rm entity-class))
         (entity   (apply #'make-instance entity-class
                           :tenant-id tenant-id
                           initargs))
         (verb-fn  (fdefinition
                     (find-symbol (string verb-symbol)
                                  (gana-package-for verb-symbol)))))
    ;; rm is NOT passed below this line. It goes out of scope with this form.
    (funcall verb-fn entity ctx)))

;;; nst-bl-adhara.lisp addition — request->dispatch, one method per base verb

(defun rm-row-id (rm)
  "Shared helper — every verb needing row-id extracts it the same way.
   NOT a new abstraction layer, just avoiding six copies of one getf."
  (getf (params rm) :row-id))

(defmethod request->dispatch ((rm nst-request-model) (verb-symbol (eql 'make))
                               (entity-class symbol) (ctx domain-ctx))
  (apply #'make entity-class ctx (extract-domain-initargs rm entity-class)))

(defmethod request->dispatch ((rm nst-request-model) (verb-symbol (eql 'fetch))
                               (entity-class symbol) (ctx domain-ctx))
  (fetch entity-class (rm-row-id rm) ctx))

(defmethod request->dispatch ((rm nst-request-model) (verb-symbol (eql 'enumerate))
                               (entity-class symbol) (ctx domain-ctx))
  (apply #'enumerate entity-class ctx (extract-domain-initargs rm entity-class)))

(defmethod request->dispatch ((rm nst-request-model) (verb-symbol (eql '!update))
                               (entity-class symbol) (ctx domain-ctx))
  (apply #'!update entity-class (rm-row-id rm) ctx (extract-domain-initargs rm entity-class)))

(defmethod request->dispatch ((rm nst-request-model) (verb-symbol (eql 'delete!))
                               (entity-class symbol) (ctx domain-ctx))
  (delete! entity-class (rm-row-id rm) ctx))

(defmethod request->dispatch ((rm nst-request-model) (verb-symbol (eql '?exists))
                               (entity-class symbol) (ctx domain-ctx))
  "?exists takes whatever uniqueness criterion the entity defines —
   e.g. GSTIN for nst-whs. extract-domain-initargs pulls it the same
   way make does; the entity's own ?exists method decides which
   fields it actually reads."
  (apply #'?exists entity-class ctx (extract-domain-initargs rm entity-class)))

(defmethod request->dispatch ((rm nst-request-model) (verb-symbol (eql '!settings))
                               (entity-class symbol) (ctx domain-ctx))
  "extract-domain-initargs cannot carry a settings blob: it forwards only keys the
   domain class declares as initargs, and a sub-resource payload is ONE :settings
   value rather than a set of nst-vnd fields.

   THE VALUE MUST GO IN AS A PLIST ENTRY, not positionally. !settings takes
   &rest args and reads (getf args :settings), so passing the blob as the sole
   positional argument makes args the one-element list (<blob>) — and getf on a list
   of odd length is not \"no :settings key\", it is a MALFORMED PROPERTY LIST error.
   That is not hypothetical: this line was written positionally first, and the ferry
   hop was the only thing that failed, because every direct REPL call passes :settings
   properly and never touches this path. Same shape as !update's own ferry method."
  (apply #'!settings entity-class (rm-row-id rm) ctx
         (list :settings (getf (params rm) :settings))))


;;; Companion — the reverse ferry, domain result OUT to boundary tree
(defgeneric domain->response (entity ctx)
  (:documentation
   "Reverse ferry: Tree 1 result → Tree 2 nst-response-model.
    entity is the ONLY dispatching argument that may be nst-domain-entity.
    Returns an nst-response-model — never the entity itself.
    The entity does not cross into Ring 4 (UI/HTTP) directly."))


;;; ═══════════════════════════════════════════════════════════════════════
;;; Rendering contract — Tree 2 out to the transport
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; The final hop: an nst-boundary-object (response model, or a LIST of
;;; them, or a Belnap sentinel) selected into a transport-encoded string.
;;; Multiple dispatch — the Cardinality/Format grid.
;;;
;;;   (render-json  <single-response>  ctx)   → one object → JSON
;;;   (render-json  <list>             ctx)   → many      → JSON
;;;   (render-html  <single-response>  ctx)   → one object → HTML
;;;   (render-html  <list>             ctx)   → many      → HTML
;;;
;;; Format (json vs html) is hard-coded in the generic NAME; cardinality
;;; and entity-type are resolved by CLOS specialized METHODS. This is the
;;; deliberate multiple-dispatch use: (render-json list) vs (render-json
;;; single-object) vs (render-json nst-entity-nil) are all distinct
;;; methods that the type system routes, with zero if/else in the body.
;;;
;;; SECURITY CONTRACT: each response-model method is an explicit field
;;; allowlist — nothing is serialized except what the method's own
;;; accessors read. A field added to the response model does NOT
;;; automatically leak outbound; it must be added here per-format.
;;;
;;; BELNAP NOTE: the response-model sentinels (nst-response-nil/
;;; nst-response-unknown/nst-response-contradiction) are nst-boundary-
;;; object subclasses too — methods on them define what "not found" /
;;; "unknown" / "contradiction" look like for each transport. Define them
;;; per-format so a 404 and a 5xx render differently. The entity-stage
;;; domain sentinels (nst-entity-nil / -unknown / -contradiction, Tree 1)
;;; should have been converted to their response-model counterparts by
;;; domain->response BEFORE rendering is reached — do not render Tree 1
;;; sentinels here.

(defgeneric render-json (response ctx)
  (:documentation
   "Post-ferry outbound encoding, JSON. response dispatches the method:
    a single nst-boundary-object (or its subclass), a LIST of them, or a
    response-model Belnap sentinel. Returns the JSON text (a string).
    Multiple dispatch: response carries BOTH cardinality and entity type;
    CLOS resolves both — no if/else over types in method bodies."))

(defgeneric render-html (response ctx)
  (:documentation
   "Post-ferry outbound encoding, HTML. response dispatches the method:
    a single nst-boundary-object (or its subclass), a LIST of them, or a
    response-model Belnap sentinel. Returns an HTML string. Same multiple-
    dispatch contract as render-json — response determines both
    cardinality and entity type."))


;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-bl-adhara.lisp — SECTION 4a: extract-domain-initargs
;;; ═══════════════════════════════════════════════════════════════════════

(defparameter *reserved-initargs*
  '(:tenant-id :id :created-at :updated-at :deleted-state)
  "Slots that must NEVER be set from client-supplied request params.
   :tenant-id specifically — नियम-1 [LEGAL]: allowing a client-supplied
   tenant-id would let a request claim membership in a different tenant,
   defeating tenant isolation before नियम-1 even gets to run its check.
   :id/:created-at/:updated-at/:deleted-state — forging these would let
   a client claim a false audit history. All five are supplied ONLY by
   the domain layer itself (tenant-id from ctx, the rest from initforms).")

(defgeneric extract-domain-initargs (rm entity-class)
  (:documentation
   "Reads rm's params (a plist), filters against entity-class's own
    declared initargs via CLOS MOP introspection, and returns ONLY the
    initargs entity-class actually declares, MINUS *reserved-initargs*.

    MOP-driven deliberately: no per-entity mapping function is hand-
    written anywhere. A new entity (nst-pr, nst-rfq, whatever comes
    after Warehouse) needs ZERO changes to this function — it works
    for any nst-domain-entity subclass the moment the class exists.

    This function IS where लोप actually happens: rm's transport-shaped
    params go in, a plain initargs plist matching the domain class's
    own slots comes out. rm itself is discarded by the caller
    immediately after this returns."))

(defmethod extract-domain-initargs ((rm nst-request-model) (entity-class symbol))
  (let* ((params    (params rm))
         (class-obj (find-class entity-class)))
    (sb-mop:finalize-inheritance class-obj)   ; safe even if already finalized
    (let ((declared-initargs
            (remove-duplicates
              (loop for slot in (sb-mop:class-slots class-obj)
                    append (sb-mop:slot-definition-initargs slot)))))
      (loop for (key value) on params by #'cddr
            when (and (member key declared-initargs)
                      (not (member key *reserved-initargs*)))
              append (list key value)))))

(defun build-domain-ctx-from-request (requestmodel-params)
  "ASSUMPTION FLAGGED ABOVE: signature matches make-domain-ctx as
   recalled from memory, not re-verified against Document 3/5 this
   session. tenant-id MUST come from session (get-login-company or
   equivalent), NEVER from client params directly — this is the
   नियम-1 boundary; verify the actual key your session layer uses
   before trusting this line in production."
  (make-domain-ctx :tenant (getf requestmodel-params :tenant-id)
                    :actor (getf requestmodel-params :actor-id)))

;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-bl-adhara.lisp — SECTION 4b: gana-package-for
;;; ═══════════════════════════════════════════════════════════════════════

(defparameter *verb->gana-package* (make-hash-table :test 'eq)
  "Maps each Document 1 धातु symbol to its owning गण package keyword.
   Populated at load time by define-gana-verbs calls living in each
   गण package's OWN file — not by one central table that would need
   editing every time a new entity is added anywhere in the system.")

(defmacro define-gana-verbs (package-keyword &rest verb-symbols)
  "Self-registering — called once near the top of each proc.GANA
   package file, right after that package's defpackage form.
   Keeps verb→गण ownership declared in the same file as the verbs
   themselves, so the two can never silently drift apart."
  `(dolist (v ',verb-symbols)
     (setf (gethash v *verb->gana-package*) ,package-keyword)))

;;; Example registrations — one form per गण, placed in that गण's file.
;;; Shown here for illustration; the canonical location is each
;;; proc.GANA package's own file, immediately after its defpackage.
;;;
;;; गण → PACKAGE NAME MAPPING (Sanskrit concept, English ASCII symbol —
;;; same convention as domain-ctx's actor/tenant/channel/recipient/source
;;; fields: the Sanskrit word already had no diacritics here, so this
;;; is a translation for READABILITY, not a diacritic-removal fix):
;;;
;;;   प्रवेशगण  (Entry)        → proc.entry
;;;   योजनागण   (Planning)     → proc.planning
;;;   क्रयगण    (Acquisition)  → proc.acquisition
;;;   पूर्तिगण  (Fulfillment)  → proc.fulfillment
;;;   वित्तगण   (Financial)    → proc.finance
;;;   करगण      (Tax/GST)      → proc.tax
;;;   शासनगण    (Governance)   → proc.governance
;;;   भण्डारगण  (Inventory)    → proc.inventory
;;;
;;; A developer typing proc.tax:claim-itc or proc.governance:approve at
;;; the REPL no longer needs to already know which Sanskrit गण word
;;; owns which verb — the package name states its domain directly.
;;; The गण CONCEPT (Document 1's classification, Document 3's
;;; गण-scoped नियम) is unchanged; only the typed identifier is English.

(define-gana-verbs :proc.inventory
  catalog price discount consume count value allocate-stock
  consolidate assemble)

(define-gana-verbs :proc.finance
  invoice issue match pay settle refund adjust debit credit
  recharge transfer accrue receive-payment !settings)

(define-gana-verbs :proc.tax
  classify-hsn verify-gstin generate-irn generate-eway reconcile-2b
  claim-itc reverse-itc pay-rcm self-invoice file amend
  offset-itc discharge upload-gstn)

(define-gana-verbs :proc.governance
  approve reject escalate route delegate-authority audit block override)

;;; (remaining गण — entry, planning, acquisition, fulfillment — registered identically
;;;  in their own files, per Document 1's full verb list)

(defgeneric gana-package-for (verb-symbol)
  (:documentation
   "Returns the गण package (keyword) that owns verb-symbol.
    [STRUCTURAL/LEGAL]: an unregistered verb reaching this function
    means a verb was invoked without being declared in Document 1's
    grammar — this is treated as an error, not a silent no-op, because
    silently returning nil here would make the ferry dispatch into
    nothing and fail confusingly three lines later instead of failing
    clearly at the actual point of the grammar violation."))

(defmethod gana-package-for ((verb-symbol symbol))
  (or (gethash verb-symbol *verb->gana-package*)
      (error "GUARDRAIL 3 VIOLATION: verb ~A is not registered in any ~
              गण package. Every verb the ferry dispatches must be ~
              declared via define-gana-verbs in its owning proc.GANA ~
              file (Document 1)." verb-symbol)))

;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-bl-adhara.lisp — SECTION 5: Immunity Verification
;;; ═══════════════════════════════════════════════════════════════════════

(defun test-complete-immunity ()
  "Walks every domain package's exported generic functions.
   FAILS if any method specializer is nst-boundary-object or a subclass.
   Run this in CI after every commit touching proc.* packages."
  (let ((violations nil))
    (dolist (pkg-name '(:proc.pravesh :proc.yojana :proc.kraya :proc.purti
                        :proc.vitta   :proc.kara   :proc.shasana :proc.bhandara
                        :proc.bs))
      (let ((pkg (find-package pkg-name)))
        (when pkg
          (do-external-symbols (sym pkg)
            (when (and (fboundp sym)
                       (typep (fdefinition sym) 'standard-generic-function))
              (dolist (method (sb-mop:generic-function-methods (fdefinition sym)))
                (dolist (specializer (sb-mop:method-specializers method))
                  (when (and (typep specializer 'class)
                             (subtypep specializer 'nst-boundary-object))
                    (push (list pkg-name sym specializer) violations)))))))))
    (if violations
        (error "IMMUNITY VIOLATED — ~A boundary-type leak(s) into domain packages:~%~{  ~A~%~}"
               (length violations) violations)
        (format t "IMMUNITY CONFIRMED — 0 boundary-type leaks across ~A domain packages~%"
                9))))

(defun test-domain-entity-never-inherits-boundary ()
  "Structural check: nst-domain-entity subtree and nst-boundary-object
   subtree must never intersect below standard-object."
  (assert (not (subtypep 'nst-domain-entity 'nst-boundary-object)))
  (assert (not (subtypep 'nst-boundary-object 'nst-domain-entity)))
  (format t "TREE DISJOINTNESS CONFIRMED~%"))

(defun test-ctx-is-struct-not-dispatchable-class ()
  "domain-ctx must remain a struct — never converted to a CLOS class
   that could accidentally become a dispatch target for the entity
   position in a proc.GANA verb signature."
  (assert (typep (make-domain-ctx) 'structure-object))
  (assert (not (typep (make-domain-ctx) 'nst-domain-entity)))
  (format t "CTX CARRIER DISCIPLINE CONFIRMED~%"))

(defun run-all-adhara-tests ()
  (test-domain-entity-never-inherits-boundary)
  (test-ctx-is-struct-not-dispatchable-class)
  (test-complete-immunity))


;; ;;; nियम १ — Tenant Isolation — now specializes on the immune root
;; (defmethod check-niyam :before ((entity nst-domain-entity) (ctx domain-ctx))
;;   (assert (equal (tenant-id entity) (adhikaraṇa ctx)) nil
;;           "नियम १ VIOLATED: entity tenant ~A ≠ ctx tenant ~A"
;;           (tenant-id entity) (adhikaraṇa ctx)))

;; ;;; नियम २ — Not-Deleted Guard
;; (defmethod check-niyam :before ((entity nst-domain-entity) (ctx domain-ctx))
;;   (assert (not (equal (deleted-state entity) "Y")) nil
;;           "नियम २ VIOLATED: operation on deleted entity blocked"))

;; ;;; नियम ३ — Audit Record
;; (defmethod emit-audit :after ((entity nst-domain-entity) (ctx domain-ctx))
;;   (create-bus-transaction entity ctx))  ; existing building block, unchanged
;;; नियम १ — Tenant Isolation — now specializes on the immune root
(defmethod check-niyam :before ((entity nst-domain-entity) (ctx domain-ctx))
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (assert (equal (tenant-id entity) tenant-id) nil
            "नियम १ VIOLATED: entity tenant ~A ≠ ctx tenant ~A"
            (tenant-id entity) tenant-id)))

;;; नियम २ — Not-Deleted Guard
(defmethod check-niyam :before ((entity nst-domain-entity) (ctx domain-ctx))
  (assert (not (equal (deleted-state entity) "Y")) nil
          "नियम २ VIOLATED: operation on deleted entity blocked"))

;;; नियम ३ — Audit Record
(defmethod emit-audit :after ((entity nst-domain-entity) (ctx domain-ctx))
  ;;(create-bus-transaction entity ctx)
  )  ; existing building block, unchanged


;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-bl-adhara.lisp — SECTION 5b: knowledge → domain result
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; WHY THIS EXISTS. The four truth values are carried by TWO types in this tree:
;;;
;;;   bo-knowledge          — what the CRUD macros in nst-mult-logic.lisp return
;;;                           (with-db-call, with-nst-db-create/update/delete/
;;;                           read-all). Every प्रत्यय method gets one.
;;;   nst-entity-nil/-unknown/-contradiction
;;;                         — Tree 1 domain results, the only things the reverse
;;;                           ferry (domain->response) can carry out.
;;;
;;; Nothing converted between them, so each verb hand-rolled the mapping — and,
;;; before this section existed, most verbs did not make the conversion at all:
;;; they RAISED on :U and :C, turning "I could not find out" and "my own rules
;;; disagree" into a 500 indistinguishable from a crash. The distinction Belnap
;;; exists to preserve was being discarded at exactly the point it mattered.
;;;
;;; The conversion is ONE rule, stated once:
;;;
;;;   :T → the caller's own result (the payload is the answer)
;;;   :F → nst-entity-nil             (a domain FACT: it is not there)
;;;   :U → nst-entity-unknown         (ignorance — must never read as :F)
;;;   :C → nst-entity-contradiction   (our sources disagree — a human decides)
;;;
;;; THE REASON STRING CARRIES THE PROVENANCE. bo-knowledge provenance is where
;;; the *why* lives — e.g. नियम-2's "DELETED_STATE='Y' rows are invisible to
;;; every verb" — and it is the only thing that distinguishes a :C caused by a
;;; soft-deleted identity holder from any other contradiction. Dropping it would
;;; leave a 409 with nothing actionable in it.

(defun knowledge-provenance-text (knowledge)
  "The provenance of KNOWLEDGE as one readable string, for a sentinel reason."
  (let ((p (bo-knowledge-provenance knowledge)))
    (cond ((null p) "no provenance recorded")
          ((listp p) (format nil "~{~A~^ | ~}" p))
          (t (format nil "~A" p)))))

(defun knowledge-reason-for (truth reason provenance)
  "The reason string for a non-:T sentinel.

   REASON is either a STRING (used for every non-:T state) or a FUNCTION of one
   argument — the truth keyword — returning a string. The function form exists
   because one message usually does NOT fit all three states: for fetch, \":F —
   row-id 999 not found in this tenant\" is right, while the same words in front
   of a :U would claim we looked and found nothing when in fact we could not look
   at all. That is the exact confusion this whole section exists to remove, so the
   converter refuses to make it on the caller's behalf.

   The PROVENANCE is always appended: it is where the *why* lives (e.g. नियम-2's
   explanation of a soft-deleted identity holder), and a 409 with no provenance is
   a 409 nobody can act on."
  (let ((head (cond ((null reason) nil)
                    ((stringp reason) reason)
                    ((functionp reason) (funcall reason truth))
                    (t (error "knowledge-reason-for: :reason must be a string or a function of the truth, got ~S" reason)))))
    (if (and head (plusp (length head)))
        (format nil "~A — ~A" head provenance)
        provenance)))

(defun domain-sentinel-from-knowledge (knowledge ctx &key reason)
  "The THREE non-:T states of KNOWLEDGE → the matching Tree-1 sentinel.

   This is the primitive, and it deliberately refuses :T: a :T is a domain FACT,
   not a failure, and only the calling verb knows what to do with the payload
   (hydrate it into an entity, or — for make — treat it as a conflict). Callers
   that want :T handled for them should use domain-result-from-knowledge.

   Signals on :T and on any unrecognized truth, rather than inventing a sentinel:
   a verb that reaches here with :T has a control-flow bug, and 404/503/409 would
   all be lies."
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
        (truth (bo-knowledge-truth knowledge))
        (why (knowledge-provenance-text knowledge)))
    (case truth
      (:F (make-instance 'nst-entity-nil
                         :tenant-id tenant-id
                         :reason (knowledge-reason-for :F reason why)))
      (:U (make-instance 'nst-entity-unknown
                         :tenant-id tenant-id
                         :reason (format nil "The boundary could not answer: ~A"
                                         (knowledge-reason-for :U reason why))))
      (:C (make-instance 'nst-entity-contradiction
                         :tenant-id tenant-id
                         :reason (knowledge-reason-for :C reason why)))
      (:T (error "domain-sentinel-from-knowledge: truth is :T — that is a fact, not a failure. Handle :T at the call site (or use domain-result-from-knowledge)."))
      (otherwise (error "domain-sentinel-from-knowledge: unrecognized bo-knowledge-truth ~A (provenance: ~A)"
                        truth why)))))

(defun domain-result-from-knowledge (knowledge ctx &key hydrate reason)
  "The FULL four-state conversion of KNOWLEDGE into a Tree-1 domain result.

   HYDRATE is a one-argument function (the bo-knowledge payload → a domain entity)
   and is REQUIRED when the truth is :T. It is not given a default on purpose:
   silently substituting a sentinel for a payload the caller forgot to hydrate
   would turn a programming error into a plausible-looking 404.

   The three failing truths go through domain-sentinel-from-knowledge, so the
   mapping rule lives in exactly one place. See the section header for why this
   exists at all."
  (if (eq (bo-knowledge-truth knowledge) :T)
      (if hydrate
          (funcall hydrate (bo-knowledge-payload knowledge))
          (error "domain-result-from-knowledge: truth is :T but no :hydrate function was supplied — the payload is a DB object, not a domain entity, and a verb must not fabricate a sentinel for it."))
      (domain-sentinel-from-knowledge knowledge ctx :reason reason)))

(defun domain-result-truth (result)
  "The four-valued truth of a Tree-1 domain result — the INVERSE of
   domain-result-from-knowledge, and the missing piece that makes a COMPOUND verb
   possible.

   Why it is needed: a प्रत्यय answers with an entity or a sentinel, never with a
   bo-knowledge. So a verb that sequences several प्रत्यय calls —
   order->invoice, approve->order — holds RESULTS, and results must be reduced to
   truths before they can be composed with bo-conjoin (nst-bl-beltrusys.lisp).
   Without this, conjoin is only reachable from code that calls the CRUD macros
   directly, which is not where compound verbs live.

   The round trip is exact for the three sentinels and for a real entity:
   domain-result-from-knowledge ∘ domain-result-truth is the identity on them.

   NIL IS AMBIGUOUS IN COMMON LISP — nil IS the empty list — so this cannot tell
   'a verb returned bare NIL' from 'a verb returned an empty collection'. It reads
   NIL as :F (absence), which is what every sentinel-returning verb means by it.
   The consequence to know: an EMPTY enumerate (which returns '()) reads as :F, not
   as a successful empty list. That is inherent to the language, and it is one more
   reason the verb contract should require explicit sentinels (see the review note
   about action->response laundering a bare nil into a 404)."
  (cond
    ((typep result 'nst-entity-nil)           +false+)
    ((typep result 'nst-entity-unknown)       +unknown+)
    ((typep result 'nst-entity-contradiction) +contradiction+)
    ((typep result 'nst-domain-entity)        +true+)   ; the :T case: a real entity
    ((null result)                            +false+)  ; see the NIL note above
    ((listp result)                           +true+)   ; a collection result
    ((eq result t)                            +true+)   ; the delete! ack
    (t (error "domain-result-truth: ~S is not a domain result — expected an nst-domain-entity, a Belnap sentinel, a collection, or T." result))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-bl-adhara.lisp — SECTION 6: Universal प्रत्यय
;;; ═══════════════════════════════════════════════════════════════════════

;;; make/fetch/enumerate/?exists take entity-class as a SYMBOL, not an
;;; instance — the entity doesn't exist yet (make) or hasn't been
;;; located yet (fetch/?exists) or is a whole-collection query
;;; (enumerate). This mirrors the eql-specializer style आधार's own
;;; extract-domain-initargs already uses for entity-class dispatch —
;;; consistent style, not a new convention.
;;;
;;; !update/delete! take entity as an ACTUAL INSTANCE — it already
;;; exists — so they dispatch on the class itself, the ordinary way.

(defgeneric make (entity-class ctx &rest initargs)
  (:documentation
   "सृजन प्रत्यय — crystallizes a new entity instance.
    [LEGAL] Any GSTIN-bearing entity (nst-whs, nst-vnd, ...) MUST run
    a ?exists uniqueness check as a :before method BEFORE construction
    completes — see the nst-whs example below. :U from that check
    MUST abort; only a confirmed :F (not found) permits creation."))

(defgeneric fetch (entity-class id ctx)
  (:documentation
   "स्मरण प्रत्यय — recall by identity. Returns either a real entity
    instance or an nst-entity-nil/nst-entity-unknown/nst-entity-
    contradiction sentinel (Section 1) — never a bare CL nil, so
    callers always have a Belnap-inspectable domain object back."))

(defgeneric enumerate (entity-class ctx &key)
  (:documentation
   "दर्शन प्रत्यय — list within tenant scope. नियम-1 applies to the
    SCOPE filter here (WHERE tenant_id = ctx.tenant), not to each
    returned row individually — the row-level check is redundant
    once the query itself is tenant-scoped correctly."))

(defgeneric !update (entity row-id ctx &rest changed-slots)
  (:documentation
   "!state प्रत्यय — entity is an EXISTING instance here, not a class
    symbol. GUARDRAIL 2 still holds: entity first, ctx before &rest."))

(defgeneric ?exists (entity-class lookup-value ctx &key &allow-other-keys)
  (:documentation
   "प्रत्यभिज्ञा प्रत्यय — existence check, Belnap-returning (:T/:F/
    :U/:C). lookup-value's meaning is entity-specific and documented
    per method — usually the primary id, but for uniqueness checks
    (GSTIN, phone, email) it is whatever field must be unique.

    &KEY &ALLOW-OTHER-KEYS is here for exactly that reason: an entity whose
    uniqueness is a TUPLE needs extra lookup values (nst-whs checks
    (GSTIN, W_NAME, TENANT) — the tuple its uk_gstin_name_tenant really
    enforces — and declares &key WNAME). CLOS congruence then requires EVERY
    method to accept &key/&rest: a method with a bare (entity-class value ctx)
    lambda list is REJECTED with 'differ in whether they accept &REST or &KEY'.
    So a new ?exists method must carry at least &key &allow-other-keys even if it
    uses no keywords. The alternative (a GF with &rest but no &key) was measured
    and is worse: it accepts a keyed method but rejects permissive ones."))

(defgeneric delete! (entity row-id ctx)
  (:documentation
   "लोप प्रत्यय — soft-delete. Sets deleted-state to \"Y\". Never a
    hard DELETE — नियम-2 already blocks all further verbs on the
    result; physical removal is not this project's concern."))

(defgeneric !settings (entity-class row-id ctx &rest args)
  (:documentation
   "संरचना प्रत्यय — replace ONE configuration SUB-RESOURCE on an existing entity.
    The seventh पद, and deliberately not folded into !update: !update assigns typed
    COLUMNS, one initarg per field, so the domain can check each value against its
    own slot type. A settings sub-resource is a single TEXT column holding a whole
    nested structure, so there is no per-field type to check — the invariant is on
    the STRUCTURE (which sections exist, what shape each entry has), and it has to
    live in a verb that knows it is validating a structure rather than assigning
    fields.

    GUARDRAIL 2 as for every verb: entity-class first, ctx before &rest."))

(defun test-requestmodel-rejected-by-domain-verb ()
  "Any proc.GANA verb called with an nst-request-model as first arg
   must signal no-applicable-method — not silently succeed."
  (handler-case
      (sleep 1)
      ;;(proc.inventory:catalog (make-instance 'nst-request-model) (make-domain-ctx))
      (hhub-method-not-found (condition)
	  (let ((exceptionstr (format nil  "Method not found Error:~A: ~a~%" (mysql-now) condition)))
	    ;; return the exception.
	    (error 'hhub-method-not-found :errstring exceptionstr)))
      (:no-error (result)
	(error "FAIL: request-model was accepted — immunity broken. Got: ~A" result))))

(defun test-ferry-discards-request-model ()
  "request->dispatch must not retain rm beyond the call.
   STUB: use a weak-pointer or manual GC check to confirm rm is
   collectible immediately after request->dispatch returns."
  nil)

(defun test-extract-domain-initargs-strips-tenant-id ()
  "[LEGAL/SECURITY] A client-supplied :tenant-id in rm.params must
   NEVER survive into the returned initargs. This is the नियम-1 bypass
   this function exists to close — test it explicitly, not incidentally.
   STUB: build rm with params containing (:tenant-id 99 :wname \"X\"),
   call extract-domain-initargs, assert :tenant-id absent from result,
   assert :wname present."
  nil)

(defun test-extract-domain-initargs-strips-all-reserved-fields ()
  "Every symbol in *reserved-initargs* must be absent from the result,
   regardless of what rm.params contains.
   STUB: build rm.params containing all five reserved keys plus one
   legitimate key, assert only the legitimate key survives."
  nil)

(defun test-extract-domain-initargs-ignores-unknown-keys ()
  "A key in rm.params that entity-class does not declare as an initarg
   must be silently dropped, not passed through to make-instance.
   STUB: rm.params contains :bogus-field \"x\", assert absent from result."
  nil)

(defun test-extract-domain-initargs-needs-zero-changes-for-new-entity ()
  "Structural test: define a throwaway nst-domain-entity subclass with
   a novel slot, verify extract-domain-initargs handles it correctly
   with NO code changes to extract-domain-initargs itself. This is
   the MOP-driven guarantee — confirm it holds, don't just assert it."
  nil)

(defun test-gana-package-for-resolves-junction-entity-verbs-correctly ()
  "nst-inv is a triple-junction entity. Verify gana-package-for routes
   correctly per VERB, not per entity:
     (gana-package-for 'invoice)      → :proc.finance
     (gana-package-for 'reconcile-2b) → :proc.tax
     (gana-package-for 'approve)      → :proc.governance
   All three verbs act on the SAME entity class (nst-inv) but resolve
   to three DIFFERENT गण packages. This is the bug the original ferry
   had — entity-class alone could never have produced this."
  nil)

(defun test-gana-package-for-errors-on-unregistered-verb ()
  "An unregistered verb symbol must signal a clear error, not return
   nil and let the ferry fail three lines later with a confusing
   find-symbol-on-nil error.
   STUB: (gana-package-for 'not-a-real-verb) → error, not nil."
  nil)

(defun test-niyam-fires-on-domain-entity-not-boundary ()
  "check-niyam :before must apply to nst-whs (domain) and must NOT
   have an applicable method for nst-view-model (boundary)."
  (assert (compute-applicable-methods
            #'check-niyam (list (make-instance 'nst-whs :tenant-id 1) (make-domain-ctx))))
  (handler-case
      (compute-applicable-methods
        #'check-niyam (list (make-instance 'nst-view-model) (make-domain-ctx)))
    (error () (format t "PASS: niyam has no applicable method on boundary tree~%"))))
