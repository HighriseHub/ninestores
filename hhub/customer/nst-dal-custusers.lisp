;;; nst-dal-custusers.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)




(clsql:def-view-class dod-customer-user-activity ()
  (;; Primary Key
   (row-id 
    :db-kind :key 
    :db-constraints :not-null 
    :type integer 
    :initarg :row-id)
   
   ;; Foreign Keys
   (user-id 
    :type integer 
    :db-constraints :not-null
    :initarg :user-id)
   
   (user
    :accessor activity-user
    :db-kind :join
    :db-info (:join-class dod-customer-users
              :home-key user-id
              :foreign-key row-id
              :set nil))
   
   (customer-id 
    :type integer 
    :db-constraints :not-null
    :initarg :customer-id)
   
   (customer
    :accessor activity-customer
    :db-kind :join
    :db-info (:join-class dod-cust-profile
              :home-key customer-id
              :foreign-key row-id
              :set nil))
   
   ;; Activity Details
   (activity-type 
    :type string 
    :db-constraints :not-null
    :initarg :activity-type)
   
   (activity-description 
    :type string 
    :initarg :activity-description)
   
   (reference-id 
    :type (string 100) 
    :initarg :reference-id)
   
   ;; Session Info
   (ip-address 
    :type (string 45) 
    :initarg :ip-address)
   
   (user-agent 
    :type string 
    :initarg :user-agent)
   
   ;; Timestamp
   (created-at 
    :type wall-time 
    :initarg :created-at)
   
   ;; Multi-tenancy
   (tenant-id 
    :type integer 
    :db-constraints :not-null
    :initarg :tenant-id)
   
   (company
    :accessor activity-company
    :db-kind :join
    :db-info (:join-class dod-company
              :home-key tenant-id
              :foreign-key row-id
              :set nil)))
  
  (:base-table dod_customer_user_activity))



;;; Permission Checking Functions

(defun can-user-create-order-p (user)
  "Check if user can create orders"
  (or (string= (slot-value user 'can-create-order) "Y")
      (member (slot-value user 'user-role) 
              '("OWNER" "ADMIN" "PROCUREMENT_MANAGER" "PROCUREMENT_EXECUTIVE")
              :test #'string=)))

(defun can-user-approve-pr-p (user)
  "Check if user can approve purchase requisitions"
  (or (string= (slot-value user 'can-approve-pr) "Y")
      (member (slot-value user 'user-role)
              '("OWNER" "ADMIN" "PROCUREMENT_MANAGER" "FINANCE_APPROVER")
              :test #'string=)))

(defun can-user-manage-users-p (user)
  "Check if user can manage other users"
  (or (string= (slot-value user 'can-manage-users) "Y")
      (member (slot-value user 'user-role)
              '("OWNER" "ADMIN")
              :test #'string=)))

(defun check-approval-limit (user amount)
  "Check if user can approve given amount"
  (let ((limit (slot-value user 'order-approval-limit)))
    (or (null limit)  ; No limit = can approve any amount
        (<= amount limit))))

;;; Activity Logging

(defun log-user-activity (user-id customer-id activity-type 
                          &key description reference-id ip-address user-agent tenant-id)
  "Log a user activity"
  (let ((activity (make-instance 'dod-customer-user-activity
                                 :user-id user-id
                                 :customer-id customer-id
                                 :activity-type activity-type
                                 :activity-description description
                                 :reference-id reference-id
                                 :ip-address ip-address
                                 :user-agent user-agent
                                 :created-at (clsql:get-time)
                                 :tenant-id tenant-id)))
    (clsql:update-records-from-instance activity)))

;;; User Lookup Functions

(defun find-user-by-username (username)
  "Find active user by username"
  (car (clsql:select 'dod-customer-users
                     :where [and [= [username] username]
                                 [= [is-active] "Y"]
                                 [= [deleted-state] "N"]]
                     :flatp t)))

(defun find-user-by-email (email customer-id)
  "Find user by email within a customer account"
  (car (clsql:select 'dod-customer-users
                     :where [and [= [email] email]
                                 [= [customer-id] customer-id]
                                 [= [deleted-state] "N"]]
                     :flatp t)))

(defun find-users-for-customer (customer-id &key (active-only t))
  "Get all users for a customer"
  (clsql:select 'dod-customer-users
                :where (if active-only
                          [and [= [customer-id] customer-id]
                               [= [is-active] "Y"]
                               [= [deleted-state] "N"]]
                          [and [= [customer-id] customer-id]
                               [= [deleted-state] "N"]])
                :order-by '(([is-primary-user] :desc) ([created] :asc))
                :flatp t))

(defun get-primary-user (customer-id)
  "Get the primary user (owner) of a customer account"
  (car (clsql:select 'dod-customer-users
                     :where [and [= [customer-id] customer-id]
                                 [= [is-primary-user] "Y"]
                                 [= [deleted-state] "N"]]
                     :flatp t)))

;;; Authentication Functions

(defun authenticate-user (username password)
  "Authenticate user by username and password"
  (let ((user (find-user-by-username username)))
    (when user
      (when (check&encrypt  password 
                            (slot-value user 'password)
                            (slot-value user 'salt))
        ;; Update last login
        (setf (slot-value user 'last-login-at) (clsql:get-time))
        (setf (slot-value user 'failed-login-attempts) 0)
        (clsql:update-records-from-instance user)
        
        ;; Log login activity
        (log-user-activity (slot-value user 'row-id)
                          (slot-value user 'customer-id)
                          "LOGIN"
                          :ip-address (get-client-ip)
                          :user-agent (get-user-agent))
        user))))

(defun record-failed-login (username)
  "Record failed login attempt"
  (let ((user (find-user-by-username username)))
    (when user
      (incf (slot-value user 'failed-login-attempts))
      (when (>= (slot-value user 'failed-login-attempts) 5)
        ;; Lock account for 30 minutes after 5 failed attempts
        (setf (slot-value user 'locked-until)
              (clsql:time+ (clsql:get-time) (clsql:make-duration :minute 30))))
      (clsql:update-records-from-instance user)
      
      ;; Log failed login
      (log-user-activity (slot-value user 'row-id)
                        (slot-value user 'customer-id)
                        "FAILED_LOGIN"
                        :ip-address (get-client-ip)))))

;;; User Management Functions

(defun create-customer-user (customer-id full-name email username password
                             &key (user-role "VIEWER") phone designation department tenant-id)
  "Create a new customer user"
  (let* ((salt (CREATECIPHERSALT))
         (hashed-password (encrypt password salt))
         (user (make-instance 'dod-customer-users
                             :customer-id customer-id
                             :username username
                             :password hashed-password
                             :salt salt
                             :full-name full-name
                             :email email
                             :phone phone
                             :designation designation
                             :department department
                             :user-role user-role
                             :is-active "Y"
                             :is-primary-user "N"
                             :created (clsql:get-time)
                             :updated (clsql:get-time)
                             :tenant-id tenant-id
                             :deleted-state "N")))
    
    ;; Set default permissions based on role
    (set-default-permissions-for-role user user-role)
    
    (clsql:update-records-from-instance user)
    user))

(defun set-default-permissions-for-role (user role)
  "Set default permissions based on user role"
  (case (intern (string-upcase role) :keyword)
    (:owner
     (setf (slot-value user 'can-create-order) "Y"
           (slot-value user 'can-create-bom) "Y"
           (slot-value user 'can-create-pr) "Y"
           (slot-value user 'can-approve-pr) "Y"
           (slot-value user 'can-approve-order) "Y"
           (slot-value user 'can-manage-wallet) "Y"
           (slot-value user 'can-view-invoices) "Y"
           (slot-value user 'can-download-reports) "Y"
           (slot-value user 'can-manage-users) "Y"
           (slot-value user 'can-manage-company-profile) "Y"))
    
    (:procurement-manager
     (setf (slot-value user 'can-create-order) "Y"
           (slot-value user 'can-create-bom) "Y"
           (slot-value user 'can-create-pr) "Y"
           (slot-value user 'can-approve-pr) "Y"
           (slot-value user 'can-manage-wallet) "Y"
           (slot-value user 'can-view-invoices) "Y"
           (slot-value user 'can-download-reports) "Y"
           (slot-value user 'order-approval-limit) 200000.00))
    
    (:accountant
     (setf (slot-value user 'can-view-invoices) "Y"
           (slot-value user 'can-download-reports) "Y"))
    
    ;; Add other roles as needed
    ))
