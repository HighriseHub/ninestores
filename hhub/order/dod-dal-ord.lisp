;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
;;(clsql:file-enable-sql-reader-syntax)


(clsql:def-view-class dod-order ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   
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

   (gstnumber
    :accessor get-gstnumber
    :type (string 20)
    :initarg :gstnumber)
   (gstorgname
    :accessor get-gstorgname
    :type (string 50)
    :initarg :gstorgname)
   
   (order-fulfilled
    :type (string 1)
    :void-value "N"
    :initarg :order-fulfilled)

   (order-amt
    :type float
    :initarg :order-amt)

   (shipping-cost
    :type float
    :initarg :shipping-cost)

   (total-discount
    :type float
    :initarg :total-discount)
   
   (total-tax
    :type float
    :initarg :total-tax)

   (payment-mode
    :type (string 3)
    :initarg :payment-mode)

   (comments
    :accessor comments
    :type (string 250)
    :initarg :comments)

   (context-id
    :ACCESSOR get-context-id 
    :type (string 100)
    :initarg :context-id)

    (cust-id
    :type integer
    :initarg :cust-id)
   (customer
    :ACCESSOR get-customer
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-cust-profile
	                  :HOME-KEY cust-id
                          :FOREIGN-KEY row-id
                          :SET nil))

   (status
    :type (string 3)
    :initarg :status)

   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)

   (order-type 
    :type (string 4)
    :initarg :order-type
    :void-value "SALE")

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
  (:BASE-TABLE dod_order))


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

