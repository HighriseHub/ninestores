;;; nst-dal-Customer.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defclass CustomerAdapter (AdapterService)
  ())

(defclass CustomerDBService (DBAdapterService)
  ())

(defclass CustomerPresenter (PresenterService)
  ())

(defclass CustomerService (BusinessService)
  ())
(defclass CustomerHTMLView (HTMLView)
  ())

(defclass CustomerAddressJSONView (JSONView)
  ())
(defclass CustomerViewModel (ViewModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (password
    :initarg :password
    :accessor password)
   (salt
    :initarg :salt
    :accessor salt)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
   (company
    :initarg :company
    :accessor company)))




(defclass CustomerResponseModel (ResponseModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
   (company
    :initarg :company
    :accessor company)))
   

(defclass CustomerRequestModel (RequestModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (password
    :initarg :password
    :accessor password)
   (salt
    :initarg :salt
    :accessor salt)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
   (company
    :initarg :company
    :accessor company)))


(defclass CustomerSearchRequestModel (CustomerRequestModel)
  ())

(defclass Customer (BusinessObject)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (password
    :initarg :password
    :accessor password)
   (salt
    :initarg :salt
    :accessor salt)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
    (company
    :initarg :company
    :accessor company)))


;;; ═══════════════════════════════════════════════════════════════════════
;;; nst-customer — island (Tree 1) domain entity. §3.1 adhara shape.
;;; ═══════════════════════════════════════════════════════════════════════
;;; Added incrementally (Step A) alongside the legacy Customer aggregate,
;;; which remains until nst-bl-Customer.lisp / nst-ui-Customer.lisp are
;;; migrated to the ferry. Do NOT redeclare id/tenant-id/created-at/
;;; updated-at/deleted-state — they are inherited from nst-domain-entity.
;;; :tenant-id comes from ctx, never from client input.
(defclass nst-customer (nst-domain-entity)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (fullname
    :initarg :fullname
    :accessor fullname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (approved-flag
    :initarg :approved-flag
    :accessor approved-flag)
   (approval-status
    :initarg :approval-status
    :accessor approval-status)
   (approved-by
    :initarg :approved-by
    :accessor approved-by)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (active-flag
    :initarg :active-flag
    :accessor active-flag)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
   (suspend-flag
    :initarg :suspend-flag
    :accessor suspend-flag)
   (upi-id
    :initarg :upi-id
    :accessor upi-id)
   (legal-company-name
    :initarg :legal-company-name
    :accessor legal-company-name)
   (gst-customer-type
    :initarg :gst-customer-type
    :accessor gst-customer-type)
   (company-name
    :initarg :company-name
    :accessor company-name)
   (legal-name
    :initarg :legal-name
    :accessor legal-name)
   (gstin
    :initarg :gstin
    :accessor gstin)
   (pan-number
    :initarg :pan-number
    :accessor pan-number)
   (business-type
    :initarg :business-type
    :accessor business-type)
   (organization-type
    :initarg :organization-type
    :accessor organization-type)
   (gst-registration-type
    :initarg :gst-registration-type
    :accessor gst-registration-type)
   (tan-number
    :initarg :tan-number
    :accessor tan-number)
   (msme-number
    :initarg :msme-number
    :accessor msme-number)
   (is-tax-exempt
    :initarg :is-tax-exempt
    :accessor is-tax-exempt)
   (tax-exemption-cert
    :initarg :tax-exemption-cert
    :accessor tax-exemption-cert)
   (business-established-date
    :initarg :business-established-date
    :accessor business-established-date)
   (annual-turnover
    :initarg :annual-turnover
    :accessor annual-turnover)
   (employee-count
    :initarg :employee-count
    :accessor employee-count)
   (industry
    :initarg :industry
    :accessor industry)
   (credit-limit
    :initarg :credit-limit
    :accessor credit-limit)
   (payment-terms
    :initarg :payment-terms
    :accessor payment-terms)
   (credit-days
    :initarg :credit-days
    :accessor credit-days)
   (primary-contact-name
    :initarg :primary-contact-name
    :accessor primary-contact-name)
   (primary-contact-phone
    :initarg :primary-contact-phone
    :accessor primary-contact-phone)
   (primary-contact-email
    :initarg :primary-contact-email
    :accessor primary-contact-email)
   (primary-contact-designation
    :initarg :primary-contact-designation
    :accessor primary-contact-designation)
   (accounts-contact-name
    :initarg :accounts-contact-name
    :accessor accounts-contact-name)
   (accounts-contact-phone
    :initarg :accounts-contact-phone
    :accessor accounts-contact-phone)
   (accounts-contact-email
    :initarg :accounts-contact-email
    :accessor accounts-contact-email)
   (bank-account-number
    :initarg :bank-account-number
    :accessor bank-account-number)
   (bank-ifsc-code
    :initarg :bank-ifsc-code
    :accessor bank-ifsc-code)
   (bank-name
    :initarg :bank-name
    :accessor bank-name)
   (bank-branch
    :initarg :bank-branch
    :accessor bank-branch)
   (bank-account-holder-name
    :initarg :bank-account-holder-name
    :accessor bank-account-holder-name)
   (registered-address
    :initarg :registered-address
    :accessor registered-address)
   (billing-address
    :initarg :billing-address
    :accessor billing-address)
   (shipping-address
    :initarg :shipping-address
    :accessor shipping-address)
   (registered-state
    :initarg :registered-state
    :accessor registered-state)
   (registered-city
    :initarg :registered-city
    :accessor registered-city)
   (registered-zipcode
    :initarg :registered-zipcode
    :accessor registered-zipcode)
   (kyc-status
    :initarg :kyc-status
    :accessor kyc-status)
   (kyc-verified-date
    :initarg :kyc-verified-date
    :accessor kyc-verified-date)
   (kyc-verified-by
    :initarg :kyc-verified-by
    :accessor kyc-verified-by)
   (kyc-documents
    :initarg :kyc-documents
    :accessor kyc-documents)
   (blacklisted-vendors
    :initarg :blacklisted-vendors
    :accessor blacklisted-vendors)
   (last-order-date
    :initarg :last-order-date
    :accessor last-order-date)
   (total-orders
    :initarg :total-orders
    :accessor total-orders)
   (total-spent
    :initarg :total-spent
    :accessor total-spent)
   (loyalty-points
    :initarg :loyalty-points
    :accessor loyalty-points)
   (company
    :initarg :company
    :accessor company)
  )
  (:documentation
   "Customer domain entity (nst-customer). Reference entity - lives on the island (Tree 1), subclassing nst-domain-entity ONLY. id/tenant-id/created-at/updated-at/deleted-state are inherited from nst-domain-entity and never redeclared here. Scalar business slots mirror every dod_cust_profile business column EXCEPT the DEPRECATED login credentials (username/password/salt - now in dod_customer_users), the DB-managed audit/lifecycle columns (created/updated), and the :join relationship slots (customer-users/wallets/orders/company/kyc-verifier) which are not scalar domain state."))



;;; ---------------------------------------------------------------------------
;;; Ferry boundary models (§3.2 / §3.3). Distinct from the legacy typed
;;; CustomerRequestModel/CustomerResponseModel above, which still back the
;;; unmigrated nst-bl-Customer.lisp / nst-ui-Customer.lisp and stay until those
;;; are rewired.
;;; ---------------------------------------------------------------------------

(defclass nst-customer-request-model (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object (Tree 2) for customer operations.

    Deliberately SLOTLESS: carries NO per-field typed slots. All inbound data
    (including :row-id) rides in the inherited `params` slot as a plist. The
    ferry (request->dispatch / extract-domain-initargs in nst-bl-adhara.lisp)
    reads (params rm) and MOP-filters that plist against whatever initargs
    nst-customer actually declares. :tenant-id and audit keys are stripped by
    extract-domain-initargs and never accepted from a client."))

(defclass nst-customer-response-model (nst-response-model)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (name
    :initarg :name
    :accessor name)
   (address
    :initarg :address
    :accessor address)
   (phone
    :initarg :phone
    :accessor phone)
   (email
    :initarg :email
    :accessor email)
   (firstname
    :initarg :firstname
    :accessor firstname)
   (lastname
    :initarg :lastname
    :accessor lastname)
   (fullname
    :initarg :fullname
    :accessor fullname)
   (salutation
    :initarg :salutation
    :accessor salutation)
   (title
    :initarg :title
    :accessor title)
   (birthdate
    :initarg :birthdate
    :accessor birthdate)
   (picture-path
    :initarg :picture-path
    :accessor picture-path)
   (city
    :initarg :city
    :accessor city)
   (state
    :initarg :state
    :accessor state)
   (country
    :initarg :country
    :accessor country)
   (zipcode
    :initarg :zipcode
    :accessor zipcode)
   (approved-flag
    :initarg :approved-flag
    :accessor approved-flag)
   (approval-status
    :initarg :approval-status
    :accessor approval-status)
   (approved-by
    :initarg :approved-by
    :accessor approved-by)
   (cust-type
    :initarg :cust-type
    :accessor cust-type)
   (active-flag
    :initarg :active-flag
    :accessor active-flag)
   (email-add-verified
    :initarg :email-add-verified
    :accessor email-add-verified)
   (suspend-flag
    :initarg :suspend-flag
    :accessor suspend-flag)
   (upi-id
    :initarg :upi-id
    :accessor upi-id)
   (legal-company-name
    :initarg :legal-company-name
    :accessor legal-company-name)
   (gst-customer-type
    :initarg :gst-customer-type
    :accessor gst-customer-type)
   (company-name
    :initarg :company-name
    :accessor company-name)
   (legal-name
    :initarg :legal-name
    :accessor legal-name)
   (gstin
    :initarg :gstin
    :accessor gstin)
   (pan-number
    :initarg :pan-number
    :accessor pan-number)
   (business-type
    :initarg :business-type
    :accessor business-type)
   (organization-type
    :initarg :organization-type
    :accessor organization-type)
   (gst-registration-type
    :initarg :gst-registration-type
    :accessor gst-registration-type)
   (tan-number
    :initarg :tan-number
    :accessor tan-number)
   (msme-number
    :initarg :msme-number
    :accessor msme-number)
   (is-tax-exempt
    :initarg :is-tax-exempt
    :accessor is-tax-exempt)
   (tax-exemption-cert
    :initarg :tax-exemption-cert
    :accessor tax-exemption-cert)
   (business-established-date
    :initarg :business-established-date
    :accessor business-established-date)
   (annual-turnover
    :initarg :annual-turnover
    :accessor annual-turnover)
   (employee-count
    :initarg :employee-count
    :accessor employee-count)
   (industry
    :initarg :industry
    :accessor industry)
   (credit-limit
    :initarg :credit-limit
    :accessor credit-limit)
   (payment-terms
    :initarg :payment-terms
    :accessor payment-terms)
   (credit-days
    :initarg :credit-days
    :accessor credit-days)
   (primary-contact-name
    :initarg :primary-contact-name
    :accessor primary-contact-name)
   (primary-contact-phone
    :initarg :primary-contact-phone
    :accessor primary-contact-phone)
   (primary-contact-email
    :initarg :primary-contact-email
    :accessor primary-contact-email)
   (primary-contact-designation
    :initarg :primary-contact-designation
    :accessor primary-contact-designation)
   (accounts-contact-name
    :initarg :accounts-contact-name
    :accessor accounts-contact-name)
   (accounts-contact-phone
    :initarg :accounts-contact-phone
    :accessor accounts-contact-phone)
   (accounts-contact-email
    :initarg :accounts-contact-email
    :accessor accounts-contact-email)
   (bank-account-number
    :initarg :bank-account-number
    :accessor bank-account-number)
   (bank-ifsc-code
    :initarg :bank-ifsc-code
    :accessor bank-ifsc-code)
   (bank-name
    :initarg :bank-name
    :accessor bank-name)
   (bank-branch
    :initarg :bank-branch
    :accessor bank-branch)
   (bank-account-holder-name
    :initarg :bank-account-holder-name
    :accessor bank-account-holder-name)
   (registered-address
    :initarg :registered-address
    :accessor registered-address)
   (billing-address
    :initarg :billing-address
    :accessor billing-address)
   (shipping-address
    :initarg :shipping-address
    :accessor shipping-address)
   (registered-state
    :initarg :registered-state
    :accessor registered-state)
   (registered-city
    :initarg :registered-city
    :accessor registered-city)
   (registered-zipcode
    :initarg :registered-zipcode
    :accessor registered-zipcode)
   (kyc-status
    :initarg :kyc-status
    :accessor kyc-status)
   (kyc-verified-date
    :initarg :kyc-verified-date
    :accessor kyc-verified-date)
   (kyc-verified-by
    :initarg :kyc-verified-by
    :accessor kyc-verified-by)
   (kyc-documents
    :initarg :kyc-documents
    :accessor kyc-documents)
   (blacklisted-vendors
    :initarg :blacklisted-vendors
    :accessor blacklisted-vendors)
   (last-order-date
    :initarg :last-order-date
    :accessor last-order-date)
   (total-orders
    :initarg :total-orders
    :accessor total-orders)
   (total-spent
    :initarg :total-spent
    :accessor total-spent)
   (loyalty-points
    :initarg :loyalty-points
    :accessor loyalty-points)
   (company
    :initarg :company
    :accessor company)
  )
  (:documentation
   "Outbound boundary model for the customer aggregate. Per adhara it subclasses nst-response-model (NOT nst-boundary-object directly). Field set mirrors nst-customer exactly; rendered only via render-* methods; the nst-customer domain entity never crosses the boundary."))


;;; ===========================================================================
;;; Relocated from dod-dal-cus.lisp (retired). ORM view-classes + address classes.
;;; ===========================================================================
(clsql:file-enable-sql-reader-syntax)

(defclass address (BusinessObject)
  ((house-no)
   (street)
   (locality)
   (city)
   (state)
   (pincode)
   (country)
   (longitude)
   (latitude)))
  
(defclass RequestPincode (RequestModel)
  (pincode))

(defclass ResponseAddress (ResponseModel)
  ((house-no)
   (street)
   (locality)
   (city)
   (state)
   (pincode)
   (country)
   (longitude)
   (latitude)))

(defclass AddressViewModel (ViewModel)
  ((locality)
   (state)
   (city)
   (pincode)))


(defclass AddressService (BusinessService)
  ())

(defclass Address-Adapter (AdapterService)
  ())

(defclass Address-Presenter (PresenterService)
  ())

  
(clsql:def-view-class dod-cust-profile ()
  (;; Primary Key
   (row-id 
    :db-kind :key 
    :db-constraints :not-null 
    :type integer 
    :initarg :row-id)
   
   ;; Legacy Individual Fields (kept for backward compatibility)
   (name 
    :accessor name
    :type (string 70) 
    :db-constraints :not-null
    :initarg :name)
   
   (address
    :accessor address 
    :type (string 256) 
    :initarg :address)
   
   (phone
    :accessor  phone 
    :type (string 30) 
    :db-constraints :not-null
    :initarg :phone)
   
   ;; Legacy Login Credentials (DEPRECATED - moved to DOD_CUSTOMER_USERS)
   (username
    :accessor username
    :type (string 30) 
    :db-constraints :not-null
    :initarg :username)
   
   (password 
    :type (string 128) 
    :db-constraints :not-null
    :initarg :password)
   
   (salt 
    :type (string 128) 
    :initarg :salt)
   
   (email
    :accessor email
    :type (string 255) 
    :initarg :email)
   
   ;; Legacy Individual Name Fields
   (firstname 
    :type (string 50) 
    :initarg :firstname)
   
   (lastname 
    :type (string 50) 
    :initarg :lastname)
   
   (fullname 
    :type (string 50) 
    :initarg :fullname)
   
   (salutation 
    :type (string 10) 
    :initarg :salutation)
   
   (title 
    :type (string 255) 
    :initarg :title)
   
   (birthdate 
    :type wall-time 
    :initarg :birthdate)
   
   (picture-path 
    :type (string 256) 
    :initarg :picture-path)
   
   ;; Legacy Address Fields
   (city 
    :type (string 256) 
    :initarg :city)
   
   (state 
    :type (string 256) 
    :initarg :state)
   
   (country 
    :type (string 100) 
    :initarg :country)
   
   (zipcode 
    :accessor zipcode
    :type (string 10) 
    :initarg :zipcode)
   
   ;; Audit Fields
   (created 
    :type clsql:wall-time 
    :db-constraints :not-null
    :initarg :created)
   
   (updated 
    :type clsql:wall-time 
    :db-constraints :not-null
    :initarg :updated)
   
   (deleted-state 
    :type (string 1) 
    :initarg :deleted-state)
   
   
   ;; Approval & Status
   (approved-flag 
    :type (string 1) 
    :initarg :approved-flag)
   
   (approval-status 
    :type (string 20) 
    :initarg :approval-status)
   
   (approved-by 
    :type (string 30) 
    :initarg :approved-by)
   
   (cust-type 
    :type (string 50) 
    :initarg :cust-type)
   
   (active-flag 
    :type (string 1) 
    :db-constraints :not-null
    :void-value "N"
    :initarg :active-flag)
   
   (email-add-verified 
    :type (string 1) 
    :initarg :email-add-verified)
   
   (suspend-flag 
    :type (string 1) 
    :initarg :suspend-flag)
   
   (upi-id 
    :type (string 70) 
    :initarg :upi-id)
   
   ;; B2B Company Information
   (legal-company-name 
    :type (string 255) 
    :initarg :legal-company-name)
   
   (gst-customer-type 
    :type (string 20) 
    :void-value "B2C"
    :initarg :gst-customer-type)
   
   (company-name 
    :type (string 255) 
    :initarg :company-name)
   
   (legal-name 
    :type (string 255) 
    :initarg :legal-name)
   
   ;; Tax & Compliance
   (gstin 
    :type (string 15) 
    :initarg :gstin)
   
   (pan-number 
    :type (string 10) 
    :initarg :pan-number)
   
   (business-type 
    :type string
    :void-value "INDIVIDUAL"
    :initarg :business-type)
   
   (organization-type 
    :type string
    :void-value "INDIVIDUAL"
    :initarg :organization-type)
   
   (gst-registration-type 
    :type string
    :void-value "UNREGISTERED"
    :initarg :gst-registration-type)
   
   (tan-number 
    :type (string 10) 
    :initarg :tan-number)
   
   (msme-number 
    :type (string 50) 
    :initarg :msme-number)
   
   (is-tax-exempt 
    :type (string 1) 
    :void-value "N"
    :initarg :is-tax-exempt)
   
   (tax-exemption-cert 
    :type (string 100) 
    :initarg :tax-exemption-cert)
   
   ;; Business Details
   (business-established-date 
    :type clsql-sys:date 
    :initarg :business-established-date)
   
   (annual-turnover 
    :type float 
    :initarg :annual-turnover)
   
   (employee-count 
    :type integer 
    :initarg :employee-count)
   
   (industry 
    :type (string 100) 
    :initarg :industry)
   
   ;; Financial Terms
   (credit-limit 
    :type float 
    :void-value 0.00
    :initarg :credit-limit)
   
   (payment-terms 
    :type (string 50) 
    :void-value "PREPAID"
    :initarg :payment-terms)
   
   (credit-days 
    :type integer 
    :void-value 0
    :initarg :credit-days)
   
   ;; Contact Information
   (primary-contact-name 
    :type (string 255) 
    :initarg :primary-contact-name)
   
   (primary-contact-phone 
    :type (string 30) 
    :initarg :primary-contact-phone)
   
   (primary-contact-email 
    :type (string 255) 
    :initarg :primary-contact-email)
   
   (primary-contact-designation 
    :type (string 100) 
    :initarg :primary-contact-designation)
   
   (accounts-contact-name 
    :type (string 255) 
    :initarg :accounts-contact-name)
   
   (accounts-contact-phone 
    :type (string 30) 
    :initarg :accounts-contact-phone)
   
   (accounts-contact-email 
    :type (string 255) 
    :initarg :accounts-contact-email)
   
   ;; Bank Details
   (bank-account-number 
    :type (string 30) 
    :initarg :bank-account-number)
   
   (bank-ifsc-code 
    :type (string 11) 
    :initarg :bank-ifsc-code)
   
   (bank-name 
    :type (string 100) 
    :initarg :bank-name)
   
   (bank-branch 
    :type (string 100) 
    :initarg :bank-branch)
   
   (bank-account-holder-name 
    :type (string 255) 
    :initarg :bank-account-holder-name)
   
   ;; Business Addresses
   (registered-address 
    :type string 
    :initarg :registered-address)
   
   (billing-address 
    :type string 
    :initarg :billing-address)
   
   (shipping-address 
    :type string 
    :initarg :shipping-address)
   
   (registered-state 
    :type (string 256) 
    :initarg :registered-state)
   
   (registered-city 
    :type (string 256) 
    :initarg :registered-city)
   
   (registered-zipcode 
    :type (string 10) 
    :initarg :registered-zipcode)
   
   ;; KYC & Verification
   (kyc-status 
    :type string
    :void-value "PENDING"
    :initarg :kyc-status)
   
   (kyc-verified-date 
    :type wall-time 
    :initarg :kyc-verified-date)
   
   (kyc-verified-by 
    :type integer 
    :initarg :kyc-verified-by)
   
   (kyc-verifier
    :accessor cust-profile-kyc-verifier
    :db-kind :join
    :db-info (:join-class dod-users
              :home-key kyc-verified-by
              :foreign-key row-id
              :set nil))
   
   (kyc-documents 
    :type string 
    :initarg :kyc-documents)
   
   ;; Business Relationships
   (blacklisted-vendors 
    :type string 
    :initarg :blacklisted-vendors)
   
   ;; Platform Usage Metrics
   (last-order-date 
    :type wall-time 
    :initarg :last-order-date)
   
   (total-orders 
    :type integer 
    :void-value 0
    :initarg :total-orders)
   
   (total-spent 
    :type float 
    :void-value 0.00
    :initarg :total-spent)
   
   (loyalty-points 
    :type integer 
    :void-value 0
    :initarg :loyalty-points)
   
   ;; Relationships to other entities
   (customer-users
    :accessor cust-profile-users
    :db-kind :join
    :db-info (:join-class dod-customer-users
              :home-key row-id
              :foreign-key customer-id
              :set t))
   
   (wallets
    :accessor cust-profile-wallets
    :db-kind :join
    :db-info (:join-class dod-cust-wallet
              :home-key row-id
              :foreign-key cust-id
              :set t))
   
   (orders
    :accessor cust-profile-orders
    :db-kind :join
    :db-info (:join-class dod-order
              :home-key row-id
              :foreign-key cust-id
              :set t))

     ;; Multi-tenancy
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
    
  (:base-table dod_cust_profile))


(clsql:def-view-class GuestCustomer (dod-cust-profile)
  ())

(clsql:def-view-class StandardCustomer (dod-cust-profile)
  ())



;;;;; Create class for DOD_CUST_WALLET table
(clsql:def-view-class dod-cust-wallet ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :column "ROW_ID"
    :type integer
    :initarg :row-id)

   ;; --- Relationships ---
   (cust-id
    :type integer
    :column "CUST_ID"
    :db-constraints :not-null
    :initarg :cust-id)
   (customer
    :accessor get-customer
    :db-kind :join
    :db-info (:join-class dod-cust-profile
              :home-key cust-id
              :foreign-key row-id
              :set nil))
   
   (vendor-id
    :type integer
    :column "VENDOR_ID"
    :db-constraints :not-null
    :initarg :vendor-id)
   (vendor
    :accessor get-vendor
    :db-kind :join
    :db-info (:join-class dod-vend-profile
              :home-key vendor-id
              :foreign-key row-id
              :set nil))

   ;; --- GST & Identifiers ---
   (customer-gstin
    :type (string 15)
    :column "CUSTOMER_GSTIN"
    :initarg :customer-gstin)
   (vendor-gstin
    :type (string 15)
    :column "VENDOR_GSTIN"
    :db-constraints :not-null
    :initarg :vendor-gstin)
   (tenant-id
    :type integer
    :column "TENANT_ID"
    :db-constraints :not-null
    :initarg :tenant-id)

   ;; --- Financials (Legacy & Main) ---
   (balance
    :type double-float ; Maps to decimal(15,2)
    :column "balance"
    :initarg :balance)
    (lifetime-spent
    :type double-float
    :column "lifetime_spent"
    :initarg :lifetime-spent)
   (current-month-spent
    :type double-float
    :column "current_month_spent"
    :initarg :current-month-spent)

   ;; --- Advanced Ledger Tracking (Compliance) ---
   (total-advances-received
    :type double-float
    :column "TOTAL_ADVANCES_RECEIVED"
    :initarg :total-advances-received)
   (total-advances-adjusted
    :type double-float
    :column "TOTAL_ADVANCES_ADJUSTED"
    :initarg :total-advances-adjusted)
   (unadjusted-advance-value
    :type double-float
    :column "UNADJUSTED_ADVANCE_VALUE"
    :initarg :unadjusted-advance-value)
   (unadjusted-gst-amount
    :type double-float
    :column "UNADJUSTED_GST_AMOUNT"
    :initarg :unadjusted-gst-amount)
   (oldest-voucher-date
    :type clsql:date
    :column "OLDEST_VOUCHER_DATE"
    :initarg :oldest-voucher-date)

   ;; --- Status & Lifecycle ---
   (wallet-status
    :type (string 20) ; Enum mapping
    :column "wallet_status"
    :initarg :wallet-status)
  
   ;; --- Auto Reload & Thresholds ---
   (auto-reload-enabled
    :type integer ; tinyint(1)
    :column "auto_reload_enabled"
    :initarg :auto-reload-enabled)
   (auto-reload-threshold
    :type double-float
    :column "auto_reload_threshold"
    :initarg :auto-reload-threshold)
   (auto-reload-amount
    :type double-float
    :column "auto_reload_amount"
    :initarg :auto-reload-amount)
   (monthly-budget-limit
    :type double-float
    :column "monthly_budget_limit"
    :initarg :monthly-budget-limit)
   (low-balance-alert-enabled
    :type integer
    :column "low_balance_alert_enabled"
    :initarg :low-balance-alert-enabled)
   (low-balance-threshold
    :type double-float
    :column "low_balance_threshold"
    :initarg :low-balance-threshold)

   ;; --- Suspension & Closure Details ---
   (suspended-at
    :type clsql:wall-time
    :column "suspended_at"
    :initarg :suspended-at)
   (suspended-by
    :type integer
    :column "suspended_by"
    :initarg :suspended-by)
   (suspension-reason
    :type string
    :column "suspension_reason"
    :initarg :suspension-reason)
   (closed-at
    :type clsql:wall-time
    :column "closed_at"
    :initarg :closed-at)
   (closed-by
    :type integer
    :column "closed_by"
    :initarg :closed-by)
   (closure-reason
    :type string
    :column "closure_reason"
    :initarg :closure-reason)

   ;; --- Audit ---
   (created
    :type clsql:wall-time
    :column "CREATED"
    :db-constraints :not-null
    :initarg :created)
   (updated
    :type clsql:wall-time
    :column "UPDATED"
    :db-constraints :not-null
    :initarg :updated)
   (deleted-state
    :type (string 1)
    :column "DELETED_STATE"
    :initarg :deleted-state)

    (company
    :accessor get-company
    :db-kind :join
    :db-info (:join-class dod-company
                          :home-key tenant-id
                          :foreign-key row-id
                          :set nil)))

  (:base-table "DOD_CUST_WALLET"))


