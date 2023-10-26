;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defclass WarehouseAdapter (AdapterService)
  ())

(defclass WarehouseDBService (DBAdapterService)
  ())

(defclass WarehousePresenter (PresenterService)
  ())

(defclass WarehouseService (BusinessService)
  ())
(defclass WarehouseHTMLView (HTMLView)
  ())


(defclass WarehouseRequestModel (RequestModel)
  ((row-id)
   (w-name
    :initarg :w-name
    :accessor w-name)
   (w-addr1
    :initarg :w-addr1
    :accessor w-addr1)
   (w-addr2
    :initarg :w-addr2
    :accessor w-addr2)
   (w-pin
    :initarg :w-pin
    :accessor w-pin)
   (w-city
    :initarg :w-city
    :accessor w-city)
   (w-state
    :initarg :w-state
    :accessor w-state)
   (w-country
    :accessor w-country
    :initarg :w-country)
   (w-manager
    :accessor w-manager
    :initarg :w-manager)
   (w-phone
    :accessor w-phone
    :initarg :w-phone)
   (w-alt-phone
    :accessor w-alt-phone
    :initarg :w-alt-phone)
   (w-email
    :accessor w-email
    :initarg :w-email)
   (company
    :accessor company
    :initarg :company)))

(defclass WarehouseResponseModel (ResponseModel)
  ((row-id)
   (w-name
    :initarg :w-name
    :accessor w-name)
   (w-addr1
    :initarg :w-addr1
    :accessor w-addr1)
   (w-addr2
    :initarg :w-addr2
    :accessor w-addr2)
   (w-pin
    :initarg :w-pin
    :accessor w-pin)
   (w-city
    :initarg :w-city
    :accessor w-city)
   (w-state
    :initarg :w-state
    :accessor w-state)
   (w-country
    :accessor w-country
    :initarg :w-country)
   (w-manager
    :accessor w-manager
    :initarg :w-manager)
   (w-phone
    :accessor w-phone
    :initarg :w-phone)
   (w-alt-phone
    :accessor w-alt-phone
    :initarg :w-alt-phone)
   (w-email
    :accessor w-email
    :initarg :w-email)
   (company
    :accessor company
    :initarg :company)))
  

(defclass Warehouse (BusinessObject)
  ((row-id)
   (w-name
    :initarg :w-name
    :accessor w-name)
   (w-addr1
    :initarg :w-addr1
    :accessor w-addr1)
   (w-addr2
    :initarg :w-addr2
    :accessor w-addr2)
   (w-pin
    :initarg :w-pin
    :accessor w-pin)
   (w-city
    :initarg :w-city
    :accessor w-city)
   (w-state
    :initarg :w-state
    :accessor w-state)
   (w-country
    :accessor w-country
    :initarg :w-country)
   (w-manager
    :accessor w-manager
    :initarg :w-manager)
   (w-phone
    :accessor w-phone
    :initarg :w-phone)
   (w-alt-phone
    :accessor w-alt-phone
    :initarg :w-alt-phone)
   (w-email
    :accessor w-email
    :initarg :w-email)
   (company
    :accessor company
    :initarg :company)))

   

(clsql:def-view-class dod-warehouse ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

   (w-name
    :accessor w-name
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 100)
    :INITARG :w-name)

   (w-addr1
    :type (string 100)
    :initarg :w-addr1)
   
   (w-addr2
    :type (string 100)
    :initarg :w-addr2)

   (w-pin
    :type (string 6)
    :initarg :w-pin)

   (w-city
    :type (string 30)
    :initarg :w-city)
   (w-state
    :type (string 30)
    :initarg :w-state)

   (w-country
    :type (string 30)
    :initarg :w-country)

   (w-manager
    :type (string 100)
    :initarg :w-manager)

   (w-phone
    :type (string 16)
    :initarg :w-phone)

   (w-alt-phone
    :type (string 16)
    :initarg :w-alt-phone)

   (w-email
    :type (string 100)
    :initarg :w-email)

   
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

   
  (:BASE-TABLE dod_warehouse))
