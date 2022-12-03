;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
;;(clsql:file-enable-sql-reader-syntax)


(clsql:def-view-class dod-ord-pref ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)

   (cust-id
    :type integer
    :initarg :cust-id)
   (customer
    :ACCESSOR get-opf-customer
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-cust-profile
	                  :HOME-KEY cust-id
                          :FOREIGN-KEY row-id
                          :SET nil))

(prd-id
    :accessor get-opf-prd-id
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer
    :initarg :prd-id)
(productobject
 :ACCESSOR get-opf-product
 :db-kind :join
 :db-info (:join-class dod-prd-master
		       :home-key prd-id
		       :foreign-key row-id
		       :set nil))

(prd-qty
    :accessor get-product-qty
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer
    :initarg :prd-qty)

   (sun
    :type (string 1)
    :void-value "N"
    :initarg :sun)
   (mon
    :type (string 1)
    :void-value "N"
    :initarg :mon)
   (tue
    :type (string 1)
    :void-value "N"
    :initarg :tue)
   (wed
    :type (string 1)
    :void-value "N"
    :initarg :wed)
   (thu
    :type (string 1)
    :void-value "N"
    :initarg :thu)
   (fri
    :type (string 1)
    :void-value "N"
    :initarg :fri)
   (sat
    :type (string 1)
    :void-value "N"
    :initarg :sat)


    (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR customer-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET nil))



   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state))
  (:base-table dod_ord_pref))





