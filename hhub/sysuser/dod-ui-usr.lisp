(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


  
(defun com-hhub-transaction-sadmin-create-users-page ()
 (with-opr-session-check 
   (let* ((tenant-id (hunchentoot:parameter "tenant-id"))
	  (users (get-users-for-company tenant-id))
	  (params nil))

     (setf params (acons "uri" (hunchentoot:request-uri*)  params))
     (setf params (acons "username" (get-login-user-name)  params))
     
     (with-hhub-transaction "com-hhub-transaction-sadmin-create-users-page" params
       (with-standard-admin-page "List HHUB Users"
	 (:h3 "Users")
	 (:a  :data-toggle "modal" :data-target (format nil "#adduser-modal")  :href "#"  (:span :class "glyphicon glyphicon-plus") " Add User")
	 (hunchentoot:log-message* :info "I am here" )
	 (modal-dialog (format nil "adduser-modal") "Add/Edit Policy" (modal.com-hhub-transaction-sadmin-create-users tenant-id "NEW"))
	 
	 (cl-who:str (display-as-table (list "Name" "Phone number" "Email" "Action")  users 'user-card)))))))



(defun user-card (user-instance)
  (let ((name (slot-value user-instance 'name))
	(phone-mobile (slot-value user-instance 'phone-mobile))
	(email (slot-value user-instance 'email))
	(row-id (slot-value user-instance 'row-id)))
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" 
	(:h6 :class "user-name"  (cl-who:str name)))
      (:td :height "10px" 
	(:h6 :class "user-phone-mobile"  (cl-who:str phone-mobile)))
      (:td :height "10px" 
       	 (:h6 :class "user-email"  (cl-who:str email) ))
      (:td :height "10px" 
       (:a  :data-toggle "modal" :data-target (format nil "#edituser-modal~A" row-id)  :href "#"  (:span :class "glyphicon glyphicon-pencil"))
	(modal-dialog (format nil "edituser-modal~a" row-id) "Add/Edit Policy" (modal.com-hhub-transaction-sadmin-create-users nil "EDIT" user-instance))))))




(defun modal.com-hhub-transaction-sadmin-create-users (for-tenant-id mode  &optional (user nil))
  (let* ((fullname (if user (slot-value user 'name)))
	 (username (if user (slot-value user 'username)))
	 (email (if user (slot-value user 'email)))
	 (phone (if user (slot-value user 'phone-mobile)))
	 (row-id (if user (slot-value user 'row-id)))
	 (tenant-id (if user (slot-value user 'tenant-id)))
	 (userrole-instance (if user (select-user-role-by-userid row-id tenant-id)))
	 (userrolename (if userrole-instance (slot-value (get-user-roles.role userrole-instance) 'name))))

       (cl-who:with-html-output (*standard-output* nil)
	(:div :class "row" 
	      (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		    (:form :class "form-adduser" :role "form" :method "POST" :action "dasadduseraction" :data-toggle "validator"
			   (if user (cl-who:htm (:input :class "form-control" :type "hidden" :value row-id :name "id")))
			   (:img :class "profile-img" :src "/img/logo.png" :alt "")
			   (:h1 :class "text-center login-title"  "Add/Edit User")
			   (:div :class "form-group input-group"
				 (:input :class "form-control" :required T :name "fullname" :aria-describedby "fullnameprefix" :placeholder "Enter Full Name" :maxlength "60" :size "50" :type "text"  :value fullname)) 
			   
			   (:div :class "form-group input-group"
				 (:input :class "form-control" :name "username" :required T :aria-describedby "nameprefix" :placeholder "Enter username" :maxlength "30" :type "text"  :value username)) 
			   (:div :class "form-group"
				 (:label :for "email")
				 (:input :class "form-control" :name "email" :required T :placeholder "Enter User Email " :type "text" :value email ))
			   (:div :class "form-group"
				 (:label :for "userrole")
				 (role-dropdown "userrole" userrolename))
			   (:div :class "form-group input-group"
				 (:input :class "form-control" :name "phone" :maxlength "30"  :required T :value phone :placeholder "Phone"  :type "text"))
			   (if (equal mode "NEW") 
			       (cl-who:htm 
				(:div :class "form-group input-group"
				      (:input :class "form-control" :name "usertenantid" :type "hidden" :value for-tenant-id))
				
				(:div :class "form-group input-group"
				      (:input :class "form-control" :name "password" :id "password" :maxlength "30" :required T  :placeholder "Password"  :type "password"))
				(:div :class "form-group input-group"
				      (:input :class "form-control" :name "confirmpass" :maxlength "30" :required T :data-match "#password" :data-match-error "Passwords dont match !"  :placeholder "Confirm Password"  :type "password"))))
					;else
			   (if (equal mode "EDIT") (cl-who:htm (:div :class "form-group input-group"
							      (:input :class "form-control" :name "usertenantid" :type "hidden" :value tenant-id))))
			   
			   (:div :class "form-group input-group"
				 (:input :class "form-control" :name "userid" :type "hidden" :value row-id))
			   
			   (:div :class "form-group"
				 (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))


(defun dod-controller-add-user-action ()
  (with-opr-session-check 
      (let*  ((userid (hunchentoot:parameter "userid"))
	      (usertenantid (parse-integer (hunchentoot:parameter "usertenantid")))
	      (fullname (hunchentoot:parameter "fullname"))
	      (username (hunchentoot:parameter "username"))
	      (phone (hunchentoot:parameter "phone"))
	      (email (hunchentoot:parameter "email"))
	      (userrole-name (hunchentoot:parameter "userrole"))
	      (password (hunchentoot:parameter "password"))
	      (confirmpass (hunchentoot:parameter "confirmpass"))
	      (salt-octet (secure-random:bytes 56 secure-random:*generator*))
	      (salt (flexi-streams:octets-to-string  salt-octet))
	      (encryptedpass (if (and password confirmpass) (check&encrypt password confirmpass salt)))
      	      (user (select-user-by-id userid usertenantid))
	      (userrole-instance (select-user-role-by-userid userid usertenantid))
	      (roletobeupdated (select-role-by-name userrole-name))
	      (role-row-id (if roletobeupdated (slot-value roletobeupdated 'row-id))))

	(unless (and  
		 (or (null fullname) (zerop (length fullname)))
		 (or (null username) (zerop (length username)))
		 (or (null phone) (zerop (length phone)))
		 (or (null email) (zerop (length email))))		
	  (if user (progn 
		     (setf (slot-value user 'name) fullname)
		     (setf (slot-value user 'username) username)
		     (setf (slot-value user 'phone-mobile) phone)
		     (setf (slot-value user 'email) email)
		     (setf (slot-value userrole-instance 'role-id) role-row-id) 
		     (update-user user)
		     (update-user-role userrole-instance))
					;else
	      (progn 
		(create-dod-user fullname username encryptedpass salt  email phone  usertenantid)
		(let ((user-id  (slot-value (select-user-by-phonenumber phone usertenantid) 'row-id))
		      (role-id (slot-value roletobeupdated 'row-id))) 
		(create-user-role user-id role-id usertenantid)))))
	(hunchentoot:redirect  "/hhub/sadminhome"))))



(defun create-user-with-role (fullname username email phone password userrole-name usertenantid) 
  (let*  ((confirmpass password)
	  (salt-octet (secure-random:bytes 56 secure-random:*generator*))
	  (salt (flexi-streams:octets-to-string  salt-octet))
	  (encryptedpass (check&encrypt password confirmpass salt))
	  (roletobeupdated (select-role-by-name userrole-name)))
    (unless (and  
	     (or (null fullname) (zerop (length fullname)))
	     (or (null username) (zerop (length username)))
	     (or (null phone) (zerop (length phone)))
	     (or (null email) (zerop (length email))))		
      
      (progn 
	(create-dod-user fullname username encryptedpass salt  email phone  usertenantid)
	(let ((user-id  (slot-value (select-user-by-phonenumber phone usertenantid) 'row-id))
	      (role-id (slot-value roletobeupdated 'row-id))) 
	  (create-user-role user-id role-id usertenantid))))))



(defun get-login-userid ()
     (hunchentoot:session-value :login-userid))
    
(defun hhub-session-validp ()
  (if hunchentoot:*session* T))

(defun get-login-user-name ()
  (hunchentoot:session-value :login-username))


(defun verify-superadmin ();;"Verifies whether username is superadmin" 
  (if (equal (get-login-user-name) "superadmin") T NIL ))

(defun superadmin-login ()
(if (verify-superadmin )
  (setf ( hunchentoot:session-value :login-company) "super")))

