;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(clsql:def-view-class dod-currency ()
  ((country 
    :accessor country
    :type (string 100)
    :initarg :country)

   (currency
    :accessor currency
    :type (string 20)
    :initarg :currency)

   (code
    :accessor code
    :type (string 10)
    :initarg :code)

   (symbol
    :accessor symbol
    :type (string 5)
    :initarg :symbol))
      
  (:BASE-TABLE dod_currency))

