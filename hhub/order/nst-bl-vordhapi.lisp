;;; nst-bl-vordhapi.lisp — the VENDOR ORDER channel: Tier-2 routes + Ring-4 bindings (S11)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Design: aiharness/deepseek/skills/vendor-orders-adhara-CONTEXT.md (§4 S11, decisions V11-V15).
;;; The customer channel is order/nst-bl-ordhapi.lisp; this file mirrors its shape and does NOT
;;; restate its reasoning.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THIS FILE IS
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; THREE routes over the vendor order row (nst-vordh / DOD_VENDOR_ORDERS), and their three Ring-4
;;; bindings. The spec (nst-bl-apidefs2.lisp / nst-bl-conflodis2.lisp) publishes NO vendor-orders
;;; endpoint at all — D3 says these three paths are ours, and the live vendor family already carries
;;; /api/v1/vendor/profile, /payment and /shipping (vendor/nst-bl-vndapi.lisp).
;;;
;;;   GET  /hhub/api/v1/vendor/orders                 → enumerate   (the vendor's worklist)
;;;   GET  /hhub/api/v1/vendor/orders/{ordnum}        → fetch       (one slice, with an ETag)
;;;   PUT  /hhub/api/v1/vendor/orders/{ordnum}        → !update     (the vendor's own four fields)
;;;
;;; ⚠ NO DELETE, AND THAT IS A DECISION RATHER THAN AN OMISSION: V9 makes delete! refuse every
;;; external channel, because a vendor erasing its slice would remove the row the customer's order is
;;; accounted for by. A vendor that stops supplying an order CANCELS it, and /cancel is out of this
;;; batch's scope (D3), so there is nothing here to bind.
;;;
;;; ⚠ NO NESTED LINES EITHER, and this one is a KNOWN GAP rather than a design choice: a vendor
;;; legitimately needs to know WHAT to ship, and ORDER_ITEMS is the only place that is written down.
;;; Serving it needs a vendor-scoped line read in nst-bl-orditm.lisp (the line entity's enumerate
;;; filters by order, not by vendor), which is another file's contract. Recorded in the story file's
;;; open list rather than half-done here.
;;;
;;; ── THE THREE LOAD-ORDER FACTS THIS FILE DEPENDS ON ─────────────────────────
;;;
;;; 1. A BINDING LIVES IN THE FILE THAT REGISTERS ITS VERB. register-api-route REFUSES a path whose
;;;    action route is not already registered (api-route-bindable-p), so the order of two top-level
;;;    forms inside a loaded file is a BUILD-LEVEL requirement and the failure is brutal: the refusal
;;;    runs at LOAD time and aborts the load of this file, so the application does not come up. Each
;;;    binding below therefore sits IMMEDIATELY BELOW its own registration, and
;;;    aiharness/deepseek/tools/nst-binding-order-check is the static stand-in that asserts it.
;;; 2. THE PATHS CARRY THE /hhub PREFIX (api-path-deployment-prefix-p refuses a template without it),
;;;    although the spec's own paths omit it and nginx rewrites the rest.
;;; 3. This file loads AFTER order/nst-bl-vordh.lisp, whose BL selectors and copy ferry it calls,
;;;    and after order/nst-bl-ordh.lisp, whose SHARED helpers it reuses: ordh-param, ordh-page-param,
;;;    ordh-keyword-value, ordh-param's keyword handling, ordh-params-without, ordh-header-value,
;;;    nst-order-header-if-match-refusal and the JSON-error writers. Nothing here is a second copy of
;;;    "what asc means" or "which statuses are terminal".
;;;
;;; ── WHO THE CALLER IS, AND WHY THAT READ IS NOT DIRECT ──────────────────────
;;;
;;; The vendor identity comes from the session, NEVER from the URL or the body (V3/V10). It is read
;;; with conflodis2-session-value (:login-vendor) — the house helper — and NOT with
;;; hunchentoot:session-value directly. That is not style: outside an HTTP request the direct call
;;; signals UNBOUND-VARIABLE, so "we cannot tell who you are" would reach a REPL or test caller as a
;;; 500 instead of the 401 this must answer. The vendor API's own file records that measurement next
;;; to the identical read (vendor/nst-bl-vndapi.lisp:353-364), and the same reasoning governs
;;; vordh-emit-etag below.
;;;
;;; The TENANT needs no work from this file: make-action-domain-ctx (core/nst-bl-conflodis2.lisp:160)
;;; builds अधिकरण from conflodis2-login-company, which resolves vendor → customer → user company, so
;;; a vendor session already yields a correct tenant in the ctx. That is worth stating because it is
;;; the kind of thing a reader would otherwise re-derive: नियम-1 is satisfied by the layer above.

;;; ───────────────────────────────────────────────────────────────────────────
;;; SECTION 1 — the session: who is asking
;;; ───────────────────────────────────────────────────────────────────────────

(defun vordh-session-vendor ()
  "The session's VENDOR object, or NIL. The read is conflodis2's tolerant session reader, so a
   REPL/batch caller gets NIL instead of a signalling hunchentoot call.

   ⚠ THE KEY IS :login-vendor, THE OBJECT — the same object the vendor's own pages read
   (get-login-vendor, vendor/dod-ui-ven.lisp:3128) and the same one the vendor API's settings route
   reads. A row-id and an object that disagreed would be two answers to 'which vendor is this', and
   the object is what carries the row-id the domain needs anyway.

   THE slot-value IS GUARDED SEPARATELY: a session value can be anything a stale or foreign session
   put there, so ANY FAILURE TO ESTABLISH AN IDENTITY IS NIL — fail closed, never fall back to a
   body row-id."
  (let ((vendor (conflodis2-session-value :login-vendor)))
    (when (and vendor (ignore-errors (slot-value vendor 'row-id)))
      vendor)))

(defun vordh-session-vendor-id ()
  "The session vendor's ROW-ID as an INTEGER, or NIL. The integer, not a string: the BL's scope
   comparisons and the CLSQL columns are integers, and a string here would make every scope test
   compare 47 against \"47\" and quietly select nothing."
  (let ((vendor (vordh-session-vendor)))
    (when vendor (slot-value vendor 'row-id))))

(defun vordh-no-session-vendor (ctx)
  "The sentinel a vendor route answers when the session carries no vendor: :F, so 404.

   ⚠ NOT A 401, AND NOT A CREATION. A 401 is the API's word for 'no credential at all', and the
   layer above already speaks it: api-authenticate refuses a request with no login company before any
   route runs. Reaching here means the caller IS authenticated as a tenant but is not a vendor — and
   on a vendor-addressed document that is an ABSENCE, which is what :F means in this domain (the
   customer channel's ordh-no-session-customer draws the identical line, S12 (d))."
  (make-instance 'nst-entity-nil
                 :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                 :reason "No vendor order is addressable from this session: it carries no vendor identity (:login-vendor). This is the vendor channel, and a vendor order row belongs to the session's vendor — the vendor is read from the session and never from the URL or the body (V3), so there is no row here to read or change. Sign in as a vendor."))

;;; ───────────────────────────────────────────────────────────────────────────
;;; SECTION 2 — the transport keys: what the ROUTE removes and what it PINS
;;; ───────────────────────────────────────────────────────────────────────────

(defparameter *vordh-transport-keys*
  '(:ordnum :vendor-id :tenant-id :row-id :order-id :cust-id
    "ordnum" "vendor-id" "tenant-id" "row-id" "order-id" "cust-id")
  "Keys the route REMOVES from a request's body before the verb sees it: the URL's address and the
   session's scope.

   ⚠ BOTH SPELLINGS ARE LISTED ON PURPOSE. A params plist can be KEYWORD-keyed (path parameters, an
   :agent caller) or STRING-keyed (a JSON body, a querystring), and a filter that knew only one
   spelling would silently pass the other through — which is the whole defect this list exists to
   prevent. ordh-param already reads both shapes; this list is the write-side twin of that.

   ⚠ THE VERB STRIPS THESE TOO (V8, *vordh-update-stripped-initargs*), AND THE DUPLICATION IS
   DELIBERATE: the route's copy protects the vendor's own scope from a body that contradicts it, and
   the verb's copy protects every OTHER caller — a REPL, an :agent, a batch job — that never passes a
   route at all.")

(defun vordh-params-without-transport-keys (payload)
  "PAYLOAD without any of *vordh-transport-keys*. Walks by #'cddr because a params plist alternates
   keys and values; iterating by pairs is the trap the vendor API's own docstring records."
  (loop for (key value) on payload by #'cddr
        unless (member key *vordh-transport-keys* :test #'equal)
          append (list key value)))

(defun vordh-params-with-session-scope (payload vendor-id)
  "PAYLOAD without the transport keys, with :vendor-id FORCED to the SESSION's VENDOR-ID.

   THE FORCE IS THE POINT (AC d): the vendor axis is a fact about who is asking, so it is pinned here
   and any inbound :vendor-id has already been removed by the filter above. list* puts the forced pair
   FIRST, which matters even if a twin survived: getf reads the first match, so the session's value
   wins by construction rather than by luck.

   The forced key is NOT a second source of truth — the verb consumes :vendor-id as SCOPE and verifies
   it against the row it resolved (V10), and it strips it so it can never be assigned. Passing it is
   how the route tells the verb which vendor's session this is."
  (list* :vendor-id vendor-id (vordh-params-without-transport-keys payload)))

;;; ───────────────────────────────────────────────────────────────────────────
;;; SECTION 3 — the list route's query arguments
;;; ───────────────────────────────────────────────────────────────────────────

(defun vordh-enumerate-args (payload vendor-id)
  "Filter args for (enumerate 'nst-vordh ctx …). These are QUERY arguments of the enumerate verb
   rather than nst-vordh initargs, so extract-domain-initargs would drop every one of them: a list
   action is one read of a filtered collection, not an entity crossing.

   VENDOR-ID IS A PARAMETER RATHER THAN A PAYLOAD READ, and that is V3: the vendor scope comes from
   the SESSION, never from the query string, so this function cannot be handed a client-supplied one.
   The BL then REFUSES an enumerate without it, which is why forgetting it cannot produce the
   cross-vendor list.

   FROM-DATE / TO-DATE pass through as the strings the query carried — the comparison is against a
   TIMESTAMP column here (DOD_VENDOR_ORDERS.ORD_DATE is a timestamp, unlike the header's date), where
   MySQL compares a well-formed date string correctly and a malformed one matches nothing. They are
   FILTERS, not stored fields.

   ?include-deleted IS DELIBERATELY NOT HONOURED, exactly as on the customer channel: that flag is an
   internal audit caller's, this is an external surface, and नियम-2 makes a DELETED_STATE='Y' row
   invisible to every verb. A client that sends it is IGNORED rather than obeyed.

   ?cust-id IS HONOURED, unlike the customer channel's (which pins it), because it cannot widen
   anything here: the query is already bounded by the session's vendor AND tenant, so a customer
   filter can only narrow a vendor's OWN rows — 'show me this customer's orders with me'. It cannot
   be used to discover that the customer has orders elsewhere."
  (list :vendor-id   vendor-id
        :cust-id     (ordh-param payload :cust-id)
        :status      (ordh-param payload :status)
        :ordnum-like (ordh-param payload :ordnum-like)
        :from-date   (ordh-param payload :from-date)
        :to-date     (ordh-param payload :to-date)
        :limit       (ordh-page-param (ordh-param payload :limit) "limit")
        :offset      (ordh-page-param (ordh-param payload :offset) "offset" :allow-zero t)
        :sort-by     (or (ordh-keyword-value (ordh-param payload :sort-by)) :ord-date)
        :sort-dir    (or (ordh-keyword-value (ordh-param payload :sort-dir)) :desc)))

(defun vordh-guard-sort-args (payload)
  "Refuse an unusable sort-by/sort-dir at the ROUTE layer, as a 400, and never pass the sort through
   unguarded.

   WHY THIS EXISTS AT ALL: the whitelist that actually protects the ORDER BY lives in the domain
   (nst-ordh-sort-column), and that function says in its own docstring that a plain `error` there
   reaches the API as a 500 — 'the server broke' — for a client that mistyped a query parameter the
   API itself publishes. This is that 400, and it READS *vordh-sort-whitelist* rather than restating
   the columns, so the guard and the authority cannot drift apart.

   ONLY A SUPPLIED AND UNUSABLE VALUE IS REFUSED: an absent sort-by is legal and defaults in
   vordh-enumerate-args, so the happy path is untouched."
  (let ((sort-by (ordh-keyword-value (ordh-param payload :sort-by)))
        (sort-dir (ordh-keyword-value (ordh-param payload :sort-dir))))
    (when (and sort-by (not (assoc sort-by *vordh-sort-whitelist*)))
      (api-client-error "sort-by ~S is not sortable here; use one of ~{~A~^, ~}"
                        sort-by (mapcar #'car *vordh-sort-whitelist*)))
    (when (and sort-dir (not (member sort-dir '(:asc :desc))))
      (api-client-error "sort-dir must be asc or desc, got ~S" sort-dir))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; SECTION 4 — the address: {ordnum} + the session's vendor → ONE row
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; ⚠ THIS FUNCTION IS THE ONLY PLACE THE VENDOR NARROWS fetch/!update/delete! (V10), and it is where
;;; AC (c), (d) and (e) are enforced for those paths. It returns the ROW rather than the entity, and
;;; that is a deliberate improvement on the customer channel's resolver: the row is what carries
;;; UPDATED, so the ETag the detail route emits and the version the PUT compares against both come
;;; from the SAME read, with no second SELECT and no chance of the two disagreeing.

(defun vordh-row-from-url (request ctx)
  "The dod-vendor-order row the URL's {ordnum} names FOR THIS SESSION'S VENDOR, or a sentinel.

   ONE ANSWER FOR EVERY WAY OF FAILING — the number does not exist, it is another vendor's row, it is
   another tenant's, it has been soft-deleted, or its ORDNUM is NULL. A 403 or a distinct message
   would CONFIRM that another vendor's row exists, which is the leak F1 was resolved around; and a
   caller who is authenticated as a vendor but not THIS vendor learns nothing beyond 'not here'.

   ⚠ AC (e) IS STRUCTURAL. The lookup is an equality on ORDNUM, and `[= [:ordnum] ordnum]` cannot
   match NULL, so a legacy row with no number is unreachable and answers :F. There is deliberately no
   `OR ORDNUM IS NULL` fallback: 462 of the 462 pre-migration rows were NULL, and a best-effort
   address would have handed every vendor the same stranger's order.

   ⚠ THE TENANT COMES FROM THE CTX AND THE VENDOR FROM THE SESSION, in that order, and both are in the
   SQL. A resolver that took either from the URL would be the BOLA shape the vendor API's settings
   route guards against with the same three-way check."
  (let* ((payload (params request))
         (raw (ordh-param payload :ordnum))
         (tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (vendor (vordh-session-vendor)))
    (if (null vendor)
        (vordh-no-session-vendor ctx)
        (let ((ordnum (cond ((and (stringp raw) (plusp (length (string-trim " " raw))))
                             (string-trim " " raw))
                            ;; An integer is not an ORDNUM, but an agent/REPL caller may hand one over
                            ;; where apidefs2 would have handed a string — coerced rather than refused,
                            ;; exactly as the customer channel's resolver coerces one.
                            ((integerp raw) (princ-to-string raw))
                            (t nil))))
          (if (null ordnum)
              (api-client-error "a vendor order number is required in the URL (a non-blank ordnum, e.g. ORD-DEMO-2023-24-XNEBWE)")
              (let* ((vendor-id (slot-value vendor 'row-id))
                     (knowledge (with-db-call
                                    (nst-select-vendor-order-rows-by-ordnum ordnum tenant-id
                                                                           :vendor-id vendor-id)
                                  "nst-vordhapi/row-from-url (ordnum, tenant, session vendor)")))
                (if (not (eq (bo-knowledge-truth knowledge) :T))
                    (domain-sentinel-from-knowledge
                     knowledge ctx
                     :reason (lambda (truth)
                               (case truth
                                 (:F (format nil "No live vendor order holds number ~A for this vendor in this tenant. It does not exist, it belongs to another vendor or another tenant, or it has been soft-deleted — those are ONE fact for every verb in this domain (नियम-2 makes a soft-deleted row invisible), and distinguishing them would confirm that somebody else's row exists." ordnum))
                                 (:U (format nil "Could not resolve vendor order number ~A — the database call did not answer, so whether that row exists is UNKNOWN" ordnum))
                                 (otherwise (format nil "Vendor order number ~A could not be resolved (unexpected truth ~A)" ordnum truth)))))
                    (let ((rows (bo-knowledge-payload knowledge)))
                      (if (or (null rows) (cdr rows))
                          (if (null rows)
                              (make-instance 'nst-entity-nil
                                             :tenant-id tenant-id
                                             :reason (format nil "No live vendor order holds number ~A for this vendor in this tenant." ordnum))
                              (make-instance 'nst-entity-contradiction
                                             :tenant-id tenant-id
                                             :reason (format nil "Vendor order number ~A returned ~D rows for ONE vendor in this tenant — uk_vo_order_vendor should make that impossible, so two sources disagree and which row the URL names cannot be decided" ordnum (length rows))))
                          (car rows))))))))))

(defun vordh-emit-etag (row)
  "Put the row's version on the response as a WEAK ETag, so that If-Match is USABLE.

   🚨 WITHOUT THIS, THE PRECONDITION ON THE PUT CANNOT BE USED AT ALL. If-Match is enforced (V13) and
   answers 412 correctly, but a caller has no way to learn a validator: UPDATED is DB-managed and
   deliberately not a mirrored slot (D19), so it appears in no response body. A precondition whose
   token is unguessable is decoration. The customer channel omits the ETag and says so; this channel
   emits it, and the difference is recorded here rather than left for a reader to notice.

   ⚠ WEAK AND QUOTED, per RFC 9110, and the domain's own comparison expects exactly that:
   nst-ordh-if-match-value strips the W/ prefix and the surrounding quotes before comparing
   (nst-bl-ordh.lisp:841-854), so the token emitted here round-trips byte-for-byte through the check.

   ⚠ A NON-HTTP CALLER IS NOT AN ERROR: outside a request there is no response to carry a header, and
   hunchentoot signals. handler-case, the same tolerance the session read has — a REPL caller should
   get the row, not a 500 about a missing header table."
  (let ((token (nst-ordh-version-token (slot-value row 'updated))))
    (when token
      (handler-case (setf (hunchentoot:header-out :etag) (format nil "W/\"~A\"" token))
        (condition () nil)))
    token))

;;; ───────────────────────────────────────────────────────────────────────────
;;; SECTION 5 — the three routes
;;; ───────────────────────────────────────────────────────────────────────────

(defun route-vordh-list (request ctx)
  "कर्म = the filtered nst-vordh collection, SCOPED TO THE SESSION'S VENDOR (V3). Calls enumerate
   directly (not via the ferry) because its arguments are query filters rather than entity initargs —
   see vordh-enumerate-args.

   Zero rows is a SUCCESS with an empty list, not a 404: a vendor's worklist is a VIEW, and 'you have
   no orders yet' is not 'no such thing'.

   The sort arguments and the page arguments are guarded BEFORE the domain sees them, so an unusable
   ?sort-by or ?limit is a 400 rather than the 500 a bare domain error would produce."
  (let ((vendor (vordh-session-vendor)))
    (if (null vendor)
        (vordh-no-session-vendor ctx)
        (progn
          (vordh-guard-sort-args (params request))
          (apply #'enumerate 'nst-vordh ctx
                 (vordh-enumerate-args (params request) (slot-value vendor 'row-id)))))))

(defun route-vordh-detail (request ctx)
  "कर्म = nst-vordh: ONE vendor's slice of one order, addressed by ORDNUM, with an ETag.

   TWO READS, DELIBERATELY, and both are load-bearing. The first is the address resolution
   (vordh-row-from-url: tenant + vendor + live, and the ONE 404), and the second is the VERB's own
   read through fetch. Returning the resolver's entity and skipping fetch would save a SELECT and give
   the detail path its own private route to the row — the shape the customer channel refuses for the
   same reason ('bypassing enumerate would save one SELECT and give the aggregate its own private
   path to the child rows').

   The ETag comes from the resolver's row, NOT from the entity: UPDATED is not a mirrored slot (D19),
   so the entity that crosses the boundary carries no version at all."
  (let ((row (vordh-row-from-url request ctx)))
    (if (not (typep row 'dod-vendor-order))
        row
        (let ((entity (fetch 'nst-vordh (princ-to-string (slot-value row 'row-id)) ctx)))
          (if (not (typep entity 'nst-vordh))
              entity
              (progn
                (vordh-emit-etag row)
                entity))))))

(defun route-vordh-update (request ctx)
  "कर्म = nst-vordh. Partial update by ORDNUM (the URL's address); only the initargs actually supplied
   change — CLOS reinitialize-instance, in the verb.

   ONLY FOUR FIELDS CAN ACTUALLY CHANGE ON THIS CHANNEL (V8: fulfilment, shipped date, comments, a
   tracking URL). Everything else in the body is REFUSED by the verb's field policy with a 409 naming
   the keys — the vendor cannot write the money, the customer's addresses, or the lifecycle. This
   route does not restate that policy; it lets the domain judge, which is the only way the two stay
   in step.

   :if-match IS PASSED INTO THE VERB BY CALLING !update DIRECTLY, because the ferry would drop it:
   request->dispatch hands !update (extract-domain-initargs rm entity-class), which forwards only keys
   the DOMAIN CLASS declares, and a transport precondition is not one. The verb consumes it as a
   control key BEFORE its field policy — the order that S12 had to fix on the customer side, where
   policy-first refused :if-match as an escalation and made every If-Match update answer 409.

   ⚠ AND THE ROUTE STILL ANSWERS THE PRECONDITION FIRST, which is not a second rule but the only way
   to answer 412: the verb's refusal is an nst-entity-contradiction, and api-status-for-response maps
   that to 409 for every route in the tree — so a stale validator reaching the client through the verb
   would read as 'two sources disagree' instead of RFC 9110's Precondition Failed. Both checks run the
   SAME function (nst-order-header-if-match-refusal), so a change to the rule changes both, and the
   verb's own check — against the row it is about to write — remains the authority that closes the
   window between them."
  (let ((row (vordh-row-from-url request ctx)))
    (if (not (typep row 'dod-vendor-order))
        row
        (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
               (vendor-id (vordh-session-vendor-id))
               (expected (ordh-header-value :if-match))
               (refusal (when expected
                          (nst-order-header-if-match-refusal row expected tenant-id))))
          (if refusal
              (progn
                (api-write-json (api-error-json "precondition_failed" (entity-reason refusal)) 412)
                nil)
              (let* ((row-id (princ-to-string (slot-value row 'row-id)))
                     (rm (make-instance 'NstVordhRequestModel
                                        :params (vordh-params-with-session-scope
                                                 (params request) vendor-id))))
                ;; extract-domain-initargs is the ONE MOP filter, so the verb is handed exactly what
                ;; the ferry would have handed it — no second filter, no keys the ferry would drop —
                ;; and :if-match is prepended because it is precisely the key the ferry WOULD drop.
                ;; An absent header passes :if-match NIL, which the verb reads as 'no precondition
                ;; asserted' rather than as an unmatched validator.
                (apply #'!update 'nst-vordh row-id ctx
                       (list* :if-match expected
                              (extract-domain-initargs rm 'nst-vordh)))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; SECTION 6 — the registrations and the Ring-4 bindings
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; ⚠ EACH BINDING SITS IMMEDIATELY BELOW ITS REGISTRATION, and that order is a LOAD-TIME requirement
;;; rather than tidiness: register-api-route refuses a path whose action route is not yet registered,
;;; and the refusal aborts the load of THIS file — one of the API files — so the application does not
;;; come up. See the header, fact 1.
;;;
;;; ⚠ /vendor/orders AND /orders DO NOT SHADOW EACH OTHER, and this file is what makes that testable
;;; at last: S13 (c) has been open since the customer channel shipped, because the vendor paths did
;;; not exist. find-api-route ranks candidates fewest-parameters-first, and these two templates differ
;;; in their literal prefix, so a GET on either resolves to its own route.

(register-action-route 'route-vordh-list
                       :action-verb 'route-vordh-list
                       :request-class 'NstVordhRequestModel
                       :description "List the SESSION vendor's order rows (V3 scoping: vendor AND tenant AND live), newest first by ORD_DATE. Query params: status, ordnum-like, cust-id, from-date, to-date, sort-by, sort-dir, limit, offset. ?include-deleted is deliberately not honoured. An empty result is 200 with [], not 404; an unusable sort-by or limit is 400. The vendor is read from the session, never from the query string."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(order-domain)
                       :audit-level :read)

(register-api-route 'route-vordh-list
                    :method :get
                    :path "/hhub/api/v1/vendor/orders"
                    :success-status 200
                    :auth-scope :session
                    :description "The vendor channel's worklist (D3: the spec publishes no vendor-orders endpoint; these three paths are this batch's). One row per (order, vendor), scoped to the session's vendor and tenant — a second vendor's row in the same tenant is invisible. 404 when the session carries no vendor identity; 400 for an unusable sort or limit; 200 [] when the vendor simply has no orders.")

(register-action-route 'route-vordh-detail
                       :action-verb 'route-vordh-detail
                       :request-class 'NstVordhRequestModel
                       :description "One vendor order slice, addressed by ORDNUM: the row's own fields (a denormalised copy of the customer's order header for THIS vendor, carrying the customer's document number per D20). Answers an ETag so the PUT's If-Match precondition is usable. 404 for every way of not being addressable — absent, another vendor's, another tenant's, soft-deleted, or a legacy row whose ORDNUM is NULL — because distinguishing them would confirm that somebody else's row exists."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(order-domain)
                       :audit-level :read)

(register-api-route 'route-vordh-detail
                    :method :get
                    :path "/hhub/api/v1/vendor/orders/{ordnum}"
                    :path-params '(("ordnum" . :ordnum))
                    :success-status 200
                    :auth-scope :session
                    :description "One vendor's slice of one order, by the customer's ORDNUM. 400 when the URL carries no usable number; 404 when no live row holds that number FOR THIS VENDOR in this tenant; 503 when the database could not be answered (NOT 404 — whether it exists is UNKNOWN). The response carries a weak ETag derived from the row's UPDATED, which is the validator the PUT expects.")

(register-action-route 'route-vordh-update
                       :action-verb 'route-vordh-update
                       :request-class 'NstVordhRequestModel
                       :description "Update the SESSION vendor's own slice, by ORDNUM. Only the fields the vendor channel may write change (V8): order-fulfilled, shipped-date, comments, external-url. Everything else is refused with 409 naming the keys — the money, the customer's addresses and the lifecycle belong to other verbs. The vendor, the tenant, the order id, the customer id and the ORDNUM itself are stripped before the verb sees them, so a body cannot move the row. If-Match is enforced and answers 412, not 409."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(order-domain)
                       :audit-level :full)

(register-api-route 'route-vordh-update
                    :method :put
                    :path "/hhub/api/v1/vendor/orders/{ordnum}"
                    :path-params '(("ordnum" . :ordnum))
                    :success-status 200
                    :auth-scope :session
                    :description "Partial update of one vendor's slice. Body: an object of nst-vordh field names; only the fields supplied change, and only the four this channel may write are accepted (409 otherwise, naming every offending key at once). Dates on the vendor channel are STRINGS (ORD_DATE/REQ_DATE/SHIPPED_DATE are timestamp columns read and written verbatim, so the round trip is exact), apart from the internal-only expected-delivery-date. Send If-Match with the ETag the GET returned: a mismatch is 412, not 409. 404 for every way of not being addressable, as on the GET.")
