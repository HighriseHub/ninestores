;;; nst-bl-vaisettings.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;;; ----------------------------
;;;; Vendor setting registry
;;;; ----------------------------

(defparameter *vendor-setting-registry*
  '(;; ---- :invoice ------------------------------------------------------------
    (:key nst.vendor.invoicesetting.send-invoice-email-after-paid
     :domain :invoice
     :data-type :boolean
     :description "Send invoice email immediately after payment"
     :keywords ("send" "email" "invoice" "paid"))

    (:key nst.vendor.invoicesetting.attach-pdf-to-invoice-email
     :domain :invoice
     :data-type :boolean
     :description "Attach the invoice PDF to the email"
     :keywords ("attach" "pdf" "invoice" "email"))

    (:key nst.vendor.invoicesetting.invoice-number-prefix
     :domain :invoice
     :data-type :string
     :description "Prefix used when generating invoice numbers"
     :keywords ("prefix" "number" "invoice" "series"))

    (:key nst.vendor.invoicesetting.invoice-print-font-size
     :domain :invoice
     :data-type :number
     :description "Font size used when printing the invoice"
     :keywords ("font" "size" "print" "invoice"))

    (:key nst.vendor.invoicesetting.invoice-terms-in-days
     :domain :invoice
     :data-type :number
     :description "Payment terms in days printed on the invoice"
     :keywords ("terms" "days" "credit" "due"))

    ;; ---- :payment ------------------------------------------------------------
    (:key nst.vendor.paymentsetting.accept-cash-on-delivery
     :domain :payment
     :data-type :boolean
     :description "Allow customers to pay cash on delivery"
     :keywords ("cash" "delivery" "cod" "payment"))

    (:key nst.vendor.paymentsetting.gateway-provider
     :domain :payment
     :data-type :string
     :description "Payment gateway used for online payments"
     :keywords ("gateway" "provider" "online" "payment"))

    (:key nst.vendor.paymentsetting.auto-refund-on-cancellation
     :domain :payment
     :data-type :boolean
     :description "Refund automatically when an order is cancelled"
     :keywords ("refund" "cancel" "money" "automatic"))

    ;; ---- :shipping -----------------------------------------------------------
    (:key nst.vendor.shippingsetting.free-shipping-above-amount
     :domain :shipping
     :data-type :number
     :description "Order value above which shipping is free"
     :keywords ("free" "shipping" "above" "amount"))

    (:key nst.vendor.shippingsetting.default-shipping-charge
     :domain :shipping
     :data-type :number
     :description "Shipping charge applied when not free"
     :keywords ("charge" "shipping" "flat" "fee"))

    (:key nst.vendor.shippingsetting.ship-only-within-state
     :domain :shipping
     :data-type :boolean
     :description "Restrict shipping to within the vendor's state"
     :keywords ("state" "restrict" "local" "deliver"))

    ;; ---- :tax ----------------------------------------------------------------
    (:key nst.vendor.taxsetting.default-gst-rate
     :domain :tax
     :data-type :number
     :description "Default GST rate applied to products"
     :keywords ("gst" "rate" "tax" "percent"))

    (:key nst.vendor.taxsetting.show-tax-inclusive-prices
     :domain :tax
     :data-type :boolean
     :description "Display prices inclusive of tax"
     :keywords ("inclusive" "tax" "price" "display"))

    ;; ---- :inventory ----------------------------------------------------------
    (:key nst.vendor.inventorysetting.low-stock-alert-threshold
     :domain :inventory
     :data-type :number
     :description "Stock level at which a low-stock alert is raised"
     :keywords ("stock" "low" "alert" "threshold"))

    (:key nst.vendor.inventorysetting.allow-backorders
     :domain :inventory
     :data-type :boolean
     :description "Accept orders when stock is zero"
     :keywords ("backorder" "out" "stock" "zero"))

    ;; ---- :notification -------------------------------------------------------
    (:key nst.vendor.notificationsetting.order-confirmation-sms
     :domain :notification
     :data-type :boolean
     :description "Send an SMS when an order is placed"
     :keywords ("sms" "order" "confirmation" "mobile"))

    (:key nst.vendor.notificationsetting.daily-sales-summary-email
     :domain :notification
     :data-type :boolean
     :description "Email a daily sales summary"
     :keywords ("daily" "summary" "sales" "report"))

    ;; ---- :orders -------------------------------------------------------------
    (:key nst.vendor.ordersetting.minimum-order-value
     :domain :orders
     :data-type :number
     :description "Minimum order value accepted"
     :keywords ("minimum" "order" "value" "cart"))

    (:key nst.vendor.ordersetting.cancellation-window-hours
     :domain :orders
     :data-type :number
     :description "Hours within which a customer may cancel"
     :keywords ("cancellation" "window" "hours" "cancel"))

    ;; ---- :profile ------------------------------------------------------------
    (:key nst.vendor.profilesetting.store-display-name
     :domain :profile
     :data-type :string
     :description "Public name shown to customers"
     :keywords ("store" "name" "display" "shop"))

    ;; ---- :security -----------------------------------------------------------
    (:key nst.vendor.securitysetting.two-factor-login-required
     :domain :security
     :data-type :boolean
     :description "Require two-factor authentication for vendor login"
     :keywords ("factor" "login" "authentication" "secure"))

    ;; ---- :loyalty ------------------------------------------------------------
    (:key nst.vendor.loyaltysetting.points-per-rupee
     :domain :loyalty
     :data-type :number
     :description "Loyalty points awarded per rupee spent"
     :keywords ("loyalty" "points" "reward" "rupee"))))


;;;; ----------------------------
;;;; Intent CLOS class
;;;; ----------------------------

(defclass intent ()
  ((actor       :initarg :actor       :accessor intent-actor)
   (domain      :initarg :domain      :accessor intent-domain)
   (operation   :initarg :operation   :accessor intent-operation)
   (description :initarg :description :accessor intent-description)
   (raw-text    :initarg :raw-text    :accessor intent-raw-text)
   (trace       :initarg :trace       :accessor intent-trace)))


(defun make-intent (&key actor domain operation description raw-text trace)
  (make-instance 'intent
                 :actor actor
                 :domain domain
                 :operation operation
                 :description description
                 :raw-text raw-text
                 :trace trace))


(defparameter prompt-for-llm "You are an intent extraction engine for a Common Lisp system.

Your task:
- Convert user text into a structured intent object.
- Do NOT infer system-specific identifiers.
- Do NOT guess setting keys.
- Do NOT execute actions.
- Preserve the user's words faithfully.

Return output ONLY as a Common Lisp property list.

Schema (MANDATORY):
(:actor <number>
 :domain <keyword>
 :operation <keyword>
 :description <string>
 :raw-text <string>
 :trace ((:origin . <keyword>)
         (:session . <string>)))

Rules:
- :actor is always a number.
- :domain must be a single keyword.
- :operation must be one keyword.
- :description is a short normalized summary.
- :raw-text is %user-input%.
- If uncertain, choose the most likely domain but NEVER invent new fields.
- No explanations.
- No markdown.")


(defun build-llm-prompt (text user-input)
  (setf text (cl-ppcre:regex-replace-all "%user-input%" text user-input))
  text)
 
;;;; ----------------------------
;;;; Naive LLM stub
;;;; Replace later with real LLM
;;;; ----------------------------

(defun llm->intent (text)
  (let* ((prompt (build-llm-prompt prompt-for-llm text))
         (response (llm-generate prompt))
         (plist (read-from-string response)))
    (apply #'make-intent plist)))


;;;; ----------------------------
;;;; Scoring & resolution
;;;; ----------------------------

(defun tokenize (text)
  (mapcar #'string-downcase
          (split-sequence:split-sequence #\Space text)))

(defun score-setting (intent setting)
  (let* ((intent-tokens (tokenize (intent-description intent)))
         (keywords (getf setting :keywords))
         (matches (count-if (lambda (k)
                              (member k intent-tokens :test #'string=))
                            keywords)))
    (/ (float matches) (max 1 (length keywords)))))




;;;; ----------------------------
;;;; LLM matcher & confidence fusion
;;;;
;;;; The keyword scorer is no longer the DECIDER. It is kept as a second,
;;;; independent signal: a model that is `certain` about a setting whose
;;;; keywords do not appear at all in the request is exactly the case we must
;;;; not auto-execute.
;;;; ----------------------------

(defparameter prompt-for-match "You are a setting matcher for a Common Lisp system.

You are given a user request and a CLOSED list of candidate settings.
Choose the ONE candidate that best matches the request, or none if none match.

Rules:
- The key must be one of the candidate keys below, copied EXACTLY.
- Never invent, translate, abbreviate or reformat a key.
- Match on MEANING, not spelling: \"payment is done\" and \"paid\" are the same.
- confidence is exactly one of: certain, likely, unsure.
  certain = correct enough to apply without asking a human.
  likely  = probably correct, but a human should confirm first.
  unsure  = the request does not clearly identify any candidate.
- value is the value stated in the request, as TEXT, or null if none is stated.
  For a yes/no setting use \"true\" or \"false\". An imperative such as \"stop
  emailing the invoice\" states the value \"false\".
- If no candidate matches, set key to null.
- reason is at most 20 words.
- Reply with ONE JSON object and nothing else. No markdown, no commentary.

Reply format:
{\"key\": \"<candidate key or null>\", \"confidence\": \"certain|likely|unsure\", \"value\": \"<stated value as text, or null>\", \"reason\": \"<why>\"}

User request: %user-input%

Candidates:
%candidates%")

(defun trim-token (s)
  (when (stringp s) (string-trim '(#\Space #\Tab #\Newline #\Return) s)))

(defun setting-candidates-for (intent)
  "Stage-1 router. Narrow the registry by :domain (INTENT_DOMAIN in
DOD_VENDOR_SETTINGS_DEFINITION) BEFORE anything reaches the model, so prompt size
stops growing with the number of settings. This is the single recall seam: swap
it for embeddings later and nothing else changes. Falls back to the full registry
when the model returns a domain no setting declares."
  (let ((scoped (remove-if-not (lambda (s) (eq (getf s :domain) (intent-domain intent)))
                               *vendor-setting-registry*)))
    (or scoped *vendor-setting-registry*)))

(defun build-match-prompt (text candidates)
  (build-llm-prompt
   (cl-ppcre:regex-replace-all
    "%candidates%" prompt-for-match
    (format nil "~{~A | ~A~%~}"
            (loop for s in candidates
                  append (list (getf s :key) (getf s :description)))))
   text))

(defun extract-json-object (reply)
  "Models wrap JSON in markdown fences often enough that it must be tolerated."
  (let ((start (position #\{ reply))
        (end (position #\} reply :from-end t)))
    (if (and start end (< start end)) (subseq reply start (1+ end)) reply)))

(defun parse-match-reply (reply)
  (when reply
    (handler-case
        (let* ((obj (json:decode-json-from-string (extract-json-object reply)))
               (conf (trim-token (cdr (assoc :confidence obj))))
               ;; allowlist, same principle as the keys
               (name (and conf (first (member (string-upcase conf)
                                              '("CERTAIN" "LIKELY" "UNSURE")
                                              :test #'string=)))))
          (list :key (trim-token (cdr (assoc :key obj)))
                :confidence (and name (intern name :keyword))
                :value (trim-token (cdr (assoc :value obj)))
                :reason (cdr (assoc :reason obj))))
      (error () (list :key nil :confidence :unsure
                      :reason "unparseable model reply")))))

(defun find-registry-setting (key-string candidates)
  "Allowlist check: the model's answer resolves only if it names one of the
candidates we actually sent. Model output is never interned into a package."
  (let ((k (trim-token key-string)))
    (and k (find (string-downcase k) candidates
                 :key (lambda (s) (string-downcase (string (getf s :key))))
                 :test #'string=))))

(defun setting-corroboration (text setting)
  "The same arithmetic as score-setting, but against the RAW user text. Scoring
against the model's own :description would not be an independent signal."
  (let ((tokens (tokenize text))
        (keywords (getf setting :keywords)))
    (/ (float (count-if (lambda (k) (member k tokens :test #'string=)) keywords))
       (max 1 (length keywords)))))

(defun match-setting (text candidates)
  (let ((reply (llm-generate (build-match-prompt text candidates))))
    (or (parse-match-reply reply)
        (list :key nil :confidence :unsure :reason "no model reply"))))

(defun stated-number-p (raw)
  "True only when the request actually stated a number. Nothing else may reach a
:number setting, or a missing value would silently coerce to 0."
  (let ((s (trim-token raw)))
    (and s (parse-integer s :junk-allowed t) t)))

(defun coerce-setting-value (raw data-type)
  "Values arrive as TEXT because JSON false and JSON null both decode to NIL,
so a boolean cannot otherwise be told apart from an absent value. For a boolean,
an imperative with no stated value means ENABLE; \"false\"/\"no\"/\"off\"
disables."
  (let* ((s (trim-token raw))
         (flat (and s (string-downcase s))))
    (ecase data-type
      (:boolean (not (member flat '("false" "no" "off" "disable" "disabled" "0")
                             :test #'string=)))
      (:number (or (and flat (parse-integer flat :junk-allowed t)) 0))
      (:string (or s "")))))

(defun decide-setting (text match candidates)
  "Fuse two independent signals into one action.

model-confidence : an ORDINAL (certain/likely/unsure), not a float. A model's
                   self-reported probability is unstable across retries; a
                   3-way ordinal is what it is actually good at.
corroboration    : deterministic keyword overlap for the SAME setting, 0..1.

Autonomy requires BOTH: the model is certain AND the lexical signal agrees the
setting is at least partly about this request. Everything else asks. Returns the
registry plist plus the decision, so :key and :data-type survive for the caller."
  (let* ((setting (find-registry-setting (getf match :key) candidates))
         (confidence (getf match :confidence))
         (corroboration (if setting (setting-corroboration text setting) 0.0))
         (evidence (list :model-confidence confidence
                         :corroboration corroboration
                         :value (getf match :value)
                         :reason (getf match :reason))))
    (cond
      ((null setting)
       (append (list :action :abstain :key nil) evidence
               (list :candidates candidates)))
      ((eq confidence :unsure)
       (append (list :action :abstain :key (getf setting :key)) evidence
               (list :candidates candidates)))
      ((and (eq confidence :certain) (plusp corroboration)
            (or (not (eq (getf setting :data-type) :number))
                (stated-number-p (getf match :value))))
       (append setting (list :action :execute) evidence))
      (t
       (append setting (list :action :confirm) evidence
               (list :candidates candidates))))))

(defun resolve-setting (intent)
  (let ((candidates
          (mapcar (lambda (s)
                    (list :key (getf s :key)
                          :score (score-setting intent s)
                          :data-type (getf s :data-type)))
                  *vendor-setting-registry*)))
    (sort candidates #'> :key (lambda (c) (getf c :score)))))


(defun select-setting (candidates)
  (let ((top (first candidates)))
    (cond
      ((>= (getf top :score) 0.9)
       top)
      ((>= (getf top :score) 0.7)
       (list :needs-confirmation candidates))
      (t
       (list :ambiguous candidates)))))


;;;; ----------------------------
;;;; Execution layer
;;;; ----------------------------

(defun execute-setting (&key vendor-id setting-key value data-type context-id trace)
  ;; type validation
  (unless (typep value
                 (ecase data-type
                   (:boolean 'boolean)
                   (:number 'number)
                   (:string 'string)
                   (:json 'list)))
    (error "Invalid value type"))

  ;; placeholder for real persistence
  (format t "~%[EXECUTE] vendor=~A key=~A value=~A context=~A trace=~A~%"
          vendor-id setting-key value context-id trace)

  t)


(defun build-execution-context (intent resolved-setting value)
  (execute-setting
   :vendor-id (intent-actor intent)
   :setting-key (getf resolved-setting :key)
   :value value
   :data-type (getf resolved-setting :data-type)
   :context-id (cdr (assoc :session (intent-trace intent)))
   :trace (intent-trace intent)))


;;;; ----------------------------
;;;; Decision log
;;;;
;;;; One JSON object per line, append-only. This is the calibration dataset: the
;;;; empirical agreement rate per :model-confidence level IS the probability, and
;;;; nothing else in this file can produce it. `wc -l` is the sample count, jq or
;;;; grep is the query. The full candidate shortlist is recorded so a decision can
;;;; be replayed offline against the exact choices the model saw.
;;;;
;;;; Written BEFORE execution, so a decision that then failed is still on record.
;;;; ----------------------------

(defparameter *decision-log-path*
  "/home/ubuntu/ninestores/logs/vendor-settings-decisions.log")

(defun decision-log-id ()
  (format nil "~A-~D" (get-universal-time) (random 100000)))

(defun decision-log-stamp ()
  "Readable and lexicographically sortable; machine-local time, no offset."
  (multiple-value-bind (s mi h d mo y) (get-decoded-time)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D" y mo d h mi s)))

(defun decision-log-key (key)
  "Keys are logged as STRINGS. cl-json camelCases a symbol when encoding it
(FREE-SHIPPING-ABOVE-AMOUNT becomes freeShippingAboveAmount), which would
silently stop the log matching the registry."
  (and key (string-downcase (string key))))

(defun record-decision (text intent candidates decision value)
  "Never let logging break a decision: a full disk must not stop the system."
  (handler-case
      (progn
        (ensure-directories-exist *decision-log-path*)
        (with-open-file (s *decision-log-path* :direction :output
                                              :if-exists :append
                                              :if-does-not-exist :create)
          (format s "~A~%"
                  (json:encode-json-to-string
                   (list (cons "id" (decision-log-id))
                         (cons "time" (decision-log-stamp))
                         (cons "text" text)
                         (cons "domain" (and (intent-domain intent)
                                             (string-downcase (string (intent-domain intent)))))
                         (cons "candidate-count" (length candidates))
                         (cons "candidate-keys"
                               (mapcar (lambda (s) (decision-log-key (getf s :key)))
                                       candidates))
                         (cons "key" (decision-log-key (getf decision :key)))
                         (cons "action" (decision-log-key (getf decision :action)))
                         (cons "confidence" (decision-log-key (getf decision :model-confidence)))
                         (cons "corroboration" (getf decision :corroboration))
                         (cons "value-raw" (getf decision :value))
                         (cons "value-used" value)
                         (cons "reason" (getf decision :reason)))))))
    (error (e) (format t "~&[DECISION-LOG-FAILED] ~A~%" e))))


;;;; ----------------------------
;;;; Orchestration
;;;; ----------------------------

(defun run-intent (text)
  (let* ((intent (llm->intent text))
         (candidates (setting-candidates-for intent))
         (decision (decide-setting text (match-setting text candidates) candidates))
         (execute-p (eq (getf decision :action) :execute))
         (value (and execute-p
                     (coerce-setting-value (getf decision :value)
                                           (getf decision :data-type)))))
    (record-decision text intent candidates decision value)
    (if execute-p
        (build-execution-context intent decision value)
        decision)))


;;;; ----------------------------
;;;; Example
;;;; ----------------------------

;; (run-intent  "set vendor invoice setting send email after invoice payment is done")
