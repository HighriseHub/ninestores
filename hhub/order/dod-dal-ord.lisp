;;; dod-dal-ord.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
;;(clsql:file-enable-sql-reader-syntax)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; CLASS - DOD-VENDOR-ORDERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(clsql:def-view-class dod-vendor-orders ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)

   (cust-id
    :type integer
    :initarg :cust-id)
   (customer 
    :accessor get-customer 
    :db-kind :join
    :db-info (:join-class dod-cust-profile
			  :home-key cust-id
			  :foreign-key row-id
			  :set nil))
   
   (order-id
    :TYPE integer
    :initarg :order-id)

   ;; ORDNUM (D20). THE LIVE COLUMN PREDATES THIS CLASS: DOD_VENDOR_ORDERS.ORDNUM is varchar(50) NULL
   ;; and arrived by migrate-2026March-modify-vendor-order-table, so the class was 34 columns behind
   ;; the table and could not carry the number at all — which is why the D14 assembly had no way to
   ;; stamp it into a vendor row, and why every one of the 462 rows is NULL. The slot is added here
   ;; because the API's interim vendor-row writer needs it NOW; S9's nst-vordh gets its OWN class over
   ;; all 60 live columns (the decision recorded at §3 of the orders story), and this one stays the
   ;; legacy UI's.
   (ordnum
    :type (string 50)
    :initarg :ordnum)
   
   (order
    :accessor get-order
    :db-kind :join
    :db-info (:join-class dod-order
			  :home-key order-id
			  :foreign-key row-id
			  :set nil))
   
   (vendor-id
    :db-constraints :NOT-NULL
    :type integer
    :initarg :vendor-id)
   
   (vendorobject
    :accessor odt-vendorobject
    :db-kind :join
    :db-info (:join-class dod-vend-profile
			  :home-key vendor-id
			  :foreign-key row-id
			  :set nil))
   
   (ord-date
    :accessor order-date
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE clsql:date
    :initarg :ord-date)
   
   (req-date
    :accessor get-requested-date
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE clsql:date
    :initarg :req-date)
   
   (shipped-date
    :accessor get-shipped-date
    :TYPE clsql:date
    :INITARG :shipped-date)   
   
   
   (ship-address
    :ACCESSOR get-ship-address 
    :type (string 200)
    :initarg :ship-address)

   (shipzipcode
    :accessor get-shipzipcode
    :type (string 10)
    :initarg :shipzipcode)

   (shipcity
    :accessor get-shipcity
    :type (string 50)
    :initarg :shipcity)
   (shipstate
    :accessor get-shipstate
    :type (string 50)
    :initarg :shipstate)
   (billaddress
    :accessor get-billaddress
    :type (string 200)
    :initarg :billaddress)
   (billzipcode
    :accessor get-billzipcode
    :type (string 10)
    :initarg :billzipcode)
   (billcity
    :accessor get-billcity
    :type (string 50)
    :initarg :billcity)
   (billstate
    :accessor get-billstate
    :type (string 50)
    :initarg :billstate)
   
   (country
    :accessor get-country
    :type (string 50)
    :initarg :country)
   
   (billsameasship
    :accessor get-billsameasship
    :type (string 1)
    :initarg :billsameasship)
   
   (order-amt
    :type float
    :initarg :order-amt)

   (shipping-cost
    :type float
    :initarg :shipping-cost)

   
   (payment-mode
    :type (string 3)
    :initarg :payment-mode)
   
   (storepickupenabled
     :type (string 1)
     :initarg :storepickupenabled)
    
   (fulfilled
    :type (string 1)
    :void-value "N"
    :initarg :fulfilled)
   
   
   (status 
    :accessor odt-status
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 3)
    :initarg :status)
   
   
   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)
   
   (comments
    :accessor comments
    :type (string 250)
    :initarg :comments)
   
   
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
  (:BASE-TABLE dod_vendor_orders))

