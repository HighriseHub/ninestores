;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun test-warehouse-DBSave (managername phone)
  (let* ((democompany (select-company-by-id 2))
	 (requestmodel (make-instance 'WarehouseRequestModel
				      :w-name  "Test Warehouse"
				      :w-addr1 "Mahalaxmi layout"
				      :w-addr2 "Near Vivekananda Women's college"
				      :w-pin "560096"
				      :w-city "Bengaluru"
				      :w-state "Karnataka"
				      :w-country "IN"
				      :w-manager managername
				      :w-phone phone
				      :w-alt-phone "9393993222"
				      :w-email "warehouse@example.com"
				      :company democompany)))
    (with-entity-create 'WarehouseAdapter requestmodel)))


(defun test-warehouses-fetch () 
  (let* ((company (select-company-by-id 2))
	 (requestmodel (make-instance 'WarehouseRequestModel)))
    (setf (slot-value requestmodel 'company) company)
    (with-entity-readall 'WarehouseAdapter requestmodel)))

(defun test-warehouse-fetch () 
  (let* ((company (select-company-by-id 2))
	 (requestmodel (make-instance 'WarehouseRequestModel)))

    (setf (slot-value requestmodel 'company) company)
    (setf (slot-value requestmodel 'w-phone) "9999339933")
    (with-entity-readall 'WarehouseAdapter requestmodel
    (with-entity-read 'WarehouseAdapter requestmodel))))
    




(defun entitycreate (entityname fieldnames destfile)
  (let* ((filecontent (hhub-read-file "~/hhubplatform/hhub/core/hhub-bl-egn.lisp")))
    
    (setf filecontent (cl-ppcre:regex-replace-all "field1" filecontent (nth 0 fieldnames)))
    (setf filecontent (cl-ppcre:regex-replace-all "field2" filecontent (nth 1 fieldnames)))
    (setf filecontent (cl-ppcre:regex-replace-all "field3" filecontent (nth 2 fieldnames)))
    (setf filecontent (cl-ppcre:regex-replace-all "field4" filecontent (nth 3 fieldnames)))
    (setf filecontent (cl-ppcre:regex-replace-all "field5" filecontent (nth 4 fieldnames)))
    (setf filecontent (cl-ppcre:regex-replace-all "field6" filecontent (nth 5 fieldnames)))
    (setf filecontent (cl-ppcre:regex-replace-all "field7" filecontent (nth 6 fieldnames)))
    (setf filecontent (cl-ppcre:regex-replace-all "field8" filecontent (nth 7 fieldnames)))
    (setf filecontent (cl-ppcre:regex-replace-all "field9" filecontent (nth 8 fieldnames)))
    (let ((temp-str (cl-ppcre:regex-replace-all "xxxx" filecontent entityname)))
      (with-open-file (stream destfile :if-exists :append :direction :output)
	(print (format stream temp-str))
	(terpri stream)))))


;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.


(defmethod ProcessCreateRequest ((adapter VPaymentMethodsAdapter) (requestmodel VPaymentMethodsRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'VPaymentMethodsService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas VPaymentMethodsDBService) (bo VPaymentMethods))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'VPaymentMethods)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))


(defmethod doreadall ((service VPaymentMethodsService) (requestmodel VPaymentMethodsRequestModel))
  (let* ((vend (vendor requestmodel))
	 (cust (customer requestmodel))
	 (comp (company requestmodel))
	 (readalllst (select-all-VPaymentMethods cust vend comp)))
    ;; return back a list of upi payments response model
    (mapcar (lambda (object)
	      (let ((domainobj (make-instance 'VPaymentMethods)))
		(copydomainobj-dbtodomain upitran upipayment))) upitranslst)))

(defmethod doCreate ((service VPaymentMethodsService) (requestmodel VPaymentMethodsRequestModel))
  (let* ((VPaymentMethodsdbservice (make-instance 'VPaymentMethodsDBService))
	 (vendor (vendor requestmodel))
	 (company (company requestmodel))
	 (customer (customer requestmodel))
	 (codenabled (codenabled requestmodel))
	 (upienabled (upienabled requestmodel))
	 (payprovidersenabled (payprovidersenabled requestmodel))
	 (walletenabled (walletenabled requestmodel))
	 (paylaterenabled (paylaterenabled requestmodel))
	 (field6 (field6 requestmodel))
	 (field7 (field7 requestmodel))
	 (field8 (field8 requestmodel))
	 (field9 (field9 requestmodel))
	 (domainobj (createVPaymentMethodsobject codenabled upienabled payprovidersenabled walletenabled paylaterenabled field6 field7 field8 field9)))
         ;; Initialize the DB Service
    (init VPaymentMethodsdbservice domainobj)
    (copy-businessobject-to-dbobject VPaymentMethodsdbservice)
    (db-save VPaymentMethodsdbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createVPaymentMethodsobject (codenabled upienabled payprovidersenabled walletenabled paylaterenabled field6 field7 field8 field9 vendor customer company)
  (let* ((domainobj  (make-instance 'VPaymentMethods 
				       :codenabled codenabled
				       :upienabled upienabled
				       :payprovidersenabled payprovidersenabled
				       :walletenabled walletenabled
				       :paylaterenabled paylaterenabled
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

(defmethod Copy-BusinessObject-To-DBObject ((dbas VPaymentMethodsDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyVPaymentMethods-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copyVPaymentMethods-domaintodb (source destination) 
  (let ((vendor (slot-value source 'vendor))
	(customer (slot-value source 'customer))
	(company (slot-value source 'company)))
    (with-slots (codenabled upienabled payprovidersenabled field 4 paylaterenabled field6 field7 field8 field9 customer-id vendor-id tenant-id) destination
      (setf vendor-id (slot-value vendor 'row-id))
      (setf tenant-id (slot-value company 'row-id))
      (setf customer-id (slot-value customer 'row-id))
      (setf codenabled (slot-value source 'codenabled))
      (setf upienabled (slot-value source 'upienabled))
      (setf payprovidersenabled (slot-value source 'payprovidersenabled))
      (setf walletenabled (slot-value source 'walletenabled))
      (setf paylaterenabled (slot-value source 'paylaterenabled))
      (setf field6 (slot-value source 'field6))
      (setf field7 (slot-value source 'field7))
      (setf field8 (slot-value source 'field8))
      (setf field9 (slot-value source 'field9))
    destination)))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter VPaymentMethodsAdapter) (requestmodel VPaymentMethodsRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'VPaymentMethodsService))
  ;; call the parent ProcessUpdate
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter VPaymentMethodsAdapter) (requestmodel VPaymentMethodsRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'VPaymentMethodsService))
  (call-next-method))

(defmethod doreadall ((service VPaymentMethodsService) (requestmodel VPaymentMethodsRequestModel))
  (let* ((vend (vendor requestmodel))
	 (comp (company requestmodel))
	 (cust (customer requestmodel))
	 (domainobjlst (select-multiple-objects-func cust  vend comp)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance 'VPaymentMethods)))
		(copyVPaymentMethods-dbtodomain object domainobject))) domainobjlst)))


(defmethod CreateViewModel ((presenter VPaymentMethodsPresenter) (responsemodel VPaymentMethodsResponseModel))
  (let ((viewmodel (make-instance 'VPaymentMethodsViewModel)))
    (with-slots (codenabled upienabled payprovidersenabled walletenabled paylaterenabled field6 field7 field8 field9 vendor customer company created) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel 'codenabled) codenabled)
      (setf (slot-value viewmodel 'upienabled) upienabled)
      (setf (slot-value viewmodel 'payprovidersenabled payprovidersenabled)
      (setf (slot-value viewmodel 'walletenabled) walletenabled)
      (setf (slot-value viewmodel 'paylaterenabled) paylaterenabled)
      (setf (slot-value viewmodel 'field6) field6)
      (setf (slot-value viewmodel 'field7) field7)
      (setf (slot-value viewmodel 'field8) field8)
      (setf (slot-value viewmodel 'field9) field9)
      (setf (slot-value viewmodel 'company) company)
      (setf (slot-value viewmodel 'created) created)
      viewmodel))))
  

(defmethod ProcessResponseList ((adapter VPaymentMethodsAdapter) VPaymentMethodslist)
  (mapcar (lambda (doaminobj)
	    (let ((responsemodel (make-instance 'VPaymentMethodsResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) VPaymentMethodslist))

(defmethod CreateAllViewModel ((presenter VPaymentMethodsPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod doupdate ((service VPaymentMethodsService) (requestmodel VPaymentMethodsRequestModel))
  (let* ((vend (vendor requestmodel))
	 (cust (customer requestmodel))
	 (VPaymentMethodsdbservice (make-instance 'VPaymentMethodsDBService))
	 (codenabled (codenabled requestmodel))
	 (upienabled (upienabled requestmodel))
	 (payprovidersenabled (payprovidersenabled requestmodel))
	 (walletenabled (walletenabled requestmodel))
	 (paylaterenabled (walletenabled requestmodel))
	 (field6 (walletenabled requestmodel))
	 (field7 (walletenabled requestmodel))
	 (field8 (walletenabled requestmodel))
	 (field9 (walletenabled requestmodel))
	 (comp (company requestmodel))
	 (VPaymentMethodsdbobj (select-dbobject-from-database cust vend comp))
	 (domainobj (make-instance 'VPaymentMethods)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when somefield  
      (setf (slot-value VPaymentMethodsdbobj 'codenabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'upienabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'payprovidersenabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'walletenabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'paylaterenabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'field6) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'field7) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'field8) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'field9) "SOMEVALUE"))

    (unless somefield  
      (setf (slot-value VPaymentMethodsdbobj 'codenabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'upienabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'payprovidersenabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'walletenabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'paylaterenabled) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'field6) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'field7) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'field8) "SOMEVALUE")
      (setf (slot-value VPaymentMethodsdbobj 'field9) "SOMEVALUE"))
    ;;  FIELD UPDATE CODE ENDS HERE. 
    
    (setf (slot-value VPaymentMethodsdbservice 'dbobject) VPaymentMethodsdbobj)
    (setf (slot-value VPaymentMethodsdbservice 'businessobject) domainobj)
    
    (setcompany VPaymentMethodsdbservice comp)
    (db-save VPaymentMethodsdbservice)
    ;; Return the newly created UPI domain object
    (copyVPaymentMethods-dbtodomain VPaymentMethodsdbobj domainobj)))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter VPaymentMethodsAdapter) (requestmodel VPaymentMethodsRequestModel))
  :description "Adapter service method to read a single VPaymentMethods"
  (setf (slot-value adapter 'businessservice) (find-class 'VPaymentMethodsService))
  (call-next-method))

(defmethod doread ((service VPaymentMethodsService) (requestmodel VPaymentMethodsRequestModel))
  (let* ((comp (company requestmodel))
	 (cust (customer requestmodel))
	 (vend (vendor requestmodel))
	 (dbVPaymentMethods (select-VPaymentMethods vend cust comp))
	 (VPaymentMethodsobj (make-instance 'VPaymentMethods)))
    ;; return back a Vpaymentmethod  response model
    (setf (slot-value VPaymentMethodsobj 'company) comp)
    (copyVPaymentMethods-dbtodomain dbVPaymentMethods VPaymentMethodsobj)))

