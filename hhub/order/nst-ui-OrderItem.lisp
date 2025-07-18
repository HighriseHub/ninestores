;; -*- mode: common-lisp; coding: utf-8 -*
(in-package :nstores)

(defun OrderItems-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchOrderItems" "syssearchOrderItems" "idOrderItemslivesearch" "OrderItemslivesearch" "searchOrderItemsaction" "onkeyupsearchform1event();" "Search for an OrderItems"
			(submitsearchform1event-js "#idOrderItemslivesearch" "#OrderItemslivesearchresult")))))))

(defun com-hhub-transaction-show-OrderItems-page ()
  :description "This is a show list page for all the OrderItems entities"
  (with-cust-session-check ;; delete if not needed. 
    (with-mvc-ui-page "OrderItems" #'create-model-for-showOrderItems #'create-widgets-for-showOrderItems :role :customer ))) ;; keep only one role, delete reset. 

(defun create-model-for-showOrderItems ()
  :description "This is a model function which will create a model to show OrderItems entities"
  (let* ((company (get-login-company))
	 (username (get-login-user-name))
	 (presenterobj (make-instance 'OrderItemsPresenter))
	 (requestmodelobj (make-instance 'OrderItemsRequestModel
					 :company company))
	 (adapterobj (make-instance 'OrderItemsAdapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'OrderItemsHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-OrderItems-page" params 
      (function (lambda ()
	(values viewallmodel htmlview username))))))

(defun create-widgets-for-showOrderItems (modelfunc)
 :description "This is the view/widget function for show OrderItems entities" 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-vendor-breadcrumb)
		       (OrderItems-search-html)
			 (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for OrderItems."))
		       (:div :id "OrderItemslivesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:a :href "/hhub/addOrderItems" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create OrderItems"))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
	  (widget3 (function (lambda ()
		     (submitformevent-js "#OrderItemslivesearchresult")))))
      (list widget1 widget2 widget3))))

(defun create-widgets-for-updateOrderItems (modelfunc)
:description "This is a widgets function for update OrderItems entity"      
  (funcall #'create-widgets-for-genericredirect modelfunc))

(defmethod RenderListViewHTML ((htmlview OrderItemsHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for OrderItems entities, which will display each OrderItems entity in a row"
  (when viewmodellist
    (display-as-table (list "row-id" "order" "product" "vendor" "prd-qty" "unit-price" "disc-rate" "cgst" "sgst" "igst" "addl-tax1-rate" "comments" "fulfilled" "status" "deleted-state" "company" "%16%" "%17%" "%18%" "%19%" "%20%" "%21%" "%22%" "%23%" "%24%" "%25%" "%26%" "%27%" "%28%" "%29%" "%30%" "%31%" "%32%" "%33%" "%34%" "%35%" "%36%" "%37%") viewmodellist 'display-OrderItems-row)))

(defun create-model-for-searchOrderItems ()
  :description "This is a model function for search OrderItems entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "OrderItemslivesearch"))
	 (company (get-login-company))
	 (presenterobj (make-instance 'OrderItemsPresenter))
	 (requestmodelobj (make-instance 'OrderItemsSearchRequestModel
						 :field1 search-clause
						 :company company))
	 (adapterobj (make-instance 'OrderItemsAdapter))
	 (domainobjlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'OrderItemsHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-OrderItems-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))



(defun com-hhub-transaction-search-OrderItems-action ()
  :description "This is a MVC function to search action for OrderItems entities/entity" 
  (let* ((modelfunc (funcall #'create-model-for-searchOrderItems))
	 (widgets (funcall #'create-widgets-for-searchOrderItems modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
	(cl-who:str (funcall widget))))))

(defun create-model-for-updateOrderItems ()
  :description "This is a model function for update OrderItems entity"
  (let* ((row-id (hunchentoot:parameter "row-id"))
	 (order (hunchentoot:parameter "order"))
	 (product (hunchentoot:parameter "product"))
	 (vendor (hunchentoot:parameter "vendor"))
	 (prd-qty (hunchentoot:parameter "prd-qty"))
	 (unit-price (float (with-input-from-string (in (hunchentoot:parameter "unit-price"))
			      (read in))))
	 (disc-rate (float (with-input-from-string (in (hunchentoot:parameter "disc-rate"))
		   (read in))))
	 (cgst (hunchentoot:parameter "cgst"))
	 (sgst (hunchentoot:parameter "sgst"))
	 (igst (hunchentoot:parameter "igst"))
	 (addl-tax1-rate (hunchentoot:parameter "addl-tax1-rate"))
	 (comments (hunchentoot:parameter "comments"))
	 (fulfilled (hunchentoot:parameter "fulfilled"))
	 (status (hunchentoot:parameter "status"))
	 (deleted-state (hunchentoot:parameter "deleted-state"))
	 (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance 'OrderItemsRequestModel
					 :row-id row-id
					 :order order
					 :product product
					 :vendor vendor
					 :prd-qty prd-qty
					 :unit-price unit-price
					 :disc-rate disc-rate
					 :cgst cgst
					 :sgst sgst
					 :igst igst
					 :addl-tax1-rate addl-tax1-rate
					 :comments comments
					 :fulfilled fulfilled
					 :status status
					 :deleted-state deleted-state
					 :company company))
	 (adapterobj (make-instance 'OrderItemsAdapter))
	 (redirectlocation  "/hhub/OrderItems")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-OrderItems-action" params 
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))


(defun create-model-for-createOrderItems ()
  :description "This is a create model function for creating a OrderItems entity"
  (let* ((row-id (hunchentoot:parameter "row-id"))
	 (order (hunchentoot:parameter "order"))
	 (product (hunchentoot:parameter "product"))
	 (vendor (hunchentoot:parameter "vendor"))
	 (prd-qty (hunchentoot:parameter "prd-qty"))
	 (unit-price (float (with-input-from-string (in (hunchentoot:parameter "unit-price"))
			      (read in))))
	 (disc-rate (float (with-input-from-string (in (hunchentoot:parameter "disc-rate"))
		   (read in))))
	 (cgst (hunchentoot:parameter "cgst"))
	 (sgst (hunchentoot:parameter "sgst"))
	 (igst (hunchentoot:parameter "igst"))
	 (addl-tax1-rate (hunchentoot:parameter "addl-tax1-rate"))
	 (comments (hunchentoot:parameter "comments"))
	 (fulfilled (hunchentoot:parameter "fulfilled"))
	 (status (hunchentoot:parameter "status"))
	 (deleted-state (hunchentoot:parameter "deleted-state"))
	 (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance 'OrderItemsRequestModel
					 :row-id row-id
					 :order order
					 :product product
					 :vendor vendor
					 :prd-qty prd-qty
					 :unit-price unit-price
					 :disc-rate disc-rate
					 :cgst cgst
					 :sgst sgst
					 :igst igst
					 :addl-tax1-rate addl-tax1-rate
					 :comments comments
					 :fulfilled fulfilled
					 :status status
					 :deleted-state deleted-state
					 :company company
					 :company company))
	 (adapterobj (make-instance 'OrderItemsAdapter))
	 (redirectlocation  "/hhub/OrderItems")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-OrderItems-action" params 
      (handler-case 
	  (let ((domainobj (ProcessCreateRequest adapterobj requestmodel)))
	    ;; Create the GST HSN Code object if not present. 
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))

(defun com-hhub-transaction-create-OrderItems-dialog (&optional domainobj)
  :description "This function creates a dialog to create OrderItems entity"
  (let* ((row-id  (if domainobj (slot-value domainobj 'row-id)))
	 (order  (if domainobj (slot-value domainobj 'order)))
	 (product  (if domainobj (slot-value domainobj 'product)))
	 (vendor  (if domainobj (slot-value domainobj 'vendor)))
	 (prd-qty  (if domainobj (slot-value domainobj 'prd-qty)))
	 (unit-price  (if domainobj (slot-value domainobj 'unit-price)))
	 (disc-rate  (if domainobj (slot-value domainobj 'disc-rate)))
	 (cgst  (if domainobj (slot-value domainobj 'cgst)))
	 (sgst  (if domainobj (slot-value domainobj 'sgst)))
	 (igst  (if domainobj (slot-value domainobj 'igst)))
	 (addl-tax1-rate  (if domainobj (slot-value domainobj 'addl-tax1-rate)))
	 (comments  (if domainobj (slot-value domainobj 'comments)))
	 (fulfilled  (if domainobj (slot-value domainobj 'fulfilled)))
	 (status  (if domainobj (slot-value domainobj 'status)))
	 (deleted-state  (if domainobj (slot-value domainobj 'deleted-state)))
	 (company  (if domainobj (slot-value domainobj 'company))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addOrderItems~A" row-id)  (if domainobj "updateOrderItemsaction" "createOrderItemsaction")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "row-id" :maxlength "20"  :value  row-id :placeholder "OrderItems (max 20 characters) " :type "text" ))
		    
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value order :placeholder "order"  :name "order" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value product :placeholder "product"  :name "product" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value vendor :placeholder "vendor"  :name "vendor" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value prd-qty :placeholder "prd-qty"  :name "prd-qty" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value unit-price :placeholder "unit-price"  :name "unit-price" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value disc-rate :placeholder "disc-rate"  :name "disc-rate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value cgst :placeholder "cgst"  :name "cgst" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value sgst :placeholder "sgst"  :name "sgst" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value igst :placeholder "igst"  :name "igst" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value addl-tax1-rate :placeholder "addl-tax1-rate"  :name "addl-tax1-rate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value comments :placeholder "comments"  :name "comments" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fulfilled :placeholder "fulfilled"  :name "fulfilled" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value status :placeholder "status"  :name "status" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value deleted-state :placeholder "deleted-state"  :name "deleted-state" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value company :placeholder "company"  :name "company" ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))





(defun create-widgets-for-createOrderItems (modelfunc)
  :description "This is a create widget function for OrderItems entity"
  (funcall #'create-widgets-for-genericredirect modelfunc))




(defun create-widgets-for-searchOrderItems (modelfunc)
  :description "This is a widget function for search OrderItems entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#editOrderItems-modal" "Add OrderItems")
				   (modal-dialog "editOrderItems-modal" "Add/Edit OrderItems" (com-hhub-transaction-create-OrderItems-dialog)))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))



 
(defun display-OrderItems-row (OrderItems)
  :description "This function has HTML row code for OrderItems entity row"
  (with-slots (row-id order product vendor prd-qty unit-price disc-rate cgst sgst igst addl-tax1-rate comments fulfilled status deleted-state company %16% %17% %18% %19% %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37%) OrderItems 
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str row-id))
      (:td  :height "10px" (cl-who:str order))
      (:td  :height "10px" (cl-who:str product))
      (:td  :height "10px" (cl-who:str vendor))
      (:td  :height "10px" (cl-who:str prd-qty))
      (:td  :height "10px" (cl-who:str unit-price))
      (:td  :height "10px" (cl-who:str disc-rate))
      (:td  :height "10px" (cl-who:str cgst))
      (:td  :height "10px" (cl-who:str sgst))
      (:td  :height "10px" (cl-who:str igst))
      (:td  :height "10px" (cl-who:str addl-tax1-rate))
      (:td  :height "10px" (cl-who:str comments))
      (:td  :height "10px" (cl-who:str fulfilled))
      (:td  :height "10px" (cl-who:str status))
      (:td  :height "10px" (cl-who:str deleted-state))
      (:td  :height "10px" (cl-who:str company))
      (:td  :height "10px" 
	    (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target (format nil "#editOrderItems-modal~A" row-id) (:i :class "fa-solid fa-pencil"))
	    (modal-dialog-v2 (format nil "editOrderItems-modal~A" row-id) (cl-who:str (format nil "Add/Edit OrderItems " )) (com-hhub-transaction-create-OrderItems-dialog OrderItems))
	    (modal-dialog (format nil "editOrderItems-modal~A" row-id) "Add/Edit OrderItems" (com-hhub-transaction-create-OrderItems-dialog OrderItems))))))


(defun com-hhub-transaction-update-OrderItems-action ()
  :description "This is the MVC function to update action for OrderItems entity"
  (with-cust-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-updateOrderItems #'create-widgets-for-updateOrderItems)))
      (format nil "~A" url))))


(defun com-hhub-transaction-create-OrderItems-action ()
  :description "This is a MVC function for create OrderItems entity"
  (with-cust-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-createOrderItems #'create-widgets-for-createOrderItems)))
      (format nil "~A" url))))









