;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

;;;;;;;;;;;;;;;;; Functions for dod-auth-policy-attr class ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun get-auth-attrs (tenant-id)
  (clsql:select 'dod-auth-attr-lookup  :where [and [= [:deleted-state] "N"] [= [:tenant-id] tenant-id]]    :caching *dod-database-caching* :flatp t ))

(defun get-system-abac-attributes () 
  (select-auth-attrs-by-company (select-company-by-id 1)))

(defun select-auth-attrs-by-company (company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
 (clsql:select 'dod-auth-attr-lookup  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]]
     :caching *dod-database-caching* :flatp t )))

  (defun select-auth-attr-by-id (id)
    (car (clsql:select 'dod-auth-attr-lookup :where [and
		[= [:deleted-state] "N"]
		[= [:row-id] id]]
		:caching *dod-database-caching* :flatp t)))


  (defun select-auth-attr-by-key (name-like-clause company-instance )
      (let ((tenant-id (slot-value company-instance 'row-id)))
  (car (clsql:select 'dod-auth-attr-lookup :where [and
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[like  [:name] name-like-clause]]
		:caching *dod-database-caching* :flatp t))))


(defun attrinlist-p  (attr-id list)
(member attr-id  (mapcar (lambda (item)
		(slot-value item 'row-id)) list)))



(defun update-auth-attr-lookup (instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance instance))

(defun delete-auth-attr-lookup( id company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (let ((dodauthattr (car (clsql:select 'dod-auth-attr-lookup :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodauthattr 'deleted-state) "Y")
    (clsql:update-record-from-slot dodauthattr 'deleted-state))))



(defun delete-auth-attrs ( list company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (mapcar (lambda (id)  (let ((dodauthattr (car (clsql:select 'dod-auth-attr-lookup :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
			  (setf (slot-value dodauthattr 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodauthattr  'deleted-state))) list )))


(defun restore-deleted-auth-policy-attrs ( list company-instance )
    (let ((tenant-id (slot-value company-instance 'row-id)))
(mapcar (lambda (id)  (let ((dodauthattr (car (clsql:select 'dod-auth-attr-lookup :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodauthattr 'deleted-state) "N")
    (clsql:update-record-from-slot dodauthattr 'deleted-state))) list )))

(defun persist-auth-attr-lookup(name description attr-func attr-type tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-auth-attr-lookup
						    :name name
						    :description description
						    :attr-func attr-func
						    ;:attr-unique-func attr-unique-func 
						    :attr-type attr-type 
						    :active-flg "Y" 
						    :tenant-id tenant-id
						    :deleted-state "N")))
 


(defun create-auth-attr-lookup (name description attr-func  attr-type company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id))) 
    (persist-auth-attr-lookup name description attr-func attr-type tenant-id)
     (with-open-file (stream "~/hhubplatform/hhub/dod-ui-attr.lisp" :if-exists :append :direction :output)
      (print (format stream "(defun ~A ())" attr-func))
       (terpri stream))
        (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* (hhub-gen-globally-cached-lists-functions))))





;    (with-open-file (stream "~/hhubplatform/hhub/dod-ui-attr.lisp" :if-exists nil :direction :output)
 ;     (format stream "(defun ~A ())" attr-func)
  ;    (terpri stream))))
	
	

;;;;;;;;;;;;;;;;;;;;; business logic for dod-auth-policy ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun get-system-auth-policies () 
(get-auth-policies 1))


(defun get-auth-policies (tenant-id)
  (clsql:select 'dod-auth-policy  :where [and [= [:deleted-state] "N"] [= [:tenant-id] tenant-id]]    :caching *dod-database-caching* :flatp t ))

(defun get-system-auth-policies-ht ()
  :documentation "This function stores all the system ABAC policies in a Hashtable. The Key = Policy ID, Value = Policy instance."
  (let ((ht (make-hash-table :test 'equal))
	(policies (get-system-auth-policies)))
    (loop for policy in policies do
	 (let ((key (slot-value policy 'row-id)))
	   (setf (gethash key ht) policy)))
    ; Return  the hash table. 
    ht))


(defun select-auth-policy-by-id (id)
 (car  (clsql:select 'dod-auth-policy :where 
		[and [= [:deleted-state] "N"]
		[= [:row-id] id]]
		     :caching *dod-database-caching* :flatp t )))

(defun select-auth-policy-by-company (company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
 (clsql:select 'dod-auth-policy  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]]
     :caching *dod-database-caching* :flatp t )))

(defun select-auth-policy-by-name (name-like-clause company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
 (clsql:select 'dod-auth-policy  :where
		[and [= [:deleted-state] "N"]
		[like [:name] name-like-clause]
		[= [:tenant-id] tenant-id]]
     :caching *dod-database-caching* :flatp t )))




(defun update-auth-policy (instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance instance))

(defun delete-auth-policy( id company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (let ((dodauthpolicy (car (clsql:select 'dod-auth-policy :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodauthpolicy 'deleted-state) "Y")
    (clsql:update-record-from-slot dodauthpolicy 'deleted-state))))



(defun delete-auth-policies ( list company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (mapcar (lambda (id)  (let ((dodauthpolicy (car (clsql:select 'dod-auth-policy :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
			  (setf (slot-value dodauthpolicy 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodauthpolicy  'deleted-state))) list )))


(defun restore-deleted-auth-policy ( list company-instance )
    (let ((tenant-id (slot-value company-instance 'row-id)))
(mapcar (lambda (id)  (let ((dodauthpolicy (car (clsql:select 'dod-auth-policy :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodauthpolicy 'deleted-state) "N")
    (clsql:update-record-from-slot dodauthpolicy 'deleted-state))) list )))

   

  
(defun persist-auth-policy(name description policy-func tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-auth-policy
						    :name name
						    :description description
						    :policy-func policy-func
						    :active-flg "Y" 
						    :tenant-id tenant-id
						    :deleted-state "N")))
 


(defun create-auth-policy (name description policy-func  company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id))) 
    (persist-auth-policy name description policy-func tenant-id)
        (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* (hhub-gen-globally-cached-lists-functions))))




;;;;;;;;;;;;;;;;;;;;; business logic for dod-auth-policy-attr ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun get-auth-policy-attr (tenant-id)
  (clsql:select 'dod-auth-policy-attr  :where [and [= [:deleted-state] "N"] [= [:tenant-id] tenant-id]]    :caching *dod-database-caching* :flatp t ))

(defun select-auth-policy-attr-by-company (company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
 (clsql:select 'dod-auth-policy-attr  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]]
     :caching *dod-database-caching* :flatp t )))



(defun update-auth-policy-attr (instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance instance))

(defun delete-auth-policy-attr( id company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (let ((dodauthpolicyattr (car (clsql:select 'dod-auth-policy-attr :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodauthpolicyattr 'deleted-state) "Y")
    (clsql:update-record-from-slot dodauthpolicyattr 'deleted-state))))



(defun delete-auth-policie-attrs ( list company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (mapcar (lambda (id)  (let ((dodauthpolicyattr (car (clsql:select 'dod-auth-policy-attr :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
			  (setf (slot-value dodauthpolicyattr 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodauthpolicyattr  'deleted-state))) list )))


(defun restore-deleted-auth-policy-attr ( list company-instance )
    (let ((tenant-id (slot-value company-instance 'row-id)))
(mapcar (lambda (id)  (let ((dodauthpolicyattr (car (clsql:select 'dod-auth-policy-attr :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodauthpolicyattr 'deleted-state) "N")
    (clsql:update-record-from-slot dodauthpolicyattr 'deleted-state))) list )))

   

  
(defun persist-auth-policy-attr (policy-id attribute-id attr-val tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-auth-policy-attr
						    :policy-id policy-id
						    :attribute-id attribute-id
						    :attr-val attr-val
						   :tenant-id tenant-id )))
 


(defun create-auth-policy-attr (policy-id attribute-id attr-val  company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id))) 
	      (persist-auth-policy-attr policy-id attribute-id attr-val tenant-id))) 

