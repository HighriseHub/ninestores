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
(defclass UpiPaymentsHTMLView (HTMLView)
  ())

(defclass UpiPaymentsViewModel (ViewModel)
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
   (transaction-id
    :initarg :transaction-id
    :accessor transaction-id)
   (status
    :initarg :status
    :accessor status)
   (vendorconfirm
    :initarg :vendorconfirm
    :accessor vendorconfirm)
   (created
    :initarg :created
    :accessor created)
   (phone
    :initarg :phone
    :accessor phone)
   (company
    :initarg :company
    :accessor company)))
  
(defclass UpiPaymentsResponseModel (ResponseModel)
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
   (transaction-id
    :initarg :transaction-id
    :accessor transaction-id)
   (status
    :initarg :status
    :accessor status)
   (vendorconfirm
    :initarg :vendorconfirm
    :accessor vendorconfirm)
   (created
    :accessor :created
    :initarg :created)
   (phone
    :initarg :phone
    :accessor phone)
  
   (company
    :initarg :company
    :accessor company)))


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
   (transaction-id
    :initarg :transaction-id
    :accessor transaction-id)
   (status
    :initarg :status
    :accessor status)
    (vendorconfirm
    :initarg :vendorconfirm
    :accessor vendorconfirm)
   (phone
    :initarg :phone
    :accessor phone)
   (paymentconfirm
    :initarg :paymentconfirm
    :accessor paymentconfirm)

   (company
    :initarg :company
    :accessor company)))

(defclass UpiPayment (BusinessObject)
  ((row-id)
   (transaction-id
    :initarg :transaction-id
    :accessor transaction-id)
   (amount
    :accessor amount 
    :initarg :amount)
   (status
    :initarg :status
    :accessor status)
   (utrnum
    :initarg :utrnum
    :accessor utrnum)
   (customer
    :accessor customer
    :initarg :customer)
   (vendor
   :accessor vendor 
   :initarg :vendor)
   (vendorconfirm
    :initarg :vendorconfirm
    :accessor vendorconfirm)
   (company
    :accessor company
    :initarg :company)
   (phone
    :initarg :phone
    :accessor phone)
  
   (created
    :accessor created)
   (deleted-state
    :accessor deleted-state
    :initarg :deleted-state)))




(clsql:def-view-class dod-upi-payments ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   (transaction-id
    :accessor transaction-id
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 20)
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
    :void-value "N"
    :initarg :deleted-state) 

   (phone
    :type (string 20)
    :initarg :phone
    :accessor phone)
  
   (created
    :accessor created
    :TYPE clsql:date)
   
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
