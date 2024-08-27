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


