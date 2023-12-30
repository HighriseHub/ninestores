;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(clsql:def-view-class dod-prd-master ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

   (prd-name
    :accessor prd-name
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 70)
    :INITARG :prd-name)

   (description
    :type (string 1024)
    :initarg :description)

   (vendor-id
    :type integer 
    :initarg :vendor-id)
   (vendor
    :ACCESSOR product-vendor
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-vend-profile
	                  :HOME-KEY vendor-id
                          :FOREIGN-KEY row-id
                          :SET NIL))

   (catg-id
    :type integer
    :initarg :catg-id)
   (category
    :accessor product-category
    :db-kind :join
    :db-info (:join-class dod-prd-catg
			  :home-key catg-id 
			  :foreign-key row-id
			  :set nil))

   (qty-per-unit
    :accessor qty-per-unit
    :type (string 30)
    :initarg :qty-per-unit)

   (prd-image-path
    :accessor prd-image-path
    :type (string 256)
    :initarg :prd-image-path)
   


   (unit-price
    :type float
    :initarg :unit-price)
   
   (units-in-stock
    :type integer
    :initarg :units-in-stock)

   (hsn-code
    :type (string 8)
    :initarg :hsn-code)

   (sku
    :type (string 20)
    :initarg :sku)

   (upc
    :type (string 20)
    :initarg :upc)
   (ean
    :type (string 20)
    :initarg :ean)
   (jan
    :type (string 20)
    :initarg :jan)
   (isbn
    :type (string 20)
    :initarg :isbn)
   (serial-no
    :type (string 20)
    :initarg :serial-no)
   
   (external-url
    :type (string 255)
    :initarg :external-url)

   (shipping-length-cms
    :type integer
    :initarg :shipping-length-cms)

   (shipping-width-cms
    :type integer
    :initarg :shipping-width-cms)

   (shipping-height-cms
    :type integer
    :initarg :shipping-height-cms)

   (shipping-weight-kg
    :type float
    :initarg :shipping-weight-kg)
 
   (active-flag
    :type (string 1)
    :void-value "N"
    :initarg :active-flag)


   (deleted-state
    :type (string 1)
    :void-value "N"
       :initarg :deleted-state)

   (subscribe-flag
	  :type (string 1)
	  :void-value "N"
	  :initarg :subscribe-flag)

   (approved-flag 
    :type (string 1) 
    :void-value "N"
    :initarg :approved-flag) 
   (approval-status 
    :type (string 20) 
    :void-value "PENDING"
    :initarg :approval-status)

   (prd-type
    :type (string 4)
    :void-value "SALE"
    :initarg :prd-type)
   
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR product-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
              :SET NIL)))
   (:BASE-TABLE dod_prd_master))


;; PRODUCT PRICING


(clsql:def-view-class dod-product-pricing ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

   (product-id
    :accessor product-id
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer
    :INITARG :product-id)

   (price
    :type float
    :initarg :price)

   (discount
    :type float
    :initarg :discount)
   
   (currency
    :type (string 3)
    :void-value "INR"
    :initarg :currency)

   (start-date
    :accessor start-date
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE clsql:date
    :initarg :start-date)
   (end-date
    :accessor end-date
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE clsql:date
    :initarg :end-date)
      
   (active-flag
    :type (string 1)
    :void-value "N"
    :initarg :active-flag)


   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)

   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR product-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET T)))

   
  (:BASE-TABLE dod_product_pricing))

; Product category

(clsql:def-view-class dod-prd-catg ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

      (catg-name
    :accessor catg-name
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 70)
    :INITARG :catg-name)

   (lft 
    :accessor get-left
    :type integer 
    :initarg :lft) 
   
   (rgt 
    :accessor get-right
    :type integer 
    :initarg :rgt) 
   

   (active-flag
    :type (string 1)
    :void-value "N"
       :initarg :active-flag)


   (deleted-state
    :type (string 1)
    :void-value "N"
       :initarg :deleted-state)

    (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR product-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET T)))

   
  (:BASE-TABLE dod_prd_catg))



