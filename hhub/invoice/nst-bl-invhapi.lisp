;;; nst-bl-invhapi.lisp — INVOICE HEADER ACTION ROUTES (conflodis2 Tier 2, Ring 2/3)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Design: aiharness/deepseek/skills/knowledge/nst-bl-conflodis2-DESIGN.md
;;;         (§3 verb signature, §5 multi-entity assembly, §6 कारक, §9 file layout)
;;; Dispatcher: hhub/core/nst-bl-conflodis2.lisp
;;;
;;; The invoice-header analogue of warehouse/nst-bl-whsapi.lisp: inbound action
;;; symbol → (register-action-route 'route-invh-<action> …) → ONE route-invh-<action>
;;; verb → Tier-1 ferries (request->dispatch … 'nst-invh).
;;;
;;; Every verb here returns DOMAIN-LAYER results (an nst-invh, a list of them, a
;;; Belnap sentinel, or the delete! ack T). The dispatcher alone runs the reverse
;;; ferry and the Ring-4 render — no boundary type is constructed in this file
;;; (DESIGN §3).
;;;
;;; ⚠ THIS FILE DEPENDS ON THREE THINGS IT DOES NOT DEFINE, all of them load-order
;;; facts rather than choices:
;;;
;;;   1. THE BELNAP SENTINEL FERRY. domain->response methods for nst-entity-nil /
;;;      -unknown / -contradiction, the (eql t) delete ack, and render-json /
;;;      render-html for nst-response-nil/-unknown/-contradiction live in
;;;      warehouse/nst-bl-whsapi.lisp SECTION 4 — which nstores.asd loads AFTER the
;;;      invoice section. Without that file loaded, every 404/409/503 this domain
;;;      returns dies at the dispatcher's reverse ferry with NO-APPLICABLE-METHOD.
;;;      They are domain-generic and whsapi's own FLAG says they belong in
;;;      core/nst-bl-adhara.lisp (DESIGN §4.3); relocating them is its own change,
;;;      deliberately NOT smuggled into this one. Nothing here redefines them: a
;;;      second method with those specializers would REPLACE the warehouse's.
;;;
;;;   2. THE DELETE ACK TYPE IS warehouse-ack-response, by name. An invoice DELETE
;;;      therefore answers {"ok":true,"operation":"delete"} through the warehouse's
;;;      class. Correct in substance (there is no कर्म left to return once the row
;;;      is soft-deleted — whsapi SECTION 4's one documented boundary exception),
;;;      wrong in name. Renaming it is part of the same relocation above.
;;;
;;;   3. request->dispatch CANNOT CARRY ?exists. The ferry's ?exists method passes
;;;      ctx where the lookup value belongs (apidefs2-CONTEXT §9.4, an open item for
;;;      nst-whs too), so route-invh-fetch-by-invnum calls the verb directly and
;;;      converts its bo-knowledge with domain-result-from-knowledge — exactly the
;;;      shape route-warehouse-fetch-identity uses.
;;;
;;; NOT IN THIS FILE, ON PURPOSE:
;;;   * NO API BINDINGS. register-api-route lines are the next step; this file is
;;;     the Tier-2 surface only. The route KEYS are what the bindings will name.
;;;   * NO COMPOUND "invoice + its lines" WRITE (create-with-lines). The READ half —
;;;     the spec's GET /invoices/{id} — IS here, as route-invh-detail; see SECTION 4
;;;     for what the write waits on.
;;;   * NO ?exists ROUTE. See SECTION 4.
;;;
;;; Load order: AFTER core/nst-bl-adhara.lisp, core/nst-bl-conflodis2.lisp,
;;; core/nst-bl-apidefs2.lisp (api-client-error), invoice/nst-dal-invh.lisp and
;;; invoice/nst-bl-invh.lisp.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Params readers and the route layer's coercions
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Inbound data rides in (params request) as a plist of nst-invh's OWN initargs
;;; (:invnum "…" :custname "…" :placeofsupply "…"), not DB column spellings.
;;; extract-domain-initargs does the MOP filtering; these functions handle only
;;; what it cannot — string-keyed payloads, keyword-valued filters, and the one
;;; typed field (a date) the domain class refuses as a string.

(defun inv-param (payload key)
  "Read KEY (a keyword initarg/query name) from PAYLOAD.
   Accepts a keyword-keyed plist (conflodis2/agent callers) or a string-keyed one
   (a JSON body or querystring parsed by an inbound adapter)."
  (or (getf payload key)
      (getf payload (string-downcase (symbol-name key)))))

(defun inv-keyword-value (value)
  "Coerce an inbound scalar to a keyword — \"inv-date\"/'inv-date → :INV-DATE.
   Used for sort-by/sort-dir, which the verbs take as keywords. Non-scalars pass
   through so the verb's own whitelist check names the offender."
  (cond ((null value) nil)
        ((keywordp value) value)
        ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
        ((stringp value) (intern (string-upcase value) :keyword))
        (t value)))

(defun inv-plist-set (payload key value)
  "PAYLOAD with KEY's value replaced, or appended when KEY is absent. Small
   plists, so the append is not worth avoiding."
  (let ((out nil) (seen nil))
    (loop for (k v) on payload by #'cddr
          do (if (eq k key)
                 (progn (setf seen t) (setf out (append out (list key value))))
                 (setf out (append out (list k v)))))
    (if seen out (append out (list key value)))))

(defun inv-params-without (payload &rest keys)
  "PAYLOAD minus KEYS — used where a value that arrived from the transport must
   not reach a verb (the item routes strip :invheadid for !update, which refuses
   it). Same idiom as extract-domain-initargs, applied at the route layer."
  (loop for (k v) on payload by #'cddr
        unless (member k keys) append (list k v)))

(defun inv-date-param (value)
  "An inbound date → the CLSQL date object nst-invh's invdate requires, or NIL.

   ACCEPTS EXACTLY TWO THINGS: \"YYYY-MM-DD\", and a value that is already a date
   object (a REPL or agent caller). Everything else is refused with api-client-error
   → 400, deliberately: invdate is NOT NULL and decides the financial year, and a
   silently mis-parsed date is a wrong invoice, not a failed request. This is why
   the route layer coerces it at all — the class documents that a raw transport
   string is not accepted, and this is the place that makes that true.

   ONE FORMAT, ISO. The internal UI posts DD/MM/YYYY to its own handlers and converts
   with get-date-from-string before any verb sees it; an API client gets ISO and
   nothing else, so there is never a question of which reading \"03/04/2026\" wants."
  (cond
    ((null value) nil)
    ((not (stringp value)) value)
    ((and (= (length value) 10)
          (char= (char value 4) #\-)
          (char= (char value 7) #\-))
     (let ((y (parse-integer value :start 0 :end 4 :junk-allowed t))
           (m (parse-integer value :start 5 :end 7 :junk-allowed t))
           (d (parse-integer value :start 8 :end 10 :junk-allowed t)))
       (unless (and y m d (<= 1 m 12) (<= 1 d 31))
         (api-client-error "~S is not a valid YYYY-MM-DD date" value))
       (clsql-sys:make-date :year y :month m :day d :hour 0 :minute 0 :second 0)))
    (t (api-client-error "~S is not a YYYY-MM-DD date" value))))

(defun inv-row-id-param (request)
  "The :row-id this request addresses, as a STRING, or api-client-error → 400.

   fetch, !update and delete! all specialize their id parameter on (id string), so a
   missing or integer-valued :row-id reaches the generic function as a non-string and
   signals NO-APPLICABLE-METHOD — a 500 for what is a malformed request. An integer IS
   a well-formed id (a JSON body or an agent caller may carry one) and is coerced
   rather than refused. Through HTTP this is defensive only: apidefs2 maps every path
   parameter to a string. It matters for the other channels DESIGN §6 names (:agent,
   :batch) — and it is why this domain does not copy whsapi's routes, where a missing
   id is a 500."
  (let ((id (inv-param (params request) :row-id)))
    (cond ((and (stringp id) (plusp (length id))) id)
          ((integerp id) (princ-to-string id))
          (t (api-client-error "a row-id is required (a numeric id)")))))

(defun inv-request-with-row-id-string (request)
  "REQUEST whose :row-id is a string, so a verb method specializing on (id string) is
   always applicable. Returns REQUEST unchanged when it already is one — the normal
   case, since apidefs2 maps every path parameter to a string.

   Built as a NEW request rather than by mutating: the same request object is handed to
   every ferry in an action, and no verb should observe another verb's coercion.
   (class-of request) keeps this entity-agnostic, so the header and the line routes
   share one implementation."
  (if (stringp (inv-param (params request) :row-id))
      request
      (make-instance (class-of request)
                     :params (inv-plist-set (params request) :row-id (inv-row-id-param request)))))

(defun invh-normalised-request (request)
  "REQUEST with BOTH transport-shaped fields coerced — :row-id to a string and
   :invdate to a CLSQL date — or REQUEST unchanged when neither needs it. The ferry
   reads the request's params, so a coercion has to produce a request, not a side
   effect on a shared object."
  (let* ((with-id (inv-request-with-row-id-string request))
         (payload (params with-id))
         (invdate (inv-param payload :invdate)))
    (if (stringp invdate)
        (make-instance 'NstInvhRequestModel
                       :params (inv-plist-set payload :invdate (inv-date-param invdate)))
        with-id)))

(defun invh-enumerate-args (payload)
  "Filter args for (enumerate 'nst-invh ctx …). Like whs-enumerate-args, these are
   QUERY arguments of the enumerate verb rather than nst-invh initargs, so
   extract-domain-initargs would drop every one of them: a list action is one read
   of a filtered collection, not an entity crossing.

   FROM-DATE / TO-DATE are passed through as the strings the query carried —
   [>= [:invdate] \"2026-04-01\"] compares correctly against a DATE column, and a
   malformed one simply matches nothing. They are filters, not stored fields, so
   the strict ISO coercion above applies to invdate only."
  (list :status      (inv-param payload :status)
        :custid      (inv-param payload :custid)
        :vendor-id   (inv-param payload :vendor-id)
        :invnum-like (inv-param payload :invnum-like)
        :from-date   (inv-param payload :from-date)
        :to-date     (inv-param payload :to-date)
        :sort-by     (or (inv-keyword-value (inv-param payload :sort-by)) :invdate)
        :sort-dir    (or (inv-keyword-value (inv-param payload :sort-dir)) :desc)))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action verbs (Tier 2)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Signature is uniform and fixed by DESIGN §3: (route-invh-<action> request ctx).
;;; Plain defuns, not generics — dispatch-action resolves them with fdefinition.
;;; No domain law lives here: identity, status rules and the four-valued answers
;;; belong to the प्रत्यय in nst-bl-invh.lisp, so the API, the internal website and
;;; a REPL caller all get the same answer from the same code.

(defun route-invh-create (request ctx)
  "कर्म = nst-invh. Make a DRAFT header.
   invnum/invdate/finyear are derived by the verb when absent (a placeholder number,
   today, the GST financial year), so a minimal body works. The NOT NULL text columns
   the caller must supply (custname, statecode, placeofsupply) are refused by the
   database with the column named → a genuine :F, not a 404."
  (request->dispatch (invh-normalised-request request) 'make 'nst-invh ctx))

(defun route-invh-fetch (request ctx)
  "कर्म = nst-invh, addressed by :row-id (rm-row-id). Returns an nst-invh or a
   Belnap sentinel — never a bare CL nil. An integer :row-id is coerced to a string
   first, so the verb method is always applicable (see inv-row-id-param)."
  (request->dispatch (inv-request-with-row-id-string request) 'fetch 'nst-invh ctx))

(defun route-invh-fetch-by-invnum (request ctx)
  "कर्म = nst-invh, addressed by its INVOICE NUMBER rather than its row-id.

   THE READ THAT CAN LEGITIMATELY ANSWER :C, and the reason it is worth exposing:
   DOD_INVOICE_HEADER has no unique key on INVNUM, so nothing but this check stands
   between a number and a duplicate — and a SOFT-DELETED row still holds its number,
   because DELETED_STATE is not part of any key there either. So the four states are:

     :T  a LIVE header holds the number in this tenant        → 200 + the entity
     :F  nothing holds it                                     → 404
     :C  a SOFT-DELETED header holds it: the row is in the table and the number is
         consumed, while नियम-2 makes it invisible to every verb. Two of the
         domain's own rules disagree → 409. This is the SAME fact `make :around`
         refuses a create on; this verb reaches it through a read.
     :U  the boundary could not answer                        → 503

   Called directly, not through the ferry — see this file's header, item 3."
  (let* ((payload (params request))
         (invnum (inv-param payload :invnum))
         (tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (unless (and (stringp invnum) (plusp (length (string-trim " " invnum))))
      (api-client-error "invoice-fetch-by-invnum requires a non-blank invnum"))
    (let ((knowledge (?exists 'nst-invh invnum ctx)))
      ;; ONE conversion, in adhara — the same call fetch and every other verb uses.
      (domain-result-from-knowledge
       knowledge ctx
       :hydrate (lambda (dbobj)
                  (let ((entity (make-instance 'nst-invh :tenant-id tenant-id)))
                    (nst-copy-invoice-header-dbtodomain dbobj entity)
                    entity))
       :reason (lambda (truth)
                 (case truth
                   (:F (format nil "No live invoice holds number ~A in this tenant" invnum))
                   (:U (format nil "Could not resolve invoice number ~A — the database call did not answer" invnum))
                   (:C (format nil "Invoice number ~A is held by a SOFT-DELETED invoice: the row is still in DOD_INVOICE_HEADER and the number is therefore consumed, while नियम-2 makes that row invisible to every verb. 'It is there' and 'there is no such invoice' are both true, so this is neither present nor absent. Human decision needed: reuse is not permitted — see the number's owner by row-id, or issue under a different number." invnum))))))))

(defun route-invh-update (request ctx)
  "कर्म = nst-invh. Partial update (CLOS reinitialize-instance): only the initargs
   actually supplied in params change. :row-id selects the row; a string :invdate is
   coerced first, since !update would otherwise write a transport string into a DATE
   column."
  (request->dispatch (invh-normalised-request request) '!update 'nst-invh ctx))

(defun route-invh-delete (request ctx)
  "कर्म = nst-invh. Soft delete, and ONLY while the header is a DRAFT — the verb's
   rule, not this route's. It also soft-deletes the invoice's LINES first and leaves
   the header untouched if that does not fully succeed (see the verb), so a partial
   failure is re-runnable rather than half-applied.
   Returns T on success, nst-entity-nil when absent, nst-entity-contradiction when
   the invoice is not a DRAFT."
  (request->dispatch (inv-request-with-row-id-string request) 'delete! 'nst-invh ctx))

(defun route-invh-list (request ctx)
  "कर्म = the filtered nst-invh collection. Calls enumerate directly (not via the
   ferry) because its arguments are query filters rather than entity initargs — see
   invh-enumerate-args. Zero rows is a SUCCESS with an empty list, not a 404."
  (apply #'enumerate 'nst-invh ctx (invh-enumerate-args (params request))))


;;; ───────────────────────────────────────────────────────────────────────────
;;; THE AGGREGATE READ — one action, two boats (DESIGN §5)
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; hhub/core/nstoresapi.html defines GET /api/v1/invoices/{id} as "Get full invoice:
;;; header, line items, GST breakdown, payment status, and assigned customer
;;; details" — a different result from route-invh-fetch, which returns the header
;;; alone. Three of those five things the header ALREADY carries: payment-status and
;;; balance-due are columns, and the customer's name, address and GSTIN are snapshots
;;; on the row. So the aggregate is the header PLUS its lines; the GST breakdown is
;;; the one piece not yet built (see the note after the render method).

(defclass invh-detail-response (nst-response-model)
  ((header
    :initarg :header
    :accessor detail-header
    :documentation "An NstInvhResponseModel — already ferried, not an entity.")
   (lines
    :initarg :lines
    :accessor detail-lines
    :documentation "A list of NstInvitmResponseModel, in row-id (print) order."))
  (:documentation
   "The assembled outbound shape of ONE invoice: the header's fields plus a nested
    line array.

    This is a boundary type built by an ACTION VERB, which DESIGN §3 forbids in
    general — and the dispatcher's own reverse ferry is what allows it here:
    (action->response …) carries an explicit pass-through clause for a ready-made
    nst-response-model, so an action that must NEST two entity types has a sanctioned
    door. The alternative — a flat [header, line, line…] array — is renderable today
    and loses exactly the nesting the spec asks for. whsapi's delete ack went through
    the same door, and DESIGN §3's blanket sentence should be amended to name it."))

(defmethod render-json ((r invh-detail-response) (ctx domain-ctx))
  "The header's own field allowlist, SPLICED, plus a \"lines\" array — so the body is
   one invoice object rather than a wrapper the client has to unwrap.

   The header alist comes from render-json on NstInvhResponseModel and each line alist
   from render-json on NstInvitmResponseModel, so this method introduces NO field of
   its own and cannot leak one: the outbound allowlist stays in exactly one place per
   entity. There is no render-html method — no HTML view for the new invoice entities
   exists, and inventing one here would be a presentation decision made in an API
   file. A :html dispatch of this route would therefore signal NO-APPLICABLE-METHOD;
   every registered route for it is :json."
  (append (render-json (detail-header r) ctx)
          (list (cons "lines" (mapcar (lambda (l) (render-json l ctx)) (detail-lines r))))))

;;; NOT HERE: THE GST BREAKDOWN. The spec lists it as part of "the full invoice", and
;;; it is derivable from the lines' own cgst/sgst/igst rate and amount columns — but
;;; it is a DOMAIN computation, not a render-time fold, and its honest home is a
;;; function in nst-bl-invh.lisp beside the प्रत्यय. The legacy stack has one
;;; (generate-gst-tax-breakdown, with the generic add-item-to-tax-breakdown in
;;; nst-dal-itm.lisp), and it operates on the OLD business objects, so it is a
;;; starting point rather than something reusable. Summing it in this file would make
;;; the route layer the owner of a tax figure that the GSTR-1 export also reads.

(defun route-invh-detail (request ctx)
  "कर्म = nst-invh, PLUS its lines as a second crossing — two Tier-1 ferries in one
   action, which is what DESIGN §5 exists for. Answers the spec's GET /invoices/{id}.

   THE SENTINEL RULE, and why the naive version is wrong: if the header fetch answers
   with a sentinel, that sentinel IS the answer for the whole read (404/409/503). But
   if the header IS found and the line enumerate answers with a sentinel — :U, the
   database did not answer — then returning the header alone would tell the client
   'this invoice has no lines'. That is the :U-read-as-:F collapse this tree exists to
   prevent, and the one case where a detail read must not quietly answer partially.
   A non-list answer from the line enumerate is therefore returned unchanged, and
   reaches the boundary as 503 or 409.

   THREE SELECTS, deliberately: the header fetch (tenant-checked), enumerate's own
   parent verification, and the line query. Bypassing enumerate — calling
   select-invoice-items-for-header directly — would save one SELECT and give the
   aggregate its own private path to the child rows, which is exactly how a read ends
   up skipping rules the verbs enforce."
  (let* ((req (inv-request-with-row-id-string request))
         (header (request->dispatch req 'fetch 'nst-invh ctx)))
    (if (not (typep header 'nst-invh))
        header
        (let ((lines (enumerate 'nst-invitm ctx :invheadid (row-id header))))
          (if (listp lines)
              (make-instance 'invh-detail-response
                             :header (domain->response header ctx)
                             :lines (mapcar (lambda (l) (domain->response l ctx)) lines))
              lines)))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Route registration
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; One line per inbound action. The route key IS the symbol the dispatcher is
;;; called with: (dispatch-route2 'route-invh-create …). request-class is the
;;; SLOTLESS NstInvhRequestModel — the whole payload rides in its params slot.
;;;
;;; required-roles / feature-flags / audit-level are CARRIED but NOT enforced by
;;; conflodis2 v1 (DESIGN §4.2, §11.1) — registered now so the metadata sits in one
;;; place when the PEP/ABAC seam lands. The role names follow the legacy invoice
;;; route (hhub/invoice/nst-bl-invapi.lisp), which registered '(vendor).

(register-action-route 'route-invh-create
                       :action-verb 'route-invh-create
                       :request-class 'NstInvhRequestModel
                       :description "Create a DRAFT invoice header for the session tenant. invnum/invdate/finyear default when absent."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :full
                       :tags '(invoice api v1))

(register-action-route 'route-invh-fetch
                       :action-verb 'route-invh-fetch
                       :request-class 'NstInvhRequestModel
                       :description "Fetch one invoice header by :row-id (or a Belnap sentinel)."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :read
                       :tags '(invoice api v1))

(register-action-route 'route-invh-fetch-by-invnum
                       :action-verb 'route-invh-fetch-by-invnum
                       :request-class 'NstInvhRequestModel
                       :description "Fetch one invoice header by its NUMBER (invnum, scoped to the session tenant). Four-valued: 200 live / 404 free / 409 held by a soft-deleted invoice / 503 boundary failure."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :read
                       :tags '(invoice api v1))

(register-action-route 'route-invh-update
                       :action-verb 'route-invh-update
                       :request-class 'NstInvhRequestModel
                       :description "Partially update an invoice header by :row-id. An ISO :invdate is coerced to a date object."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :full
                       :tags '(invoice api v1))

(register-action-route 'route-invh-delete
                       :action-verb 'route-invh-delete
                       :request-class 'NstInvhRequestModel
                       :description "Soft-delete a DRAFT invoice header and its lines, by :row-id. 409 when the invoice is not a DRAFT."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :full
                       :tags '(invoice api v1))

(register-action-route 'route-invh-list
                       :action-verb 'route-invh-list
                       :request-class 'NstInvhRequestModel
                       :description "List invoice headers for the session tenant. Filters: status, custid, vendor-id, invnum-like, from-date, to-date; whitelisted sort-by/sort-dir (default invdate desc)."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :read
                       :tags '(invoice api v1))

(register-action-route 'route-invh-detail
                       :action-verb 'route-invh-detail
                       :request-class 'NstInvhRequestModel
                       :description "One invoice WITH its line items — the header plus a nested line array, as the API spec's GET /invoices/{id} defines. Two Tier-1 crossings; a line read that could not be answered is reported as 503 rather than as an invoice with no lines."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :read
                       :tags '(invoice api v1))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Deliberately absent, and what each one waits on
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; 1. NO COMPOUND "create an invoice WITH its lines" ACTION — the WRITE half of
;;;    DESIGN §5 (one action, several Tier-1 boats). The READ half now exists
;;;    (route-invh-detail), and what it proved is that the nesting problem has a
;;;    sanctioned answer: the dispatcher's pass-through clause for a ready-made
;;;    nst-response-model. What still blocks the compound CREATE is only ATOMICITY.
;;;
;;;      conflodis2 v1 runs the action verb UNWRAPPED — *action-route-transaction-function*
;;;      is a no-op by default (nst-bl-conflodis2.lisp SECTION 5) — and neither the
;;;      प्रत्यय layer nor CLSQL wrapping is in place. A compound create is therefore not
;;;      atomic: header written, line 3 refused, and the client holds a DRAFT with some
;;;      of its lines. Each per-route verb here is ONE ferry, so a failure commits
;;;      nothing; a compound one cannot say that yet.
;;;
;;;    Until the transaction seam is real, a client creates a header
;;;    (route-invh-create) and then its lines (route-invitm-create) — which is also
;;;    exactly what the internal website does, and what the current invoice data model
;;;    expects, since nothing yet rolls the lines up into the header's total.
;;;
;;; 2. NO ?exists ROUTE, for either entity. ?exists answers a four-valued QUESTION
;;;    ("is this identity taken?", "is this product already on the invoice?"), and
;;;    the answer that matters for a form — :F, 'no' — is NOT a 404. Mapping it onto
;;;    HTTP would either turn the normal case into an error, or need a body shape
;;;    that carries a truth value rather than a resource. route-invh-fetch-by-invnum
;;;    covers the one read where :C is genuinely actionable, and item-side duplicate
;;;    detection waits for a form that asks it.
;;;
;;; 3. NO ROUTE FOR THE HEADER DELETE. The spec (nstoresapi.html) defines no
;;;    DELETE /invoices/{id} at all, which agrees with the domain rule that an issued
;;;    invoice is cancelled rather than deleted. route-invh-delete exists and is
;;;    registered for UI/agent callers (it refuses anything past DRAFT); it is simply
;;;    not part of the published surface.


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 5 — Public API bindings (Ring 4)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; These bind the paths defined in hhub/core/nstoresapi.html for the Invoicing
;;; domain (id 'inv', role Vendor). SEVEN of that domain's twelve endpoints map onto
;;; routes that exist — FOUR of them here (the header CRUD plus the aggregate read)
;;; and THREE in nst-bl-invitmapi.lisp (the line endpoints), because a binding has to
;;; follow the file that registers its action route; see the note at the end of this
;;; section. The other five endpoints are listed after them with the concrete thing
;;; each is waiting for.
;;;
;;; ⚠ THE SPEC'S PATHS AND THESE TEMPLATES DIFFER BY THE /hhub PREFIX, ON PURPOSE.
;;; The spec publishes /api/v1/invoices; the template says /hhub/api/v1/invoices.
;;; register-api-route REJECTS a template without the prefix (api-path-deployment-prefix-p),
;;; because the deployed nginx proxies `location /hhub/` through unchanged and
;;; rewrites every other URI to /hhub/$1 — so a client calling /api/v1/invoices arrives
;;; as /hhub/api/v1/invoices and matches this template. When nginx later gets a
;;; dedicated `location /api/`, the prefix drops from both the templates and the
;;; dispatcher regex in one pass (nst-bl-apidefs2-CONTEXT §7).
;;;
;;; ⚠ NO :inject-company ANYWHERE, and that is a real difference from the warehouse
;;; bindings. nst-whs carries a legacy COMPANY slot and copyWarehouse-domaintodb
;;; derives the row's tenant from it, so its bindings must inject the session company.
;;; nst-invh and nst-invitm have no such slot: they read the inherited tenant-id, set
;;; by the ferry from domain-ctx, which make-action-domain-ctx built from the session
;;; login company. The tenant therefore reaches the domain with no help from the API
;;; layer (नियम-1), and injecting :company would push an initarg at verbs that do not
;;; declare it.
;;;
;;; Path ids are numeric row-ids, as everywhere in this tree: `id` is the INVOICE's
;;; row-id, `item-id` is the LINE's. api-params-for-request puts path params ahead of
;;; the body, so a client cannot override either through the payload.
;;;
;;; BODIES carry nst-invh / nst-invitm INITARG names ("invnum", "custname",
;;; "placeofsupply", "prddesc", "hsncode", …), not DB column spellings; camelCase is
;;; accepted. A body-supplied "tenant-id" is stripped as reserved, and "row-id" /
;;; "invheadid" from a body cannot displace the URL's values.

(register-api-route 'route-invh-create
                    :method :post
                    :path "/hhub/api/v1/invoices"
                    :success-status 201
                    :auth-scope :session
                    :description "Spec: POST /api/v1/invoices — create a new invoice for a customer. Body: JSON object of nst-invh field names; invnum, invdate and finyear are derived by the domain when omitted. 404 when a named customer is not this tenant's; 409 when the invoice number is already held.")

(register-api-route 'route-invh-list
                    :method :get
                    :path "/hhub/api/v1/invoices"
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: GET /api/v1/invoices — search and list invoices by customer, date range or status. Query params: status, custid, vendor-id, invnum-like, from-date, to-date, sort-by, sort-dir. An empty result is 200 with [], not 404.")

(register-api-route 'route-invh-detail
                    :method :get
                    :path "/hhub/api/v1/invoices/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: GET /api/v1/invoices/{id} — get the full invoice: the header's fields plus a nested \"lines\" array. 404 when the invoice does not exist, belongs to another tenant, or is soft-deleted; 503 (not 404) when the database could not be reached.")

(register-api-route 'route-invh-update
                    :method :put
                    :path "/hhub/api/v1/invoices/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: PUT /api/v1/invoices/{id} — update the invoice header. Body: JSON object of nst-invh field names; only the fields supplied change. invdate, if present, must be YYYY-MM-DD (400 otherwise).")

;;; ───────────────────────────────────────────────────────────────────────────
;;; THE THREE LINE ENDPOINTS ARE BOUND IN nst-bl-invitmapi.lisp, NOT HERE — and the
;;; reason is load order, not tidiness.
;;;
;;; The URL is invoice-scoped (/invoices/{id}/items), which is why they were written
;;; here first. register-api-route REFUSES a path whose action route is not already
;;; registered (api-route-bindable-p), and route-invitm-* are registered in
;;; nst-bl-invitmapi.lisp, which loads AFTER this file — so the first full build died
;;; at load time with:
;;;
;;;   apidefs2: ROUTE-INVITM-CREATE is not a registered action route.
;;;
;;; raised from this file's own fasl. It is the convention every other domain already
;;; follows (whsapi, vndapi, vndshpapi each hold their entity's verbs, action routes
;;; AND bindings): A BINDING LIVES IN THE FILE THAT REGISTERS THE VERB, whatever the
;;; URL looks like.
;;;
;;; Neither offline check could see this — compile-file does not evaluate the
;;; load-time registrations, and a name-level audit of "is every bound route
;;; registered somewhere" answers yes. Only ORDER fails, and only a real load proves
;;; it. Hence the check in the verification script: bindings are walked in the
;;; build's own file order, and a binding that precedes its registration is a failure.
;;; ───────────────────────────────────────────────────────────────────────────
;;; THE FIVE SPEC ENDPOINTS WITH NO BINDING, and the concrete blocker for each.
;;; None is a route-file gap: each needs something that does not exist yet, and
;;; binding it to an existing route would ship a documented contract the code
;;; cannot honour.
;;;
;;;   POST /api/v1/invoices/{id}/payment   "Record a payment ... method: cash | UPI |
;;;        wallet | card | bank-transfer." A payment is a different कर्म
;;;        (DOD_PAYMENT_TRANSACTION, proc.finance's pay / receive-payment), and no
;;;        प्रत्यय exists for it. It also has to move the header's
;;;        payment-status / payment-allocated / balance-due columns, which is a
;;;        domain rule spanning two entities — i.e. the same atomicity question as
;;;        the compound create.
;;;
;;;   POST /api/v1/invoices/{id}/send      "Email the invoice ... using the vendor
;;;        configured mail settings." Not a domain verb at all: it is the actor
;;;        model's send-email-async path plus the invoice email templates that
;;;        already exist in nst-ui-ihd.lisp. A fire-and-forget job behind an HTTP
;;;        200 — it needs the 202/shape decision, not a ferry.
;;;
;;;   GET  /api/v1/invoices/{id}/download  "Generate and return a print-ready PDF."
;;;        apidefs2 HAS the seam (:response-format :csv + :content-type, plus the
;;;        dispatcher's string pass-through in action->response). What is missing is
;;;        a PDF producer for the NEW entities: the existing generatepdf pipeline
;;;        renders the legacy invoice template models.
;;;
;;;   GET  /api/v1/invoices/{id}/public    "No authentication required." NO SUCH
;;;        AUTH SCOPE EXISTS: api-authenticate handles :session and signals
;;;        "unknown auth scope" for anything else, so this endpoint cannot be bound
;;;        until apidefs2 gains a :public scope (and the live-link mechanism —
;;;        external-url, expiry, password — is decided).
;;;
;;;   PUT  /api/v1/invoices/settings       "Update invoice print settings: logo,
;;;        header text, footer, GSTIN, digital signature." ALREADY IMPLEMENTED, on
;;;        the VENDOR profile rather than an invoice: PUT
;;;        /hhub/api/v1/vendor/profile/{id}/invoice-settings (vendor/nst-bl-vndapi.lisp),
;;;        verified end to end, writing DOD_VEND_PROFILE.INVOICE_SETTINGS which
;;;        *invoice-settings* then reads. Binding it again here would create a second
;;;        writer for one blob. The spec's placement of it under /invoices is the
;;;        thing to reconcile, not the code.

;;; End of nst-bl-invhapi.lisp
