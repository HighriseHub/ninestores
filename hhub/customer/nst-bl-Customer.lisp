;;; nst-bl-Customer.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

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
	(copyCustomer-dbtodomain dbCustomer Customerobj)
	;; set the bo knowledget payload as the domain object
	(setf (bo-knowledge-payload dbCustomerKnowledge) Customerobj)
	Customerobj))))


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




;;; ===========================================================================
;;; nst-customer — adhara verbs + ferries (Step C of the CUSTOMER/VENDOR
;;; migration). Mirrors nst-bl-warehouse.lisp line-for-line in shape and
;;; error-handling; only the fields/persistence differ.
;;;
;;; DISPATCH NOTE: the shared ferries domain->response-list and render-json-on-
;;; a-list are defined ONCE in nst-bl-warehouse.lisp and dispatch per element
;;; through domain->response / render-json. This file therefore adds ONLY the
;;; per-nst-customer domain->response and the per-response render-json method,
;;; NOT the list wrappers.
;;;
;;; Persistence note: dod_cust_profile carries legacy NOT NULL columns that the
;;; nst-customer domain does not expose (username/password/active-flag/created/
;;; updated — credentials are DEPRECATED, moved to DOD_CUSTOMER_USERS). The
;;; make verb satisfies them on INSERT exactly as dod-bl-cus.lisp does
;;; (username<-email, password placeholder, active-flag "Y", created/updated).
;;; !update and the copy helper never touch those columns.
;;;
;;; UNIQUENESS: phone is the natural unique key for a customer within a tenant
;;; (see dod-bl-cus.lisp duplicate-customerp). ?exists is phone-based and make
;;; enforces it via a :before guard — the exact warehouse GSTIN pattern.
;;; ===========================================================================

(defparameter *cust-sort-whitelist*
  '((:row-id . :row-id) (:name . :name) (:city . :city)
    (:state . :state) (:phone . :phone) (:cust-type . :cust-type))
  "The ONLY columns enumerate may ORDER BY. sort-by is caller-controllable
   (eventually from HTTP params) — this whitelist is what stands between that
   and arbitrary ORDER BY construction. Extend deliberately, never accept a
   raw column from outside this list.")
(defparameter *nst-customer-business-fields*
  '(row-id name address phone email firstname lastname fullname salutation
    title birthdate picture-path city state country zipcode approved-flag
    approval-status approved-by cust-type active-flag email-add-verified
    suspend-flag upi-id legal-company-name gst-customer-type company-name
    legal-name gstin pan-number business-type organization-type
    gst-registration-type tan-number msme-number is-tax-exempt
    tax-exemption-cert business-established-date annual-turnover
    employee-count industry credit-limit payment-terms credit-days
    primary-contact-name primary-contact-phone primary-contact-email
    primary-contact-designation accounts-contact-name
    accounts-contact-phone accounts-contact-email bank-account-number
    bank-ifsc-code bank-name bank-branch bank-account-holder-name
    registered-address billing-address shipping-address registered-state
    registered-city registered-zipcode kyc-status kyc-verified-date
    kyc-verified-by kyc-documents blacklisted-vendors last-order-date
    total-orders total-spent loyalty-points)
  "Scalar dod_cust_profile business columns shared by nst-customer, the
   response model and the copy ferries, kept in one list so the three never
   drift. row-id is listed (written read-only: domaintodb skips it). Excludes
   deprecated creds (username/password/salt), DB audit (created/updated),
   tenant-id/deleted-state (lifecycle/inherited), and the :join relationship
   slots (company/customer-users/wallets/orders/kyc-verifier).")

(defparameter *nst-customer-json-keys*
  '((row-id . "rowId")
    (name . "name")
    (address . "address")
    (phone . "phone")
    (email . "email")
    (firstname . "firstName")
    (lastname . "lastName")
    (fullname . "fullname")
    (salutation . "salutation")
    (title . "title")
    (birthdate . "birthdate")
    (picture-path . "picturePath")
    (city . "city")
    (state . "state")
    (country . "country")
    (zipcode . "zipcode")
    (approved-flag . "approvedFlag")
    (approval-status . "approvalStatus")
    (approved-by . "approvedBy")
    (cust-type . "custType")
    (active-flag . "activeFlag")
    (email-add-verified . "emailAddVerified")
    (suspend-flag . "suspendFlag")
    (upi-id . "upiId")
    (legal-company-name . "legalCompanyName")
    (gst-customer-type . "gstCustomerType")
    (company-name . "companyName")
    (legal-name . "legalName")
    (gstin . "gstin")
    (pan-number . "panNumber")
    (business-type . "businessType")
    (organization-type . "organizationType")
    (gst-registration-type . "gstRegistrationType")
    (tan-number . "tanNumber")
    (msme-number . "msmeNumber")
    (is-tax-exempt . "isTaxExempt")
    (tax-exemption-cert . "taxExemptionCert")
    (business-established-date . "businessEstablishedDate")
    (annual-turnover . "annualTurnover")
    (employee-count . "employeeCount")
    (industry . "industry")
    (credit-limit . "creditLimit")
    (payment-terms . "paymentTerms")
    (credit-days . "creditDays")
    (primary-contact-name . "primaryContactName")
    (primary-contact-phone . "primaryContactPhone")
    (primary-contact-email . "primaryContactEmail")
    (primary-contact-designation . "primaryContactDesignation")
    (accounts-contact-name . "accountsContactName")
    (accounts-contact-phone . "accountsContactPhone")
    (accounts-contact-email . "accountsContactEmail")
    (bank-account-number . "bankAccountNumber")
    (bank-ifsc-code . "bankIfscCode")
    (bank-name . "bankName")
    (bank-branch . "bankBranch")
    (bank-account-holder-name . "bankAccountHolderName")
    (registered-address . "registeredAddress")
    (billing-address . "billingAddress")
    (shipping-address . "shippingAddress")
    (registered-state . "registeredState")
    (registered-city . "registeredCity")
    (registered-zipcode . "registeredZipcode")
    (kyc-status . "kycStatus")
    (kyc-verified-date . "kycVerifiedDate")
    (kyc-verified-by . "kycVerifiedBy")
    (kyc-documents . "kycDocuments")
    (blacklisted-vendors . "blacklistedVendors")
    (last-order-date . "lastOrderDate")
    (total-orders . "totalOrders")
    (total-spent . "totalSpent")
    (loyalty-points . "loyaltyPoints"))
  "camelCase wire key per response slot; drives render-json.")


;;; ---------------------------------------------------------------------------
;;; QUERY HELPERS  (nst- prefixed to avoid clobbering dod-bl-cus.lisp, which is
;;; still loaded during the migration window)
;;; ---------------------------------------------------------------------------
(defun nst-select-customer-by-id (id tenant-id)
  "Select a live dod-cust-profile by row-id within a tenant."
  (car (clsql:select 'dod-cust-profile
                     :where [and [= [:tenant-id] tenant-id]
                                 [= [:row-id] id]
                                 [= [:deleted-state] "N"]]
                     :caching *dod-database-caching* :flatp t)))

(defun nst-select-customer-by-phone (phone tenant-id)
  "Select a live dod-cust-profile by phone within a tenant."
  (car (clsql:select 'dod-cust-profile
                     :where [and [= [:phone] phone]
                                 [= [:tenant-id] tenant-id]
                                 [= [:deleted-state] "N"]]
                     :caching *dod-database-caching* :flatp t)))

(defun nst-build-customer-where (tenant-id &key name-like city state cust-type)
  "Build the WHERE clause list for enumerate. No arbitrary clause injection —
   every accepted key maps to a fixed column."
  (let ((clauses (list [= [:tenant-id] tenant-id]
                       [= [:deleted-state] "N"])))
    (when (and name-like (plusp (length (string-trim " " name-like))))
      (push [like [:name] (format nil "%~A%" (string-trim " " name-like))]
            clauses))
    (when city   (push [= [:city] city]   clauses))
    (when state  (push [= [:state] state] clauses))
    (when cust-type (push [= [:cust-type] cust-type] clauses))
    clauses))

;;; ---------------------------------------------------------------------------
;;; ?exists — by phone. Phone is the natural unique key for a customer within a
;;; tenant (see dod-bl-cus.lisp duplicate-customerp), so this also feeds the
;;; make :before uniqueness guard below — the warehouse GSTIN pattern.
;;; ---------------------------------------------------------------------------
(defmethod ?exists ((entity-class (eql 'nst-customer)) (phone string) (ctx domain-ctx))
  (with-db-call
    (nst-select-customer-by-phone phone (slot-value (domain-ctx-tenant ctx) 'row-id))))

;;; make :before — reject a duplicate customer for this tenant by phone.
(defmethod make :before ((entity-class (eql 'nst-customer)) (ctx domain-ctx)
                         &rest initargs)
  (let ((phone (getf initargs :phone)))
    (when (and phone (plusp (length (string-trim " " phone))))
      (when (?exists 'nst-customer phone ctx)
        (error "Customer with phone ~A already exists for this tenant." phone)))))

;;; make primary method — mirrors nst-bl-warehouse make.
(defmethod make ((entity-class (eql 'nst-customer)) (ctx domain-ctx) &rest initargs)
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (entity (apply #'make-instance 'nst-customer :tenant-id tenant-id initargs))
         (dbobj  (make-instance 'dod-cust-profile)))
    (nst-copy-customer-domaintodb entity dbobj)
    ;; Satisfy dod_cust_profile's legacy NOT NULL columns (same as dod-bl-cus
    ;; create-b2c/-b2b): username <- email, placeholder password, active + audit.
    (let ((emailv (email entity)))
      (setf (slot-value dbobj 'username) (or emailv ""))
      (setf (slot-value dbobj 'password) "PLACEHOLDER")
      (setf (slot-value dbobj 'active-flag) "Y")
      (setf (slot-value dbobj 'created)  (clsql:get-time))
      (setf (slot-value dbobj 'updated)  (clsql:get-time)))
    (let ((knowledge (with-nst-db-create (:source "nst-customer/make")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
            entity)
        (:F (error "Customer create rejected at DB write — row not inserted."))
        (:U (error 'hhub-database-error :errstring "Customer create failed — see log"))
        (:C (error "Unreachable: no :pre-flight form supplied to with-nst-db-create \
                     in this call — :C here means the macro contract changed"))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                          (bo-knowledge-truth knowledge)))))))

;;; fetch — returns a real nst-customer OR a Belnap sentinel, never bare nil.
(defmethod fetch ((entity-class (eql 'nst-customer)) (id string) (ctx domain-ctx))
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
        (bk (with-db-call (nst-select-customer-by-id (parse-integer id) tenant-id))))
    (if bk
        (let ((entity (make-instance 'nst-customer :tenant-id tenant-id))
              (dbobj (bo-knowledge-payload bk)))
          (nst-copy-customer-dbtodomain dbobj entity)
          entity)
        (make-instance 'nst-entity-nil :tenant-id tenant-id))))

;;; delete! — soft delete (deleted-state = "Y"), mirroring warehouse.
(defmethod delete! ((entity-class (eql 'nst-customer)) (row-id string) (ctx domain-ctx))
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (dbobj (nst-select-customer-by-id (parse-integer row-id) tenant-id)))
    (cond
      ((null dbobj)
       (make-instance 'nst-entity-nil :tenant-id tenant-id
                      :reason (format nil "Customer row-id ~A not found" row-id)))
      ((string= (deleted-state dbobj) "Y")
       (make-instance 'nst-entity-nil :tenant-id tenant-id
                      :reason (format nil "Customer row-id ~A already deleted" row-id)))
      (t
       (let ((knowledge (with-nst-db-delete (:source "nst-customer/delete!")
                           (setf (deleted-state dbobj) "Y")
                           (clsql:update-record-from-slot dbobj 'deleted-state)
                           dbobj)))
         (case (bo-knowledge-truth knowledge)
           (:T t)
           (:U (error 'hhub-database-error
                      :errstring (format nil "Customer delete failed, row-id ~A" row-id)))
           (otherwise (error "Unrecognized bo-knowledge-truth ~A"
                             (bo-knowledge-truth knowledge)))))))))

;;; !update — hydrate, CLOS partial-update from supplied initargs, persist.
(defmethod !update ((entity-class (eql 'nst-customer)) (row-id string) (ctx domain-ctx)
                    &rest update-args)
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (dbobj (nst-select-customer-by-id (parse-integer row-id) tenant-id)))
    (if (null dbobj)
        (make-instance 'nst-entity-nil :tenant-id tenant-id
                       :reason (format nil "Customer row-id ~A not found" row-id))
        (let ((entity (make-instance 'nst-customer :tenant-id tenant-id)))
          (nst-copy-customer-dbtodomain dbobj entity)          ;; hydrate current state
          (apply #'reinitialize-instance entity update-args)   ;; partial update
          (nst-copy-customer-domaintodb entity dbobj)
          (let ((knowledge (with-nst-db-update (:source "nst-customer/!update")
                              (clsql:update-records-from-instance dbobj)
                              dbobj)))
            (case (bo-knowledge-truth knowledge)
              (:T entity)
              (:U (error 'hhub-database-error
                         :errstring (format nil "Customer update failed, row-id ~A" row-id)))
              (otherwise (error "Unrecognized bo-knowledge-truth ~A"
                                (bo-knowledge-truth knowledge)))))))))

;;; enumerate — tenant-scoped listing with a whitelisted sort.
(defmethod enumerate ((entity-class (eql 'nst-customer)) (ctx domain-ctx)
                      &key name-like city state cust-type
                        (sort-by :name) (sort-dir :asc))
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (sort-col (cdr (assoc sort-by *cust-sort-whitelist*))))
    (unless sort-col
      (error "Enumerate sort-by ~A not in the customer sort whitelist." sort-by))
    (clsql:select 'dod-cust-profile
                  :where (apply #'clsql:sql-and
                                (nst-build-customer-where
                                 tenant-id :name-like name-like :city city
                                 :state state :cust-type cust-type))
                  :order-by (list (list sort-col sort-dir))
                  :limit 200
                  :caching *dod-database-caching* :flatp t)));
;;; domain->response — the OUT ferry. Copies the island entity into the
;;; outbound boundary model. Shared for a list via domain->response-list.
(defmethod domain->response ((entity nst-customer) (ctx domain-ctx))
  (let ((r (make-instance 'nst-customer-response-model)))
    (setf (company r) (company entity))
    (dolist (f *nst-customer-business-fields*)
      (setf (slot-value r f) (slot-value entity f)))
    r))

(defmethod render-json ((r nst-customer-response-model) (ctx domain-ctx))
  (json:encode-json-to-string
   (loop for (f . key) in *nst-customer-json-keys*
         collect (cons key (slot-value r f)))))

;;; ---------------------------------------------------------------------------
;;; COPY FERRIES — nst-customer domain <-> dod-cust-profile ORM row.
;;; ---------------------------------------------------------------------------
(defun nst-copy-customer-domaintodb (source destination)
  "domain nst-customer -> dod-cust-profile. Copies every scalar business field,
   skipping row-id on write (DB autoincrement / preserved on a fetched row).
   Pins tenant-id and live deleted-state. Never touches legacy creds/audit."
  (dolist (f *nst-customer-business-fields*)
    (unless (eq f 'row-id)
      (setf (slot-value destination f) (slot-value source f))))
  (setf (slot-value destination 'tenant-id) (slot-value source 'tenant-id))
  (setf (slot-value destination 'deleted-state) "N")
  destination)

(defun nst-copy-customer-dbtodomain (source destination)
  "dod-cust-profile -> domain nst-customer (incl. row-id). tenant-id is set by
   the verb; join relationships are not copied into scalar domain state."
  (dolist (f *nst-customer-business-fields*)
    (setf (slot-value destination f) (slot-value source f)))
  destination)


;;; ===============================================================================
;;; RELOCATED from dod-bl-cus.lisp (retired). Legacy customer BL layer:
;;; GSTIN / B2B / B2C queries, KYC + metrics, wallet ops, pincode adapters,
;;; and the select / create / update / delete helper layer still used by dod-ui-cus.
;;; ===============================================================================
;;; Customer Profile Queries

(defun find-customer-by-gstin (gstin)
  "Find customer by GSTIN"
  (car (clsql:select 'dod-cust-profile
                     :where [and [= [gstin] gstin]
                                 [= [active-flag] "Y"]
                                 [= [deleted-state] "N"]]
                     :flatp t)))

(defun find-customer-by-company-name (company-name)
  "Find customer by company name"
  (clsql:select 'dod-cust-profile
                :where [and [like [company-name] (concatenate 'string "%" company-name "%")]
                            [= [active-flag] "Y"]
                            [= [deleted-state] "N"]]
                :flatp t))

(defun find-customer-by-pan (pan-number)
  "Find customer by PAN"
  (car (clsql:select 'dod-cust-profile
                     :where [and [= [pan-number] pan-number]
                                 [= [deleted-state] "N"]]
                     :flatp t)))

(defun get-b2b-customers (&optional (tenant-id nil))
  "Get all B2B customers (with GSTIN)"
  (clsql:select 'dod-cust-profile
                :where (if tenant-id
                          [and [= [gst-customer-type] "B2B"]
                               [is-not-null [gstin]]
                               [= [active-flag] "Y"]
                               [= [tenant-id] tenant-id]
                               [= [deleted-state] "N"]]
                          [and [= [gst-customer-type] "B2B"]
                               [is-not-null [gstin]]
                               [= [active-flag] "Y"]
                               [= [deleted-state] "N"]])
                :order-by '([company-name])
                :flatp t))

(defun get-b2c-customers (&optional (tenant-id nil))
  "Get all B2C customers (no GSTIN or INDIVIDUAL type)"
  (clsql:select 'dod-cust-profile
                :where (if tenant-id
                          [and [or [= [gst-customer-type] "B2C"]
                                   [is-null [gstin]]
                                   [= [business-type] "INDIVIDUAL"]]
                               [= [active-flag] "Y"]
                               [= [tenant-id] tenant-id]
                               [= [deleted-state] "N"]]
                          [and [or [= [gst-customer-type] "B2C"]
                                   [is-null [gstin]]
                                   [= [business-type] "INDIVIDUAL"]]
                               [= [active-flag] "Y"]
                               [= [deleted-state] "N"]])
                :order-by '([name])
                :flatp t))

;;; Customer Type Detection

(defun is-b2b-customer-p (customer)
  "Check if customer is B2B (has GSTIN)"
  (and (slot-value customer 'gstin)
       (= 15 (length (string-trim " " (slot-value customer 'gstin))))))

(defun is-b2c-customer-p (customer)
  "Check if customer is B2C (no GSTIN)"
  (not (is-b2b-customer-p customer)))

(defun get-customer-display-name (customer)
  "Get appropriate display name based on customer type"
  (if (is-b2b-customer-p customer)
      (or (slot-value customer 'company-name)
          (slot-value customer 'legal-name)
          (slot-value customer 'name))
      (or (slot-value customer 'fullname)
          (slot-value customer 'name)
          (format nil "~A ~A" 
                  (slot-value customer 'firstname)
                  (slot-value customer 'lastname)))))

;;; KYC Management

(defun update-kyc-status (customer-id status verified-by)
  "Update KYC status for a customer"
  (let ((customer (car (clsql:select 'dod-cust-profile
                                     :where [= [row-id] customer-id]
                                     :flatp t))))
    (when customer
      (setf (slot-value customer 'kyc-status) status)
      (when (string= status "VERIFIED")
        (setf (slot-value customer 'kyc-verified-date) (clsql:get-time))
        (setf (slot-value customer 'kyc-verified-by) verified-by))
      (clsql:update-records-from-instance customer)
      customer)))

;;; Business Metrics

(defun update-customer-metrics (customer-id order-amount)
  "Update customer's order metrics after a new order"
  (let ((customer (car (clsql:select 'dod-cust-profile
                                     :where [= [row-id] customer-id]
                                     :flatp t))))
    (when customer
      (incf (slot-value customer 'total-orders))
      (incf (slot-value customer 'total-spent) order-amount)
      (setf (slot-value customer 'last-order-date) (clsql:get-time))
      (clsql:update-records-from-instance customer)
      customer)))

(defun get-top-customers (limit &key (by-amount t))
  "Get top customers by spend or order count"
  (clsql:select 'dod-cust-profile
                :where [and [= [active-flag] "Y"]
                            [= [deleted-state] "N"]]
                :order-by (if by-amount
                             '(([total-spent] :desc))
                             '(([total-orders] :desc)))
                :limit limit
                :flatp t))

;;; GST Validation

(defun validate-gstin-format (gstin)
  "Validate GSTIN format (15 chars, specific pattern)"
  (and gstin
       (= 15 (length gstin))
       (cl-ppcre:scan "^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$" 
                      gstin)))

(defun extract-pan-from-gstin (gstin)
  "Extract PAN number from GSTIN (characters 3-12)"
  (when (validate-gstin-format gstin)
    (subseq gstin 2 12)))

(defun extract-state-code-from-gstin (gstin)
  "Extract state code from GSTIN (first 2 characters)"
  (when (validate-gstin-format gstin)
    (subseq gstin 0 2)))

(defun auto-populate-from-gstin (customer)
  "Auto-populate PAN and state from GSTIN if not set"
  (when (and (slot-value customer 'gstin)
             (validate-gstin-format (slot-value customer 'gstin)))
    (unless (slot-value customer 'pan-number)
      (setf (slot-value customer 'pan-number)
            (extract-pan-from-gstin (slot-value customer 'gstin))))
    (unless (slot-value customer 'registered-state)
      (let ((state-code (extract-state-code-from-gstin (slot-value customer 'gstin))))
        (setf (slot-value customer 'registered-state)
              (get-state-name-from-code state-code))))
    (clsql:update-records-from-instance customer)))


(defun get-state-name-from-code (state-code)
 (gethash state-code *NSTGSTSTATECODES-HT*))



;;; Customer Creation

(defun create-b2b-customer (company-name gstin &key legal-name email phone 
                                          business-type organization-type
                                          primary-contact-name tenant-id)
  "Create a new B2B customer"
  (let ((customer (make-instance 'dod-cust-profile
                                 :company-name company-name
                                 :legal-name (or legal-name company-name)
                                 :name company-name
                                 :gstin gstin
                                 :gst-customer-type "B2B"
                                 :business-type (or business-type "OTHER")
                                 :organization-type (or organization-type "COMPANY")
                                 :email email
                                 :phone phone
                                 :primary-contact-name primary-contact-name
                                 :username email  ; Temporary - will use DOD_CUSTOMER_USERS
                                 :password "PLACEHOLDER"  ; Will be set via DOD_CUSTOMER_USERS
                                 :active-flag "Y"
                                 :created (clsql:get-time)
                                 :updated (clsql:get-time)
                                 :tenant-id tenant-id
                                 :deleted-state "N")))
    
    ;; Auto-populate from GSTIN
    (auto-populate-from-gstin customer)
    
    (clsql:update-records-from-instance customer)
    customer))

(defun create-b2c-customer (name email phone &key firstname lastname tenant-id)
  "Create a new B2C customer"
  (make-instance 'dod-cust-profile
                 :name name
                 :firstname firstname
                 :lastname lastname
                 :fullname name
                 :email email
                 :phone phone
                 :gst-customer-type "B2C"
                 :business-type "INDIVIDUAL"
                 :organization-type "INDIVIDUAL"
                 :username email
                 :password "PLACEHOLDER"
                 :active-flag "Y"
                 :created (clsql:get-time)
                 :updated (clsql:get-time)
                 :tenant-id tenant-id
                 :deleted-state "N")) 


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


(defun get-pincode-details-adapter (pincode)
  "TCUF Boundary Adapter for Pincode lookup. 
   Contract: Returns (ADDRESS-INSTANCE/NIL TCUF-STATUS)."
  (let* ((address (make-instance 'address))
         (param-name (list "api-key" "format" "offset" "limit" "filters[pincode]"))
         (param-values (list *hhubapi.gov.in.key* "json" "0" "1" (format nil "~A" pincode)))
         (param-alist (pairlis param-name param-values)))

    (handler-case
        (multiple-value-bind (body status)
            ;; Drakma call. We capture the body (1st value) and status code (2nd value).
            (drakma:http-request *hhubgetpincodeurlexternal*
                                 :method :GET
                                 :parameters param-alist)

          ;; --- INTERPRETATION LOGIC (MAPPING STATUS CODE) ---

          (cond
            ;; 1. SUCCESS: HTTP 200 (Proceed to Data Quality Check)
            ((= status 200)
             (handler-case
                 (let* ((json-response (json:decode-json-from-string (map 'string 'code-char body)))
			(locality (cdr (assoc :OFFICENAME (nth 1 (nth 24 json-response)) :test 'equal)))
			(city (cdr (assoc :DISTRICTNAME (nth 1 (nth 24 json-response)) :test 'equal)))
			(division (cdr (assoc :DIVISIONNAME (nth 1 (nth 24 json-response)) :test 'equal)))
			(state (cdr (assoc :STATENAME (nth 1 (nth 24 json-response)) :test 'equal))))
		   (format t "locality=~A, city=~A, division =~A, state=~A" locality city division state)
                   ;; --- DATA QUALITY CHECK (MAPPING JSON CONTENT) ---
                   (if (and locality city state)
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
			 (setf (slot-value address 'state) state)
			 (values address :T))
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
			 (setf (slot-value address 'state) "Not Found")
			 ;; Data is partially missing (e.g., locality is nil, but city/state exist)
                         (format t "~&[ADAPTER F] Pincode ~A data incomplete. Mapping to :F." pincode)
                         (values nil :F)))) ; Treat incomplete data as a Definitive Failure (F)
               ;; Catch JSON parsing errors (Malformed response)
               (error (e)
                 (format t "~&[ADAPTER C] JSON Parsing Error: ~A. Mapping to CONTRADICTION (:C)." e)
                 (values nil :C))))
             
            
            ;; 2. DEFINITIVE FAILURE: HTTP 4xx (Client/Not Found Errors)
            ((<= 400 status 499)
             (format t "~&[ADAPTER F] HTTP ~A Pincode lookup error. Mapping to :F." status)
             (values nil :F))
            
            ;; 3. UNKNOWN: HTTP 5xx (Server Errors, potentially transient)
            ((<= 500 status 599)
             (format t "~&[ADAPTER U] HTTP ~A Pincode service error. Mapping to :U." status)
             (values nil :U))
            
            ;; 4. CONTRADICTION: Other unexpected codes (3xx redirects, etc.)
            (t
             (format t "~&[ADAPTER C] Unexpected HTTP status ~A. Mapping to :C." status)
             (values nil :C))))

      ;; --- EXCEPTION HANDLING (MAPPING CHAOS) ---
      
      ;; Maps network/timeout Lisp condition to :U
      (nst-api-timeout-error ()
        (format t "~&[ADAPTER U] Network Timeout. Mapping to UNKNOWN (:U).")
        (values nil :U))
        
      ;; Catch-all for any other Lisp error (Network issues not caught above, etc.)
      (error (e)
        (format t "~&[ADAPTER C] Unhandled Lisp Error in Adapter: ~A. Mapping to CONTRADICTION (:C)." e)
        (values nil :C)))))

(defun getpincodedetails (pincode)
  (let* ((pcodedata (gethash pincode *NST-ALL-INDIA-PINCODES*))
	 (address (make-instance 'Address))
	 (locality (if pcodedata (slot-value pcodedata 'office-name)))
	 (city (if pcodedata (slot-value pcodedata 'district)))
	 (division (if pcodedata (slot-value pcodedata 'division-name)))
	 (state (if pcodedata (slot-value pcodedata 'state-name))))
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
	 

(defun getpincodedetails-old (pincode)
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

(defun select-customer-list-by-phone (phone-like-clause company)
  (let ((tenant-id (slot-value company 'row-id)))
    (clsql:select 'dod-cust-profile :where [and
		  [= [:deleted-state] "N"]
		  [= [:cust-type] "STANDARD"]
		  [= [:tenant-id] tenant-id]
		  [= [:active-flag] "Y"]
		  [like  [:phone] phone-like-clause]]
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
		       [= [:cust-type] "STANDARD"]
		       [= [:active-flag] "Y"]]
		       :caching *dod-database-caching* :flatp t)))


(defun select-customers-for-vendor (vendor company)
  (let* ((wallets (get-cust-wallets-for-vendor vendor company))
       (mycustomers (remove nil (mapcar (lambda (wallet)
                                          (let* ((customer (slot-value wallet 'customer))
                                                 (cust-type (slot-value customer 'cust-type)))
                                            (when (equal cust-type "STANDARD") customer))) wallets))))
    mycustomers))

(defun select-customer-for-vendor-by-phone (phone vendor company)
  (let* ((wallets (get-cust-wallets-for-vendor vendor company))
	 (mycustomer (car (remove nil (mapcar (lambda (wallet)
                                            (let* ((customer (slot-value wallet 'customer))
                                                   (cust-type (slot-value customer 'cust-type))
						   (cust-phone (slot-value customer 'phone)))
                                              (when (and (equal cust-type "STANDARD")
							 (equal cust-phone phone)) customer))) wallets)))))
    mycustomer))


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
						       :active-flag "Y"
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



