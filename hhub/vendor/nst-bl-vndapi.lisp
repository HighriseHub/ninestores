;;; nst-bl-vndapi.lisp — Vendor profile API: action verbs, action routes, API bindings
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; 🚨 NOT YET LOADED. This file is wired into nstores.asd and package/compile.lisp
;;; but has never been compiled. Nothing in it has run. See §0 of
;;; vendor/nst-bl-vndapi-CONTEXT.md, and call the प्रत्यय directly before trusting
;;; any binding here.
;;;
;;; WHAT THIS FILE IS. The Ring-3/Ring-4 surface for the vendor PROFILE entity
;;; (nst-vnd, vendor/nst-dal-vnd.lisp) built on the six Tier-1 प्रत्यय in
;;; vendor/nst-bl-vnd.lisp. It is a copy of the shape of
;;; products/nst-bl-prdapi.lisp — the newest reference — with the vendor-specific
;;; differences stated where they bite.
;;;
;;; THE INVARIANT: this file adds TRANSPORT, never business routes. Every endpoint
;;; below is a thin binding onto an already-registered verb, so an API call and an
;;; internal page share one कारक build, one ferry, one set of domain laws. That
;;; matters more for vendor than for products, because the vendor identity law
;;; (tenant-scoped UC_Vendor) and the secret lockout both live in the प्रत्यय —
;;; duplicating either here would create the two-implementations problem the
;;; products work spent a session removing.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE PATH, AND WHY IT IS /vendor/profile
;;;
;;; core/nstoresapi.html — the API surface design — specifies NO vendor profile
;;; CRUD. Its vendor surface is exactly four families:
;;;
;;;   admin/vendors/{pending, {id}/approve, {id}/reject}   CompAdmin
;;;   auth/vendor/{login, logout, tenant}                  all / vendor
;;;   vendor/payment/{gateway, upi, upi-transactions}      vendor
;;;   vendor/shipping/{default, flat-rate, ...}            vendor
;;;
;;; — approval, auth, payment and shipping. Nothing that reads, creates, updates or
;;; deletes a vendor RECORD. vendor/nst-bl-vendapi.lisp (the stale pre-conflodis2
;;; sketch) has the same gap: its nine routes are those same four families.
;;;
;;; So this surface is ADDITIVE, and the path was chosen rather than inherited:
;;; /hhub/api/v1/vendor/profile sits in the doc's own `vendor/*` family, parallel
;;; to /hhub/api/v1/catalog/products for products. `{id}` therefore addresses one
;;; profile within that collection, exactly as `products/{id}` does.
;;;
;;; 🚨 THE PATH DOES NOT RESTRICT ANYTHING. required-roles / feature-flags /
;;; audit-level are CARRIED but NOT ENFORCED by conflodis2 v1 — see the same note
;;; in products/nst-bl-prdapi.lisp. Registering :required-roles '(vendor) below
;;; records INTENT so the metadata is in one place when the PEP/ABAC seam lands.
;;; Do not read it as protection: every endpoint here answers to any
;;; authenticated session today.
;;;
;;; THIS MATTERS MORE HERE THAN FOR PRODUCTS, because of two verbs:
;;;   * `make` requires PASSWORD and sets the vendor's LOGIN CREDENTIAL, and
;;;   * `!update` can write approved-flag / approval-status / suspend-flag — the
;;;     columns the login contract reads (approved_flag='Y' AND
;;;     approval_status='APPROVED' AND deleted_state='N').
;;; A caller of either can create a login or lock an existing vendor out of its
;;; own. That is a real authorization decision, it is NOT made by this file, and
;;; it is recorded here so it is not mistaken for one.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; NO ROUTE HERE CARRIES :inject-company
;;;
;;; Deliberate, and the same difference from the warehouse that products has.
;;; nst-vnd's `make` and `!update` set the कारक company from the domain-ctx
;;; UNCONDITIONALLY, so the session tenant cannot be overridden by a body or query
;;; string. The warehouse has to inject the company through params because its
;;; verbs take it from the entity — a rule that depends on leftmost-initarg
;;; precedence. Both end up tenant-safe; this one does not depend on initarg
;;; ordering at all.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THREE PATHS HERE WILL ANSWER 500 WHERE 400 IS RIGHT
;;;
;;; Known and recorded, not a surprise when it shows up in a test:
;;;   1. POST with a missing NOT NULL field    → vendor-required-field-missing
;;;   2. PUT carrying :password/:salt/:payment-api-key/:payment-api-salt
;;;                                            → vendor-required-field-missing
;;;   3. GET with a bad ?sort-by= / ?sort-dir= → validate-vendor-sort-args
;;;
;;; All three signal a condition, and the current taxonomy maps a condition to
;;; 500. 400 is correct. This is the same defect the warehouse has with
;;; validate-sort-args and it is fixed in one place for all of them — see
;;; §7.2 of the CONTEXT. Until then a 500 is still better than the 503 those
;;; paths would otherwise produce.
;;;
;;; STATUS MAPPING (apidefs2 §5) otherwise applies unchanged: 201 for create, 200
;;; otherwise, 200 [] for an empty list, 404 for a fetch/update/delete miss, 409
;;; when a create collides with a SOFT-DELETED vendor's phone IN THAT TENANT, 401
;;; without a session.
;;; ═══════════════════════════════════════════════════════════════════════════

(in-package :nstores)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Inbound parameter helpers
;;;
;;; The ferry (request->dispatch / extract-domain-initargs) handles everything
;;; that is an ENTITY INITARG. It cannot handle these, and deliberately so:
;;; :row-id is a path param, and the list verb's arguments are enumerate KEYWORDS
;;; rather than nst-vnd initargs, so the ferry would drop every one of them.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun vnd-param (payload key)
  "Read KEY (a keyword initarg/query name) from PAYLOAD.
   Accepts a keyword-keyed plist (conflodis2/api callers) or a string-keyed plist
   (a JSON body or query string parsed by another inbound adapter)."
  (or (getf payload key)
      (getf payload (string-downcase (symbol-name key)))))

(defun vnd-keyword-value (value)
  "Coerce an inbound scalar to the keyword form the domain expects —
   \"approval-status\"/\"APPROVAL-STATUS\"/'approval-status → :APPROVAL-STATUS.
   Non-scalars pass through."
  (cond ((null value) nil)
        ((keywordp value) value)
        ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
        ((stringp value) (intern (string-upcase value) :keyword))
        (t value)))

(defun vnd-int-arg (value what)
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

(defun vnd-enumerate-args (payload)
  "Filter args for (enumerate 'nst-vnd ctx …).
   NOT a ferry, deliberately: these are QUERY arguments of the enumerate verb,
   not initargs of nst-vnd, so extract-domain-initargs would drop every one.

   :keyword IS ACCEPTED AS A SYNONYM FOR :name-like, matching the products API,
   because the original API sketches called that filter 'keyword' while the domain
   verb calls it name-like. Accepting both keeps the published surface honest
   without renaming a verb whose meaning is 'LIKE %x% on NAME'.

   THE QUERY STRING DOES REACH HERE. api-params-for-request merges the session
   company, path params, the JSON body and — since the products work —
   the query string (api-query-params, apidefs2). Products' own comment still
   carries a stale ⚠ TRANSPORT GAP warning saying otherwise; it was written before
   that merge landed, and ?limit=2 returning exactly 2 objects is what proved it.

   :status is passed through RAW, not keywordised here: the enumerate verb applies
   vnd-status-arg itself, so an unknown status signals in the DOMAIN with a
   message naming the valid set, rather than in the transport."
  (list :status          (vnd-param payload :status)
        :approval-status (vnd-param payload :approval-status)
        :name-like       (or (vnd-param payload :name-like)
                             (vnd-param payload :keyword))
        :city            (vnd-param payload :city)
        :gst-number      (vnd-param payload :gst-number)
        :sort-by         (or (vnd-keyword-value (vnd-param payload :sort-by)) :row-id)
        :sort-dir        (or (vnd-keyword-value (vnd-param payload :sort-dir)) :desc)
        :limit           (vnd-int-arg (vnd-param payload :limit) "limit")
        :offset          (vnd-int-arg (vnd-param payload :offset) "offset")))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action verbs (Tier 2)
;;;
;;; Signature is uniform and fixed: (route-<action> request ctx). Plain defuns,
;;; not generics — the dispatcher resolves them with fdefinition, exactly like
;;; route-ping and route-product-*.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun route-vendor-create (request ctx)
  "कर्म = nst-vnd. The tenant-scoped UC_Vendor identity law — including the
   soft-deleted-holder :C — rides in the verb's own `make :around`
   (nst-bl-vnd.lisp), so the API, the internal website and any REPL caller all get
   the same four-valued answer. The required-field guard and the username
   derivation ride there too.

   🚨 THIS VERB SETS THE VENDOR'S LOGIN CREDENTIAL: password is one of the four
   fields `make` requires, so an API create provisions a working login. Whatever
   authorization the binding layer grows must treat this as a privileged act —
   see the header. Nothing enforces that today."
  (request->dispatch request 'make 'nst-vnd ctx))

(defun route-vendor-fetch (request ctx)
  "कर्म = nst-vnd. Reads :row-id from params. Returns an nst-vnd or a Belnap
   sentinel — never a bare CL nil (adhara §6's fetch contract). The dispatcher's
   reverse ferry turns nst-entity-nil into nst-response-nil, so a miss is a 404
   with no vendor-specific code. Authorization is per-object: the verb re-selects
   WITH THE SESSION TENANT, so another tenant's row-id is a 404, never data
   (OWASP API1:2023 BOLA) — which is exactly why the new verbs do not use the
   legacy select-vendor-by-id, which is not tenant-scoped."
  (request->dispatch request 'fetch 'nst-vnd ctx))

(defun route-vendor-update (request ctx)
  "कर्म = nst-vnd. Partial update (CLOS reinitialize-instance): only the initargs
   actually supplied in params change. :row-id selects the row and is stripped by
   the verb itself.

   🚨 TWO VENDOR-ONLY LAWS RIDE IN !update, not here, because they are domain law
   and not transport law:
     1. it REFUSES the four secret initargs (:password :salt :payment-api-key
        :payment-api-salt) rather than silently stripping them. A dropped
        :password leaves the client believing it rotated a credential that was
        never touched. Credential rotation is its own verb.
     2. it can write approved-flag / approval-status / suspend-flag, which the
        login contract reads — so this verb can lock a vendor out of its own
        login. Approval and suspension want their own verbs with a CompAdmin
        credential; until those exist this note is the only record of it."
  (request->dispatch request '!update 'nst-vnd ctx))

(defun route-vendor-delete (request ctx)
  "कर्म = nst-vnd. SOFT delete: DELETED_STATE → \"Y\", the row kept, so its PHONE
   stays reserved — but PER TENANT, unlike products. UC_Vendor is
   UNIQUE(PHONE, TENANT_ID), so the number is blocked only in the tenant that held
   it and may be registered in any other. That per-tenant reservation is the one
   behaviour that genuinely distinguishes this entity from nst-prd, and it is the
   assertion the smoke test must make. Returns T, which the reverse ferry maps to
   an ack response."
  (request->dispatch request 'delete! 'nst-vnd ctx))

(defun route-vendor-list (request ctx)
  "कर्म = the filtered nst-vnd collection. Calls the enumerate verb DIRECTLY (not
   via request->dispatch) because its arguments are query filters rather than
   entity initargs — see vnd-enumerate-args."
  (apply #'enumerate 'nst-vnd ctx (vnd-enumerate-args (params request))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; The INVOICE_SETTINGS sub-resource
;;;
;;; WHY IT EXISTS. :invoice-settings is a declared initarg on nst-vnd, so generic
;;; !update already accepted it and wrote the column with NO validation at all — a
;;; blob whose section keys are keywords lands in the table and the readers' strict
;;; (assoc 'invoice-print-settings … :test #'equal) then misses it and silently falls
;;; back to the shipped defaults, reverting the vendor's configuration without an
;;; error anywhere. !settings owns that invariant; this is its only HTTP door.
;;;
;;; THE BODY *IS* THE SETTINGS OBJECT, with no wrapper key — the same shape the
;;; sibling payment-methods PUT uses (its body is the flat flag set). The ferry hop
;;; for !settings reads ONE named :settings key, so the payload is re-labelled here,
;;; in the transport, rather than making every client wrap its body in a key whose
;;; name the URL already states.
;;; ═══════════════════════════════════════════════════════════════════════════

(defparameter *vnd-settings-transport-keys* '(:row-id :company)
  "Keys api-params-for-request may add to an inbound params plist that are NOT part of
   the settings object: :row-id from the path params, and :company from the session —
   which is only injected when a route is registered with :inject-company, and the
   vendor bindings are not. :company is stripped anyway, defensively: enabling
   :inject-company on this binding later must not silently become a settings section
   called \"company\". Every OTHER key is a section, which is what makes a wrapper key
   unnecessary — and a stray query parameter is then REFUSED by the section allowlist,
   the failure this wants: closed and named, not silently stored.")

(defun vnd-settings-payload (params)
  "The settings object out of an inbound params plist, as a SECTION ALIST.

   THE GROUPING IS THIS FUNCTION'S REAL WORK, and it is not cosmetic. PARAMS IS A
   PLIST — (:section <object> :section <object> …) — and a plist read as a list of
   (key . value) pairs does not give pairs at all: its elements are the alternating
   key and value ATOMS, so the first section arrives with its body and the SECOND
   arrives as a bare keyword, which section validation then refuses with
   ':INVOICE-GENERAL-SETTINGS is not a (section . entries) pair'. That is exactly how
   this failed the first time. Walking BY #'CDDR is what turns the transport's plist
   into the alist the domain speaks."
  (let ((rest (copy-list params)))
    (dolist (key *vnd-settings-transport-keys*) (remf rest key))
    (loop for (key value) on rest by #'cddr collect (cons key value))))

(defun vnd-settings-request (request)
  "REQUEST with its body relabelled under the :settings key the ferry hop reads, and
   returned so it can be dispatched.

   THE FERRY TAKES THE REQUEST MODEL, NOT THE PAYLOAD — (request->dispatch rm '!settings
   'nst-vnd ctx) — and its !settings method reads (getf (params rm) :settings). So the
   ONE thing this has to do is present the body under that key. Passing the payload
   itself as the first argument instead lands a plist where a request model belongs and
   answers with no-applicable-method; that was written first, and this docstring exists
   so it is not written again.

   The relabelled key goes FIRST so getf finds it, and the transport keys stay in the
   plist behind it so rm-row-id still resolves the address. Mutating params here is
   safe: the API layer built this request model for this one dispatch, and the ferry's
   whole contract is that the request model dies at the crossing."
  (setf (params request)
        (list* :settings (vnd-settings-payload (params request)) (params request)))
  request)

(defun route-vendor-settings-update (request ctx)
  "कर्म = the INVOICE_SETTINGS sub-resource of nst-vnd, by :row-id.

   The verb validates before it reads the row, so a malformed blob is malformed
   whether or not the vendor exists — see !settings for why the order matters.

   OVER HTTP THE BODY MUST BE A JSON OBJECT, one key per settings section. The verb
   itself also accepts the stored blob as a STRING and stores it verbatim, but that
   path is unreachable from here: api-normalize-body-params refuses a non-object body
   outright ('the request body must be a JSON object'), and rightly — a settings
   sub-resource whose representation is sometimes an object and sometimes a string is
   two contracts for one URL. The string form exists for internal callers, and the
   consequence to know is that a client can READ the blob as a string from
   GET /hhub/api/v1/vendor/profile/{id} but cannot PUT that string back: a
   JSON-shaped read of the settings is not built yet."
  (request->dispatch (vnd-settings-request request) '!settings 'nst-vnd ctx))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Route registration
;;;
;;; One line per inbound action. The route key IS the action symbol the dispatcher
;;; is called with: (dispatch-route2 'route-vendor-create …). request-class is the
;;; SLOTLESS VendorRequestModel — the whole payload rides in its inherited params
;;; slot.
;;;
;;; required-roles / feature-flags / audit-level are CARRIED but NOT ENFORCED by
;;; conflodis2 v1. Do not read them as protection — see the header.
;;;
;;; THE VENDOR ENDPOINTS OF THE ORIGINAL SKETCH THAT ARE ABSENT HERE, and why —
;;; listed so their absence is a decision and not an oversight. All nine of
;;; vendor/nst-bl-vendapi.lisp's routes are absent, and the file itself should be
;;; deleted or reduced first, because `vendapi` and `vndapi` differ by one letter:
;;;
;;;   admin/vendors/pending      get-vendors-for-approval (dod-bl-ven.lisp) exists
;;;                              and answers this, but it is a legacy function
;;;                              with a hard-wired predicate
;;;                              (approved_flag='N' AND active_flag='Y' AND
;;;                              approval_status='PENDING'). The new surface
;;;                              reaches the same rows via
;;;                              ?status=pending, so a second binding would be a
;;;                              duplicate route to the same fact.
;;;   {id}/approve, {id}/reject  a REAL gap, not an oversight. Setting
;;;                              approved_flag + approval_status + approved_by is
;;;                              a domain LAW — it is what the login contract
;;;                              reads — so it belongs in its own प्रत्यय with its
;;;                              own verb, not in a route that writes three fields
;;;                              through generic !update. Do it before exposing
;;;                              approval over HTTP.
;;;   auth/vendor/*              login/logout/tenant are SESSION concerns, not
;;;                              entity concerns. dod-vend-login already owns them
;;;                              and the API layer authenticates separately
;;;                              (api-authenticate). Out of scope for this file.
;;;   vendor/payment/*           DOD_VPAYMENT_METHODS has no domain entity and no
;;;                              Tier-1 प्रत्यय — nothing for a route to call.
;;;   vendor/shipping/*          the shipping_enabled column IS on the vendor row,
;;;                              so that one flag is reachable today through
;;;                              !update; the five shipping endpoints need their
;;;                              own entity (DOD_VENDOR_SHIP_ZONES) and are not
;;;                              built.
;;; ═══════════════════════════════════════════════════════════════════════════

(register-action-route 'route-vendor-create
                       :action-verb 'route-vendor-create
                       :request-class 'VendorRequestModel
                       :description "Register a vendor (PHONE unique per tenant), pending CompAdmin approval."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor api v1))

(register-action-route 'route-vendor-fetch
                       :action-verb 'route-vendor-fetch
                       :request-class 'VendorRequestModel
                       :description "Fetch one vendor by :row-id within the session tenant (or a Belnap sentinel)."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :read
                       :tags '(vendors vendor api v1))

(register-action-route 'route-vendor-update
                       :action-verb 'route-vendor-update
                       :request-class 'VendorRequestModel
                       :description "Partially update a vendor by :row-id — only the supplied fields change. Credential fields are refused."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor api v1))

(register-action-route 'route-vendor-delete
                       :action-verb 'route-vendor-delete
                       :request-class 'VendorRequestModel
                       :description "Soft-delete a vendor by :row-id (the row is kept and its PHONE stays reserved in this tenant)."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor api v1))

(register-action-route 'route-vendor-list
                       :action-verb 'route-vendor-list
                       :request-class 'VendorRequestModel
                       :description "List the session tenant's vendors with status/approval-status/city/gst/keyword filters and whitelisted sort."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :read
                       :tags '(vendors vendor api v1))

(register-action-route 'route-vendor-settings-update
                       :action-verb 'route-vendor-settings-update
                       :request-class 'VendorRequestModel
                       :description "Replace one vendor's INVOICE_SETTINGS blob by :row-id. Validated in the domain, not here: section names must be ones the shipped defaults carry, a NULL read back as \"undefined\" is refused, and a JSON body's section keys are canonicalised so the readers can find them."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor invoice settings api v1))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Public API bindings (Ring 4)
;;;
;;; One binding per (METHOD, PATH) → an ALREADY-REGISTERED action route. The
;;; registration calls above must come first: register-api-route REFUSES to bind a
;;; path to a verb that does not exist (api-route-bindable-p), and the whole file
;;; is re-evaluated on every reload, so this order is load-bearing.
;;;
;;; THE PATH PREFIX IS PART OF THE TEMPLATE. register-api-route rejects a template
;;; without "/hhub/" because the deployed nginx proxies that prefix and rewrites
;;; everything else — a template without it would be unreachable.
;;;
;;; {id} IS A NUMERIC ROW-ID (DOD_VEND_PROFILE.ROW_ID), passed through
;;; path-params as :row-id. It is an ADDRESS, never an authorization: every verb
;;; re-selects with the tenant from the session, so another tenant's id yields
;;; 404, never data.
;;; ═══════════════════════════════════════════════════════════════════════════

(register-api-route 'route-vendor-list
                    :method :get
                    :path "/hhub/api/v1/vendor/profile"
                    :success-status 200
                    :auth-scope :session
                    :description "List the session tenant's vendors. Query params: status (active|inactive|suspended|pending|rejected), approval-status, name-like (alias: keyword), city, gst-number, sort-by, sort-dir, limit, offset. An empty list is 200 [].")

(register-api-route 'route-vendor-create
                    :method :post
                    :path "/hhub/api/v1/vendor/profile"
                    :success-status 201
                    :auth-scope :session
                    :description "Register a vendor for the session tenant. Body: JSON object of nst-vnd field names; name, address, phone and password are required (all NOT NULL with no column default). username defaults to the phone. 409 when the phone is held in this tenant by a SOFT-DELETED vendor.")

(register-api-route 'route-vendor-fetch
                    :method :get
                    :path "/hhub/api/v1/vendor/profile/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Fetch one vendor by numeric row-id. 404 when it does not exist or belongs to another tenant. Credential fields are never published.")

(register-api-route 'route-vendor-update
                    :method :put
                    :path "/hhub/api/v1/vendor/profile/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Partially update a vendor by numeric row-id; only the supplied fields change. password, salt, payment-api-key and payment-api-salt are REFUSED (credential rotation is its own verb). 404 when it does not exist in this tenant.")

(register-api-route 'route-vendor-delete
                    :method :delete
                    :path "/hhub/api/v1/vendor/profile/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Soft-delete a vendor by numeric row-id: the row is kept and its phone stays reserved IN THIS TENANT ONLY, so re-registering that number here is a 409 while another tenant may still use it.")

;;; A SUB-RESOURCE OF THE VENDOR PROFILE, and the segment count is what keeps it
;;; separate: api-match-route requires equal segment counts, so this 7-segment
;;; template cannot be swallowed by the 6-segment PUT /vendor/profile/{id} above.
;;; The design document (hhub/core/nstoresapi.html) specifies no invoice-settings
;;; endpoint, so like the payment-methods surface this binding is ADDITIVE and the
;;; path was chosen rather than inherited.
(register-api-route 'route-vendor-settings-update
                    :method :put
                    :path "/hhub/api/v1/vendor/profile/{id}/invoice-settings"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Replace one vendor's invoice settings by numeric row-id. THE BODY IS THE SETTINGS OBJECT — a JSON object with one key per settings section, no wrapper. Refused with the domain's own condition when the payload is not a list, when it carries the string \"undefined\" (the legacy void value for a NULL column), or when a section name is not one the shipped defaults carry; a JSON body's section keys are canonicalised so the readers find them. 404 when the vendor is not in this tenant. Returns the updated vendor profile, whose invoiceSettings field is the stored blob.")
