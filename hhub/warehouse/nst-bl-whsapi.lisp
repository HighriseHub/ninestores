;;; nst-bl-whsapi.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; WAREHOUSE ACTION ROUTES — conflodis2 Tier 2 (Ring 2/3).
;;;
;;; Design: hhub/core/nst-bl-conflodis2-DESIGN.md  (§3 signature, §5 multi-
;;;         entity assembly, §6 कारक, §9 file layout)
;;; Dispatcher: hhub/core/nst-bl-conflodis2.lisp
;;;
;;; This file is the whs analogue of hhub/customer/nst-bl-custapi.lisp — same
;;; purpose (the API surface of ONE domain), deliberately DIFFERENT route
;;; logic. There is no :crud-op here, no adapter/presenter/view wiring, no
;;; businessobject-class. Instead:
;;;
;;;   inbound action symbol  →  (register-action-route 'route-<action> …)  →
;;;   ONE route-<action> verb →  Tier-1 ferries (request->dispatch … 'nst-whs)
;;;
;;; Every route-<action> verb returns DOMAIN-LAYER results (an nst-whs, a list
;;; of them, or a Belnap sentinel). The dispatcher alone runs the reverse ferry
;;; (domain->response) and the Ring-4 render (dṛś). No boundary type is
;;; constructed by a verb, with the single documented exception of the delete
;;; ack — see SECTION 4.
;;;
;;; नियम-1: the tenant (अधिकरण) is built by make-action-domain-ctx from the
;;; SESSION login company. A client-supplied :tenant-id in params is stripped
;;; by extract-domain-initargs and never reaches nst-whs.
;;;
;;; Load order: AFTER core/nst-bl-adhara.lisp, core/nst-bl-conflodis2.lisp,
;;; warehouse/nst-dal-warehouse.lisp and warehouse/nst-bl-warehouse.lisp.
;;; NOT yet listed in package/compile.lisp or nstores.asd — DESIGN §9 says the
;;; dispatcher and its route files are wired in only after review.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Params readers (transport-shaped plist, no typed slots)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; nst-whs inbound data rides in (params request) as a plist of the domain
;;; class's OWN initargs — (:wname "…" :wcity "…" :warehouse-gstin "…"), not
;;; :w-name/:w-gstin DB column spellings. extract-domain-initargs does the
;;; MOP filtering; these readers only handle the cases it does NOT (values
;;; that must become keywords, and querystring keys that arrive as strings).

(defun whs-param (payload key)
  "Read KEY (a keyword initarg/query name) from PAYLOAD.
   Accepts a keyword-keyed plist (conflodis2/agent callers) or a string-keyed
   plist (a JSON body or querystring parsed by an inbound adapter)."
  (or (getf payload key)
      (getf payload (string-downcase (symbol-name key)))))

(defun whs-keyword-value (value)
  "Coerce an inbound scalar to the keyword form the domain expects —
   \"w-name\"/\"W-NAME\"/'w-name → :W-NAME. Non-scalars pass through."
  (cond ((null value) nil)
        ((keywordp value) value)
        ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
        ((stringp value) (intern (string-upcase value) :keyword))
        (t value)))

(defun whs-enumerate-args (payload)
  "Filter args for (enumerate 'nst-whs ctx …).
   NOTE (deliberate, not a ferry): :warehouse-type/:city/:sort-by are QUERY
   arguments of the enumerate verb, not initargs of nst-whs, so
   extract-domain-initargs would drop every one of them. A list action is not
   an entity crossing — it is one fetch of a filtered collection — so this
   verb builds the kāraka-free query args itself and still calls the Tier-1
   verb with the entity class as कर्म."
  (list :warehouse-type     (whs-keyword-value (whs-param payload :warehouse-type))
        :state-code         (whs-param payload :state-code)
        :city               (whs-param payload :city)
        :is-primary-location (whs-param payload :is-primary-location)
        :name-like          (whs-param payload :name-like)
        :sort-by            (or (whs-keyword-value (whs-param payload :sort-by)) :w-name)
        :sort-dir           (or (whs-keyword-value (whs-param payload :sort-dir)) :asc)))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action verbs (Tier 2)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Signature is uniform and fixed by DESIGN §3: (route-<action> request ctx).
;;; Plain defuns, not generics — dispatch-action resolves them with
;;; fdefinition, exactly like route-ping. A verb MAY launch several Tier-1
;;; ferries (DESIGN §5); each of the routes below launches one today because
;;; a warehouse IS one entity, with no aggregate to assemble.

(defun route-warehouse-create (request ctx)
  "कर्म = nst-whs. The GSTIN uniqueness laws ride in nst-whs's own ?exists /
   make :before (nst-bl-warehouse.lisp) — the ferry does not re-check them here.

   ONE exception, because it is not a legality question but an epistemic one:
   an identity held by a SOFT-DELETED row. DOD_WAREHOUSE keeps the row and
   uk_gstin_name_tenant contains no DELETED_STATE, so the row still reserves
   (GSTIN, name, tenant) while नियम-2 makes it invisible to every verb. The
   client's 'create this' and the world's 'it is already there, marked deleted'
   disagree → Belnap :C, and :C must reach a human, not a stack trace: the
   INSERT would otherwise fail on the unique key and surface as a misleading
   'uniqueness race lost after :before check passed' error.

   Returning nst-entity-contradiction is enough — the dispatcher's reverse ferry
   renders it 409 with a conflict body, and the API log records it."
  (let* ((payload (params request))
         (gstin (getf payload :warehouse-gstin))
         (wname (getf payload :wname))
         (check (when (and gstin wname)
                  (?exists 'nst-whs gstin ctx :wname wname))))
    (if (and check (eq (bo-knowledge-truth check) :C))
        (make-instance 'nst-entity-contradiction
                       :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                       :reason (format nil "Warehouse identity GSTIN ~A / name ~S is held by a soft-deleted row: it still occupies uk_gstin_name_tenant in DOD_WAREHOUSE, but DELETED_STATE='Y' makes it invisible to every verb (नियम-2). Undelete that warehouse, or create this one under a different name."
                                       gstin wname))
        (request->dispatch request 'make 'nst-whs ctx))))

(defun route-warehouse-fetch (request ctx)
  "कर्म = nst-whs. Reads :row-id from params (rm-row-id). Returns an nst-whs
   or nst-entity-nil — never a bare CL nil (Section 6 fetch contract)."
  (request->dispatch request 'fetch 'nst-whs ctx))

(defun route-warehouse-update (request ctx)
  "कर्म = nst-whs. Partial update (CLOS reinitialize-instance): only the
   initargs actually supplied in params change. :row-id selects the row."
  (request->dispatch request '!update 'nst-whs ctx))

(defun route-warehouse-delete (request ctx)
  "कर्म = nst-whs. Soft delete (deleted-state → Y). Returns T on success or
   nst-entity-nil when the row is absent/already deleted."
  (request->dispatch request 'delete! 'nst-whs ctx))

(defun route-warehouse-list (request ctx)
  "कर्म = the filtered nst-whs collection. Calls the enumerate verb directly
   (not via request->dispatch) because its arguments are query filters rather
   than entity initargs — see whs-enumerate-args."
  (apply #'enumerate 'nst-whs ctx (whs-enumerate-args (params request))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Route registration
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; One line per inbound action. The route key IS the action symbol the
;;; dispatcher is called with: (dispatch-route2 'route-warehouse-create …).
;;; request-class is the SLOTLESS WarehouseRequestModel — the whole payload
;;; rides in its inherited params slot.
;;;
;;; required-roles / feature-flags / audit-level are CARRIED but NOT enforced
;;; by conflodis2 v1 (DESIGN §4.2, §11.1) — registered now so the metadata is
;;; in one place when the PEP/ABAC seam lands.

(register-action-route 'route-warehouse-create
                       :action-verb 'route-warehouse-create
                       :request-class 'WarehouseRequestModel
                       :description "Register a new warehouse (GSTIN-unique) for the session tenant."
                       :output-type :json
                       :channel :http
                       :required-roles '(warehouse-admin admin)
                       :feature-flags '(warehouse-domain)
                       :audit-level :full
                       :tags '(warehouse api v1))

(register-action-route 'route-warehouse-fetch
                       :action-verb 'route-warehouse-fetch
                       :request-class 'WarehouseRequestModel
                       :description "Fetch one warehouse by :row-id (or nst-entity-nil)."
                       :output-type :json
                       :channel :http
                       :required-roles '(warehouse-admin warehouse-operator admin)
                       :feature-flags '(warehouse-domain)
                       :audit-level :read
                       :tags '(warehouse api v1))

(register-action-route 'route-warehouse-update
                       :action-verb 'route-warehouse-update
                       :request-class 'WarehouseRequestModel
                       :description "Partially update a warehouse by :row-id."
                       :output-type :json
                       :channel :http
                       :required-roles '(warehouse-admin admin)
                       :feature-flags '(warehouse-domain)
                       :audit-level :full
                       :tags '(warehouse api v1))

(register-action-route 'route-warehouse-delete
                       :action-verb 'route-warehouse-delete
                       :request-class 'WarehouseRequestModel
                       :description "Soft-delete a warehouse by :row-id."
                       :output-type :json
                       :channel :http
                       :required-roles '(warehouse-admin admin)
                       :feature-flags '(warehouse-domain)
                       :audit-level :full
                       :tags '(warehouse api v1))

(register-action-route 'route-warehouse-list
                       :action-verb 'route-warehouse-list
                       :request-class 'WarehouseRequestModel
                       :description "List warehouses for the session tenant with filters and whitelisted sort."
                       :output-type :json
                       :channel :http
                       :required-roles '(warehouse-admin warehouse-operator admin)
                       :feature-flags '(warehouse-domain)
                       :audit-level :read
                       :tags '(warehouse api v1))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Reverse-ferry shims — temporarily warehouse-local
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; FLAG (read before extending): these methods are DOMAIN-GENERIC, not
;;; warehouse-specific, and by DESIGN §4.3 they belong in
;;; core/nst-bl-adhara.lisp. They live here only because that file currently
;;; declares nst-response-nil/-unknown/-contradiction WITHOUT ever ferrying
;;; nst-entity-nil/-unknown/-contradiction into them, so a fetch miss, a
;;; delete! ack or an :U/:C sentinel would die with NO-APPLICABLE-METHOD at
;;; the dispatcher's reverse ferry (conflodis2 SECTION 4). Relocate on the
;;; next adhara pass and delete this section.

(defmethod domain->response ((entity nst-entity-nil) (ctx domain-ctx))
  (declare (ignore ctx))
  (make-instance 'nst-response-nil :params (list :reason (entity-reason entity))))

(defmethod domain->response ((entity nst-entity-unknown) (ctx domain-ctx))
  (declare (ignore ctx))
  (make-instance 'nst-response-unknown :params (list :reason (entity-reason entity))))

(defmethod domain->response ((entity nst-entity-contradiction) (ctx domain-ctx))
  (declare (ignore ctx))
  (make-instance 'nst-response-contradiction :params (list :reason (entity-reason entity))))

(defclass warehouse-ack-response (nst-response-model)
  ()
  (:documentation
   "The ONE boundary type a verb in this file is allowed to build, and only
    because delete! has no कर्म left to return: the row it acted on is gone,
    so the ack itself is the outbound domain fact."))

(defmethod domain->response ((entity (eql t)) (ctx domain-ctx))
  "delete! (nst-bl-warehouse.lisp) acknowledges with a bare T."
  (declare (ignore entity ctx))
  (make-instance 'warehouse-ack-response :params (list :ok t :operation "delete")))

;;; ---- dṛś: the three Belnap sentinels + the ack, per format -------------

(defun whs-response-reason (r)
  (getf (params r) :reason))

(defun whs-error-json (code r)
  (json:encode-json-to-string
   (list (cons "error" code) (cons "reason" (whs-response-reason r)))))

(defun whs-error-html (css-class r)
  "cl-who:str escapes the reason — a domain reason string is never emitted
   as raw markup (same escaping discipline as display-warehouse-row)."
  (cl-who:with-html-output-to-string (s nil)
    (:div :class (format nil "error ~A" css-class)
          (cl-who:str (or (whs-response-reason r) "Error")))))

(defmethod render-json ((r nst-response-nil) (ctx domain-ctx))
  (declare (ignore ctx)) (whs-error-json "not_found" r))
(defmethod render-html ((r nst-response-nil) (ctx domain-ctx))
  (declare (ignore ctx)) (whs-error-html "not-found" r))

(defmethod render-json ((r nst-response-unknown) (ctx domain-ctx))
  (declare (ignore ctx)) (whs-error-json "unknown" r))
(defmethod render-html ((r nst-response-unknown) (ctx domain-ctx))
  (declare (ignore ctx)) (whs-error-html "unknown" r))

(defmethod render-json ((r nst-response-contradiction) (ctx domain-ctx))
  (declare (ignore ctx)) (whs-error-json "conflict" r))
(defmethod render-html ((r nst-response-contradiction) (ctx domain-ctx))
  (declare (ignore ctx)) (whs-error-html "conflict" r))

(defmethod render-json ((r warehouse-ack-response) (ctx domain-ctx))
  (declare (ignore ctx))
  (json:encode-json-to-string
   (list (cons "ok" (getf (params r) :ok))
         (cons "operation" (getf (params r) :operation)))))

(defmethod render-html ((r warehouse-ack-response) (ctx domain-ctx))
  (declare (ignore ctx))
  (cl-who:with-html-output-to-string (s nil)
    (:div :class "ack" (cl-who:str (or (getf (params r) :operation) "ok")))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 5 — Public API bindings (Ring 4)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; The API endpoint is a BINDING, not a second business route: this line says
;;; "PUT /hhub/api/v1/warehouse/{id} dispatches to the SAME route-warehouse-update
;;; verb the internal website handler calls", so both callers share one कारक
;;; build (नियम-1 from the credential), one ferry (request->dispatch !update
;;; 'nst-whs) and one set of domain laws.
;;;
;;; The /hhub prefix is part of the path because the deployed nginx proxies
;;; `location /hhub/` through unchanged while rewriting every other URI to
;;; /hhub/$1 — see the apidefs2 header. When nginx later gets a dedicated
;;; /api/ location, these templates drop the prefix in one pass.
;;;
;;; {id} is the numeric DOD_WAREHOUSE.row-id — every existing domain verb
;;; identifies a row that way (rm-row-id → parse-integer). Authorization is
;;; per-object: the verb re-selects with tenant-id from the session, so an id
;;; belonging to another tenant yields nst-entity-nil → 404, never data
;;; (OWASP API1:2023 BOLA). warehouse-uuid stays available if opaque ids are
;;; wanted later.
;;;
;;; The JSON body carries nst-whs initarg names ("wname", "warehouse-gstin",
;;; "wcity", …) — camelCase is accepted too. A body-supplied "tenant-id" or
;;; "row-id" cannot take effect: the first is stripped as reserved, the second
;;; is overridden by the path parameter.
;;;
;;; Not yet bound here (create/fetch/delete/list) — one line each when wanted:
;;;   POST   /hhub/api/v1/warehouse        → route-warehouse-create
;;;   GET    /hhub/api/v1/warehouse/{id}   → route-warehouse-fetch
;;;   DELETE /hhub/api/v1/warehouse/{id}   → route-warehouse-delete
;;;   GET    /hhub/api/v1/warehouse        → route-warehouse-list
;;;
;;; Notes on the two that need more than a path binding:
;;;   * CREATE also sets :inject-company, because make → copyWarehouse-domaintodb
;;;     derives the row's tenant from the legacy COMPANY slot exactly like the
;;;     update path does. success-status is 201.
;;;   * FETCH/DELETE/LIST do NOT: fetch uses copyWarehouse-dbtodomain (which
;;;     never touches COMPANY), and delete!/enumerate never call the copy
;;;     helper at all. Injecting there would push an initarg into verbs that do
;;;     not declare it.
;;;   * LIST passes its filters as query-string params (whs-param reads keyword
;;;     OR string keys), e.g. ?warehouse-type=own&city=Thane&sort-by=w-city.
;;;   * DELETE answers with the warehouse-ack-response body, not an entity —
;;;     there is no कर्म left once the row is soft-deleted.

(register-api-route 'route-warehouse-update
                    :method :put
                    :path "/hhub/api/v1/warehouse/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    ;; The nst-whs domain keeps a legacy COMPANY slot beside the
                    ;; TENANT-ID it inherits from nst-domain-entity, and
                    ;; copyWarehouse-domaintodb derives the DB row's tenant from
                    ;; that slot. The internal website handlers pass
                    ;; :company <login company> explicitly; the API has no such
                    ;; field coming from the client, so the auth module injects
                    ;; the SESSION company here before the PUT reaches the
                    ;; domain (नियम-1: the tenant is the credential's, never the
                    ;; payload's).
                    :inject-company t
                    :description "Update an existing warehouse for the authenticated tenant. Body: JSON object of nst-whs field names; only supplied fields change.")

(register-api-route 'route-warehouse-create
                    :method :post
                    :path "/hhub/api/v1/warehouse"
                    :success-status 201
                    :auth-scope :session
                    :inject-company t
                    :description "Create a warehouse for the authenticated tenant. Body: JSON object of nst-whs field names. GSTIN must be unique; the row-id, uuid and short code are generated by the domain.")

(register-api-route 'route-warehouse-fetch
                    :method :get
                    :path "/hhub/api/v1/warehouse/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Fetch one warehouse by numeric row-id. 404 when the row does not exist or belongs to another tenant.")

(register-api-route 'route-warehouse-delete
                    :method :delete
                    :path "/hhub/api/v1/warehouse/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Soft-delete a warehouse by numeric row-id (deleted-state Y). 404 when it does not exist or is already deleted.")

(register-api-route 'route-warehouse-list
                    :method :get
                    :path "/hhub/api/v1/warehouse"
                    :success-status 200
                    :auth-scope :session
                    :description "List the authenticated tenant's warehouses. Query params: warehouse-type, state-code, city, is-primary-location, name-like, sort-by, sort-dir.")

;;; End of nst-bl-whsapi.lisp
