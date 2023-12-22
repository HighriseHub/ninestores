;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)



;(defmacro defservicemethod  (method-name params &body body) 
;  `(defmethod ,method-name ((,instance-name ,instance-of) ,params)
;    (let* ((repository (cdr (assoc "repository" ,params :test 'equal)))
;	    (bo-key (cdr (assoc "bo-key" ,params :test 'equal)))
;	    (bo-ht  (slot-value repository 'businessobjects))
;	    (busobject (gethash bo-key bo-ht)))
;      ,@body)))

;(defservicemethod (service AddressService) params
;  (let ((pincode (slot-value busobject 'pincode)))
;    (getpincodedetails pincode)))


 


(defun update-cust-wallet-balance (amount wallet-id)
  (let* ((wallet (get-cust-wallet-by-id wallet-id (get-login-customer-company)))
	 (current-balance (slot-value wallet 'balance))
	 (latest-balance (+ current-balance amount)))
    (set-wallet-balance latest-balance wallet)))



(defmethod ProcessResponse ((service Address-Adapter)  params)
  (let* ((address (cdr (assoc "address" params :test 'equal)))
	 (responsemodel (make-instance 'ResponseAddress)))
    
    (with-slots (house-no street locality city state pincode country longitude latitude) address
      (setf (slot-value responsemodel 'house-no) house-no)
      (setf (slot-value responsemodel 'street) street)
      (setf (slot-value responsemodel 'locality) locality)
      (setf (slot-value responsemodel 'city) city)
      (setf (slot-value responsemodel 'state) state)
      (setf (slot-value responsemodel 'pincode) pincode)
      (setf (slot-value responsemodel 'country) country)
      (setf (slot-value responsemodel 'latitude) latitude)
	(setf (slot-value responsemodel 'longitude) longitude))
    ;; return the responsemodel
    responsemodel))
    

(defmethod CreateViewModel ((service Address-Presenter) (responsemodel ResponseAddress))
  (let ((viewmodel (make-instance 'AddressViewModel)))
    (with-slots (locality city state pincode) responsemodel
      (setf (slot-value viewmodel 'locality) locality)
      (setf (slot-value viewmodel 'city) city)
      (setf (slot-value viewmodel 'state) state)
      (setf (slot-value viewmodel 'pincode) pincode)
      ;;return the viewmodel
      (setf (slot-value service 'viewmodel) viewmodel)
      viewmodel)))




;; Service layer implementation for the pincode check.
;; We would need to have a BusinessService which takes requestmodel as parameter    
(defmethod doService ((service AddressService) requestmodel)
  (let* ((pincode (slot-value requestmodel 'pincode)))
    (getpincodedetails pincode)))

(defmethod ProcessRequest ((service Address-Adapter)  params)
  :description "This function is responsible for initializaing the BusinessService and calling its doService method. It then creates an instance of outboundwebservice"
  (let* ((pincode (cdr (assoc "pincode" params :test 'equal)))
	   (requestmodel (make-instance 'RequestPincode)))
      
      (setf (slot-value service 'businessservice) (find-class  'AddressService))
      (setf (slot-value service 'businessservicemethod) "doservice")
      (setf (slot-value requestmodel 'pincode) pincode)
      (setf (slot-value service 'requestmodel) requestmodel)
      
      (let ((addressobj (call-next-method))
	    (params nil)) 
	(setf params (acons "address" addressobj params))
	(processresponse service params))))
  
(defun getpincodedetails (pincode)
  (let* ((address (make-instance 'Address))
	 (param-name (list "api-key" "format" "offset" "limit" "filters[pincode]"))
	 (param-values (list *HHUBAPI.GOV.IN.KEY*  "json" "0" "1" (format nil "~A" pincode)))
	 (param-alist (pairlis param-name param-values ))
	 (json-response (json:decode-json-from-string  (map 'string 'code-char (drakma:http-request *HHUBGETPINCODEURLEXTERNAL*
												    :method :GET
												    :parameters param-alist  ))))
	 (locality (cdr (assoc :OFFICENAME (nth 1 (nth 24 json-response)) :test 'equal)))
	 (city (cdr (assoc :DISTRICTNAME (nth 1 (nth 24 json-response)) :test 'equal)))
	 (division (cdr (assoc :DIVISIONNAME (nth 1 (nth 24 json-response)) :test 'equal)))
	 (state (cdr (assoc :STATENAME (nth 1 (nth 24 json-response)) :test 'equal))))
    (format t "locality = ~A, city= ~A, state = ~A" locality city state)
    ;; Send the Area, City and State values back.
    (if (and 
	     (not (null locality))
	     (not (null city))
	     (not (null state)))
	(progn
	  (setf (slot-value address 'pincode) pincode)
	  ;; Remove the S.O from the locality string.
	  (setf (slot-value address 'house-no) "")
	  (setf (slot-value address 'street) "")
	  (setf (slot-value address 'country) "")
	  (setf (slot-value address 'longitude) "")
	  (setf (slot-value address 'latitude) "")
	  (setf (slot-value address 'locality) (string-trim "S.O" locality))
	  (setf (slot-value address 'city) (format nil "~A, ~A" division city))
	  (setf (slot-value address 'state) state))
	
	;;else
	(progn
	  (setf (slot-value address 'pincode) pincode)
	  (setf (slot-value address 'house-no) "")
	  (setf (slot-value address 'street) "")
	  (setf (slot-value address 'country) "")
	  (setf (slot-value address 'longitude) "")
	  (setf (slot-value address 'latitude) "")
	  (setf (slot-value address 'locality) "Not Found")
	  (setf (slot-value address 'city) "Not Found")
	  (setf (slot-value address 'state) "Not Found")))
    ;; return the address object
    address))
	  



(defun select-customer-by-name (name-like-clause company)
  (let ((tenant-id (slot-value company 'row-id)))
    (car (clsql:select 'dod-cust-profile :where [and
		  [= [:deleted-state] "N"]
		  [= [:tenant-id] tenant-id]
		  [= [:cust-type] "STANDARD"]
		  [= [:active-flag] "Y"]
		  [like  [:name] name-like-clause]]
					 :caching *dod-database-caching* :flatp t))))


(defun select-customer-list-by-name (name-like-clause company)
  (let ((tenant-id (slot-value company 'row-id)))
    (clsql:select 'dod-cust-profile :where [and
		  [= [:deleted-state] "N"]
		  [= [:cust-type] "STANDARD"]
		  [= [:tenant-id] tenant-id]
		  [= [:active-flag] "Y"]
		  [like  [:name] name-like-clause]]
					 :caching *dod-database-caching* :flatp t)))



(defun select-customer-by-phone (phone company)
(let ((tenant-id (slot-value company 'row-id)))
  (car (clsql:select 'dod-cust-profile :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:cust_type] "STANDARD"]
		[= [:active-flag] "Y"]
		[like  [:phone] phone]]
		:caching *dod-database-caching* :flatp t))))



(defun select-customers-for-company (company) 
  (let ((tenant-id (slot-value company 'row-id)))
    (clsql:select 'dod-cust-profile :where [and
		       [= [:deleted-state] "N"]
		       [= [:tenant-id] tenant-id]
		       [= [:active-flag] "Y"]]
		       :caching *dod-database-caching* :flatp t)))


(defun select-guest-customer (company)
(let ((tenant-id (slot-value company 'row-id)))
  (car (clsql:select 'dod-cust-profile :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:active-flag] "Y"]
		[= [:phone] *HHUBGUESTCUSTOMERPHONE*]
		[= [:cust-type] "GUEST"]]
		:caching *dod-database-caching* :flatp t))))




(defun update-customer (customer-instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance customer-instance))

(defun duplicate-customerp(phone company)
  (if (select-customer-by-phone phone company) T NIL))
    

(defun select-customer-by-id (id company)
(let ((tenant-id (slot-value company 'row-id)))
  (car (clsql:select 'dod-cust-profile :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:active-flag] "Y"]
		[=  [:row-id] id]]
		:caching *dod-database-caching* :flatp t))))



(defun select-customer-by-email (email)
  (car (clsql:select 'dod-cust-profile :where [and
		[= [:deleted-state] "N"]
		[= [:active-flag] "Y"]
		[=  [:email] email]]
		:caching *dod-database-caching* :flatp t)))




(defun reset-customer-password (customer)
  (let* ((confirmpassword (hhub-random-password 8))
	 (salt (createciphersalt))
	(encryptedpass (check&encrypt confirmpassword confirmpassword salt)))
	  
    (setf (slot-value customer 'password) encryptedpass)
    (setf (slot-value customer 'salt) salt) 
    ; Whenever we reset the customer password, we activate the customer, as he is in-activated when this process started. 
    (setf (slot-value customer 'active-flag) "Y") 
    (update-customer  customer )
    confirmpassword)) ; return the newly generated password. 

       

(defun select-deleted-customer-by-id (id company)
(let ((tenant-id (slot-value company 'row-id)))
  (car (clsql:select 'dod-cust-profile :where [and
		[= [:deleted-state] "Y"]
		[= [:tenant-id] tenant-id]
		[=  [:row-id] id]]
		:caching *dod-database-caching* :flatp t))))


(defun delete-customer (object)
  (let ((cust-id (slot-value object 'row-id))
	 (tenant-id (slot-value object 'tenant-id)))
	 (delete-cust-profile cust-id tenant-id)))

(defun restore-deleted-customer (object)
  (let ((cust-id (slot-value object 'row-id))
	(tenant-id (slot-value object 'tenant-id)))
    (restore-deleted-cust-profile (list cust-id) tenant-id)))

    

(defun delete-cust-profile( id tenant-id )
  (let ((dodcust (car (clsql:select 'dod-cust-profile :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodcust 'deleted-state) "Y")
    (clsql:update-record-from-slot dodcust 'deleted-state)))

(defun delete-cust-profiles ( list company)
(let ((tenant-id (slot-value company 'row-id)))  
  (mapcar (lambda (id)  (let ((doduser (car (clsql:select 'dod-cust-profile :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
			  (setf (slot-value doduser 'deleted-state) "Y")
			  (clsql:update-record-from-slot doduser  'deleted-state))) list )))


(defun restore-deleted-cust-profile ( list tenant-id )
(mapcar (lambda (id)  (let ((doduser (car (clsql:select 'dod-cust-profile :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value doduser 'deleted-state) "N")
    (clsql:update-record-from-slot doduser 'deleted-state))) list ))




(defun create-customer(name address phone  email birthdate password salt city state zipcode company  )
  (let ((tenant-id (slot-value company 'row-id)))
 (clsql:update-records-from-instance (make-instance 'dod-cust-profile
						    :name name
						    :address address
						    :email email 
						    :password password 
						    :salt salt
						    :birthdate birthdate 
						    :phone phone
						    :city city 
						    :state state 
						    :zipcode zipcode
						    :tenant-id tenant-id
						    :cust-type "STANDARD"
						    :active-flag "N"
						    :deleted-state "N"))))
 

(defun create-guest-customer(company)
  (let ((tenant-id (slot-value company 'row-id))
	(customer-name (format nil "Guest Customer - ~A" (slot-value company 'name)))
	(existingguestcust (select-guest-customer company)))
    (unless existingguestcust (clsql:update-records-from-instance (make-instance 'dod-cust-profile
						    :name customer-name
						    :address (slot-value company 'address)
						    :email nil 
						    :password "demo"
						    :salt nil
						    :birthdate nil
						    :phone "9999999999"
						    :city (slot-value company 'city)
						    :state (slot-value company 'state)
						    :zipcode (slot-value company 'zipcode)
						    :tenant-id tenant-id
						    :cust-type "GUEST"
						    :active-flag "Y"
						    :deleted-state "N")))))



;;;;; Customer wallet related functions ;;;;;


(defun create-wallet(customer vendor company  )
  (let ((tenant-id (slot-value company 'row-id))
	(cust-id (slot-value customer 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
    (persist-wallet cust-id vendor-id tenant-id)))

(defun persist-wallet (cust-id vendor-id tenant-id)
 (clsql:update-records-from-instance (make-instance 'dod-cust-wallet
						    :cust-id cust-id
						    :vendor-id vendor-id 
						    :tenant-id tenant-id
				    		    :deleted-state "N")))

(defun check-wallet-balance (amount customer-wallet)
  (let ((cur-balance (slot-value customer-wallet  'balance)))
    (if (> cur-balance amount) T nil)))

(defun check-low-wallet-balance (customer-wallet) 
(if (< (slot-value customer-wallet 'balance) 50.00) T nil))

(defun check-zero-wallet-balance (customer-wallet)
(if (< (slot-value customer-wallet 'balance) 0.00) T nil)) 


(defun deduct-wallet-balance (amount customer-wallet)
(let ((cur-balance (slot-value customer-wallet 'balance)))
(progn  (setf (slot-value customer-wallet 'balance) (- cur-balance amount))
  (clsql:update-record-from-slot customer-wallet 'balance))))

(defun set-wallet-balance (amount customer-wallet)
 (progn  (setf (slot-value customer-wallet 'balance) amount)
	 (clsql:update-record-from-slot customer-wallet 'balance)))

(defun get-cust-wallets-for-vendor (vendor company)
  (let ((tenant-id (slot-value company 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
  (clsql:select 'dod-cust-wallet :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=  [:vendor-id] vendor-id]]
		:caching *dod-database-caching* :flatp t)))


(defun get-cust-wallet-by-vendor (customer vendor company) 
  (let ((tenant-id (slot-value company 'row-id))
	(cust-id (slot-value customer 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
  (car (clsql:select 'dod-cust-wallet :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:cust-id] cust-id]
		[=  [:vendor-id] vendor-id]]
		:caching *dod-database-caching* :flatp t))))

(defun get-cust-wallets (customer company) 
  (let ((tenant-id (slot-value company 'row-id))
	(cust-id (slot-value customer 'row-id)))
   (clsql:select 'dod-cust-wallet :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:cust-id] cust-id]]
		:caching *dod-database-caching* :flatp t)))





(defun get-cust-wallet-by-id (id company) 
  (let ((tenant-id (slot-value company 'row-id)))
	
   (car (clsql:select 'dod-cust-wallet :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:row-id] id]]
	
		:caching *dod-database-caching* :flatp t))))



