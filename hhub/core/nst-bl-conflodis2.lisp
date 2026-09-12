;;; nst-bl-conflodis2.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; The Ring-2/3 ROUTE-ACTION DISPATCHER — Pāṇinian verb dispatch.
;;; Design: hhub/core/nst-bl-conflodis2-DESIGN.md
;;; Grammar: paninigrammarprocurement.md
;;;
;;; TWO-TIER OWNERSHIP
;;;   Tier 1 (Ring 1, domain): request->dispatch — the ferry. ONE धातु verb
;;;           against ONE कर्म (single entity). Owned by nst-bl-adhara.lisp.
;;;   Tier 2 (Ring 2/3, here):  route-* action verbs. Entity-agnostic. An action
;;;           verb assembles the entities it needs by launching SEVERAL Tier-1
;;;           ferries (one boat per entity crossing) inside one transaction.
;;;
;;; This file deliberately contains NO crud-op, no adapter/presenter/view wiring
;;; and no single-entity assumption. It is the first version: one action verb per
;;; inbound action, with the संधि/chain seam reserved for later.
;;;
;;; Depends on nst-bl-adhara.lisp (load AFTER it): nst-request-model, params,
;;; nst-response-model, domain-ctx/make-domain-ctx, request->dispatch,
;;; domain->response, render-html, render-json.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 1 — The action-route record
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; A route maps ONE inbound action symbol (route-<action>) to ONE Ring-2/3
;;; action verb. It carries transport/security metadata only — never an entity
;;; class, never an adapter chain.

(defclass action-route ()
  ((action-verb
    :initarg :action-verb
    :accessor route-action-verb
    :documentation "The route-* symbol this route dispatches. e.g. ROUTE-ORDER.")
   (request-class
    :initarg :request-class
    :accessor route-request-class
    :initform 'nst-request-model
    :documentation "Slotless nst-request-model subclass carrying the payload
                    in (params request). Action verbs may specialize on it.")
   (output-type
    :initarg :output-type
    :accessor route-output-type
    :initform :json
    :documentation ":json or :html — the Ring-4 dṛś format. Overridable per call.")
   (channel
    :initarg :channel
    :accessor route-channel
    :initform :http
    :documentation "करण — instrument: :http/:ui/:agent/:batch/:scheduler.")
   (description
    :initarg :description :accessor route-description :initform nil)
   ;; --- carried for later enforcement (NOT enforced in v1) ---
   (required-roles      :initarg :required-roles      :accessor route-required-roles      :initform nil)
   (permission-checker  :initarg :permission-checker  :accessor route-permission-checker  :initform nil)
   (feature-flags       :initarg :feature-flags       :accessor route-feature-flags       :initform nil)
   (tenant-overrides    :initarg :tenant-overrides    :accessor route-tenant-overrides    :initform nil)
   (audit-level         :initarg :audit-level         :accessor route-audit-level         :initform nil)
   (active              :initarg :active              :accessor route-active              :initform t)
   (tags                :initarg :tags                :accessor route-tags                :initform nil)
   (version             :initarg :version             :accessor route-version             :initform nil)
   (metadata            :initarg :metadata            :accessor route-metadata            :initform nil))
  (:documentation
   "An ACTION ROUTE. Entity-agnostic by construction: it names the action verb
    (route-*), not a business object. Multi-entity assembly happens INSIDE the
    action verb via several Tier-1 ferries."))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The action-route registry
;;; ═══════════════════════════════════════════════════════════════════════

(defparameter *action-route-registry* (make-hash-table :test 'eq)
  "route-* symbol → action-route instance.")

(defun register-action-route (route-key
                              &key action-verb
                                   (request-class 'nst-request-model)
                                   (output-type :json)
                                   (channel :http)
                                   description
                                   required-roles permission-checker feature-flags
                                   tenant-overrides audit-level
                                   (active t) tags version metadata)
  "Register (or replace) an action route. Returns ROUTE-KEY.
   ACTION-VERB defaults to ROUTE-KEY itself, so the common case is a one-liner:
     (register-action-route 'route-order)"
  (setf (gethash route-key *action-route-registry*)
        (make-instance 'action-route
                       :action-verb (or action-verb route-key)
                       :request-class request-class
                       :output-type output-type
                       :channel channel
                       :description description
                       :required-roles required-roles
                       :permission-checker permission-checker
                       :feature-flags feature-flags
                       :tenant-overrides tenant-overrides
                       :audit-level audit-level
                       :active active
                       :tags tags
                       :version version
                       :metadata metadata))
  route-key)

(defun find-action-route (route-key)
  "Resolve ROUTE-KEY to its action-route, or signal a clear grammar error.
   An unknown route is a Ring-3 registration mistake — fail loudly, never
   silently no-op (same discipline as gana-package-for)."
  (let ((route (gethash route-key *action-route-registry*)))
    (unless route
      (error "conflodis2: no action route registered for ~S. Register it with ~
              (register-action-route '~S)." route-key route-key))
    (unless (route-active route)
      (error "conflodis2: action route ~S is inactive." route-key))
    route))

(defun list-action-routes ()
  "Diagnostic — all registered action route keys."
  (let (keys)
    (maphash (lambda (k v) (declare (ignore v)) (push k keys)) *action-route-registry*)
    (sort keys #'string< :key #'symbol-name)))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 3 — कारक: building domain-ctx from the session
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; नियम-1: अधिकरण (tenant) comes from the SESSION LOGIN COMPANY only. A
;;; client-supplied :tenant-id in the payload is NEVER consulted.

(defun conflodis2-session-value (key)
  "Session read that tolerates a non-HTTP caller (REPL/tests) → nil."
  (handler-case (hunchentoot:session-value key)
    (condition () nil)))

(defparameter *action-route-company-override* nil
  "TEST/REPL ONLY. A company object used as अधिकरण when no HTTP session is
   active. MUST stay NIL in production — नियम-1 requires the session login
   company; this exists only so routes can be exercised outside Hunchentoot.")

(defun conflodis2-login-company ()
  "The acting login company OBJECT (vendor → customer → user role track).
   Returns nil outside a logged-in session."
  (or (conflodis2-session-value :login-vendor-company)
      (conflodis2-session-value :login-customer-company)
      (conflodis2-session-value :login-user-company)))

(defun conflodis2-actor ()
  "कर्ता — the agent performing the action (user object or role name)."
  (or (conflodis2-session-value :login-user)
      (conflodis2-session-value :login-user-role-name)))

(defun make-action-domain-ctx (route request)
  "Build the कारक passenger for an action dispatch.
   कर्म is NOT here — it is the action verb's own argument (Guardrail 2).
   संप्रदान/अपादान are read from the payload when the action is directed at /
   drawn from another party; they are NOT tenant-scoped by नियम-1."
  (let ((company (or (conflodis2-login-company) *action-route-company-override*))
        (payload (and request (params request))))
    (unless company
      (error "conflodis2: no login company in session — cannot establish ~
              अधिकरण (tenant) for नियम-1. Dispatch requires a logged-in session."))
    (make-domain-ctx
     :actor     (conflodis2-actor)
     :tenant    company
     :channel   (route-channel route)
     :recipient (getf payload :recipient)
     :source    (getf payload :source))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Reverse ferry + Ring-4 render (dṛś)
;;; ═══════════════════════════════════════════════════════════════════════

(defun action->response (domain ctx)
  "Reverse boundary: domain result → nst-response-model (or a list of them).
   Accepts a single entity, a LIST (enumerate/assembly), a Belnap domain
   sentinel, or a ready-made response model (pass-through)."
  (cond
    ((null domain) nil)
    ((typep domain 'nst-response-model) domain)
    ((listp domain)
     (mapcar (lambda (e)
               (cond ((null e) nil)
                     ((typep e 'nst-response-model) e)
                     (t (domain->response e ctx))))
             domain))
    (t (domain->response domain ctx))))

(defun conflodis2-json-output-p (output-type)
  "True when OUTPUT-TYPE selects JSON (accepts :json / 'json / \"json\")."
  (and output-type
       (string-equal "json"
                     (string (if (keywordp output-type)
                                 output-type
                                 (intern (string-upcase (string output-type))))))))

(defun conflodis2-json-text (rendered)
  "One render-json RESULT → one JSON text.
   The render-json contract in this tree is SPLIT: per-ENTITY methods return a
   Lisp structure (e.g. WarehouseResponseModel → an alist), while per-LIST and
   sentinel methods return already-encoded text. The dispatcher must emit ONE
   document, so encode only what is not already text — interpolating a Lisp
   structure into a JSON array with ~A would emit Lisp syntax, not JSON."
  (if (stringp rendered)
      rendered
      (json:encode-json-to-string rendered)))

(defun conflodis2-html-fragment (rendered)
  "One render-html RESULT → one fragment. NIL means the method WROTE directly
   to *standard-output* (e.g. display-warehouse-row in nst-ui-warehouse.lisp)
   and has nothing to return — PRINCing that NIL into the output would emit the
   four letters N-I-L as markup."
  (cond ((null rendered) "")
        ((stringp rendered) rendered)
        (t (princ-to-string rendered))))

(defun conflodis2-render (response ctx output-type)
  "Ring-4 dṛś: encode RESPONSE using the adhara render contract.
   Lists are composed element-wise here (the dispatcher stays aggregate-agnostic;
   no per-aggregate LIST method is required). Each element is normalised through
   conflodis2-json-text / conflodis2-html-fragment, because the render methods it
   calls are allowed to return either text or a Lisp structure."
  (let ((jsonp (conflodis2-json-output-p output-type)))
    (cond
      ((null response) (if jsonp "[]" ""))
      ((listp response)
       (if jsonp
           (format nil "[~{~A~^,~}]"
                   (mapcar (lambda (r)
                             (if r (conflodis2-json-text (render-json r ctx)) "null"))
                           response))
           (with-output-to-string (s)
             (dolist (r response)
               (when r
                 (princ (conflodis2-html-fragment (render-html r ctx)) s))))))
      (t (if jsonp
             (conflodis2-json-text (render-json response ctx))
             (conflodis2-html-fragment (render-html response ctx)))))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 5 — Transaction / ABAC seam (pluggable)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; v1 default runs the action verb unwrapped so routes are testable before the
;;; PEP/ABAC wiring lands. To plug the legacy Policy Enforcement Point, set
;;; *action-route-transaction-function* to a function that runs THUNK inside
;;; with-hhub-transaction (build the ABAC params — including "uri" — there).

(defun call-with-action-transaction (thunk route request trans-func-name)
  "Default: no wrapper. Replace/bind to integrate ABAC + with-hhub-transaction."
  (declare (ignore route request trans-func-name))
  (funcall thunk))

(defparameter *action-route-transaction-function* #'call-with-action-transaction
  "Function of (THUNK ROUTE REQUEST TRANS-FUNC-NAME) that executes the action
   verb. The single seam for AuthZ/transaction/audit.")


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 6 — The dispatcher
;;; ═══════════════════════════════════════════════════════════════════════

(defun dispatch-action (route request ctx &key output-type (raw nil))
  "Run the action verb for ROUTE, then reverse-ferry and render.
   :RAW T returns the response model(s) instead of the rendered string
   (useful for UI/widget callers)."
  (let* ((verb (route-action-verb route))
         (fn   (fdefinition verb))
         (domain (funcall *action-route-transaction-function*
                          (lambda () (funcall fn request ctx))
                          route request nil))
         (response (action->response domain ctx)))
    (if raw
        response
        (conflodis2-render response ctx (or output-type (route-output-type route))))))

(defun dispatch-route2 (route-key raw-params
                        &key trans-func-name output-type request-uri raw)
  "THE ENTRY POINT. Ring-3 inbound action → Ring-2/3 action verb → Ring-1 verbs.

   ROUTE-KEY        a route-* symbol, e.g. 'ROUTE-ORDER
   RAW-PARAMS       the inbound payload (a plist) — carries ALL params, for all
                    entities the action needs. Never carries a trusted tenant.
   TRANS-FUNC-NAME  audit/ABAC transaction name (used by the transaction seam)
   OUTPUT-TYPE      :json / :html (defaults to the route's own)
   REQUEST-URI      kept for boundary/audit compatibility
   RAW              return response model(s) instead of rendered output"
  (declare (ignore request-uri))
  (let* ((route   (find-action-route route-key))
         (request (make-instance (route-request-class route)
                                 :params raw-params))
         (ctx     (make-action-domain-ctx route request)))
    (format t "~&conflodis2: ~S → action verb ~S~%"
            route-key (route-action-verb route))
    (dispatch-action route request ctx
                     :output-type output-type
                     :raw raw)))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 7 — Built-in smoke-test route (route-ping)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Lets you exercise the dispatcher end-to-end (registry → कारक ctx → action
;;; verb → reverse ferry → render) with no domain entity involved.

(defclass ping-response (nst-response-model) ())

(defmethod render-json ((r ping-response) (ctx domain-ctx))
  (declare (ignore r ctx))
  "{\"ok\":true,\"route\":\"ping\",\"dispatcher\":\"conflodis2\"}")

(defmethod render-html ((r ping-response) (ctx domain-ctx))
  (declare (ignore r ctx))
  "<div class=\"ping\">ok — conflodis2</div>")

(defun route-ping (request ctx)
  "Diagnostic action verb: proves the two-tier path is wired."
  (declare (ignore ctx))
  (make-instance 'ping-response :params (params request)))

(register-action-route 'route-ping
                       :description "conflodis2 smoke test"
                       :output-type :json)

;;; End of nst-bl-conflodis2.lisp
