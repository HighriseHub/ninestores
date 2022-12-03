(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-compadmin-navigation-bar ()
    :documentation "This macro returns the html text for generating a navigation bar using bootstrap."
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "navbar navbar-default navbar-inverse navbar-static-top"
	     (:div :class "container-fluid"
		   (:div :class "navbar-header"
			 (:button :type "button" :class "navbar-toggle" :data-toggle "collapse" :data-target "#navHeaderCollapse"
				  (:span :class "icon-bar")
				  (:span :class "icon-bar")
				  (:span :class "icon-bar"))
			 (:a :class "navbar-brand" :href "#" :title "HighriseHub" (:img :style "width: 30px; height: 30px;" :src "/img/logo.png" )  ))
		   (:div :class "collapse navbar-collapse" :id "navHeaderCollapse"
			 (:ul :class "nav navbar-nav navbar-left"
			      (:li :class "active" :align "center" (:a :href "/hhub/hhubcadindex"  (:span :class "glyphicon glyphicon-home")  " Home"))
			      (:li  (:a :href "/hhub/dasproductapprovals" "Customer Approvals"))
			      (:li  (:a :href "/hhub/dasproductapprovals" "Vendor Approvals"))
			      (:li :align "center" (:a :href "#" (cl-who:str (format nil "Group: ~a" (slot-value (get-login-company) 'name)))))
			      (:li :align "center" (:a :href "#" (print-web-session-timeout))))
			 
			 (:ul :class "nav navbar-nav navbar-right"
			      (:li :align "center" (:a :href "#"   (:span :class "glyphicon glyphicon-user") " My Profile" )) 
			      (:li :align "center" (:a :href "/hhub/hhubcadlogout"  (:span :class "glyphicon glyphicon-off") " Logout "  )))))))))
  

(defun com-hhub-transaction-cad-login-page ()
  (handler-case 
      (progn  (if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)	      
	      (if (is-dod-session-valid?)
		  (hunchentoot:redirect "/hhub/hhubcadindex")
		  ;else
		  (with-standard-compadmin-page "Company Administrator Login"
						(:div :class "row"
			  (:div :class "col-sm-6 col-md-4 col-md-offset-4"
				(:div :class "account-wall"
				      (:img :class "profile-img" :src "/img/logo.png" :alt "")
				      (:h1 :class "text-center login-title"  "Login to HighriseHub")
				      (:form :class "form-signin" :role "form" :method "POST" :action "hhubcadloginaction"
					     
					     (:div :class "form-group"
						   (:input :class "form-control" :name "phone" :placeholder "Enter RMN. Ex: 9999999999" :type "text"))
					     (:div :class "form-group"
						   (:input :class "form-control" :name "password"  :placeholder "Password=demo" :type "password"))
					     (:input :type "submit"  :class "btn btn-primary" :value "Login      "))))))))
	      (clsql:sql-database-data-error (condition)
					     (if (equal (clsql:sql-error-error-id condition) 2006 ) (progn
												      (stop-das) 
												      (start-das)
												      (hunchentoot:redirect "/hhub/cad-login.html"))))))



(defun com-hhub-transaction-compadmin-home () 
  (with-cad-session-check 
  (let ((params nil))
    ; We are not checking the URI for home page, because it contains the session variable. 
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
    (with-hhub-transaction "com-hhub-transaction-compadmin-home" params
	(let ((products (get-products-for-approval (get-login-tenant-id))))
	  (with-standard-compadmin-page  "Welcome to Highrisehub."
	    (:div :class "container"
		  (:div :id "row"
			(:div :id "col-xs-6" 
			      (:h3 "Welcome " (cl-who:str (format nil "~A" (get-login-user-name))))))
		  (:hr)
		  (:h4 "Pending Product Approvals")
		  (:div :id "row"
			(:div :id "col-xs-6"
			      (:div :id "col-xs-6" :align "right" 
				  (:span :class "badge" (cl-who:str (format nil "~A" (length products)))))))
		  (:hr)
		  (cl-who:str (display-as-tiles products 'product-card-for-approval "product-box" )))))))))
  
  
(defun com-hhub-transaction-cad-login-action ()
  (let ((params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    ; The person has not yet logged in 
					;(setf params (acons "rolename" (com-hhub-attribute-role-name) params))
    (with-hhub-transaction "com-hhub-transaction-cad-login-action" params
    (let  ((phone (hunchentoot:parameter "phone"))
	   (passwd (hunchentoot:parameter "password")))
      (unless(and
	      ( or (null phone) (zerop (length phone)))
	      ( or (null passwd) (zerop (length passwd))))
	(if (dod-cad-login :phone phone :password passwd)
	    (hunchentoot:redirect  "/hhub/hhubcadindex")
					;else
	      (hunchentoot:redirect "/hhub/cad-login.html")))))))


(defun dod-cad-login (&key phone  password)
  (let* ((login-user (car (clsql:select 'dod-users :where [and
				       [= [slot-value 'dod-users 'phone-mobile] phone]]
				       :caching nil :flatp t)))
	 (login-userid (if login-user (slot-value login-user 'row-id)))
	 (login-attribute-cart '())
	 (login-tenant-id (if login-user (slot-value  (users-company login-user) 'row-id)))
	 (login-company (if login-user (slot-value login-user 'company)))
	 (username (if login-user (slot-value login-user 'username)))
	 (pwd (if login-user (slot-value login-user 'password)))
	 (salt (if login-user (slot-value login-user 'salt)))
	 (password-verified (if login-user  (check-password password salt pwd)))
	 (company-name (if login-user (slot-value (users-company login-user) 'name))))

    (unless login-user (hunchentoot:log-message* :info "Company admin user does not exist - ~A" phone))
    (unless password-verified (hunchentoot:log-message* :info "Password not verified for ~A" phone))

    (when (and   
	   login-user password-verified
	   (null (hunchentoot:session-value :login-username)) ;; User should not be logged-in in the first place.
	   )  (progn 				      (setf *current-user-session* (hunchentoot:start-session))
				      (setf (hunchentoot:session-value :login-username) username)
				      (setf (hunchentoot:session-value :login-userid) login-userid)
				      (setf (hunchentoot:session-value :login-attribute-cart) login-attribute-cart)
				      (setf (hunchentoot:session-value :login-tenant-id) login-tenant-id)
				      (setf (hunchentoot:session-value :login-company-name) company-name)
				      (setf (hunchentoot:session-value :login-company) login-company)
				      T))))


  
(defun com-hhub-transaction-cad-logout ()
  (let ((params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
    (with-hhub-transaction "com-hhub-transaction-cad-logout" params 
      (progn (dod-logout (get-login-user-name))
	     (hunchentoot:remove-session *current-user-session*)
	     (hunchentoot:redirect "/hhub/cad-login.html")))))



(defun com-hhub-transaction-cad-product-reject-action ()
  (with-cad-session-check
     (let ((params nil))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
   (with-hhub-transaction "com-hhub-transaction-cad-product-reject-action" params 
    (let ((id (hunchentoot:parameter "id"))
	    (description (hunchentoot:parameter "description")))
	(reject-product id description (get-login-company))
	(hunchentoot:redirect "/hhub/hhubcadindex"))))))
     



(defun com-hhub-transaction-cad-product-approve-action ()
  (with-cad-session-check
    (let ((params nil))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
   (with-hhub-transaction "com-hhub-transaction-cad-product-approve-action" params
      (let ((id (hunchentoot:parameter "id"))
	    (description (hunchentoot:parameter "description")))
	(approve-product id description (get-login-company))
	(hunchentoot:redirect "/hhub/hhubcadindex"))))))


(defun dod-controller-products-approval-page ()
  :documentation "This controller function is used by the System admin and Company Admin to approve products" 
 (with-cad-session-check
   (let ((products (get-products-for-approval (get-login-tenant-id))))
     (with-standard-compadmin-page "New products approval" 
	(:div :class "container"
	(:div :id "row"
	      (:div :id "col-xs-6" 
	(:h3 "Welcome " (cl-who:str (format nil "~A" (get-login-user-name))))))
	(:hr)
	(:h4 "Pending Product Approvals")
	(:div :id "row"
	      (:div :id "col-xs-6"
		    (:div :id "col-xs-6" :align "right" 
			  (:span :class "badge" (cl-who:str (format nil "~A" (length products)))))))
	(:hr)
   	(cl-who:str (display-as-tiles products 'product-card-for-approval 'product-box )))))))
   
