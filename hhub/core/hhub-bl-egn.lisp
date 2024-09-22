;; -*- mode: common-lisp; coding: utf-8 -*-%
(in-package :hhub)

;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.
;; DO NOT COMPILE THIS FILE USING CTRL + C CTRL + K (OR CTRL + CK)
;; DO NOT ADD THIS FILE TO COMPILE.LISP FOR MASS COMPILATION. 


(defmethod ProcessCreateRequest ((adapter xxxxAdapter) (requestmodel xxxxRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'xxxxService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas xxxxDBService) (bo xxxx))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'xxxx)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))



(defmethod doCreate ((service xxxxService) (requestmodel xxxxRequestModel))
  (let* ((xxxxdbservice (make-instance 'xxxxDBService))
	 (vendor (vendor requestmodel))
	 (company (company requestmodel))
	 (customer (customer requestmodel))
	 (fieldA (fieldA requestmodel))
	 (fieldB (fieldB requestmodel))
	 (fieldC (fieldC requestmodel))
	 (fieldD (fieldD requestmodel))
	 (fieldE (fieldE requestmodel))
	 (fieldF (fieldF requestmodel))
	 (fieldG (fieldG requestmodel))
	 (fieldH (fieldH requestmodel))
	 (fieldI (fieldI requestmodel))
	 (fieldJ (fieldJ requestmodel))
	 (fieldK (fieldK requestmodel))
	 (fieldL (fieldL requestmodel))
	 (fieldM (fieldM requestmodel))
	 (fieldN (fieldN requestmodel))
	 (fieldO (fieldO requestmodel))
	 (fieldP (fieldP requestmodel))
	 (fieldQ (fieldQ requestmodel))
	 (fieldR (fieldR requestmodel))
	 (fieldS (fieldS requestmodel))
	 (domainobj (createxxxxobject fieldA fieldB fieldC fieldD fieldE fieldF fieldG fieldH fieldI fieldJ fieldK fieldL fieldM fieldN fieldO fieldP fieldQ fieldR fieldS)))
         ;; Initialize the DB Service
    (init xxxxdbservice domainobj)
    (copy-businessobject-to-dbobject xxxxdbservice)
    (db-save xxxxdbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createxxxxobject (fieldA fieldB fieldC fieldD fieldE fieldF fieldG fieldH fieldI vendor customer company)
  (let* ((domainobj  (make-instance 'xxxx 
				       :fieldA fieldA
				       :fieldB fieldB
				       :fieldC fieldC
				       :fieldD fieldD
				       :fieldE fieldE
				       :fieldF fieldF
				       :fieldG fieldG
				       :fieldH fieldH
				       :fieldI fieldI
				       :fieldJ fieldJ
				       :fieldK fieldK 
				       :fieldL fieldL
				       :fieldM fieldM
				       :fieldN fieldN
				       :fieldO fieldO
				       :fieldP fieldP
				       :fieldQ fieldQ
				       :fieldR fieldR
				       :fieldS fieldS
				       :deleted-state "N"
				       :active-flag "Y"
				       :vendor vendor
				       :customer customer
				       :company company)))
    domainobj))

(defmethod Copy-BusinessObject-To-DBObject ((dbas xxxxDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyxxxx-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copyxxxx-domaintodb (source destination) 
  (let ((vendor (slot-value source 'vendor))
	(customer (slot-value source 'customer))
	(company (slot-value source 'company)))
    (with-slots (fieldA fieldB fieldC fieldD fieldE fieldF fieldG fieldH fieldI fieldJ fieldK fieldL fieldM fieldN fieldO fieldP fieldQ fieldR fieldS customer-id vendor-id tenant-id) destination
      (setf vendor-id (slot-value vendor 'row-id))
      (setf tenant-id (slot-value company 'row-id))
      (setf customer-id (slot-value customer 'row-id))
      (setf fieldA (slot-value source 'fieldA))
      (setf fieldB (slot-value source 'fieldB))
      (setf fieldC (slot-value source 'fieldC))
      (setf fieldD (slot-value source 'fieldD))
      (setf fieldE (slot-value source 'fieldE))
      (setf fieldF (slot-value source 'fieldF))
      (setf fieldG (slot-value source 'fieldG))
      (setf fieldH (slot-value source 'fieldH))
      (setf fieldI (slot-value source 'fieldI))
      (setf fieldJ (slot-value source 'fieldJ))
      (setf fieldK (slot-value source 'fieldK))
      (setf fieldL (slot-value source 'fieldL))
      (setf fieldM (slot-value source 'fieldM))
      (setf fieldN (slot-value source 'fieldN))
      (setf fieldO (slot-value source 'fieldO))
      (setf fieldP (slot-value source 'fieldP))
      (setf fieldQ (slot-value source 'fieldQ))
      (setf fieldR (slot-value source 'fieldR))
      (setf fieldS (slot-value source 'fieldS))
      destination)))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter xxxxAdapter) (requestmodel xxxxRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'xxxxService))
  ;; call the parent ProcessUpdate
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter xxxxAdapter) (requestmodel xxxxRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'xxxxService))
  (call-next-method))

(defmethod doreadall ((service xxxxService) (requestmodel xxxxRequestModel))
  (let* ((vend (vendor requestmodel))
	 (comp (company requestmodel))
	 (cust (customer requestmodel))
	 (domainobjlst (select-multiple-objects-func cust  vend comp)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance 'xxxx)))
		(copyxxxx-dbtodomain object domainobject))) domainobjlst)))


(defmethod CreateViewModel ((presenter xxxxPresenter) (responsemodel xxxxResponseModel))
  (let ((viewmodel (make-instance 'xxxxViewModel)))
    (with-slots (fieldA fieldB fieldC fieldD fieldE fieldF fieldG fieldH fieldI fieldJ fieldK fieldL fieldM fieldN fieldO fieldP fieldQ fieldR fieldS vendor customer company created) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel 'fieldA) fieldA)
      (setf (slot-value viewmodel 'fieldB) fieldB)
      (setf (slot-value viewmodel 'fieldC fieldC)
      (setf (slot-value viewmodel 'fieldD) fieldD)
      (setf (slot-value viewmodel 'fieldE) fieldE)
      (setf (slot-value viewmodel 'fieldF) fieldF)
      (setf (slot-value viewmodel 'fieldG) fieldG)
      (setf (slot-value viewmodel 'fieldH) fieldH)
      (setf (slot-value viewmodel 'fieldI) fieldI)
      (setf (slot-value viewmodel 'fieldJ) fieldJ)
      (setf (slot-value viewmodel 'fieldK) fieldK)
      (setf (slot-value viewmodel 'fieldL) fieldL)
      (setf (slot-value viewmodel 'fieldM fieldM)
      (setf (slot-value viewmodel 'fieldN) fieldN)
      (setf (slot-value viewmodel 'fieldO) fieldO)
      (setf (slot-value viewmodel 'fieldP) fieldP)
      (setf (slot-value viewmodel 'fieldQ) fieldQ)
      (setf (slot-value viewmodel 'fieldR) fieldR)
      (setf (slot-value viewmodel 'fieldS) fieldS)
      (setf (slot-value viewmodel 'company) company)
      (setf (slot-value viewmodel 'created) created)
      viewmodel))))
  

(defmethod ProcessResponse ((adapter xxxxAdapter) (busobj xxxx))
  (let ((responsemodel (make-instance 'xxxxResponseModel)))
    (createresponsemodel adapter busobj responsemodel)))

(defmethod ProcessResponseList ((adapter xxxxAdapter) xxxxlist)
  (mapcar (lambda (doaminobj)
	    (let ((responsemodel (make-instance 'xxxxResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) xxxxlist))

(defmethod CreateAllViewModel ((presenter xxxxPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod CreateResponseModel ((adapter xxxxAdapter) (source xxxx) (destination xxxxResponseModel))
  :description "source = xxxx destination = xxxxResponseModel"
  (with-slots (fieldA fieldB fieldC fieldD fieldE fieldF fieldG fieldH fieldI fieldJ fieldK fieldL fieldM fieldN fieldO fieldP fieldQ fieldR fieldS vendor customer company created) destination  
    (setf fieldA (slot-value source 'fieldA))
    (setf fieldB (slot-value source 'fieldB))
    (setf fieldC (slot-value source 'fieldC))
    (setf fieldD (slot-value source 'fieldD))
    (setf fieldE (slot-value source 'fieldE))
    (setf fieldF (slot-value source 'fieldF))
    (setf fieldG (slot-value source 'fieldG))
    (setf fieldH (slot-value source 'fieldH))
    (setf fieldI (slot-value source 'fieldI))
    (setf fieldJ (slot-value source 'fieldJ))
    (setf fieldK (slot-value source 'fieldK))
    (setf fieldL (slot-value source 'fieldL))
    (setf fieldM (slot-value source 'fieldM))
    (setf fieldN (slot-value source 'fieldN))
    (setf fieldO (slot-value source 'fieldO))
    (setf fieldP (slot-value source 'fieldP))
    (setf fieldQ (slot-value source 'fieldQ))
    (setf fieldR (slot-value source 'fieldR))
    (setf fieldS (slot-value source 'fieldS))
    (setf (slot-value viewmodel 'vendor) vendor)
    (setf (slot-value viewmodel 'customer) customer)
    (setf company (slot-value source 'company))
    (setf (slot-value viewmodel 'created) created)
    destination))



(defmethod doupdate ((service xxxxService) (requestmodel xxxxRequestModel))
  (let* ((vend (vendor requestmodel))
	 (cust (customer requestmodel))
	 (xxxxdbservice (make-instance 'xxxxDBService))
	 (fieldA (fieldA requestmodel))
	 (fieldB (fieldB requestmodel))
	 (fieldC (fieldC requestmodel))
	 (fieldD (fieldD requestmodel))
	 (fieldE (fieldE requestmodel))
	 (fieldF (fieldF requestmodel))
	 (fieldG (fieldG requestmodel))
	 (fieldH (fieldH requestmodel))
	 (fieldI (fieldI requestmodel))
	 (fieldJ (fieldJ requestmodel))
	 (fieldK (fieldK requestmodel))
	 (fieldL (fieldL requestmodel))
	 (fieldM (fieldM requestmodel))
	 (fieldN (fieldN requestmodel))
	 (fieldO (fieldN requestmodel))
	 (fieldP (fieldP requestmodel))
	 (fieldQ (fieldQ requestmodel))
	 (fieldR (fieldR requestmodel))
	 (fieldS (fieldS requestmodel))
	 (comp (company requestmodel))
	 (xxxxdbobj (select-dbobject-from-database cust vend comp))
	 (domainobj (make-instance 'xxxx)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when somefield  
      (setf (slot-value xxxxdbobj 'fieldA) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldB) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldC) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldD) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldE) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldF) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldG) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldH) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldI) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldJ) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldK) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldL) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldM) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldN) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldO) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldP) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldQ) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldR) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldS) "SOMEVALUE"))


    (unless somefield  
      (setf (slot-value xxxxdbobj 'fieldA) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldB) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldC) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldD) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldE) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldF) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldG) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldH) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldI) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldJ) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldK) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldL) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldM) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldN) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldO) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldP) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldQ) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldR) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'fieldS) "SOMEVALUE"))
    ;;  FIELD UPDATE CODE ENDS HERE. 
    
    (setf (slot-value xxxxdbservice 'dbobject) xxxxdbobj)
    (setf (slot-value xxxxdbservice 'businessobject) domainobj)
    
    (setcompany xxxxdbservice comp)
    (db-save xxxxdbservice)
    ;; Return the newly created UPI domain object
    (copyxxxx-dbtodomain xxxxdbobj domainobj)))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter xxxxAdapter) (requestmodel xxxxRequestModel))
  :description "Adapter service method to read a single xxxx"
  (setf (slot-value adapter 'businessservice) (find-class 'xxxxService))
  (call-next-method))

(defmethod doread ((service xxxxService) (requestmodel xxxxRequestModel))
  (let* ((comp (company requestmodel))
	 (cust (customer requestmodel))
	 (vend (vendor requestmodel))
	 (dbxxxx (select-xxxx vend cust comp))
	 (xxxxobj (make-instance 'xxxx)))
    ;; return back a Vpaymentmethod  response model
    (setf (slot-value xxxxobj 'company) comp)
    (copyxxxx-dbtodomain dbxxxx xxxxobj)))


(defun copyxxxx-dbtodomain (source destination)
  (let* ((comp (select-company-by-id (slot-value source 'tenant-id)))
	 (vend (select-vendor-by-id (slot-value source 'vendor-id)))
	 (cust (select-customer-by-id (slot-value source 'cust-id) comp)))

    (with-slots (fieldA fieldB fieldC fieldD fieldE fieldF fieldG fieldH fieldI fieldJ fieldK fieldL fieldM fieldN fieldO fieldP fieldQ fieldR fieldS vendor customer company) destination
      (setf vendor vend)
      (setf customer cust)
      (setf company comp)
      (setf fieldA (slot-value source 'fieldA))
      (setf fieldB (slot-value source 'fieldB))
      (setf fieldC (slot-value source 'fieldC))
      (setf fieldD (slot-value source 'fieldD))
      (setf fieldE (slot-value source 'fieldE))
      (setf fieldF (slot-value source 'fieldF))
      (setf fieldG (slot-value source 'fieldG))
      (setf fieldH (slot-value source 'fieldH))
      (setf fieldI (slot-value source 'fieldI))
      (setf fieldJ (slot-value source 'fieldJ))
      (setf fieldK (slot-value source 'fieldK))
      (setf fieldL (slot-value source 'fieldL))
      (setf fieldM (slot-value source 'fieldM))
      (setf fieldN (slot-value source 'fieldN))
      (setf fieldO (slot-value source 'fieldO))
      (setf fieldP (slot-value source 'fieldP))
      (setf fieldQ (slot-value source 'fieldQ))
      (setf fieldR (slot-value source 'fieldR))
      (setf fieldS (slot-value source 'fieldS))
      destination)))
