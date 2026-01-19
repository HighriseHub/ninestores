;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defclass tax-entry ()
  ((hsn-code      :initarg :hsn-code      :accessor hsn-code)
   (taxable-value :initarg :taxable-value :initform 0 :accessor taxable-value)
   (cgst-rate     :initarg :cgst-rate     :initform 0 :accessor cgst-rate)
   (sgst-rate     :initarg :sgst-rate     :initform 0 :accessor sgst-rate)
   (igst-rate     :initarg :igst-rate     :initform 0 :accessor igst-rate)
   (cgst-amount   :initarg :cgst-amount   :initform 0 :accessor cgst-amount)
   (sgst-amount   :initarg :sgst-amount   :initform 0 :accessor sgst-amount)
   (igst-amount   :initarg :igst-amount   :initform 0 :accessor igst-amount))
  (:documentation "Represents a single row in the HSN summary table."))

(defclass gst-breakdown ()
  ((entries       :initform (make-hash-table :test 'equal) :accessor entries)
   (is-interstate :initarg :is-interstate :initform nil   :accessor interstate-p))
  (:documentation "A container that groups taxes by HSN and Rate."))

(defgeneric add-item-to-tax-breakdown (breakdown item)
  (:documentation "Processes an InvoiceItem and aggregates it into the breakdown summary."))

(defgeneric remove-item-from-tax-breakdown (breakdown item)
  (:documentation "Subtracts an InvoiceItem's values from the breakdown summary."))

(defgeneric update-item-in-tax-breakdown (breakdown old-item new-item)
  (:documentation "Adjusts the breakdown when an item is modified."))

(defgeneric get-sorted-tax-summary (breakdown)
  (:documentation "Returns the tax entries as a list sorted by HSN code."))



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


