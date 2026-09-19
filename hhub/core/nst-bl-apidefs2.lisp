;;; nst-bl-apidefs2.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; THE API BOUNDARY — Ring 4 (HTTP/JSON) → Ring 3 (conflodis2 action routes).
;;;
;;; Design: aiharness/deepseek/skills/nst-bl-conflodis2-DESIGN.md; conventions of
;;; hhub/core/nstoresapi.html and the *api.lisp route files.
;;;
;;; The API adds TRANSPORT, never business routes. An endpoint is a binding
;;; from (HTTP method, path template) to an ALREADY-REGISTERED route-* action
;;; verb, so an external call and the internal website handler land on the
;;; same Tier-2 verb and the same Tier-1 ferries:
;;;
;;;   PUT /hhub/api/v1/warehouse/42   ─┐
;;;   /hhub/vupdatewarehouseaction ────┴→ route-warehouse-update → !update ∘ nst-whs
;;;
;;; URL convention:
;;;   METHOD /hhub/api/v1/{domain}/{resource}[/{id}][/{sub-action}]
;;; The HTTP method carries the verb; a {sub-action} segment (approve, reject,
;;; status, …) is reserved for genuine state transitions, not for updates.
;;;
;;; WHY THE /hhub PREFIX IS PART OF THE PATH: the deployed nginx
;;; (sites-available/highrisehub.com) proxies `location /hhub/` straight to the
;;; acceptor but rewrites every other URI to /hhub/$1. A path that already
;;; starts with /hhub therefore arrives UNCHANGED, which is what makes the
;;; endpoint template and the acceptor's own URL the same string. If nginx
;;; later gains a dedicated `location /api/ { proxy_pass http://hunchentoot; }`,
;;; the prefix can be dropped from the templates and the dispatcher regex in
;;; one pass — nothing else in this file depends on it.
;;;
;;; कारक / नियम-1: the tenant (अधिकरण) is NEVER taken from the payload.
;;; dispatch-route2 builds it from the login company established by the
;;; inbound CREDENTIAL — see SECTION 4, the one seam that changes when bearer
;;; API keys land. extract-domain-initargs strips :tenant-id regardless.
;;;
;;; Load order: AFTER core/nst-bl-conflodis2.lisp (which itself follows adhara).
;;; Depends on: dispatch-route2, *action-route-registry*, conflodis2-login-company,
;;;             render-json, make-domain-ctx, nst-response-nil/-unknown/-contradiction,
;;;             json:decode-json-from-string / json:encode-json-to-string, hunchentoot.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 1 — The api-route record (a BINDING, not a business route)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; An api-route owns no domain knowledge. It says only: this method + this
;;; path template dispatches to that already-registered action verb, and this
;;; path segment feeds that params key.

(defclass api-route ()
  ((route-key
    :initarg :route-key :accessor api-route-key
    :documentation "The route-* symbol already registered with register-action-route.")
   (http-method
    :initarg :http-method :accessor api-route-method :initform :get
    :documentation ":GET / :PUT / :POST / :DELETE — the verb of the URL.")
   (path
    :initarg :path :accessor api-route-path
    :documentation "Template such as \"/hhub/api/v1/warehouse/{id}\". {name} matches exactly one segment.")
   (path-params
    :initarg :path-params :accessor api-route-path-params :initform nil
    :documentation "Alist (segment-name . params-key), e.g. ((\"id\" . :row-id)).
                    The params key is the name the Tier-1 ferry reads.")
   (success-status
    :initarg :success-status :accessor api-route-success-status :initform 200
    :documentation "200 for update/fetch, 201 for create.")
   (auth-scope
    :initarg :auth-scope :accessor api-route-auth-scope :initform :session
    :documentation "Credential kind — see SECTION 4. :session today, :bearer later.")
   (inject-company
    :initarg :inject-company :accessor api-route-inject-company :initform nil
    :documentation "T = the authenticated session company (अधिकरण) is injected
                    into the params as :company before dispatch.
                    WHY THIS EXISTS: some domain entities predate nst-domain-entity
                    and carry a legacy COMPANY slot alongside the inherited
                    TENANT-ID (nst-whs is one: nst-dal-warehouse.lisp declares
                    :company, and copyWarehouse-domaintodb derives the DB row's
                    tenant from it). The internal website callers satisfy that
                    slot explicitly, but a JSON body must NEVER carry it — the
                    company IS the session tenant (नियम-1), not client input.
                    Injection is therefore OPT-IN PER ROUTE, not global: an
                    entity that does not declare :company would reject the
                    unknown initarg, and the dispatcher stays entity-agnostic.
                    Only routes whose Tier-1 verb reads the slot set this.")
   (description :initarg :description :accessor api-route-description :initform nil)
   (active :initarg :active :accessor api-route-active :initform t))
  (:documentation
   "One API endpoint: an HTTP binding onto an existing route-* action verb."))

(defparameter *api-route-registry* '()
  "List of api-route instances, newest first. Linear scan is deliberate: the
   table is small, and a path-template match is not a hash lookup.")

(defun api-route-bindable-p (route-key)
  (and (gethash route-key *action-route-registry*) t))

(defun register-api-route (route-key &key (method :get) path path-params
                                      (success-status 200) (auth-scope :session)
                                      inject-company
                                      description (active t))
  "Bind (METHOD, PATH) to the action route ROUTE-KEY. Returns ROUTE-KEY.

   Refuses to create an endpoint whose action verb does not exist: an API
   surface that points at an unregistered verb is a Ring-3 registration
   mistake, and failing here is the same discipline as find-action-route."
  (unless (api-route-bindable-p route-key)
    (error "apidefs2: ~S is not a registered action route. Call ~
            (register-action-route '~S) before binding an API path to it."
           route-key route-key))
  (unless (api-path-deployment-prefix-p path)
    (error "apidefs2: ~S path template must start with \"/hhub/\" (got ~S) — the ~
            deployed nginx rewrites every other URI, so a template without the ~
            prefix would be unreachable through the proxy."
           route-key path))
  (unless (member method '(:get :put :post :delete :patch))
    (error "apidefs2: ~S has unsupported HTTP method ~S." route-key method))
  ;; A DIFFERENT action route claiming the same method+path is a real conflict.
  (dolist (existing *api-route-registry*)
    (when (and (eq (api-route-method existing) method)
               (string-equal (api-route-path existing) path)
               (not (eq (api-route-key existing) route-key)))
      (error "apidefs2: ~A ~A is already bound to ~S."
             method path (api-route-key existing))))
  ;; Re-registering the SAME route-key is idempotent, exactly like
  ;; register-action-route: domain files are re-evaluated on every reload, and
  ;; a binding that cannot be replaced would make its own file un-loadable.
  (setf *api-route-registry*
        (remove-if (lambda (r)
                     (and (eq (api-route-method r) method)
                          (string-equal (api-route-path r) path)
                          (eq (api-route-key r) route-key)))
                   *api-route-registry*))
  (push (make-instance 'api-route
                       :route-key route-key
                       :http-method method
                       :path path
                       :path-params path-params
                       :success-status success-status
                       :auth-scope auth-scope
                       :inject-company inject-company
                       :description description
                       :active active)
        *api-route-registry*)
  route-key)

(defun list-api-routes ()
  "Diagnostic — every bound endpoint as (METHOD PATH ROUTE-KEY)."
  (mapcar (lambda (r) (list (api-route-method r) (api-route-path r) (api-route-key r)))
          (reverse *api-route-registry*)))

(defun api-path-deployment-prefix-p (path)
  "True when PATH already starts with the deployment prefix (/hhub).
   Path templates carry it, so the inbound path — which nginx passes through
   unchanged for /hhub/ URIs — matches a template as-is. This predicate exists
   only so register-api-route can reject a template that omits the prefix and
   would therefore be unreachable through the deployed proxy."
  (and (stringp path)
       (>= (length path) 6)
       (string-equal "/hhub/" (subseq path 0 6))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 2 — Path template matching
;;; ═══════════════════════════════════════════════════════════════════════

(defun api-path-segments (path)
  "Split PATH on / , dropping empty segments and any ?query / #fragment."
  (when (stringp path)
    (let* ((cut (or (position-if (lambda (c) (or (char= c #\?) (char= c #\#))) path)
                    (length path)))
           (clean (subseq path 0 cut))
           (segs '())
           (start 0))
      (dotimes (i (length clean))
        (when (char= (char clean i) #\/)
          (let ((s (subseq clean start i)))
            (unless (string= s "") (push s segs)))
          (setf start (1+ i))))
      (let ((s (subseq clean start)))
        (unless (string= s "") (push s segs)))
      (nreverse segs))))

(defun api-param-segment-p (segment)
  (and (> (length segment) 2)
       (char= (char segment 0) #\{)
       (char= (char segment (1- (length segment))) #\})))

(defun api-param-segment-name (segment)
  (subseq segment 1 (1- (length segment))))

(defun api-match-route (route segments)
  "Does ROUTE's template match SEGMENTS?
   → (values T matched-params-alist) on a match, NIL otherwise."
  (let ((template (api-path-segments (api-route-path route)))
        (found '()))
    (when (= (length template) (length segments))
      (loop for tpl in template
            for seg in segments
            do (cond ((api-param-segment-p tpl)
                      (push (cons (api-param-segment-name tpl) seg) found))
                     ((string-equal tpl seg))
                     (t (return-from api-match-route nil))))
      (values t (nreverse found)))))

(defun api-route-param-count (route)
  "How many path segments of ROUTE's template are {parameters}.
   Zero means every segment is literal."
  (count-if #'api-param-segment-p (api-path-segments (api-route-path route))))

(defun find-api-route (method path)
  "→ (values api-route path-param-alist), or (values NIL NIL).

   LITERAL SEGMENTS WIN OVER PARAMETERS. This used to return the FIRST template
   that matched while *api-route-registry* is scanned newest-first, so the answer
   depended on registration order: GET /catalog/products/{id} also matches
   /catalog/products/template, and whichever of the two happened to be registered
   later decided whether 'template' was read as an id. A mistyped literal segment
   would silently become a parameter and reach the domain as a row-id.

   Candidates are now RANKED: fewest parameter segments first, with registry
   order (newest first) kept as the tie-break, so the previous behaviour survives
   wherever no literal/parameter collision exists. The table is small and a path
   match is not a hash lookup, so the full scan costs nothing worth measuring."
  (let ((segments (api-path-segments path))
        (best nil) (best-params nil) (best-score nil))
    (dolist (route *api-route-registry*)
      (when (and (api-route-active route) (eq (api-route-method route) method))
        (multiple-value-bind (matched params) (api-match-route route segments)
          (when matched
            (let ((score (api-route-param-count route)))
              ;; STRICT < : on a tie the earlier (newer) route is kept.
              (when (or (null best) (< score best-score))
                (setf best route best-params params best-score score)))))))
    (values best best-params)))

;;; A routing failure is a condition like any other error from the dispatcher's
;;; point of view, so it is declared here — with the routing code, and BEFORE
;;; the SECTION 6 classifier that typecases on it.
(define-condition api-no-endpoint (error)
  ((message :initarg :message :reader api-no-endpoint-message))
  (:report (lambda (c s) (format s "API endpoint not found: ~A" (api-no-endpoint-message c)))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Inbound payload: path params + JSON body → params plist
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; The plist handed to dispatch-route2 is the SAME shape the internal website
;;; action builds: a plist whose keys are nst-whs's own initarg names. That is
;;; what lets extract-domain-initargs MOP-filter it with zero per-entity
;;; mapping — the ferry cannot tell the API caller from the HTML form.

(define-condition api-client-error (error)
  ((message :initarg :message :reader api-client-error-message))
  (:report (lambda (c s) (format s "API client error: ~A" (api-client-error-message c)))))

(defun api-client-error (format-string &rest args)
  (error 'api-client-error :message (apply #'format nil format-string args)))

(defun api-camel->lisp-name (string)
  "\"warehouseGstin\" → \"WAREHOUSE-GSTIN\". JSON keys are accepted in the
   canonical hyphenated form (\"warehouse-gstin\", identical to the initarg)
   and in camelCase, which is the spelling the response JSON already uses."
  (with-output-to-string (out)
    (loop for i from 0 below (length string)
          for c = (char string i)
          do (cond ((and (upper-case-p c)
                         (plusp i)
                         (not (char= (char string (1- i)) #\-)))
                    (write-char #\- out)
                    (write-char (char-upcase c) out))
                   (t (write-char (char-upcase c) out))))))

(defun api-json-key->param-key (key)
  (cond ((keywordp key) key)
        ((stringp key) (intern (api-camel->lisp-name key) :keyword))
        ((symbolp key) (intern (api-camel->lisp-name (symbol-name key)) :keyword))
        (t (api-client-error "unusable JSON object key ~S" key))))

(defun api-normalize-body-params (decoded)
  "A decoded JSON object (an alist) → a params plist. A non-object body is
   rejected: the ferry reads a plist, and silently ignoring a wrong-shaped
   body would turn a client mistake into a no-op update."
  (unless (listp decoded)
    (api-client-error "the request body must be a JSON object, got ~S" (type-of decoded)))
  (loop for pair in decoded
        when (consp pair)
          append (list (api-json-key->param-key (car pair)) (cdr pair))))

(defun api-request-body-params ()
  "Reads the raw body and decodes it. NIL for an absent/blank body — a PUT
   with no body is a legal no-field-change request, not an error."
  (let ((raw (handler-case (hunchentoot:raw-post-data :force-text t)
               (condition () nil))))
    (if (or (null raw)
            (string= "" (string-trim '(#\Space #\Tab #\Newline #\Return) raw)))
        nil
        (handler-case (api-normalize-body-params (json:decode-json-from-string raw))
          (api-client-error (c) (error c))
          (condition (c) (api-client-error "malformed JSON payload: ~A" c))))))

(defun api-query-params ()
  "The QUERY STRING as a params plist, or NIL.

   WHY THIS EXISTS AT ALL: without it a filtering endpoint is unreachable over
   HTTP. api-params-for-request used to merge only the session company, the path
   params and the JSON body, so GET /hhub/api/v1/catalog/products?status=active
   arrived at the list verb with no :status key and every filter was silently
   ignored — a surface that exists, is documented, and does nothing.

   Keys go through the same api-json-key->param-key normalisation as body keys,
   so ?product-code=… and ?productCode=… both land on :PRODUCT-CODE, and a
   querystring is not a second, differently-spelled dialect of the JSON contract.

   An EMPTY value (\"?status=\", or a bare \"?flag\") is PASSED THROUGH, not
   dropped. Dropping it would turn \"the client asked for something unusable\"
   into \"the client asked for nothing\" and quietly widen the result set — the
   exact failure mode this project already has on record with
   ?is-primary-location=0 (nst-bl-apidefs2-CONTEXT.md §9.6). The domain verb
   refuses it instead. NOTE the honest consequence: a bad query VALUE currently
   surfaces as 500 rather than 400, because the domain-validation condition
   taxonomy is still unfinished (CONTEXT §9.1) — it is on the list, not fixed
   here.

   Repeated keys (?a=1&a=2) keep every occurrence; getf then takes the first,
   which is the same 'first wins' rule as the rest of this plist."
  (handler-case
      (loop for (name . value) in (hunchentoot:get-parameters*)
            when (and name (stringp name) (plusp (length name)))
              append (list (api-json-key->param-key name) value))
    (condition () nil)))   ; a broken querystring must not 500 the request

(defun api-params-for-request (route matched-path-params company)
  "Build the params plist handed to the ferry, in precedence order:
     1. the AUTHENTICATED session company, as :company (see SECTION 4);
     2. path params (the URL is the address of the object);
     3. JSON body params (the client's data);
     4. query-string params (the weakest signal — see api-query-params).
   getf returns the FIRST match, so precedence is literal: a client cannot
   override the session company through the body, nor the row-id through the
   body, no matter what it sends.
   BODY BEFORE QUERY because the body is the resource representation and the
   query string is a filter/argument channel: when a POST or PUT carries both,
   the payload wins. A GET list has no body, so the ordering is invisible there.
   Path values stay STRINGS (the ferry's rm-row-id is parsed by the domain verb).
   :company is NOT in adhara's *reserved-initargs*, so it survives
   extract-domain-initargs and reaches the domain verb — which is the point:
   the legacy COMPANY slot on entities like nst-whs sees the session tenant and
   नियम-1 is satisfied by construction rather than by a client-supplied value."
  (append (when (and company (api-route-inject-company route))
            (list :company company))
          (loop for (name . value) in matched-path-params
                for key = (cdr (assoc name (api-route-path-params route)
                                      :test #'string-equal))
                when key append (list key value))
          (api-request-body-params)
          (api-query-params)))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 4 — The credential seam (नियम-1)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; TODAY: :session — the browser/vendor session cookie, i.e. the same login
;;; the internal website uses. This is the ONLY place that has to change when
;;; bearer API keys land: an :bearer scope resolves the key to a company and
;;; installs it as the session login company, after which everything below —
;;; कारक construction, नियम-1 tenant isolation — is unchanged. The dispatcher
;;; never consults the payload for a tenant, so no endpoint can opt out of
;;; tenant isolation by accident.

(define-condition api-not-authenticated (error)
  ((message :initarg :message :reader api-not-authenticated-message))
  (:report (lambda (c s) (format s "API unauthenticated: ~A" (api-not-authenticated-message c)))))

(defun api-authenticate (route)
  "Establishes the login company (अधिकरण) for this request, or signals 401.
   → THE COMPANY OBJECT itself, not merely T.
   Returning the company is what lets the API hand the session tenant to the
   domain BEFORE the PUT reaches it (see api-params-for-request and
   api-route-inject-company). It is the same object make-action-domain-ctx
   independently puts in domain-ctx as :tenant — one credential, read once by
   the session, so the कारक and the injected initarg can never disagree."
  (case (api-route-auth-scope route)
    (:session
     (or (conflodis2-login-company)
         (error 'api-not-authenticated
                :message "no login company in session — sign in first, or present a credential the API can resolve to a tenant.")))
    (t (error "apidefs2: unknown auth scope ~S on route ~S."
              (api-route-auth-scope route) (api-route-key route)))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 5 — Belnap → HTTP status, and the JSON body
;;; ═══════════════════════════════════════════════════════════════════════

(defun api-status-for-response (response success-status)
  "The Belnap sentinels ARE the HTTP status: a domain fact of 'absent' is 404,
   'inconclusive' is 503, 'sources disagree' is 409. An empty LIST is a
   successful empty result — 200, not 404."
  (cond
    ((listp response) (if response success-status 200))
    ((null response) 404)
    ((typep response 'nst-response-nil) 404)
    ((typep response 'nst-response-unknown) 503)
    ((typep response 'nst-response-contradiction) 409)
    (t success-status)))

(defun api-render-json (response)
  "Always one JSON text: a single object, an array, or [].
   Delegates to the dispatcher's own ring-4 hop (conflodis2-render), which
   normalises per-entity structures and per-list texts into one document.
   ctx is a throwaway empty domain-ctx — the render-json methods for response
   models ignore it (it exists for renderers that format per-tenant)."
  (conflodis2-render response (make-domain-ctx) :json))

(defun api-write-json (text status)
  "Terminate the request with TEXT as application/json and STATUS.
   abort-request-handler (not a plain return) so callers can bail out from
   anywhere — the same discipline as return-json in dod-bl-utl.lisp."
  (setf (hunchentoot:content-type*) "application/json; charset=utf-8")
  (setf (hunchentoot:return-code*) status)
  (hunchentoot:abort-request-handler text))

(defun api-error-json (code message)
  (json:encode-json-to-string (list (cons "error" code) (cons "message" message))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 6 — The API error log
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Every API failure the dispatcher answers for is written to an append-only
;;; log before the response is sent. The client body stays deliberately vague
;;; (OWASP "improper error handling": an internal message can leak schema, SQL
;;; or file paths), so this file is where the real condition AND the backtrace
;;; must land — otherwise a 500 is undiagnosable after the fact.
;;;
;;; It is also the security record: every 401 is captured with its client
;;; address, which is what you need to spot credential-stuffing or endpoint
;;; enumeration. No rate limiting or rotation is implemented here — the
;;; operating system owns both.

(defparameter *api-log-file* #p"~/hhublogs/ninestores-apilogs.log"
  "Append-only API error log. The acceptor runs as the hunchentoot user, so ~
   resolves to /home/hunchentoot — the same hhublogs/ directory that already
   holds ninestores-access.log and ninestores-messages.log (see
   acceptor-access-log-destination in dod-ini-sys.lisp start-das).")

(defparameter *api-log-lock* (bt:make-lock "ninestores-apilogs")
  "Hunchentoot serves requests on many threads; without this lock two failing
   requests can interleave partial lines into the same file.")

(defun api-log-timestamp ()
  "Local wall-clock stamp, same shape hunchentoot's own logs use —
   [2026-09-12 12:31:04]."
  (multiple-value-bind (sec min hr day mon yr) (get-decoded-time)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
            yr mon day hr min sec)))

(defun api-log-line (text)
  "Append TEXT as one entry. Logging must NEVER be able to fail a request:
   a full disk or a permission change degrades to *error-output*, not a 500."
  (handler-case
      (bt:with-lock-held (*api-log-lock*)
        (with-open-file (stream *api-log-file*
                                :direction :output
                                :if-exists :append
                                :if-does-not-exist :create
                                :external-format :utf-8)
          (write-string text stream)))
    (condition (c)
      (format *error-output* "~&apidefs2: cannot append to ~A — ~A~%"
              *api-log-file* c))))

(defun api-condition-backtrace (condition)
  "Best-effort backtrace of the CURRENT stack.
   SBCL-specific on purpose: this project is SBCL-only (nst-bl-adhara.lisp
   already calls sb-mop), and the frames are the whole reason a 5xx gets logged.
   TWO traps this function must not fall into:
    1. sb-debug:print-backtrace here accepts only :STREAM/:COUNT — passing
       :CONDITION signals unknown-&key on this SBCL, and the guard below would
       then quietly degrade every 500 to '<backtrace unavailable>';
    2. it captures the stack where it is CALLED, so it is only useful from a
       handler-bind handler (see com-hhub-api-dispatch). Called from a
       handler-case clause it is worthless: handler-case unwinds first, and the
       log then names only api-fail's own frames."
  (declare (ignore condition))
  (handler-case
      (with-output-to-string (s)
        (sb-debug:print-backtrace :stream s :count 25))
    (condition () "<backtrace unavailable>")))

;;; --- condition → status/code, and the client-safe message -----------------

(defun api-status-for-condition (condition)
  (typecase condition
    (api-client-error 400)
    (api-not-authenticated 401)
    (api-no-endpoint 404)
    (t 500)))

(defun api-error-code-for-status (status)
  (case status
    (400 "invalid_request")
    (401 "unauthenticated")
    (404 "no_such_endpoint")
    (405 "method_not_allowed")
    (t "internal_error")))

(defun api-safe-message-for-condition (condition status)
  "What the CLIENT may see. Our own api-* conditions carry messages written
   for callers; anything else is by definition unexpected and gets a fixed
   string — its real text goes to the log only."
  (case status
    (400 (api-client-error-message condition))
    (401 (api-not-authenticated-message condition))
    (404 (api-no-endpoint-message condition))
    (t "the request could not be completed")))

(defun api-log-error (status code condition method path &key backtrace)
  "One log entry per failed request: request line, client address, condition,
   and (for 5xx) BACKTRACE — captured by the caller AT SIGNAL TIME (see
   com-hhub-api-dispatch); the fallback below can only see the handler's own
   frames, so a stack-less entry means the capture never ran."
  (api-log-line
   (with-output-to-string (s)
     (format s "[~A] ~D ~A ~A ~A client=~A~%"
             (api-log-timestamp) status code method path
             (handler-case (or (hunchentoot:remote-addr*) "unknown")
               (condition () "unknown")))
     (format s "  condition: ~A~%" condition)
     (when (>= status 500)
       (format s "  backtrace:~%~A~%" (or backtrace (api-condition-backtrace condition)))))))

(defun api-fail (condition method path &key backtrace)
  "LOG FIRST, then answer: api-write-json aborts the handler, so a response
   sent before the log entry would lose the evidence on any later error."
  (let* ((status (api-status-for-condition condition))
         (code (api-error-code-for-status status)))
    (api-log-error status code condition method path :backtrace backtrace)
    (api-write-json (api-error-json code (api-safe-message-for-condition condition status))
                    status)))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 7 — The one generic handler (bound to ^/hhub/api/v1/ in the dispatch table)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; There is deliberately ONE handler for every API endpoint: adding an
;;; endpoint is a register-api-route line in the domain's own file, never a
;;; new entry in hunchentoot:*dispatch-table*.

(defun api-run-route (route path-params company)
  "The whole Ring-4 → Ring-3 crossing for one matched endpoint. COMPANY is the
   already-authenticated session company (अधिकरण) — the credential is resolved
   ONCE, in the auth module, and then travels both ways: into params as
   :company when the route asks for it, and (independently, inside
   dispatch-route2) into domain-ctx as :tenant."
  (let* ((params (api-params-for-request route path-params company))
         (response (dispatch-route2 (api-route-key route) params
                                    :trans-func-name (format nil "api ~A ~A"
                                                             (api-route-method route)
                                                             (api-route-path route))
                                    :request-uri (hunchentoot:request-uri*)
                                    :output-type :json
                                    :raw t))
         (status (api-status-for-response response (api-route-success-status route))))
    (api-write-json (api-render-json response) status)))

(defun com-hhub-api-dispatch ()
  "THE API ENTRY POINT. Registered once:

     (hunchentoot:create-regex-dispatcher \"^/hhub/api/v1/\" 'com-hhub-api-dispatch)

   Method+path select the endpoint; the endpoint selects an action route; the
   action route selects a route-* verb. Nothing here knows about warehouses.

   ONE handler-case clause covers every failure because the api-* conditions
   are ordinary errors: api-fail classifies the condition (400/401/404/500),
   writes the log entry, and only then answers. A domain-validation 4xx
   taxonomy is still a follow-up — until it exists, an unrecognised condition
   is a 500 whose detail is in the log, not in the response.

   ORDER MATTERS: the route must be matched and the credential resolved BEFORE
   the domain is reached, because the resolved company is part of what the
   domain verb receives (api-route-inject-company).

   BACKTRACE CAPTURE — handler-BIND, not handler-case. handler-case unwinds the
   stack before its clauses run, so a trace taken in the clause names only
   api-fail's own frames (that is exactly what the 19:34:05 entry in
   ninestores-apilogs.log shows: no domain frame anywhere). handler-bind runs in
   the dynamic context of the signal, so the frames are still live. The LAST
   signal wins, which is normally the one that escapes; an error that the domain
   catches and recovers from can therefore leave its trace replaced by a later
   one — the logged condition is always the escaping one."
  (let ((method (hunchentoot:request-method*))
        (path (or (hunchentoot:script-name*) "/"))
        (trace nil))
    (handler-case
        (handler-bind ((error (lambda (c) (setf trace (api-condition-backtrace c)))))
          (multiple-value-bind (route path-params) (find-api-route method path)
            (unless route
              (error 'api-no-endpoint
                     :message (format nil "~A ~A" method path)))
            (let ((company (api-authenticate route)))
              (api-run-route route path-params company))))
      (error (c) (api-fail c method path :backtrace trace)))))

;;; End of nst-bl-apidefs2.lisp
