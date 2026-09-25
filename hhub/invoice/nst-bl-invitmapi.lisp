;;; nst-bl-invitmapi.lisp — INVOICE LINE ACTION ROUTES (conflodis2 Tier 2, Ring 2/3)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Design: aiharness/deepseek/skills/knowledge/nst-bl-conflodis2-DESIGN.md (§3, §5, §6)
;;; Dispatcher: hhub/core/nst-bl-conflodis2.lisp
;;;
;;; The line-side counterpart of invoice/nst-bl-invhapi.lisp. Same contract: an
;;; inbound action symbol → (register-action-route 'route-invitm-<action> …) → ONE
;;; action verb → Tier-1 ferries (request->dispatch … 'nst-invitm). Domain-layer
;;; results only; the dispatcher does the reverse ferry and the render.
;;;
;;; ⚠ A LINE IS ADDRESSED UNDER ITS DOCUMENT, AND THESE ROUTES ENFORCE THE PAIRING.
;;; The verbs in nst-bl-invitm.lisp already prove the header exists in the session
;;; tenant before touching a line. What they cannot know is whether the caller named
;;; the RIGHT parent: a nested URL (PUT /invoice/7/lines/42) carries two ids, and
;;; answering it requires agreeing that line 42 really is a line of invoice 7.
;;; invitm-check-pairing-of does that, and its absence would show up as a lie rather
;;; than a failure — !update on a mismatched pair would return 409 "a line does not
;;; move between documents", which is a true rule answering an untrue question.
;;;
;;; ⚠ THE SHARED PARAM READERS LIVE IN nst-bl-invhapi.lisp (inv-param,
;;; inv-keyword-value, inv-params-without) and this file uses them rather than
;;; defining a fifth copy of the same three functions. nstores.asd lists
;;; nst-bl-invhapi.lisp first, so they are defined when this file compiles.
;;;
;;; Depends on the same three load-order facts as the header file: the Belnap
;;; sentinel ferry and the delete ack live in warehouse/nst-bl-whsapi.lisp
;;; SECTION 4, and request->dispatch cannot carry ?exists. See that file's header.
;;;
;;; Load order: AFTER core/nst-bl-adhara.lisp, core/nst-bl-conflodis2.lisp,
;;; core/nst-bl-apidefs2.lisp, invoice/nst-dal-invitm.lisp,
;;; invoice/nst-bl-invitm.lisp and invoice/nst-bl-invhapi.lisp.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Params readers specific to a line
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; The :row-id reader is NOT here: inv-row-id-param / inv-request-with-row-id-string
;;; live in nst-bl-invhapi.lisp and are shared, because a line's row-id and a header's
;;; hit the same (id string) specializer and would otherwise need the same guard twice.

(defun invitm-enumerate-args (payload)
  "Filter args for (enumerate 'nst-invitm ctx …) — query arguments of the verb, not
   nst-invitm initargs, so extract-domain-initargs would drop them all.

   :invheadid is the normal scope: with it, the verb VERIFIES the document first, so
   naming an invoice that does not exist in this tenant answers 404 rather than an
   empty list. Without it the list is the whole tenant's lines, which is what a
   rate-wise summary across invoices reads. :include-deleted is exposed because an
   edited invoice's history — what was on it before — is an audit question, and it
   is the one caller that may see soft-deleted lines."
  (list :invheadid       (invitm-id-from-value (inv-param payload :invheadid))
        :status          (inv-param payload :status)
        :include-deleted (inv-param payload :include-deleted)
        :sort-by         (or (inv-keyword-value (inv-param payload :sort-by)) :row-id)
        :sort-dir        (or (inv-keyword-value (inv-param payload :sort-dir)) :asc)))

(defun invitm-check-pairing-of (line request ctx)
  "LINE back when the payload's :invheadid — if it names one — is the header LINE
   belongs to; otherwise nst-entity-nil.

   Three cases return LINE unchanged, and each is a different reason:
     * no :invheadid in the payload — no pairing is being asserted (a flat
       /lines/{id} URL), so there is nothing to disagree with;
     * LINE is a sentinel — it is already the answer, and a missing line is a 404
       whether or not a parent was named;
     * the ids agree.
   A named parent that disagrees is a 404 about the PAIR, which is what the caller
   got wrong. It is deliberately not a 403: knowing that line 42 exists but belongs
   elsewhere is not information this tenant's caller is owed, and the tenant check in
   the verb has already ruled out the case that would matter."
  (let* ((payload (params request))
         (head-id (invitm-id-from-value (inv-param payload :invheadid))))
    (cond
      ((null head-id) line)
      ((not (typep line 'nst-invitm)) line)
      ((eql (invheadid line) head-id) line)
      (t (make-instance 'nst-entity-nil
                        :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                        :reason (format nil "Invoice line row-id ~A is not a line of invoice header row-id ~A"
                                        (or (inv-param payload :row-id) "?") head-id))))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action verbs (Tier 2)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Uniform signature (route-invitm-<action> request ctx), DESIGN §3. All domain law
;;; — the parent check, the DRAFT-only status rule, the no-reassignment rule — lives
;;; in nst-bl-invitm.lisp, so these verbs stay thin and every caller shares it.

(defun route-invitm-create (request ctx)
  "कर्म = nst-invitm. Add a line to a DRAFT invoice. :invheadid is REQUIRED in the
   payload; the verb locates that header in the SESSION tenant and refuses with
   nst-entity-nil when it cannot be seen, so a guessed id cannot add rows to another
   tenant's invoice (BOLA), and with nst-entity-contradiction when the invoice is no
   longer a DRAFT. No :around uniqueness check exists: the same product twice on one
   invoice is legitimate."
  (request->dispatch request 'make 'nst-invitm ctx))

(defun route-invitm-fetch (request ctx)
  "कर्म = nst-invitm, addressed by :row-id; the payload may also name :invheadid, in
   which case the line must belong to it. ONE SELECT: the pairing is checked on the
   entity the ferry already returned. The request is normalised first so the (id
   string) verb method is always applicable — see inv-row-id-param."
  (let ((req (inv-request-with-row-id-string request)))
    (invitm-check-pairing-of (request->dispatch req 'fetch 'nst-invitm ctx)
                             req ctx)))

(defun route-invitm-update (request ctx)
  "कर्म = nst-invitm. Partial update of one line.

   THREE STEPS THE FERRY CANNOT DO — hence the pre-fetch:
     1. the row-id is normalised to a string, so !update's (row-id string) method is
        applicable for an agent/batch caller as well as for a path parameter;
     2. the pairing check above (a mismatched parent must 404, not answer !update's
        409 'this line is being moved');
     3. :invheadid is STRIPPED before the ferry, because !update refuses it by design.
        The nested URL puts the parent in the payload, so without this every nested
        PUT would be refused for attempting something it was not attempting. What
        !update sees is then the same payload a flat /lines/{id} URL would have
        produced."
  (let* ((req (inv-request-with-row-id-string request))
         (line (fetch 'nst-invitm (inv-param (params req) :row-id) ctx)))
    (let ((checked (invitm-check-pairing-of line req ctx)))
      (if (not (typep checked 'nst-invitm))
          checked
          (request->dispatch
           (make-instance 'NstInvitmRequestModel
                          :params (inv-params-without (params req) :invheadid))
           '!update 'nst-invitm ctx)))))

(defun route-invitm-delete (request ctx)
  "कर्म = nst-invitm. Soft delete one line, and ONLY while its document is still a
   DRAFT — the verb checks that, not this route. Returns T on success, 404 when the
   line is absent, 409 when the invoice has been issued. The header's TOTALVALUE is
   not adjusted (documented gap in the प्रत्यय layer); delete! here does NOT go
   through the header's own लोप, which removes a whole document's lines at once.
   The row-id is normalised for the same reason as in update."
  (let* ((req (inv-request-with-row-id-string request))
         (line (fetch 'nst-invitm (inv-param (params req) :row-id) ctx)))
    (let ((checked (invitm-check-pairing-of line req ctx)))
      (if (not (typep checked 'nst-invitm))
          checked
          (request->dispatch req 'delete! 'nst-invitm ctx)))))

(defun route-invitm-list (request ctx)
  "कर्म = the filtered nst-invitm collection, normally scoped by :invheadid — see
   invitm-enumerate-args. enumerate takes the filters directly; they are query
   arguments, not entity initargs, so the ferry would drop them. Zero lines is a
   SUCCESS with an empty list, not a 404."
  (apply #'enumerate 'nst-invitm ctx (invitm-enumerate-args (params request))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Route registration
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Role/flag/audit metadata is CARRIED, not enforced, in conflodis2 v1
;;; (DESIGN §4.2) — registered here so it is in one place when the PEP lands.

(register-action-route 'route-invitm-create
                       :action-verb 'route-invitm-create
                       :request-class 'NstInvitmRequestModel
                       :description "Add a line to a DRAFT invoice for the session tenant. Requires invheadid; the header is located in the session tenant before anything is written."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :full
                       :tags '(invoice api v1))

(register-action-route 'route-invitm-fetch
                       :action-verb 'route-invitm-fetch
                       :request-class 'NstInvitmRequestModel
                       :description "Fetch one invoice line by :row-id. When the payload also names :invheadid, the line must belong to that invoice, otherwise 404."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :read
                       :tags '(invoice api v1))

(register-action-route 'route-invitm-update
                       :action-verb 'route-invitm-update
                       :request-class 'NstInvitmRequestModel
                       :description "Partially update one invoice line by :row-id. :invheadid in the payload is a scope claim, verified and then stripped — it can never move the line."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :full
                       :tags '(invoice api v1))

(register-action-route 'route-invitm-delete
                       :action-verb 'route-invitm-delete
                       :request-class 'NstInvitmRequestModel
                       :description "Soft-delete one invoice line by :row-id, only while its invoice is a DRAFT. 409 when the invoice has been issued."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :full
                       :tags '(invoice api v1))

(register-action-route 'route-invitm-list
                       :action-verb 'route-invitm-list
                       :request-class 'NstInvitmRequestModel
                       :description "List invoice lines for the session tenant, normally scoped by invheadid (which is verified: a document this tenant cannot see answers 404, not an empty list). Filters: status, include-deleted; whitelisted sort-by/sort-dir (default row-id asc)."
                       :output-type :json
                       :channel :http
                       :required-roles '(vendor admin)
                       :feature-flags '(invoice-domain)
                       :audit-level :read
                       :tags '(invoice api v1))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Public API bindings (Ring 4)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; These live HERE, not in nst-bl-invhapi.lisp, even though every path below starts
;;; with /invoices/{id}: register-api-route REFUSES a path whose action route is not
;;; registered yet (api-route-bindable-p), and these three routes are registered a few
;;; lines above this section — while nst-bl-invhapi.lisp loads BEFORE this file.
;;; Binding them there failed the first full build with
;;;
;;;   apidefs2: ROUTE-INVITM-CREATE is not a registered action route
;;;
;;; raised from that file's fasl at load time. The rule, and it is the one every other
;;; domain's api file already follows: A BINDING LIVES IN THE FILE THAT REGISTERS THE
;;; VERB, whatever the URL looks like.
;;;
;;; Neither offline check could have seen this — compile-file does not evaluate the
;;; registrations, and a name-level audit of "is every bound route registered
;;; somewhere" answers yes. Only ORDER fails, and only a real load proves it.
;;;
;;; The spec paths (hhub/core/nstoresapi.html) are the PUBLIC paths; the templates
;;; carry the /hhub prefix the deployed nginx needs — see SECTION 5 of
;;; nst-bl-invhapi.lisp for the full note.
;;;
;;; {id} is the INVOICE's row-id and becomes :invheadid; {item-id} is the LINE's and
;;; becomes :row-id. api-params-for-request puts path params ahead of the body, so
;;; neither can be displaced by the payload — which is what makes the route layer's
;;; (header, line) pairing check meaningful rather than decorative.

(register-api-route 'route-invitm-create
                    :method :post
                    :path "/hhub/api/v1/invoices/{id}/items"
                    :path-params '(("id" . :invheadid))
                    :success-status 201
                    :auth-scope :session
                    :description "Spec: POST /api/v1/invoices/{id}/items — add a product line item. The invoice in the URL is located in the session tenant first (404 if it is not this tenant's, 409 if it is no longer a DRAFT). Body: nst-invitm initarg names (prd-id, prddesc, hsncode, qty, uom, price, discount, the tax rate/amount columns).")

(register-api-route 'route-invitm-update
                    :method :put
                    :path "/hhub/api/v1/invoices/{id}/items/{item-id}"
                    :path-params '(("id" . :invheadid) ("item-id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: PUT /api/v1/invoices/{id}/items/{item-id} — update a line's quantity, unit price, discount or description. The pair is verified: a line that does not belong to the named invoice answers 404, and :invheadid is stripped before the verb, so it can never move the line to another document.")

(register-api-route 'route-invitm-delete
                    :method :delete
                    :path "/hhub/api/v1/invoices/{id}/items/{item-id}"
                    :path-params '(("id" . :invheadid) ("item-id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: DELETE /api/v1/invoices/{id}/items/{item-id} — remove a line. Soft delete; 409 while the invoice is not a DRAFT, 404 when the pair does not match or the line is absent. The header's total is NOT adjusted (documented gap).")

;;; End of nst-bl-invitmapi.lisp
