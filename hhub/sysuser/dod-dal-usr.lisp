;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(clsql:def-view-class dod-users ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)
   (name
    :accessor name
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 30)
    :INITARG :name)
   (username
    :ACCESSOR username 
    :type (string 30)
    :initarg :username)
   (password
    :accessor password
    :type (string 100)
    :initarg :password)

    (salt 
    :accessor salt
    :type (string 128)
    :initarg :salt)

   
   (email
    :accessor email
    :type (string 255)
    :initarg :email)

   (phone-mobile 
    :accessor phone-mobile
    :type (string 50)
    :initarg :phone-mobile)
   
   

   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)

   (created-by
    :TYPE INTEGER
    :INITARG :created-by)
   (user-created-by
    :ACCESSOR user-created-by
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-users
                          :HOME-KEY created-by
                          :FOREIGN-KEY row-id
                          :SET NIL))
   (updated-by
    :TYPE INTEGER
    :INITARG :updated-by)
   (user-updated-by
    :ACCESSOR user-updated-by
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-users
                          :HOME-KEY updated-by
                          :FOREIGN-KEY row-id
                          :SET NIL))
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR users-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET NIL))

   
   (parent-id
    :type integer
    :initarg :parent-id)
   (manager
    :accessor users-manager
    :db-kind :join
    :db-info (:join-class dod_users
                          :home-key parent-id
                          :foreign-key row-id
                          :set nil)))

   
  (:BASE-TABLE dod_users))



