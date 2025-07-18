(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)


(defun get-reset-password-instance-by-token (token) 
  (car (clsql:select 'dod-password-reset  :where [and [= [:deleted-state] "N"] 
		[= [:token] token]]    :caching nil :flatp t )))

(defun get-reset-password-instance-by-email (email tenant-id) 
 (car (clsql:select 'dod-password-reset  :where [and [= [:deleted-state] "N"] 
		[= [:tenant-id] tenant-id]
		[= [:email] email]]    :caching nil :flatp t )))

(defun delete-reset-password-instance ( id )
  (let ((object (car (clsql:select 'dod-password-reset :where [= [:row-id] id] :flatp t :caching nil))))
    (setf (slot-value object 'deleted-state) "Y")
    (clsql:update-record-from-slot object 'deleted-state)))

(defmethod update-reset-password-instance (reset-password-instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance reset-password-instance))

(defmethod delete-reset-password-instances  ( list )
  (mapcar (lambda (id)  (let ((object (car (clsql:select 'dod-password-reset :where [= [:row-id] id] :flatp t :caching nil))))
			  (setf (slot-value object 'deleted-state) "Y")
			  (clsql:update-record-from-slot object  'deleted-state))) list ))


(defun restore-deleted-reset-password-instances( list )
(mapcar (lambda (id)  (let ((object (car (clsql:select 'dod-password-reset :where [= [:row-id] id] :flatp t :caching nil))))
			  (setf (slot-value object 'deleted-state) "N")
			  (clsql:update-record-from-slot object  'deleted-state))) list ))


  
(defun create-reset-password-instance (user-type token email  tenant-id)
 (clsql:update-records-from-instance (make-instance 'dod-password-reset
				    :user-type user-type 
				    :email email 
				    :token token 
				    :tenant-id tenant-id 
				    :deleted-state "N"
				    :active-flg "Y")))
				    
 
