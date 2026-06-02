;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;; Query-side only. No DBAdapterService. No write operations.

(defclass CustomerInvoiceRegisterAdapter   (AdapterService)   ())
(defclass CustomerInvoiceRegisterPresenter (PresenterService)  ())
(defclass CustomerInvoiceRegisterService   (BusinessService)   ())
(defclass CustomerInvoiceRegisterHTMLView  (HTMLView)          ())
(defclass CustomerInvoiceRegisterJSONView  (JSONView)          ())

(defclass CustomerInvoiceRegisterRequestModel (RequestModel)
  ((buyer-id  :initarg :buyer-id  :accessor buyer-id)
   (tenant-id :initarg :tenant-id :accessor tenant-id)
   (gst-period :initarg :gst-period :accessor gst-period :initform nil)
   (company   :initarg :company   :accessor company)))

(defclass CustomerInvoiceEntry (BusinessObject)
  ((invoice-id          :initarg :invoice-id          :accessor invoice-id)
   (invoice-number      :initarg :invoice-number      :accessor invoice-number)
   (invoice-date        :initarg :invoice-date        :accessor invoice-date)
   (vendor-name         :initarg :vendor-name         :accessor vendor-name)
   (vendor-gstin        :initarg :vendor-gstin        :accessor vendor-gstin)
   (total-amount        :initarg :total-amount        :accessor total-amount)
   (itc-amount          :initarg :itc-amount          :accessor itc-amount)
   (itc-eligible        :initarg :itc-eligible        :accessor itc-eligible)
   (itc-claimed         :initarg :itc-claimed         :accessor itc-claimed)
   (gstr2b-match-status :initarg :gstr2b-match-status :accessor gstr2b-match-status)
   (payment-status      :initarg :payment-status      :accessor payment-status)
   (gst-period          :initarg :gst-period          :accessor gst-period)))

(defclass CustomerITCSummary (BusinessObject)
  ((total-invoices    :initarg :total-invoices    :accessor total-invoices)
   (itc-claimable     :initarg :itc-claimable     :accessor itc-claimable)
   (itc-claimed       :initarg :itc-claimed       :accessor itc-claimed)
   (itc-at-risk       :initarg :itc-at-risk       :accessor itc-at-risk)
   (total-purchases   :initarg :total-purchases   :accessor total-purchases)))

(defclass CustomerInvoiceEntryResponseModel (ResponseModel)
  ((invoice-number      :initarg :invoice-number      :accessor invoice-number)
   (invoice-date        :initarg :invoice-date        :accessor invoice-date)
   (vendor-name         :initarg :vendor-name         :accessor vendor-name)
   (vendor-gstin        :initarg :vendor-gstin        :accessor vendor-gstin)
   (total-amount        :initarg :total-amount        :accessor total-amount)
   (itc-amount          :initarg :itc-amount          :accessor itc-amount)
   (gstr2b-match-status :initarg :gstr2b-match-status :accessor gstr2b-match-status)
   (payment-status      :initarg :payment-status      :accessor payment-status)))

(defclass CustomerInvoiceEntryViewModel (ViewModel)
  ((invoice-number      :initarg :invoice-number      :accessor invoice-number)
   (invoice-date        :initarg :invoice-date        :accessor invoice-date)
   (vendor-name         :initarg :vendor-name         :accessor vendor-name)
   (vendor-gstin        :initarg :vendor-gstin        :accessor vendor-gstin)
   (total-amount        :initarg :total-amount        :accessor total-amount)
   (itc-amount          :initarg :itc-amount          :accessor itc-amount)
   (gstr2b-match-status :initarg :gstr2b-match-status :accessor gstr2b-match-status)
   (payment-status      :initarg :payment-status      :accessor payment-status)))


(clsql:def-view-class dod-v-customer-invoice-register ()
  (;; PRIMARY KEY
   (invoice-id
    :db-kind     :key
    :type        integer
    :initarg     :invoice-id
    :accessor    invoice-id)

   ;; INVOICE IDENTIFICATION
   (invoice-number
    :accessor    invoice-number
    :type        (string 50)
    :initarg     :invoice-number)
   (invoice-date
    :accessor    invoice-date
    :type        clsql:date
    :initarg     :invoice-date)
   (financial-year
    :accessor    financial-year
    :type        (string 9)
    :initarg     :financial-year)
   (gst-period
    :accessor    gst-period
    :type        (string 7)
    :initarg     :gst-period)

   ;; VENDOR DETAILS
   (vendor-id
    :accessor    vendor-id
    :type        integer
    :initarg     :vendor-id)
   (vendor-name
    :accessor    vendor-name
    :type        (string 255)
    :initarg     :vendor-name)
   (vendor-trade-name
    :accessor    vendor-trade-name
    :type        (string 255)
    :initarg     :vendor-trade-name)
   (vendor-gstin
    :accessor    vendor-gstin
    :type        (string 20)
    :initarg     :vendor-gstin)
   (vendor-gst-type
    :accessor    vendor-gst-type
    :type        (string 20)
    :initarg     :vendor-gst-type)
   (vendor-filing-frequency
    :accessor    vendor-filing-frequency
    :type        (string 10)
    :initarg     :vendor-filing-frequency)

   ;; BUYER DETAILS
   (buyer-id
    :accessor    buyer-id
    :type        integer
    :initarg     :buyer-id)
   (buyer-name
    :accessor    buyer-name
    :type        (string 255)
    :initarg     :buyer-name)
   (buyer-gstin
    :accessor    buyer-gstin
    :type        (string 15)
    :initarg     :buyer-gstin)
   (buyer-gst-type
    :accessor    buyer-gst-type
    :type        (string 20)
    :initarg     :buyer-gst-type)

   ;; INVOICE AMOUNTS
   (total-amount
    :accessor    total-amount
    :type        float
    :initarg     :total-amount)
   (balance-due
    :accessor    balance-due
    :type        float
    :initarg     :balance-due)
   (advance-adjusted
    :accessor    advance-adjusted
    :type        float
    :initarg     :advance-adjusted)
   (payment-allocated
    :accessor    payment-allocated
    :type        float
    :initarg     :payment-allocated)

   ;; ITC FIELDS
   (itc-eligible
    :accessor    itc-eligible
    :type        integer
    :initarg     :itc-eligible)
   (itc-amount
    :accessor    itc-amount
    :type        float
    :initarg     :itc-amount)
   (itc-claimed
    :accessor    itc-claimed
    :type        integer
    :initarg     :itc-claimed)
   (itc-claim-month
    :accessor    itc-claim-month
    :type        (string 7)
    :initarg     :itc-claim-month)

   ;; GSTR2B RECONCILIATION
   (in-gstr2b
    :accessor    in-gstr2b
    :type        integer
    :initarg     :in-gstr2b)
   (gstr2b-match-status
    :accessor    gstr2b-match-status
    :type        (string 20)
    :initarg     :gstr2b-match-status)
   (gstr2b-verified-date
    :accessor    gstr2b-verified-date
    :type        clsql:date
    :initarg     :gstr2b-verified-date)

   ;; E-INVOICE FIELDS
   (e-invoice-required
    :accessor    e-invoice-required
    :type        integer
    :initarg     :e-invoice-required)
   (irn
    :accessor    irn
    :type        (string 64)
    :initarg     :irn)
   (irn-date
    :accessor    irn-date
    :type        clsql:wall-time
    :initarg     :irn-date)
   (ack-number
    :accessor    ack-number
    :type        (string 20)
    :initarg     :ack-number)

   ;; RCM FIELDS
   (reverse-charge
    :accessor    reverse-charge
    :type        (string 3)
    :initarg     :reverse-charge)
   (rcm-paid
    :accessor    rcm-paid
    :type        integer
    :initarg     :rcm-paid)
   (rcm-paid-date
    :accessor    rcm-paid-date
    :type        clsql:date
    :initarg     :rcm-paid-date)

   ;; PAYMENT AND STATUS
   (payment-status
    :accessor    payment-status
    :type        (string 20)
    :initarg     :payment-status)
   (uploaded-to-gstn
    :accessor    uploaded-to-gstn
    :type        integer
    :initarg     :uploaded-to-gstn)
   (gstn-upload-date
    :accessor    gstn-upload-date
    :type        clsql:wall-time
    :initarg     :gstn-upload-date)
   (place-of-supply
    :accessor    place-of-supply
    :type        (string 50)
    :initarg     :place-of-supply)
   (state-code
    :accessor    state-code
    :type        (string 2)
    :initarg     :state-code)
   (invoice-status
    :accessor    invoice-status
    :type        (string 20)
    :initarg     :invoice-status)
   (tenant-id
    :accessor    tenant-id
    :type        integer
    :initarg     :tenant-id)
   (created-at
    :accessor    created-at
    :type        clsql:wall-time
    :initarg     :created-at)
   (updated-at
    :accessor    updated-at
    :type        clsql:wall-time
    :initarg     :updated-at))

  (:base-table dod_v_customer_invoice_register))
