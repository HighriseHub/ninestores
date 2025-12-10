;; -*- mode: common-lisp; coding: utf-8 -*
(in-package :nstores)

(defun Customer-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchCustomer" "syssearchCustomer" "idCustomerlivesearch" "Customerlivesearch" "searchCustomeraction" "onkeyupsearchform1event();" "Search for an Customer"
			(submitsearchform1event-js "#idCustomerlivesearch" "#Customerlivesearchresult")))))))

(defun com-hhub-transaction-show-Customer-page ()
  :description "This is a show list page for all the Customer entities"
  (with-cust-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Customer" #'create-model-for-showCustomer #'create-widgets-for-showCustomer :role  :customer))) ;; keep only one role, delete reset. 

(defun create-model-for-showCustomer ()
  :description "This is a model function which will create a model to show Customer entities"
  (let* ((company (get-login-company))
	 (username (get-login-user-name))
	 (presenterobj (make-instance 'CustomerPresenter))
	 (requestmodelobj (make-instance 'CustomerRequestModel
					 :company company))
	 (adapterobj (make-instance 'CustomerAdapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'CustomerHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-Customer-page" params 
      (function (lambda ()
	(values viewallmodel htmlview username))))))

(defun create-widgets-for-showCustomer (modelfunc)
 :description "This is the view/widget function for show Customer entities" 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-customer-breadcrumb)
		       (Customer-search-html)
			 (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for Customer."))
		       (:div :id "Customerlivesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:a :href "/hhub/addCustomer" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Customer"))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
	  (widget3 (function (lambda ()
		     (submitformevent-js "#Customerlivesearchresult")))))
      (list widget1 widget2 widget3))))

(defun create-widgets-for-updateCustomer (modelfunc)
:description "This is a widgets function for update Customer entity"      
  (funcall #'create-widgets-for-genericredirect modelfunc))


(defmethod RenderListViewHTML ((htmlview CustomerHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for Customer entities, which will display each Customer entity in a row"
  (when viewmodellist
    (display-as-table (list "row-id" "name" "address" "phone" "email" "firstname" "lastname" "salutation" "title" "birthdate" "city" "state" "country" "zipcode" "picture-path" "password" "salt" "cust-type" "email-add-verified" "company") viewmodellist 'display-Customer-row)))

(defun create-model-for-searchCustomer ()
  :description "This is a model function for search Customer entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "Customerlivesearch"))
	 (company (get-login-company))
	 (presenterobj (make-instance 'CustomerPresenter))
	 (requestmodelobj (make-instance 'CustomerSearchRequestModel
						 :field1 search-clause
						 :company company))
	 (adapterobj (make-instance 'CustomerAdapter))
	 (domainobjlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'CustomerHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-Customer-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))



(defun com-hhub-transaction-search-Customer-action ()
  :description "This is a MVC function to search action for Customer entities/entity" 
  (let* ((modelfunc (funcall #'create-model-for-searchCustomer))
	 (widgets (funcall #'create-widgets-for-searchCustomer modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
	(cl-who:str (funcall widget))))))

(defun create-model-for-updateCustomer ()
  :description "This is a model function for update Customer entity"
  (let* ((row-id (hunchentoot:parameter "row-id"))
	 (name (hunchentoot:parameter "name"))
	 (address (hunchentoot:parameter "address"))
	 (phone (hunchentoot:parameter "phone"))
	 (email (hunchentoot:parameter "email"))
	 (firstname (hunchentoot:parameter "firstname"))
	 (lastname (hunchentoot:parameter "lastname"))
	 (salutation (hunchentoot:parameter "salutation"))
	 (title (hunchentoot:parameter "title"))
	 (birthdate (hunchentoot:parameter "birthdate"))
	 (city (hunchentoot:parameter "city"))
	 (state (hunchentoot:parameter "state"))
	 (country (hunchentoot:parameter "country"))
	 (zipcode (hunchentoot:parameter "zipcode"))
	 (picture-path (hunchentoot:parameter "picture-path"))
	 (password (hunchentoot:parameter "password"))
	 (salt (hunchentoot:parameter "salt"))
	 (cust-type (hunchentoot:parameter "cust-type"))
	 (email-add-verified (hunchentoot:parameter "email-add-verified"))
	  (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance 'CustomerRequestModel
					 :row-id row-id
					 :name name
					 :address address
					 :phone phone
					 :email email
					 :firstname firstname
					 :lastname lastname
					 :salutation salutation
					 :title title
					 :birthdate birthdate
					 :city city
					 :state state
					 :country country
					 :zipcode zipcode
					 :picture-path picture-path
					 :password password
					 :salt salt
					 :cust-type cust-type
					 :email-add-verified email-add-verified
					 :company company))
	 (adapterobj (make-instance 'CustomerAdapter))
	 (redirectlocation  "/hhub/Customer")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-Customer-action" params 
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))


(defun create-model-for-createCustomer ()
  :description "This is a create model function for creating a Customer entity"
  (let* ((row-id (hunchentoot:parameter "row-id"))
	 (name (hunchentoot:parameter "name"))
	 (address (hunchentoot:parameter "address"))
	 (phone (hunchentoot:parameter "phone"))
	 (email (hunchentoot:parameter "email"))
	 (firstname (hunchentoot:parameter "firstname"))
	 (lastname (hunchentoot:parameter "lastname"))
	 (salutation (hunchentoot:parameter "salutation"))
	 (title (hunchentoot:parameter "title"))
	 (birthdate (hunchentoot:parameter "birthdate"))
	 (city (hunchentoot:parameter "city"))
	 (state (hunchentoot:parameter "state"))
	 (country (hunchentoot:parameter "country"))
	 (zipcode (hunchentoot:parameter "zipcode"))
	 (picture-path (hunchentoot:parameter "picture-path"))
	 (password (hunchentoot:parameter "password"))
	 (salt (hunchentoot:parameter "salt"))
	 (cust-type (hunchentoot:parameter "cust-type"))
	 (email-add-verified (hunchentoot:parameter "email-add-verified"))
	 (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance 'CustomerRequestModel
					 :row-id row-id
					 :name name
					 :address address
					 :phone phone
					 :email email
					 :firstname firstname
					 :lastname lastname
					 :salutation salutation
					 :title title
					 :birthdate birthdate
					 :city city
					 :state state
					 :country country
					 :zipcode zipcode
					 :picture-path picture-path
					 :password password
					 :salt salt
					 :cust-type cust-type
					 :email-add-verified email-add-verified
					 :company company))
	 (adapterobj (make-instance 'CustomerAdapter))
	 (redirectlocation  "/hhub/Customer")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-Customer-action" params 
      (handler-case 
	  (let ((domainobj (ProcessCreateRequest adapterobj requestmodel)))
	    ;; Create the GST HSN Code object if not present. 
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))

(defun com-hhub-transaction-create-Customer-dialog (&optional domainobj)
  :description "This function creates a dialog to create Customer entity"
  (let* ((row-id  (if domainobj (slot-value domainobj 'row-id)))
	 (name  (if domainobj (slot-value domainobj 'name)))
	 (address  (if domainobj (slot-value domainobj 'address)))
	 (phone  (if domainobj (slot-value domainobj 'phone)))
	 (email  (if domainobj (slot-value domainobj 'email)))
	 (firstname  (if domainobj (slot-value domainobj 'firstname)))
	 (lastname  (if domainobj (slot-value domainobj 'lastname)))
	 (salutation  (if domainobj (slot-value domainobj 'salutation)))
	 (title  (if domainobj (slot-value domainobj 'title)))
	 (birthdate  (if domainobj (slot-value domainobj 'birthdate)))
	 (city  (if domainobj (slot-value domainobj 'city)))
	 (state  (if domainobj (slot-value domainobj 'state)))
	 (country  (if domainobj (slot-value domainobj 'country)))
	 (zipcode  (if domainobj (slot-value domainobj 'zipcode)))
	 (picture-path  (if domainobj (slot-value domainobj 'picture-path)))
	 (password  (if domainobj (slot-value domainobj 'password)))
	 (salt  (if domainobj (slot-value domainobj 'salt)))
	 (cust-type  (if domainobj (slot-value domainobj 'cust-type)))
	 (email-add-verified  (if domainobj (slot-value domainobj 'email-add-verified)))
	 (company  (if domainobj (slot-value domainobj 'company))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addCustomer~A" row-id)  (if domainobj "updateCustomeraction" "createCustomeraction")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "row-id" :maxlength "20"  :value  row-id :placeholder "Customer (max 20 characters) " :type "text" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value name :placeholder "name"  :name "name" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value address :placeholder "address"  :name "address" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value phone :placeholder "phone"  :name "phone" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value email :placeholder "email"  :name "email" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value firstname :placeholder "firstname"  :name "firstname" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value lastname :placeholder "lastname"  :name "lastname" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value salutation :placeholder "salutation"  :name "salutation" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value title :placeholder "title"  :name "title" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value birthdate :placeholder "birthdate"  :name "birthdate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value city :placeholder "city"  :name "city" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value state :placeholder "state"  :name "state" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value country :placeholder "country"  :name "country" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value zipcode :placeholder "zipcode"  :name "zipcode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value picture-path :placeholder "picture-path"  :name "picture-path" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value password :placeholder "password"  :name "password" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value salt :placeholder "salt"  :name "salt" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value cust-type :placeholder "cust-type"  :name "cust-type" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value email-add-verified :placeholder "email-add-verified"  :name "email-add-verified" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value email-add-verified :placeholder "email-add-verified"  :name "email-add-verified" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value company :placeholder "company"  :name "company" ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))





(defun create-widgets-for-createCustomer (modelfunc)
  :description "This is a create widget function for Customer entity"
  (funcall #'create-widgets-for-genericredirect modelfunc))




(defun create-widgets-for-searchCustomer (modelfunc)
  :description "This is a widget function for search Customer entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#editCustomer-modal" "Add Customer")
				   (modal-dialog "editCustomer-modal" "Add/Edit Customer" (com-hhub-transaction-create-Customer-dialog)))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))



 
(defun display-Customer-row (Customer)
  :description "This function has HTML row code for Customer entity row"
  (with-slots (row-id name address phone email firstname lastname salutation title birthdate city state country zipcode picture-path password salt cust-type email-add-verified company %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37%) Customer 
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str row-id))
      (:td  :height "10px" (cl-who:str name))
      (:td  :height "10px" (cl-who:str address))
      (:td  :height "10px" (cl-who:str phone))
      (:td  :height "10px" (cl-who:str email))
      (:td  :height "10px" (cl-who:str firstname))
      (:td  :height "10px" (cl-who:str lastname))
      (:td  :height "10px" (cl-who:str salutation))
      (:td  :height "10px" (cl-who:str title))
      (:td  :height "10px" (cl-who:str birthdate))
      (:td  :height "10px" (cl-who:str city))
      (:td  :height "10px" (cl-who:str state))
      (:td  :height "10px" (cl-who:str country))
      (:td  :height "10px" (cl-who:str zipcode))
      (:td  :height "10px" (cl-who:str picture-path))
      (:td  :height "10px" (cl-who:str password))
      (:td  :height "10px" (cl-who:str salt))
      (:td  :height "10px" (cl-who:str cust-type))
      (:td  :height "10px" (cl-who:str email-add-verified))
      (:td  :height "10px" 
	    (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target (format nil "#editCustomer-modal~A" row-id) (:i :class "fa-solid fa-pencil"))
	    (modal-dialog-v2 (format nil "editCustomer-modal~A" row-id) (cl-who:str (format nil "Add/Edit Customer " )) (com-hhub-transaction-create-Customer-dialog Customer))
	    (modal-dialog (format nil "editCustomer-modal~A" row-id) "Add/Edit Customer" (com-hhub-transaction-create-Customer-dialog Customer))))))


(defun com-hhub-transaction-update-Customer-action ()
  :description "This is the MVC function to update action for Customer entity"
  (with-cust-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-updateCustomer #'create-widgets-for-updateCustomer)))
      (format nil "~A" url))))


(defun com-hhub-transaction-create-Customer-action ()
  :description "This is a MVC function for create Customer entity"
  (with-cust-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-createCustomer #'create-widgets-for-createCustomer)))
      (format nil "~A" url))))









