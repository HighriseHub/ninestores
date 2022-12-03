;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defmethod ProcessCreateRequest ((adapter UpiPaymentsAdapter) (requestmodel UpiPaymentsRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method"
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'UpiPaymentsService))
  ;; call the parent ProcessCreate
  (call-next-method))

(defmethod doCreate ((service UpiPaymentsService) (requestmodel UpiPaymentsRequestModel))
  (let* ((vend (vendor requestmodel))
	 (upipaymentsdbservice (make-instance 'UpiPaymentsDBService))
	 (cust (customer requestmodel))
	 (amt (amount requestmodel))
	 (comp (tenant requestmodel))
	 (upiobj (createupipaymentobject cust vend amt comp)))
    
    ;; Initialize the DB Service
    (init upipaymentsdbservice upiobj)
    (copy-businessobject-to-dbobject upipaymentsdbservice)
    (db-save upipaymentsdbservice)))

(defmethod init ((dbas UpiPaymentsDBService) (bo UpiPayment))
  :description "Set the DB object and domain object"
  (let* ((vend (vendor bo))
	 (cust (customer bo))
	 (amt (amount bo))
	 (vendor-id (slot-value vend 'row-id))
	 (cust-id (slot-value cust 'row-id))
	 (comp (company bo))
	 (tenant-id (slot-value comp 'row-id))
	 (UpiPaymentsDBObj  (make-instance 'dod-upi-payments
					    :cust-id cust-id
					    :vendor-id vendor-id
					    :amount amt
					    :utrnum nil
					    :tenant-id tenant-id
					    :deleted-state "N")))
   
    (setf (dbobject dbas) UpiPaymentsDBObj)
    ;; Set the company context for the web push notification DB service 
    (setcompany dbas comp)
    (call-next-method)))
      
(defmethod Copy-BusinessObject-To-DBObject ((dbas UpiPaymentsDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(upipaymentobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyupipayment upipaymentobj dbobj))))

       
(defun copyupipayment (source destination)
  (let ((vendor (slot-value source 'vendor))
	(customer (slot-value source 'customer))
	(company (slot-value source 'company)))
    
  (with-slots (transaction-id cust-id vendor-id amount status utrnum vendorconfirm tenant-id) destination
    (setf vendor-id (slot-value vendor 'row-id))
    (setf cust-id  (slot-value customer 'row-id))
    (setf amount (slot-value source 'amount))
    (setf tenant-id (slot-value company 'row-id))
    (setf transaction-id  (random 99999))
    (setf status "PEN")
    (setf vendorconfirm "N")
    (setf utrnum (format nil "UTR~d" (random 999999)))
    destination)))

      
(defmethod ProcessRead ((adapter UpiPaymentsAdapter) (requestmodel UpiPaymentsRequestModel))
  :descrition "Adapter service method to call the BusinessService Read method")


(defun createupipaymentobject (customer vendor amount company)
  (let* ((upipaymentobj (make-instance 'UpiPayment
				       :customer customer
				       :vendor vendor
				       :amount amount
				       :company company)))
    upipaymentobj))
				       
