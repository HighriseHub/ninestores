;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)


(defun set-user-session-params (company  user)
  ;; Add the vendor object and the tenant to the Business Session 
  ;;set vendor company related params
  (let ((usessionobj (make-instance 'UserSessionObject)))
    (setf (slot-value usessionobj 'uwebsession) hunchentoot:*session*)
    (setf (hunchentoot:session-value :login-user ) user)
    (setf (slot-value usessionobj 'user) user)
    (setf (hunchentoot:session-value :login-username) (slot-value user 'username))
    (setf (hunchentoot:session-value :login-user-name) (slot-value user 'name))
    (setf (slot-value usessionobj 'user-name) (slot-value user 'name))
    (setf (hunchentoot:session-value :login-user-id) (slot-value user 'row-id))
    (setf (slot-value usessionobj 'user-id) (slot-value user 'row-id))
    (setf (hunchentoot:session-value :login-user-tenant-id) (slot-value company 'row-id ))
    (setf (slot-value usessionobj 'user-tenant-id) (slot-value company 'row-id))
    (setf (hunchentoot:session-value :login-user-company-name) (slot-value company 'name))
    (setf (slot-value usessionobj 'companyname) (slot-value company 'name))
    (setf (hunchentoot:session-value :login-user-company) company)
    (setf (hunchentoot:session-value :login-user-currency) (get-account-currency company))
    (setf (hunchentoot:session-value :login-user-role-name) (com-hhub-attribute-role-name))
    (setf (hunchentoot:session-value :login-attribute-cart) '())
    ;;(setf (hunchentoot:session-value :login-prd-cache )  (select-products-by-company company))
    ;;set vendor related params 
    (addloginusersettings)
    (let ((sessionkey (createBusinessSession (getBusinessContext *HHUBBUSINESSSERVER* "compadminsite") usessionobj)))
      (setf (hunchentoot:session-value :login-user-business-session-id) sessionkey)
      (logiamhere (format nil "web session is ~A" (slot-value usessionobj 'uwebsession)))
      (logiamhere (format nil "session key is ~A" sessionkey))
      (enforceusersession sessionkey "compadminsite" *HHUBMAXUSERLOGINS*)
      sessionkey)))

(defun enforceusersession (sessionkey contextname maxusersallowed)
  (let* ((bcontext (getBusinessContext *HHUBBUSINESSSERVER* contextname))
	 (bsessions-ht (businesssessions-ht bcontext))
	 (busersession (gethash sessionkey bsessions-ht))
	 (user (slot-value busersession 'user))
	 (sessionlist '())
	 (keylist '()))
    (maphash (lambda (k v)
	       (let ((prevuserid (slot-value v 'user-id))
		     (prevwebsession (slot-value v 'uwebsession))
		     (loginuserid (slot-value user 'row-id))
		     (username (slot-value user 'name)))
		 (when (and
			(not (equal k sessionkey)) ;; There are 2 separate sessions from same user. 
			(= prevuserid loginuserid)) ;; Same user is login again.
		   (logiamhere (format nil "User is ~A. key is ~A. Websession is ~A" username k prevwebsession))
		   (setf sessionlist (append sessionlist (list v)))
		   (setf keylist (append keylist (list k)))))) bsessions-ht)
    ;; If there are exactly 1 item in the list that means that user has logged in previouly. 
    (when (>= (length sessionlist) maxusersallowed)
      (let* ((sessiontoremove (nth 0 sessionlist))
	     (websession (slot-value sessiontoremove 'uwebsession))
	     (firstkey (nth 0 keylist)))
	(hunchentoot:remove-session websession)
	(deleteBusinessSession bcontext firstkey)))
    (logiamhere (format nil "there are ~d items in session list " (length sessionlist)))))



(defun addloginusersettings ()
  )


(defun list-dod-users ()
  (clsql:select 'dod-users  :where [and [= [:deleted-state] "N"] 
		[= [:tenant-id] (get-login-tenant-id)]
		[<> [:name] "superadmin"]]    :caching nil :flatp t ))

(defun get-users-for-company (tenant-id)
  (clsql:select 'dod-users  :where [and [= [:deleted-state] "N"] 
		[= [:tenant-id] tenant-id]
		[<> [:name] "superadmin"]]    :caching nil :flatp t ))


(defun select-user-by-id (user-id tenant-id)
  (car (clsql:select 'dod-users  :where [and [= [:deleted-state] "N"] 
		[= [:tenant-id] tenant-id]
		[= [:row-id] user-id]
		[<> [:name] "superadmin"]]    :caching nil :flatp t )))

(defun select-user-by-phonenumber (phone tenant-id)
  (car (clsql:select 'dod-users  :where [and [= [:deleted-state] "N"] 
		[= [:tenant-id] tenant-id]
		[= [:phone-mobile] phone]
		[<> [:name] "superadmin"]]    :caching nil :flatp t )))



(defun delete-dod-user ( id )
  (let ((doduser (car (clsql:select 'dod-users :where [= [:row-id] id] :flatp t :caching nil))))
    (setf (slot-value doduser 'deleted-state) "Y")
    (clsql:update-record-from-slot doduser 'deleted-state)))



(defun update-user (user-instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance user-instance))

(defun delete-dod-users ( list )
  (mapcar (lambda (id)  (let ((doduser (car (clsql:select 'dod-users :where [= [:row-id] id] :flatp t :caching nil))))
			  (setf (slot-value doduser 'deleted-state) "Y")
			  (clsql:update-record-from-slot doduser  'deleted-state))) list ))


(defun restore-deleted-dod-users ( list )
(mapcar (lambda (id)  (let ((doduser (car (clsql:select 'dod-users :where [= [:row-id] id] :flatp t :caching nil))))
    (setf (slot-value doduser 'deleted-state) "N")
    (clsql:update-record-from-slot doduser 'deleted-state))) list ))


(defun reset-user-password (user &optional password)
  :description "If a password is provided, then it is set otherwise returns a random password"
  (let* ((randompassword (hhub-random-password 10))
         (salt (createciphersalt))
         (encryptedpass (if password (encrypt password salt) (encrypt randompassword salt))))
    (setf (slot-value user 'password) encryptedpass)
    (setf (slot-value user 'salt) salt)
    (update-user user)
    (unless password randompassword)))    


(defun create-dod-user(name uname passwd salt email-address phone tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-users
				    :name name
				    :username uname
				    :salt salt
				    :password passwd
				    :email email-address
				    :phone-mobile phone
				    :tenant-id tenant-id
				    :deleted-state "N"
				    :created-by tenant-id
				    :updated-by tenant-id)))
 


