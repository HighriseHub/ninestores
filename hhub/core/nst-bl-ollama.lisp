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
(defvar *last-refactored-code* nil
  "Holds the most recent code string from refactor-live-function.
   Pass to commit-refactoring to write it to disk.")

(defvar *last-refactored-target* nil
  "Holds the function symbol from the most recent refactor-live-function session.")

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

(defun llm-generate (prompt &key system (model *deepseek-default-model*)  stream)
  "Unified generation dispatcher. Supports real-time REPL stream echo
   via the :stream T parameter for local Ollama models."
  (let* ((target-model (or model *ollama-default-model*))
         (is-deepseek  (deepseek-p target-model)))
    (if is-deepseek
        ;; --- DeepSeek Path ---
        (let* ((api-key  (or *DEEPSEEKAPIKEY*
                             (error "DEEPSEEKAPIKEY variable is not defined.")))
               (messages (if system
                             (list `((:role . "system") (:content . ,system))
                                   `((:role . "user")   (:content . ,prompt)))
                             (list `((:role . "user")   (:content . ,prompt)))))
               (payload  (json:encode-json-to-string
                          `((:model       . "deepseek-v4-flash")
                            (:messages    . ,messages)
                            (:stream      . nil)
                            (:temperature . 0.2))))
               (raw-response (drakma:http-request
                              "https://api.deepseek.com/v1/chat/completions"
                              :method :POST
                              :content payload
                              :content-type "application/json"
                              :additional-headers `(("Authorization" . ,(format nil "Bearer ~A" api-key))))))
          (let* ((response-string (map 'string #'code-char raw-response))
                 (json-obj        (json:decode-json-from-string response-string))
                 (choices         (cdr (assoc :choices json-obj))))
            (if choices
                (let* ((first-choice (elt choices 0))
                       (message-obj  (cdr (assoc :message first-choice))))
                  (cdr (assoc :content message-obj)))
                (progn
                  (format t "~&[DeepSeek Debug Raw Response]: ~A~%" response-string)
                  nil))))
        ;; --- Ollama Path (supports both live echo and unified return) ---
        (let* ((payload (json:encode-json-to-string
                         `((:model  . ,target-model)
                           (:prompt . ,prompt)
                           ,@(when system `((:system . ,system)))
                           (:stream . ,(if stream t nil)))))
               (raw-response (drakma:http-request
                              *ollama-url*
                              :method :POST
                              :content payload
                              :content-type "application/json"
                              :external-format-out :utf-8
                              :external-format-in  :utf-8)))
          ;; parse-ollama-ndjson prints chunks to screen if stream is T,
          ;; but ALWAYS returns the complete concatenated string.
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
        (let* ((obj   (json:decode-json-from-string line))
               (chunk (cdr (assoc :response obj))))
          (when chunk
            (write-string chunk out)
            (when print-stream
              (write-string chunk *standard-output*)
              (force-output *standard-output*))))))))  ; Force Emacs/REPL to render immediately


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
     (format nil "Database Schema:~%~A~%~A~%User Request:~%~A" sql-schema *sql-schema-rules* natural-language)
     :system "You are a MySQL query generator. Return a complete SQL query. The query must end with a semicolon."
     :model model)))

(defun unsafe-sql-p (sql)
  (or (search "DROP"     sql :test #'char-equal)
      (search "TRUNCATE" sql :test #'char-equal)
      (search "ALTER"    sql :test #'char-equal)
      (search "DELETE"   sql :test #'char-equal)))

(defun safe-nl-to-sql (input &key model)
  (let ((sql (nl-to-sql input :model model)))
    (if (unsafe-sql-p sql)
        (error "Unsafe SQL generated: ~A" sql)
        sql)))


;;; ============================================================================
;;; REPL Ergonomics & Live Image Helpers
;;; ============================================================================

(defun ollama-lisp-help (code &key look-up-fn (model *ollama-default-model*))
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

(defmacro qlisp (form &key explain (model *deepseek-default-model*))
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

(defun ollama-chat (prompt &key (model *ollama-default-model*))
  (let ((target-model (or model "deepseek")))
    (if (string-equal target-model "deepseek")
        ;; DeepSeek Path
        (let ((response (llm-generate prompt :system "You are a helpful assistant." :model "deepseek-v4-flash")))
          (when response
            (format t "~&~A~%" response)   ; Explicitly print to the screen
            (push (format nil "User: ~A"      prompt)   *chat-history*)
            (push (format nil "Assistant: ~A" response) *chat-history*))
          (values))
        ;; Ollama Local Path (Streaming)
        (progn
          (format t "~&~%")
          (let ((response (llm-generate prompt :model target-model :stream t)))
            (push (format nil "User: ~A"      prompt)   *chat-history*)
            (push (format nil "Assistant: ~A" response) *chat-history*)
            (values))))))

(defun clear-chat ()
  "Flushes the local conversation memory frame clean."
  (setf *chat-history* nil))


;;; ============================================================================
;;; Low-Bloat ReAct Token Controller & Executor
;;; ============================================================================

(defun execute-agent-action (action-alist)
  "Maps an alist structural command format from the agent directly to execution routines.
   Kept alongside dispatch-tool for use by run-autonomous-task."
  (let* ((tool-name (cdr (assoc 'ACTION  action-alist :test #'string-equal)))
         (target    (cdr (assoc 'TARGET  action-alist :test #'string-equal)))
         (content   (cdr (assoc 'CONTENT action-alist :test #'string-equal))))
    (cond
      ((string-equal tool-name "lookup-metadata")
       (let ((target-sym (intern (string-upcase (format nil "~A" target)))))
         (format t "Target symbol is ~A" target-sym)
         (multiple-value-bind (meta foundp) (tool-find-function-metadata target-sym)
           (if foundp
               (format nil "~S" meta)
               (format nil "ERROR: Function symbol '~A' not found in project index." target-sym)))))

      ((string-equal tool-name "read-source-file")
       (handler-case (get-source-code-reflective (format nil "~A" target))
         (error (e) (format nil "ERROR: Could not read source. ~A" e))))

      ((string-equal tool-name "save-and-recompile")
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
      (let* ((raw-llm-string (llm-generate current-prompt
                                           :system *refactoring-agent-prompt* :model "deepseek"))
             (action-spec    (with-standard-io-syntax
                               (let ((*read-eval* nil))  ; Security guardrail
                                 (read-from-string raw-llm-string)))))
        (format t "[LLM Native S-Exp Output]: ~S~%" action-spec)
        (let ((action  (cdr (assoc :action  action-spec :test #'string-equal)))
              (content (cdr (assoc :content action-spec :test #'string-equal))))
          (if (string-equal action "complete")
              (progn
                (format t "~&~%[Task Complete]:~%~A~%" content)
                (return-from run-autonomous-task content))
              (let ((action-result (execute-agent-action action-spec)))
                (format t "[Action Result]: ~A~%" action-result)
                (setf current-prompt
                      (format nil "The tool execution returned: ~A. Provide your next action list."
                              action-result)))))))))


;;; ============================================================================
;;; Refactoring Agent — System Prompt (used by run-autonomous-task)
;;; ============================================================================

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


;;; ============================================================================
;;; S-Expression Parse Utilities
;;; ============================================================================

(defun safe-read-alist (string)
  "Safely reads an alist from STRING. Strips common LLM markdown artifacts before parsing."
  (handler-case
      (let ((*read-eval* nil))
        (setf string (cl-ppcre:regex-replace-all "`"         string ""))
        (setf string (cl-ppcre:regex-replace-all "^```lisp\\s*" string ""))
        (setf string (cl-ppcre:regex-replace-all "^```\\s*"  string ""))
        (setf string (cl-ppcre:regex-replace-all "```\\s*$"  string ""))
        (setf string (string-trim " " string))
        (let ((form (read-from-string string)))
          (if (and (listp form) (every #'consp form))
              form
              (progn
                (format t "~&[DEBUG] Not an alist: ~S~%" form)
                nil))))
    (error (e)
      (format t "~&[Parse Error] ~A~%Input: ~A~%" e string)
      nil)))

(defun alist-get (key alist)
  "Gets value from ALIST by KEY using case-insensitive string comparison."
  (cdr (assoc key alist :test #'string-equal)))


;;; ============================================================================
;;; Core Infrastructure — File Operations & Metadata
;;; ============================================================================

(defun apply-file-refactor-and-load (function-symbol file-path new-code-string)
  "Locates FUNCTION-SYMBOL's defun block in FILE-PATH, splices in NEW-CODE-STRING,
   writes the result back to disk with :supersede, then compiles and hot-loads it."
  (handler-case
      (let* ((file-content (uiop:read-file-string file-path))
             (symbol-name  (string-downcase (symbol-name function-symbol)))
             (pattern-1    (format nil "(defun ~A " symbol-name))
             (pattern-2    (format nil "(defun ~A~%" symbol-name))
             (start-pos    (or (search pattern-1 (string-downcase file-content))
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
            (with-open-file (out file-path :direction :output
                                           :if-exists :supersede      ; Replaces — never appends
                                           :if-does-not-exist :create)
              (write-string updated-content out))
            (multiple-value-bind (output-truename warnings-p failure-p)
                (compile-file file-path)
              (declare (ignore output-truename warnings-p))
              (if failure-p
                  (format nil "FAILURE: Compilation errors in ~A" file-path)
                  (progn
                    (load (compile-file-pathname file-path))
                    (format nil "SUCCESS: ~A refactored and reloaded from ~A"
                            function-symbol file-path)))))))
    (error (e)
      (format nil "FAILURE: ~A" e))))

(defun commit-refactoring (&optional function-symbol)
  "Writes *last-refactored-code* to disk and hot-loads it into the image.
   If FUNCTION-SYMBOL is omitted, uses *last-refactored-target* from the last session.

   Usage:
     (commit-refactoring)                         ; uses last session's target
     (commit-refactoring 'my-fn)                  ; explicit symbol
     (commit-refactoring 'create-model-for-updatewarehouse)"
  (let* ((sym  (or (when function-symbol
                     (intern (string-upcase (format nil "~A" function-symbol)) *package*))
                   (when *last-refactored-target*
                     (intern (string-upcase *last-refactored-target*) *package*))))
         (code *last-refactored-code*))
    (unless sym
      (format t "~&[commit-refactoring] No target. Run refactor-live-function first.~%")
      (return-from commit-refactoring nil))
    (unless code
      (format t "~&[commit-refactoring] No code stored. Run refactor-live-function first.~%")
      (return-from commit-refactoring nil))
    (multiple-value-bind (meta foundp) (tool-find-function-metadata sym)
      (if (and foundp (getf meta :file-path))
          (progn
            (format t "~&[commit-refactoring] Writing ~A to ~A...~%"
                    sym (getf meta :file-path))
            (let ((result (apply-file-refactor-and-load sym (getf meta :file-path) code)))
              (format t "~&[commit-refactoring] ~A~%" result)
              result))
          (format nil "ERROR: File path not found for '~A'." sym)))))

(defun tool-find-function-metadata (function-symbol)
  "Searches the function lookup dataset for a matching function or generic-function.
   Accepts symbols or strings (case-insensitive). Returns (values plist foundp)."
  (let* ((search-str (string-upcase (format nil "~A" function-symbol)))
         (match      (assoc search-str *nst-function-symbols* :test #'string-equal)))
    (if match
        (destructuring-bind (name type file-path arg1 arg2 flag) match
          (declare (ignore arg1 arg2 flag))
          (values (list :name name :type type :file-path file-path) t))
        (values nil nil))))

(defun concat-strings (&rest strings)
  (apply #'concatenate 'string strings))


;;; ============================================================================
;;; Swank Source Extraction Layer
;;; ============================================================================

(defun locate-source-via-swank (symbol)
  "Leverages SLIME's backend to programmatically find a symbol's definition source.
   Returns (values file-path character-position) or (values nil nil)."
  (let ((definitions (swank:find-definitions-for-emacs symbol)))
    (when definitions
      (let* ((match    (first definitions))
             (location (second match)))
        (when (eq (first location) :location)
          (let ((file-spec (assoc :file     (cdr location)))
                (pos-spec  (assoc :position (cdr location))))
            (values (second file-spec)    ; Absolute filename string
                    (second pos-spec))))))))  ; Character position integer

(defun read-source-from-swank-location (file-path position)
  "Reads the complete S-expression form from FILE-PATH starting at Swank POSITION."
  (handler-case
      (if (and file-path (probe-file file-path))
          (with-open-file (stream file-path :direction :input :external-format :utf-8)
            (file-position stream (1- position))
            (let* ((*read-eval* nil)
                   (parsed-form (read stream)))
              (with-output-to-string (out)
                (let ((*print-case* :downcase))
                  (format out "~S" parsed-form)))))
          (format nil "ERROR: File path ~A does not exist." file-path))
    (error (e)
      (format nil "ERROR: Failed to extract source text reflectively: ~A" e))))

(defun get-source-code-reflective (function-symbol)
  "Reflectively pulls the complete raw source code of FUNCTION-SYMBOL using Swank."
  (multiple-value-bind (file-path position) (locate-source-via-swank function-symbol)
    (if (and file-path position)
        (read-source-from-swank-location file-path position)
        (format nil "ERROR: Swank could not resolve a memory location for symbol '~A'." function-symbol))))

(defun dispatch-tool (action-alist)
  "Resolves :action to its registered tool and calls it.
   Single-arg tools receive :target only.
   Two-arg tools (define-tool with content-arg) also receive :content."
  (let* ((tool-name (cdr (assoc :action  action-alist :test #'string-equal)))
         (target    (cdr (assoc :target  action-alist :test #'string-equal)))
         (content   (cdr (assoc :content action-alist :test #'string-equal)))
         (tool-sym  (find-symbol (string-upcase (format nil "~A" tool-name)) *package*)))
    (if (and tool-sym (get tool-sym :agent-tool))
        (if (get tool-sym :tool-needs-content)
            (funcall tool-sym target content)
            (funcall tool-sym target))
        (format nil "ERROR: '~A' is not a registered agent tool." tool-name))))



;;; ============================================================================
;;; Agent Tool Registry — DEFINE-TOOL Macro Pattern
;;; ============================================================================

(defparameter *agent-tools* nil
  "Registry of all tools available to the refactoring agent.
   Populated automatically by DEFINE-TOOL at load time. Never edit manually.")
(defmacro define-tool (name (target-arg &optional (content-arg nil content-provided-p))
                       docstring &body body)
  "Defines a Lisp function, registers it as an agent tool, and attaches its
   documentation to the symbol plist. Optional CONTENT-ARG enables two-argument
   tools that receive both :target and :content from the agent's alist."
  `(progn
     (defun ,name (,target-arg ,@(when content-provided-p `(,content-arg)))
       ,docstring
       ,@body)
     (setf (get ',name :agent-tool)         t
           (get ',name :tool-doc)           ,docstring
           (get ',name :tool-arg)           ,(string-downcase (symbol-name target-arg))
           (get ',name :tool-needs-content) ,content-provided-p)
     (pushnew ',name *agent-tools*)
     ',name))

;;; ============================================================================
;;; Tool Definitions
;;;
;;; MANDATORY PIPELINE TOOLS — always called in this order:
;;;   1. lookup-metadata
;;;   2. read-source-file
;;;
;;; OPTIONAL INTELLIGENCE TOOLS — agent selects based on what it discovers.
;;; Each define-tool form is simultaneously a live callable function, a
;;; self-documenting registry entry, and a prompt section. Zero maintenance.
;;; ============================================================================

;;; --- Mandatory: Phase 1 & 2 ---

(define-tool lookup-metadata (function-name)
  "Confirms FUNCTION-NAME exists in the project index. Returns metadata plist with name, type, and file path."
  (let ((sym (intern (string-upcase (format nil "~A" function-name)))))
    (multiple-value-bind (meta foundp) (tool-find-function-metadata sym)
      (if foundp
          (format nil "~S" meta)
          (format nil "ERROR: '~A' not found in project index." function-name)))))

(define-tool read-source-file (function-name)
  "Retrieves the complete live source code of FUNCTION-NAME from the running Lisp image via Swank."
  (let ((clean-name (string-upcase
                     (car (last (cl-ppcre:split ":" (string function-name)))))))
    (handler-case
        (get-source-code-reflective clean-name)
      (error (e)
        (format nil "ERROR: Swank lookup failed for '~A': ~A" clean-name e)))))

;;; --- Optional: Structural Intelligence ---

(define-tool get-function-type (function-name)
  "Returns whether FUNCTION-NAME is a FUNCTION, GENERIC-FUNCTION, MACRO, or UNBOUND.
   Call early — macros and generic functions require fundamentally different refactoring strategies."
  (let* ((sym (find-symbol (string-upcase (format nil "~A" function-name)) *package*)))
    (cond
      ((null sym)
       (format nil "UNINTERNED: '~A' is not interned in the current package." function-name))
      ((macro-function sym)
       "MACRO: Reader-time expansion context is invisible in source alone — refactor with extreme care.")
      ((and (fboundp sym)
            (typep (ignore-errors (fdefinition sym)) 'standard-generic-function))
       "GENERIC-FUNCTION: Has multiple dispatch methods. Call list-generic-methods before refactoring.")
      ((fboundp sym)
       "FUNCTION: Standard compiled function. Safe to analyze and refactor directly.")
      (t
       (format nil "UNBOUND: '~A' is interned but has no function binding in the image." function-name)))))

(define-tool get-function-arglist (function-name)
  "Returns the live argument list of FUNCTION-NAME. An empty list means zero arguments — correct and expected for no-arg functions. Do not reinvestigate."
  (let* ((sym (find-symbol (string-upcase (format nil "~A" function-name)) *package*)))
    (if (and sym (fboundp sym))
        (handler-case
            (let ((arglist (sb-introspect:function-lambda-list (fdefinition sym))))
              (if (null arglist)
                  "() — ZERO-ARGUMENT FUNCTION. This is correct and expected. Do not call get-function-type again to verify this."
                  (format nil "~S" arglist)))
          (error (e)
            (format nil "ERROR reading arglist for '~A': ~A" function-name e)))
        (format nil "ERROR: '~A' is not bound as a function in the image." function-name))))



(define-tool get-function-docstring (function-name)
  "Returns the live documentation string of FUNCTION-NAME from the image.
   Use to verify the docstring remains accurate after refactoring, and to spot functions lacking one."
  (let* ((sym (find-symbol (string-upcase (format nil "~A" function-name)) *package*)))
    (cond
      ((null sym)       (format nil "ERROR: '~A' not found in package." function-name))
      ((not (fboundp sym)) (format nil "ERROR: '~A' has no function binding." function-name))
      (t (or (documentation sym 'function)
             (format nil "No docstring on '~A'. The refactored version should add one." function-name))))))

(define-tool check-exported-p (function-name)
  "Checks whether FUNCTION-NAME is exported from its package (part of the public API).
   Exported symbols must have their signatures preserved exactly — callers outside this package depend on them."
  (let* ((sym (find-symbol (string-upcase (format nil "~A" function-name)) *package*)))
    (if (null sym)
        (format nil "ERROR: '~A' not found in package." function-name)
        (let ((status (nth-value 1 (find-symbol (symbol-name sym) (symbol-package sym)))))
          (ecase status
            (:external
             (format nil "EXPORTED: '~A' is part of the public API. Preserve its signature exactly." function-name))
            (:internal
             (format nil "INTERNAL: '~A' is not exported. Signature and naming changes are safe." function-name))
            (:inherited
             (format nil "INHERITED: '~A' comes from another package. Do not redefine without tracing the inheritance chain." function-name)))))))

(define-tool list-callers (function-name)
  "Lists all functions that call FUNCTION-NAME across the loaded image.
   High caller count means interface changes carry proportional risk — call before any signature modification."
  (let* ((sym (find-symbol (string-upcase (format nil "~A" function-name)) *package*)))
    (if (null sym)
        (format nil "ERROR: '~A' not interned in current package." function-name)
        (handler-case
            (let* ((refs  (swank:xref :callers sym))
                   (names (remove-if #'null
                                     (mapcar (lambda (x) (ignore-errors (format nil "  ~A" (car x))))
                                             refs))))
              (if names
                  (format nil "~D caller(s) of ~A:~%~{~A~%~}" (length names) function-name names)
                  (format nil "No callers found for '~A'. Interface changes and renames are safe." function-name)))
          (error (e)
            (format nil "XREF unavailable: ~A. Ensure SLIME is connected and the XREF index is built." e))))))

(define-tool list-callees (function-name)
  "Lists all functions called BY FUNCTION-NAME.
   Reveals dependencies, heavy or redundant calls, and consolidation opportunities."
  (let* ((sym (find-symbol (string-upcase (format nil "~A" function-name)) *package*)))
    (if (null sym)
        (format nil "ERROR: '~A' not interned in current package." function-name)
        (handler-case
            (let* ((refs  (swank:xref :calls sym))
                   (names (remove-if #'null
                                     (mapcar (lambda (x) (ignore-errors (format nil "  ~A" (car x))))
                                             refs))))
              (if names
                  (format nil "~A calls ~D function(s):~%~{~A~%~}" function-name (length names) names)
                  (format nil "'~A' has no recorded outbound calls. XREF index may need rebuilding." function-name)))
          (error (e)
            (format nil "XREF unavailable: ~A." e))))))

(define-tool list-generic-methods (function-name)
  "If FUNCTION-NAME is a generic function, lists all its methods with their specializers.
   Required reading before refactoring any generic function — changing the primary definition affects all dispatch paths."
  (let* ((sym (find-symbol (string-upcase (format nil "~A" function-name)) *package*))
         (gf  (when (and sym (fboundp sym))
                (ignore-errors (fdefinition sym)))))
    (if (typep gf 'standard-generic-function)
        (let ((methods (sb-mop:generic-function-methods gf)))
          (if methods
              (with-output-to-string (out)
                (format out "~A has ~D method(s):~%" function-name (length methods))
                (dolist (m methods)
                  (format out "  Specializers: ~S~%"
                          (mapcar (lambda (s)
                                    (if (typep s 'sb-mop:eql-specializer)
                                        `(eql ,(sb-mop:eql-specializer-object s))
                                        (class-name s)))
                                  (sb-mop:method-specializers m)))))
              (format nil "Generic function '~A' exists but has no methods defined." function-name)))
        (format nil "'~A' is not a generic function — list-generic-methods does not apply." function-name))))

(define-tool count-source-complexity (function-name)
  "Measures structural complexity of FUNCTION-NAME: total cons form count, maximum nesting depth,
   and let-binding block count. Use to calibrate how aggressively to decompose into helpers."
  (let* ((source (get-source-code-reflective (string-upcase function-name))))
    (if (or (null source) (search "ERROR:" source))
        (format nil "ERROR: Could not read source for '~A'." function-name)
        (handler-case
            (let* ((form       (with-standard-io-syntax
                                 (let ((*read-eval* nil))
                                   (read-from-string source))))
                   (form-count 0)
                   (max-depth  0)
                   (let-count  0))
              (labels ((walk (node depth)
                         (when (consp node)
                           (setf max-depth (max max-depth depth))
                           (incf form-count)
                           (when (and (symbolp (car node))
                                      (member (symbol-name (car node))
                                              '("LET" "LET*" "FLET" "LABELS")
                                              :test #'string-equal))
                             (incf let-count))
                           (dolist (child node)
                             (walk child (1+ depth))))))
                (walk form 0))
              (format nil "Forms: ~D | Max nesting depth: ~D | Let-binding blocks: ~D~%Assessment: ~A"
                      form-count max-depth let-count
                      (cond ((> form-count 120) "HIGH — decompose into focused helper functions.")
                            ((> form-count 50)  "MEDIUM — review nested lets and cond branches for clarity.")
                            (t                  "LOW — focus on idiomatic style over structural decomposition."))))
          (error (e)
            (format nil "ERROR during complexity walk: ~A" e))))))

(define-tool list-sibling-functions (function-name)
  "Lists all other defun/defmacro/defgeneric forms in the same source file as FUNCTION-NAME.
   Reveals available utilities and project naming conventions the refactored code should follow."
  (multiple-value-bind (file-path position)
      (locate-source-via-swank (string-upcase function-name))
    (declare (ignore position))
    (if (null file-path)
        (format nil "ERROR: Could not locate source file for '~A'." function-name)
        (handler-case
            (let* ((content  (uiop:read-file-string file-path))
                   (siblings '()))
              (with-input-from-string (s content)
                (let ((*read-eval* nil))
                  (loop
                    (let ((form (handler-case (read s nil :eof) (error () :eof))))
                      (when (eq form :eof) (return))
                      (when (and (consp form)
                                 (symbolp (car form))
                                 (member (symbol-name (car form))
                                         '("DEFUN" "DEFMACRO" "DEFGENERIC")
                                         :test #'string-equal)
                                 (not (string-equal
                                       (string-downcase (format nil "~A" (cadr form)))
                                       (string-downcase function-name))))
                        (push (format nil "  (~A ~A)"
                                      (string-downcase (symbol-name (car form)))
                                      (string-downcase (format nil "~A" (cadr form))))
                              siblings))))))
              (if siblings
                  (format nil "~D sibling(s) in ~A:~%~{~A~%~}"
                          (length siblings) (file-namestring file-path) (nreverse siblings))
                  "No sibling function definitions found in this file."))
          (error (e)
            (format nil "ERROR reading siblings: ~A" e))))))

(define-tool list-file-globals (function-name)
  "Lists all defparameter and defvar forms in the same source file as FUNCTION-NAME.
   Shows what global state the function may be reading or mutating — important context for refactoring."
  (multiple-value-bind (file-path position)
      (locate-source-via-swank (string-upcase function-name))
    (declare (ignore position))
    (if (null file-path)
        (format nil "ERROR: Could not locate source file for '~A'." function-name)
        (handler-case
            (let* ((content (uiop:read-file-string file-path))
                   (globals '()))
              (with-input-from-string (s content)
                (let ((*read-eval* nil))
                  (loop
                    (let ((form (handler-case (read s nil :eof) (error () :eof))))
                      (when (eq form :eof) (return))
                      (when (and (consp form)
                                 (symbolp (car form))
                                 (member (symbol-name (car form))
                                         '("DEFPARAMETER" "DEFVAR")
                                         :test #'string-equal))
                        (push (format nil "  (~A ~A)"
                                      (string-downcase (symbol-name (car form)))
                                      (string-downcase (format nil "~A" (cadr form))))
                              globals))))))
              (if globals
                  (format nil "~D global(s) in ~A:~%~{~A~%~}"
                          (length globals) (file-namestring file-path) (nreverse globals))
                  "No defparameter/defvar globals found in this file."))
          (error (e)
            (format nil "ERROR reading globals: ~A" e))))))

(define-tool find-similar-functions (function-name)
  "Searches the project function index for names structurally similar to FUNCTION-NAME.
   Detects existing utilities the target may be reimplementing — eliminates duplication."
  (let* ((search-str (string-downcase (format nil "~A" function-name)))
         (root       (cl-ppcre:regex-replace-all
                      "(^nst-|^tool-|-p$|-fn$|-helper$)" search-str ""))
         (matches    '()))
    (dolist (entry *nst-function-symbols*)
      (let ((candidate (string-downcase (format nil "~A" (first entry)))))
        (when (and (search root candidate)
                   (not (string-equal candidate search-str)))
          (push (format nil "  ~A  [~A]" (first entry) (second entry)) matches))))
    (if matches
        (format nil "~D similar function(s) found (root: '~A'):~%~{~A~%~}"
                (length matches) root (nreverse matches))
        (format nil "No similar functions found for '~A' in the project index." function-name))))

(define-tool get-compile-warnings (function-name)
  "Compiles the source file containing FUNCTION-NAME and collects warnings and notes.
   Does not modify the file. Use to identify latent issues to address proactively during refactoring."
  (multiple-value-bind (meta foundp)
      (tool-find-function-metadata (intern (string-upcase function-name) *package*))
    (if (and foundp (getf meta :file-path))
        (handler-case
            (let ((warnings '())
                  (tmp-fasl (merge-pathnames "nst-compile-check.fasl" (uiop:temporary-directory))))
              (handler-bind ((warning (lambda (w)
                                        (push (format nil "  ~A" w) warnings)
                                        (muffle-warning w))))
                (compile-file (getf meta :file-path) :output-file tmp-fasl))
              (ignore-errors (delete-file tmp-fasl))
              (if warnings
                  (format nil "~D warning(s) in ~A:~%~{~A~%~}"
                          (length warnings) (file-namestring (getf meta :file-path)) (nreverse warnings))
                  "No compile warnings. Source file is clean."))
          (error (e)
            (format nil "ERROR during compilation check: ~A" e)))
        (format nil "ERROR: Could not find source file metadata for '~A'." function-name))))

(define-tool estimate-reference-count (function-name)
  "Counts occurrences of FUNCTION-NAME across all project source files in the index.
   High count = high blast radius. Use to decide how conservative to be with interface changes."
  (let* ((search-str (string-downcase function-name))
         (files-seen (make-hash-table :test #'equal))
         (total-refs 0)
         (file-hits  '()))
    (dolist (entry *nst-function-symbols*)
      (let ((fp (third entry)))
        (when (and fp (stringp fp) (not (gethash fp files-seen)))
          (setf (gethash fp files-seen) t))))
    (maphash (lambda (file-path _)
               (declare (ignore _))
               (handler-case
                   (let* ((content (string-downcase (uiop:read-file-string file-path)))
                          (count   0)
                          (pos     0))
                     (loop
                       (let ((found (search search-str content :start2 pos)))
                         (unless found (return))
                         (incf count)
                         (setf pos (1+ found))))
                     (when (> count 0)
                       (push (format nil "  ~A: ~D hit(s)" (file-namestring file-path) count)
                             file-hits)
                       (incf total-refs count)))
                 (error () nil)))
             files-seen)
    (format nil "~D total reference(s) to '~A' across ~D file(s):~%~{~A~%~}~%Impact: ~A"
            total-refs function-name (length file-hits) (nreverse file-hits)
            (cond ((> total-refs 20) "HIGH — interface changes will have wide blast radius. Preserve signature.")
                  ((> total-refs 5)  "MODERATE — rename or signature changes need careful coordination.")
                  (t                 "LOW — safe to restructure, rename, or change interface freely.")))))


(define-tool get-variable-value (variable-name)
  "Returns the current runtime value of a global variable by name. Call this after list-file-globals reveals a variable the function uses — never assume a variable's structure without reading its value first."
  (let* ((sym (find-symbol (string-upcase (format nil "~A" variable-name)) *package*)))
    (cond
      ((null sym)
       (format nil "ERROR: '~A' not interned in package." variable-name))
      ((not (boundp sym))
       (format nil "UNBOUND: '~A' is declared but has no value in the image." variable-name))
      (t
       (handler-case
           (format nil "~S" (symbol-value sym))
         (error (e)
           (format nil "ERROR reading value of '~A': ~A" variable-name e)))))))

(define-tool save-and-compile (function-name new-code)
  "Writes the refactored code for FUNCTION-NAME to its source file and hot-loads it into the running image. Call this as the second-to-last step, immediately before complete. Pass the full refactored (defun ...) block(s) as :content."
  (let ((sym (intern (string-upcase (format nil "~A" function-name)) *package*)))
    (multiple-value-bind (meta foundp) (tool-find-function-metadata sym)
      (cond
        ((not foundp)
         (format nil "ERROR: '~A' not found in project index." function-name))
        ((null (getf meta :file-path))
         (format nil "ERROR: No file path in metadata for '~A'." function-name))
        ((or (null new-code)
             (not (stringp new-code))
             (zerop (length (string-trim " " new-code))))
         (format nil "ERROR: :content is empty. Pass the full (defun ...) block as :content."))
        (t
         (apply-file-refactor-and-load sym (getf meta :file-path) new-code))))))
;;; ============================================================================
;;; Agent Loop Infrastructure
;;; ============================================================================



(defun generate-agent-prompt ()
  "Builds the agent system prompt directly from the live tool registry.
   Always in sync with what is implemented — no separate schema to maintain."
  (format nil
    "You are a Common Lisp Refactoring Agent for the ninestores project.
Respond exclusively with a single Common Lisp alist. No markdown. No prose. No preamble.

OUTPUT FORMAT (every turn — exact shape):
((:action . \"tool-name\") (:target . \"value\") (:content . nil) (:reason . \"rationale\"))

CRITICAL RULES — NEVER VIOLATE:
  1. The :target field ALWAYS contains the ORIGINAL function symbol name from the user.
     It NEVER changes for the entire session. NEVER copy words from a tool result into :target.
  2. Tool results are INFORMATIONAL CONTEXT ONLY. If a result says \"FUNCTION: ...\" or
     \"MACRO: ...\" that is a type description — not a new function name to target.
  3. After read-source-file returns source text, NEVER call it again. It is in context.
  4. After lookup-metadata confirms the function, NEVER call it again.

MANDATORY PIPELINE:
  Turn 1:     lookup-metadata    — always first. Confirm the function exists.
  Turn 2:     read-source-file   — always second. Retrieve the complete source.
                                   NEVER repeat this call once source is retrieved.
  Turn 3+:    OPTIONAL TOOLS     — call any subset below based on what you discover.
  Turn N-1:   save-and-compile     — write and hot-load the refactored code before signalling done.
                                     :target  -> the function symbol name
                                     :content -> the COMPLETE raw (defun ...) block(s), no quoting
  Final turn: complete             — signal the session is done.
                                     :content -> :delivered
 
DECISION GUIDE FOR OPTIONAL TOOLS:
  Always call  get-function-type        — macros and generic functions need different strategies.
  Call         list-callers             — before any signature or name change.
  Call         check-exported-p         — before any interface modification.
  Call         count-source-complexity  — to calibrate decomposition aggression.
  Call         list-sibling-functions   — to discover utilities the refactored code should leverage.
  Call         list-file-globals        — when the function appears to read or mutate global state.
  Call         get-variable-value    — immediately after list-file-globals, for ANY global the  function references. Never assume a variable's structure.
  Call         get-compile-warnings     — to identify latent issues to fix proactively.
  Call         list-generic-methods     — only when get-function-type returned GENERIC-FUNCTION.
  Call         find-similar-functions   — to detect logic already solved elsewhere in the project.
  Call         estimate-reference-count — for widely-called or hot-path functions.
  Call         get-function-docstring   — to check accuracy and completeness of existing docs.
  Call         list-callees             — to spot heavy dependencies or consolidation opportunities.
 
AVAILABLE TOOLS:
~{~A~%~}
COMPLETION — TWO-PART FORMAT, MANDATORY:
Do NOT embed the refactored code as a string inside the alist :content field.
Lisp code contains double-quotes that cannot be reliably escaped inside a string.
The reader will fail and your completion will be lost.

Output exactly two parts, in this order:

Part 1 — the signal alist, :content set to the keyword :delivered (not a string):
((:action . \"complete\") (:target . \"FUNCTION-NAME\") (:content . :delivered) (:reason . \"summary\"))

Part 2 — the raw defun block(s), on the very next line, no quotes, no wrapping:
(defun function-name (...)
  \"docstring\"
  body...)

If the refactoring produces a helper function, output both defun blocks in order,
helper first, then the main function. Both will be captured automatically."
    (mapcar (lambda (tool-sym)
              (format nil "  ~A — ~A"
                      (string-downcase (symbol-name tool-sym))
                      (get tool-sym :tool-doc)))
            (reverse *agent-tools*))))



(define-condition refactoring-complete ()
  ((result :initarg :result :reader refactoring-result)
   (target :initarg :target :reader refactoring-target))
  (:documentation "Signalled when the agent delivers a completed refactoring.
                   Caught by the agent loop to terminate cleanly with the result string."))


;;; ============================================================================
;;; IST Timing Guard — DeepSeek Off-Peak Rate Management
;;; ============================================================================

(defparameter *ist-timezone-offset* 19800
  "Seconds offset from UTC for Indian Standard Time (IST, UTC+5:30).")

(defun ist-valid-coding-time-p (&optional (ist-time (get-universal-time)))
  "Predicate: returns T only if the current IST time falls inside a DeepSeek off-peak window.
     Window 1: 09:30 – 11:30  IST
     Window 2: 15:30 – 06:30  IST (crosses midnight)"
  (let* ((local    (+ ist-time *ist-timezone-offset*))
         (minute   (nth-value 1 (decode-universal-time local 0)))
         (hour     (nth-value 2 (decode-universal-time local 0)))
         (now      (+ (* hour 60) minute))
         (w1-start (+ (* 9  60) 30))   ; 09:30
         (w1-end   (+ (* 11 60) 30))   ; 11:30
         (w2-start (+ (* 15 60) 30))   ; 15:30
         (w2-end   (+ (* 6  60) 30)))  ; 06:30 next morning
    (or (and (>= now w1-start) (< now w1-end))     ; 09:30 – 11:30
        (and (>= now w2-start) (< now (* 24 60)))  ; 15:30 – 00:00
        (< now w2-end))))                           ; 00:00 – 06:30

(defun extract-all-defun-blocks (text)
  "Scans TEXT for all top-level (defun ...) forms using paren counting.
   Robust to unescaped quotes inside docstrings — works even when the Lisp
   reader fails. Returns a single string with all blocks, or NIL if none found."
  (let ((blocks '())
        (pos     0)
        (lower   (string-downcase text)))
    (loop
      (let ((start (search "(defun " lower :start2 pos)))
        (unless start (return))
        (let ((block
                ;; Prefer the Lisp reader for clean pretty-printed output
                (or (handler-case
                        (let ((form (with-standard-io-syntax
                                      (let ((*read-eval* nil))
                                        (read-from-string text nil :eof :start start)))))
                          (unless (eq form :eof)
                            (with-output-to-string (out)
                              (let ((*print-case* :downcase))
                                (pprint form out)))))
                      (error () nil))
                    ;; Fallback: count parens manually — handles unescaped chars in strings
                    (block paren-scan
                      (let ((depth    0)
                            (in-str   nil)
                            (i        start))
                        (loop while (< i (length text)) do
                          (let ((ch (char text i)))
                            (cond
                              (in-str
                               (cond ((char= ch #\\) (incf i))  ; skip escaped char
                                     ((char= ch #\") (setf in-str nil))))
                              ((char= ch #\") (setf in-str t))
                              ((char= ch #\() (incf depth))
                              ((char= ch #\))
                               (decf depth)
                               (when (zerop depth)
                                 (return-from paren-scan
                                   (string-trim '(#\Space #\Newline #\Return)
                                                (subseq text start (1+ i)))))))
                            (incf i))))))))
          (when block (push block blocks))
          (setf pos (+ start 7)))))  ; advance past "(defun "
    (when blocks
      (format nil "~{~A~%~%~}" (nreverse blocks)))))


;;; ============================================================================
;;; Main Entry Point
;;; ============================================================================

(defun refactor-live-function (function-symbol &key (max-steps 10) hint)
  "Drives the multi-tool refactoring agent loop for FUNCTION-SYMBOL via DeepSeek.

   :max-steps  — step budget (default 10; raise for complex functions)
   :hint       — optional developer guidance injected into the first prompt.

   Examples:
     (refactor-live-function 'apply-file-refactor-and-load)
     (refactor-live-function 'llm-generate
                             :hint \"unify the deepseek and ollama branches\")
     (refactor-live-function 'create-model-for-updatewarehouse :max-steps 10
                             :hint \"extract hunchentoot:parameter collection into a helper\")

   Blocked outside IST off-peak windows (09:30-11:30, 15:30-06:30).
   Returns the refactored defun string on success, NIL on failure."
  (unless (ist-valid-coding-time-p)
    (format t "~&[refactor-live-function] Blocked: outside DeepSeek off-peak IST window.~%")
    (format t "~&  Allowed: 09:30-11:30 / 15:30-06:30 IST.~%")
    (return-from refactor-live-function nil))

  (let* ((fn-name       (string-upcase (format nil "~A" function-symbol)))
         (system-prompt (generate-agent-prompt))
         (current-prompt (format nil
                           "Refactor the function ~A. Begin with lookup-metadata.~A"
                           fn-name
                           (if hint
                               (format nil "~%~%Developer guidance: ~A" hint)
                               "")))
         ;; Session state
         (completed-tools  (make-hash-table :test #'equal))
         (context-log      '())
         (source-retrieved nil))

    (format t "~&~%=== Refactoring Session: ~A ===" fn-name)
    (when hint (format t "~&    Hint: ~A~%" hint))

    (handler-case
        (dotimes (step max-steps
                  (progn
                    (format t "~&~%[Agent] ~D-step budget exhausted without completion.~%" max-steps)
                    nil))

          (format t "~&~%[Step ~D/~D]~%" (1+ step) max-steps)
	  (let* ((raw-output   (llm-generate current-prompt
                                   :system system-prompt
                                   :model "deepseek"))
       ;; safe-read-alist strips markdown fences and validates alist shape
       (action-alist (safe-read-alist raw-output))
       (action       (when action-alist
                       (cdr (assoc :action action-alist :test #'string-equal))))
       (content      (when action-alist
                       (cdr (assoc :content action-alist :test #'string-equal)))))

  (format t "[Agent] ~S~%" action-alist)

  (cond
    ;; --- Completion path: alist parsed cleanly and signals complete ---
    ((string-equal action "complete")
     (let ((code (or
                  ;; :content is :delivered — extract defun blocks from raw output
                  (and (or (null content) (eq content :delivered))
                       (extract-all-defun-blocks raw-output))
                  ;; :content held the code string and the reader actually parsed it
                  (and (stringp content) (plusp (length content)) content))))
       (if code
           (signal 'refactoring-complete :result code :target fn-name)
           (progn
             (format t "~&[Complete] Action confirmed but no defun block found.~%")
             (format t "~&[Complete] Raw output:~%~A~%" raw-output)
             (return-from refactor-live-function nil)))))

    ;; --- Rescue path: alist parse failed but raw output contains complete signal ---
    ;; This fires when the model put the code inside :content as an unescaped string
    ;; and read-from-string choked on the inner quotes.
    ((and (null action-alist)
          (search "\"complete\"" raw-output))
     (let ((code (extract-all-defun-blocks raw-output)))
       (if code
           (progn
             (format t "~&[Rescued] Alist parse failed but defun block(s) extracted from raw output.~%")
             (signal 'refactoring-complete :result code :target fn-name))
           (progn
             (format t "~&[Rescued] Complete signal found but no defun block extractable.~%")
             (format t "~&Raw:~%~A~%" raw-output)
             (return-from refactor-live-function nil)))))

    ;; --- Hard parse failure: nothing usable ---
    ((null action-alist)
     (format t "~&[Parse Error] Could not parse LLM output and no rescue path matched.~%")
     (format t "~&Raw:~%~A~%" raw-output)
     (return-from refactor-live-function nil))

    ;; --- Normal tool call ---
    (t
     (let ((tool-result (dispatch-tool action-alist)))
       (setf (gethash action completed-tools) t)
       (when (and (string-equal action "read-source-file")
                  (not (search "ERROR:" (or tool-result ""))))
         (setf source-retrieved t))
       (push (format nil "  Step ~D [~A]: ~A"
                     (1+ step) action
                     (if (> (length (or tool-result "")) 120)
                         (concatenate 'string (subseq tool-result 0 120) "…")
                         tool-result))
             context-log)
       (format t "[~A] ~A~%"
               action
               (if (> (length (or tool-result "")) 300)
                   (concatenate 'string (subseq tool-result 0 300) "…")
                   tool-result))
       (let* ((steps-left (- max-steps step 1))
              (has-basics (and source-retrieved
                               (gethash "get-function-type" completed-tools)))
              (pressure
                (cond
                  ((<= steps-left 2)
                   (format nil
                     "~%!! CRITICAL: Only ~D step(s) left. Issue complete NOW. ~
                      Output the alist with :content . :delivered then the raw (defun ...) block.~%"
                     steps-left))
                  ((<= steps-left 5)
                   (format nil
                     "~%! WARNING: ~D steps remain. Move toward complete soon.~%" steps-left))
                  (has-basics
                   "~%You have source and type confirmed. Issue complete unless you still need a specific tool.~%")
                  (t ""))))
         (setf current-prompt
               (format nil
                 "TARGET: ~A~%~%~
                  SESSION LOG (do NOT repeat any tool already called):~%~{~A~%~}~%~
                  ALREADY CALLED: ~{~A~^, ~}~%~%~
                  LAST RESULT [~A]:~%~A~%~%~
                  ~A~%~
                  Next: one alist action. :target must always be \"~A\"."
                 fn-name
                 (nreverse (copy-list context-log))
                 (loop for k being the hash-keys of completed-tools collect k)
                 action tool-result
                 pressure
                 fn-name))))))))

      (refactoring-complete (c)
	(let ((code   (refactoring-result c))
              (target (refactoring-target c)))
	  (format t "~&~%=== Refactored: ~A ===~%~%~A~%~%=== End ===~%" target code)
	  ;; Store for commit-refactoring
	  (setf *last-refactored-code*   code
		*last-refactored-target* target)
	  (format t "~&[Stored] Call (commit-refactoring) to write and hot-load.~%")
	  code)))))






