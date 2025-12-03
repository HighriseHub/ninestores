; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)


(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun render-compadmin-sidebar-offcanvas ()
    (cl-who:with-html-output (*standard-output* nil :prologue t :indent t)
      (:div :class "offcanvas offcanvas-start" :tabindex"-1" :id "offcanvasExample" :aria-labelledby "offcanvasExampleLabel"
	    (:div :class "offcanvas-header"
		  (:img :src "/img/logo.png" :alt "" :width "32" :height "32" :class "rounded-circle me-2")
		  (:h5 :class "offcanvas-title" :id "offcanvasExampleLabel" "Nine Stores")
		  (:button :type "button" :class "btn-close" :data-bs-dismiss "offcanvas" :aria-label "Close"))
	    (:div :class "offcanvas-body"
		  (:ul :class "nav nav-pills flex-column mb-auto"
		       (:li :class "nav-item"
			    (:a :href "hhubcadindex" :class "nav-link link-body-emphasis"    
				(:i :class "fa-solid fa-house")  "Home"))
		       (:li :class "nav-item" (:a :href "/hhub/dasproductapprovals" :class "nav-link link-body-emphasis"    
						  " Customer Approvals"))
		       (:li :class "nav-item"  (:a :href "/hhub/hhubvendorapprovalpage" :class "nav-link link-body-emphasis"    
						   " Vendor Approvals"))))))))


(defun com-hhub-transaction-vendor-reject-action ()
  (with-cad-session-check
    (let ((params nil)
	  (companyadmin (get-login-user)))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
   (with-hhub-transaction "com-hhub-transaction-vendor-reject-action" params
     (let* ((id (hunchentoot:parameter "vendor-id"))
	    (vendor (select-vendor-by-id id)))
       (reject-vendor vendor companyadmin)
       (hunchentoot:redirect "/hhub/hhubvendorapprovalpage"))))))
      
(defun com-hhub-transaction-vendor-approve-action () 
  (with-cad-session-check
    (let* ((params nil)
	   (vendor-id (hunchentoot:parameter "vendor-id"))
	   (companyadmin (get-login-user)))

      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
      (setf params (acons "company" (get-login-company) params))
      
      (with-hhub-transaction "com-hhub-transaction-vendor-approve-action"  params
	(let* ((requestmodel (make-instance 'RequestModelVendorApproval
					    :vendor-id vendor-id
					    :companyadmin companyadmin))
	       (adapter (make-instance 'VendorApprovalAdapter)))
	  (ProcessUpdateRequest adapter requestmodel)
	  (hunchentoot:redirect "/hhub/hhubvendorapprovalpage"))))))
      
(defun test-vendor-approval ()
  (let* ((vendor-id 1)
	 (companyadmin (select-user-by-id 4 2))
	 (requestmodel (make-instance 'RequestModelVendorApproval
				      :vendor-id vendor-id
				      :companyadmin companyadmin))
	 (adapter (make-instance 'VendorApprovalAdapter))
	 (updatedvendor (ProcessUpdateRequest adapter requestmodel)))
    updatedvendor))


(defun create-model-for-productcategoriespage ()
  (let* ((company (get-login-company))
	 (categories (select-prdcatg-by-company company))
	 (catgcount (length categories)))
    (function (lambda ()
      (values categories catgcount)))))

(defun create-widgets-for-productcategoriespage (modelfunc)
  (multiple-value-bind ( categories catgcount) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-html-div-row
			 (with-html-div-col
			   (:a :data-bs-toggle "modal" :data-bs-target (format nil "#dodvenaddprodcatg-modal")  :href "#"  (:i :class "fa-solid fa-plus") "Add New Category" )
			   (modal-dialog-v2 (format nil "dodvenaddprodcatg-modal") "Add New Category" (modal.product-category-add)))
			 (with-html-div-col :align "right"
			   (:span :class "badge" (cl-who:str (format nil " ~d " catgcount)))))
		       (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (cl-who:str (display-as-table (list "Name" "Action") categories 'product-category-row)))))))
    (list widget1 widget2))))

  
(defun dod-controller-product-categories-page ()
  (with-cad-session-check
    (with-mvc-ui-page "Company Admin - Product Categories" #'create-model-for-productcategoriespage #'create-widgets-for-productcategoriespage :role :compadmin)))


(defun modal.product-category-add ()
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-div-row 
      (with-html-div-col-8
	(with-html-form "form-productcategories" "hhubprodcatgaddaction"
	  (:div :class "form-group"
		(:input :class "form-control" :name "catg-name" :value "" :placeholder "Category Name" :type "text" ))
	  (:div :class "form-group" 
		(:input :type "submit"  :class "btn btn-primary" :value "Add Category")))))))

(defun product-category-row (category &rest arguments)
  (declare (ignore arguments))
  (with-slots (row-id catg-name) category 
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str catg-name))
	(:td :height "10px"
	     (:div :class "col-xs-2" :data-toggle "tooltip" :title "Delete" 
		   (:a :href (format nil "hhubdeleteprodcatg?id=~A" row-id) (:i :class "fa-regular fa-trash-can")))))))



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



(defun create-model-for-publishaccountexturl ()
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
	(function (lambda ()
	  redirectto))))))

  
(defun com-hhub-transaction-publish-account-exturl ()
  (with-cad-session-check
    (let ((uri (with-mvc-redirect-ui #'create-model-for-publishaccountexturl #'create-widgets-for-genericredirect)))
      (format nil "~A" uri))))

(defun create-model-for-cadprofile ()
  (let ((account (get-login-company))
	(loginusername (get-login-user-name)))
    (function (lambda ()
      (values account loginusername)))))

(defun create-widgets-for-cadprofile (modelfunc)
  (multiple-value-bind (account loginusername) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-catch-submit-event "idcadprofile" 
			 (:h3 "Welcome " (cl-who:str (format nil "~A" loginusername)))
			 (:hr)
			 (:div :class "list-group col-sm-6 col-md-6 col-lg-6"
			       (:a :class "list-group-item"  :href "hhubcadlistprodcatg"  "Product Categories")
			       (:a :data-bs-toggle "modal" :class "list-group-item"  :data-bs-target (format nil "#dodaccountexturl-modal")  :href "#"  "Account External URL")
			       (modal-dialog-v2 (format nil "dodaccountexturl-modal") "Account External URL" (modal.account-external-url account))
			       (:a :class "list-group-item" :data-bs-toggle "modal" :data-bs-target (format nil "#dodaccountadminupdate-modal")  :href "#"  "Contact Information")
			       (modal-dialog-v2 (format nil "dodaccountadminupdate-modal") "Update Account Administrator" (modal.account-admin-update-details)) 
			       (:a :class "list-group-item" :data-bs-toggle "modal" :data-bs-target (format nil "#dodaccadminchangepin-modal")  :href "#"  "Change Password")
			       (modal-dialog-v2 (format nil "dodaccadminchangepin-modal") "Change Password" (modal.account-admin-change-pin)))))))))
      (list widget1))))

(defun dod-controller-cad-profile ()
  (with-cad-session-check
    (with-mvc-ui-page "Welcome Company Administrator" #'create-model-for-cadprofile #'create-widgets-for-cadprofile :role :compadmin)))


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

      
(defun create-model-for-cadupdatedetailsaction ()
  (let* ((params nil)
	 (redirectlocation "/hhub/hhubcadprofile"))
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
	(function (lambda ()
	  redirectlocation))))))


(defun com-hhub-transaction-compadmin-updatedetails-action ()
  (with-cad-session-check
    (let ((uri (with-mvc-redirect-ui #'create-model-for-cadupdatedetailsaction #'create-widgets-for-genericredirect)))
      (format nil "~A" uri))))

(eval-when (:compile-toplevel :load-toplevel :execute)
 (defun with-compadmin-navigation-bar ()
    :documentation "This macro returns the html text for generating a navigation bar using bootstrap."
    (cl-who:with-html-output (*standard-output* nil)
       (:nav :class "navbar navbar-expand-sm  sticky-top navbar-dark bg-dark" :id "hhubcompadminnavbar"  
     	     (:div  :class "container-fluid"
		   (:a :class "navbar-brand" :href "/hhub/hhubcadindex" (:img :style "width: 30px; height: 24px;" :src "/img/logo.png" ))
		   (:button :class "navbar-toggler" :type "button" :data-bs-toggle "collapse" :data-bs-target "#navbarSupportedContent" :aria-controls "navbarSupportedContent" :aria-expanded "false" :aria-label "Toggle navigation" 
			    (:span :class "navbar-toggler-icon" ))
		   (:div :class "collapse navbar-collapse justify-content-between" :id "navbarSupportedContent"
			 (:ul :class "navbar-nav me-auto mb-2 mb-lg-0"
			      (:li :class "nav-item"
				  (:a :class "btn btn-primary" :data-bs-toggle "offcanvas" :href "#offcanvasExample" :role "button" :aria-controls "offcanvasExample" (:i :class "fa-solid fa-bars")))
			      (:li :class "nav-item" 	
				   (:a :class "nav-link active" :aria-current "page" :href "/hhub/hhubcadindex" (:i :class "fa-solid fa-house") "&nbsp;Home"))
		   	      ;;(:li :class "nav-item" :align "center" (:a :class "nav-link" :href "#" (cl-who:str (format nil "Group: ~a" (slot-value (get-login-company) 'name)))))
			      (:li :class "nav-item" :align "center" (:a :class "nav-link" :href "#" (print-web-session-timeout))))
			 (:ul :class "navbar-nav ms-auto"
			      (:li :class "nav-item"  (:a :class "nav-link" :href "#"  (:i :class "fa-regular fa-bell")))
			      (:li :class "nav-item"  (:a :class "nav-link" :href "/hhub/hhubcadprofile"  (:i :class "fa-regular fa-user")))
			      (:li :class "nav-item" (:a :class "nav-link" :href "/hhub/hhubcadlogout" (:i :class "fa-solid fa-arrow-right-from-bracket"))))))))))


(defun com-hhub-transaction-cad-login-page ()
  (handler-case 
      (progn  (if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)	      
	      (if (is-dod-session-valid?)
		  (hunchentoot:redirect "/hhub/hhubcadindex")
		  ;else
		  (with-standard-compadmin-page "Company Administrator Login"
		    (:div :id "idcompadminlogin" :class "row"
			  (:div :class "col-sm-6 col-md-4 col-md-offset-4"
				(:div :class "account-wall"
				      (:img :class "profile-img" :src "/img/logo.png" :alt "")
				      (:h1 :class "text-center login-title"  "Login to Nine Stores")
				      (:form :class "form-signin" :role "form" :method "POST" :action "hhubcadloginaction"
					     (:div :class "form-group"
						   (:input :class "form-control" :name "phone" :placeholder "Enter RMN. Ex: 9999999999" :type "text"))
					     (:div :class "form-group"
						   (:input :class "form-control" :name "password"  :placeholder "Password=demo" :type "password"))
					     (:input :type "submit"  :class "btn btn-primary" :value "Login")))))
		    (submitformevent-js "#idcompadminlogin")))) 
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2006 )
	  (progn
	    (stop-das) 
	    (start-das)
	    (hunchentoot:redirect "/hhub/cad-login.html"))))))

;;;;;;;;;;;; com-hhub-transaction-compadmin-home ;;;;;;;;;;;;;;;
(defun create-model-for-compadminhome ()
  (let ((params nil))
    ;; We are not checking the URI for home page, because it contains the session variable. 
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
    (with-hhub-transaction "com-hhub-transaction-compadmin-home" params
      (let* ((products (get-products-for-approval (get-login-tenant-id)))
	     (numproducts (length products))
	     (username (get-login-user-name)))
	(function (lambda ()
	  (values  products numproducts username)))))))

(defun create-widgets-for-compadminhome (modelfunc)
  (multiple-value-bind ( products numproducts username) (funcall  modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)   
		       (with-html-div-row
			 (with-html-div-col-6
			   (:h4 "Welcome " (cl-who:str (format nil "~A" username)))))
		       (:hr)
		       (with-html-div-row
			 (with-html-div-col-6
			   (:p "Pending Product Approvals"))
			 (with-html-div-col-6 
			   (:div :class "col-xs-6" :align "right" 
				 (:b (:span :class "position-relative translate-middle badge rounded-pill bg-success" (cl-who:str (format nil "~d" numproducts)))))))
		       (:hr)
		       (with-catch-submit-event  "idcompadminhome" 
			 (cl-who:str (display-as-tiles products 'product-card-for-approval "product-box" ))))))))
      (list widget1))))

(defun com-hhub-transaction-compadmin-home () 
  (with-cad-session-check
    (with-mvc-ui-page "Welcome Company Administrator" #'create-model-for-compadminhome #'create-widgets-for-compadminhome :role :compadmin)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;com-hhub-transaction-cad-login-action;;;;;;;;;;;;
(defun create-model-for-cadloginaction ()
  (let ((params nil)
	(redirectlocation "/hhub/cad-login.html"))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    ;; The person has not yet logged in 
    ;; (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
    (with-hhub-transaction "com-hhub-transaction-cad-login-action" params
      (let  ((phone (hunchentoot:parameter "phone"))
	     (passwd (hunchentoot:parameter "password")))
	(unless (and
		 (or (null phone) (zerop (length phone)))
		 (or (null passwd) (zerop (length passwd))))
	  (if (dod-cad-login :phone phone :password passwd)
	      (setf redirectlocation "/hhub/hhubcadindex")))))
    (function (lambda ()
      redirectlocation))))

(defun com-hhub-transaction-cad-login-action ()
  (let ((uri (with-mvc-redirect-ui #'create-model-for-cadloginaction #'create-widgets-for-genericredirect)))
    (format nil "~A" uri)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun dod-cad-login (&key phone  password)
  (let* ((login-user (car (clsql:select 'dod-users :where [and
				       [= [slot-value 'dod-users 'phone-mobile] phone]]
				       :caching nil :flatp t)))
	 (login-company (if login-user (slot-value login-user 'company)))
	 (pwd (if login-user (slot-value login-user 'password)))
	 (salt (if login-user (slot-value login-user 'salt)))
	 (password-verified (if login-user  (check-password password salt pwd))))
	 
    (unless login-user (hunchentoot:log-message* :info "Company admin user does not exist - ~A" phone))
    (unless password-verified (hunchentoot:log-message* :info "Password not verified for ~A" phone))

    (when (and   
	   login-user
	   password-verified
	   (null (hunchentoot:session-value :login-user-name))) ;; User should not be logged-in in the first place.
      (progn
	(hunchentoot:start-session)
	(setf hunchentoot:*session-max-time* (* 3600 8))
	(set-user-session-params login-company login-user)
	T))))







;;;;;;;;;;;;;;com-hhub-transaction-cad-logout;;;;;;;;;;;;;;;
(defun create-model-for-cadlogout ()
  (let ((params nil)
	(username (get-login-user-name))
	(redirectlocation "/hhub/cad-login.html"))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
    (with-hhub-transaction "com-hhub-transaction-cad-logout" params 
      (progn
	(dod-logout username)
	(when hunchentoot:*session* (hunchentoot:remove-session hunchentoot:*session*))
	(deleteBusinessSession (getBusinessContext *HHUBBUSINESSSERVER* "compadminsite") (hunchentoot:session-value :login-user-business-session-id)) 
	(function (lambda ()
	  redirectlocation))))))

(defun com-hhub-transaction-cad-logout ()
  (let ((uri (with-mvc-redirect-ui #'create-model-for-cadlogout #'create-widgets-for-genericredirect)))
    (hunchentoot:redirect (format nil "~A" uri))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  

(defun create-model-for-cadproductrejectaction ()
  (let ((params nil)
	(company (get-login-company))
	(redirectlocation "/hhub/hhubcadindex"))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
    (with-hhub-transaction "com-hhub-transaction-cad-product-reject-action" params 
      (let ((id (hunchentoot:parameter "id"))
	    (description (hunchentoot:parameter "description")))
	(reject-product id description company)
	(function (lambda ()
	  redirectlocation))))))

(defun com-hhub-transaction-cad-product-reject-action ()
  (with-cad-session-check
    (let ((uri (with-mvc-redirect-ui #'create-model-for-cadproductrejectaction #'create-widgets-for-genericredirect)))
      (format nil "~A" uri))))



(defun create-model-for-cadproductapproveaction ()
  (let ((params nil)
	(redirectlocation "/hhub/hhubcadindex"))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
    (with-hhub-transaction "com-hhub-transaction-cad-product-approve-action" params
      (let ((id (hunchentoot:parameter "id"))
	    (description (hunchentoot:parameter "description")))
	(approve-product id description (get-login-company))
	(function (lambda ()
	  redirectlocation))))))

(defun com-hhub-transaction-cad-product-approve-action ()
  (with-cad-session-check
    (let ((uri (with-mvc-redirect-ui #'create-model-for-cadproductapproveaction #'create-widgets-for-genericredirect)))
      (format nil "~A" uri))))
  

(defun dod-controller-products-approval-page ()
  :documentation "This controller function is used by the System admin and Company Admin to approve products" 
 (with-cad-session-check
   (let ((products (get-products-for-approval (get-login-tenant-id))))
     (with-standard-compadmin-page-v2 "New products approval" 
       (welcomemessage (get-login-user-name))
       (:hr)
       (with-html-div-row
	 (with-html-div-col (:h4 "Pending Product Approvals"))
	 (with-html-div-col :align "right"
 	   (:span :class "badge" (cl-who:str (format nil "~A" (length products))))))
       (:hr)
       (cl-who:str (display-as-tiles products 'product-card-for-approval 'product-box ))))))

(defun dod-controller-vendor-approval-page ()
  :documentation "This controller function is used by the System admin and Company Admin to approve vendors" 
 (with-cad-session-check
   (let ((pendingvendors (get-vendors-for-approval (get-login-tenant-id))))
     (with-standard-compadmin-page-v2 "New Vendor approval" 
       (welcomemessage (get-login-user-name))
       (:hr)
       (with-html-div-row
	 (with-html-div-col (:h4 "Pending Vendor Approvals"))
	 (with-html-div-col :align "right"
	   (:span :class "badge" (cl-who:str (format nil "~A" (length pendingvendors))))))
       (:hr)
       (cl-who:str (display-as-tiles pendingvendors 'vendor-card-for-approval "vendor-card" ))))))



(defun vendor-card-for-approval (vendor-instance)
    (let* ((name (slot-value vendor-instance 'name))
	   (phone (slot-value vendor-instance 'phone))
	   (vendor-id (slot-value vendor-instance 'row-id))
	   ;; (active-flag (slot-value vendor-instance 'active-flag))
	   (approved-flag (slot-value vendor-instance 'approved-flag))
	   (tenant-id (slot-value vendor-instance 'tenant-id))
	   (company (select-company-by-id tenant-id))
	   (company-name (slot-value company 'name))
	   (approval-status (slot-value vendor-instance 'approval-status)))
      (when (and (equal approved-flag "N") (equal approval-status "PENDING"))
	(cl-who:with-html-output (*standard-output* nil)
	  (with-html-div-row
	    (with-html-div-col-12
	      (:h5 (cl-who:str (format nil "~A" company-name)))))
	  (with-html-div-row
	    (:h5 :class "product-name" (cl-who:str (if (> (length name) 30)  (subseq name  0 30) name))))
	  (with-html-div-row
	    (:h5 :class "product-name" (cl-who:str phone)))
	  (with-html-div-row
	    (with-html-div-col-6
	      (:button :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendreject-modal~A" vendor-id)  :href "#"  (:i :class "fa-solid fa-ban") "Reject")
	      (modal-dialog-v2 (format nil "dodvendreject-modal~A" vendor-id) "Reject Vendor" (modal.reject-vendor-html vendor-id)))
	    (with-html-div-col-6
	      (:button :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendaccept-modal~A" vendor-id)  :href "#"  (:i :class "fa-regular fa-thumbs-up") "Approve")
	      (modal-dialog-v2 (format nil "dodvendaccept-modal~A" vendor-id) "Approve Vendor" (modal.approve-vendor-html vendor-id ))))))))



(defun modal.reject-vendor-html (vendor-id)
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-form "form-vendorreject" "hhubvendorrejectaction" 
      (:div :class "form-group" :style "display: none"
	    (:input :class "form-control" :name "vendor-id" :value vendor-id :type "text" :readonly T ))
      (:div :class "form-group"
	    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Reject")))))

(defun modal.approve-vendor-html (vendor-id)
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-form "form-vendorreject" "hhubvendorapproveaction"
      (:div :class "form-group" :style "display: none"
	    (:input :class "form-control" :name "vendor-id" :value vendor-id :type "text" :readonly T ))
      (:div :class "form-group"
	    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Approve")))))



      
