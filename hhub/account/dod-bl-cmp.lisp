;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)


(defun get-account-currency (company)
  (let* ((country (slot-value company 'country))
	 (currency-ht (hhub-get-cached-currencies-ht))
	 (currency (nth 1 (gethash country currency-ht))))
    (if currency currency *HHUBDEFAULTCURRENCY*)))
    
(defun generate-account-ext-url (account)
  :description "Generates an external URL for an account, which can be shared with external entities"
  (let* ((tenant-id (slot-value account 'row-id))
	 (param-csv (format nil "tenant-id~C~A" #\linefeed tenant-id))
	 (param-base64 (cl-base64:string-to-base64-string param-csv)))
    (format nil "~A/hhub/displaystore?key=~A" *siteurl* param-base64)))


(defun new-dod-company(cname caddress city state country zipcode website cmp-type subscription-plan createdby updatedby)
  (let  ((company-name cname)
	 (company-address caddress))
	(clsql:update-records-from-instance (make-instance 'dod-company
							   :name company-name
							   :address company-address
							   :city city
							   :state state 
							   :country country
							   :zipcode zipcode
							   :website website 
							   :deleted-state "N"
							   :suspend-flag "N"
							   :tshirt-size "SM"
							   :revenue 0
							   :cmp-type cmp-type
							   :subscription-plan subscription-plan
							   :created-by createdby
							   :updated-by updatedby))))



(defun suspendaccount (tenant-id)
  (let* ((company (select-company-by-id tenant-id))
	(suspend-flag (slot-value company 'suspend-flag)))
    (unless (com-hhub-attribute-company-issuspended suspend-flag)
      (setf (slot-value company 'suspend-flag) "Y"))
    (update-company company)
    (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* (hhub-gen-globally-cached-lists-functions))))

(defun restoreaccount (tenant-id)
  (let* ((company (select-company-by-id tenant-id))
	(suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (setf (slot-value company 'suspend-flag) "N"))
    (update-company company)
    (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* (hhub-gen-globally-cached-lists-functions))))



;(defun get-count-company-customers (company) 
;  (let ((old-func (symbol-function 'count-company-customers))
;	(previous (make-hash-table)))
;    (defun count-company-customers (company)
;      (or (gethash company previous)
;	  (setf (gethash company previous) (funcall old-func company))))))

(defun account-created-days-ago (account)
  (let ((created (slot-value account 'created)))
    (clsql-sys:duration-reduce (clsql-sys:time-difference (clsql-sys:get-time) created) :day)))
  

(defun trial-account-days-to-expiry (account)
  (let ((created (slot-value account 'created))
	(subsplan (slot-value account 'subscription-plan)))
    (when (equal subsplan "TRIAL")
      (- (clsql-sys:duration-reduce (clsql-sys:make-duration :day *HHUBTRIALCOMPANYEXPIRYDAYS*) :day) (clsql-sys:duration-reduce (clsql-sys:time-difference (clsql-sys:get-time) created) :day)))))
  

(defun trial-account-expired-p (account)
  (let ((created (slot-value account 'created))
	(subsplan (slot-value account 'subscription-plan)))
    (when (equal subsplan "TRIAL")
      (clsql-sys:duration> (clsql-sys:time-difference (clsql-sys:get-time) created)  (clsql-sys:make-duration :day *HHUBTRIALCOMPANYEXPIRYDAYS*))))) 
    
(defun count-company-customers (company) 
 (let ((tenant-id (slot-value company 'row-id))) 
    (first (clsql:select [count [*]] :from 'dod-cust-profile  :where 
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]]   :caching nil :flatp t ))))

(defun count-company-vendors (company) 
 (let ((tenant-id (slot-value company 'row-id))) 
    (first (clsql:select [count [*]] :from 'dod-vend-profile  :where 
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]]   :caching nil :flatp t ))))



(defun equal-companiesp (cmp1 cmp2)
  (equal (slot-value cmp1 'row-id) (slot-value cmp2 'row-id)))


(defun select-company-by-name (name-like-clause)
(car (clsql:select 'dod-company :where [and
		[= [:deleted-state] "N"]
		[like  [:name] name-like-clause]]
		:caching *dod-database-caching* :flatp t)))


(defun select-companies-by-name (name-like-clause)
 (clsql:select 'dod-company :where [and
		[= [:deleted-state] "N"]
		[like  [:name] (format NIL "%~a%"  name-like-clause)]]
		:caching *dod-database-caching* :flatp t))

(defun select-companies-by-pincode (name-like-clause)
 (clsql:select 'dod-company :where [and
		[= [:deleted-state] "N"]
		[like  [:zipcode] (format NIL "%~a%"  name-like-clause)]]
		:caching *dod-database-caching* :flatp t))




(defun select-company-by-id (id)
(car (clsql:select 'dod-company :where [and
		[= [:deleted-state] "N"]
		[= [:row-id] id]]
		:caching *dod-database-caching* :flatp t)))



(defun get-system-companies ()
  (clsql:select 'dod-company  :where
		[and
		[= [:deleted-state] "N"]
		[<> [:name] "super"]] ; Avoid super company in any list. 
			      :caching *dod-database-caching* :flatp t ))

(defun delete-dod-company ( id )
  (let ((company (car (clsql:select 'dod-company :where [= [:row-id] id] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value company 'deleted-state) "Y")
    (clsql:update-record-from-slot company 'deleted-state)))
    

(defun delete-dod-companies ( list )
  (mapcar (lambda (id)  (let ((company (car (clsql:select 'dod-company :where [= [:row-id] id] :flatp t :caching *dod-database-caching*))))
			  (setf (slot-value company 'deleted-state) "Y")
			  (clsql:update-record-from-slot company 'deleted-state))) list ))


(defun restore-deleted-dod-companies ( list )
(mapcar (lambda (id)  (let ((company (car (clsql:select 'dod-company :where [= [:row-id] id] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value company 'deleted-state) "N")
    (clsql:update-record-from-slot company 'deleted-state))) list ))



(defun update-company (instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance instance))
