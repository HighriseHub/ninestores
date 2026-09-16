;;; nst-bl-vndshpapi.lisp — Vendor shipping API: action verbs, action routes, API bindings
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; 🚨 NOT YET COMPILED OR LOADED. See §0 of vendor/nst-bl-vndapi-CONTEXT.md.
;;;
;;; WHAT THIS FILE IS. The Ring-3/Ring-4 surface for the vendor SHIPPING entity
;;; (nst-vnd-shp, vendor/nst-dal-vndshp.lisp) built on the Tier-1 प्रत्यय in
;;; vendor/nst-bl-vndshp.lisp. It is a copy of the shape of
;;; vendor/nst-bl-vndvpmapi.lisp — the sibling surface — with the differences stated
;;; where they bite.
;;;
;;; THE INVARIANT: this file adds TRANSPORT, never business routes. Every endpoint
;;; below is a thin binding onto an already-registered verb, so an API call and an
;;; internal page share one कारक build, one ferry, one set of domain laws. That
;;; matters more here than anywhere else in the vendor tree, because the five laws
;;; that keep a zonewise cart from being charged NOTHING live in the verbs — see
;;; §L1–L5 of nst-bl-vndshp.lisp. A second copy of any of them here would be a second
;;; implementation of the rule that decides what a customer pays.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THE EXISTING UI DOES, AND HOW EACH PIECE MAPS ONTO THIS SURFACE
;;;
;;; The legacy pages are registered in core/dod-ui-sys.lisp and their controllers sit
;;; in vendor/dod-ui-ven.lisp. Every one of them is a thin controller over the SAME
;;; two tables this entity owns, so the mapping is a translation of ADDRESSING, not
;;; of meaning:
;;;
;;;   UI route (dod-ui-sys.lisp)                UI controller                                    → here
;;;   ───────────────────────────────────────── ──────────────────────────────────────────────── → ─────────────────────────────
;;;   /hhub/hhubvendorshipmethods               dod-controller-vend-shipping-methods              GET  shipping/{vendorId}
;;;                                             (READ: vendor + row + flat/free/ext fields)
;;;   /hhub/hhubvendupdatfreeshipmethodaction   …-update-free-shipping-method-action             PUT  shipping/{vendorId}
;;;                                             (freeshipenabled, minorderamt)                      (same two fields)
;;;   /hhub/hhubupdatflatrateshipmethodaction   …-update-flatrate-shipping-action                PUT  shipping/{vendorId}
;;;                                             (flatrateshipenabled, flatratetype, price)           (same three fields)
;;;   /hhub/hhubvendupdatedefaultshipmethod     …-update-default-shipping-method                 PUT  shipping/{vendorId}
;;;                                             (defaultshippingmethod, storepickupenabled, AND      + PUT vendor profile
;;;                                              vendor.shipping-enabled — a CROSS-ENTITY write)     (see the note below)
;;;   /hhub/hhubvendupdateshippartneraction     …-update-external-shipping-partner-action        PUT  shipping/{vendorId}
;;;                                             (shippartnerkey, shippartnersecret, extship)         (same three fields)
;;;   /hhub/hhubvendshipzoneratetablepage       …-vendor-shipzone-ratetable-page                 GET  shipping/{vendorId}
;;;                                             (READ: rate table + zone tiles)                      (zones ride inside the entity)
;;;   /hhub/hhubvenduploadshipratetableaction   …-upload-shipping-ratetable-action               PUT  shipping/{vendorId}/rate-table
;;;                                             (RATETABLECSV + tablerateshipenable + zone rows)     (the same three, atomically)
;;;   — no UI counterpart —                     (the legacy form cannot upload the zone file      PUT  shipping/{vendorId}/zones
;;;                                              without the rate table)                            (zones alone — see the note below)
;;;   /hhub/hhubvendaddprodshipinfoaction       com-hhub-transaction-vend-prd-shipinfo-add-action  NOT HERE
;;;                                             (shipping dims on DOD_PRD_MASTER)
;;;
;;; 🚨 THE ZONES-ONLY ADDRESS IS THE ONE PLACE THIS SURFACE IS ADDITIVE RATHER THAN
;;; EQUIVALENT TO THE UI, and it is additive because the UI cannot express it. The legacy
;;; upload form carries two file inputs and its controller writes both halves in one
;;; request (dod-ui-ven.lisp:2035-2064), so a vendor whose only change is a pincode range
;;; must re-submit a rate table it did not touch — and the browser hands back whatever
;;; copy of the matrix it was shown. Splitting the address removes that failure mode for
;;; API clients; the UI keeps working unchanged through /rate-table.
;;;
;;; 🚨 THE LAST ONE IS NOT THIS ENTITY, and the row is in the table so its absence is
;;; a decision rather than an oversight. That controller writes shipping-length-cms,
;;; shipping-width-cms, shipping-height-cms and shipping-weight-kg onto a PRODUCT
;;; (update-prd-details, dod-ui-ven.lisp:1375). Those are nst-prd fields; they are
;;; what the rate table is indexed BY, not part of the shipping configuration, and
;;; binding them here would give one route two कर्म.
;;;
;;; 🚨 TWO UI ROUTES COLLAPSE INTO ONE PUT. Free shipping, flat rate, the default
;;; method, store pickup, the external partner and zonewise are all FIELDS OF ONE ROW
;;; (DOD_SHIPPING_METHODS is a singleton per vendor). The legacy UI gives each its own
;;; form and its own controller; the API gives them one verb, because `!update` is
;;; partial by construction — only the supplied initargs change. Splitting them into
;;; five endpoints would multiply the addresses without adding a fact.
;;;
;;; 🚨 THE ONE CROSS-ENTITY WRITE THE UI DOES, AND WHAT HAPPENS TO IT HERE.
;;; dod-controller-vendor-update-default-shipping-method writes TWO entities: the
;;; shipping row AND DOD_VEND_PROFILE.SHIPPING_ENABLED on the vendor
;;; (dod-ui-ven.lisp:2082). That second column is nst-vnd's field, and the checkout
;;; requires it before it will consider ANY paid shipping (`(equal vshipping-enabled
;;; "Y")` gates steps 2 and 3 of calculate-shipping-cost-for-order). This file does
;;; NOT write another entity's row: the caller makes two calls —
;;;     PUT /hhub/api/v1/vendor/shipping/{vendorId}   { "defaultShippingMethod": "TRS", … }
;;;     PUT /hhub/api/v1/vendor/profile/{rowId}       { "shippingEnabled": true }
;;; — and pairing them is the ROUTE layer's job, not a route's. A compound verb that
;;; writes both would need its own authorization story (it can enable shipping for a
;;; vendor) and is deliberately not invented here. Recorded so the gap is not mistaken
;;; for a decision, exactly as nst-bl-vndvpmapi.lisp records its own.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; SIX ENDPOINTS, AND WHY THE LIST EXISTS HERE AND NOT FOR PAYMENT
;;;
;;;   POST /hhub/api/v1/vendor/shipping                        create
;;;   GET  /hhub/api/v1/vendor/shipping                        list (tenant-wide)
;;;   GET  /hhub/api/v1/vendor/shipping/{vendorId}             read   ← also the exists check
;;;   PUT  /hhub/api/v1/vendor/shipping/{vendorId}             update
;;;   PUT  /hhub/api/v1/vendor/shipping/{vendorId}/rate-table  the zonewise table (+ zones)
;;;   PUT  /hhub/api/v1/vendor/shipping/{vendorId}/zones       the zone collection alone
;;;
;;; THERE IS STILL NO /exists ENDPOINT, for the reason the payment twin gives: the GET
;;; already reports it — 200 means the configuration is there, 404 means this vendor has
;;; none yet. `?exists` is not dropped, it is called on every create as make's :around
;;; pre-flight (adhara's make contract REQUIRES it) and is what turns a duplicate create
;;; into a 409 instead of a second configuration row.
;;;
;;; THE LIST EXISTS because nst-vnd-shp HAS an enumerate verb and the payment entity
;;; does not. The reason is structural, not stylistic: a shipping configuration carries
;;; a COLLECTION (the zones), so the tenant-wide question — "which vendors ship zonewise,
;;; and who has zonewise on with no rate table?" — has an answer worth publishing. See
;;; §11 of nst-bl-vndshp.lisp for what the list is and is not.
;;;
;;; THE TWO ZONEWISE SUB-RESOURCES ARE ONE VERB WITH TWO CONTRACTS, and BOTH addresses
;;; exist because the two files are edited for different reasons:
;;;
;;;   /rate-table  the legacy upload form's payload — BOTH files at once. That is the
;;;                form the vendor actually submits (dod-ui-ven.lisp:1991-1997 hands
;;;                over the rate-table CSV and the zone CSV together), and it is where a
;;;                vendor that changed PRICES posts.
;;;   /zones       the ZONE,PINCODES file ALONE, leaving the stored matrix untouched.
;;;                This is the COMMON edit — a pincode range is added to an existing
;;;                zone and no price changes — and without its own address the client
;;;                would have to re-send a matrix it never touched, which is how a stale
;;;                copy of the table gets written back over a good one.
;;;
;;; A zones-only write cannot reach the state that charges 0.00: the L2 law runs on the
;;; MERGED configuration inside `!update`, so a zone set whose names no longer match the
;;; stored matrix is REFUSED with the difference named. (While zonewise shipping is
;;; DISABLED the zonewise laws are skipped by design — the matrix is not consulted — and
;;; they fire the moment the vendor turns it on.)
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; {vendorId} IS THE PARENT VENDOR, NOT A ROW-ID — AND WHY THAT IS FORCED
;;;
;;; Same reasoning as the payment twin, with the same consequence: this entity holds ONE
;;; row per vendor for the vendor's whole lifetime, and although there IS an enumerate,
;;; it lists CONFIGURATIONS, not rows a client would address one by one. Addressing by
;;; the parent is the only usable address — and the honest one, because
;;; (VENDOR_ID, TENANT_ID) IS this entity's identity (nst-bl-vndshp.lisp, ?exists).
;;;
;;; 🚨 THE PATH PARAM IS :shp-vendor-id, NOT :vendor-id, AND THAT IS LOAD-BEARING.
;;;
;;; :vendor-id IS a declared initarg of nst-vnd-shp, so if the path param used that name
;;; the ferry (extract-domain-initargs) would pass it into the update args — where
;;; !update REFUSES it, because it is the parent link and re-pointing a shipping
;;; configuration at another vendor is a BOLA primitive, not a config edit
;;; (*vndshp-update-forbidden-fields*). Every PUT would fail.
;;;
;;; :shp-vendor-id is NOT a declared initarg, so the MOP-driven ferry drops it
;;; automatically and the route reads it explicitly with vndshp-address-arg. One name for
;;; the address, one name for the field, and the ferry's filter keeps them apart without
;;; a hand-written remf that would silently discard a client's mistake.
;;;
;;; On the CREATE body the field IS :vendor-id, because there it is genuinely an initarg.
;;; The two legs differ because they are doing different things: creating a row FOR a
;;; vendor, versus addressing an existing row BY its vendor.
;;;
;;; 🚨 THE ZONES TRAVEL AS INITARGS, so they DO go through the ferry on the shared PUT.
;;; `:zones` is a declared initarg of nst-vnd-shp, so extract-domain-initargs keeps it,
;;; and vndshp-parse-zones-initarg accepts the whole zone CSV as a string or a list of
;;; (:zonename … :pincodes …) entries. The rate-table route below is explicit about the
;;; three keys it forwards instead of relying on that filter, because it is the one place
;;; a partial payload does silent damage.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; NO ROUTE HERE CARRIES :inject-company
;;;
;;; Deliberate, and the same difference from the warehouse that the profile, products and
;;; payment surfaces have. nst-vnd-shp's `make` and `!update` set the कारक company from
;;; the domain-ctx UNCONDITIONALLY, so the session tenant cannot be overridden by a body
;;; or query string. The warehouse has to inject the company through params because its
;;; verbs take it from the entity — a rule that depends on leftmost-initarg precedence.
;;; Both end up tenant-safe; this one does not depend on initarg ordering at all.
;;;
;;; 🚨 THE PATH DOES NOT RESTRICT ANYTHING. required-roles / feature-flags / audit-level
;;; are CARRIED but NOT ENFORCED by conflodis2 v1 — see the same note in
;;; products/nst-bl-prdapi.lisp. Registering :required-roles '(vendor) below records
;;; INTENT so the metadata is in one place when the PEP/ABAC seam lands. Do not read it
;;; as protection: every endpoint here answers to any authenticated session today.
;;;
;;; THAT MATTERS HERE AS MUCH AS FOR PAYMENT, because {vendorId} is CLIENT-SUPPLIED. The
;;; tenant is enforced by construction — every verb re-selects WITH THE SESSION TENANT,
;;; so another tenant's vendor-id is a 404, never data. But INSIDE one tenant nothing
;;; stops vendor X from reading or editing vendor Y's shipping configuration by passing
;;; Y's vendor-id, and for THIS entity the exposure is worse than a settings disclosure:
;;; the shippartnerkey and shippartnersecret on the row are BOOKING credentials, and a
;;; writer who can set defaultshippingmethod can choose which method prices the cart.
;;; That is intra-tenant BOLA; tenant scoping does not cover it, and it is closed by
;;; putting the vendor on domain-ctx's `actor` slot (CONTEXT §12.3 decision 3) — which is
;;; NOT done. Recorded here so it is not mistaken for done.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; STATUS MAPPING (apidefs2 §5): 201 for create, 200 otherwise, 404 for a vendor with no
;;; configuration, 409 when a create collides with an existing row (:T) or with a
;;; soft-deleted one (:C) — and 409 from a zone write that did not complete, which is the
;;; one outcome that is neither success nor failure (nst-bl-vndshp.lisp, make/!update).
;;; 401 without a session. The five laws signal the vndshp-field-rejected condition, which
;;; under the current taxonomy reaches the client as a 500 where 400 is right — the shared
;;; 4xx gap (CONTEXT §7.2), not a defect introduced here.
;;;
;;; THE RESPONSE MODEL IS RENDERED — the two methods live beside the प्रत्यय, NOT here:
;;;   domain->response ((entity nst-vnd-shp) (ctx domain-ctx))   nst-bl-vndshp.lisp §12
;;;   render-json      ((r VndShipResponseModel) (ctx domain-ctx)) nst-bl-vndshp.lisp §12
;;; Fourteen keys cross the wire and no more, and the two that do NOT — shippartnerkey
;;; and shippartnersecret — have no slot on the response class to be copied into. They
;;; belong in the domain file rather than this one because the field list, the flag
;;; meaning and the id convention are DOMAIN decisions; putting them here would make the
;;; API layer hold business rules (CONTEXT §11.1).
;;; ═══════════════════════════════════════════════════════════════════════════

(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Inbound parameter helpers
;;;
;;; The ferry (request->dispatch / extract-domain-initargs) handles everything that is
;;; an ENTITY INITARG. It cannot handle the ADDRESS on the fetch and update legs, and
;;; the rate-table leg's file payload needs a lookup that tolerates the several spellings
;;; a JSON body, a query string and a form post each produce.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun vndshp-body-value (payload &rest keys)
  "The first of KEYS present in PAYLOAD, or NIL.

   WHY NOT vnd-param. vnd-param answers for ONE key, in the two spellings the ferry
   produces: the keyword :ratetablecsv and the downcased string \"ratetablecsv\". This
   surface has to answer for more than that, because the key a client sends is not the
   key the domain uses:

     the domain initarg   :ratetablecsv        (DOD_SHIPPING_METHODS.RATETABLECSV)
     a JSON client sends   \"rateTableCsv\"      (the name render-json publishes)
     the legacy form post  \"ratetablecsv\"      (the hunchentoot:parameter name)

   All three must land on the same initarg, and the honest place to reconcile them is
   here rather than in the vendor's client. Keys are tried IN ORDER, so the list a caller
   passes IS the precedence."
  (loop for key in keys
        for value = (vnd-param payload key)
        when value return value))

(defun vndshp-address-arg (payload)
  "The {vendorId} path param, as the STRING every nst-vnd-shp verb here expects.

   The verbs take a string and parse it themselves (vndshp-vendor-id-from-string), so a
   value that cannot address a vendor answers :F / not-found rather than raising. An
   absent param therefore becomes the EMPTY STRING, which parses to NIL and produces a
   404 — the honest answer for 'no address given' — instead of a NIL that would signal
   no-applicable-method, since the verbs specialize their address on (string).

   vnd-param is REUSED from vendor/nst-bl-vndapi.lisp rather than copied: it is the one
   place that knows a payload may be keyword-keyed (conflodis2/api callers) or
   string-keyed (a JSON body or query string parsed by another inbound adapter)."
  (let ((value (vnd-param payload :shp-vendor-id)))
    (cond ((stringp value) value)
          ((null value) "")
          (t (princ-to-string value)))))

(defun vndshp-rate-table-args (payload)
  "The initargs the rate-table route forwards to !update, and ONLY those.

   THREE KEYS, an explicit list rather than the ferry, and the reason is the contract the
   address promises: this leg REPLACES the zone collection. A ferry would forward every
   initarg the body happens to carry, so a client posting a rate table plus a stale
   defaultShippingMethod and extshipenabled in the same payload would change all three —
   not what the address says and not what the client means. The keys not present are
   absent from the list, so `!update` leaves those fields exactly as they were.

   :zones IS PASSED THROUGH UNPARSED. vndshp-parse-zones-initarg accepts the whole zone
   CSV as a string (which is the file the legacy page uploads) or a list of
   (:zonename \"ZONE-A\" :pincodes \"56,57\") entries, and it is the verb that owns that
   translation — doing it here would put a domain rule in the transport."
  (let ((table (vndshp-body-value payload :ratetablecsv :rate-table-csv))
        (zones (vndshp-body-value payload :zones :zonepincodescsv :zone-pincodes-csv))
        (enabled (vndshp-body-value payload :tablerateshipenabled :zone-wise-enabled)))
    (append (when table   (list :ratetablecsv table))
            (when zones   (list :zones zones))
            (when enabled (list :tablerateshipenabled enabled)))))

(defun vndshp-zone-args (payload)
  "The initargs the ZONES-ONLY route forwards to !update: :zones, and nothing else.

   🚨 AN EMPTY PAYLOAD IS REFUSED, NOT READ AS 'REMOVE EVERY ZONE'. This is the one
   difference from vndshp-rate-table-args that must not be left implicit. There, an
   absent :zones simply means the caller did not send a zone file and the stored
   collection is left alone — correct, because the address is about the matrix. Here the
   address IS the collection, so a body with no zones in it has exactly one reading, and
   it is not the one a client means: `!update` would receive an explicit nil, the entity's
   `zones` slot would become the empty list, and — while zonewise shipping is DISABLED,
   when the zonewise laws are skipped by design — every zone row would be retired with a
   200 returned. That is a data-losing write reachable by an empty body.

   So the guard is here, at the transport, and it names the accepted shapes. Retiring a
   zone is done by sending a zone set that does not contain it; removing them ALL is not
   an operation this surface offers, because a zonewise configuration with no zones is
   the state L1 already refuses to create.

   THE SHAPES ARE NOT RE-STATED HERE. vndshp-parse-zones-initarg owns them (the whole
   ZONE,PINCODES CSV as text, or a list of (:zonename \"ZONE-A\" :pincodes \"56,57\")
   entries) and this function deliberately does not look inside the value."
  (let ((zones (vndshp-body-value payload :zones :zonepincodescsv :zone-pincodes-csv)))
    (unless zones
      (error 'vndshp-field-rejected
             :field :zones
             :why "the zone upload carried no zones. Send the ZONE,PINCODES file as text under \"zones\", or a list of (:zonename \"ZONE-A\" :pincodes \"56,57\") entries. This address REPLACES the vendor's zone collection, so an empty payload is refused rather than read as 'remove every zone' — which would retire every row and leave a zonewise configuration the checkout cannot price."))
    (list :zones zones)))

(defun vndshp-enumerate-args (payload)
  "Filter args for (enumerate 'nst-vnd-shp ctx …).
   NOT a ferry, deliberately: these are QUERY arguments of the enumerate verb, not
   initargs of nst-vnd-shp, so extract-domain-initargs would drop every one. (That
   :vendor-id IS also a declared initarg is a coincidence of this entity having a parent
   link, not a reason to ferry them.)

   :method AND :status ARE PASSED THROUGH the keywordiser, not raw: unlike nst-vnd's
   enumerate, whose status verb re-normalises its own argument, this entity's filter
   clauses CASE on the keyword and signal on anything else. A query string therefore has
   to be turned into :zonewise/:pickup/… here, and an unknown value still signals IN THE
   DOMAIN with a message naming the valid set — which is the behaviour that matters, and
   it is preserved because vnd-keyword-value passes a non-scalar through unchanged.

   THE QUERY STRING DOES REACH HERE — api-params-for-request merges the session company,
   path params, the JSON body and the query string (api-query-params, apidefs2); see
   vnd-enumerate-args, which this mirrors."
  (list :vendor-id      (vnd-param payload :vendor-id)
        :default-method (vnd-param payload :default-shipping-method)
        :method         (vnd-keyword-value (vnd-param payload :method))
        :status         (vnd-keyword-value (vnd-param payload :status))
        :sort-by        (or (vnd-keyword-value (vnd-param payload :sort-by)) :row-id)
        :sort-dir       (or (vnd-keyword-value (vnd-param payload :sort-dir)) :desc)
        :limit          (vnd-int-arg (vnd-param payload :limit) "limit")
        :offset         (vnd-int-arg (vnd-param payload :offset) "offset")))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action verbs (Tier 2)
;;;
;;; Signature is uniform and fixed: (route-<action> request ctx). Plain defuns, not
;;; generics — the dispatcher resolves them with fdefinition, exactly like
;;; route-vendor-*, route-vpm-* and route-product-*.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun route-vndshp-create (request ctx)
  "कर्म = nst-vnd-shp. Goes through the FERRY, because on this leg every inbound field
   IS an entity initarg: :vendor-id, the five method flags, the money fields, the partner
   credentials and :zones all pass the MOP filter, and :tenant-id is stripped by
   adhara's *reserved-initargs* before it can pretend to be another tenant.

   FOUR DOMAIN LAWS RIDE IN THE VERB, not here, because they are domain law and not
   transport law — all in make's :around and vndshp-validate-config (nst-bl-vndshp.lisp):
     1. THE PARENT MUST EXIST in this tenant. Neither table declares a FOREIGN KEY, so
        MySQL accepts an orphan vendor-id; the missing constraint is applied in the
        domain. A vendor that does not resolve answers 404, not 409.
     2. THE SLOT MUST BE FREE. This is the singleton law — no index enforces it, and the
        legacy checkout reads the FIRST row with NO ORDER BY, so a duplicate would not
        raise, it would silently change the price charged. A live row answers 409; a
        soft-deleted one also answers 409, because there is no delete! on this entity.
     3. THE CONFIGURATION MUST BE PRICEABLE — the L1–L5 laws, run on the merged entity
        before anything is written.
     4. A CALLER THAT SUPPLIES NEITHER HALF GETS THE PLATFORM MASTER FILES
        (vndshp-seed-defaults), which is the state the legacy page shows a new vendor.
        Seeding is all-or-nothing, so a seeded zone set can never be paired with a
        caller's matrix."
  (request->dispatch request 'make 'nst-vnd-shp ctx))

(defun route-vndshp-fetch (request ctx)
  "कर्म = nst-vnd-shp. Reads :shp-vendor-id from params and calls the verb DIRECTLY
   rather than through request->dispatch, for a specific reason: the ferry's fetch method
   hard-codes (rm-row-id rm) — (getf params :row-id) — and this entity's address is the
   PARENT VENDOR, not a row-id. Routing through it would mean naming the vendor-id
   :row-id, which makes the transport lie about what the value is; the two would then
   disagree the first time anyone read the code. route-vendor-list and route-vpm-fetch
   set the same precedent for arguments the ferry does not model.

   Returns an nst-vnd-shp or a Belnap sentinel — never a bare CL nil. The dispatcher's
   reverse ferry turns nst-entity-nil into nst-response-nil, so 'this vendor has no
   shipping configuration' is a 404 with no shipping-specific code.

   THE ZONES COME WITH IT — they are the entity's `zones` slot, hydrated by one extra
   query inside fetch. A vendor whose shipping is flat-rate or free has none, and that is
   a valid configuration rather than an incomplete one.

   🚨 THIS IS ALSO THE EXISTS CHECK. 200 means the configuration is there, 404 means the
   slot is free and a POST may create it — there is no fifth endpoint for that question.

   🚨 THE PARTNER CREDENTIALS ARE ON THE ROW AND DO NOT CROSS IT: shippartnerkey and
   shippartnersecret have no slot on VndShipResponseModel, so this read cannot publish
   them even by a later edit to render-json."
  (fetch 'nst-vnd-shp (vndshp-address-arg (params request)) ctx))

(defun route-vndshp-update (request ctx)
  "कर्म = nst-vnd-shp. Reads :shp-vendor-id from params and calls the verb directly, for
   the same reason fetch does: the ferry's !update reads its address from :row-id.

   THE FIELD ARGS STILL GO THROUGH THE FERRY. extract-domain-initargs filters the body
   against nst-vnd-shp's declared initargs, so only real fields survive — and
   :shp-vendor-id is NOT one of them, which is what keeps the address out of the update
   args without a remf that would silently discard it. :zones IS one of them, so a body
   that carries zones replaces the collection, exactly as the dedicated rate-table route
   does; the difference between the two addresses is what the CLIENT is promising, not
   what the verb does.

   🚨 THE REFUSALS RIDE IN THE VERB, not here: !update REFUSES :vendor-id outright (the
   parent link — re-pointing a configuration at another vendor is a BOLA primitive), and
   vndshp-validate-config REFUSES any set of fields that would leave a configuration the
   checkout cannot price (L1–L5). Both are domain law about what the row can honestly
   mean, so they belong beside the copier, not in a route.

   THE PARTNER CREDENTIALS ARE EDITABLE HERE, deliberately — unlike the profile's
   :password/:salt. They are vendor-configurable credentials, the vendor's own settings
   page writes them today, and refusing to rotate them through the API would leave a
   vendor unable to replace a leaked key. They are kept off the WIRE by the response
   model, which is a different boundary and the right one."
  (apply #'!update 'nst-vnd-shp (vndshp-address-arg (params request)) ctx
         (extract-domain-initargs request 'nst-vnd-shp)))

(defun route-vndshp-upload-ratetable (request ctx)
  "कर्म = nst-vnd-shp — the zonewise slice: RATETABLECSV, TABLERATESHIPENABLED and the
   DOD_VENDOR_SHIP_ZONES collection, written together.

   THE BODY CARRIES A FILE. The vendor's page hands the browser
   defaultshipratetable.csv and defaultshipzonepincodes.csv, the vendor edits them, and
   uploads both (dod-ui-ven.lisp:1991-1997). This route accepts that same payload:
     rateTableCsv         the MIN,MAX,ZONE-… matrix, as the file's text
     zones                the ZONE,PINCODES file's text, or (:zonename/:pincodes) entries
     zoneWiseEnabled      \"Y\"/\"N\", optional — omit it and the flag is left alone
   See vndshp-rate-table-args for why only these three cross, and vndshp-body-value for
   the spellings each key answers to.

   IT IS ONE !update, NOT A HAND-WRITTEN SEQUENCE, and that is the whole point of giving
   the upload its own address: the laws that make the pair safe (L1 matrix shape, L2
   matrix columns ↔ zone rows, L3 column caps, L4 prefix overlap) are checked on the
   MERGED configuration inside the verb. A route that wrote the table and then the zones
   itself would have to re-implement every one of them, or write a configuration the
   checkout prices at 0.00.

   🚨 THE ZONE COLLECTION IS REPLACED, NOT MERGED — names that disappear are retired
   (soft-deleted) and names that reappear are revived, because the file IS the whole zone
   set. A merge would make removal inexpressible.

   🚨 A ZONE WRITE THAT DID NOT COMPLETE ANSWERS 409, NOT 200 AND NOT 500. The verb stops
   before writing the configuration row and returns a contradiction naming what was and
   was not written; the dispatcher ferries it as nst-response-contradiction. The client's
   recovery is to re-send the same payload, and the message says so.

   ⚠ IT DOES NOT WRITE THE VENDOR'S shipping_enabled. The legacy page's sibling control
   does (dod-ui-ven.lisp:2082), and the checkout requires that column before it will
   price anything zonewise — see the header for the two-call sequence."
  (apply #'!update 'nst-vnd-shp (vndshp-address-arg (params request)) ctx
         (vndshp-rate-table-args (params request))))

(defun route-vndshp-upload-zones (request ctx)
  "कर्म = nst-vnd-shp — the ZONE,PINCODES file alone: DOD_VENDOR_SHIP_ZONES, without
   touching RATETABLECSV.

   WHY THIS IS NOT JUST A CONVENIENCE. The vendor's common edit is a PINCODE change — a
   range is added to an existing zone and no price moves. The legacy form cannot express
   it: both file inputs belong to one submit (dod-ui-ven.lisp:1991-1997), so the browser
   re-posts whatever copy of the matrix it is holding, and a stale copy silently becomes
   the stored price list. An API client that only has zones never has to hold a matrix at
   all.

   IT IS THE SAME !update, so every law still applies to the MERGED configuration:
     * L2 refuses the write if the new zone names no longer match the stored matrix's
       columns, in EITHER direction — so this address cannot produce a zone that resolves
       to no column, which is the silent 0.00 charge;
     * L4 refuses two zones claiming the same pincode prefix;
     * L1/L3 apply to the stored table as it will be after the merge, so a zone set that
       pushes a prefix list past varchar(1024) is refused here too.
   The zonewise laws are skipped while tablerateshipenabled is \"N\", by design — the
   matrix is not consulted then — and they fire the moment it is turned on.

   🚨 AN EMPTY PAYLOAD IS REFUSED BY vndshp-zone-args, not read as 'remove every zone'.
   See that function: a body with no zones would otherwise retire every row and answer
   200, which is a data-losing write reachable by sending nothing.

   🚨 THE COLLECTION IS REPLACED, NOT MERGED — the zone list in the payload IS the
   vendor's zone set. A zone that disappears is retired (soft-deleted, so the checkout
   stops matching it while the row is kept), and a name that reappears is revived rather
   than duplicated.

   🚨 A ZONE WRITE THAT DID NOT COMPLETE ANSWERS 409, NOT 200 AND NOT 500 — the verb
   stops before writing the configuration row and names what was and was not written."
  (apply #'!update 'nst-vnd-shp (vndshp-address-arg (params request)) ctx
         (vndshp-zone-args (params request))))

(defun route-vndshp-list (request ctx)
  "कर्म = the filtered nst-vnd-shp collection. Calls the enumerate verb DIRECTLY (not via
   request->dispatch) because its arguments are query filters rather than entity
   initargs — see vndshp-enumerate-args.

   Returns a LIST of nst-vnd-shp, or the EMPTY LIST when nothing matches; apidefs2 renders
   that as 200 [] and reserves 404 for a sentinel. Each element carries its zones, filled
   from ONE extra query for the whole page rather than one per row.

   A vendor that has never configured shipping simply does not appear. Finding the vendors
   with NO configuration is a question about DOD_VEND_PROFILE and belongs to that entity's
   surface, not this one."
  (apply #'enumerate 'nst-vnd-shp ctx (vndshp-enumerate-args (params request))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Action route registration (Ring 3)
;;;
;;; One line per inbound action. The route key IS the action symbol the dispatcher is
;;; called with: (dispatch-route2 'route-vndshp-create …). request-class is the SLOTLESS
;;; VndShipRequestModel — the whole payload rides in its inherited params slot.
;;;
;;; required-roles / feature-flags / audit-level are CARRIED but NOT ENFORCED by
;;; conflodis2 v1. Do not read them as protection — see the header.
;;;
;;; THE ROUTES THE ORIGINAL SKETCH NAMES THAT ARE NOT HERE, so their absence is a
;;; decision and not an oversight:
;;;
;;;   vendor/shipping/quote        a RATE QUOTATION for a pincode + weight. Real, wanted,
;;;                                and NOT a verb of this entity: it reads the row and the
;;;                                zones and prices a cart, which is
;;;                                get-shipping-rate-from-table + get-zonename-from-pincode
;;;                                (shipping/dod-bl-osh.lisp:65-142) — a COMPOUND read with
;;;                                no side effects. It should reuse those two functions
;;;                                rather than re-implement the regex matching, and it
;;;                                needs the L4 overlap question answered first (the live
;;;                                master file still gives prefix 30 to two zones).
;;;   per-product shipping dims    com-hhub-transaction-vend-prd-shipinfo-add-action writes
;;;                                nst-prd fields. Not this entity — see the mapping table.
;;;   tracking / labels            OrderShipment and the external partner's API belong to
;;;                                the order and logistics surfaces, not to configuration.
;;; ═══════════════════════════════════════════════════════════════════════════

(register-action-route 'route-vndshp-create
                       :action-verb 'route-vndshp-create
                       :request-class 'VndShipRequestModel
                       :description "Create the session tenant's shipping configuration for one vendor. One row per vendor for its lifetime; the vendor must already exist in this tenant. A caller that supplies neither a rate table nor zones gets the platform master files."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor shipping vndshp api v1))

(register-action-route 'route-vndshp-fetch
                       :action-verb 'route-vndshp-fetch
                       :request-class 'VndShipRequestModel
                       :description "Read a vendor's shipping configuration, zones included. 404 when the vendor has none — which is the existence answer; there is no separate exists route. The partner credentials are not published."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :read
                       :tags '(vendors vendor shipping vndshp api v1))

(register-action-route 'route-vndshp-update
                       :action-verb 'route-vndshp-update
                       :request-class 'VndShipRequestModel
                       :description "Partially update a vendor's shipping configuration — only the supplied fields change. Covers free shipping, flat rate, the default method, store pickup, the external partner and the zonewise flags, because they are all columns of one row. vendor-id is refused as a field; a configuration the checkout could not price is refused with the reason."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor shipping vndshp api v1))

(register-action-route 'route-vndshp-upload-ratetable
                       :action-verb 'route-vndshp-upload-ratetable
                       :request-class 'VndShipRequestModel
                       :description "Replace a vendor's zonewise shipping: the rate table CSV, the enable flag and the zone collection, checked against each other and written together. The zones are replaced, not merged. 409 when a zone write did not complete, naming what was and was not written."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor shipping zonewise vndshp api v1))

(register-action-route 'route-vndshp-upload-zones
                       :action-verb 'route-vndshp-upload-zones
                       :request-class 'VndShipRequestModel
                       :description "Replace a vendor's zone collection from an uploaded ZONE,PINCODES file, leaving the stored rate table untouched. Checked against the stored matrix both ways, so a zone set the matrix cannot price is refused rather than stored. An empty payload is refused. 409 when a zone write did not complete, naming what was and was not written."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :full
                       :tags '(vendors vendor shipping zonewise vndshp api v1))

(register-action-route 'route-vndshp-list
                       :action-verb 'route-vndshp-list
                       :request-class 'VndShipRequestModel
                       :description "List the session tenant's shipping configurations, filtered by vendor, default method, enabled method or status, with pagination. Each row carries its zones."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-vendor-domain)
                       :audit-level :read
                       :tags '(vendors vendor shipping vndshp api v1))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Public API bindings (Ring 4)
;;;
;;; One binding per (METHOD, PATH) → an ALREADY-REGISTERED action route. The
;;; registrations above must come first: register-api-route REFUSES to bind a path to a
;;; verb that does not exist (api-route-bindable-p), and the whole file is re-evaluated on
;;; every reload, so this order is load-bearing.
;;;
;;; THE PATH PREFIX IS PART OF THE TEMPLATE. register-api-route rejects a template without
;;; "/hhub/" because the deployed nginx proxies that prefix and rewrites everything else —
;;; a template without it would be unreachable.
;;;
;;; THE PATH SITS IN core/nstoresapi.html's OWN `vendor/*` FAMILY, alongside
;;; /hhub/api/v1/vendor/profile and /hhub/api/v1/vendor/payment/methods. The design
;;; document specifies the shipping set and this is the first four of it; `/vendor/shipping`
;;; rather than `/vendor/vendors/shipping` because the vendor is already the session's
;;; subject on three of the five — the same reasoning that made the payment surface
;;; `/vendor/payment/methods`. The {vendorId} form exists for the ADMIN case, where the
;;; vendor is NOT the session's subject.
;;;
;;; {vendorId} IS A NUMERIC VENDOR ID (DOD_VEND_PROFILE.ROW_ID), passed through
;;; path-params as :shp-vendor-id. It is an ADDRESS, never an authorization: every verb
;;; re-selects with the tenant from the session, so another tenant's id yields 404, never
;;; data.
;;; ═══════════════════════════════════════════════════════════════════════════

(register-api-route 'route-vndshp-create
                    :method :post
                    :path "/hhub/api/v1/vendor/shipping"
                    :success-status 201
                    :auth-scope :session
                    :description "Create the shipping configuration for one vendor in the session tenant. Body: JSON object of nst-vnd-shp field names — vendorId is required (the parent; its column is nullable but the domain refuses a configuration that belongs to no vendor), plus any of freeShipEnabled, flatRateEnabled, zoneWiseEnabled, externalPartnerEnabled, storePickupEnabled, minOrderAmount, flatRateType, flatRatePrice, defaultShippingMethod, rateTableCsv, zones, shipPartnerKey, shipPartnerSecret and activeFlag. A body carrying neither rateTableCsv nor zones is seeded from the platform master files. A zonewise configuration whose rate table and zones disagree is REFUSED with the reason rather than stored and charged at 0.00. 404 when the vendor does not exist in this tenant; 409 when it already has a configuration, or when a soft-deleted row holds the slot.")

(register-api-route 'route-vndshp-list
                    :method :get
                    :path "/hhub/api/v1/vendor/shipping"
                    :success-status 200
                    :auth-scope :session
                    :description "List the session tenant's shipping configurations, newest row-id first. Query: vendorId (exact), defaultShippingMethod (FSH|FRS|TRS|EXS), method (free|flat|table|external|pickup — the method whose enable flag is on), status (active|inactive), sortBy (row-id|vendor-id|default-shipping-method), sortDir, limit, offset. Each element carries its zones, filled with one extra query for the whole page. 200 [] when nothing matches — an empty page is not a 404.")

(register-api-route 'route-vndshp-fetch
                    :method :get
                    :path "/hhub/api/v1/vendor/shipping/{vendorId}"
                    :path-params '(("vendorId" . :shp-vendor-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Read one vendor's shipping configuration, zones included — each zone with its pincode prefixes and the region codes those prefixes fall in. 200 means it exists; 404 means this vendor has none yet (or the row was deleted out of band) — this GET is also the existence check, so there is no /exists route. 404 also covers a vendor belonging to another tenant. The external partner's key and secret are never published.")

(register-api-route 'route-vndshp-update
                    :method :put
                    :path "/hhub/api/v1/vendor/shipping/{vendorId}"
                    :path-params '(("vendorId" . :shp-vendor-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Partially update one vendor's shipping configuration; only the supplied fields change, so an omitted field keeps its stored value. vendorId is REFUSED in the body (it is the parent link, not an editable field). Supplying zones replaces the zone collection. A configuration the checkout could not price is refused with the reason — for example a default shipping method whose enable flag is not \"Y\" would charge the customer NOTHING at all. 404 when the vendor has no configuration to update.")

(register-api-route 'route-vndshp-upload-ratetable
                    :method :put
                    :path "/hhub/api/v1/vendor/shipping/{vendorId}/rate-table"
                    :path-params '(("vendorId" . :shp-vendor-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Replace one vendor's zonewise shipping from an uploaded file pair. Body: rateTableCsv (the MIN,MAX,ZONE-… matrix as text), zones (the ZONE,PINCODES file as text, or an array of {zoneName, pincodes} objects), and optionally zoneWiseEnabled (\"Y\"/\"N\"; omit it and the flag is left alone). The zones REPLACE the vendor's zone collection — names that disappear are retired. The rate table's zone columns and the zone rows must name the same zones in both directions, no two zones may claim the same pincode prefix, and every cell must be a number with contiguous weight bands from 0.5 kg or below; a payload that breaks any of these is refused with the reason. 409 when a zone write did not complete — the configuration row is left untouched and the same payload should be re-sent.")

(register-api-route 'route-vndshp-upload-zones
                    :method :put
                    :path "/hhub/api/v1/vendor/shipping/{vendorId}/zones"
                    :path-params '(("vendorId" . :shp-vendor-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Replace one vendor's zone collection from an uploaded ZONE,PINCODES file, leaving the stored rate table untouched — the address for a pincode change that moves no price, so a client never has to re-send a matrix it did not edit. Body: zones (the ZONE,PINCODES file as text, or an array of {zoneName, pincodes} objects). The zones REPLACE the vendor's zone set — names that disappear are retired, names that reappear are revived — so the payload IS the whole zone set; an empty payload is REFUSED rather than read as 'remove every zone'. The new zone names are checked against the STORED rate table in both directions, and no two zones may claim the same pincode prefix, while zonewise shipping is enabled; a payload that breaks either is refused with the difference named. 404 when the vendor has no configuration to update; 409 when a zone write did not complete — the configuration row is left untouched and the same payload should be re-sent.")
