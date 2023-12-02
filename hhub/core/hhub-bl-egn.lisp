

;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.


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
	 (field1 (field1func requestmodel))
	 (field2 (field2func requestmodel))
	 (field3 (field3func requestmodel))
	 (domainobj (createxxxxobject arg1 arg2 . . . )))
         ;; Initialize the DB Service
    (init xxxxdbservice domainobj)
    (copy-businessobject-to-dbobject xxxxdbservice)
    (db-save xxxxdbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createxxxxobject (field1 field2 field3 ... company)
  (let* ((domainobj  (make-instance 'xxxx 
				       :field1 field1
				       :field2 field2
				       :field3 field3
				       :company company)))
    domainobj))



(defmethod Copy-BusinessObject-To-DBObject ((dbas xxxxDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copywarehouse-domaintodb domainobj dbobj))))

(defun copywarehouse-domaintodb (source destination) ;; source = domain destination = db
  (with-slots (field1 field2 field3 field 4 ... ) destination
    (setf field1 (slot-value source 'field1))
    (setf field2 (slot-value source 'field2))
    (setf field3 (slot-value source 'field3))
    (setf field4 (slot-value source 'field4))
    destination))

