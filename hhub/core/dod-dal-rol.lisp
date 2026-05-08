;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(clsql:def-view-class dod-roles ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   (name
    :type (string 30)
    :initarg :name)
   (description
    :type (string 255)
    :initarg :address)

 (created-by
    :TYPE INTEGER
    :INITARG :created-by)
   (user-created-by
    :ACCESSOR role-created-by
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-users
                          :HOME-KEY created-by
                          :FOREIGN-KEY row-id
                          :SET NIL))
   (updated-by
    :TYPE INTEGER
    :INITARG :updated-by)
   (user-updated-by
    :ACCESSOR role-updated-by
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-users
                          :HOME-KEY updated-by
                          :FOREIGN-KEY row-id
                          :SET NIL)))
  

   (:base-table dod_roles))


(clsql:def-view-class dod-user-roles ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   (user-id
    :type integer
    :initarg :user-id)

   (user
    :ACCESSOR GET-USER-ROLES.USER
    :DB-KIND :JOIN 
    :DB-INFO (:JOIN-CLASS dod-users
			  :HOME-KEY user-id
			  :FOREIGN-KEY row-id
			  :SET NIL))
   
			  
   (role-id 
    :type integer
    :initarg :role-id)
   
   (role
    :ACCESSOR GET-USER-ROLES.ROLE
    :DB-KIND :JOIN 
    :DB-INFO (:JOIN-CLASS dod-roles
			  :HOME-KEY role-id
			  :FOREIGN-KEY row-id
			  :SET NIL))

   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR user-roles-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET NIL)))

   (:base-table dod_user_roles))
