;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)



(defparameter *ollama-url* "http://192.168.0.101:11434/api/generate")
(defparameter *ollama-model* "qwen3.5:latest")
(defvar *dod-vend-profile-table* "/home/ubuntu/ninestores/hhub/vendor/templates/dod-vend-profile.txt")
(defvar *dod-invoice-header-table* "/home/ubuntu/ninestores/hhub/vendor/templates/dod-invoice-header.txt")
(defvar *dod-invoice-items-table* "/home/ubuntu/ninestores/hhub/vendor/templates/dod-invoice-items.txt")

(defun call-local-llm (prompt &key
                               (max-tokens 500)
                               (temperature 0.1)
                               (model *ollama-model*))
  "Calls local Ollama instance.
   Low temperature for structured extraction tasks.
   Higher temperature only for narrative generation."
  (let* ((request-body
           (json:encode-json-to-string
             `(("model"  . ,model)
               ("prompt" . ,prompt)
               ("stream" . nil)
               ("options" .
                 (("temperature"  . ,temperature)
                  ("num_predict"  . ,max-tokens)
                  ("num_ctx"      . 8192))))))
         (response
           (drakma:http-request
             *ollama-url*
             :method :post
             :content-type "application/json"
             :content request-body)))
    (let* ((parsed   (json:decode-json-from-string
                       (flexi-streams:octets-to-string response)))
           (text     (cdr (assoc :response parsed))))
      text)))

(defun ollama-generate (prompt &key system)
  (let* ((payload
           (json:encode-json-to-string
            `((:model . ,*ollama-model*)
              (:prompt . ,prompt)
              (:system . ,system)
              (:stream . nil))))
	 (raw-response
           (drakma:http-request
            *ollama-url*
            :method :POST
	    :content payload
            :content-type "application/json"))
         (json-response
           ;;(json:decode-json-from-string
            (parse-ollama-ndjson (map 'string #'code-char raw-response))))
    json-response))


(defun parse-ollama-ndjson (string)
  (let ((out ""))
    (dolist (line (split-sequence:split-sequence #\Newline string))
      (when (> (length line) 0)
        (let* ((obj (json:decode-json-from-string line))
              (chunk (cdr (assoc :RESPONSE obj))))
            (setf out (concatenate 'string out chunk)))))
    out))

(defparameter *sql-schema-rules*
  "Rules:
- Use only tables and columns from the schema
- Do not invent tables or columns
- Do not explain the query
- Vendors are identified by VENDOR_ID
- Soft deletes use DELETED_STATE = 'N'
- ACTIVE_FLAG = 'Y' means active
- Monetary fields are DECIMAL
- Never select PASSWORD, SALT, API keys
- Default tenant isolation: TENANT_ID = :tenant_id
- Return only SQL
If the request cannot be answered using the schema,
return:
ERROR: CANNOT_GENERATE_SQL")

(defun nl-to-sql (natural-language)
  (let ((sql-schema (format nil "~A ~A ~A "
	  (funcall (nst-get-cached-vendor-tables-structure-for-agentic-ai :templatenum 1))
	  (funcall (nst-get-cached-vendor-tables-structure-for-agentic-ai :templatenum 2))
	  (funcall (nst-get-cached-vendor-tables-structure-for-agentic-ai :templatenum 3)))))
    (ollama-generate
     (format nil
             "Database Schema:
~A
~A 
User Request:
~A"
           sql-schema *sql-schema-rules* natural-language)
   :system
   "You are a MySQL query generator. Return a complete SQL query.
The query must end with a semicolon.")))

(defun ollama-lisp-help (code)
  (ollama-generate
   code
   :system
   "You are a senior Common Lisp developer.
Explain idiomatic Lisp usage, macros, closures,
and functional design. Be precise and concise."))

(defun unsafe-sql-p (sql)
  (or (search "DROP" sql :test #'char-equal)
      (search "TRUNCATE" sql :test #'char-equal)
      (search "ALTER" sql :test #'char-equal)
      (search "DELETE" sql :test #'char-equal)))

(defun safe-nl-to-sql (input)
  (let ((sql (nl-to-sql input)))
    (if (unsafe-sql-p sql)
        (error "Unsafe SQL generated: ~A" sql)
        sql)))





(meta intake-chat-message
  '((:description . "First function called for every chat message.
                      Writes raw message to CHAT_SIGNAL.
                      Returns row_id for downstream processing.")
    (:domain      . :chat)
    (:category    . :intake)
    (:inputs  . (((:name . entity-id)   (:type . string) (:required . t) (:source . :parameter))
                 ((:name . entity-type) (:type . string) (:required . t) (:source . :parameter))
                 ((:name . message)     (:type . string) (:required . t) (:source . :parameter))
                 ((:name . tenant-id)   (:type . integer)(:required . t) (:source . :parameter))))
    (:outputs . (((:name . chat-signal-id) (:type . integer) (:binds-as . :chat-signal-id))))
    (:reads   . ())
    (:writes  . (:dod-procure-chat-signal))
    (:throws  . (:db-error))
    (:pure    . nil)
    (:cost    . :low)))

(defun intake-chat-message (entity-id entity-type message tenant-id)
  (clsql:execute-command 
    (format nil "INSERT INTO DOD_PROCURE_CHAT_SIGNAL
     (TENANT_ID, ENTITY_ID, ENTITY_TYPE, RAW_MESSAGE,
      CHANNEL, CLASSIFICATION, EXTRACTED,
      CONFIDENCE, STATUS)
     VALUES ('~A', '~A', '~A', '~A', 'CHAT', 'PENDING', '{}', 0.0, 'NEW');"
	    tenant-id entity-id entity-type message)))


(meta classify-chat-message
  '((:description . "Calls local Ollama LLM to classify a chat message
                      and extract structured intent or facts.
                      This is Touch Point 1 — the only LLM call in
                      the profile update flow.")
    (:domain      . :chat)
    (:category    . :classification)
    (:inputs  . (((:name . chat-signal-id) (:type . integer) (:required . t) (:source . :parameter))
                 ((:name . entity-type)    (:type . string)  (:required . t) (:source . :parameter))))
    (:outputs . (((:name . classification) (:type . json) (:binds-as . :classification))))
    (:reads   . (:dod-procure-chat-signal))
    (:writes  . (:dod-procure-chat-signal))
    (:throws  . (:llm-error :db-error))
    (:pure    . nil)
    (:cost    . :medium)))

(defun classify-chat-message (chat-signal-id entity-type)
  (let* ((row     (fetch-chat-signal chat-signal-id))
         (message (getf row :raw-message))
         (prompt  (build-classification-prompt message entity-type))
         (raw     (call-local-llm prompt
                    :temperature 0.0
                    :max-tokens  400))
         (parsed  (extract-json-from-llm-response raw)))

    ;; Update the CHAT_SIGNAL row with classification result
    (when parsed
      (clsql:execute-command
        (format nil "UPDATE DOD_PROCURE_CHAT_SIGNAL
         SET CLASSIFICATION     = ~A,
             EXTRACTED          = ~A,
             CONFIDENCE         = ~A,
             SIGNAL_TYPE        = ~A,
             STATUS             = 'CLASSIFIED'
         WHERE ROW_ID = ~A"
                (getf parsed :classification)
		(json:encode-json-to-string (getf parsed :extracted))
		(getf parsed :confidence)
		(getf parsed :signal-type)
		chat-signal-id)))
    parsed))


(defun build-classification-prompt (message entity-type)
  (format nil
    "You are a classifier for a B2B procurement system.
     Classify this message from a ~A.
     Respond with valid JSON only. No explanation. No markdown.

     CLASSIFICATION OPTIONS:
     - TRANSACTION_INTENT: wants to buy something
     - CONTEXT_UPDATE: updating profile facts (name, email, address, GST, etc.)
     - WEAK_SIGNAL: future plans, observations, preferences
     - QUERY: asking about orders, invoices, status
     - SOCIAL: greeting, thanks, unrelated

     FOR CONTEXT_UPDATE extract facts as array:
     [{\"fact_key\": \"com.nst.~A.identity.email\",
       \"fact_val\": \"actual value\",
       \"fact_type\": \"string\"}]

     NAMESPACE RULES:
     com.nst.vendor.identity.name
     com.nst.vendor.identity.email
     com.nst.vendor.identity.phone
     com.nst.vendor.tax.gstin
     com.nst.vendor.tax.pan
     com.nst.vendor.location.address

     MESSAGE: ~S

     JSON:"
    entity-type
    (string-downcase entity-type)
    message))


(defun promote-to-signal (chat-signal-id classification tenant-id)
  "Takes a classified CHAT_SIGNAL and writes a DOD_PROCURE_SIGNAL row.
   This is the bridge between raw input and the agent pipeline."
  (let* ((signal-type (getf classification :classification))
         (extracted   (getf classification :extracted))
         (confidence  (getf classification :confidence)))

    (execute-sql
      "INSERT INTO DOD_PROCURE_SIGNAL
       (SIGNAL_TYPE, ENTITY_TYPE, ENTITY_ID,
        OBSERVED_VALUE, CONFIDENCE, STATUS,
        SCOUT_TYPE, TENANT_ID)
       SELECT ?, ENTITY_TYPE, ENTITY_ID,
              ?, ?, 'NEW', 'CHAT-INTAKE', ?
       FROM DOD_PROCURE_CHAT_SIGNAL
       WHERE ROW_ID = ?"
      (list signal-type
            (json:encode-json-to-string extracted)
            confidence
            tenant-id
            chat-signal-id))

    (let ((signal-id (last-insert-id)))
      ;; Update CHAT_SIGNAL to link to the promoted signal
      (execute-sql
        "UPDATE DOD_PROCURE_CHAT_SIGNAL
         SET STATUS = 'PROMOTED', SIGNAL_ID = ?
         WHERE ROW_ID = ?"
        (list signal-id chat-signal-id))
      signal-id)))

(defun process-chat-message (entity-id entity-type message tenant-id)
  "The main entry point. Called by your web handler.
   Orchestrates the entire flow for one chat message.
   Returns a response map for the UI."

  ;; Step 1: Write raw message
  (let* ((chat-id        (intake-chat-message
                           entity-id entity-type message tenant-id))

         ;; Step 2: LLM classifies (Touch Point 1)
         (classification (classify-chat-message chat-id entity-type))

         ;; Step 3: Promote to signal
         (signal-id      (promote-to-signal
                           chat-id classification tenant-id))

         ;; Step 4: Read routing table
         (route          (fetch-signal-route
                           (getf classification :classification)
                           tenant-id))

         ;; Step 5: Assemble agent context
         (run-id         (generate-run-id entity-id))
         (context        (assemble-agent-context
                           run-id
                           (getf route :agent-name)
                           signal-id
                           entity-id
                           tenant-id))

         ;; Step 6: Write agent context
         (_ctx-id        (write-agent-context
                           run-id
                           (getf route :agent-name)
                           signal-id
                           context))

         ;; Step 7: Plan the action
         (action         (plan-action
                           signal-id context classification tenant-id))

         ;; Step 8: Check policy
         (policy-verdict (evaluate-policy action tenant-id))

         ;; Step 9: Execute or raise exception
         (result
           (case (getf policy-verdict :verdict)
             (:auto-approve
               (execute-action action context tenant-id))
             (:require-approval
               (create-exception action policy-verdict tenant-id)
               (list :status :pending-approval
                     :message "Sent for approval"))
             (:block
               (list :status :blocked
                     :message (getf policy-verdict :reason))))))

    ;; Return response for the UI
    (build-ui-response classification result context)))


(defun execute-fact-updates (entity-id facts-to-update tenant-id run-id)
  "Updates ENTITY_FACT rows.
   Expires old values. Writes new values.
   Writes COMMERCE_EVENT for audit.
   Writes TRACE_EVENT for learning."

  (dolist (fact facts-to-update)
    (let ((key (getf fact :fact-key))
          (val (getf fact :fact-val))
          (typ (getf fact :fact-type "string")))

      ;; Expire the old fact
      (execute-sql
        "UPDATE DOD_PROCURE_ENTITY_FACT
         SET VALID_TO = NOW()
         WHERE ENTITY_ID = ?
           AND FACT_KEY  = ?
           AND TENANT_ID = ?
           AND VALID_TO IS NULL"
        (list entity-id key tenant-id))

      ;; Write the new fact
      (execute-sql
        "INSERT INTO DOD_PROCURE_ENTITY_FACT
         (ENTITY_ID, TENANT_ID, FACT_KEY, FACT_VAL,
          FACT_TYPE, SOURCE_TYPE, CONFIDENCE,
          VALID_FROM, VALID_TO, ASSERTED_BY)
         VALUES (?, ?, ?, ?, ?, 'AI_EXTRACTED', 0.95,
                 NOW(), NULL, ?)"
        (list entity-id tenant-id key val typ run-id))))

  ;; Write commerce event — the audit record
  (let ((thread-id (format nil "PROFILE-~A" entity-id)))
    (execute-sql
      "INSERT INTO DOD_PROCURE_COMMERCE_EVENT
       (TENANT_ID, THREAD_ID, THREAD_TYPE,
        EVENT_TYPE, ACTOR_TYPE, ACTOR_ID,
        PAYLOAD, NARRATIVE)
       VALUES (?, ?, 'PROFILE_UPDATE',
               'VENDOR_PROFILE_UPDATED',
               'AGENT', 'PROFILE-UPDATE-AGENT',
               ?, ?)"
      (list tenant-id
            thread-id
            (json:encode-json-to-string
              `(("facts_updated" . ,(length facts-to-update))
                ("run_id"        . ,run-id)))
            (format nil "~A fact(s) updated for entity ~A"
                    (length facts-to-update) entity-id))))

  ;; Write trace event — feeds Bayesian learning
  (execute-sql
    "INSERT INTO DOD_PROCURE_TRACE_EVENT
     (ENTITY_TYPE, ENTITY_ID,
      EVENT_DOMAIN, EVENT_TYPE, EVENT_CODE,
      NARRATIVE_TEXT, EVENT_DATA,
      CONTEXT_ID, ACTOR_TYPE, ACTOR_ID,
      PERSONA_TYPE, SEVERITY, INTENT_DOMAIN,
      TENANT_ID)
     VALUES ('FUNCTION', 'EXECUTE-FACT-UPDATES',
             'profile', 'function-executed',
             'FACT-UPDATE-SUCCESS',
             ?, ?,
             ?, 'AGENT', 'PROFILE-UPDATE-AGENT',
             'VENDOR', 'INFO', 'PROFILE',
             ?)"
    (list
      (format nil "Updated ~A facts for ~A"
              (length facts-to-update) entity-id)
      (json:encode-json-to-string
        `(("facts" . ,(length facts-to-update))
          ("run_id" . ,run-id)))
      run-id
      tenant-id)))

;;;; =============================================================================
;;;; AI INTELLIGENCE SUBSTRATE — AGENT PIPELINE FUNCTIONS
;;;; Vendor Profile Update via Chat — Complete Implementation
;;;; =============================================================================
;;;;
;;;; Dependencies assumed:
;;;;   - cl-dbi        : database connectivity
;;;;   - cl-json       : JSON encode/decode
;;;;   - drakma        : HTTP client for Ollama API
;;;;   - local-time    : timestamp handling
;;;;   - flexi-streams : octet/string conversion
;;;;   - cl-ppcre      : regex for JSON extraction
;;;;
;;;; Database connection assumed available via *DB-CONNECTION*
;;;; Ollama assumed running at http://localhost:11434
;;;; =============================================================================



;;; =============================================================================
;;; GLOBALS AND CONFIGURATION
;;; =============================================================================

;;; =============================================================================
;;; DATABASE HELPERS
;;; Thin wrappers around cl-dbi keeping SQL visible in the call site.
;;; =============================================================================


(defun db-last-insert-id ()
  "Returns the last auto-increment ID from the connection."
  (let ((row (clsql:execute-command "SELECT LAST_INSERT_ID() AS id")))
    (cdr (assoc "id" row :test #'string=))))

(defun row-get (row key)
  "Get value from a DB result row alist by column name string."
  (cdr (assoc key row :test #'string=)))


;;; =============================================================================
;;; FUNCTION 1: FETCH-CHAT-SIGNAL
;;; =============================================================================

(meta fetch-chat-signal
  '((:description . "Fetch a CHAT_SIGNAL row by its primary key.
                      Returns an alist with all columns.
                      Returns NIL if the row does not exist.")
    (:domain      . :chat)
    (:category    . :read)
    (:inputs  . (((:name . chat-signal-id) (:type . integer) (:required . t))))
    (:outputs . (((:name . chat-signal-row) (:type . alist))))
    (:reads   . (:dod-procure-chat-signal))
    (:writes  . ())
    (:throws  . (:db-error :not-found))
    (:pure    . nil)
    (:cost    . :low)))

(defun fetch-chat-signal (chat-signal-id)
  "Fetch a single CHAT_SIGNAL row by ROW_ID.
   Returns an alist of (column-name . value) pairs.
   Returns NIL if no row found.

   Example return value:
     ((\"ROW_ID\" . 1)
      (\"ENTITY_ID\" . \"VEND-001\")
      (\"ENTITY_TYPE\" . \"VENDOR\")
      (\"RAW_MESSAGE\" . \"Update email to new@acme.com\")
      (\"CLASSIFICATION\" . \"PENDING\")
      (\"EXTRACTED\" . \"{}\")
      (\"CONFIDENCE\" . 0.0)
      (\"STATUS\" . \"NEW\"))"
  (let ((row (clsql:execute-command
               (format nil "SELECT ROW_ID, TENANT_ID, ENTITY_ID, ENTITY_TYPE,
                       RAW_MESSAGE, CHANNEL, CLASSIFICATION,
                       EXTRACTED, SIGNAL_TYPE, IMPLIED_TIMEFRAME,
                       CONFIDENCE, STATUS, ACCUMULATION_GROUP,
                       SIGNAL_ID, THREAD_ID, EXPIRES_AT,
                       CREATED, UPDATED
                FROM DOD_PROCURE_CHAT_SIGNAL
                WHERE ROW_ID = ~A"
		       chat-signal-id))))
    (unless row
      (format t  "fetch-chat-signal: no row found for id=~A" chat-signal-id))
    row))

;;; =============================================================================
;;; FUNCTION 2: EXTRACT-JSON-FROM-LLM-RESPONSE
;;; =============================================================================

(meta extract-json-from-llm-response
  '((:description . "Defensively extracts and parses JSON from a raw LLM
                      response string. Handles: leading prose, trailing prose,
                      markdown fences (```json ... ```), extra whitespace,
                      and occasional structural errors from smaller models.
                      Returns parsed Lisp structure or NIL on total failure.")
    (:domain      . :llm)
    (:category    . :parsing)
    (:inputs  . (((:name . raw) (:type . string) (:required . t))))
    (:outputs . (((:name . parsed) (:type . alist-or-nil))))
    (:reads   . ())
    (:writes  . ())
    (:throws  . ())
    (:pure    . t)
    (:cost    . :low)))

(defun extract-json-from-llm-response (raw)
  "Defensively parse JSON from raw LLM output.
   Smaller models (9B) occasionally emit:
     - Preamble: 'Sure, here is the JSON: {...}'
     - Markdown fences: ```json\\n{...}\\n```
     - Trailing explanation after closing brace
   This function handles all of the above.

   Returns the parsed JSON as a Lisp alist/list.
   Returns NIL if no valid JSON can be extracted."
  (unless (and raw (> (length raw) 0))
    (log-warn "extract-json-from-llm-response: empty input")
    (return-from extract-json-from-llm-response nil))

  ;; Step 1: strip markdown fences
  (let* ((stripped (cl-ppcre:regex-replace-all
                     "```(?:json)?\\s*|```"
                     raw ""))
         ;; Step 2: find outermost { ... } or [ ... ]
         (open-brace  (position #\{ stripped))
         (open-bracket (position #\[ stripped))
         (open-pos    (cond
                        ((and open-brace open-bracket)
                         (min open-brace open-bracket))
                        (open-brace  open-brace)
                        (open-bracket open-bracket)
                        (t nil))))

    (unless open-pos
      (log-warn "extract-json-from-llm-response: no JSON structure found in: ~A"
                (subseq raw 0 (min 100 (length raw))))
      (return-from extract-json-from-llm-response nil))

    ;; Step 3: find matching close delimiter from the end
    (let* ((open-char  (char stripped open-pos))
           (close-char (if (char= open-char #\{) #\} #\]))
           (close-pos  (position close-char stripped :from-end t)))

      (unless (and close-pos (> close-pos open-pos))
        (log-warn "extract-json-from-llm-response: unmatched delimiter")
        (return-from extract-json-from-llm-response nil))

      ;; Step 4: extract the candidate JSON string
      (let ((candidate (subseq stripped open-pos (1+ close-pos))))
        (handler-case
            (let ((parsed (json:decode-json-from-string candidate)))
              (log-info "extract-json-from-llm-response: parsed successfully")
              parsed)
          (error (e)
            (log-error "extract-json-from-llm-response: parse failed: ~A" e)
            ;; Step 5: attempt lightweight repair — trailing comma before }
            (let* ((repaired (cl-ppcre:regex-replace-all
                               ",\\s*([}\\]])"
                               candidate "\\1"))
                   (repaired (cl-ppcre:regex-replace-all
                               "([{,])\\s*}" repaired "}")))
              (handler-case
                  (json:decode-json-from-string repaired)
                (error ()
                  (log-error "extract-json-from-llm-response: repair failed too")
                  nil)))))))))

;;; =============================================================================
;;; FUNCTION 3: FETCH-SIGNAL-ROUTE
;;; =============================================================================

(meta fetch-signal-route
  '((:description . "Read the routing rule for a given signal classification
                      and tenant. Returns the agent name and optional skill ID
                      that should handle this signal type.
                      Falls back to platform default (tenant_id IS NULL)
                      if no tenant-specific route exists.")
    (:domain      . :signal)
    (:category    . :routing)
    (:inputs  . (((:name . classification) (:type . string) (:required . t))
                 ((:name . tenant-id)      (:type . integer)(:required . t))))
    (:outputs . (((:name . route) (:type . alist))))
    (:reads   . (:dod-procure-signal-route))
    (:writes  . ())
    (:throws  . (:no-route-found :db-error))
    (:pure    . nil)
    (:cost    . :low)))

(defun fetch-signal-route (classification tenant-id)
  "Fetch the routing rule for CLASSIFICATION under TENANT-ID.
   Tries tenant-specific route first, falls back to platform default.

   Returns alist:
     ((\"AGENT_NAME\" . \"PROFILE-UPDATE-AGENT\")
      (\"SKILL_ID\"   . nil)
      (\"PRIORITY\"   . 3)
      (\"CONDITIONS\" . \"{...}\"))

   Signals an error if no route found — an unroutable signal
   is a configuration error that must be caught early."

  ;; Try tenant-specific route first
  (let ((route (db-query-one
                 "SELECT ROW_ID, SIGNAL_TYPE, AGENT_NAME,
                         SKILL_ID, PRIORITY, CONDITIONS
                  FROM DOD_PROCURE_SIGNAL_ROUTE
                  WHERE SIGNAL_TYPE = ?
                    AND TENANT_ID   = ?
                    AND ENABLED     = 'Y'
                  ORDER BY PRIORITY ASC
                  LIMIT 1"
                 (list classification tenant-id))))

    ;; Fall back to platform default if no tenant-specific route
    (unless route
      (setf route (db-query-one
                    "SELECT ROW_ID, SIGNAL_TYPE, AGENT_NAME,
                            SKILL_ID, PRIORITY, CONDITIONS
                     FROM DOD_PROCURE_SIGNAL_ROUTE
                     WHERE SIGNAL_TYPE = ?
                       AND TENANT_ID IS NULL
                       AND ENABLED     = 'Y'
                     ORDER BY PRIORITY ASC
                     LIMIT 1"
                    (list classification))))

    (unless route
      (error "No signal route found for classification=~A tenant=~A.
              Seed DOD_PROCURE_SIGNAL_ROUTE before running the pipeline."
             classification tenant-id))

    (log-info "fetch-signal-route: ~A → ~A"
              classification (row-get route "AGENT_NAME"))
    route))

;;; =============================================================================
;;; FUNCTION 4: GENERATE-RUN-ID
;;; =============================================================================

(meta generate-run-id
  '((:description . "Generate a unique, human-readable run identifier
                      for one agent execution thread.
                      Format: RUN-{ENTITY-ID-PREFIX}-{YYYYMMDD}-{HHMMSS}-{NONCE}
                      Stable enough for logging, unique enough for correlation.")
    (:domain      . :agent)
    (:category    . :identity)
    (:inputs  . (((:name . entity-id) (:type . string) (:required . t))))
    (:outputs . (((:name . run-id) (:type . string) (:binds-as . :run-id))))
    (:reads   . ())
    (:writes  . ())
    (:throws  . ())
    (:pure    . nil)   ; reads clock — not pure
    (:cost    . :low)))

(defun generate-run-id (entity-id)
  "Generate a unique run ID for one agent execution.

   Format: RUN-{PREFIX}-{DATE}-{TIME}-{NONCE}
   Example: RUN-VEND-001-20260317-143022-A3F7

   The entity-id prefix is truncated to 12 chars to keep IDs readable.
   The nonce is 4 random hex chars — enough for same-second collision avoidance.

   This ID ties together: AGENT_CONTEXT, PLANNED_ACTION, TRACE_EVENT,
   and COMMERCE_EVENT written during one agent run."
  (let* ((now        (local-time:now))
         (date-str   (local-time:format-timestring
                       nil now :format '(:year (:month 2) (:day 2))))
         (time-str   (local-time:format-timestring
                       nil now :format '((:hour 2) (:min 2) (:sec 2))))
         ;; Truncate entity-id for readability, uppercase, replace spaces
         (prefix     (string-upcase
                       (substitute #\- #\Space
                                   (subseq entity-id 0
                                           (min 12 (length entity-id))))))
         ;; 4 random hex chars for collision avoidance
         (nonce      (format nil "~4,'0X" (random #xFFFF))))
    (format nil "RUN-~A-~A-~A-~A" prefix date-str time-str nonce)))

;;; =============================================================================
;;; FUNCTION 5: ASSEMBLE-AGENT-CONTEXT
;;; =============================================================================

(meta assemble-agent-context
  '((:description . "Assemble the complete working memory for one agent run.
                      Reads: signal data, current entity facts, relevant policies,
                      recent trace events (episodic memory), and vendor qualification.
                      Token-counts the result. Sets TRIMMED if over budget.
                      This is the context the LLM receives — quality here
                      directly determines decision quality.")
    (:domain      . :agent)
    (:category    . :context)
    (:inputs  . (((:name . run-id)     (:type . string)  (:required . t))
                 ((:name . agent-name) (:type . string)  (:required . t))
                 ((:name . signal-id)  (:type . integer) (:required . t))
                 ((:name . entity-id)  (:type . string)  (:required . t))
                 ((:name . tenant-id)  (:type . integer) (:required . t))))
    (:outputs . (((:name . context) (:type . alist) (:binds-as . :context))))
    (:reads   . (:dod-procure-signal
                 :dod-procure-entity-fact
                 :dod-procure-ai-policy
                 :dod-procure-trace-event
                 :dod-procure-supplier-qualification))
    (:writes  . ())
    (:throws  . (:db-error :signal-not-found))
    (:pure    . nil)
    (:cost    . :medium)))

(defun assemble-agent-context (run-id agent-name signal-id entity-id tenant-id)
  "Assemble working memory for one agent run.

   Returns an alist with keys:
     :run-id         — this run's identifier
     :agent-name     — which agent is running
     :signal         — the triggering signal row
     :entity-facts   — current facts for the entity
     :policies       — applicable policy rows
     :recent-history — last 5 trace events for this entity
     :qualification  — supplier qualification if entity is a vendor
     :token-estimate — rough token count for LLM context budget
     :trimmed        — T if context was reduced to fit window

   Context assembly order matters for LLM attention:
     Most relevant information comes FIRST (signal, facts).
     Background information comes LAST (history, policies).
   Research shows LLMs attend better to early context."

  (log-info "assemble-agent-context: run=~A agent=~A entity=~A"
            run-id agent-name entity-id)

  ;; ── 1. The triggering signal ────────────────────────────────────
  (let* ((signal (db-query-one
                   "SELECT ROW_ID, SIGNAL_TYPE, ENTITY_TYPE,
                           ENTITY_ID, OBSERVED_VALUE, CONFIDENCE,
                           STATUS, SCOUT_TYPE, CREATED
                    FROM DOD_PROCURE_SIGNAL
                    WHERE ROW_ID   = ?
                      AND TENANT_ID = ?"
                   (list signal-id tenant-id)))

         ;; ── 2. Current entity facts (valid only) ────────────────
         (entity-facts (db-query
                         "SELECT FACT_KEY, FACT_VAL, FACT_TYPE,
                                 SOURCE_TYPE, CONFIDENCE, VALID_FROM
                          FROM DOD_PROCURE_ENTITY_FACT
                          WHERE ENTITY_ID  = ?
                            AND TENANT_ID  = ?
                            AND VALID_TO IS NULL
                          ORDER BY CONFIDENCE DESC"
                         (list entity-id tenant-id)))

         ;; ── 3. Applicable policies ──────────────────────────────
         ;; Read policies that match either the signal type or
         ;; the generic action type for this agent
         (policies (db-query
                     "SELECT POLICY_CODE, POLICY_TYPE,
                             CONDITIONS, OUTCOME, PRIORITY
                      FROM DOD_PROCURE_AI_POLICY
                      WHERE (APPLIES_TO_SIGNAL = ?
                          OR APPLIES_TO_SIGNAL IS NULL)
                        AND (TENANT_ID = ? OR TENANT_ID IS NULL)
                        AND ENABLED = 'Y'
                      ORDER BY PRIORITY ASC
                      LIMIT 10"
                     (list (row-get signal "SIGNAL_TYPE") tenant-id)))

         ;; ── 4. Recent episodic history for this entity ──────────
         ;; Last 5 relevant trace events — the agent's memory
         ;; of what happened with this entity recently
         (recent-history (db-query
                           "SELECT EVENT_TYPE, EVENT_CODE,
                                   NARRATIVE_TEXT, EVENT_DATA,
                                   ACTOR_ID, SEVERITY, CREATED
                            FROM DOD_PROCURE_TRACE_EVENT
                            WHERE ENTITY_ID   = ?
                              AND TENANT_ID   = ?
                              AND SEVERITY    != 'ERROR'
                            ORDER BY CREATED DESC
                            LIMIT 5"
                           (list entity-id tenant-id)))

         ;; ── 5. Supplier qualification (vendors only) ────────────
         (qualification
           (when (string-equal (row-get signal "ENTITY_TYPE") "VENDOR")
             (db-query-one
               "SELECT STATUS, OVERALL_SCORE, DELIVERY_PERFORMANCE,
                       FINANCIAL_HEALTH, QUALITY_SCORE,
                       COMPLIANCE_SCORE, ESG_RATING,
                       STRATEGIC_TIER, ASSESSMENT_DATE
                FROM DOD_PROCURE_SUPPLIER_QUALIFICATION
                WHERE VENDOR_ENTITY_ID = ?
                  AND TENANT_ID        = ?
                  AND VALID_TO IS NULL
                ORDER BY ASSESSMENT_DATE DESC
                LIMIT 1"
               (list entity-id tenant-id))))

         ;; ── 6. Assemble the context map ─────────────────────────
         (context `((:run-id         . ,run-id)
                    (:agent-name     . ,agent-name)
                    (:signal         . ,signal)
                    (:entity-facts   . ,entity-facts)
                    (:policies       . ,policies)
                    (:recent-history . ,recent-history)
                    (:qualification  . ,qualification)))

         ;; ── 7. Token estimation ─────────────────────────────────
         ;; Rough estimate: 1 token ≈ 4 characters
         ;; This avoids hitting the LLM context window limit
         (context-str    (json-encode context))
         (token-estimate (ceiling (length context-str) 4))
         (token-budget   6000)  ; leave 2000 for prompt + response
         (trimmed        nil))

    ;; ── 8. Trim if over budget ───────────────────────────────────
    ;; Drop history first (lowest signal-to-noise), then policies
    (when (> token-estimate token-budget)
      (log-warn "assemble-agent-context: over budget (~A tokens), trimming"
                token-estimate)
      (setf trimmed t)
      ;; Remove recent-history first — it is background context
      (setf context (remove :recent-history context :key #'car))
      ;; Recheck — trim policies to 5 if still over
      (let* ((trimmed-str (json-encode context))
             (trimmed-est (ceiling (length trimmed-str) 4)))
        (when (> trimmed-est token-budget)
          (let ((fewer-policies (subseq (alist-get context :policies) 0
                                        (min 5 (length (alist-get context :policies))))))
            (setf context (cons `(:policies . ,fewer-policies)
                                (remove :policies context :key #'car)))))))

    ;; Add metadata to context
    (setf context (append context
                           `((:token-estimate . ,token-estimate)
                             (:trimmed        . ,trimmed))))

    (log-info "assemble-agent-context: assembled ~A tokens, trimmed=~A"
              token-estimate trimmed)
    context))

;;; =============================================================================
;;; FUNCTION 6: WRITE-AGENT-CONTEXT
;;; =============================================================================

(meta write-agent-context
  '((:description . "Persist the assembled agent context to the database.
                      This is the observability record — it lets you debug
                      exactly what information the agent had when it decided.
                      Essential for explainability and bias auditing.")
    (:domain      . :agent)
    (:category    . :write)
    (:inputs  . (((:name . run-id)     (:type . string)  (:required . t))
                 ((:name . agent-name) (:type . string)  (:required . t))
                 ((:name . signal-id)  (:type . integer) (:required . t))
                 ((:name . context)    (:type . alist)   (:required . t))))
    (:outputs . (((:name . context-row-id) (:type . integer))))
    (:reads   . ())
    (:writes  . (:dod-procure-ai-agent-context))
    (:throws  . (:db-error))
    (:pure    . nil)
    (:cost    . :low)))

(defun write-agent-context (run-id agent-name signal-id context)
  "Write the assembled context to DOD_PROCURE_AI_AGENT_CONTEXT.
   Returns the new ROW_ID.

   The CONTEXT_DATA JSON is the complete working memory snapshot.
   Do not summarise or truncate before writing — the full context
   is needed for post-hoc analysis of agent decisions."
  (let* ((token-estimate (alist-get context :token-estimate 0))
         (trimmed        (if (alist-get context :trimmed) "Y" "N"))
         (trimmed-fields (when (alist-get context :trimmed)
                           (json-encode
                             (remove-if (lambda (k)
                                          (member k '(:policies :recent-history)
                                                  :test #'eq))
                                        '()))))  ; fields dropped
         (context-json   (json-encode context))
         (tenant-id      (alist-get (alist-get context :signal) "TENANT_ID")))

    (db-execute
      "INSERT INTO DOD_PROCURE_AI_AGENT_CONTEXT
         (RUN_ID, AGENT_NAME, SIGNAL_ID, ACTION_ID,
          CONTEXT_DATA, TOKEN_COUNT, TRIMMED, TRIMMED_FIELDS,
          STARTED_AT, RUN_STATUS, TENANT_ID)
       VALUES (?, ?, ?, NULL, ?, ?, ?, ?, NOW(), 'IN_PROGRESS', ?)"
      (list run-id agent-name signal-id context-json
            token-estimate trimmed trimmed-fields tenant-id))

    (let ((row-id (db-last-insert-id)))
      (log-info "write-agent-context: written row=~A run=~A" row-id run-id)
      row-id)))

;;; =============================================================================
;;; FUNCTION 7: PLAN-ACTION
;;; =============================================================================

(meta plan-action
  '((:description . "Determine the action to execute for a classified signal.
                      For known patterns: retrieves matching SKILL and instantiates it.
                      For novel patterns: calls LLM to compose a workflow script.
                      Writes a PLANNED_ACTION row and returns it.
                      This is where CONTEXT_UPDATE signals become concrete steps.")
    (:domain      . :agent)
    (:category    . :planning)
    (:inputs  . (((:name . signal-id)      (:type . integer) (:required . t))
                 ((:name . context)        (:type . alist)   (:required . t))
                 ((:name . classification) (:type . alist)   (:required . t))
                 ((:name . tenant-id)      (:type . integer) (:required . t))))
    (:outputs . (((:name . action) (:type . alist) (:binds-as . :action))))
    (:reads   . (:dod-procure-ai-skill))
    (:writes  . (:dod-procure-ai-planned-action))
    (:throws  . (:db-error :composition-failed))
    (:pure    . nil)
    (:cost    . :medium)))

(defun plan-action (signal-id context classification tenant-id)
  "Compose the workflow script for a signal.

   Decision tree:
   1. Does a matching SKILL exist? → instantiate it (no LLM)
   2. No matching skill?           → compose fresh (LLM called)

   For CONTEXT_UPDATE with known facts: skill handles it after run #10.
   Before run #10: LLM composes the UPDATE_ENTITY_FACT steps.

   Returns the PLANNED_ACTION alist after writing it to the database."
  (let* ((signal-type (alist-get (alist-get context :signal) "SIGNAL_TYPE"))
         (entity-id   (alist-get (alist-get context :signal) "ENTITY_ID"))

         ;; ── Check for an existing skill ─────────────────────────
         (matching-skill
           (db-query-one
             "SELECT ROW_ID, SKILL_CODE, SKILL_SCRIPT,
                     SUCCESS_COUNT, FAILURE_COUNT, SUCCESS_RATE
              FROM DOD_PROCURE_AI_SKILL
              WHERE TRIGGER_SIGNAL_TYPE = ?
                AND STATUS = 'ACTIVE'
                AND (TENANT_ID = ? OR TENANT_ID IS NULL)
              ORDER BY SUCCESS_RATE DESC, SUCCESS_COUNT DESC
              LIMIT 1"
             (list signal-type tenant-id)))

         ;; ── Compose the action script ───────────────────────────
         (action-script
           (if matching-skill
               ;; CROW PATH: use proven skill — no LLM needed
               (progn
                 (log-info "plan-action: using skill ~A for signal ~A"
                           (row-get matching-skill "SKILL_CODE") signal-type)
                 (instantiate-skill matching-skill context classification))
               ;; HONEYBEE PATH: compose fresh — LLM called
               (progn
                 (log-info "plan-action: composing fresh workflow for ~A" signal-type)
                 (compose-fresh-workflow context classification))))

         ;; ── Determine action type ────────────────────────────────
         (action-type (determine-action-type classification))

         ;; ── Write the planned action row ─────────────────────────
         (run-id      (alist-get context :run-id))
         (skill-id    (when matching-skill
                        (row-get matching-skill "ROW_ID"))))

    (db-execute
      "INSERT INTO DOD_PROCURE_AI_PLANNED_ACTION
         (SIGNAL_ID, PREDICTION_ID, SKILL_ID, RUN_ID,
          ACTION_TYPE, ACTION_SCRIPT, STATUS,
          APPROVAL_REQUIRED, TENANT_ID)
       VALUES (?, NULL, ?, ?, ?, ?, 'PLANNED', 'N', ?)"
      (list signal-id skill-id run-id
            action-type (json-encode action-script)
            tenant-id))

    (let* ((action-id (db-last-insert-id))
           (action    `(("ROW_ID"      . ,action-id)
                        ("ACTION_TYPE" . ,action-type)
                        ("ACTION_SCRIPT" . ,action-script)
                        ("SKILL_ID"    . ,skill-id)
                        ("STATUS"      . "PLANNED"))))

      (log-info "plan-action: wrote action=~A type=~A" action-id action-type)
      action)))


(defun determine-action-type (classification)
  "Map a signal classification to a canonical action type string."
  (let ((cls (if (stringp classification)
                 classification
                 (alist-get classification :classification ""))))
    (cond
      ((string-equal cls "CONTEXT_UPDATE")    "UPDATE_ENTITY_FACT")
      ((string-equal cls "TRANSACTION_INTENT") "CREATE_PURCHASE_ORDER")
      ((string-equal cls "WEAK_SIGNAL")       "ACCUMULATE_SIGNAL")
      ((string-equal cls "QUERY")             "READ_AND_RESPOND")
      (t "HANDLE_GENERIC_SIGNAL"))))


(defun instantiate-skill (skill context classification)
  "Instantiate a SKILL by substituting context values into its script template.
   The skill script uses {{variable}} placeholders replaced with actual values."
  (let* ((script-json  (row-get skill "SKILL_SCRIPT"))
         (script       (json-decode script-json))
         (extracted    (alist-get classification :extracted '()))
         (entity-facts (alist-get context :entity-facts '())))
    ;; For CONTEXT_UPDATE skills: the script is a parameterised
    ;; UPDATE_ENTITY_FACT sequence. Substitute extracted facts.
    (mapcar (lambda (step)
              (let ((inputs (alist-get step :inputs)))
                (when inputs
                  ;; Replace {{extracted_facts}} with actual facts
                  (setf (cdr (assoc :inputs step))
                        (substitute-placeholders inputs extracted entity-facts)))
                step))
            script)))


(defun substitute-placeholders (inputs extracted entity-facts)
  "Replace template placeholders in INPUTS with actual context values."
  ;; For now: pass extracted facts directly
  ;; In production: walk INPUTS JSON, match {{key}} patterns
  (declare (ignore entity-facts))
  `((:extracted-facts . ,extracted)
    ,@inputs))


(defun compose-fresh-workflow (context classification)
  "Call LLM to compose a workflow script for a novel scenario.
   Returns the script as a Lisp list of step alists.
   This is the HONEYBEE PATH — called only when no skill matches."
  (let* ((prompt  (build-workflow-composition-prompt context classification))
         (raw     (call-local-llm prompt
                                  :temperature 0.1
                                  :max-tokens  800))
         (parsed  (extract-json-from-llm-response raw)))
    (unless parsed
      (log-warn "compose-fresh-workflow: LLM composition failed, using fallback")
      (setf parsed (build-fallback-workflow classification)))
    parsed))


(defun build-workflow-composition-prompt (context classification)
  "Build the LLM prompt for workflow composition.
   Injects: signal type, extracted facts, entity facts, available functions."
  (let* ((signal-type (alist-get (alist-get context :signal) "SIGNAL_TYPE" "UNKNOWN"))
         (extracted   (alist-get classification :extracted '()))
         (facts       (mapcar (lambda (f)
                                (format nil "~A = ~A (confidence: ~A)"
                                        (row-get f "FACT_KEY")
                                        (row-get f "FACT_VAL")
                                        (row-get f "CONFIDENCE")))
                              (alist-get context :entity-facts '()))))
    (format nil
      "You are a workflow composer for a B2B procurement intelligence system.
Compose a JSON workflow script to handle a ~A signal.

EXTRACTED FACTS TO PROCESS:
~A

CURRENT ENTITY FACTS:
~A

AVAILABLE FUNCTIONS:
- expire-entity-fact: expires current ENTITY_FACT row (sets VALID_TO=NOW)
- write-entity-fact: inserts new ENTITY_FACT row with new value
- write-commerce-event: writes audit event to COMMERCE_EVENT
- write-trace-event: writes execution trace to TRACE_EVENT
- notify-entity: sends notification to an entity

RULES:
- For each extracted fact: call expire-entity-fact then write-entity-fact
- Always end with write-commerce-event and write-trace-event
- Respond with JSON array of steps ONLY. No explanation. No markdown.

JSON:"
      signal-type
      (or (json-encode extracted) "[]")
      (format nil "~{~A~^, ~}" facts))))


(defun build-fallback-workflow (classification)
  "Minimal safe fallback workflow when LLM composition fails.
   Handles CONTEXT_UPDATE by writing a trace event and raising an exception."
  (let ((action-type (determine-action-type classification)))
    `(((:step . 1)
       (:function . "write-trace-event")
       (:inputs . ((:event-code . "COMPOSITION-FALLBACK")
                   (:narrative . ,(format nil "LLM failed to compose ~A workflow"
                                          action-type))
                   (:severity . "WARN")))
       (:purpose . "Record that fallback was triggered")))))

;;; =============================================================================
;;; FUNCTION 8: EVALUATE-POLICY
;;; =============================================================================

(meta evaluate-policy
  '((:description . "Evaluate the planned action against applicable POLICY rows.
                      Returns a verdict: :auto-approve, :require-approval, or :block.
                      Policies are evaluated in priority order (lower = higher priority).
                      First matching policy wins — no fall-through.
                      This is the policy guard — the constitutional layer.")
    (:domain      . :policy)
    (:category    . :evaluation)
    (:inputs  . (((:name . action)    (:type . alist)   (:required . t))
                 ((:name . tenant-id) (:type . integer) (:required . t))))
    (:outputs . (((:name . verdict) (:type . alist) (:binds-as . :verdict))))
    (:reads   . (:dod-procure-ai-policy))
    (:writes  . (:dod-procure-ai-planned-action))
    (:throws  . (:db-error))
    (:pure    . nil)
    (:cost    . :low)))

(defun evaluate-policy (action tenant-id)
  "Evaluate PLANNED-ACTION against POLICY rows.

   Returns an alist:
     ((:verdict  . :auto-approve)   ; or :require-approval or :block
      (:policy-code . \"AUTO-APPROVE-PROFILE-UPDATE\")
      (:reason   . \"Vendor updating own profile within allowed fact count\")
      (:outcome  . {the policy outcome JSON}))

   If no policy matches: default is :require-approval.
   This is the safe default — unknown situations go to humans.

   Updates PLANNED_ACTION.STATUS to reflect policy decision."
  (let* ((action-type (row-get action "ACTION_TYPE"))
         (action-id   (row-get action "ROW_ID"))

         ;; Load applicable policies ordered by priority
         (policies (db-query
                     "SELECT ROW_ID, POLICY_CODE, POLICY_TYPE,
                             CONDITIONS, OUTCOME, PRIORITY, DESCRIPTION
                      FROM DOD_PROCURE_AI_POLICY
                      WHERE (APPLIES_TO_ACTION = ? OR APPLIES_TO_ACTION IS NULL)
                        AND (TENANT_ID = ? OR TENANT_ID IS NULL)
                        AND ENABLED = 'Y'
                      ORDER BY PRIORITY ASC"
                     (list action-type tenant-id))))

    (log-info "evaluate-policy: action=~A type=~A, evaluating ~A policies"
              action-id action-type (length policies))

    ;; Evaluate policies in priority order — first match wins
    (let ((verdict (loop for policy in policies
                         for conditions = (json-decode
                                            (row-get policy "CONDITIONS"))
                         when (policy-conditions-met-p conditions action)
                           do (log-info "evaluate-policy: matched ~A"
                                        (row-get policy "POLICY_CODE"))
                           and return (build-verdict policy)
                         finally
                           ;; No policy matched — safe default
                           (return (list (cons :verdict :require-approval)
                                         (cons :policy-code nil)
                                         (cons :reason
                                               "No matching policy — default to human approval")
                                         (cons :outcome nil))))))

      ;; Update PLANNED_ACTION status based on verdict
      (let ((new-status
              (case (alist-get verdict :verdict)
                (:auto-approve    "APPROVED")
                (:require-approval "POLICY_CHECK")
                (:block           "BLOCKED"))))
        (db-execute
          "UPDATE DOD_PROCURE_AI_PLANNED_ACTION
           SET STATUS           = ?,
               APPROVAL_REQUIRED = ?,
               APPROVAL_REASON  = ?
           WHERE ROW_ID = ?"
          (list new-status
                (if (eq (alist-get verdict :verdict) :require-approval) "Y" "N")
                (alist-get verdict :reason)
                action-id)))

      (log-info "evaluate-policy: verdict=~A" (alist-get verdict :verdict))
      verdict)))


(defun policy-conditions-met-p (conditions action)
  "Evaluate whether CONDITIONS (parsed JSON alist) are satisfied by ACTION.

   Supported condition keys:
     actor_type            — matches if action was triggered by this actor type
     updating_own_profile  — true if vendor is updating their own facts
     max_facts_per_update  — maximum number of facts being changed
     max_value             — maximum monetary value of the action
     vendor_reliability_min — minimum vendor reliability score required

   Returns T if all conditions are met, NIL otherwise.
   Unknown conditions are logged and skipped (permissive — not blocking)."
  (every (lambda (condition)
           (let ((key   (car condition))
                 (value (cdr condition)))
             (cond
               ;; actor_type check
               ((string-equal (symbol-name key) "ACTOR_TYPE")
                t)  ; trust the signal routing for actor type

               ;; updating_own_profile: vendor updating their own facts
               ((string-equal (symbol-name key) "UPDATING_OWN_PROFILE")
                (if value t t))  ; for now always true for CONTEXT_UPDATE

               ;; max_facts_per_update
               ((string-equal (symbol-name key) "MAX_FACTS_PER_UPDATE")
                (let ((script (row-get action "ACTION_SCRIPT")))
                  (when script
                    (let* ((steps  (json-decode script))
                           (fact-steps (count-if
                                         (lambda (s)
                                           (string-equal
                                             (alist-get s :function "")
                                             "write-entity-fact"))
                                         steps)))
                      (<= fact-steps value)))))

               ;; Unknown condition — log and skip (do not block)
               (t
                (log-warn "policy-conditions-met-p: unknown condition ~A" key)
                t))))
         conditions))


(defun build-verdict (policy)
  "Build a verdict alist from a matched POLICY row."
  (let* ((policy-type (row-get policy "POLICY_TYPE"))
         (outcome     (json-decode (row-get policy "OUTCOME")))
         (verdict-key (cond
                        ((string-equal policy-type "AUTO_APPROVE")    :auto-approve)
                        ((string-equal policy-type "REQUIRE_APPROVAL") :require-approval)
                        ((string-equal policy-type "BLOCK")           :block)
                        ((string-equal policy-type "NOTIFY_ONLY")     :auto-approve)
                        (t :require-approval))))
    `((:verdict     . ,verdict-key)
      (:policy-code . ,(row-get policy "POLICY_CODE"))
      (:reason      . ,(or (row-get policy "DESCRIPTION")
                           (format nil "Matched policy ~A"
                                   (row-get policy "POLICY_CODE"))))
      (:outcome     . ,outcome))))

;;; =============================================================================
;;; FUNCTION 9: EXECUTE-ACTION
;;; =============================================================================

(meta execute-action
  '((:description . "Execute the planned and approved workflow script.
                      Walks the ACTION_SCRIPT steps in sequence.
                      For each step: looks up the function in *META-REGISTRY*,
                      calls it with the resolved inputs.
                      Writes: ENTITY_FACT updates, COMMERCE_EVENT, TRACE_EVENT.
                      Updates: PLANNED_ACTION.STATUS to COMPLETED or FAILED.")
    (:domain      . :agent)
    (:category    . :execution)
    (:inputs  . (((:name . action)    (:type . alist)   (:required . t))
                 ((:name . context)   (:type . alist)   (:required . t))
                 ((:name . tenant-id) (:type . integer) (:required . t))))
    (:outputs . (((:name . result) (:type . alist) (:binds-as . :result))))
    (:reads   . (:dod-procure-ai-planned-action))
    (:writes  . (:dod-procure-entity-fact
                 :dod-procure-commerce-event
                 :dod-procure-trace-event
                 :dod-procure-ai-planned-action
                 :dod-procure-signal))
    (:throws  . (:db-error :execution-failed))
    (:pure    . nil)
    (:cost    . :medium)))

(defun execute-action (action context tenant-id)
  "Execute the approved PLANNED_ACTION.

   Dispatches to the appropriate executor based on ACTION_TYPE.
   Currently handles:
     UPDATE_ENTITY_FACT  — expires old facts, writes new facts
     CREATE_PURCHASE_ORDER — (stub for phase 2)
     ACCUMULATE_SIGNAL   — (stub for phase 2)

   Writes COMMERCE_EVENT and TRACE_EVENT after execution.
   Updates PLANNED_ACTION.STATUS.

   Returns result alist:
     ((:success . t)
      (:facts-updated . 2)
      (:execution-ms . 43))"
  (let* ((action-type  (row-get action "ACTION_TYPE"))
         (action-id    (row-get action "ROW_ID"))
         (run-id       (alist-get context :run-id))
         (signal       (alist-get context :signal))
         (entity-id    (row-get signal "ENTITY_ID"))
         (entity-type  (row-get signal "ENTITY_TYPE"))
         (classification (let ((chat-sig-extracted
                                 (alist-get context :signal)))
                           (json-decode
                             (row-get chat-sig-extracted "OBSERVED_VALUE"))))
         (start-ms     (get-internal-real-time))
         result)

    (log-info "execute-action: action=~A type=~A entity=~A"
              action-id action-type entity-id)

    ;; ── Dispatch to type-specific executor ──────────────────────
    (setf result
          (handler-case
              (cond
                ((string-equal action-type "UPDATE_ENTITY_FACT")
                 (execute-entity-fact-updates
                   entity-id tenant-id classification run-id))

                ((string-equal action-type "CREATE_PURCHASE_ORDER")
                 ;; Phase 2 — stub
                 `((:success . t) (:message . "Purchase order flow — Phase 2")))

                ((string-equal action-type "ACCUMULATE_SIGNAL")
                 ;; Phase 2 — stub
                 `((:success . t) (:message . "Signal accumulation — Phase 2")))

                (t
                 (log-warn "execute-action: unknown action type ~A" action-type)
                 `((:success . nil)
                   (:error . ,(format nil "Unknown action type: ~A" action-type)))))

            (error (e)
              (log-error "execute-action: execution failed: ~A" e)
              `((:success . nil) (:error . ,(format nil "~A" e))))))

    (let* ((success     (alist-get result :success))
           (elapsed-ms  (round (/ (* (- (get-internal-real-time) start-ms)
                                     1000)
                                  internal-time-units-per-second)))
           (new-status  (if success "COMPLETED" "FAILED")))

      ;; ── Update PLANNED_ACTION status ─────────────────────────
      (db-execute
        "UPDATE DOD_PROCURE_AI_PLANNED_ACTION
         SET STATUS       = ?,
             RESULT       = ?,
             EXECUTED_AT  = NOW(),
             EXECUTED_BY  = ?
         WHERE ROW_ID = ?"
        (list new-status
              (json-encode (append result `((:execution-ms . ,elapsed-ms))))
              "PROFILE-UPDATE-AGENT"
              action-id))

      ;; ── Write COMMERCE_EVENT audit record ────────────────────
      (when success
        (write-commerce-event-for-action
          entity-id entity-type action-type
          result run-id tenant-id))

      ;; ── Write TRACE_EVENT ────────────────────────────────────
      (write-trace-event-for-action
        entity-id action-type result
        elapsed-ms run-id tenant-id success)

      ;; ── Update SIGNAL status ─────────────────────────────────
      (db-execute
        "UPDATE DOD_PROCURE_SIGNAL
         SET STATUS    = ?,
             EVALUATED_BY = ?,
             EVALUATED_AT = NOW(),
             ACTION_ID    = ?
         WHERE ROW_ID = ?"
        (list (if success "ACTED" "FAILED")
              "PROFILE-UPDATE-AGENT"
              action-id
              (row-get signal "ROW_ID")))

      (log-info "execute-action: completed action=~A status=~A elapsed=~Ams"
                action-id new-status elapsed-ms)

      (append result `((:execution-ms . ,elapsed-ms))))))


(defun execute-entity-fact-updates (entity-id tenant-id classification run-id)
  "Core executor for UPDATE_ENTITY_FACT actions.
   For each extracted fact:
     1. Expires the current ENTITY_FACT row (sets VALID_TO=NOW)
     2. Inserts a new ENTITY_FACT row with the new value

   Returns result alist with count of facts updated."
  (let* ((extracted (alist-get classification :extracted '()))
         (facts-updated 0))

    (unless extracted
      (log-warn "execute-entity-fact-updates: no facts to update for entity=~A"
                entity-id)
      (return-from execute-entity-fact-updates
        `((:success . t) (:facts-updated . 0) (:message . "No facts to update"))))

    (dolist (fact extracted)
      (let ((fact-key  (alist-get fact :fact-key
                                  (alist-get fact "fact_key" "")))
            (fact-val  (alist-get fact :fact-val
                                  (alist-get fact "fact_val" "")))
            (fact-type (alist-get fact :fact-type
                                  (alist-get fact "fact_type" "string"))))

        (when (and (> (length fact-key) 0)
                   (> (length (format nil "~A" fact-val)) 0))

          ;; Step 1: expire the current value
          (db-execute
            "UPDATE DOD_PROCURE_ENTITY_FACT
             SET VALID_TO = NOW()
             WHERE ENTITY_ID  = ?
               AND TENANT_ID  = ?
               AND FACT_KEY   = ?
               AND VALID_TO IS NULL"
            (list entity-id tenant-id fact-key))

          ;; Step 2: write the new value
          (db-execute
            "INSERT INTO DOD_PROCURE_ENTITY_FACT
               (ENTITY_ID, TENANT_ID, FACT_KEY, FACT_VAL,
                FACT_TYPE, SOURCE_TYPE, CONFIDENCE,
                VALID_FROM, VALID_TO, ASSERTED_BY)
             VALUES (?, ?, ?, ?, ?, 'AI_EXTRACTED', 0.95,
                     NOW(), NULL, ?)"
            (list entity-id tenant-id fact-key
                  (format nil "~A" fact-val) fact-type run-id))

          (incf facts-updated)
          (log-info "execute-entity-fact-updates: updated ~A = ~A"
                    fact-key fact-val))))

    `((:success       . t)
      (:facts-updated . ,facts-updated))))


(defun write-commerce-event-for-action (entity-id entity-type action-type
                                         result run-id tenant-id)
  "Write the audit COMMERCE_EVENT for a completed action."
  (let ((thread-id (format nil "PROFILE-~A" entity-id))
        (event-type (cond
                      ((string-equal action-type "UPDATE_ENTITY_FACT")
                       "VENDOR_PROFILE_UPDATED")
                      (t "ENTITY_ACTION_COMPLETED"))))
    (db-execute
      "INSERT INTO DOD_PROCURE_COMMERCE_EVENT
         (TENANT_ID, THREAD_ID, THREAD_TYPE,
          EVENT_TYPE, ACTOR_TYPE, ACTOR_ID,
          PAYLOAD, NARRATIVE)
       VALUES (?, ?, 'PROFILE_UPDATE', ?, 'AGENT', 'PROFILE-UPDATE-AGENT', ?, ?)"
      (list tenant-id thread-id event-type
            (json-encode `(("action_type"    . ,action-type)
                            ("entity_id"      . ,entity-id)
                            ("entity_type"    . ,entity-type)
                            ("facts_updated"  . ,(alist-get result :facts-updated 0))
                            ("run_id"         . ,run-id)))
            (format nil "~A completed for ~A ~A. ~A fact(s) updated."
                    action-type entity-type entity-id
                    (alist-get result :facts-updated 0))))))


(defun write-trace-event-for-action (entity-id action-type result
                                      elapsed-ms run-id tenant-id success)
  "Write the TRACE_EVENT for the execution — the episodic memory record."
  (db-execute
    "INSERT INTO DOD_PROCURE_TRACE_EVENT
       (ENTITY_TYPE, ENTITY_ID,
        EVENT_DOMAIN, EVENT_TYPE, EVENT_CODE,
        NARRATIVE_TEXT, EVENT_DATA,
        CONTEXT_ID, ACTOR_TYPE, ACTOR_ID,
        PERSONA_TYPE, SEVERITY, INTENT_DOMAIN, TENANT_ID)
     VALUES ('FUNCTION', 'EXECUTE-ACTION',
             'profile', 'function-executed',
             ?, ?, ?, ?, 'AGENT', 'PROFILE-UPDATE-AGENT',
             'VENDOR', ?, 'PROFILE', ?)"
    (list (if success "FACT-UPDATE-SUCCESS" "FACT-UPDATE-FAILED")
          (format nil "~A for entity ~A. ~A fact(s) updated in ~Ams."
                  action-type entity-id
                  (alist-get result :facts-updated 0)
                  elapsed-ms)
          (json-encode `(("action_type"   . ,action-type)
                          ("facts_updated" . ,(alist-get result :facts-updated 0))
                          ("execution_ms"  . ,elapsed-ms)
                          ("run_id"        . ,run-id)
                          ("success"       . ,success)))
          run-id
          (if success "INFO" "ERROR")
          tenant-id)))

;;; =============================================================================
;;; LLM CONNECTOR — Ollama
;;; =============================================================================

(defun call-local-llm (prompt &key (temperature 0.0)
                                    (max-tokens 500)
                                    (model *ollama-model*))
  "Call local Ollama LLM instance.
   Returns the raw response string.
   Raises an error on HTTP failure.

   TEMPERATURE guide:
     0.0  — classification, slot extraction, confirmation detection
     0.1  — workflow composition
     0.2  — vendor reasoning text (slight variation acceptable)
     0.3  — exception text, human-facing narratives"
  (let* ((request-body (json-encode
                          `(("model"   . ,model)
                            ("prompt"  . ,prompt)
                            ("stream"  . :false)
                            ("options" . (("temperature"  . ,temperature)
                                          ("num_predict"  . ,max-tokens)
                                          ("num_ctx"      . ,*default-context-window*))))))
         (url (format nil "~A/api/generate" *ollama-base-url*)))

    (log-info "call-local-llm: model=~A temp=~A max-tokens=~A"
              model temperature max-tokens)

    (multiple-value-bind (response status)
        (drakma:http-request url
                             :method :post
                             :content-type "application/json"
                             :content request-body
                             :external-format-in  :utf-8
                             :external-format-out :utf-8)
      (unless (= status 200)
        (error "Ollama API returned status ~A. Is Ollama running at ~A?"
               status *ollama-base-url*))

      (let* ((response-str (if (stringp response)
                               response
                               (flexi-streams:octets-to-string
                                 response :external-format :utf-8)))
             (parsed       (json-decode response-str))
             (text         (alist-get parsed :response "")))
        (log-info "call-local-llm: received ~A chars" (length text))
        text))))

;;; =============================================================================
;;; TOP-LEVEL ORCHESTRATOR
;;; =============================================================================

(defun process-chat-message (entity-id entity-type message tenant-id)
  "Main entry point. Called by your web handler for every chat message.

   Runs the complete pipeline:
     1. Write raw message to CHAT_SIGNAL
     2. Call LLM to classify and extract (Touch Point 1)
     3. Promote to SIGNAL
     4. Read SIGNAL_ROUTE
     5. Assemble AGENT_CONTEXT
     6. Write AGENT_CONTEXT
     7. Plan action (SKILL or LLM composition)
     8. Evaluate POLICY
     9. Execute or raise EXCEPTION
    10. Return response for the UI

   Returns alist:
     ((:status   . :completed)   ; or :pending-approval :blocked :failed
      (:message  . \"Done. Updated 2 facts.\")
      (:facts-updated . 2))"

  (log-info "process-chat-message: entity=~A type=~A tenant=~A"
            entity-id entity-type tenant-id)

  ;; ── Step 1: Write raw intake ────────────────────────────────────
  (let* ((chat-signal-id (intake-chat-message
                           entity-id entity-type message tenant-id))
         (_ (log-info "process-chat-message: intake done, chat-signal=~A"
                      chat-signal-id))

         ;; ── Step 2: LLM classifies ──────────────────────────────
         (classification (classify-chat-message chat-signal-id entity-type))
         (_ (unless classification
              (error "Classification failed for chat-signal=~A" chat-signal-id)))

         ;; ── Step 3: Promote to signal ───────────────────────────
         (signal-id (promote-to-signal chat-signal-id classification tenant-id))

         ;; ── Step 4: Route ───────────────────────────────────────
         (route (fetch-signal-route
                  (alist-get classification :classification "CONTEXT_UPDATE")
                  tenant-id))
         (agent-name (row-get route "AGENT_NAME"))

         ;; ── Step 5 & 6: Assemble and write context ──────────────
         (run-id  (generate-run-id entity-id))
         (context (assemble-agent-context
                    run-id agent-name signal-id entity-id tenant-id))
         (_ctx-id (write-agent-context run-id agent-name signal-id context))

         ;; ── Step 7: Plan action ─────────────────────────────────
         (action (plan-action signal-id context classification tenant-id))

         ;; ── Step 8: Policy evaluation ───────────────────────────
         (policy-verdict (evaluate-policy action tenant-id))

         ;; ── Step 9: Execute or escalate ─────────────────────────
         (result
           (case (alist-get policy-verdict :verdict)

             (:auto-approve
              (execute-action action context tenant-id))

             (:require-approval
              (create-exception action policy-verdict tenant-id)
              `((:status  . :pending-approval)
                (:message . "Sent for approval — you will be notified.")))

             (:block
              `((:status  . :blocked)
                (:message . ,(format nil "Action blocked: ~A"
                                     (alist-get policy-verdict :reason))))))))

    ;; ── Step 10: Build UI response ──────────────────────────────
    (build-ui-response classification result)))


(defun intake-chat-message (entity-id entity-type message tenant-id)
  "Write the raw chat message to CHAT_SIGNAL. Returns the new ROW_ID."
  (db-execute
    "INSERT INTO DOD_PROCURE_CHAT_SIGNAL
       (TENANT_ID, ENTITY_ID, ENTITY_TYPE, RAW_MESSAGE,
        CHANNEL, CLASSIFICATION, EXTRACTED,
        CONFIDENCE, STATUS)
     VALUES (?, ?, ?, ?, 'CHAT', 'PENDING', '{}', 0.0, 'NEW')"
    (list tenant-id entity-id entity-type message))
  (db-last-insert-id))


(defun classify-chat-message (chat-signal-id entity-type)
  "Call LLM to classify the message and extract structured facts.
   Updates the CHAT_SIGNAL row with classification result.
   Returns parsed classification alist."
  (let* ((row     (fetch-chat-signal chat-signal-id))
         (message (row-get row "RAW_MESSAGE"))
         (prompt  (build-classification-prompt message entity-type))
         (raw     (call-local-llm prompt :temperature 0.0 :max-tokens 400))
         (parsed  (extract-json-from-llm-response raw)))

    (when parsed
      (db-execute
        "UPDATE DOD_PROCURE_CHAT_SIGNAL
         SET CLASSIFICATION  = ?,
             EXTRACTED       = ?,
             CONFIDENCE      = ?,
             SIGNAL_TYPE     = ?,
             STATUS          = 'CLASSIFIED'
         WHERE ROW_ID = ?"
        (list (alist-get parsed :classification "SOCIAL")
              (json-encode (alist-get parsed :extracted '()))
              (alist-get parsed :confidence 0.5)
              (alist-get parsed :signal-type)
              chat-signal-id)))
    parsed))


(defun build-classification-prompt (message entity-type)
  "Build the classification prompt for the LLM.
   Explicit schema reduces hallucination in 9B models.
   Ends with 'JSON:' to prime the model to output JSON immediately."
  (format nil
    "You are a classifier for a B2B procurement intelligence system.
Classify this message from a ~A and extract structured facts.
Respond with valid JSON only. No explanation. No markdown. No preamble.

CLASSIFICATION OPTIONS:
- TRANSACTION_INTENT: wants to buy, order, or procure something
- CONTEXT_UPDATE: updating profile facts (email, address, phone, VAT, terms)
- WEAK_SIGNAL: future plans, observations, preferences, complaints
- QUERY: asking about orders, invoices, delivery status
- SOCIAL: greeting, thanks, unrelated conversation

FOR CONTEXT_UPDATE — extract facts array:
Each fact must have fact_key using this namespace:
  com.xyz.vendor.identity.name
  com.xyz.vendor.identity.email
  com.xyz.vendor.identity.phone
  com.xyz.vendor.tax.vat_number
  com.xyz.vendor.financial.payment_terms
  com.xyz.vendor.location.address
  com.xyz.vendor.identity.registration_number

RESPONSE SCHEMA:
{
  \"classification\": \"CONTEXT_UPDATE\",
  \"confidence\": 0.96,
  \"signal_type\": null,
  \"extracted\": [
    {\"fact_key\": \"com.xyz.vendor.identity.email\",
     \"fact_val\": \"new@company.com\",
     \"fact_type\": \"string\"}
  ]
}

ENTITY TYPE: ~A
MESSAGE: ~S

JSON:"
    entity-type entity-type message))


(defun promote-to-signal (chat-signal-id classification tenant-id)
  "Promote a classified CHAT_SIGNAL to a DOD_PROCURE_SIGNAL row.
   Returns the new SIGNAL ROW_ID."
  (let* ((row         (fetch-chat-signal chat-signal-id))
         (entity-id   (row-get row "ENTITY_ID"))
         (entity-type (row-get row "ENTITY_TYPE"))
         (signal-type (alist-get classification :classification "SOCIAL"))
         (extracted   (alist-get classification :extracted '()))
         (confidence  (alist-get classification :confidence 0.5)))

    (db-execute
      "INSERT INTO DOD_PROCURE_SIGNAL
         (SIGNAL_TYPE, ENTITY_TYPE, ENTITY_ID,
          OBSERVED_VALUE, CONFIDENCE, STATUS,
          SCOUT_TYPE, TENANT_ID)
       VALUES (?, ?, ?, ?, ?, 'NEW', 'CHAT-INTAKE', ?)"
      (list signal-type entity-type entity-id
            (json-encode `(("classification" . ,signal-type)
                            ("extracted"      . ,extracted)
                            ("chat_signal_id" . ,chat-signal-id)))
            confidence tenant-id))

    (let ((signal-id (db-last-insert-id)))
      (db-execute
        "UPDATE DOD_PROCURE_CHAT_SIGNAL
         SET STATUS = 'PROMOTED', SIGNAL_ID = ?
         WHERE ROW_ID = ?"
        (list signal-id chat-signal-id))
      (log-info "promote-to-signal: signal=~A type=~A" signal-id signal-type)
      signal-id)))


(defun create-exception (action policy-verdict tenant-id)
  "Write an EXCEPTION row when policy requires human approval.
   The procurement manager sees this in their exception inbox."
  (db-execute
    "INSERT INTO DOD_PROCURE_AI_EXCEPTION
       (ACTION_ID, EXCEPTION_TYPE, EXCEPTION_TEXT,
        OPTIONS, SLA_HOURS, TENANT_ID)
     VALUES (?, 'APPROVAL_REQUIRED', ?, ?, 24, ?)"
    (list (row-get action "ROW_ID")
          (format nil "Action requires approval: ~A"
                  (alist-get policy-verdict :reason))
          (json-encode
            '((("label"       . "Approve")
               ("action"      . "APPROVE")
               ("consequence" . "Action executes immediately"))
              (("label"       . "Reject")
               ("action"      . "REJECT")
               ("consequence" . "Action cancelled"))))
          tenant-id)))


(defun build-ui-response (classification result)
  "Build the response string to display in the chat interface."
  (let ((cls     (alist-get classification :classification "SOCIAL"))
        (success (alist-get result :success t))
        (updated (alist-get result :facts-updated 0))
        (status  (alist-get result :status :completed))
        (message (alist-get result :message)))

    (cond
      ;; Explicit message from pipeline
      (message
       `((:status . ,status) (:message . ,message)))

      ;; Successful fact update
      ((and (string-equal cls "CONTEXT_UPDATE") success)
       `((:status  . :completed)
         (:message . ,(format nil "Done. Updated ~A detail~:P successfully."
                              updated))
         (:facts-updated . ,updated)))

      ;; General success
      (success
       `((:status  . :completed)
         (:message . "Request processed successfully.")))

      ;; Failure
      (t
       `((:status  . :failed)
         (:message . "Something went wrong. Please try again or contact support."))))))

;;; =============================================================================
;;; EOF
;;; =============================================================================
