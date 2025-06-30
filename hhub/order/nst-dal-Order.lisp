;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

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

   (expected-delivery-date
    :accessor expected-delivery-date
    :TYPE clsql:date
    :initarg :expected-delivery-date)
   
   (ordnum
    :accessor ordnum
    :type (string 50)
    :initarg :ordnum)
   
   
   (shipaddr
    :ACCESSOR shipaddr 
    :type (string 512)
    :initarg :shipaddr)
   
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
   (billaddr
    :accessor get-billaddress
    :type (string 512)
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
   
   (billsameasship
    :accessor get-billsameasship
    :type (string 1)
    :initarg :billsameasship)

   (storepickupenabled
     :type (string 1)
     :accessor storepickupenabled
     :initarg :storepickupenabled)
      
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

   (is-converted-to-invoice
    :type (string 1)
    :void-value "N"
    :initarg :is-converted-to-invoice)

   (is-cancelled
    :type (string 1)
    :void-value "N"
    :initarg :is-cancelled)

   (cancel-reason
    :type (string 255)
    :initarg :cancel-reason)

   (external-url
    :type (string 1024)
    :initarg :external-url)
   
   (order-type 
    :type (string 4)
    :initarg :order-type
    :void-value "SALE")

   (order-source
    :type (string 20)
    :initarg :order-source
    :void-value "ONLINE")
   
   (custname
    :type (string 255)
    :initarg :custname
    :accessor custname)
     
   
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
