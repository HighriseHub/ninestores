(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(clsql:def-view-class dod-vendor-availability-day ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)

   (vendor-id
    :type integer
    :initarg :vendor-id)
   (vendor
    :ACCESSOR get-vendor
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-vend-profile
	                  :HOME-KEY vendor-id
                          :FOREIGN-KEY row-id
                          :SET nil))


   (avail-date
    :accessor avail-date
    :type clsql:wall-time
    :initarg :avail-date)
   

    (start-time
    :accessor start-time
    :type clsql:wall-time
    :initarg :start-time)
   
 (end-time
    :accessor end-time
    :type clsql:wall-time
    :initarg :end-time)

(break-start-time
    :accessor break-start-time
    :type clsql:wall-time
    :initarg :break-start-time)
(break-end-time
    :accessor break-end-time
    :type clsql:wall-time
    :initarg :break-end-time)


   (active-flg
    :accessor active-flg
    :type (string 1)
    :void-value "N"
    :initarg :active-flg)
   

   (leave-flag
    :accessor leave-flag
    :type (string 1)
    :void-value "N"
    :initarg :leave-flag)


   (comments
    :accessor comments
    :type (string 500)
    :initarg comments)

   (created
    :accessor created
    :type clsql:wall-time
    :initarg :created)

(created-by 
 :accessor created-by 
 :type integer 
 :initarg :created-by)
(created-by-user
 :accessor created-by-user 
 :db-kind :join
 :db-info (:join-class dod-users
		       :home-key created-by
		       :foreign-key row-id 
		       :set nil))
   
   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)
   
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR vendor-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET nil)))
   

   
  (:BASE-TABLE dod_vendor_availability_day))

