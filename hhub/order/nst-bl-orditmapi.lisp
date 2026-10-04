;;; nst-bl-orditmapi.lisp — ORDER LINE ACTION ROUTES (conflodis2 Tier 2, Ring 2/3-4)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Design: aiharness/deepseek/skills/knowledge/nst-bl-conflodis2-DESIGN.md (§3, §5, §6)
;;;         aiharness/deepseek/skills/order-adhara-stories-CONTEXT.md (S12/S13, D3, D5, D8)
;;; Dispatcher: hhub/core/nst-bl-conflodis2.lisp
;;; Model: hhub/invoice/nst-bl-invitmapi.lisp (the worked example this file mirrors)
;;;
;;; The line-side counterpart of order/nst-bl-ordhapi.lisp. Same contract: an inbound action symbol
;;; → (register-action-route 'route-orditm-<action> …) → ONE action verb → Tier-1 ferries
;;; (request->dispatch … 'nst-orditm). Domain-layer results only; the dispatcher does the reverse
;;; ferry and the render.
;;;
;;; ⚠ A LINE IS ADDRESSED UNDER ITS ORDER, AND THESE ROUTES ENFORCE THE PAIRING. The verbs in
;;; nst-bl-orditm.lisp already prove the order exists in the session tenant before touching a line
;;; (nst-fetch-visible-order-header) — that is this entity's whole authorization model, because
;;; DOD_ORDER_ITEMS has NO foreign key on ORDER_ID and nothing else constrains it. What a verb
;;; CANNOT know is whether the caller named the RIGHT parent: a nested URL carries two ids, and
;;; answering it requires agreeing that line 42 really is a line of order 7. orditm-check-pairing-of
;;; does that, and its absence would show up as a LIE rather than a failure — !update on a
;;; mismatched pair would return 409 'a line does not move between orders', which is a true rule
;;; answering an untrue question. A mismatched pair is 404 about the PAIR, never 403: knowing that
;;; line 42 exists but belongs to another order is not information this caller is owed, and the
;;; tenant check has already ruled out the case that would matter.
;;;
;;; ⚠ THE SHARED PARAM READERS LIVE IN nst-bl-ordhapi.lisp (ordh-param, ordh-params-without,
;;; ordh-plist-set, ordh-row-id-param, ordh-request-with-row-id-string, ordh-header-from-url,
;;; ordh-request-with-header-row-id, the sort/page guards) and this file uses them rather than
;;; defining a second copy. Both build lists list nst-bl-ordhapi BEFORE this file, so they are
;;; defined when this file compiles. ⚠ It does NOT redefine the HEADER's routes: route-ordh-* and
;;; NstOrdhRequestModel are that file's, and the nested URL is resolved by its resolver.
;;;
;;; REGISTERED BUT DELIBERATELY UNBOUND — route-orditm-list AND route-orditm-fetch. Both are real
;;; Tier-2 verbs, reachable from the internal UI and an :agent caller, and NEITHER is bound to a
;;; path:
;;;
;;;   * THE SPEC DEFINES NO LINE READ. hhub/core/nstoresapi.html (id 'ord') publishes four line
;;;     endpoints — PUT and DELETE on /orders/{id}/items/{item-id} — and no GET of either shape.
;;;     A line is read THROUGH ITS ORDER: route-ordh-detail returns the header plus a nested
;;;     "lines" array, which is exactly what the spec's 'Get complete order details: line items …'
;;;     asks for. Two more bindings would be two more ways to read the same rows, with their own
;;;     scoping rules to keep in step.
;;;   * AND THE BATCH'S PLAN AGREES: S12 names these two as the 'registered-but-unbound'
;;;     pair, and S13's acceptance criterion is that a request to them answers 404 no_such_endpoint
;;;     — i.e. they are absent from the surface ON PURPOSE rather than by omission.
;;;
;;; Load order: AFTER core/nst-bl-adhara.lisp, core/nst-bl-conflodis2.lisp,
;;; core/nst-bl-apidefs2.lisp, order/nst-dal-orditm.lisp, order/nst-bl-ordh.lisp,
;;; order/nst-bl-orditm.lisp and order/nst-bl-ordhapi.lisp (whose param readers and resolver this
;;; file uses). The same three load-order facts the header file records apply: the Belnap sentinel
;;; ferry and the delete ack live in warehouse/nst-bl-whsapi.lisp SECTION 4, and request->dispatch
;;; refuses to carry a control key — which is why the line routes call fetch directly before
;;; dispatching !update.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Params readers specific to a line
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; The :row-id reader is NOT here: ordh-row-id-param / ordh-request-with-row-id-string live in
;;; nst-bl-ordhapi.lisp and are shared, because a line's row-id and a header's hit the same
;;; (id string) specializer and would otherwise need the same guard twice.

(defun orditm-enumerate-args (payload)
  "Filter args for (enumerate 'nst-orditm ctx …) — query arguments of the verb, not nst-orditm
   initargs, so extract-domain-initargs would drop them all.

   :order-id IS THE NORMAL SCOPE: with it, the verb VERIFIES the document first
   (nst-order-item-list → nst-fetch-visible-order-header), so naming an order that does not exist in
   this tenant, or that has been soft-deleted, answers 404 rather than an empty list. Without it the
   list is the whole tenant's lines — deliberately allowed by the verb and safe HERE because this
   route is not bound (see the header): the only reachable line read is the nested one.

   ⚠ THE PAGE ARGUMENTS ARE COERCED because a querystring value is always a string and the verbs'
   own guard signals a plain error for a non-integer — the same 500-for-a-mistyped-page defect the
   header's list route documents. :include-deleted is deliberately NOT exposed, for the reason given
   on route-ordh-list: an external surface must not be handed the switch that un-hides rows नियम-2
   hides."
  (list :order-id     (nst-order-item-id-from-value (ordh-param payload :order-id))
        :status       (ordh-param payload :status)
        :limit        (ordh-page-param (ordh-param payload :limit) "limit")
        :offset       (ordh-page-param (ordh-param payload :offset) "offset" :allow-zero t)
        :sort-by      (or (ordh-keyword-value (ordh-param payload :sort-by)) :row-id)
        :sort-dir     (or (ordh-keyword-value (ordh-param payload :sort-dir)) :asc)))

(defun orditm-guard-sort-args (payload)
  "Refuse an unusable sort-by/sort-dir at the ROUTE layer, as a 400 — the line's own whitelist, read
   from the domain rather than restated: nst-ordh-sort-column takes the whitelist as a PARAMETER
   exactly so the line entity can be validated against its own column set, and it says in its
   docstring that 'a plain `error` here reaches the API as a 500 … The 400 belongs to S12/S13'.
   An absent sort-by is legal and defaults in orditm-enumerate-args."
  (let ((sort-by (ordh-keyword-value (ordh-param payload :sort-by)))
        (sort-dir (ordh-keyword-value (ordh-param payload :sort-dir))))
    (when (and sort-by (not (assoc sort-by *orditm-sort-whitelist*)))
      (api-client-error "sort-by ~S is not sortable here; use one of ~{~A~^, ~}"
                        sort-by (mapcar #'car *orditm-sort-whitelist*)))
    (when (and sort-dir (not (member sort-dir '(:asc :desc))))
      (api-client-error "sort-dir must be asc or desc, got ~S" sort-dir))))

(defun orditm-request-with-parent-row-id (request ctx)
  "REQUEST whose :order-id is the parent's ROW-ID when the URL named the parent BY NUMBER, otherwise
   REQUEST unchanged — a flat line URL names no parent, and substituting one would invent a pairing
   the caller never claimed.

   The nested URL (/{ordnum}/items/{item-id}) carries the order's NUMBER; the verbs and the pairing
   check both work in row-ids. Resolving it here, once, keeps the verbs unchanged — the same shape
   as the header file's resolver, reused rather than re-implemented."
  (if (ordh-param (params request) :ordnum)
      (ordh-request-with-header-row-id request ctx)
      request))

(defun orditm-check-pairing-of (line request ctx)
  "LINE back when the payload's :order-id — if it names one — is the order LINE belongs to;
   otherwise nst-entity-nil (404 about the PAIR).

   Three cases return LINE unchanged, and each is a different reason:
     * no :order-id in the payload — no pairing is being asserted (a flat /lines/{id} URL), so there
       is nothing to disagree with;
     * LINE is a sentinel — it is already the answer, and a missing line is a 404 whether or not a
       parent was named;
     * the ids agree.
   THE COMPARISON IS INTEGER-TO-INTEGER, which is the one thing this cannot copy from the invoice's
   invitm-check-pairing-of verbatim: the payload's :order-id arrives as a STRING (a path parameter,
   and the header resolver deliberately writes it as a string so the ferry's id handling is uniform),
   while the line's own order-id slot is an INTEGER. Comparing them raw would answer 'not a line of
   that order' to every legitimate request. nst-order-item-id-from-value is the domain's own
   coercion for exactly this, and it is used rather than a local parse-integer for the reason its
   docstring gives: an integer IS a well-formed id, from a body or an agent caller, and must not be
   answered 'not a product row-id'."
  (let* ((payload (params request))
         (head-id (nst-order-item-id-from-value (ordh-param payload :order-id))))
    (cond
      ((null head-id) line)
      ((not (typep line 'nst-orditm)) line)
      ((eql (order-id line) head-id) line)
      (t (make-instance 'nst-entity-nil
                        :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                        :reason (format nil "Order line row-id ~A is not a line of order row-id ~A — the pair in the URL does not exist, whatever either id means on its own"
                                        (or (ordh-param payload :row-id) "?") head-id))))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action verbs (Tier 2)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Uniform signature (route-orditm-<action> request ctx), DESIGN §3. All domain law — the parent
;;; proof, the open-only status rule on make/delete!, the no-reassignment rule, the parent-header
;;; reachability check — lives in nst-bl-orditm.lisp, so these verbs stay thin and every caller
;;; shares it.

(defun route-orditm-update (request ctx)
  "कर्म = nst-orditm. Partial update of one line, addressed as /orders/{ordnum}/items/{item-id}.

   FOUR STEPS THE FERRY CANNOT DO, hence the pre-fetch:
     1. the order in the URL is resolved from its NUMBER to its row-id
        (orditm-request-with-parent-row-id → the header file's resolver), so a number this tenant
        cannot see answers 404 before anything else happens;
     2. the row-id is normalised to a string, so !update's (row-id string) method is applicable for
        an agent/batch caller as well as for a path parameter;
     3. the pairing check above — a mismatched pair must 404, not answer !update's 409 'this line is
        being moved';
     4. :order-id is STRIPPED before the ferry, because !update REFUSES it by design (S7 AC d: a line
        does not migrate between orders — moving one changes two orders' contents at once and
        bypasses both headers' status rules). The nested URL puts the parent in the payload, so
        without this every nested PUT would be refused for attempting something it was not
        attempting. The invoice batch measured that exact failure on this exact shape
        (nst-bl-invhapi.lisp:377-383), and the FIX IS NOT to weaken the verb — a verb guard that
        refuses the key its own address carries is what a direct :agent caller needs; the route
        verifies the pair and then removes the claim.

   NO :if-match HERE, AND THAT IS A REAL ASYMMETRY WITH THE HEADER ROUTE — stated rather than left
   to be noticed: the version token is UPDATED of the row, F8's precondition is defined on the
   header (nst-order-header-if-match-refusal), and ITEM rows have no such helper and no version
   policy. Inventing one here would be inventing a contract the domain does not state."
  (let ((resolved (orditm-request-with-parent-row-id request ctx)))
    (if (not (typep resolved 'nst-request-model))
        resolved
        (let* ((req (ordh-request-with-row-id-string resolved))
               (line (fetch 'nst-orditm (ordh-param (params req) :row-id) ctx)))
          (let ((checked (orditm-check-pairing-of line req ctx)))
            (if (not (typep checked 'nst-orditm))
                checked
                (request->dispatch
                 (make-instance 'NstOrditmRequestModel
                                :params (ordh-params-without (params req) :order-id))
                 '!update 'nst-orditm ctx)))))))

(defun route-orditm-delete (request ctx)
  "कर्म = nst-orditm. Soft delete ONE line, and ONLY while its order is still OPEN — the verb checks
   that, not this route (409 above: removing content from a finished order is what a cancellation is
   for). Returns T on success, 404 when the line is absent or the pair does not match, 409 when the
   order is not open.

   ⚠ THE ORDER'S TOTALS ARE NOT ADJUSTED (D13, deliberately): adding, changing or removing a line
   never touches ORDER_AMT/TOTAL_*, and this route does not invent a roll-up. A client that sums the
   lines and a client that reads the header can therefore disagree, and the header is the one the
   API does not recompute — stated here because the difference is otherwise found in production.
   ⚠ AND THIS IS NOT THE HEADER'S लोप: that one (nst-soft-delete-order-items-for-header) removes a
   whole document's lines at once and is called by route-ordh-delete's verb. This deletes one row of
   a document the caller named."
  (let ((resolved (orditm-request-with-parent-row-id request ctx)))
    (if (not (typep resolved 'nst-request-model))
        resolved
        (let* ((req (ordh-request-with-row-id-string resolved))
               (line (fetch 'nst-orditm (ordh-param (params req) :row-id) ctx)))
          (let ((checked (orditm-check-pairing-of line req ctx)))
            (if (not (typep checked 'nst-orditm))
                checked
                (request->dispatch
                 (make-instance 'NstOrditmRequestModel
                                :params (ordh-params-without (params req) :order-id))
                 'delete! 'nst-orditm ctx)))))))

(defun route-orditm-list (request ctx)
  "कर्म = the filtered nst-orditm collection, normally scoped by :order-id, which the verb VERIFIES —
   so 'that order has no lines' and 'there is no such order for you' stay different answers, which an
   empty list would collapse.

   ⚠ REGISTERED BUT DELIBERATELY UNBOUND — see this file's header. The spec publishes no line read,
   and a line reaches the wire through route-ordh-detail's nested array, so binding this would add a
   second way to read the same rows with its own scoping rules to keep in step. It exists for the
   internal UI and :agent callers, which is also why :include-deleted is not exposed but the
   tenant-wide (no :order-id) form is still allowed: the verb keeps it tenant-scoped, and nothing
   outside the process can reach the route."
  (let ((resolved (orditm-request-with-parent-row-id request ctx)))
    (if (not (typep resolved 'nst-request-model))
        resolved
        (progn
          (orditm-guard-sort-args (params resolved))
          (apply #'enumerate 'nst-orditm ctx (orditm-enumerate-args (params resolved)))))))

(defun route-orditm-fetch (request ctx)
  "कर्म = nst-orditm, addressed by :row-id; the payload may also name a parent (:ordnum or :order-id),
   in which case the line must belong to it. ONE SELECT: the pairing is checked on the entity the
   verb already returned. The request is normalised first so the (id string) verb method is always
   applicable — see ordh-row-id-param.

   ⚠ REGISTERED BUT DELIBERATELY UNBOUND, like route-orditm-list and for the same reason."
  (let ((resolved (orditm-request-with-parent-row-id request ctx)))
    (if (not (typep resolved 'nst-request-model))
        resolved
        (let ((req (ordh-request-with-row-id-string resolved)))
          (orditm-check-pairing-of (fetch 'nst-orditm (ordh-param (params req) :row-id) ctx)
                                   req ctx)))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Route registration
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Role/flag/audit metadata is CARRIED, not enforced, in conflodis2 v1 (DESIGN §4.2, D18) —
;;; registered here so it is in one place when the PEP lands. :channel :http is what arms F5's
;;; fail-closed field policy for this entity's callers.

(register-action-route 'route-orditm-update
                       :action-verb 'route-orditm-update
                       :request-class 'NstOrditmRequestModel
                       :description "Partially update one order line, addressed as /orders/{ordnum}/items/{item-id}. The URL's order is resolved by number, the (order, line) pair is verified (a mismatch is 404), and :order-id is stripped before the verb — which refuses it, because a line does not move between orders."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer admin)
                       :feature-flags '(order-domain)
                       :audit-level :full
                       :tags '(order api v1))

(register-action-route 'route-orditm-delete
                       :action-verb 'route-orditm-delete
                       :request-class 'NstOrditmRequestModel
                       :description "Soft-delete one order line, addressed as /orders/{ordnum}/items/{item-id}, and only while its order is OPEN. 409 when the order is finished, 404 when the pair does not match or the line is absent. The order's totals are not adjusted (D13)."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer admin)
                       :feature-flags '(order-domain)
                       :audit-level :full
                       :tags '(order api v1))

(register-action-route 'route-orditm-list
                       :action-verb 'route-orditm-list
                       :request-class 'NstOrditmRequestModel
                       :description "List order lines for the session tenant, normally scoped by order-id (which is verified: a document this tenant cannot see answers 404, not an empty list). Filters: status; whitelisted sort-by/sort-dir; limit/offset. REGISTERED BUT DELIBERATELY UNBOUND — the spec publishes no line read; lines reach the wire through the order detail's nested array."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer admin)
                       :feature-flags '(order-domain)
                       :audit-level :read
                       :tags '(order api v1))

(register-action-route 'route-orditm-fetch
                       :action-verb 'route-orditm-fetch
                       :request-class 'NstOrditmRequestModel
                       :description "Fetch one order line by :row-id; when the payload also names a parent, the line must belong to it (otherwise 404 about the pair). REGISTERED BUT DELIBERATELY UNBOUND — see route-orditm-list."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer admin)
                       :feature-flags '(order-domain)
                       :audit-level :read
                       :tags '(order api v1))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Public API bindings (Ring 4): TWO, AND THAT IS THE WHOLE LINE SURFACE
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; The spec (hhub/core/nstoresapi.html, id 'ord') publishes exactly two line endpoints, and both are
;;; bound here:
;;;
;;;   PUT    /api/v1/orders/{id}/items/{item-id}   'Edit a specific item within a pending order:
;;;                                                 quantity or delivery preference.'
;;;   DELETE /api/v1/orders/{id}/items/{item-id}   'Remove a specific item from a pending order.'
;;;
;;; ⚠ THERE IS NO POST /orders/{ordnum}/items, HERE OR ANYWHERE. Order lines are placed WITH the
;;; order (route-ordh-create's assembly, D14) — the spec defines no line create, D3 plans none, and
;;; the invoice's separate line-create exists because an invoice is assembled against a document that
;;; is already issued. Adding one would give an order two ways to acquire a line, only one of which
;;; writes the vendor rows.
;;;
;;; ⚠ THE BINDINGS LIVE HERE, NOT IN nst-bl-ordhapi.lisp, EVEN THOUGH EVERY PATH BELOW STARTS WITH
;;; /orders/{ordnum}. register-api-route REFUSES a path whose action route is not registered yet
;;; (api-route-bindable-p), and these two routes are registered a few lines above this section — while
;;; nst-bl-ordhapi.lisp is loaded BEFORE this file. That is not a stylistic preference: the refusal
;;; runs at LOAD time, from the other file's own fasl, and aborts the load, so the application does
;;; not come up. The invoice batch measured it —
;;;
;;;   apidefs2: ROUTE-INVITM-CREATE is not a registered action route
;;;
;;; — and the rule every domain's api file follows is: A BINDING LIVES IN THE FILE THAT REGISTERS THE
;;; VERB, whatever the URL looks like. aiharness/deepseek/tools/nst-binding-order-check walks the
;;; build's own file order and asserts it, because neither compile-file nor a name-level audit can see
;;; the difference.
;;;
;;; {ordnum} becomes :ordnum (the ORDER's number) and {item-id} becomes :row-id (the LINE's row-id).
;;; api-params-for-request puts path params ahead of the body, so neither can be displaced by the
;;; payload — which is what makes the pairing check meaningful rather than decorative.

(register-api-route 'route-orditm-update
                    :method :put
                    :path "/hhub/api/v1/orders/{ordnum}/items/{item-id}"
                    :path-params '(("ordnum" . :ordnum) ("item-id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: PUT /api/v1/orders/{id}/items/{item-id} — edit an item on a pending order (quantity, price, discount, tax columns, description). Body: an object of nst-orditm field names; only the fields supplied change. The (order, line) pair is verified: a line that is not this order's answers 404 about the pair, never 403, and a body-supplied order-id is stripped after that check, so it can never move the line to another order. 409 when the order is terminal (the header verb's rule).")

(register-api-route 'route-orditm-delete
                    :method :delete
                    :path "/hhub/api/v1/orders/{ordnum}/items/{item-id}"
                    :path-params '(("ordnum" . :ordnum) ("item-id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: DELETE /api/v1/orders/{id}/items/{item-id} — remove an item from a pending order. Soft delete, and only while the order is OPEN: 409 once the order is finished. 404 when the pair does not match or the line is absent, or when the order cannot be seen in this tenant. The order's totals are NOT adjusted (D13, deliberate). Answers {\"ok\":true,\"operation\":\"delete\"}.")

;;; ───────────────────────────────────────────────────────────────────────────
;;; THE TWO ROUTES WITH NO BINDING, AND WHY THAT IS THE DESIGN RATHER THAN A GAP
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; route-orditm-list and route-orditm-fetch are registered above and bound to NOTHING. A request to
;;; either shape answers 404 no_such_endpoint, which is S13's acceptance criterion and the honest
;;; answer: the endpoint does not exist.
;;;
;;; The reason is the shape of a line's life over HTTP. A line is READ through its order —
;;; GET /orders/{ordnum} returns the header plus a nested "lines" array (route-ordh-detail) — and it
;;; is WRITTEN through the two paths above. There is no request that needs a line addressed on its
;;; own: a client edits a line it just read in the order's array, and it knows both ids from that
;;; same array. Binding the two would add surface with its own scoping rules (the tenant-wide list,
;;; the flat fetch) for no request that exists, and surface nobody asked for is surface nobody keeps
;;; correct.
;;;
;;; ⚠ THEY ARE STILL REAL VERBS, and this is not dead code: conflodis2 routes are the in-tree UI's
;;; and the :agent channel's door as much as HTTP's, and both callers read a line on its own
;;; constantly. Unbound is a statement about the PUBLISHED SURFACE, not about the verb.

;;; End of nst-bl-orditmapi.lisp
