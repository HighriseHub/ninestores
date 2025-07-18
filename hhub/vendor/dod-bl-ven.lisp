;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)



(defmethod ProcessUpdateRequest ((adapter VendorApprovalAdapter) (requestmodel RequestModelVendorApproval))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'VendorApprovalService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod doupdate ((service VendorApprovalService) (requestmodel RequestModelVendorApproval))
  (let* ((dbas (make-instance 'vendorDBService))
	 (vendor-id (slot-value requestmodel 'vendor-id))
	 (companyadmin (slot-value requestmodel 'companyadmin))
	 (approved-by-phone (slot-value companyadmin 'phone-mobile))
	 (dbvendor (select-vendor-by-id vendor-id))
	 (company (get-vendor-company dbvendor))
	 (vendor (make-instance 'vendor)))
    
    (setf (slot-value dbvendor 'approved-flag) "Y")
    (setf (slot-value dbvendor 'approval-status) "APPROVED")
    (setf (slot-value dbvendor 'approved-by) approved-by-phone)
    (setf (slot-value dbas 'dbobject) dbvendor)
    (setf (slot-value dbas 'businessobject) vendor)
    ;; initialise the dbservice with vendor object. 
    (setcompany dbas company)
    (db-save dbas)
    (Copy-DBObject-To-BusinessObject dbas)))
    
(defun reject-vendor (vendor companyadmin)
  (let ((dbas (make-instance 'vendorDBService))
	(rejected-by-phone (slot-value companyadmin 'phone)))
	
    (setf (slot-value vendor 'approved-flag) "N")
    (setf (slot-value vendor 'approval-status) "REJECTED")
    (setf (slot-value vendor 'approved-by) rejected-by-phone)
    ;; initialise the dbservice with vendor object. 
    (init dbas vendor)
    (Copy-BusinessObject-To-DBObject dbas)
    (db-save dbas)))
    

(defmethod init ((dbas vendorDBService) (bo vendor))
  :description "Set the DB object and domain object"
  (let* ((vendorDBObj  (make-instance 'dod-vend-profile)))

    (setf (dbobject dbas) vendorDBObj)
    ;; Set the company context for the vendor db service 
    (call-next-method)))


(defmethod Copy-BusinessObject-To-DBObject ((dbas vendorDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(businessobject (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyvendor-domaintodb businessobject dbobj))))

(defmethod Copy-DBObject-To-BusinessObject ((dbas vendorDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(businessobject (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyvendor-dbtodomain dbobj  businessobject))))

  
(defun copyvendor-domaintodb (businessobj dbobj)
  (let* ((company (slot-value businessobj 'company))
	 (tid (slot-value company 'row-id)))
    (with-slots
	  (row-id name address phone email  email-add-verified suspend-flag active-flag approved-flag approval-status approved-by upi-id tenant-id) dbobj
      (setf row-id (slot-value businessobj 'row-id))
      (setf (slot-value dbobj 'salt) (slot-value businessobj 'salt))
      (setf name (slot-value businessobj 'name))
      (setf address (slot-value businessobj 'address))
      (setf phone (slot-value businessobj 'phone))
      (setf email (slot-value businessobj 'email))
      (setf (slot-value dbobj 'password) (slot-value businessobj 'password))
      (setf email-add-verified (slot-value businessobj 'email-add-verified))
      (setf suspend-flag (slot-value businessobj 'suspend-flag))
      (setf active-flag (slot-value businessobj 'active-flag))
      (setf approved-flag (slot-value businessobj 'approved-flag))
      (setf approval-status (slot-value businessobj 'approval-status))
      (setf approved-by (slot-value businessobj 'approved-by))
      (setf upi-id (slot-value businessobj 'upi-id))
      (setf tenant-id tid)
      dbobj)))


(defun copyvendor-dbtodomain (dbobj businessobj)
  (let* ((comp (select-company-by-id (slot-value dbobj 'tenant-id))))
    (with-slots (row-id name address phone email  email-add-verified suspend-flag active-flag approved-flag approval-status approved-by upi-id tenantobj) businessobj
      (setf row-id (slot-value dbobj 'row-id))
      (setf name (slot-value dbobj 'name))
      (setf address (slot-value dbobj 'address))
      (setf phone (slot-value dbobj 'phone))
      (setf email (slot-value dbobj 'email))
      (setf (slot-value businessobj 'password) (slot-value dbobj 'password))
      (setf (slot-value businessobj 'salt) (slot-value dbobj 'salt))
      (setf email-add-verified (slot-value dbobj 'email-add-verified))
      (setf suspend-flag (slot-value dbobj 'suspend-flag))
      (setf active-flag (slot-value dbobj 'active-flag))
      (setf approved-flag (slot-value dbobj 'approved-flag))
      (setf approval-status (slot-value dbobj 'approval-status))
      (setf approved-by (slot-value dbobj 'approved-by))
      (setf upi-id (slot-value dbobj 'upi-id))
      (setf tenantobj comp)
      businessobj)))

(defmethod ProcessCreateRequest ((adapter VendorAdapter) (requestmodel RequestVendor))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created vendor object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'VendorProfileService))
  ;; call the parent ProcessCreate
  (call-next-method))

(defmethod ProcessUpdateRequest ((adapter VendorAdapter) (requestmodel RequestVendor))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'VendorProfileService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod ProcessReadAllRequest ((adapter VendorAdapter) (requestmodel RequestVendor))
  :description "Adapter service method to read the upi payments"
  (setf (slot-value adapter 'businessservice) (find-class 'VendorProfileService))
  (call-next-method))

(defmethod doreadall ((service VendorProfileService) (requestmodel RequestVendor))
  (let* ((comp (slot-value requestmodel 'tenantobj))
	 (vendorlist (select-vendors-for-company comp)))
	
    ;; return back a list of upi payments response model
    (mapcar (lambda (dbvendor)
	      (let ((vendor (make-instance 'vendor)))
		(copyvendor-dbtodomain dbvendor vendor))) vendorlist)))
        

(defmethod CreateViewModel ((presenter VendorPresenter) (responsemodel ResponseVendor))
  (let ((viewmodel (make-instance 'VendorViewModel)))
    (with-slots (vendor customer amount utrnum transaction-id status vendorconfirm company created) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel 'amount) amount)
      (setf (slot-value viewmodel 'utrnum) utrnum)
      (setf (slot-value viewmodel 'transaction-id) transaction-id)
      (setf (slot-value viewmodel 'status) status)
      (setf (slot-value viewmodel 'vendorconfirm) vendorconfirm)
      (setf (slot-value viewmodel 'company) company)
      (setf (slot-value viewmodel 'created) created)
      responsemodel)))


(defmethod ProcessResponseList ((adapter VendorAdapter) vendorlist)
  (mapcar (lambda (vendor)
	    (let ((responsemodel (make-instance 'ResponseVendor)))
	      (createresponsemodel adapter vendor  responsemodel))) vendorlist))
  

(defmethod CreateAllViewModel ((presenter VendorPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))



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



;;; Method implementation for DBAdapterService
(defmethod db-fetch ((dbas vendorDBService) row-id)
  :description  "Fetch the DBObject based on row-id"
  (let ((dbvendor (select-vendor-by-id row-id))
	(vendor (businessobject dbas)))
    (setf (dbobject dbas) dbvendor)
    (setf (businessobject dbas) (copyvendor-dbtodomain dbvendor vendor)))) 

(defmethod db-delete ((dbas vendorDBService))
  :description "Will be implementd by the derived class objects"
  (let* ((dbvendor (slot-value  dbas 'dbobject))
	(dbcompany (slot-value dbvendor 'company))
	(id (slot-value dbvendor 'row-id)))
    (delete-vendor id dbcompany)))


(defmethod select-vendor-by-phone ((dbas VendorDBService) phone)
  (let ((dbvendor (car (clsql:select 'dod-vend-profile  :where
		       [and [= [:deleted-state] "N"]
		       [= [:phone] phone]
		       [= [:active-flag] "Y"]]
		       :caching nil :flatp t ))))
    (setf (slot-value dbas 'dbobject) dbvendor)
    dbvendor))

(defun get-vendors-for-approval (tenant-id)
:documentation "This function will be used only by the company admin user" 
  (clsql:select 'dod-vend-profile  :where 
		[and 
		[= [:deleted-state] "N"] 
		[= [:active-flag] "Y"]
		[= [:approved-flag] "N"]
		[= [:tenant-id] tenant-id]
		[= [:approval-status] "PENDING"]]
		:caching *dod-database-caching* :flatp t ))



(defun select-vendors-for-company (company)
  (let ((tenant-id (slot-value company 'row-id)))
    (clsql:select 'dod-vend-profile  :where [and [= [:deleted-state] "N"] [= [:tenant-id] tenant-id]]    :caching nil :flatp t )))


(defun select-vendor-by-id (id)
  (car (clsql:select 'dod-vend-profile  :where
		[and [= [:deleted-state] "N"]
		[=[:row-id] id]]    :caching nil :flatp t )))



(defun select-vendor-by-email (email)
  (car (clsql:select 'dod-vend-profile  :where
		[and [= [:deleted-state] "N"]
		;[= [:active-flag] "Y"]
		[=[:email] email]]    :caching nil :flatp t )))


(defun select-vendor-by-name (name-like-clause company)
  (let ((tenant-id (slot-value company 'row-id)))
  (car (clsql:select 'dod-vend-profile :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[like  [:name] (format nil "%~a%" name-like-clause)]]
		:caching nil :flatp t))))

(defun select-vendors-by-name (name-like-clause company)
  (let ((tenant-id (slot-value company 'row-id)))
    (clsql:select 'dod-vend-profile :where [and
		  [= [:deleted-state] "N"]
		  [= [:tenant-id] tenant-id]
		  [like  [:name] (format nil "%~a%" name-like-clause)]]
				    :caching nil :flatp t)))


(defun reset-vendor-password (vendor)
  (let* ((confirmpassword (hhub-random-password 8))
	 (salt (createciphersalt))
	 (encryptedpass (check&encrypt confirmpassword confirmpassword salt)))
	  
    (setf (slot-value vendor 'password) encryptedpass)
    (setf (slot-value vendor 'salt) salt) 
    ; Whenever we reset the vendor password, we activate the vendor, as he is in-activated when this process started. 
    (setf (slot-value vendor 'active-flag) "Y") 
    (update-vendor-details  vendor )
    confirmpassword)) ; return the newly generated password. 





(defun update-vendor-payment-params (payment-api-key payment-api-salt vendor)
  (setf (slot-value vendor 'payment-api-key) payment-api-key)
  (setf (slot-value vendor 'payment-api-salt) payment-api-salt)
  (update-vendor-details vendor))
 

(defun update-vendor-details (vendor-instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance vendor-instance))

(defun delete-vendor( id company )
  (let ((tenant-id (slot-value company 'row-id)))
  (let ((dodvendor (car (clsql:select 'dod-vend-profile :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching nil))))
    (setf (slot-value dodvendor 'deleted-state) "Y")
    (clsql:update-record-from-slot dodvendor 'deleted-state))))



(defun delete-vendors ( list company)
  (let ((tenant-id (slot-value company 'row-id)))
  (mapcar (lambda (id)  (let ((dodvendor (car (clsql:select 'dod-vend-profile :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching nil))))
			  (setf (slot-value dodvendor 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodvendor  'deleted-state))) list )))


(defun restore-deleted-vendors ( list company )
  (let ((tenant-id (slot-value company 'row-id)))
(mapcar (lambda (id)  (let ((dodvendor (car (clsql:select 'dod-vend-profile :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching nil))))
    (setf (slot-value dodvendor 'deleted-state) "N")
    (clsql:update-record-from-slot dodvendor 'deleted-state))) list )))

  
  
(defun create-vendor(name address phone email password salt city state zipcode company )
  (let ((tenant-id (slot-value company 'row-id)))
 (clsql:update-records-from-instance (make-instance 'dod-vend-profile
				    :name name
				    :address address
				    :email email 
				    :password password 
				    :salt salt
				    :phone phone
				    :city city 
				    :state state 
				    :zipcode zipcode
				    :tenant-id tenant-id
				    :push-notify-subs-flag "N"
				    :deleted-state "N"))))
 

 

; DOD_VENDOR_TENANTS related functions
(defun create-vendor-tenant (vendor default-flag company)
  (let ((tenant-id (slot-value company 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
    (clsql:update-records-from-instance (make-instance 'dod-vendor-tenants
						       :vendor-id vendor-id
						       :tenant-id tenant-id
						       :default-flag default-flag
						       :deleted-state "N"))))

(defun delete-vendor-tenant (vendor-tenantlist company)
   (let ((tenant-id (slot-value company 'row-id)))
  (mapcar (lambda (id)  (let ((dodvendortenant (car (clsql:select 'dod-vendor-tenants :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching nil))))
			  (setf (slot-value dodvendortenant 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodvendortenant  'deleted-state))) vendor-tenantlist )))




(defun get-vendor-tenants (vendor)
  (let ((vendor-id (slot-value vendor 'row-id)))
 (clsql:select 'dod-vendor-tenants  :where
		[and [= [:deleted-state] "N"]
		[= [:vendor-id] vendor-id]]
	           :caching nil :flatp t )))



(defun get-vendor-tenants-as-companies (vendor) 
  (let ((vendor-tenants-list (get-vendor-tenants vendor)))
    (mapcar (lambda (vt) 
	      (let ((tenant-id (slot-value vt 'tenant-id)))
		(select-company-by-id tenant-id))) vendor-tenants-list)))

    
