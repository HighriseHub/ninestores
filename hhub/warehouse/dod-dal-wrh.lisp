;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(clsql:def-view-class hhub-warehouse ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

   (w-name
    :accessor w-name
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 100)
    :INITARG :w-name)

   (w-addr1
    :type (string 100)
    :initarg :w-addr1)
   
   (w-addr2
    :type (string 100)
    :initarg :w-addr2)

   (w-pin
    :type (string 6)
    :initarg :w-pin)

   (w-city
    :type (string 30)
    :initarg :w-city)
   (w-state
    :type (string 30)
    :initarg :w-state)

   (w-country
    :type (string 30)
    :initarg :w-country)

   (w-manager
    :type (string 100)
    :initarg :w-manager)

   (w-phone
    :type (string 16)
    :initarg :w-phone)

   (w-alt-phone
    :type (string 16)
    :initarg :w-alt-phone)

   (w-email
    :type (string 100)
    :initarg :w-email)

   
   (active-flag
    :type (string 1)
    :void-value "N"
    :initarg :active-flag)


   (deleted-state
    :type (string 1)
    :void-value "N"
       :initarg :deleted-state)

    
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR product-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET T)))

   
  (:BASE-TABLE dod_prd_master))
