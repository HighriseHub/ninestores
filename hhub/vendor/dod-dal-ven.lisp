;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

;;;;; Vendor Profile Update related classes

(defclass RequestVendor (RequestModel)
  ((name)
   (address)
   (phone) 
   (email)
   (firstname)
   (lastname)
   (salutation)
   (title)
   (birthdate)
   (city)
   (state)
   (country)
   (zipcode)
   (gstnumber)
   (picture-path)
   (password)
   (salt)
   (payment-gateway-mode)
   (payment-api-key)
   (payment-api-salt)
   (push-notify-subs-flag)
   (email-add-verified)
   (company)))

(defclass RequestModelVendorApproval (RequestModel)
  ((vendor-id
    :initarg :vendor-id)
   (companyadmin
    :initarg :companyadmin)))


(defclass ResponseVendor (ResponseModel)
  ((name)
   (address)
   (phone) 
   (email)
   (firstname)
   (lastname)
   (salutation)
   (title)
   (birthdate)
   (city)
   (state)
   (country)
   (zipcode)
   (gstnumber)
   (picture-path)
   (password)
   (salt)
   (payment-gateway-mode)
   (payment-api-key)
   (payment-api-salt)
   (push-notify-subs-flag)
   (email-add-verified)
   (company)))
  
(defclass VendorViewModel (ViewModel)
  ((name)
   (address)
   (phone) 
   (email)
   (firstname)
   (lastname)
   (salutation)
   (title)
   (birthdate)
   (city)
   (state)
   (country)
   (zipcode)
   (gstnumber)
   (picture-path)
   (password)
   (salt)
   (payment-gateway-mode)
   (payment-api-key)
   (payment-api-salt)
   (push-notify-subs-flag)
   (email-add-verified)))
  

(defclass VendorAdapter (AdapterService)
  ())
(defclass VendorApprovalAdapter (AdapterService)
  ())

(defclass VendorPresenter (PresenterService)
  ())

(defclass VendorProfileService (BusinessService)
  ())
(defclass VedorPasscodeService (BusinessService)
  ())
(defclass VendorPushnotificationService (BusinessService)
  ())
(defclass VendorApprovalService (BusinessService)
  ())


;;; Business Service classes for Vendor 


(defclass VendorDBService (DBAdapterService)
  ())

;;; VendorRepository class
(defclass VendorRepository (BusinessObjectRepository)
  ())

;;; Business object for Vendor

(defclass Vendor (BusinessObject)
  ((row-id)
   (name)
   (address)
   (phone) 
   (email)
   (firstname)
   (lastname)
   (salutation)
   (title)
   (birthdate)
   (city)
   (state)
   (country)
   (zipcode)
   (gstnumber)
   (picture-path)
   (password)
   (salt)
   (payment-gateway-mode)
   (payment-api-key)
   (payment-api-salt)
   (push-notify-subs-flag)
   (email-add-verified)
   (suspend-flag)
   (active-flag)
   (approved-flag)
   (approved-by)
   (approval-status)
   (upi-id)
   (company
    :accessor company
    :initarg :company)))

;;; Database object for Vendor profile

(clsql:def-view-class dod-vend-profile ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   (name
    :accessor name
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 70)
    :INITARG :name)
   (address
    :ACCESSOR address 
    :type (string 70)
    :initarg :address)
   (phone
    :accessor phone
    :type (string 30)
    :initarg :phone)

   (email
    :accessor email
    :type (string 255)
    :initarg :email)
   (firstname
    :accessor firstname
    :type (string 50)
    :initarg :firstname)
   (lastname
    :accessor lastname
    :type (string 50)
    :initarg :lastname)
   (salutation
    :accessor salutation
    :type (string 10)
    :initarg :salutation)
   (title
    :accessor title
    :type (string 255)
    :initarg :title)
   (birthdate
    :accessor birthdate
    :type clsql:date
    :initarg :birthdate)
   (city
    :accessor city
    :type (string 256)
    :initarg :city)
   (state
    :accessor city
    :type (string 256)
    :initarg :state)
   (country
    :accessor city
    :type (string 256)
    :initarg :country)
   (zipcode
    :accessor zipcode
    :type (string 10)
    :initarg :zipcode)

   (gstnumber
    :accessor gstnumber
    :type (string 20)
    :initarg :gstnumber)
   
   (picture-path
    :accessor picture-path
    :type (string 256)
    :initarg :picture-path)
   
   (password 
    :accessor password
    :type (string 128) 
    :initarg :password)
   
   (salt 
    :accessor salt
    :type (string 128)
    :initarg :salt)
   
   (payment-gateway-mode
    :accessor payment-gateway-mode
    :type (string 10)
    :initarg :payment-gateway-mode)
   
   (payment-api-key 
    :accessor payment-api-key
    :type (string 40)
    :initarg :payment-api-key)
   
   (payment-api-salt 
    :accessor payment-api-salt
    :type (string 40)
    :initarg :payment-api-salt)
   
   (active-flag
    :accessor active-flag
    :type (string 1)
    :void-value "N"
    :initarg :active-flag ) 

    (suspend-flag
    :accessor suspend-flag
    :type (string 1)
    :void-value "N"
    :initarg :suspend-flag ) 

   (upi-id
    :accessor upi-id
    :type (string 70)
    :initarg :upi-id)
   

   (approved-flag
    :accessor approved-flag
    :type (string 1)
    :void-value "N"
    :initarg :approved-flag)

   (approval-status
    :accessor approval-status
    :type (string 20)
    :void-value "PENDING"
    :initarg :approval-status)

   (approved-by
    :accessor approved-by
    :type (string 30)
    :initarg :approved-by)
   
   (push-notify-subs-flag
    :accessor push-notify-subs-flag 
    :type (string 1)
    :void-value "N"
    :initarg :push-notify-subs-flag)

   (email-add-verified
    :type (string 1)
    :void-value "N"
    :initarg :email-add-verified)

   (shipping-enabled
    :type (string 1)
    :void-value "N"
    :initarg :shipping-enabled)
   
   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)
   
   (invoice-settings
    :type (string 4000)
    :void-value "undefined"
    :initarg :invoice-settings)
   
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR get-vendor-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
              :SET NIL)))
   (:BASE-TABLE dod_vend_profile))




; DOD_VENDOR_TENANTS table is created to support multiple tenants for a given vendor. 

(defclass HHUBVendorTenants (BusinessObject) 
  ((vendor)
   (tenant)
   (default-flag)))

(clsql:def-view-class dod-vendor-tenants ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   (vendor-id
    :accessor vendor-id
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer 
    :INITARG :vendor-id)
   (tenant-id 
    :type integer 
    :initarg :tenant-id)
    (COMPANY
    :ACCESSOR get-vendor-tenants-list
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET T))
   (default-flag 
       :type (string 1) 
     :void-value "N" 
     :initarg :default-flag)

   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state))
  (:BASE-TABLE dod_vendor_tenants))

;;;;;;;;;;; Generic functions ;;;;;;;;;;;;;;;;;;;;;;;;;
(defgeneric select-vendor-by-phone (VendorDBService Phone)
  (:documentation "Load Vendor from Database given the phone number"))






