;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
;;(clsql:file-enable-sql-reader-syntax)

(defclass hhubstore (BusinessObject)
  ((name
    :accessor name
    :initform "defaulthhubstore"
    :initarg :name )
   (logo
    :accessor logo
    :initform ""
    :initarg :logo)
   (banner
    :accessor banner
    :initform ""
    :initarg :banner)
   (address
    :accessor address
    :initarg :address)
   (city
    :accessor city
    :initarg :city)
   (state
    :accessor state
    :type (string 256)
    :initarg :state)
   (country
    :accessor country
    :type (string 256)
    :initarg :country)
   (zipcode
    :accessor zipcode
    :type (string 10)
    :initarg :zipcode)
   (website 
    :accessor website
    :type (string 256)
    :initarg :website)
   (tshirt-size
    :accessor website
    :initform "sm"
    :initarg :tshirt-size)
   (revenue
    :accessor revenue
    :initarg :revenue)
   (subscription-plan
    :accessor subscription-plan
    :initarg :subscription-plan)
   (external-url
    :accessor external-url
    :initarg :external-url)
   (suspend-flag
    :accessor suspend-flag
    :initarg :suspend-flag)
   (created
    :accessor created
    :initform (get-universal-time)
    :initarg :created)
   (employees
    :accessor employees
    :initarg :employees)
   (customers
    :accessor customers
    :initarg :customers)
   (vendors
    :accessor vendors
    :initarg :vendors)))

(defclass communitystore (hhubstore)
  ())


;; Generic functions for a store.





(clsql:def-view-class dod-company ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   (name
    :type (string 255)
    :initarg :name)
   (address
    :type (string 512)
    :initarg :address)
   (city
    :accessor city
    :type (string 256)
    :initarg :city)
   (state
    :accessor state
    :type (string 256)
    :initarg :state)
   (country
    :accessor country
    :type (string 256)
    :initarg :country)
   (zipcode
    :accessor zipcode
    :type (string 10)
    :initarg :zipcode)
   (website 
    :type (string 256)
    :initarg :website)
   (created
    :accessor created
    :type clsql:wall-time
    :initarg :created)     
   (created-by
    :TYPE INTEGER
    :INITARG :created-by)
   (user-created-by
    :ACCESSOR company-created-by
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-users
              :HOME-KEY created-by
              :FOREIGN-KEY row-id
              :SET NIL))
   (updated-by
    :TYPE INTEGER
    :INITARG :updated-by)
   (user-updated-by
    :ACCESSOR company-updated-by
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-users
              :HOME-KEY updated-by
              :FOREIGN-KEY row-id
              :SET NIL))
   (cmp-type
    :accessor cmp-type
    :type (string 30)
    :initarg :cmp-type)
   
   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)
   
   (suspend-flag
    :type (string 1)
    :void-value "N"
    :initarg :suspend-flag)
   
   (tshirt-size
    :type (string 2)
    :void-value "SM"
    :initarg :tshirt-size)
   
   (revenue
    :type integer
    :initarg :revenue)
   
   (subscription-plan
    :accessor subscription-plan
    :type (string 50)
    :initarg :subscription-plan)
   
   (external-url
    :type (string 255)
    :initarg :external-url)
   
   (employees
    :reader company-employees
    :db-kind :join
    :db-info (:join-class dod-users
              :home-key row-id
              :foreign-key tenant-id
              :set t)))
  (:base-table dod_company))






