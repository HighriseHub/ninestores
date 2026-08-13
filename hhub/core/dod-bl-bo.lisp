;;; dod-bl-bo.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
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

  
(defun persist-bus-object(name hhub-type tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-bus-object
						    :name name
						    :active-flg "Y" 
						    :tenant-id tenant-id
						    :hhub-type hhub-type
						    :deleted-state "N")))
 


(defun create-bus-object (name hhub-type company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id))) 
	      (persist-bus-object (string-upcase name) hhub-type tenant-id)))



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

  
(defun persist-abac-subject(name hhub-type tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-abac-subject
						    :name name
						    :active-flg "Y" 
						    :tenant-id tenant-id
						    :deleted-state "N"
						    :hhub-type hhub-type)))
 


(defun create-abac-subject (name hhub-type)
  (let ((tenant-id (slot-value (select-company-by-id 1) 'row-id))) 
	      (persist-abac-subject (string-upcase name) hhub-type tenant-id)))



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
(defun select-bus-trans-by-id (id company-instance )
  (let ((tenant-id (slot-value company-instance 'row-id)))
  (car (clsql:select 'dod-bus-transaction :where [and
		     [= [:deleted-state] "N"]
		     [= [:tenant-id] tenant-id]
		     [like  [:row-id] id]]
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
    (persist-bus-transaction name  uri trans-type trans-func  tenant-id)))



; POLICY ENFORCEMENT POINT 
(defun has-permission1 (policy-id subject resource action env)
  (let* ((policy (if policy-id (select-auth-policy-by-id policy-id)))
	(policy-func (if policy (slot-value policy 'policy-func))))
     (if policy-func (funcall (intern  (string-upcase policy-func)) subject resource action env))))



(defun has-permission (transaction &optional params)
  "Policy Enforcement Point (PEP).
   Returns (list returnvalue exceptionstr), where returnvalue is T/NIL,
   and exceptionstr is a user-facing error string or NIL on success."
  (flet ((log-error (msg)
           (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE*
                                   :direction :output
                                   :if-exists :append
                                   :if-does-not-exist :create)
             (format stream "~A: ~A~%" (mysql-now) msg))))
    (let ((policy-name nil))  ; bind here so error handlers can see it
      (handler-case
          (progn
            ;; 1. Transaction validation
            (unless transaction
              (return-from has-permission
                (list nil "No transaction object provided.")))
            (let ((policy-id (slot-value transaction 'auth-policy-id)))
              (unless policy-id
                (return-from has-permission
                  (list nil (format nil "Transaction ~A has no associated policy ID."
                                    (slot-value transaction 'name)))))

              ;; 2. Policy retrieval
              (let* ((policy (get-ht-val policy-id (HHUB-GET-CACHED-AUTH-POLICIES-HT)))
                     (policy-func (when policy (slot-value policy 'policy-func))))
                (setf policy-name (when policy (slot-value policy 'name)))

                (unless policy
                  (return-from has-permission
                    (list nil (format nil "Policy ID ~A not found in cache." policy-id))))
                (unless policy-func
                  (return-from has-permission
                    (list nil (format nil "Policy ~A has no associated function." policy-name))))

                ;; 3. Resolve the policy function symbol safely
                (let ((symbol (find-symbol (string-upcase policy-func) :nstores)))
                  (unless (and symbol (fboundp symbol))
                    (return-from has-permission
                      (list nil (format nil "Policy function ~A not found or not callable."
                                        (string-upcase policy-func)))))

                  ;; 4. Execute the policy and return result
                  (let ((result (funcall symbol params)))
		    (logiamhere (format nil "Result for policy - ~A is ~A" policy-name result))
		    (list result nil))))))

        ;; 5. Handle specific ABAC errors
        (hhub-abac-transaction-error (condition)
          (let ((msg (format nil "~A: ABAC Policy Error for ~A: ~A"
                             (mysql-now) (or policy-name "Unknown Policy")
                             (getExceptionStr condition))))
            (log-error msg)
            #+sbcl (log-error (format nil "Backtrace:~%~A" (sb-debug:list-backtrace)))
            (list nil "Nine Stores Authorization Error. Contact your system administrator.")))

        ;; 6. Handle any other errors (including missing symbols)
        (error (c)
          (let ((msg (format nil "~A: General Policy Error for ~A: ~A"
                             (mysql-now) (or policy-name "Unknown Policy") c)))
            (log-error msg)
            #+sbcl (log-error (format nil "Backtrace:~%~A" (sb-debug:list-backtrace)))
            (list nil "Nine Stores General Authorization Error. Contact your system administrator.")))))))

  



