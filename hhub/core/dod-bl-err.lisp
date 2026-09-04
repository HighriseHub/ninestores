;;; dod-bl-err.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)



(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-database-error (error)
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))
    (:documentation "Base condition for logical database results (non-fatal).")))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-unknown (error)
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))
    (:documentation "Base condition for logical database results (non-fatal).")))


;; --- No Result ---
(define-condition hhub-no-result (hhub-database-error)
  ()
  (:report (lambda (c s)
             (format s "No result found: ~A" (getExceptionStr c))))
  (:documentation "Raised when a DB query returns zero rows."))

;; --- Contradiction (multiple results when only one expected) ---
(define-condition hhub-contradiction (hhub-database-error)
  ()
  (:report (lambda (c s)
             (format s "Contradictory results: ~A" (getExceptionStr c))))
  (:documentation "Raised when multiple inconsistent results were found."))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition nst-api-timeout-error (error) 
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition nst-api-internal-error (error)
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-business-function-error (error)
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))))

;; ─────────────────────────────────────────────────────────────────────────────
;; ABAC Condition Hierarchy (Policy Enforcement Point)
;;
;; Industry benchmark: CLHS §9.1 (Condition System), the Google Common Lisp
;; Style Guide (§Conditions), and the hierarchical condition designs used by
;; usocket, ironclad, bordeaux-threads and Hunchentoot itself. A hierarchy lets
;; handlers catch the whole family (hhub-abac-error), the URI family
;; (hhub-abac-uri-error), or one precise failure. Every ABAC condition derives
;; from ERROR so the PEP fails closed: an authorization anomaly must never
;; degrade into an allow.
;; ─────────────────────────────────────────────────────────────────────────────

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-abac-error (error)
    ((errstring
      :initarg :errstring
      :initform "Nine Stores authorization error."
      :reader getExceptionStr))
    (:report (lambda (c s)
               (format s "ABAC policy failure: ~A" (getExceptionStr c))))
    (:documentation "Base condition for all ABAC Policy Enforcement Point failures.")))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-abac-transaction-error (hhub-abac-error)
    ()
    (:report (lambda (c s)
               (format s "ABAC transaction not found: ~A" (getExceptionStr c))))
    (:documentation "Raised when the PEP cannot find the named transaction in the cache.")))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-abac-uri-error (hhub-abac-error)
    ((db-uri
      :initarg :db-uri
      :initform nil
      :reader abac-db-uri)
     (request-uri
      :initarg :request-uri
      :initform nil
      :reader abac-request-uri))
    (:report (lambda (c s)
               (format s "ABAC URI verification failure: ~A" (getExceptionStr c))))
    (:documentation "Base condition for URI verification failures in the PEP.")))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-abac-uri-missing-error (hhub-abac-uri-error)
    ()
    (:report (lambda (c s)
               (format s "Transaction has no URI configured in the database (config defect): ~A"
                       (getExceptionStr c))))
    (:documentation "Raised when the transaction exists but has no URI registered in the DB.")))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-abac-uri-absent-error (hhub-abac-uri-error)
    ()
    (:report (lambda (c s)
               (format s "Request carried no URI for ABAC verification (caller defect): ~A"
                       (getExceptionStr c))))
    (:documentation "Raised when the request params carry no \"uri\" key (caller defect).")))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-abac-uri-mismatch-error (hhub-abac-uri-error)
    ()
    (:report (lambda (c s)
               (format s "URI mismatch: database '~A' vs browser '~A'. ~A"
                       (abac-db-uri c) (abac-request-uri c) (getExceptionStr c))))
    (:documentation "Raised when the DB transaction URI and the browser request URI do not match.")))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-method-not-found (error)
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-webpush-subscription-exists (error)
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition nst-shipping-error (error)
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro  with-nst-error-handler (expression condition)
    :description "Takes an expression, condition and error-string. Executes the expression and upon failure throws the condition and error string and also writes to file"
    `(handler-case 
	 ,expression
       (error (e)
  	 (let ((exceptionstr (format nil  "~&[~A] Error: ~A~%" (mysql-now) e))) 
	   (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				   :direction :output
				   :if-exists :append
				   :if-does-not-exist :create)
	     (format stream "~A. ~A" exceptionstr (sb-debug:list-backtrace)))
	   ;; return the exception.
	   (error ,condition :errstring (format nil "Caught error: ~A" e)))))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *nst-environment* :development) 
  ;; :development | :staging | :production
  (defmacro with-nst-debugger (&body body)
    "Debugger-centric NST execution boundary.
     - Development  : drop into debugger (full SLIME stack)
     - Staging      : log full stacktrace + re-signal
     - Production   : log sanitized + signal business condition"
    `(handler-bind
         ((error
            (lambda (e)
	      (case *nst-environment*
                ;; ------------------------------------------------------------
                ;; DEVELOPMENT MODE
                ;; ------------------------------------------------------------
                (:development
                 ;; Let SBCL debugger take full control
                 (invoke-debugger e))
		;; ------------------------------------------------------------
                ;; STAGING MODE
                ;; ------------------------------------------------------------
                (:staging
                 (when (boundp '*HHUBBUSINESSFUNCTIONSLOGFILE*)
                   (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE*
                                           :direction :output
                                           :if-exists :append
                                           :if-does-not-exist :create)
                     (format stream "~&[~A] STAGING ERROR: ~A~%"
                             (mysql-now) e)
                     (when (find-package :sb-debug)
                       (funcall (intern "PRINT-BACKTRACE" :sb-debug)
                                :stream stream))))
                 (signal e))
		;; ------------------------------------------------------------
                ;; PRODUCTION MODE
                ;; ------------------------------------------------------------
                (:production
                 (when (boundp '*HHUBBUSINESSFUNCTIONSLOGFILE*)
                   (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE*
                                           :direction :output
                                           :if-exists :append
                                           :if-does-not-exist :create)
                     (format stream "~&[~A] PROD ERROR: ~A~%"
                             (mysql-now) (type-of e))))
                 (error 'hhub-database-error
                        :errstring "Unexpected system error occurred."))
		;; ------------------------------------------------------------
                ;; DEFAULT FALLBACK
                ;; ------------------------------------------------------------
                (otherwise
                 (invoke-debugger e))))))

       ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-nst-error-boundary ((condition &key (log-level :error) (rethrow t)) &body body)
    :description "Enterprise-grade NST error boundary. Separates logging, signaling and rethrow strategy."
    `(handler-bind
         ((error
            (lambda (e)
	      ;; Structured log entry
              (let ((exceptionstr
                      (format nil "~&[~A] [~A] ~A: ~A~%"
                              (mysql-now)
                              ,log-level
                              (type-of e)
                              e)))
		;; Centralized logging (no deep-layer hard dependency)
                (when (boundp '*HHUBBUSINESSFUNCTIONSLOGFILE*)
                  (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE*
                                          :direction :output
                                          :if-exists :append
                                          :if-does-not-exist :create)
                    (format stream "~A" exceptionstr)))
		;; Optional rethrow strategy
                (when ,rethrow
                  (invoke-restart 'abort))
		;; Signal domain-specific condition (Belnap compatible)
                (signal ,condition :errstring exceptionstr)))))
       (restart-case
           (progn ,@body)
	 (abort ()
           :report "Abort NST operation and propagate failure."
           (error ,condition :errstring "Operation aborted at NST boundary."))
	 (continue ()
           :report "Continue execution ignoring error."
           nil)))))


(defun check-null (value &optional (error-message "Null value encountered") (error-type 'null-value-error))
  "Safely checks if VALUE is null and signals an error if it is.
   
   Parameters:
   - VALUE: The value to check for null
   - ERROR-MESSAGE: Optional custom error message (default: 'Null value encountered')
   - ERROR-TYPE: Optional error type (default: 'null-value-error)
   
   Returns:
   - The original value if not null
   - Signals an error if value is null
   
   Example usage:
   (check-null some-value \"Expected non-null value for calculation\")"

  (when (null value)
    (error (make-condition error-type
                          :message error-message
                          :value value)))
  value)

;; Define a custom error condition
(define-condition null-value-error (error)
  ((message :initarg :message :reader error-message)
   (value :initarg :value :reader error-value))
  (:report (lambda (condition stream)
             (format stream "~A. Value: ~S" 
                     (error-message condition) 
                     (error-value condition)))))

;; Helper macro for more concise null checking
(defmacro ensure-not-null (value &optional message)
  `(check-null ,value ,message))

(defun find-caller-name-from-backtrace ()
  "Uses string parsing on SBCL's LIST-BACKTRACE to find the 
   symbol name of the function that called the DB adapter."
  (handler-case 
      ;; We need to know which frame holds the caller:
      ;; Frame 0: find-caller-name-from-backtrace
      ;; Frame 1: log-critical-error 
      ;; Frame 2: The adapter function (e.g., select-mock-data)
      ;; Frame 3: The function that called the adapter (THE CALLER WE WANT)
      (let* ((frame-to-inspect 3)
             (backtrace-list (sb-debug:list-backtrace))
             (frame-string (nth frame-to-inspect backtrace-list))) ; Get the 4th element (index 3)
        
        (if frame-string
            ;; Parse the string: Find the opening '(' and read the list head.
            ;; Example string: "  3: (CL-USER::MAIN-APP-FUNCTION 1)"
            (let* ((start-pos (position #\( frame-string :test #'char=)) 
                   (call-list (read-from-string (subseq frame-string start-pos))))
              (if (listp call-list)
                  (car call-list) ; Extract the first element (the function name)
                  :unknown-fun-object))
            :stack-too-shallow))
    (error (c)
      (format nil "Stack inspection error: ~A" c))))

(defun log-critical-error (status message &optional payload)
  "Logs a critical error, automatically including the function that initiated the DB call."
  (let ((caller (find-caller-name-from-backtrace)))
    (format t "~&[CRITICAL LOG ~A] Called by: ~A | ~A~%[Payload/Error]: ~A" 
            status 
            caller 
            message 
            payload)))

