  ;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defun InvoiceItem-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchInvoiceItem" "syssearchInvoiceItem" "idInvoiceItemlivesearch" "InvoiceItemlivesearch" "searchInvoiceItemaction" "onkeyupsearchform1event();" "Search for an InvoiceItem"
			(submitsearchform1event-js "#idInvoiceItemlivesearch" "#InvoiceItemlivesearchresult")))))))

(defun com-hhub-transaction-show-InvoiceItem-page ()
  :description "This is a show list page for all the InvoiceItem entities"
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "InvoiceItem" createmodelforshowInvoiceItem createwidgetsforshowInvoiceItem :role :vendor))) ;; keep only one role, delete reset. 

(defun createmodelforshowInvoiceItem ()
  :description "This is a model function which will create a model to show InvoiceItem entities"
  (let* ((company (get-login-company))
	 (username (get-login-user-name))
	 (presenterobj (make-instance 'InvoiceItemPresenter))
	 (requestmodelobj (make-instance 'InvoiceItemRequestModel
					 :company company))
	 (adapterobj (make-instance 'InvoiceItemAdapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceItemHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-InvoiceItem-page" params 
      (function (lambda ()
	(values viewallmodel htmlview username))))))

(defun createwidgetsforshowInvoiceItem (modelfunc)
 :description "This is the view/widget function for show InvoiceItem entities" 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-vendor-breadcrumb)
		       (InvoiceItem-search-html)
			 (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for InvoiceItem."))
		       (:div :id "InvoiceItemlivesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:a :href "/hhub/addcusttoinvoice" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
	  (widget3 (function (lambda ()
		     (submitformevent-js "#InvoiceItemlivesearchresult")))))
      (list widget1 widget2 widget3))))


(defun createwidgetsforupdateInvoiceItem (modelfunc)
:description "This is a widgets function for update InvoiceItem entity"      
  (createwidgetsforgenericredirect modelfunc))

(defmethod RenderListViewHTML ((htmlview InvoiceItemHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for InvoiceItem entities, which will display each InvoiceItem entity in a row"
  (when viewmodellist
    (display-as-table (list "InvoiceHeader" "prdid" "prddesc" "hsncode" "qty" "uom" "price" "discount" "taxablevalue" "cgstrate" "cgstamt" "sgstrate" "sgstamt" "igstrate" "igstamt" "totalitemval" "company" "fieldR" "fieldS") viewmodellist 'display-InvoiceItem-row)))

(defun createmodelforsearchInvoiceItem ()
  :description "This is a model function for search InvoiceItem entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "InvoiceItemlivesearch"))
	 (company (get-login-company))
	 (presenterobj (make-instance 'InvoiceItemPresenter))
	 (requestmodelobj (make-instance 'InvoiceItemSearchRequestModel
						 :field1 search-clause
						 :company company))
	 (adapterobj (make-instance 'InvoiceItemAdapter))
	 (domainobjlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceItemHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-InvoiceItem-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))



(defun com-hhub-transaction-search-InvoiceItem-action ()
  :description "This is a MVC function to search action for InvoiceItem entities/entity" 
  (let* ((modelfunc (createmodelforsearchInvoiceItem))
	 (widgets (createwidgetsforsearchInvoiceItem modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
	(cl-who:str (funcall widget))))))

(defun createmodelforupdateInvoiceItem ()
  :description "This is a model function for update InvoiceItem entity"
  (let* ((InvoiceHeader (hunchentoot:parameter "InvoiceHeader"))
	 (prdid (hunchentoot:parameter "prdid"))
	 (prddesc (hunchentoot:parameter "prddesc"))
	 (hsncode (hunchentoot:parameter "hsncode"))
	 (qty (hunchentoot:parameter "qty"))
	 (uom (hunchentoot:parameter "uom"))
	 (price (float (with-input-from-string (in (hunchentoot:parameter "price"))
		   (read in))))
	 (discount (float (with-input-from-string (in (hunchentoot:parameter "discount"))
			    (read in))))
	 (taxablevalue (float (with-input-from-string (in (hunchentoot:parameter "taxablevalue"))
			    (read in))))
	 (cgstrate (float (with-input-from-string (in (hunchentoot:parameter "cgstrate"))
		   (read in))))
	 (cgstamt (float (with-input-from-string (in (hunchentoot:parameter "cgstamt"))
		   (read in))))
	 (sgstrate (float (with-input-from-string (in (hunchentoot:parameter "sgstrate"))
		   (read in))))

	 (sgstamt (float (with-input-from-string (in (hunchentoot:parameter "sgstamt"))
			   (read in))))
	 (igstrate (float (with-input-from-string (in (hunchentoot:parameter "igstrate"))
			    (read in))))
	 (igstamt (float (with-input-from-string (in (hunchentoot:parameter "igstamt"))
			    (read in))))
	 (totalitemval (float (with-input-from-string (in (hunchentoot:parameter "totalitemval"))
			    (read in))))
	 (company (get-login-vendor-company))
	 (requestmodel (make-instance 'InvoiceItemRequestModel
					 :InvoiceHeader InvoiceHeader
					 :prdid prdid
					 :prddesc prddesc
					 :hsncode hsncode
					 :qty qty
					 :uom uom
					 :price price
					 :discount discount
					 :taxablevalue taxablevalue
					 :cgstrate cgstrate
					 :cgstamt cgstamt
					 :sgstrate sgstrate
					 :sgstamt sgstamt
					 :igstrate igstrate
					 :igstamt igstamt
					 :totalitemval totalitemval
					 :company company))
	 (adapterobj (make-instance 'InvoiceItemAdapter))
	 (redirectlocation  "/hhub/InvoiceItem")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-InvoiceItem-action" params 
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))


(defun createmodelforcreateInvoiceItem ()
  :description "This is a create model function for creating a InvoiceItem entity"
  (let* ((InvoiceHeader (hunchentoot:parameter "InvoiceHeader"))
	 (prdid (hunchentoot:parameter "prdid"))
	 (prdqty (hunchentoot:parameter "prdqty"))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (product (select-product-by-id prdid company))
	 (ppricing (select-product-pricing-by-product-id prdid company))
	 (prdname (slot-value product 'prd-name))
	 (prd-name (subseq prdname 0 (min 20 (length prdname))))
	 (prddesc (slot-value product 'description))
	 (description (subseq prddesc 0 (min 30 (length prddesc))))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (prd-image-path (slot-value product 'prd-image-path))
	 (hsncode (slot-value product 'hsn-code))
	 (unit-price (slot-value product 'unit-price))
	 (pprice (if ppricing (slot-value ppricing 'price)))
	 (pdiscount (if ppricing (slot-value ppricing 'discount)))
	 (pcurr (if ppricing (slot-value ppricing 'currency)))
	 (taxablevalue (float (- (* prdqty (if pprice pprice price)) pdiscount)))
	 (cgstrate 0.00)
	 (cgstamt (float (with-input-from-string (in (hunchentoot:parameter "cgstamt"))
		   (read in))))
	 (sgstrate (float (with-input-from-string (in (hunchentoot:parameter "sgstrate"))
		   (read in))))

	 (sgstamt (float (with-input-from-string (in (hunchentoot:parameter "sgstamt"))
			   (read in))))
	 (igstrate (float (with-input-from-string (in (hunchentoot:parameter "igstrate"))
			    (read in))))
	 (igstamt (float (with-input-from-string (in (hunchentoot:parameter "igstamt"))
			    (read in))))
	 (totalitemval (float (with-input-from-string (in (hunchentoot:parameter "totalitemval"))
			    (read in))))
	 (company (get-login-vendor-company))
	 (requestmodel (make-instance 'InvoiceItemRequestModel
					 :InvoiceHeader InvoiceHeader
					 :prdid prdid
					 :prddesc prddesc
					 :hsncode hsncode
					 :qty qty
					 :uom uom
					 :price price
					 :discount discount
					 :taxablevalue taxablevalue
					 :cgstrate cgstrate
					 :cgstamt cgstamt
					 :sgstrate sgstrate
					 :sgstamt sgstamt
					 :igstrate igstrate
					 :igstamt igstamt
					 :totalitemval totalitemval
					 :company company))
	 (adapterobj (make-instance 'InvoiceItemAdapter))
	 (redirectlocation  "/hhub/InvoiceItem")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-InvoiceItem-action" params 
      (handler-case 
	  (let ((domainobj (ProcessCreateRequest adapterobj requestmodel)))
	    ;; Create the GST HSN Code object if not present. 
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))

(defun com-hhub-transaction-create-InvoiceItem-dialog (&optional domainobj)
  :description "This function creates a dialog to create InvoiceItem entity"
  (let* ((InvoiceHeader  (if domainobj (slot-value domainobj 'InvoiceHeader)))
	 (prdid  (if domainobj (slot-value domainobj 'prdid)))
	 (prddesc  (if domainobj (slot-value domainobj 'prddesc)))
	 (hsncode  (if domainobj (slot-value domainobj 'hsncode)))
	 (qty  (if domainobj (slot-value domainobj 'qty)))
	 (uom  (if domainobj (slot-value domainobj 'uom)))
	 (price  (if domainobj (slot-value domainobj 'price)))
	 (discount  (if domainobj (slot-value domainobj 'discount)))
	 (taxablevalue  (if domainobj (slot-value domainobj 'taxablevalue)))
	 (cgstrate  (if domainobj (slot-value domainobj 'cgstrate)))
	 (cgstamt  (if domainobj (slot-value domainobj 'cgstamt)))
	 (sgstrate  (if domainobj (slot-value domainobj 'sgstrate)))
	 (sgstamt  (if domainobj (slot-value domainobj 'sgstamt)))
	 (igstrate  (if domainobj (slot-value domainobj 'igstrate)))
	 (igstamt  (if domainobj (slot-value domainobj 'igstamt)))
	 (totalitemval  (if domainobj (slot-value domainobj 'totalitemval)))
	 (company  (if domainobj (slot-value domainobj 'company)))
	 (fieldR  (if domainobj (slot-value domainobj 'fieldR)))
	 (fieldS  (if domainobj (slot-value domainobj 'fieldS))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addInvoiceItem~A" InvoiceHeader)  (if domainobj "updateInvoiceItemaction" "createInvoiceItemaction")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "InvoiceHeader" :maxlength "20"  :value  InvoiceHeader :placeholder "InvoiceItem (max 20 characters) " :type "text" ))
		    (:div :class "form-group"
			  (:label :for "description")
			  (:textarea :class "form-control" :name "description"  :placeholder "Description ( max 500 characters) "  :rows "5" :onkeyup "countChar(this, 500)" (cl-who:str prddesc)))
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value prdid :placeholder "prdid"  :name "prdid" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value prddesc :placeholder "prddesc"  :name "prddesc" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value hsncode :placeholder "hsncode"  :name "hsncode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value qty :placeholder "qty"  :name "qty" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value uom :placeholder "uom"  :name "uom" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value price :placeholder "price"  :name "price" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value discount :placeholder "discount"  :name "discount" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value taxablevalue :placeholder "taxablevalue"  :name "taxablevalue" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value cgstrate :placeholder "cgstrate"  :name "cgstrate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value cgstamt :placeholder "cgstamt"  :name "cgstamt" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value sgstrate :placeholder "sgstrate"  :name "sgstrate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value sgstamt :placeholder "sgstamt"  :name "sgstamt" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value igstrate :placeholder "igstrate"  :name "igstrate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value igstamt :placeholder "igstamt"  :name "igstamt" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value totalitemval :placeholder "totalitemval"  :name "totalitemval" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value company :placeholder "company"  :name "company" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldR :placeholder "fieldR"  :name "fieldR" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldS :placeholder "fieldS"  :name "fieldS" ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))





(defun createwidgetsforcreateInvoiceItem (modelfunc)
  :description "This is a create widget function for InvoiceItem entity"
  (createwidgetsforgenericredirect modelfunc))




(defun createwidgetsforsearchInvoiceItem (modelfunc)
  :description "This is a widget function for search InvoiceItem entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#editInvoiceItem-modal" "Add InvoiceItem")
				   (modal-dialog "editInvoiceItem-modal" "Add/Edit InvoiceItem" (com-hhub-transaction-create-InvoiceItem-dialog)))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))


(defmethod RenderListViewHTML ((htmlview InvoiceItemHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for InvoiceHeader entities, which will display each InvoiceHeader entity in a row"
  (when viewmodellist
    (display-as-table (list "Product" "HSN Code" "UOM" "Qty" "Rate" "Amount" "Less:Discount" "Taxable Value" "CGST" "SGST" "IGST" "Total") viewmodellist 'display-InvoiceItem-row)))
 
(defun display-InvoiceItem-row (InvoiceItemViewModel)
  :description "This function has HTML row code for InvoiceItem entity row"
  (with-slots (InvoiceHeader prdid prddesc hsncode qty uom price discount  taxablevalue cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval) InvoiceItemViewModel 
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str prdid))
      (:td  :height "10px" (cl-who:str prddesc))
      (:td  :height "10px" (cl-who:str hsncode))
      (:td  :height "10px" (cl-who:str uom))
      (:td  :height "10px" (cl-who:str qty))
      (:td  :height "10px" (cl-who:str price))
      (:td  :height "10px" (cl-who:str taxablevalue))
      (:td  :height "10px" (cl-who:str discount))
      (:td  :height "10px" (cl-who:str (- taxablevalue discount)))
      (:td  :height "10px" (cl-who:str cgstrate))
      (:td  :height "10px" (cl-who:str sgstrate))
      (:td  :height "10px" (cl-who:str igstrate))
      (:td  :height "10px" (cl-who:str totalitemval))
      (:td  :height "10px" 
	    (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target (format nil "#editInvoiceItem-modal~A" prdid) (:i :class "fa-solid fa-pencil"))
	    (modal-dialog (format nil "editInvoiceItem-modal~A" prdid) "Add/Edit InvoiceItem" (com-hhub-transaction-create-InvoiceItem-dialog InvoiceItemViewModel))))))



(defun com-hhub-transaction-update-InvoiceItem-action ()
  :description "This is the MVC function to update action for InvoiceItem entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforupdateInvoiceItem createwidgetsforupdateInvoiceItem)))
      (format nil "~A" url))))


(defun com-hhub-transaction-create-InvoiceItem-action ()
  :description "This is a MVC function for create InvoiceItem entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforcreateInvoiceItem createwidgetsforcreateInvoiceItem)))
      (format nil "~A" url))))


