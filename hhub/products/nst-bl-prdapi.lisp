;;; nst-bl-prdapi.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; PRODUCTS ACTION ROUTES — conflodis2 Tier 2 (Ring 2/3).
;;;
;;; Design:     hhub/core/nst-bl-conflodis2-DESIGN.md  (§3 signature, §5 multi-
;;;             entity assembly, §6 कारक, §9 file layout)
;;; Dispatcher: hhub/core/nst-bl-conflodis2.lisp
;;; Domain:     hhub/products/dod-dal-prd.lisp   (nst-prd, ProductRequestModel)
;;;             hhub/products/dod-bl-prd.lisp    (the Tier-1 प्रत्यय)
;;;
;;; NOTE THE NEAR-NAME COLLISION: hhub/products/nst-bl-prodapi.lisp also exists
;;; and is INERT — it holds the original twelve register-outbound-route sketches
;;; for the old (pre-conflodis2) registry, whose classes were never defined and
;;; whose /api/v1/... paths could never be reached through nginx. This file is
;;; the live surface. "prodapi" = dead spec, "prdapi" = this.
;;;
;;; The shape is the whs analogue of hhub/warehouse/nst-bl-whsapi.lisp — same
;;; purpose (the API surface of ONE domain). There is no :crud-op here, no
;;; adapter/presenter/view wiring, no businessobject-class. Instead:
;;;
;;;   inbound action symbol  →  (register-action-route 'route-<action> …)  →
;;;   ONE route-<action> verb →  Tier-1 ferries (request->dispatch … 'nst-prd)
;;;
;;; Every route-<action> verb returns DOMAIN-LAYER results (an nst-prd, a list of
;;; them, or a Belnap sentinel). The dispatcher alone runs the reverse ferry
;;; (domain->response) and the Ring-4 render (dṛś). No verb here constructs a
;;; boundary type — with the one warehouse-inherited exception of returning
;;; nst-entity-contradiction, which is a DOMAIN sentinel, not a response model.
;;;
;;; नियम-1: the tenant (अधिकरण) is built by make-action-domain-ctx from the
;;; SESSION login company. A client-supplied :tenant-id in params is stripped by
;;; extract-domain-initargs and never reaches nst-prd.
;;;
;;; WHY THERE IS NO :inject-company ON ANY PRODUCTS ROUTE (a deliberate
;;; difference from the warehouse bindings): nst-prd's make fills the legacy
;;; company slot from ctx by itself, so nothing in the product verb chain needs
;;; the company handed to it through params. See dod-bl-prd.lisp's make.
;;;
;;; Load order: AFTER core/nst-bl-adhara.lisp, core/nst-bl-conflodis2.lisp,
;;; products/dod-dal-prd.lisp and products/dod-bl-prd.lisp.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Params readers
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; nst-prd inbound data rides in (params request) as a plist of the DOMAIN
;;; class's own initargs — (:prd-name "…" :catg-id 7 :sku "…"), not the DB
;;; column spellings. extract-domain-initargs does the MOP filtering; these
;;; readers only handle what it does NOT: values that must become keywords or
;;; integers, and list-verb query arguments (which are enumerate keywords, not
;;; entity initargs, so the ferry would drop every one of them).

(defun prd-param (payload key)
  "Read KEY (a keyword initarg/query name) from PAYLOAD.
   Accepts a keyword-keyed plist (conflodis2/api callers) or a string-keyed
   plist (a JSON body or querystring parsed by another inbound adapter)."
  (or (getf payload key)
      (getf payload (string-downcase (symbol-name key)))))

(defun prd-keyword-value (value)
  "Coerce an inbound scalar to the keyword form the domain expects —
   \"row-id\"/\"ROW-ID\"/'row-id → :ROW-ID. Non-scalars pass through."
  (cond ((null value) nil)
        ((keywordp value) value)
        ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
        ((stringp value) (intern (string-upcase value) :keyword))
        (t value)))

(defun prd-int-arg (value what)
  "Query and JSON scalars arrive as STRINGS; :limit/:offset must reach CLSQL as
   integers. A value that is present but unusable SIGNALS rather than being
   dropped: silently ignoring a filter the caller asked for is the class of bug
   this project already has on record (nst-bl-apidefs2-CONTEXT.md §9.6, where
   '?is-primary-location=0' filtered FOR primary locations)."
  (cond ((null value) nil)
        ((integerp value) value)
        ((and (stringp value)
              (plusp (length value))
              (every #'digit-char-p value))
         (parse-integer value))
        (t (error "~A ~S is not a non-negative integer" what value))))

(defun prd-enumerate-args (payload)
  "Filter args for (enumerate 'nst-prd ctx …).
   NOT a ferry, deliberately: :status/:catg-id/:sort-by/:limit are QUERY
   arguments of the enumerate verb, not initargs of nst-prd, so
   extract-domain-initargs would drop every one of them. A list action is not an
   entity crossing — it is one fetch of a filtered collection — so the verb
   builds these itself and still calls the Tier-1 verb with the entity class as
   कर्म.

   :keyword IS ACCEPTED AS A SYNONYM FOR :name-like because the original products
   API sketch called that filter 'keyword' while the domain verb calls it
   name-like. Accepting both keeps the published surface honest without
   renaming a verb whose meaning is 'LIKE %x% on PRD_NAME'.

   ⚠ TRANSPORT GAP, flagged rather than hidden: these values are read from
   (params request), and apidefs2's api-params-for-request currently merges ONLY
   the session company, the path params and the JSON BODY — it does not read the
   query string at all. A GET /catalog/products?status=active would therefore
   arrive with no :status key and the filters would be silently ignored. Until
   apidefs2 grows an api-query-params step, this verb is reachable with filters
   only from non-HTTP callers (REPL, widgets) or a request that carries them in
   the body. That is a Step-7 change in core/nst-bl-apidefs2.lisp, not a change
   to the domain."
  (list :status     (prd-param payload :status)
        :catg-id    (prd-param payload :catg-id)
        :vendor-id  (prd-param payload :vendor-id)
        :name-like  (or (prd-param payload :name-like)
                        (prd-param payload :keyword))
        :min-price  (prd-param payload :min-price)
        :max-price  (prd-param payload :max-price)
        :sort-by    (or (prd-keyword-value (prd-param payload :sort-by)) :row-id)
        :sort-dir   (or (prd-keyword-value (prd-param payload :sort-dir)) :desc)
        :limit      (prd-int-arg (prd-param payload :limit) "limit")
        :offset     (prd-int-arg (prd-param payload :offset) "offset")))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action verbs (Tier 2)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Signature is uniform and fixed by DESIGN §3: (route-<action> request ctx).
;;; Plain defuns, not generics — the dispatcher resolves them with fdefinition,
;;; exactly like route-ping.

(defun route-product-create (request ctx)
  "कर्म = nst-prd. The PRODUCT_CODE uniqueness laws ride in nst-prd's own
   ?exists / make :before (dod-bl-prd.lisp) — the ferry does not re-check them.

   ONE exception, because it is not a legality question but an epistemic one: an
   identity held by a SOFT-DELETED row. PRODUCT_CODE's unique index carries no
   DELETED_STATE, so a deleted product keeps its code reserved forever, while
   नियम-2 makes that row invisible to every verb. The client's 'create this' and
   the world's 'the code is taken, by a row marked deleted' disagree → Belnap :C.

   Returning the contradiction HERE is what turns that disagreement into a 409
   with a reason a human can act on. Letting it fall through to make :before
   would raise an error, which the unfinished taxonomy renders as a 500 — with
   the difference between 'duplicate' and 'deleted, undelete it' visible only in
   the log."
  (let* ((payload (params request))
         (code (prd-param payload :product-code))
         (check (when (and code (stringp code))
                  (?exists 'nst-prd code ctx))))
    (if (and check (eq (bo-knowledge-truth check) :C))
        (make-instance 'nst-entity-contradiction
                       :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                       :reason (format nil "PRODUCT_CODE ~A is held by a SOFT-DELETED product: the row is still in DOD_PRD_MASTER and the unique index on PRODUCT_CODE includes no DELETED_STATE, while नियम-2 makes it invisible to every verb. Human decision needed: undelete that product, or create this one under a different code."
                                       code))
        (request->dispatch request 'make 'nst-prd ctx))))

(defun route-product-fetch (request ctx)
  "कर्म = nst-prd. Reads :row-id from params (rm-row-id). Returns an nst-prd or
   a Belnap sentinel — never a bare CL nil (adhara Section 6's fetch contract).
   The dispatcher's reverse ferry turns nst-entity-nil into nst-response-nil, so
   a miss is a 404 without any product-specific code."
  (request->dispatch request 'fetch 'nst-prd ctx))

(defun route-product-update (request ctx)
  "कर्म = nst-prd. Partial update (CLOS reinitialize-instance): only the initargs
   actually supplied in params change. :row-id selects the row and is stripped by
   the verb itself. NOTE: the 're-trigger approval if major fields change' rule in
   the original products spec is NOT implemented — it is a business law, and it
   belongs here or in the domain, not smuggled into !update."
  (request->dispatch request '!update 'nst-prd ctx))

(defun route-product-delete (request ctx)
  "कर्म = nst-prd. SOFT delete: DELETED_STATE → \"Y\", the row kept, so its
   PRODUCT_CODE stays reserved (which is what makes the next create on that code
   a :C contradiction rather than a fresh product). Returns T, which the
   dispatcher's reverse ferry maps to an ack response."
  (request->dispatch request 'delete! 'nst-prd ctx))

(defun route-product-list (request ctx)
  "कर्म = the filtered nst-prd collection. Calls the enumerate verb DIRECTLY (not
   via request->dispatch) because its arguments are query filters rather than
   entity initargs — see prd-enumerate-args, including the transport gap noted
   there."
  (apply #'enumerate 'nst-prd ctx (prd-enumerate-args (params request))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Route registration
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; One line per inbound action. The route key IS the action symbol the
;;; dispatcher is called with: (dispatch-route2 'route-product-create …).
;;; request-class is the SLOTLESS ProductRequestModel — the whole payload rides
;;; in its inherited params slot.
;;;
;;; required-roles / feature-flags / audit-level are CARRIED but NOT ENFORCED by
;;; conflodis2 v1 (DESIGN §4.2, §11.1) — registered now so the metadata is in one
;;; place when the PEP/ABAC seam lands. Do not read them as protection.
;;;
;;; THE SEVEN ENDPOINTS OF THE ORIGINAL SKETCH THAT ARE ABSENT HERE, and why —
;;; listed so their absence is a decision and not an oversight:
;;;
;;;   update-status     could be !update with :active-flag, but the published
;;;                     'active | inactive' vocabulary does not match the schema's
;;;                     three-column reality (active_flag is 'Y' on all 107 live
;;;                     rows; what delists a product is approved_flag/deleted_state).
;;;                     Registering it before that is settled would publish a verb
;;;                     that cannot do what its name says.
;;;   update-shipping   the shipping_* columns ARE on the master row, so this is
;;;                     !update with those initargs — achievable, but it needs a
;;;                     product-owned validation rule first (a weight without a
;;;                     unit, a zero dimension).
;;;   copy              needs read-then-make with an explicit field policy (does a
;;;                     copy inherit approval? pricing tiers?). A design decision.
;;;   update-pricing    prices live in DOD_PRODUCT_PRICING, which has NO domain
;;;                     entity and no Tier-1 प्रत्यय — nothing for a route to call.
;;;   bulk-create       CSV upload: multipart, and apidefs2 reads the body as JSON
;;;                     only (api-request-body-params). Blocked on that extension.
;;;   upload-images     same multipart block.
;;;   template          produces text/csv, not JSON — it should not go through
;;;                     api-write-json at all, so it is an apidefs2 concern.

(register-action-route 'route-product-create
                       :action-verb 'route-product-create
                       :request-class 'ProductRequestModel
                       :description "Create a product (PRODUCT_CODE-unique) for the session tenant, pending CompAdmin approval."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :full
                       :tags '(products catalog api v1))

(register-action-route 'route-product-fetch
                       :action-verb 'route-product-fetch
                       :request-class 'ProductRequestModel
                       :description "Fetch one product by :row-id within the session tenant (or a Belnap sentinel)."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :read
                       :tags '(products catalog api v1))

(register-action-route 'route-product-update
                       :action-verb 'route-product-update
                       :request-class 'ProductRequestModel
                       :description "Partially update a product by :row-id — only the supplied fields change."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :full
                       :tags '(products catalog api v1))

(register-action-route 'route-product-delete
                       :action-verb 'route-product-delete
                       :request-class 'ProductRequestModel
                       :description "Soft-delete a product by :row-id (the row and its PRODUCT_CODE stay reserved)."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :full
                       :tags '(products catalog api v1))

(register-action-route 'route-product-list
                       :action-verb 'route-product-list
                       :request-class 'ProductRequestModel
                       :description "List the session tenant's catalog with status/category/vendor/keyword/price filters and whitelisted sort."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :read
                       :tags '(products catalog api v1))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Public API bindings (Ring 4)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; One binding per (METHOD, PATH) → an ALREADY-REGISTERED action route. The
;;; registration calls above must come first: register-api-route REFUSES to bind
;;; a path to a verb that does not exist (api-route-bindable-p), and the whole
;;; file is re-evaluated on every reload, so this order is load-bearing.
;;;
;;; THE PATH PREFIX IS PART OF THE TEMPLATE. The deployed nginx proxies
;;; `location /hhub/` straight through and rewrites every other URI to /hhub/$1,
;;; so /hhub/api/v1/... arrives unchanged; register-api-route rejects a template
;;; without the prefix because it would be unreachable through the proxy.
;;;
;;; NO ROUTE HERE CARRIES :inject-company, and that is a deliberate difference
;;; from the warehouse bindings rather than an omission. nst-prd's make and
;;; !update set the कारक company from the domain-ctx UNCONDITIONALLY, so the
;;; session tenant cannot be overridden by a body or query string. The warehouse
;;; has to inject the company through params because its domain verbs take it
;;; from the entity — a rule that depends on leftmost-initarg precedence. Both
;;; end up tenant-safe; this one does not depend on initarg ordering.
;;;
;;; {id} IS A NUMERIC ROW-ID (DOD_PRD_MASTER.ROW_ID). Authorization is
;;; per-object: every verb re-selects with the tenant from the session, so
;;; another tenant's id yields 404, never data. Unlike PRODUCT_CODE, which is
;;; globally unique, the row-id is not a credential and must not be treated as
;;; one.
;;;
;;; STATUS MAPPING (apidefs2 §5) applies unchanged: 201 for create, 200
;;; otherwise, 200 [] for an empty catalog, 404 for a fetch/update/delete miss,
;;; 409 when a create collides with a SOFT-DELETED product's code, 401 without a
;;; session, 400 for a malformed body or path. Endpoints we did not bind (bulk,
;;; template, images, pricing, status, copy, shipping) answer 404
;;; no_such_endpoint — see SECTION 3 for why each is absent.

(register-api-route 'route-product-list
                    :method :get
                    :path "/hhub/api/v1/catalog/products"
                    :success-status 200
                    :auth-scope :session
                    :description "List the session tenant's catalog. Query params: status (active|inactive|pending|rejected), catg-id, vendor-id, name-like (alias: keyword), min-price, max-price, sort-by, sort-dir, limit, offset. An empty catalog is 200 [].")

(register-api-route 'route-product-create
                    :method :post
                    :path "/hhub/api/v1/catalog/products"
                    :success-status 201
                    :auth-scope :session
                    :description "Create a product for the session tenant. Body: JSON object of nst-prd field names. product-code is generated when omitted; active/approved/approval-status default to Y/N/PENDING. 409 when the code is held by a soft-deleted product.")

(register-api-route 'route-product-fetch
                    :method :get
                    :path "/hhub/api/v1/catalog/products/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Fetch one product by numeric row-id. 404 when it does not exist or belongs to another tenant.")

(register-api-route 'route-product-update
                    :method :put
                    :path "/hhub/api/v1/catalog/products/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Partially update a product by numeric row-id; only the supplied fields change. 404 when it does not exist in this tenant.")

(register-api-route 'route-product-delete
                    :method :delete
                    :path "/hhub/api/v1/catalog/products/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Soft-delete a product by numeric row-id: the row is kept and its product-code stays reserved, so re-creating that code later is a 409, not a fresh product.")
