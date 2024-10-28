;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defclass InvoiceItemAdapter (AdapterService)
  ())

(defclass InvoiceItemDBService (DBAdapterService)
  ())

(defclass InvoiceItemPresenter (PresenterService)
  ())

(defclass InvoiceItemService (BusinessService)
  ())
(defclass InvoiceItemHTMLView (HTMLView)
  ())

(defclass InvoiceItemViewModel (ViewModel)
  ((InvoiceHeader
    :initarg :InvoiceHeader
    :accessor InvoiceHeader)
   (prd-id
    :initarg :prd-id
    :accessor prd-id)
   (prddesc
    :initarg :prddesc
    :accessor prddesc)
   (hsncode
    :initarg :hsncode
    :accessor hsncode)
   (qty
    :initarg :qty
    :accessor qty)
   (uom
    :initarg :uom
    :accessor uom)
   (price
    :initarg :price
    :accessor price)
   (discount
    :initarg :discount
    :accessor discount)
   (taxablevalue
    :initarg :taxablevalue
    :accessor taxablevalue)
   (cgstrate
    :initarg :cgstrate
    :accessor cgstrate)
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstrate
    :initarg :sgstrate
    :accessor sgstrate)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt)
   (igstrate
    :initarg :igstrate
    :accessor igstrate)
   (igstamt
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval)
   (status
    :initarg :status
    :accessor status)
   (company
    :initarg :company
    :accessor company)))

(defclass InvoiceItemResponseModel (ResponseModel)
  ((InvoiceHeader
    :initarg :InvoiceHeader
    :accessor InvoiceHeader)
   (prd-id
    :initarg :prd-id
    :accessor prd-id)
   (prddesc
    :initarg :prddesc
    :accessor prddesc)
   (hsncode
    :initarg :hsncode
    :accessor hsncode)
   (qty
    :initarg :qty
    :accessor qty)
   (uom
    :initarg :uom
    :accessor uom)
   (price
    :initarg :price
    :accessor price)
   (discount
    :initarg :discount
    :accessor discount)
   (taxablevalue
    :initarg :taxablevalue
    :accessor taxablevalue)
   (cgstrate
    :initarg :cgstrate
    :accessor cgstrate)
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstrate
    :initarg :sgstrate
    :accessor sgstrate)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt)
   (igstrate
    :initarg :igstrate
    :accessor igstrate)
   (igstamt
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval)
   (status
    :initarg :status
    :accessor status)
   (company
    :initarg :company
    :accessor company)))
   

(defclass InvoiceItemRequestModel (RequestModel)
  ((InvoiceHeader
    :initarg :InvoiceHeader
    :accessor InvoiceHeader)
   (prd-id
    :initarg :prd-id
    :accessor prd-id)
   (prddesc
    :initarg :prddesc
    :accessor prddesc)
   (hsncode
    :initarg :hsncode
    :accessor hsncode)
   (qty
    :initarg :qty
    :accessor qty)
   (uom
    :initarg :uom
    :accessor uom)
   (price
    :initarg :price
    :accessor price)
   (discount
    :initarg :discount
    :accessor discount)
   (taxablevalue
    :initarg :taxablevalue
    :accessor taxablevalue)
   (cgstrate
    :initarg :cgstrate
    :accessor cgstrate)
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstrate
    :initarg :sgstrate
    :accessor sgstrate)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt)
   (igstrate
    :initarg :igstrate
    :accessor igstrate)
   (igstamt
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval)
   (status
    :initarg :status
    :accessor status)
   (company
    :initarg :company
    :accessor company)))


(defclass InvoiceItemSearchRequestModel (InvoiceItemRequestModel)
  ())

(defclass InvoiceItem (BusinessObject)
  ((row-id)
   (InvoiceHeader
    :initarg :InvoiceHeader
    :accessor InvoiceHeader)
   (prd-id
    :initarg :prd-id
    :accessor prd-id)
   (prddesc
    :initarg :prddesc
    :accessor prddesc)
   (hsncode
    :initarg :hsncode
    :accessor hsncode)
   (qty
    :initarg :qty
    :accessor qty)
   (uom
    :initarg :uom
    :accessor uom)
   (price
    :initarg :price
    :accessor price)
   (discount
    :initarg :discount
    :accessor discount)
   (taxablevalue
    :initarg :taxablevalue
    :accessor taxablevalue)
   (cgstrate
    :initarg :cgstrate
    :accessor cgstrate)
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstrate
    :initarg :sgstrate
    :accessor sgstrate)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt)
   (igstrate
    :initarg :igstrate
    :accessor igstrate)
   (igstamt
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval)
   (status
    :initarg :status
    :accessor status)
   (company
    :initarg :company
    :accessor company)))


(clsql:def-view-class dod-invoice-items ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)
   (invheadid
    :initarg :invheadid
    :type integer
    :accessor invheadid)
   (prd-id
    :type integer
    :initarg :prd-id
    :accessor prd-id)
   (prddesc
    :type (string 200)
    :initarg :prddesc
    :accessor prddesc)
   (hsncode
    :type (string 20)
    :initarg :hsncode
    :accessor hsncode)
   (qty
    :type integer
    :initarg :qty
    :accessor qty)
   (uom
    :type (string 20)
    :initarg :uom
    :accessor uom)
   (price
    :type float
    :initarg :price
    :accessor price)
   (discount
    :type float
    :initarg :discount
    :accessor discount)
   (taxable-value
    :type float
    :initarg :taxable-value
    :accessor taxable-value)
   (cgstrate
    :type float
    :initarg :cgstrate
    :accessor cgstrate)
   (cgstamt
    :type float
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstrate
    :type float
    :initarg :sgstrate
    :accessor sgstrate)
   (sgstamt
    :type float
    :initarg :sgstamt
    :accessor sgstamt)
   (igstrate
    :type float
    :initarg :igstrate
    :accessor igstrate)
   (igstamt
    :type float
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :type float
    :initarg :totalitemval
    :accessor totalitemval)
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
  (:BASE-TABLE dod_invoice_items))


