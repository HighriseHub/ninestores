;; -*- mode: common-lisp; coding: utf-8 -*
(in-package :nstores)

(defun order-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchorder" "syssearchorder" "idorderlivesearch" "orderlivesearch" "searchorderaction" "onkeyupsearchform1event();" "Search for an order"
			(submitsearchform1event-js "#idorderlivesearch" "#orderlivesearchresult")))))))

(defun com-hhub-transaction-show-order-page ()
  :description "This is a show list page for all the order entities"
  (with-cust-session-check ;; delete if not needed. 
    (with-mvc-ui-page "order" #'create-model-for-showorder #'create-widgets-for-showorder :role :customer))) ;; keep only one role, delete reset. 

(defun create-model-for-showorder ()
  :description "This is a model function which will create a model to show order entities"
  (let* ((company (get-login-company))
	 (username (get-login-user-name))
	 (presenterobj (make-instance 'orderPresenter))
	 (requestmodelobj (make-instance 'orderRequestModel
					 :company company))
	 (adapterobj (make-instance 'orderAdapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'orderHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-order-page" params 
      (function (lambda ()
	(values viewallmodel htmlview username))))))

(defun create-widgets-for-showorder (modelfunc)
 :description "This is the view/widget function for show order entities" 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-vendor-breadcrumb)
		       (order-search-html)
			 (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for order."))
		       (:div :id "orderlivesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:a :href "/hhub/addorder" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create order"))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
	  (widget3 (function (lambda ()
		     (submitformevent-js "#orderlivesearchresult")))))
      (list widget1 widget2 widget3))))

(defun create-widgets-for-updateorder (modelfunc)
:description "This is a widgets function for update order entity"      
  (funcall #'create-widgets-for-genericredirect modelfunc))

(defmethod RenderListViewHTML ((htmlview orderHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for order entities, which will display each order entity in a row"
  (when viewmodellist
    (display-as-table (list "row-id" "ord-date" "req-date" "shipped-date" "expected-delivery-date" "ordnum" "shipaddr" "shipzipcode" "shipcity" "shipstate" "billaddr" "billzipcode" "billcity" "billstate" "billsameasship" "storepickupenabled" "gstnumber" "gstorgname" "order-fulfilled" "order-amt" "shipping-cost" "total-discount" "total-tax" "payment-mode" "comments" "context-id" "customer" "status" "deleted-state" "is-converted-to-invoice" "is-cancelled" "cancel-reason" "order-type" "external-url" "order-source" "custname" "company" "{37}") viewmodellist 'display-order-row)))

(defun create-model-for-searchorder ()
  :description "This is a model function for search order entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "orderlivesearch"))
	 (company (get-login-company))
	 (presenterobj (make-instance 'orderPresenter))
	 (requestmodelobj (make-instance 'orderSearchRequestModel
						 :field1 search-clause
						 :company company))
	 (adapterobj (make-instance 'orderAdapter))
	 (domainobjlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'orderHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-order-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))



(defun com-hhub-transaction-search-order-action ()
  :description "This is a MVC function to search action for order entities/entity" 
  (let* ((modelfunc (funcall #'create-model-for-searchorder))
	 (widgets (funcall #'create-widgets-for-searchorder modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
	(cl-who:str (funcall widget))))))

(defun create-model-for-updateorder ()
  :description "This is a model function for update order entity"
  (let* ((row-id (hunchentoot:parameter "row-id"))
	 (ord-date (hunchentoot:parameter "ord-date"))
	 (req-date (hunchentoot:parameter "req-date"))
	 (shipped-date (hunchentoot:parameter "shipped-date"))
	 (expected-delivery-date (hunchentoot:parameter "expected-delivery-date"))
	 (ordnum (hunchentoot:parameter "ordnum"))
	 (shipaddr (hunchentoot:parameter "shipaddr"))
	 (shipzipcode (hunchentoot:parameter "shipzipcode"))
	 (shipcity (hunchentoot:parameter "shipcity"))
	 (shipstate (hunchentoot:parameter "shipstate"))
	 (billaddr (hunchentoot:parameter "billaddr"))
	 (billzipcode (hunchentoot:parameter "billzipcode"))
	 (billcity (hunchentoot:parameter "billcity"))
	 (billstate (hunchentoot:parameter "billstate"))
	 (billsameasship (hunchentoot:parameter "billsameasship"))
	 (storepickupenabled (hunchentoot:parameter "storepickupenabled"))
	 (gstnumber (hunchentoot:parameter "gstnumber"))
	 (gstorgname (hunchentoot:parameter "gstorgname"))
	 (order-fulfilled (hunchentoot:parameter "order-fulfilled"))
	 (order-amt (hunchentoot:parameter "order-amt"))
	 (shipping-cost (hunchentoot:parameter "shipping-cost"))
	 (total-discount (hunchentoot:parameter "total-discount"))
	 (total-tax (hunchentoot:parameter "total-tax"))
	 (payment-mode (hunchentoot:parameter "payment-mode"))
	 (comments (hunchentoot:parameter "comments"))
	 (context-id (hunchentoot:parameter "context-id"))
	 (customer (hunchentoot:parameter "customer"))
	 (status (hunchentoot:parameter "status"))
	 (deleted-state (hunchentoot:parameter "deleted-state"))
	 (is-converted-to-invoice (hunchentoot:parameter "is-converted-to-invoice"))
	 (is-cancelled (hunchentoot:parameter "is-cancelled"))
	 (cancel-reason (hunchentoot:parameter "cancel-reason"))
	 (order-type (hunchentoot:parameter "order-type"))
	 (external-url (hunchentoot:parameter "external-url"))
	 (order-source (hunchentoot:parameter "order-source"))
         (custname (hunchentoot:parameter "custname"))
	 (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance 'orderRequestModel
				      :row-id row-id
				      :ord-date ord-date
				      :req-date req-date
				      :shipped-date shipped-date
				      :expected-delivery-date expected-delivery-date
				      :ordnum ordnum
				      :shipaddr shipaddr
				      :shipzipcode shipzipcode
				      :shipcity shipcity
				      :shipstate shipstate
				      :billaddr billaddr
				      :billzipcode billzipcode
				      :billcity billcity
				      :billstate billstate
				      :billsameasship billsameasship
				      :storepickupenabled storepickupenabled
				      :gstnumber gstnumber
				      :gstorgname gstorgname
				      :order-fulfilled order-fulfilled
				      :order-amt order-amt
				      :shipping-cost shipping-cost
				      :total-discount total-discount
				      :total-tax total-tax
				      :payment-mode payment-mode
				      :comments comments
				      :context-id context-id
				      :customer customer
				      :status status
				      :deleted-state deleted-state
				      :is-converted-to-invoice is-converted-to-invoice
				      :is-cancelled is-cancelled
				      :cancel-reason cancel-reason
				      :order-type order-type
				      :external-url external-url
				      :order-source order-source
				      :custname custname
				      :company company))
	 (adapterobj (make-instance 'orderAdapter))
	 (redirectlocation  "/hhub/order")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-order-action" params 
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))

(defun create-model-for-createorder ()
  :description "This is a create model function for creating a order entity"
  (let* ((row-id (hunchentoot:parameter "row-id"))
	 (ord-date (hunchentoot:parameter "ord-date"))
	 (req-date (hunchentoot:parameter "req-date"))
	 (shipped-date (hunchentoot:parameter "shipped-date"))
	 (expected-delivery-date (hunchentoot:parameter "expected-delivery-date"))
	 (ordnum (hunchentoot:parameter "ordnum"))
	 (shipaddr (hunchentoot:parameter "shipaddr"))
	 (shipzipcode (hunchentoot:parameter "shipzipcode"))
	 (shipcity (hunchentoot:parameter "shipcity"))
	 (shipstate (hunchentoot:parameter "shipstate"))
	 (billaddr (hunchentoot:parameter "billaddr"))
	 (billzipcode (hunchentoot:parameter "billzipcode"))
	 (billcity (hunchentoot:parameter "billcity"))
	 (billstate (hunchentoot:parameter "billstate"))
	 (billsameasship (hunchentoot:parameter "billsameasship"))
	 (storepickupenabled (hunchentoot:parameter "storepickupenabled"))
	 (gstnumber (hunchentoot:parameter "gstnumber"))
	 (gstorgname (hunchentoot:parameter "gstorgname"))
	 (order-fulfilled (hunchentoot:parameter "order-fulfilled"))
	 (order-amt (hunchentoot:parameter "order-amt"))
	 (shipping-cost (hunchentoot:parameter "shipping-cost"))
	 (total-discount (hunchentoot:parameter "total-discount"))
	 (total-tax (hunchentoot:parameter "total-tax"))
	 (payment-mode (hunchentoot:parameter "payment-mode"))
	 (comments (hunchentoot:parameter "comments"))
	 (context-id (hunchentoot:parameter "context-id"))
	 (customer (hunchentoot:parameter "customer"))
	 (status (hunchentoot:parameter "status"))
	 (deleted-state (hunchentoot:parameter "deleted-state"))
	 (is-converted-to-invoice (hunchentoot:parameter "is-converted-to-invoice"))
	 (is-cancelled (hunchentoot:parameter "is-cancelled"))
	 (cancel-reason (hunchentoot:parameter "cancel-reason"))
	 (order-type (hunchentoot:parameter "order-type"))
	 (external-url (hunchentoot:parameter "external-url"))
	 (order-source (hunchentoot:parameter "order-source"))
	 (custname (hunchentoot:parameter "custname"))
	 (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance 'orderRequestModel
					 :row-id row-id
					 :ord-date ord-date
					 :req-date req-date
					 :shipped-date shipped-date
					 :expected-delivery-date expected-delivery-date
					 :ordnum ordnum
					 :shipaddr shipaddr
					 :shipzipcode shipzipcode
					 :shipcity shipcity
					 :shipstate shipstate
					 :billaddr billaddr
					 :billzipcode billzipcode
					 :billcity billcity
					 :billstate billstate
					 :billsameasship billsameasship
					 :storepickupenabled storepickupenabled
					 :gstnumber gstnumber
					 :gstorgname gstorgname
					 :order-fulfilled order-fulfilled
					 :order-amt order-amt
					 :shipping-cost shipping-cost
					 :total-discount total-discount
					 :total-tax total-tax
					 :payment-mode payment-mode
					 :comments comments
					 :context-id context-id
					 :customer customer
					 :status status
					 :deleted-state deleted-state
					 :is-converted-to-invoice is-converted-to-invoice
					 :is-cancelled is-cancelled
					 :cancel-reason cancel-reason
					 :order-type order-type
					 :external-url external-url
					 :order-source order-source
					 :custname custname
					 :company company))
	 (adapterobj (make-instance 'orderAdapter))
	 (redirectlocation  "/hhub/order")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-order-action" params 
      (handler-case 
	  (let ((domainobj (ProcessCreateRequest adapterobj requestmodel)))
	    ;; Create the GST HSN Code object if not present. 
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))

(defun com-hhub-transaction-create-order-dialog (&optional domainobj)
  :description "This function creates a dialog to create order entity"
  (let* ((row-id  (if domainobj (slot-value domainobj 'row-id)))
	 (ord-date  (if domainobj (slot-value domainobj 'ord-date)))
	 (req-date  (if domainobj (slot-value domainobj 'req-date)))
	 (shipped-date  (if domainobj (slot-value domainobj 'shipped-date)))
	 (expected-delivery-date  (if domainobj (slot-value domainobj 'expected-delivery-date)))
	 (ordnum  (if domainobj (slot-value domainobj 'ordnum)))
	 (shipaddr  (if domainobj (slot-value domainobj 'shipaddr)))
	 (shipzipcode  (if domainobj (slot-value domainobj 'shipzipcode)))
	 (shipcity  (if domainobj (slot-value domainobj 'shipcity)))
	 (shipstate  (if domainobj (slot-value domainobj 'shipstate)))
	 (billaddr  (if domainobj (slot-value domainobj 'billaddr)))
	 (billzipcode  (if domainobj (slot-value domainobj 'billzipcode)))
	 (billcity  (if domainobj (slot-value domainobj 'billcity)))
	 (billstate  (if domainobj (slot-value domainobj 'billstate)))
	 (billsameasship  (if domainobj (slot-value domainobj 'billsameasship)))
	 (storepickupenabled  (if domainobj (slot-value domainobj 'storepickupenabled)))
	 (gstnumber  (if domainobj (slot-value domainobj 'gstnumber)))
	 (gstorgname  (if domainobj (slot-value domainobj 'gstorgname)))
	 (order-fulfilled  (if domainobj (slot-value domainobj 'order-fulfilled)))
	 (order-amt  (if domainobj (slot-value domainobj 'order-amt)))
	 (shipping-cost  (if domainobj (slot-value domainobj 'shipping-cost)))
	 (total-discount  (if domainobj (slot-value domainobj 'total-discount)))
	 (total-tax  (if domainobj (slot-value domainobj 'total-tax)))
	 (payment-mode  (if domainobj (slot-value domainobj 'payment-mode)))
	 (comments  (if domainobj (slot-value domainobj 'comments)))
	 (context-id  (if domainobj (slot-value domainobj 'context-id)))
	 (customer  (if domainobj (slot-value domainobj 'customer)))
	 (status  (if domainobj (slot-value domainobj 'status)))
	 (deleted-state  (if domainobj (slot-value domainobj 'deleted-state)))
	 (is-converted-to-invoice  (if domainobj (slot-value domainobj 'is-converted-to-invoice)))
	 (is-cancelled  (if domainobj (slot-value domainobj 'is-cancelled)))
	 (cancel-reason  (if domainobj (slot-value domainobj 'cancel-reason)))
	 (order-type  (if domainobj (slot-value domainobj 'order-type)))
	 (order-source  (if domainobj (slot-value domainobj 'order-source)))
	 (custname  (if domainobj (slot-value domainobj 'custname)))
	 (company  (if domainobj (slot-value domainobj 'company))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addorder~A" row-id)  (if domainobj "updateorderaction" "createorderaction")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "row-id" :maxlength "20"  :value  row-id :placeholder "order (max 20 characters) " :type "text" ))
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value ord-date :placeholder "ord-date"  :name "ord-date" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value req-date :placeholder "req-date"  :name "req-date" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value shipped-date :placeholder "shipped-date"  :name "shipped-date" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value expected-delivery-date :placeholder "expected-delivery-date"  :name "expected-delivery-date" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value ordnum :placeholder "ordnum"  :name "ordnum" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value shipaddr :placeholder "shipaddr"  :name "shipaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value shipzipcode :placeholder "shipzipcode"  :name "shipzipcode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value shipcity :placeholder "shipcity"  :name "shipcity" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value shipstate :placeholder "shipstate"  :name "shipstate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value billaddr :placeholder "billaddr"  :name "billaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value billzipcode :placeholder "billzipcode"  :name "billzipcode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value billcity :placeholder "billcity"  :name "billcity" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value billstate :placeholder "billstate"  :name "billstate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value billsameasship :placeholder "billsameasship"  :name "billsameasship" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value storepickupenabled :placeholder "storepickupenabled"  :name "storepickupenabled" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value gstnumber :placeholder "gstnumber"  :name "gstnumber" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value gstorgname :placeholder "gstorgname"  :name "gstorgname" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value order-fulfilled :placeholder "order-fulfilled"  :name "order-fulfilled" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value order-fulfilled :placeholder "order-fulfilled"  :name "order-fulfilled" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value order-amt :placeholder "order-amt"  :name "order-amt" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value shipping-cost :placeholder "shipping-cost"  :name "shipping-cost" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value total-discount :placeholder "total-discount"  :name "total-discount" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value total-tax :placeholder "total-tax"  :name "total-tax" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value payment-mode :placeholder "payment-mode"  :name "payment-mode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value comments :placeholder "comments"  :name "comments" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value context-id :placeholder "context-id"  :name "context-id" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value customer :placeholder "customer"  :name "customer" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value status :placeholder "status"  :name "status" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value deleted-state :placeholder "deleted-state"  :name "deleted-state" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value is-converted-to-invoice :placeholder "is-converted-to-invoice"  :name "is-converted-to-invoice" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value is-cancelled :placeholder "is-cancelled"  :name "is-cancelled" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value cancel-reason :placeholder "cancel-reason"  :name "cancel-reason" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value order-type :placeholder "order-type"  :name "order-type" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value cancel-reason :placeholder "external-url"  :name "external-url" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value order-source :placeholder "order-source"  :name "order-source" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value custname :placeholder "custname"  :name "custname" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value company :placeholder "company"  :name "company" ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))

(defun create-widgets-for-createorder (modelfunc)
  :description "This is a create widget function for order entity"
  (funcall #'create-widgets-for-genericredirect modelfunc))

(defun create-widgets-for-searchorder (modelfunc)
  :description "This is a widget function for search order entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#editorder-modal" "Add order")
				   (modal-dialog "editorder-modal" "Add/Edit order" (com-hhub-transaction-create-order-dialog)))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))
 
(defun display-order-row (order)
  :description "This function has HTML row code for order entity row"
  (with-slots (row-id ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id customer status deleted-state is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname company) order 
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str row-id))
      (:td  :height "10px" (cl-who:str ord-date))
      (:td  :height "10px" (cl-who:str req-date))
      (:td  :height "10px" (cl-who:str shipped-date))
      (:td  :height "10px" (cl-who:str expected-delivery-date))
      (:td  :height "10px" (cl-who:str ordnum))
      (:td  :height "10px" (cl-who:str shipaddr))
      (:td  :height "10px" (cl-who:str shipzipcode))
      (:td  :height "10px" (cl-who:str shipcity))
      (:td  :height "10px" (cl-who:str shipstate))
      (:td  :height "10px" (cl-who:str billaddr))
      (:td  :height "10px" (cl-who:str billzipcode))
      (:td  :height "10px" (cl-who:str billcity))
      (:td  :height "10px" (cl-who:str billstate))
      (:td  :height "10px" (cl-who:str billsameasship))
      (:td  :height "10px" (cl-who:str storepickupenabled))
      (:td  :height "10px" (cl-who:str gstnumber))
      (:td  :height "10px" (cl-who:str gstorgname))
      (:td  :height "10px" (cl-who:str order-fulfilled))
      (:td  :height "10px" (cl-who:str order-amt))
      (:td  :height "10px" (cl-who:str shipping-cost))
      (:td  :height "10px" (cl-who:str total-discount))
      (:td  :height "10px" (cl-who:str total-tax))
      (:td  :height "10px" (cl-who:str payment-mode))
      (:td  :height "10px" (cl-who:str comments))
      (:td  :height "10px" (cl-who:str context-id))
      (:td  :height "10px" (cl-who:str customer))
      (:td  :height "10px" (cl-who:str status))
      (:td  :height "10px" (cl-who:str deleted-state))
      (:td  :height "10px" (cl-who:str is-converted-to-invoice))
      (:td  :height "10px" (cl-who:str is-cancelled))
      (:td  :height "10px" (cl-who:str cancel-reason))
      (:td  :height "10px" (cl-who:str order-type))
      (:td  :height "10px" (cl-who:str external-url))
      (:td  :height "10px" (cl-who:str order-source))
      (:td  :height "10px" (cl-who:str custname))
      (:td  :height "10px" (cl-who:str company))
      (:td  :height "10px" 
	    (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target (format nil "#editorder-modal~A" row-id) (:i :class "fa-solid fa-pencil"))
	    (modal-dialog-v2 (format nil "editorder-modal~A" row-id) (cl-who:str (format nil "Add/Edit order " )) (com-hhub-transaction-create-order-dialog order))))))


(defun com-hhub-transaction-update-order-action ()
  :description "This is the MVC function to update action for order entity"
  (with-cust-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-updateorder #'create-widgets-for-updateorder)))
      (format nil "~A" url))))


(defun com-hhub-transaction-create-order-action ()
:description "This is a MVC function for create order entity"
  (with-cust-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-createorder #'create-widgets-for-createorder)))
      (format nil "~A" url))))








 
