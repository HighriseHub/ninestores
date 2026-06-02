;;; dod-dal-cus.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
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




