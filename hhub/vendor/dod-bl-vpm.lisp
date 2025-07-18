;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.


(defmethod ProcessCreateRequest ((adapter VPaymentMethodsAdapter) (requestmodel VPaymentMethodsRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Vendor Payment Methods object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'VPaymentMethodsService))
  ;; call the parent ProcessCreate
  (call-next-method))

(defmethod init ((dbas VPaymentMethodsDBService) (bo VPaymentMethods))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'dod-vpayment-methods))
	 (company (slot-value bo 'company)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the VPaymentMethods DB service 
    (setcompany dbas company)
    (call-next-method)))

(defmethod doCreate ((service VPaymentMethodsService) (requestmodel VPaymentMethodsRequestModel))
  (let* ((VPaymentMethodsdbservice (make-instance 'VPaymentMethodsDBService))
	 (vendor (vendor requestmodel))
	 (codenabled (codenabled requestmodel))
	 (upienabled (upienabled requestmodel))
	 (payprovidersenabled (payprovidersenabled requestmodel))
	 (walletenabled (walletenabled requestmodel))
	 (paylaterenabled (paylaterenabled requestmodel))
	 (company (company requestmodel))
	 (domainobj (createVPaymentMethodsobject vendor codenabled upienabled payprovidersenabled walletenabled paylaterenabled company))) 
         ;; Initialize the DB Service
    (init VPaymentMethodsdbservice domainobj)
    (copy-businessobject-to-dbobject VPaymentMethodsdbservice)
    (db-save VPaymentMethodsdbservice)
    ;; Return the newly created domain object
    domainobj))


(defun createVPaymentMethodsobject (vendor codenabled upienabled payprovidersenabled walletenabled paylaterenabled company)
  (let* ((domainobj  (make-instance 'VPaymentMethods 
				       :vendor vendor 
				       :codenabled codenabled
				       :upienabled upienabled
				       :payprovidersenabled payprovidersenabled
				       :walletenabled walletenabled
				       :paylaterenabled paylaterenabled
				       :deleted-state "N"
				       :active-flag "Y"
				       :company company)))
    domainobj))



(defmethod Copy-BusinessObject-To-DBObject ((dbas VPaymentMethodsDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyVPaymentMethods-domaintodb domainobj dbobj))))

(defun copyVPaymentMethods-domaintodb (source destination) ;; source = domain destination = db
  (let ((vendor (slot-value source 'vendor))
	(company (slot-value source 'company)))
    (with-slots (vendor-id codenabled upienabled payprovidersenabled walletenabled paylaterenabled  deleted-state active-flag tenant-id) destination
      (setf vendor-id (slot-value vendor 'row-id))
      (setf codenabled (slot-value source 'codenabled))
      (setf upienabled (slot-value source 'upienabled))
      (setf payprovidersenabled (slot-value source 'payprovidersenabled))
      (setf walletenabled (slot-value source 'walletenabled))
      (setf paylaterenabled (slot-value source 'paylaterenabled))
      (setf tenant-id (slot-value company 'row-id))
      (setf deleted-state (slot-value source 'deleted-state))
      (setf active-flag (slot-value source 'active-flag))
      destination)))
  

;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter VPaymentMethodsAdapter) (requestmodel VPaymentMethodsRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'VPaymentMethodsService))
  ;; call the parent ProcessUpdate
  (call-next-method))

(defmethod doupdate ((service VPaymentMethodsService) (requestmodel VPaymentMethodsRequestModel))
  (let* ((vend (vendor requestmodel))
	 (comp (company requestmodel))
	 (codenabled (codenabled requestmodel))
	 (upienabled (upienabled requestmodel))
	 (payprovidersenabled (payprovidersenabled requestmodel))
	 (walletenabled (walletenabled requestmodel))
	 (paylaterenabled (paylaterenabled requestmodel))
	 (vpaymentmethodsdbservice (make-instance 'VPaymentMethodsDBService))
	 (vpaymentmethodsdbobj (select-vpayment-methods vend comp))
	 (vpaymentmethodsobj (make-instance 'VPaymentMethods)))
    
    (setf (slot-value vpaymentmethodsdbobj 'codenabled) codenabled)
    (setf (slot-value vpaymentmethodsdbobj 'upienabled) upienabled)
    (setf (slot-value vpaymentmethodsdbobj 'payprovidersenabled) payprovidersenabled)
    (setf (slot-value vpaymentmethodsdbobj 'walletenabled) walletenabled)
    (setf (slot-value vpaymentmethodsdbobj 'paylaterenabled) paylaterenabled)
  
    (setf (slot-value vpaymentmethodsdbservice 'dbobject) vpaymentmethodsdbobj)
    (setf (slot-value vpaymentmethodsdbservice 'businessobject) vpaymentmethodsobj)
    
    (setcompany vpaymentmethodsdbservice comp)
    (db-save vpaymentmethodsdbservice)
    ;; Return the newly created vendor payment methods domain object
    (copyvpaymentmethods-dbtodomain vpaymentmethodsdbobj vpaymentmethodsobj)))


;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter VPaymentMethodsAdapter) (requestmodel VPaymentMethodsRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'VPaymentMethodsService))
  (call-next-method))

(defmethod doreadall ((service VPaymentMethodsService) (requestmodel VPaymentMethodsRequestModel))
  (let* ((vend (vendor requestmodel))
	 (comp (company requestmodel))
	 (domainobjlst (select-allvpayment-methods vend comp)))
    ;; return back a list of VpaymentMethods business objects 
    (mapcar (lambda (object)
	      (let ((vpaymentmethod (make-instance 'VPaymentMethods)))
		(copyvpaymentmethods-dbtodomain object vpaymentmethod))) domainobjlst)))

(defmethod ProcessReadRequest ((adapter VPaymentMethodsAdapter) (requestmodel VPaymentMethodsRequestModel))
  :description "Adapter service method to read a single VPaymentMethods"
  (setf (slot-value adapter 'businessservice) (find-class 'VPaymentMethodsService))
  (call-next-method))

(defmethod doread ((service VPaymentMethodsService) (requestmodel VPaymentMethodsRequestModel))
  (let* ((comp (company requestmodel))
	 (vend (vendor requestmodel))
	 (dbvpaymentmethods (select-vpayment-methods vend comp))
	 (vpaymentmethodsobj (make-instance 'VPaymentMethods)))
    ;; return back a Vpaymentmethod  response model
    (setf (slot-value vpaymentmethodsobj 'company) comp)
    (when dbvpaymentmethods
      (copyvpaymentmethods-dbtodomain dbvpaymentmethods vpaymentmethodsobj))))

(defun copyvpaymentmethods-dbtodomain (source destination)
  (let* ((comp (select-company-by-id (slot-value source 'tenant-id)))
	 (vend (select-vendor-by-id (slot-value source 'vendor-id))))
    (with-slots (vendor codenabled upienabled payprovidersenabled walletenabled paylaterenabled  deleted-state active-flag company) destination 
      (setf vendor vend)
      (setf company comp)
      (setf codenabled (slot-value source 'codenabled))
      (setf upienabled (slot-value source 'upienabled))
      (setf payprovidersenabled (slot-value source 'payprovidersenabled))
      (setf walletenabled (slot-value source 'walletenabled))
      (setf paylaterenabled (slot-value source 'paylaterenabled))
      (setf deleted-state (slot-value source 'deleted-state))
      (setf active-flag (slot-value source 'active-flag))
      destination)))

(defun select-vpayment-methods (vend company)
  (let ((tenant-id (slot-value company 'row-id))
	(vendor-id (slot-value vend 'row-id)))
    (car (clsql:select 'dod-vpayment-methods  :where
		[and 
		[= [:deleted-state] "N"]
		[= [:vendor-id] vendor-id]
		[= [:tenant-id] tenant-id]] :order-by '(([row-id] :desc)) 
					 :caching *dod-database-caching* :flatp t))))

(defun select-allvpayment-methods (vend company)
  (let ((tenant-id (slot-value company 'row-id))
	(vendor-id (slot-value vend 'row-id)))
    (clsql:select 'dod-vpayment-methods  :where
		  [and 
		  [= [:deleted-state] "N"]
		  [= [:vendor-id] vendor-id]
		  [= [:tenant-id] tenant-id]] :order-by '(([row-id] :desc)) 
					 :caching *dod-database-caching* :flatp t)))


