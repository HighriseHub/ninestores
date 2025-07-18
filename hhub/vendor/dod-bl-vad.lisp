(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;;;;;; High level functions to be implemented 
;;;;;;; create vendor availability day
;;;;;;; get vendor availability day
;;;;;;; delete vendor availability day


(defun get-vendor-availability-day-by-avail-date (vendor-id avail-date tenant-id) 
  (car (clsql:select 'dod-vendor-availability-day  :where [and 
		     [= [:deleted-state] "N"] 
		     [= [:active-flg] "Y"] 
		     [= [:avail-date] avail-date] 
		     [= [:tenant-id] tenant-id] 
		     [= [:vendor-id] vendor-id]]    :caching nil :flatp t )))


(defun get-vendor-availability-day-by-id (row-id )
  (car (clsql:select 'dod-vendor-availability-day  :where [and 
		     [= [:deleted-state] "N"] 
		     [= [:active-flg] "Y"] 
		     [= [:row-id] row-id]]  :caching nil :flatp t )))


(defun get-vendor-availability-days  (vendor-id tenant-id) 
 (clsql:select 'dod-vendor-availability-day  :where [and 
		     [= [:deleted-state] "N"] 
		     [= [:active-flg] "Y"] 
		      [= [:tenant-id] tenant-id] 
		     [= [:vendor-id] vendor-id]]    :caching nil :flatp t ))


(defun delete-vendor-availability-day-instance (id) 
  (let ((object (car (clsql:select 'dod-vendor-availability-day :where [= [:row-id] id] :flatp t :caching nil))))
    (setf (slot-value object 'deleted-state) "Y")
    (clsql:update-record-from-slot object 'deleted-state)))

(defun update-vendor-availability-day-instance (instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance instance))

(defun delete-vendor-availability-day-instances (list) 
  (mapcar (lambda (id)  (let ((object (car (clsql:select 'dod-vendor-availability-day :where [= [:row-id] id] :flatp t :caching nil))))
			  (setf (slot-value object 'deleted-state) "Y")
			  (clsql:update-record-from-slot object  'deleted-state))) list ))


(defun restore-deleted-vendor-availability-day-instances( list )
(mapcar (lambda (id)  (let ((object (car (clsql:select 'dod-vendor-availability-day :where [= [:row-id] id] :flatp t :caching nil))))
			  (setf (slot-value object 'deleted-state) "N")
			  (clsql:update-record-from-slot object  'deleted-state))) list ))


  
(defun create-vendor-availability-day  (vendor-id avail-date start-time end-time break-start-time break-end-time leave-flag comments tenant-id created-by) 
 (clsql:update-records-from-instance (make-instance 'dod-vendor-availability-day
				    :vendor-id vendor-id 
				    :avail-date avail-date 
				    :start-time start-time 
				    :end-time end-time 
				    :break-start-time break-start-time
				    :break-end-time break-end-time 
				    :leave-flag leave-flag
				    :comments comments
				    :tenant-id tenant-id 
				    :created-by created-by 
				    :deleted-state "N"
				    :active-flg "Y")))

