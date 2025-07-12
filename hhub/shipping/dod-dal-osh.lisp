;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defclass ShippingRateCheck (BusinessObject)
  ((from-pincode)
   (to-pincode)
   (shipping-length-cms)
   (shipping-width-cms)
   (shipping-height-cms)
   (shipping-weight-kg)
   (order-type)
   (payment-method)
   (product-mrp)
   (access-token)
   (secret-key)))



(defclass OrderShipment (BusinessObject)
  ((row-id)
   (cust-order-id)
   (vendor-order-id)
   (waybill_no)
   (order-date)
   (order-amt)
   (total-discount)
   (name)
   (company-name)
   (addr1)
   (addr2)
   (addr3)
   (pin)
   (city)
   (state)
   (country)
   (phone)
   (alt-phone)
   (email)
   (is-billing-same-as-shipping)
   (billing-name)
   (billing-company)
   (billing-addr1)
   (billing-addr2)
   (billing-addr3)
   (billing-pin)
   (billing-city)
   (billing-country)
   (billing-phone)
   (billing-alt-phone)
   (billing-email)
   (ship-length-cm)
   (ship-width-cm)
   (ship-height-cm)
   (weightkg)
   (shipping-charges)
   (giftwrap-charges)
   (tran-charges)
   (cod-charges)
   (advance-amount)
   (cod-amount)
   (payment-mode)
   (eway-bill-no)
   (return-address-id)
   (pickup-address-id)
   (logistics)
   (order-type)
   (s-type)
   (products)))
  


(clsql:def-view-class dod-shipping-methods ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

    (name
    :accessor name
    :TYPE (string 70)
    :INITARG :name)

    (freeshipenabled
     :type (string 1)
     :initarg :freeshipenabled)

    (flatrateshipenabled
     :type (string 1)
     :initarg :flatrateshipenabled)
    (tablerateshipenabled
     :type (string 1)
     :initarg :tablerateshipenabled)
    (extshipenabled
     :type (string 1)
     :initarg :extshipenabled)
    (storepickupenabled
     :type (string 1)
     :initarg :storepickupenabled)
    
    (defaultshippingmethod
     :type (string 3)
     :initarg :defaultshippingmethod)
    
    (shippartnerkey
     :type (string 50)
     :initarg :shippartnerkey)
    (shippartnersecret
     :type (string 50)
     :initarg :shippartnersecret)
    
    (flatratetype
     :type (string 3)
     :initarg :flatratetype)
    
    (flatrateprice
     :type float
     :initarg :flatrateprice)

    (ratetablecsv
     :type (string 500)
     :initarg :ratetablecsv)
    
    (minorderamt
    :type float
    :initarg :minorderamt)


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
 

    (created
    :accessor created
    :TYPE clsql:date)
   
   (active-flag
    :type (string 1)
    :void-value "Y"
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

   
  (:BASE-TABLE dod_shipping_methods))



(clsql:def-view-class dod-vendor-ship-zones ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

    (zonename
    :accessor zonename
    :TYPE (string 70)
    :INITARG :zonename)

    (zipcoderangecsv
     :type (string 1024)
     :initarg :zipcoderangecsv)
    
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
 

    (created
    :accessor created
    :TYPE clsql:date)
   
    (active-flag
    :type (string 1)
    :void-value "Y"
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

   
  (:BASE-TABLE dod_vendor_ship_zones))


