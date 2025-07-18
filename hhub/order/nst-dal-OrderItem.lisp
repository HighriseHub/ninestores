;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defclass OrderItemsAdapter (AdapterService)
  ())

(defclass OrderItemsDBService (DBAdapterService)
  ())

(defclass OrderItemsPresenter (PresenterService)
  ())

(defclass OrderItemsService (BusinessService)
  ())
(defclass OrderItemsHTMLView (HTMLView)
  ())

(defclass OrderItemsViewModel (ViewModel)
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

(defclass OrderItemsResponseModel (ResponseModel)
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
   

(defclass OrderItemsRequestModel (RequestModel)
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


(defclass OrderItemsSearchRequestModel (OrderItemsRequestModel)
  ())

(defclass OrderItems (BusinessObject)
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
    :type integer
    :initarg :row-id)
   
   (order-id
    :accessor odt-order-id
    :TYPE integer
    :initarg :order-id)
   (orderobject 
    :accessor odt-orderobject 
    :db-kind :join
    :db-info (:join-class dod-order
	      :home-key order-id 
	      :foreign-key row-id
		       :set nil))
   
   (prd-id
    :accessor odt-prd-id
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer
    :initarg :prd-id)
   
   (productobject
    :ACCESSOR get-odt-product
    :db-kind :join
    :db-info (:join-class dod-prd-master
	      :home-key prd-id
	      :foreign-key row-id
	      :set nil))

   
   
   (vendor-id
    :accessor odt-vendor-id
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
   

   
   (prd-qty
    :accessor odt-product-qty
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer
    :initarg :prd-qty)

   
   (unit-price
    :accessor get-unit-price
    :db-constraints :not-null
    :type float
    :initarg :unit-price)

   (cgst
    :accessor cgst
    :type float
    :initarg :cgst)

   (sgst
    :accessor sgst
    :type float
    :initarg :sgst)

   (igst
    :accessor igst
    :type float
    :initarg :igst)

   (disc-rate
    :accessor disc-rate
    :type float
    :initarg :disc-rate)

   (addl-tax1-rate
    :accessor addl-tax1-rate
    :type float
    :initarg :addl-tax1-rate)

   (comments
    :accessor comments
    :type (string 250)
    :initarg :comments)
   
   (fulfilled
    :type (string 1)
    :void-value "N"
    :initarg :fulfilled)
   

   (status 
    :accessor odt-status
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 3)
    :initarg :status)
   
   
   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)

    (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR customer-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	      :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET nil)))

   
  (:BASE-TABLE dod_order_items))



