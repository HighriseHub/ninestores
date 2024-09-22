;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)



(defun com-hhub-transaction-add-customer-to-invoice-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Add Customer To Invoice" createmodelforaddcusttoinvoice createwidgetsforaddcusttoinvoice :role  :vendor )))

(defun createmodelforaddcusttoinvoice()
  (let* ((vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (wallets (get-cust-wallets-for-vendor vendor company))
	 (mycustomers (remove nil (mapcar (lambda (wallet)
					    (let* ((customer (slot-value wallet 'customer))
						   (cust-type (slot-value customer 'cust-type)))
					      (when (equal cust-type "STANDARD") customer))) wallets))))
    (function (lambda ()
      (values mycustomers)))))

(defun createwidgetsforaddcusttoinvoice (modelfunc)
  (multiple-value-bind (mycustomers) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-vendor-breadcrumb
			  (:li :class "breadcrumb-item" (:a :href "displayinvoices" "Invoices")))
			(:span "Create Invoice - Step 1: ")
			(:h2 "Select Customer")))))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-search-form "idsearchmycustomer" "searchmycustomer" "idtxtsearchcustomer" "txtsearchcustomer" "hhubsearchmycustomer" "onkeyupsearchform1event();" "Customer Name"
			  (submitsearchform1event-js "#idtxtsearchcustomer" "#vendormycustomerssearchresult" ))
			(:div :id "vendormycustomerssearchresult"  :class "container"
			      (cl-who:str (display-as-table (list "Name" "Phone" "Action") mycustomers 'display-add-customer-to-invoice-row))))))))
      (list widget1 widget2))))

(defun display-add-customer-to-invoice-row (customer)
  (let* ((cust-id (slot-value customer 'row-id))
	 (cust-phone (slot-value customer 'phone))
	 (cust-name (slot-value customer 'name)))
    (with-slots (name phone address) customer
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str cust-name))
	(:td  :height "10px" (cl-who:str cust-phone))
	(:td  :height "10px"
	      (with-html-form (format nil "invoicecreateforcust~A" cust-id) "editinvoicepage"
		(with-html-input-text-hidden "mode" "create")
		(with-html-input-text-hidden "custid" cust-id)
		(:div :class "form-group"
			  (:button :class "btn btn-sm btn-primary" :type "submit" (:i :class "fa-solid fa-user-plus" :aria-hidden "true") "&nbsp;Create Invoice&nbsp;"))))))))
	  ;;    (:a :href (format nil "/hhub/editinvoicepage?mode=create&custid=~A" cust-id) :alt "Select Customer" (:i :class "fa-solid fa-user-plus" :aria-hidden "true")))))))

	   ;;   (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target (format nil "#editInvoiceHeader-modal~A" (subseq invnum 0 8)) (:i :class "fa-solid fa-pencil"))
	   ;;   (modal-dialog (format nil "editInvoiceHeader-modal~A" (subseq invnum 0 8))  "Add/Edit InvoiceHeader" (com-hhub-transaction-create-InvoiceHeader-dialog viewmodel)))))))))))


(defun InvoiceHeader-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchInvoiceHeader" "syssearchInvoiceHeader" "idInvoiceHeaderlivesearch" "InvoiceHeaderlivesearch" "searchinvoicesaction" "onkeyupsearchform1event();" "Search for an Invoice"
			(submitsearchform1event-js "#idInvoiceHeaderlivesearch" "#InvoiceHeaderlivesearchresult")))))))

(defun com-hhub-transaction-show-invoices-page ()
  :description "This is a show list page for all the InvoiceHeader entities"
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "InvoiceHeader" createmodelforshowInvoiceHeader createwidgetsforshowInvoiceHeader :role  :vendor )))

(defun createmodelforshowInvoiceHeader ()
  :description "This is a model function which will create a model to show InvoiceHeader entities"
  (let* ((company (get-login-vendor-company))
	 (presenterobj (make-instance 'InvoiceHeaderPresenter))
	 (requestmodelobj (make-instance 'InvoiceHeaderRequestModel
					 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceHeaderHTMLView))
	 (params nil))

    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-show-invoices-page" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))

(defun createwidgetsforshowInvoiceHeader (modelfunc)
 :description "This is the view/widget function for show InvoiceHeader entities" 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-vendor-breadcrumb)
		       (InvoiceHeader-search-html)
			 (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for InvoiceHeader."))
		       (:div :id "InvoiceHeaderlivesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:a :href "/hhub/addcusttoinvoice" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
	  (widget3 (function (lambda ()
		     (submitformevent-js "#InvoiceHeaderlivesearchresult")))))
      (list widget1 widget2 widget3))))

(defun createwidgetsforupdateInvoiceHeader (modelfunc)
:description "This is a widgets function for update InvoiceHeader entity"      
  (createwidgetsforgenericredirect modelfunc))


(defmethod RenderListViewHTML ((htmlview InvoiceHeaderHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for InvoiceHeader entities, which will display each InvoiceHeader entity in a row"
  (when viewmodellist
    (display-as-table (list "Invoice Number" "Date" "Customer Name" "Total Value") viewmodellist 'display-InvoiceHeader-row)))

(defun createmodelforsearchInvoiceHeader ()
  :description "This is a model function for search InvoiceHeader entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "InvoiceHeaderlivesearch"))
	 (company (get-login-vendor-company))
	 (presenterobj (make-instance 'InvoiceHeaderPresenter))
	 (requestmodelobj (make-instance 'InvoiceHeaderSearchRequestModel
						 :invnum search-clause
						 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (domainobjlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceHeaderHTMLView))
	 (params nil))

    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-invoice-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))

(defun createwidgetsforsearchInvoiceHeader (modelfunc)
  :description "This is a widget function for search InvoiceHeader entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:a :href "/hhub/addcusttoinvoice" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
      (list widget1))))

(defun com-hhub-transaction-search-invoice-action ()
  :description "This is a MVC function to search action for InvoiceHeader entities/entity" 
  (let* ((modelfunc (createmodelforsearchInvoiceHeader))
	 (widgets (createwidgetsforsearchInvoiceHeader modelfunc)))
    (display-search-results-with-widgets widgets)))

(defun createmodelforupdateInvoiceHeader ()
  :description "This is a model function for update InvoiceHeader entity"
  (let* ((invnum (hunchentoot:parameter "invnum"))
	 (invdate (get-date-from-string (hunchentoot:parameter "invdate")))
	 (custid (hunchentoot:parameter "custid"))
	 (custname (hunchentoot:parameter "custname"))
	 (custaddr (hunchentoot:parameter "custaddr"))
	 (custgstin (hunchentoot:parameter "custgstin"))
	 (statecode (hunchentoot:parameter "statecode"))
	 (billaddr (hunchentoot:parameter "billaddr"))
	 (shipaddr (hunchentoot:parameter "shipaddr"))
	 (placeofsupply (hunchentoot:parameter "placeofsupply"))
	 (revcharge (hunchentoot:parameter "revcharge"))
	 (transmode (hunchentoot:parameter "transmode"))
	 (vnum (hunchentoot:parameter "vnum"))
	 (totalvalue (float (with-input-from-string (in (hunchentoot:parameter "totalvalue"))
		     (read in))))
	 (totalinwords (hunchentoot:parameter "totalinwords"))
	 (bankaccnum (hunchentoot:parameter "bankaccnum"))
	 (bankifsccode (hunchentoot:parameter "bankifsccode"))
	 (tnc (hunchentoot:parameter "tnc"))
	 (authsign (hunchentoot:parameter "authsign"))
	 (finyear (hunchentoot:parameter "finyear"))
	 (company (get-login-vendor-company)) ;; or get ABAC subject specific login company function. 
	 (customer (select-customer-by-id custid company))
	 (vendor (get-login-vendor))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
					 :invnum invnum
					 :invdate invdate
					 :customer customer
					 :custid custid
					 :custname custname
					 :custaddr custaddr
					 :custgstin custgstin
					 :statecode statecode
					 :billaddr billaddr
					 :shipaddr shipaddr
					 :placeofsupply placeofsupply
					 :revcharge revcharge
					 :transmode transmode
					 :vnum vnum
					 :totalvalue totalvalue
					 :totalinwords totalinwords
					 :bankaccnum bankaccnum
					 :bankifsccode bankifsccode
					 :tnc tnc
					 :authsign authsign
					 :finyear finyear
					 :vendor vendor
					 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (redirectlocation  "/hhub/displayinvoices")
	 (params nil))
    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-invoice-action" params 
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (function (lambda ()
	      (values redirectlocation domainobj))))

	(error (c)
	  (let ((exceptionstr (format nil  "Business Error:~A: ~a~%" (mysql-now) (getexceptionstr c))))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-business-function-error :errstring exceptionstr)))))))
	
		 

(defun com-hhub-transaction-create-invoice-action()
  :description "This is a MVC function for create InvoiceHeader entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforcreateInvoiceHeader createwidgetsforcreateInvoiceHeader)))
      (format nil "~A" url))))

(defun createwidgetsforcreateInvoiceHeader (modelfunc)
  :description "This is a create widget function for InvoiceHeader entity"
  (createwidgetsforgenericredirect modelfunc))

(defun createmodelforcreateInvoiceHeader ()
  :description "This is a create model function for creating a InvoiceHeader entity"
  (let* ((invdate (get-date-from-string (hunchentoot:parameter "invdate")))
	 (company (get-login-vendor-company))
	 (custid (hunchentoot:parameter "custid"))
	 (customer (select-customer-by-id custid company))
	 (custaddr (hunchentoot:parameter "custaddr"))
	 (custgstin (hunchentoot:parameter "custgstin"))
	 (statecode (hunchentoot:parameter "statecode"))
	 (billaddr (hunchentoot:parameter "billaddr"))
	 (shipaddr (hunchentoot:parameter "shipaddr"))
	 (placeofsupply (hunchentoot:parameter "placeofsupply"))
	 (revcharge (hunchentoot:parameter "revcharge"))
	 (transmode (hunchentoot:parameter "transmode"))
	 (vnum (hunchentoot:parameter "vnum"))
	 (totalvalue (float (with-input-from-string (in (hunchentoot:parameter "totalvalue"))
		     (read in))))
	 (totalinwords (hunchentoot:parameter "totalinwords"))
	 (bankaccnum (hunchentoot:parameter "bankaccnum"))
	 (bankifsccode (hunchentoot:parameter "bankifsccode"))
	 (tnc (hunchentoot:parameter "tnc"))
	 (authsign (hunchentoot:parameter "authsign"))
	 (finyear (hunchentoot:parameter "finyear"))
	 (company (get-login-vendor-company)) ;; or get ABAC subject specific login company function.
	 (vendor (get-login-vendor))
	 (vname (get-login-vendor-name))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
				      :invnum "000"
				      :invdate invdate
				      :customer customer
				      :vendor vendor
				      :custaddr custaddr
				      :custgstin custgstin
				      :statecode statecode
				      :billaddr billaddr
				      :shipaddr shipaddr
				      :placeofsupply placeofsupply
				      :revcharge revcharge
				      :transmode transmode
				      :vnum vnum
				      :totalvalue totalvalue
				      :totalinwords totalinwords
				      :bankaccnum bankaccnum
				      :bankifsccode bankifsccode
				      :tnc tnc
				      :authsign (if authsign authsign vname)
				      :finyear finyear
				      :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (redirectlocation  "/hhub/displayinvoices")
	 (params nil))
    (setf params (acons "company" company params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-invoice-action" params 
      (handler-case 
	  (let ((domainobj (ProcessCreateRequest adapterobj requestmodel)))
	    (function (lambda ()
	      (values redirectlocation domainobj))))

	(error (c)
	  (let ((exceptionstr (format nil  "Business Error:~A: ~a~%" (mysql-now) (getExceptionStr c))))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-business-function-error :errstring exceptionstr)))))))

(defun com-hhub-transaction-create-InvoiceHeader-dialog (&optional domainobj)
  :description "This function creates a dialog to create InvoiceHeader entity"
  (let* ((invnum  (if domainobj (slot-value domainobj 'invnum)))
	 (invdate  (if domainobj (get-date-string (slot-value domainobj 'invdate))))
	 (custaddr  (if domainobj (slot-value domainobj 'custaddr)))
	 (custgstin  (if domainobj (slot-value domainobj 'custgstin)))
	 (statecode  (if domainobj (slot-value domainobj 'statecode)))
	 (billaddr  (if domainobj (slot-value domainobj 'billaddr)))
	 (shipaddr  (if domainobj (slot-value domainobj 'shipaddr)))
	 (placeofsupply  (if domainobj (slot-value domainobj 'placeofsupply)))
	 (revcharge  (if domainobj (slot-value domainobj 'revcharge)))
	 (transmode  (if domainobj (slot-value domainobj 'transmode)))
	 (vnum  (if domainobj (slot-value domainobj 'vnum)))
	 (totalvalue  (if domainobj (slot-value domainobj 'totalvalue)))
	 (totalinwords  (if domainobj (slot-value domainobj 'totalinwords)))
	 (bankaccnum  (if domainobj (slot-value domainobj 'bankaccnum)))
	 (bankifsccode  (if domainobj (slot-value domainobj 'bankifsccode)))
	 (tnc  (if domainobj (slot-value domainobj 'tnc)))
	 (authsign  (if domainobj (slot-value domainobj 'authsign))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addInvoiceHeader~A" invnum)  (if domainobj "updateinvoiceaction" "createinvoiceaction")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "invnum" :maxlength "20"  :value  invnum :placeholder "Invoice Number (max 20 characters) " :type "text" :readonly t))
		    
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value invdate :placeholder "invdate"  :name "invdate" ))
		    
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value custaddr :placeholder "custaddr"  :name "custaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value custgstin :placeholder "custgstin"  :name "custgstin" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value statecode :placeholder "statecode"  :name "statecode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value billaddr :placeholder "billaddr"  :name "billaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value shipaddr :placeholder "shipaddr"  :name "shipaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value placeofsupply :placeholder "placeofsupply"  :name "placeofsupply" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value revcharge :placeholder "revcharge"  :name "revcharge" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value transmode :placeholder "transmode"  :name "transmode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value vnum :placeholder "vnum"  :name "vnum" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value totalvalue :placeholder "totalvalue"  :name "totalvalue" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value totalinwords :placeholder "totalinwords"  :name "totalinwords" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value bankaccnum :placeholder "bankaccnum"  :name "bankaccnum" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value bankifsccode :placeholder "bankifsccode"  :name "bankifsccode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value tnc :placeholder "tnc"  :name "tnc" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value authsign :placeholder "authsign"  :name "authsign" ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))



 
(defun display-InvoiceHeader-row (viewmodel)
  :description "This function has HTML row code for InvoiceHeader entity row"
  (with-slots (invnum invdate customer totalvalue) viewmodel
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str  invnum))
      (:td  :height "10px" (cl-who:str (get-date-string invdate)))
      (:td  :height "10px" (cl-who:str (slot-value customer 'name)))
      (:td  :height "10px" (cl-who:str totalvalue))
      (:td  :height "10px" (:a :href (format nil "/hhub/editinvoicepage?invnum=~A" invnum) :alt "Edit Invoice" (:i :class "fa-solid fa-pencil"))))))

	


(defun com-hhub-transaction-update-invoice-action()
  :description "This is the MVC function to update action for InvoiceHeader entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforupdateInvoiceHeader createwidgetsforupdateInvoiceHeader)))
      (format nil "~A" url))))


(defun com-hhub-transaction-edit-invoice-header-page()
  :description "This is the MVC function to show invoice header page"
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Edit Invoice" createmodelforeditinvoiceheaderpage createwidgetsforeditinvoiceheaderpage :role :vendor)))



(defun createmodelforeditinvoiceheaderpage ()
  (let* ((company (get-login-vendor-company))
	 (custid (hunchentoot:parameter "custid"))
	 (inum (hunchentoot:parameter "invnum"))
	 (mode (hunchentoot:parameter "mode"))
	 (adapter (make-instance 'InvoiceHeaderAdapter))
	 (busobj (make-instance 'InvoiceHeader
				:company (get-login-vendor-company)
				:vendor (get-login-vendor)
				:customer (select-customer-by-id custid company)
				:finyear (current-year-string)
				:statecode *NSTGSTBUSINESSSTATE*
				:tnc *NSTGSTINVOICETERMS*
				:authsign (get-login-vendor-name)
				:revcharge "No"))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
				      :invnum inum
				      :company company))
	 (invoiceobj (if inum (ProcessReadRequest adapter requestmodel) busobj)))
    (with-slots (invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear customer ) invoiceobj
      (function (lambda()
	(values invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear customer  mode))))))
    

(defun createwidgetsforeditinvoiceheaderpage (modelfunc)
  (multiple-value-bind (invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear customer  mode) (funcall modelfunc)
    (let* ((widget1 (editinvoicewidget-section1 invnum invdate  custgstin statecode finyear customer))
	   (widget2 (editinvoicewidget-section2 custaddr billaddr shipaddr))
	   (widget3 (editinvoicewidget-section3 placeofsupply revcharge transmode vnum totalvalue totalinwords))
	   (widget4 (editinvoicewidget-section4 bankaccnum bankifsccode tnc authsign))
	   (widget5 (function (lambda ()
		     (submitformevent-js "#idupdateinvoiceaction"))))
	   (widget6 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-vendor-breadcrumb
			  (:li :class "breadcrumb-item" (:a :href "displayinvoices" "Invoices"))
			  (:li :class "breadcrumb-item" (:a :href "addcusttoinvoice" "Select Customer")))
			(:span "Create Invoice - Step 2: ")
			(:h2 "Fill Invoice Details For")
			(:div :id "idupdateinvoiceaction" 
			      (with-html-form (format nil "form-addInvoiceHeader~A" invnum) (if (equal mode "create") "createinvoiceaction" "updateinvoiceaction")
				(with-html-div-row
				  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
					(funcall widget1))
				  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
					(funcall widget2)))
				(with-html-div-row
				  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
					(funcall widget3))
				  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
					      (funcall widget4)))
				(funcall widget5))))))))
      (list widget6))))


(defun editinvoicewidget-section1 (invnum invdate  custgstin statecode finyear customer)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-password 3)))
	  (finyear-ht (make-hash-table)))
      (setf (gethash (current-year-string--) finyear-ht) (current-year-string--))
      (setf (gethash (current-year-string) finyear-ht) (current-year-string))
      (setf (gethash (current-year-string++) finyear-ht) (current-year-string++))
     
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (with-html-input-text-hidden "custid" (cl-who:str (slot-value customer 'row-id)))
	      (with-html-input-text-hidden "custname" (cl-who:str (slot-value customer 'name)))
	      (:h3 (:span (cl-who:str (slot-value customer 'name))))
	      (:h3 (:span (cl-who:str (slot-value customer 'phone)))))
	(:div :class "form-group"
	    (:label :for "finyear" "Financial Year")
	    (with-html-dropdown "finyear" finyear-ht finyear))
	(:div :class "form-group"
	      (:label :for "invnum" "Invoice Number")
	      (:input :class "form-control" :name "invnum" :maxlength "20"  :value  invnum :placeholder "Invoice Number (max 20 characters) " :type "text" :readonly t))
	(:div :class "form-group"
	      (:label :for "invdate" "Invoice Date")
	      (:input :class "form-control" :type "text" :value (get-date-string invdate) :placeholder "invdate"  :name "invdate" ))
	(:div :class "form-group"
	      (:label :for "custgstin" "Customer GST Number")
	      (:input :class "form-control" :type "text" :value custgstin :onkeyup (format nil "countChar(~A.id, this, 15)" charcountid1) :placeholder "Customer GST Number"  :name "custgstin" )
	      (:div :class "form-group" :id charcountid1))
	(:div :class "form-group"
	      (:label :for "statecode" "Select State")
	      (with-html-dropdown "statecode" *NSTGSTSTATECODES-HT* statecode)))))))


(defun editinvoicewidget-section2 (custaddr billaddr shipaddr)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-password 3)))
	  (charcountid2 (format nil "idchcount~A" (hhub-random-password 3)))
	  (charcountid3 (format nil "idchcount~A" (hhub-random-password 3))))
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (:label :for "custaddr" "Customer Address")
	      (:textarea :class "form-control" :name "custaddr"  :placeholder "Enter Address ( max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid1) (cl-who:str (format nil "~A" custaddr)))
	      (:div :class "form-group" :id charcountid1))
	(:div :class "form-group"
	      (:label :for "billaddr" "Billing Address")
	      (:textarea :class "form-control" :name "billaddr"  :placeholder "Enter Billing Address ( max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid2) (cl-who:str (format nil "~A" billaddr)))
	      (:div :class "form-group" :id charcountid2 ))
	(:div :class "form-group"
	      (:label :for "shipaddr" "Shipping Address")
	      (:textarea :class "form-control" :name "shipaddr"  :placeholder "Enter Shipping Address ( max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid3) (cl-who:str (format nil "~A" shipaddr)))
	      (:div :class "form-group" :id charcountid3)))))))
  

(defun editinvoicewidget-section3 ( placeofsupply revcharge transmode vnum totalvalue totalinwords)
  (function (lambda ()
    (let ((revcharge-ht (make-hash-table))
	  (transmode-ht (make-hash-table)))
      (setf (gethash "Yes" revcharge-ht) "Yes") 
      (setf (gethash "No" revcharge-ht) "No")
      (setf (gethash "NA" transmode-ht) "Not Applicable")
      (setf (gethash "Road" transmode-ht) "Road")
      (setf (gethash "Rail" transmode-ht) "Rail")
      (setf (gethash "Air" transmode-ht) "Air")
      (setf (gethash "Ship/Waterways" transmode-ht) "Ship/Waterways")
      
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (:label :for "placeofsupply" "Place Of Supply")
	      (:input :class "form-control" :type "text" :value placeofsupply :placeholder "placeofsupply"  :name "placeofsupply" ))
	(:div :class "form-group"
	      (:label :for "revcharge" "Reverse Charge")
	      (with-html-dropdown "revcharge" revcharge-ht revcharge))
	(:div :class "form-group"
	      (:label :for "transmode" "Transport Mode")
	      (with-html-dropdown "transmode" transmode-ht transmode))
	(:div :class "form-group"
	      (:label :for "vnum" "Vehicle Number")
	      (:input :class "form-control" :type "text" :value vnum :placeholder "Vehicle Number"  :name "vnum" ))
	(:div :class "form-group" :style "display:none;"
	      (:label :for "totalvalue" "Total Value")
	      (:input :class "form-control" :type "text" :value totalvalue :placeholder "Total Value"  :name "totalvalue" ))
	(:div :class "form-group" :style "display:none;"
	      (:label :for "totalinwords" "Total In Words")
	      (:input :class "form-control" :type "text" :value totalinwords :placeholder "Total In Words"  :name "totalinwords" )))))))

(defun editinvoicewidget-section4 (bankaccnum bankifsccode tnc authsign)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-password 3))))
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (:label :for "bankaccnum" "Bank Account Number")
	      (:input :class "form-control" :type "text" :value bankaccnum :placeholder "bankaccnum"  :name "bankaccnum" ))
	(:div :class "form-group"
	      (:label :for "bankifsccode" "Bank IFSC Code")
	      (:input :class "form-control" :type "text" :value bankifsccode :placeholder "bankifsccode"  :name "bankifsccode" ))
	(:div :class "form-group"
	      (:label :for "tnc" "Invoice Terms")
	      (:textarea :class "form-control" :name "tnc"  :placeholder "Enter Invoice Terms (Max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 1000)" charcountid1) (cl-who:str (format nil "~A" tnc)))
	      (:div :class "form-group" :id charcountid1 ))
        (:div :class "form-group"
	    (:label :for "invnum" "Authorised Signatory")
	    (:input :class "form-control" :type "text" :value authsign :placeholder "authsign"  :name "authsign" ))
      
	(:div :class "form-group"
	    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))))
