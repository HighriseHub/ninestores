(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


(defun dod-controller-product-categories-page ()
  (with-cad-session-check
    (let* ((company (get-login-company))
	   (categories (select-prdcatg-by-company company))
	   (catgcount (length categories)))
      (with-standard-compadmin-page "Product Categories"
	(with-html-div-row
	  (with-html-div-col
	    (:a :data-toggle "modal" :data-target (format nil "#dodvenaddprodcatg-modal")  :href "#"  (:span :class "glyphicon glyphicon-plus") "Add New Category" )
	    (modal-dialog (format nil "dodvenaddprodcatg-modal") "Add New Category" (modal.product-category-add)))
	  (with-html-div-col :align "right"
	    (:span :class "badge" (cl-who:str (format nil " ~d " catgcount)))))
	(:hr)
	(cl-who:str (display-as-table (list "Name" "Action") categories 'product-category-row))))))

(defun modal.product-category-add ()
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-div-row 
      (with-html-div-col
	(with-html-form "form-productcategories" "hhubprodcatgaddaction"
	  (:div :class "form-group"
		(:input :class "form-control" :name "catg-name" :value "" :placeholder "Category Name" :type "text" ))
	  (:div :class "form-group" 
		(:input :type "submit"  :class "btn btn-primary" :value "Add Category")))))))

(defun product-category-row (category)
  (with-slots (row-id catg-name) category 
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str catg-name))
	(:td :height "10px"
	     (:div :class "col-xs-2" :data-toggle "tooltip" :title "Delete" 
		   (:a :href (format nil "hhubdeleteprodcatg?id=~A" row-id) (:span :class "glyphicon glyphicon-off")))))))



(defun com-hhub-transaction-prodcatg-add-action ()
  (with-cad-session-check
    (let* ((catg-name (hunchentoot:parameter "catg-name"))
	   (company (get-login-company))
	   (params nil))
      
      (setf params (acons "company" company params))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
      
      (with-hhub-transaction "com-hhub-transaction-prodcatg-add-action" params
	(when catg-name (add-new-node-prdcatg catg-name company)))
      (hunchentoot:redirect "/hhub/hhubcadlistprodcatg"))))
  


(defun dod-controller-delete-product-category ()
  (with-cad-session-check
    (let ((id (hunchentoot:parameter "id"))
	  (company (get-login-company)))
      (when id (delete-prd-catg id company))
      (hunchentoot:redirect "/hhub/hhubcadlistprodcatg"))))



(defun com-hhub-transaction-publish-account-exturl ()
  (with-cad-session-check 
    (let* ((params nil))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
      (with-hhub-transaction "com-hhub-transaction-publish-account-exturl" params 
	(let* ((redirectto (hunchentoot:parameter "redirectto"))
	       (account (get-login-company))
	       (ext-url (slot-value account 'external-url)))
	  (unless ext-url
	    (let ((url (generate-account-ext-url account)))
	      (setf (slot-value account 'external-url) url)
	      (update-company account)))
	  (hunchentoot:redirect redirectto))))))


(defun dod-controller-cad-profile ()
  (with-cad-session-check 
    (let ((account (get-login-company)))
      (with-standard-compadmin-page "HighriseHub - Company Admin Profile"
	(:h3 "Welcome " (cl-who:str (format nil "~A" (get-login-user-name))))
	(:hr)
	(:div :class "list-group col-sm-6 col-md-6 col-lg-6"
	      (:a :class "list-group-item"  :href "hhubcadlistprodcatg"  "Product Categories")
	      (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodaccountexturl-modal")  :href "#"  "Account External URL")
	      (modal-dialog (format nil "dodaccountexturl-modal") "Account External URL" (modal.account-external-url account))
	      (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodaccountadminupdate-modal")  :href "#"  "Contact Information")
	      (modal-dialog (format nil "dodaccountadminupdate-modal") "Update Account Administrator" (modal.account-admin-update-details)) 
	      (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodaccadminchangepin-modal")  :href "#"  "Change Password")
	      (modal-dialog (format nil "dodaccadminchangepin-modal") "Change Password" (modal.account-admin-change-pin)))))))



(defun modal.account-admin-change-pin ()
  )

(defun modal.account-external-url (account)
  :description "Update the external URL for a given account"
  (let* ((ext-url (slot-value account 'external-url)))
    (when ext-url
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "row" 
	      (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		    (:p (cl-who:str (format nil "~A" ext-url)))))))
    (unless ext-url
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :id (format nil "form-compadminupdate")  :role "form" :method "POST" :action "hhubpublishaccountexturl" :enctype "multipart/form-data" 
			 (:div :class "form-group" :style "display:none;"
			       (:input :class "form-control" :name "redirectto" :value "/hhub/hhubcadprofile" :placeholder "" :type "text"))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Generate URL")))))))))




(defun modal.account-admin-update-details ()
  (let* ((admin (get-login-user))
	 (name (name admin))
	 (phone  (phone-mobile admin))
	 (email (email admin)))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :id (format nil "form-compadminupdate")  :role "form" :method "POST" :action "hhubcompadminupdateaction" :enctype "multipart/form-data" 
			 (:h1 :class "text-center login-title"  "Update Company Admin Details")
			 (:div :class "form-group"
			       (:input :class "form-control" :name "name" :value name :placeholder "Customer Name" :type "text"))
			 (:div :class "form-group"
			       (:input :class "form-control" :name "phone"  :value phone :placeholder "Phone"  :type "text" ))
			 (:div :class "form-group"
			       (:input :class "form-control" :name "email" :value email :placeholder "Email" :type "text"))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))

      


(defun com-hhub-transaction-compadmin-updatedetails-action ()
  (let* ((params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
    (with-hhub-transaction "com-hhub-transaction-compadmin-updatedetails-action" params
      (let ((name (hunchentoot:parameter "name"))
	    (phone (hunchentoot:parameter "phone"))
	    (email (hunchentoot:parameter "email"))
	    (admin (get-login-user)))
	
	(when admin 
	  (setf (slot-value admin 'name) name)
	  (setf (slot-value admin 'phone-mobile) phone)
	  (setf (slot-value admin 'email) email)
	  (update-user admin))
	(hunchentoot:redirect "/hhub/hhubcadprofile")))))
  
  


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
			      (:li :align "center" (:a :href "/hhub/hhubcadprofile"   (:span :class "glyphicon glyphicon-user") " My Profile" )) 
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
	   login-user
	   password-verified
	   (null (hunchentoot:session-value :login-username))) ;; User should not be logged-in in the first place.
      (progn
	(hunchentoot:start-session)
	(setf (hunchentoot:session-value :login-user) login-user)
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
	     (hunchentoot:remove-session hunchentoot:*session*)
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
   
