;; backend/repl-handler.lisp

(defpackage :nstores.repl
  (:use :cl)
  (:export #:evaluate-safe #:*allowed-symbols*))

(in-package :nstores.repl)

;; Whitelist of allowed symbols
(defparameter *allowed-symbols*
  '(get-setting set-setting list-settings 
    validate-setting export-settings import-settings
    reset-setting describe-setting help))

;; Forbidden patterns (same as frontend)
(defparameter *forbidden-patterns*
  '("DEFUN" "DEFMACRO" "EVAL" "COMPILE" "DEFPACKAGE" 
    "IN-PACKAGE" "RUN-PROGRAM" "OPEN" "DELETE-FILE" 
    "LOAD" "REQUIRE" "FUNCALL" "APPLY" "MAKE-THREAD"))

(defun check-forbidden (code-string)
  "Returns T if code contains forbidden patterns"
  (some (lambda (pattern)
          (search pattern (string-upcase code-string)))
        *forbidden-patterns*))

(defun evaluate-safe (code-string seller-id)
  "Safely evaluate user code in restricted environment"
  (handler-case
      (progn
        ;; Security check
        (when (check-forbidden code-string)
          (return-from evaluate-safe 
            (list :error "Security: Forbidden operation")))
        
        ;; Parse s-expression
        (let* ((expr (read-from-string code-string))
               (cmd (first expr))
               (args (rest expr)))
          
          ;; Validate command is in whitelist
          (unless (member cmd *allowed-symbols*)
            (return-from evaluate-safe
              (list :error (format nil "Unknown command: ~A" cmd))))
          
          ;; Execute in safe environment
          (let ((result (apply cmd args)))
            (list :success result))))
    
    (error (e)
      (list :error (format nil "Error: ~A" e)))))

;; Implement allowed commands
(defun get-setting (key)
  "Get setting value from database"
  (db:fetch-setting *current-seller-id* key))

(defun set-setting (key value)
  "Set setting value in database"
  (db:update-setting *current-seller-id* key value)
  t)

(defun list-settings (&optional category)
  "List all settings or by category"
  (db:fetch-all-settings *current-seller-id* :category category))

;; ... implement other commands
