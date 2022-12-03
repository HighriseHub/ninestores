;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(clsql:def-view-class dod-password-reset ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

   ; USER-TYPE = CUSTOMER, VENDOR, EMPLOYEE
   (user-type
    :accessor user-type
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 30)
    :INITARG :user-type)

      (email
    :accessor email
    :type (string 255)
    :initarg :email)


   (created
    :accessor created
    :type clsql:wall-time
    :initarg :created)
   
   (token
    :accessor token
    :type (string 512)
    :initarg :token)
   
   (active-flg
    :accessor active-flg
    :type (string 1)
    :void-value "N"
    :initarg :active-flg)

   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)
   
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR reset-password-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET T)))

   
  (:BASE-TABLE dod_password_reset))

