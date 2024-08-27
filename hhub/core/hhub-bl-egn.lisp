;; -*- mode: common-lisp; coding: utf-8 -*-
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
	 (field1 (field1 requestmodel))
	 (field2 (field2 requestmodel))
	 (field3 (field3 requestmodel))
	 (field4 (field4 requestmodel))
	 (field5 (field5 requestmodel))
	 (field6 (field6 requestmodel))
	 (field7 (field7 requestmodel))
	 (field8 (field8 requestmodel))
	 (field9 (field9 requestmodel))
	 (domainobj (createxxxxobject field1 field2 field3 field4 field5 field6 field7 field8 field9)))
         ;; Initialize the DB Service
    (init xxxxdbservice domainobj)
    (copy-businessobject-to-dbobject xxxxdbservice)
    (db-save xxxxdbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createxxxxobject (field1 field2 field3 field4 field5 field6 field7 field8 field9 vendor customer company)
  (let* ((domainobj  (make-instance 'xxxx 
				       :field1 field1
				       :field2 field2
				       :field3 field3
				       :field4 field4
				       :field5 field5
				       :field6 field6
				       :field7 field7
				       :field8 field8
				       :field9 field9
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
    (with-slots (field1 field2 field3 field4 field5 field6 field7 field8 field9 customer-id vendor-id tenant-id) destination
      (setf vendor-id (slot-value vendor 'row-id))
      (setf tenant-id (slot-value company 'row-id))
      (setf customer-id (slot-value customer 'row-id))
      (setf field1 (slot-value source 'field1))
      (setf field2 (slot-value source 'field2))
      (setf field3 (slot-value source 'field3))
      (setf field4 (slot-value source 'field4))
      (setf field5 (slot-value source 'field5))
      (setf field6 (slot-value source 'field6))
      (setf field7 (slot-value source 'field7))
      (setf field8 (slot-value source 'field8))
      (setf field9 (slot-value source 'field9))
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
    (with-slots (field1 field2 field3 field4 field5 field6 field7 field8 field9 vendor customer company created) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel 'field1) field1)
      (setf (slot-value viewmodel 'field2) field2)
      (setf (slot-value viewmodel 'field3 field3)
      (setf (slot-value viewmodel 'field4) field4)
      (setf (slot-value viewmodel 'field5) field5)
      (setf (slot-value viewmodel 'field6) field6)
      (setf (slot-value viewmodel 'field7) field7)
      (setf (slot-value viewmodel 'field8) field8)
      (setf (slot-value viewmodel 'field9) field9)
      (setf (slot-value viewmodel 'company) company)
      (setf (slot-value viewmodel 'created) created)
      viewmodel))))
  

(defmethod ProcessResponseList ((adapter xxxxAdapter) xxxxlist)
  (mapcar (lambda (doaminobj)
	    (let ((responsemodel (make-instance 'xxxxResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) xxxxlist))

(defmethod CreateAllViewModel ((presenter xxxxPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod CreateResponseModel ((adapter xxxxAdapter) (source xxxx) (destination xxxxResponseModel))
  :description "source = xxxx destination = xxxxResponseModel"
  (with-slots (field1 field2 field3 field4 field5 field6 field7 field8 field9 vendor customer company created) destination  
    (setf field1 (slot-value source 'field1))
    (setf field2 (slot-value source 'field2))
    (setf field3 (slot-value source 'field3))
    (setf field4 (slot-value source 'field4))
    (setf field5 (slot-value source 'field5))
    (setf field6 (slot-value source 'field6))
    (setf field7 (slot-value source 'field7))
    (setf field8 (slot-value source 'field8))
    (setf field9 (slot-value source 'field9))
    (setf (slot-value viewmodel 'vendor) vendor)
    (setf (slot-value viewmodel 'customer) customer)
    (setf company (slot-value source 'company))
    (setf (slot-value viewmodel 'created) created)
    destination))



(defmethod doupdate ((service xxxxService) (requestmodel xxxxRequestModel))
  (let* ((vend (vendor requestmodel))
	 (cust (customer requestmodel))
	 (xxxxdbservice (make-instance 'xxxxDBService))
	 (field1 (field1 requestmodel))
	 (field2 (field2 requestmodel))
	 (field3 (field3 requestmodel))
	 (field4 (field4 requestmodel))
	 (field5 (field4 requestmodel))
	 (field6 (field4 requestmodel))
	 (field7 (field4 requestmodel))
	 (field8 (field4 requestmodel))
	 (field9 (field4 requestmodel))
	 (comp (company requestmodel))
	 (xxxxdbobj (select-dbobject-from-database cust vend comp))
	 (domainobj (make-instance 'xxxx)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when somefield  
      (setf (slot-value xxxxdbobj 'field1) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field2) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field3) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field4) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field5) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field6) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field7) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field8) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field9) "SOMEVALUE"))

    (unless somefield  
      (setf (slot-value xxxxdbobj 'field1) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field2) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field3) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field4) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field5) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field6) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field7) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field8) "SOMEVALUE")
      (setf (slot-value xxxxdbobj 'field9) "SOMEVALUE"))
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

    (with-slots (field1 field2 field3 field4 field5 field6 field7 field8 field9 vendor customer company) destination
      (setf vendor vend)
      (setf customer cust)
      (setf company comp)
      (setf field1 (slot-value source 'field1))
      (setf field2 (slot-value source 'field2))
      (setf field3 (slot-value source 'field3))
      (setf field4 (slot-value source 'field4))
      (setf field5 (slot-value source 'field5))
      (setf field6 (slot-value source 'field6))
      (setf field7 (slot-value source 'field7))
      (setf field8 (slot-value source 'field8))
      (setf field9 (slot-value source 'field9))
      destination)))
