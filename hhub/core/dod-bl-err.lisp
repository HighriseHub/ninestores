;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-business-function-error (error)
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-abac-transaction-error (error)
    ((errstring
      :initarg :errstring
      :reader getExceptionStr))))

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
  (define-condition hhub-database-error (error)
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
