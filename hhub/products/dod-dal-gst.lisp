;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)



(defclass GSTHSNCodesAdapter (AdapterService)
  ())

(defclass GSTHSNCodesDBService (DBAdapterService)
  ())

(defclass GSTHSNCodesPresenter (PresenterService)
  ())

(defclass GSTHSNCodesService (BusinessService)
  ())
(defclass GSTHSNCodesHTMLView (HTMLView)
  ())

(defclass GSTHSNCodesViewModel (ViewModel)
  ((hsncode
    :initarg :hsncode
    :accessor hsncode)
   (hsncode4digit
    :initarg :hsncode4digit
    :accessor hsncode4digit)
   (description
    :initarg :description
    :accessor description)
   (cgst
    :initarg :cgst
    :accessor cgst)
   (sgst
    :initarg :sgst
    :accessor sgst)
   (igst
    :initarg :igst
    :accessor igst)
   (compcess
    :initarg :compcess
    :accessor compcess)
   (company
    :initarg :company
    :accessor company)))

(defclass GSTHSNCodesResponseModel (ResponseModel)
  ((hsncode
    :initarg :hsncode
    :accessor hsncode)
   (hsncode4digit
    :initarg :hsncode4digit
    :accessor hsncode4digit)
   (description
    :initarg :description
    :accessor description)
   (cgst
    :initarg :cgst
    :accessor cgst)
   (sgst
    :initarg :sgst
    :accessor sgst)
   (igst
    :initarg :igst
    :accessor igst)
   (compcess
    :initarg :compcess
    :accessor compcess)
   (company
    :initarg :company
    :accessor company)))


(defclass GSTHSNCodesRequestModel (RequestModel)
  ((hsncode
    :initarg :hsncode
    :accessor hsncode)
   (hsncode4digit
    :initarg :hsncode4digit
    :accessor hsncode4digit)
   (description
    :initarg :description
    :accessor description)
   (cgst
    :initarg :cgst
    :accessor cgst)
   (sgst
    :initarg :sgst
    :accessor sgst)
   (igst
    :initarg :igst
    :accessor igst)
   (compcess
    :initarg :compcess
    :accessor compcess)
   (company
    :initarg :company
    :accessor company)))

(defclass GSTHSNCodesSearchRequestModel (GSTHSNCodesRequestModel)
  ())

(defclass GSTHSNCodes (BusinessObject)
  ((row-id)
   (hsncode
    :initarg :hsncode
    :accessor hsncode)
   (hsncode4digit
    :initarg :hsncode4digit
    :accessor hsncode4digit)
   (description
    :initarg :description
    :accessor description)
   (cgst
    :initarg :cgst
    :accessor cgst)
   (sgst
    :initarg :sgst
    :accessor sgst)
   (igst
    :initarg :igst
    :accessor igst)
   (compcess
    :initarg :compcess
    :accessor compcess)
   (company
    :initarg :company
    :accessor company)))

(clsql:def-view-class dod-gst-hsn-codes ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)
   (hsn-code
    :accessor hsn-code
    :TYPE (string 10))
   (hsn-code-4digit
    :accessor hsn-code-4digit
    :type (string 4))
   
   (hsn-description
    :accessor hsn-description
    :TYPE (string 500))

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

   (comp-cess
    :accessor comp-cess
    :type float
    :initarg :comp-cess)

   (comp-cess-func
    :accessor comp-cess-func
    :TYPE (string 255))

   (gst-hsn-func
    :accessor gst-hsn-func
    :TYPE (string 255))

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
  (:BASE-TABLE dod_gst_hsn_codes))
