;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

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

