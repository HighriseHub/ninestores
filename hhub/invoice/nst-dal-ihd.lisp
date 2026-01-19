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
   (customer
    :initarg :customer
    :accessor customer)
   (vendor
    :initarg :vendor
    :accessor vendor)
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
   (customer
    :initarg :customer
    :accessor customer)
   (vendor
    :initarg :vendor
    :accessor vendor)
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
   (external-url
    :initarg :external-url
    :accessor external-url)
   (status
    :initarg :status
    :accessor status)
   (company
    :initarg :company
    :accessor company)))
   

(defclass InvoiceHeaderRequestModel (RequestModel)
  ((invnum
    :initarg :invnum
    :accessor invnum)
   (context-id
    :initarg :context-id
    :accessor context-id)
   (invdate
    :initarg :invdate
    :accessor invdate)
   (custid
    :initarg :custid
    :accessor custid)
   (custname
    :initarg :custname
    :accessor custname)
   (customer
    :initarg :customer
    :accessor customer)
   (vendor
    :initarg :vendor
    :accessor vendor)
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
   (external-url
    :initarg :external-url
    :accessor external-url)
   (status
    :initarg :status
    :accessor status)
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
   (context-id
    :initarg :context-id
    :accessor context-id)
   (invnum
    :initarg :invnum
    :initform "000"
    :accessor invnum)
   (invdate
    :initarg :invdate
    :initform (clsql-sys::get-date)
    :accessor invdate)
   (customer
    :initarg :customer
    :initform ""
    :accessor customer)
   (vendor
    :initarg :vendor
    :accessor vendor)
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
   (external-url
    :initarg :external-url
    :accessor external-url)
   (status
    :initarg :status
    :initform "DRAFT"
    :accessor status)
   (company
    :initarg :company
    :accessor company)))


(clsql:def-view-class dod-Invoice-Header ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)
   (context-id
    :initarg :context-id
    :type (string 100)
    :accessor context-id)
   (invnum
    :initarg :invnum
    :type (string 50)
    :accessor invnum)
   (invdate
    :type clsql:date
    :initarg :invdate
    :accessor invdate)
   (custid
    :type integer
    :initarg :custid
    :accessor custid)
   (customer
    :ACCESSOR get-customer
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-cust-profile
	                  :HOME-KEY custid
                          :FOREIGN-KEY row-id
                          :SET NIL))
   
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
   
   (custname
    :type (string 255)
    :initarg :custname
    :accessor custname)
   (custaddr
    :type (string 500)
    :initarg :custaddr
    :accessor custaddr)
   (custgstin
    :type (string 15)
    :initarg :custgstin
    :accessor custgstin)
   (statecode
    :type (string 2)
    :initarg :statecode
    :accessor statecode)
   (billaddr
    :type (string 500)
    :initarg :billaddr
    :accessor billaddr)
   (shipaddr
    :type (string 500)
    :initarg :shipaddr
    :accessor shipaddr)
   (placeofsupply
    :type (string 50)
    :initarg :placeofsupply
    :accessor placeofsupply)
   (revcharge
    :type (string 3)
    :initarg :revcharge
    :accessor revcharge)
   (transmode
    :type (string 50)
    :initarg :transmode
    :accessor transmode)
   (vnum
    :type (string 20)
    :initarg :vnum
    :accessor vnum)
   (totalvalue
    :type float
    :initarg :totalvalue
    :accessor totalvalue)
   (totalinwords
    :type (string 255)
    :initarg :totalinwords
    :accessor totalinwords)
   (bankaccnum
    :type (string 20)
    :initarg :bankaccnum
    :accessor bankaccnum)
   (bankifsccode
    :type (string 11)
    :initarg :bankifsccode
    :accessor bankifsccode)
   (tnc
    :type (string 500)
    :initarg :tnc
    :accessor tnc)
   (authsign
    :type (string 100)
    :initarg :authsign
    :accessor authsign)

   (finyear
    :type (string 9)
    :initarg :finyear
    :accessor finyear)
   (external-url
    :type (string 512)
    :initarg :external-url
    :accessor external-url)
   (status
    :type (string 20)
    :initarg :status
    :accessor status)
   
   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state) 
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR get-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET NIL)))
  (:BASE-TABLE dod_invoice_header))
