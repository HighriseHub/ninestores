;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


(defclass UpiPaymentsAdapter (AdapterService)
  ())

(defclass UpiPaymentsDBService (DBAdapterService)
  ())

(defclass UpiPaymentsPresenter (PresenterService)
  ())

(defclass UpiPaymentsService (BusinessService)
  ())

(defclass UpiPaymentsViewModel (ViewModel)
  ())
(defclass UpiPaymentsRequestModel (RequestModel)
  ((vendor
    :initarg :vendor
    :accessor vendor)
   (customer
    :initarg :customer
    :accessor customer)
   (amount
    :initarg :amount
    :accessor amount)
   (utrnum
    :initarg :utrnum
    :accessor utrnum)
   (tenant
    :initarg :tenant
    :accessor tenant)))

(defclass UpiPayment (BusinessObject)
  ((row-id)
   (transaction-id
    :initarg :transaction-id
    :accessor transaction-id)
   (vendor
    :accessor vendor 
    :initarg :vendor ) 
   (customer
    :accessor customer
    :initarg :customer)
   (amount
    :accessor amount 
    :initarg :amount)
   (status
    :initarg :status
    :accessor status)
   (utrnum
    :initarg :utrnum
    :accessor utrnum)
   (vendorconfirm
    :initarg :vendorconfirm
    :accessor vendorconfirm)
   (company
    :accessor company
    :initarg :company)))
   
(clsql:def-view-class dod-upi-payments ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   (transaction-id
    :accessor transaction-id
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer
    :INITARG :transaction-id)
   (vendor-id
    :ACCESSOR vendor-id
    :type integer
    :initarg :vendor-id)

   (vendor
    :ACCESSOR get-vendor
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-vend-profile
	                  :HOME-KEY vendor-id
                          :FOREIGN-KEY row-id
                          :SET nil))
   (cust-id
    :accessor cust-id
    :type integer
    :initarg :cust-id)
  
   (customer
    :ACCESSOR get-customer
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-cust-profile
	                  :HOME-KEY cust-id
                          :FOREIGN-KEY row-id
                          :SET nil))

   (amount
    :type float
    :initarg :amount)
   (status
    :type (string 3)
    :initarg :status)
   (utrnum
    :accessor utrnum
    :type (string 20))
   (vendorconfirm
    :type (string 1))
   
   (deleted-state
    :type (string 1)
    :void-value "N")
   

   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR get-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET NIL)))
 (:base-table dod_upi_payments))
