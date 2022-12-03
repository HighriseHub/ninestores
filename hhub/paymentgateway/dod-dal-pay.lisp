;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


(clsql:def-view-class dod-payment-transaction ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)

   (order-id
    :type (string 30)
    :initarg :order-id)
   
   (order
    :ACCESSOR get-order
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-order
	                  :HOME-KEY order-id
                          :FOREIGN-KEY row-id
                          :SET nil))

   (amt
    :type (float)
    :initarg :amt)

   (currency
    :type (string 10)
    :initarg :currency)
   
   (description
    :type (string 200)
    :initarg :description)

   (customer-id
    :type integer
    :initarg :customer-id)
   (customer
    :ACCESSOR get-customer
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-cust-profile
	                  :HOME-KEY customer-id
                          :FOREIGN-KEY row-id
                          :SET nil))

   (vendor-id
    :type integer
    :initarg :vendor-id)
   (vendor
    :ACCESSOR get-vendor
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-vend-profile
	                  :HOME-KEY vendor-id
                          :FOREIGN-KEY row-id
                          :SET nil))

   
   (payment-mode
    :type (string 20)
    :initarg :payment-mode)
   
   (transaction-id
    :type (string 30)
    :initarg :transaction-id)

   (response-code 
    :type integer
    :initarg :response-code)

   (response-message 
    :type (string 100)
    :initarg :response-message)


   (error-desc 
    :type (string 100)
    :initarg :error-desc)

   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)
   
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR get-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET nil)))
  
  
  (:BASE-TABLE dod_payment_transaction))

