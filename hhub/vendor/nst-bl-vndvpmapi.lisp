;;; nst-bl-vndvpmapi.lisp — Vendor payment settings API: action verbs, action routes, API bindings
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; 🚨 NOT YET COMPILED OR LOADED. See §0 of vendor/nst-bl-vndapi-CONTEXT.md.
;;;
;;; WHAT THIS FILE IS. The Ring-3/Ring-4 surface for the vendor PAYMENT SETTINGS
;;; entity (nst-vnd-vpm, vendor/nst-dal-vndvpm.lisp) built on the Tier-1 प्रत्यय in
;;; vendor/nst-bl-vndvpm.lisp. It is a copy of the shape of vendor/nst-bl-vndapi.lisp
;;; — the sibling surface — with the differences stated where they bite.
;;;
;;; THE INVARIANT: this file adds TRANSPORT, never business routes. Every endpoint
;;; below is a thin binding onto an already-registered verb, so an API call and an
;;; internal page share one कारक build, one ferry, one set of domain laws. That
;;; matters here for the same reason it does for the profile: the singleton law and
;;; the referential law both live in the प्रत्यय, and duplicating either here would
;;; create the two-implementations problem the products work spent a session removing.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THREE ENDPOINTS, NOT FOUR — THE EXISTS CHECK IS THE GET
;;;
;;;   POST   /hhub/api/v1/vendor/payment/methods            create
;;;   GET    /hhub/api/v1/vendor/payment/methods/{vendorId} read
;;;   PUT    /hhub/api/v1/vendor/payment/methods/{vendorId} update
;;;
;;; There is deliberately NO /exists endpoint. Existence is a 200-vs-404 fact, and the
;;; GET already reports it: 200 means the settings are there, 404 means this vendor has
;;; none yet. A separate route would answer a question the GET has just answered, and
;;; two routes to one fact is how they drift apart.
;;;
;;; This is not the same as dropping the प्रत्यय: `?exists` is still called on every
;;; create, as `make`'s :around pre-flight (adhara's make contract REQUIRES it), and it
;;; is what turns a duplicate create into a 409 instead of a second settings row. It is
;;; simply not reachable as its own endpoint, because it is a STEP inside create rather
;;; than a resource of its own.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; {vendorId} IS THE PARENT VENDOR, NOT A ROW-ID — AND WHY THAT IS FORCED
;;;
;;; Every other entity in this tree addresses a row by row-id. This one cannot:
;;; DOD_VPAYMENT_METHODS holds ONE row per vendor for the vendor's whole lifetime,
;;; and there is no `enumerate` on this entity, so a client has NO WAY TO LEARN a
;;; row-id before asking for it. Addressing by the parent is therefore the only usable
;;; address — and it is also the honest one, because (VENDOR_ID, TENANT_ID) IS this
;;; entity's identity (see nst-bl-vndvpm.lisp).
;;;
;;; 🚨 THE PATH PARAM IS :vpm-vendor-id, NOT :vendor-id, AND THAT IS LOAD-BEARING.
;;;
;;; :vendor-id IS a declared initarg of nst-vnd-vpm, so if the path param used that
;;; name the ferry (extract-domain-initargs) would pass it into the update args — where
;;; !update REFUSES it, because it is the parent link and re-pointing a settings row at
;;; another vendor is a BOLA primitive, not a config edit. Every PUT would fail.
;;;
;;; :vpm-vendor-id is NOT a declared initarg, so the MOP-driven ferry drops it
;;; automatically and the route reads it explicitly with vpm-address-arg. One name for
;;; the address, one name for the field, and the ferry's filter keeps them apart
;;; without a hand-written remf that would silently discard a client's mistake.
;;;
;;; On the CREATE body the field IS :vendor-id, because there it is genuinely an
;;; initarg. The two legs differ because they are doing different things: creating a row
;;; FOR a vendor, versus addressing an existing row BY its vendor.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; NO ROUTE HERE CARRIES :inject-company
;;;
;;; Deliberate, and the same difference from the warehouse that the profile and products
;;; surfaces have. nst-vnd-vpm's `make` and `!update` set the कारक company from the
;;; domain-ctx UNCONDITIONALLY, so the session tenant cannot be overridden by a body or
;;; query string. The warehouse has to inject the company through params because its
;;; verbs take it from the entity — a rule that depends on leftmost-initarg precedence.
;;; Both end up tenant-safe; this one does not depend on initarg ordering at all.
;;;
;;; 🚨 THE PATH DOES NOT RESTRICT ANYTHING. required-roles / feature-flags /
;;; audit-level are CARRIED but NOT ENFORCED by conflodis2 v1 — see the same note in
;;; products/nst-bl-prdapi.lisp. Registering :required-roles '(vendor) below records
;;; INTENT so the metadata is in one place when the PEP/ABAC seam lands. Do not read it
;;; as protection: every endpoint here answers to any authenticated session today.
;;;
;;; THAT MATTERS MORE HERE THAN IT LOOKS, because {vendorId} is CLIENT-SUPPLIED. The
;;; tenant is enforced by construction — every verb re-selects WITH THE SESSION TENANT,
;;; so another tenant's vendor-id is a 404, never data. But INSIDE one tenant nothing
;;; stops vendor X from reading or editing vendor Y's payment settings by passing Y's
;;; vendor-id. That is intra-tenant BOLA, tenant scoping does not cover it, and it is
;;; closed by putting the vendor on domain-ctx's `actor` slot (CONTEXT §12.3 decision 3)
;;; — which is NOT done. Recorded here so it is not mistaken for done.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; STATUS MAPPING (apidefs2 §5): 201 for create, 200 otherwise, 404 for a vendor with
;;; no settings row, 409 when a create collides with an existing row (:T) or with a
;;; soft-deleted one (:C), 401 without a session.
;;;
;;; THE RESPONSE MODEL IS RENDERED — the two methods live beside the प्रत्यय, NOT here,
;;; exactly as render-json for VendorResponseModel lives in vendor/nst-bl-vnd.lisp:
;;;   domain->response ((entity nst-vnd-vpm) (ctx domain-ctx))  nst-bl-vndvpm.lisp:690
;;;   render-json      ((r VpmResponseModel) (ctx domain-ctx))  nst-bl-vndvpm.lisp:731
;;; Seven keys cross the wire and no more: rowId, codEnabled, upiEnabled,
;;; payProvidersEnabled, walletEnabled, payLaterEnabled, active. They belong in the
;;; domain file rather than this one because the field list, the flag meaning and the
;;; id convention are DOMAIN decisions; putting them here would make the API layer hold
;;; business rules (CONTEXT §11.1).
;;; ═══════════════════════════════════════════════════════════════════════════

(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Inbound parameter helper
;;;
;;; The ferry (request->dispatch / extract-domain-initargs) handles everything that is
;;; an ENTITY INITARG. It cannot handle the ADDRESS on the fetch and update legs, and
;;; deliberately so — see the header on why the path param is :vpm-vendor-id.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun vpm-address-arg (payload)
  "The {vendorId} path param, as the STRING every nst-vnd-vpm verb here expects.

   The verbs take a string and parse it themselves (vpm-vendor-id-from-string), so a
   value that cannot address a vendor answers :F / not-found rather than raising. An
   absent param therefore becomes the EMPTY STRING, which parses to NIL and produces a
   404 — the honest answer for 'no address given' — instead of a NIL that would signal
   no-applicable-method, since the verbs specialize their address on (string).

   vnd-param is REUSED from vendor/nst-bl-vndapi.lisp rather than copied: it is the one
   place that knows a payload may be keyword-keyed (conflodis2/api callers) or
   string-keyed (a JSON body or query string parsed by another inbound adapter)."
  (let ((value (vnd-param payload :vpm-vendor-id)))
    (cond ((stringp value) value)
          ((null value) "")
          (t (princ-to-string value)))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action verbs (Tier 2)
;;;
;;; Signature is uniform and fixed: (route-<action> request ctx). Plain defuns, not
;;; generics — the dispatcher resolves them with fdefinition, exactly like
;;; route-vendor-* and route-product-*.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun route-vpm-create (request ctx)
  "कर्म = nst-vnd-vpm. Goes through the FERRY, because on this leg every inbound field
   IS an entity initarg: :vendor-id and the five flags + active-flag all pass the MOP
   filter, and :tenant-id is stripped by adhara's *reserved-initargs* before it can
   pretend to be another tenant.

   TWO DOMAIN LAWS RIDE IN THE VERB, not here, because they are domain law and not
   transport law — both in make's :around (nst-bl-vndvpm.lisp):
     1. the PARENT MUST EXIST in this tenant. DOD_VPAYMENT_METHODS declares no FOREIGN
        KEY, so MySQL accepts an orphan vendor-id; the missing constraint is applied in
        the domain. A vendor that does not resolve answers 404, not 409.
     2. the SLOT MUST BE FREE. This is the singleton law — no index enforces it, so
        ?exists is the only thing standing between a vendor and several contradictory
        settings rows. A live row answers 409; a soft-deleted one also answers 409,
        because there is no delete! on this entity and such a row can only come from the
        legacy UI or raw SQL."
  (request->dispatch request 'make 'nst-vnd-vpm ctx))

(defun route-vpm-fetch (request ctx)
  "कर्म = nst-vnd-vpm. Reads :vpm-vendor-id from params and calls the verb DIRECTLY
   rather than through request->dispatch, for a specific reason: the ferry's fetch
   method hard-codes (rm-row-id rm) — (getf params :row-id) — and this entity's address
   is the PARENT VENDOR, not a row-id. Routing through it would mean naming the
   vendor-id :row-id, which makes the transport lie about what the value is; the two
   would then disagree the first time anyone read the code. route-vendor-list sets the
   same precedent for arguments the ferry does not model.

   Returns an nst-vnd-vpm or a Belnap sentinel — never a bare CL nil. The dispatcher's
   reverse ferry turns nst-entity-nil into nst-response-nil, so 'this vendor has no
   payment settings' is a 404 with no payment-specific code.

   🚨 THIS IS ALSO THE EXISTS CHECK. 200 means the advice exists, 404 means the slot is
   free and a POST may create it — there is no fourth endpoint for that question. See
   the header."
  (fetch 'nst-vnd-vpm (vpm-address-arg (params request)) ctx))

(defun route-vpm-update (request ctx)
  "कर्म = nst-vnd-vpm. Reads :vpm-vendor-id from params and calls the verb directly, for
   the same reason fetch does: the ferry's !update reads its address from :row-id.

   THE FIELD ARGS STILL GO THROUGH THE FERRY. extract-domain-initargs filters the body
   against nst-vnd-vpm's declared initargs, so only real fields survive — and
   :vpm-vendor-id is NOT one of them, which is what keeps the address out of the update
   args without a remf that would silently discard it.

   🚨 THE REFUSALS RIDE IN THE VERB, not here: !update REFUSES :vendor-id outright (it
   is the parent link — re-pointing a settings row at another vendor is a BOLA
   primitive) and REFUSES any flag sent as an explicit nil (a NULL flag is read back as
   \"Y\" through the legacy view-class and would silently ENABLE a payment method; send
   \"N\" to disable one). Both are domain law about what the column can honestly store,
   so they belong beside the copier, not in a route."
  (apply #'!update 'nst-vnd-vpm (vpm-address-arg (params request)) ctx
         (extract-domain-initargs request 'nst-vnd-vpm)))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Action route registration (Ring 3)
;;;
;;; One line per inbound action. The route key IS the action symbol the dispatcher is
;;; called with: (dispatch-route2 'route-vpm-create …). request-class is the SLOTLESS
;;; VpmRequestModel — the whole payload rides in its inherited params slot.
;;;
;;; required-roles / feature-flags / audit-level are CARRIED but NOT ENFORCED by
;;; conflodis2 v1. Do not read them as protection — see the header.
;;; ═══════════════════════════════════════════════════════════════════════════

(register-action-route 'route-vpm-create
                       :action-verb 'route-vpm-create
                       :request-class 'VpmRequestModel
                       :description "Create the session tenant's payment settings for one vendor. One row per vendor for its lifetime; the vendor must already exist in this tenant."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor payment vpm api v1))

(register-action-route 'route-vpm-fetch
                       :action-verb 'route-vpm-fetch
                       :request-class 'VpmRequestModel
                       :description "Read a vendor's payment settings. 404 when the vendor has none — which is the existence answer; there is no separate exists route."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :read
                       :tags '(vendors vendor payment vpm api v1))

(register-action-route 'route-vpm-update
                       :action-verb 'route-vpm-update
                       :request-class 'VpmRequestModel
                       :description "Partially update a vendor's payment settings — only the supplied flags change. vendor-id is refused as a field; a flag sent as null is refused."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor payment vpm api v1))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Public API bindings (Ring 4)
;;;
;;; One binding per (METHOD, PATH) → an ALREADY-REGISTERED action route. The
;;; registrations above must come first: register-api-route REFUSES to bind a path to a
;;; verb that does not exist (api-route-bindable-p), and the whole file is re-evaluated
;;; on every reload, so this order is load-bearing.
;;;
;;; THE PATH PREFIX IS PART OF THE TEMPLATE. register-api-route rejects a template
;;; without "/hhub/" because the deployed nginx proxies that prefix and rewrites
;;; everything else — a template without it would be unreachable.
;;;
;;; THE PATH SITS IN core/nstoresapi.html's OWN `vendor/*` FAMILY, alongside
;;; /hhub/api/v1/vendor/profile: the design document specifies
;;; /api/v1/vendor/payment/{gateway,upi,upi-transactions} and the shipping set, but no
;;; endpoint for the payment-METHOD flags themselves. So this surface is ADDITIVE, and
;;; the path was chosen rather than inherited. The two credentials endpoints the
;;; document does specify are !update on the VENDOR row (nst-vnd), not on this entity —
;;; PAYMENT_API_KEY, PAYMENT_API_SALT, PAYMENT_GATEWAY_MODE and UPI_ID are
;;; DOD_VEND_PROFILE columns.
;;;
;;; {vendorId} IS A NUMERIC VENDOR ID (DOD_VEND_PROFILE.ROW_ID), passed through
;;; path-params as :vpm-vendor-id. It is an ADDRESS, never an authorization: every verb
;;; re-selects with the tenant from the session, so another tenant's id yields 404,
;;; never data.
;;; ═══════════════════════════════════════════════════════════════════════════

(register-api-route 'route-vpm-create
                    :method :post
                    :path "/hhub/api/v1/vendor/payment/methods"
                    :success-status 201
                    :auth-scope :session
                    :description "Create payment settings for one vendor in the session tenant. Body: JSON object of nst-vnd-vpm field names — vendorId is required (the parent; its column is nullable but the domain refuses a settings row that belongs to no vendor), plus any of codEnabled, upiEnabled, payProvidersEnabled, walletEnabled, payLaterEnabled and activeFlag. An omitted flag takes the live DDL default (true for all but payLaterEnabled, whose default is false); a flag sent as null is refused. 404 when the vendor does not exist in this tenant; 409 when it already has settings, or when a soft-deleted row holds the slot.")

(register-api-route 'route-vpm-fetch
                    :method :get
                    :path "/hhub/api/v1/vendor/payment/methods/{vendorId}"
                    :path-params '(("vendorId" . :vpm-vendor-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Read one vendor's payment settings. 200 means they exist; 404 means this vendor has none yet (or the row was deleted out of band) — this GET is also the existence check, so there is no /exists route. 404 also covers a vendor belonging to another tenant.")

(register-api-route 'route-vpm-update
                    :method :put
                    :path "/hhub/api/v1/vendor/payment/methods/{vendorId}"
                    :path-params '(("vendorId" . :vpm-vendor-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Partially update one vendor's payment settings; only the supplied flags change, so an omitted flag keeps its stored value. vendorId is REFUSED in the body (it is the parent link, not an editable field). A flag sent as null is REFUSED — send \"N\" to disable a method. 404 when the vendor has no settings row to update.")
