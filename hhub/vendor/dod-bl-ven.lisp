;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


;;; Method implementation for DBAdapterService
(defmethod db-fetch ((dbas vendorDBService) row-id)
  :description  "Fetch the DBObject based on row-id"
  (let ((dbvendor (select-vendor-by-id row-id))
	(vendor (businessobject dbas)))
    (setf (dbobject dbas) dbvendor)
    (setf (businessobject dbas) (copyvendor dbvendor vendor))
    vendor)) 

(defmethod db-delete ((dbas vendorDBService))
  :description "Will be implementd by the derived class objects"
  (let* ((dbvendor (slot-value  dbas 'dbobject))
	(dbcompany (slot-value dbvendor 'company))
	(id (slot-value dbvendor 'row-id)))
    (delete-vendor id dbcompany)))

(defmethod syncobjects ((dbas vendorDBService))
  :description "Will be implementd by the derived class objects"
  (let ((dbobj (slot-value dbas 'dbobject))
	(busobj (slot-value dbas 'businessobject)))
    (copyvendor dbobj busobj)))

(defmethod select-vendor-by-phone ((dbas VendorDBService) phone)
  (let ((dbvendor (car (clsql:select 'dod-vend-profile  :where
		       [and [= [:deleted-state] "N"]
		       [= [:phone] phone]
		       [= [:active-flag] "Y"]]
		       :caching nil :flatp t ))))
    (setf (slot-value dbas 'dbobject) dbvendor)
    dbvendor))




(defmethod doService ((vpservice VendorProfileService) params )
  (let* ((repository (cdr (assoc "repository" params :test 'equal)))
	 (vendor-id (cdr (assoc "vendor-id" params :test 'equal)))
	 (vendors-ht  (slot-value repository 'businessobjects))
	 (vendor (gethash vendor-id vendors-ht))
	 (name (slot-value vendor 'name))
	 (address (slot-value vendor 'address))
	 (phone (slot-value vendor 'phone))
	 (email (slot-value vendor 'email))
	 (vdbservice (make-instance 'vendorDBService))
	 (dbvendor (select-vendor-by-phone vdbservice phone)))
    
    ;; initialise the vendor db service with the vendor object. 
    (init vdbservice vendor)
        
    (if dbvendor
	(progn
	  (setf (slot-value dbvendor 'name) name)
	  (setf (slot-value dbvendor 'address) address)
	  (setf (slot-value dbvendor 'phone) phone)
	  (setf (slot-value dbvendor 'email) email)
	  (setf (slot-value vdbservice 'dbobject) dbvendor)
	  (db-save vdbservice)
	  (format t "Vendor ~A has been updated" name))
	;;else
	(format t "Vendor not found"))

    (let ((dbvendor (select-vendor-by-phone vdbservice phone)))
      (if dbvendor
	  (progn 
	    (setf (slot-value vdbservice 'dbobject) dbvendor)
	    (syncobjects vdbservice)
	    (addbo repository (getbusinessobject vdbservice))
	    repository)))))

;; This is a client function which will be calling the business service layer. 
(defun testVendorUpdateProfile(server)
  (let* ((vr (make-instance 'VendorRepository))
	 (vendor (make-instance 'Vendor))
	 (vendor-id (slot-value vendor 'id))
	 (vpservice (discoverService server "HSRV10001"))
	 (params nil))

    (setf (slot-value vendor 'name) "Demo Vendor")
    (setf (slot-value vendor 'address) "Near Mahalaxmi layout entrance")
    (setf (slot-value vendor 'phone) "9999999990")
    (setf (slot-value vendor 'email) "pawan.deshpande@gmail.com")
    (addbo vr vendor)
    
    (setf params (acons "repository" vr params))
    (setf params (acons "vendor-id" vendor-id params))
    (doservice vpservice params)))



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
		[like  [:name] name-like-clause]]
		:caching nil :flatp t))))


(defun reset-vendor-password (vendor)
  (let* ((confirmpassword (hhub-random-password 8))
	(salt-octet (secure-random:bytes 56 secure-random:*generator*))
	(salt (flexi-streams:octets-to-string  salt-octet))
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

    
