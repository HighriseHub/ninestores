;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


(defun get-system-roles () 
(clsql:select 'dod-roles :where 
	      [and 
	      [= [:deleted-state] "N"]
	      [<> [:name] "SUPERADMIN"]]
	      :caching nil :flatp t ))

(defun select-role-by-id (id )
  (car (clsql:select 'dod-roles :where 
		     [= [:row-id] id]
		     :caching nil :flatp t)))


(defun select-role-by-name (name )
  (car (clsql:select 'dod-roles :where 
		     [= [:name] name]
		     :caching nil :flatp t)))


(defun select-user-role-by-userid (user-id tenant-id)
  (car (clsql:select 'dod-user-roles :where [and 
		[= [:tenant-id] tenant-id]
		[= [:user-id] user-id]]
	        :caching nil :flatp t )))



(defun update-user-role (userrole-instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance userrole-instance))


(defun create-user-role (user-id role-id tenant-id)
   (clsql:update-records-from-instance (make-instance 'dod-user-roles
				    :user-id user-id 
				    :role-id role-id 
				    :tenant-id tenant-id)))

