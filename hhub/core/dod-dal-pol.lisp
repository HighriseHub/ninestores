;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(clsql:def-view-class dod-auth-attr-lookup ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
  (name
    :type (string 50)
    :initarg :name)
   
(description
    :type (string 100)
    :initarg :description)
  

   (attr-func
    :type (string 100)
    :initarg :attr-func)
   (attr-unique-func
    :type (string 100) 
    :initarg :attr-unique-func)

  (attr-type
    :type (string 50)
    :initarg :attr-type)

     (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)

        (active-flg
    :type (string 1)
    :void-value "Y"
    :initarg :active-flg)

   

 (created-by
    :TYPE INTEGER
    :INITARG :created-by)
   (attr-created-by
    :ACCESSOR attr-created-by
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-users
                          :HOME-KEY created-by
                          :FOREIGN-KEY row-id
                          :SET NIL))
 
  
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR policy-attr-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET NIL)))


   (:base-table dod_auth_attr_lookup))

;;;;;;;;;;;;;;;;;;;; class dod-auth-policy
 
(clsql:def-view-class dod-auth-policy ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)
   (name
    :type (string 50)
    :initarg :name)
   (description
    :type (string 100)
    :initarg :description)
   (policy-func
    :type (string 255)
    :initarg :policy-func)



        (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)

        (active-flg
    :type (string 1)
    :void-value "Y"
    :initarg :active-flg)



 (created-by
    :TYPE INTEGER
    :INITARG :created-by)
   (attr-created-by
    :ACCESSOR attr-created-by
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-users
                          :HOME-KEY created-by
                          :FOREIGN-KEY row-id
                          :SET NIL))
 
  
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR policy-attr-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET NIL)))



   (:base-table dod_auth_policy))


;;;; DEFINE CLASS FOR TABLE DOD_AUTH_POLICY_ATTR


(clsql:def-view-class dod-auth-policy-attr ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id)

   (policy-id
    :type integer
    :initarg :policy-id)
  
   (attribute-id
    :type integer
    :initarg :attribute-id)
   (attr-val 
    :type (string 100)
    :initarg :attr-val)
  
   (tenant-id
    :type integer
    :initarg :tenant-id)
 

     (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)

        (active-flg
    :type (string 1)
    :void-value "Y"
    :initarg :active-flg))

   (:base-table dod_auth_policy_attr))



