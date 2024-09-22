;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defclass xxxxAdapter (AdapterService)
  ())

(defclass xxxxDBService (DBAdapterService)
  ())

(defclass xxxxPresenter (PresenterService)
  ())

(defclass xxxxService (BusinessService)
  ())
(defclass xxxxHTMLView (HTMLView)
  ())

(defclass xxxxViewModel (ViewModel)
  ((fieldA
    :initarg :fieldA
    :accessor fieldA)
   (fieldB
    :initarg :fieldB
    :accessor fieldB)
   (fieldC
    :initarg :fieldC
    :accessor fieldC)
   (fieldD
    :initarg :fieldD
    :accessor fieldD)
   (fieldE
    :initarg :fieldE
    :accessor fieldE)
   (fieldF
    :initarg :fieldF
    :accessor fieldF)
   (fieldG
    :initarg :fieldG
    :accessor fieldG)
   (fieldH
    :initarg :fieldH
    :accessor fieldH)
   (fieldI
    :initarg :fieldI
    :accessor fieldI)
   (fieldJ
    :initarg :fieldJ
    :accessor fieldJ)
   (fieldK
    :initarg :fieldK
    :accessor fieldK)
   (fieldL
    :initarg :fieldL
    :accessor fieldL)
   (fieldM
    :initarg :fieldM
    :accessor fieldM)
   (fieldN
    :initarg :fieldN
    :accessor fieldN)
   (fieldO
    :initarg :fieldO
    :accessor fieldO)
   (fieldP
    :initarg :fieldP
    :accessor fieldP)
   (fieldQ
    :initarg :fieldQ
    :accessor fieldQ)
   (fieldR
    :initarg :fieldR
    :accessor fieldR)
   (fieldS
    :initarg :fieldS
    :accessor fieldS)
   (company
    :initarg :company
    :accessor company)))

(defclass xxxxResponseModel (ResponseModel)
  ((fieldA
    :initarg :fieldA
    :accessor fieldA)
   (fieldB
    :initarg :fieldB
    :accessor fieldB)
   (fieldC
    :initarg :fieldC
    :accessor fieldC)
   (fieldD
    :initarg :fieldD
    :accessor fieldD)
   (fieldE
    :initarg :fieldE
    :accessor fieldE)
   (fieldF
    :initarg :fieldF
    :accessor fieldF)
   (fieldG
    :initarg :fieldG
    :accessor fieldG)
   (fieldH
    :initarg :fieldH
    :accessor fieldH)
   (fieldI
    :initarg :fieldI
    :accessor fieldI)
   (fieldJ
    :initarg :fieldJ
    :accessor fieldJ)
   (fieldK
    :initarg :fieldK
    :accessor fieldK)
   (fieldL
    :initarg :fieldL
    :accessor fieldL)
   (fieldM
    :initarg :fieldM
    :accessor fieldM)
   (fieldN
    :initarg :fieldN
    :accessor fieldN)
   (fieldO
    :initarg :fieldO
    :accessor fieldO)
   (fieldP
    :initarg :fieldP
    :accessor fieldP)
   (fieldQ
    :initarg :fieldQ
    :accessor fieldQ)
   (fieldR
    :initarg :fieldR
    :accessor fieldR)
   (fieldS
    :initarg :fieldS
    :accessor fieldS)
   (company
    :initarg :company
    :accessor company)))
   

(defclass xxxxRequestModel (RequestModel)
  ((fieldA
    :initarg :fieldA
    :accessor fieldA)
   (fieldB
    :initarg :fieldB
    :accessor fieldB)
   (fieldC
    :initarg :fieldC
    :accessor fieldC)
   (fieldD
    :initarg :fieldD
    :accessor fieldD)
   (fieldE
    :initarg :fieldE
    :accessor fieldE)
   (fieldF
    :initarg :fieldF
    :accessor fieldF)
   (fieldG
    :initarg :fieldG
    :accessor fieldG)
   (fieldH
    :initarg :fieldH
    :accessor fieldH)
   (fieldI
    :initarg :fieldI
    :accessor fieldI)
   (fieldJ
    :initarg :fieldJ
    :accessor fieldJ)
   (fieldK
    :initarg :fieldK
    :accessor fieldK)
   (fieldL
    :initarg :fieldL
    :accessor fieldL)
   (fieldM
    :initarg :fieldM
    :accessor fieldM)
   (fieldN
    :initarg :fieldN
    :accessor fieldN)
   (fieldO
    :initarg :fieldO
    :accessor fieldO)
   (fieldP
    :initarg :fieldP
    :accessor fieldP)
   (fieldQ
    :initarg :fieldQ
    :accessor fieldQ)
   (fieldR
    :initarg :fieldR
    :accessor fieldR)
   (fieldS
    :initarg :fieldS
    :accessor fieldS)
   (company
    :initarg :company
    :accessor company)))


(defclass xxxxSearchRequestModel (xxxxRequestModel)
  ())

(defclass xxxx (BusinessObject)
  ((row-id)
   (fieldA
    :initarg :fieldA
    :accessor fieldA)
   (fieldB
    :initarg :fieldB
    :accessor fieldB)
   (fieldC
    :initarg :fieldC
    :accessor fieldC)
   (fieldD
    :initarg :fieldD
    :accessor fieldD)
   (fieldE
    :initarg :fieldE
    :accessor fieldE)
   (fieldF
    :initarg :fieldF
    :accessor fieldF)
   (fieldG
    :initarg :fieldG
    :accessor fieldG)
   (fieldH
    :initarg :fieldH
    :accessor fieldH)
   (fieldI
    :initarg :fieldI
    :accessor fieldI)
   (fieldJ
    :initarg :fieldJ
    :accessor fieldJ)
   (fieldK
    :initarg :fieldK
    :accessor fieldK)
   (fieldL
    :initarg :fieldL
    :accessor fieldL)
   (fieldM
    :initarg :fieldM
    :accessor fieldM)
   (fieldN
    :initarg :fieldN
    :accessor fieldN)
   (fieldO
    :initarg :fieldO
    :accessor fieldO)
   (fieldP
    :initarg :fieldP
    :accessor fieldP)
   (fieldQ
    :initarg :fieldQ
    :accessor fieldQ)
   (fieldR
    :initarg :fieldR
    :accessor fieldR)
   (fieldS
    :initarg :fieldS
    :accessor fieldS)
   (company
    :initarg :company
    :accessor company)))


(clsql:def-view-class dod-xxxx ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)
   (fieldA
    :initarg :fieldA
    :type (string 20)
    :accessor fieldA)
   (fieldB
    :type (string 20)
    :initarg :fieldB
    :accessor fieldB)
   (fieldC
    :type (string 20)
    :initarg :fieldC
    :accessor fieldC)
   (fieldD
    :type (string 20)
    :initarg :fieldD
    :accessor fieldD)
   (fieldE
    :type (string 20)
    :initarg :fieldE
    :accessor fieldE)
   (fieldF
    :type (string 20)
    :initarg :fieldF
    :accessor fieldF)
   (fieldG
    :type (string 20)
    :initarg :fieldG
    :accessor fieldG)
   (fieldH
    :type (string 20)
    :initarg :fieldH
    :accessor fieldH)
   (fieldI
    :type (string 20)
    :initarg :fieldI
    :accessor fieldI)
   (fieldJ
    :type (string 20)
    :initarg :fieldJ
    :accessor fieldJ)
   (fieldK
    :type (string 20)
    :initarg :fieldK
    :accessor fieldK)
   (fieldL
    :type (string 20)
    :initarg :fieldL
    :accessor fieldL)
   (fieldM
    :type (string 20)
    :initarg :fieldM
    :accessor fieldM)
   (fieldN
    :type (string 20)
    :initarg :fieldN
    :accessor fieldN)
   (fieldO
    :type (string 20)
    :initarg :fieldO
    :accessor fieldO)
   (fieldP
    :type (string 20)
    :initarg :fieldP
    :accessor fieldP)
   (fieldQ
    :type (string 20)
    :initarg :fieldQ
    :accessor fieldQ)
   (fieldR
    :type (string 20)
    :initarg :fieldR
    :accessor fieldR)
   (fieldS
    :type (string 20)
    :initarg :fieldS
    :accessor fieldS)

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
  (:BASE-TABLE dod_xxxx))
