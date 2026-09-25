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

(defun %defun-delimiter-p (char)
  "T when CHAR may sit immediately before or after the `defun' token of a valid
   header. NIL means the token is really part of a longer symbol such as
   `my-defun-helper', which must not be treated as a definition."
  (or (null char)
      (case char
        ((#\Space #\Tab #\Newline #\Return #\() t)
        (t nil))))

(defun %defun-token-p (string position)
  "T when a case-insensitive \"defun\" token, delimited on both sides, begins at
   POSITION in STRING."
  (and (<= (+ position 5) (length string))
       (string-equal "defun" string :start1 0 :end1 5
                              :start2 position :end2 (+ position 5))
       (%defun-delimiter-p (and (> position 0) (char string (1- position))))
       (%defun-delimiter-p (and (< (+ position 5) (length string))
                                (char string (+ position 5))))))


;;; Drop-in replacement for EXTRACT-DEFUN-REGIONS.
;;;
;;; Defects in the shipped version:
;;;   1. (multiple-value-bind (form-start form-end) (scan-from i) ...) binds
;;;      FORM-END to the wrong value, so the end of the form is mislocated.
;;;   2. Helpers such as skip-string end with a trailing variable after a
;;;      (loop ... (return x)), which makes them return TWO values. Any caller
;;;      using (setf i (skip-string i)) silently takes the first, which is the
;;;      index of the closing quote rather than one past it — so the scanner
;;;      re-reads the same quote forever and the form never closes.
;;;   3. Detection consumed the opening "(" and the depth counter counted it
;;;      again, corrupting nesting depth.
;;;
;;; This version returns single values from every helper, never mixes detection
;;; with depth counting, and tracks depth only for the form it is following.

(defun extract-defun-regions (content function-name)
  "Scans CONTENT for complete top-level (defun FUNCTION-NAME ...) forms and
   returns a list of (start . end) cons cells in file order.

   String-, comment- and character-literal-aware, so it cannot be fooled by a
   defun mentioned inside a docstring or a comment, and it finds EVERY
   definition of FUNCTION-NAME rather than only the first."
  (let ((i      0)
        (len    (length content))
        (found  '())
        (start  nil)   ; start of the top-level form currently being tracked
        (depth  0)
        (active nil))  ; T while inside a form we are tracking
    (labels ((past-string (i)
               ;; I is the index of the opening quote. Returns the index just
               ;; past the closing quote. NOTE: single value, no loop-return.
               (let ((j (1+ i)))
                 (loop while (< j len) do
                   (let ((ch (char content j)))
                     (cond ((char= ch #\\) (incf j 2))
                           ((char= ch #\") (return))
                           (t             (incf j)))))
                 (if (< j len) (1+ j) len)))
             (past-block-comment (i)
               ;; I is just past the opening #|. Single value.
               (let ((j i))
                 (loop while (and (< (1+ j) len)
                                  (not (and (char= (char content j) #\|)
                                            (char= (char content (1+ j)) #\#))))
                       do (incf j))
                 (min len (+ j 2))))
             (past-line-comment (i)
               ;; Single value.
               (let ((j i))
                 (loop while (and (< j len) (not (char= (char content j) #\Newline)))
                       do (incf j))
                 j))
             (defun-name-at (start)
               "Down-cased name when a valid (defun name ...) header starts at
                START, otherwise NIL. Reads only the name token."
               (when (and (< (+ start 5) len)
                          (char= (char content start) #\()
                          (%defun-token-p content (1+ start)))
                 (let ((*read-eval* nil))
                   (handler-case
                       (multiple-value-bind (name pos)
                           (read-from-string content t nil :start (+ start 6))
                         (declare (ignore pos))
                         (and (symbolp name)
                              (string-downcase (format nil "~A" name))))
                     (error () nil))))))
      (loop while (< i len) do
        (let* ((ch   (char content i))
               (next (and (< (1+ i) len) (char content (1+ i)))))
          (cond
            ;; --- non-code text: never affects depth, never starts a form ---
            ((char= ch #\")                      (setf i (past-string i)))
            ((char= ch #\;)                      (setf i (past-line-comment (1+ i))))
            ((and (char= ch #\#) (eql next #\|)) (setf i (past-block-comment (+ i 2))))
            ((and (char= ch #\#) (eql next #\\)) (incf i 2))
            ((and (char= ch #\#) (eql next #\;)) (incf i 2))

            ;; --- code ---
            ((char= ch #\()
             (cond
               ;; Already tracking a form: only count nesting.
               (active (incf depth) (incf i))
               ;; At top level: does this parenthesis open the form we want?
               (t
                (let ((name (defun-name-at i)))
                  (if (and name (string-equal name function-name))
                      (progn (setf start i depth 1 active t) (incf i))
                      (incf i))))))
            ((char= ch #\))
             (incf i)
             (when active
               (decf depth)
               (when (zerop depth)
                 (push (cons start i) found)
                 (setf active nil))))
            (t (incf i)))))
      (nreverse found))))

(defun replace-defun-blocks (content regions new-code)
  "Returns CONTENT with each (start . end) span in REGIONS replaced by NEW-CODE.
   Every region is rewritten, so a function defined more than once in the file
   cannot be left half-updated."
  (let ((cursor 0)
        (pieces '()))
    (dolist (region regions)
      (push (subseq content cursor (car region)) pieces)
      (push new-code pieces)
      (setf cursor (cdr region)))
    (push (subseq content cursor) pieces)
    (apply #'concatenate 'string (nreverse pieces))))

(defun read-defun-arglist (content function-name)
  "Returns the lambda list of the FIRST (defun FUNCTION-NAME ...) in CONTENT, or
   NIL when it cannot be determined. Reads the on-disk source rather than
   introspecting the image, which stays correct even when an earlier
   build-image-time redefinition shadows the definition being edited."
  (let ((regions (extract-defun-regions content function-name)))
    (when regions
      (handler-case
          (let* ((text (subseq content (car (first regions)) (cdr (first regions))))
                 (*read-eval* nil)
                 (form (read-from-string text nil nil)))
            (when (and (consp form) (consp (cddr form)))
              (third form)))
        (error () nil)))))

(defun defun-source-matches-p (string function-name)
  "T when STRING contains a complete top-level (defun FUNCTION-NAME ...) form.
   Used to reject spliced code that defines some other function - the classic
   way an automated edit silently discards the only definition of the target.

   This deliberately does NOT read-from-string the whole STRING: that requires
   every package referenced inside the code to exist at check time, so code
   containing clsql: or hunchentoot: forms would be rejected as invalid even
   though it is perfectly good. EXTRACT-DEFUN-REGIONS already proves the form
   is complete and balanced, which is the check that actually matters."
  (and (stringp string)
       (extract-defun-regions string function-name)
       t))

(defun %git-object-id (file-path)
  "Returns the git object id of FILE-PATH's current on-disk content, or NIL when
   the file is not tracked or git is unavailable. Recorded in the backup so a
   restore is a single `git show` even if the backup itself is later lost."
  (handler-case
      (multiple-value-bind (out err code)
          (uiop:run-program (list "git" "hash-object" (uiop:native-namestring file-path))
                            :output :string :error-output :string :ignore-error-status t)
        (declare (ignore err))
        (when (and (zerop code) out)
          (string-trim '(#\Space #\Newline #\Return) out)))
    (error () nil)))

(defun backup-file-timestamped (file-path)
  "Copies FILE-PATH to a timestamped sibling named FILE~YYYYMMDD-HHMMSS.
   That suffix is already git-ignored via the existing `*.*~' rule, so backups
   never pollute the working tree.

   Returns (values backup-pathname :ok) when the original was copied, and
   (values nil :failed) when the copy could not be made — in which case the
   caller must NOT overwrite the original."
  (handler-case
      (let* ((stamp (multiple-value-bind (sec min hour date month year)
                        (decode-universal-time (get-universal-time))
                      (format nil "~4,'0D~2,'0D~2,'0D-~2,'0D~2,'0D~2,'0D"
                              year month date hour min sec)))
             (backup
               (merge-pathnames
                (format nil "~A~A"
                        (file-namestring file-path)
                        (format nil "~C~A" #\~ stamp))
                (or (uiop:pathname-directory-pathname file-path)
                    (uiop:parse-native-namestring "./")))))
        (with-open-file (in file-path :direction :input :element-type '(unsigned-byte 8))
          (with-open-file (out backup :direction :output
                                      :if-exists :supersede
                                      :if-does-not-exist :create
                                      :element-type '(unsigned-byte 8))
            (let ((buf (make-array 8192 :element-type '(unsigned-byte 8))))
              (loop for n = (read-sequence buf in)
                    while (plusp n)
                    do (write-sequence buf out :end n)))))
        (values backup :ok))
    (error () (values nil :failed))))

(defun write-file-string (file-path content)
  "Rewrites FILE-PATH with CONTENT, preserving the original file mode."
  (let ((mode (ignore-errors
                (sb-posix:stat-mode (sb-posix:stat (uiop:native-namestring file-path))))))
    (with-open-file (out file-path :direction :output
                                  :if-exists :supersede
                                  :if-does-not-exist :create)
      (write-string content out))
    (when mode (ignore-errors (sb-posix:chmod (uiop:native-namestring file-path) mode)))))

(defun apply-file-refactor-and-load (function-symbol file-path new-code-string
                                     &key allow-signature-change (want-backup t)
                                          dry-run)
  "Validated, reversible splice of FUNCTION-SYMBOL's definition in FILE-PATH.

   Order of operations — the on-disk source is never the first thing to break:
     1. validate  NEW-CODE-STRING actually defines FUNCTION-SYMBOL
     2. locate    every top-level (defun FUNCTION-SYMBOL ...) in the file
     3. guard     the argument list against the one on disk (see below)
     4. back up   the original to FILE~YYYYMMDD-HHMMSS
     5. write     the spliced source
     6. compile   the written file to a temporary .fasl
     7. roll back to the backup if compilation failed, then return FAILURE
     8. load      the verified .fasl and confirm the symbol is fbound

   :allow-signature-change — skip the argument-list guard, for intentional
      interface changes. Default NIL: required, optional, rest and keyword
      arguments must match the disk source exactly, because every caller in the
      project was compiled against the old signature. Redefining a function to
      return a DIFFERENT SHAPE usually does not need this flag — the lambda list
      (parameter structure) need not change to change the return value.
   :want-backup — set NIL to skip the backup copy. Not recommended.
   :dry-run — validate the splice and compile it, then stop. Nothing is written
      and nothing is loaded; returns VALIDATION PASSED / VALIDATION FAILED.
      This is what the agent's validate-refactoring tool uses, so the model can
      prove its code compiles without the file being touched.

   Returns a SUCCESS/FAILURE string; FAILURE leaves both the file and the running
   image as they were."
  (handler-case
      (let* ((symbol (intern (string-upcase (format nil "~A" function-symbol)) *package*))
             (name   (string-downcase (symbol-name symbol))))
        ;; --- 1. guards ------------------------------------------------------
        (unless (and (stringp file-path) (probe-file file-path))
          (return-from apply-file-refactor-and-load
            (format nil "FAILURE: Source file does not exist: ~A" file-path)))
        (unless (and (stringp new-code-string)
                     (plusp (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                                 new-code-string))))
          (return-from apply-file-refactor-and-load
            "FAILURE: New code is empty."))
        (unless (defun-source-matches-p new-code-string name)
          (return-from apply-file-refactor-and-load
            (format nil "FAILURE: The replacement code does not define ~A. ~
                         Expected a top-level (defun ~A ...) or (defmacro ~A ...) form."
                    symbol name name)))

        (let* ((content (uiop:read-file-string file-path))
               (regions (extract-defun-regions content name)))
          ;; --- 2. locate ----------------------------------------------------
          (when (null regions)
            (return-from apply-file-refactor-and-load
              (format nil "FAILURE: No top-level (defun ~A ...) found in ~A."
                      name file-path)))

          ;; --- 3. signature guard -------------------------------------------
          (unless allow-signature-change
            (let ((old-args (read-defun-arglist content name))
                  (new-args (read-defun-arglist new-code-string name)))
              (when (and old-args new-args (not (equal old-args new-args)))
                (return-from apply-file-refactor-and-load
                  (format nil "FAILURE: Signature change blocked for ~A.~%  on disk: ~S~%  new code: ~S~%  ~
                               Callers elsewhere in the project were compiled against the existing ~
                               argument list. Preserve it, or pass :allow-signature-change t when the ~
                               interface change is intentional."
                          name old-args new-args)))))

          ;; --- :dry-run — validate and compile only, touch nothing ----------
          (when dry-run
            (return-from apply-file-refactor-and-load
              (validate-refactoring-splice name content regions new-code-string)))

          ;; --- 4-8. write, compile, roll back, load -------------------------
          (let* ((updated  (replace-defun-blocks content regions new-code-string))
                 (tmp-fasl (merge-pathnames
                            (format nil "nst-refactor-~A-~A.fasl" name (random 1000000))
                            (uiop:temporary-directory)))
                 (warnings '())
                 (hard-warnings '())
                 (compile-failed nil)
                 (backup nil))
            ;; Make the backup BEFORE the first write, and refuse to overwrite a
            ;; file we could not back up.
            (when want-backup
              (multiple-value-bind (path status)
                  (backup-file-timestamped file-path)
                (if (eq status :ok)
                    (progn
                      (setf backup path)
                      (format t "~&[refactor] Backup: ~A~A~%"
                              (file-namestring path)
                              (let ((object-id (%git-object-id file-path)))
                                (if object-id (format nil "  (git blob ~A)" object-id) ""))))
                    (return-from apply-file-refactor-and-load
                      (format nil "FAILURE: Could not create a backup for ~A; refusing to overwrite it."
                              file-path)))))
            (write-file-string file-path updated)

            (handler-case
                (handler-bind ((warning (lambda (w)
                                          (let ((text (format nil "~A" w)))
                                            (push text warnings)
                                            ;; SBCL reports undefined functions and
                                            ;; variables as WARNINGS, so a body that
                                            ;; calls a function which does not exist
                                            ;; still "compiles". Treat those as hard
                                            ;; failures, otherwise broken code is
                                            ;; written to disk and hot-loaded.
                                            (when (or (search "undefined function" text)
                                                      (search "undefined variable" text))
                                              (push text hard-warnings)))
                                          (muffle-warning w))))
                  (multiple-value-bind (fasl w-p f-p)
                      (compile-file file-path :output-file tmp-fasl)
                    (declare (ignore w-p))
                    (setf compile-failed (or f-p (and hard-warnings t)))
                    (when fasl (setf tmp-fasl fasl))))
              (error (e)
                (setf compile-failed t)
                (push (format nil "~A" e) warnings)))

            (cond
              (compile-failed
               (let ((reasons (nreverse (if hard-warnings hard-warnings warnings))))
                 (if backup
                     (let ((restored (handler-case
                                         (progn (write-file-string file-path content) t)
                                       (error () nil))))
                       (format nil "FAILURE: Compilation failed for ~A. ~A~%~{~A~%~}"
                               file-path
                               (if restored
                                   "File rolled back to its previous content; image untouched."
                                   (format nil "!! ROLLBACK FAILED — restore from ~A" backup))
                               reasons))
                     (format nil "FAILURE: Compilation failed for ~A and no backup was taken.~%~{~A~%~}"
                             file-path reasons))))
              (t
               ;; Load FIRST, then clean up. Deleting the fasl before loading
               ;; makes LOAD fail with "Couldn't load".
               (load tmp-fasl)
               (ignore-errors (delete-file tmp-fasl))
               (unless (fboundp symbol)
                 (return-from apply-file-refactor-and-load
                   (format nil "FAILURE: After reloading ~A, ~A is still not fbound."
                           file-path symbol)))
               (format nil "SUCCESS: ~A reloaded. ~D definition(s) replaced in ~A.~A~A"
                       symbol (length regions) (file-namestring file-path)
                       (if backup (format nil " Backup: ~A." (file-namestring backup)) "")
                       (if warnings
                           (format nil " ~D compile warning(s), first: ~A"
                                   (length warnings) (first warnings))
                           "")))))))
    (error (e)
      (format nil "FAILURE: ~A" e))))

(defun %body-call-symbols (form)
  "Returns the value of (values (calls . bindings)) for the top-level FORMS of
   FORM: CALLS is the set of symbols appearing in operator position (including
   inside setf places), BINDINGS is the set of symbols introduced by a lambda
   list, let, let* or multiple-value-bind.

   Only strings, numbers and quoted literals are skipped. No form is treated as
   special syntax, because in this project the side effects that matter are
   written that way — (setf (slot-value v 'pass) x), (clsql:update-records-from-
   instance v) — and hand-rolled 'special form' lists silently miss them."
  (let ((calls '())
        (bindings '()))
    (labels ((walk (x)
               (cond ((stringp x) nil)
                     ((numberp x) nil)
                     ((null x) nil)
                     ((consp x)
                      (let ((op (car x)))
                        (cond
                          ;; lambda list: the parameters are not calls
                          ((eq op 'lambda)
                           (pushnew 'lambda calls)
                           (dolist (sub (cddr x)) (walk sub)))
                          ;; let / let*: walk only the init forms, never the
                          ;; variable names, or every binding reads as a call
                          ((member op '(let let* multiple-value-bind))
                           (pushnew op calls)
                           (dolist (b (cadr x))
                             (when (consp b)
                               (pushnew (car b) bindings)
                               (dolist (init (cdr b)) (walk init))))
                           (dolist (sub (cddr x)) (walk sub)))
                          (t
                           (when (and (symbolp op) (not (member op '(quote function))))
                             (pushnew op calls))
                           (when (eq op 'setf)
                             ;; (setf (slot-value v 'pass) x): the place operator
                             ;; is a real call, but its arguments are not.
                             (loop for (place value) on (cdr x) by #'cddr do
                               (if (consp place)
                                   (progn (when (symbolp (car place)) (pushnew (car place) calls))
                                          (when (eq (car place) 'slot-value)
                                            (dolist (s (cddr place)) (walk s))))
                                   (walk place))
                               (walk value)))
                           (unless (eq op 'setf)
                             (dolist (sub x) (walk sub)))))))
                     (t nil))))
      (walk form))
    (values calls bindings)))

(defun preservation-report (old-source new-source name)
  "Compares the calls made by the old definition of NAME with the calls made by
   its replacement, and returns a warning string when the new code has dropped
   calls the old code made — or NIL when nothing is missing.

   Only CALLS are compared; local bindings are ignored, so a rename of a let
   variable does not trigger it. This is the check that catches the most damaging
   failure mode: a refactor that reads well and compiles cleanly while quietly
   deleting side effects such as database writes and field assignments."
  (declare (ignore name))
  (let* ((old-form (handler-case
                       (let ((*read-eval* nil) (*package* *package*))
                         (read-from-string old-source nil nil))
                     (error () nil)))
         (new-form (handler-case
                       (let ((*read-eval* nil) (*package* *package*))
                         (read-from-string new-source nil nil))
                     (error () nil))))
    (when (and (consp old-form) (consp new-form))
      (let* ((old-calls (handler-case (nth-value 0 (%body-call-symbols old-form)) (error () nil)))
             (new-calls (handler-case (nth-value 0 (%body-call-symbols new-form)) (error () nil)))
             ;; Calls the old code made that the new code no longer makes, minus
             ;; anything the new code binds locally (helper lambdas etc.) and
             ;; minus built-in special forms, which are not the side effects a
             ;; reader would recognise as lost behaviour.
             (dropped   (when (and old-calls new-calls)
                          (remove-if (lambda (s)
                                       (or (member s new-calls)
                                           (member s '(%let %let* let let* lambda setf
                                                       progn if when unless cond and or
                                                       multiple-value-bind multiple-value-setq
                                                       declare the values)
                                                   :test #'string-equal)))
                                     old-calls))))
        (when dropped
          (format nil "WARNING: the replacement no longer calls ~{~A~^, ~}. ~
                       If that was not deliberate, the refactor has dropped side ~
                       effects (database writes, field assignments) and the ~
                       original behaviour is gone."
                  (mapcar (lambda (s) (string-downcase (format nil "~A" s))) dropped))))))) 

(defun validate-refactoring-splice (name content regions new-code-string)
  "Dry-run helper for APPLY-FILE-REFACTOR-AND-LOAD. Writes the spliced source to a
   temporary file, compiles it, and reports the result. The real file is never
   touched and nothing is loaded, so the developer keeps the decision of when the
   change lands."
  (let* ((spliced  (replace-defun-blocks content regions new-code-string))
         (tmp      (merge-pathnames
                    (format nil "nst-validate-~A-~A.lisp" name (random 1000000))
                    (uiop:temporary-directory)))
         (tmp-fasl (merge-pathnames
                    (format nil "nst-validate-~A-~A.fasl" name (random 1000000))
                    (uiop:temporary-directory)))
         (warnings '())
         (hard '()))
    (unwind-protect
         (progn
           (with-open-file (out tmp :direction :output :if-exists :supersede
                                    :if-does-not-exist :create)
             (write-string spliced out))
           (handler-case
               (handler-bind ((warning (lambda (w)
                                         (let ((text (format nil "~A" w)))
                                           (push text warnings)
                                           (when (or (search "undefined function" text)
                                                     (search "undefined variable" text))
                                             (push text hard)))
                                         (muffle-warning w))))
                 (compile-file tmp :output-file tmp-fasl))
             (error (e) (push (format nil "~A" e) hard)))
           (cond
             (hard
              (format nil "VALIDATION FAILED for ~A. ~D definition(s) would be replaced. ~
                           Nothing was written.~%~{~A~%~}~%Fix these before completing."
                      name (length regions) (nreverse hard)))
             (t
              (let* ((old-defs (mapcar (lambda (r) (subseq content (car r) (cdr r))) regions))
                     (old-text (format nil "~{~A~%~}" old-defs))
                     (preserve (preservation-report old-text new-code-string name)))
                (format nil "VALIDATION PASSED for ~A. ~D definition(s) would be replaced, and the ~
                             spliced source compiles~A. Nothing was written — the developer will ~
                             call commit-refactoring to apply it.~@[~%~%~A~%~]~%End the session ~
                             with the complete action now."
                        name (length regions)
                        (if warnings
                            (format nil " with ~D warning(s) to note" (length warnings))
                            " cleanly")
                        preserve)))))
      (ignore-errors (delete-file tmp))
      (ignore-errors (delete-file tmp-fasl)))))

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
  (let ((match (funcinfo function-symbol)))
    (if match
        (values (list :name (entry-field match :name)
                      :type (entry-field match :type)
                      :file-path (entry-field match :file))
                t)
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
                   ;; Read and print in the project package, so symbols come back
                   ;; bare instead of fully qualified as COMMON-LISP-USER::FOO.
                   (*package* *package*)
                   (parsed-form (read stream)))
              (with-output-to-string (out)
                (let ((*print-case* :downcase)
                      (*package* *package*))
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
      (let ((candidate (string-downcase (format nil "~A" (entry-field entry :name)))))
        (when (and (search root candidate)
                   (not (string-equal candidate search-str)))
          (push (format nil "  ~A  [~A]" (entry-field entry :name) (entry-field entry :type)) matches))))
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
      (let ((fp (entry-field entry :file)))
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

;;; NOTE: this tool writes to disk and hot-loads, so it is deliberately NOT
;;; offered to the agent (see the pipeline in GENERATE-AGENT-PROMPT). The
;;; developer applies a refactor by calling COMMIT-REFACTORING. Kept callable
;;; for manual use and for policies that explicitly opt into writing.
(define-tool save-and-compile (function-name new-code)
  "Writes the refactored code for FUNCTION-NAME to its source file and hot-loads it into the running image. Only call this if you are explicitly asked to write to disk; normally the developer calls commit-refactoring instead."
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

(define-tool validate-refactoring (function-name new-code)
  "Checks that NEW-CODE is a valid replacement for FUNCTION-NAME: verifies the
   splice point exists, that the argument list is unchanged, and that the spliced
   file COMPILES. Nothing is written to disk and nothing is hot-loaded, so this is
   always safe. Use this instead of save-and-compile, then conclude with complete."
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
         (apply-file-refactor-and-load sym (getf meta :file-path) new-code
                                       :dry-run t))))))
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
  0. PRESERVE BEHAVIOUR. The replacement must still perform every side effect the
     original performed: every setf and slot-value assignment, every database
     call such as clsql:update-records-from-instance, every encryption, hashing
     or salt-generation call. A refactor that drops these is NOT a refactor, even
     if it compiles cleanly and looks tidier. If the developer's hint asks for a
     change that would remove one of them, keep the side effect and raise the
     conflict in your :reason field instead of silently deleting it.
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
  Turn N-1:   validate-refactoring — check your work before finishing. Optional but
                                     strongly recommended.
                                     :target  -> the function symbol name
                                     :content -> the COMPLETE refactored (defun ...)
                                     block(s) as ONE escaped string, backslash-escaping
                                     every quote character inside it.
                                     It verifies the splice point, the argument list,
                                     and that the file compiles. It writes NOTHING.
                                     If the code has many quotes, skip this turn and
                                     just finish with complete below — the two-part
                                     complete turn carries raw code and needs no
                                     escaping, which is easier to get right.
                                     NEVER write raw unescaped Lisp inside :content:
                                     the reader fails with \"end of file\" and the
                                     whole session is lost.
  Final turn: complete             — signal the session is done. This is the ONLY
                                     terminal action and it ends the loop.
                                     :content -> :delivered
                                     Put the raw defun block(s) on the next line, as
                                     described in COMPLETION below.
 
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
YOU NEVER WRITE TO DISK:
  The developer reviews your work and applies it by calling commit-refactoring.
  Never call save-and-compile and never claim the file has been changed. Your job
  is to produce the code and end the session; landing it is the developer's call.

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
  "Predicate: returns T when the refactoring agent may run.

     Weekends (Saturday and Sunday, IST): always allowed — no window check.
     Weekdays: only inside a DeepSeek off-peak window.
       Window 1: 09:30 – 11:30 IST
       Window 2: 15:30 – 06:30 IST (crosses midnight)

   The argument is a UNIVERSAL-TIME integer (UTC). The weekday is therefore
   derived from the IST-shifted time, not from the UTC time — at 20:00 UTC on
   Friday it is already Saturday in IST, and the weekend rule must apply.

   Note: DECODE-UNIVERSAL-TIME numbers the weekdays 0=Monday .. 6=Sunday, so
   Saturday is 5 and Sunday is 6. The comparison must be against numbers."
  (multiple-value-bind (sec minute hour date month year day-of-week dst-p zone)
      (decode-universal-time (+ ist-time *ist-timezone-offset*) 0)
    (declare (ignore sec date month year dst-p zone))
    (if (member day-of-week '(5 6))     ; 5 = Saturday, 6 = Sunday
        ;; Weekends: no off-peak restriction at all.
        t
	;;else 
	(let* ((now      (+ (* hour 60) minute))
               (w1-start (+ (* 9  60) 30))   ; 09:30
               (w1-end   (+ (* 11 60) 30))   ; 11:30
               (w2-start (+ (* 15 60) 30))   ; 15:30
               (w2-end   (+ (* 6  60) 30)))  ; 06:30 next morning
          (or (and (>= now w1-start) (< now w1-end))     ; 09:30 – 11:30
              (and (>= now w2-start) (< now (* 24 60)))  ; 15:30 – 00:00
              (< now w2-end))))))                       ; 00:00 – 06:30

(defun extract-all-defun-blocks (text)
  "Scans TEXT for all top-level (defun ...) forms using paren counting.
   Robust to unescaped quotes inside docstrings — works even when the Lisp
   reader fails. Returns a single string with all blocks, or NIL if none found."
  (let ((blocks '())
        (pos     0)
        ;; Capture the project package BEFORE any WITH-STANDARD-IO-SYNTAX:
        ;; that macro rebinds *package* to CL-USER internally, so a binding of
        ;; (*package* *package*) inside its body would capture CL-USER and
        ;; qualify every symbol as COMMON-LISP-USER::FOO.
        (pkg     *package*)
        (lower   (string-downcase text)))
    (loop
      (let ((start (search "(defun " lower :start2 pos)))
        (unless start (return))
        (let ((block
                ;; Prefer the Lisp reader for clean pretty-printed output.
                (or (handler-case
                        (let ((form (with-standard-io-syntax
                                      (let ((*read-eval* nil)
                                            (*package* pkg))
                                        (read-from-string text nil :eof :start start)))))
                          (unless (eq form :eof)
                            (with-output-to-string (out)
                              (let ((*print-case* :downcase)
                                    (*package* pkg))
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
;;; Generic Objective-Driven Agent Loop
;;;
;;; RUN-AGENT-LOOP carries the machinery only: prompt -> parse action -> dispatch
;;; tool -> append result -> repeat with budget pressure -> terminate.
;;; Everything task-specific (system prompt, first message, pressure wording,
;;; completion extraction, terminal-action predicate) is supplied by an
;;; AGENT-POLICY object, so one loop drives any number of tasks.
;;; ============================================================================

(defun agent-log-block (list &key (width 120))
  "Renders LIST of session-log lines with a head-truncated preview of each."
  (with-output-to-string (out)
    (dolist (line (nreverse (copy-list list)))
      (format out "  ~A~%" (preview-line line :width width)))))

(defun agent-call-list (completed-tools)
  "Renders the ALREADY CALLED list from COMPLETED-TOOLS."
  (format nil "~{~A~^, ~}" (loop for k being the hash-keys of completed-tools collect k)))

(defun agent-preview (string &key (width 300))
  "Head-truncates STRING to WIDTH with an ellipsis, for progress echo."
  (preview-line (or string "") :width width))

(defun preview-line (string &key (width 300))
  "Head-truncates STRING to WIDTH characters, appending an ellipsis when cut."
  (if (> (length string) width)
      (concatenate 'string (subseq string 0 width) "…")
      string))

(defun default-next-message (target action result context-log completed-tools
                             steps-left)
  "Task-agnostic step prompt: state the target, what has been tried, and the
   last observation. Works for any tool-using objective."
  (declare (ignore target))
  (format nil
          "SESSION LOG (do NOT repeat a completed action):~%~A~%~
           ALREADY CALLED: ~A~%~
           LAST RESULT [~A]:~%~A~%~%~
           ~A~
           Next: one alist action."
          (agent-log-block context-log)
          (agent-call-list completed-tools)
          action (or result "")
          (if (and steps-left (<= steps-left 3))
              (format nil "Step budget: only ~D step(s) remain.~%" steps-left)
              "")))

(defun refactoring-pressure-message (completed-tools steps-left source-retrieved)
  "Budget pressure text tuned for the refactoring pipeline: escalates as the
   step budget drains, and nudges toward completion once source and type are in."
  (let ((has-basics (and source-retrieved
                         (gethash "get-function-type" completed-tools))))
    (cond
      ((<= steps-left 2)
       (format nil
               "~%!! CRITICAL: Only ~D step(s) left. Issue complete NOW. ~
                Output the alist with :content . :delivered then the raw (defun ...) block.~%"
               steps-left))
      ((<= steps-left 5)
       (format nil "~%! WARNING: ~D steps remain. Move toward complete soon.~%" steps-left))
      (has-basics
       "~%You have source and type confirmed. Issue complete unless you still need a specific tool.~%")
      (t ""))))

(defun refactoring-next-message (target action result context-log completed-tools
                                 steps-left source-retrieved)
  "Step prompt for the refactoring pipeline: pins :target and applies pressure."
  (format nil
          "TARGET: ~A~%~%~
           SESSION LOG (do NOT repeat any tool already called):~%~A~%~
           ALREADY CALLED: ~A~%~%~
           LAST RESULT [~A]:~%~A~%~%~
           ~A~%~
           Next: one alist action. :target must always be \"~A\"."
          target
          (agent-log-block context-log)
          (agent-call-list completed-tools)
          action (or result "")
          (refactoring-pressure-message completed-tools steps-left
                                        source-retrieved)
          target))

(defun refactoring-on-complete (raw-output action-content)
  "Completion extractor for the refactoring pipeline. Handles both delivery
   conventions: :content . :delivered (code in raw text) and a parsed string."
  (or (and (or (null action-content) (eq action-content :delivered))
           (extract-all-defun-blocks raw-output))
      (and (stringp action-content) (plusp (length action-content)) action-content)))

(defun make-refactoring-policy ()
  "Builds the AGENT-POLICY that turns RUN-AGENT-LOOP into the refactoring agent.
   Fresh per call so :tracked-state does not leak between sessions."
  (list :name              "refactoring"
        :system-prompt     (generate-agent-prompt)
        :initial-message   (lambda (target hint)
                             (format nil
                                     "Refactor the function ~A. Begin with lookup-metadata.~A"
                                     target
                                     (if hint
                                         (format nil "~%~%Developer guidance: ~A" hint)
                                         "")))
        :tracked-state     (lambda (action result state)
                             (declare (ignore action result))
                             (getf state :source-retrieved))
        :next-message      #'refactoring-next-message
        :done-p            (lambda (action) (string-equal action "complete"))
        :on-complete       #'refactoring-on-complete
        :completion-marker "\"complete\""
        ;; No :terminal-actions. The agent never lands the change itself: the
        ;; developer reviews the result and calls (commit-refactoring) to write
        ;; it to disk and hot-load it.
        :completion-signal (lambda (code target) (list :result code :target target))))

(defun run-agent-loop (objective &key policy (model "deepseek")
                                  (max-steps 10) hint (echo t))
  "Objective-driven tool-using agent loop. Carries the control flow only; all
   task-specific behaviour comes from POLICY (see MAKE-REFACTORING-POLICY).

   POLICY is a plist:
     :name              short string used in the session banner
     :system-prompt     system prompt string
     :initial-message   (lambda (target hint) ...) -> first prompt string
     :tracked-state     (lambda (action result state) ...) -> updated state plist.
                        Only needed by policies whose prompt builder wants
                        derived state (the refactoring policy tracks whether a
                        clean source retrieval has happened).
     :next-message      (lambda (target action result context-log completed-tools
                                 steps-left state) ...) -> next prompt string
     :done-p            (lambda (action) ...) -> T when ACTION terminates the run
     :on-complete       (lambda (raw-output action-content) ...) -> final result
     :completion-marker substring searched for in RAW-OUTPUT on the rescue path,
                        used when the alist failed to parse but the model clearly
                        signalled completion in prose
     :completion-signal (lambda (result target) ...) -> condition initargs

   TARGET is (format nil \"~A\" objective), upper-cased.

   Returns the policy's completed result, or NIL when the step budget is
   exhausted or a parse failure cannot be rescued."
  (let* ((target        (string-upcase (format nil "~A" objective)))
         (system-prompt (getf policy :system-prompt))
         (current-prompt (funcall (getf policy :initial-message) target hint))
         (completed-tools (make-hash-table :test #'equal))
         (context-log     '())
         (state           nil))

    (format t "~&~%=== ~A Session: ~A ===" (getf policy :name) target)
    (when hint (format t "~&    Hint: ~A~%" hint))

    (handler-case
        (dotimes (step max-steps
                       (progn
                         (format t "~&~%[Agent] ~D-step budget exhausted without completion.~%"
                                 max-steps)
                         nil))

          (format t "~&~%[Step ~D/~D]~%" (1+ step) max-steps)
          (let* ((raw-output   (llm-generate current-prompt
                                             :system system-prompt
                                             :model model))
                 (action-alist (safe-read-alist raw-output))
                 (action       (when action-alist
                                 (cdr (assoc :action action-alist :test #'string-equal))))
                 (content      (when action-alist
                                 (cdr (assoc :content action-alist :test #'string-equal)))))
            (format t "[Agent] ~S~%" action-alist)

            (cond
              ;; --- Completion: alist parsed cleanly and signals done ---
              ((and action-alist (funcall (getf policy :done-p) action))
               (let ((code (funcall (getf policy :on-complete) raw-output content)))
                 (if code
                     (apply #'signal 'refactoring-complete
                            (funcall (getf policy :completion-signal) code target))
                     (progn
                       (format t "~&[Complete] Action confirmed but no result could be extracted.~%")
                       (format t "~&[Complete] Raw output:~%~A~%" raw-output)
                       (return-from run-agent-loop nil)))))

              ;; --- Rescue path: alist parse failed but the raw output still
              ;;     carries the completion marker. Fires when the model put code
              ;;     inside :content as an unescaped string and the reader choked.
              ((and (null action-alist)
                    (search (getf policy :completion-marker) raw-output))
               (let ((code (funcall (getf policy :on-complete) raw-output nil)))
                 (if code
                     (progn
                       (format t "~&[Rescued] Alist parse failed but result extracted from raw output.~%")
                       (apply #'signal 'refactoring-complete
                              (funcall (getf policy :completion-signal) code target)))
                     (progn
                       (format t "~&[Rescued] Completion marker found but no result extractable.~%")
                       (format t "~&Raw:~%~A~%" raw-output)
                       (return-from run-agent-loop nil)))))

              ;; --- Hard parse failure: nothing usable ---
              ((null action-alist)
               (format t "~&[Parse Error] Could not parse LLM output and no rescue path matched.~%")
               (format t "~&Raw:~%~A~%" raw-output)
               (return-from run-agent-loop nil))

              ;; --- Normal tool call ---
              (t
               (let* ((tool-result (dispatch-tool action-alist))
                      (steps-left  (- max-steps step 1)))
                 (setf (gethash action completed-tools) t)
                 (when (getf policy :tracked-state)
                   (setf state (funcall (getf policy :tracked-state)
                                        action tool-result state)))
                 (push (format nil "  Step ~D [~A]: ~A"
                               (1+ step) action (agent-preview tool-result :width 120))
                       context-log)
                 (when echo
                   (format t "[~A] ~A~%" action (agent-preview tool-result :width 300)))

                 ;; No tool ends the session implicitly. Even a tool that writes
                 ;; to disk only advances the conversation — the developer
                 ;; decides when the change is committed, via commit-refactoring.
                 (setf current-prompt
                       (funcall (getf policy :next-message)
                                target action tool-result context-log
                                completed-tools steps-left state)))))))

      (refactoring-complete (c)
        (let ((code   (refactoring-result c))
              (target (refactoring-target c)))
          (format t "~&~%=== ~A: ~A ===~%~%~A~%~%=== End ===~%"
                  (getf policy :name) target code)
          (setf *last-refactored-code*   code
                *last-refactored-target* target)
          (format t "~&[Stored] NOTHING has been written. Review the code above, then call~%")
          (format t "~&         (commit-refactoring)   to write it to disk and hot-load it.~%")
          code)))))


;;; ============================================================================
;;; Main Entry Point — Refactoring Policy (thin wrapper over RUN-AGENT-LOOP)
;;; ============================================================================

(defun refactor-live-function (function-symbol &key (max-steps 10) hint
                                               (model "deepseek"))
  "Drives the multi-tool refactoring agent loop for FUNCTION-SYMBOL via DeepSeek.

   :max-steps  — step budget (default 10; raise for complex functions)
   :hint       — optional developer guidance injected into the first prompt.
   :model      — provider target string (default \"deepseek\").

   Examples:
     (refactor-live-function 'apply-file-refactor-and-load)
     (refactor-live-function 'llm-generate
                             :hint \"unify the deepseek and ollama branches\")
     (refactor-live-function 'create-model-for-updatewarehouse :max-steps 10
                             :hint \"extract hunchentoot:parameter collection into a helper\")

   Time gate: on WEEKENDS (Sat/Sun IST) this always runs. On weekdays it is
   blocked outside the DeepSeek off-peak windows (09:30-11:30 / 15:30-06:30 IST).
   Returns the refactored defun string on success, NIL on failure."
  (unless (ist-valid-coding-time-p)
    (format t "~&[refactor-live-function] Blocked: outside DeepSeek off-peak IST window.~%")
    (format t "~&  Allowed: weekends anytime, or weekdays 09:30-11:30 / 15:30-06:30 IST.~%")
    (return-from refactor-live-function nil))

  (run-agent-loop function-symbol
                  :policy     (make-refactoring-policy)
                  :model      model
                  :max-steps  max-steps
                  :hint       hint))






