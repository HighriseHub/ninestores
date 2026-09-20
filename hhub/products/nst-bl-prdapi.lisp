;;; nst-bl-prdapi.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; PRODUCTS ACTION ROUTES — conflodis2 Tier 2 (Ring 2/3).
;;;
;;; Design:     aiharness/deepseek/skills/knowledge/nst-bl-conflodis2-DESIGN.md  (§3 signature, §5 multi-
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
(clsql:file-enable-sql-reader-syntax)

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
  "कर्म = nst-prd. The PRODUCT_CODE identity laws — including the
   soft-deleted-holder :C — ride in the verb's own `make :around`
   (dod-bl-prd.lisp), so the API, the internal website and any REPL caller all get
   the same four-valued answer.

   THIS VERB USED TO DO THE :C PRE-CHECK ITSELF, which meant only the HTTP path saw
   a 409 for a soft-deleted code holder while every other caller still raised and
   got a 500. The law belongs to the प्रत्यय, not to the transport."
  (request->dispatch request 'make 'nst-prd ctx))

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

(defun route-product-update-shipping (request ctx)
  "कर्म = nst-prd — THE SAME ENTITY AND THE SAME VERB AS route-product-update.

   There is no shipping entity to write. The four shipping_* columns live ON
   DOD_PRD_MASTER (shipping-length-cms / -width-cms / -height-cms / -weight-kg),
   and nst-prd already declares all four slots, so this endpoint is a CONSTRAINED
   !update — a narrower door onto the identical verb, not a second business path.
   That is also why nst-bl-vndshpapi.lisp:61-66 lists the legacy controller as
   'NOT HERE': the vendor's shipping CONFIGURATION is nst-vnd-shp, but these
   dimensions are product fields that the rate table is indexed BY.

   WHY IT DOES NOT GO THROUGH request->dispatch, unlike every sibling verb in this
   file. The generic ferry MOP-filters params against EVERY initarg nst-prd
   declares, so binding this route that way would let a caller rename the product,
   move its price, or flip its approval status simply by adding one JSON key to a
   request that claims to be about shipping — a mass-assignment hole of exactly
   the shape the legacy CSV upload already has. Here the four values are read
   explicitly and handed to prd-validate-shipping-args, so THE ALLOWLIST IS
   STRUCTURAL: there is no code path by which a fifth field can reach !update.

   ERROR TAXONOMY. A malformed VALUE is the client's mistake and becomes a 400
   via api-client-error — the condition prd-shipping-validation-error exists
   precisely so this clause catches the caller's error without also catching a
   genuine bug and mislabelling it. An EMPTY request (no shipping key at all) is
   also a 400 and not a silent 200: it is the same 'a write that did not happen
   must not report success' rule the legacy controller breaks when the vendor's
   shipping_enabled flag is off (see the note on the binding below).

   A missing or other-tenant product yields !update's own nst-entity-nil → 404,
   with no product-specific code here."
  (let ((payload (params request)))
    (handler-case
        (let ((args (prd-validate-shipping-args
                     (prd-param payload :shipping-length-cms)
                     (prd-param payload :shipping-width-cms)
                     (prd-param payload :shipping-height-cms)
                     (prd-param payload :shipping-weight-kg))))
          (unless args
            (api-client-error "no shipping information supplied — expected at least one of shipping-length-cms, shipping-width-cms, shipping-height-cms, shipping-weight-kg"))
          (apply #'!update 'nst-prd (rm-row-id request) ctx args))
      (prd-shipping-validation-error (c)
        (api-client-error "~A" (prd-shipping-validation-error-message c))))))

(defun route-product-update-pricing (request ctx)
  "कर्म = nst-prd-pricing — A DIFFERENT ENTITY from every other verb in this file.

   Every sibling here drives nst-prd through the generic ferry. This one drives
   the pricing row through set-product-pricing (nst-bl-prdpricing.lisp §9), the
   aggregate verb that writes the pricing row AND refreshes the product master's
   cached CURRENT_PRICE / CURRENT_DISCOUNT in one transaction — so the catalogue,
   the :current-price sort and the cart cannot advertise a price the pricing row
   does not justify.

   WHY IT DOES NOT GO THROUGH request->dispatch. Two reasons, either sufficient:

     * set-product-pricing takes the product-id POSITIONALLY and the rest as &key,
       so the ferry's (request verb entity-class ctx) shape cannot address it —
       the same reason route-product-update-shipping calls its verb directly.
     * the generic ferry MOP-filters params against EVERY initarg nst-prd-pricing
       declares, which is the mass-assignment hole route-product-update-shipping
       documents at length. Here the five values are read explicitly, so THE
       ALLOWLIST IS STRUCTURAL: there is no code path by which a sixth field —
       active-flag, tenant-id, row-id — reaches the verb.

   UPSERT, not update. The product may carry no pricing row yet (11 live products
   are in that state); set-product-pricing creates one. A client cannot tell the
   two apart from the response, and does not need to.

   WHAT A MISSING KEY MEANS differs by path, and this is the only asymmetry here:
   on UPDATE it means leave the stored value alone; on CREATE it takes the house
   default (1.00 / 0.00 / today … today+90 days). See the verb's own docstring.

   AN EMPTY BODY IS REFUSED, following route-product-update-shipping: a write that
   did not happen must not report success. Note the consequence — because at least
   one field is always supplied, the create-path defaults above are reachable from
   REPL and legacy callers but not from this endpoint. That is intended: a client
   that says nothing about a product's price has not asked for 1.00.

   ERROR TAXONOMY. A malformed VALUE is the client's mistake and becomes a 400 via
   api-client-error, caught as prdpricing-validation-error — the condition exists
   precisely so this clause catches the caller's error WITHOUT also catching a
   database failure (503) or a genuine bug (500) and mislabelling either as a bad
   request. A missing or other-tenant product yields the verb's own nst-entity-nil
   → 404, with no product-specific code here. A non-numeric {id} does the same,
   because the verb resolves the id through product-row-id-from-string."
  (let* ((payload    (params request))
         (price      (prd-param payload :price))
         (discount   (prd-param payload :discount))
         (start-date (prd-param payload :start-date))
         (end-date   (prd-param payload :end-date))
         (currency   (prd-param payload :currency)))
    (unless (or price discount start-date end-date currency)
      (api-client-error "no pricing information supplied — expected at least one of price, discount, start-date, end-date, currency"))
    (handler-case
        (set-product-pricing ctx (rm-row-id request)
                             :price      price
                             :discount   discount
                             :start-date start-date
                             :end-date   end-date
                             :currency   currency)
      (prdpricing-validation-error (c)
        (api-client-error "~A" (prdpricing-validation-error-message c))))))

(defun prd-status->active-flag (value)
  "The PUBLISHED status vocabulary → the column's char(1), or NIL when absent.

   This is the one place the two vocabularies meet, and it is deliberately a
   function rather than an inline cond: the API publishes `active`/`inactive`
   (what the vendor's own menu calls Turn On / Turn Off) while the column holds
   'Y'/'N'. Anything else is refused rather than coerced — a status of \"ACTIVE\"
   is accepted for case, but \"enabled\", \"1\", \"true\" and \"delisted\" are not,
   because guessing which of the schema's three lifecycle columns a caller meant
   is exactly how a delist silently becomes a no-op.

   CONTEXT FOR WHY THIS IS NOT THE WHOLE STORY: the products API note (SECTION 3)
   used to argue this endpoint could not be published until the vocabulary was
   settled, on the grounds that `active_flag` is 'Y' on every live row and what
   really delists a product is `approved_flag`/`deleted_state`. Reading the legacy
   controller settles it: `activate-product` / `deactivate-product`
   (dod-bl-prd.lisp:27-38) set `active_flag` to \"N\"/\"Y\" and nothing else, and the
   action menu wires exactly those two. So `inactive` means `active_flag='N'`, and
   this endpoint is a faithful port rather than a new invention. If delisting ever
   needs `approved_flag` too, that is a second, separately-named endpoint — not a
   second meaning smuggled into this one."
  (cond
    ((null value) nil)
    ((not (stringp value))
     (api-client-error "status ~S is not a string — expected \"active\" or \"inactive\"" value))
    ((string-equal value "active")   "Y")
    ((string-equal value "inactive") "N")
    (t (api-client-error "status ~S is neither \"active\" nor \"inactive\"" value))))

(defun route-product-update-status (request ctx)
  "कर्म = nst-prd, CONSTRAINED to :active-flag — the second narrow door in this file.

   Body: {\"status\":\"active\"} or {\"status\":\"inactive\"}. That is the whole
   surface: one field, two values, and the allowlist is STRUCTURAL because the
   field is a literal in the call below — the generic ferry is bypassed entirely,
   so there is no code path by which a caller can rename, reprice or re-approve a
   product through a request that claims to be about visibility.

   WHY IT IS NOT `!update` VIA request->dispatch: identical reasoning to
   route-product-update-shipping. The ferry MOP-filters params against EVERY initarg
   nst-prd declares, so `{\"status\":\"inactive\",\"current-price\":1}` would have
   changed both.

   THE LEGACY EQUIVALENT IS TWO CONTROLLERS, and this is a faithful port of both:
   /hhub/dodvendactivateprod → activate-product, /hhub/dodvenddeactivateprod →
   deactivate-product (dod-bl-prd.lisp:27-38), each of which sets `active_flag` and
   nothing else.

   A missing or other-tenant product yields !update's own nst-entity-nil → 404, and
   a malformed status a 400 via api-client-error — no product-specific code for
   either."
  (let* ((payload (params request))
         (flag    (prd-status->active-flag (prd-param payload :status))))
    (unless flag
      (api-client-error "no status supplied — expected \"status\": \"active\" or \"inactive\""))
    (!update 'nst-prd (rm-row-id request) ctx :active-flag flag)))

(defmethod render-json ((r ProductBulkUploadResponseModel) (ctx domain-ctx))
  "The bulk report → JSON alist. This alist IS the allowlist, as everywhere else.

   THE PROBLEMS ARRAY IS THE POINT OF THE WHOLE OBJECT. A count alone ('3 skipped')
   tells a vendor that something went wrong and nothing about what; each entry names
   the row and the reason, so the file can actually be fixed. It is capped nowhere
   here — a 100-row ceiling (com-hhub-attribute-vendor-bulk-product-count) bounds it
   by construction, so the response cannot be used to make an arbitrarily large
   answer.

   Kept beside the route rather than with the products प्रत्यय (dod-bl-prd.lisp),
   unlike every other render-json in this tree: those describe ENTITIES that the
   domain owns, whereas this describes the RESULT OF A REQUEST and nothing outside
   this file has any use for it."
  (declare (ignore ctx))
  (list (cons "rows"     (rows r))
        (cons "applied"  (applied r))
        (cons "created"  (created r))
        (cons "updated"  (updated r))
        (cons "skipped"  (skipped r))
        (cons "problems" (problems r))))

(defun route-product-template (request ctx)
  "कर्म = the session vendor's own catalogue, rendered as the products.csv that
   route-product-bulk-upload consumes. स्मरण — it reads and formats, and changes
   nothing.

   RETURNS TEXT, NOT AN ENTITY, and the registration says :response-format :csv so
   apidefs2 writes it with text/csv instead of running it through render-json. A
   download is a DOCUMENT, not a resource representation: wrapping a CSV in JSON so
   the client can unwrap it again serves nothing, and the whole value of the
   endpoint is that the file arrives saveable.

   🚨 THE GENERATOR IS THE LEGACY ONE, DELIBERATELY — create-products-csv2, which is
   also what the vendor's own page produces. This is not laziness; it is the
   property the feature depends on. That function emits the eleven columns in the
   order product-csv-file-data-row reads them POSITIONALLY, including the MD5Digest
   in column 10, which the upload recomputes from the same
   normalize-md5-fields formatting (~,1F qty, ~,2F money). A second generator here
   would be a second column order and a second formatting rule to keep in step, and
   when the two drift the round trip fails SILENTLY — every row rejected as a bad
   MD5 with no hint that the file was never wrong.

   So the download and the upload are two ends of one contract, and both reuse the
   code that already implements it. *prd-bulk-csv-header* was hoisted for the same
   reason.

   ⚠ KNOWN COUPLING, flagged rather than hidden: create-products-csv2 lives in
   vendor/dod-ui-ven.lisp, which compiles AFTER this file, so referencing it here
   costs an undefined-function style warning at every rebuild. It should move into
   the products BL when the vendor page is migrated onto this route — which is
   precisely what the route existing makes possible."
  (declare (ignore request))
  ;; 🚨 REFRESH FIRST. hhub-get-cached-vendor-products reads a SESSION-CACHED list
  ;; (the :login-vendor-products-functions session value), and nothing on the API path
  ;; ever invalidates it -- the legacy UI calls dod-reset-vendor-products-functions
  ;; after every write, the API does not. So a vendor who created a product through
  ;; the API and immediately downloaded the template got a file WITHOUT it: the smoke
  ;; test saw 63 rows and no fixture. A stale export is worse than a slow one, because
  ;; the vendor edits a file that cannot describe the catalogue they just changed.
  (dod-reset-vendor-products-functions (get-login-vendor) (domain-ctx-tenant ctx))
  (create-products-csv2 *prd-bulk-csv-header* (hhub-get-cached-vendor-products)))

(defun route-product-bulk-upload (request ctx)
  "कर्म = THE CSV TEXT carried by the request. सृजन/!state — an upsert per row.

   WHERE THE TEXT COMES FROM IS NOT THIS VERB'S BUSINESS, and that is the design.
   apidefs2's :request-format :raw hands it over in :raw-body after reconciling
   either transport — a multipart upload (-F \"file=@products.csv\") or a raw
   text/csv body (--data-binary @products.csv). Naming the file fields, reading the
   temp file, choosing between the two: all of that happens in the transport, so the
   verb takes the same path from a curl script and, later, from the vendor page.

   THE SAME IMPLEMENTATION AS THE LEGACY CONTROLLER. cl-csv:read-csv with
   :skip-first-p T and :map-fn #'product-csv-file-data-row is literally
   com-hhub-transaction-vendor-bulk-products-add's call (dod-ui-ven.lisp:540), and
   the parsed rows go to create-bulk-products (dod-bl-prd.lisp:278) unchanged. The
   ONE difference is the input: the legacy passes a temp FILE PATH and this passes
   TEXT. cl-csv accepts both — so the parsing, the positional column contract and
   the MD5 rule are the same code, not a rewrite kept in step by hand.

   🚨 A MALFORMED ROW IS REPORTED, NOT FATAL, WHICH IS A DELIBERATE DEPARTURE.
   The legacy passes :map-fn to cl-csv, so the first bad row signals out of the
   entire upload: the vendor gets a stack trace and no idea how far it got. Here
   each row is parsed inside its own handler-case and whatever fails is counted and
   NAMED, because 'row 47: <parse error>' is actionable and 'the upload failed' is
   not. The good rows still apply.

   ONE TRANSACTION for the writes. A partial upload that reports success is worse
   than a refused one, and create-bulk-products issues one statement per row without
   wrapping them — so the caller wraps, exactly as set-product-pricing does for its
   two-row pair.

   NOT DONE HERE, AND WORTH KNOWING: the subscription rules that the UI path
   enforces through com-hhub-policy-vendor-bulk-product-add — plan gate, suspension,
   and the 100-row cap — belong to the ABAC policy for this route, not to the verb.
   Until that policy is seeded and the PEP seam is bound, this endpoint applies no
   ceiling and no plan check. Do not mistake a 200 here for a permitted upload."
  (let* ((payload (params request))
         (csv (getf payload :raw-body)))
    (unless csv
      (api-client-error "no products.csv supplied — post it as -F \"file=@products.csv\" (multipart) or as a text/csv body"))
    (let ((raw (handler-case (cl-csv:read-csv csv :skip-first-p t)
                 (error (e) (api-client-error "products.csv could not be parsed as CSV: ~A" e))))
          (problems nil)
          (rows nil))
      (loop for row in raw
            for n from 1
            do (handler-case
                   (let ((parsed (product-csv-file-data-row row)))
                     ;; 🚨 NIL MEANS UNCHANGED, NOT INVALID, and this got written the
                     ;; other way round first. product-csv-file-data-row ends
                     ;;   (unless (equal expected-md5 computed-md5) (list ...))
                     ;; so it returns a row when the digests DIFFER -- i.e. when the
                     ;; vendor EDITED it -- and NIL when they MATCH, which means the row
                     ;; is untouched and there is nothing to do. A NIL is therefore a
                     ;; normal skip, and the first run's report said
                     ;;   skipped 63, problems 63 x "MD5Digest does not match"
                     ;; for a file whose digests were all perfectly correct.
                     ;; ONLY AN EXCEPTION IS A PROBLEM: a row that cannot be parsed at
                     ;; all, which is a genuinely broken file rather than an unedited one.
                     (when parsed (push parsed rows)))
                 (error (e)
                   (push (format nil "row ~D: ~A" n e) problems))))
      (setf rows (nreverse rows) problems (nreverse problems))
      ;; ── THE ROW CAP, enforced HERE and not in the policy — see
      ;;    com-hhub-policy-api-product-bulk-upload in dod-ui-pol.lisp for why the
      ;;    split is deliberate. The count is a property of the file; the only code
      ;;    that knows it correctly is this parser, and a line count in the policy
      ;;    would be a second, cruder definition of 'a row' that miscounts the
      ;;    moment a quoted field contains a newline.
      ;;    Refused BEFORE any write, so an over-long file costs nothing but the
      ;;    parse, and it is checked against the RAW row count: a file of 150 rows
      ;;    is over the cap even if 60 of them would have been skipped for a bad
      ;;    MD5, because the vendor's real intent was 150 products.
      (let ((cap (com-hhub-attribute-vendor-bulk-product-count)))
        (when (> (length raw) cap)
          (api-client-error "products.csv carries ~D rows; the limit for one upload is ~D" (length raw) cap)))
      ;; Classification for the report, done BEFORE the writes. create-bulk-products
      ;; makes the same distinction internally; this only counts it.
      (let ((created 0) (updated 0))
        (dolist (pair rows)
          (let* ((prd (first pair))
                 (rid (ignore-errors (slot-value prd 'row-id))))
            (if (and rid (ignore-errors (select-product-by-id rid (product-company prd))))
                (incf updated)
                (incf created))))
        (when rows
          (clsql:with-transaction ()
            (create-bulk-products (lambda () rows))))
        (make-instance 'ProductBulkUploadResponseModel
                       :rows (length raw)
                       :applied (length rows)
                       :created created
                       :updated updated
                       :skipped (- (length raw) (length rows))
                       :problems problems)))))

(defun route-product-copy (request ctx)
  "कर्म = nst-prd. सृजन — a COPY is a CREATE, which is the whole design decision here.

   The verb is `make`, not `!update` and not a bespoke copier, because a copy is a NEW
   PRODUCT: new row-id, new product-code, make's approval defaults. Modelling it as a
   write on the source would be the mistake — nothing about the source changes.

   THE SOURCE IS READ, NOT TRUSTED FROM THE BODY. `fetch` is used rather than reading a
   payload, for two reasons that both matter:

     * it re-selects with the SESSION tenant, so another tenant's id answers 404
       instead of copying their product;
     * a caller therefore cannot supply the fields being copied. The body is EMPTY —
       there is nothing to mass-assign and no field a client can smuggle into the new
       row. The name is generated (`Copy of …`) rather than accepted, which is the same
       rule stated positively.

   A fetch that misses returns a Belnap sentinel, and that is RETURNED UNCHANGED rather
   than wrapped: the dispatcher's reverse ferry already turns nst-entity-nil into a
   404, so copying a product that does not exist needs no copy-specific code.

   WHAT IT INHERITS is prd-copy-initargs (dod-bl-prd.lisp), which carries the field
   policy and its reasons — including the two traps that would otherwise be silent
   bugs: product-code is uniquely indexed and must not be inherited, and external-url
   is the source's public share link.

   STATUS 201, because this creates. The registration below says so."
  (let ((source (fetch 'nst-prd (rm-row-id request) ctx)))
    (if (typep source 'nst-prd)
        (apply #'make 'nst-prd ctx (prd-copy-initargs source))
        source)))


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
;;; THE FOUR ENDPOINTS OF THE ORIGINAL SKETCH THAT ARE STILL ABSENT HERE, and why
;;; — listed so their absence is a decision and not an oversight:
;;;
;;;   (update-shipping   WAS on this list and is now BOUND above, as
;;;                      PUT /catalog/products/{id}/shipping. The validation rule
;;;                      it was waiting for now lives in dod-bl-prd.lisp as
;;;                      prd-validate-shipping-args, with
;;;                      prd-shipping-validation-error as its condition.)
;;;   update-status     could be !update with :active-flag, but the published
;;;                     'active | inactive' vocabulary does not match the schema's
;;;                     three-column reality (active_flag is 'Y' on all 107 live
;;;                     rows; what delists a product is approved_flag/deleted_state).
;;;                     Registering it before that is settled would publish a verb
;;;                     that cannot do what its name says.
;;;   copy              WAS on this list, and the note above used to ask the two
;;;                     questions it was waiting on — 'does a copy inherit approval?
;;;                     pricing tiers?'. Both are now answered, in code rather than
;;;                     prose: NO to approval (make's defaults apply, so a copy is
;;;                     PENDING and cannot launder approval), and YES to the price
;;;                     but not the window (prd-copy-initargs, dod-bl-prd.lisp).
;;;                     BOUND above as POST /catalog/products/{id}/copy.
;;;   update-pricing    WAS on this list and is now BOUND above, as
;;;                     PUT /catalog/products/{id}/pricing. It stopped being a
;;;                     missing entity some time earlier — nst-prd-pricing has a
;;;                     domain class (dod-dal-prd.lisp), Tier-1 प्रत्यय
;;;                     (nst-bl-prdpricing.lisp) and boundary models — and the
;;;                     binding was the last part. Note what it does NOT delegate:
;;;                     it calls set-product-pricing directly rather than through
;;;                     the ferry, and the reason is recorded on the verb.
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

(register-action-route 'route-product-update-shipping
                       :action-verb 'route-product-update-shipping
                       :request-class 'ProductRequestModel
                       :description "Update a product's shipping dimensions and weight (the fields the zonewise shipping rate table is indexed by)."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :full
                       :tags '(products catalog shipping api v1))

(register-action-route 'route-product-update-pricing
                       :action-verb 'route-product-update-pricing
                       :request-class 'ProductPricingRequestModel
                       :description "Set a product's price, discount and discount window. Upsert: creates the pricing row when the product has none. Also refreshes the product's cached currentPrice/currentDiscount in the same transaction."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :full
                       :tags '(products catalog pricing api v1))

(register-action-route 'route-product-update-status
                       :action-verb 'route-product-update-status
                       :request-class 'ProductRequestModel
                       :description "Turn a product on or off: set its active flag. Body: {\"status\":\"active\"|\"inactive\"}. The legacy equivalent is the action menu's Turn On / Turn Off."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :full
                       :tags '(products catalog status api v1))

(register-action-route 'route-product-copy
                       :action-verb 'route-product-copy
                       :request-class 'ProductRequestModel
                       :description "Duplicate a product as a NEW listing: a copy of every catalogue field, named 'Copy of <name>', with a fresh product-code and unapproved status. The source is unchanged."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :full
                       :tags '(products catalog copy api v1))

;;; THE BULK PAIR. These two are ONE CONTRACT: the template emits the file the
;;; upload consumes, so they are registered together and their descriptions refer
;;; to each other. Registering either alone publishes half a round trip.
(register-action-route 'route-product-template
                       :action-verb 'route-product-template
                       :request-class 'ProductRequestModel
                       :description "Download the session vendor's catalogue as products.csv — the file the bulk upload consumes. text/csv, not JSON."
                       :output-type :csv
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :read
                       :tags '(products catalog bulk csv api v1))

(register-action-route 'route-product-bulk-upload
                       :action-verb 'route-product-bulk-upload
                       :request-class 'ProductRequestModel
                       :description "Upsert many products from a products.csv. Blank ProductID creates, a present one updates. Answers a per-row report."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor)
                       :feature-flags '(new-product-domain)
                       :audit-level :full
                       :tags '(products catalog bulk csv api v1))


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
;;; template, images, status, copy) answer 404
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

(register-api-route 'route-product-update-shipping
                    :method :put
                    :path "/hhub/api/v1/catalog/products/{id}/shipping"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Set a product's shipping dimensions and weight. Body: any subset of shipping-length-cms, shipping-width-cms, shipping-height-cms (whole centimetres, 1-32767) and shipping-weight-kg (0.01-999.99), camelCase or hyphenated. Only the supplied fields change; at least one is required. 400 on a non-positive, fractional-dimension or oversized value, or on an empty body. 404 when the product does not exist in this tenant. NOTE: these four fields are what the zonewise shipping rate table is indexed BY; the vendor's shipping configuration itself is a different entity and a different endpoint.")

(register-api-route 'route-product-update-pricing
                    :method :put
                    :path "/hhub/api/v1/catalog/products/{id}/pricing"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Set a product's price, discount and discount window. Body: any subset of price (decimal, must be > 0), discount (a PERCENTAGE, 0-100), start-date and end-date (DD/MM/YYYY, the period the discount RUNS, end not before start) and currency (3 letters). camelCase or hyphenated; at least one field is required. UPSERT: a product with no pricing row gets one, created with the house defaults for any field not supplied (price 1.00, discount 0.00, window today..today+90 days, currency from the account). An UPDATE changes only the fields actually supplied. Either way the product's cached currentPrice/currentDiscount are refreshed in the same transaction, so the catalogue and the cart cannot advertise a price the pricing row does not justify. 400 on a malformed or empty body. 404 when the product does not exist in this tenant. The response publishes discountExpired, DERIVED from the window and today's date, and never stored.")

(register-api-route 'route-product-update-status
                    :method :put
                    :path "/hhub/api/v1/catalog/products/{id}/status"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Turn a product on or off. Body: {\"status\": \"active\"} or {\"status\": \"inactive\"}. That is the whole surface — a constrained !update on active-flag, with no other product field reachable through this path. 'inactive' means active_flag='N' (what the vendor's Turn Off does today); it does NOT delist the product, which is approved_flag/deleted_state and a different operation. 400 on a missing or unrecognised status. 404 when the product does not exist in this tenant.")

(register-api-route 'route-product-copy
                    :method :post
                    :path "/hhub/api/v1/catalog/products/{id}/copy"
                    :path-params '(("id" . :row-id))
                    :success-status 201
                    :auth-scope :session
                    :description "Duplicate a product. NO BODY: the copy is made from the stored product addressed by {id}, so nothing a client sends can reach the new row. Inherits description, hsn-code, product type, unit of measure, qty per unit, sku, upc, category, vendor, subscription flag, price, discount and the shipping dimensions. NOT inherited, deliberately: product-code (uniquely indexed — a copy takes a fresh one), external-url (it is the source's public share link), and approval state, so the copy starts PENDING like any new listing. Units in stock are NOT copied: stock is a count of physical goods, not product identity. The name is generated as 'Copy of <source name>'. 404 when the source does not exist in this tenant. Returns 201 with the NEW product.")

(register-api-route 'route-product-template
                    :method :get
                    :path "/hhub/api/v1/catalog/products/template"
                    :success-status 200
                    :auth-scope :session
                    :response-format :csv
                    :content-type "text/csv; charset=utf-8"
                    :description "Download the session vendor's catalogue as products.csv. Eleven columns, ProductID first and MD5Digest last — the exact file the bulk upload consumes, including the digest it recomputes. Fill it in and post it back to /catalog/products/bulk. NOTE: register-api-route matches /catalog/products/template BEFORE /catalog/products/{id}, so this path is not shadowed by a product whose id is the literal string 'template'.")

(register-api-route 'route-product-bulk-upload
                    :method :post
                    :path "/hhub/api/v1/catalog/products/bulk"
                    :success-status 200
                    :auth-scope :session
                    :request-format :raw
                    :description "Upsert many products from a products.csv. Send the file as multipart (-F \"file=@products.csv\") or as the raw body (-H 'Content-Type: text/csv' --data-binary @products.csv). Columns are positional and MUST keep the downloaded order; a blank ProductID creates a product and a present one updates it. Each row's MD5Digest is recomputed and a row that does not match is REPORTED AND SKIPPED rather than failing the whole upload. Answers {rows, applied, created, updated, skipped, problems[]}, with problems naming the row and the reason. All writes happen in one transaction, so a reported success is a complete upload. NOTE: the subscription plan gate, the suspension check and the 100-row ceiling are enforced by this route's ABAC policy, not by the verb — until that policy is seeded and the PEP seam is bound, this endpoint applies no ceiling.")
