;;; nst-dal-ihd.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defclass InvoiceHeaderAdapter (AdapterService)
  ())

(defclass InvoiceHeaderDBService (DBAdapterService)
  ())

(defclass InvoiceHeaderPresenter (PresenterService)
  ())

(defclass InvoiceHeaderService (BusinessService)
  ())
(defclass InvoiceHeaderHTMLView (HTMLView)
  ())

(defclass SessionInvoice (BusinessObject)
  ((customer
    :initarg :customer
    :accessor customer)
   (invoiceheader
    :initarg :invoiceheader
    :accessor invoiceheader)
   (invoiceitems
    :initarg :inivoiceitems
    :accessor invoiceitems
    :initform '())
   (invoicetaxbreakdown
    :initarg :invoicetaxbreakdown
    :accessor invoicetaxbreakdown
    :initform nil)
   (invoiceproducts
    :initarg :invoiceproducts
    :accessor invoiceproducts
    :initform '())))

(defclass InvoiceHeaderViewModel (ViewModel)
  ((invnum
    :initarg :invnum
    :accessor invnum)
   (invdate
    :initarg :invdate
    :accessor invdate)
   (context-id
    :initarg :context-id
    :accessor context-id)
   (customer
    :initarg :customer
    :accessor customer)
   (vendor
    :initarg :vendor
    :accessor vendor)
   (custname
    :initarg :custname
    :accessor custname)
   (custaddr
    :initarg :custaddr
    :accessor custaddr)
   (custgstin
    :initarg :custgstin
    :accessor custgstin)
   (statecode
    :initarg :statecode
    :accessor statecode)
   (billaddr
    :initarg :billaddr
    :accessor billaddr)
   (shipaddr
    :initarg :shipaddr
    :accessor shipaddr)
   (placeofsupply
    :initarg :placeofsupply
    :accessor placeofsupply)
   (revcharge
    :initarg :revcharge
    :accessor revcharge)
   (transmode
    :initarg :transmode
    :accessor transmode)
   (vnum
    :initarg :vnum
    :accessor vnum)
   (totalvalue
    :initarg :totalvalue
    :accessor totalvalue)
   (totalinwords
    :initarg :totalinwords
    :accessor totalinwords)
   (bankaccnum
    :initarg :bankaccnum
    :accessor bankaccnum)
   (bankifsccode
    :initarg :bankifsccode
    :accessor bankifsccode)
   (tnc
    :initarg :tnc
    :accessor tnc)
   (authsign
    :initarg :authsign
    :accessor authsign)
   (finyear
    :initarg :finyear
    :accessor finyear)
   (user-id
    :initarg :user-id
    :accessor user-id)
   (created
    :initarg :created
    :accessor created)
   (updated
    :initarg :updated
    :accessor updated)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (external-url
    :initarg :external-url
    :accessor external-url)
   (status
    :initarg :status
    :accessor status)
   (company
    :initarg :company
    :accessor company)))

(defclass InvoiceHeaderResponseModel (ResponseModel)
  ((invnum
    :initarg :invnum
    :accessor invnum)
   (invdate
    :initarg :invdate
    :accessor invdate)
   (context-id
    :initarg :context-id
    :accessor context-id)
    (custname
    :initarg :custname
    :accessor custname)
   (custaddr
    :initarg :custaddr
    :accessor custaddr)
   (custgstin
    :initarg :custgstin
    :accessor custgstin)
   (statecode
    :initarg :statecode
    :accessor statecode)
   (billaddr
    :initarg :billaddr
    :accessor billaddr)
   (shipaddr
    :initarg :shipaddr
    :accessor shipaddr)
   (placeofsupply
    :initarg :placeofsupply
    :accessor placeofsupply)
   (revcharge
    :initarg :revcharge
    :accessor revcharge)
   (transmode
    :initarg :transmode
    :accessor transmode)
   (vnum
    :initarg :vnum
    :accessor vnum)
   (totalvalue
    :initarg :totalvalue
    :accessor totalvalue)
   (totalinwords
    :initarg :totalinwords
    :accessor totalinwords)
   (bankaccnum
    :initarg :bankaccnum
    :accessor bankaccnum)
   (bankifsccode
    :initarg :bankifsccode
    :accessor bankifsccode)
   (tnc
    :initarg :tnc
    :accessor tnc)
   (authsign
    :initarg :authsign
    :accessor authsign)
   (finyear
    :initarg :finyear
    :accessor finyear)
   (user-id
    :initarg :user-id
    :accessor user-id)
   (created
    :initarg :created
    :accessor created)
   (updated
    :initarg :updated
    :accessor updated)
   (status
    :initarg :status
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (external-url
    :initarg :external-url
    :accessor external-url)
   (last-viewed-by-user-id
    :initarg :last-viewed-by-user-id
    :accessor last-viewed-by-user-id)
   (last-viewed-at
    :initarg :last-viewed-at
    :accessor last-viewed-at)
   (e-invoice-required
    :initarg :e-invoice-required
    :accessor e-invoice-required)
   (irn
    :initarg :irn
    :accessor irn)
   (irn-date
    :initarg :irn-date
    :accessor irn-date)
   (ack-number
    :initarg :ack-number
    :accessor ack-number)
   (ack-date
    :initarg :ack-date
    :accessor ack-date)
   (qr-code-path
    :initarg :qr-code-path
    :accessor qr-code-path)
   (uploaded-to-gstn
    :initarg :uploaded-to-gstn
    :accessor uploaded-to-gstn)
   (gstn-upload-date
    :initarg :gstn-upload-date
    :accessor gstn-upload-date)
   (gstr1-period
    :initarg :gstr1-period
    :accessor gstr1-period)
   (in-gstr2b
    :initarg :in-gstr2b
    :accessor in-gstr2b)
   (gstr2b-match-status
    :initarg :gstr2b-match-status
    :accessor gstr2b-match-status)
   (gstr2b-verified-date
    :initarg :gstr2b-verified-date
    :accessor gstr2b-verified-date)
   (itc-eligible
    :initarg :itc-eligible
    :accessor itc-eligible)
   (itc-claimed
    :initarg :itc-claimed
    :accessor itc-claimed)
   (itc-claim-month
    :initarg :itc-claim-month
    :accessor itc-claim-month)
   (itc-amount
    :initarg :itc-amount
    :accessor itc-amount)
   (advance-adjusted
    :initarg :advance-adjusted
    :accessor advance-adjusted)
   (payment-allocated
    :initarg :payment-allocated
    :accessor payment-allocated)
   (total-allocated
    :initarg :total-allocated
    :accessor total-allocated)
   (total-tds-deducted
    :initarg :total-tds-deducted
    :accessor total-tds-deducted)
   (balance-due
    :initarg :balance-due
    :accessor balance-due)
   (advance-gst-reversed
    :initarg :advance-gst-reversed
    :accessor advance-gst-reversed)
   (payment-status
    :initarg :payment-status
    :accessor payment-status)
   (rcm-paid
    :initarg :rcm-paid
    :accessor rcm-paid)
   (rcm-paid-date
    :initarg :rcm-paid-date
    :accessor rcm-paid-date)
   ;; Merged slots
   (customer
    :initarg :customer
    :accessor customer)
   (vendor
    :initarg :vendor
    :accessor vendor)
   (company
    :initarg :company
    :accessor company)))
   

(defclass InvoiceHeaderRequestModel (RequestModel)
  ((invnum
    :initarg :invnum
    :accessor invnum)
   (invdate
    :initarg :invdate
    :accessor invdate)
   (context-id
    :initarg :context-id
    :accessor context-id)
   (custid
    :initarg :custid
    :accessor custid)
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id)
   (custname
    :initarg :custname
    :accessor custname)
   (customer
    :initarg :customer
    :accessor customer)
   (custaddr
    :initarg :custaddr
    :accessor custaddr)
   (custgstin
    :initarg :custgstin
    :accessor custgstin)
   (statecode
    :initarg :statecode
    :accessor statecode)
   (billaddr
    :initarg :billaddr
    :accessor billaddr)
   (shipaddr
    :initarg :shipaddr
    :accessor shipaddr)
   (placeofsupply
    :initarg :placeofsupply
    :accessor placeofsupply)
   (revcharge
    :initarg :revcharge
    :accessor revcharge)
   (transmode
    :initarg :transmode
    :accessor transmode)
   (vnum
    :initarg :vnum
    :accessor vnum)
   (totalvalue
    :initarg :totalvalue
    :accessor totalvalue)
   (totalinwords
    :initarg :totalinwords
    :accessor totalinwords)
   (bankaccnum
    :initarg :bankaccnum
    :accessor bankaccnum)
   (bankifsccode
    :initarg :bankifsccode
    :accessor bankifsccode)
   (tnc
    :initarg :tnc
    :accessor tnc)
   (authsign
    :initarg :authsign
    :accessor authsign)
   (finyear
    :initarg :finyear
    :accessor finyear)
   (user-id
    :initarg :user-id
    :accessor user-id)
   (status
    :initarg :status
    :accessor status)
   (tenant-id
    :initarg :tenant-id
    :accessor tenant-id)
   (external-url
    :initarg :external-url
    :accessor external-url)
   (last-viewed-by-user-id
    :initarg :last-viewed-by-user-id
    :accessor last-viewed-by-user-id)
   (last-viewed-at
    :initarg :last-viewed-at
    :accessor last-viewed-at)
   (e-invoice-required
    :initarg :e-invoice-required
    :accessor e-invoice-required)
   (irn
    :initarg :irn
    :accessor irn)
   (irn-date
    :initarg :irn-date
    :accessor irn-date)
   (ack-number
    :initarg :ack-number
    :accessor ack-number)
   (ack-date
    :initarg :ack-date
    :accessor ack-date)
   (qr-code-path
    :initarg :qr-code-path
    :accessor qr-code-path)
   (uploaded-to-gstn
    :initarg :uploaded-to-gstn
    :accessor uploaded-to-gstn)
   (gstn-upload-date
    :initarg :gstn-upload-date
    :accessor gstn-upload-date)
   (gstr1-period
    :initarg :gstr1-period
    :accessor gstr1-period)
   (in-gstr2b
    :initarg :in-gstr2b
    :accessor in-gstr2b)
   (gstr2b-match-status
    :initarg :gstr2b-match-status
    :accessor gstr2b-match-status)
   (gstr2b-verified-date
    :initarg :gstr2b-verified-date
    :accessor gstr2b-verified-date)
   (itc-eligible
    :initarg :itc-eligible
    :accessor itc-eligible)
   (itc-claimed
    :initarg :itc-claimed
    :accessor itc-claimed)
   (itc-claim-month
    :initarg :itc-claim-month
    :accessor itc-claim-month)
   (itc-amount
    :initarg :itc-amount
    :accessor itc-amount)
   (advance-adjusted
    :initarg :advance-adjusted
    :accessor advance-adjusted)
   (payment-allocated
    :initarg :payment-allocated
    :accessor payment-allocated)
   (total-allocated
    :initarg :total-allocated
    :accessor total-allocated)
   (total-tds-deducted
    :initarg :total-tds-deducted
    :accessor total-tds-deducted)
   (balance-due
    :initarg :balance-due
    :accessor balance-due)
   (advance-gst-reversed
    :initarg :advance-gst-reversed
    :accessor advance-gst-reversed)
   (payment-status
    :initarg :payment-status
    :accessor payment-status)
   (rcm-paid
    :initarg :rcm-paid
    :accessor rcm-paid)
   (rcm-paid-date
    :initarg :rcm-paid-date
    :accessor rcm-paid-date)
   ;; Merged slots
   (vendor
    :initarg :vendor
    :accessor vendor)
   (company
    :initarg :company
    :accessor company)))


(defclass InvoiceHeaderSearchRequestModel (InvoiceHeaderRequestModel)
  ())

(defclass InvoiceHeaderContextIDRequestModel (InvoiceHeaderRequestModel)
  ())

(defclass InvoiceHeaderStatusRequestModel (InvoiceHeaderRequestModel)
  ())

(defclass InvoiceHeader (BusinessObject)
  ((row-id)
   (invnum
    :initarg :invnum
    :initform "000"
    :accessor invnum)
   (invdate
    :initarg :invdate
    :initform (clsql-sys::get-date)
    :accessor invdate)
   (context-id
    :initarg :context-id
    :accessor context-id)
   (custid
    :initarg :custid
    :accessor custid)
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id)
   (custname
    :initarg :custname
    :initform ""
    :accessor custname)
   (custaddr
    :initarg :custaddr
    :initform ""
    :accessor custaddr)
   (custgstin
    :initarg :custgstin
    :initform ""
    :accessor custgstin)
   (statecode
    :initarg :statecode
    :initform ""
    :accessor statecode)
   (billaddr
    :initarg :billaddr
    :initform ""
    :accessor billaddr)
   (shipaddr
    :initarg :shipaddr
    :initform ""
    :accessor shipaddr)
   (placeofsupply
    :initarg :placeofsupply
    :initform ""
    :accessor placeofsupply)
   (revcharge
    :initarg :revcharge
    :initform ""
    :accessor revcharge)
   (transmode
    :initarg :transmode
    :initform ""
    :accessor transmode)
   (vnum
    :initarg :vnum
    :initform ""
    :accessor vnum)
   (totalvalue
    :initarg :totalvalue
    :initform 0.00
    :accessor totalvalue)
   (totalinwords
    :initarg :totalinwords
    :initform ""
    :accessor totalinwords)
   (bankaccnum
    :initarg :bankaccnum
    :initform ""
    :accessor bankaccnum)
   (bankifsccode
    :initarg :bankifsccode
    :initform ""
    :accessor bankifsccode)
   (tnc
    :initarg :tnc
    :initform ""
    :accessor tnc)
   (authsign
    :initarg :authsign
    :initform ""
    :accessor authsign)
   (finyear
    :initarg :finyear
    :initform ""
    :accessor finyear)
   (user-id
    :initarg :user-id
    :accessor user-id)
   (created
    :initarg :created
    :accessor created)
   (updated
    :initarg :updated
    :accessor updated)
   (status
    :initarg :status
    :initform "DRAFT"
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :initform "N"
    :accessor deleted-state)
   (tenant-id
    :initarg :tenant-id
    :accessor tenant-id)
   (external-url
    :initarg :external-url
    :accessor external-url)
   (last-viewed-by-user-id
    :initarg :last-viewed-by-user-id
    :accessor last-viewed-by-user-id)
   (last-viewed-at
    :initarg :last-viewed-at
    :accessor last-viewed-at)
   (e-invoice-required
    :initarg :e-invoice-required
    :accessor e-invoice-required)
   (irn
    :initarg :irn
    :accessor irn)
   (irn-date
    :initarg :irn-date
    :accessor irn-date)
   (ack-number
    :initarg :ack-number
    :accessor ack-number)
   (ack-date
    :initarg :ack-date
    :accessor ack-date)
   (qr-code-path
    :initarg :qr-code-path
    :accessor qr-code-path)
   (uploaded-to-gstn
    :initarg :uploaded-to-gstn
    :accessor uploaded-to-gstn)
   (gstn-upload-date
    :initarg :gstn-upload-date
    :accessor gstn-upload-date)
   (gstr1-period
    :initarg :gstr1-period
    :accessor gstr1-period)
   (in-gstr2b
    :initarg :in-gstr2b
    :accessor in-gstr2b)
   (gstr2b-match-status
    :initarg :gstr2b-match-status
    :accessor gstr2b-match-status)
   (gstr2b-verified-date
    :initarg :gstr2b-verified-date
    :accessor gstr2b-verified-date)
   (itc-eligible
    :initarg :itc-eligible
    :accessor itc-eligible)
   (itc-claimed
    :initarg :itc-claimed
    :accessor itc-claimed)
   (itc-claim-month
    :initarg :itc-claim-month
    :accessor itc-claim-month)
   (itc-amount
    :initarg :itc-amount
    :accessor itc-amount)
   (advance-adjusted
    :initarg :advance-adjusted
    :accessor advance-adjusted)
   (payment-allocated
    :initarg :payment-allocated
    :accessor payment-allocated)
   (total-allocated
    :initarg :total-allocated
    :accessor total-allocated)
   (total-tds-deducted
    :initarg :total-tds-deducted
    :accessor total-tds-deducted)
   (balance-due
    :initarg :balance-due
    :accessor balance-due)
   (advance-gst-reversed
    :initarg :advance-gst-reversed
    :accessor advance-gst-reversed)
   (payment-status
    :initarg :payment-status
    :accessor payment-status)
   (rcm-paid
    :initarg :rcm-paid
    :accessor rcm-paid)
   (rcm-paid-date
    :initarg :rcm-paid-date
    :accessor rcm-paid-date)
   ;; Merged slots
   (customer
    :initarg :customer
    :initform ""
    :accessor customer)
   (vendor
    :initarg :vendor
    :accessor vendor)
   (company
    :initarg :company
    :accessor company)))


(clsql:def-view-class dod-Invoice-Header ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)
   (invnum
    :initarg :invnum
    :type (string 50)
    :accessor invnum)
   (invdate
    :type clsql:date
    :initarg :invdate
    :accessor invdate)
   (context-id
    :initarg :context-id
    :type (string 100)
    :accessor context-id)
   (custid
    :initarg :custid
    :type integer
    :accessor custid)
   (vendor-id
    :initarg :vendor-id
    :type integer
    :accessor vendor-id)
   (custname
    :initarg :custname
    :type (string 255)
    :accessor custname)
   (custaddr
    :initarg :custaddr
    :type string
    :accessor custaddr)
   (custgstin
    :initarg :custgstin
    :type (string 15)
    :accessor custgstin)
   (statecode
    :initarg :statecode
    :type (string 2)
    :accessor statecode)
   (billaddr
    :initarg :billaddr
    :type string
    :accessor billaddr)
   (shipaddr
    :initarg :shipaddr
    :type string
    :accessor shipaddr)
   (placeofsupply
    :initarg :placeofsupply
    :type (string 50)
    :accessor placeofsupply)
   (revcharge
    :initarg :revcharge
    :type (string 3)
    :accessor revcharge)
   (transmode
    :initarg :transmode
    :type (string 50)
    :accessor transmode)
   (vnum
    :initarg :vnum
    :type (string 20)
    :accessor vnum)
   (totalvalue
    :initarg :totalvalue
    :type float
    :accessor totalvalue)
   (totalinwords
    :initarg :totalinwords
    :type (string 255)
    :accessor totalinwords)
   (bankaccnum
    :initarg :bankaccnum
    :type (string 20)
    :accessor bankaccnum)
   (bankifsccode
    :initarg :bankifsccode
    :type (string 11)
    :accessor bankifsccode)
   (tnc
    :initarg :tnc
    :type string
    :accessor tnc)
   (authsign
    :initarg :authsign
    :type (string 100)
    :accessor authsign)
   (finyear
    :initarg :finyear
    :type (string 9)
    :accessor finyear)
   (user-id
    :initarg :user-id
    :type integer
    :accessor user-id)
   (created
    :initarg :created
    :type clsql:wall-time
    :accessor created)
   (updated
    :type clsql:wall-time
    :initarg :updated
    :void-value (clsql:get-time)
    :accessor updated)
   (status
    :initarg :status
    :type (string 20)
    :accessor status)
   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state
    :accessor deleted-state)
   (tenant-id
    :initarg :tenant-id
    :type integer
    :accessor tenant-id)
   (external-url
    :initarg :external-url
    :type (string 2048)
    :accessor external-url)
   (last-viewed-by-user-id
    :initarg :last-viewed-by-user-id
    :type integer
    :accessor last-viewed-by-user-id)
   (last-viewed-at
    :initarg :last-viewed-at
    :type clsql:wall-time
    :accessor last-viewed-at)
   (e-invoice-required
    :initarg :e-invoice-required
    :type integer
    :accessor e-invoice-required)
   (irn
    :initarg :irn
    :type (string 64)
    :accessor irn)
   (irn-date
    :initarg :irn-date
    :type clsql:wall-time
    :accessor irn-date)
   (ack-number
    :initarg :ack-number
    :type (string 20)
    :accessor ack-number)
   (ack-date
    :initarg :ack-date
    :type clsql:wall-time
    :accessor ack-date)
   (qr-code-path
    :initarg :qr-code-path
    :type (string 500)
    :accessor qr-code-path)
   (uploaded-to-gstn
    :initarg :uploaded-to-gstn
    :type integer
    :accessor uploaded-to-gstn)
   (gstn-upload-date
    :initarg :gstn-upload-date
    :type clsql:wall-time
    :accessor gstn-upload-date)
   (gstr1-period
    :initarg :gstr1-period
    :type (string 7)
    :accessor gstr1-period)
   (in-gstr2b
    :initarg :in-gstr2b
    :type integer
    :accessor in-gstr2b)
   (gstr2b-match-status
    :initarg :gstr2b-match-status
    :type (string 20)
    :accessor gstr2b-match-status)
   (gstr2b-verified-date
    :initarg :gstr2b-verified-date
    :type clsql:date
    :accessor gstr2b-verified-date)
   (itc-eligible
    :initarg :itc-eligible
    :type integer
    :accessor itc-eligible)
   (itc-claimed
    :initarg :itc-claimed
    :type integer
    :accessor itc-claimed)
   (itc-claim-month
    :initarg :itc-claim-month
    :type (string 7)
    :accessor itc-claim-month)
   (itc-amount
    :initarg :itc-amount
    :type float
    :accessor itc-amount)
   (advance-adjusted
    :initarg :advance-adjusted
    :type float
    :accessor advance-adjusted)
   (payment-allocated
    :initarg :payment-allocated
    :type float
    :accessor payment-allocated)
   (total-allocated
    :initarg :total-allocated
    :type float
    :accessor total-allocated)
   (total-tds-deducted
    :initarg :total-tds-deducted
    :type float
    :accessor total-tds-deducted)
   (balance-due
    :initarg :balance-due
    :type float
    :accessor balance-due)
   (advance-gst-reversed
    :initarg :advance-gst-reversed
    :type float
    :accessor advance-gst-reversed)
   (payment-status
    :initarg :payment-status
    :type (string 20)
    :accessor payment-status)
   (rcm-paid
    :initarg :rcm-paid
    :type integer
    :accessor rcm-paid)
   (rcm-paid-date
    :initarg :rcm-paid-date
    :type clsql:date
    :accessor rcm-paid-date)
   ;; Merged joins
   (customer
    :ACCESSOR get-customer
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-cust-profile
                          :HOME-KEY custid
                          :FOREIGN-KEY row-id
                          :SET NIL))
   (vendorobject
    :accessor odt-vendorobject
    :db-kind :join
    :db-info (:join-class dod-vend-profile
                          :home-key vendor-id
                          :foreign-key row-id
                          :set nil))
   (COMPANY
    :ACCESSOR get-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
                          :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET NIL)))
  (:BASE-TABLE dod_invoice_header))
