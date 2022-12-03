;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

;;;;;;;;;;;;;;;;;;;;; business logic for dod-bus-object ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun get-bus-object (id)
  (car (clsql:select 'dod-bus-object  :where [and [= [:deleted-state] "N"] [= [:row-id] id]]    :caching *dod-database-caching* :flatp t )))

(defun get-system-bus-objects () 
(select-bus-object-by-company (select-company-by-id 1)))

(defun get-bus-object-by-name (name)
  (car (clsql:select 'dod-bus-object  :where [and [= [:deleted-state] "N"] [= [:name] name]]    :caching *dod-database-caching* :flatp t )))

(defun select-bus-object-by-company (company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (clsql:select 'dod-bus-object  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]] :ORDER-BY '([:name])
		:caching *dod-database-caching* :flatp t )))

  
(defun persist-bus-object(name tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-bus-object
						    :name name
						    :active-flg "Y" 
						    :tenant-id tenant-id
						    :deleted-state "N")))
 


(defun create-bus-object (name company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id))) 
	      (persist-bus-object (string-upcase name) tenant-id)))



;;;;;;;;;;;;;;;;;;;;; Functions for dod-abac-subject ;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun get-abac-subject (id)
  (car (clsql:select 'dod-abac-subject  :where [and [= [:deleted-state] "N"] [= [:row-id] id]]    :caching *dod-database-caching* :flatp t )))

(defun get-system-abac-subjects () 
  (select-abac-subject-by-company (select-company-by-id 1)))

(defun get-abac-subject-by-name (name)
  (car (clsql:select 'dod-abac-subject  :where [and [= [:deleted-state] "N"] [= [:name] name]]    :caching *dod-database-caching* :flatp t )))

(defun select-abac-subject-by-company (company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (clsql:select 'dod-abac-subject  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]] :ORDER-BY '([:name])
		:caching *dod-database-caching* :flatp t )))

  
(defun persist-abac-subject(name tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-abac-subject
						    :name name
						    :active-flg "Y" 
						    :tenant-id tenant-id
						    :deleted-state "N")))
 


(defun create-abac-subject (name company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id))) 
	      (persist-abac-subject (string-upcase name) tenant-id)))



;;;;;;;;;;;;;;;;; Functions for dod-bus-transaction ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun get-bus-transaction (id)
 (car  (clsql:select 'dod-bus-transaction  :where [and [= [:deleted-state] "N"] [= [:row-id] id]]    :caching *dod-database-caching* :flatp t )))

(defun get-system-bus-transactions () 
(select-bus-trans-by-company (select-company-by-id 1)))

(defun get-system-bus-transactions-ht ()
  (let ((ht (make-hash-table :test 'equal))
	(transactions (get-system-bus-transactions)))
    (loop for tran in transactions do
	 (let ((key (slot-value tran 'trans-func)))
	   (setf (gethash key ht) tran)))
    ht))


(defun select-bus-trans-by-trans-func (name)
  (car (clsql:select 'dod-bus-transaction  :where
		[and [= [:deleted-state] "N"]
		[= [:trans-func] name]]
     :caching *dod-database-caching* :flatp t )))



(defun select-bus-trans-by-company (company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
 (clsql:select 'dod-bus-transaction  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]]
     :caching *dod-database-caching* :flatp t )))

(defun select-bus-trans-by-name (name-like-clause company-instance )
      (let ((tenant-id (slot-value company-instance 'row-id)))
  (car (clsql:select 'dod-bus-transaction :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[like  [:name] name-like-clause]]
		:caching *dod-database-caching* :flatp t))))

(defun update-bus-transaction (instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance instance))



(defun delete-bus-transaction( id company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (let ((object (car (clsql:select 'dod-bus-transaction :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value object 'deleted-state) "Y")
    (clsql:update-record-from-slot object 'deleted-state))))



(defun delete-bus-transactions ( list company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (mapcar (lambda (id)  (let ((object (car (clsql:select 'dod-bus-transaction :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
			  (setf (slot-value object 'deleted-state) "Y")
			  (clsql:update-record-from-slot object  'deleted-state))) list )))


(defun restore-deleted-bus-transactions ( list company-instance )
    (let ((tenant-id (slot-value company-instance 'row-id)))
(mapcar (lambda (id)  (let ((object (car (clsql:select 'dod-bus-transaction :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value object 'deleted-state) "N")
    (clsql:update-record-from-slot object 'deleted-state))) list )))

(defun persist-bus-transaction(name  uri  trans-type trans-func tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-bus-transaction
						    :name name
						    :uri uri
						    :bo-id 1 
						    :auth-policy-id 1
						    :trans-type trans-type
						    :active-flg "Y" 
						    :trans-func trans-func
						    :tenant-id tenant-id
						    :deleted-state "N")))
 


(defun create-bus-transaction (name  uri trans-type trans-func company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (persist-bus-transaction name  uri trans-type trans-func  tenant-id)
        (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* (hhub-gen-globally-cached-lists-functions))))


; POLICY ENFORCEMENT POINT 
(defun has-permission1 (policy-id subject resource action env)
  (let* ((policy (if policy-id (select-auth-policy-by-id policy-id)))
	(policy-func (if policy (slot-value policy 'policy-func))))
     (if policy-func (funcall (intern  (string-upcase policy-func)) subject resource action env))))


(defun has-permission (transaction &optional params)
  :documentation "This function is the PEP (Policy Enforcement Point) in the ABAC system"
  ;; Execute permission logic here. 
  (let* ((policy-id (if transaction (slot-value transaction 'auth-policy-id)))
	 (policy (if policy-id (get-ht-val policy-id (HHUB-GET-CACHED-AUTH-POLICIES-HT))))
	 (policy-name (if policy (slot-value policy 'name)))
	 (policy-func (if policy (slot-value policy 'policy-func)))
	 (exceptionstr nil))
    (handler-case 
	(multiple-value-bind (returnvalues) (funcall (intern  (string-upcase policy-func) :hhub) params)
					;Return a list of return values and exception as nil. 
	  (list returnvalues nil))

      ;; If we get an ABAC Transaction exception
      (hhub-abac-transaction-error (condition)
	(setf exceptionstr (format nil "HHUB ABAC Transaction error - ~A. Error: ~A~%" (string-upcase policy-name) (getExceptionStr condition)))
	(with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				:direction :output
				:if-exists :append
				:if-does-not-exist :create)
	  (format stream "~A" exceptionstr))
	(list nil (format nil "HighriseHub General Authorization Error. Contact your system administrator.")))
  
      ;; If we get any general error we will not throw it to the upper levels. Instead set the exception and log it. 
      (error (c)
	(setf exceptionstr (format nil  "HHUB General ABAC Policy Error: ~A :: ~A~%" (string-upcase policy-name) c))
	(with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				:direction :output
			      :if-exists :append
				:if-does-not-exist :create)
	  (format stream "~A" exceptionstr))
	(list nil (format nil "HHUB General Authorization Error. Contact your system administrator."))))))


