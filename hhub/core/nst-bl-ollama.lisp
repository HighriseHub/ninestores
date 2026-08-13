;;; nst-bl-ollama.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; ============================================================================
;;; Configuration & Parameters
;;; ============================================================================

;; Providers Setup
(defparameter *ollama-url* "http://192.168.0.110:11434/api/generate")
(defparameter *ollama-default-model* "qwen3.5:latest")

(defparameter *deepseek-url* "https://api.deepseek.com/v1/chat/completions")
(defparameter *deepseek-default-model* "deepseek-v4-flash") ; DeepSeek-V3 (use "deepseek-reasoner" for R1)

;; Template Paths
(defvar *dod-vend-profile-table* "/home/ubuntu/ninestores/hhub/vendor/templates/dod-vend-profile.txt")
(defvar *dod-invoice-header-table* "/home/ubuntu/ninestores/hhub/vendor/templates/dod-invoice-header.txt")
(defvar *dod-invoice-items-table* "/home/ubuntu/ninestores/hhub/vendor/templates/dod-invoice-items.txt")

;; State Variables
(defvar *chat-history* nil 
  "Stores a rolling, low-overhead conversation window for contextual follow-ups.")

(defvar *nst-function-symbols* (funcall (function-lookup-table)))


;;; ============================================================================
;;; Core Multi-Provider Generation Router
;;; ============================================================================

(defun deepseek-p (model-name)
  "Determines if the requested model belongs to the DeepSeek platform ecosystem."
  (and model-name 
       (or (search "deepseek" (string-downcase model-name))
           (string-equal model-name "ds"))))

(defun llm-generate (prompt &key system model stream)
  "Unified generation dispatcher. Supports real-time REPL stream echo 
   via the :stream T parameter for local Ollama models."
  (let* ((target-model (or model *ollama-default-model*))
         (is-deepseek (deepseek-p target-model)))
    (if is-deepseek
        ;; --- DeepSeek Path (Standard Non-Streaming Endpoint) ---
	;; --- DeepSeek Path (Fixed & Verified) ---
	;; --- DeepSeek Path (Structured with Backquote for JSON safety) ---
	(let* ((api-key (or *DEEPSEEKAPIKEY*
                            (error "DEEPSEEKAPIKEY variable is not defined.")))
	       (messages (if system
			     (list `((:role . "system") (:content . ,system))
				   `((:role . "user") (:content . ,prompt)))
			     (list `((:role . "user") (:content . ,prompt)))))
	       (payload (json:encode-json-to-string
			 `((:model . "deepseek-v4-flash") ; Using direct, standard model identifier string
			   (:messages . ,messages)
			   (:stream . nil)
                   (:temperature . 0.2))))
       (raw-response (drakma:http-request
                      "https://api.deepseek.com/v1/chat/completions"
                      :method :POST
                      :content payload
                      :content-type "application/json"
                      :additional-headers `(("Authorization" . ,(format nil "Bearer ~A" api-key))))))
  
	  (let* ((response-string (map 'string #'code-char raw-response))
		 (json-obj (json:decode-json-from-string response-string))
		 (choices (cdr (assoc :choices json-obj))))
	    (if choices
		(let* ((first-choice (elt choices 0))
		       (message-obj (cdr (assoc :message first-choice))))
		  (cdr (assoc :content message-obj)))
		(progn
		  (format t "~&[DeepSeek Debug Raw Response]: ~A~%" response-string)
		  nil))))

	          ;; --- Ollama Path (Supports both Live Echo & Unified Return) ---
        (let* ((payload (json:encode-json-to-string
                         `((:model . ,target-model)
                           (:prompt . ,prompt)
                           ,@(when system `((:system . ,system)))
                           ;; Set stream to true if requested
                           (:stream . ,(if stream t nil)))))
               (raw-response (drakma:http-request
                              *ollama-url*
                              :method :POST
                              :content payload
                              :content-type "application/json"
                              :external-format-out :utf-8
                              :external-format-in :utf-8)))
          ;; parse-ollama-ndjson prints chunks to screen if stream is T, 
          ;; but ALWAYS returns the complete concatenated string right here.
          (parse-ollama-ndjson (map 'string #'code-char raw-response) :print-stream stream)))))



;; Retained for backwards-compatibility mapping layers
(defun ollama-generate (prompt &key system)
  (llm-generate prompt :system system :model *ollama-default-model*))

(defun parse-ollama-ndjson (string &key print-stream)
  "Parses Ollama's NDJSON stream response. If PRINT-STREAM is T, 
   it echoes chunks to the REPL in real-time while accumulating the full text string."
  (with-output-to-string (out)
    (dolist (line (split-sequence:split-sequence #\Newline string))
      (when (plusp (length line))
        (let* ((obj (json:decode-json-from-string line))
               (chunk (cdr (assoc :response obj))))
          (when chunk
            (write-string chunk out)
            (when print-stream
              (write-string chunk *standard-output*)
              (force-output *standard-output*)))))))) ; Force Emacs/REPL to render it immediately



;;; ============================================================================
;;; Technical Analysis & SQL Coprocessor
;;; ============================================================================

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

(defun nl-to-sql (natural-language &key model)
  (let ((sql-schema (format nil "~A ~A ~A "
      (funcall (nst-get-cached-vendor-tables-structure-for-agentic-ai :templatenum 1))
      (funcall (nst-get-cached-vendor-tables-structure-for-agentic-ai :templatenum 2))
      (funcall (nst-get-cached-vendor-tables-structure-for-agentic-ai :templatenum 3)))))
    (llm-generate
     (format nil
             "Database Schema:
~A
~A 
User Request:
~A"
           sql-schema *sql-schema-rules* natural-language)
   :system "You are a MySQL query generator. Return a complete SQL query. The query must end with a semicolon."
   :model model)))

(defun unsafe-sql-p (sql)
  (or (search "DROP" sql :test #'char-equal)
      (search "TRUNCATE" sql :test #'char-equal)
      (search "ALTER" sql :test #'char-equal)
      (search "DELETE" sql :test #'char-equal)))

(defun safe-nl-to-sql (input &key model)
  (let ((sql (nl-to-sql input :model model)))
    (if (unsafe-sql-p sql)
        (error "Unsafe SQL generated: ~A" sql)
        sql)))

;;; ============================================================================
;;; REPL Ergonomics & Live Image Helpers
;;; ============================================================================

(defun ollama-lisp-help (code &key look-up-fn model)
  "Enhanced interactive help helper. If :look-up-fn is passed, it extracts the 
   live runtime system documentation string directly from the running Lisp image."
  (let ((final-prompt 
          (if look-up-fn
              (format nil "Explain the usage and structure of the function or macro '~A'.~%~%Live Environment Documentation:~%~A~%~%~A"
                      look-up-fn 
                      (or (documentation look-up-fn 'function) "No active docstring found in image.")
                      code)
              code)))
    (llm-generate
     final-prompt
     :system "You are a senior Common Lisp developer. Explain idiomatic Lisp usage, macros, closures, and functional design. Be precise and concise."
     :model model)))

(defmacro qlisp (form &key explain model)
  "Surgical REPL prompter interface. Captures raw Common Lisp forms without 
   requiring manual text quote wrapping or escaping nested string tokens."
  `(llm-generate 
    (format nil "Look at this Common Lisp code sequence:~%~S~%~%~A" 
            ',form 
            ,(if explain 
                 explain 
                 "Review this code architecture for idiomatic style, performance bottlenecks, or runtime safety."))
    :system "You are an elite Common Lisp compiler architect. Be concise and precise."
    :model ,model))


(defun ollama-chat (prompt &key model)
  (let ((target-model (or model "deepseek")))
    (if (string-equal target-model "deepseek")
        ;; DeepSeek Path
        (let ((response (llm-generate prompt :system "You are a helpful assistant." :model "deepseek-v4-flash")))
          (when response
            (format t "~&~A~%" response) ; Explicitly print to the screen!
            (push (format nil "User: ~A" prompt) *chat-history*)
            (push (format nil "Assistant: ~A" response) *chat-history*))
          (values))
        
        ;; Ollama Local Path (Streaming)
        (progn
          (format t "~&~%")
          (let ((response (llm-generate prompt :model target-model :stream t)))
            (push (format nil "User: ~A" prompt) *chat-history*)
            (push (format nil "Assistant: ~A" response) *chat-history*)
            (values))))))

(defun clear-chat ()
  "Flushes the local conversation memory frame clean."
  (setf *chat-history* nil))

;;; ============================================================================
;;; Low-Bloat ReAct Token Controller & Executor
;;; ============================================================================


(defun execute-agent-action (action-alist)
  "Maps an alist structural command format from the agent directly to execution routines."
  (let* ((tool-name (cdr (assoc 'ACTION action-alist :test #'string-equal)))
         (target    (cdr (assoc 'TARGET action-alist :test #'string-equal)))
         (content   (cdr (assoc 'CONTENT action-alist :test #'string-equal))))
    (cond
      ((string-equal tool-name "lookup-metadata")
       ;; Target holds the function symbol name (e.g., 'calculate-stuff)
       (let ((target-sym (intern (string-upcase (format nil "~A" target)))))
	 (format t "Target symbol is ~A" target-sym)
	 (multiple-value-bind (meta foundp) (tool-find-function-metadata target-sym)
           (if foundp
               (format nil "~S" meta)
               (format nil "ERROR: Function symbol '~A' not found in project index." target-sym)))))

      ((string-equal tool-name "read-source-file")
       ;; Target holds the filename or explicit file path string
       (handler-case (get-source-code-reflective (format nil "~A" target))
         (error (e) (format nil "ERROR: Could not read file. ~A" e))))
      
      ((string-equal tool-name "save-and-recompile")
       ;; For saving, target is the symbol name, content holds the new code string
       (let ((sym (intern (string-upcase (format nil "~A" target)))))
	 (multiple-value-bind (meta foundp) (tool-find-function-metadata sym)
	   (if (and foundp (getf meta :file-path))
               (apply-file-refactor-and-load sym (getf meta :file-path) content)
               (format nil "ERROR: Cannot write to disk. Metadata lookup failed for '~A'." target)))))
      (t (format nil "ERROR: Tool command action '~A' is unrecognized." tool-name)))))


(defun extract-function-name (sentence)
  "Pulls the last word/symbol name out of the user prompt string."
  (let ((words (cl-ppcre:split "\\s+" (string-trim " ." sentence))))
    (string-upcase (car (last words)))))


(defun run-autonomous-task (objective &key (max-steps 5))
  "Manages the agent loop, reading raw LLM strings directly into live Lisp S-expressions."
  (format t "~&--- Starting Task: '~A' ---~%" objective)
  
  (let ((current-prompt objective))
    (dotimes (step max-steps (format t "~&[Agent]: Hit maximum step cutoff before completion.~%"))
      (format t "~&~%[Step ~D] Consulting LLM...~%" (1+ step))
      ;; 1. Send our structured context up to your verified llm-generate function
      (let* ((raw-llm-string (llm-generate current-prompt 
                                           :system *refactoring-agent-prompt* :model "deepseek"))
             ;; 2. SAFELY convert the text directly into a live Lisp list
             (action-spec (with-standard-io-syntax
                            (let ((*read-eval* nil)) ; Crucial security guardrail
                              (read-from-string raw-llm-string)))))
        (format t "[LLM Native S-Exp Output]: ~S~%" action-spec)
        ;; 3. Check for the termination signal
	(let ((action  (cdr (assoc :action  action-spec :test #'string-equal)))
	      (content (cdr (assoc :content action-spec :test #'string-equal))))
	  (if (string-equal action "complete")
	      (progn
		(format t "~&~%[Task Complete]:~%~A~%" content)
		(return-from run-autonomous-task content))
	      (let ((action-result (execute-agent-action action-spec)))
		(format t "[Action Result]: ~A~%" action-result)
		;; Update history loop context frame
		(setf current-prompt 
                      (format nil "The tool execution returned: ~A. Provide your next action list." 
                              action-result)))))))))

(defparameter *refactoring-agent-prompt*
  "You are a specialized Common Lisp Refactoring Agent for the ninestores project.
You respond exclusively with a single Common Lisp association list (alist).
No markdown. No explanatory prose. Output only the raw alist — nothing before or after it.

OUTPUT FORMAT (exact shape, every single turn):
((:action . \"tool-name\") (:target . \"value\") (:content . nil) (:reason . \"brief rationale\"))

PIPELINE — three phases, executed in strict sequential order:

PHASE 1 — LOOKUP METADATA  (always your very first response)
  Confirm the function exists in the project index and retrieve its metadata.
  :action  -> \"lookup-metadata\"
  :target  -> The exact function symbol name the user gave (e.g., calculate-stuff)
  :content -> nil

PHASE 2 — READ LIVE SOURCE  (after Phase 1 confirms the function is found)
  Read the complete source code of the function directly from the running Lisp image.
  Use the same symbol name from Phase 1. The runtime resolves the file location internally.
  :action  -> \"read-source-file\"
  :target  -> The same function symbol name used in Phase 1 — unchanged
  :content -> nil

PHASE 3 — COMPLETE  (after Phase 2 returns the full source text)
  Analyze the source. Produce a clean, idiomatic, production-ready replacement.
  Do not call any further tools.
  :action  -> \"complete\"
  :target  -> The function symbol name
  :content -> The COMPLETE valid refactored (defun ...) block as a string. Copy-paste ready.
  :reason  -> Concise summary of every change made.")



(defun refactor-live-function-old (function-symbol &key (max-steps 5))
  "Drives the 3-phase refactoring agent loop for FUNCTION-SYMBOL.
   Phase 1: lookup-metadata -> Phase 2: read-source-file -> Phase 3: complete.
   Returns the refactored defun string on success, NIL on parse error or step exhaustion."
  (let* ((fn-name       (string-upcase (format nil "~A" function-symbol)))
         (current-prompt (format nil "Refactor the function ~A. Begin with Phase 1." fn-name)))

    (format t "~&~%=== Refactoring Session: ~A ===" fn-name)

    (dotimes (step max-steps
              (progn
                (format t "~&~%[Agent] ~D-step budget exhausted — no completion signal received.~%" max-steps)
                nil))

      (format t "~&~%[Step ~D/~D] Querying refactoring agent...~%" (1+ step) max-steps)

      (let* ((raw-output   (llm-generate current-prompt
                                         :system *refactoring-agent-prompt*
                                         :model "deepseek"))
             (action-alist (handler-case
                               (with-standard-io-syntax
                                 (let ((*read-eval* nil))
                                   (read-from-string raw-output)))
                             (error (e)
                               (format t "~&[Parse Error] LLM output is not a valid S-expression.~%Reason: ~A~%Raw output:~%~A~%"
                                       e raw-output)
                               (return-from refactor-live-function-old nil)))))

        (format t "[Agent] ~S~%" action-alist)

        (let ((action  (cdr (assoc :action  action-alist :test #'string-equal)))
              (content (cdr (assoc :content action-alist :test #'string-equal))))

          (cond
            ;; Terminal state — agent has finished and returned the refactored code in :content
            ((string-equal action "complete")
             (format t "~&~%=== Refactored Output (~A) ===~%~%~A~%~%=== End ===~%" fn-name content)
             (return-from refactor-live-function-old content))

            ;; Intermediate step — execute the tool and feed the result back into the next prompt
            (t
             (let ((tool-result (execute-agent-action action-alist)))
               (format t "[Tool Result] ~A~%" tool-result)
               (setf current-prompt
                     (format nil "Tool returned:~%~A~%~%Proceed to the next phase." tool-result))))))))))

;;; ============================================================================
;;; Refactoring Agent - Fixed Alist Handling
;;; ============================================================================

(defun safe-read-alist (string)
  "Safely read an alist from string, returns alist as-is."
  (handler-case
      (let ((*read-eval* nil))
        ;; Clean up common LLM artifacts
        (setf string (cl-ppcre:regex-replace-all "`" string ""))
        (setf string (cl-ppcre:regex-replace-all "^```lisp\\s*" string ""))
        (setf string (cl-ppcre:regex-replace-all "^```\\s*" string ""))
        (setf string (cl-ppcre:regex-replace-all "```\\s*$" string ""))
        (setf string (string-trim " " string))
        
        (let ((form (read-from-string string)))
          ;; Validate it's an alist (list of cons cells)
          (if (and (listp form)
                   (every #'consp form))
              form
              (progn
                (format t "~&[DEBUG] Not an alist: ~S~%" form)
                nil))))
      (error (e)
        (format t "~&[Parse Error] ~A~%Input: ~A~%" e string)
        nil)))

(defun alist-get (key alist)
  "Get value from alist by key (case-insensitive string comparison)."
  (cdr (assoc key alist :test #'string-equal)))

;; Fixed file write in apply-file-refactor-and-load (critical bug fix)
(defun apply-file-refactor-and-load (function-symbol file-path new-code-string)
  "Fixes the dangerous :if-exists :append bug."
  (handler-case
      (let* ((file-content (uiop:read-file-string file-path))
             (symbol-name (string-downcase (symbol-name function-symbol)))
             (pattern-1 (format nil "(defun ~A " symbol-name))
             (pattern-2 (format nil "(defun ~A~%" symbol-name))
             (start-pos (or (search pattern-1 (string-downcase file-content))
                            (search pattern-2 (string-downcase file-content)))))
        
        (unless start-pos
          (return-from apply-file-refactor-and-load 
            (format nil "FAILURE: Could not find '(defun ~A' in ~A" symbol-name file-path)))
        
        (let ((end-pos (with-input-from-string (s file-content :start start-pos)
                         (let ((*read-eval* nil))
                           (read s)
                           (file-position s)))))
          
          (let ((updated-content (concatenate 'string
                                              (subseq file-content 0 start-pos)
                                              new-code-string
                                              (subseq file-content (+ start-pos end-pos)))))
            
            ;; FIXED: Replace file, don't append
            (with-open-file (out file-path :direction :output 
                                           :if-exists :supersede
                                           :if-does-not-exist :create)
              (write-string updated-content out))
            
            (multiple-value-bind (output-truename warnings-p failure-p)
                (compile-file file-path)
              (declare (ignore output-truename))
              (if failure-p
                  (format nil "FAILURE: Compilation errors in ~A" file-path)
                  (progn
                    (load (compile-file-pathname file-path))
                    (format nil "SUCCESS: ~A refactored and reloaded from ~A" 
                            function-symbol file-path)))))))
    (error (e)
      (format nil "FAILURE: ~A" e))))


(defun tool-find-function-metadata (function-symbol)
  "Searches the function lookup dataset for a matching function or generic-function.
   Accepts symbols or strings (case-insensitive)."
  (let* ((search-str (string-upcase (format nil "~A" function-symbol)))
         ;; Find the matching sublist where the first element matches our search string
         (match (assoc search-str *nst-function-symbols* :test #'string-equal)))
    (if match
        (destructuring-bind (name type file-path arg1 arg2 flag) match
          (declare (ignore arg1 arg2 flag))
          (values (list :name name
                        :type type
                        :file-path file-path)
                  t))
        (values nil nil))))

;; Helper function for clean string concatenation
(defun concat-strings (&rest strings)
  (apply #'concatenate 'string strings))

(defun locate-source-via-swank (symbol)
  "Leverages SLIME's backend to programmatically find a symbol's definition source."
  (let ((definitions (swank:find-definitions-for-emacs symbol)))
    (when definitions
      (let* ((match (first definitions))
             (location (second match)))
        (when (eq (first location) :location)
          (let ((file-spec (assoc :file (cdr location)))
                (pos-spec (assoc :position (cdr location))))
            (values (second file-spec)   ;; Returns the absolute filename string
                    (second pos-spec)))))))) ;; Returns the character location integer

(defun read-source-from-swank-location (file-path position)
  "Reads the complete S-expression form from a file path starting at a Swank position."
  (handler-case
      (if (and file-path (probe-file file-path))
          (with-open-file (stream file-path :direction :input :external-format :utf-8)
            ;; 1. Wind the stream to the Swank position marker
            (file-position stream (1- position))
            
            ;; 2. Safe-bind read-eval
            (let* ((*read-eval* nil)
                   ;; Read parses the complete top-level form automatically
                   (parsed-form (read stream)))
              
              ;; 3. Render the read data back out to a pristine string
              (with-output-to-string (out)
                ;; Using standard format with ~S or ~A handles structure safely,
                ;; or use cl:pprint if you want beautifully indented output layout.
                (let ((*print-case* :downcase))
                  (format out "~S" parsed-form)))))
          (format nil "ERROR: File path ~A does not exist." file-path))
    (error (e)
      (format nil "ERROR: Failed to extract source text reflectively: ~A" e))))
(defun get-source-code-reflective (function-symbol)
  "Reflectively pulls the complete raw text source code of a live function symbol using Swank."
  (multiple-value-bind (file-path position) (locate-source-via-swank function-symbol)
    (if (and file-path position)
        (read-source-from-swank-location file-path position)
        (format nil "ERROR: Swank could not resolve a memory location for symbol '~A'." function-symbol))))




;;; ============================================================================
;;; Agent Tool Registry — DEFINE-TOOL Macro Pattern
;;; ============================================================================

(defparameter *agent-tools* nil
  "Registry of all tools available to the refactoring agent.
   Populated automatically by DEFINE-TOOL at load time.")

(defmacro define-tool (name (target-arg) docstring &body body)
  "Defines a Lisp function, registers it as an agent tool, and attaches
   its documentation to its symbol plist in one form.
   The system prompt is auto-generated from registered tools at call time —
   it is always in sync with the implementation."
  `(progn
     (defun ,name (,target-arg)
       ,docstring
       ,@body)
     (setf (get ',name :agent-tool)  t
           (get ',name :tool-doc)    ,docstring
           (get ',name :tool-arg)    ,(string-downcase (symbol-name target-arg)))
     (pushnew ',name *agent-tools*)
     ',name))


;;; Tool Definitions — each is a live Lisp function and a registered agent tool

(define-tool lookup-metadata (function-name)
  "Confirms FUNCTION-NAME exists in the project index. Returns its metadata plist."
  (let ((sym (intern (string-upcase (format nil "~A" function-name)))))
    (multiple-value-bind (meta foundp) (tool-find-function-metadata sym)
      (if foundp
          (format nil "~S" meta)
          (format nil "ERROR: '~A' not found in project index." function-name)))))

(define-tool read-source-file (function-name)
  "Retrieves the complete live source code of FUNCTION-NAME from the running image via Swank."
  (let ((clean-name (string-upcase
                     (car (last (cl-ppcre:split ":" (string function-name)))))))
    (handler-case
        (get-source-code-reflective clean-name)
      (error (e)
        (format nil "ERROR: Swank lookup failed for '~A': ~A" clean-name e)))))



(defun dispatch-tool (action-alist)
  "Resolves the tool name to its registered symbol and calls it directly.
   Adding a new tool requires only a new DEFINE-TOOL form — nothing here changes."
  (let* ((tool-name (cdr (assoc :action action-alist :test #'string-equal)))
         (target    (cdr (assoc :target action-alist :test #'string-equal)))
         (tool-sym  (find-symbol (string-upcase (format nil "~A" tool-name)) *package*)))
    (if (and tool-sym (get tool-sym :agent-tool))
        (funcall tool-sym target)
        (format nil "ERROR: '~A' is not a registered tool." tool-name))))

(defun generate-agent-prompt ()
  "Builds the agent system prompt directly from the registered tool docstrings.
   The prompt is always in sync with the implementation — there is no separate schema."
  (format nil
    "You are a Common Lisp Refactoring Agent for the ninestores project.
You respond exclusively with a single Common Lisp alist. No markdown. No prose.

OUTPUT FORMAT (every turn):
((:action . \"tool-name\") (:target . \"value\") (:content . nil) (:reason . \"rationale\"))

AVAILABLE TOOLS:
~{~A~%~}
PIPELINE: Call each tool in order. On the final step, use action \"complete\" with :content
holding the full refactored (defun ...) block and :target holding the function name."
    (mapcar (lambda (tool-sym)
              (format nil "  ~A — ~A"
                      (string-downcase (symbol-name tool-sym))
                      (get tool-sym :tool-doc)))
            (reverse *agent-tools*))))


(define-condition refactoring-complete ()
  ((result :initarg :result :reader refactoring-result)
   (target :initarg :target :reader refactoring-target))
  (:documentation "Signalled when the agent delivers a completed refactoring.
                   Caught by the agent loop to terminate cleanly with the result."))

(defun refactor-live-function (function-symbol &key (max-steps 5))
  "Drives the refactoring agent loop for FUNCTION-SYMBOL.
   Termination is handled via the condition system — REFACTORING-COMPLETE is signalled
   when the agent issues the complete action, caught here to return the result string."
  (let* ((fn-name       (string-upcase (format nil "~A" function-symbol)))
         (system-prompt (generate-agent-prompt))
         (current-prompt (format nil "Refactor the function ~A. Begin with Phase 1." fn-name)))

    (format t "~&~%=== Refactoring Session: ~A ===" fn-name)

    (handler-case
        (dotimes (step max-steps
                  (progn
                    (format t "~&~%[Agent] ~D-step budget exhausted.~%" max-steps)
                    nil))

          (format t "~&~%[Step ~D/~D]~%" (1+ step) max-steps)

          (let* ((raw-output   (llm-generate current-prompt
                                             :system system-prompt
                                             :model "deepseek"))
                 (action-alist (handler-case
                                   (with-standard-io-syntax
                                     (let ((*read-eval* nil))
                                       (read-from-string raw-output)))
                                 (error (e)
                                   (format t "~&[Parse Error] ~A~%Raw: ~A~%" e raw-output)
                                   (return-from refactor-live-function nil)))))

            (format t "[Agent] ~S~%" action-alist)

            (let ((action  (cdr (assoc :action  action-alist :test #'string-equal)))
                  (content (cdr (assoc :content action-alist :test #'string-equal))))

              (if (string-equal action "complete")
                  ;; Signal completion — unwinds to handler-case below
                  (signal 'refactoring-complete :result content :target fn-name)
                  (let ((tool-result (dispatch-tool action-alist)))
                    (format t "[Tool] ~A~%" tool-result)
                    (setf current-prompt
                          (format nil "Tool returned:~%~A~%~%Proceed to the next phase."
                                  tool-result)))))))

      ;; Clean termination path
      (refactoring-complete (c)
        (format t "~&~%=== Refactored: ~A ===~%~%~A~%~%=== End ===~%"
                (refactoring-target c) (refactoring-result c))
        (refactoring-result c)))))
