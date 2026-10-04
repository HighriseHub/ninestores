;;; nst-bl-ordhapi.lisp — ORDER HEADER ACTION ROUTES + CUSTOMER API BINDINGS
;;;                          (conflodis2 Tier 2, Ring 2/3-4)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Design: aiharness/deepseek/skills/knowledge/nst-bl-conflodis2-DESIGN.md (§3, §5, §6, §9)
;;;         aiharness/deepseek/skills/order-adhara-stories-CONTEXT.md (S12/S13, D5, D8, D14, D20, O3)
;;; Dispatcher: hhub/core/nst-bl-conflodis2.lisp
;;; Worked example this file mirrors, function for function: hhub/invoice/nst-bl-invhapi.lisp
;;;
;;; The order-header analogue of invoice/nst-bl-invhapi.lisp: inbound action symbol →
;;; (register-action-route 'route-ordh-<action> …) → ONE route-ordh-<action> verb → Tier-1
;;; ferries (request->dispatch … 'nst-ordh) — plus, in SECTION 5, the five customer bindings,
;;; because register-api-route REFUSES a path whose action route is not registered yet and a
;;; binding must therefore live in the file that registers its verb.
;;;
;;; Every route here returns DOMAIN-LAYER results (an nst-ordh / nst-orditm, a list of them, a
;;; Belnap sentinel, the delete! ack T, or a ready-made nst-response-model for the assembled
;;; aggregate). No route renders; the dispatcher alone runs the reverse ferry and the Ring-4
;;; render (DESIGN §3). A GET never writes.
;;;
;;; ⚠ THIS FILE DEPENDS ON THREE THINGS IT DOES NOT DEFINE, all of them load-order facts rather
;;; than choices — the same three the invoice api file records:
;;;
;;;   1. THE BELNAP SENTINEL FERRY. domain->response methods for nst-entity-nil / -unknown /
;;;      -contradiction, the (eql t) delete ack, and render-json/render-html for
;;;      nst-response-nil/-unknown/-contradiction live in warehouse/nst-bl-whsapi.lisp SECTION 4,
;;;      which both build lists load AFTER the order files. Without it, every 404/409/503 this
;;;      domain returns dies at the dispatcher's reverse ferry with NO-APPLICABLE-METHOD.
;;;   2. THE DELETE ACK TYPE IS warehouse-ack-response, by name. An order DELETE answers
;;;      {"ok":true,"operation":"delete"} through the warehouse's class. Correct in substance
;;;      (there is no कर्म left to return once the row is soft-deleted), wrong in name; the same
;;;      wart the invoice api file records, and renaming a shared boundary class is a shared-file
;;;      change, not this one.
;;;   3. request->dispatch CANNOT CARRY A CONTROL KEY. Its !update method hands the verb
;;;      (extract-domain-initargs rm entity-class), which forwards only keys the DOMAIN CLASS
;;;      declares — so :if-match is dropped before the verb can see it, and the ferry can carry
;;;      NO non-initarg at all. This is why route-ordh-update calls the verb directly; see the
;;;      measurement note above route-ordh-update for what that revealed.
;;;
;;; NOT IN THIS FILE, ON PURPOSE — the out-of-scope list of the orders batch (D3), so that a
;;; reader does not go looking for it:
;;;
;;;   * VENDOR EMAILS, WEB PUSH, THE CUSTOMER'S EMAIL AND SMS. create-order-from-shopcart's
;;;     tail (dod-bl-ord.lisp) sends all four. They are the ACTOR MODEL's fire-and-forget
;;;     path (send-order-mail, send-webpush-message, send-order-email-*/send-order-sms-*, called
;;;     by the UI caller in customer/dod-ui-cus.lisp), not a domain verb: putting them behind an
;;;     HTTP 200 needs the 202-vs-200 decision and the actor model's own review, not a ferry.
;;;   * THE UPI TRANSACTION ROW (save-upi-transaction). It is one row per vendor carrying the
;;;     UTR number the shopper typed, and the API has no field for that number — a create that
;;;     wrote one would be inventing a payment.
;;;   * CART ENDPOINTS (the session shopping cart the legacy funnel reads).
;;;   * PUT /orders/{ordnum}/fulfill AND /cancel. D3 puts both out of scope, and both are a
;;;     STATUS TRANSITION with its own verbs: *ordh-internal-only-fields* makes :status and
;;;     :order-fulfilled internal-only for exactly this reason — an external caller may not reach
;;;     them by field assignment instead of through their own verb.
;;;   * POST /orders/batch/daily AND GET /orders/calendar. Neither is bound here, and DAILY IS NOT A
;;;     WORKING FUNNEL TO ROUTE ONTO EVEN IF SOMEONE WANTED TO: create-order-from-pref
;;;     (dod-bl-ord.lisp:424) supplies 12 values to create-order's 28-variable multiple-value-bind, in
;;;     the wrong order — position 2 puts the CUSTOMER where request-date belongs — so `customer`
;;;     binds to NIL and (slot-value customer 'row-id) signals MISSING-SLOT BEFORE ANY ROW IS WRITTEN.
;;;     The batch path cannot create an order at all today. It is NOT fixed here (it is a repair to a
;;;     legacy funnel, not a route) and nothing in this file calls it.
;;;   * POST /orders/{ordnum}/items. The spec (hhub/core/nstoresapi.html, id 'ord') defines no
;;;     such route and D3 plans none: an order's lines are placed WITH the order, and a line is
;;;     edited or removed afterwards. route-orditm-update/-delete exist; there is no line CREATE.
;;;
;;; Load order: AFTER core/nst-bl-adhara.lisp, core/nst-bl-conflodis2.lisp,
;;; core/nst-bl-apidefs2.lisp, order/nst-dal-ordh.lisp, order/nst-dal-orditm.lisp,
;;; order/nst-bl-ordh.lisp and order/nst-bl-orditm.lisp — and BEFORE order/nst-bl-orditmapi.lisp,
;;; which reuses the param readers in SECTION 1.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 1 — Params readers and the route layer's coercions
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Inbound data rides in (params request) as a plist of nst-ordh's OWN initarg names
;;; (:ord-date "…" :ship-city "…" :place-of-supply "…"), not DB column spellings — the same
;;; shape the internal website's action builds, which is what lets extract-domain-initargs
;;; MOP-filter it with no per-entity mapping. These functions handle only what it cannot:
;;; string-keyed payloads, keyword-valued filters, page arguments that arrive as TEXT, and the
;;; date columns the domain class refuses as strings.

(defun ordh-param (payload key)
  "Read KEY (a keyword initarg/query name) from PAYLOAD.
   Accepts a keyword-keyed plist (conflodis2/agent callers) or a string-keyed one (a JSON body
   or querystring parsed by an inbound adapter)."
  (or (getf payload key)
      (getf payload (string-downcase (symbol-name key)))))

(defun ordh-keyword-value (value)
  "Coerce an inbound scalar to a keyword — \"ord-date\"/'ord-date → :ORD-DATE.
   Used for sort-by/sort-dir, which the verbs take as keywords. Non-scalars pass through so the
   guard's own message names the offender."
  (cond ((null value) nil)
        ((keywordp value) value)
        ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
        ((stringp value) (intern (string-upcase value) :keyword))
        (t value)))

(defun ordh-plist-set (payload key value)
  "PAYLOAD with KEY's value replaced, or appended when KEY is absent.

   ONE OCCURRENCE, NOT TWO, and that is why this exists rather than a list*: a plist may legally
   carry a key twice, and a duplicate INITARG is worse than untidy — make-instance applies both in
   order, so the value a route prepends would be OVERWRITTEN by the client's. Prepending is only an
   override if the old pair is gone."
  (let ((out nil) (seen nil))
    (loop for (k v) on payload by #'cddr
          do (if (eq k key)
                 (progn (setf seen t) (setf out (append out (list key value))))
                 (setf out (append out (list k v)))))
    (if seen out (append out (list key value)))))

(defun ordh-params-without (payload &rest keys)
  "PAYLOAD minus KEYS — used where a value that arrived from the transport must not reach a verb:
   the create strips the nested line array and the session-owned keys it sets itself, and the
   update strips :ordnum (the ADDRESS, which the verb refuses as a field and which the item routes
   also carry as their parent claim). Same idiom as extract-domain-initargs, applied at the route
   layer."
  (loop for (k v) on payload by #'cddr
        unless (member k keys) append (list k v)))

(defun ordh-date-param (value)
  "An inbound date → the CLSQL date object dod-order's ord-date/req-date require, or NIL.

   ACCEPTS EXACTLY TWO THINGS: \"YYYY-MM-DD\", and a value that is already a date object (a REPL or
   agent caller). Everything else is refused with api-client-error → 400, deliberately: ORD_DATE and
   REQ_DATE are NOT NULL with no DDL default, and a silently mis-parsed date is an order asking for
   delivery on the wrong day, not a failed request. The domain's own prepare-args defaults a MISSING
   ord-date to today; it cannot help with a string, because the class stores a date object and the
   database driver will not accept the text.

   ONE FORMAT, ISO — the same choice the invoice's inv-date-param records, for the same reason: the
   internal UI posts DD/MM/YYYY to its own handlers and converts with get-date-from-string before
   any verb sees it, while an API client gets ISO and nothing else, so there is never a question of
   which reading \"03/04/2026\" wants."
  (cond
    ((null value) nil)
    ((not (stringp value)) value)
    ((and (= (length value) 10)
          (char= (char value 4) #\-)
          (char= (char value 7) #\-))
     (let ((y (parse-integer value :start 0 :end 4 :junk-allowed t))
           (m (parse-integer value :start 5 :end 7 :junk-allowed t))
           (d (parse-integer value :start 8 :end 10 :junk-allowed t)))
       (unless (and y m d (<= 1 m 12) (<= 1 d 31))
         (api-client-error "~S is not a valid YYYY-MM-DD date" value))
       (clsql-sys:make-date :year y :month m :day d :hour 0 :minute 0 :second 0)))
    (t (api-client-error "~S is not a YYYY-MM-DD date" value))))

(defparameter *ordh-date-param-keys*
  '(:ord-date :req-date :expected-delivery-date :shipped-date)
  "The four date initargs a body may carry, and the reason each is coerced HERE rather than in the
   verb: dod-order declares all four clsql:date, so a transport string reaches the row as a string,
   and the write fails with the column named — a 503 'the database call did not answer' for what is
   a client-supplied date in the documented format. :shipped-date is on the list although only an
   internal channel may write it (F5): coercing it first means the refusal the client gets is about
   the FIELD POLICY, which is the true reason, instead of about its type.")

(defun ordh-params-with-dates (payload)
  "PAYLOAD with every supplied date initarg coerced, or PAYLOAD unchanged when none needs it.
   A NEW plist, so no caller observes another's coercion — the same discipline as the invoice's
   invh-normalised-request, and needed for the same reason: the ferry reads the params it is given."
  (let ((out payload))
    (dolist (key *ordh-date-param-keys*)
      (let ((value (getf out key)))
        (when (stringp value)
          (setf out (ordh-plist-set out key (ordh-date-param value))))))
    out))

(defun ordh-page-param (value label &key allow-zero)
  "A query-string page argument → an INTEGER, or api-client-error → 400.

   🚨 WHY THIS IS NOT PASSED THROUGH, MEASURED IN THE DOMAIN. A querystring value is ALWAYS a
   string, and the verbs' own page guard, nst-ordh-page-limit (nst-bl-ordh.lisp:474), signals a
   PLAIN ERROR for anything that is not a positive integer — 'limit must be a positive integer'. A
   plain error is not one of apidefs2's named conditions, so api-status-for-condition answers 500:
   ?limit=10, the spelling every client writes, would be reported as the SERVER breaking. That is
   the same defect class as the sort whitelist's bare error, and it is fixed the same way, in the
   route layer.

   A NEGATIVE OR ZERO LIMIT IS REFUSED HERE rather than left to the domain, because 0 is a
   well-formed integer with no legal meaning as a page size. :allow-zero is for :offset, where 0
   means the first page and IS legal."
  (cond ((null value) nil)
        ((integerp value) (if (or (plusp value) (and allow-zero (zerop value)))
                              value
                              (api-client-error "~A must be ~:[a positive integer~;zero or a positive integer~], got ~S"
                                                label allow-zero value)))
        ((and (stringp value)
              (plusp (length value))
              (every #'digit-char-p value))
         (ordh-page-param (parse-integer value) label :allow-zero allow-zero))
        (t (api-client-error "~A must be ~:[a positive integer~;zero or a positive integer~], got ~S"
                             label allow-zero value))))

(defun ordh-row-id-param (request)
  "The :row-id this request addresses, as a STRING, or api-client-error → 400.

   fetch, !update and delete! all specialize their id parameter on (id string), so a missing or
   integer-valued :row-id reaches the generic function as a non-string and signals
   NO-APPLICABLE-METHOD — a 500 for a malformed request. An integer IS a well-formed id (a JSON body
   or an agent caller may carry one) and is coerced rather than refused. Through HTTP this is
   defensive only: apidefs2 maps every path parameter to a string, and the item bindings map
   {item-id} to :row-id — but the same route is reachable from the other channels DESIGN §6 names
   (:agent, :batch), which is why the guard exists at all."
  (let ((id (ordh-param (params request) :row-id)))
    (cond ((and (stringp id) (plusp (length id))) id)
          ((integerp id) (princ-to-string id))
          (t (api-client-error "an order line row-id is required (a numeric item-id)")))))

(defun ordh-request-with-row-id-string (request)
  "REQUEST whose :row-id is a string, so a verb method specializing on (id string) is always
   applicable. Returns REQUEST unchanged when it already is one — the normal case.

   Built as a NEW request rather than by mutating: the same request object is handed to every ferry
   in an action, and no verb should observe another verb's coercion. (class-of request) keeps this
   entity-agnostic, so the header's and the line's routes share one implementation."
  (if (stringp (ordh-param (params request) :row-id))
      request
      (make-instance (class-of request)
                     :params (ordh-plist-set (params request) :row-id (ordh-row-id-param request)))))

(defun ordh-nested-param (entry key)
  "Read KEY from ONE NESTED body object ENTRY — a decoded-JSON alist with string keys, or a
   keyword-keyed plist (the offline/agent spelling).

   TWO SPELLINGS ARE TRIED, and the second is not decoration: the shared body-key normaliser
   (api-camel->lisp-name) turns \"taxableValue\" into :TAXABLEVALUE, which IS the entity's own
   initarg — but it turns \"totalItemVal\" into :TOTAL-ITEM-VAL, which is NOT (the initarg is
   :TOTALITEMVAL). So a client echoing back the very JSON this API renders would have its line
   total silently dropped. The hyphen-stripped spelling is tried second, so both round-trip.
   ⚠ The same wart exists one level UP, in api-params-for-request; fixing it there is a change to
   the seam all bound endpoints share and is deliberately not smuggled into this file. Recorded
   rather than hidden, because it is invisible from the outside."
  (cond ((null entry) nil)
        ((and (consp entry) (keywordp (car entry))) (ordh-param entry key))
        ((listp entry)
         (let* ((camel (api-camel->lisp-name (symbol-name key)))
                (flat (remove #\- camel)))
           (cdr (assoc-if (lambda (k)
                            (and (stringp k)
                                 (or (string-equal k camel) (string-equal k flat))))
                          entry))))
        (t nil)))

(defun ordh-lines-array (payload)
  "The create's nested line array, as a NON-EMPTY list of entries — an absent or empty array is a
   400, not a bare header.

   TWO SPELLINGS ARE ACCEPTED, :items and :lines, and neither is a synonym invented here: the spec
   (nstoresapi.html, id 'ord') fixes no body schema for POST /orders, the invoice line endpoint is
   called items, and the nested array this API RENDERS on the way out is called \"lines\"
   (route-ordh-detail). Refusing a client over which of its own two names it used would be a
   needless 400 on a request the API can answer.

   🚨 WHY AN EMPTY CART IS REFUSED, WHICH IS A CLOSED GAP RATHER THAN A STRICTNESS. The shopcart
   funnel inherits 'no empty-cart guard — an empty cart still writes a header with no lines' from the
   UI flow, and the orders story's reconnaissance section names it among the things a public
   endpoint must decide. For the API the decision is forced by the surface itself: 'Place an order
   from the current cart' with no cart is not an order, THE API PUBLISHES NO ADD-LINE ENDPOINT
   (D3 plans none, and route-orditm-list/-fetch are the deliberately unbound pair), and D13 has no
   totals roll-up — so a header created with no lines could never be completed or totalled over this
   surface by anything. It would be a row that exists only to be deleted.
   ⚠ THE DOMAIN STILL ALLOWS IT, and that is not a contradiction: nst-ordh's make does not require a
   line, the internal UI's own model is 'create the order, add its lines as they are picked', and
   that caller keeps its door. This is a rule about ONE ENDPOINT, enforced where the endpoint is."
  (let ((raw (or (ordh-param payload :items) (ordh-param payload :lines))))
    (cond ((null raw)
           (api-client-error "a create must carry at least one line: send an \"items\" (or \"lines\") array of objects, each naming a prd-id and a prd-qty. An order with no lines is not a request this endpoint can answer — there is no add-line endpoint to complete it with, and nothing recomputes the header's totals (D13)."))
          ((and (listp raw) (null raw))
           (api-client-error "the order's line array is empty: a create must carry at least one line (an \"items\" array of objects, each naming a prd-id and a prd-qty)."))
          ((listp raw)
           (unless (every #'listp raw)
             (api-client-error "the order's line array must be a JSON array of objects, got ~S" raw))
           raw)
          (t (api-client-error "the order's line array must be a JSON array of objects, got ~S" raw)))))

(defun ordh-enumerate-args (payload cust-id)
  "Filter args for (enumerate 'nst-ordh ctx …). These are QUERY arguments of the enumerate verb
   rather than nst-ordh initargs, so extract-domain-initargs would drop every one of them: a list
   action is one read of a filtered collection, not an entity crossing.

   CUST-ID IS A PARAMETER RATHER THAN A PAYLOAD READ, and that is D5: the customer scope comes from
   the SESSION, never from the payload, so this function cannot be handed a client-supplied one.
   See route-ordh-list.

   FROM-DATE / TO-DATE are passed through as the strings the query carried — [>= [:ord-date]
   \"2026-04-01\"] compares correctly against a DATE column, and a malformed one matches nothing.
   They are FILTERS, not stored fields, which is why the strict ISO coercion above applies to
   :ord-date only."
  (list :cust-id     cust-id
        :status      (ordh-param payload :status)
        :ordnum-like (ordh-param payload :ordnum-like)
        :from-date   (ordh-param payload :from-date)
        :to-date     (ordh-param payload :to-date)
        :limit       (ordh-page-param (ordh-param payload :limit) "limit")
        :offset      (ordh-page-param (ordh-param payload :offset) "offset" :allow-zero t)
        :sort-by     (or (ordh-keyword-value (ordh-param payload :sort-by)) :ord-date)
        :sort-dir    (or (ordh-keyword-value (ordh-param payload :sort-dir)) :desc)))

(defun ordh-guard-sort-args (payload)
  "Refuse an unusable sort-by/sort-dir at the ROUTE layer, as a 400, and never pass the sort
   through unguarded.

   🚨 WHY THIS EXISTS — the same measurement the invoice batch recorded, and it applies verbatim
   here. The whitelist that actually protects the ORDER BY lives in the domain (nst-ordh-sort-column,
   nst-bl-ordh.lisp:450), and THAT FILE SAYS SO IN ITS OWN DOCSTRING: 'a plain `error` here reaches
   the API as a 500 — \"the server broke\" — for a client that simply mistyped a query parameter the
   API itself publishes … The 400 belongs to S12/S13.' This is S12.

   THE DOMAIN CHECK STAYS, and this is not a replacement for it: the guard covers the values the HTTP
   layer can see, while the whitelist remains the authority for every other channel (:agent, :batch,
   a REPL caller) that reaches enumerate directly. It READS the same *ordh-sort-whitelist* rather
   than restating the columns, so the two cannot drift apart.

   Only a SUPPLIED and unusable value is refused. An absent sort-by is legal and defaults in
   ordh-enumerate-args, so the happy path is untouched."
  (let ((sort-by (ordh-keyword-value (ordh-param payload :sort-by)))
        (sort-dir (ordh-keyword-value (ordh-param payload :sort-dir))))
    (when (and sort-by (not (assoc sort-by *ordh-sort-whitelist*)))
      (api-client-error "sort-by ~S is not sortable here; use one of ~{~A~^, ~}"
                        sort-by (mapcar #'car *ordh-sort-whitelist*)))
    (when (and sort-dir (not (member sort-dir '(:asc :desc))))
      (api-client-error "sort-dir must be asc or desc, got ~S" sort-dir))))

(defun ordh-header-value (name)
  "The incoming request header NAME, or NIL. NIL outside a live request: a REPL, a batch job or the
   offline harness has no request in scope at all and hunchentoot SIGNALS there rather than
   answering, which is why the read is wrapped instead of assumed."
  (handler-case (hunchentoot:header-in* name) (condition () nil)))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The session scope (D5): WHO is placing or reading
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; D5, measured against the live placement path: the customer and the vendor share the TENANT, and
;;; the PARTY is a scope NARROWING INSIDE it — customer session → CUST_ID = the login customer.
;;; 'Scope is read from the SESSION, never the payload; an inbound :vendor-id/:cust-id is ignored,
;;; not honoured and not refused.'
;;;
;;; SO THESE ROUTES ARE THE CUSTOMER'S, and the party is read ONCE per request, here. नियम-1's
;;; tenant check is a separate matter and is already structural: every SELECT the verbs run carries
;;; TENANT_ID from domain-ctx.
;;;
;;; ⚠ WHAT A VENDOR SESSION GETS, STATED RATHER THAN LEFT TO BE DISCOVERED: the vendor half of the
;;; spec's GET /orders sentence ('vendors see orders pending fulfilment') is the VENDOR CHANNEL —
;;; DOD_VENDOR_ORDERS, scoped by VENDOR_ID, with its own entity and its own /vendor/orders bindings
;;; (S9-S11). Answering it from the header table here would be a second, weaker implementation of
;;; that channel's scope, so a session with no customer answers :F → 404 rather than a filtered list.
;;;
;;; AND THE NARROWING IS NOT ONLY THE LIST'S: the customer is written on a create, filtered on a list,
;;; and CHECKED on every route that addresses an order by number — see ordh-header-in-session-scope in
;;; SECTION 3, which is the one place that decides it. A session with no customer therefore answers 404
;;; on all five customer paths, and that is why 'an order naming neither the session's customer nor its
;;; vendor is 404, not 403' (D5) holds for a number in a URL exactly as it does for a filter.

(defun ordh-session-customer ()
  "The session's customer entity, or NIL. The read is conflodis2's own tolerant session reader, so
   a REPL/batch caller gets NIL instead of a signalling hunchentoot call — the same reason
   nst-bl-conflodis2 defines conflodis2-session-value at all.

   ⚠ THE KEY IS :login-customer, THE OBJECT — not :login-customer-id (a second session value the
   legacy UI also sets). The object is the one the placement path itself reads
   (customer/dod-ui-cus.lisp, get-login-customer), and reading the object rather than the id keeps
   ONE source: an id and an object that disagreed would be two answers to 'who is placing this
   order', and the object is what carries the row-id the domain needs anyway."
  (let ((customer (conflodis2-session-value :login-customer)))
    (when (and customer (ignore-errors (slot-value customer 'row-id)))
      customer)))

(defun ordh-no-session-customer (ctx)
  "The sentinel a customer route answers when the session carries no customer: :F, so 404.

   ⚠ NOT A CREATION, AND NOT A 401. A 401 is the API's word for 'no credential at all', and it is
   already spoken one layer up: api-authenticate refuses a request with no login company before any
   route runs. Reaching here means the caller IS authenticated as a tenant but is not a customer —
   and for a customer-addressed document that is an ABSENCE, which is exactly what :F means in this
   tree. The alternative, creating an order with no customer, is the one thing this must never do."
  (make-instance 'nst-entity-nil
                 :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                 :reason "This is a customer route and the session carries no customer (:login-customer). An order is placed BY a party, and the party is read from the session, never from the payload (D5) — so there is no order here to place, read or change. Sign in as the customer, or use the vendor channel (/vendor/orders) for a vendor session."))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 3 — THE URL CARRIES THE ORDER NUMBER, NOT THE ROW-ID
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Every order binding maps its {ordnum} segment to :ordnum. THE NUMBER IS THE BACKBONE KEY of an
;;; order in this domain: it is what the customer quotes, what the vendor looks it up by (D20
;;; denormalises it into every vendor row for exactly that reason), and what a human can type. A
;;; surrogate ROW_ID is none of those things — it is an accident of insertion order.
;;;
;;; 🚨 WHY THE RESOLUTION HAPPENS *HERE* AND NOT IN A VERB. The domain verbs specialize on
;;; (id string) — fetch, !update, delete! — and AN ORDNUM AND A ROW-ID ARE BOTH STRINGS, so no verb
;;; method can be written that tells them apart: CLOS dispatches on type, and the type is the same.
;;; The distinction is knowable only in the route layer, which is exactly where the URL is read.
;;; The verbs are NOT re-addressed: they still work by row-id, and this resolves the number to that
;;; row-id once per request. The domain keeps its surrogate key and the API gets a readable one.
;;;
;;; ⚠ THE DOMAIN POINTS THE ROUTE LAYER AT ONE SELECTOR, AND THIS USES IT: nst-select-order-header-by-ordnum,
;;; whose docstring says it is 'the single-row lookup the ROUTE layer uses to turn the URL's number
;;; into a row-id (the verbs stay row-id-keyed, exactly as the invoice's do, because CLOS dispatches
;;; on TYPE and an ORDNUM and a ROW_ID are both strings)'.
;;;
;;; ⚠ AND THAT SELECTOR EXCLUDES SOFT-DELETED HOLDERS, WHICH THE INVOICE'S RESOLVER DOES NOT DO — a
;;; deliberate divergence, stated because the two files are read side by side. route-invh-fetch-by-invnum
;;; goes through ?exists and answers :C → 409 when a soft-deleted invoice still holds the number. Here
;;; a soft-deleted holder answers :F → 404, and the reason is that ORDNUM is GLOBALLY UNIQUE and
;;; MINTED (D4/D6): a burnt number can never be reissued to a live order, so 'held by a row you
;;; cannot see' and 'no such order here' are the SAME fact for every caller of this API — the number
;;; is not an address, and nothing the client can do differs between the two answers. ?exists, the
;;; checker that CAN see deleted holders, is not reachable through the ferry at all (the ferry's
;;; ?exists method passes ctx where the lookup value belongs), and it is a question about MINTING,
;;; which is the verb's business and not an address resolution's.

(defun ordh-header-in-session-scope (header ctx)
  "HEADER when it belongs to this SESSION's customer, otherwise :F → 404.

   🔒 THE NARROWING IS D5, APPLIED TO THE ADDRESSED READ AS WELL AS TO THE LIST. D5 puts it plainly —
   'customer session → CUST_ID = :login-customer-id on nst-ordh … An order naming neither the session's
   customer nor its vendor is 404, not 403' — and it is the same rule whether a session reaches an
   order through a list filter or through a number in the URL. Without this, the only thing between one
   customer and another's order is the UNGUESSABILITY of the minted ORDNUM (prefix + financial year +
   an HMAC-truncated reference, D6): good, but a property of the NUMBER rather than a check, and this
   tree does not accept 'the key is hard to guess' as an authorization model anywhere else.

   ⚠ THE TWO ABSENCES ARE ONE ANSWER, ON PURPOSE, AND THE REASON STRING DOES NOT SEPARATE THEM. Saying
   'that order exists but is not yours' would confirm the existence of another customer's order —
   precisely the ORACLE the tenant-scoped SELECT is built to avoid. A caller that guessed a number
   learns what a caller that guessed a wrong number learns: nothing is there.

   ⚠ THIS ALSO MEANS A VENDOR SESSION CANNOT USE THE CUSTOMER PATHS AT ALL — every one of them answers
   404, which is the same answer route-ordh-list gives. The vendor's half of the spec's sentence is the
   vendor channel (/vendor/orders, DOD_VENDOR_ORDERS, S9-S11); if the batch ever wants the same paths
   to serve both parties, THIS is the one function that decides it, and it would key on
   (domain-ctx-actor ctx)'s role rather than on the session customer alone."
  (let ((customer (ordh-session-customer)))
    (cond
      ((null customer) (ordh-no-session-customer ctx))
      ((eql (cust-id header) (slot-value customer 'row-id)) header)
      (t (make-instance 'nst-entity-nil
                        :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                        :reason "No live order with that number is addressable from this session. This is a customer route and an order belongs to the session's customer (D5); whether the number is wrong, held by another tenant, soft-deleted, or another customer's order is deliberately not distinguished — a 403 here would confirm that somebody else's order exists.")))))

(defun ordh-header-from-url (request ctx)
  "The nst-ordh the URL's {ordnum} names in the session tenant AND this session's customer, or the
   sentinel that answers for it."
  (let* ((payload (params request))
         (raw (ordh-param payload :ordnum))
         (tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (ordnum (cond ((and (stringp raw) (plusp (length (string-trim " " raw))))
                        (string-trim " " raw))
                       ;; An integer is not an ORDNUM, but an agent/REPL caller may hand one over
                       ;; where apidefs2 would have handed a string — coerced rather than refused,
                       ;; exactly as the invoice's row-id guard coerces one.
                       ((integerp raw) (princ-to-string raw))
                       (t nil))))
    (unless ordnum
      (api-client-error "an order number is required in the URL (a non-blank ordnum, e.g. LGIB/25-26/00012)"))
    (let ((knowledge (with-db-call (nst-select-order-header-by-ordnum ordnum tenant-id)
                                   "nst-ordhapi/header-from-url (ordnum, session tenant)")))
      (if (eq (bo-knowledge-truth knowledge) :T)
          (let ((entity (make-instance 'nst-ordh :tenant-id tenant-id)))
            (nst-copy-order-header-dbtodomain (bo-knowledge-payload knowledge) entity)
            (ordh-header-in-session-scope entity ctx))
          (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (lambda (truth)
                     (case truth
                       (:F (format nil "No live order holds number ~A in this tenant. It does not exist, it belongs to another tenant, or it has been soft-deleted — those are one fact for every verb in this domain (नियम-2 makes a soft-deleted row invisible, and the number is consumed either way)." ordnum))
                       (:U (format nil "Could not resolve order number ~A — the database call did not answer, so whether that order exists is UNKNOWN" ordnum))
                       (:C (format nil "Order number ~A returned more than one row in this tenant — the unique index on ORDNUM is not holding, so which order the URL names cannot be decided" ordnum)))))))))

(defun ordh-request-with-header-row-id (request ctx)
  "REQUEST whose :order-id is the ROW-ID of the order the URL named by :ordnum, or the SENTINEL
   that answers for that number.

   The LINE routes need the parent's row-id — the verb locates the header by it and checks the
   (order, line) pairing against it — while the URL carries the number. The substitution happens
   here so the verbs, and orditm-check-pairing-of, are unchanged; :ordnum is REMOVED from the
   params, so nothing downstream can mistake a number for an id and silently look up the wrong
   column. This is the invoice's invh-request-with-header-row-id shape with :invnum/:invheadid
   renamed."
  (let ((header (ordh-header-from-url request ctx)))
    (if (not (typep header 'nst-ordh))
        header
        (make-instance (class-of request)
                       ;; ordh-plist-set, not list*: a client may have sent its own :order-id in a
                       ;; nested PUT body, and a duplicate key is not an override — see ordh-plist-set.
                       ;; The URL's resolution REPLACES it, which is what makes the pairing check a
                       ;; statement about the address rather than about the payload.
                       :params (ordh-plist-set (ordh-params-without (params request) :ordnum)
                                               :order-id (princ-to-string (row-id header)))))))

(defun ordh-header-row (row-id ctx)
  "The dod-order ROW with ROW-ID in the session tenant, or a sentinel. Used by the one route that
   needs the row rather than the entity — see route-ordh-update — because UPDATED is DB-managed and
   is deliberately NOT a mirrored slot (D19: an instance hydrated a moment ago would hold a stale
   value), so the version token the If-Match check compares against can only be read from the row."
  (let ((knowledge (with-db-call (nst-select-order-header-by-row-id row-id
                                                                   (slot-value (domain-ctx-tenant ctx) 'row-id))
                                 "nst-ordhapi/header-row (row-id, session tenant)")))
    (if (eq (bo-knowledge-truth knowledge) :T)
        (bo-knowledge-payload knowledge)
        (domain-sentinel-from-knowledge
         knowledge ctx
         :reason (format nil "Order row-id ~A was resolved a moment ago but its row could not be re-read, so its version cannot be checked — the precondition cannot be evaluated" row-id)))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 4 — The action verbs (Tier 2)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; Signature is uniform and fixed by DESIGN §3: (route-ordh-<action> request ctx). Plain defuns,
;;; not generics — dispatch-action resolves them with fdefinition. No domain law lives here:
;;; identity, status rules and the four-valued answers belong to the प्रत्यय in nst-bl-ordh.lisp, so
;;; the API, the internal website and a REPL caller all get the same answer from the same code.

;;; ───────────────────────────────────────────────────────────────────────────
;;; THE CREATE — a Tier-2 ASSEMBLY, not one ferry (D14)
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; hhub/core/nstoresapi.html defines POST /api/v1/orders as 'Place an order' and the legacy funnel
;;; it must mirror is create-order-from-shopcart (order/dod-bl-ord.lisp:563), which does, in order:
;;;
;;;   1. mint a context-id uuid;
;;;   2. INSERT the header (status PEN, the three N flags, NO ORDNUM — the number never had a writer,
;;;      which is S8b's whole subject — and FAR FEWER COLUMNS THAN THE CLASS DECLARES: see the trap
;;;      below, which is the reason this list describes the legacy's INTENT and not its output);
;;;   3. re-read it by context-id;
;;;   4. for each cart line: create-order-items (the product looked up by prd-id, VENDOR-ID DERIVED
;;;      FROM THE PRODUCT, then unit-price / disc-rate / qty and the six tax columns — of which the
;;;      three RATE columns never reach the row, see the trap below) and update-stock-inventory — the
;;;      product's stock DECREMENTED;
;;;   5. for each DISTINCT vendor: persist-vendor-orders (one row with that vendor's line total,
;;;      status PEN, fulfilled N, the dates, the ship address, the payment mode, storepickup, the
;;;      tenant — and no ORDNUM either), plus a UPI row, a vendor email and a web push;
;;;   6. the UI caller clears the session cart and sends the customer's email/SMS.
;;;
;;; 🚨 THE LEGACY WRITES FAR LESS THAN THAT SEQUENCE LOOKS LIKE, AND THIS ASSEMBLY DOES NOT COPY THE
;;; LEGACY'S COLUMN SET — IT WRITES MORE, CORRECTLY. MEASURED, not inferred from the code's names:
;;; persist-order (dod-bl-ord.lisp:376-412) passes initargs the dod-order VIEW CLASS does not declare
;;; (:shipaddr :shipzipcode :shipcity :shipstate :billaddr :billzipcode :billcity :billstate
;;; :billsameasship :gstnumber :gstorgname :customer-name where the class declares
;;; :ship-address-short :ship-addr-full :ship-city … :cust-name :gst-number :gst-org-name), and
;;; persist-order-items passes :cgst/:sgst/:igst where dod-order-items declares
;;; :cgst-rate/:sgst-rate/:igst-rate. CLSQL's initialize-instance on standard-db-object carries
;;; &allow-other-keys, so THE KEYWORDS ARE ACCEPTED AND DISCARDED, and attribute-value-pairs then
;;; OMITS THE UNBOUND SLOTS FROM THE INSERT. Consequence, on every legacy shopcart order: NULL
;;; addresses, NULL GST number and org name, NULL CUSTNAME, NULL SHIPPED_DATE, NULL TOTAL_DISCOUNT,
;;; NULL TOTAL_TAX — and on every legacy LINE, the three RATE columns never written at all.
;;;
;;; ⚠ SO THE FIELD SET HERE IS THE LEGACY'S *INTENT*, NOT ITS OUTPUT, and the difference is a fix
;;; rather than a divergence: nst-ordh/nst-orditm and their list-driven copiers
;;; (nst-copy-order-header-domaintodb / nst-copy-order-item-domaintodb) WRITE BY SLOT NAME, driven by
;;; *ordh-mirrored-slots* / *orditm-mirrored-slots*, so a field the client supplies REACHES the row —
;;; the addresses, cust-name, the GST identity fields and the six tax columns included. A client that
;;; posts an address and then reads the order back gets the address it posted; through the legacy
;;; funnel it would get NULL. Where the legacy's own numbers are STILL not reproduced, that is said in
;;; place (the LINE and VENDOR-ROW statuses below, and D13's absent totals roll-up).
;;;
;;; WHAT THIS ASSEMBLY TAKES FROM THE LEGACY, AND WHAT IT DELIBERATELY DOES NOT:
;;;
;;;   * the HEADER's status comes from make (DFT), NOT the legacy PEN — the decision the brief takes
;;;     and S8 implemented: the legacy reads were taught to accept both, so DFT is a legal open
;;;     status everywhere the legacy looks.
;;;   * ORDNUM IS MINTED BY make AND DENORMALISED INTO EVERY VENDOR ROW (D20). Without that stamp
;;;     the vendor channel cannot address an order this API itself created.
;;;   * the LINE and VENDOR-ROW statuses stay exactly what the legacy writers write (PEN / N). That is
;;;     a decision, and it is about ONE COLUMN rather than about the legacy's column set: the statuses
;;;     are values the legacy does write and the batch has no decision about, the one deviation the
;;;     brief names is the HEADER's, and D8's mirror-the-parent rule belongs to the nst-vordh प्रत्यय
;;;     that will own that row in S9-S11. Writing a second, unstated status policy into an interim
;;;     writer is how the header and its child rows would come to disagree without anybody deciding
;;;     they should. (Everything the legacy SILENTLY FAILED to write — see the trap above — is NOT
;;;     copied: the API writes those columns.)
;;;   * steps 5's UPI row, vendor email and web push, and step 6 entirely — see NOT IN THIS FILE,
;;;     ON PURPOSE, in the header.
;;;
;;; 🚨 THE PARTIAL-WRITE WINDOW (O3), STATED RATHER THAN PRETENDED AWAY. conflodis2 v1 runs an
;;; action verb UNWRAPPED — *action-route-transaction-function* is a no-op by default
;;; (nst-bl-conflodis2.lisp SECTION 5) — so this assembly is NOT atomic, and the suite asserts the
;;; gap as a KNOWN rather than assuming it harmless. Concretely, if a LINE insert is refused after
;;; the header is written, the client holds a DFT order with some of its lines; if the database stops
;;; answering after a line is written but before it is acknowledged, that line's presence is UNKNOWN.
;;; TWO THINGS SHRINK THE WINDOW, and both are deliberate:
;;;
;;;   (a) THE READ HALF RUNS FIRST. Every line is resolved — product, vendor, price, tax — BEFORE the
;;;       header is inserted (ordh-line-plans), so a mistyped prd-id, an unresolvable vendor state or
;;;       an inconsistent tax figure refuses with NOTHING written. The legacy discovers a bad product
;;;       after it has already inserted the header, because its cart was validated by the UI; an API
;;;       has no such luxury. The WRITE order is unchanged — header, then lines, then vendor rows —
;;;       which is what S12's acceptance criterion names.
;;;   (b) THE VENDOR ROWS ARE WRITTEN LAST, so a refused line leaves no orphan vendor row (S12 AC e).
;;;
;;; Fixing atomicity properly means a transaction seam all ~40 bound endpoints share, and it belongs
;;; in its own change.

;;; THE IDEMPOTENCY KEY (F6) ──────────────────────────────────────────────────
;;;
;;; A retried POST must not place a second order: it would burn a counter value, mint a second
;;; number, and duplicate every vendor row, with no transaction to roll any of it back. The key
;;; already exists in the data model — DOD_ORDER.CONTEXT_ID, stamped by the legacy funnel with
;;; (uuid:make-v1-uuid) — so honouring it is a route-layer decision, not a migration.
;;;
;;; ⚠ A GENERATED KEY PROTECTS NOBODY, AND SAYING SO IS THE POINT. If the client sends neither
;;; :context-id nor an Idempotency-Key header, this route GENERATES one, so that make's own
;;; bookkeeping always has a key; but a generated key is NEW on every attempt, so a retry generates a
;;; different one and places a second order. A client that wants retry-safety must SEND the key —
;;; that is what makes make's :around fire, and there is no way to invent that guarantee on its
;;; behalf.

(defun ordh-idempotency-key (payload)
  "The create's idempotency key: :context-id from the body, else the Idempotency-Key request
   header, else a freshly generated v1 uuid (see the note above for why a generated one is not a
   guarantee)."
  (let ((supplied (ordh-param payload :context-id)))
    (or (when supplied
          (let ((text (string-trim " " (princ-to-string supplied))))
            (when (plusp (length text)) text)))
        (let ((header (ordh-header-value :idempotency-key)))
          (when (and (stringp header) (plusp (length (string-trim " " header))))
            (string-trim " " header)))
        (princ-to-string (uuid:make-v1-uuid)))))

(defun ordh-replay-answer (context-id tenant-id ctx)
  "The aggregate of the order a REPEATED create already placed, NIL when this key is new, or a
   sentinel when the key could not be checked.

   🚨 WHY THE ROUTE LOOKS, WHEN make's :around ALREADY DOES. The :around returns the EXISTING header
   on a repeated :context-id — correct, and not enough: this route would then go on to insert the
   LINES a second time, so a retried POST would return the same order number with twice its lines
   and a doubled stock decrement. The :around protects the header's identity; only the assembly can
   protect its CHILDREN, because only the assembly writes them. So the lookup happens once, here,
   BEFORE anything is written, and a replay answers with what was already placed.
   ⚠ THE :around IS STILL THE AUTHORITY, and this is not a second copy of its rule: it fires on the
   residual race (two concurrent first attempts, which CONTEXT_ID's missing unique key makes
   possible — F6), and it stays the thing that decides. This only asks first.

   A key that cannot be CHECKED answers :U → 503 rather than proceeding: creating on an unconfirmed
   identity is exactly how a duplicate gets written."
  (let ((knowledge (with-db-call (nst-select-order-header-by-context-id context-id tenant-id)
                                 "nst-ordhapi/idempotency-key (context-id, session tenant)")))
    (case (bo-knowledge-truth knowledge)
      (:F nil)
      (:T (let ((entity (make-instance 'nst-ordh :tenant-id tenant-id)))
            (nst-copy-order-header-dbtodomain (bo-knowledge-payload knowledge) entity)
            (ordh-order-aggregate entity ctx)))
      (otherwise (domain-sentinel-from-knowledge
                  knowledge ctx
                  :reason (format nil "Order create: the idempotency key ~A could not be checked, so whether this request has already been placed is UNKNOWN. Refusing rather than risking a second order with a second number and a second set of vendor rows." context-id))))))

;;; THE READ HALF OF THE ASSEMBLY: one cart line → one PLAN ───────────────────
;;;
;;; A PLAN is not a request payload. It is (:args <nst-orditm initargs> :product <the dod-prd-master
;;; row> :vendor-id N), and it carries the PRODUCT OBJECT because the write half must decrement that
;;; product's stock (step 4 of the legacy) and re-selecting the row a moment later would be a second
;;; read of a row that may have moved in between.

(defun ordh-line-qty (entry)
  "The line's quantity as a positive integer, or api-client-error → 400. PRD_QTY is the one line
   field a create cannot default: it is what the order is FOR, and the stock decrement is computed
   from it."
  (let ((value (ordh-nested-param entry :prd-qty)))
    (cond ((and (integerp value) (plusp value)) value)
          ((and (stringp value) (plusp (length value)) (every #'digit-char-p value))
           (let ((n (parse-integer value)))
             (if (plusp n) n (api-client-error "a line's prd-qty must be a positive integer, got ~S" value))))
          (t (api-client-error "every line must carry a positive integer prd-qty, got ~S" value)))))

(defun ordh-line-number (entry key)
  "A line's numeric field KEY as a float, or NIL when absent, or api-client-error → 400."
  (let ((value (ordh-nested-param entry key)))
    (cond ((null value) nil)
          ((numberp value) (float value))
          ((and (stringp value) (plusp (length value))
                (every (lambda (c) (or (digit-char-p c) (member c '(#\. #\- #\+ #\e #\E)))) value))
           (handler-case (float (read-from-string value))
             (error () (api-client-error "a line's ~A must be a number, got ~S" key value))))
          (t (api-client-error "a line's ~A must be a number, got ~S" key value)))))

(defun ordh-line-unit-price (entry product)
  "The line's unit price: the body's :unit-price when supplied, else the product's CURRENT_PRICE,
   else 0.0 — the brief's rule, and the price the LINE will carry."
  (or (ordh-line-number entry :unit-price)
      (float (or (slot-value product 'current-price) 0.0))))

(defun ordh-line-disc-rate (entry product)
  "The line's discount rate: the body's :disc-rate when supplied, else the product's
   CURRENT_DISCOUNT, else 0.0."
  (or (ordh-line-number entry :disc-rate)
      (float (or (slot-value product 'current-discount) 0.0))))

(defun ordh-line-vendor (product ctx)
  "The dod-vend-profile that sells PRODUCT, resolved IN THE SESSION TENANT. Returns the VENDOR or a
   sentinel — a bo-knowledge's :T converted, or :U/:C passed through as its own sentinel.

   ⚠ THE VENDOR IS DERIVED FROM THE PRODUCT, never from the payload — the legacy rule is to read it
   through (product-vendor product) (create-order-items, order/dod-bl-odt.lisp:188), and that rule is
   kept: WHICH vendor is decided by the product's own VENDOR_ID and by nothing the caller sends. A
   client-supplied :vendor-id would be a client choosing who fulfils the order, which is the vendor
   channel's business and not the buyer's. (The legacy's JOIN is not reused for the lookup itself —
   see below, it faults unscoped.)

   🚨 IT IS RESOLVED WITH THE TENANT-SCOPED SELECTOR, AND THAT IS A FIX RATHER THAN A DETAIL.
   hhub/vendor/nst-bl-vnd.lisp:470 says it in its own docstring: select-vendor-by-id
   (vendor/dod-bl-ven.lisp:230) 'filters on deleted-state and row-id ONLY and is not tenant-scoped,
   so using it here would let a session in tenant 2 read tenant 1's vendor by guessing its row-id.
   That is OWASP API1:2023 BOLA, and it is a pre-existing hole in the legacy layer, not one this file
   may inherit.' The order batch already has the scoped selector; this uses it.
   ⚠ THE JOIN IS NOT USED FOR THE LOOKUP, and that is not a second-guessing of (product-vendor
   product): the product WAS selected tenant-scoped (select-product-by-id carries the tenant), so its
   own vendor normally belongs to the same tenant — but 'normally' is exactly the assumption a BOLA
   check exists to stop trusting, and a PRODUCT.VENDOR_ID pointing at another tenant's vendor row is a
   data state MySQL permits (nothing constrains it). Resolving through the scoped selector costs the
   SAME single SELECT the join would have faulted, and it also gives us the vendor's state (below)
   from the row the tenant is allowed to see."
  (let* ((vendor-id (slot-value product 'vendor-id))
         (tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (if (null vendor-id)
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "Product row-id ~A names no vendor, and a line cannot exist without one: ORDER_ITEMS.VENDOR_ID is NOT NULL, the vendor is DERIVED FROM THE PRODUCT rather than chosen by the caller, and the vendor row this create would write is keyed on it. Fix the product's VENDOR_ID — nothing has been written."
                                       (slot-value product 'row-id)))
        (let ((knowledge (with-db-call (select-vendor-by-id-in-tenant vendor-id tenant-id)
                                       "nst-ordhapi/line-vendor (vendor-id, session tenant)")))
          (if (eq (bo-knowledge-truth knowledge) :T)
              (bo-knowledge-payload knowledge)
              (domain-sentinel-from-knowledge
               knowledge ctx
               :reason (lambda (truth)
                         (case truth
                           (:F (format nil "Product row-id ~A names vendor row-id ~A, which is not a live vendor of this tenant — so this line has no seller to bill, no state to tax against, and no vendor row to be addressed by. That is the product's own data being inconsistent (nothing constrains PRODUCT.VENDOR_ID), and NOTHING HAS BEEN WRITTEN." (slot-value product 'row-id) vendor-id))
                           (otherwise (format nil "The vendor behind product row-id ~A could not be looked up — the database call did not answer, so this line's seller and tax treatment are UNKNOWN" (slot-value product 'row-id)))))))))))

(defun ordh-tax-product-copy (product unit-price disc-rate)
  "PRODUCT as the LEGACY TAX HELPER needs to see it: the same row, carrying the price basis the LINE
   will have.

   🚨 WHY A COPY, AND NOT A TEMPORARY setf ON THE FETCHED PRODUCT. update-gst-for-order-lineitem
   reads the TAXABLE BASE off the product's own current-price/current-discount, while the price the
   line must store may be the one the CLIENT supplied — so the helper has to be shown the resolved
   price or its taxable value describes a different sale. Writing that price onto the fetched
   instance would be a mutation of a possibly SHARED object: select-product-by-id passes
   :caching *dod-database-caching*, which is T in production (init-hhubplatform), so the row it
   returns can be the same object another thread is holding.
   The copy carries :view-database, which is what makes CLSQL fault the join slots (product-company,
   which the HSN lookup needs) from the COPY instead of answering NIL. ⚠ It is read through
   clsql-sys::view-database, the double-colon spelling, because CLSQL does not EXPORT that accessor and
   :nstores is a nickname of :com.nstores.app, which uses only :cl — an unqualified view-database would
   intern a fresh symbol here and be an undefined function at run time. (The tree already reaches for
   clsql::date+ in the same spirit.)"
  (let ((copy (make-instance (class-of product) :view-database (clsql-sys::view-database product))))
    (dolist (slot (sb-mop:class-slots (class-of product)))
      (let ((name (sb-mop:slot-definition-name slot)))
        (when (slot-boundp product name)
          (setf (slot-value copy name) (slot-value product name)))))
    (setf (slot-value copy 'current-price) (float unit-price))
    (setf (slot-value copy 'current-discount) (float disc-rate))
    copy))

(defparameter *ordh-tax-consistency-tolerance* 0.01
  "The rupee tolerance for the fallback's arithmetic check. decimal(15,2) columns round to a paisa,
   so an exactly-correct client figure can differ from the double-precision product by half of one —
   refusing THAT would be the check crying wolf. A rupee is roomy enough for rounding and far too
   tight for a different tax treatment to slip through.")

(defun ordh-line-tax-args (entry product vendor unit-price disc-rate qty tenant-id placeofsupply)
  "The line's tax and value initargs, computed BY THE LEGACY HELPER where the vendor's state is known,
   or taken from the body and CHECKED where it is not. Returns (values ARGS REFUSAL), exactly one of
   which is non-NIL — the domain's own two-value refusal shape (nst-order-header-prepare-args).

   🚨 THE INTRA/INTER-STATE RULE IS NOT RE-IMPLEMENTED HERE, and that is the whole design of this
   function. update-gst-for-order-lineitem (order/dod-bl-odt.lisp:194) is the tree's one statement of
   it: it takes the HSN code's GST values, decides intrastate vs interstate by comparing the vendor's
   state with the place of supply, and writes taxablevalue / the three RATES / the three AMOUNTS /
   totalitemval onto a line object. This calls it — on a THROWAWAY (make-instance 'dod-order-items)
   — and reads the columns back off it, so a change to the rule changes this route too. A copy of the
   arithmetic here is how two answers to 'how much GST' would come to exist.

   ⚠ THE TWO SIDES OF THAT COMPARISON COME FROM TWO DIFFERENT PLACES, and that is the legacy's own
   shape rather than an accident of this route. MEASURED at the legacy call site
   (customer/dod-ui-cus.lisp:2759,2769):
     (update-gst-for-order-lineitem lineitem itemproduct (string-upcase shipstate) (string-upcase vstate))
   — so the PLACE OF SUPPLY is the SHIPPING STATE (upcased), and the VENDOR'S STATE is
   (slot-value singlevendor 'state), the vendor row's own `state` slot. Both strings are UPCASED on
   the way in, and since the helper compares them with EQUAL an un-upcased pair would answer
   INTER-state for an intra-state sale — so this route upcases both, exactly as the caller does.
   The place of supply is threaded in from the order (:place-of-supply, else :ship-state — a line does
   not have one), and the VENDOR is the one this line resolved (vendor argument, never the payload).
   ⚠ THE VENDOR ROW ALSO CARRIES gst-state-code, AND IT IS DELIBERATELY NOT USED AS A FALLBACK. The
   legacy reads `state` and nothing else; choosing between two state columns is a GST decision (which
   one is authoritative, and what a NULL in either means), and a route that silently preferred one
   would be inventing it. A vendor whose `state` is empty therefore takes the fallback path below —
   the client's figures, checked — rather than being taxed against a guess.

   🚨 PER LINE, AGAINST THAT LINE'S OWN VENDOR — WHICH IS A DELIBERATE DIVERGENCE FROM THE LEGACY AND
   THE ONE PLACE THE LEGACY'S TAX IS SIMPLY WRONG FOR ITS OWN DATA. The legacy computes EVERY line
   against ONE vendor: `singlevendor` is (first (get-shopcart-vendorlist lstshopcart)) at the
   ship-methods page, and that single state is passed as `vstate` for the whole cart — while
   save-vendor-orders-in-db then writes ONE VENDOR ROW PER DISTINCT VENDOR, because a cart may span
   several. So a multi-vendor order taxed intra-state for a vendor in another state (or the reverse)
   is the legacy's normal case, not a corner. This route calls the helper once PER LINE with THAT
   line's vendor state, so the rule is applied to the sale it describes. Nothing else about the
   helper changes: same function, same comparison, same arithmetic.

   ⚠ THE HELPER DOES NOT COMPUTE CESS, and that is stated rather than papered over: it reads the HSN
   row's comp-cess and ignores it, so CESS_RATE and CESS_AMOUNT are left at the class initform 0.0.
   Inventing a cess figure here would be inventing tax law; the legacy line has the same hole.

   WHERE THE VENDOR'S STATE CANNOT BE RESOLVED the rule cannot be applied at all, so the client's own
   tax columns are taken — and checked, because an unchecked figure is a silently wrong tax document.
   The check is the one arithmetic the brief names and no more: TAXABLEVALUE against
   qty × price × (1 − disc/100), and TOTALITEMVAL against that base plus the supplied tax amounts.
   An inconsistent pair is a CONTRADICTION → 409: two sources disagree, and a human decides."
  (let* ((vendor-state (slot-value vendor 'state))
         (state (when vendor-state
                  (string-upcase (string vendor-state))))
         (placeofsupply (string-upcase (string (or (ordh-nested-param entry :place-of-supply)
                                                   placeofsupply
                                                   "")))))
    (if state
        (let* ((lineitem (make-instance 'dod-order-items :prd-qty qty))
               (priced (ordh-tax-product-copy product unit-price disc-rate)))
          (update-gst-for-order-lineitem lineitem priced (or placeofsupply "") state)
          (values (list :cgst (slot-value lineitem 'cgst)
                        :sgst (slot-value lineitem 'sgst)
                        :igst (slot-value lineitem 'igst)
                        :cgstamt (slot-value lineitem 'cgstamt)
                        :sgstamt (slot-value lineitem 'sgstamt)
                        :igstamt (slot-value lineitem 'igstamt)
                        :taxablevalue (slot-value lineitem 'taxablevalue)
                        :totalitemval (slot-value lineitem 'totalitemval)
                        :disc-rate disc-rate
                        ;; The discount AMOUNT is the helper's own subtrahend, not a second rule:
                        ;; it computes txvalue as qty×price − qty×price×disc/100, and this is that
                        ;; second term, which the helper never writes to a column.
                        :discount-amount (float (or (ordh-line-number entry :discount-amount)
                                                    (/ (* qty unit-price disc-rate) 100.0))))
                  nil))
        (let* ((base (* qty unit-price (- 1 (/ disc-rate 100.0))))
               (taxable (ordh-line-number entry :taxablevalue))
               (cgstamt (or (ordh-line-number entry :cgstamt) 0.0))
               (sgstamt (or (ordh-line-number entry :sgstamt) 0.0))
               (igstamt (or (ordh-line-number entry :igstamt) 0.0))
               (cessamt (or (ordh-line-number entry :cess-amount) 0.0))
               (total (ordh-line-number entry :totalitemval))
               (tolerance *ordh-tax-consistency-tolerance*))
          (cond
            ((or (null taxable) (null total))
             (values nil
                     (make-instance 'nst-entity-contradiction
                                    :tenant-id tenant-id
                                    :reason "The product's vendor does not resolve to a state, so the intra/inter-state GST rule cannot be applied, and the line did not supply both :taxablevalue and :totalitemval to be used instead. NOTHING HAS BEEN WRITTEN. Send both figures (with the tax columns they were computed from), or fix the product's vendor record — the API will not guess a tax treatment.")))
            ((or (> (abs (- taxable base)) tolerance)
                 (> (abs (- total (+ taxable cgstamt sgstamt igstamt cessamt))) tolerance))
             (values nil
                     (make-instance 'nst-entity-contradiction
                                    :tenant-id tenant-id
                                    :reason (format nil "The supplied tax figures are arithmetically inconsistent and NOTHING HAS BEEN WRITTEN: ~D × ~,2F with a ~,2F%% discount gives a taxable value of ~,2F, and the body said ~,2F; with the supplied tax amounts (~,2F CGST + ~,2F SGST + ~,2F IGST + ~,2F cess) the line total should be ~,2F and the body said ~,2F. The vendor could not be resolved to a state either, so the rule cannot be applied for you — correct the figures, or fix the product's vendor record."
                                            qty unit-price disc-rate base taxable
                                            cgstamt sgstamt igstamt cessamt
                                            (+ taxable cgstamt sgstamt igstamt cessamt) total))))
            (t (values (list :cgst (or (ordh-line-number entry :cgst) 0.0)
                             :sgst (or (ordh-line-number entry :sgst) 0.0)
                             :igst (or (ordh-line-number entry :igst) 0.0)
                             :cgstamt cgstamt
                             :sgstamt sgstamt
                             :igstamt igstamt
                             :cess-rate (or (ordh-line-number entry :cess-rate) 0.0)
                             :cess-amount cessamt
                             :taxablevalue taxable
                             :totalitemval total
                             :disc-rate disc-rate
                             :discount-amount (or (ordh-line-number entry :discount-amount)
                                                  (/ (* qty unit-price disc-rate) 100.0)))
                       nil)))))))

(defun ordh-line-plan (entry ctx tenant-id placeofsupply)
  "One cart line → a PLAN (:args :product :vendor-id), or a sentinel. NOTHING IS WRITTEN.

   The steps are the legacy's, in the legacy's order, minus its two writes: resolve the product by
   prd-id, derive the vendor FROM THE PRODUCT — through the TENANT-SCOPED selector, see
   ordh-line-vendor — resolve qty/price/disc, compute the tax columns.

   TWO ABSENCES, TWO DIFFERENT ANSWERS, and the distinction is the tree's own convention rather than
   a preference:
     * THE PRODUCT is absent here → :F → 404. nst-entity-nil, the same answer make gives when a create
       names a customer that is not this tenant's.
     * A VENDOR IS NAMED BUT NOT VISIBLE HERE (absent, soft-deleted, or another tenant's — one fact,
       as everywhere in this domain) → :F → 404 as well, for the same reason: what the caller got
       wrong is a reference, and 'there is no such vendor for you' is what an absence means.
     * THE PRODUCT NAMES NO VENDOR AT ALL (VENDOR_ID NULL) → nst-entity-contradiction → 409: nothing
       was referenced, so there is nothing to call absent — the product's own row is incomplete, and
       that is a contradiction about DATA rather than a missing reference.
   Every one of the three refuses BEFORE anything is written, which is why they can be this precise.

   PLACEOFSUPPLY IS THE ORDER'S, threaded down from the create payload: the intra/inter-state rule
   compares the VENDOR's state with where the goods are supplied, and only the order knows the second
   half. See ordh-line-tax-args."
  (let* ((raw-prd (ordh-nested-param entry :prd-id))
         (prd-id (nst-order-item-id-from-value raw-prd)))
    (unless prd-id
      (api-client-error "every line must name a product row-id (prd-id); got ~S" raw-prd))
    (let ((knowledge (with-db-call (select-product-by-id prd-id (domain-ctx-tenant ctx))
                                   "nst-ordhapi/line-product (prd-id, session tenant)")))
      (unless (eq (bo-knowledge-truth knowledge) :T)
        (return-from ordh-line-plan
          (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (lambda (truth)
                     (case truth
                       (:F (format nil "Line product row-id ~A is not a live product of this tenant, so no line can be priced for it" prd-id))
                       (otherwise (format nil "Line product row-id ~A could not be looked up — the database call did not answer, so its price and tax are UNKNOWN" prd-id)))))))
      (let* ((product (bo-knowledge-payload knowledge))
             (vendor (ordh-line-vendor product ctx)))
        (unless (typep vendor 'dod-vend-profile)
          (return-from ordh-line-plan vendor))
        (let* ((vendor-id (slot-value vendor 'row-id))
               (qty (ordh-line-qty entry))
               (unit-price (ordh-line-unit-price entry product))
               (disc-rate (ordh-line-disc-rate entry product)))
          (multiple-value-bind (tax-args refusal)
              (ordh-line-tax-args entry product vendor unit-price disc-rate qty tenant-id placeofsupply)
            (if refusal
                refusal
                (list :product product
                      :vendor-id vendor-id
                      :args (list* :prd-id prd-id
                                   :vendor-id vendor-id
                                   :prd-qty qty
                                   :unit-price unit-price
                                   ;; The line statuses are the LEGACY writer's, not the header's —
                                   ;; see the assembly note above.
                                   :status "PEN"
                                   :fulfilled "N"
                                   tax-args)))))))))

(defun ordh-line-plans (payload ctx tenant-id)
  "The create's READ HALF: every cart line resolved into a PLAN, or a refusal. Returns a NON-EMPTY
   LIST or a sentinel, and writes nothing. An absent or empty line array is a 400 (see
   ordh-lines-array); a MALFORMED line is refused too, with nothing written, because this runs before
   the header insert.

   THE PLACE OF SUPPLY IS RESOLVED ONCE, from the order: :place-of-supply is a HEADER field, and the
   tax rule needs it for every line. :ship-state is the fallback because the legacy UI passes the
   shopper's ship state into the same comparison (dod-ui-cus.lisp:2769, which hands
   update-gst-for-order-lineitem the upcased shipstate) — so an API client that states only where the
   goods go still gets the right tax treatment rather than a silent inter-state default."
  (let ((entries (ordh-lines-array payload))
        (placeofsupply (or (ordh-param payload :place-of-supply)
                           (ordh-param payload :ship-state)))
        (plans '()))
    (dolist (entry entries)
      (let ((plan (ordh-line-plan entry ctx tenant-id placeofsupply)))
        (unless (listp plan) (return-from ordh-line-plans plan))
        (push plan plans)))
    (nreverse plans)))

;;; THE WRITE HALF OF THE ASSEMBLY ────────────────────────────────────────────

(defun ordh-create-header (payload customer context-id ctx)
  "The header: the body's own initargs, with the SESSION-owned keys pinned and the nested line array
   removed. Returns an nst-ordh or a sentinel.

   :context-id AND :cust-id ARE PINNED, and pinned by REMOVING the client's pair first — a duplicate
   key in a plist is not an override (see ordh-plist-set). :cust-id comes from the session (D5); an
   inbound one is IGNORED, not honoured and not refused.
   ⚠ :cust-name IS SNAPSHOT FROM THE SESSION when the body does not supply one. It is a copy of the
   customer's name, which is why *ordh-never-writable-fields* refuses it on !update — a client that
   could rewrite it would make the order lie about who placed it. Leaving it NULL on create would
   have the same effect in the other direction, and the session already knows the answer; the
   precedence (legal-company-name → legal-name → company-name → name) is the one the document prefix
   is derived from, read through the same function."
  (let* ((body (ordh-params-with-dates
                (ordh-params-without payload
                                     :items :lines :ordnum
                                     :context-id :cust-id :cust-name)))
         (params (list* :context-id context-id
                        :cust-id (slot-value customer 'row-id)
                        :cust-name (or (ordh-param payload :cust-name)
                                       (nst-customer-document-name customer))
                        body)))
    (request->dispatch (make-instance 'NstOrdhRequestModel :params params) 'make 'nst-ordh ctx)))

(defun ordh-create-lines (plans header ctx)
  "The create's WRITE HALF for the lines, in the legacy's order per line: the line ROW, then the
   STOCK DECREMENT. Returns the created entities, or the first sentinel.

   ⚠ update-stock-inventory IS CALLED EXACTLY AS THE LEGACY CALLS IT (dod-bl-ord.lisp:528), against
   the product object the read half already resolved. It is NOT wrapped: a stock failure is a real
   failure, and swallowing it would return 201 for an order that was placed against stock nobody
   decremented. Its limits are the legacy's too — 'a rudimentary stock inventory update function',
   which sets 0 rather than a negative when the shelf is empty — and this file does not improve on it:
   the batch's job is to route, and a stock RULE belongs to whichever story owns inventory.

   SO THE PARTIAL-WRITE WINDOW IS REAL HERE: the line row exists before the decrement, so a failure
   between them leaves a line whose stock was not taken. That is why the idempotency key matters — a
   retry of the whole create returns the order it already placed instead of placing a second one."
  (let ((lines '()))
    (dolist (plan plans)
      (let ((line (request->dispatch
                   (make-instance 'NstOrditmRequestModel
                                  :params (list* :order-id (row-id header) (getf plan :args)))
                   'make 'nst-orditm ctx)))
        (unless (typep line 'nst-orditm)
          (return-from ordh-create-lines line))
        (update-stock-inventory (getf plan :product) (getf (getf plan :args) :prd-qty))
        (push line lines)))
    (nreverse lines)))

(defun ordh-vendor-line-totals (lines)
  "An alist of (VENDOR-ID . TOTAL) over LINES — ONE ENTRY PER DISTINCT VENDOR, carrying that
   vendor's own line total, which is the figure persist-vendor-orders stores in ORDER_AMT for its
   row (and NOT the order's total, which is what the legacy computes per vendor with
   get-order-items-total-for-vendor)."
  (let ((totals '()))
    (dolist (line lines)
      (let* ((vendor (vendor-id line))
             (cell (assoc vendor totals)))
        (if cell
            (incf (cdr cell) (float (or (totalitemval line) 0.0)))
            (push (cons vendor (float (or (totalitemval line) 0.0))) totals))))
    (nreverse totals)))

;;; ───────────────────────────────────────────────────────────────────────────
;;; THE INTERIM VENDOR-ROW WRITER — S9-S11 WILL MOVE THIS
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; 🚨 INTERIM HOME, ON PURPOSE, AND IT IS A DEBT WITH A NAME. DOD_VENDOR_ORDERS is the vendor
;;; channel's table, its entity is nst-vordh, and its own प्रत्यय (make/fetch/enumerate/!update/
;;; delete! with a vendor-scoped session) is S9-S11. Until that exists, the D14 assembly still has to
;;; stamp one row per distinct vendor or the hole §3b measured reopens for every order this API
;;; creates ('at least 23 orders have no vendor row at all and are therefore invisible to the vendor
;;; channel by construction'). So the row is written HERE, by the smallest possible function, and
;;; promoted to nst-vordh's make in S9-S11 — this function then DELETES, it does not get called.
;;;
;;; WHY THE LEGACY CLASS AND NOT A NEW ONE: the live table has 60 columns against this class's 26
;;; (§3), but the columns this writer needs are all declared on it, and S9's decision is explicit —
;;; nst-vordh gets its OWN class and 'the legacy dod-vendor-orders class stays untouched for the
;;; legacy UI, because extending it in place would change a live SELECT's column list as a side
;;; effect of an order change'. One slot WAS added (ORDNUM, below, with its reason); nothing else.

(defun ordh-vendor-order-insert (header vendor-id vendor-total ctx tenant-id)
  "ONE vendor row for HEADER: the fields persist-vendor-orders writes (dod-bl-ord.lisp:578) plus the
   minted ORDNUM. Returns T or a sentinel.

   ⚠ THE VENDOR-ID IS ONE THIS TENANT JUST RESOLVED (ordh-line-vendor, through
   select-vendor-by-id-in-tenant), never the legacy's unscoped read, and the row's TENANT-ID is the
   session's own — so a vendor row written here cannot name a vendor of another tenant. The legacy's
   own vendor lookup (select-vendor-by-id) has no tenant predicate at all; that is a pre-existing BOLA
   shape in the legacy layer, and this writer does not inherit it.

   ⚠ THE ORDNUM STAMP IS D20 AND IT IS THE POINT OF THIS FUNCTION: the number is denormalised INTO
   every vendor row, one row per (order, vendor), which is why S0b puts its unique index on DOD_ORDER
   only. Without the stamp, a vendor row holds no way to address the order the customer quotes.
   ⚠ THE SHIP ADDRESS IS NOW A REAL ONE, which is a difference from every legacy vendor row rather
   than a detail: the legacy header's addresses were NEVER WRITTEN (the silent initarg/INSERT trap in
   the assembly note above), so it handed this column a NIL. An API-created order carries the address
   the client supplied, and that is what is stamped here.
   ⚠ THE OTHER ADDRESS COLUMNS THE LEGACY LEAVES ALONE ARE STILL LEFT ALONE: SHIPZIPCODE / SHIPCITY /
   SHIPSTATE and the four billing columns are declared on the class and are NOT set, because
   persist-vendor-orders does not set them — it passes one ship-address string. Filling them would be
   an unstated policy change; S9's nst-vordh is where that decision belongs."
  (let ((row (make-instance 'dod-vendor-orders
                            :order-id (row-id header)
                            :cust-id (cust-id header)
                            :vendor-id vendor-id
                            :ordnum (ordnum header)          ; D20
                            :status "PEN"                    ; the legacy writer's status, see the assembly note
                            :fulfilled "N"
                            :ord-date (ord-date header)
                            :req-date (req-date header)
                            :shipped-date (shipped-date header)
                            :ship-address (or (ship-addr-full header)
                                              (ship-address-short header))
                            :payment-mode (payment-mode header)
                            :order-amt vendor-total
                            :shipping-cost (float (or (shipping-cost header) 0.0))
                            :storepickupenabled (storepickupenabled header)
                            :deleted-state "N"
                            :tenant-id tenant-id)))
    (let ((knowledge (with-nst-db-create (:source "nst-ordhapi/vendor-order (interim for nst-vordh)")
                        (clsql:update-records-from-instance row)
                        row)))
      (if (eq (bo-knowledge-truth knowledge) :T)
          t
          (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Order create: the order and its lines are written, but the VENDOR row for vendor ~A could not be (see the provenance). The vendor channel cannot address this order until that row exists — re-running the create with the same idempotency key will NOT repeat it, so this needs the row written by hand or the create repeated with a new key after the cause is fixed." vendor-id))))))

(defun ordh-create-vendor-rows (lines header ctx tenant-id)
  "One row per distinct vendor, LAST in the assembly — so a refused line leaves no orphan vendor row
   (S12 AC e). Returns T or the first sentinel."
  (dolist (cell (ordh-vendor-line-totals lines))
    (let ((written (ordh-vendor-order-insert header (car cell) (cdr cell) ctx tenant-id)))
      (unless (eq written t)
        (return-from ordh-create-vendor-rows written))))
  t)

;;; THE AGGREGATE ─────────────────────────────────────────────────────────────

(defclass ordh-detail-response (nst-response-model)
  ((header
    :initarg :header
    :accessor ordh-detail-header
    :documentation "An NstOrdhResponseModel — already ferried, not an entity.")
   (lines
    :initarg :lines
    :accessor ordh-detail-lines
    :documentation "A list of NstOrditmResponseModel, in row-id (print) order."))
  (:documentation
   "The assembled outbound shape of ONE order: the header's fields plus a nested line array.

    This is a boundary type built by an ACTION VERB, which DESIGN §3 forbids in general — and the
    dispatcher's own reverse ferry is what allows it here: (action->response …) carries an explicit
    pass-through clause for a ready-made nst-response-model, so an action that must NEST two entity
    types has a sanctioned door. The alternative — a flat [header, line, line…] array — is renderable
    today and loses exactly the nesting the spec's 'Get complete order details: line items …' asks
    for. whsapi's delete ack and the invoice's invh-detail-response went through the same door.

    ⚠ THE ACCESSORS ARE ordh-detail-header/-lines, NOT detail-header/-lines: the invoice's class
    already owns those names as accessors on the same generic functions, and sharing them would make
    two different boundary types read identically at every call site."))

(defmethod render-json ((r ordh-detail-response) (ctx domain-ctx))
  "The header's own field allowlist, SPLICED, plus a \"lines\" array — so the body is one order object
   rather than a wrapper the client has to unwrap.

   The header alist comes from render-json on NstOrdhResponseModel and each line alist from render-json
   on NstOrditmResponseModel, so this method introduces NO field of its own and cannot leak one: the
   outbound allowlist stays in exactly one place per entity. There is no render-html method — no HTML
   view for the new order entities exists, and inventing one here would be a presentation decision made
   in an API file; every registered route for this type is :json."
  (append (render-json (ordh-detail-header r) ctx)
          (list (cons "lines" (mapcar (lambda (l) (render-json l ctx)) (ordh-detail-lines r))))))

(defun ordh-detail-response-for (header lines ctx)
  "The nested outbound shape of one order: HEADER's fields plus LINES."
  (make-instance 'ordh-detail-response
                 :header (domain->response header ctx)
                 :lines (mapcar (lambda (l) (domain->response l ctx)) lines)))

(defun ordh-order-aggregate (header ctx)
  "HEADER plus its LIVE lines as the nested detail response, or the sentinel the line read answered.

   THE SENTINEL RULE, and why the naive version is wrong: if the header answers with a sentinel, that
   sentinel IS the answer for the whole read (404/409/503) — the callers of this function have already
   established that the header is a real entity. But if the LINES enumerate answers with a sentinel —
   :U, the database did not answer — then returning the header alone would tell the client 'this order
   has no lines'. That is the :U-read-as-:F collapse this tree exists to prevent, so a non-list answer
   is returned unchanged and reaches the boundary as 503 or 409.

   ⚠ THE PAGE LIMIT IS THE MAXIMUM, NOT THE DEFAULT: nst-select-order-items-by-filter caps at
   *ordh-page-max-limit* (200) rows and DEFAULTS to *ordh-page-default-limit* (50), so a nested read
   that said nothing would silently truncate a 60-line order — an aggregate that lies by omission.
   Beyond 200 lines this read still needs paging, and that is a stated limit, not a silent one."
  (let ((lines (enumerate 'nst-orditm ctx :order-id (row-id header)
                                       :limit *ordh-page-max-limit*)))
    (if (listp lines)
        (ordh-detail-response-for header lines ctx)
        lines)))

(defun route-ordh-create (request ctx)
  "कर्म = nst-ordh (and its lines, and its vendor rows): the D14 assembly. Answers the created order
   as the nested aggregate, with 201 from its binding.

   THE STEPS, in order — see the section note above for the full reasoning and the partial-write
   window:
     1. the SESSION's customer (D5), or :F → 404;
     2. the idempotency key, and a replay check — a repeated key answers what was already placed;
     3. THE READ HALF: the line array is required (an empty cart is a 400) and every line is resolved
        to a plan, with NOTHING written;
     4. the header, through the make ferry;
     5. the lines, then their stock decrements;
     6. the vendor rows, one per distinct vendor;
     7. the aggregate.

   EVERY REFUSAL BETWEEN THEM IS A SENTINEL OR A 400, and each names how far the assembly got — a
   client that receives one must be able to tell whether an order exists. That is what the reasons say.

   ⚠ IT DOES NOT REPRODUCE THE LEGACY'S COLUMN SET, AND IT SHOULD NOT: the legacy's own writes silently
   drop most of the header's identity and address fields and all three line RATE columns (measured —
   see the trap in the section note above). What the client supplies here REACHES the row, because the
   adhara entities carry every field the class declares and the copiers write by SLOT NAME. The one
   place this route deliberately stays with the legacy's value is the child rows' status (PEN / N),
   and D13's absent totals roll-up is unchanged: this assembly sums nothing into ORDER_AMT or the
   TOTAL_* columns, so a client that wants them set must send them."
  (let* ((payload (params request))
         (tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (customer (ordh-session-customer)))
    (if (null customer)
        (ordh-no-session-customer ctx)
        (let* ((context-id (ordh-idempotency-key payload))
               (replay (ordh-replay-answer context-id tenant-id ctx)))
          (if replay
              replay
              (let ((plans (ordh-line-plans payload ctx tenant-id)))
                (if (not (listp plans))
                    plans
                    (let ((header (ordh-create-header payload customer context-id ctx)))
                      (if (not (typep header 'nst-ordh))
                          header
                          (let ((lines (ordh-create-lines plans header ctx)))
                            (if (not (listp lines))
                                lines
                                (let ((vendors (ordh-create-vendor-rows lines header ctx tenant-id)))
                                  (if (eq vendors t)
                                      (ordh-detail-response-for header lines ctx)
                                      vendors)))))))))))))

(defun route-ordh-list (request ctx)
  "कर्म = the filtered nst-ordh collection, SCOPED TO THE SESSION'S CUSTOMER (D5). Calls enumerate
   directly (not via the ferry) because its arguments are query filters rather than entity initargs —
   see ordh-enumerate-args. Zero rows is a SUCCESS with an empty list, not a 404.

   The sort arguments and the page arguments are guarded BEFORE the domain sees them, so an unusable
   ?sort-by or ?limit is a 400 rather than the 500 the domain's bare errors produced.

   🔒 ?include-deleted IS DELIBERATELY NOT HONOURED, and the difference from the invoice's list is a
   decision: that flag is the internal audit caller's ('what was on this order before?'), and this is
   an external surface. नियम-2 makes a DELETED_STATE='Y' row invisible to every verb — handing an
   external client a switch that un-hides rows is exactly the widening the four-valued layer exists to
   prevent. A client that sends it is IGNORED rather than obeyed, and the reply shows live rows only.

   NOTE what is NOT validated here, deliberately: ?status passes through unvalidated. The domain only
   upcases it, so an unknown status compares against the column, matches nothing, and answers 200 with
   [] — 'this filter selected no orders' is a legitimate answer, not a malformed request."
  (let ((customer (ordh-session-customer)))
    (if (null customer)
        (ordh-no-session-customer ctx)
        (progn
          (ordh-guard-sort-args (params request))
          (apply #'enumerate 'nst-ordh ctx
                 (ordh-enumerate-args (params request) (slot-value customer 'row-id)))))))

(defun route-ordh-detail (request ctx)
  "कर्म = nst-ordh, PLUS its lines as a second crossing — two Tier-1 ferries in one action, which is
   what DESIGN §5 exists for. Answers the spec's GET /orders/{id} — 'Get complete order details: line
   items, delivery status, payment summary, and shipping address'.

   Two of those four things the header ALREADY carries (the addresses are columns, and the payment
   summary is PAYMENT_MODE plus the TOTAL_* columns, which D13 leaves un-rolled-up by decision — so a
   client must not read them as line-derived). The lines are the nested array; the delivery status is
   the header's own shipped-date / order-fulfilled columns.

   THREE SELECTS, deliberately: the header resolution (tenant-checked), enumerate's own parent
   verification, and the line query. Bypassing enumerate — calling nst-select-order-items-for-header
   directly — would save one SELECT and give the aggregate its own private path to the child rows,
   which is exactly how a read ends up skipping rules the verbs enforce."
  (let ((header (ordh-header-from-url request ctx)))
    (if (not (typep header 'nst-ordh))
        header
        (ordh-order-aggregate header ctx))))

(defun ordh-if-match-412 (row-id expected tenant-id ctx)
  "NIL when the caller's precondition holds (or none was asserted); otherwise the 412 IS WRITTEN HERE
   and the handler is aborted. Returns a sentinel only when the row itself could not be re-read.

   🚨 WHY 412 IS WRITTEN FROM THE ROUTE RATHER THAN MAPPED FROM A SENTINEL, WHICH IS WHAT THE SEAM IS
   FOR. apidefs2's classifier (api-status-for-condition / api-status-for-response) knows 400, 401, 404,
   405, 409, 500 and 503 — and NOTHING in the tree produces a 412: it exists nowhere, and the shared
   files (core/nst-bl-apidefs2.lisp, core/nst-bl-conflodis2.lisp) are not this change's to edit. But the
   distinction is the whole point of the header: RFC 9110 makes Precondition Failed a DIFFERENT answer
   from Conflict, and F13 records that the classifier has no 409 case either — so letting
   nst-order-header-if-match-refusal's sentinel fall through would report 'your validator is stale' as
   409 'two sources disagree', which is a different sentence about a different situation.
   api-write-json is the sanctioned way out: it sets the content type, sets the status, and calls
   hunchentoot:abort-request-handler — which THROWS out to hunchentoot's own catch tag, so nothing
   after it executes and the dispatcher's own error handling (which intercepts CONDITIONS, not throws)
   never sees a body to write. The body is api-error-json's shape, the same envelope every other API
   failure uses (json:encode-json-to-string under it), so a client parses 412 exactly like 400.
   THE ROW IS RE-READ FOR THIS CHECK because UPDATED is DB-managed and deliberately not a mirrored slot
   (D19) — the entity in hand holds no version token, so the comparison the domain states can only run
   against the row. One extra SELECT, on the write path only, and only when If-Match was sent."
  (when expected
    (let ((row (ordh-header-row row-id ctx)))
      (if (not (typep row 'dod-order))
          row
          (let ((refusal (nst-order-header-if-match-refusal row expected tenant-id)))
            (when refusal
              (api-write-json (api-error-json "precondition_failed" (entity-reason refusal)) 412))
            nil)))))

(defun route-ordh-update (request ctx)
  "कर्म = nst-ordh. Partial update by ORDNUM (the URL's address; see SECTION 3). Only the initargs
   actually supplied change — CLOS reinitialize-instance, in the verb.

   :ordnum IS STRIPPED, AND IT CANNOT BE *REFUSED* — because THE ADDRESS AND A BODY KEY ARE THE SAME
   PARAM. api-params-for-request merges the path parameters and the JSON body into ONE params plist, so
   the :ordnum that names the order in the URL is indistinguishable from an :ordnum a client put in the
   body. A guard that refuses :ordnum therefore refuses every legitimate request — which is exactly what
   happened the first time the invoice batch wrote one (nst-bl-invhapi.lisp:377-383). WHAT THAT COSTS,
   stated plainly: a client that sends ordnum in the body is IGNORED rather than told no, and the
   mitigation is that the response returns the row's ACTUAL ordnum — and the number is minted and
   immutable anyway (*ordh-update-stripped-initargs* strips it inside the verb too).
   THE DATES ARE COERCED before the verb sees them, or the write would put a transport string in a DATE
   column.

   🚨 :if-match IS PASSED INTO THE VERB BY CALLING !update DIRECTLY, AND IT CAN BE, BECAUSE THE DOMAIN
   WAS FIXED WHILE THIS FILE WAS BEING WRITTEN. The design is that the verb owns the precondition:
   *ordh-update-control-keys* records that ':if-match reaches this method only when the ROUTE calls the
   verb itself, and a route that forgets it loses the precondition silently' — and the ferry's !update
   method forwards only DECLARED initargs, so a ferry call would drop the key. Hence the direct call.
   ⚠ WHAT BLOCKED IT, AND WHAT THE FIX WAS: nst-order-header-update used to run its FIELD POLICY before
   it CONSUMED the control key (strip → nst-order-header-field-refusal → nst-ordh-consume-control-key),
   and that policy refuses every key that is not a writable field of nst-ordh on this channel —
   :if-match is not one, so passing it refused every legitimate If-Match update with a 409 naming
   :IF-MATCH as an escalation. The verb's own docstring now records the fix (S12) and the steps run
   control key → strip → field policy → precondition. MEASURED BY READING, not by running: nothing in
   this file executes offline.
   ⚠ SO THE KEY IS PASSED, AND THIS ROUTE STILL ASKS THE QUESTION FIRST — both, deliberately, and they
   are not two rules. THE ROUTE'S PRE-CHECK IS THE ONLY THING THAT CAN ANSWER 412: the verb's refusal is
   an nst-entity-contradiction, and api-status-for-response maps that to 409 for every route in the tree,
   so a mismatched validator reaching the client through the verb would read as 'two sources disagree'
   instead of RFC 9110's Precondition Failed. Both calls run the SAME function
   (nst-order-header-if-match-refusal, via ordh-if-match-412), so a change to the rule changes both.
   A validator that matches passes the pre-check and is then re-checked by the verb against the row it
   is about to write — which is the authority, and the only check that closes the window between the two."

  (let ((header (ordh-header-from-url request ctx)))
    (if (not (typep header 'nst-ordh))
        header
        (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
               (expected (ordh-header-value :if-match))
               (checked (ordh-if-match-412 (row-id header) expected tenant-id ctx)))
          (if checked
              checked
              (let* ((row-id (princ-to-string (row-id header)))
                     (rm (make-instance 'NstOrdhRequestModel
                                        :params (ordh-params-with-dates
                                                 (ordh-params-without (params request) :ordnum)))))
                ;; extract-domain-initargs is the ONE MOP filter, so the verb is handed exactly what the
                ;; ferry would have handed it — no second filter, no keys the ferry would drop — and
                ;; :if-match is prepended because it is precisely the key the ferry WOULD drop.
                ;; An absent header passes :if-match NIL, which the verb's consume-control-key reads as
                ;; 'no precondition asserted' (its docstring says so), not as an unmatched validator.
                (apply #'!update 'nst-ordh row-id ctx
                       (list* :if-match expected
                              (extract-domain-initargs rm 'nst-ordh)))))))))

(defun route-ordh-delete (request ctx)
  "कर्म = nst-ordh. SOFT delete by ORDNUM, and the verb's rules decide the rest: DELETED_STATE becomes
   Y, the order's LINES are soft-deleted first and the header is left UNTOUCHED if that does not fully
   succeed (so a partial failure is re-runnable), an order already converted to an invoice is refused
   (409 — the invoice is the record then), and only a DFT order may be deleted at all (409 above that:
   a PLACED order is cancelled, because the vendor rows already refer to it).

   Returns T on success, nst-entity-nil when absent (including already-deleted: नियम-2 makes those one
   fact), nst-entity-contradiction when a rule refuses.
   ⚠ THE BODY IS DISCARDED, and deliberately: delete! takes an id and the कारक and nothing else, so
   there is no field a body could carry. Building the request from the ADDRESS BY ROW-ID keeps that
   structural rather than conventional."
  (let ((header (ordh-header-from-url request ctx)))
    (if (not (typep header 'nst-ordh))
        header
        (request->dispatch
         (make-instance 'NstOrdhRequestModel
                        :params (list :row-id (princ-to-string (row-id header))))
         'delete! 'nst-ordh ctx))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 5 — Route registration
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; One line per inbound action. The route key IS the symbol the dispatcher is called with:
;;; (dispatch-route2 'route-ordh-create …). request-class is the SLOTLESS NstOrdhRequestModel — the
;;; whole payload rides in its params slot.
;;;
;;; :channel :http BECOMES (domain-ctx-channel ctx), AND THE ORDER VERBS READ IT: F5's per-channel
;;; field policy refuses :status / :order-fulfilled / :shipped-date to any channel that is not one of
;;; *ordh-internal-channels*, and an unknown or NIL channel fails CLOSED. So registering these routes
;;; :http is what makes an external PUT unable to reach a status transition by field assignment —
;;; the policy is in the domain, and this line is what arms it.
;;;
;;; required-roles / feature-flags / audit-level are CARRIED but NOT enforced by conflodis2 v1
;;; (DESIGN §4.2, §11.1, D18) — registered now so the metadata sits in one place when the PEP lands.

(register-action-route 'route-ordh-create
                       :action-verb 'route-ordh-create
                       :request-class 'NstOrdhRequestModel
                       :description "Place an order for the session's customer (D14 assembly): mint the idempotency key, write the header (status DFT, minted ORDNUM), then its lines and the stock decrements, then one vendor row per distinct vendor carrying that number (D20). Not atomic — see the partial-write window on the route; a repeated Idempotency-Key/:context-id answers what was already placed."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer admin)
                       :feature-flags '(order-domain)
                       :audit-level :full
                       :tags '(order api v1))

(register-action-route 'route-ordh-list
                       :action-verb 'route-ordh-list
                       :request-class 'NstOrdhRequestModel
                       :description "List the session customer's orders (D5 scoping), newest first. Filters: status, ordnum-like, from-date, to-date; whitelisted sort-by/sort-dir; limit/offset (default 50, capped at 200). ?include-deleted is deliberately not honoured."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer admin)
                       :feature-flags '(order-domain)
                       :audit-level :read
                       :tags '(order api v1))

(register-action-route 'route-ordh-detail
                       :action-verb 'route-ordh-detail
                       :request-class 'NstOrdhRequestModel
                       :description "One order WITH its line items, addressed by ORDNUM: the header's fields plus a nested \"lines\" array. Two Tier-1 crossings; a line read that could not be answered is reported as 503 rather than as an order with no lines."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer admin)
                       :feature-flags '(order-domain)
                       :audit-level :read
                       :tags '(order api v1))

(register-action-route 'route-ordh-update
                       :action-verb 'route-ordh-update
                       :request-class 'NstOrdhRequestModel
                       :description "Partially update an order by ORDNUM: only the supplied fields change. ISO dates are coerced; :ordnum is stripped (the address is a param, not a field); an If-Match validator is enforced by the route and answers 412 when it does not match. The status, the fulfilment flag and the shipped date are refused to this channel (F5)."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer admin)
                       :feature-flags '(order-domain)
                       :audit-level :full
                       :tags '(order api v1))

(register-action-route 'route-ordh-delete
                       :action-verb 'route-ordh-delete
                       :request-class 'NstOrdhRequestModel
                       :description "Soft-delete an order by ORDNUM, lines first, and only while it is a DFT draft: 409 once it is placed (a placed order is cancelled), 409 once it has been converted to an invoice. Returns T. The spec defines no order DELETE; this is the batch's addition (O4)."
                       :output-type :json
                       :channel :http
                       :required-roles '(customer admin)
                       :feature-flags '(order-domain)
                       :audit-level :full
                       :tags '(order api v1))


;;; ═══════════════════════════════════════════════════════════════════════
;;; SECTION 6 — Public API bindings (Ring 4)
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; The spec (hhub/core/nstoresapi.html, id 'ord', role 'Customer + Vendor') defines nine order
;;; endpoints. FIVE of them are bound here (the header CRUD plus the aggregate read) and TWO in
;;; nst-bl-orditmapi.lisp (the line endpoints) — the other two, /fulfill and /cancel, are out of
;;; scope for this batch (D3), and the two remaining spec entries are the batch and calendar reads.
;;;
;;; ⚠ A BINDING LIVES IN THE FILE THAT REGISTERS ITS VERB, whatever the URL looks like.
;;; register-api-route REFUSES a path whose action route is not already registered
;;; (api-route-bindable-p), so the ORDER of two top-level forms inside a loaded file is a BUILD-LEVEL
;;; requirement and the failure is brutal: the refusal runs at LOAD time and aborts the load of this
;;; file, which is one of the API files, so the application does not come up. THAT IS WHY THE ITEM
;;; BINDINGS ARE NOT HERE even though /orders/{ordnum}/items/{item-id} is order-scoped:
;;; route-orditm-* are registered in nst-bl-orditmapi.lisp, which loads AFTER this one. The invoice
;;; batch measured exactly this (`apidefs2: ROUTE-INVITM-CREATE is not a registered action route`,
;;; raised from nst-bl-invhapi.lisp's own fasl), and
;;; aiharness/deepseek/tools/nst-binding-order-check is the static stand-in that walks the build's own
;;; file order and asserts it.
;;;
;;; ⚠ THE SPEC'S PATHS AND THESE TEMPLATES DIFFER BY THE /hhub PREFIX, ON PURPOSE. The spec publishes
;;; /api/v1/orders; the template says /hhub/api/v1/orders. register-api-route REJECTS a template without
;;; the prefix (api-path-deployment-prefix-p), because the deployed nginx proxies `location /hhub/`
;;; through unchanged and rewrites every other URI to /hhub/$1 — so a client calling /api/v1/orders
;;; arrives as /hhub/api/v1/orders and matches this template.
;;;
;;; ⚠ NO :inject-company ANYWHERE, and that is a real difference from the warehouse bindings: nst-ordh
;;; has no legacy COMPANY slot (its tenant is the INHERITED tenant-id, set by the ferry from domain-ctx,
;;; which make-action-domain-ctx built from the session login company), so the tenant reaches the domain
;;; with no help from the API layer (नियम-1) and injecting :company would push an initarg at verbs that
;;; do not declare it.
;;;
;;; {ordnum} IS THE ORDER NUMBER and becomes :ordnum; {item-id} is the LINE's row-id and becomes
;;; :row-id. api-params-for-request puts path params ahead of the body, so a client cannot displace
;;; either through the payload — which is what makes the route layer's (order, line) pairing check
;;; meaningful rather than decorative. A path segment must be at least three characters for the matcher
;;; (api-param-segment-p), and ordnum/item-id both are.
;;;
;;; ⚠ AN ORDNUM IS ONE PATH SEGMENT, AND A SLASH IN ONE WOULD BE UNADDRESSABLE — measured, not
;;; hypothesised, by asking find-api-route for a four-segment path in the offline image: it answers
;;; NIL, so the router cannot tell a number containing / from a longer path. The LIVE format is safe
;;; (*nst-order-number-format* = "ORD-{prefix}-{fy}-{ref:6}", core/dod-bl-utl.lisp:1369 — hyphens
;;; only), and a DERIVED prefix is alphanumeric by construction (nst-doc-prefix-base requires at least
;;; three alphanumerics). But DOC_PREFIX can be set BY HAND, and the allocator's own error message
;;; says so, so a hand-set prefix containing / would mint numbers this API cannot address. A client
;;; percent-encodes the rest as usual (%2F is decoded by hunchentoot before the path is split here, so
;;; it does NOT help); the durable fix, if it is ever wanted, is to constrain DOC_PREFIX — recorded
;;; rather than discovered by whoever first mints such a number.
;;;
;;; BODIES carry nst-ordh / nst-orditm INITARG names ("ordDate", "shipCity", "placeOfSupply", "prdId",
;;; "prdQty", …), not DB column spellings; camelCase is accepted. A body-supplied "tenant-id"/"id" is
;;; stripped by the ferry as reserved, and "ordnum"/"order-id" from a body cannot displace the URL's
;;; values.

(register-api-route 'route-ordh-create
                    :method :post
                    :path "/hhub/api/v1/orders"
                    :success-status 201
                    :auth-scope :session
                    :description "Spec: POST /api/v1/orders — place an order for the session's customer. Body: an object of nst-ordh field names plus an \"items\"/\"lines\" array of nst-orditm field names; AT LEAST ONE line is required (an empty cart is 400, and there is no add-line endpoint), and prd-id and prd-qty are required per line (unit-price/disc-rate default to the product's current price/discount; the tax columns come from the product's HSN and THAT line's vendor state). Send an Idempotency-Key header (or a context-id) to make a retry safe: a repeat answers the order already placed. 400 for a malformed line, an empty cart, or a non-ISO date; 404 when the session has no customer, or a line names a product this tenant cannot see; 409 when a line's tax figures contradict its own arithmetic, or the product names no vendor; 503 when the database could not be reached. NOT ATOMIC: a refused line leaves a draft order with the lines already written — see the route's note.")

(register-api-route 'route-ordh-list
                    :method :get
                    :path "/hhub/api/v1/orders"
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: GET /api/v1/orders — list the session customer's orders. Query params: status, ordnum-like, from-date, to-date, sort-by, sort-dir, limit, offset. An empty result is 200 with [], not 404; an unusable sort-by or limit is 400. The vendor half of the spec's sentence ('vendors see orders pending fulfilment') is the vendor channel, /vendor/orders, not this path.")

(register-api-route 'route-ordh-detail
                    :method :get
                    :path "/hhub/api/v1/orders/{ordnum}"
                    :path-params '(("ordnum" . :ordnum))
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: GET /api/v1/orders/{id} — complete order details: the header's fields plus a nested \"lines\" array. 404 when no live order holds that number in this tenant (absent, another tenant's, or soft-deleted — one fact for every verb); 503 (not 404) when the database could not be reached, including when the LINES could not be read.")

(register-api-route 'route-ordh-update
                    :method :put
                    :path "/hhub/api/v1/orders/{ordnum}"
                    :path-params '(("ordnum" . :ordnum))
                    :success-status 200
                    :auth-scope :session
                    :description "Spec: PUT /api/v1/orders/{id} (the batch's reading: the spec's list has no order PUT, and content may change at any status except terminal — the verb's rule). Body: an object of nst-ordh field names; only the fields supplied change; dates must be YYYY-MM-DD (400 otherwise). An If-Match validator is enforced and answers 412 when the order changed after the caller read it. Status, fulfilment flag and shipped date are refused on this channel (409, F5).")

(register-api-route 'route-ordh-delete
                    :method :delete
                    :path "/hhub/api/v1/orders/{ordnum}"
                    :path-params '(("ordnum" . :ordnum))
                    :success-status 200
                    :auth-scope :session
                    :description "Soft-delete a DFT order and its lines, by number. The spec defines no order DELETE; this is the batch's addition (O4) and the invoice precedent is the opposite, because GST forbids deleting an issued invoice while an order has no such bar before invoicing. 409 once the order is placed or has been converted to an invoice; 404 when no live order holds the number. Answers {\"ok\":true,\"operation\":\"delete\"}.")

;;; End of nst-bl-ordhapi.lisp
