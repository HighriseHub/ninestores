;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-entity-create (adaptername requestmodel &body body)
    :description "Creates a business entity when provided with a adapter name and requestmodel"
    `(let* ((adapter (make-instance ,adaptername)))
       ;; create the entity in the Database and return back the business object. 
       (ProcessCreateRequest adapter ,requestmodel)
       ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-entity-readall (adaptername requestmodel &body body)
    `(let* ((adapter (make-instance ,adaptername)))
      ;; Read the entity from the database and return back a list of business objects
      (ProcessReadallRequest adapter ,requestmodel)
      ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-entity-read (adaptername requestmodel &body body)
    `(let* ((adapter (make-instance ,adaptername)))
       ;; Read the entity from the database adn return back a single business object.
       (ProcessReadRequest adapter ,requestmodel)
       ,@body)))

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
    




(defun testentitycreate ()
  (let* ((destfile "~/hhubplatform/hhub/test/hhub-tst-wrh.lisp")
	 (filecontent (hhub-read-file "~/hhubplatform/hhub/core/hhub-bl-egn.lisp"))
	 (temp-str (cl-ppcre:regex-replace-all "xxxx" filecontent "Warehouse")))
    (with-open-file (stream destfile :if-exists :append :direction :output)
      (print (format stream temp-str))
      (terpri stream))))
    


;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.


(defmethod ProcessCreateRequest ((adapter WarehouseAdapter) (requestmodel WarehouseRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'WarehouseService))
  ;; call the parent ProcessCreate
  (call-next-method))

(defmethod init ((dbas WarehouseDBService) (bo Warehouse))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'Warehouse)))
    ;; Set specific fields of the DB object if you need to. 

    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))

(defmethod doCreate ((service WarehouseService) (requestmodel WarehouseRequestModel))
  (let* ((Warehousedbservice (make-instance 'WarehouseDBService))
	 (field1 (field1func requestmodel))
	 (field2 (field2func requestmodel))
	 (field3 (field3func requestmodel))
	 (domainobj (createWarehouseobject arg1 arg2 . . . )))
         ;; Initialize the DB Service
    (init Warehousedbservice domainobj)
    (copy-businessobject-to-dbobject Warehousedbservice)
    (db-save Warehousedbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createWarehouseobject (field1 field2 field3 ... company)
  (let* ((domainobj  (make-instance 'Warehouse 
				       :field1 field1
				       :field2 field2
				       :field3 field3
				       :company company)))
    domainobj))



(defmethod Copy-BusinessObject-To-DBObject ((dbas WarehouseDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(warehouseobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copywarehouse-domaintodb warehouseobj dbobj))))

(defun copywarehouse-domaintodb (source destination) ;; source = domain destination = db
  (with-slots (field1 field2 field3 field 4 ... ) destination
    (setf field1 (slot-value source 'field1))
    (setf field2 (slot-value source 'field2))
    (setf field3 (slot-value source 'field3))
    (setf field4 (slot-value source 'field4))
    destination))


