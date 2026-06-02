;;; nst-dal-Order.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defclass orderAdapter (AdapterService)
  ())

(defclass orderDBService (DBAdapterService)
  ())

(defclass orderPresenter (PresenterService)
  ())

(defclass orderService (BusinessService)
  ())
(defclass orderHTMLView (HTMLView)
  ())

(defclass orderViewModel (ViewModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (ord-date
    :initarg :ord-date
    :accessor ord-date)
   (req-date
    :initarg :req-date
    :accessor req-date)
   (shipped-date
    :initarg :shipped-date
    :accessor shipped-date)
   (expected-delivery-date
    :initarg :expected-delivery-date
    :accessor expected-delivery-date)
   (ordnum
    :initarg :ordnum
    :accessor ordnum)
   (shipaddr
    :initarg :shipaddr
    :accessor shipaddr)
   (shipzipcode
    :initarg :shipzipcode
    :accessor shipzipcode)
   (shipcity
    :initarg :shipcity
    :accessor shipcity)
   (shipstate
    :initarg :shipstate
    :accessor shipstate)
   (billaddr
    :initarg :billaddr
    :accessor billaddr)
   (billzipcode
    :initarg :billzipcode
    :accessor billzipcode)
   (billcity
    :initarg :billcity
    :accessor billcity)
   (billstate
    :initarg :billstate
    :accessor billstate)
   (billsameasship
    :initarg :billsameasship
    :accessor billsameasship)
   (storepickupenabled
    :initarg :storepickupenabled
    :accessor storepickupenabled)
   (gstnumber
    :initarg :gstnumber
    :accessor gstnumber)
   (gstorgname
    :initarg :gstorgname
    :accessor gstorgname)
   (order-fulfilled
    :initarg :order-fulfilled
    :accessor order-fulfilled)
   (order-amt
    :initarg :order-amt
    :accessor order-amt)
   (shipping-cost
    :initarg :shipping-cost
    :accessor shipping-cost)
   (total-discount
    :initarg :total-discount
    :accessor total-discount)
   (total-tax
    :initarg :total-tax
    :accessor total-tax)
   (payment-mode
    :initarg :payment-mode
    :accessor payment-mode)
   (comments
    :initarg :comments
    :accessor comments)
   (context-id
    :initarg :context-id
    :accessor context-id)
   (customer
    :initarg :customer
    :accessor customer)
   (status
    :initarg :status
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (is-converted-to-invoice
    :initarg :is-converted-to-invoice
    :accessor is-converted-to-invoice)
   (is-cancelled
    :initarg :is-cancelled
    :accessor is-cancelled)
   (cancel-reason
    :initarg :cancel-reason
    :accessor cancel-reason)
   (order-type
    :initarg :order-type
    :accessor order-type)
   (external-url
    :initarg :external-url
    :accessor external-url)
   (order-source
    :initarg :order-source
    :accessor order-source)
   (custname
    :initarg :custname
    :accessor custname)
   (company
    :initarg :company
    :accessor company)))

(defclass orderResponseModel (ResponseModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (ord-date
    :initarg :ord-date
    :accessor ord-date)
   (req-date
    :initarg :req-date
    :accessor req-date)
   (shipped-date
    :initarg :shipped-date
    :accessor shipped-date)
   (expected-delivery-date
    :initarg :expected-delivery-date
    :accessor expected-delivery-date)
   (ordnum
    :initarg :ordnum
    :accessor ordnum)
   (shipaddr
    :initarg :shipaddr
    :accessor shipaddr)
   (shipzipcode
    :initarg :shipzipcode
    :accessor shipzipcode)
   (shipcity
    :initarg :shipcity
    :accessor shipcity)
   (shipstate
    :initarg :shipstate
    :accessor shipstate)
   (billaddr
    :initarg :billaddr
    :accessor billaddr)
   (billzipcode
    :initarg :billzipcode
    :accessor billzipcode)
   (billcity
    :initarg :billcity
    :accessor billcity)
   (billstate
    :initarg :billstate
    :accessor billstate)
   (billsameasship
    :initarg :billsameasship
    :accessor billsameasship)
   (storepickupenabled
    :initarg :storepickupenabled
    :accessor storepickupenabled)
   (gstnumber
    :initarg :gstnumber
    :accessor gstnumber)
   (gstorgname
    :initarg :gstorgname
    :accessor gstorgname)
   (order-fulfilled
    :initarg :order-fulfilled
    :accessor order-fulfilled)
   (order-amt
    :initarg :order-amt
    :accessor order-amt)
   (shipping-cost
    :initarg :shipping-cost
    :accessor shipping-cost)
   (total-discount
    :initarg :total-discount
    :accessor total-discount)
   (total-tax
    :initarg :total-tax
    :accessor total-tax)
   (payment-mode
    :initarg :payment-mode
    :accessor payment-mode)
   (comments
    :initarg :comments
    :accessor comments)
   (context-id
    :initarg :context-id
    :accessor context-id)
   (customer
    :initarg :customer
    :accessor customer)
   (status
    :initarg :status
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (is-converted-to-invoice
    :initarg :is-converted-to-invoice
    :accessor is-converted-to-invoice)
   (is-cancelled
    :initarg :is-cancelled
    :accessor is-cancelled)
   (cancel-reason
    :initarg :cancel-reason
    :accessor cancel-reason)
   (order-type
    :initarg :order-type
    :accessor order-type)
   (external-url
    :initarg :external-url
    :accessor external-url)
   (order-source
    :initarg :order-source
    :accessor order-source)
   (custname
    :initarg :custname
    :accessor custname)
   (company
    :initarg :company
    :accessor company)))
   

(defclass orderRequestModel (RequestModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (ord-date
    :initarg :ord-date
    :accessor ord-date)
   (req-date
    :initarg :req-date
    :accessor req-date)
   (shipped-date
    :initarg :shipped-date
    :accessor shipped-date)
   (expected-delivery-date
    :initarg :expected-delivery-date
    :accessor expected-delivery-date)
   (ordnum
    :initarg :ordnum
    :accessor ordnum)
   (shipaddr
    :initarg :shipaddr
    :accessor shipaddr)
   (shipzipcode
    :initarg :shipzipcode
    :accessor shipzipcode)
   (shipcity
    :initarg :shipcity
    :accessor shipcity)
   (shipstate
    :initarg :shipstate
    :accessor shipstate)
   (billaddr
    :initarg :billaddr
    :accessor billaddr)
   (billzipcode
    :initarg :billzipcode
    :accessor billzipcode)
   (billcity
    :initarg :billcity
    :accessor billcity)
   (billstate
    :initarg :billstate
    :accessor billstate)
   (billsameasship
    :initarg :billsameasship
    :accessor billsameasship)
   (storepickupenabled
    :initarg :storepickupenabled
    :accessor storepickupenabled)
   (gstnumber
    :initarg :gstnumber
    :accessor gstnumber)
   (gstorgname
    :initarg :gstorgname
    :accessor gstorgname)
   (order-fulfilled
    :initarg :order-fulfilled
    :accessor order-fulfilled)
   (order-amt
    :initarg :order-amt
    :accessor order-amt)
   (shipping-cost
    :initarg :shipping-cost
    :accessor shipping-cost)
   (total-discount
    :initarg :total-discount
    :accessor total-discount)
   (total-tax
    :initarg :total-tax
    :accessor total-tax)
   (payment-mode
    :initarg :payment-mode
    :accessor payment-mode)
   (comments
    :initarg :comments
    :accessor comments)
   (context-id
    :initarg :context-id
    :accessor context-id)
   (customer
    :initarg :customer
    :accessor customer)
   (status
    :initarg :status
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (is-converted-to-invoice
    :initarg :is-converted-to-invoice
    :accessor is-converted-to-invoice)
   (is-cancelled
    :initarg :is-cancelled
    :accessor is-cancelled)
   (cancel-reason
    :initarg :cancel-reason
    :accessor cancel-reason)
   (order-type
    :initarg :order-type
    :accessor order-type)
   (external-url
    :initarg :external-url
    :accessor external-url)
   (order-source
    :initarg :order-source
    :accessor order-source)
   (custname
    :initarg :custname
    :accessor custname)
   (company
    :initarg :company
    :accessor company)))


(defclass orderSearchRequestModel (orderRequestModel)
  ())

(defclass order (BusinessObject)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (ord-date
    :initarg :ord-date
    :accessor ord-date)
   (req-date
    :initarg :req-date
    :accessor req-date)
   (shipped-date
    :initarg :shipped-date
    :accessor shipped-date)
   (expected-delivery-date
    :initarg :expected-delivery-date
    :accessor expected-delivery-date)
   (ordnum
    :initarg :ordnum
    :accessor ordnum)
   (shipaddr
    :initarg :shipaddr
    :accessor shipaddr)
   (shipzipcode
    :initarg :shipzipcode
    :accessor shipzipcode)
   (shipcity
    :initarg :shipcity
    :accessor shipcity)
   (shipstate
    :initarg :shipstate
    :accessor shipstate)
   (billaddr
    :initarg :billaddr
    :accessor billaddr)
   (billzipcode
    :initarg :billzipcode
    :accessor billzipcode)
   (billcity
    :initarg :billcity
    :accessor billcity)
   (billstate
    :initarg :billstate
    :accessor billstate)
   (billsameasship
    :initarg :billsameasship
    :accessor billsameasship)
   (storepickupenabled
    :initarg :storepickupenabled
    :accessor storepickupenabled)
   (gstnumber
    :initarg :gstnumber
    :accessor gstnumber)
   (gstorgname
    :initarg :gstorgname
    :accessor gstorgname)
   (order-fulfilled
    :initarg :order-fulfilled
    :accessor order-fulfilled)
   (order-amt
    :initarg :order-amt
    :accessor order-amt)
   (shipping-cost
    :initarg :shipping-cost
    :accessor shipping-cost)
   (total-discount
    :initarg :total-discount
    :accessor total-discount)
   (total-tax
    :initarg :total-tax
    :accessor total-tax)
   (payment-mode
    :initarg :payment-mode
    :accessor payment-mode)
   (comments
    :initarg :comments
    :accessor comments)
   (context-id
    :initarg :context-id
    :accessor context-id)
   (customer
    :initarg :customer
    :accessor customer)
   (status
    :initarg :status
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (is-converted-to-invoice
    :initarg :is-converted-to-invoice
    :accessor is-converted-to-invoice)
   (is-cancelled
    :initarg :is-cancelled
    :accessor is-cancelled)
   (cancel-reason
    :initarg :cancel-reason
    :accessor cancel-reason)
   (order-type
    :initarg :order-type
    :accessor order-type)
   (external-url
    :initarg :external-url
    :accessor external-url)
   (order-source
    :initarg :order-source
    :accessor order-source)
   (custname
    :initarg :custname
    :accessor custname)
   (company
    :initarg :company
    :accessor company)))


(clsql:def-view-class dod-order ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :column "ROW_ID"
    :type integer
    :initarg :row-id)

   ;; --- Relationships & Joins ---
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
   
   (created-by-user-id
    :type integer
    :column "CREATED_BY_USER_ID"
    :initarg :created-by-user-id)
   (approved-by-user-id
    :type integer
    :column "APPROVED_BY_USER_ID"
    :initarg :approved-by-user-id)

   ;; --- Order Identity & Status ---
   (ordnum
    :type (string 50)
    :column "ORDNUM"
    :initarg :ordnum)
   (context-id
    :type (string 100)
    :column "CONTEXT_ID"
    :initarg :context-id)
   (status
    :type (string 3)
    :column "STATUS"
    :initarg :status)
   (order-type
    :type (string 4)
    :column "ORDER_TYPE"
    :initarg :order-type)
   (order-source
    :type (string 10) ; enum('POS','ONLINE','WHATSAPP','API')
    :column "ORDER_SOURCE"
    :initarg :order-source)
   (order-fulfilled
    :type (string 1)
    :column "ORDER_FULFILLED"
    :initarg :order-fulfilled)

   ;; --- Temporal Data ---
   (ord-date
    :type clsql:date
    :column "ORD_DATE"
    :initarg :ord-date)
   (req-date
    :type clsql:date
    :column "REQ_DATE"
    :initarg :req-date)
   (shipped-date
    :type clsql:date
    :column "SHIPPED_DATE"
    :initarg :shipped-date)
   (expected-delivery-date
    :type clsql:date
    :column "EXPECTED_DELIVERY_DATE"
    :initarg :expected-delivery-date)
   (invoice-date
    :type clsql:date
    :column "INVOICE_DATE"
    :initarg :invoice-date)

   ;; --- Financial Totals ---
   (order-amt
    :type float
    :column "ORDER_AMT"
    :initarg :order-amt)
   (total-taxable-value
    :type float
    :column "TOTAL_TAXABLE_VALUE"
    :initarg :total-taxable-value)
   (total-tax
    :type float
    :column "TOTAL_TAX"
    :initarg :total-tax)
   (total-discount
    :type float
    :column "TOTAL_DISCOUNT"
    :initarg :total-discount)
   (shipping-cost
    :type float
    :column "SHIPPING_COST"
    :initarg :shipping-cost)

   ;; --- GST Breakdown ---
   (total-cgst
    :type float
    :column "TOTAL_CGST"
    :initarg :total-cgst)
   (total-sgst
    :type float
    :column "TOTAL_SGST"
    :initarg :total-sgst)
   (total-igst
    :type float
    :column "TOTAL_IGST"
    :initarg :total-igst)
   (total-cess
    :type float
    :column "TOTAL_CESS"
    :initarg :total-cess)

   ;; --- Compliance & TDS ---
   (place-of-supply
    :type (string 50)
    :column "PLACE_OF_SUPPLY"
    :initarg :place-of-supply)
   (place-of-supply-code
    :type (string 2)
    :column "PLACE_OF_SUPPLY_CODE"
    :initarg :place-of-supply-code)
   (supply-type
    :type (string 15) ; enum('INTRA_STATE','INTER_STATE')
    :column "SUPPLY_TYPE"
    :initarg :supply-type)
   (gst-number
    :type (string 20)
    :column "GSTNUMBER"
    :initarg :gst-number)
   (gst-org-name
    :type (string 50)
    :column "GSTORGNAME"
    :initarg :gst-org-name)
   (reverse-charge-applicable
    :type integer ; tinyint(1)
    :column "REVERSE_CHARGE_APPLICABLE"
    :initarg :reverse-charge-applicable)
   (eway-bill-required
    :type integer
    :column "EWAY_BILL_REQUIRED"
    :initarg :eway-bill-required)
   (tds-applicable
    :type integer
    :column "TDS_APPLICABLE"
    :initarg :tds-applicable)
   (tds-amount
    :type float
    :column "TDS_AMOUNT"
    :initarg :tds-amount)

   ;; --- Shipping & Billing Addresses ---
   (cust-name
    :type (string 255)
    :column "CUSTNAME"
    :initarg :cust-name)
   (ship-address-short
    :type (string 200)
    :column "SHIP_ADDRESS"
    :initarg :ship-address-short)
   (ship-addr-full
    :type string ; text
    :column "SHIPADDR"
    :initarg :ship-addr-full)
   (ship-city
    :type (string 50)
    :column "SHIPCITY"
    :initarg :ship-city)
   (ship-state
    :type (string 50)
    :column "SHIPSTATE"
    :initarg :ship-state)
   (ship-zipcode
    :type (string 10)
    :column "SHIPZIPCODE"
    :initarg :ship-zipcode)
   (bill-address-short
    :type (string 200)
    :column "BILLADDRESS"
    :initarg :bill-address-short)
   (bill-addr-full
    :type string ; text
    :column "BILLADDR"
    :initarg :bill-addr-full)
   (bill-city
    :type (string 50)
    :column "BILLCITY"
    :initarg :bill-city)
   (bill-state
    :type (string 50)
    :column "BILLSTATE"
    :initarg :bill-state)
   (bill-zipcode
    :type (string 10)
    :column "BILLZIPCODE"
    :initarg :bill-zipcode)
   (country
    :type (string 50)
    :column "COUNTRY"
    :initarg :country)
   (bill-same-as-ship
    :type (string 1)
    :column "BILLSAMEASSHIP"
    :initarg :bill-same-as-ship)

   ;; --- Workflow Flags & Metadata ---
   (payment-mode
    :type (string 3)
    :column "PAYMENT_MODE"
    :initarg :payment-mode)
   (is-converted-to-invoice
    :type (string 1)
    :column "IS_CONVERTED_TO_INVOICE"
    :initarg :is-converted-to-invoice)
   (invoice-number
    :type (string 50)
    :column "INVOICE_NUMBER"
    :initarg :invoice-number)
   (is-cancelled
    :type (string 1)
    :column "IS_CANCELLED"
    :initarg :is-cancelled)
   (cancel-reason
    :type string
    :column "CANCEL_REASON"
    :initarg :cancel-reason)
   (storepickupenabled
    :type (string 1)
    :column "STOREPICKUPENABLED"
    :initarg :storepickupenabled)
   (comments
    :type (string 255)
    :column "COMMENTS"
    :initarg :comments)
   (external-url
    :type (string 2048)
    :column "EXTERNAL_URL"
    :initarg :external-url)

   ;; --- Audit Trail ---
   (tenant-id
    :type integer
    :column "TENANT_ID"
    :initarg :tenant-id)
   (company
    :accessor get-company
    :db-kind :join
    :db-info (:join-class dod-company
              :home-key tenant-id
              :foreign-key row-id
              :set nil))
   (deleted-state
    :type (string 1)
    :column "DELETED_STATE"
    :initarg :deleted-state)
   (created
    :type (string 30)
    :column "CREATED"
    :initarg :created)
   (updated
    :type (string 30)
    :column "UPDATED"
    :initarg :updated))
  (:base-table "DOD_ORDER"))

 
