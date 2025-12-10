;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.
;; DO NOT COMPILE THIS FILE USING CTRL + C CTRL + K (OR CTRL + CK)
;; DO NOT ADD THIS FILE TO COMPILE.LISP FOR MASS COMPILATION. 


(defmethod ProcessCreateRequest ((adapter CustomerAdapter) (requestmodel CustomerRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'CustomerService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas CustomerDBService) (bo Customer))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'database-table-object-name-here)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))



(defmethod doCreate ((service CustomerService) (requestmodel CustomerRequestModel))
  (let* ((Customerdbservice (make-instance 'CustomerDBService))
	 (vendor (vendor requestmodel))
	 (customer (customer requestmodel))
	 (row-id (row-id requestmodel))
	 (name (name requestmodel))
	 (address (address requestmodel))
	 (phone (phone requestmodel))
	 (email (email requestmodel))
	 (firstname (firstname requestmodel))
	 (lastname (lastname requestmodel))
	 (salutation (salutation requestmodel))
	 (title (title requestmodel))
	 (birthdate (birthdate requestmodel))
	 (city (city requestmodel))
	 (state (state requestmodel))
	 (country (country requestmodel))
	 (zipcode (zipcode requestmodel))
	 (picture-path (picture-path requestmodel))
	 (password (password requestmodel))
	 (salt (salt requestmodel))
	 (cust-type (cust-type requestmodel))
	 (email-add-verified (email-add-verified requestmodel))
	 (company (company requestmodel))
	 (domainobj (createCustomerobject row-id name address phone email firstname lastname salutation title birthdate city state country zipcode picture-path password salt cust-type email-add-verified vendor customer company )))
         ;; Initialize the DB Service
    (init Customerdbservice domainobj)
    (copy-businessobject-to-dbobject Customerdbservice)
    (db-save Customerdbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createCustomerobject (row-id name address phone email firstname lastname salutation title birthdate city state country zipcode picture-path password salt cust-type email-add-verified vendor customer company)
  (let* ((domainobj  (make-instance 'Customer 
				       :row-id row-id
				       :name name
				       :address address
				       :phone phone
				       :email email
				       :firstname firstname
				       :lastname lastname
				       :salutation salutation
				       :title title
				       :birthdate birthdate
				       :city city 
				       :state state
				       :country country
				       :zipcode zipcode
				       :picture-path picture-path
				       :password password
				       :salt salt
				       :cust-type cust-type
				       :email-add-verified email-add-verified
				       :deleted-state "N"
				       :active-flag "Y"
				       :vendor vendor
				       :customer customer
				       :company company)))
    domainobj))

(defmethod Copy-BusinessObject-To-DBObject ((dbas CustomerDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyCustomer-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copyCustomer-domaintodb (source destination) 
  (with-slots (row-id name address phone email firstname lastname salutation title birthdate city state country zipcode picture-path password salt cust-type email-add-verified company) destination
    (setf company (slot-value source 'company))
    (setf row-id (slot-value source 'row-id))
    (setf name (slot-value source 'name))
    (setf address (slot-value source 'address))
    (setf phone (slot-value source 'phone))
    (setf email (slot-value source 'email))
    (setf firstname (slot-value source 'firstname))
    (setf lastname (slot-value source 'lastname))
    (setf salutation (slot-value source 'salutation))
    (setf title (slot-value source 'title))
    (setf birthdate (slot-value source 'birthdate))
    (setf city (slot-value source 'city))
    (setf state (slot-value source 'state))
    (setf country (slot-value source 'country))
    (setf zipcode (slot-value source 'zipcode))
    (setf picture-path (slot-value source 'picture-path))
    (setf password (slot-value source 'password))
    (setf salt (slot-value source 'salt))
    (setf cust-type (slot-value source 'cust-type))
    (setf email-add-verified (slot-value source 'email-add-verified))
    destination))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter CustomerAdapter) (requestmodel CustomerRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'CustomerService))
  ;; call the parent ProcessUpdate
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter CustomerAdapter) (requestmodel CustomerRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'CustomerService))
  (call-next-method))

(defmethod doreadall ((service CustomerService) (requestmodel CustomerRequestModel))
  (let* ((comp (company requestmodel))
	 (domainobjlst (select-customers-for-company comp)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance 'Customer)))
		(copyCustomer-dbtodomain object domainobject))) domainobjlst)))

(defmethod CreateViewModel ((presenter CustomerPresenter) (responsemodel ResponseModelNIL))
  (call-next-method))

(defmethod CreateViewModel ((presenter CustomerPresenter) (responsemodel ResponseModelUnknown))
  (call-next-method))

(defmethod CreateViewModel ((presenter CustomerPresenter) (responsemodel ResponseModelContradiction))
  (call-next-method))

(defmethod CreateViewModel ((presenter CustomerPresenter) (responsemodel CustomerResponseModel))
  (let ((viewmodel (make-instance 'CustomerViewModel)))
    (with-slots (row-id name address phone email firstname lastname salutation title birthdate city state country zipcode picture-path cust-type email-add-verified  company ) responsemodel
      (setf (slot-value viewmodel 'row-id) row-id)
      (setf (slot-value viewmodel 'name) name)
      (setf (slot-value viewmodel 'address) address)
      (setf (slot-value viewmodel 'phone) phone)
      (setf (slot-value viewmodel 'email) email)
      (setf (slot-value viewmodel 'firstname) firstname)
      (setf (slot-value viewmodel 'lastname) lastname)
      (setf (slot-value viewmodel 'salutation) salutation)
      (setf (slot-value viewmodel 'title) title)
      (setf (slot-value viewmodel 'birthdate) birthdate)
      (setf (slot-value viewmodel 'city) city)
      (setf (slot-value viewmodel 'state) state)
      (setf (slot-value viewmodel 'country) country)
      (setf (slot-value viewmodel 'zipcode) zipcode)
      (setf (slot-value viewmodel 'picture-path) picture-path)
      (setf (slot-value viewmodel 'cust-type) cust-type)
      (setf (slot-value viewmodel 'email-add-verified) email-add-verified)
      (setf (slot-value viewmodel 'company) company)
      viewmodel)))
  

(defmethod ProcessResponse ((adapter CustomerAdapter) (busobj Customer))
  (let ((responsemodel (make-instance 'CustomerResponseModel)))
    (setf responsemodel (createresponsemodel adapter busobj responsemodel))
    responsemodel))
(defmethod ProcessResponse ((adapter CustomerAdapter) (busobj BusinessObjectNIL))
  (call-next-method))

(defmethod ProcessResponseList ((adapter CustomerAdapter) Customerlist)
  (mapcar (lambda (domainobj)
	    (let ((responsemodel (make-instance 'CustomerResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) Customerlist))

(defmethod CreateAllViewModel ((presenter CustomerPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))

(defmethod CreateResponseModel ((adapter CustomerAdapter) (source Customer) (destination ResponseModelNIL))
  (call-next-method))

(defmethod CreateResponseModel ((adapter CustomerAdapter) (source Customer) (destination ResponseModelUnknown))
  (call-next-method))

(defmethod CreateResponseModel ((adapter CustomerAdapter) (source Customer) (destination ResponseModelContradiction))
  (call-next-method))


(defmethod CreateResponseModel ((adapter CustomerAdapter) (source Customer) (destination CustomerResponseModel))
  :description "source = Customer destination = CustomerResponseModel"
  (with-slots (row-id name address phone email firstname lastname salutation title birthdate city state country zipcode picture-path  cust-type email-add-verified company) destination  
    (setf row-id (slot-value source 'row-id))
    (setf name (slot-value source 'name))
    (setf address (slot-value source 'address))
    (setf phone (slot-value source 'phone))
    (setf email (slot-value source 'email))
    (setf firstname (slot-value source 'firstname))
    (setf lastname (slot-value source 'lastname))
    (setf salutation (slot-value source 'salutation))
    (setf title (slot-value source 'title))
    (setf birthdate (slot-value source 'birthdate))
    (setf city (slot-value source 'city))
    (setf state (slot-value source 'state))
    (setf country (slot-value source 'country))
    (setf zipcode (slot-value source 'zipcode))
    (setf picture-path (slot-value source 'picture-path))
    (setf cust-type (slot-value source 'cust-type))
    (setf email-add-verified (slot-value source 'email-add-verified))
    (setf company (slot-value source 'company))
    destination))

(defmethod doupdate ((service CustomerService) (requestmodel CustomerRequestModel))
  (with-slots (row-id name address phone email firstname lastname salutation title birthdate city state country zipcode picture-path password salt cust-type email-add-verified  company) requestmodel
  (let* ((Customerdbservice (make-instance 'CustomerDBService))
	 (Customerdbobj (select-customer-by-phone phone company))
	 (domainobj (make-instance 'Customer)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when Customerdbobj 
      (setf (slot-value Customerdbobj 'row-id) row-id)
      (setf (slot-value Customerdbobj 'name) name)
      (setf (slot-value Customerdbobj 'address) address)
      (setf (slot-value Customerdbobj 'phone) phone)
      (setf (slot-value Customerdbobj 'email) email)
      (setf (slot-value Customerdbobj 'firstname) firstname)
      (setf (slot-value Customerdbobj 'lastname) lastname)
      (setf (slot-value Customerdbobj 'salutation) salutation)
      (setf (slot-value Customerdbobj 'title) title)
      (setf (slot-value Customerdbobj 'birthdate) birthdate)
      (setf (slot-value Customerdbobj 'city) city)
      (setf (slot-value Customerdbobj 'state) state)
      (setf (slot-value Customerdbobj 'country) country)
      (setf (slot-value Customerdbobj 'zipcode) zipcode)
      (setf (slot-value Customerdbobj 'picture-path) picture-path)
      (setf (slot-value Customerdbobj 'password) password)
      (setf (slot-value Customerdbobj 'salt) salt)
      (setf (slot-value Customerdbobj 'cust-type) cust-type)
      (setf (slot-value Customerdbobj 'email-add-verified) email-add-verified))

     ;;  FIELD UPDATE CODE ENDS HERE. 
    
    (setf (slot-value Customerdbservice 'dbobject) Customerdbobj)
    (setf (slot-value Customerdbservice 'businessobject) domainobj)
    
    (setcompany Customerdbservice company)
    (db-save Customerdbservice)
    ;; Return the newly created UPI domain object
    (copyCustomer-dbtodomain Customerdbobj domainobj))))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter CustomerAdapter) (requestmodel CustomerRequestModel))
  :description "Adapter service method to read a single Customer"
  (setf (slot-value adapter 'businessservice) (find-class 'CustomerService))
  (call-next-method))

(defmethod doread ((service CustomerService) (requestmodel CustomerRequestModel))
  (let* ((comp (company requestmodel))
	 (phone (phone requestmodel))
	 (dbCustomerKnowledge (with-db-call (select-customer-by-phone phone comp) "DB/Customer"))
	 (Customerobj (make-instance 'Customer)))
    (setf (bo-knowledge service) dbCustomerKnowledge)
    (setf (slot-value Customerobj 'company) comp)
    (when (eq (bo-knowledge-truth dbCustomerKnowledge) :T)
      (let ((dbCustomer (bo-knowledge-payload dbCustomerKnowledge)))
	(copyCustomer-dbtodomain dbCustomer Customerobj)))
     Customerobj))


(defun copyCustomer-dbtodomain (source destination)
  (let* ((comp (select-company-by-id (slot-value source 'tenant-id))))
    (with-slots (row-id name address phone email firstname lastname salutation title birthdate city state country zipcode picture-path password salt cust-type email-add-verified  company) destination
      (setf company comp)
      (setf row-id (slot-value source 'row-id))
      (setf name (slot-value source 'name))
      (setf address (slot-value source 'address))
      (setf phone (slot-value source 'phone))
      (setf email (slot-value source 'email))
      (setf firstname (slot-value source 'firstname))
      (setf lastname (slot-value source 'lastname))
      (setf salutation (slot-value source 'salutation))
      (setf title (slot-value source 'title))
      (setf birthdate (slot-value source 'birthdate))
      (setf city (slot-value source 'city))
      (setf state (slot-value source 'state))
      (setf country (slot-value source 'country))
      (setf zipcode (slot-value source 'zipcode))
      (setf picture-path (slot-value source 'picture-path))
      (setf password (slot-value source 'password))
      (setf salt (slot-value source 'salt))
      (setf cust-type (slot-value source 'cust-type))
      (setf email-add-verified (slot-value source 'email-add-verified))
      destination)))

(defmethod Render ((view View) (viewmodel ViewModelNIL))
  (call-next-method))

(defmethod Render ((view View) (viewmodel ViewModelUnknown))
  (call-next-method))

(defmethod Render ((view View) (viewmodel ViewModelContradiction))
  (call-next-method))

(defmethod Render ((view JSONView) (viewmodel CustomerViewModel))
  (let* ((templist '())
         (appendlist '())
         (mylist '())
         (firstname (slot-value viewmodel 'firstname))
         (lastname (slot-value viewmodel 'lastname))
	 (custname (slot-value viewmodel 'name))
	 (email (slot-value viewmodel 'email))
	 (address (slot-value viewmodel 'address))
         (phone (slot-value viewmodel 'phone))
         (city (slot-value viewmodel 'city))
         (state (slot-value viewmodel 'state))
         (zipcode (slot-value viewmodel 'zipcode)))

    ;; If minimum address fields exist
    (if (and phone city state zipcode)
        (progn
          ;; Combine first + last name as "name"
	  (setf templist (acons "custname" (format nil "~A" custname) templist))
	  (setf templist (acons "fullname"
                                (format nil "~A ~A"
                                        (or firstname "")
                                        (or lastname ""))
                                templist))
	  (setf templist (acons "email" (format nil "~A" email) templist))
          (setf templist (acons "address"  (format nil "~A" address) templist))
          (setf templist (acons "city"     (format nil "~A" city)    templist))
          (setf templist (acons "state"    (format nil "~A" state)   templist))
          (setf templist (acons "zipcode"  (format nil "~A" zipcode) templist))
          (setf templist (acons "phone"    (format nil "~A" phone)   templist))

          (push templist appendlist)

          ;; API format expected by JS
          (setf mylist (acons "addresses" appendlist mylist))
          (setf mylist (acons "success" 1 mylist)))

        ;; Else: failure response
        (progn
          (setf mylist (acons "addresses" '() mylist))
          (setf mylist (acons "success" 0 mylist))))

    ;; Encode JSON
    (let ((jsondata (json:encode-json-to-string mylist)))
      (setf (slot-value view 'jsondata) jsondata)
      jsondata)))


