;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)


(defclass VPaymentMethodsAdapter (AdapterService)
  ())

(defclass VPaymentMethodsDBService (DBAdapterService)
  ())

(defclass VPaymentMethodsPresenter (PresenterService)
  ())

(defclass VPaymentMethodsService (BusinessService)
  ())
(defclass VPaymentMethodsHTMLView (HTMLView)
  ())

(defclass VPaymentMethodsViewModel (ViewModel)
  ((vendor
    :initarg :vendor
    :accessor vendor)))

(defclass VPaymentMethodsResponseModel (ResponseModel)
  ((vendor
    :initarg :vendor
    :accessor vendor)
   (codenabled
    :initarg :codenabled
    :accessor codenabled)
   (upienabled
    :accessor upienabled
    :initarg :upienabled)
   (payprovidersenabled
    :accessor payprovidersenabled 
    :initarg :payprovidersenabled)
   (walletenabled 
    :accessor walletenabled
    :initarg :walletenabled)
   (paylaterenabled 
    :accessor paylaterenabled
    :initarg :paylaterenabled)
   (company
    :accessor company
    :initarg :company)
   (active-flag
    :accessor active-flag
    :initarg :active-flag)
   (deleted-state
    :accessor deleted-state
    :initarg :deleted-state)))

(defclass VPaymentMethodsRequestModel (RequestModel)
  ((vendor
    :initarg :vendor
    :accessor vendor)
   (codenabled
    :initarg :codenabled
    :accessor codenabled)
   (upienabled
    :accessor upienabled
    :initarg :upienabled)
   (payprovidersenabled
    :accessor payprovidersenabled 
    :initarg :payprovidersenabled)
   (walletenabled 
    :accessor walletenabled
    :initarg :walletenabled)
   (paylaterenabled 
    :accessor paylaterenabled
    :initarg :paylaterenabled)
   (company
    :accessor company
    :initarg :company)
   (active-flag
    :accessor active-flag
    :initarg :active-flag)
   (deleted-state
    :accessor deleted-state
    :initarg :deleted-state)))


(defclass VPaymentMethods (BusinessObject)
  ((row-id)
   (vendor
    :initarg :vendor
    :accessor vendor)
   (codenabled
    :initarg :codenabled
    :accessor codenabled)
   (upienabled
    :accessor upienabled
    :initarg :upienabled)
   (payprovidersenabled
    :accessor payprovidersenabled 
    :initarg :payprovidersenabled)
   (walletenabled 
    :accessor walletenabled
    :initarg :walletenabled)
   (paylaterenabled 
    :accessor paylaterenabled
    :initarg :paylaterenabled)
   (company
    :accessor company
    :initarg :company)
   (active-flag
    :accessor active-flag
    :initarg :active-flag)
   (deleted-state
    :accessor deleted-state
    :initarg :deleted-state)))
   
  
;; DOD_VPAYMENT_METHODS
(clsql:def-view-class dod-vpayment-methods ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   (codenabled
    :accessor codenabled
    :type (string 1)
    :void-value "Y"
    :initarg :codenabled )
   (upienabled
    :accessor upienabled
    :type (string 1)
    :void-value "Y"
    :initarg :enabled )
   (payprovidersenabled
    :accessor payprovidersenabled 
    :type (string 1)
    :void-value "Y"
    :initarg :payprovidersenabled)
   (walletenabled
    :accessor walletenabled
    :type (string 1)
    :void-value "Y"
    :initarg :walletenabled )
   (paylaterenabled
    :accessor paylaterenabled
    :type (string 1)
    :void-value "Y"
    :initarg :paylaterenabled )

   (active-flag
    :accessor active-flag
    :type (string 1)
    :void-value "Y"
    :initarg :active-flag ) 

   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)
   (vendor-id
    :accessor vendor-id
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer 
    :INITARG :vendor-id)
   (vendor
    :accessor get-vendor
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-vend-profile
	      :HOME-KEY vendor-id
	      :FOREIGN-KEY row-id)
    :SET NIL)
   
   (tenant-id 
    :type integer 
    :initarg :tenant-id))
   (:BASE-TABLE DOD_VPAYMENT_METHODS))


