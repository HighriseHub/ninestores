;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defmethod (setf amount) (new-val (obj UpiPayment))
  (if (> new-val  10000.00)
      "Amount should be less than 10000.00"
      ;;else
      (setf (slot-value obj 'amount) new-val)))
  

(defmethod ProcessCreateRequest ((adapter UpiPaymentsAdapter) (requestmodel UpiPaymentsRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created UPI object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'UpiPaymentsService))
  ;; call the parent ProcessCreate
  (call-next-method))

(defmethod ProcessUpdateRequest ((adapter UpiPaymentsAdapter) (requestmodel UpiPaymentsRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'UpiPaymentsService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod ProcessReadAllRequest ((adapter UpiPaymentsAdapter) (requestmodel UpiPaymentsRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'UpiPaymentsService))
  (call-next-method))

(defmethod doreadall ((service UpiPaymentsService) (requestmodel UpiPaymentsRequestModel))
  (let* ((vend (vendor requestmodel))
	 (comp (company requestmodel))
	 (upitranslst (select-upi-transactions-by-vendor vend comp)))
    ;; return back a list of upi payments
    (mapcar (lambda (upitran)
	      (let ((upipayment (make-instance 'UpiPayment)))
		(copyupipayment-dbtodomain upitran upipayment))) upitranslst)))
        

(defmethod CreateViewModel ((presenter UpiPaymentsPresenter) (responsemodel UpiPaymentsResponseModel))
  (let ((viewmodel (make-instance 'UpiPaymentsViewModel)))
    (with-slots (vendor customer amount utrnum transaction-id status vendorconfirm phone company created) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel 'amount) amount)
      (setf (slot-value viewmodel 'utrnum) utrnum)
      (setf (slot-value viewmodel 'transaction-id) transaction-id)
      (setf (slot-value viewmodel 'status) status)
      (setf (slot-value viewmodel 'vendorconfirm) vendorconfirm)
      (setf (slot-value viewmodel 'phone) phone)
      (setf (slot-value viewmodel 'company) company)
      (setf (slot-value viewmodel 'created) created)
      viewmodel)))


(defmethod ProcessResponseList ((adapter UpiPaymentsAdapter) upipaymentslist)
  (mapcar (lambda (upipayment)
	    (let ((responsemodel (make-instance 'UpiPaymentsResponseModel)))
	      (createresponsemodel adapter upipayment responsemodel))) upipaymentslist))
  

(defmethod CreateAllViewModel ((presenter UpiPaymentsPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod doupdate ((service UpiPaymentsService) (requestmodel UpiPaymentsRequestModel))
  (let* ((vend (vendor requestmodel))
	 (upipaymentsdbservice (make-instance 'UpiPaymentsDBService))
	 (utrnum (utrnum requestmodel))
	 (comp (company requestmodel))
	 (paymentconfirm (paymentconfirm requestmodel))
	 (upidbobj (select-upi-transaction-by-utrnum utrnum vend comp))
	 (upiobj (make-instance 'UpiPayment)))
    
    (when paymentconfirm 
      (setf (slot-value upidbobj 'vendorconfirm) "Y")
      (setf (slot-value upidbobj 'status) "CNF"))
    
    (unless paymentconfirm
      (setf (slot-value upidbobj 'vendorconfirm) "N")
      (setf (slot-value upidbobj 'status) "CAN"))

    (setf (slot-value upipaymentsdbservice 'dbobject) upidbobj)
    (setf (slot-value upipaymentsdbservice 'businessobject) upiobj)
    
    (setcompany upipaymentsdbservice comp)
    (db-save upipaymentsdbservice)
    ;; Return the newly created UPI domain object
    (copyupipayment-dbtodomain upidbobj upiobj)))
 

(defun get-vendor-orders-from-upi-transactions ()
  (let* ((upitrans (select-upi-transactions-by-vendor (get-login-vendor) (get-login-vendor-company)))
	 (orders (mapcar (lambda (tran)
			   (subseq (slot-value tran 'transaction-id) 5)) upitrans)))
    orders))

(defun select-upi-transaction-by-utrnum (utrnum vend company)
  (let ((tenant-id (slot-value company 'row-id))
	(vendor-id (slot-value vend 'row-id)))
    
    (first (clsql:select 'dod-upi-payments  :where
		[and 
		[= [:deleted-state] "N"]
		[= [:vendor-id] vendor-id]
		[= [:utrnum] utrnum]
		[= [:tenant-id] tenant-id]]
     :caching *dod-database-caching* :flatp t ))))

(defun select-upi-transactions-by-customer (cust company)
  (let ((tenant-id (slot-value company 'row-id))
	(cust-id (slot-value cust 'row-id)))
	    
    (clsql:select 'dod-upi-payments  :where
		[and 
		[= [:deleted-state] "N"]
		[= [:cust-id] cust-id]		[= [:tenant-id] tenant-id]]
     :caching *dod-database-caching* :flatp t )))


(defun select-upi-transactions-by-vendor (vend company &optional (recordsfordays 60))
  (let ((tenant-id (slot-value company 'row-id))
	(vendor-id (slot-value vend 'row-id))
	(strfromdate (get-date-string-mysql (clsql-sys:date- (clsql-sys:get-date) (clsql-sys:make-duration :day recordsfordays))))
	(strtodate (get-date-string-mysql (clsql-sys:date+ (clsql-sys:get-date) (clsql-sys:make-duration :day recordsfordays)))))
    
    (clsql:select 'dod-upi-payments  :where
		[and 
		[= [:deleted-state] "N"]
		[= [:vendor-id] vendor-id]
		[between [:created] strfromdate strtodate]
		[= [:tenant-id] tenant-id]] :order-by '(([row-id] :desc)) 
				     :caching *dod-database-caching* :flatp t)))

(defmethod doCreate ((service UpiPaymentsService) (requestmodel UpiPaymentsRequestModel))
  (let* ((vend (vendor requestmodel))
	 (upipaymentsdbservice (make-instance 'UpiPaymentsDBService))
	 (cust (customer requestmodel))
	 (amt (amount requestmodel))
	 (phone (phone requestmodel))
	 (utrnum (utrnum requestmodel))
	 (transaction-id (transaction-id requestmodel))
	 (comp (company requestmodel))
	 (upiobj (createupipaymentobject cust vend amt transaction-id utrnum comp phone)))

    (setf (slot-value upiobj 'status) "PEN")
    (setf (slot-value upiobj 'vendorconfirm) "N")
    
    ;; Initialize the DB Service
    (init upipaymentsdbservice upiobj)
    (copy-businessobject-to-dbobject upipaymentsdbservice)
    (db-save upipaymentsdbservice)
    ;; Return the newly created UPI domain object
    upiobj))

(defmethod init ((dbas UpiPaymentsDBService) (bo UpiPayment))
  :description "Set the DB object and domain object"
  (let* ((UpiPaymentsDBObj  (make-instance 'dod-upi-payments)))
      (setf (dbobject dbas) UpiPaymentsDBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))

(defmethod Copy-DbObject-To-BusinessObject ((dbas UpiPaymentsDBService))
  :description "Syncs the dbobject and domain object"
  (let ((dbobj (slot-value dbas 'dbobject))
	(upipaymentobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'businessobject) (copyupipayment-dbtodomain dbobj upipaymentobj))))

(defmethod Copy-BusinessObject-To-DBObject ((dbas UpiPaymentsDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(upipaymentobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyupipayment-domaintodb upipaymentobj dbobj))))

(defun copyupipayment-dbtodomain (source destination)
  (let* ((comp (select-company-by-id (slot-value source 'tenant-id)))
	 (vend (select-vendor-by-id (slot-value source 'vendor-id)))
	 (cust (select-customer-by-id (slot-value source 'cust-id) comp)))

    (with-slots (amount transaction-id customer vendor status utrnum vendorconfirm deleted-state company created phone) destination
      (setf vendor vend)
      (setf customer cust)
      (setf amount (slot-value source 'amount))
      (setf company comp)
      (setf transaction-id  (slot-value source 'transaction-id))
      (setf utrnum (slot-value source 'utrnum))
      (setf vendorconfirm (slot-value source 'vendorconfirm))
      (setf status (slot-value source 'status))
      (setf deleted-state (slot-value source 'deleted-state))
      (setf created (slot-value source 'created))
      (setf phone (slot-value source 'phone))
      destination)))


(defun copyupipayment-domaintodb (source destination)
  (let ((vendor (slot-value source 'vendor))
	(customer (slot-value source 'customer))
	(company (slot-value source 'company)))
    
  (with-slots (transaction-id cust-id vendor-id amount status utrnum vendorconfirm deleted-state tenant-id phone) destination
    (setf vendor-id (slot-value vendor 'row-id))
    (setf cust-id  (slot-value customer 'row-id))
    (setf phone (slot-value customer 'phone))
    (setf amount (slot-value source 'amount))
    (setf tenant-id (slot-value company 'row-id))
    (setf transaction-id  (slot-value source 'transaction-id))
    (setf utrnum (slot-value source 'utrnum))
    (setf vendorconfirm (slot-value source 'vendorconfirm))
    (setf status (slot-value source 'status))
    (setf deleted-state (slot-value source 'deleted-state))
    destination)))


(defmethod CreateResponseModel ((adapter UpiPaymentsAdapter) (source UpiPayment) (destination UpiPaymentsResponseModel))
  :description "source = upipayment destination = upipaymentresponsemodel"
  (with-slots (transaction-id customer vendor amount status utrnum vendorconfirm deleted-state company created phone) destination
    (setf vendor (slot-value source 'vendor))
    (setf customer  (slot-value source 'customer))
    (setf amount (slot-value source 'amount))
    (setf company (slot-value source 'company))
    (setf transaction-id  (slot-value source 'transaction-id))
    (setf utrnum (slot-value source 'utrnum))
    (setf vendorconfirm (slot-value source 'vendorconfirm))
    (setf status (slot-value source 'status))
    (setf created (slot-value source 'created))
    (setf phone (slot-value source 'phone))
    destination))

  
(defun createupipaymentobject (customer vendor amount transaction-id utrnum  company phone)
  (let* ((upipaymentobj (make-instance 'UpiPayment
				       :customer customer
				       :vendor vendor
				       :amount amount
				       :transaction-id transaction-id
				       :utrnum utrnum
				       :company company
				       :phone phone
				       :deleted-state "N")))
    upipaymentobj))
				       




