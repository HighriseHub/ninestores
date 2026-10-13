;;; nst-bl-cusinvapi.lisp — CUSTOMER INWARD INVOICE REGISTER — action routes + API
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Design: aiharness/deepseek/skills/knowledge/nst-bl-conflodis2-DESIGN.md
;;;         (§3 verb signature, §5 multi-entity assembly, §6 कारक, §9 file layout)
;;; Dispatcher: hhub/core/nst-bl-conflodis2.lisp   API boundary: hhub/core/nst-bl-apidefs2.lisp
;;;
;;; The register's analogue of warehouse/nst-bl-whsapi.lisp and
;;; invoice/nst-bl-invhapi.lisp:
;;;
;;;   inbound action symbol → (register-action-route 'route-cinv-<action> …)
;;;                         → ONE route-cinv-<action> verb
;;;                         → Tier-1 ferries (request->dispatch … 'nst-cinv)
;;;
;;; Every verb here returns DOMAIN-LAYER results — an nst-cinv, a list of them,
;;; an nst-cinv-itc-summary, or a Belnap sentinel. The dispatcher alone runs the
;;; reverse ferry (domain->response) and the Ring-4 render; no boundary type here.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; ⚠ THIS FILE DEPENDS ON TWO THINGS IT DOES NOT DEFINE
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; 1. THE BELNAP SENTINEL FERRY (domain->response / render-json for the nil/-unknown/
;;;    -contradiction types) lives in whsapi.lisp §4; without it every 404/409/503 here
;;;    dies as NO-APPLICABLE-METHOD. ⚠ Never redefine them: a second method REPLACES it.
;;;
;;; 2. invoice/nst-ui-cusinv.lisp also defines cinv-enumerate-args, and this file does
;;;    NOT reuse it: that one is a one-key page allowlist (?itc only), this one the
;;;    published filter surface, so widening the API cannot widen the UI's reach.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE BUYER COMES FROM THE SESSION AND FROM NOWHERE ELSE
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; नियम-1 covers the TENANT (अधिकरण), built by make-action-domain-ctx from the session
;;; login company; this domain has a SECOND scoping key, the CUSTOMER, since several
;;; customers share a tenant — a tenant-only read would let one guess another's rows.
;;;
;;; So every verb resolves the buyer with cinv-buyer-from-session (nst-bl-cusinv.lisp)
;;; and passes it as :for-buyer; :for-buyer is not an nst-cinv initarg, so the ferry's
;;; extract-domain-initargs can never produce that key from (params request).
;;;
;;; A CALLER WHO IS NOT A CUSTOMER GETS A 404, NOT A WIDER QUERY — the verb returns
;;; nst-entity-nil naming that reason. ⚠ apidefs2 has NO 403 vocabulary (400/401/404,
;;; else 500), so 404 is the closest honest answer; a 403 branch would be a core change.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Params readers (transport-shaped plist, no typed slots)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; apidefs2 normalises query and body KEYS to keywords via api-json-key->param-key
;;; (?itc=… → :ITC, ?sort-by=… → :SORT-BY) but NOT the VALUES, which arrive as the
;;; strings the URL carried — hence the coercions below.

(defun cinv-param (payload key)
  "Read KEY (a keyword query/param name) from PAYLOAD.
   Accepts a keyword-keyed plist (conflodis2/agent callers) or a string-keyed
   plist (a JSON body or querystring read directly)."
  (or (getf payload key)
      (getf payload (string-downcase (symbol-name key)))))

(defun cinv-keyword-value (value)
  "Coerce an inbound scalar to the keyword form the domain expects —
   \"desc\"/\"DESC\"/'desc → :DESC. Non-scalars pass through."
  (cond ((null value) nil)
        ((keywordp value) value)
        ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
        ((stringp value) (intern (string-upcase value) :keyword))
        (t value)))

(defun cinv-api-itc-filter (payload)
  "The :itc filter for this request, or NIL when none was asked for. ⚠ An UNRECOGNISED
  value is a 400, unlike the page, which falls back to :all and SHOWS it; an API client
  sees no such display, so a filter it never got must be reported. :at-risk passes to 503."
  (let ((raw (cinv-param payload :itc)))
    (when raw
      (let ((value (cinv-keyword-value raw)))
        (unless (member value '(:all :claimable :claimed :at-risk))
          (api-client-error "itc must be one of all, claimable, claimed or at-risk; got ~S" raw))
        value))))

(defun cinv-guard-sort-args (payload)
  "Refuse an unusable sort-by / sort-dir at the ROUTE layer, as a 400. 🚨 The domain
  whitelist signals a PLAIN ERROR, which api-status-for-condition answers as 500, so
  ?sort-by=password would read as a crash. It reads the same *cinv-sort-whitelist*."
  (let ((sort-by  (cinv-keyword-value (cinv-param payload :sort-by)))
        (sort-dir (cinv-keyword-value (cinv-param payload :sort-dir))))
    (when (and sort-by (not (assoc sort-by *cinv-sort-whitelist*)))
      (api-client-error "sort-by ~S is not sortable here; use one of ~{~A~^, ~}"
                        sort-by (mapcar #'car *cinv-sort-whitelist*)))
    (when (and sort-dir (not (member sort-dir '(:asc :desc))))
      (api-client-error "sort-dir must be asc or desc, got ~S" sort-dir))))

(defun cinv-integer-param (payload key)
  "KEY's value as an integer, NIL when absent, or a 400 when it is not a whole number.
  🚨 NOT (parse-integer v :junk-allowed t): that returns NIL for \"abc\", the filter
  decays to NIL and ?vendor-id=abc returned the WHOLE UNFILTERED REGISTER unnoticed."
  (let ((v (cinv-param payload key)))
    (cond
      ((null v) nil)
      ((integerp v) v)
      ((stringp v)
       (let* ((trimmed (string-trim '(#\Space #\Tab) v))
              (end (length trimmed)))
         (if (zerop end)
             nil
             (multiple-value-bind (n parsed-to) (parse-integer trimmed :junk-allowed t)
               (unless (and n (= parsed-to end))
                 (api-client-error "~A must be a whole number, got ~S"
                                   (string-downcase (symbol-name key)) v))
               n))))
      (t (api-client-error "~A must be a whole number, got ~S"
                           (string-downcase (symbol-name key)) v)))))

(defun cinv-api-enumerate-args (payload buyer-id)
  "Filter args for (enumerate 'nst-cinv ctx …) — QUERY arguments, not nst-cinv initargs,
  so extract-domain-initargs would drop every one (buyer is a parameter; see header).
  from/to-date pass through raw strings; :vendor-id refuses a non-numeric value."
  (list :for-buyer            buyer-id
        :itc                  (or (cinv-api-itc-filter payload) :all)
        :vendor-id            (cinv-integer-param payload :vendor-id)
        :payment-status       (cinv-param payload :payment-status)
        :gstr2b-match-status  (cinv-param payload :gstr2b-match-status)
        :invoice-status       (cinv-param payload :invoice-status)
        :gst-period           (cinv-param payload :gst-period)
        :invoice-number-like  (cinv-param payload :invoice-number-like)
        :from-date            (cinv-param payload :from-date)
        :to-date              (cinv-param payload :to-date)
        :sort-by              (or (cinv-keyword-value (cinv-param payload :sort-by)) :invoice-date)
        :sort-dir             (or (cinv-keyword-value (cinv-param payload :sort-dir)) :desc)))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action verbs (Tier 2)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; Signature is fixed by DESIGN §3: (route-cinv-<action> request ctx); plain defuns,
;;; not generics — dispatch-action resolves them with fdefinition. No domain law lives
;;; here: derivation, scoping and the four-valued answers are all nst-bl-cusinv.lisp's.

(defun cinv-ctx-tenant-id (ctx)
  "The अधिकरण integer from ctx — needed only to build a sentinel, which requires
   a tenant-id of its own (nst-domain-entity declares it)."
  (slot-value (domain-ctx-tenant ctx) 'row-id))

(defun cinv-route-buyer ()
  "The session's customer row-id, or NIL. A named seam so that the rule — the buyer is
   read from the session and NEVER from the payload — has one place to audit here."
  (cinv-buyer-from-session))

(defun cinv-no-buyer-sentinel (ctx)
  "The answer for a caller with no customer session: a :F fact, not a wider query.
   See the file header for why this is a 404 and not a 403."
  (make-instance 'nst-entity-nil
                 :tenant-id (cinv-ctx-tenant-id ctx)
                 ;; ⚠ CLIENT-VISIBLE, so no internal vocabulary here: not "नियम-1",
                 ;; not "tenant", not a table or class name. This sentence travels to
                 ;; the caller in the JSON "reason" field of a 404.
                 :reason "No customer is signed in on this session, so there is no inward invoice register to read. This register belongs to one customer account; a vendor or operator session does not have one, and no wider view of it is available."))

(defun route-cinv-list (request ctx)
  "कर्म = the filtered nst-cinv collection (one Tier-1 read). Calls enumerate DIRECTLY,
   not via the ferry: every filter — :for-buyer, :itc, :vendor-id, the sort — is a QUERY
   arg extract-domain-initargs would drop, leaving no buyer. Empty register = 200 []."
  (let ((buyer (cinv-route-buyer)))
    (if (null buyer)
        (cinv-no-buyer-sentinel ctx)
        (progn
          (cinv-guard-sort-args (params request))
          (apply #'enumerate 'nst-cinv ctx
                 (cinv-api-enumerate-args (params request) buyer))))))

(defun route-cinv-detail (request ctx)
  "कर्म = ONE nst-cinv, addressed by INVOICE_ID. THIS ONE DOES RIDE THE FERRY, the only
   verb here that can: fetch takes (entity-class id ctx) and there are no query args to
   lose. The buyer is resolved INSIDE the fetch verb, so no cross-customer read by id."
  (let ((invoice-id (rm-row-id request)))
    (if (or (null invoice-id) (string= "" (string-trim " " (format nil "~A" invoice-id))))
        (api-client-error "the invoice id is missing from the request path")
        (request->dispatch request 'fetch 'nst-cinv ctx))))

(defun route-cinv-itc-summary (request ctx)
  "कर्म = the nst-cinv-itc-summary fact. ⚠ IGNORES EVERY FILTER, INCLUDING ?itc=, BY
   DESIGN: summarize-itc reduces over unfiltered enumerate, so card and collection cannot
   disagree; an unreadable register yields the same nst-entity-unknown → 503, not zeroes."
  (let ((buyer (cinv-route-buyer)))
    (if (null buyer)
        (cinv-no-buyer-sentinel ctx)
        (apply #'summarize-itc 'nst-cinv ctx (list :for-buyer buyer)))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — action-route registrations (conflodis2, Ring 2/3)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; required-roles / feature-flags / audit-level are CARRIED but NOT enforced by
;;; conflodis2 v1 (DESIGN §4.2, §11.1) — registered now so the metadata sits in
;;; one place when the PEP/ABAC seam lands.
;;;
;;; Also NOT wired: *action-route-transaction-function* defaults to a pass-through, so
;;; an API route runs no with-hhub-transaction wrapper — the state of every API route in
;;; this tree, not a choice made here (the UI page calls with-hhub-transaction itself).

(register-action-route 'route-cinv-list
                       :action-verb 'route-cinv-list
                       :request-class 'NstCinvRequestModel
                       :description "List the signed-in customer's INWARD invoice register, with the ITC position. Filters: itc (all/claimable/claimed/at-risk), vendor-id, payment-status, gstr2b-match-status, invoice-status, gst-period, invoice-number-like, from-date, to-date; whitelisted sort-by/sort-dir (default invoice-date desc)."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer)
                       :feature-flags '(customer-invoice-register itc)
                       :audit-level :read
                       :tags '(customer invoice itc gstr2b api v1))

(register-action-route 'route-cinv-detail
                       :action-verb 'route-cinv-detail
                       :request-class 'NstCinvRequestModel
                       :description "One inward invoice by INVOICE_ID, scoped to the signed-in customer AND the session tenant. 404 when it is not in this customer's register; 503 when the boundary could not be reached."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer)
                       :feature-flags '(customer-invoice-register itc)
                       :audit-level :read
                       :tags '(customer invoice itc gstr2b api v1))

(register-action-route 'route-cinv-itc-summary
                       :action-verb 'route-cinv-itc-summary
                       :request-class 'NstCinvRequestModel
                       :description "The customer's ITC position over the whole register: invoices, claimable, claimed, atRisk, purchases. Unfiltered by design — it is a reduction over the same read the list endpoint performs, so the two can never disagree. atRisk is null (not determined), never 0, because nothing in this database records it."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer)
                       :feature-flags '(customer-invoice-register itc)
                       :audit-level :read
                       :tags '(customer invoice itc gstr2b api v1))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — API bindings (apidefs2, Ring 4)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; A binding MUST follow the register-action-route of the verb it names in LOAD ORDER:
;;; register-api-route refuses a path whose action route is not already registered
;;; (api-route-bindable-p), so both halves live here, in this order.
;;;
;;; ⚠ THE PATHS ARE UNDER /customer/ AND THAT IS THE WHOLE NAMESPACING DECISION: the
;;; vendor-side API already owns /hhub/api/v1/invoices and /invoices/{id}, and these are
;;; the BUYER's view (one customer, two predicates), not reachable as the vendor surface.
;;;
;;; ⚠ NO :inject-company, for the reason invhapi records: nst-cinv has no legacy COMPANY
;;; slot — its tenant is the inherited tenant-id the ferry sets from domain-ctx (built by
;;; make-action-domain-ctx from the session login company), so :company would be undeclared.
;;;
;;; ⚠ THREE DISTINCT SHAPES, NO RANKING QUESTION: two five-segment LITERALS (…/invoices,
;;; …/itc-summary) and one six-segment parametric (…/invoices/{id}) — the parametric
;;; one stands alone, so find-api-route's literal-over-parameter ranking never fires.
;;;
;;; Path ids are numeric row-ids, as everywhere in this tree: {id} is the INVOICE's id
;;; (DOD_INVOICE_HEADER.ROW_ID / the view's INVOICE_ID). api-params-for-request puts path
;;; params ahead of body and query, so a client cannot displace the address via payload.

(register-api-route 'route-cinv-list
                    :method :get
                    :path "/hhub/api/v1/customer/invoices"
                    :success-status 200
                    :auth-scope :session
                    :description "The signed-in CUSTOMER's inward invoice register. Query params: itc (all|claimable|claimed|at-risk), vendor-id, payment-status, gstr2b-match-status, invoice-status, gst-period, invoice-number-like, from-date (YYYY-MM-DD), to-date, sort-by, sort-dir. Each row carries itcRecorded (the ledger column), itcDerived (computed from the invoice's own line items) and itcAmount (the effective figure). An empty register is 200 with [] — never 404, and never null. 400 for an unusable itc/sort-by/sort-dir; 404 when no customer is signed in; 503 when itc=at-risk is asked for, because the data that would decide it does not exist.")

(register-api-route 'route-cinv-detail
                    :method :get
                    :path "/hhub/api/v1/customer/invoices/{id}"
                    :path-params '(("id" . :row-id))
                    :success-status 200
                    :auth-scope :session
                    :description "One inward invoice from the signed-in customer's register, by numeric INVOICE_ID. 404 when it is not in this customer's register — which covers another customer's invoice inside the SAME tenant, another tenant's, and a row the vendor soft-deleted (the view's own predicates hide that case); 503 (not 404) when the database could not be reached, because absence and ignorance are different answers.")

(register-api-route 'route-cinv-itc-summary
                    :method :get
                    :path "/hhub/api/v1/customer/itc-summary"
                    :success-status 200
                    :auth-scope :session
                    :description "The signed-in customer's ITC position over the whole register: {invoices, claimable, claimed, atRisk, atRiskReason, purchases}. Unfiltered by design. claimable is summed from the invoices' own line-item tax, not from DOD_INVOICE_HEADER.ITC_AMOUNT — that column is NULL on every row because nothing writes it. atRisk is null and atRiskReason says why; rendering null as 0 is the defect this field exists to prevent. 404 when no customer is signed in; 503 when the register could not be read.")
