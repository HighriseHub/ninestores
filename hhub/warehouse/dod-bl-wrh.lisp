;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

;; METHODS FOR WAREHOUSE CREATE 

(defmethod ProcessCreateRequest ((adapter WarehouseAdapter) (requestmodel WarehouseRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'WarehouseService))
  ;; call the parent ProcessCreate
  (call-next-method))

(defmethod init ((dbas WarehouseDBService) (bo Warehouse))
  :description "Set the DB object and domain object"
  (let* ((WarehouseDBObj  (make-instance 'dod-warehouse)))
    (setf (slot-value WarehouseDBObj 'deleted-state) "N")
    (setf (slot-value WarehouseDBObj 'active-flag) "Y")
    (setf (dbobject dbas) WarehouseDBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))

(defmethod doCreate ((service WarehouseService) (requestmodel WarehouseRequestModel))
  (let* ((name (w-name requestmodel))
	 (wrhdbservice (make-instance 'WarehouseDBService))
	 (addr1 (w-addr1 requestmodel))
	 (addr2 (w-addr2 requestmodel))
	 (zipcode (w-pin requestmodel))
	 (city  (w-city requestmodel))
	 (state (w-state requestmodel))
	 (manager (w-manager requestmodel))
	 (phone (w-phone requestmodel))
	 (email (w-email requestmodel))
	 (alt-phone (w-alt-phone requestmodel))
	 (company (company requestmodel))
	 (warehouseobj (createwarehouseobject name addr1 addr2 zipcode city state "IN" manager phone alt-phone email company)))
    
     ;; Initialize the DB Service
    (init wrhdbservice warehouseobj)
    (copy-businessobject-to-dbobject wrhdbservice)
    (db-save wrhdbservice)
    ;; Return the newly created warehouse domain object
    warehouseobj))


(defun createwarehouseobject (name addr1 addr2 zipcode city state country manager phone alt-phone email company)
  (let* ((warehouseobj  (make-instance 'Warehouse 
				       :w-name name
				       :w-addr1 addr1
				       :w-addr2 addr2
				       :w-pin zipcode
				       :w-city city
				       :w-state state 
				       :w-country country 
				       :w-manager manager
				       :w-phone phone 
				       :w-alt-phone alt-phone
				       :w-email email
				       :company company)))
    warehouseobj))



(defmethod Copy-BusinessObject-To-DBObject ((dbas WarehouseDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(warehouseobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copywarehouse-domaintodb warehouseobj dbobj))))




(defun copywarehouse-domaintodb (source destination) ;; source = domain destination = db
  (with-slots (w-name w-addr1 w-addr2 w-pin w-city w-state w-country w-manager w-phone w-alt-phone w-email) destination
    (setf w-name  (slot-value source 'w-name))
    (setf w-addr1  (slot-value source 'w-addr1))
    (setf w-addr2  (slot-value source 'w-addr2))
    (setf w-pin  (slot-value source 'w-pin))
    (setf w-city  (slot-value source 'w-city))
    (setf w-state  (slot-value source 'w-state))
    (setf w-country  (slot-value source 'w-country))
    (setf w-manager  (slot-value source 'w-manager))
    (setf w-phone  (slot-value source 'w-phone))
    (setf w-alt-phone  (slot-value source 'w-alt-phone))
    (setf w-email  (slot-value source 'w-email))
    destination))


;; METHODS FOR WAREHOUSE READ

(defmethod ProcessReadAllRequest ((adapter WarehouseAdapter) (requestmodel WarehouseRequestModel))
  :description "Adapter service method to read the warehouses"
  (setf (slot-value adapter 'businessservice) (find-class 'WarehouseService))
  (call-next-method))

(defmethod doreadall ((service WarehouseService) (requestmodel WarehouseRequestModel))
  (let* ((comp (company requestmodel))
	 (dbwarehouses (select-warehouses comp)))
    ;; return back a list of warehouses response model
    (mapcar (lambda (dbwarehouseobj)
	      (let ((warehouseobj (make-instance 'Warehouse)))
		(setf (slot-value warehouseobj 'company) comp)
		(copywarehouse-dbtodomain dbwarehouseobj warehouseobj))) dbwarehouses)))

(defmethod ProcessReadRequest ((adapter WarehouseAdapter) (requestmodel WarehouseRequestModel))
  :description "Adapter service method to read a single warehouse"
  (setf (slot-value adapter 'businessservice) (find-class 'WarehouseService))
  (call-next-method))

(defmethod doread ((service WarehouseService) (requestmodel WarehouseRequestModel))
  (let* ((comp (company requestmodel))
	 (phone (w-phone requestmodel))
	 (dbwarehouse (select-warehouse-by-manager phone comp))
	 (warehouseobj (make-instance 'Warehouse)))
    ;; return back a list of warehouses response model
    (setf (slot-value warehouseobj 'company) comp)
    (copywarehouse-dbtodomain dbwarehouse warehouseobj)))
    

(defmethod Copy-DbObject-To-BusinessObject ((dbas WarehouseDBService))
  :description "Syncs the dbobject and domain object"
  (let ((dbobj (slot-value dbas 'dbobject))
	(warehouseobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'businessobject) (copywarehouse-dbtodomain dbobj warehouseobj))))

(defun copywarehouse-dbtodomain (source destination)
  (with-slots (w-name w-addr1 w-addr2 w-pin w-city w-state w-country w-manager w-phone w-alt-phone w-email) destination
    (setf w-name  (slot-value source 'w-name))
    (setf w-addr1  (slot-value source 'w-addr1))
    (setf w-addr2  (slot-value source 'w-addr2))
    (setf w-pin  (slot-value source 'w-pin))
    (setf w-city  (slot-value source 'w-city))
    (setf w-state  (slot-value source 'w-state))
    (setf w-country  (slot-value source 'w-country))
    (setf w-manager  (slot-value source 'w-manager))
    (setf w-phone  (slot-value source 'w-phone))
    (setf w-alt-phone  (slot-value source 'w-alt-phone))
    (setf w-email  (slot-value source 'w-email))
    destination))

(defun select-warehouses (company)
  (let ((tenant-id (slot-value company 'row-id)))
    (clsql:select 'dod-warehouse  :where
		[and 
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]]
     :caching *dod-database-caching* :flatp t )))

(defun select-warehouse-by-manager (phone company)
  (let ((tenant-id (slot-value company 'row-id)))
    (car (clsql:select 'dod-warehouse  :where
		  [and 
		  [= [:deleted-state] "N"]
		  [= [:w-phone] phone]
		  [= [:tenant-id] tenant-id]]
		  :caching *dod-database-caching* :flatp t ))))
  

;; Warehouse methods for viewmodel and presenter
(defmethod CreateViewModel ((presenter WarehousePresenter) (responsemodel WarehouseResponseModel))
  (let ((viewmodel (make-instance 'WarehouseViewModel)))
    (with-slots (w-name w-addr1 w-addr2 w-pin w-city w-state w-country w-manager w-phone w-alt-phone w-email) responsemodel
      (setf (slot-value viewmodel 'w-name) w-name)
      (setf (slot-value viewmodel 'w-addr1) w-addr1)
      (setf (slot-value viewmodel 'w-addr2) w-addr2)
      (setf (slot-value viewmodel 'w-pin) w-pin)
      (setf (slot-value viewmodel 'w-city-id) w-city)
      (setf (slot-value viewmodel 'w-state) w-state)
      (setf (slot-value viewmodel 'w-country) w-country)
      (setf (slot-value viewmodel 'w-manager) w-manager)
      (setf (slot-value viewmodel 'w-phone) w-phone)
      (setf (slot-value viewmodel 'w-alt-phone) w-alt-phone)
      (setf (slot-value viewmodel 'w-email) w-email)
      responsemodel)))


(defmethod ProcessResponseList ((adapter UpiPaymentsAdapter) upipaymentslist)
  (mapcar (lambda (upipayment)
	    (let ((responsemodel (make-instance 'UpiPaymentsResponseModel)))
	      (createresponsemodel adapter upipayment responsemodel))) upipaymentslist))
  

(defmethod CreateAllViewModel ((presenter UpiPaymentsPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))

