(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

;;;;;;; High level functions to be implemented 
;;;;;;; create vendor availability day
;;;;;;; get vendor availability day
;;;;;;; delete vendor availability day


(defun get-vendor-appointment-instance (vendor-id appt-date tenant-id) 
  (car (clsql:select 'dod-vendor-appointment :where [and 
		     [= [:deleted-state] "N"] 
		     [= [:active-flg] "Y"] 
		     [= [:appt-date] appt-date] 
		     [= [:tenant-id] tenant-id] 
		     [= [:vendor-id] vendor-id]]    :caching nil :flatp t )))

(defun get-vendor-appointments  (vendor-id tenant-id) 
 (clsql:select 'dod-vendor-appointment :where [and 
		     [= [:deleted-state] "N"] 
		     [= [:active-flg] "Y"] 
		      [= [:tenant-id] tenant-id] 
		     [= [:vendor-id] vendor-id]]    :caching nil :flatp t ))


(defun delete-vendor-appointment-instance (id) 
  (let ((object (car (clsql:select 'dod-vendor-appointment :where [= [:row-id] id] :flatp t :caching nil))))
    (setf (slot-value object 'deleted-state) "Y")
    (clsql:update-record-from-slot object 'deleted-state)))

(defmethod update-vendor-appointment-instance (instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance instance))

(defun delete-vendor-appointment-instances (list) 
  (mapcar (lambda (id)  (let ((object (car (clsql:select 'dod-vendor-appointment :where [= [:row-id] id] :flatp t :caching nil))))
			  (setf (slot-value object 'deleted-state) "Y")
			  (clsql:update-record-from-slot object  'deleted-state))) list ))


(defun restore-deleted-vendor-appointment-instances( list )
(mapcar (lambda (id)  (let ((object (car (clsql:select 'dod-vendor-appointment :where [= [:row-id] id] :flatp t :caching nil))))
			  (setf (slot-value object 'deleted-state) "N")
			  (clsql:update-record-from-slot object  'deleted-state))) list ))


  
(defun create-vendor-appointment  (vendor-id appt-date start-time end-time  comments tenant-id created-by) 
 (clsql:update-records-from-instance (make-instance 'dod-vendor-appointment
				    :vendor-id vendor-id 
				    :appt-date appt-date 
				    :start-time start-time 
				    :end-time end-time 
				    :comments comments
				    :tenant-id tenant-id 
				    :created-by created-by 
				    :deleted-state "N"
				    :active-flg "Y")))
