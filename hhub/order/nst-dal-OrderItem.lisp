;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defclass OrderItemAdapter (AdapterService)
  ())

(defclass OrderItemDBService (DBAdapterService)
  ())

(defclass OrderItemPresenter (PresenterService)
  ())

(defclass OrderItemService (BusinessService)
  ())
(defclass OrderItemHTMLView (HTMLView)
  ())

(defclass OrderItemViewModel (ViewModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (order
    :initarg :order
    :accessor order)
   (product
    :initarg :product
    :accessor product)
   (vendor
    :initarg :vendor
    :accessor vendor)
   (prd-qty
    :initarg :prd-qty
    :accessor prd-qty)
   (unit-price
    :initarg :unit-price
    :accessor unit-price)
   (disc-rate
    :initarg :disc-rate
    :accessor disc-rate)
   (taxablevalue
    :initarg :taxablevalue
    :accessor taxablevalue)
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt)
   (igstamt
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval)

   (cgst
    :initarg :cgst
    :accessor cgst)
   (sgst
    :initarg :sgst
    :accessor sgst)
   (igst
    :initarg :igst
    :accessor igst)
   (addl-tax1-rate
    :initarg :addl-tax1-rate
    :accessor addl-tax1-rate)
   (comments
    :initarg :comments
    :accessor comments)
   (fulfilled
    :initarg :fulfilled
    :accessor fulfilled)
   (status
    :initarg :status
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (company
    :initarg :company
    :accessor company)))

(defclass OrderItemResponseModel (ResponseModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (order
    :initarg :order
    :accessor order)
   (product
    :initarg :product
    :accessor product)
   (vendor
    :initarg :vendor
    :accessor vendor)
   (prd-qty
    :initarg :prd-qty
    :accessor prd-qty)
   (unit-price
    :initarg :unit-price
    :accessor unit-price)
   (disc-rate
    :initarg :disc-rate
    :accessor disc-rate)
   (taxablevalue
    :initarg :taxablevalue
    :accessor taxablevalue)
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt)
   (igstamt
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval)

   (cgst
    :initarg :cgst
    :accessor cgst)
   (sgst
    :initarg :sgst
    :accessor sgst)
   (igst
    :initarg :igst
    :accessor igst)
   (addl-tax1-rate
    :initarg :addl-tax1-rate
    :accessor addl-tax1-rate)
   (comments
    :initarg :comments
    :accessor comments)
   (fulfilled
    :initarg :fulfilled
    :accessor fulfilled)
   (status
    :initarg :status
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (company
    :initarg :company
    :accessor company)))
   

(defclass OrderItemRequestModel (RequestModel)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (order
    :initarg :order
    :accessor order)
   (product
    :initarg :product
    :accessor product)
   (vendor
    :initarg :vendor
    :accessor vendor)
   (prd-qty
    :initarg :prd-qty
    :accessor prd-qty)
   (unit-price
    :initarg :unit-price
    :accessor unit-price)
   (disc-rate
    :initarg :disc-rate
    :accessor disc-rate)
   (taxablevalue
    :initarg :taxablevalue
    :accessor taxablevalue)
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt)
   (igstamt
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval)

   (cgst
    :initarg :cgst
    :accessor cgst)
   (sgst
    :initarg :sgst
    :accessor sgst)
   (igst
    :initarg :igst
    :accessor igst)
   (addl-tax1-rate
    :initarg :addl-tax1-rate
    :accessor addl-tax1-rate)
   (comments
    :initarg :comments
    :accessor comments)
   (fulfilled
    :initarg :fulfilled
    :accessor fulfilled)
   (status
    :initarg :status
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (company
    :initarg :company
    :accessor company)))


(defclass OrderItemSearchRequestModel (OrderItemRequestModel)
  ())

(defclass OrderItem (BusinessObject)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (order
    :initarg :order
    :accessor order)
   (product
    :initarg :product
    :accessor product)
   (vendor
    :initarg :vendor
    :accessor vendor)
   (prd-qty
    :initarg :prd-qty
    :accessor prd-qty)
   (unit-price
    :initarg :unit-price
    :accessor unit-price)
   (disc-rate
    :initarg :disc-rate
    :accessor disc-rate)
   (taxablevalue
    :initarg :taxablevalue
    :accessor taxablevalue)
   (cgstamt
    :initarg :cgstamt
    :accessor cgstamt)
   (sgstamt
    :initarg :sgstamt
    :accessor sgstamt)
   (igstamt
    :initarg :igstamt
    :accessor igstamt)
   (totalitemval
    :initarg :totalitemval
    :accessor totalitemval)

   (cgst
    :initarg :cgst
    :accessor cgst)
   (sgst
    :initarg :sgst
    :accessor sgst)
   (igst
    :initarg :igst
    :accessor igst)
   (addl-tax1-rate
    :initarg :addl-tax1-rate
    :accessor addl-tax1-rate)
   (comments
    :initarg :comments
    :accessor comments)
   (fulfilled
    :initarg :fulfilled
    :accessor fulfilled)
   (status
    :initarg :status
    :accessor status)
   (deleted-state
    :initarg :deleted-state
    :accessor deleted-state)
   (company
    :initarg :company
    :accessor company)))


(clsql:def-view-class dod-order-items ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :column "ROW_ID"
    :type integer
    :initarg :row-id)

   ;; --- Relationships (Joins) ---
   (order-id
    :type integer
    :column "ORDER_ID"
    :db-constraints :not-null
    :initarg :order-id)
   (order
    :accessor get-order
    :db-kind :join
    :db-info (:join-class dod-order
              :home-key order-id
              :foreign-key row-id
              :set nil))

   (vendor-id
    :type integer
    :column "VENDOR_ID"
    :db-constraints :not-null
    :initarg :vendor-id)
   ;; Join to dod-vend-profile would go here
   (vendor
    :accessor get-vendor 
    :db-kind :join
    :db-info (:join-class doe-vend-profile
              :home-key order-id
              :foreign-key row-id
              :set nil))
   
   (prd-id
    :type integer
    :column "PRD_ID"
    :db-constraints :not-null
    :initarg :prd-id)
   ;; Join to dod-product would go here
   (product
    :ACCESSOR get-item-product
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-order-items
	                  :HOME-KEY prd-id
                          :FOREIGN-KEY row-id
                          :SET NIL))

   ;; --- Product & Catalog Details ---
   (hsn-code
    :type (string 8)
    :column "HSN_CODE"
    :initarg :hsn-code)
   (sac-code
    :type (string 8)
    :column "SAC_CODE"
    :initarg :sac-code)
   (item-description
    :type (string 500)
    :column "ITEM_DESCRIPTION"
    :initarg :item-description)
   (uqc
    :type (string 10)
    :column "UQC"
    :initarg :uqc)

   ;; --- Basic Pricing & Quantity ---
   (unit-price
    :type float
    :column "UNIT_PRICE"
    :initarg :unit-price)
   (mrp
    :type float
    :column "MRP"
    :initarg :mrp)
   (prd-qty
    :type integer
    :column "PRD_QTY"
    :initarg :prd-qty)

   ;; --- Tax & Discount Rates (%) ---
   (cgst
    :type float
    :column "CGST"
    :initarg :cgst-rate)
   (sgst
    :type float
    :column "SGST"
    :initarg :sgst-rate)
   (igst
    :type float
    :column "IGST"
    :initarg :igst-rate)
   (cess-rate
    :type float
    :column "CESS_RATE"
    :initarg :cess-rate)
   (disc-rate
    :type float
    :column "DISC_RATE"
    :initarg :disc-rate)
   (addl-tax1-rate
    :type float
    :column "ADDL_TAX1_RATE"
    :initarg :addl-tax1-rate)

   ;; --- Calculated Amounts ---
   (discount-amount
    :type float
    :column "DISCOUNT_AMOUNT"
    :initarg :discount-amount)
   (cgstamt
    :type float
    :column "CGSTAMT"
    :accessor cgstamt
    :initarg :cgstamt)
   (sgstamt
    :type float
    :column "SGSTAMT"
    :accessor sgstamt 
    :initarg :sgstamt)
   (igstamt
    :type float
    :column "IGSTAMT"
    :accessor igstamt 
    :initarg :igstamt)
   (cess-amount
    :type float
    :column "CESS_AMOUNT"
    :initarg :cess-amount)
   (taxablevalue
    :type float
    :column "TAXABLEVALUE"
    :initarg :taxablevalue)
   (totalitemval
    :type float
    :column "TOTALITEMVAL"
    :initarg :totalitemval)

   ;; --- Status & Compliance ---
   (fulfilled
    :type (string 1) ; 'Y'/'N'
    :column "FULFILLED"
    :initarg :fulfilled)
   (status
    :type (string 3)
    :column "STATUS"
    :initarg :status)
   (itc-eligible
    :type (string 10) ; enum('ELIGIBLE','INELIGIBLE','BLOCKED')
    :column "ITC_ELIGIBLE"
    :initarg :itc-eligible)
   (comments
    :type (string 255)
    :column "COMMENTS"
    :initarg :comments)

   ;; --- Audit & Meta ---
   (tenant-id
    :type integer
    :column "TENANT_ID"
    :initarg :tenant-id)
   (company
    :ACCESSOR get-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET NIL))
   (deleted-state
    :type (string 1)
    :column "DELETED_STATE"
    :initarg :deleted-state)
      ;; AUDIT FIELDS
   (created
    :accessor created
    :type (string 30)
    :initarg :created
    :db-kind :base)
   (updated
    :accessor updated
    :type (string 30)
    :initarg :updated
    :db-kind :base))
  (:base-table "DOD_ORDER_ITEMS"))










